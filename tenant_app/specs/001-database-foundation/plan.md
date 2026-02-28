# Implementation Plan: Database Foundation

**Branch**: `001-database-foundation` | **Date**: 2026-02-27 | **Spec**: [spec.md](file:///d:/flutter_projects/pager/ontapi/tenant_app/specs/001-database-foundation/spec.md)  
**Input**: Feature specification from `specs/001-database-foundation/spec.md`

## Summary

Create all 10 core database tables for the Ontapi multi-tenant queue management platform using Supabase (Postgres). This includes defining foreign key relationships, CHECK constraints, indexes, enums for order status/source, and unique constraints. The schema serves as the foundation for all subsequent phases (RLS, auth, orders, realtime, etc.).

## Technical Context

**Language/Version**: SQL (PostgreSQL 15+ via Supabase)  
**Primary Dependencies**: Supabase project with Postgres database  
**Storage**: PostgreSQL (Supabase-managed)  
**Testing**: SQL integration tests via Supabase SQL Editor or `psql` CLI  
**Target Platform**: Supabase cloud (dev environment)  
**Project Type**: Database migration (no application code)  
**Performance Goals**: Indexed queries return results in < 1s for 100k+ records  
**Constraints**: Schema must be compatible with Supabase Auth (`auth.users` FK references)  
**Scale/Scope**: 10 core tables, ~20 functional requirements, single migration file

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Constitution Rule | Status |
|------|-------------------|--------|
| Multi-tenant isolation | All data scoped to tenant via `tenant_id` FK | ✅ Pass |
| Role-based access | `tenant_users` and `branch_users` tables define roles | ✅ Pass |
| Supabase Auth integration | FK references to `auth.users` only, no custom auth | ✅ Pass |
| RLS enforcement | Schema supports RLS (enabled in Phase 2, not here) | ✅ Pass — deferred by design |
| No cross-tenant access | FK + future RLS ensures isolation | ✅ Pass |
| Realtime support | Tables structured for Supabase Realtime subscriptions | ✅ Pass — compatible |
| No Next.js dependency | Pure SQL, no frontend framework | ✅ Pass |

All gates pass. No violations to justify.

## Project Structure

### Documentation (this feature)

```text
specs/001-database-foundation/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── checklists/
    └── requirements.md  # Quality checklist (complete)
```

### Source Code (database)

```text
supabase/
└── migrations/
    └── 001_database_foundation.sql   # Single migration file with all tables
```

**Structure Decision**: This is a database-only phase. The deliverable is a single SQL migration file applied via Supabase Dashboard SQL Editor or CLI. No application code is produced.

## Verification Plan

### Automated Tests (SQL)

Run the following SQL verification script in Supabase SQL Editor after applying the migration:

1. **Table existence check**: Query `information_schema.tables` to confirm all 10 tables exist
2. **Foreign key validation**: Insert records with invalid FK references and verify rejection
3. **CHECK constraint validation**: Insert invalid enum values (order status, source) and out-of-range ratings; verify rejection
4. **Unique constraint validation**: Insert duplicate `tenant_users`, `branch_users`, `usage_tracking` records; verify rejection
5. **CASCADE test**: Delete a tenant and verify all child data records are removed while user mappings block the delete (must remove user mappings first)
6. **Index verification**: Query `pg_indexes` to confirm all expected indexes exist
7. **Timestamp defaults**: Insert a record without explicit timestamps and verify auto-population

### Manual Verification

1. Open Supabase Dashboard → Table Editor and visually confirm all 10 tables are present with correct column types
2. Insert sample records via the Table Editor UI to validate the happy path
3. Verify the migration can be re-applied to a fresh database without errors
