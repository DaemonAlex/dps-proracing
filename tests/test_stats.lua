TEST('MergeBestLap records only faster laps', function()
  RESET_STUB(); Config = { Stats = { enabled = true, showAfterRace = false } }; Bridge = { GetPlayerIdentifier = function() return 'C1' end }
  dofile('server/stats.lua')
  local bl, rec = Stats.MergeBestLap({ Short_Track = 50000 }, 'Short_Track', 48000); TRUTHY(rec); EQ(bl.Short_Track, 48000)
  bl, rec = Stats.MergeBestLap(bl, 'Short_Track', 49000); FALSY(rec); EQ(bl.Short_Track, 48000)
  bl, rec = Stats.MergeBestLap(bl, 'Long_Track', 0); FALSY(rec)
end)

-- Runs Migrate with only the named table present and returns the RENAME query, if any.
local function migrateWith(present)
  RESET_STUB(); Config = { Stats = { enabled = true } }; Bridge = {}
  local orig = MySQL.scalar.await
  MySQL.scalar.await = function(sql, params)
    STUB.queries[#STUB.queries+1] = { sql = sql, params = params }
    return (params and params[1] == present) and 1 or 0
  end
  dofile('server/stats.lua')
  MySQL.scalar.await = orig
  for _, q in ipairs(STUB.queries) do if q.sql:find('RENAME TABLE') then return q.sql end end
end

TEST('Migrate renames the old table when only it exists', function()
  local sql = migrateWith('speedway_stats')
  TRUTHY(sql); TRUTHY(sql:find('speedway_stats TO dps_proracing_stats', 1, true))
end)

TEST('Migrate carries stats over from the dps-roxwoodracing name', function()
  local sql = migrateWith('dps_roxwoodracing_stats')
  TRUTHY(sql); TRUTHY(sql:find('dps_roxwoodracing_stats TO dps_proracing_stats', 1, true))
end)

TEST('Migrate leaves an existing table alone', function()
  FALSY(migrateWith('dps_proracing_stats'))
end)

TEST('Save upserts with mode counters', function()
  RESET_STUB(); Config = { Stats = { enabled = true, showAfterRace = false } }; Bridge = { GetPlayerIdentifier = function() return 'C1' end }
  STUB.scalar = 0
  dofile('server/stats.lua')
  STUB.row = { total_races = 2, wins = 1, best_laps = '{"Short_Track":50000}' }
  Stats.Save(7, 1, 'Short_Track', 48000, 7900, 'open')
  local q = STUB.queries[#STUB.queries]
  TRUTHY(q.sql:find('open_wins'), 'open_wins column in upsert')
  EQ(q.params[1], 'C1')
end)
