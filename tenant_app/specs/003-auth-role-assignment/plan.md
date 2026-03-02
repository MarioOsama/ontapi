# Implementation Plan: Authentication & Role Assignment

**Branch**: `003-auth-role-assignment` | **Date**: 2026-03-02 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `specs/003-auth-role-assignment/spec.md`

---

## Summary

Implement the full authentication and role assignment system for the Ontapi Tenant App. This phase spans **two layers**: (1) a Supabase database migration introducing the `invitations` table, a signup-provisioning trigger, and constraint triggers, and (2) a Flutter frontend with auth screens (signup, sign-in), session/role routing, staff invitation management, and invitation acceptance. All authentication uses Supabase Auth (email/password). Signup atomically creates a tenant, branch, and tenant_admin membership via a database trigger. Invitations are persisted in a new table with 48-hour expiry and managed through a Tenant Admin UI.

---

## Technical Context

**Language/Version**: Dart 3.9 / Flutter 3.35  
**Primary Dependencies**: Supabase (Auth, Postgres, Realtime, Storage), `supabase_flutter` SDK  
**Storage**: PostgreSQL (via Supabase) — 10 core tables from Phase 1 + 1 new `invitations` table  
**Testing**: Supabase local dev (`supabase db reset` + `supabase test db`) + Flutter widget/integration tests + manual role-persona testing  
**Target Platform**: Flutter Web (primary) + Mobile  
**Project Type**: Mobile + Web (Flutter) backed by Supabase  
**Performance Goals**: Signup-to-dashboard in under 30 seconds; sign-in-to-dashboard in under 10 seconds  
**Constraints**: Supabase Auth only (no custom auth). No JWT custom claims (per Phase 2). Invitation expiry: 48 hours. Single tenant_admin per user.  
**Scale/Scope**: 1 new table, 3 triggers, 1 database function, auth screens, invitation management UI, role-based routing

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| Supabase Auth required; JWT-based session | ✅ Pass | Uses `supabase_flutter` auth with email/password |
| All requests subject to RLS | ✅ Pass | New `invitations` table will have RLS policies; existing tables unchanged |
| Tenant App never accesses another tenant's data | ✅ Pass | Signup provisioning is scoped to new tenant only; invitations scoped to admin's tenant |
| No dependency on Client App or Next.js | ✅ Pass | Pure Flutter + Supabase |
| Roles: tenant_admin, branch_manager, branch_staff | ✅ Pass | All three roles covered in routing and invitation assignment |
| Branch Staff: create orders, update status, cancel orders | ✅ Pass | Staff role assignment scoped correctly; order capabilities unchanged |
| No JWT custom claims | ✅ Pass | Role resolved via `tenant_users` / `branch_users` lookup, consistent with Phase 2 |
| Ratings read-only for internal roles | ✅ Pass | No changes to ratings access |
| Tenant Admin manages staff (constitution §4.1) | ✅ Pass | FR-009, FR-020 implement invite and remove |
| Branch Manager manages branch staff (constitution §4.2) | ⚠ Deferred | Branch Manager staff management is deferred — only Tenant Admin can invite/remove in this phase (see Complexity Tracking) |

**One deferred item justified below. Proceeding to Phase 0.**

---

## Project Structure

### Documentation (this feature)

```text
specs/003-auth-role-assignment/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── contracts/
│   └── auth-contracts.md     ← Phase 1 output
└── tasks.md             ← Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
supabase/
└── migrations/
    ├── 20260228101405_database_foundation.sql   ← Phase 1 (existing)
    ├── 20260301123647_access_control_rls.sql    ← Phase 2 (existing)
    └── YYYYMMDDHHMMSS_auth_role_assignment.sql  ← Phase 3 (new migration)

lib/
├── core/
│   ├── constants/
│   │   └── app_config.dart
│   ├── utils/
│   │   └── injection_container.dart    ← GetIt service locator setup
│   ├── services/
│   │   └── auth_service.dart           ← Supabase auth wrapper
│   └── shared_widgets/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── models/
│   │   │       └── app_user.dart
│   │   ├── logic/
│   │   │   ├── auth_cubit.dart
│   │   │   └── auth_state.dart
│   │   └── ui/
│   │       ├── pages/
│   │       │   ├── sign_in_page.dart
│   │       │   ├── sign_up_page.dart
│   │       │   └── branch_selector_page.dart
│   │       └── widgets/
│   ├── invitations/
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   │   └── invitation_repository.dart
│   │   │   └── models/
│   │   │       └── invitation.dart
│   │   ├── logic/
│   │   │   ├── invitation_cubit.dart
│   │   │   └── invitation_state.dart
│   │   └── ui/
│   │       ├── pages/
│   │       │   ├── invitation_list_page.dart
│   │       │   └── accept_invitation_page.dart
│   │       └── widgets/
│   └── ... (other features unchanged)
├── app.dart
└── main.dart
```

**Structure Decision**: This phase introduces Flutter feature folders (`auth/`, `invitations/`) following the existing clean-architecture pattern defined in the implementation plan. One new Supabase migration file is added for the `invitations` table, triggers, and constraints.

---

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|--------------------------------------|
| Branch Manager staff management deferred | Phase 3 focuses on Tenant Admin as the sole staff authority for the initial launch — simplifies the invitation flow to a single actor. Branch Manager invite/remove capability will be added in Phase 4 (Core Branch Management) when the branch-level management features are built. | Adding a second invitation actor increases scope and introduces permissions complexity within invitations (who can invite whom) that is better solved alongside the Branch Management feature. |
