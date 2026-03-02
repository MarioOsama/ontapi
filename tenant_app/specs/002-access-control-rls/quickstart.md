# Quickstart: Access Control & RLS Implementation

**Branch**: `002-access-control-rls` | **Date**: 2026-03-01

---

## What This Phase Delivers

A single new Supabase migration that enables Row Level Security on all 10 Phase 1 tables and enforces the role-based access model defined in the spec. No Flutter code changes are needed.

---

## Prerequisites

- Phase 1 migration (`20260228101405_database_foundation.sql`) applied ✅
- Supabase CLI installed and local dev stack running (`supabase start`)
- At least one test user in each role created in the local dev environment

---

## Key Files

| File | Purpose |
|---|---|
| `specs/002-access-control-rls/plan.md` | This plan |
| `specs/002-access-control-rls/research.md` | Technical decisions and rationale |
| `specs/002-access-control-rls/data-model.md` | Full per-table RLS policy matrix |
| `specs/002-access-control-rls/contracts/rls-policy-matrix.md` | Named policy contract (drives migration) |
| `supabase/migrations/20260301123647_access_control_rls.sql` | Migration to be applied |

---

## Role Reference

| Role | Membership Table | Access Scope |
|---|---|---|
| `tenant_admin` | `tenant_users` | All data within own tenant |
| `branch_manager` | `branch_users` (role = branch_manager) | Own branch data + read-only offers/ratings |
| `branch_staff` | `branch_users` (role = branch_staff) | Orders in own branch only |
| Unauthenticated | — | Zero access |

---

## Test Personas Needed

Create these identities in local Supabase before running the security test suite:

1. **Admin User** → inserted into `tenant_users` with `role = 'tenant_admin'` for Tenant A
2. **Manager User** → inserted into `branch_users` with `role = 'branch_manager'` for Branch A (under Tenant A)
3. **Staff User** → inserted into `branch_users` with `role = 'branch_staff'` for Branch A (under Tenant A)
4. **Roleless User** → authenticated user with no entry in either membership table
5. **Cross-Tenant User** → a `tenant_admin` for a separate Tenant B (to test isolation)

---

## Verification Approach

After the migration is applied:

1. Run `supabase db reset` to apply all migrations fresh
2. Use `supabase test db` with SQL test scripts that SET ROLE / SET LOCAL to simulate each persona
3. For each table, assert:
   - Correct rows returned for authorized role
   - Zero rows returned for unauthorized role
   - Insert/update rejected silently for unauthorized role
4. Test role-conflict trigger: attempt to insert a `tenant_admin` user into `branch_users` and assert the exception is raised

---

## Next Step

Run `/speckit.tasks` to generate the implementation task list for this plan.
