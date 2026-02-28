# Feature Specification: Database Foundation

**Feature Branch**: `001-database-foundation`  
**Created**: 2026-02-26  
**Status**: Draft  
**Input**: User description: "Phase 1 — Database Foundation from implementation_plan.md: Create all core tables, define constraints, indexes, enums, foreign key relationships, and unique constraints for the Ontapi tenant app."

## Clarifications

### Session 2026-02-27

- Q: When a tenant or branch is deleted, what should happen to dependent records? → A: CASCADE on tenant → branches/orders/offers (full wipe); RESTRICT on user mappings.
- Q: Should orders support soft-delete via a `deleted_at` column? → A: No. Hard-delete only for Phase 1; data retention and archival handled in Phase 9.
- Q: Should the database enforce a minimum value on `avg_service_duration`? → A: Yes. CHECK constraint requiring value > 0 (positive integer only).
- Q: Should the system enforce a single rating per order? → A: Yes. Unique constraint on `order_id` in ratings table (one rating per order).
- Q: Should `order_number` be unique per branch at the database level? → A: No. Uniqueness is per branch per day, enforced at the application level. Numbers reset daily.
- Q: Should a tenant have only one subscription record or multiple? → A: Multiple. One active (`is_active = true`) for the current period, plus inactive records for historical analytics.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Tenant Onboarding Data Storage (Priority: P1)

A new tenant signs up for Ontapi. The system must have a database structure capable of storing the tenant's identity (name, logo, description), their branches, and mapping users to both tenants and branches with appropriate roles.

**Why this priority**: Without core tables for tenants, branches, and user-role mappings, no other feature in the platform can function. This is the absolute foundation of the multi-tenant architecture.

**Independent Test**: Can be fully tested by inserting a tenant record, a branch record linked to that tenant, and user-role mapping records, then verifying all relationships and constraints hold.

**Acceptance Scenarios**:

1. **Given** an empty database with the schema applied, **When** a new tenant record is inserted with name, logo_url, and description, **Then** the record is persisted with an auto-generated UUID primary key and timestamps.
2. **Given** an existing tenant, **When** a branch is created with a reference to that tenant, **Then** the branch record is linked via foreign key and includes default avg_service_duration.
3. **Given** an existing tenant, **When** a user is mapped as `tenant_admin` in `tenant_users`, **Then** the mapping is persisted with valid foreign keys to both tenant and auth user.
4. **Given** an existing branch, **When** a user is mapped as `branch_manager` or `branch_staff` in `branch_users`, **Then** the mapping is persisted with valid foreign keys.
5. **Given** a branch with a non-existent tenant_id, **When** the insert is attempted, **Then** the database rejects the insert with a foreign key violation.

---

### User Story 2 - Order Lifecycle Data Storage (Priority: P1)

Branch staff create orders for customers entering the queue. The system must store each order's lifecycle — from creation (waiting) through service (in_progress) to completion (done) or cancellation (cancelled) — along with the source of the order (manual or API).

**Why this priority**: The order system is the core product value of Ontapi (queue management). Without the orders table and its constraints, the queue engine cannot operate.

**Independent Test**: Can be fully tested by inserting orders into a branch, transitioning statuses, and verifying all constraints (valid statuses, required foreign keys, timestamps) are enforced.

**Acceptance Scenarios**:

1. **Given** a branch belonging to a tenant, **When** an order is created with status `waiting` and source `manual`, **Then** the order is persisted with correct foreign keys and a `created_at` timestamp.
2. **Given** an order with status `waiting`, **When** status is updated to `in_progress`, **Then** the `started_at` timestamp is populated.
3. **Given** an order with status `in_progress`, **When** status is updated to `done`, **Then** the `completed_at` timestamp is populated.
4. **Given** an order, **When** an invalid status value (e.g., `expired`) is inserted, **Then** the database rejects the value with a constraint violation.
5. **Given** an order, **When** an invalid source value is inserted, **Then** the database rejects the value with a constraint violation.

---

### User Story 3 - Offer Management Data Storage (Priority: P2)

Tenant admins create promotional offers that can be tenant-wide (global) or assigned to specific branches. The system must store offer details and branch-offer associations.

**Why this priority**: Offers are a value-add feature that enhances the tenant's ability to engage with customers, but the platform can function without them initially.

**Independent Test**: Can be fully tested by creating offers, associating them with branches, and verifying global vs. branch-specific behavior through data queries.

**Acceptance Scenarios**:

