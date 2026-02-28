-- Migration: Database Foundation
-- Created: 2026-02-27
-- Description: Create all core tables, constraints, indexes, and enums for the Ontapi tenant app.
-- Phase: 1 (Database Foundation)

-- Extensions
CREATE EXTENSION IF NOT EXISTS moddatetime SCHEMA extensions;

-- Tables

-- Tenants table
CREATE TABLE IF NOT EXISTS public.tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    logo_url TEXT,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Branches table
CREATE TABLE IF NOT EXISTS public.branches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    address TEXT,
    avg_service_duration INTEGER NOT NULL CHECK (avg_service_duration > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Tenant users table
CREATE TABLE IF NOT EXISTS public.tenant_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE RESTRICT,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('tenant_admin')),
    UNIQUE(tenant_id, user_id)
);

-- Branch users table
CREATE TABLE IF NOT EXISTS public.branch_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE RESTRICT,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('branch_manager', 'branch_staff')),
    UNIQUE(branch_id, user_id)
);

-- Orders table
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    order_number TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'waiting' CHECK (status IN ('waiting', 'in_progress', 'done', 'cancelled')),
    source TEXT NOT NULL CHECK (source IN ('manual', 'api')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

-- Offers table
CREATE TABLE IF NOT EXISTS public.offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    is_global BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Branch offers junction table
CREATE TABLE IF NOT EXISTS public.branch_offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    offer_id UUID NOT NULL REFERENCES public.offers(id) ON DELETE CASCADE,
    UNIQUE(branch_id, offer_id)
);

-- Subscriptions table
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    plan_name TEXT NOT NULL,
    monthly_order_limit INTEGER NOT NULL,
    current_period_start DATE NOT NULL,
    current_period_end DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Usage tracking table
CREATE TABLE IF NOT EXISTS public.usage_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    month TEXT NOT NULL, -- Format: YYYY-MM
    orders_count INTEGER NOT NULL DEFAULT 0,
    UNIQUE(tenant_id, month)
);

-- Ratings table
CREATE TABLE IF NOT EXISTS public.ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    feedback TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(order_id)
);

-- Triggers for updated_at

-- Tenants updated_at trigger
CREATE TRIGGER handle_tenants_updated_at
    BEFORE UPDATE ON public.tenants
    FOR EACH ROW
    EXECUTE PROCEDURE extensions.moddatetime(updated_at);

-- Branches updated_at trigger
CREATE TRIGGER handle_branches_updated_at
    BEFORE UPDATE ON public.branches
    FOR EACH ROW
    EXECUTE PROCEDURE extensions.moddatetime(updated_at);

-- Offers updated_at trigger
CREATE TRIGGER handle_offers_updated_at
    BEFORE UPDATE ON public.offers
    FOR EACH ROW
    EXECUTE PROCEDURE extensions.moddatetime(updated_at);

-- Indexes

-- Branches tenant_id index
CREATE INDEX IF NOT EXISTS idx_branches_tenant_id ON public.branches(tenant_id);

-- Tenant users indexes
CREATE INDEX IF NOT EXISTS idx_tenant_users_tenant_id ON public.tenant_users(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_users_user_id ON public.tenant_users(user_id);

-- Branch users indexes
CREATE INDEX IF NOT EXISTS idx_branch_users_branch_id ON public.branch_users(branch_id);
CREATE INDEX IF NOT EXISTS idx_branch_users_user_id ON public.branch_users(user_id);

-- Orders indexes
CREATE INDEX IF NOT EXISTS idx_orders_tenant_id ON public.orders(tenant_id);
CREATE INDEX IF NOT EXISTS idx_orders_branch_id ON public.orders(branch_id);

-- Offers indexes
CREATE INDEX IF NOT EXISTS idx_offers_tenant_id ON public.offers(tenant_id);

-- Branch offers indexes
CREATE INDEX IF NOT EXISTS idx_branch_offers_branch_id ON public.branch_offers(branch_id);
CREATE INDEX IF NOT EXISTS idx_branch_offers_offer_id ON public.branch_offers(offer_id);

-- Subscriptions indexes
CREATE INDEX IF NOT EXISTS idx_subscriptions_tenant_id ON public.subscriptions(tenant_id);

-- Usage tracking indexes
CREATE INDEX IF NOT EXISTS idx_usage_tracking_tenant_id ON public.usage_tracking(tenant_id);

-- Ratings indexes
CREATE INDEX IF NOT EXISTS idx_ratings_tenant_id ON public.ratings(tenant_id);
CREATE INDEX IF NOT EXISTS idx_ratings_branch_id ON public.ratings(branch_id);
