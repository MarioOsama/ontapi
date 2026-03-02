# RLS Policy Contract: Access Control & Row Level Security

**Branch**: `002-access-control-rls` | **Date**: 2026-03-01  
**Phase**: 1 — Contracts  
**Format**: SQL policy contract (implementation-ready)

---

## Overview

This contract defines the exact policy set to be implemented in the Phase 2 migration. Each entry maps to one `CREATE POLICY` statement in the migration file.

Naming convention: `<table>_<role>_<operation(s)>`

---

## Global Rules

- RLS is **enabled** on all 10 tables via `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`.
- `FORCE ROW LEVEL SECURITY` is set to prevent table-owner bypass.
- All policies use `auth.uid()` for identity resolution.
- No JWT claims are used.
- Deny-by-default: tables with no matching policy return zero rows.

---

## Policy Matrix

### `public.tenants`

| Policy Name | Command | Role | USING Condition |
|---|---|---|---|
| `tenants_tenant_admin_all` | ALL | `authenticated` | Tenant Admin: `EXISTS (SELECT 1 FROM tenant_users WHERE user_id = auth.uid() AND tenant_id = tenants.id)` |
| `tenants_branch_manager_select` | SELECT | `authenticated` | Branch Manager: `EXISTS (SELECT 1 FROM branch_users bu JOIN branches b ON bu.branch_id = b.id WHERE bu.user_id = auth.uid() AND bu.role = 'branch_manager' AND b.tenant_id = tenants.id)` |

---

### `public.branches`

| Policy Name | Command | USING / WITH CHECK Condition |
|---|---|---|
| `branches_tenant_admin_all` | ALL | `EXISTS (SELECT 1 FROM tenant_users WHERE user_id = auth.uid() AND tenant_id = branches.tenant_id)` |
| `branches_branch_manager_select` | SELECT | `EXISTS (SELECT 1 FROM branch_users WHERE user_id = auth.uid() AND branch_id = branches.id AND role = 'branch_manager')` |
| `branches_branch_manager_update` | UPDATE | `EXISTS (SELECT 1 FROM branch_users WHERE user_id = auth.uid() AND branch_id = branches.id AND role = 'branch_manager')` |
| `branches_branch_staff_select` | SELECT | `EXISTS (SELECT 1 FROM branch_users WHERE user_id = auth.uid() AND branch_id = branches.id AND role = 'branch_staff')` |

---

### `public.tenant_users`

| Policy Name | Command | Condition |
|---|---|---|
| `tenant_users_tenant_admin_all` | ALL | `EXISTS (SELECT 1 FROM tenant_users tu WHERE tu.user_id = auth.uid() AND tu.tenant_id = tenant_users.tenant_id)` |

---

### `public.branch_users`

| Policy Name | Command | USING Condition | WITH CHECK Condition |
|---|---|---|---|
| `branch_users_tenant_admin_all` | ALL | `EXISTS (SELECT 1 FROM tenant_users tu JOIN branches b ON tu.tenant_id = b.tenant_id WHERE tu.user_id = auth.uid() AND b.id = branch_users.branch_id)` | *(same)* |
| `branch_users_branch_manager_select` | SELECT | `EXISTS (SELECT 1 FROM branch_users bu WHERE bu.user_id = auth.uid() AND bu.branch_id = branch_users.branch_id AND bu.role = 'branch_manager')` | — |
| `branch_users_branch_manager_insert_staff` | INSERT | — | `EXISTS (SELECT 1 FROM branch_users bu WHERE bu.user_id = auth.uid() AND bu.branch_id = branch_users.branch_id AND bu.role = 'branch_manager') AND NEW.role = 'branch_staff'` |
| `branch_users_branch_manager_delete_staff` | DELETE | `EXISTS (SELECT 1 FROM branch_users bu WHERE bu.user_id = auth.uid() AND bu.branch_id = branch_users.branch_id AND bu.role = 'branch_manager') AND branch_users.role = 'branch_staff'` | — |

---

### `public.orders`

