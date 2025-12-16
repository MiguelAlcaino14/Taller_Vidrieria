/*
  # Create Storage Bucket for Order Documents

  ## Overview
  Creates a storage bucket for SVG order documents with appropriate RLS policies.

  ## Changes
  1. Create `order_documents` storage bucket
  2. Set bucket to public (files accessible via public URL)
  3. Configure RLS policies for secure access

  ## Security
  - Users can only upload to their own folder (user_id prefix)
  - Users can only read/delete their own files
  - All authenticated users can upload files

  ## Notes
  - Files are named with pattern: {user_id}_{timestamp}_{order_code}.svg
  - Public bucket allows direct access to files for viewing in browser
*/

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'order_documents',
  'order_documents',
  true,
  10485760,
  ARRAY['image/svg+xml', 'application/svg+xml']::text[]
)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Users can upload own order documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'order_documents' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can view own order documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'order_documents' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can update own order documents"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'order_documents' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can delete own order documents"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'order_documents' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
