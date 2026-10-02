-- Run after migrations. Any failed expectation raises and aborts (psql -v ON_ERROR_STOP=1).
\set ON_ERROR_STOP on
BEGIN;

-- helper: assert a statement fails
CREATE FUNCTION pg_temp.expect_fail(stmt text, label text) RETURNS void AS $$
BEGIN
    BEGIN
        EXECUTE stmt;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'PASS (rejected): %', label;
        RETURN;
    END;
    RAISE EXCEPTION 'FAIL (was accepted): %', label;
END;
$$ LANGUAGE plpgsql;

-- 1. Category self-reference: Học tập > IELTS > Speaking
INSERT INTO categories (id, name, parent_id, level) VALUES
  ('00000000-0000-0000-0000-0000000000a1', 'Học tập', NULL, 1),
  ('00000000-0000-0000-0000-0000000000a2', 'IELTS',   '00000000-0000-0000-0000-0000000000a1', 2),
  ('00000000-0000-0000-0000-0000000000a3', 'Speaking','00000000-0000-0000-0000-0000000000a2', 3),
  ('00000000-0000-0000-0000-0000000000a4', 'Toán',    NULL, 1),
  ('00000000-0000-0000-0000-0000000000a5', 'Speaking','00000000-0000-0000-0000-0000000000a4', 2);  -- same name, different branch: allowed

DO $$ BEGIN
  IF (SELECT count(*) FROM categories c JOIN categories p ON c.parent_id = p.id
      WHERE c.name = 'Speaking' AND p.name = 'IELTS') <> 1 THEN
    RAISE EXCEPTION 'FAIL: tree not represented correctly';
  END IF;
  RAISE NOTICE 'PASS: Học tập > IELTS > Speaking stored; same name allowed in another branch';
END $$;

SELECT pg_temp.expect_fail($$INSERT INTO categories (name,parent_id,level) VALUES ('X',NULL,2)$$, 'level 2 without parent');
SELECT pg_temp.expect_fail($$INSERT INTO categories (name,parent_id,level) VALUES ('X','00000000-0000-0000-0000-0000000000a1',1)$$, 'level 1 with parent');
SELECT pg_temp.expect_fail($$INSERT INTO categories (name,parent_id,level) VALUES ('X','00000000-0000-0000-0000-0000000000a1',3)$$, 'level skips a tier');
SELECT pg_temp.expect_fail($$INSERT INTO categories (name,parent_id,level) VALUES ('Y','00000000-0000-0000-0000-0000000000a3',4)$$, 'depth 4');
SELECT pg_temp.expect_fail($$INSERT INTO categories (name,parent_id,level) VALUES ('ielts','00000000-0000-0000-0000-0000000000a1',2)$$, 'duplicate sibling name (case-insensitive)');
SELECT pg_temp.expect_fail($$INSERT INTO categories (name,parent_id,level) VALUES ('học tập',NULL,1)$$, 'duplicate root name');
SELECT pg_temp.expect_fail($$INSERT INTO categories (name,parent_id,level) VALUES ('Z','00000000-0000-0000-0000-00000000ffff',2)$$, 'nonexistent parent');

-- 2. Video / category relationship
INSERT INTO videos (id, user_id, url, category_id) VALUES
  ('00000000-0000-0000-0000-0000000000b1','11111111-1111-1111-1111-111111111111','https://youtu.be/x','00000000-0000-0000-0000-0000000000a3');
DO $$ BEGIN
  IF (SELECT status FROM videos WHERE id='00000000-0000-0000-0000-0000000000b1') <> 'PROCESSING' THEN
    RAISE EXCEPTION 'FAIL: default status';
  END IF;
  RAISE NOTICE 'PASS: video default status PROCESSING, linked to category';
END $$;
SELECT pg_temp.expect_fail($$INSERT INTO videos (user_id,url,category_id) VALUES ('11111111-1111-1111-1111-111111111111','u','00000000-0000-0000-0000-00000000ffff')$$, 'video with unknown category');
SELECT pg_temp.expect_fail($$INSERT INTO videos (user_id,url,status) VALUES ('11111111-1111-1111-1111-111111111111','u','BOGUS')$$, 'invalid status');
SELECT pg_temp.expect_fail($$INSERT INTO videos (user_id) VALUES ('11111111-1111-1111-1111-111111111111')$$, 'video without url');
SELECT pg_temp.expect_fail($$DELETE FROM categories WHERE id='00000000-0000-0000-0000-0000000000a3'$$, 'delete category still used by a video');

-- 3. Interaction / video relationship + append-only
INSERT INTO video_interactions (user_id, video_id, action) VALUES
  ('11111111-1111-1111-1111-111111111111','00000000-0000-0000-0000-0000000000b1','SAVED'),
  ('11111111-1111-1111-1111-111111111111','00000000-0000-0000-0000-0000000000b1','OPENED'),
  ('11111111-1111-1111-1111-111111111111','00000000-0000-0000-0000-0000000000b1','REOPENED');
DO $$ BEGIN
  IF (SELECT count(*) FROM video_interactions) <> 3 THEN RAISE EXCEPTION 'FAIL: interactions'; END IF;
  RAISE NOTICE 'PASS: 3 interactions stored for video';
END $$;
SELECT pg_temp.expect_fail($$INSERT INTO video_interactions (user_id,video_id,action) VALUES ('11111111-1111-1111-1111-111111111111','00000000-0000-0000-0000-00000000ffff','SAVED')$$, 'interaction for unknown video');
SELECT pg_temp.expect_fail($$INSERT INTO video_interactions (user_id,video_id,action) VALUES ('11111111-1111-1111-1111-111111111111','00000000-0000-0000-0000-0000000000b1','WATCHED')$$, 'invalid action');
SELECT pg_temp.expect_fail($$UPDATE video_interactions SET action='SAVED'$$, 'update interaction history');
SELECT pg_temp.expect_fail($$DELETE FROM video_interactions$$, 'delete interaction history');
SELECT pg_temp.expect_fail($$DELETE FROM videos WHERE id='00000000-0000-0000-0000-0000000000b1'$$, 'hard-delete video with history');

-- 4. Indexes from §7 exist
DO $$
DECLARE missing text;
BEGIN
  SELECT string_agg(i, ', ') INTO missing FROM unnest(ARRAY[
    'idx_videos_user_id','idx_videos_category_id','idx_videos_last_opened_at','idx_videos_saved_at',
    'idx_interactions_video_id','idx_interactions_user_id','idx_categories_parent_id']) i
  WHERE NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = i);
  IF missing IS NOT NULL THEN RAISE EXCEPTION 'FAIL: missing indexes %', missing; END IF;
  RAISE NOTICE 'PASS: all 7 required indexes exist';
END $$;

ROLLBACK;  -- leave the database clean
