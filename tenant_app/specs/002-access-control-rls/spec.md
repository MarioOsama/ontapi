# Feature Specification: Access Control & Row Level Security

**Feature Branch**: `002-access-control-rls`  
**Created**: 2026-02-28  
**Status**: Clarified  
**Input**: User description: "Phase 2 – Implement Access Control and Row Level Security (RLS) policies for the Tenant App, covering tenant_admin, branch_manager, and branch_staff roles across all database tables"

---

## Clarifications

### Session 2026-03-01

- Q: When an unauthorized read or write is attempted, should the system return a distinct access-denied signal or silently return nothing? → A: Silent empty result — unauthorized reads return zero rows, unauthorized writes are dropped with no error message surfaced to the caller.
- Q: Should access control policies for computed views and database functions (e.g., queue position calculation, analytics views) be included in this phase? → A: Out of scope — computed views and functions are excluded from Phase 2; they inherit the calling user's base-table permissions automatically. View/function-level policies are deferred to the phases where those resources are built.
- Q: When an admin changes or removes a user's role, when does the new access level take effect for an already-active session? → A: Immediately on the next request — role changes take effect without requiring re-authentication, because access decisions are evaluated per-request via a live membership lookup.
- Q: When a user simultaneously holds a Tenant Admin role and a Branch Staff role, should the system grant the broader access, block the conflict, or apply the narrower role? → A: Prevent the overlap — the system MUST reject adding a user to a conflicting role. A Tenant Admin cannot simultaneously be listed as a branch-level staff member for the same tenant; the conflict must be resolved before access is granted.
- Q: Should any internal role (Tenant Admin, Branch Manager, Branch Staff) be permitted to write to the ratings table, or should ratings be read-only for all internal users? → A: Read-only for all internal roles — no internal user can create, edit, or delete ratings. Ratings are written exclusively by the external customer-facing channel (e.g., a kiosk or public-facing endpoint), not by any staff role.
- EC1: What happens when a user has no entry in either membership table? → A: Zero access — treated identically to an unauthenticated user; all tables return empty results.
- EC2: What happens when a tenant is deleted? → A: Cascade delete — all associated records (branches, memberships, orders, ratings, etc.) are automatically removed.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Tenant Admin Has Full Access to Their Tenant's Data (Priority: P1)

A Tenant Admin signs in and can view and manage all data that belongs to their tenant — including branches, users, orders, offers, subscriptions, usage records, and ratings. They cannot see any data belonging to other tenants, even if they share the same platform.

**Why this priority**: This is the cornerstone of the multi-tenant security model. Every other access story depends on tenant boundaries being reliably enforced here first.

**Independent Test**: Can be fully tested by signing in as a Tenant Admin for Tenant A, querying every data resource, then confirming Tenant B's records return no results — delivers a verifiable tenant-isolation guarantee as a standalone outcome.

**Acceptance Scenarios**:

1. **Given** a Tenant Admin is authenticated for Tenant A, **When** they query any data resource (branches, orders, offers, subscriptions, ratings), **Then** only records belonging to Tenant A are returned.
2. **Given** a Tenant Admin is authenticated for Tenant A, **When** they attempt to read, create, update, or delete a record belonging to Tenant B, **Then** the operation is silently rejected and no data is returned.
3. **Given** a Tenant Admin is authenticated, **When** they create, update, or delete a branch within their tenant, **Then** the operation succeeds and is reflected immediately.
4. **Given** a Tenant Admin is authenticated, **When** they change or remove a user's role within their tenant, **Then** the new access level takes effect on that user's very next data request — no re-authentication is required.

---

### User Story 2 — Branch Manager Can Only Operate Within Their Assigned Branch (Priority: P2)

A Branch Manager signs in and can view and manage data within their assigned branch — orders placed at that branch, staff assigned to it, ratings received, and branch-level settings. They cannot access data from any other branch, even within the same tenant.

**Why this priority**: Branch isolation ensures that operational data (queues, orders, staff) cannot be cross-contaminated between locations. Without this, a manager at one branch could inadvertently affect or view another branch's live operations.

**Independent Test**: Can be fully tested by creating two branches under the same tenant, assigning a Branch Manager to Branch A only, and confirming they can operate on Branch A while Branch B returns no data — delivers branch-scoped access as a standalone verifiable outcome.

**Acceptance Scenarios**:

