-- Run with .tools/lua-validator/node_modules/.bin/fengari tools/Test-Loadout.lua
-- Starting loadout rows: random weapon count (0-2) and one random perk (0-1).
local dvars = {}
CoD = { isMultiplayer = false, ButtonPrompt = { Height = 30 }, GameLobby = {} }
CoD.PrivateGameLobby = { Dvars = { { id = "sv_cheats" } }, DvarDefaults = {}, New = function ()
	return { setPreviousMenu = function () end, addTitle = function () end, registerEventHandler = function () end,
		panelManager = { panels = { buttonPane = {} } } }
end }
CoD.ZMCheckpointMenu = { HookLobby = function () end, AddLobbyResumeButton = function () end,
	DvarString = function ( k ) return dvars[k] == nil and "" or tostring( dvars[k] ) end,
	CurrentMap = function () return "zm_nuked" end }
LUI = { createMenu = {} }
Engine = { Localize = function ( s ) return s end, SetDvar = function ( k, v ) dvars[k] = v end }
function require() end
assert( loadfile( "src/ui/ui/t6/menus/zmcheckpointloadout.lua" ) )()
local lobby = assert( loadfile( "src/ui/ui/t6/menus/privateonlinegamelobby.lua" ) )
lobby(); lobby() -- loading twice must not duplicate rows
local list = CoD.PrivateGameLobby.Dvars
local ids = {}
for _, option in ipairs( list ) do ids[#ids + 1] = option.id end
assert( table.concat( ids, "," ) == "sv_cheats,zmcp_all_perks,zmcp_start_weapons,zmcp_start_perks,zmcp_start_points,zmcp_start_world", table.concat( ids, "," ) )

-- Starting points: fixed amounts, DEFAULT first. Opening: power/doors bit values.
local points, world = list[5], list[6]
assert( points.name == "STARTING POINTS" and #points.labels == 9 and #points.values == 9 )
assert( points.labels[1] == "DEFAULT" and points.values[1] == 0 and points.values[9] == 1000000 and points.labels[9] == "1,000,000" )
assert( world.name == "OPENING" and #world.labels == 4 and world.labels[1] == "NORMAL" and world.labels[4] == "POWER + DOORS" )
assert( world.values[1] == 0 and world.values[2] == 1 and world.values[3] == 2 and world.values[4] == 3 )
assert( CoD.PrivateGameLobby.DvarDefaults.zmcp_start_points == 0 and CoD.PrivateGameLobby.DvarDefaults.zmcp_start_world == 0 )

-- No weapon list: only how many random weapons, and a single random perk.
local weapons, perks = list[3], list[4]
assert( weapons.name == "STARTING WEAPONS" and #weapons.labels == 5 and #weapons.values == 5 )
assert( weapons.labels[1] == "NONE" and weapons.labels[2] == "1 RANDOM WEAPON" and weapons.labels[3] == "2 RANDOM WEAPONS" )
assert( weapons.labels[4] == "1 PACKED WEAPON" and weapons.labels[5] == "2 PACKED WEAPONS" and weapons.values[4] == 3 and weapons.values[5] == 4 and weapons.values[3] == 2 )
assert( perks.name == "STARTING PERK" and #perks.labels == 2 and perks.labels[2] == "1 RANDOM PERK" and perks.values[2] == 1 )
assert( CoD.PrivateGameLobby.DvarDefaults.zmcp_start_weapons == 0 and CoD.PrivateGameLobby.DvarDefaults.zmcp_start_perks == 0 )
assert( list[1].id == "sv_cheats" and not CoD.ZMCheckpointMenu.LoadoutMaps and not CoD.ZMCheckpointMenu.LoadoutWeapons, "weapon lists are gone" )

-- Stored values are clamped when the lobby opens; valid ones are kept.
local function open( weaponsValue, perksValue )
	dvars.zmcp_start_weapons, dvars.zmcp_start_perks = weaponsValue, perksValue
	LUI.createMenu.PrivateOnlineGameLobby( 0 )
	return tostring( dvars.zmcp_start_weapons ), tostring( dvars.zmcp_start_perks )
end
local w, p = open( nil, nil ); assert( w == "0" and p == "0", "missing values start at 0" )
w, p = open( "4", "1" ); assert( w == "4" and p == "1", "valid values are kept" )
w, p = open( "9", "4" ); assert( w == "4" and p == "1", "old multi-perk and oversized values clamp" )
w, p = open( "-3", "-1" ); assert( w == "0" and p == "0" )
w, p = open( "x", "1.7" ); assert( w == "0" and p == "1" )
dvars.zmcp_start_points, dvars.zmcp_start_world = "50000", "2"
LUI.createMenu.PrivateOnlineGameLobby( 0 )
assert( tostring( dvars.zmcp_start_points ) == "50000" and tostring( dvars.zmcp_start_world ) == "2", "valid points/opening kept" )
dvars.zmcp_start_points, dvars.zmcp_start_world = "123", "9"
LUI.createMenu.PrivateOnlineGameLobby( 0 )
assert( tostring( dvars.zmcp_start_points ) == "123" and tostring( dvars.zmcp_start_world ) == "3", "typed points kept, opening clamps" )
dvars.zmcp_start_points = "99999999"
LUI.createMenu.PrivateOnlineGameLobby( 0 )
assert( tostring( dvars.zmcp_start_points ) == "1000000", "points clamp to 1,000,000" )
dvars.zmcp_start_points = "-5"
LUI.createMenu.PrivateOnlineGameLobby( 0 )
assert( tostring( dvars.zmcp_start_points ) == "0" )
dvars.zmcp_start_points, dvars.zmcp_start_world = nil, "x"
LUI.createMenu.PrivateOnlineGameLobby( 0 )
assert( tostring( dvars.zmcp_start_points ) == "0" and tostring( dvars.zmcp_start_world ) == "0" )
print( "PASS: starting loadout rows: weapon count 0-4 (random or packed), single random perk, points and opening rows, stored values clamped" )
