-- Companion updater information popup.
local C = CoD.ZMCheckpointMenu
C.OpenUpdater = function ( menu, event )
	local controller = event.controller or menu.m_ownerController or 0
	Engine.SetDvar( "zmcp_update_state", "checking" )
	Engine.SetDvar( "zmcp_update_version", "" )
	-- T6 logs an unknown command; echo itself is unsupported here.
	Engine.Exec( controller, "zmcp_update_request_20261028\n" )
	menu:openPopup( "ZMCheckpointUpdaterInfo", controller )
end

LUI.createMenu.ZMCheckpointUpdaterInfo = function ( controller )
	local menu = CoD.Menu.New( "ZMCheckpointUpdaterInfo" )
	menu.m_ownerController = controller
	menu:addLargePopupBackground()
	menu:addTitle( "ZM CHECKPOINT UPDATER" )
	menu:addBackButton()

	local status = LUI.UIText.new()
	status:setLeftRight( true, true, 0, 0 )
	status:setTopBottom( true, false, 105, 139 )
	status:setFont( CoD.fonts.Condensed )
	status:setAlignment( LUI.Alignment.Left )
	status:setText( "Checking for updates..." )
	menu:addElement( status )

	local body = LUI.UIText.new()
	body:setLeftRight( true, true, 0, 0 )
	body:setTopBottom( true, false, 150, 224 )
	body:setFont( CoD.fonts.Condensed )
	body:setAlignment( LUI.Alignment.Left )
	body:setText( "Please wait while ZM Checkpoint checks GitHub." )
	menu:addElement( body )
	menu:registerEventHandler( "zmcp_update_refresh", function ()
		Engine.Exec( controller, "exec zmcp_update_status.cfg\n" )
		local state = UIExpression.DvarString( nil, "zmcp_update_state" )
		local version = UIExpression.DvarString( nil, "zmcp_update_version" ) or ""
		if state == "up_to_date" then
			status:setText( "Latest version installed." )
			body:setText( "Installed: " .. version )
		elseif state == "update_available" then
			status:setText( "Update available: " .. version )
			body:setText( "Choose Yes in the Windows update prompt to install it." )
		elseif state == "installed" then
			status:setText( "Update installed: " .. version )
			body:setText( "Unload and reload the mod from the Mods menu." )
		elseif state == "error" then
			status:setText( "Update check failed." )
			body:setText( "Check your connection and try again." )
		end
	end )
	menu:addElement( LUI.UITimer.new( 1500, "zmcp_update_refresh", false ) )
	return menu
end
