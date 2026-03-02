# Research: Authentication & Role Assignment

**Branch**: `003-auth-role-assignment` | **Date**: 2026-03-02  
**Phase**: 0 — Research  
**Source**: spec.md (Clarified)

---

## 1. Supabase Auth — Signup and Auto-Provisioning

**Decision**: Use a PostgreSQL trigger on `auth.users` (`AFTER INSERT`) to atomically provision the tenant, default branch, and tenant_admin membership when a new user signs up.

**Rationale**: Supabase Auth manages the `auth.users` table. A database trigger fires within the same transaction as the user insert, guaranteeing atomicity without relying on application-layer orchestration. If any provisioning step fails, the entire signup transaction rolls back — satisfying FR-002.

**Alternatives considered**:
- **Supabase Edge Function (after signup webhook)**: Rejected — runs asynchronously after the auth transaction commits, meaning a failed provisioning step would leave an orphaned user account. Does not satisfy the atomicity requirement.
- **Client-side orchestration (multi-step API calls)**: Rejected — introduces race conditions and partial failure states. If the client disconnects between creating the user and inserting the tenant, orphaned records result.
- **Supabase Database Function (RPC call from client after signup)**: Partially viable but adds a second request. The user could sign up but fail to call the RPC if the client crashes. Trigger-based approach is more reliable.

---

## 2. Business Name Collection at Signup

**Decision**: Pass the business name (tenant name) via Supabase Auth's `options.data` metadata field during `signUp()`. The database trigger reads this value from `NEW.raw_user_meta_data->>'business_name'` to populate the tenant's `name` column.

**Rationale**: Supabase Auth's `signUp` method supports passing arbitrary metadata in `raw_user_meta_data`. This is the standard approach for passing extra registration data without requiring a custom registration endpoint.

**Post-signup editing**: The Tenant Admin can also update the tenant name at any time after signup via a standard Supabase update on `public.tenants` (subject to RLS). The signup metadata approach sets the initial value; subsequent changes use the normal CRUD path.

**Alternatives considered**:
- **Separate API call after signup to set initial tenant name**: Rejected for the initial value — would require the tenant to exist with a placeholder name first, then update. The trigger approach sets it correctly from the start. However, editing after signup is fully supported via standard table updates.
- **Custom Supabase Edge Function for registration**: Rejected — overengineered for passing one extra field. The metadata approach is simpler and uses built-in Supabase functionality.

---

## 3. Single Tenant Admin Per User — Enforcement

**Decision**: Add a `UNIQUE(user_id)` constraint on `tenant_users` to enforce the one-tenant-admin-per-user rule at the database level.

**Rationale**: The `tenant_users` table currently has a `UNIQUE(tenant_id, user_id)` constraint (preventing duplicate admin assignments within one tenant). Adding a standalone `UNIQUE(user_id)` constraint prevents the same user from appearing in `tenant_users` for multiple tenants — enforcing FR-019 at the lowest possible level.

**Alternatives considered**:
- **Application-layer check before insert**: Rejected — can be bypassed by direct database access. Database constraints are the strongest guarantee.
- **Trigger-based check**: Viable but unnecessary — a unique constraint is simpler, faster, and automatically produces a clear error.

---

## 4. Invitation Table Design

**Decision**: Create a new `public.invitations` table with columns: `id`, `tenant_id`, `branch_id`, `email`, `role`, `status`, `token`, `invited_by`, `created_at`, `expires_at`. Use a unique secure token in the invitation link. Status transitions: `pending` → `accepted` | `revoked` | `expired`.

**Rationale**: The spec requires listing pending invitations (FR-013), revoking them, tracking 48-hour expiry (FR-018), and preventing duplicate acceptance (FR-014). All of these require persistent, queryable records. A unique token per invitation enables secure link-based acceptance without exposing internal IDs.

