module Sound.Tidal.Arc
  (module Sound.Tidal.Arc,
   module Sound.Tidal.Time
  )
where

-- (c) Alex McLean 2022
-- Shared under the terms of the GNU Public License v. 3.0

import Sound.Tidal.Time
import Sound.Tidal.Types

-- | Similar to 'fmap' but time is relative to the cycle (i.e. the
-- sam of the start of the arc)
mapCycle :: (Time -> Time) -> Arc -> Arc
mapCycle f (Arc s e) = Arc (sam' + f (s - sam')) (sam' + f (e - sam'))
         where sam' = sam s

-- | @isIn a t@ is @True@ if @t@ is inside
-- the arc represented by @a@.
isIn :: Arc -> Time -> Bool
isIn (Arc s e) t = t >= s && t < e

-- | Intersection of two timearcs
sect :: Arc -> Arc -> Arc
sect (Arc b e) (Arc b' e') = Arc (max b b') (min e e')

-- | Intersection of two timearcs, returns Nothing if they don't intersect
maybeSect :: Arc -> Arc -> Maybe Arc
maybeSect a b = check $ sect a b
  where check :: Arc -> Maybe Arc
        check (Arc a b) | b <= a = Nothing
                        | otherwise = Just (Arc a b)

-- | convex hull union
hull :: Arc -> Arc -> Arc
hull (Arc s e) (Arc s' e') = Arc (min s s') (max e e')

-- | Splits a timearc at cycle boundaries
splitArcs :: Arc -> [Arc]
splitArcs (Arc b e) | e <= b = []
                    | sam b == sam e = [Arc b e]
                    | otherwise
  = Arc b (nextSam b) : splitArcs (Arc (nextSam b) e)

-- | Shifts a timearc to one of equal duration that starts within cycle zero.
-- (Note that the output timearc probably does not start *at* Time 0 --
-- that only happens when the input Arc starts at an integral Time.)
cycleArc :: Arc -> Arc
cycleArc (Arc b e) = Arc b' e'
  where b' = cyclePos b
        e' = b' + (e - b)
