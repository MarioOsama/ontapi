# Feature Specification: Authentication & Role Assignment

**Feature Branch**: `003-auth-role-assignment`  
**Created**: 2026-03-02  
**Status**: Clarified  
**Input**: User description: "Phase 3 — Authentication & Role Assignment: Self-service signup flow, auto-create tenant on signup, auto-create first branch, assign tenant_admin role, invite staff & assign branch roles"

---

## Clarifications

### Session 2026-03-02

- Q: Should pending invitations expire automatically, and if so, after how long? → A: Expire after 48 hours. The Tenant Admin can resend an expired invitation to generate a fresh 48-hour window.
- Q: When a user is a Tenant Admin for multiple tenants, how should the system determine which tenant context to load? → A: A user MUST NOT be a Tenant Admin for more than one tenant. The system enforces a one-tenant-admin-per-user constraint. Multi-tenant admin routing is therefore not applicable.
- Q: Can a Tenant Admin remove an already-accepted staff member from a branch? → A: Yes, Tenant Admin can remove any staff member (branch_manager or branch_staff) immediately. The removal takes effect on the staff member’s next request — no re-authentication required.
- Q: Should the invitation workflow use a new database table, or rely solely on signed tokens in the link? → A: Introduce a new `invitations` table in this phase. Persistent records are required to support listing pending invitations, revoking them, tracking expiry, and preventing duplicate acceptance.
- Q: Should the signup form collect the tenant/business name upfront, or default to a placeholder? → A: Collect the tenant name (business name) alongside email and password at signup. This avoids generic placeholder names and gives the admin a branded experience from the start.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — New User Signs Up and Becomes a Tenant Admin (Priority: P1)

A new user visits the Tenant App, creates an account through a self-service signup form (email, password, and business name), and upon successful registration the system automatically provisions a new tenant with the provided name, creates a default first branch under that tenant, and assigns the user the tenant_admin role — all in a single seamless flow. The user lands on their operational dashboard immediately, ready to configure their business.

**Why this priority**: This is the entry point to the entire platform. No other functionality can be used until a tenant exists with an admin who can manage it. Every downstream feature — branch management, orders, staff invitations — depends on this flow succeeding first.

**Independent Test**: Can be fully tested by completing the signup form with valid credentials and verifying that the user is authenticated, a new tenant record exists, a default branch is attached to that tenant, and the user is listed in the tenant membership table with the tenant_admin role — delivers a fully operational tenant as a standalone outcome.

**Acceptance Scenarios**:

1. **Given** a visitor is on the signup page, **When** they submit a valid email address, password, and business name, **Then** a new user account is created, a new tenant is provisioned with the provided business name, a default first branch ("Main Branch") is created under that tenant, and the user is assigned the tenant_admin role — all atomically.
2. **Given** a visitor submits a signup form with an email that is already registered, **When** the system processes the request, **Then** the signup is rejected with a clear error message indicating the email is already in use — no duplicate tenant or branch is created.
3. **Given** a visitor submits a signup form with an invalid email format or a password that does not meet minimum requirements, **When** the system validates the input, **Then** the signup is rejected immediately with a specific validation error — no account, tenant, or branch is created.
4. **Given** a new user has just completed signup, **When** the provisioning completes, **Then** the user is automatically signed in and directed to their dashboard — no additional login step is required.
5. **Given** a new user has completed signup, **When** they view their tenant dashboard, **Then** the tenant name displays the business name they entered during signup, and the first branch is named "Main Branch" — both editable later from settings.

---

### User Story 2 — Tenant Admin Invites Staff and Assigns Branch Roles (Priority: P2)

A Tenant Admin navigates to a staff management section, enters a new team member's email address, selects a target branch, and assigns them either the branch_manager or branch_staff role. The invited user receives an invitation (via email or a shareable link) and upon accepting, their account is linked to the specified branch with the assigned role — ready to operate within their scope immediately.

**Why this priority**: A single-person tenant has limited value. Inviting and assigning staff is the primary mechanism for scaling operations across branches. Without this, the queue system cannot function with multiple operators.

**Independent Test**: Can be fully tested by a Tenant Admin inviting a user to a branch with a specific role, having that user accept the invitation, and verifying the new user can access data scoped to their assigned branch and role — delivers a functional multi-user tenant as a standalone outcome.

**Acceptance Scenarios**:

