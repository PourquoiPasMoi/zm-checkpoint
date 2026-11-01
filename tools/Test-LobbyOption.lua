-- Loads the shipped private-lobby hook with a mocked stock lobby and checks the
-- UNLIMITED PERKS row is appended once after CHEATS and its dvar is initialized.
local dvars = {}
local stockDvars = { { id = "zombies_minplayers" }, { id = "sv_allowAimAssist" }, { id = "sv_cheats" } }
local built
CoD = { isMultiplayer = false, ButtonPrompt = { Height = 30 } }
CoD.PrivateGameLobby = {
	Dvars = stockDvars,
	DvarDefaults = {},
	New = function ( name, controller )
		built = { dvarAtBuild = dvars.zmcp_all_perks, count = #CoD.PrivateGameLobby.Dvars }
		local menu = {}
		function menu:setPreviousMenu() end
		function menu:addTitle() end
		function menu:registerEventHandler() end
		menu.panelManager = { panels = { buttonPane = {} } }
		return menu
	end
}
CoD.GameLobby = {}
CoD.ZMCheckpointMenu = {
	HookLobby = function () end,
	AddLobbyResumeButton = function () end,
	DvarString = function ( name ) return dvars[name] == nil and "" or tostring( dvars[name] ) end
}
LUI = { createMenu = {} }
Engine = { Localize = function ( s ) return s end, SetDvar = function ( k, v ) dvars[k] = v end }
function require() end

local chunk = assert( loadfile( "src/ui/ui/t6/menus/privateonlinegamelobby.lua" ) )
chunk()
chunk() -- loading twice must not duplicate the row

local list = CoD.PrivateGameLobby.Dvars
assert( #list == 8, "expected five added rows, got " .. #list )
assert( list[4].id == "zmcp_all_perks" and list[3].id == "sv_cheats", "row must follow CHEATS" )
assert( list[5].id == "zmcp_start_weapons" and list[6].id == "zmcp_start_perks" )
assert( list[7].id == "zmcp_start_points" and list[8].id == "zmcp_start_world" )
assert( list[4].values[1] == 0 and list[4].values[2] == 1 and #list[4].labels == 2 )
assert( CoD.PrivateGameLobby.DvarDefaults.zmcp_all_perks == 0 )
LUI.createMenu.PrivateOnlineGameLobby( 0 )
assert( built.dvarAtBuild == 0, "dvar must exist before the selector is built" )
dvars.zmcp_all_perks = 1
LUI.createMenu.PrivateOnlineGameLobby( 0 )
assert( built.dvarAtBuild == 1, "an existing value must not be reset" )
print( "PASS: unlimited perks lobby row appended once after CHEATS; dvar kept" )
