BEGIN;
-- Setup test data
INSERT INTO public.tenants (id, name) VALUES ('00000000-0000-0000-0000-000000000001', 'Test Tenant');
INSERT INTO public.branches (id, tenant_id, name, avg_service_duration) 
VALUES ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Test Branch', 15);

-- 1. Test Valid Order
INSERT INTO public.orders (tenant_id, branch_id, order_number, status, source)
VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'A-001', 'waiting', 'manual');

-- 2. Test Invalid Status (Should FAIL)
DO \$\$ 
BEGIN
    BEGIN
        INSERT INTO public.orders (tenant_id, branch_id, order_number, status, source)
        VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'A-002', 'invalid_status', 'manual');
        RAISE EXCEPTION 'Constraint FAILED: Invalid status was accepted';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'Success: Invalid status was rejected as expected';
    END;
END \$\$;

-- 3. Test Invalid Source (Should FAIL)
DO \$\$ 
BEGIN
    BEGIN
        INSERT INTO public.orders (tenant_id, branch_id, order_number, status, source)
        VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'A-003', 'waiting', 'invalid_source');
        RAISE EXCEPTION 'Constraint FAILED: Invalid source was accepted';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'Success: Invalid source was rejected as expected';
    END;
END \$\$;

ROLLBACK;
