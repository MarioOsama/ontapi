# Research: Database Foundation

**Branch**: `001-database-foundation` | **Date**: 2026-02-27

## Summary

No major unknowns were identified during Technical Context evaluation. All technology choices are established in the project constitution (Supabase + PostgreSQL). This document records decisions made during the planning phase.

---

## Decision 1: Enum Implementation Strategy

**Decision**: Use PostgreSQL CHECK constraints with text values (not custom ENUM types)

**Rationale**: CHECK constraints like `CHECK (status IN ('waiting', 'in_progress', 'done', 'cancelled'))` are simpler to modify and migrate than PostgreSQL's `CREATE TYPE ... AS ENUM`. Adding a new status value with CHECK requires altering the constraint, while ENUM types require `ALTER TYPE ... ADD VALUE` which cannot run inside a transaction.

**Alternatives considered**:
- Custom ENUM types (`CREATE TYPE order_status AS ENUM (...)`) — rejected: harder to modify, transaction restrictions
- Lookup tables for statuses — rejected: over-engineering for a small fixed set of values

---

## Decision 2: UUID Generation

**Decision**: Use `gen_random_uuid()` as the default for all primary keys

**Rationale**: Built-in to PostgreSQL 13+ (no extension needed). Supabase's Postgres includes this by default. Generates random UUIDs (v4) which are suitable for distributed systems.

**Alternatives considered**:
- `uuid_generate_v4()` from `uuid-ossp` extension — rejected: requires extension installation, `gen_random_uuid()` is equivalent and built-in
- Application-generated UUIDs — rejected: database defaults are more reliable

---

## Decision 3: Timestamp Management

**Decision**: Use `timestamptz` with `DEFAULT now()` for `created_at`; use trigger or application-level handling for `updated_at`

**Rationale**: `timestamptz` stores timestamps in UTC and converts for display based on session timezone. `DEFAULT now()` handles creation time. For `updated_at`, a Postgres trigger (`moddatetime`) automatically sets the value on update, keeping it out of application code.

**Alternatives considered**:
- `timestamp` without timezone — rejected: loses timezone awareness, potential for ambiguity
- Application-managed timestamps — rejected: inconsistent if multiple clients access the database directly

---

## Decision 4: Cascade Strategy

**Decision**: CASCADE for data tables, RESTRICT for user mapping tables (per clarification Q1)

**Rationale**: When a tenant is deleted, all operational data (branches, orders, offers, subscriptions, usage tracking, ratings) should be removed as a complete wipe. User mappings (tenant_users, branch_users) use RESTRICT to force explicit removal of users before tenant deletion — preventing orphaned user accounts.

**Alternatives considered**:
- Full RESTRICT — rejected by user (makes cleanup difficult)
- Full CASCADE — too aggressive for user mappings
- Soft-delete — rejected for Phase 1 (deferred to Phase 9)

---

## Decision 5: Index Strategy

**Decision**: Create B-tree indexes on `tenant_id`, `branch_id`, and `user_id` foreign key columns across all relevant tables

**Rationale**: PostgreSQL does not automatically index foreign key columns (unlike primary keys). These columns are used in virtually every query (tenant-scoped RLS policies, branch-level filtering, user lookups). B-tree is the default and optimal index type for equality and range queries.

**Alternatives considered**:
- Composite indexes (e.g., `tenant_id + branch_id`) — not needed for Phase 1; can be added in optimization phases
- Partial indexes — premature optimization for schema phase
