# Data Model: Access Control & Row Level Security

**Branch**: `002-access-control-rls` | **Date**: 2026-03-01  
**Phase**: 1 — Design  
**Source**: Phase 1 migration `20260228101405_database_foundation.sql`

---

## Overview

This phase adds no new tables. All 10 tables from Phase 1 are augmented with RLS policies and one new database trigger (role-conflict prevention). This document describes those additions as a data model layer on top of the existing schema.

---

## Existing Tables (Phase 1) — RLS Additions

### `public.tenants`

| Aspect | Detail |
|---|---|
| RLS Enabled | Yes |
| Partition key | `id` (tenant identity) |
| Lookup used | `tenant_users.tenant_id = tenants.id AND tenant_users.user_id = auth.uid()` |

**Policies:**

| Role | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| tenant_admin | Own tenant only | ✗ | Own tenant only | ✗ |
| branch_manager | Own tenant only (read-only for context) | ✗ | ✗ | ✗ |
| branch_staff | ✗ | ✗ | ✗ | ✗ |
| unauthenticated | ✗ | ✗ | ✗ | ✗ |

---

### `public.branches`

| Aspect | Detail |
|---|---|
| RLS Enabled | Yes |
| Partition key | `tenant_id` (tenant), `id` (branch) |
| Tenant lookup | `tenant_users` via `tenant_id` |
| Branch lookup | `branch_users` via `branch_id` |

**Policies:**

| Role | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| tenant_admin | All branches in own tenant | Own tenant | Own tenant | Own tenant |
| branch_manager | Own branch only | ✗ | Own branch only | ✗ |
| branch_staff | Own branch only (read-only for context) | ✗ | ✗ | ✗ |
| unauthenticated | ✗ | ✗ | ✗ | ✗ |

---

### `public.tenant_users`

| Aspect | Detail |
|---|---|
| RLS Enabled | Yes |
| Partition key | `tenant_id` |
| Note | Used as the role-lookup table itself; must allow self-read |

**Policies:**

| Role | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| tenant_admin | Own tenant's records | Own tenant | ✗ | Own tenant |
| branch_manager | ✗ | ✗ | ✗ | ✗ |
| branch_staff | ✗ | ✗ | ✗ | ✗ |
| unauthenticated | ✗ | ✗ | ✗ | ✗ |

---

### `public.branch_users`

| Aspect | Detail |
|---|---|
| RLS Enabled | Yes |
| Partition key | `branch_id` (→ `tenant_id` via `branches`) |
| Note | Trigger `prevent_role_conflict` added here (see below) |

**Policies:**

| Role | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| tenant_admin | All branch users in own tenant | Own tenant's branches | ✗ | Own tenant's branches |
| branch_manager | Own branch only | Own branch only **(role = branch_staff only — enforced via WITH CHECK)** | ✗ | Own branch's staff only |
| branch_staff | ✗ | ✗ | ✗ | ✗ |
| unauthenticated | ✗ | ✗ | ✗ | ✗ |

> **Note**: The Branch Manager INSERT policy enforces `NEW.role = 'branch_staff'` via `WITH CHECK`. A Branch Manager cannot elevate someone to `branch_manager` — only a Tenant Admin can do that.

---

### `public.orders`

| Aspect | Detail |
|---|---|
| RLS Enabled | Yes |
| Partition key | `branch_id`, `tenant_id` |

**Policies:**

| Role | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| tenant_admin | All orders in own tenant | ✗ | ✗ | ✗ |
| branch_manager | Own branch orders | ✗ | Own branch orders | ✗ |
| branch_staff | Own branch orders | Own branch orders | Own branch orders (status only) | ✗ |
| unauthenticated | ✗ | ✗ | ✗ | ✗ |

> **Note**: Branch Staff UPDATE is scoped to the `status` column transition only. Column-level restrictions are enforced via policy conditions or application-layer (the policy permits UPDATE on rows they own; column-level grants may be added as a hardening step).

---

### `public.offers`

| Aspect | Detail |
|---|---|
| RLS Enabled | Yes |
| Partition key | `tenant_id` |

**Policies:**

