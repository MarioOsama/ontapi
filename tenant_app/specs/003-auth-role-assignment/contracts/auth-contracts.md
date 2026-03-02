# Auth & Invitation Contracts

**Branch**: `003-auth-role-assignment` | **Date**: 2026-03-02  
**Phase**: 1 — Design

---

## 1. Supabase Auth — Signup

### `supabase.auth.signUp()`

**Actor**: Unauthenticated visitor  
**Trigger**: User submits signup form

**Request:**

```dart
final response = await supabase.auth.signUp(
  email: email,
  password: password,
  data: {'business_name': businessName},
);
```

**Server-Side Effect** (via `handle_new_user_signup` trigger):

1. Creates `tenants` record with `name = business_name`
2. Creates `branches` record with `name = 'Main Branch'`, `tenant_id` from step 1
3. Creates `tenant_users` record with `user_id`, `tenant_id`, `role = 'tenant_admin'`

**Success Response**: `AuthResponse` with `user` and `session` populated.

**Error Cases:**

| Condition | Response |
|-----------|----------|
| Email already registered | `AuthException` — "User already registered" |
| Invalid email format | `AuthException` — validation error |
| Weak password (<8 chars) | `AuthException` — password policy violation |
| User already is tenant_admin elsewhere | `PostgrestException` — UNIQUE constraint violation on `tenant_users.user_id` (trigger rollback) |

---

## 2. Supabase Auth — Sign In

### `supabase.auth.signInWithPassword()`

**Actor**: Registered user  
**Trigger**: User submits sign-in form

**Request:**

```dart
final response = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);
```

**Success Response**: `AuthResponse` with `user` and `session`.

**Post-Sign-In Role Resolution** (client-side):

```dart
// 1. Check tenant_admin
final tenantUser = await supabase
    .from('tenant_users')
    .select('tenant_id')
    .eq('user_id', userId)
    .maybeSingle();

if (tenantUser != null) {
  // Route to tenant admin dashboard
  return;
}

// 2. Check branch memberships
final branchUsers = await supabase
    .from('branch_users')
    .select('branch_id, role')
    .eq('user_id', userId);

if (branchUsers.length == 1) {
  // Route to single branch view
} else if (branchUsers.length > 1) {
  // Show branch selector
} else {
  // No roles — show pending/error state
}
```

**Error Cases:**

| Condition | Response |
|-----------|----------|
| Incorrect email or password | `AuthException` — "Invalid login credentials" |

---

## 3. Supabase Auth — Sign Out

### `supabase.auth.signOut()`

**Actor**: Any authenticated user  
**Trigger**: User taps sign-out

**Request:**

```dart
await supabase.auth.signOut();
```

**Effect**: Session destroyed. Client navigates to sign-in page.

---

## 4. Invitations — Create

### `supabase.from('invitations').insert()`

**Actor**: Tenant Admin  
**Trigger**: Admin submits invitation form

**Request:**

```dart
final result = await supabase.from('invitations').insert({
  'tenant_id': tenantId,
  'branch_id': branchId,
  'email': inviteeEmail,
  'role': role,       // 'branch_manager' or 'branch_staff'
  'invited_by': userId,
}).select().single();
```

**Success Response**: Inserted invitation record including `token`.

**Post-Insert**: Client generates shareable link: `https://admin.ontapi.com/invite?token={token}`

**Error Cases:**

| Condition | Response |
|-----------|----------|
| Duplicate pending invitation (same branch + email) | `PostgrestException` — unique constraint violation |
| Invalid role value | `PostgrestException` — CHECK constraint violation |
| Non-admin user attempts insert | RLS blocks — empty result / error |

---

## 5. Invitations — List Pending

### `supabase.from('invitations').select()`

**Actor**: Tenant Admin  
**Trigger**: Admin opens invitation management page

**Request:**

```dart
final invitations = await supabase
    .from('invitations')
    .select('*, branches(name)')
    .eq('tenant_id', tenantId)
    .eq('status', 'pending')
    .gt('expires_at', DateTime.now().toIso8601String())
    .order('created_at', ascending: false);
```

**Response**: List of pending, non-expired invitation records with branch names.

---

## 6. Invitations — Revoke

### `supabase.from('invitations').update()`

**Actor**: Tenant Admin  
**Trigger**: Admin revokes a pending invitation

**Request:**

```dart
await supabase
    .from('invitations')
    .update({'status': 'revoked'})
    .eq('id', invitationId)
    .eq('status', 'pending');
```

**Effect**: Invitation status changes to `revoked`. Link becomes invalid.

---

## 7. Invitations — Resend

### Re-insert flow

**Actor**: Tenant Admin  
**Trigger**: Admin resends an expired or revoked invitation

**Logic:**

1. Mark original invitation as `revoked` (if still `pending`) or leave as-is (if already `expired`/`revoked`).
2. Insert a new invitation with the same `branch_id`, `email`, and `role` → generates a fresh `token` and `expires_at`.
3. Share the new invitation link.

---

## 8. Invitations — Accept

### `supabase.rpc('accept_invitation')`

**Actor**: Invited user (authenticated)  
**Trigger**: User opens invitation link and authenticates

**Request:**

```dart
final result = await supabase.rpc('accept_invitation', params: {
  'invitation_token': token,
});
```

**Success Response** (`status = 'success'`):

```json
{
  "status": "success",
  "branch_id": "uuid",
  "role": "branch_staff",
  "tenant_id": "uuid"
}
```

**Error Responses:**

| `status` value | Meaning |
|----------------|---------|
| `invalid` | Token not found, expired, or already used |
| `email_mismatch` | Authenticated user's email doesn't match invitation |
| `role_conflict` | User is a tenant_admin for this tenant — cannot hold branch role |
| `already_member` | User is already assigned to this branch |

---

## 9. Staff — Remove

### `supabase.from('branch_users').delete()`

**Actor**: Tenant Admin  
**Trigger**: Admin removes a staff member

**Request:**

```dart
await supabase
    .from('branch_users')
    .delete()
    .eq('id', branchUserId);
```

**Effect**: Branch membership deleted. User loses access on next request (per Phase 2 RLS).

**Error Cases:**

| Condition | Response |
|-----------|----------|
| Non-admin attempts delete | RLS blocks — no effect |
| Record doesn't exist | No error — DELETE on zero rows is a no-op |
