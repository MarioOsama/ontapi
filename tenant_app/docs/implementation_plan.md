# Tenant App Detailed Implementation Plan

**Created At**: 2026-02-17  
**Updated At**: 2026-02-26  
**Version**: 3.0.0

---

# Table of Contents

1. Architecture Overview  
2. Database Schema  
3. Access Control & RLS Strategy  
4. Frontend Architecture  
5. Queue Engine Logic  
6. Realtime Integration  
7. Subscription Enforcement Model  
8. Analytics Engine  
9. Data Retention Strategy  
10. Build Order (Detailed Phases)  
11. Deployment Strategy  

---

# 1. Architecture Overview

## 1.1 Purpose

The Tenant App is the operational control panel for Ontapi tenants.

It allows:
- Tenant Admins to manage tenant-wide configuration.
- Branch Managers to manage branch-level operations.
- Branch Staff to manage daily queue operations.

This system is fully isolated per tenant and secured via strict Row Level Security (RLS).

---

## 1.2 Tech Stack

- Flutter 3.35 (Web-first)
- Dart 3.9
- Supabase (Auth, Postgres, Realtime, Storage)
- Clean Architecture
- Feature-based folder structure
- Bloc/Cubit for state management

---

## 1.3 High-Level Architecture

Presentation Layer (Flutter UI)  
↓  
Application Layer (Use Cases / Cubits)  
↓  
Data Layer (Repositories)  
↓  
Supabase SDK  
↓  
Postgres + RLS + Realtime

Strict separation between UI and database access.

---

# 2. Database Schema

## 2.1 Core Tables

### tenants
- id (uuid, PK)
- name (text)
- logo_url (text)
- description (text)
- created_at (timestamptz)
- updated_at (timestamptz)

### branches
- id (uuid, PK)
- tenant_id (uuid, FK)
- name (text)
- address (text)
- avg_service_duration (int, minutes)
- created_at (timestamptz)
- updated_at (timestamptz)

### tenant_users
- id (uuid, PK)
- tenant_id (uuid, FK)
- user_id (uuid, FK → auth.users)
- role (text: tenant_admin)

### branch_users
- id (uuid, PK)
- branch_id (uuid, FK)
- user_id (uuid, FK → auth.users)
- role (text: branch_manager, branch_staff)

### orders
- id (uuid, PK)
- tenant_id (uuid, FK)
- branch_id (uuid, FK)
- order_number (text)
- status (text: waiting, in_progress, done, cancelled)
- source (text: manual, api)
- created_at (timestamptz)
- started_at (timestamptz)
- completed_at (timestamptz)

### offers
- id (uuid, PK)
- tenant_id (uuid, FK)
- title (text)
- description (text)
- image_url (text)
- is_global (boolean)
- is_active (boolean)
- created_at (timestamptz)
- updated_at (timestamptz)

### branch_offers
- id (uuid, PK)
- branch_id (uuid, FK)
- offer_id (uuid, FK)

### subscriptions
- id (uuid, PK)
- tenant_id (uuid, FK)
- plan_name (text)
- monthly_order_limit (int)
- current_period_start (date)
- current_period_end (date)

### usage_tracking
- id (uuid, PK)
- tenant_id (uuid, FK)
- month (text: YYYY-MM)
- orders_count (int)

### ratings
- id (uuid, PK)
- tenant_id (uuid, FK)
- branch_id (uuid, FK)
- order_id (uuid, FK)
- rating (int: 1–5)
- feedback (text)
- created_at (timestamptz)

---

# 3. Access Control & RLS Strategy

## 3.1 Principle

All access control is enforced using relational RLS policies based on:

- auth.uid()
- tenant_users
- branch_users

JWT custom tenant_id claims are NOT used.

---

## 3.2 Role Capabilities

### Tenant Admin
- Full access to all tenant data.

### Branch Manager
- Access limited to assigned branch.
- Cannot manage other branches.

### Branch Staff
- Create orders.
- Update order status.
- Cannot manage offers or subscription.

---

# 4. Frontend Architecture

## 4.1 Folder Structure

lib/
  core/
    constants/
    utils/
    services/
    shared_widgets/
  features/
    auth/
    dashboard/
    branches/
    orders/
    offers/
    analytics/
    subscription/
  app.dart

---

## 4.2 Feature Structure Example

