-- Stock T6 private lobby entry point with the ZM Checkpoint hook loaded last.

require( "T6.Menus.PrivateGameLobby" )
require( "T6.Menus.ZMCheckpointMenu" )

CoD.ZMCheckpointMenu.HookLobby()

CoD.PrivateOnlineGameLobby = {}

-- Extra lobby option rows. The stock lobby builds one selector row per entry of
-- CoD.PrivateGameLobby.Dvars, so appending here places the row directly under
-- CHEATS with the same spacing, font, hint and focus behavior as the stock rows.
local addLobbyDvarOption = function ( id, default, name, hint )
	for _, option in ipairs( CoD.PrivateGameLobby.Dvars ) do
		if option.id == id then
			return
		end
	end
	local option = {
		id = id,
		name = name,
		hintText = hint,
		labels = { "MENU_DISABLED_CAPS", "MENU_ENABLED_CAPS" },
		values = { 0, 1 }
	}
	CoD.PrivateGameLobby.DvarDefaults[id] = default
	CoD.PrivateGameLobby.Dvars[#CoD.PrivateGameLobby.Dvars + 1] = option
end

addLobbyDvarOption( "zmcp_all_perks", 0, "UNLIMITED PERKS",
	"Allow every perk at once instead of the normal limit of four." )

LUI.createMenu.PrivateOnlineGameLobby = function ( controller )
	-- The selector reads its dvar when it is built; make sure it exists first.
	if CoD.ZMCheckpointMenu.DvarString( "zmcp_all_perks" ) == "" then
		Engine.SetDvar( "zmcp_all_perks", 0 )
	end
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
