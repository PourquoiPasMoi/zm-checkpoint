-- Host-stored co-op page. Lobby metadata is only a preview; GSC revalidates.
local C = CoD.ZMCheckpointMenu

C.NormalizeId = function ( id )
	-- Never turn a 64-bit identity into a Lua double.
	if type( id ) ~= "string" then return nil end
	id = string.lower( id )
	id = string.gsub( id, "^0x", "" )
	id = string.gsub( id, "^0+", "" )
	if id == "" or #id > 16 or string.find( id, "[^0-9a-f]" ) then return nil end
	return id
end

-- Lobby APIs can expose a 64-bit XUID as decimal while GSC getxuid() uses
-- hexadecimal. Divide the string by 16 so no Lua double loses ID bits.
C.DecimalIdToHex = function ( id )
	if type( id ) ~= "string" or #id < 1 or #id > 20 or string.find( id, "[^0-9]" ) then return nil end
	id = string.gsub( id, "^0+", "" )
	if id == "" then return nil end
	local result = ""
	while id ~= "" do
		local quotient, carry = "", 0
		for i = 1, #id do
			local value = carry * 10 + tonumber( string.sub( id, i, i ) )
			local digit = math.floor( value / 16 )
			carry = value % 16
			if quotient ~= "" or digit ~= 0 then quotient = quotient .. digit end
		end
		result = string.sub( "0123456789abcdef", carry + 1, carry + 1 ) .. result
		if #result > 16 then return nil end
		id = quotient
	end
	return result
end

