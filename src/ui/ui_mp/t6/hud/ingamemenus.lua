-- Stock T6 in-game menu loader with the ZM Checkpoint hook loaded last.
-- The final require is the only Checkpoint-specific change.

require( "T6.CoDBase" )
require( "T6.MFPopup" )
require( "T6.HUD.EndGamePopup" )
require( "T6.HUD.team_marinesopfor" )

if CoD.isZombie == true then
	require( "T6.Zombie.RestartGamePopupZombie" )
else
	require( "T6.HUD.changeclass" )
end

require( "T6.HUD.class" )
require( "T6.Options" )

CoD.InGameMenu = InheritFrom( CoD.Menu )

CoD.InGameMenu.New = function ( menuName, controller, title )
	local menu = CoD.Menu.New( menuName )
	menu:setClass( CoD.InGameMenu )
	menu:setOwner( controller )
	if title ~= nil then
		menu:addTitle( title )
	end
	return menu
end

CoD.InGameMenu.BackButtonPressed = function ( menu, event )
	if CoD.isZombie == true and UIExpression.IsDemoPlaying( event.controller ) == 0 and CoD.InGameMenu.m_unpauseDisabled and CoD.InGameMenu.m_unpauseDisabled[event.controller + 1] ~= nil and CoD.InGameMenu.m_unpauseDisabled[event.controller + 1] > 0 then
		if menu.menuName ~= "class" then
			CoD.Menu.ButtonPromptBack( menu, event )
		end
		return
	end

	CoD.Menu.ButtonPromptBack( menu, event )
	if not menu.previousMenuName then
		if CoD.isZombie == true and UIExpression.IsDemoPlaying( event.controller ) == 0 then
			Engine.SetDvar( "cl_paused", 0 )
		end
		if menu.occludedMenu ~= nil then
			menu.occludedMenu:processEvent( {
				name = "close_ingame_menu",
				controller = event.controller
			} )
		end
		Engine.SendMenuResponse( event.controller, "vcs", "ingame_menu_closed" )
	end
end

CoD.InGameMenu.StartButtonPressed = function ( menu, event )
	if CoD.isZombie == true and UIExpression.IsDemoPlaying( event.controller ) == 0 then
		if CoD.InGameMenu.m_unpauseDisabled and CoD.InGameMenu.m_unpauseDisabled[event.controller + 1] ~= nil and CoD.InGameMenu.m_unpauseDisabled[event.controller + 1] > 0 then
			return
		end
		Engine.SetDvar( "cl_paused", 0 )
	end

	CoD.Menu.ButtonPromptBack( menu, event )
	if not menu.previousMenuName and menu.occludedMenu ~= nil then
		menu.occludedMenu:processEvent( {
			name = "close_ingame_menu",
			controller = event.controller
		} )
	end
end

CoD.InGameMenu.addButtonPrompts = function ( menu )
	menu:addSelectButton()
	menu:addBackButton()
	menu.backButtonPrompt = CoD.ButtonPrompt.new( "select", "", menu, "button_prompt_back", true )
	menu.startButtonPrompt = CoD.ButtonPrompt.new( "start", "", menu, "button_prompt_start", true )
	menu:addRightButtonPrompt( menu.backButtonPrompt )
	menu:addRightButtonPrompt( menu.startButtonPrompt )
end

CoD.InGameMenu.CloseAllInGameMenus = function ( menu, event )
	if CoD.isZombie == true and UIExpression.IsDemoPlaying( event.controller ) == 0 then
		if CoD.InGameMenu.m_unpauseDisabled == nil then
			CoD.InGameMenu.m_unpauseDisabled = {}
		end
		CoD.InGameMenu.m_unpauseDisabled[event.controller + 1] = 0
	end

	menu:dispatchEventToChildren( event )
	if not menu.m_inputDisabled then
		menu.previousMenuName = nil
		menu:goBack()
		if menu.occludedMenu then
			menu.occludedMenu:processEvent( event )
		end
	end
end

CoD.InGameMenu:registerEventHandler( "close_all_ingame_menus", CoD.InGameMenu.CloseAllInGameMenus )
CoD.InGameMenu:registerEventHandler( "button_prompt_back", CoD.InGameMenu.BackButtonPressed )
CoD.InGameMenu:registerEventHandler( "button_prompt_start", CoD.InGameMenu.StartButtonPressed )

require( "T6.Menus.ZMCheckpointInGame" )
