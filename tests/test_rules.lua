dofile('shared/rules.lua')

local track = {
  { x = 1121.55, y = 2158.48, z = 51.62 }, { x = 1010.46, y = 2206.57, z = 48.44 }, { x = 913.99, y = 2310.34, z = 50.27 },
  { x = 900.85, y = 2460.02, z = 51.64 }, { x = 1029.14, y = 2460.91, z = 51.24 }, { x = 1151.72, y = 2415.19, z = 52.39 },
}
local rules = { checkpointRadius = 75.0, maxSpeed = 105.0, minLapSeconds = { Grand_Senora = 15 } }

TEST('a checkpoint counts only when the racer is there', function()
  TRUTHY(RaceRules.AtCheckpoint({ x = 1125, y = 2160, z = 51 }, track[1], 75.0))
  FALSY(RaceRules.AtCheckpoint({ x = 1125, y = 2160, z = 51 }, track[4], 75.0), 'the far side of the track')
  FALSY(RaceRules.AtCheckpoint(nil, track[1], 75.0))
end)

TEST('nothing gets between two checkpoints faster than top speed', function()
  local ms = RaceRules.MinLegMs(track[1], track[2], 105.0)
  TRUTHY(ms > 1000 and ms < 1300, 'about 121 m at 105 m/s, got ' .. ms)
  EQ(RaceRules.MinLegMs(nil, track[2], 105.0), 0)
end)

TEST('the shortest lap is the track floor, or the lap length at top speed', function()
  local len = RaceRules.TrackLength(track)
  TRUTHY(len > 850 and len < 1000, 'lap length ' .. len)
  EQ(RaceRules.MinLapMs(track, rules, 'Grand_Senora'), 15000)
  local bySpeed = RaceRules.MinLapMs(track, rules, 'Unknown_Track')
  TRUTHY(bySpeed > 8000 and bySpeed < 9500, 'no floor set: ' .. bySpeed)
end)

TEST('a short race pays part of the purse', function()
  EQ(RaceRules.PurseScale(3, 3), 1); EQ(RaceRules.PurseScale(10, 3), 1)
  TRUTHY(math.abs(RaceRules.PurseScale(1, 3) - 1 / 3) < 1e-9)
  EQ(RaceRules.PurseScale(1, nil), 1, 'no rule set: full purse')
end)

TEST('the daily cap trims the purse and never the pool', function()
  local p = { position = 5000, participation = 500, bestLap = 1000, pool = 1200 }
  EQ(RaceRules.CapPurse(p, 0, 20000), 6500); FALSY(p.capped)
  p = { position = 5000, participation = 500, bestLap = 1000, pool = 1200 }
  EQ(RaceRules.CapPurse(p, 18000, 20000), 2000)
  EQ(p.participation, 500); EQ(p.position, 1500); EQ(p.bestLap, 0); EQ(p.pool, 1200); TRUTHY(p.capped)
  p = { position = 5000, participation = 500, bestLap = 0, pool = 0 }
  EQ(RaceRules.CapPurse(p, 25000, 20000), 0); EQ(p.position, 0)
  p = { position = 5000, participation = 500, bestLap = 0, pool = 0 }
  EQ(RaceRules.CapPurse(p, 99999, nil), 5500, 'no cap set')
end)

TEST('Settle: a one-lap race with the daily cap pays a third, then stops at the cap', function()
  RESET_STUB()
  Config = { Job = { name = 'proracing', label = 'Raceway' },
    Economy = { purseSource = 'society', entryFee = { enabled = true, amount = 1000 }, poolSplit = { [1] = 60, [2] = 30, [3] = 10 },
      payouts = { [1] = 6000, [2] = 3000, [3] = 1500 }, participationReward = 600, bestLapBonus = 900, moneyType = 'cash',
      minPlayersForPurse = 3, fullPurseLaps = 3, dailyPurseCap = 2500 } }
  local cash, kvp, society = { [1] = 0, [2] = 0, [3] = 0 }, {}, 100000
  Bridge = { Framework = 'qbx', GetPlayerIdentifier = function(pid) return 'CID' .. pid end, GetPlayerName = function(pid) return 'P' .. pid end,
    AddMoney = function(pid, _, amt) cash[pid] = cash[pid] + amt return true end }
  Banking = { GetBalance = function() return society end, Withdraw = function(_, amt) society = society - amt return true end,
    Deposit = function() return true end, LogOnly = function() end, EnsureAccount = function() return true end }
  Garages = { GiveVehicle = function() return true end }
  GetResourceKvpInt = function(k) return kvp[k] or 0 end
  SetResourceKvpInt = function(k, v) kvp[k] = v end
  dofile('shared/payouts.lua'); dofile('server/rewards.lua')

  local res = { { id = 1 }, { id = 2 }, { id = 3 } }
  Rewards.Settle({ players = { 1, 2, 3 }, prizePool = 0, name = 'L', laps = 1 }, res, 1)
  EQ(cash[1], 2500, 'a third is 2000 + 200 + 300 = 2500, exactly the cap')
  EQ(cash[2], 1000 + 200); EQ(cash[3], 500 + 200)
  Rewards.Settle({ players = { 1, 2, 3 }, prizePool = 0, name = 'L', laps = 1 }, res, 1)
  EQ(cash[1], 2500, 'the cap is reached: no more purse today')
  EQ(Rewards.PurseToday('CID1'), 2500)
  Rewards.Settle({ players = { 1, 2 }, prizePool = 1000, name = 'L', laps = 3 }, { { id = 2 }, { id = 3 } }, 2)
  EQ(cash[2], 1200 + 1200 + 600, 'two racers: pool money only')
  GetResourceKvpInt, SetResourceKvpInt = nil, nil
end)
