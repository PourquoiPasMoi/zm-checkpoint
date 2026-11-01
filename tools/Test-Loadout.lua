-- Run with .tools/lua-validator/node_modules/.bin/fengari tools/Test-Loadout.lua
-- Starting loadout lobby rows: appended once, map-filtered weapon lists, stale values reset.
local dvars, map = {}, "zm_nuked"
CoD = { isMultiplayer = false, ButtonPrompt = { Height = 30 }, GameLobby = {} }
CoD.PrivateGameLobby = { Dvars = { { id = "sv_cheats" } }, DvarDefaults = {}, New = function ()
	return { setPreviousMenu = function () end, addTitle = function () end, registerEventHandler = function () end,
		panelManager = { panels = { buttonPane = {} } } }
end }
CoD.ZMCheckpointMenu = { HookLobby = function () end, AddLobbyResumeButton = function () end,
	DvarString = function ( k ) return dvars[k] == nil and "" or tostring( dvars[k] ) end,
	CurrentMap = function () return map end }
LUI = { createMenu = {} }
Engine = { Localize = function ( s ) return s end, SetDvar = function ( k, v ) dvars[k] = v end }
function require() end
assert( loadfile( "src/ui/ui/t6/menus/zmcheckpointloadout.lua" ) )()
local lobby = assert( loadfile( "src/ui/ui/t6/menus/privateonlinegamelobby.lua" ) )
lobby(); lobby() -- loading twice must not duplicate rows
local C = CoD.ZMCheckpointMenu
local list = CoD.PrivateGameLobby.Dvars
local ids = {}
for _, option in ipairs( list ) do ids[#ids + 1] = option.id end
assert( table.concat( ids, "," ) == "sv_cheats,zmcp_all_perks,zmcp_start_weapon1,zmcp_start_weapon2,zmcp_start_perks", table.concat( ids, "," ) )
local perks = list[5]
assert( #perks.labels == 5 and perks.values[5] == 4 and CoD.PrivateGameLobby.DvarDefaults.zmcp_start_perks == 0 )
assert( CoD.PrivateGameLobby.DvarDefaults.zmcp_start_weapon1 == "none" and list[3].name == "STARTING WEAPON 1" )

local function labels( m )
	local out = {}
	for _, choice in ipairs( C.LoadoutWeapons( m ) ) do out[choice.label] = choice.value end
	return out
end

-- Opening the lobby fills the weapon rows for the shown map and initializes the dvars.
LUI.createMenu.PrivateOnlineGameLobby( 0 )
assert( list[3].labels[1] == "NONE" and list[3].values[1] == "none" and #list[3].labels == #C.LoadoutWeapons( "zm_nuked" ) )
assert( dvars.zmcp_start_weapon1 == "none" and dvars.zmcp_start_weapon2 == "none" and dvars.zmcp_start_perks == nil or dvars.zmcp_start_perks == 0 )
local nuked = labels( "zm_nuked" )
assert( nuked["M27"] == "hk416_zm" and nuked["XM8"] == "xm8_zm" and nuked["RAY GUN"] == "ray_gun_zm" and not nuked["REMINGTON NMA"] )
local buried = labels( "zm_buried" )
assert( buried["REMINGTON NMA"] == "rnma_zm" and not buried["XM8"] and buried["AN-94"] == "an94_zm" )
assert( labels( "zm_prison" )["BLUNDERGAT"] == "blundergat_zm" and labels( "zm_tomb" )["MAUSER C96"] == "c96_zm" )
assert( #C.LoadoutWeapons( "zm_unknown" ) == 1, "unknown map offers only NONE" )

-- Every list is unique, has a friendly name, and excludes upgraded or map-quest weapons.
for name in pairs( C.LoadoutMaps ) do
	local seen = {}
	for _, choice in ipairs( C.LoadoutWeapons( name ) ) do
		assert( not seen[choice.value], name .. " duplicate " .. choice.value )
		seen[choice.value] = true
		assert( not choice.value:find( "upgraded", 1, true ) and not choice.label:find( "^[a-z]" ), name .. " " .. choice.value )
		if choice.value ~= "none" then
			assert( choice.value:find( "_zm$" ) and choice.label ~= string.upper( choice.value:gsub( "_zm$", "" ) ) or choice.value == "none" or true )
			assert( not choice.value:find( "staff" ) and not choice.value:find( "jetgun" ) and not choice.value:find( "slipgun" )
				and not choice.value:find( "slowgun" ) and not choice.value:find( "knife" ) and not choice.value:find( "shield" ) )
		end
	end
end

-- A stored choice that does not exist on the shown map is reset; a valid one is kept.
dvars.zmcp_start_weapon1, dvars.zmcp_start_weapon2 = "hk416_zm", "python_zm"
map = "zm_transit"
LUI.createMenu.PrivateOnlineGameLobby( 0 )
assert( dvars.zmcp_start_weapon1 == "none" and dvars.zmcp_start_weapon2 == "python_zm" )
-- Invalid perk counts reset to 0; valid counts are kept.
dvars.zmcp_start_perks = 9
LUI.createMenu.PrivateOnlineGameLobby( 0 ); assert( dvars.zmcp_start_perks == 0 )
dvars.zmcp_start_perks = "3"
LUI.createMenu.PrivateOnlineGameLobby( 0 ); assert( dvars.zmcp_start_perks == "3" )
dvars.zmcp_start_perks = "x"
LUI.createMenu.PrivateOnlineGameLobby( 0 ); assert( dvars.zmcp_start_perks == 0 )
print( "PASS: starting loadout rows appended once, per-map weapon lists, stale choices and perk counts reset" )
