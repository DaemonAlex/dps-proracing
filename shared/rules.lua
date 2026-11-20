-- What the server accepts as real racing. Pure maths, no game calls, so the tests can load it.
RaceRules = {}

local function dist(a, b)
  local dx, dy, dz = a.x - b.x, a.y - b.y, (a.z or 0) - (b.z or 0)
  return math.sqrt(dx * dx + dy * dy + dz * dz)
end
RaceRules.Dist = dist

--- Length of one lap, measured checkpoint to checkpoint and back to the first.
function RaceRules.TrackLength(cps)
  if type(cps) ~= 'table' or #cps < 2 then return 0 end
  local sum = 0
  for i = 1, #cps do sum = sum + dist(cps[i], cps[i % #cps + 1]) end
  return sum
end

--- Is this position at the checkpoint? The radius is wide: the server sees a fast car a little late.
function RaceRules.AtCheckpoint(pos, cp, radius)
  if not pos or not cp then return false end
  return dist(pos, cp) <= (radius or 75.0)
end

--- Shortest time a car could need between two checkpoints, in ms.
function RaceRules.MinLegMs(from, to, maxSpeed)
  if not from or not to then return 0 end
  return math.floor(dist(from, to) / (maxSpeed or 105.0) * 1000)
end

--- Shortest lap the server believes, in ms: the track's own floor, or the lap length at top speed.
function RaceRules.MinLapMs(cps, rules, track)
  rules = rules or {}
  local bySpeed = math.floor(RaceRules.TrackLength(cps) / (rules.maxSpeed or 105.0) * 1000)
  local floor = ((rules.minLapSeconds or {})[track] or 0) * 1000
  return math.max(bySpeed, floor)
end

--- Part of the purse a race of this many laps pays (a one-lap race is not a full race).
function RaceRules.PurseScale(laps, fullLaps)
  if not fullLaps or fullLaps <= 0 then return 1 end
  return math.min(1, math.max(0, (laps or 0)) / fullLaps)
end

--- Trim one racer's purse parts so the day's total stays under the cap. Pool money is their own
--- buy-ins and is never capped. Returns the purse actually allowed.
function RaceRules.CapPurse(parts, earnedToday, cap)
  local want = (parts.position or 0) + (parts.participation or 0) + (parts.bestLap or 0)
  if not cap or cap <= 0 then return want end
  local room = math.max(0, cap - (earnedToday or 0))
  if want <= room then return want end
  local left = room
  for _, key in ipairs({ 'participation', 'position', 'bestLap' }) do
    local take = math.min(parts[key] or 0, left)
    parts[key] = take
    left = left - take
  end
  parts.capped = true
  return room
end
