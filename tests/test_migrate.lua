-- Runs Migrate.Carry with only the named tables present; returns the RENAME sql, if any.
local function carry(new, present)
  RESET_STUB()
  local orig, keep = MySQL.scalar.await, Migrate
  MySQL.scalar.await = function(sql, params) return present[params[1]] and 1 or 0 end
  dofile('server/migrate.lua')
  Migrate.Carry(new)
  MySQL.scalar.await = orig; Migrate = keep
  for _, q in ipairs(STUB.queries) do if q.sql:find('RENAME TABLE') then return q.sql end end
end

TEST('Carry renames a table left from the dps-roxwoodracing name', function()
  local sql = carry('dps_proracing_lines', { dps_roxwoodracing_lines = true })
  TRUTHY(sql); TRUTHY(sql:find('dps_roxwoodracing_lines TO dps_proracing_lines', 1, true))
end)

TEST('Carry leaves things alone when the new table exists or there is no old one', function()
  FALSY(carry('dps_proracing_lines', { dps_roxwoodracing_lines = true, dps_proracing_lines = true }))
  FALSY(carry('dps_proracing_signs', {}))
end)
