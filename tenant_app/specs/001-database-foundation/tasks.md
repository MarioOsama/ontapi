# Tasks: Database Foundation

**Input**: Design documents from `specs/001-database-foundation/`  
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)
- All paths relative to `supabase/migrations/001_database_foundation.sql` unless noted

---

## Phase 1: Setup

**Purpose**: Initialize Supabase migration file and enable required extensions

- [x] T001 Create migration file at `supabase/migrations/001_database_foundation.sql` with header comment block
- [x] T002 Enable required PostgreSQL extensions (`moddatetime` for auto-updating `updated_at` timestamps) in `supabase/migrations/001_database_foundation.sql`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create core tables that ALL user stories depend on — `tenants` and `branches`

**⚠️ CRITICAL**: No user story tables can be created until these exist (foreign key dependencies)

- [x] T003 Create `tenants` table with columns: `id` (uuid PK, default `gen_random_uuid()`), `name` (text NOT NULL), `logo_url` (text), `description` (text), `created_at` (timestamptz NOT NULL, default `now()`), `updated_at` (timestamptz NOT NULL, default `now()`) in `supabase/migrations/001_database_foundation.sql`
- [x] T004 Create `moddatetime` trigger on `tenants` to auto-update `updated_at` on row modification in `supabase/migrations/001_database_foundation.sql`
- [x] T005 Create `branches` table with columns: `id` (uuid PK, default `gen_random_uuid()`), `tenant_id` (uuid FK → tenants.id ON DELETE CASCADE, NOT NULL), `name` (text NOT NULL), `address` (text), `avg_service_duration` (int NOT NULL, CHECK > 0), `created_at` (timestamptz NOT NULL, default `now()`), `updated_at` (timestamptz NOT NULL, default `now()`) in `supabase/migrations/001_database_foundation.sql`
- [x] T006 Create `moddatetime` trigger on `branches` to auto-update `updated_at` in `supabase/migrations/001_database_foundation.sql`
- [x] T007 Create index on `branches.tenant_id` in `supabase/migrations/001_database_foundation.sql`

**Checkpoint**: `tenants` and `branches` tables ready — user story phases can now begin

---

## Phase 3: User Story 1 — Tenant Onboarding Data Storage (Priority: P1) 🎯 MVP

**Goal**: Store tenant identity, branches, and user-role mappings with full referential integrity

**Independent Test**: Insert a tenant, a branch linked to it, and user-role mapping records — verify all relationships and constraints hold

### Implementation for User Story 1

- [x] T008 [P] [US1] Create `tenant_users` table with columns: `id` (uuid PK, default `gen_random_uuid()`), `tenant_id` (uuid FK → tenants.id ON DELETE RESTRICT, NOT NULL), `user_id` (uuid FK → auth.users.id ON DELETE CASCADE, NOT NULL), `role` (text NOT NULL, CHECK IN ('tenant_admin')), UNIQUE(`tenant_id`, `user_id`) in `supabase/migrations/001_database_foundation.sql`
- [x] T009 [P] [US1] Create `branch_users` table with columns: `id` (uuid PK, default `gen_random_uuid()`), `branch_id` (uuid FK → branches.id ON DELETE RESTRICT, NOT NULL), `user_id` (uuid FK → auth.users.id ON DELETE CASCADE, NOT NULL), `role` (text NOT NULL, CHECK IN ('branch_manager', 'branch_staff')), UNIQUE(`branch_id`, `user_id`) in `supabase/migrations/001_database_foundation.sql`
- [x] T010 [P] [US1] Create indexes on `tenant_users.tenant_id`, `tenant_users.user_id`, `branch_users.branch_id`, `branch_users.user_id` in `supabase/migrations/001_database_foundation.sql`

**Checkpoint**: User Story 1 complete — tenant onboarding data model fully operational

---

## Phase 4: User Story 2 — Order Lifecycle Data Storage (Priority: P1) 🎯 MVP

**Goal**: Store orders with status tracking, source tracking, and lifecycle timestamps

**Independent Test**: Insert orders into a branch, transition statuses between `waiting`/`in_progress`/`done`/`cancelled`, and verify CHECK constraints reject invalid values

### Implementation for User Story 2

