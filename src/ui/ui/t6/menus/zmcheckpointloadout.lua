-- Starting loadout lobby options: 0-2 random starting weapons and 0-1 random
-- starting perk, plus the starting points and the opening (power/doors) rows.
-- The weapon pool is chosen in GSC from each map's own weapon list, so the lobby
-- only stores how many to give.
local C = CoD.ZMCheckpointMenu

C.LoadoutWeaponMax = 4
C.LoadoutPerkMax = 1
C.LoadoutWorldMax = 3
C.LoadoutPointValues = { 0, 5000, 10000, 25000, 50000, 100000, 250000, 500000, 1000000 }

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

-- The points row only offers fixed amounts; anything else becomes DEFAULT.
local function normalizePoints()
	local value = tonumber( C.DvarString( "zmcp_start_points" ) )
	if value ~= nil and value == value then
		value = math.floor( value )
		for _, allowed in ipairs( C.LoadoutPointValues ) do
			if value == allowed then
				if tostring( value ) ~= C.DvarString( "zmcp_start_points" ) then Engine.SetDvar( "zmcp_start_points", value ) end
				return
			end
		end
	end
	Engine.SetDvar( "zmcp_start_points", 0 )
end

-- Clamps stored values so the rows and GSC always agree (older versions allowed
-- up to four random perks and named weapon rows; a stored perk count of 2 or
-- more becomes the single random perk).
C.RefreshLoadoutOptions = function ()
	normalize( "zmcp_start_weapons", C.LoadoutWeaponMax )
	normalize( "zmcp_start_perks", C.LoadoutPerkMax )
	normalize( "zmcp_start_world", C.LoadoutWorldMax )
	normalizePoints()
end
