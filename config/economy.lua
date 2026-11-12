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
  minPlayersForPurse  = 2,          -- solo races pay the buy-in pool only (no purse farming)
  maxStaffSetting     = 1000000,    -- ceiling for any fee/purse value set from Raceway Control
}