**Alternatives considered**:
- **Signed JWT token only (no table)**: Rejected — cannot support listing, revoking, or checking if already accepted without server-side state.
- **Reusing `branch_users` table with a pending flag**: Rejected — mixes invitation state with actual access grants, complicating RLS policies and role checks.

---

## 5. Invitation Expiry Mechanism

**Decision**: Store `expires_at` as `created_at + INTERVAL '48 hours'` on insert. Check expiry in both the acceptance endpoint (application-layer) and via a SQL condition in queries (`WHERE status = 'pending' AND expires_at > now()`). Optionally, a scheduled job can batch-update expired invitations to `status = 'expired'`.

**Rationale**: Storing the expiry timestamp is simpler and more reliable than a background job alone. The query-time filter ensures expired invitations are never returned as valid, even if no cleanup job has run.

**Alternatives considered**:
- **Background cron job only**: Rejected as the sole mechanism — if the job fails or is delayed, expired invitations could still be accepted.
- **TTL on rows (auto-delete)**: Rejected — the spec requires expired invitations to remain visible (Tenant Admin can resend). Deleting them would prevent this.

---

## 6. Role-Based Routing After Sign-In

**Decision**: After successful Supabase Auth sign-in, the Flutter app queries `tenant_users` (filtering by `user_id = auth.uid()`). If a record exists → route to Tenant Admin dashboard. If not, query `branch_users` → if single branch → route to branch view. If multiple branches → show branch selector. If no records in either table → show an error/pending state.

**Rationale**: This mirrors the Phase 2 RLS approach — role is determined by membership table presence, not JWT claims. The query order (tenant_users first, then branch_users) respects the role hierarchy.

**Alternatives considered**:
- **Store role in JWT claims via Supabase hook**: Rejected — Phase 2 explicitly prohibits custom JWT claims.
- **Single combined query with a UNION**: Viable for optimization but adds complexity. Sequential queries are clearer for the initial implementation and can be optimized later.

---

## 7. Invitation Link Format

**Decision**: Use the app's URL with the invitation token as a query parameter. During local development: `http://localhost:<port>/invite?token={uuid}`. In production: `https://admin.ontapi.com/invite?token={uuid}`. The Flutter app reads the token on load, validates it against the `invitations` table, and routes to signup or sign-in accordingly.

**Rationale**: Simple, works with Flutter Web routing, and the token-based approach avoids exposing internal IDs. The token is a UUID generated server-side, providing sufficient entropy for security. The base URL is environment-dependent — localhost for development, `admin.ontapi.com` for production deployment.

> **Note**: All documentation in this phase references `admin.ontapi.com` as the production domain. During development and testing, use `localhost` with the appropriate port. The base URL should be driven by an environment configuration.

**Alternatives considered**:
- **Supabase Magic Link**: Rejected — Magic Links are for passwordless auth, not for invitation-with-role-assignment. The use case requires associating a role and branch with the link, which Magic Links don't support natively.
- **Short URL with redirect service**: Unnecessary complexity for the initial launch. Can be added later if sharing UX needs improvement.

---

## 8. Invitation RLS Policies

**Decision**: Apply RLS on the `invitations` table. Tenant Admin can SELECT, INSERT, UPDATE (for revoke/resend) invitations scoped to their tenant. No other role has direct access. Invitation acceptance is handled via a `SECURITY DEFINER` function that validates the token and creates the `branch_users` record — bypassing RLS for the atomic accept operation.

**Rationale**: The accept-invitation flow involves a user who is not yet a member of any tenant/branch (they have no RLS-visible rows). A `SECURITY DEFINER` function safely performs the lookup and insert on their behalf, then returns the result.

**Alternatives considered**:
- **Open SELECT on invitations by token**: Rejected — exposes invitation metadata to anyone with a valid token. The SECURITY DEFINER function returns only the necessary status.
- **Supabase Edge Function for acceptance**: Viable but adds an external dependency. A database function keeps the logic co-located with the data and runs within the same transaction.