| Policy Name | Command | Condition |
|---|---|---|
| `orders_tenant_admin_select` | SELECT | `EXISTS (SELECT 1 FROM tenant_users WHERE user_id = auth.uid() AND tenant_id = orders.tenant_id)` |
| `orders_branch_manager_select` | SELECT | `EXISTS (SELECT 1 FROM branch_users WHERE user_id = auth.uid() AND branch_id = orders.branch_id AND role = 'branch_manager')` |
| `orders_branch_manager_update` | UPDATE | `EXISTS (SELECT 1 FROM branch_users WHERE user_id = auth.uid() AND branch_id = orders.branch_id AND role = 'branch_manager')` |
| `orders_branch_staff_select_insert_update` | SELECT, INSERT, UPDATE | `EXISTS (SELECT 1 FROM branch_users WHERE user_id = auth.uid() AND branch_id = orders.branch_id AND role = 'branch_staff')` |

---

### `public.offers`

| Policy Name | Command | Condition |
|---|---|---|
| `offers_tenant_admin_all` | ALL | `EXISTS (SELECT 1 FROM tenant_users WHERE user_id = auth.uid() AND tenant_id = offers.tenant_id)` |
| `offers_branch_manager_select` | SELECT | `EXISTS (SELECT 1 FROM branch_users bu JOIN branches b ON bu.branch_id = b.id WHERE bu.user_id = auth.uid() AND bu.role = 'branch_manager' AND b.tenant_id = offers.tenant_id)` |

---

### `public.branch_offers`

| Policy Name | Command | Condition |
|---|---|---|
| `branch_offers_tenant_admin_all` | ALL | `EXISTS (SELECT 1 FROM tenant_users tu JOIN branches b ON tu.tenant_id = b.tenant_id WHERE tu.user_id = auth.uid() AND b.id = branch_offers.branch_id)` |
| `branch_offers_branch_manager_select` | SELECT | `EXISTS (SELECT 1 FROM branch_users WHERE user_id = auth.uid() AND branch_id = branch_offers.branch_id AND role = 'branch_manager')` |

---

### `public.subscriptions`

| Policy Name | Command | Condition |
|---|---|---|
| `subscriptions_tenant_admin_select` | SELECT | `EXISTS (SELECT 1 FROM tenant_users WHERE user_id = auth.uid() AND tenant_id = subscriptions.tenant_id)` |
| `subscriptions_tenant_admin_update` | UPDATE | `EXISTS (SELECT 1 FROM tenant_users WHERE user_id = auth.uid() AND tenant_id = subscriptions.tenant_id)` |

---

### `public.usage_tracking`

| Policy Name | Command | Condition |
|---|---|---|
| `usage_tracking_tenant_admin_select` | SELECT | `EXISTS (SELECT 1 FROM tenant_users WHERE user_id = auth.uid() AND tenant_id = usage_tracking.tenant_id)` |

---

### `public.ratings`

| Policy Name | Command | Condition |
|---|---|---|
| `ratings_tenant_admin_select` | SELECT | `EXISTS (SELECT 1 FROM tenant_users WHERE user_id = auth.uid() AND tenant_id = ratings.tenant_id)` |
| `ratings_branch_manager_select` | SELECT | `EXISTS (SELECT 1 FROM branch_users WHERE user_id = auth.uid() AND branch_id = ratings.branch_id AND role = 'branch_manager')` |

---

## Trigger Contract

### `prevent_role_conflict` on `public.branch_users`

```
TRIGGER: prevent_role_conflict
TIMING:  BEFORE INSERT
TABLE:   public.branch_users
FOR:     EACH ROW
ACTION:
  1. Resolve tenant_id from branches where id = NEW.branch_id
  2. Check if NEW.user_id exists in tenant_users for that tenant_id
  3. IF yes → RAISE EXCEPTION 'User is already a tenant_admin for this tenant. Role conflict not allowed.'
  4. ELSE → allow INSERT to proceed
```

---

## Policy Count Summary

| Table | Policies |
|---|---|
| tenants | 2 |
| branches | 4 |
| tenant_users | 1 |
| branch_users | 4 |
| orders | 4 |
| offers | 2 |
| branch_offers | 2 |
| subscriptions | 2 |
| usage_tracking | 1 |
| ratings | 2 |
| **Total** | **24** |
