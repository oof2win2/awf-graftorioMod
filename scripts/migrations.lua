-- sourced from flib
local lib = {}

local version_pattern = "%d+"
local version_format = "%02d"
lib.format_version = function(version, format)
	if version then
	  format = format or version_format
	  local tbl = {}
	  for v in string.gmatch(version, version_pattern) do
		tbl[#tbl+1] = string.format(format, v)
	  end
	  if next(tbl) then
		return table.concat(tbl, ".")
	  end
	end
	return nil
  end

--- Check if current_version is newer than old_version.
lib.is_newer_version = function(old_version, current_version)
	local v1 = lib.format_version(old_version)
	local v2 = lib.format_version(current_version)
	if v1 and v2 then
	  if v2 > v1 then
		return true
	  end
	  return false
	end
	return nil
  end
return lib