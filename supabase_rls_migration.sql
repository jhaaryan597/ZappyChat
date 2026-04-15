-- ============================================================
-- ZappyChat: Message UUID + Row-Level Security Migration
-- Run this in: Supabase Dashboard → SQL Editor
-- ============================================================

-- ============================================================
-- PART A: Add UUID primary key to messages table
-- (Fixes race condition from using timestamp as PK)
-- ============================================================

-- Enable the uuid extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Add id column (UUID, auto-generated for existing rows)
ALTER TABLE messages ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid();

-- Backfill any existing rows that have no id
UPDATE messages SET id = gen_random_uuid() WHERE id IS NULL;

-- Make id NOT NULL
ALTER TABLE messages ALTER COLUMN id SET NOT NULL;

-- Drop old primary key on 'sent' and set 'id' as the new PK
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_pkey;
ALTER TABLE messages ADD PRIMARY KEY (id);

-- Keep an index on sent for ordering performance
CREATE INDEX IF NOT EXISTS idx_messages_sent ON messages(sent);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);

-- ============================================================
-- STEP 1: Enable RLS on both tables
-- ============================================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- STEP 2: USERS table policies
-- ============================================================

-- Users can read all profiles (needed to show contact list)
CREATE POLICY "users_select_all"
  ON users FOR SELECT
  TO authenticated
  USING (true);

-- Users can only insert their own profile
CREATE POLICY "users_insert_own"
  ON users FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid()::text);

-- Users can only update their own profile
CREATE POLICY "users_update_own"
  ON users FOR UPDATE
  TO authenticated
  USING (id = auth.uid()::text)
  WITH CHECK (id = auth.uid()::text);

-- Users cannot delete profiles (admin only — remove if needed)
-- CREATE POLICY "users_delete_own" ON users FOR DELETE TO authenticated USING (id = auth.uid()::text);

-- ============================================================
-- STEP 3: MESSAGES table policies
-- ============================================================

-- Users can only read messages they sent or received
CREATE POLICY "messages_select_participant"
  ON messages FOR SELECT
  TO authenticated
  USING (
    "fromId" = auth.uid()::text
    OR "told" = auth.uid()::text
  );

-- Users can only insert messages where they are the sender
CREATE POLICY "messages_insert_own"
  ON messages FOR INSERT
  TO authenticated
  WITH CHECK ("fromId" = auth.uid()::text);

-- Users can only update messages they sent (for edit feature)
CREATE POLICY "messages_update_own"
  ON messages FOR UPDATE
  TO authenticated
  USING ("fromId" = auth.uid()::text)
  WITH CHECK ("fromId" = auth.uid()::text);

-- Users can only delete messages they sent
CREATE POLICY "messages_delete_own"
  ON messages FOR DELETE
  TO authenticated
  USING ("fromId" = auth.uid()::text);

-- ============================================================
-- STEP 4 (Optional): Storage RLS for chat-files bucket
-- Run this only if your bucket is not already restricted.
-- ============================================================

-- Allow authenticated users to upload files (to their own folder)
-- CREATE POLICY "storage_insert_authenticated"
--   ON storage.objects FOR INSERT
--   TO authenticated
--   WITH CHECK (bucket_id = 'chat-files');

-- Allow users to read any file in the bucket (needed for signed URLs)
-- CREATE POLICY "storage_select_authenticated"
--   ON storage.objects FOR SELECT
--   TO authenticated
--   USING (bucket_id = 'chat-files');
