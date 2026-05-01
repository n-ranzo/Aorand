-- ══════════════════════════════════════════════════════════════
--  FOLLOW SYSTEM  –  Complete Production Setup
--  Run this entire script in your Supabase SQL Editor
-- ══════════════════════════════════════════════════════════════


-- ─────────────────────────────────────────────────────────────
-- 0. CREATE TABLE (if it doesn't exist yet)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.followers (
  id          bigserial PRIMARY KEY,
  follower_id  uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at  timestamptz NOT NULL DEFAULT now()
);


-- ─────────────────────────────────────────────────────────────
-- 1. TABLE-LEVEL GRANTS  (RLS alone is not enough)
-- ─────────────────────────────────────────────────────────────
GRANT SELECT, INSERT, DELETE ON public.followers TO authenticated;


-- ─────────────────────────────────────────────────────────────
-- 2. UNIQUE CONSTRAINT  (prevent duplicate follows)
-- ─────────────────────────────────────────────────────────────
ALTER TABLE public.followers
  DROP CONSTRAINT IF EXISTS uq_followers_pair;

ALTER TABLE public.followers
  ADD CONSTRAINT uq_followers_pair
  UNIQUE (follower_id, following_id);


-- ─────────────────────────────────────────────────────────────
-- 3. CLEAN UP DUPLICATE ROWS (if any exist from old bugs)
-- ─────────────────────────────────────────────────────────────
DELETE FROM public.followers
WHERE ctid NOT IN (
  SELECT MIN(ctid)
  FROM public.followers
  GROUP BY follower_id, following_id
);


-- ─────────────────────────────────────────────────────────────
-- 4. PERFORMANCE INDEXES
-- ─────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_followers_follower_id
  ON public.followers (follower_id);

CREATE INDEX IF NOT EXISTS idx_followers_following_id
  ON public.followers (following_id);


-- ─────────────────────────────────────────────────────────────
-- 5. ROW-LEVEL SECURITY
-- ─────────────────────────────────────────────────────────────
ALTER TABLE public.followers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "followers_select" ON public.followers;
CREATE POLICY "followers_select"
  ON public.followers FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "followers_insert" ON public.followers;
CREATE POLICY "followers_insert"
  ON public.followers FOR INSERT
  TO authenticated
  WITH CHECK (follower_id = auth.uid());

DROP POLICY IF EXISTS "followers_delete" ON public.followers;
CREATE POLICY "followers_delete"
  ON public.followers FOR DELETE
  TO authenticated
  USING (follower_id = auth.uid());


-- ─────────────────────────────────────────────────────────────
-- 6. is_following(p_current_user, p_target_user)
--    Returns TRUE if p_current_user follows p_target_user.
--    Parameter names MUST match what Flutter sends exactly.
-- ─────────────────────────────────────────────────────────────

-- Drop old signature with _id suffix so it can't conflict
DROP FUNCTION IF EXISTS public.is_following(uuid, uuid);

CREATE OR REPLACE FUNCTION public.is_following(
  p_current_user uuid,
  p_target_user  uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.followers
    WHERE follower_id  = p_current_user
      AND following_id = p_target_user
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_following(uuid, uuid) TO authenticated;


-- ─────────────────────────────────────────────────────────────
-- 7. toggle_follow(p_current_user, p_target_user)
--    Returns TRUE  = now following
--    Returns FALSE = now unfollowed
--    SECURITY DEFINER bypasses RLS so DELETE always works.
--    Parameter names MUST match what Flutter sends exactly.
-- ─────────────────────────────────────────────────────────────

-- Drop old signature with _id suffix so it can't conflict
DROP FUNCTION IF EXISTS public.toggle_follow(uuid, uuid);

CREATE OR REPLACE FUNCTION public.toggle_follow(
  p_current_user uuid,
  p_target_user  uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  _was_following boolean;
BEGIN
  IF p_current_user IS NULL OR p_target_user IS NULL THEN
    RAISE EXCEPTION 'toggle_follow: NULL user IDs are not allowed';
  END IF;

  IF p_current_user = p_target_user THEN
    RAISE EXCEPTION 'toggle_follow: cannot follow yourself';
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM public.followers
    WHERE follower_id  = p_current_user
      AND following_id = p_target_user
  ) INTO _was_following;

  IF _was_following THEN
    DELETE FROM public.followers
    WHERE follower_id  = p_current_user
      AND following_id = p_target_user;
    RETURN false;
  ELSE
    INSERT INTO public.followers (follower_id, following_id)
    VALUES (p_current_user, p_target_user)
    ON CONFLICT (follower_id, following_id) DO NOTHING;
    RETURN true;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.toggle_follow(uuid, uuid) TO authenticated;


-- ─────────────────────────────────────────────────────────────
-- 8. accept_follow_request(p_sender_id)
--    Inserts (follower=sender, following=auth.uid()).
--    SECURITY DEFINER needed because follower_id != auth.uid().
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.accept_follow_request(
  p_sender_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_sender_id IS NULL OR auth.uid() IS NULL THEN
    RAISE EXCEPTION 'accept_follow_request: invalid user';
  END IF;

  IF p_sender_id = auth.uid() THEN
    RAISE EXCEPTION 'accept_follow_request: cannot accept your own request';
  END IF;

  INSERT INTO public.followers (follower_id, following_id)
  VALUES (p_sender_id, auth.uid())
  ON CONFLICT (follower_id, following_id) DO NOTHING;
END;
$$;

GRANT EXECUTE ON FUNCTION public.accept_follow_request(uuid) TO authenticated;


-- ─────────────────────────────────────────────────────────────
-- 9. profile_stats VIEW
--    Live count from followers table — no caching, always fresh.
--    DROP TABLE first in case a stale table exists from prior runs.
-- ─────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS public.profile_stats CASCADE;
DROP VIEW  IF EXISTS public.profile_stats;

CREATE VIEW public.profile_stats AS
SELECT
  p.id,
  (
    SELECT COUNT(*)::int
    FROM public.followers
    WHERE following_id = p.id
  ) AS followers_count,
  (
    SELECT COUNT(*)::int
    FROM public.followers
    WHERE follower_id = p.id
  ) AS following_count
FROM public.profiles p;

GRANT SELECT ON public.profile_stats TO authenticated;
