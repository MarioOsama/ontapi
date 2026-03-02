# Quickstart: Authentication & Role Assignment

**Branch**: `003-auth-role-assignment` | **Date**: 2026-03-02

---

## Prerequisites

- Supabase local dev environment running (`supabase start`)
- Phase 1 migration (`20260228101405_database_foundation.sql`) applied
- Phase 2 migration (`20260301123647_access_control_rls.sql`) applied
- Flutter SDK 3.35+ installed

---

## 1. Apply the Migration

```bash
# From project root
supabase db reset
# Or to apply just the new migration:
supabase migration up
```

This creates:
- `public.invitations` table with indexes and RLS
- `public.handle_new_user_signup()` trigger function on `auth.users`
- `public.accept_invitation()` SECURITY DEFINER function
- `UNIQUE(user_id)` constraint on `tenant_users`

---

## 2. Test Signup Flow

```bash
# Using Supabase Dashboard or curl
# Sign up a new user — triggers auto-provisioning
curl -X POST 'http://localhost:54321/auth/v1/signup' \
  -H 'apikey: <anon-key>' \
  -H 'Content-Type: application/json' \
  -d '{
    "email": "admin@example.com",
    "password": "password123",
    "data": { "business_name": "Acme Corp" }
  }'
```

**Verify provisioning:**

```sql
-- Check tenant was created
SELECT * FROM public.tenants WHERE name = 'Acme Corp';

-- Check branch was created
SELECT b.* FROM public.branches b
JOIN public.tenants t ON b.tenant_id = t.id
WHERE t.name = 'Acme Corp';

-- Check admin role was assigned
SELECT * FROM public.tenant_users WHERE user_id = '<user-id>';
```

---

## 3. Test Invitation Flow

```sql
-- As tenant admin, insert an invitation
INSERT INTO public.invitations (tenant_id, branch_id, email, role, invited_by)
VALUES ('<tenant-id>', '<branch-id>', 'staff@example.com', 'branch_staff', '<admin-user-id>');

-- Get the token
SELECT token FROM public.invitations WHERE email = 'staff@example.com';
```

**Accept as invited user:**

```sql
-- After signing up/in as staff@example.com
SELECT public.accept_invitation('<token-uuid>');
```

---

## 4. Test Constraints

```sql
-- Should FAIL: same user as admin in second tenant
INSERT INTO public.tenant_users (tenant_id, user_id, role)
VALUES ('<other-tenant-id>', '<existing-admin-user-id>', 'tenant_admin');
-- Expected: UNIQUE constraint violation on user_id

-- Should FAIL: tenant admin as branch staff (same tenant)
INSERT INTO public.branch_users (branch_id, user_id, role)
VALUES ('<branch-id>', '<admin-user-id>', 'branch_staff');
-- Expected: prevent_role_conflict trigger raises exception
```

---

## 5. Run Flutter App

```bash
cd tenant_app
flutter pub get
flutter run -d chrome
```

Navigate to `localhost:port` → signup screen → complete signup → verify dashboard loads with tenant name.

---

## Key Files

| File | Purpose |
|------|---------|
| `supabase/migrations/*_auth_role_assignment.sql` | Database migration |
| `lib/core/services/auth_service.dart` | Supabase Auth wrapper |
| `lib/features/auth/data/repositories/auth_repository.dart` | Auth data layer |
| `lib/features/auth/logic/auth_cubit.dart` | Auth state management |
| `lib/features/auth/ui/pages/sign_up_page.dart` | Signup screen |
| `lib/features/auth/ui/pages/sign_in_page.dart` | Sign-in screen |
| `lib/features/invitations/data/repositories/invitation_repository.dart` | Invitation data layer |
| `lib/features/invitations/logic/invitation_cubit.dart` | Invitation state management |
| `lib/features/invitations/ui/pages/invitation_list_page.dart` | Admin invitation management |
| `lib/features/invitations/ui/pages/accept_invitation_page.dart` | Invitation acceptance flow |
