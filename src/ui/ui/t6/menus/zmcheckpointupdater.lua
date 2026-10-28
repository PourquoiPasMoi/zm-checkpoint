-- Companion updater information popup.
local C = CoD.ZMCheckpointMenu
local nextRequestId = function ( controller )
	local archived = tonumber( C.DvarString( "zmcp_update_sequence" ) ) or 0
	C.UpdateRequestCounter = math.max( C.UpdateRequestCounter or 0, archived ) + 1
	if C.UpdateRequestCounter > 999999 then C.UpdateRequestCounter = 1 end
	Engine.Exec( controller, "seta zmcp_update_sequence " .. C.UpdateRequestCounter .. "\n" )
	return tostring( math.random( 100000000, 999999999 ) ) .. tostring( C.UpdateRequestCounter )
end
local requestUpdateCheck = function ( controller )
	local requestId = nextRequestId( controller )
	C.PendingUpdateRequestId = requestId
	Engine.SetDvar( "zmcp_update_state", "checking" )
	Engine.SetDvar( "zmcp_update_version", "" )
	-- T6 logs an unknown command; echo itself is unsupported here.
	Engine.Exec( controller, "zmcp_update_request_20261028_" .. requestId .. "\n" )
	return requestId
end

C.OpenUpdater = function ( menu, event )
	local controller = event.controller or menu.m_ownerController or 0
	requestUpdateCheck( controller )
	menu:openPopup( "ZMCheckpointUpdaterInfo", controller )
end

