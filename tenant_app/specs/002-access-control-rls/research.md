# Research: Access Control & Row Level Security

**Branch**: `002-access-control-rls` | **Date**: 2026-03-01  
**Phase**: 0 — Resolving all technical unknowns before design

---

## 1. RLS Policy Pattern for Multi-Tenant Supabase Apps

**Decision**: Use relational subquery pattern — `EXISTS (SELECT 1 FROM tenant_users WHERE user_id = auth.uid() AND tenant_id = <table>.tenant_id)` — rather than JWT claims.

**Rationale**: The spec and constitution explicitly prohibit JWT custom claims. Relational lookups via indexed foreign keys (`idx_tenant_users_user_id`, `idx_branch_users_user_id`) are performant and deterministic. This pattern is the Supabase-recommended approach when claims are unavailable or untrusted.

**Alternatives considered**:
- JWT custom claims (rejected — constitution and spec explicitly forbid this)
- Application-layer role enforcement (rejected — FR-010 requires data-layer enforcement)
- PostgreSQL row security with materialized roles (rejected — overkill for this scale)

---

## 2. Deny-by-Default Enforcement

**Decision**: Enable RLS (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`) on each table *before* adding any GRANT or POLICY. Enable `FORCE ROW LEVEL SECURITY` for table owners to prevent bypass.

**Rationale**: In PostgreSQL, enabling RLS without any policy results in complete denial for non-superusers. This is the correct baseline: unauthenticated users and roleless users automatically receive zero rows.

**Alternatives considered**:
- Default-deny via application layer (rejected — FR-010 requires DB-layer enforcement)
- Explicit DENY policies (not a Postgres construct — deny-by-default is inherent when RLS is enabled with no matching policy)

---

## 3. Silent Rejection Behavior in PostgreSQL RLS

**Decision**: No additional configuration needed — PostgreSQL RLS silently filters rows that don't satisfy a policy. Unauthorized reads return zero rows; unauthorized writes fail silently (or with a generic integrity error, not an access-denied message).

**Rationale**: This is the native PostgreSQL RLS behavior. The spec's Q1 clarification (silent empty result) aligns with default Postgres behavior at no extra implementation cost.

**Note**: Write operations that violate RLS will raise a `42501` error at the Postgres level, but at the Supabase/application level these should be caught and surfaced neutrally (not as "access denied").

---

## 4. Role-Conflict Prevention (FR-011)

**Decision**: Implement via a PostgreSQL `BEFORE INSERT` trigger on `branch_users` that checks whether the inserting `user_id` already exists in `tenant_users` for the same tenant. Reject the insert if a conflict is found.

**Rationale**: A database-level trigger is the only reliable enforcement mechanism — application-layer checks can be bypassed. The trigger queries `tenant_users` joined to `branches` to derive the tenant, then raises an exception if the user is already a tenant_admin.

**Alternatives considered**:
- Unique constraint across tables (not possible in standard PostgreSQL across two separate tables)
- Application-layer guard only (rejected — must be enforced at DB layer per FR-010)
- Check constraint (cannot reference other tables in standard PostgreSQL)

---

## 5. Tenant Cascade Delete (Edge Case EC2)

**Decision**: The existing `branches` table already has `ON DELETE CASCADE` from `tenants`. The `tenant_users`, `orders`, `offers`, `subscriptions`, `usage_tracking`, and `ratings` tables also have `ON DELETE CASCADE` from `tenants`. This is already implemented in the Phase 1 migration.

**Rationale**: No additional work needed for cascade delete — Phase 1 already defines the correct FK cascade chains. This phase confirms the behavior is correct and relies on it.

**Exception**: `tenant_users` uses `ON DELETE RESTRICT` from tenants (preventing tenant deletion while users exist). This is a pre-existing design choice from Phase 1 and is outside Phase 2 scope.

---

## 6. Policy Naming Convention

**Decision**: Use descriptive policy names following the pattern: `<table>_<role>_<operation>`.  
Examples: `orders_branch_staff_insert`, `offers_branch_manager_select`, `ratings_all_internal_select`.

**Rationale**: Descriptive names make auditing and debugging straightforward. Supabase dashboard displays policies by name.

---

## 7. Branch Manager Access to Offers

**Decision**: Branch Managers get SELECT-only on `offers` (tenant-scoped) and `branch_offers` (branch-scoped). No INSERT/UPDATE/DELETE.

**Rationale**: Spec FR-003 and the Q5 clarification (ratings read-only) establish read-only access to tenant-wide resources for Branch Managers. Offers fall under tenant-wide resources.

---

## 8. Orders Read Access for Branch Manager

**Decision**: Branch Manager gets full SELECT + UPDATE on orders for their assigned branch. No INSERT (only Branch Staff can create orders). No DELETE.

**Rationale**: Branch Managers monitor queues and may need to update order status in operational scenarios. The spec grants them "manage branch-level operations" which includes order status transitions. INSERT is explicit to Branch Staff only.

---

## Summary of NEEDS CLARIFICATION items

None. All unknowns resolved via spec clarifications and research above.
