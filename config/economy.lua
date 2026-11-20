Config = Config or {}




--- PERSISTENT RACE STATS
Config.Stats = {
    enabled = true,
    showAfterRace = true,            -- Show personal stats summary after each race
}

Config.Job = {
  name   = 'proracing',
  label  = 'Grand Senora Raceway',
  grades = { marshal = 0, pitcrew = 1, director = 2, owner = 3 },
  -- Boss menu zone at the paddock office (next to the lobby ped)
  -- PROVISIONAL (DPS 2026-11-12): beside the lobby host. Set the real office spot after an in-game look.
  bossCoords = vector3(1137.3, 2264.2, 52.4),
}

Config.Economy = {
  purseSource = 'society',          -- 'society' (pay from the job account) | 'house' (mint, but log)
  entryFee    = { enabled = true, amount = 1000 },
  poolSplit   = { [1] = 60, [2] = 30, [3] = 10 },
  payouts     = { [1] = 5000, [2] = 3000, [3] = 1500 },
  participationReward = 500,
  bestLapBonus        = 1000,
  vehiclePrize        = nil,        -- e.g. 'sultan3'; nil = off
  prizeGarage         = 'Sandy South',   -- DPS 2026-11-12: the nearest garage to Grand Senora (was 'Roxwood Raceway', a garage that no longer exists)
  moneyType           = 'cash',     -- player side of every transaction
  minPlayersForPurse  = 3,          -- fewer racers than this: the buy-in pool only, no purse from the account
  fullPurseLaps       = 3,          -- a race this long pays the whole purse; a 1-lap race pays a third of it
  dailyPurseCap       = 20000,      -- most purse money one racer can take from the account in a day (pool money is not counted)
  lobbyCooldownSec    = 300,        -- a player can open a new lobby this often
  lobbyDistance       = 40.0,       -- a lobby is opened at the lobby host, within this many metres
  maxStaffSetting     = 1000000,    -- ceiling for any fee/purse value set from Raceway Control
}

--- WHAT COUNTS AS REAL RACING (checked by the server)
Config.RaceRules = {
  checkpointRadius = 75.0,          -- the car must be this close to a checkpoint for it to count
  maxSpeed         = 105.0,         -- metres per second (378 km/h): nothing gets from one checkpoint to the next faster
  minLapSeconds    = { Grand_Senora = 15 },  -- no lap faster than this is believed, per track
}