- [x] T011 [US2] Create `orders` table with columns: `id` (uuid PK, default `gen_random_uuid()`), `tenant_id` (uuid FK → tenants.id ON DELETE CASCADE, NOT NULL), `branch_id` (uuid FK → branches.id ON DELETE CASCADE, NOT NULL), `order_number` (text NOT NULL), `status` (text NOT NULL DEFAULT 'waiting', CHECK IN ('waiting', 'in_progress', 'done', 'cancelled')), `source` (text NOT NULL, CHECK IN ('manual', 'api')), `created_at` (timestamptz NOT NULL, default `now()`), `started_at` (timestamptz), `completed_at` (timestamptz) in `supabase/migrations/001_database_foundation.sql`
- [x] T012 [P] [US2] Create indexes on `orders.tenant_id` and `orders.branch_id` in `supabase/migrations/001_database_foundation.sql`

**Checkpoint**: User Story 2 complete — order lifecycle tracking fully operational

---

## Phase 5: User Story 3 — Offer Management Data Storage (Priority: P2)

**Goal**: Store tenant offers (global and branch-specific) with junction table for branch associations

**Independent Test**: Create global and branch-specific offers, associate with branches, verify FK constraints

### Implementation for User Story 3

- [x] T013 [P] [US3] Create `offers` table with columns: `id` (uuid PK, default `gen_random_uuid()`), `tenant_id` (uuid FK → tenants.id ON DELETE CASCADE, NOT NULL), `title` (text NOT NULL), `description` (text), `image_url` (text), `is_global` (boolean NOT NULL DEFAULT false), `is_active` (boolean NOT NULL DEFAULT true), `created_at` (timestamptz NOT NULL, default `now()`), `updated_at` (timestamptz NOT NULL, default `now()`) in `supabase/migrations/001_database_foundation.sql`
- [x] T014 [US3] Create `moddatetime` trigger on `offers` to auto-update `updated_at` in `supabase/migrations/001_database_foundation.sql`
- [x] T015 [US3] Create `branch_offers` junction table with columns: `id` (uuid PK, default `gen_random_uuid()`), `branch_id` (uuid FK → branches.id ON DELETE CASCADE, NOT NULL), `offer_id` (uuid FK → offers.id ON DELETE CASCADE, NOT NULL), UNIQUE(`branch_id`, `offer_id`) in `supabase/migrations/001_database_foundation.sql`
- [x] T016 [P] [US3] Create indexes on `offers.tenant_id`, `branch_offers.branch_id`, `branch_offers.offer_id` in `supabase/migrations/001_database_foundation.sql`

**Checkpoint**: User Story 3 complete — offer management data model fully operational

---

## Phase 6: User Story 4 — Subscription & Usage Tracking Data Storage (Priority: P2)

**Goal**: Store subscription plans with history (active/inactive) and monthly order usage tracking per tenant

**Independent Test**: Create subscription records, toggle `is_active`, insert usage tracking records, verify unique constraint on tenant+month

### Implementation for User Story 4

- [x] T017 [P] [US4] Create `subscriptions` table with columns: `id` (uuid PK, default `gen_random_uuid()`), `tenant_id` (uuid FK → tenants.id ON DELETE CASCADE, NOT NULL), `plan_name` (text NOT NULL), `monthly_order_limit` (int NOT NULL), `current_period_start` (date NOT NULL), `current_period_end` (date NOT NULL), `is_active` (boolean NOT NULL DEFAULT true), `created_at` (timestamptz NOT NULL, default `now()`) in `supabase/migrations/001_database_foundation.sql`
- [x] T018 [P] [US4] Create `usage_tracking` table with columns: `id` (uuid PK, default `gen_random_uuid()`), `tenant_id` (uuid FK → tenants.id ON DELETE CASCADE, NOT NULL), `month` (text NOT NULL), `orders_count` (int NOT NULL DEFAULT 0), UNIQUE(`tenant_id`, `month`) in `supabase/migrations/001_database_foundation.sql`
- [x] T019 [P] [US4] Create indexes on `subscriptions.tenant_id` and `usage_tracking.tenant_id` in `supabase/migrations/001_database_foundation.sql`

**Checkpoint**: User Story 4 complete — subscription and usage tracking fully operational

---

## Phase 7: User Story 5 — Customer Ratings Data Storage (Priority: P3)

**Goal**: Store customer ratings (1–5) with optional feedback, one per order

