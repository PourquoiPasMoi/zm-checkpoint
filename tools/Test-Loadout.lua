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
assert( table.concat( ids, "," ) == "sv_cheats,zmcp_all_perks,zmcp_start_weapons,zmcp_start_perks", table.concat( ids, "," ) )

-- No weapon list: only how many random weapons, and a single random perk.
local weapons, perks = list[3], list[4]
assert( weapons.name == "STARTING WEAPONS" and #weapons.labels == 3 and #weapons.values == 3 )
assert( weapons.labels[1] == "NONE" and weapons.labels[2] == "1 RANDOM WEAPON" and weapons.labels[3] == "2 RANDOM WEAPONS" )
assert( weapons.values[1] == 0 and weapons.values[2] == 1 and weapons.values[3] == 2 )
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
w, p = open( "2", "1" ); assert( w == "2" and p == "1", "valid values are kept" )
w, p = open( "5", "4" ); assert( w == "2" and p == "1", "old multi-perk and oversized values clamp" )
w, p = open( "-3", "-1" ); assert( w == "0" and p == "0" )
w, p = open( "x", "1.7" ); assert( w == "0" and p == "1" )
print( "PASS: starting loadout rows: random weapon count 0-2 and a single random perk, stored values clamped" )
