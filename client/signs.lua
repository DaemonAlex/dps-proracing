-- Placed LED signs (one per track besides the Roxwood ymap sign). Each is a local frozen
-- object created when a player comes within range; the leaderboard texture replacement
-- applies to the model, so every placed sign shows this client's board.
local SIGN_MODEL = 'amir_speedway_led'
local objects, points, rows = {}, {}, {}
local function log(msg) print('[dps-proracing] signs: ' .. msg) end

local function clear()
  for _, p in ipairs(points) do p:remove() end
  for _, o in pairs(objects) do if DoesEntityExist(o) then DeleteObject(o) end end
  points, objects = {}, {}
end

local function place(row)
  local hash = joaat(SIGN_MODEL)
  if not IsModelValid(hash) then log(('model %s not valid (ytyp not loaded?)'):format(SIGN_MODEL)) return end
  RequestModel(hash)
  local deadline = GetGameTimer() + 5000
  while not HasModelLoaded(hash) and GetGameTimer() < deadline do Wait(50) end
  if not HasModelLoaded(hash) then log('model did not load in 5 s') return end
  -- The stored point is where the director stood (ground level). The model's origin is not
  -- at its base, so lift it by the model's lower extent and drop it on the ground from there.
  local mn, mx = GetModelDimensions(hash)
  local stand = (Config.Leaderboard and Config.Leaderboard.signStand) or {}
  local heading = (row.h + (stand.flip and 180.0 or 0.0)) % 360.0

  -- The stand. `model` is one prop or a list (the first one the game has is used). With
  -- `auto`, the prop is stood on the ground, stacked `stack` times, and the panel is set on
  -- top, all from the prop's own size. Without `auto`, `height` and `zOffset` are used as given
  -- (the old raceway-tower setup).
  local standHash, standTop
  local wanted = stand.model
  if wanted and type(wanted) ~= 'table' then wanted = { wanted } end
  for _, m in ipairs(wanted or {}) do
    local sh = type(m) == 'number' and m or joaat(m)
    if IsModelValid(sh) then
      RequestModel(sh); local dl = GetGameTimer() + 5000
      while not HasModelLoaded(sh) and GetGameTimer() < dl do Wait(50) end
      if HasModelLoaded(sh) then standHash = sh break end
    end
  end
  if wanted and not standHash then log('no stand model is valid: the panel goes on the ground') end

  if standHash then
    local smn, smx = GetModelDimensions(standHash)
    local pieces = stand.auto and math.max(1, math.floor(tonumber(stand.stack) or 1)) or 1
    local pieceH = smx.z - smn.z
    for i = 1, pieces do
      local sz = stand.auto and (row.z - smn.z + (i - 1) * pieceH) or (row.z + (stand.zOffset or 0.0))
      local so = CreateObjectNoOffset(standHash, row.x, row.y, sz, false, false, false)
      if so ~= 0 then
        SetEntityHeading(so, heading); FreezeEntityPosition(so, true); SetEntityLodDist(so, 3000)
        objects[row.track .. '#stand' .. i] = so
      end
    end
    if stand.auto then standTop = row.z + pieces * pieceH end
    log(('stand: %d piece(s), each %.2f m tall'):format(pieces, pieceH))
    SetModelAsNoLongerNeeded(standHash)
  end

  -- With an auto stand: the panel base on the stand's top. With a fixed stand: the panel origin
  -- `height` above the director's feet. With no stand: the panel base on the ground.
  local lift = stand.height or 0.0
  local z = standTop and (standTop - mn.z) or (standHash and (row.z + lift)) or (row.z - mn.z)
  local obj = CreateObjectNoOffset(hash, row.x, row.y, z, false, false, false)
  if obj == 0 then log('object create refused') return end
  log(('sign for %s created at %.1f %.1f %.1f (panel z extent %.2f..%.2f, heading %.0f)'):format(row.track, row.x, row.y, z, mn.z, mx.z, heading))
  SetEntityHeading(obj, heading)
  FreezeEntityPosition(obj, true)
  SetEntityLodDist(obj, (Config.Leaderboard and Config.Leaderboard.signLodDistance) or 3000)
  SetModelAsNoLongerNeeded(hash)
  objects[row.track] = obj
  TriggerEvent('dps-proracing:sign:nearby')      -- leaderboard re-applies the texture
end

local function arm()
  clear()
  rows = lib.callback.await('dps-proracing:sign:list', false)
  if type(rows) ~= 'table' then log('no rows from server') return end
  log(('%d sign(s) stored'):format(#rows))
  for _, row in ipairs(rows) do
    points[#points + 1] = lib.points.new({
      coords = vector3(row.x, row.y, row.z),
      distance = (Config.Leaderboard and Config.Leaderboard.signRadius) or 300.0,
      onEnter = function()
        log(('near the %s sign'):format(row.track))
        if not objects[row.track] or not DoesEntityExist(objects[row.track]) then CreateThread(function() place(row) end) end
      end,
      onExit = function()
        for k, o in pairs(objects) do
          if k == row.track or k:sub(1, #row.track + 6) == row.track .. '#stand' then
            if DoesEntityExist(o) then DeleteObject(o) end
            objects[k] = nil
          end
        end
      end,
    })
  end
end

CreateThread(function()
  while not NetworkIsSessionStarted() do Wait(500) end
  Wait(2500)
  arm()
end)

RegisterNetEvent('dps-proracing:sign:changed', function() arm() end)
RegisterNetEvent('dps-proracing:sign:result', function(ok, msg)
  Notify(Config.Job.label, msg, ok and 'success' or 'error', 7000)
end)

-- /placesign: put the sign where you stand, facing your heading, for the track you are at.
-- /placesign clear removes this track's sign.
RegisterCommand('placesign', function(_, args)
  if not Bridge.HasJob(Config.Job.name, Config.Job.grades.director) then
    Notify(Config.Job.label, Locale('staff_only'), 'error') return
  end
  local track = PracticeCurrentTrack and PracticeCurrentTrack()
  if not track then Notify(Config.Job.label, Locale('sign_no_track'), 'error') return end
  if args[1] == 'clear' then TriggerServerEvent('dps-proracing:sign:clear', track) return end
  local ped = PlayerPedId()
  local c = GetEntityCoords(ped)
  -- Store the ground under the director, not the ped root (which sits about a metre up):
  -- place() treats the stored z as ground level for the stand.
  local found, groundZ = GetGroundZFor_3dCoord(c.x, c.y, c.z + 0.5, false)
  local z = found and groundZ or (c.z - 1.0)
  TriggerServerEvent('dps-proracing:sign:place', track, c.x, c.y, z, GetEntityHeading(ped))
end, false)

RegisterCommand('signstatus', function()
  local me = GetEntityCoords(PlayerPedId())
  log(('%d row(s); current track %s'):format(#rows, tostring(PracticeCurrentTrack and PracticeCurrentTrack())))
  for _, r in ipairs(rows) do
    local o = objects[r.track]
    log(('%s at %.1f %.1f %.1f: %.0f m away, object %s'):format(r.track, r.x, r.y, r.z, #(me - vector3(r.x, r.y, r.z)), (o and DoesEntityExist(o)) and 'exists' or 'none'))
  end
end, false)

AddEventHandler('onResourceStop', function(res)
  if res == GetCurrentResourceName() then clear() end
end)