orders/
  data/
    repositories/
    models/
  logic/
    order_cubit.dart
    order_state.dart
  ui/
    pages/
    widgets/

---

# 5. Queue Engine Logic

## 5.1 Order Creation Flow

1. Staff enters order_number.
2. System performs HARD subscription check.
3. If limit reached → reject insert.
4. Insert order with status = waiting.

---

## 5.2 Queue Position

Computed dynamically:

COUNT(waiting orders created before current order in same branch)

Implemented via SQL function or view.

---

## 5.3 Estimated Time

estimated_time = branch.avg_service_duration × queue_position

---

# 6. Realtime Integration

Tenant App subscribes to:
- Orders in selected branch.
- Order status changes.
- Branch metrics updates.

Scoped by branch_id.

---

# 7. Subscription Enforcement Model

## 7.1 Hard Check on Order Creation

Before inserting order:
- Check usage_tracking.orders_count < monthly_order_limit.
- If >= limit → reject.
- If >= 80% → allow + return warning.

---

## 7.2 Usage Increment on Order Done

When status changes to done:
- Increment usage_tracking.orders_count.
- Operation must be atomic.

---

# 8. Analytics Engine

## Branch Metrics
- Average waiting time.
- Service duration.
- Completion rate.
- Cancellation rate.
- Peak hours.

## Tenant Metrics
- Aggregated branch metrics.
- Monthly order usage.
- Average ratings.

Implemented using SQL views or materialized views.

---

# 9. Data Retention Strategy

- Detailed orders retained for 1 year.
- Aggregated metrics retained indefinitely.
- Scheduled job (PG_CRON or Edge Function):
  - Aggregate old orders.
  - Archive/delete orders older than 1 year.

---

# 10. Build Order (Detailed Phases)

## Phase 1 — Database Foundation

### 1.1 Schema Creation
- Create all core tables.
- Define constraints and indexes.
- Define enums.

### 1.2 Relationship Validation
- Foreign key constraints.
- Unique constraints.

### 1.3 Index Optimization
- Index tenant_id.
- Index branch_id.
- Index user_id in mapping tables.

---

## Phase 2 — Access Control & RLS

### 2.1 Enable RLS on all tables.
### 2.2 Implement tenant_admin policies.
### 2.3 Implement branch_manager policies.
### 2.4 Implement branch_staff policies.
### 2.5 Security testing with multiple roles.

---

## Phase 3 — Authentication & Role Assignment

### 3.1 Self-service signup flow.
### 3.2 Auto-create tenant on signup.
### 3.3 Auto-create first branch.
### 3.4 Assign tenant_admin role.
### 3.5 Invite staff & assign branch roles.

---

## Phase 4 — Core Branch Management

### 4.1 Branch CRUD.
### 4.2 Branch settings UI.
### 4.3 Role-based branch access validation.

---

## Phase 5 — Order System

### 5.1 Order creation UI.
### 5.2 Subscription hard check implementation.
### 5.3 Order status transitions.
### 5.4 Queue position computation.
### 5.5 Estimated time display.

---

## Phase 6 — Realtime Layer

### 6.1 Supabase channel integration.
### 6.2 Branch-scoped subscriptions.
### 6.3 UI reactive updates.
### 6.4 Stress testing with concurrent updates.

---

## Phase 7 — Subscription System

### 7.1 Usage tracking logic.
### 7.2 Warning threshold handling.
### 7.3 Usage dashboard UI.
### 7.4 Upgrade plan interface.

---

## Phase 8 — Analytics

### 8.1 SQL metric views.
### 8.2 Dashboard charts integration.
### 8.3 Branch vs Tenant aggregation.
### 8.4 Performance testing on large datasets.

---

## Phase 9 — Data Retention & Optimization

### 9.1 Historical aggregation logic.
### 9.2 Scheduled cleanup job.
### 9.3 Monitoring and logging.

---

## Phase 10 — Hardening & Production Readiness

### 10.1 RLS penetration testing.
### 10.2 Load testing.
### 10.3 Error monitoring integration.
### 10.4 Final performance optimization.

---

# 11. Deployment Strategy

- Hosted at: ontapi.com (Flutter Web)
- Separate Supabase environments: dev / staging / production
- CI/CD pipeline for Flutter Web
- Environment variables managed securely
- Database migrations version controlled