| Role | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| tenant_admin | Own tenant's offers | Own tenant | Own tenant | Own tenant |
| branch_manager | Own tenant's offers (read-only) | ✗ | ✗ | ✗ |
| branch_staff | ✗ | ✗ | ✗ | ✗ |
| unauthenticated | ✗ | ✗ | ✗ | ✗ |

---

### `public.branch_offers`

| Aspect | Detail |
|---|---|
| RLS Enabled | Yes |
| Partition key | `branch_id` (→ tenant via `branches`) |

**Policies:**

| Role | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| tenant_admin | All in own tenant | Own tenant's branches | ✗ | Own tenant's branches |
| branch_manager | Own branch's associations | ✗ | ✗ | ✗ |
| branch_staff | ✗ | ✗ | ✗ | ✗ |
| unauthenticated | ✗ | ✗ | ✗ | ✗ |

---

### `public.subscriptions`

| Aspect | Detail |
|---|---|
| RLS Enabled | Yes |
| Partition key | `tenant_id` |

**Policies:**

| Role | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| tenant_admin | Own tenant | ✗ | Own tenant | ✗ |
| branch_manager | ✗ | ✗ | ✗ | ✗ |
| branch_staff | ✗ | ✗ | ✗ | ✗ |
| unauthenticated | ✗ | ✗ | ✗ | ✗ |

> Subscription creation/deletion is a platform-level admin operation, not a tenant-level action.

---

### `public.usage_tracking`

| Aspect | Detail |
|---|---|
| RLS Enabled | Yes |
| Partition key | `tenant_id` |

**Policies:**

| Role | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| tenant_admin | Own tenant | ✗ | ✗ | ✗ |
| branch_manager | ✗ | ✗ | ✗ | ✗ |
| branch_staff | ✗ | ✗ | ✗ | ✗ |
| unauthenticated | ✗ | ✗ | ✗ | ✗ |

> Usage counter increments are performed by a database trigger (Phase 5), not by application inserts.

---

### `public.ratings`

| Aspect | Detail |
|---|---|
| RLS Enabled | Yes |
| Partition key | `tenant_id`, `branch_id` |
| Write source | External customer-facing channel only (out of internal role scope) |

**Policies:**

| Role | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| tenant_admin | Own tenant's ratings | ✗ | ✗ | ✗ |
| branch_manager | Own branch's ratings | ✗ | ✗ | ✗ |
| branch_staff | ✗ | ✗ | ✗ | ✗ |
| unauthenticated | ✗ | ✗ | ✗ | ✗ |

---

## New Database Object: Role-Conflict Trigger

### `prevent_role_conflict` (BEFORE INSERT on `branch_users`)

| Aspect | Detail |
|---|---|
| Trigger type | `BEFORE INSERT FOR EACH ROW` |
| Table | `public.branch_users` |
| Purpose | Prevent a user who is already a `tenant_admin` from being inserted as a branch-level user in the same tenant |
| Logic | Look up `branches.tenant_id` for `NEW.branch_id`; check if `NEW.user_id` exists in `tenant_users` for that tenant; if yes → `RAISE EXCEPTION` |
| Error behavior | Raises a PostgreSQL exception (INSERT is rejected) |

---

## Helper Functions (SECURITY DEFINER)

Role verification requires querying the exact same membership tables (`tenant_users` and `branch_users`) that the policies secure. To prevent infinite recursion in the RLS engine, three standalone helper functions are introduced using `SECURITY DEFINER` (which bypasses RLS during the check):
- `public.is_tenant_admin(UUID)`
- `public.is_branch_manager(UUID)`
- `public.is_branch_staff(UUID)`

---

## Summary of Changes

| Object Type | Count |
|---|---|
| Tables with RLS enabled | 10 |
| RLS USING policies (SELECT) | 18 |
| RLS WITH CHECK policies (INSERT/UPDATE/DELETE) | 17 |
| New triggers | 1 (`prevent_role_conflict`) |
| New tables | 0 |
| New functions | 3 (`is_tenant_admin`, `is_branch_manager`, `is_branch_staff`) |
| Migration files | 1 (new) |