**Independent Test**: Insert ratings for completed orders, verify CHECK constraint rejects out-of-range values, verify unique constraint on `order_id`

### Implementation for User Story 5

- [x] T020 [US5] Create `ratings` table with columns: `id` (uuid PK, default `gen_random_uuid()`), `tenant_id` (uuid FK → tenants.id ON DELETE CASCADE, NOT NULL), `branch_id` (uuid FK → branches.id ON DELETE CASCADE, NOT NULL), `order_id` (uuid FK → orders.id ON DELETE CASCADE, NOT NULL, UNIQUE), `rating` (int NOT NULL, CHECK (rating >= 1 AND rating <= 5)), `feedback` (text), `created_at` (timestamptz NOT NULL, default `now()`) in `supabase/migrations/001_database_foundation.sql`
- [x] T021 [P] [US5] Create indexes on `ratings.tenant_id` and `ratings.branch_id` in `supabase/migrations/001_database_foundation.sql`

**Checkpoint**: User Story 5 complete — all 10 tables created

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Validation, verification, and documentation

- [x] T022 Run full migration on a fresh Supabase database and verify zero errors in `supabase/migrations/20260228101405_database_foundation.sql`
- [x] T023 [P] Validate all 10 tables exist via `information_schema.tables` query in Supabase SQL Editor
- [x] T024 [P] Validate all CHECK constraints by inserting invalid data (bad status, bad source, bad rating, negative duration)
- [x] T025 [P] Validate all UNIQUE constraints by inserting duplicate records (tenant_users, branch_users, usage_tracking month, branch_offers, ratings order_id)
- [x] T026 Validate CASCADE behavior: insert tenant → branch → orders → ratings, then delete tenant and verify all child data removed
- [x] T027 Validate RESTRICT behavior: insert tenant → tenant_user, attempt to delete tenant and verify it is blocked until user mapping removed
- [x] T028 [P] Validate all indexes exist via `pg_indexes` query
- [x] T029 Run quickstart.md test scenarios to verify end-to-end in Supabase SQL Editor

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — creates `tenants` and `branches`
- **User Stories (Phase 3–7)**: All depend on Phase 2 (FK references to tenants/branches)
  - US1 + US2 can run in parallel after Phase 2
  - US3 can run in parallel with US1/US2
  - US4 can run in parallel with US1/US2/US3
  - US5 depends on US2 (FK to orders.id)
- **Polish (Phase 8)**: Depends on all user stories complete

### User Story Dependencies

- **US1 (P1)**: Phase 2 only — no other story dependencies
- **US2 (P1)**: Phase 2 only — no other story dependencies
- **US3 (P2)**: Phase 2 only — no other story dependencies
- **US4 (P2)**: Phase 2 only — no other story dependencies
- **US5 (P3)**: Phase 2 + US2 (ratings references orders.id)

### Parallel Opportunities

```
Phase 2 complete
    ├── T008, T009, T010 (US1) ──┐
    ├── T011, T012 (US2) ────────┤── All can run in parallel
    ├── T013–T016 (US3) ─────────┤
    └── T017–T019 (US4) ─────────┘
                                  └── T020–T021 (US5) ← after US2 only
```

---

## Implementation Strategy

### MVP First (US1 + US2 only)

1. Complete Phase 1: Setup (T001–T002)
2. Complete Phase 2: Foundational (T003–T007)
3. Complete Phase 3: US1 — Tenant/user mappings (T008–T010)
4. Complete Phase 4: US2 — Orders (T011–T012)
5. **STOP and VALIDATE**: Run quickstart test insert/query
6. Deploy if ready — core queue management is functional

### Full Delivery

1. Setup + Foundational → Foundation ready
2. US1 + US2 → MVP functional (tenant + orders)3. US3 → Offers added
4. US4 → Subscription tracking added
5. US5 → Ratings added
6. Polish → Fully validated schema

---

## Notes

- All tasks target a single migration file: `supabase/migrations/001_database_foundation.sql`
- [P] tasks within a phase can be written in any order since they go into the same file sequentially
- Since this is a database-only feature, "parallel" means these SQL blocks have no ordering dependency
- Commit after each phase checkpoint
- Stop at any checkpoint to validate independently
- Total: **29 tasks** across 8 phases
