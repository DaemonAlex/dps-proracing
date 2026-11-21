Config = Config or {}


-- Pit boxes are marked in game: a Race Director stands in the box and runs /pitbox
-- (see server/pitboxes.lua). Boxes can also be written here; each one is:
--   { coords = vector3(x, y, z), heading = 180.0, radius = 6.0 },
Config.PitCrewZones = {
}


-- Pit-crew settings
-- Ped models for the crew. Each crew member picks one at random and gets a random
-- outfit variation, so the boxes are not staffed by identical clones. Models that are
-- not present on the client are skipped; if none load, s_m_y_xmech_02 is used.
Config.PitCrewModels = {
    'ig_mechanic_ped_1',   -- addon (ghostic) mechanic, present on DPS
    'ig_mechanic_ped_2',   -- addon (ghostic) mechanic, present on DPS
    's_m_y_xmech_01',      -- vanilla mechanic, coveralls
    's_m_y_xmech_02',      -- vanilla mechanic, coveralls
    's_m_m_autoshop_01',   -- vanilla LS Customs mechanic
    's_m_m_autoshop_02',   -- vanilla LS Customs mechanic
    's_m_y_airworker',     -- vanilla ground crew, hi-vis + ear defenders
    'a_m_y_motox_01',      -- vanilla race suit
    'a_m_y_motox_02',      -- vanilla race suit
    's_m_y_construct_01',  -- the original crew look, kept as one of ten so a box gets one or two
}

Config.PitCrewIdleOffsets = {
    vector3(-2.0,  0.0,  0.0),  -- two idle spots (left/right)
    vector3( 2.0,  0.0,  0.0),
}

Config.PitCrewCrewOffsets = {
    vector3( 0.0, -2.0,  0.0),  -- refuel spot (rear)
    vector3( 0.0,  2.0,  0.0),  -- hood spot (front)
    vector3( 2.0,  0.0,  0.0),  -- jack spot (side)
}


-- Pit Stop Timing (adjust for realism vs speed)
Config.PitStopTiming = {
    crewWalkSpeed    = 2.0,     -- 1.0 = walk, 2.0 = jog, 3.0+ = run
    refuelSteps      = 15,      -- Number of fuel increments (more = smoother fill)
    refuelStepMs     = 200,     -- Milliseconds per refuel step (total = steps * ms)
    repairDuration   = 3000,    -- Milliseconds for repair animation
    approachTimeout  = 8000,    -- Max ms to wait for crew to approach vehicle
    returnTimeout    = 15000,   -- Max ms to wait for crew to return to positions
}


-- Tire change: the animation the crew member at the wheel plays during a stop.
-- The file ships with this script (stream/wymianakola@animation.ycd). If it does not load,
-- the crew member plays the old general mechanic loop instead.
Config.PitCrewTireAnim = { dict = 'wymianakola@animation', clip = 'wymiana_clip' }


-- What the crew does between stops. Each crew member picks something from this list, does
-- it for a while, then picks something else. Most of the time they walk to another spot
-- in the box first. A crew member does not repeat any of their last `noRepeat` picks, and
-- two crew members in one box do not do the same thing at the same time.
-- The names are GTA's own "scenarios". Add or remove lines freely.
Config.PitCrewLife = {
    enabled     = true,
    walkChance  = 65,          -- % of the time they walk to a new spot before the next thing
    walkSide    = 3.5,         -- how far along the wall they wander from their own spot (m)
    walkDepth   = 1.5,         -- how far towards / away from the wall (m)
    seconds     = { 14, 40 },  -- how long one thing lasts (shortest, longest)
    noRepeat    = 5,
    activities  = {
        'WORLD_HUMAN_STAND_IMPATIENT',      -- waiting, shifting weight
        'WORLD_HUMAN_CLIPBOARD',            -- checking the sheet
        'WORLD_HUMAN_STAND_MOBILE',         -- on the phone
        'WORLD_HUMAN_AA_COFFEE',            -- coffee
        'WORLD_HUMAN_DRINKING',             -- a drink
        'WORLD_HUMAN_AA_SMOKE',             -- smoking
        'WORLD_HUMAN_HANG_OUT_STREET',      -- standing around, talking
        'WORLD_HUMAN_LEANING',              -- leaning
        'WORLD_HUMAN_GUARD_STAND',          -- arms folded, watching the lane
        'WORLD_HUMAN_BINOCULARS',           -- watching the track
        'WORLD_HUMAN_CAR_PARK_ATTENDANT',   -- waving a car in
        'WORLD_HUMAN_WELDING',              -- welding
        'WORLD_HUMAN_HAMMERING',            -- hammering
        'WORLD_HUMAN_JANITOR',              -- sweeping the box
        'WORLD_HUMAN_MAID_CLEAN',           -- wiping down
        'CODE_HUMAN_MEDIC_KNEEL',           -- kneeling, looking at something low
        'CODE_HUMAN_MEDIC_TEND_TO_DEAD',    -- kneeling, working with both hands
        'WORLD_HUMAN_COP_IDLES',            -- hands on belt
    },
}


-- Pit Crew Idle Animations (randomly selected for variety)
Config.PitCrewIdleAnims = {
    "WORLD_HUMAN_STAND_IMPATIENT",
    "WORLD_HUMAN_AA_SMOKE",
    "WORLD_HUMAN_CLIPBOARD",
    "WORLD_HUMAN_DRINKING",
}