1. **Given** a tenant, **When** a global offer is created with `is_global = true`, **Then** the offer is persisted and accessible to all branches by default.
2. **Given** a tenant, **When** a branch-specific offer is created with `is_global = false` and linked to a branch via `branch_offers`, **Then** the association is persisted with valid foreign keys.
3. **Given** a non-existent offer_id, **When** a `branch_offers` record references it, **Then** the database rejects the insert.

---

### User Story 4 - Subscription & Usage Tracking Data Storage (Priority: P2)

The platform enforces volume-based subscription limits. The system must store each tenant's subscription history — one active plan for the current period and inactive records for previous periods — along with monthly order limits, billing periods, and monthly usage counts. Historical subscription records enable SaaS analytics and reporting.

**Why this priority**: Subscription enforcement is essential for the business model, but the database schema can be created and validated independently of the enforcement logic.

**Independent Test**: Can be fully tested by inserting subscription records and usage tracking records, verifying period boundaries, and testing limit-related queries.

**Acceptance Scenarios**:

1. **Given** a tenant, **When** a subscription record is created with plan_name, monthly_order_limit, period dates, and `is_active = true`, **Then** the record is persisted with valid foreign keys.
2. **Given** a tenant with an active subscription, **When** the subscription period ends and a new plan begins, **Then** the previous subscription is marked `is_active = false` and a new active subscription record is created.
3. **Given** a tenant, **When** a usage_tracking record is inserted for a specific month (YYYY-MM format), **Then** the orders_count defaults to zero and can be incremented.
4. **Given** a tenant with an existing usage record for a month, **When** a duplicate month record is attempted, **Then** the database rejects it with a unique constraint violation.
5. **Given** a tenant, **When** multiple subscription records exist, **Then** only one has `is_active = true` at any time (enforced at the application level).

---

### User Story 5 - Customer Ratings Data Storage (Priority: P3)

Customers rate their service experience after an order is completed. The system must store individual ratings (1–5 scale) and optional feedback, linked to specific orders.

**Why this priority**: Ratings are a feedback mechanism that enhances analytics but are not critical to the core queue operation.

**Independent Test**: Can be fully tested by inserting rating records linked to completed orders and verifying constraint enforcement on rating values and foreign keys.

**Acceptance Scenarios**:

1. **Given** a completed order, **When** a rating (1–5) with optional feedback is submitted, **Then** the rating is persisted with valid foreign keys to tenant, branch, and order.
2. **Given** a rating value outside 1–5 range, **When** the insert is attempted, **Then** the database rejects it with a check constraint violation.
3. **Given** a non-existent order_id, **When** a rating references it, **Then** the database rejects it with a foreign key violation.

---

### Edge Cases

- When a tenant is deleted, all dependent data records (branches, orders, offers, branch_offers, subscriptions, usage_tracking, ratings) are automatically removed via CASCADE. User mappings (tenant_users, branch_users) are protected by RESTRICT and must be removed first.
- How does the system handle concurrent inserts into `usage_tracking` for the same tenant and month?
- What happens when an order is created for a branch that has been deleted or deactivated?
- How are timestamps handled across different time zones? All timestamps must use `timestamptz` (UTC-aware).
- `avg_service_duration` must be a positive integer (> 0); enforced by a CHECK constraint. Zero or negative values are rejected at the database level.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST store tenant information including name, logo URL, description, and creation/update timestamps.
- **FR-002**: System MUST store branch information linked to a tenant, including name, address, and average service duration.
- **FR-003**: System MUST map users to tenants via `tenant_users` with role assignment (tenant_admin).
- **FR-004**: System MUST map users to branches via `branch_users` with role assignment (branch_manager, branch_staff).
- **FR-005**: System MUST store orders with status tracking (waiting, in_progress, done, cancelled), source tracking (manual, api), and lifecycle timestamps.
- **FR-006**: System MUST enforce valid values for order status and order source through database-level constraints.
- **FR-007**: System MUST store offers with global/branch-specific scope, active/inactive state, and image support.
- **FR-008**: System MUST support associating offers to specific branches via a junction table.
- **FR-009**: System MUST store subscription plans with monthly order limits, billing period boundaries, and an active/inactive status (`is_active`). Multiple subscription records per tenant are supported to preserve history for analytics.
- **FR-010**: System MUST track monthly order usage per tenant with a unique constraint on tenant + month combination.
- **FR-011**: System MUST store customer ratings (1–5 scale) with optional text feedback, linked to specific orders, branches, and tenants.
- **FR-012**: System MUST enforce rating value range (1–5) through a check constraint.
- **FR-013**: System MUST enforce referential integrity via foreign key constraints on all relationship columns.
- **FR-014**: System MUST auto-generate UUID primary keys for all tables.
- **FR-015**: System MUST auto-populate `created_at` timestamps on record creation and `updated_at` on modification.
- **FR-016**: System MUST optimize read performance by indexing `tenant_id`, `branch_id`, and `user_id` columns on all relevant tables.
- **FR-017**: System MUST enforce uniqueness on tenant-user, branch-user, and tenant-month usage combinations to prevent duplicate mappings.
- **FR-018**: System MUST CASCADE delete from tenants to all data tables (branches, orders, offers, branch_offers, subscriptions, usage_tracking, ratings) and RESTRICT delete on user mapping tables (tenant_users, branch_users) — requiring explicit user removal before tenant deletion.
- **FR-019**: System MUST enforce `avg_service_duration` as a positive integer (> 0) via a CHECK constraint on the branches table.
- **FR-020**: System MUST enforce one rating per order via a unique constraint on `order_id` in the ratings table.