1. **Given** a Tenant Admin is authenticated, **When** they invite a new user by email and assign them the branch_manager role for a specific branch, **Then** an invitation record is created and the invited user receives a notification (email or link) to join.
2. **Given** an invited user clicks the invitation link, **When** they create an account (or sign in if they already have one), **Then** they are automatically assigned to the specified branch with the designated role — no additional approval step is needed.
3. **Given** a Tenant Admin attempts to invite a user who is already a tenant_admin for the same tenant, **When** the system processes the invitation, **Then** the invitation is rejected — the system enforces the rule that a tenant_admin cannot simultaneously hold a branch-level role within the same tenant.
4. **Given** a Tenant Admin invites a user to a branch role, **When** the invitation is still pending (not yet accepted), **Then** the Tenant Admin can view, resend, or revoke the pending invitation.
5. **Given** a Tenant Admin assigns a branch_staff role to a new user for Branch A, **When** the user signs in after accepting the invitation, **Then** the user can only access data within Branch A and only perform actions permitted by the branch_staff role.

---

### User Story 3 — Invited User Accepts Invitation and Gains Access (Priority: P3)

An invited user receives an invitation to join a tenant's branch team. They click through the invitation link, which either directs them to sign up (if new) or sign in (if they already have a platform account). Upon successful authentication, the system automatically links their account to the correct branch with the pre-assigned role, and they can begin operating immediately.

**Why this priority**: This completes the invitation cycle. Without a smooth acceptance flow, invited users cannot onboard, making the invitation feature from Story 2 incomplete.

**Independent Test**: Can be fully tested by sending an invitation, opening the invitation link, completing authentication, and verifying the user's branch assignment and role permissions are correctly applied — delivers a complete invitation-to-access lifecycle as a standalone outcome.

**Acceptance Scenarios**:

1. **Given** a user has received a valid invitation link, **When** they open it and do not have an existing account, **Then** they are directed to a signup form pre-associated with the invitation — after registration their branch role is applied automatically.
2. **Given** a user has received a valid invitation link, **When** they open it and already have an existing account, **Then** they are directed to sign in — after authentication their branch role is applied automatically.
3. **Given** a user attempts to use an invitation link that has been revoked or has expired, **When** they open the link, **Then** they see a clear message indicating the invitation is no longer valid — no role assignment occurs.
4. **Given** a user attempts to use the same invitation link a second time, **When** the system processes the request, **Then** it recognizes the invitation has already been accepted and does not create a duplicate role assignment.

---

### User Story 4 — Tenant Admin Signs In to an Existing Account (Priority: P1)

A returning Tenant Admin opens the Tenant App and signs in using their email and password. The system authenticates them, resolves their tenant membership, and directs them to their operational dashboard — scoped to their tenant data.

**Why this priority**: Returning-user sign-in is a core daily flow. If the admin cannot reliably sign in and be routed to the correct tenant context, the app is unusable for repeat sessions.

**Independent Test**: Can be fully tested by signing in with valid Tenant Admin credentials and verifying the dashboard loads with the correct tenant context, and by attempting sign-in with incorrect credentials and confirming access is denied — delivers authenticated session management as a standalone outcome.

**Acceptance Scenarios**:

1. **Given** a registered Tenant Admin, **When** they enter valid email and password on the sign-in page, **Then** they are authenticated and redirected to their tenant dashboard.
2. **Given** any user, **When** they enter an incorrect email or password, **Then** they see a clear error message and are not signed in — no session is created.
3. **Given** a signed-in user, **When** they choose to sign out, **Then** their session is terminated and they are redirected to the sign-in page — subsequent requests return no data until re-authentication.

---

### User Story 5 — Branch Staff or Manager Signs In and Is Routed to Their Branch (Priority: P2)

A Branch Manager or Branch Staff member signs in using their email and password. The system authenticates them, resolves their branch membership, and routes them to the appropriate branch-scoped view — they see only data and actions permitted by their assigned role.

**Why this priority**: Staff members are the primary daily operators of the queue system. Their sign-in flow must correctly scope their view and permissions to the branch they are assigned to, without exposing tenant-wide administrative controls.

**Independent Test**: Can be fully tested by signing in as a Branch Staff or Branch Manager and verifying that the interface is scoped to the correct branch, displaying only the actions and data their role permits — delivers role-aware session routing as a standalone outcome.

**Acceptance Scenarios**:

1. **Given** a Branch Manager assigned to Branch A, **When** they sign in with valid credentials, **Then** they are directed to Branch A's operational view with manager-level capabilities.
2. **Given** a Branch Staff member assigned to Branch A, **When** they sign in with valid credentials, **Then** they are directed to Branch A's operational view with staff-level capabilities only.
3. **Given** a user who holds roles in multiple branches, **When** they sign in, **Then** they are presented with a branch selection screen to choose which branch context to operate in.

