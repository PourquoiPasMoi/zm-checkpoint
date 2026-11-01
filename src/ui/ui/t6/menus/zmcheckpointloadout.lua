-- Starting loadout lobby options: 0-2 random starting weapons and 0-1 random
-- starting perk. The weapon pool is chosen in GSC from each map's own weapon
-- list, so the lobby only stores how many to give.
local C = CoD.ZMCheckpointMenu

C.LoadoutWeaponMax = 2
C.LoadoutPerkMax = 1

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

-- Clamps stored values so the rows and GSC always agree (older versions allowed
-- up to four random perks and named weapon rows; a stored perk count of 2 or
-- more becomes the single random perk).
C.RefreshLoadoutOptions = function ()
	normalize( "zmcp_start_weapons", C.LoadoutWeaponMax )
	normalize( "zmcp_start_perks", C.LoadoutPerkMax )
end
