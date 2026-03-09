ALTER TABLE lobbies
  ADD COLUMN IF NOT EXISTS pack_ids TEXT[] DEFAULT '{}';

ALTER TABLE lobbies
  ADD COLUMN IF NOT EXISTS custom_questions JSONB DEFAULT '[]'::jsonb;