C.LiveIdCandidates = function ( id )
	if type( id ) ~= "string" then return {} end
	local candidates = {}
	local direct = C.NormalizeId( id )
	if direct then candidates[#candidates + 1] = direct end
	if string.find( id, "^[0-9]+$" ) then
		local decimal = C.DecimalIdToHex( id )
		if decimal and decimal ~= direct then candidates[#candidates + 1] = decimal end
	end
	return candidates
end

local function matchSavedId( rawId, expectedSet )
	local found
	for _, candidate in ipairs( C.LiveIdCandidates( rawId ) ) do
		if expectedSet[candidate] then
			if found and found ~= candidate then return nil, true end
			found = candidate
		end
	end
	return found, false
end

C.CoopValue = function ( value )
	if value == "" then return "-" end
	return value
end

C.CoopStatus = function ( controller )
	local map = C.CurrentMap( false )
	local prefix = "zmcp_coop_" .. map .. "_"
	local dvar = function ( name ) return C.DvarString( prefix .. name ) end
	local details = {}
	if not C.SupportedMaps[map] or dvar( "has" ) ~= "1" then
		return false, "No team checkpoint on this PC. Open Resume on the Save & Exit host.", details
	end
	local expected, expectedSet = {}, {}
	for id in string.gmatch( dvar( "ids" ), "[^/]+" ) do
		id = C.NormalizeId( id )
		if not id or expectedSet[id] then return false, "Invalid saved team metadata.", details end
		expectedSet[id] = true
		table.insert( expected, id )
	end
	if #expected < 2 or #expected > 4 then return false, "Invalid saved team size.", details end
	local host = C.NormalizeId( dvar( "host" ) )
	if not host or not expectedSet[host] then return false, "Invalid saved host.", details end
	local localId, localAmbiguous = matchSavedId( Engine.GetXUIDStringForController( controller ), expectedSet )
	local members = Engine.GetPlayersInLobby()
	if type( members ) ~= "table" then return false, "Lobby identities are unavailable.", details end
	local actual, count = {}, 0
	for _, member in pairs( members ) do
		local id, ambiguous = matchSavedId( member.xuid, expectedSet )
		if ambiguous or (id and actual[id]) then return false, "Lobby contains an ambiguous or duplicate ID.", details end
		if id then actual[id] = member.gamertag or id end
		count = count + 1
	end
	local matches = count == #expected and Engine.PartyGetPlayerCount() == #expected
	for _, id in ipairs( expected ) do
		local label = actual[id] or ("ID " .. id)
		table.insert( details, (actual[id] and "CONNECTED: " or "MISSING: ") .. label .. (id == host and " (HOST)" or "") )
		if not actual[id] then matches = false end
	end
	if localAmbiguous or localId ~= host or UIExpression.GameHost( controller ) ~= 1 or not CoD.isPartyHost() then
		return false, "The original host must host this lobby.", details
	end
	if not matches then return false, "Reconnect the exact saved team; remove extra players.", details end
	local settings = tostring( Engine.GetGametypeSetting( "zmDifficulty" ) ) .. "/" .. tostring( Engine.GetGametypeSetting( "magic" ) ) .. "/" .. tostring( Engine.GetGametypeSetting( "headshotsonly" ) )
	if dvar( "mode" ) ~= C.DvarString( "ui_gametype" ) or
		dvar( "group" ) ~= C.CoopValue( C.DvarString( "ui_zm_gamemodegroup" ) ) or
		dvar( "location" ) ~= C.CoopValue( C.DvarString( "ui_zm_mapstartlocation" ) ) or
		dvar( "mod" ) ~= C.CoopValue( C.DvarString( "fs_game" ) ) or dvar( "settings" ) ~= settings then
		return false, "Select the saved mode, location, mod and game settings.", details
	end
	if Engine.PartyHostIsReadyToStart() then return false, "A launch is already in progress.", details end
	return true, "Ready: " .. C.SupportedMaps[map] .. " - round " .. dvar( "round" ) .. " - " .. #expected .. " players", details
end

C.SafeCoopStatus = function ( controller )
	local ok, ready, message, details = pcall( C.CoopStatus, controller )
	if not ok then
		if Engine.SetDvar then Engine.SetDvar( "zmcp_coop_ui_error", tostring( ready ) ) end
		return false, "Cannot verify this lobby. Resume is locked.", {}
	end
	return ready, message, details
end

C.CoopResume = function ( menu, event )
	local controller = event.controller or menu.m_ownerController or 0
	local ready = C.SafeCoopStatus( controller )
	if not ready then return end
	Engine.Exec( controller, "set zmcp_autoload 0\nset zmcp_coop_autoload 1\nxpartygo\n" )
	menu:goBack()
end

LUI.createMenu.ZMCheckpointCoop = function ( controller )
	local menu = CoD.Menu.New( "ZMCheckpointCoop" )
	menu.m_ownerController = controller
	menu:addLargePopupBackground()
	menu:addTitle( "CO-OP RESUME" )
	menu:addBackButton()
	local status = LUI.UIText.new()
	status:setLeftRight( true, true, 0, 0 )
	status:setTopBottom( true, false, 90, 115 )
	status:setFont( CoD.fonts.Condensed )
	status:setAlignment( LUI.Alignment.Left )
	menu:addElement( status )
	local rows = {}
	for i = 1, 4 do
		rows[i] = LUI.UIText.new()
		rows[i]:setLeftRight( true, true, 0, 0 )
		rows[i]:setTopBottom( true, false, 130 + i * 32, 155 + i * 32 )
		rows[i]:setFont( CoD.fonts.Condensed )
		rows[i]:setAlignment( LUI.Alignment.Left )
		menu:addElement( rows[i] )
	end
	local list = CoD.ButtonList.new( { leftAnchor = true, rightAnchor = false, left = 0, right = 500, topAnchor = true, bottomAnchor = false, top = 325, bottom = 400 } )
	menu:addElement( list )
	local resume = list:addButton( "RESUME TEAM CHECKPOINT", "The saved round restarts with the original host and the exact same players." )
	resume:setActionEventName( "zmcp_coop_resume" )
	menu:registerEventHandler( "zmcp_coop_resume", C.CoopResume )
	local wasReady = false
	local refresh = function ()
		local ready, message, details = C.SafeCoopStatus( controller )
		status:setText( message )
		for i = 1, 4 do rows[i]:setText( details[i] or "" ) end
		if ready then resume:enable() else resume:disable() end
		if ready and not wasReady then resume:processEvent( { name = "gain_focus" } ) end
		wasReady = ready
	end
	menu:registerEventHandler( "zmcp_coop_refresh", refresh )
	menu:addElement( LUI.UITimer.new( 500, "zmcp_coop_refresh", false ) )
	refresh()
	list:processEvent( { name = "gain_focus" } )
	return menu
end

C.AddCoopLobbyButton = function ( menu, controller )
	if not menu or menu.zmcpCoopButton then return end
	local pane = menu.panelManager and menu.panelManager.panels and menu.panelManager.panels.buttonPane
	local list = pane and pane.body and pane.body.buttonList
	if not list then return end
	local button = list:addButton( "CO-OP RESUME", "Resume a host-stored checkpoint with its original host and exact team." )
	list:removeElement( button )
	list:addElementToTop( button )
	button:setActionEventName( "zmcp_open_coop" )
	menu.zmcpCoopButton = button
	menu:registerEventHandler( "zmcp_open_coop", function ( owner, event )
		owner:openPopup( "ZMCheckpointCoop", event.controller or controller )
	end )
end
