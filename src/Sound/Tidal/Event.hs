{-# LANGUAGE DeriveFunctor #-}

module Sound.Tidal.Event
  (module Sound.Tidal.Time,
   module Sound.Tidal.Arc,
   module Sound.Tidal.Event
  )
where

import Data.Maybe (fromJust)
import Data.Monoid

import Sound.Tidal.Arc
import Sound.Tidal.Time
import Sound.Tidal.Types

import qualified Data.Map.Strict as Map

-- ************************************************************ --
-- Event

-- | Event metadata, currently just a list of source code position
-- ranges that an event is tagged with (see Types)

isAnalog :: Event a -> Bool
isAnalog (Event {whole = Nothing}) = True
isAnalog _ = False

isDigital :: Event a -> Bool
isDigital = not . isAnalog

-- | Returns true only if an event starts within given timearc
onsetIn :: Arc -> Event a -> Bool
onsetIn a e = isIn a (wholeBegin e)

wholeOrActive :: Event a -> Arc
wholeOrActive (Event {whole = Just a}) = a
wholeOrActive e = active e

-- | Get the onset of an event's 'whole'
wholeBegin :: Event a -> Time
wholeBegin = begin . wholeOrActive

-- | Get the offset of an event's 'whole'
wholeEnd :: Event a -> Time
wholeEnd = end . wholeOrActive

-- | Get the onset of an event's 'whole'
eventActiveBegin :: Event a -> Time
eventActiveBegin = begin . active

-- | Get the offset of an event's 'active'
eventActiveEnd :: Event a -> Time
eventActiveEnd = end . active

-- | Get the timearc of an event's 'active'
eventActive :: Event a -> Arc
eventActive = active

eventValue :: Event a -> a
eventValue = value

eventHasOnset :: Event a -> Bool
eventHasOnset e | isAnalog e = False
                | otherwise = begin (fromJust $ whole e) == begin (active e)

withArc :: (Arc -> Arc) -> Event a -> Event a
withArc f e = e {active = f $ active e,
                 whole  = f <$> whole e
                }

 -- Resolves higher order VState values to plain values, by passing through (and changing) state
resolveState :: ValueMap -> [Event ValueMap] -> (ValueMap, [Event ValueMap])
resolveState sMap [] = (sMap, [])
resolveState sMap (e:es) = (sMap'', (e {value = v'}):es')
  where f sm (VState v) = v sm
        f sm v = (sm, v)
        (sMap', v') | eventHasOnset e = Map.mapAccum f sMap (value e)    -- pass state through VState functions
                    | otherwise = (sMap, Map.filter notVState $ value e) -- filter out VState values without onsets
        (sMap'', es') = resolveState sMap' es
        notVState (VState _) = False
        notVState _ = True