---

### Edge Cases

- What happens when the automatic tenant or branch creation fails partway through signup (e.g., the tenant is created but the branch insert fails)? The entire provisioning operation must be rolled back atomically — no orphaned tenant or branch records should remain.
- What happens when a Tenant Admin invites an email address that is already assigned to a different tenant? The invitation should succeed — a single platform user may hold branch-level roles (branch_manager or branch_staff) across multiple tenants, but cannot be a Tenant Admin for more than one tenant.
- What happens when a user is assigned to multiple branches across the same tenant? The system should present a branch selection screen upon sign-in, letting the user choose which branch to operate in for that session.
- What happens when a pending invitation's target branch is deleted before the invitation is accepted? The invitation should be automatically invalidated — accepting it should display a clear message that the branch no longer exists.
- What happens when a Tenant Admin tries to assign a role that does not exist (e.g., a typo or unsupported role name)? The system must reject the assignment with a validation error — only predefined roles (tenant_admin, branch_manager, branch_staff) are permitted.
- What happens when a Tenant Admin removes a staff member who is currently signed in and actively using the system? The removal takes effect on their very next data request — they receive empty results and are effectively locked out without requiring a forced sign-out.

---

## Out of Scope

- Password reset and account recovery flows — deferred to a dedicated security-hardening phase.
- Multi-factor authentication (MFA) — not required for the initial launch.
- Social login providers (Google, Apple, etc.) — email/password is the only supported method in this phase.
- Email verification for signup — deferred; accounts are active immediately upon registration.
- Tenant Admin transfer (transferring ownership to another user) — deferred to a future phase.
- Application-layer role enforcement in the UI — this phase covers the data and identity layer; frontend role-guarding is handled in subsequent feature phases.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a self-service signup flow where a new user registers with an email address, a password, and a business name (tenant name).
- **FR-002**: Upon successful signup, the system MUST automatically provision a new tenant, create a default first branch under that tenant, and assign the new user the tenant_admin role — all as a single atomic operation. If any step fails, the entire operation MUST be rolled back with no partial records remaining.
- **FR-003**: The system MUST prevent duplicate accounts — an email address that is already registered MUST NOT be used to create a second account.
- **FR-004**: The system MUST validate signup inputs: email addresses MUST conform to a standard format, and passwords MUST meet minimum strength requirements (at least 8 characters).
- **FR-005**: After successful signup and provisioning, the system MUST automatically sign the user in and direct them to their tenant dashboard — no separate login step MUST be required.
- **FR-006**: The system MUST provide a sign-in flow for returning users using email and password credentials.
- **FR-007**: Upon successful sign-in, the system MUST resolve the user's role(s) through the tenant membership and branch membership tables and route them to the appropriate context (tenant dashboard for admins, branch view for branch-level users).
- **FR-008**: The system MUST support sign-out, which terminates the active session and prevents further data access until re-authentication.
- **FR-009**: The system MUST allow a Tenant Admin to invite new users by email, specifying a target branch and a role (branch_manager or branch_staff).
- **FR-010**: The system MUST generate and send an invitation (via email or a shareable link) that allows the invited user to accept and join the specified branch with the pre-assigned role.
- **FR-011**: When an invited user accepts an invitation, the system MUST automatically create the branch membership record linking the user to the specified branch with the designated role — no additional admin approval step SHALL be required.
- **FR-012**: The system MUST enforce the role conflict rule: a user who is a Tenant Admin for a tenant MUST NOT simultaneously be assigned a branch-level role (branch_manager or branch_staff) within the same tenant. Any attempt to create such a conflicting assignment MUST be rejected.
- **FR-013**: The system MUST allow a Tenant Admin to view all pending invitations and to resend or revoke them before they are accepted.   
- **FR-014**: An invitation MUST become invalid once it has been accepted — reusing the same invitation link MUST NOT create a duplicate role assignment.
- **FR-015**: If a user holds roles across multiple branches within the same tenant, the system MUST present a branch selection mechanism upon sign-in so the user can choose their active branch context.
- **FR-016**: Only the predefined roles (tenant_admin, branch_manager, branch_staff) MUST be assignable. Any attempt to assign an unrecognized role MUST be rejected with a validation error.
- **FR-017**: The tenant name provided during signup MUST be editable by the Tenant Admin from settings. The default first branch MUST be named "Main Branch" and also be editable.
- **FR-018**: Pending invitations MUST expire automatically 48 hours after creation. An expired invitation MUST behave identically to a revoked one — the link becomes invalid and no role assignment occurs. The Tenant Admin MUST be able to resend an expired invitation, which generates a fresh 48-hour validity window.
- **FR-019**: A user MUST NOT be a Tenant Admin for more than one tenant. If a user who already holds a tenant_admin role in one tenant attempts to sign up (which auto-creates a new tenant), or is somehow assigned tenant_admin in a second tenant, the system MUST reject the operation. A user may, however, hold branch-level roles (branch_manager or branch_staff) in tenants other than the one they administer.
- **FR-020**: A Tenant Admin MUST be able to remove any existing branch_manager or branch_staff member from any branch within their tenant. Removal MUST delete the branch membership record and take effect on the removed user’s next request — consistent with the Phase 2 principle that role changes are immediate without re-authentication.

