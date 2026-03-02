# Implementation Plan: Access Control & Row Level Security

**Branch**: `002-access-control-rls` | **Date**: 2026-03-01 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `specs/002-access-control-rls/spec.md`

---

## Summary

Implement Row Level Security (RLS) policies on all 10 core tables of the Ontapi Tenant App database. Policies enforce strict tenant and branch isolation for three internal roles (tenant_admin, branch_manager, branch_staff) and deny all unauthenticated access. Additionally, a database-level constraint prevents any user from holding a Tenant Admin role and a branch-level role simultaneously within the same tenant. All policy decisions are evaluated per-request via live relational lookups on `tenant_users` and `branch_users` — no JWT custom claims, no application-layer enforcement.

---

## Technical Context

**Language/Version**: Dart 3.9 / Flutter 3.35  
**Primary Dependencies**: Supabase (Auth, Postgres, Realtime, Storage)  
**Storage**: PostgreSQL (via Supabase) — 10 core tables from Phase 1  
**Testing**: Supabase local dev (`supabase db reset` + `supabase test db`) + manual role-persona testing  
**Target Platform**: Supabase PostgreSQL (database layer only — no Flutter UI changes in this phase)  
**Project Type**: Mobile + Web (Flutter) backed by Supabase  
**Performance Goals**: Policy evaluation adds negligible latency; relational lookups are indexed (idx_tenant_users_user_id, idx_branch_users_user_id already in place)  
**Constraints**: All policies must use `auth.uid()` only — no custom JWT claims. Deny-by-default enforced by enabling RLS before adding any policies.  
**Scale/Scope**: 10 tables, 3 internal roles + unauthenticated, 1 migration file

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| Supabase Auth required; JWT-based session | ✅ Pass | All policies use `auth.uid()` |
| All requests subject to RLS | ✅ Pass | Phase 2 enables RLS on all 10 tables |
| Tenant App never accesses another tenant's data | ✅ Pass | Tenant isolation is the core policy goal |
| No dependency on Client App or Next.js | ✅ Pass | Pure DB migration — no frontend involved |
| Roles: tenant_admin, branch_manager, branch_staff | ✅ Pass | Three roles covered by spec exactly |
| Branch Staff: create orders, update status, cancel orders | ✅ Pass | FR-004 scopes staff to orders table only |
| No JWT custom claims | ✅ Pass | Spec explicitly forbids claims-based auth (FR-006) |
| Ratings read-only for internal roles | ✅ Pass | FR-012 confirmed in clarification |

**No violations. Proceeding to Phase 0.**

---

## Project Structure

### Documentation (this feature)

```text
specs/002-access-control-rls/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── contracts/
│   └── rls-policy-matrix.md   ← Phase 1 output
└── tasks.md             ← Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
supabase/
└── migrations/
    ├── 20260228101405_database_foundation.sql   ← Phase 1 (existing)
    └── 20260301123647_access_control_rls.sql    ← Phase 2 (new migration)
```

**Structure Decision**: This phase produces a single new Supabase migration file. No Flutter source changes. All RLS logic lives at the database layer.

---

## Complexity Tracking

No constitution violations to justify.
