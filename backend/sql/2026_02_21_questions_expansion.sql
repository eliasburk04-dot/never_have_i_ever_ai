-- Never Have I Ever: question pool expansion + selector indexing
-- Date: 2026-02-21

BEGIN;

ALTER TABLE rounds
  DROP CONSTRAINT IF EXISTS rounds_question_source_id_fkey;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'rounds'
      AND column_name = 'question_source_id'
      AND udt_name = 'uuid'
  ) THEN
    ALTER TABLE rounds
      ALTER COLUMN question_source_id TYPE TEXT USING question_source_id::TEXT;
  END IF;
END
$$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'questions'
      AND column_name = 'lang'
  ) THEN
    IF NOT EXISTS (
      SELECT 1
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_name = 'questions_legacy_2026_02_21'
    ) THEN
      ALTER TABLE questions RENAME TO questions_legacy_2026_02_21;
    ELSE
      DROP TABLE questions;
    END IF;
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS questions (
  id TEXT PRIMARY KEY,
  game_key TEXT NOT NULL DEFAULT 'never_have_i_ever',
  text_en TEXT NOT NULL,
  text_de TEXT NOT NULL,
  text_es TEXT NOT NULL,
  category TEXT NOT NULL,
  subcategory TEXT NOT NULL DEFAULT 'general',
  intensity SMALLINT NOT NULL CHECK (intensity BETWEEN 1 AND 10),
  is_nsfw BOOLEAN NOT NULL DEFAULT FALSE,
  is_premium BOOLEAN NOT NULL DEFAULT FALSE,
  shock_factor REAL NOT NULL CHECK (shock_factor >= 0 AND shock_factor <= 1),
  vulnerability_level REAL NOT NULL CHECK (vulnerability_level >= 0 AND vulnerability_level <= 1),
  energy TEXT NOT NULL CHECK (energy IN ('light', 'medium', 'heavy')),
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE lobbies
  ADD COLUMN IF NOT EXISTS used_question_ids TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[];

ALTER TABLE lobbies
  ADD COLUMN IF NOT EXISTS escalation_history JSONB NOT NULL DEFAULT '[]'::jsonb;

DO $$
DECLARE
  current_udt TEXT;
BEGIN
  SELECT c.udt_name
  INTO current_udt
  FROM information_schema.columns c
  WHERE c.table_schema = 'public'
    AND c.table_name = 'lobbies'
    AND c.column_name = 'used_question_ids';

  IF current_udt = '_uuid' THEN
    ALTER TABLE lobbies
      ALTER COLUMN used_question_ids TYPE TEXT[]
      USING COALESCE(used_question_ids::TEXT[], ARRAY[]::TEXT[]);
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS idx_questions_select_base
  ON questions (game_key, status, intensity, is_nsfw, category);

CREATE INDEX IF NOT EXISTS idx_questions_subcategory
  ON questions (game_key, status, category, subcategory, intensity);

CREATE INDEX IF NOT EXISTS idx_questions_energy
  ON questions (game_key, status, energy, intensity);

CREATE INDEX IF NOT EXISTS idx_questions_nsfw_energy
  ON questions (game_key, status, is_nsfw, energy, intensity);

COMMIT;
