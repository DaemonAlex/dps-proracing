-- Carries a table over from the name it had while the script was dps-roxwoodracing (until
-- 12 November 2026). Called at the top of each module's table setup, before CREATE TABLE.
Migrate = {}

local function exists(name)
  local n = MySQL.scalar.await('SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = ?', { name })
  return (tonumber(n) or 0) > 0
end

---@param new string the table's name now, for example 'dps_proracing_lines'
function Migrate.Carry(new)
  local old = new:gsub('^dps_proracing_', 'dps_roxwoodracing_')
  if old == new or exists(new) or not exists(old) then return false end
  MySQL.query.await(('RENAME TABLE %s TO %s'):format(old, new))
  print(('[dps-proracing] renamed table %s -> %s'):format(old, new))
  return true
end
