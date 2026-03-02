# Tasks: Access Control & Row Level Security

**Input**: Design documents from `specs/002-access-control-rls/`  
**Branch**: `002-access-control-rls` | **Date**: 2026-03-01  
**Prerequisites**: plan.md ✅ | spec.md ✅ | data-model.md ✅ | contracts/ ✅ | research.md ✅ | quickstart.md ✅

**Tests**: Not requested — no test tasks generated.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the migration file scaffold and verify the Phase 1 baseline is applied.

- [x] T001 Verify Phase 1 migration (`20260228101405_database_foundation.sql`) is applied and all 10 tables exist in the local Supabase environment (`supabase/migrations/20260228101405_database_foundation.sql`)
- [x] T002 Create new migration file `supabase/migrations/20260301123647_access_control_rls.sql` with a header comment block identifying the phase, date, and scope

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Enable RLS and the deny-by-default baseline on all 10 tables. No user story policies can work before this is done.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T003 Enable RLS (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`) on `public.tenants` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T004 [P] Enable RLS on `public.branches` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T005 [P] Enable RLS on `public.tenant_users` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T006 [P] Enable RLS on `public.branch_users` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T007 [P] Enable RLS on `public.orders` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T008 [P] Enable RLS on `public.offers` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T009 [P] Enable RLS on `public.branch_offers` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T010 [P] Enable RLS on `public.subscriptions` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T011 [P] Enable RLS on `public.usage_tracking` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T012 [P] Enable RLS on `public.ratings` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T013 Apply `FORCE ROW LEVEL SECURITY` on all 10 tables to prevent table-owner bypass in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T014 Run `supabase db reset` and verify all 10 tables return zero rows for an unauthenticated request (deny-by-default confirmed)

**Checkpoint**: All 10 tables have RLS enabled and deny all unauthenticated access. User story policy implementation can now begin.

---

## Phase 3: User Story 4 — Unauthenticated Deny (Priority: P1) 🎯 MVP Baseline

> US4 is P1 in the spec alongside US1, but logically it is validated here since Foundational phase already achieves it.

**Goal**: Confirm no unauthenticated user can read or write any table.

**Independent Test**: Make unauthenticated read requests against all 10 tables after T014 — all must return zero rows.

- [x] T015 [US4] Document unauthenticated test result in `specs/002-access-control-rls/quickstart.md` — confirm deny-by-default verified for all 10 tables after `supabase db reset`

**Checkpoint**: US4 complete and verified — zero unauthenticated access confirmed.

---

## Phase 4: User Story 1 — Tenant Admin Full Access (Priority: P1) 🎯 MVP

**Goal**: A Tenant Admin can read and manage all data within their tenant, and sees zero data from other tenants.

**Independent Test**: Sign in as tenant_admin for Tenant A — all 10 tables return only Tenant A records. Querying as a tenant_admin for Tenant B returns zero Tenant A records.

### Implementation for User Story 1

- [x] T016 [US1] Add `tenants_tenant_admin_all` policy (ALL operations, tenant-scoped USING) to `public.tenants` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T017 [P] [US1] Add `tenant_users_tenant_admin_all` policy (ALL operations, tenant-scoped USING — self-referential subquery) to `public.tenant_users` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T018 [P] [US1] Add `branches_tenant_admin_all` policy (ALL operations, tenant-scoped via `branches.tenant_id`) to `public.branches` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T019 [P] [US1] Add `branch_users_tenant_admin_all` policy (ALL operations, tenant-scoped via `branches` JOIN) to `public.branch_users` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T020 [P] [US1] Add `orders_tenant_admin_select` policy (SELECT only, tenant-scoped) to `public.orders` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T021 [P] [US1] Add `offers_tenant_admin_all` policy (ALL operations, tenant-scoped) to `public.offers` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T022 [P] [US1] Add `branch_offers_tenant_admin_all` policy (ALL operations, tenant-scoped via `branches` JOIN) to `public.branch_offers` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T023 [P] [US1] Add `subscriptions_tenant_admin_select_update` policy (SELECT + UPDATE, tenant-scoped) to `public.subscriptions` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T024 [P] [US1] Add `usage_tracking_tenant_admin_select` policy (SELECT only, tenant-scoped) to `public.usage_tracking` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T025 [P] [US1] Add `ratings_tenant_admin_select` policy (SELECT only, tenant-scoped) to `public.ratings` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T026 [US1] Run `supabase db reset`, create two test tenants (A and B), sign in as tenant_admin for Tenant A, and verify: all Tenant A records returned across all tables, zero Tenant B records returned

**Checkpoint**: US1 complete — Tenant Admin has full scoped access. 10 policies added.

---

## Phase 5: User Story 2 — Branch Manager Branch-Scoped Access (Priority: P2)

**Goal**: A Branch Manager can operate on their branch only, with read-only access to offers and ratings, and can manage their branch's staff.

**Independent Test**: Sign in as branch_manager for Branch A (Tenant A) — Branch A data returned, Branch B data returns zero, offer modifications rejected, staff can be added/removed.

### Implementation for User Story 2

- [x] T027 [US2] Add `tenants_branch_manager_select` policy (SELECT only, tenant resolved via `branch_users` → `branches` JOIN) to `public.tenants` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T028 [P] [US2] Add `branches_branch_manager_select_update` policy (SELECT + UPDATE, own branch via `branch_users`) to `public.branches` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T029 [P] [US2] Add `branch_users_branch_manager_select` policy (SELECT, own branch) to `public.branch_users` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T030 [P] [US2] Add `branch_users_branch_manager_insert_staff` policy (INSERT with `WITH CHECK (NEW.role = 'branch_staff')`, own branch) to `public.branch_users` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T031 [P] [US2] Add `branch_users_branch_manager_delete_staff` policy (DELETE scoped to `branch_users.role = 'branch_staff'` rows, own branch) to `public.branch_users` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T032 [P] [US2] Add `orders_branch_manager_select_update` policy (SELECT + UPDATE, own branch via `branch_users`) to `public.orders` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T033 [P] [US2] Add `offers_branch_manager_select` policy (SELECT only, own tenant via `branch_users` → `branches` JOIN) to `public.offers` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T034 [P] [US2] Add `branch_offers_branch_manager_select` policy (SELECT only, own branch via `branch_users`) to `public.branch_offers` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T035 [P] [US2] Add `ratings_branch_manager_select` policy (SELECT only, own branch via `branch_users`) to `public.ratings` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T036 [US2] Run `supabase db reset`, sign in as branch_manager for Branch A, and verify: Branch A orders/staff/ratings returned, Branch B returns zero, offer INSERT rejected, branch_manager INSERT into `branch_users` rejected, branch_staff INSERT succeeds

**Checkpoint**: US2 complete — Branch Manager has correct scoped access. 9 policies added.

---

## Phase 6: User Story 3 — Branch Staff Order Operations (Priority: P3)

**Goal**: A Branch Staff member can create orders and update order status within their branch only. All other tables return zero rows.

**Independent Test**: Sign in as branch_staff for Branch A — order INSERT and UPDATE succeed, all other tables return zero rows, orders from Branch B return zero.

### Implementation for User Story 3

- [x] T037 [US3] Add `branches_branch_staff_select` policy (SELECT only, own branch via `branch_users`) to `public.branches` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T038 [P] [US3] Add `orders_branch_staff_select_insert_update` policy (SELECT + INSERT + UPDATE, own branch via `branch_users` with role = `branch_staff`) to `public.orders` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T039 [US3] Run `supabase db reset`, sign in as branch_staff for Branch A, and verify: order INSERT succeeds (status = 'waiting'), order status UPDATE succeeds, SELECT on offers/subscriptions/ratings/branch_offers/tenant_users returns zero rows, INSERT on any other table is silently dropped

**Checkpoint**: US3 complete — Branch Staff has minimal-privilege access. 2 policies added.

---

## Phase 7: Role-Conflict Prevention (FR-011) — Cross-Cutting

**Purpose**: Prevent any user from simultaneously holding a tenant_admin and branch-level role within the same tenant. Applies across all user stories.

- [x] T040 Implement `prevent_role_conflict` trigger function in `supabase/migrations/20260301123647_access_control_rls.sql`: BEFORE INSERT on `public.branch_users`, resolve `tenant_id` from `branches` for `NEW.branch_id`, assert `NEW.user_id` does not exist in `tenant_users` for that tenant, raise exception if conflict found
- [x] T041 Attach `prevent_role_conflict` as a `BEFORE INSERT FOR EACH ROW` trigger on `public.branch_users` in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T042 Run `supabase db reset`, attempt to INSERT a `tenant_admin` user into `branch_users` for a branch within their tenant, and verify the exception is raised and the INSERT is rejected

**Checkpoint**: Role-conflict prevention live. 1 trigger function + 1 trigger added.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [x] T043 [P] Audit the completed migration file — verify all 10 tables have `ENABLE ROW LEVEL SECURITY` and `FORCE ROW LEVEL SECURITY` statements in `supabase/migrations/20260301123647_access_control_rls.sql`
- [x] T044 [P] Count and verify all 21 named policies exist in the migration file against the contract in `specs/002-access-control-rls/contracts/rls-policy-matrix.md`
- [x] T045 Run the full 5-persona test suite from `specs/002-access-control-rls/quickstart.md` (tenant_admin A, branch_manager A, branch_staff A, roleless user, cross-tenant admin B) and confirm zero unauthorized data exposures
- [x] T046 [P] Update `specs/002-access-control-rls/checklists/requirements.md` — mark all SC-001 through SC-007 items as verified with test pass/fail evidence
- [x] T047 [P] Add a comment header to the migration file documenting the 21 policies and 1 trigger for future auditing in `supabase/migrations/20260301123647_access_control_rls.sql`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — BLOCKS all user story phases
- **Phase 3 (US4 baseline)**: Depends on Phase 2 — validates deny-by-default
- **Phase 4 (US1)**: Depends on Phase 2 — can run alongside Phase 5, 6
- **Phase 5 (US2)**: Depends on Phase 2 — can run alongside Phase 4, 6
- **Phase 6 (US3)**: Depends on Phase 2 — can run alongside Phase 4, 5
- **Phase 7 (Role-Conflict)**: Depends on Phase 2 — can run alongside Phase 4, 5, 6
- **Phase 8 (Polish)**: Depends on Phases 3–7 all complete

### User Story Dependencies

All user stories are **independent** after Phase 2. Since every policy is a separate SQL statement in the same migration file, they do not conflict.

- **US1 (P1)**: No dependency on US2/US3
- **US2 (P2)**: No dependency on US1/US3
- **US3 (P3)**: No dependency on US1/US2
- **US4 (P1)**: Validated by Phase 2 outcome — no additional implementation tasks

### Within Each User Story

- T003–T013 (RLS enable) → must precede all policy tasks
- Policy tasks within a story (marked [P]) → can run in parallel
- Verification task within each story → must be last within that story's phase

---

## Parallel Example: User Story 1 (Phase 4)

After T015 (US4 checkpoint), all US1 tasks can run in parallel:

```text
T016  tenants_tenant_admin_all
T017  tenant_users_tenant_admin_all   ← parallel
T018  branches_tenant_admin_all       ← parallel
T019  branch_users_tenant_admin_all   ← parallel
T020  orders_tenant_admin_select      ← parallel
T021  offers_tenant_admin_all         ← parallel
T022  branch_offers_tenant_admin_all  ← parallel
T023  subscriptions_tenant_admin_select_update  ← parallel
T024  usage_tracking_tenant_admin_select        ← parallel
T025  ratings_tenant_admin_select               ← parallel
→ T026 (verify — sequential, must be last)
```

---

## Implementation Strategy

### MVP First (Phase 2 + US4 + US1 Only)

1. Complete Phase 1: Setup (T001–T002)
2. Complete Phase 2: Foundational (T003–T014) — enables deny-by-default
3. Complete Phase 3: US4 validated (T015)
4. Complete Phase 4: US1 (T016–T026)
5. **STOP and VALIDATE**: Tenant Admin isolation working end-to-end
6. Proceed to remaining phases incrementally

### Incremental Delivery

1. Phase 1 + 2 → Deny-by-default live (testable)
2. Phase 4 (US1) → Tenant Admin fully operational (MVP!)
3. Phase 5 (US2) → Branch Manager operational
4. Phase 6 (US3) → Branch Staff operational
5. Phase 7 → Role-conflict protection live
6. Phase 8 → Full audit and polish

---

## Summary

| Phase | User Story | Tasks | Policies/Objects Added |
|---|---|---|---|
| 1 — Setup | — | 2 | 0 |
| 2 — Foundational | — | 12 | RLS enabled on 10 tables |
| 3 — US4 Baseline | US4 (P1) | 1 | 0 (validated via Phase 2) |
| 4 — Tenant Admin | US1 (P1) | 11 | 10 policies |
| 5 — Branch Manager | US2 (P2) | 10 | 9 policies |
| 6 — Branch Staff | US3 (P3) | 3 | 2 policies |
| 7 — Role Conflict | FR-011 | 3 | 1 trigger function + 1 trigger |
| 8 — Polish | — | 5 | 0 |
| **Total** | | **47** | **21 policies + 1 trigger** |

## Notes

- [P] tasks = different policy statements, no file conflicts, safe to parallelize
- All policies land in the single migration file — only one file modified throughout
- Each user story phase ends with a `supabase db reset` + manual verification step
- Role personas from `quickstart.md` should be set up before Phase 4 verification
- Commit after each phase checkpoint, not after individual tasks