### Key Entities

- **User Account**: A platform-level identity representing an authenticated individual. Linked to one or more tenants and branches through membership records. Identified by email address and password credentials.
- **Tenant**: The top-level organizational unit automatically created during signup. Owns branches, staff memberships, and all operational data.
- **Branch**: An operational sub-unit within a tenant. The first branch ("Main Branch") is created automatically during signup. Additional branches are managed by the Tenant Admin.
- **Tenant Membership**: A record linking a user to a tenant with the tenant_admin role. Created automatically during signup. A user may hold at most one tenant_admin membership across the entire platform.
- **Branch Membership**: A record linking a user to a specific branch with either the branch_manager or branch_staff role. Created when an invited user accepts an invitation.
- **Invitation**: A persistent record (stored in a new `invitations` table introduced in this phase) representing a pending request for a user to join a branch with a specific role. Contains the invitee's email, target branch, assigned role, status (pending, accepted, revoked, expired), and an expiration timestamp (48 hours from creation). Expired invitations can be resent by the Tenant Admin to generate a new 48-hour window.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new user can complete signup and land on their tenant dashboard in under 30 seconds — including account creation, tenant provisioning, branch creation, and role assignment.
- **SC-002**: 100% of successful signups result in exactly one tenant, one default branch, and one tenant_admin membership record — verified by a data integrity check after each signup.
- **SC-003**: Returning users can sign in and reach their scoped dashboard in under 10 seconds.
- **SC-004**: A Tenant Admin can send an invitation and the invited user can accept and gain access within 3 minutes of the invitation being issued — covering the full invite-to-access lifecycle.
- **SC-005**: 100% of invitation acceptances result in exactly one branch membership record with the correct branch and role — no duplicates and no misassignment.
- **SC-006**: The role conflict rule is enforced with zero exceptions — any attempt to assign a branch-level role to an existing Tenant Admin within the same tenant is rejected in 100% of test cases.
- **SC-007**: Failed signup attempts (invalid email, weak password, duplicate email) produce a clear user-facing error within 3 seconds — no partial records are left behind.
- **SC-008**: 95% of first-time users can complete the signup flow without external help or documentation.

---

## Assumptions

- The ten core database tables from Phase 1 (Database Foundation) and the Row Level Security policies from Phase 2 (Access Control & RLS) are already in place — this phase builds on top of both.
- This phase introduces a new `invitations` table (not part of the original Phase 1 schema) to persist invitation records. RLS policies for this table will be defined as part of this phase.
- Authentication is handled via the platform's built-in authentication service using email and password. No third-party identity providers are required in this phase.
- The atomic signup provisioning (tenant + branch + role in one operation) will be implemented as a server-side transaction or database trigger to guarantee consistency — the specific mechanism is an implementation detail outside this spec.
- Invitations are functional via a shareable link as the minimum viable delivery method. Email delivery is preferred but not strictly required if a link-based approach is implemented first.
- A single platform user (identified by email) may hold branch-level roles (branch_manager or branch_staff) in multiple tenants, but MUST NOT be a Tenant Admin for more than one tenant. Cross-tenant branch-level role conflicts are not enforced; only within-tenant conflicts (tenant_admin vs branch-level) and the single-tenant-admin-per-user constraint are prevented.
- The default branch created during signup ("Main Branch") follows the same schema and constraints as any manually created branch.
- Session management follows standard patterns: sign-in creates a session, sign-out destroys it, and all data access is gated on an active authenticated session.
- Password strength requirements are set at a minimum of 8 characters for this phase. More advanced policies (uppercase, special characters, etc.) may be introduced in a later security-hardening phase.
