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
	return menu
end
