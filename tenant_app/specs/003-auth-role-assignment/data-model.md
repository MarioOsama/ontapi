# Data Model: Authentication & Role Assignment

**Branch**: `003-auth-role-assignment` | **Date**: 2026-03-02  
**Phase**: 1 — Design  
**Source**: Phase 1 migration `20260228101405_database_foundation.sql`, Phase 2 migration `20260301123647_access_control_rls.sql`

---

## Overview

This phase introduces **1 new table** (`invitations`), **1 new database function** (`accept_invitation`), **2 new triggers** (signup provisioning + single-admin enforcement), **1 new constraint** (`UNIQUE(user_id)` on `tenant_users`), and **RLS policies** for the new table. No existing table schemas are modified.

---

## New Table: `public.invitations`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Unique identifier |
| `tenant_id` | `UUID` | `NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE` | Tenant owning this invitation |
| `branch_id` | `UUID` | `NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE` | Target branch for the invited user |
| `email` | `TEXT` | `NOT NULL` | Invitee's email address |
| `role` | `TEXT` | `NOT NULL CHECK (role IN ('branch_manager', 'branch_staff'))` | Role to assign upon acceptance |
| `status` | `TEXT` | `NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'revoked', 'expired'))` | Current invitation status |
| `token` | `UUID` | `NOT NULL UNIQUE DEFAULT gen_random_uuid()` | Secure token for invitation link |
| `invited_by` | `UUID` | `NOT NULL REFERENCES auth.users(id)` | User who created the invitation |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT now()` | Creation timestamp |
| `expires_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT (now() + INTERVAL '48 hours')` | Expiration timestamp (48 hours from creation) |

**Indexes:**

| Index | Columns | Purpose |
|-------|---------|---------|
| `idx_invitations_tenant_id` | `tenant_id` | Tenant-scoped queries |
| `idx_invitations_branch_id` | `branch_id` | Branch-scoped queries |
| `idx_invitations_token` | `token` | Fast token lookup for acceptance |
| `idx_invitations_email` | `email` | Lookup by invitee email |

**Unique Constraints:**

| Constraint | Columns | Purpose |
|------------|---------|---------|
| `uq_invitations_branch_email_pending` | `(branch_id, email)` WHERE `status = 'pending'` | Prevent duplicate pending invitations for the same email + branch |

> **Note**: This is a partial unique index (filtered on `status = 'pending'`). A user can have multiple historical invitation records (accepted, revoked, expired) for the same branch.

**RLS Policies:**

| Role | SELECT | INSERT | UPDATE | DELETE |
|------|--------|--------|--------|--------|
| tenant_admin | Own tenant's invitations | Own tenant's invitations | Own tenant's invitations (status changes only) | ✗ |
| branch_manager | Own branch's invitations | Own branch's invitations | Own branch's invitations (status changes only) | ✗ |
| branch_staff | ✗ | ✗ | ✗ | ✗ |
| unauthenticated | ✗ | ✗ | ✗ | ✗ |

> **Note**: Branch Manager RLS policies for invitations are defined now to support a future phase where Branch Managers can invite and manage `branch_staff` within their own branch. The UI-layer implementation for this feature is deferred — only Tenant Admin invitation management is built in Phase 3.

> Invitation acceptance is handled via the `accept_invitation` SECURITY DEFINER function, which bypasses RLS.

---

## Modified Table: `public.tenant_users`

### New Constraint

| Constraint | Type | Columns | Purpose |
|------------|------|---------|---------|
| `uq_tenant_users_user_id` | `UNIQUE` | `user_id` | Enforces one tenant_admin per user across the platform (FR-019) |

> This is **additional** to the existing `UNIQUE(tenant_id, user_id)` constraint. Together they ensure: (1) a user cannot be admin of the same tenant twice, and (2) a user cannot be admin of multiple tenants.

---

## New Database Function: `accept_invitation(UUID)`

| Aspect | Detail |
|--------|--------|
| Name | `public.accept_invitation` |
| Parameters | `invitation_token UUID` |
| Returns | `JSON` (branch_id, role, tenant_id, status) |
| Security | `SECURITY DEFINER` (bypasses RLS) |
| Purpose | Validates an invitation token, creates a `branch_users` record, and marks the invitation as accepted — atomically |

**Logic:**

1. Look up `invitations` record by `token` WHERE `status = 'pending'` AND `expires_at > now()`.
2. If not found → return `{ "status": "invalid" }` (expired, revoked, or non-existent).
3. If found but invitation email ≠ `auth.jwt()->>'email'` → return `{ "status": "email_mismatch" }`.
4. Check if `auth.uid()` already exists in `tenant_users` for the invitation's tenant → if yes, return `{ "status": "role_conflict" }` (tenant_admin cannot hold branch role).
5. Insert into `branch_users` (`branch_id`, `user_id = auth.uid()`, `role`). If `UNIQUE(branch_id, user_id)` conflict → return `{ "status": "already_member" }`.
6. Update `invitations` SET `status = 'accepted'`.
7. Return `{ "status": "success", "branch_id": ..., "role": ..., "tenant_id": ... }`.

---

## New Trigger: `handle_new_user_signup`

| Aspect | Detail |
|--------|--------|
| Trigger type | `AFTER INSERT FOR EACH ROW` on `auth.users` |
| Function | `public.handle_new_user_signup()` |
| Security | `SECURITY DEFINER` |
| Purpose | Auto-provisions tenant + branch + tenant_admin role on signup |

**Logic:**

1. Extract `business_name` from `NEW.raw_user_meta_data->>'business_name'`. Default to `'My Business'` if absent.
2. INSERT into `public.tenants` (`name = business_name`) → capture tenant `id`.
3. INSERT into `public.branches` (`tenant_id`, `name = 'Main Branch'`, `avg_service_duration = 10`) → capture branch `id`.
4. INSERT into `public.tenant_users` (`tenant_id`, `user_id = NEW.id`, `role = 'tenant_admin'`).
5. If any step fails, the entire auth signup transaction rolls back.

---

## Existing Trigger: `prevent_role_conflict` (Phase 2)

Already in place on `branch_users`. Prevents inserting a branch user whose `user_id` is already a `tenant_admin` for the same tenant. **No changes needed** — this trigger will correctly block acceptance of invitations for users who are tenant admins.

---

## Existing Helper Functions (Phase 2)

- `public.is_tenant_admin(UUID)` — used in RLS policies. **No changes needed.**
- `public.is_branch_manager(UUID)` — **No changes needed.**
- `public.is_branch_staff(UUID)` — **No changes needed.**

These functions will be reused in the new invitations RLS policies.

---

## Entity Relationship Additions

```mermaid
erDiagram
    auth_users ||--o| tenant_users : "signup creates"
    tenant_users ||--|| tenants : "references"
    tenants ||--|{ branches : "owns"
    tenants ||--|{ invitations : "has"
    branches ||--|{ invitations : "targets"
    invitations }|--|| auth_users : "invited_by"
    invitations -.->|"accept"| branch_users : "creates on accept"
    branch_users ||--|| branches : "assigned to"
    branch_users ||--|| auth_users : "references"
```

---

## Summary of Changes

| Object Type | Count |
|---|---|
| New tables | 1 (`invitations`) |
| New indexes | 4 (on `invitations`) |
| New constraints | 1 (`UNIQUE(user_id)` on `tenant_users`) + 1 partial unique on `invitations` |
| New functions | 2 (`handle_new_user_signup`, `accept_invitation`) |
| New triggers | 1 (`handle_new_user_signup` on `auth.users`) |
| New RLS policies | 3 (SELECT, INSERT, UPDATE on `invitations`) |
| Modified tables | 1 (`tenant_users` — new UNIQUE constraint only) |
| Migration files | 1 (new) |