LUI.createMenu.ZMCheckpointUpdaterInfo = function ( controller )
	local menu = CoD.Menu.New( "ZMCheckpointUpdaterInfo" )
	menu.m_ownerController = controller
	menu.zmcpRequestId = C.PendingUpdateRequestId
	menu.zmcpWaitTicks = 0
	menu:addLargePopupBackground()
	menu:addTitle( "ZM CHECKPOINT UPDATER" )
	menu:addBackButton()
	-- Match the stock Mods menu's U Unload and R Refresh prompt bindings.
	local unloadPrompt = CoD.ButtonPrompt.new( "alt1", Engine.Localize( "MENU_UNLOAD" ), menu,
		"button_prompt_unload", false, nil, false, nil, "U" )
	local refreshPrompt = CoD.ButtonPrompt.new( "alt2", Engine.Localize( "MENU_REFRESH" ), menu,
		"button_prompt_refresh", false, nil, false, nil, "R" )
	menu:addRightButtonPrompt( refreshPrompt )

	local status = LUI.UIText.new()
	status:setLeftRight( true, false, 0, 520 )
	status:setTopBottom( true, false, 105, 133 )
	status:setFont( CoD.fonts.Condensed )
	status:setAlignment( LUI.Alignment.Left )
	status:setText( "Checking for updates..." )
	menu:addElement( status )

	local body = LUI.UIText.new()
	body:setLeftRight( true, false, 0, 520 )
	body:setTopBottom( true, false, 150, 178 )
	body:setFont( CoD.fonts.Default )
	body:setAlignment( LUI.Alignment.Left )
	body:setText( "Checking GitHub for a new version..." )
	menu:addElement( body )

	-- Keep release notes inside the unused right column of the large popup.
	local notesPanel = LUI.UIElement.new()
	notesPanel:setLeftRight( true, false, 585, 1050 )
	notesPanel:setTopBottom( true, false, 145, 535 )
	local notesBackground = LUI.UIImage.new()
	notesBackground:setLeftRight( true, true, 0, 0 )
	notesBackground:setTopBottom( true, true, 0, 0 )
	notesBackground:setRGB( 0.04, 0.04, 0.04 )
	notesBackground:setAlpha( 0.68 )
	notesPanel:addElement( notesBackground )
	local notesBorderLeft = LUI.UIImage.new()
	notesBorderLeft:setLeftRight( true, false, 0, 1 )
	notesBorderLeft:setTopBottom( true, true, 0, 0 )
	notesBorderLeft:setRGB( 0.48, 0.48, 0.48 )
	notesBorderLeft:setAlpha( 0.5 )
	notesPanel:addElement( notesBorderLeft )
	local notesBorderRight = LUI.UIImage.new()
	notesBorderRight:setLeftRight( false, true, -1, 0 )
	notesBorderRight:setTopBottom( true, true, 0, 0 )
	notesBorderRight:setRGB( 0.48, 0.48, 0.48 )
	notesBorderRight:setAlpha( 0.5 )
	notesPanel:addElement( notesBorderRight )
	local notesBorderBottom = LUI.UIImage.new()
	notesBorderBottom:setLeftRight( true, true, 0, 0 )
	notesBorderBottom:setTopBottom( false, true, -1, 0 )
	notesBorderBottom:setRGB( 0.48, 0.48, 0.48 )
	notesBorderBottom:setAlpha( 0.5 )
	notesPanel:addElement( notesBorderBottom )
	local notesAccent = LUI.UIImage.new()
	notesAccent:setLeftRight( true, true, 0, 0 )
	notesAccent:setTopBottom( true, false, 0, 3 )
	notesAccent:setRGB( CoD.BOIIOrange.r, CoD.BOIIOrange.g, CoD.BOIIOrange.b )
	notesPanel:addElement( notesAccent )
	local notesTitle = LUI.UIText.new()
	notesTitle:setLeftRight( true, true, 18, -18 )
	notesTitle:setTopBottom( true, false, 16, 42 )
	notesTitle:setFont( CoD.fonts.Condensed )
	notesTitle:setRGB( CoD.BOIIOrange.r, CoD.BOIIOrange.g, CoD.BOIIOrange.b )
	notesTitle:setAlignment( LUI.Alignment.Left )
	notesTitle:setText( "LATEST CHANGES" )
	notesPanel:addElement( notesTitle )
	local notesVersion = LUI.UIText.new()
	notesVersion:setLeftRight( true, true, 18, -18 )
	notesVersion:setTopBottom( true, false, 52, 76 )
	notesVersion:setFont( CoD.fonts.Condensed )
	notesVersion:setAlignment( LUI.Alignment.Left )
	notesVersion:setText( "Checking release notes..." )
	notesPanel:addElement( notesVersion )
	local notesDivider = LUI.UIImage.new()
	notesDivider:setLeftRight( true, true, 18, -18 )
	notesDivider:setTopBottom( true, false, 87, 88 )
	notesDivider:setRGB( 0.5, 0.5, 0.5 )
	notesDivider:setAlpha( 0.6 )
	notesPanel:addElement( notesDivider )
	local notesLines = {}
	local notePage = 1
	local noteCount = 0
	local noteCache = {}
	for i = 1, 8 do
		local line = LUI.UIText.new()
		line:setLeftRight( true, true, 18, -18 )
		line:setTopBottom( true, false, 100 + (i - 1) * 26, 122 + (i - 1) * 26 )
		line:setFont( CoD.fonts.Condensed )
		line:setAlignment( LUI.Alignment.Left )
		line:setText( "" )
		notesPanel:addElement( line )
		notesLines[i] = line
	end
	local notePageText = LUI.UIText.new()
	notePageText:setLeftRight( true, true, 245, -18 )
	notePageText:setTopBottom( true, false, 340, 364 )
	notePageText:setFont( CoD.fonts.Condensed )
	notePageText:setAlignment( LUI.Alignment.Right )
	notePageText:setText( "PAGE 1 / 1" )
	notesPanel:addElement( notePageText )
	local noteButtons = CoD.ButtonList.new( { leftAnchor = true, rightAnchor = false,
		left = 18, right = 220, topAnchor = true, bottomAnchor = false,
		top = 318, bottom = 387 } )
	notesPanel:addElement( noteButtons )
	local previousNotes = noteButtons:addButton( "PREV PAGE" )
	local nextNotes = noteButtons:addButton( "NEXT PAGE" )
	previousNotes:disable()
	nextNotes:disable()
	local function renderNotes()
		local total = math.max( 1, math.ceil( noteCount / 8 ) )
		if notePage > total then notePage = total end
		for i = 1, 8 do
			local text = noteCache[(notePage - 1) * 8 + i] or ""
			notesLines[i]:setText( text )
			if string.sub( text, 1, 1 ) == "-" then
				notesLines[i]:setRGB( CoD.BOIIOrange.r, CoD.BOIIOrange.g, CoD.BOIIOrange.b )
			else
				notesLines[i]:setRGB( 1, 1, 1 )
			end
		end
		notePageText:setText( "PAGE " .. notePage .. " / " .. total )
		if notePage > 1 then previousNotes:enable() else previousNotes:disable() end
		if notePage < total then nextNotes:enable() else nextNotes:disable() end
	end
	local function clearNotes()
		notePage = 1
		noteCount = 0
		noteCache = {}
		renderNotes()
	end
	previousNotes:setActionEventName( "zmcp_notes_previous" )
	nextNotes:setActionEventName( "zmcp_notes_next" )
	menu:registerEventHandler( "zmcp_notes_previous", function ()
		if notePage > 1 then notePage = notePage - 1; renderNotes() end
	end )
	menu:registerEventHandler( "zmcp_notes_next", function ()
		if notePage * 8 < noteCount then notePage = notePage + 1; renderNotes() end
	end )
	menu:addElement( notesPanel )
	local actions = CoD.ButtonList.new( { leftAnchor = true, rightAnchor = false,
		left = 0, right = 500, topAnchor = true, bottomAnchor = false,
		top = 270, bottom = 440 } )
	menu:addElement( actions )
	local install = actions:addButton( "INSTALL UPDATE", "Download and install the latest ZM Checkpoint release." )
	local later = actions:addButton( "NOT NOW", "Keep the current version." )
	local unload = actions:addButton( "UNLOAD", "Unload ZM Checkpoint so the new version can be loaded." )
	local back = actions:addButton( "BACK", "Return to the Zombies menu." )
	-- Allow keyboard/controller focus to move from the main choices into the
	-- notes footer as well as allowing mouse clicks on its page buttons.
	for _, button in ipairs( { install, later, unload, back } ) do
		button.navigation = button.navigation or {}
		button.navigation.right = nextNotes
	end
	previousNotes.navigation = previousNotes.navigation or {}
	nextNotes.navigation = nextNotes.navigation or {}
	previousNotes.navigation.down = nextNotes
	nextNotes.navigation.up = previousNotes
	previousNotes.navigation.left = back
	nextNotes.navigation.left = back
	install:setActionEventName( "zmcp_update_install" )
	later:setActionEventName( "zmcp_update_later" )
	unload:setActionEventName( "zmcp_update_unload" )
	back:setActionEventName( "zmcp_update_back" )
	install:disable()
	later:disable()
	unload:disable()
	unload:setAlpha( 0 )
	back:disable()
	back:setAlpha( 0 )
	local choiceMode = "checking"
	local function setUnloadVisible( visible )
		if menu.zmcpUnloadVisible == visible then return end
		menu.zmcpUnloadVisible = visible
		menu.rightButtonPromptBar:removeAllChildren()
		if visible then
			unload:setAlpha( 1 )
			unload:enable()
			menu:addRightButtonPrompt( unloadPrompt )
		else
			unload:disable()
			unload:setAlpha( 0 )
		end
		menu:addRightButtonPrompt( refreshPrompt )
	end
	local function showBack()
		install:disable()
		later:disable()
		if choiceMode == "installed" then unload:processEvent( { name = "lose_focus" } ) end
		setUnloadVisible( false )
		if choiceMode ~= "back" then
			install:processEvent( { name = "lose_focus" } )
			later:processEvent( { name = "lose_focus" } )
			back:setAlpha( 1 )
			back:enable()
			back:processEvent( { name = "gain_focus" } )
			choiceMode = "back"
		end
	end
	local function showInstalled()
		install:disable()
		later:disable()
		if choiceMode ~= "installed" then
			install:processEvent( { name = "lose_focus" } )
			later:processEvent( { name = "lose_focus" } )
			back:processEvent( { name = "lose_focus" } )
			back:setAlpha( 1 )
			back:enable()
			setUnloadVisible( true )
			unload:processEvent( { name = "gain_focus" } )
			choiceMode = "installed"
		end
	end
	local function unloadMod()
		if not menu.zmcpUpdateInstalled then return end
		if Dvar.fs_game:get() ~= "" then Engine.Exec( 0, 'loadmod ""' ) end
	end
	menu:registerEventHandler( "button_prompt_unload", unloadMod )
	menu:registerEventHandler( "zmcp_update_unload", unloadMod )
	menu:registerEventHandler( "button_prompt_refresh", function ()
		if menu.zmcpInstallRequested then return end
		showBack()
		status:setText( "Checking for updates..." )
		body:setText( "Checking GitHub for a new version..." )
		notesVersion:setText( "Checking release notes..." )
		clearNotes()
		menu.zmcpRequestId = requestUpdateCheck( controller )
		menu.zmcpWaitTicks = 0
	end )
	menu:registerEventHandler( "zmcp_update_install", function ()
		if menu.zmcpInstallRequested then return end
		menu.zmcpInstallRequested = true
		menu.zmcpInstallTargetVersion = UIExpression.DvarString( nil, "zmcp_update_version" )
		menu.zmcpRequestId = nextRequestId( controller )
		menu.zmcpWaitTicks = 0
		menu.zmcpUpdateInstalled = false
		install:disable()
		later:disable()
		setUnloadVisible( false )
		back:disable()
		back:setAlpha( 0 )
		choiceMode = "installing"
		status:setText( "Installing update..." )
		body:setText( "Downloading and installing..." )
		Engine.Exec( controller, "zmcp_update_install_20261028_" .. menu.zmcpRequestId .. "\n" )
	end )
	menu:registerEventHandler( "zmcp_update_later", function () menu:goBack() end )
	menu:registerEventHandler( "zmcp_update_back", function () menu:goBack() end )
	menu:registerEventHandler( "zmcp_update_refresh", function ()
		Engine.Exec( controller, "exec zmcp_update_status.cfg\n" )
		local responseId = UIExpression.DvarString( nil, "zmcp_update_request_id" ) or ""
		if responseId ~= menu.zmcpRequestId then
			menu.zmcpWaitTicks = menu.zmcpWaitTicks + 1
			if menu.zmcpWaitTicks >= 120 then
				menu.zmcpInstallRequested = false
				showBack()
				status:setText( "Update check did not finish." )
				body:setText( "The update companion did not reply. Press R to retry." )
			else
				status:setText( menu.zmcpInstallRequested and "Starting update..." or "Checking for updates..." )
				body:setText( "Waiting for the update companion..." )
			end
			return
		end
		menu.zmcpWaitTicks = 0
		local state = UIExpression.DvarString( nil, "zmcp_update_state" )
		local version = UIExpression.DvarString( nil, "zmcp_update_version" ) or ""
		if state == "checking" then
			notesVersion:setText( "Checking release notes..." )
			clearNotes()
		elseif state == "error" then
			notesVersion:setText( "Release notes unavailable." )
			clearNotes()
		else
			notesVersion:setText( "VERSION " .. version )
			local count = tonumber( UIExpression.DvarString( nil, "zmcp_update_note_count" ) ) or 11
			count = math.max( 0, math.min( 64, count ) )
			if count ~= noteCount then notePage = 1 end
			noteCount = count
			for i = 1, count do noteCache[i] = UIExpression.DvarString( nil, "zmcp_update_note" .. i ) or "" end
			renderNotes()
		end
		if state == "up_to_date" then
			if menu.zmcpInstallRequested then
				if version == menu.zmcpInstallTargetVersion then
					menu.zmcpUpdateInstalled = true
					menu.zmcpInstallRequested = false
				else
					status:setText( "Installing update..." )
					body:setText( "Waiting for the current check to finish..." )
					return
				end
			end
			if menu.zmcpUpdateInstalled then showInstalled() else showBack() end
			status:setText( "Latest version installed." )
			body:setText( "Installed: " .. version )
		elseif state == "update_available" then
			if menu.zmcpInstallRequested then
				status:setText( "Installing update..." )
				body:setText( "Waiting for the current check to finish..." )
				return
			end
			status:setText( "Update available: " .. version )
			body:setText( "Install this update now?" )
			if not menu.zmcpInstallRequested then
				install:enable()
				later:enable()
				if choiceMode ~= "update_available" then
					if choiceMode == "installed" then unload:processEvent( { name = "lose_focus" } ) end
					setUnloadVisible( false )
					back:processEvent( { name = "lose_focus" } )
					back:disable()
					back:setAlpha( 0 )
					install:processEvent( { name = "gain_focus" } )
					choiceMode = "update_available"
				end
			end
		elseif state == "installing" or state == "downloading" or state == "unpacking" or state == "copying" then
			install:disable()
			later:disable()
			status:setText( "Installing update..." )
			if state == "downloading" then
				body:setText( "Downloading the release..." )
			elseif state == "unpacking" then
				body:setText( "Checking and unpacking the release..." )
			elseif state == "copying" then
				body:setText( "Copying mod files; saves are untouched..." )
			else
				body:setText( "Contacting GitHub..." )
			end
		elseif state == "installed" then
			if menu.zmcpInstallRequested or version == menu.zmcpInstallTargetVersion then
				menu.zmcpUpdateInstalled = true
			end
			menu.zmcpInstallRequested = false
			if menu.zmcpUpdateInstalled then showInstalled() else showBack() end
			status:setText( "Update installed: " .. version )
			body:setText( "Choose UNLOAD, then reload the mod from Mods." )
		elseif state == "error" then
			local detail = UIExpression.DvarString( nil, "zmcp_update_error" ) or ""
			menu.zmcpInstallRequested = false
			if menu.zmcpUpdateInstalled then showInstalled() else showBack() end
			status:setText( "Update check failed." )
			body:setText( detail ~= "" and detail or "Check your connection and try again." )
		end
	end )
	menu:addElement( LUI.UITimer.new( 1500, "zmcp_update_refresh", false ) )
	return menu
end
