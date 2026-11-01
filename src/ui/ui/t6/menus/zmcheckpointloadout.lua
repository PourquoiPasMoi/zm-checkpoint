-- Starting loadout lobby options: 0-2 random starting weapons and 0-1 random
-- starting perk, plus the starting points and the opening (power/doors) rows.
-- The weapon pool is chosen in GSC from each map's own weapon list, so the lobby
-- only stores how many to give.
local C = CoD.ZMCheckpointMenu

C.LoadoutWeaponMax = 4
C.LoadoutPerkMax = 1
C.LoadoutWorldMax = 3
C.HealthCapMax = 255
C.AutosaveMax = 8

local function normalize( dvar, maximum )
	local value = tonumber( C.DvarString( dvar ) )
	if value == nil or value ~= value then
		Engine.SetDvar( dvar, 0 )
		return
	end
	value = math.floor( value )
	if value < 0 then value = 0 end
	if value > maximum then value = maximum end
	if tostring( value ) ~= C.DvarString( dvar ) then Engine.SetDvar( dvar, value ) end
end

-- Starting points can be any whole number from 1 to 1,000,000 (typed in the
-- lobby); anything else becomes 0, which means DEFAULT.
C.PointsMax = 1000000
local function normalizePoints()
	local value = tonumber( C.DvarString( "zmcp_start_points" ) )
	if value == nil or value ~= value then
		Engine.SetDvar( "zmcp_start_points", 0 )
		return
	end
	value = math.floor( value )
	if value < 0 then value = 0 end
	if value > C.PointsMax then value = C.PointsMax end
	if tostring( value ) ~= C.DvarString( "zmcp_start_points" ) then Engine.SetDvar( "zmcp_start_points", value ) end
end

-- Clamps stored values so the rows and GSC always agree (older versions allowed
-- up to four random perks and named weapon rows; a stored perk count of 2 or
-- more becomes the single random perk).
C.RefreshLoadoutOptions = function ()
	normalize( "zmcp_start_weapons", C.LoadoutWeaponMax )
	normalize( "zmcp_start_perks", C.LoadoutPerkMax )
	normalize( "zmcp_start_world", C.LoadoutWorldMax )
	normalize( "zmcp_health_cap", C.HealthCapMax )
	normalize( "zmcp_autosave", C.AutosaveMax )
	normalizePoints()
end
