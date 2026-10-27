-- Companion updater information popup.
local C = CoD.ZMCheckpointMenu
local requestUpdateCheck = function ( controller )
	Engine.SetDvar( "zmcp_update_state", "checking" )
	Engine.SetDvar( "zmcp_update_version", "" )
	-- T6 logs an unknown command; echo itself is unsupported here.
	Engine.Exec( controller, "zmcp_update_request_20261028\n" )
end

C.OpenUpdater = function ( menu, event )
	local controller = event.controller or menu.m_ownerController or 0
	requestUpdateCheck( controller )
	menu:openPopup( "ZMCheckpointUpdaterInfo", controller )
end

LUI.createMenu.ZMCheckpointUpdaterInfo = function ( controller )
	local menu = CoD.Menu.New( "ZMCheckpointUpdaterInfo" )
	menu.m_ownerController = controller
	menu:addLargePopupBackground()
	menu:addTitle( "ZM CHECKPOINT UPDATER" )
	menu:addBackButton()
	-- Match the stock Mods/Server Browser R Refresh prompt and key binding.
	local refreshPrompt = CoD.ButtonPrompt.new( "alt1", Engine.Localize( "MENU_REFRESH" ), menu,
		"button_prompt_refresh", false, false, false, false, "R" )
	menu:addRightButtonPrompt( refreshPrompt )

	local status = LUI.UIText.new()
	status:setLeftRight( true, true, 0, 0 )
	status:setTopBottom( true, false, 105, 133 )
	status:setFont( CoD.fonts.Condensed )
	status:setAlignment( LUI.Alignment.Left )
	status:setText( "Checking for updates..." )
	menu:addElement( status )

	local body = LUI.UIText.new()
	body:setLeftRight( true, true, 0, 0 )
	body:setTopBottom( true, false, 150, 178 )
	body:setFont( CoD.fonts.Default )
	body:setAlignment( LUI.Alignment.Left )
	body:setText( "Checking GitHub for a new version..." )
	menu:addElement( body )
	local actions = CoD.ButtonList.new( { leftAnchor = true, rightAnchor = false,
		left = 0, right = 500, topAnchor = true, bottomAnchor = false,
		top = 270, bottom = 370 } )
	menu:addElement( actions )
	local install = actions:addButton( "INSTALL UPDATE", "Download and install the latest ZM Checkpoint release." )
	local later = actions:addButton( "NOT NOW", "Keep the current version." )
	local back = actions:addButton( "BACK", "Return to the Zombies menu." )
	install:setActionEventName( "zmcp_update_install" )
	later:setActionEventName( "zmcp_update_later" )
	back:setActionEventName( "zmcp_update_back" )
	install:disable()
	later:disable()
	back:disable()
	back:setAlpha( 0 )
	local choiceMode = "checking"
	local function showBack()
		install:disable()
		later:disable()
		if choiceMode ~= "back" then
			install:processEvent( { name = "lose_focus" } )
			later:processEvent( { name = "lose_focus" } )
			back:setAlpha( 1 )
			back:enable()
			back:processEvent( { name = "gain_focus" } )
			choiceMode = "back"
		end
	end
	menu:registerEventHandler( "button_prompt_refresh", function ()
		if menu.zmcpInstallRequested then return end
		showBack()
		status:setText( "Checking for updates..." )
		body:setText( "Checking GitHub for a new version..." )
		requestUpdateCheck( controller )
	end )
	menu:registerEventHandler( "zmcp_update_install", function ()
		if menu.zmcpInstallRequested then return end
		menu.zmcpInstallRequested = true
		install:disable()
		later:disable()
		back:disable()
		back:setAlpha( 0 )
		choiceMode = "installing"
		status:setText( "Installing update..." )
		body:setText( "Downloading and installing..." )
		Engine.Exec( controller, "zmcp_update_install_20261028\n" )
	end )
	menu:registerEventHandler( "zmcp_update_later", function () menu:goBack() end )
	menu:registerEventHandler( "zmcp_update_back", function () menu:goBack() end )
	menu:registerEventHandler( "zmcp_update_refresh", function ()
		Engine.Exec( controller, "exec zmcp_update_status.cfg\n" )
		local state = UIExpression.DvarString( nil, "zmcp_update_state" )
		local version = UIExpression.DvarString( nil, "zmcp_update_version" ) or ""
		if state == "up_to_date" then
			showBack()
			status:setText( "Latest version installed." )
			body:setText( "Installed: " .. version )
		elseif state == "update_available" then
			status:setText( "Update available: " .. version )
			body:setText( "Install this update now?" )
			if not menu.zmcpInstallRequested then
				install:enable()
				later:enable()
				if choiceMode ~= "update_available" then
					back:processEvent( { name = "lose_focus" } )
					back:disable()
					back:setAlpha( 0 )
					install:processEvent( { name = "gain_focus" } )
					choiceMode = "update_available"
				end
			end
		elseif state == "installing" then
			install:disable()
			later:disable()
			status:setText( "Installing update..." )
			body:setText( "Downloading and installing..." )
		elseif state == "installed" then
			menu.zmcpInstallRequested = false
			showBack()
			status:setText( "Update installed: " .. version )
			body:setText( "Unload and reload the mod from the Mods menu." )
		elseif state == "error" then
			menu.zmcpInstallRequested = false
			showBack()
			status:setText( "Update check failed." )
			body:setText( "Check your connection and try again." )
		end
	end )
	menu:addElement( LUI.UITimer.new( 1500, "zmcp_update_refresh", false ) )
	return menu
end
