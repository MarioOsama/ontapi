-- Phase 3: Authentication & Role Assignment
-- Description: Create invitations table, signup trigger, and role assignment logic.

-- 1. Create invitations table
CREATE TABLE IF NOT EXISTS public.invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('branch_manager', 'branch_staff')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'revoked', 'expired')),
    token UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    invited_by UUID NOT NULL REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '48 hours')
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_invitations_tenant_id ON public.invitations(tenant_id);
CREATE INDEX IF NOT EXISTS idx_invitations_branch_id ON public.invitations(branch_id);
CREATE INDEX IF NOT EXISTS idx_invitations_token ON public.invitations(token);
CREATE INDEX IF NOT EXISTS idx_invitations_email ON public.invitations(email);

-- Partial unique index to prevent duplicate pending invitations for same branch + email
CREATE UNIQUE INDEX IF NOT EXISTS uq_invitations_branch_email_pending 
ON public.invitations(branch_id, email) 
WHERE (status = 'pending');

-- 2. Enforce one tenant_admin per user platform-wide (FR-019)
ALTER TABLE public.tenant_users ADD CONSTRAINT uq_tenant_users_user_id UNIQUE (user_id);

-- 3. Signup Trigger: Auto-provision tenant + branch + admin role
CREATE OR REPLACE FUNCTION public.handle_new_user_signup()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_tenant_id UUID;
    business_nm TEXT;
BEGIN
    -- Extract business name from metadata
    business_nm := COALESCE(NEW.raw_user_meta_data->>'business_name', 'My Business');

    -- Create tenant
    INSERT INTO public.tenants (name)
    VALUES (business_nm)
    RETURNING id INTO new_tenant_id;

    -- Create default branch
    INSERT INTO public.branches (tenant_id, name, avg_service_duration)
    VALUES (new_tenant_id, 'Main Branch', 10);

    -- Assign admin role
    INSERT INTO public.tenant_users (tenant_id, user_id, role)
    VALUES (new_tenant_id, NEW.id, 'tenant_admin');

    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_signup();

-- 4. Accept Invitation Function
CREATE OR REPLACE FUNCTION public.accept_invitation(invitation_token UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    invite_record RECORD;
    jwt_email TEXT;
    current_user_id UUID;
BEGIN
    current_user_id := auth.uid();
    jwt_email := auth.jwt()->>'email';

    -- 1. Validate token, status, and expiry
    SELECT * INTO invite_record 
    FROM public.invitations 
    WHERE token = invitation_token 
    AND status = 'pending' 
    AND expires_at > now();

    IF NOT FOUND THEN
        RETURN json_build_object('status', 'invalid');
    END IF;

    -- 2. Verify email match
    IF invite_record.email != jwt_email THEN
        RETURN json_build_object('status', 'email_mismatch');
    END IF;

    -- 3. Check for role conflict (tenant_admin cannot hold branch role in same tenant)
    IF EXISTS (
        SELECT 1 FROM public.tenant_users 
        WHERE user_id = current_user_id 
        AND tenant_id = invite_record.tenant_id
    ) THEN
        RETURN json_build_object('status', 'role_conflict');
    END IF;

    -- 4. Create branch membership
    -- Note: The prevent_role_conflict trigger from Phase 2 also acts as a safety net here.
    BEGIN
        INSERT INTO public.branch_users (branch_id, user_id, role)
        VALUES (invite_record.branch_id, current_user_id, invite_record.role);
    EXCEPTION WHEN unique_violation THEN
        RETURN json_build_object('status', 'already_member');
    END;

    -- 5. Mark invitation accepted
    UPDATE public.invitations 
    SET status = 'accepted' 
    WHERE id = invite_record.id;

    RETURN json_build_object(
        'status', 'success',
        'branch_id', invite_record.branch_id,
        'role', invite_record.role,
        'tenant_id', invite_record.tenant_id
    );
END;
$$;

-- 5. RLS Policies for Invitations
ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;

-- Tenant Admin: Full control over their tenant's invitations
CREATE POLICY "Tenant admins can manage invitations"
ON public.invitations
FOR ALL
TO authenticated
USING (
    public.is_tenant_admin(auth.uid()) AND 
    tenant_id IN (SELECT tenant_id FROM public.tenant_users WHERE user_id = auth.uid())
)
WITH CHECK (
    public.is_tenant_admin(auth.uid()) AND 
    tenant_id IN (SELECT tenant_id FROM public.tenant_users WHERE user_id = auth.uid())
);

-- Branch Manager: Manage invitations for their branch
CREATE POLICY "Branch managers can manage branch invitations"
ON public.invitations
FOR ALL
TO authenticated
USING (
    public.is_branch_manager(auth.uid()) AND 
    branch_id IN (SELECT branch_id FROM public.branch_users WHERE user_id = auth.uid())
)
WITH CHECK (
    public.is_branch_manager(auth.uid()) AND 
    branch_id IN (SELECT branch_id FROM public.branch_users WHERE user_id = auth.uid())
);

-- 6. Admin Staff Listing Function
CREATE OR REPLACE FUNCTION public.get_tenant_staff(p_tenant_id UUID)
RETURNS TABLE (
    id UUID,
    branch_id UUID,
    role TEXT,
    email TEXT,
    branch_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Check if the current user is a tenant admin for the requested tenant
    IF NOT public.is_tenant_admin(auth.uid()) OR NOT EXISTS (
        SELECT 1 FROM public.tenant_users
        WHERE user_id = auth.uid() AND tenant_id = p_tenant_id
    ) THEN
        RAISE EXCEPTION 'Access denied';
    END IF;

    RETURN QUERY
    SELECT 
        bu.id,
        bu.branch_id,
        bu.role,
        au.email::TEXT,
        b.name AS branch_name
    FROM public.branch_users bu
    JOIN public.branches b ON bu.branch_id = b.id
    JOIN auth.users au ON bu.user_id = au.id
    WHERE b.tenant_id = p_tenant_id;
END;
$$;

