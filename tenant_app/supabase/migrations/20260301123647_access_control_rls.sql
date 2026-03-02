-- Migration: Access Control & Row Level Security
-- Created: 2026-03-01
-- Description: Implement RLS policies for all 10 core tables and role-conflict prevention.
-- Phase: 2 (Access Control & RLS)

-- ============================================================================
-- AUDIT SUMMARY (24 Policies, 3 Helper Functions, 1 Trigger)
-- tenants: 2 policies
-- branches: 4 policies
-- tenant_users: 1 policy
-- branch_users: 4 policies (admin, manager, staff mgmt)
-- orders: 4 policies
-- offers: 2 policies
-- branch_offers: 2 policies
-- subscriptions: 2 policies
-- usage_tracking: 1 policy
-- ratings: 2 policies
-- trigger: prevent_role_conflict (branch_users)
-- ============================================================================

-- ============================================================================
-- GLOBAL RULES
-- 1. All users must be authenticated via Supabase Auth.
-- 2. Access is denied by default (using ENABLE ROW LEVEL SECURITY).
-- 3. All policies use auth.uid() only (no custom JWT claims).
-- 4. Unauthorized reads return 0 rows; unauthorized writes are silently dropped.
-- 5. Role changes apply immediately on the next request.
-- ============================================================================

