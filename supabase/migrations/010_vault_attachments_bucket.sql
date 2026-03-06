-- Supabase Storage bucket for encrypted vault attachments.
-- Files are AES-256-GCM encrypted client-side before upload.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'vault-attachments',
  'vault-attachments',
  false,
  11534336, -- ~11 MB (10 MB plaintext + encryption overhead)
  NULL      -- any MIME type (files are encrypted blobs anyway)
)
ON CONFLICT (id) DO NOTHING;

-- RLS: users can only manage their own attachments.
-- Objects are stored as: {user_id}/{attachment_id}.enc

CREATE POLICY "Users can upload own attachments"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'vault-attachments'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can read own attachments"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'vault-attachments'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can delete own attachments"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'vault-attachments'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
