# Quickstart: Database Foundation

**Branch**: `001-database-foundation` | **Date**: 2026-02-27

## Prerequisites

- Access to the Supabase project dashboard (or Supabase CLI installed)
- Database credentials for the Supabase project

## Getting Started

### 1. Apply the Migration

**Option A — Supabase Dashboard (recommended for first-time setup)**:

1. Open the Supabase Dashboard → SQL Editor
2. Paste the contents of `supabase/migrations/001_database_foundation.sql`
3. Click **Run**
4. Verify success in the output panel

**Option B — Supabase CLI**:

```bash
supabase db push
```

### 2. Verify Tables

In the SQL Editor, run:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;
```

Expected output: `branch_offers`, `branch_users`, `branches`, `offers`, `orders`, `ratings`, `subscriptions`, `tenant_users`, `tenants`, `usage_tracking`

### 3. Insert Test Data

```sql
-- Create a test tenant
INSERT INTO tenants (name, description) 
VALUES ('Test Tenant', 'My first tenant');

-- Create a branch
INSERT INTO branches (tenant_id, name, avg_service_duration)
SELECT id, 'Main Branch', 15 FROM tenants WHERE name = 'Test Tenant';

-- Verify
SELECT t.name AS tenant, b.name AS branch, b.avg_service_duration
FROM tenants t
JOIN branches b ON b.tenant_id = t.id;
```

### 4. Verify Constraints

```sql
-- Should FAIL: invalid order status
INSERT INTO orders (tenant_id, branch_id, order_number, status, source)
SELECT t.id, b.id, 'TEST-001', 'expired', 'manual'
FROM tenants t JOIN branches b ON b.tenant_id = t.id
WHERE t.name = 'Test Tenant';

-- Should FAIL: rating out of range
INSERT INTO ratings (tenant_id, branch_id, order_id, rating)
VALUES (gen_random_uuid(), gen_random_uuid(), gen_random_uuid(), 6);

-- Should FAIL: negative avg_service_duration
INSERT INTO branches (tenant_id, name, avg_service_duration)
SELECT id, 'Bad Branch', -5 FROM tenants WHERE name = 'Test Tenant';
```

### 5. Clean Up Test Data

```sql
-- Remove test tenant (cascades to branches, orders, etc.)
-- Note: must remove tenant_users/branch_users first (RESTRICT)
DELETE FROM tenants WHERE name = 'Test Tenant';
```

## Next Steps

- Phase 2: Apply RLS policies (`/speckit.specify` for access-control feature)
- Phase 3: Build authentication & role assignment flow
