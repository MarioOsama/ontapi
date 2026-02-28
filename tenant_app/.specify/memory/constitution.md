<!--
**Sync Impact Report**

- **Version change**: `N/A` -> `1.0.0`
- **Modified principles**: Initial creation.
- **Added sections**: All sections are new.
- **Removed sections**: All template sections are removed.
- **Templates requiring updates**:
    - ⚠ pending: `.specify/templates/plan-template.md`
    - ⚠ pending: `.specify/templates/spec-template.md`
    - ⚠ pending: `.specify/templates/tasks-template.md`
- **Follow-up TODOs**: None.
-->

# Ontapi Tenant App Constitution

**Version**: 1.0.0 | **Ratified**: 2026-02-17 | **Last Amended**: 2026-02-17

## 1. Purpose

The Tenant App is a multi-tenant, real-time queue intelligence SaaS platform and volume-based (monthly order count pricing).
It is the operational control panel for tenants.
It is used by:

- Tenant Admin
- Branch Manager
- Branch Staff

It manages queue operations, branches, staff, analytics, subscription, and configuration.

---

## 2. Technology Stack

- Flutter 3.35 (Web + Mobile)
- Dart 3.9
- Supabase (Auth, DB, Realtime, Storage)

No dependency on Next.js.
No dependency on Client App frontend.

---

## 3. Authentication

- Supabase Auth required.
- JWT-based session.
- All requests subject to RLS.

---

## 4. Responsibilities

### 4.1 Tenant Admin

- Manage tenant metadata.
- Manage branches.
- Manage offers.
- Manage staff.
- Manage subscription plan.
- View aggregated analytics.

### 4.2 Branch Manager

- Manage branch metadata.
- Manage branch offers.
- Manage branch staff.
- Monitor queue.
- View branch analytics.

### 4.3 Branch Staff

- Create orders manually.
- Update order status.
- Cancel orders.

---

## 5. Core Functional Modules

### 5.1 Branch Management
CRUD branches scoped to tenant.

### 5.2 Order Management
- Create order (manual entry).
- Update status.
- View active queue.

### 5.3 Offer Management
- Tenant-wide offers.
- Branch-specific offers.

### 5.4 Analytics Dashboard
- Avg waiting time.
- Queue volume.
- Completion rate.
- Rating summary.

### 5.5 Subscription Monitoring
- Monthly order usage.
- Remaining quota.
- Upgrade prompt.

---

## 6. Realtime Scope

Tenant App subscribes to:
- Orders per branch.
- Order status changes.
- Branch metrics updates.

No client-side notification logic.
No vibration/sound logic.

---

## 7. Security Boundary

Tenant App can:
- Read/write tenant-scoped data.
- Never access another tenant’s data.
- Never access client ratings beyond its own tenant.

All enforced by RLS.

---

## 8. Deployment

- Hosted separately.
- Own domain/subdomain.
Example:
admin.ontapi.com
