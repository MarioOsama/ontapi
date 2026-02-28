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

-- Indexes

-- Branches tenant_id index
CREATE INDEX IF NOT EXISTS idx_branches_tenant_id ON public.branches(tenant_id);
