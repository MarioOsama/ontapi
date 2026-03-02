-- Seed data and configurations

-- Create tenant-logos storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public) 
VALUES ('tenant-logos', 'tenant-logos', true)
ON CONFLICT (id) DO NOTHING;

-- Delete existing policies to recreate them cleanly (optional, but safe)
DROP POLICY IF EXISTS "Public Access to tenant-logos" ON storage.objects;
DROP POLICY IF EXISTS "Auth Insert to tenant-logos" ON storage.objects;
DROP POLICY IF EXISTS "Auth Update to tenant-logos" ON storage.objects;

-- Policy: Anyone can view the logos
CREATE POLICY "Public Access to tenant-logos"
ON storage.objects FOR SELECT
USING (bucket_id = 'tenant-logos');

-- Policy: Authenticated users can upload logos
CREATE POLICY "Auth Insert to tenant-logos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'tenant-logos');

-- Policy: Authenticated users can update logos
CREATE POLICY "Auth Update to tenant-logos"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'tenant-logos');