1. **Given** a Branch Manager is assigned to Branch A, **When** they query orders, staff, or ratings for Branch A, **Then** the correct records are returned.
2. **Given** a Branch Manager is assigned to Branch A, **When** they attempt to read or modify data from Branch B (within the same tenant), **Then** no data is returned and any write operation is rejected.
3. **Given** a Branch Manager is authenticated, **When** they attempt to modify tenant-wide resources such as subscription plans or global offers, **Then** those write operations are rejected.
4. **Given** a Branch Manager is authenticated, **When** they view tenant-wide offers relevant to their branch, **Then** they can read those offers but cannot edit or delete them.

---

### User Story 3 — Branch Staff Can Only Create and Update Orders (Priority: P3)

A Branch Staff member signs in and can create new orders and update the status of existing orders within their assigned branch. All other resources — offers, subscription data, branch configurations, ratings — are inaccessible to them.

**Why this priority**: Staff permissions are the narrowest in the system. Granting broader access would violate the principle of least privilege and expose operational and financial data to front-line workers with no need to see it.

**Independent Test**: Can be fully tested by authenticating as Branch Staff and confirming that order creation and status transitions succeed, while reads/writes on offers, subscriptions, and other branches' orders return nothing — delivers a minimal-privilege operational role as a standalone outcome.

**Acceptance Scenarios**:

1. **Given** a Branch Staff member is assigned to Branch A, **When** they create a new order for Branch A, **Then** the order is successfully created with status "waiting".
2. **Given** a Branch Staff member is assigned to Branch A, **When** they update the status of an order in Branch A (e.g., from waiting to in_progress), **Then** the update is persisted.
3. **Given** a Branch Staff member is authenticated, **When** they attempt to read offers, subscriptions, usage records, or ratings, **Then** no data is returned.
4. **Given** a Branch Staff member is assigned to Branch A, **When** they attempt to read or modify orders from Branch B, **Then** no data is returned.

---

### User Story 4 — Unauthenticated Users Cannot Access Any Data (Priority: P1)

Any visitor or client that is not signed in receives zero data from any table in the system, regardless of how they construct their request.

**Why this priority**: Deny-by-default for unauthenticated access is a non-negotiable baseline. This must be verified before any authenticated role tests are meaningful.

**Independent Test**: Can be fully tested by making unauthenticated read requests against all protected tables and asserting that every response returns an empty result set — delivers a verifiable security baseline independently.

**Acceptance Scenarios**:

1. **Given** a user is not signed in, **When** they attempt to query any table (tenants, branches, orders, offers, subscriptions, etc.), **Then** no records are returned.
2. **Given** a user is not signed in, **When** they attempt to insert, update, or delete any record, **Then** the operation is rejected.

---

### Edge Cases

- A user with no entry in either the tenant membership or branch membership tables is treated as having zero access — all tables return empty results, identical to the unauthenticated state.
- When a Branch Manager's branch assignment is removed, the change takes effect immediately on their next request — their active session loses access to that branch's data without requiring re-authentication.
- A user who is already a Tenant Admin for a given tenant cannot simultaneously be added to the branch membership table for any branch within that same tenant — the system must reject such a conflicting assignment.
- When a tenant record is deleted, all associated records are automatically removed in a cascade — including branches, tenant and branch membership records, orders, ratings, subscriptions, and usage tracking data.
- When a Branch Staff member attempts to create an order for a branch they are not assigned to, the write is silently dropped and zero confirmation is returned — consistent with the silent-rejection policy.

---

## Out of Scope