### Key Entities

- **Tenant**: The top-level organizational unit. Has a name, branding (logo, description), and owns all branches, users, orders, offers, subscriptions, and ratings under it.
- **Branch**: A physical or logical location belonging to a tenant where queue operations occur. Has operational settings like average service duration.
- **Tenant User**: A mapping between a user and a tenant with an assigned role (tenant_admin). Controls tenant-level access.
- **Branch User**: A mapping between a user and a branch with an assigned role (branch_manager or branch_staff). Controls branch-level access.
- **Order**: A queue entry within a branch. Tracks lifecycle from creation to completion/cancellation, with timestamps at each stage.
- **Offer**: A promotional item that can be global (tenant-wide) or specific to certain branches via the Branch Offer association.
- **Branch Offer**: A junction entity linking an offer to a specific branch.
- **Subscription**: Defines a tenant's plan for a specific period, including the monthly order limit, billing period dates, and active/inactive status. Multiple records per tenant track subscription history for SaaS analytics.
- **Usage Tracking**: Records the monthly count of completed orders per tenant, used for subscription enforcement.
- **Rating**: Customer feedback for a completed order, linking a numeric score and optional text to a specific order, branch, and tenant. Limited to one rating per order (unique on order_id).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All 10 core tables (tenants, branches, tenant_users, branch_users, orders, offers, branch_offers, subscriptions, usage_tracking, ratings) are created and accept valid data inserts within 1 second each.
- **SC-002**: 100% of foreign key relationships reject invalid references immediately upon insert/update attempt.
- **SC-003**: 100% of enum-like fields (order status, order source, user roles) reject invalid values at the database level.
- **SC-004**: Check constraints on ratings (1–5 range) reject out-of-range values with zero data corruption.
- **SC-005**: Unique constraints prevent duplicate tenant-user, branch-user, and tenant-month usage records with 100% reliability.
- **SC-006**: Query performance on indexed columns (tenant_id, branch_id, user_id) returns results for datasets of 100,000+ records in under 1 second.
- **SC-007**: Timestamps are consistently stored in UTC-aware format across all tables.
- **SC-008**: The complete schema can be applied to a fresh database without errors in a single migration.

## Assumptions

- The authentication system (Supabase Auth) and `auth.users` table already exist and are managed externally; this schema only references `auth.users` via foreign keys.
- UUID generation is handled by the database (e.g., `gen_random_uuid()` or equivalent default).
- Timestamp defaults (`now()`) are applied at the database level, not the application level.
- The `avg_service_duration` field stores values in minutes as a positive integer.
- Order status transitions are enforced by the application layer, not by database triggers (Phase 1 focuses on schema, not business logic).
- `order_number` uniqueness is enforced at the application level (unique per branch per day, with daily resets). No database-level unique constraint on `order_number`.
- RLS policies are out of scope for this phase and will be addressed in Phase 2.
- Foreign key delete rules: CASCADE for data tables (branches, orders, offers, branch_offers, subscriptions, usage_tracking, ratings) when parent tenant/branch is deleted; RESTRICT for user mapping tables (tenant_users, branch_users) to require explicit user removal first.
- No soft-delete columns (e.g., `deleted_at`) in Phase 1. All deletes are hard-deletes. Historical data preservation is deferred to Phase 9 (Data Retention).
- The `month` field in `usage_tracking` uses the format `YYYY-MM` as a text field for simplicity and query readability.

## Out of Scope

- Row Level Security (RLS) policies — covered in Phase 2.
- Application-level business logic (order status transitions, subscription enforcement) — covered in later phases.
- Realtime subscriptions and live data streaming — covered in Phase 6.
- Analytics views and materialized views — covered in Phase 8.
- Data retention and cleanup jobs — covered in Phase 9.
- UI/Frontend implementation — covered in Phases 3–5.