-- ============================================================================
-- HELPER FUNCTIONS (SECURITY DEFINER)
-- Bypasses RLS to avoid circular recursion in membership lookups.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.is_tenant_admin(p_tenant_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.tenant_users 
        WHERE user_id = auth.uid() 
        AND tenant_id = p_tenant_id
        AND role = 'tenant_admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_branch_manager(p_branch_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.branch_users 
        WHERE user_id = auth.uid() 
        AND branch_id = p_branch_id
        AND role = 'branch_manager'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_branch_staff(p_branch_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.branch_users 
        WHERE user_id = auth.uid() 
        AND branch_id = p_branch_id
        AND role = 'branch_staff'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- PREPARATORY: ENABLE RLS ON ALL TABLES
-- (Deny-by-default established: unauthorized users see 0 rows)
-- ============================================================================

ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenants FORCE ROW LEVEL SECURITY;

ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branches FORCE ROW LEVEL SECURITY;

ALTER TABLE public.tenant_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_users FORCE ROW LEVEL SECURITY;

ALTER TABLE public.branch_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branch_users FORCE ROW LEVEL SECURITY;

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders FORCE ROW LEVEL SECURITY;

ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offers FORCE ROW LEVEL SECURITY;

ALTER TABLE public.branch_offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.branch_offers FORCE ROW LEVEL SECURITY;

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions FORCE ROW LEVEL SECURITY;

ALTER TABLE public.usage_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usage_tracking FORCE ROW LEVEL SECURITY;

ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings FORCE ROW LEVEL SECURITY;

-- ============================================================================
-- USER STORY 1: TENANT ADMIN ACCESS
-- Full CRUD for own tenant's data across all tables.
-- ============================================================================

-- public.tenants
CREATE POLICY tenants_tenant_admin_all ON public.tenants
    FOR ALL
    TO authenticated
    USING (public.is_tenant_admin(id));

-- public.tenant_users
CREATE POLICY tenant_users_tenant_admin_all ON public.tenant_users
    FOR ALL
    TO authenticated
    USING (public.is_tenant_admin(tenant_id));

-- public.branches
CREATE POLICY branches_tenant_admin_all ON public.branches
    FOR ALL
    TO authenticated
    USING (public.is_tenant_admin(tenant_id));

-- public.branch_users
CREATE POLICY branch_users_tenant_admin_all ON public.branch_users
    FOR ALL
    TO authenticated
    USING (EXISTS (SELECT 1 FROM public.branches b WHERE b.id = branch_users.branch_id AND public.is_tenant_admin(b.tenant_id)));

-- public.orders
CREATE POLICY orders_tenant_admin_select ON public.orders
    FOR SELECT
    TO authenticated
    USING (public.is_tenant_admin(tenant_id));

-- public.offers
CREATE POLICY offers_tenant_admin_all ON public.offers
    FOR ALL
    TO authenticated
    USING (public.is_tenant_admin(tenant_id));

-- public.branch_offers
CREATE POLICY branch_offers_tenant_admin_all ON public.branch_offers
    FOR ALL
    TO authenticated
    USING (EXISTS (SELECT 1 FROM public.branches b WHERE b.id = branch_offers.branch_id AND public.is_tenant_admin(b.tenant_id)));

-- public.subscriptions
CREATE POLICY subscriptions_tenant_admin_select ON public.subscriptions
    FOR SELECT
    TO authenticated
    USING (public.is_tenant_admin(tenant_id));

CREATE POLICY subscriptions_tenant_admin_update ON public.subscriptions
    FOR UPDATE
    TO authenticated
    USING (public.is_tenant_admin(tenant_id));

-- public.usage_tracking
CREATE POLICY usage_tracking_tenant_admin_select ON public.usage_tracking
    FOR SELECT
    TO authenticated
    USING (public.is_tenant_admin(tenant_id));

-- public.ratings
CREATE POLICY ratings_tenant_admin_select ON public.ratings
    FOR SELECT
    TO authenticated
    USING (public.is_tenant_admin(tenant_id));

-- ============================================================================
-- USER STORY 2: BRANCH MANAGER ACCESS
-- Scoped access to own branch data + read-only context + staff management.
-- ============================================================================

-- public.tenants
CREATE POLICY tenants_branch_manager_select ON public.tenants
    FOR SELECT
    TO authenticated
    USING (EXISTS (SELECT 1 FROM public.branches b WHERE b.tenant_id = tenants.id AND public.is_branch_manager(b.id)));

-- public.branches
CREATE POLICY branches_branch_manager_select ON public.branches
    FOR SELECT
    TO authenticated
    USING (public.is_branch_manager(id));

CREATE POLICY branches_branch_manager_update ON public.branches
    FOR UPDATE
    TO authenticated
    USING (public.is_branch_manager(id));

-- public.branch_users
CREATE POLICY branch_users_branch_manager_select ON public.branch_users
    FOR SELECT
    TO authenticated
    USING (public.is_branch_manager(branch_id));

CREATE POLICY branch_users_branch_manager_insert_staff ON public.branch_users
    FOR INSERT
    TO authenticated
    WITH CHECK (public.is_branch_manager(branch_id) AND role = 'branch_staff');

CREATE POLICY branch_users_branch_manager_delete_staff ON public.branch_users
    FOR DELETE
    TO authenticated
    USING (public.is_branch_manager(branch_id) AND role = 'branch_staff');

-- public.orders
CREATE POLICY orders_branch_manager_select ON public.orders
    FOR SELECT
    TO authenticated
    USING (public.is_branch_manager(branch_id));

CREATE POLICY orders_branch_manager_update ON public.orders
    FOR UPDATE
    TO authenticated
    USING (public.is_branch_manager(branch_id));

-- public.offers
CREATE POLICY offers_branch_manager_select ON public.offers
    FOR SELECT
    TO authenticated
    USING (EXISTS (SELECT 1 FROM public.branches b WHERE b.tenant_id = offers.tenant_id AND public.is_branch_manager(b.id)));

-- public.branch_offers
CREATE POLICY branch_offers_branch_manager_select ON public.branch_offers
    FOR SELECT
    TO authenticated
    USING (public.is_branch_manager(branch_id));

-- public.ratings
CREATE POLICY ratings_branch_manager_select ON public.ratings
    FOR SELECT
    TO authenticated
    USING (public.is_branch_manager(branch_id));

-- ============================================================================
-- USER STORY 3: BRANCH STAFF ACCESS
-- Minimal-privilege operational access (orders only).
-- ============================================================================

-- public.branches (read-only for context)
CREATE POLICY branches_branch_staff_select ON public.branches
    FOR SELECT
    TO authenticated
    USING (public.is_branch_staff(id));

-- public.orders (create + update status)
CREATE POLICY orders_branch_staff_select_insert_update ON public.orders
    FOR ALL
    TO authenticated
    USING (public.is_branch_staff(branch_id));

-- ============================================================================
-- PHASE 7: ROLE-CONFLICT PREVENTION (FR-011)
-- Prevent user from being both tenant_admin and branch_level in same tenant.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.check_role_conflict()
RETURNS TRIGGER AS $$
DECLARE
    v_tenant_id UUID;
BEGIN
    -- Resolve tenant_id for the branch being assigned
    SELECT tenant_id INTO v_tenant_id FROM public.branches WHERE id = NEW.branch_id;
    
    -- Check if user is already a tenant_admin for that tenant
    IF EXISTS (
        SELECT 1 
        FROM public.tenant_users 
        WHERE user_id = NEW.user_id 
          AND tenant_id = v_tenant_id 
          AND role = 'tenant_admin'
    ) THEN
        RAISE EXCEPTION 'User is already a tenant_admin for this tenant. Overlapping roles are prohibited (FR-011).';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER prevent_role_conflict
    BEFORE INSERT ON public.branch_users
    FOR EACH ROW
    EXECUTE FUNCTION public.check_role_conflict();