- Access control policies for computed database views (e.g., queue position views, analytics metric views) — these resources inherit the calling user's base-table permissions and do not require separate policies in this phase.
- Access control policies for database functions (e.g., stored procedures or RPC functions) — deferred to the phases where those functions are introduced.
- Application-layer or frontend role enforcement — this phase exclusively covers data-layer access control.
- Any new tables or resources introduced after Phase 1 — only the ten Phase 1 core tables are in scope.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST enforce access control on all database tables so that no user can read or modify data they are not authorized to access. Unauthorized read attempts MUST return zero rows (silent empty result); unauthorized write attempts MUST be silently dropped — no distinguishable error or access-denied signal SHALL be surfaced to the caller.
- **FR-002**: Tenant Admin access MUST be scoped exclusively to records belonging to their own tenant — across all tables, for all operations (read, create, update, delete).
- **FR-003**: Branch Manager access MUST be scoped to records belonging to their assigned branch. They MUST have read-only access to tenant-wide resources (e.g., offers) and to ratings for their branch. They MUST be able to add new `branch_staff` members to their own branch and remove them. They MUST NOT be permitted to create, edit, or delete ratings, tenant-wide resources, or add users with a `branch_manager` role — only a Tenant Admin can assign manager roles.
- **FR-004**: Branch Staff access MUST be limited to creating orders and updating order status within their assigned branch. All other tables and operations — including ratings — MUST be inaccessible.
- **FR-005**: Unauthenticated users MUST be denied all access to every table — no rows MUST be returned and no writes MUST be accepted.
- **FR-006**: Access control decisions MUST be determined solely by the authenticated user's identity and their membership in the tenant and branch membership tables. No external claims or application-layer checks SHALL substitute for this.
- **FR-007**: Access control MUST be applied to all ten core tables: tenants, branches, tenant membership, branch membership, orders, offers, branch-offer assignments, subscriptions, usage tracking records, and ratings.
- **FR-008**: If a user's membership record is absent from both membership tables, the system MUST default to denying all access.
- **FR-009**: All access control rules MUST be independently testable by simulating each of the three role personas (Tenant Admin, Branch Manager, Branch Staff) with dedicated test identities.
- **FR-010**: Access control rules MUST be enforced at the data layer and MUST NOT rely solely on frontend or application-layer enforcement.
- **FR-011**: The system MUST prevent a user from holding a Tenant Admin role and any branch-level role (branch_manager or branch_staff) within the same tenant simultaneously. Any attempt to create such a conflicting membership record MUST be rejected.
- **FR-012**: The ratings table MUST be read-only for all internal roles (Tenant Admin, Branch Manager, Branch Staff). No internal user may create, edit, or delete a rating record. Write access to ratings is reserved exclusively for the external customer-facing channel.

### Key Entities

- **Tenant**: The top-level organizational unit. All data is partitioned by tenant. A tenant may own multiple branches.
- **Branch**: An operational sub-unit within a tenant. Orders, staff assignments, and ratings are scoped to a branch.
- **Tenant Membership (tenant_admin role)**: Records that link a user identity to a tenant and designate them as the Tenant Admin — granting full access to all tenant-owned data.
- **Branch Membership (branch_manager / branch_staff roles)**: Records that link a user identity to a specific branch and designate their operational role — determining which tables and operations they can perform within that branch.
- **Access Policy**: A declarative rule attached to each table that filters or blocks rows based on the requesting user's identity and their verified role through the membership tables.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of the ten core data tables have access control enabled with at least one enforcing policy — confirmed by a policy coverage audit with zero gaps.
- **SC-002**: A Tenant Admin user receives all records belonging to their tenant across every table, and zero records belonging to any other tenant, in 100% of test cases.
- **SC-003**: A Branch Manager user receives records only from their assigned branch and receives zero records from any other branch — across all targeted tables — in 100% of test cases.
- **SC-004**: A Branch Staff user can successfully create an order and transition its status within their branch, and receives empty results for every other table and operation, in 100% of test cases.
- **SC-005**: All unauthenticated access attempts return zero records across all ten tables — verified with no active session token present.
- **SC-006**: Security verification with three distinct test identities (one per role) completes with zero unauthorized data exposures detected.
- **SC-007**: All ten tables pass a role-based access audit with no missing or overly permissive policies found.

---

## Assumptions

- The ten core database tables from Phase 1 (Database Foundation) are already created, populated with test data, and available — this phase depends on their existence.
- Access control is determined exclusively through relational lookups on the tenant membership and branch membership tables using the authenticated user's identity — no external token claims or application-layer role flags are used.
- A single user cannot simultaneously hold a Tenant Admin role and a branch-level role (branch_manager or branch_staff) within the same tenant. The system prevents such overlapping assignments at creation time; no silent role-precedence resolution occurs.
- Deny-by-default is the system's baseline: if no access policy explicitly grants a row to a user, that row is not returned.
- Security testing will use dedicated test user identities created specifically to simulate each of the three role personas.
- Branch Managers are granted read-only visibility into tenant-wide offers and branch-scoped ratings to support operational awareness. They cannot write to either resource.
- Ratings are written exclusively by an external customer-facing channel (e.g., a kiosk or public endpoint) and are outside the scope of internal role access. This phase only enforces that internal roles cannot modify ratings.
- Access control is enforced at the data layer, making it effective regardless of which client (web, mobile, API) accesses the data.
- Computed views and database functions are out of scope for this phase. They naturally inherit the row-level access of the authenticated caller through base-table policies set in this phase, requiring no additional policy work here.
