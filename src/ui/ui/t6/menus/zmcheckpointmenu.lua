-- ZM Checkpoint frontend and pause-menu integration.
-- Actions are sent to the server-side GSC through the stock menuresponse path.

CoD.ZMCheckpointMenu = CoD.ZMCheckpointMenu or {}

local C = CoD.ZMCheckpointMenu

C.MenuResponseName = "zm_checkpoint"
C.SupportedMaps = {
	zm_transit = "TRANZIT",
	zm_nuked = "NUKETOWN",
	zm_highrise = "DIE RISE",
	zm_prison = "MOB OF THE DEAD",
	zm_buried = "BURIED",
	zm_tomb = "ORIGINS"
}

C.DvarString = function ( name )
	local value = UIExpression.DvarString( nil, name )
	if value == nil then
		return ""
	end
	return value
end

C.CurrentMap = function ( inGame )
	local name = C.DvarString( inGame and "mapname" or "ui_mapname" )
	if string.find( name, "zm_transit", 1, true ) ~= nil then
		return "zm_transit"
	end
	return name
end

C.IsSupportedMap = function ( inGame )
	return C.SupportedMaps[C.CurrentMap( inGame )] ~= nil
end

C.HasCheckpoint = function ( mapName )
	local name = mapName or C.CurrentMap( false )
	return C.SupportedMaps[name] ~= nil and
		(tonumber( C.DvarString( "zmcp_has_" .. name ) ) or 0) == 1
end

C.ResumeLabel = function ( mapName )
	local name = mapName or C.CurrentMap( false )
	local round = tonumber( C.DvarString( "zmcp_round_" .. name ) ) or 0
	if round > 0 then
		return "RESUME " .. C.SupportedMaps[name] .. " - ROUND " .. tostring( round )
	end
	return "RESUME CHECKPOINT"
end

C.ClosePauseMenu = function ( menu, controller )
	Engine.SetDvar( "cl_paused", 0 )
	if menu ~= nil then
		pcall( function ()
			menu:processEvent( {
				name = "close_all_ingame_menus",
				controller = controller
			} )
		end )
	end
end

C.SaveAndExit = function ( menu, event )
	if not C.IsSupportedMap( true ) then
		return
	end

	local controller = event.controller or 0
	Engine.SendMenuResponse( controller, C.MenuResponseName, "hello_040" )
	-- The dvar bridge is intentionally sent as well as the stock menu response.
	-- It keeps Save & Exit working in total conversions that replace or consume
	-- the normal menuresponse callback.
	Engine.Exec( controller, "set zmcp_command save_exit\n" )
	Engine.SendMenuResponse( controller, C.MenuResponseName, "save_exit" )
	C.ClosePauseMenu( menu, controller )
	Engine.PlaySound( "uin_navigation_click" )
end

C.Resume = function ( menu, event )
	local controller = event.controller or 0
	if Engine.PartyGetPlayerCount() ~= 1 then
		return
	end
	Engine.Exec( controller, "set zmcp_coop_autoload 0\n" )
	-- Resume through the stock private-lobby launch path. A raw `map` command
	-- skips the Zombies session bootstrap, leaving the player in a loaded map
	-- without a round controller, HUD round counter, or zombie spawns.
	Engine.Exec( controller, "set zmcp_autoload 1\n" )
	Engine.Exec( controller, "xpartygo\n" )
	Engine.PlaySound( "uin_navigation_click" )
end

C.HookLobby = function ()
	-- Kept as a compatibility entry point for older companion packages.
	-- The actual button is now attached directly to PrivateOnlineGameLobby,
	-- after the stock lobby has finished constructing its internal button list.
end

C.AddLobbyResumeButton = function ( menu, controller )
	C.AddCoopLobbyButton( menu, controller )
	if menu == nil or menu.zmcpLobbyButtonAdded then
		return
	end
	local mapName = C.CurrentMap( false )
	if not C.HasCheckpoint( mapName ) then
		return
	end
	menu.zmcpLobbyButtonAdded = true
	Engine.SetDvar( "zmcp_ui_version", "0.4.0" )

	local pane = menu.panelManager and menu.panelManager.panels and menu.panelManager.panels.buttonPane
	local list = pane and pane.body and pane.body.buttonList
	if list == nil then
		menu.zmcpLobbyButtonAdded = false
		return
	end

	local button = list:addButton(
		C.ResumeLabel( mapName ),
		"Continue the saved " .. C.SupportedMaps[mapName] .. " run from the beginning of its saved round." )

	-- addButton appends to the vertical list. Reinsert the fully constructed
	-- stock button at the top so it sits immediately above START MATCH while
	-- retaining the list's normal focus, mouse, controller, and hint behavior.
	list:removeElement( button )
	list:addElementToTop( button )

	button:setActionEventName( "zmcp_resume_checkpoint" )
	menu.zmcpLobbyResumeButton = button
	menu:registerEventHandler( "zmcp_resume_checkpoint", C.Resume )
end

C.AddFallbackButton = function ( menu, controller )
	if menu == nil or menu.zmcpButtonAdded then
		return
	end
	menu.zmcpButtonAdded = true

	local list = CoD.ButtonList.new( {
		leftAnchor = true,
		rightAnchor = false,
		left = 300,
		right = 570,
		topAnchor = true,
		bottomAnchor = false,
		top = 410,
		bottom = 455
	} )
	menu:addElement( list )
	local button = list:addButton( "SAVE & EXIT", "Save this run and return to the lobby." )
	button:setActionEventName( "zmcp_save_exit" )

	-- PlutoFR/Void Zombies exposes its pause cards. Link our fallback into
	-- that navigation loop so keyboard and controller users can reach it too.
	if menu.plfr_cards ~= nil and #menu.plfr_cards > 0 then
		local first = menu.plfr_cards[1]
		local last = menu.plfr_cards[#menu.plfr_cards]
		button.navigation = button.navigation or {}
		first.navigation = first.navigation or {}
		last.navigation = last.navigation or {}
		button.navigation.up = last
		button.navigation.down = first
		last.navigation.down = button
		first.navigation.up = button
	end
end

C.HookLobby()
require( "T6.Menus.ZMCheckpointCoop" )
require( "T6.Menus.ZMCheckpointUpdater" )




