-- Pit boxes marked in game. A Race Director stands in a pit box, facing the way the crew
-- should face, and runs /pitbox. The server reads where they stand and stores it; every
-- client then shows a pit crew there. Nothing is typed in by hand.
--   /pitbox [radius]   save the spot you stand on (radius 3 to 15, default 6)
--   /pitbox del        remove the saved box nearest to you, within 15 m
--   /pitbox list       how many are saved, and the nearest one
local TABLE = 'dps_proracing_pitboxes'
PitBoxes = PitBoxes or {}

local written = {}   -- boxes written in config/pit.lua stay as they are
for i, z in ipairs(Config.PitCrewZones or {}) do written[i] = z end
local stored = {}    -- { id, x, y, z, h, r }

local function publish()
  local zones = {}
  for i, z in ipairs(written) do zones[i] = z end
  for _, b in ipairs(stored) do
    zones[#zones + 1] = { coords = vector3(b.x, b.y, b.z), heading = b.h, radius = b.r }
  end
  Config.PitCrewZones = zones
  GlobalState.dpsPitBoxes = stored
end

local function load()
  local rows = MySQL.query.await(('SELECT id, x, y, z, h, radius FROM %s ORDER BY id'):format(TABLE)) or {}
  stored = {}
  for _, r in ipairs(rows) do
    stored[#stored + 1] = { id = r.id, x = r.x + 0.0, y = r.y + 0.0, z = r.z + 0.0, h = r.h + 0.0, r = r.radius + 0.0 }
  end
  publish()
end

function PitBoxes.Init()
  MySQL.query.await(([[
    CREATE TABLE IF NOT EXISTS %s (
      id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
      x FLOAT NOT NULL, y FLOAT NOT NULL, z FLOAT NOT NULL, h FLOAT NOT NULL,
      radius FLOAT NOT NULL DEFAULT 6,
      citizenid VARCHAR(60),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  ]]):format(TABLE))
  load()
end

local function say(src, ok, msg)
  if src == 0 then print('[dps-proracing] ' .. msg) return end
  TriggerClientEvent('dps-proracing:pitbox:result', src, ok, msg)
end

local function nearest(pos, within)
  local best, bestDist
  for i, b in ipairs(stored) do
    local d = #(pos - vector3(b.x, b.y, b.z))
    if (not within or d <= within) and (not bestDist or d < bestDist) then best, bestDist = i, d end
  end
  return best, bestDist
end

RegisterCommand('pitbox', function(src, args)
  if src == 0 then return print('[dps-proracing] /pitbox is used in game, standing in the pit box') end
  if not Staff.Can(src, 'director') then return say(src, false, Locale('staff_only')) end

  local ped = GetPlayerPed(src)
  if not ped or ped == 0 then return end
  local pos = GetEntityCoords(ped)
  local what = (args[1] or ''):lower()

  if what == 'list' then
    local i, d = nearest(pos)
    return say(src, true, i and Locale('pitbox_list', #stored, math.floor(d + 0.5)) or Locale('pitbox_none'))
  end

  if what == 'del' then
    local i, d = nearest(pos, 15.0)
    if not i then return say(src, false, Locale('pitbox_none_near')) end
    MySQL.query.await(('DELETE FROM %s WHERE id = ?'):format(TABLE), { stored[i].id })
    load()
    print(('[dps-proracing] pit box removed (%.0f m away, %d left)'):format(d, #stored))
    return say(src, true, Locale('pitbox_removed', #stored))
  end

  local radius = tonumber(args[1]) or 6.0
  if radius < 3.0 or radius > 15.0 then return say(src, false, Locale('pitbox_radius')) end

  -- the box is kept at foot height: the ped's position is its middle
  MySQL.insert.await(('INSERT INTO %s (x, y, z, h, radius, citizenid) VALUES (?, ?, ?, ?, ?, ?)'):format(TABLE),
    { pos.x, pos.y, pos.z - 1.0, GetEntityHeading(ped), radius, Bridge.GetPlayerIdentifier(src) })
  load()
  print(('[dps-proracing] pit box added at %.1f %.1f %.1f (%d stored)'):format(pos.x, pos.y, pos.z, #stored))
  say(src, true, Locale('pitbox_added', #stored))
end, false)

CreateThread(function()
  PitBoxes.Init()
  print(('[dps-proracing] pit boxes: %d stored'):format(#stored))
end)
