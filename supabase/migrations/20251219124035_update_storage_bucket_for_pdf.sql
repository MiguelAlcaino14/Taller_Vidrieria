/*
  # Update Storage Bucket to Accept PDF Files

  ## Overview
  Updates the order_documents storage bucket to accept PDF files in addition to SVG files.

  ## Changes
  1. Storage Bucket Configuration
    - Update allowed_mime_types to include 'application/pdf'
    - Maintains existing SVG support

  ## Security
  - No changes to RLS policies
  - Existing policies continue to apply to all file types

  ## Notes
  - PDF files will be stored alongside SVG files in the same bucket
  - File naming pattern remains: {user_id}_{timestamp}_{order_code}.{extension}
  - Public bucket allows direct access to files for viewing in browser
*/

UPDATE storage.buckets
SET allowed_mime_types = ARRAY['image/svg+xml', 'application/svg+xml', 'application/pdf']::text[]
WHERE id = 'order_documents';
