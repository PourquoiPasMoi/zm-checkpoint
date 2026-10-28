-- Stock T6 private lobby entry point with the ZM Checkpoint hook loaded last.

require( "T6.Menus.PrivateGameLobby" )
require( "T6.Menus.ZMCheckpointMenu" )

CoD.ZMCheckpointMenu.HookLobby()

CoD.PrivateOnlineGameLobby = {}

LUI.createMenu.PrivateOnlineGameLobby = function ( controller )
	local menu = CoD.PrivateGameLobby.New( "PrivateOnlineGameLobby", controller )
	if CoD.isMultiplayer then
		menu:setPreviousMenu( "MainLobby" )
	end
	local title = Engine.Localize( "MPUI_CUSTOM_GAMES_CAPS" )
	menu:addTitle( title )
	menu.panelManager.panels.buttonPane.titleText = title
	CoD.ZMCheckpointMenu.AddLobbyResumeButton( menu, controller )
	-- Keep the stock map card clear of the expanded left-hand button list and
	-- its focused-row description. The lower right is unused by lobby controls.
	local pane = menu.panelManager and menu.panelManager.panels and menu.panelManager.panels.buttonPane
	local card = pane and pane.body and pane.body.mapInfoImage
	if card then
		card:setLeftRight( true, false, 570, 870 )
		card:setTopBottom( false, true, -CoD.ButtonPrompt.Height - 245, -CoD.ButtonPrompt.Height - 15 )
	end
	-- The stock launch countdown sits under the newly added Resume rows.
	-- Keep it above the map preview in the free right column, including when
	-- the stock lobby rebuilds its status text after an options change.
	local placeStatus = function ( owner )
		local status = owner.buttonPane and owner.buttonPane.body and owner.buttonPane.body.statusText
		if status then
			status:setLeftRight( true, false, 570, 870 )
			status:setTopBottom( false, true, -CoD.ButtonPrompt.Height - 290, -CoD.ButtonPrompt.Height - 260 )
		end
	end
	placeStatus( menu )
	menu:registerEventHandler( "party_update_status", function ( owner, event )
		CoD.GameLobby.UpdateStatusText( owner, event )
		placeStatus( owner )
	end )
	return menu
end
