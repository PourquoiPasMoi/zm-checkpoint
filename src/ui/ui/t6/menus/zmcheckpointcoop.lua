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

-- Up to four co-op sessions per map live on the host PC. Session 1 uses the
-- original file names; sessions 2 to 4 add an _sN suffix (see GSC). Dvars always carry _sN.
C.CoopSessionPrefix = function ( map, slot )
	return "zmcp_coop_" .. map .. "_s" .. slot .. "_"
end

C.CoopOverridePrefix = function ( map, slot )
	return "zmcp_ovr_coop_" .. map .. "_s" .. slot .. "_"
end

local function splitList( value )
	local out = {}
	if value == "" or value == "-" then return out end
	for item in string.gmatch( value, "[^,]+" ) do out[#out + 1] = item end
	return out
end

C.CoopMeta = function ( map, slot )
	local prefix = C.CoopSessionPrefix( map, slot )
	local read = function ( key ) return C.DvarString( prefix .. key ) end
	local meta = { slot = slot, has = read( "has" ) == "1", members = {} }
	meta.round = tonumber( read( "round" ) ) or 0
	meta.host, meta.settings = read( "host" ), read( "settings" )
	meta.mode, meta.group, meta.location, meta.mod = read( "mode" ), read( "group" ), read( "location" ), read( "mod" )
	meta.difficulty, meta.magic, meta.headshots = string.match( meta.settings, "^(%d+)/(%d+)/(%d+)$" )
	meta.difficulty, meta.magic, meta.headshots = tonumber( meta.difficulty ), tonumber( meta.magic ), tonumber( meta.headshots )
	local ovr = C.CoopOverridePrefix( map, slot )
	local choice = function ( key )
		local value = tonumber( C.DvarString( ovr .. key ) )
		if value ~= 0 and value ~= 1 then return nil end
		return value
	end
	meta.unlimited, meta.optionsSet = choice( "perks" ), C.DvarString( ovr .. "set" ) == "1"
	if meta.optionsSet then meta.assist, meta.cheats = choice( "assist" ), choice( "cheats" ) end
	if not meta.has then return meta end
	local index = 0
	for id in string.gmatch( read( "ids" ), "[^/]+" ) do
		local mp = "m" .. index .. "_"
		meta.members[#meta.members + 1] = { id = C.NormalizeId( id ), score = tonumber( read( mp .. "pts" ) ) or 0,
			weapons = splitList( read( mp .. "w" ) ), perks = splitList( read( mp .. "p" ) ) }
		index = index + 1
	end
	return meta
end

C.ApplyCoopSettings = function ( controller, slot )
	local map = C.CurrentMap( false )
	local saved = C.DvarString( C.CoopSessionPrefix( map, slot or 1 ) .. "settings" )
	local difficulty, magic, headshots = string.match( saved, "^(%d+)/(%d+)/(%d+)$" )
	if not difficulty or not magic or not headshots then return false end
	difficulty, magic, headshots = tonumber( difficulty ), tonumber( magic ), tonumber( headshots )
	if difficulty > 2 or magic > 1 or headshots > 1 then return false end
	Engine.SetGametypeSetting( "zmDifficulty", difficulty )
	Engine.SetGametypeSetting( "magic", magic )
	Engine.SetGametypeSetting( "headshotsonly", headshots )
	return tostring( Engine.GetGametypeSetting( "zmDifficulty" ) ) .. "/" ..
		tostring( Engine.GetGametypeSetting( "magic" ) ) .. "/" ..
		tostring( Engine.GetGametypeSetting( "headshotsonly" ) ) == saved
end

-- Exact roster, original host and context gate for one session. Settings no
-- longer block: START applies them and the server revalidates everything.
C.CoopStatus = function ( controller, slot )
	slot = slot or 1
	local map = C.CurrentMap( false )
	local prefix = C.CoopSessionPrefix( map, slot )
	local dvar = function ( name ) return C.DvarString( prefix .. name ) end
	local details, people = {}, {}
	if not C.SupportedMaps[map] or dvar( "has" ) ~= "1" then
		return false, "No co-op session in this slot.", details, people
	end
	local expected, expectedSet = {}, {}
	for id in string.gmatch( dvar( "ids" ), "[^/]+" ) do
		id = C.NormalizeId( id )
		if not id or expectedSet[id] then return false, "Invalid saved team metadata.", details, people end
		expectedSet[id] = true
		table.insert( expected, id )
	end
	if #expected < 2 or #expected > 4 then return false, "Invalid saved team size.", details, people end
	local host = C.NormalizeId( dvar( "host" ) )
	if not host or not expectedSet[host] then return false, "Invalid saved host.", details, people end
	local localId, localAmbiguous = matchSavedId( Engine.GetXUIDStringForController( controller ), expectedSet )
	local members = Engine.GetPlayersInLobby()
	if type( members ) ~= "table" then return false, "Lobby identities are unavailable.", details, people end
	local actual, count = {}, 0
	for _, member in pairs( members ) do
		local id, ambiguous = matchSavedId( member.xuid, expectedSet )
		if ambiguous or (id and actual[id]) then return false, "Lobby contains an ambiguous or duplicate ID.", details, people end
		if id then actual[id] = member.gamertag or id end
		count = count + 1
	end
	local matches = count == #expected and Engine.PartyGetPlayerCount() == #expected
	for _, id in ipairs( expected ) do
		local label = actual[id] or ("ID " .. id)
		people[id] = actual[id]
		table.insert( details, (actual[id] and "CONNECTED: " or "MISSING: ") .. label .. (id == host and " (HOST)" or "") )
		if not actual[id] then matches = false end
	end
	if localAmbiguous or localId ~= host or UIExpression.GameHost( controller ) ~= 1 or not CoD.isPartyHost() then
		return false, "The original host must host this lobby.", details, people
	end
	if not matches then return false, "Reconnect the exact saved team; remove extra players.", details, people end
	local savedDifficulty, savedMagic, savedHeadshots = string.match( dvar( "settings" ), "^(%d+)/(%d+)/(%d+)$" )
	if not savedDifficulty or tonumber( savedDifficulty ) > 2 or tonumber( savedMagic ) > 1 or tonumber( savedHeadshots ) > 1 then
		return false, "Invalid saved settings.", details, people
	end
	if dvar( "mode" ) ~= C.DvarString( "ui_gametype" ) then
		return false, "Select the saved mode: " .. dvar( "mode" ) .. ".", details, people
	end
	if dvar( "group" ) ~= C.CoopValue( C.DvarString( "ui_zm_gamemodegroup" ) ) then
		return false, "Select the saved mode group: " .. dvar( "group" ) .. ".", details, people
	end
	if dvar( "location" ) ~= C.CoopValue( C.DvarString( "ui_zm_mapstartlocation" ) ) then
		return false, "Select the saved start location: " .. dvar( "location" ) .. ".", details, people
	end
	if dvar( "mod" ) ~= C.CoopValue( C.DvarString( "fs_game" ) ) then
		return false, "Load the saved mod: " .. dvar( "mod" ) .. ".", details, people
	end
	if Engine.PartyHostIsReadyToStart() then return false, "A launch is already in progress.", details, people end
	return true, "Ready: " .. C.SupportedMaps[map] .. " - round " .. dvar( "round" ) .. " - " .. #expected .. " players", details, people
end

C.SafeCoopStatus = function ( controller, slot )
	local ok, ready, message, details, people = pcall( C.CoopStatus, controller, slot )
	if not ok then
		if Engine.SetDvar then Engine.SetDvar( "zmcp_coop_ui_error", tostring( ready ) ) end
		return false, "Cannot verify this lobby. Resume is locked.", {}, {}
	end
	return ready, message, details, people
end

-- START: revalidate, apply the saved (and overridden) settings with read-back,
-- then launch through the stock lobby path. The server checks everything again.
C.CoopResume = function ( menu, event, slot )
	slot = slot or 1
	local controller = event.controller or menu.m_ownerController or 0
	local ready, message = C.SafeCoopStatus( controller, slot )
	if not ready then return false, message end
	local map = C.CurrentMap( false )
	if not C.ApplyCoopSettings( controller, slot ) then
		return false, "Could not apply the saved settings in this lobby."
	end
	local meta = C.CoopMeta( map, slot )
	if meta.optionsSet then
		if meta.assist == nil or meta.cheats == nil then return false, "Stored options are invalid." end
		Engine.SetDvar( "sv_allowAimAssist", meta.assist )
		Engine.SetDvar( "sv_cheats", meta.cheats )
		if tonumber( C.DvarString( "sv_allowAimAssist" ) ) ~= meta.assist or tonumber( C.DvarString( "sv_cheats" ) ) ~= meta.cheats then
			return false, "Could not apply the stored options."
		end
	end
	if meta.unlimited ~= nil then
		Engine.SetDvar( "zmcp_all_perks", meta.unlimited )
		Engine.Exec( controller, "seta zmcp_all_perks " .. meta.unlimited .. "\n" )
	end
	Engine.Exec( controller, "set zmcp_autoload 0\nset zmcp_coop_slot " .. slot .. "\nset zmcp_coop_autoload 1\nxpartygo\n" )
	menu:goBack()
	return true
end

-- The lobby cannot touch files: hide the session now and leave a tombstone that
-- GSC applies on the next load of this map (see zmcp_apply_coop_deletes).
C.DeleteCoopSession = function ( controller, map, slot )
	if C.SupportedMaps[map] == nil or slot < 1 or slot > 4 then return false end
	local prefix = C.CoopSessionPrefix( map, slot )
	local ovr = C.CoopOverridePrefix( map, slot )
	local values = {
		[ "zmcp_del_coop_" .. map .. "_s" .. slot ] = 1,
		[ prefix .. "has" ] = 0, [ prefix .. "round" ] = 0,
		[ ovr .. "set" ] = 0, [ ovr .. "perks" ] = -1
	}
	if slot == 1 then
		values[ "zmcp_coop_" .. map .. "_has" ] = 0
		values[ "zmcp_coop_" .. map .. "_round" ] = 0
	end
	for name, value in pairs( values ) do
		Engine.Exec( controller, "seta " .. name .. " " .. value .. "\n" )
		Engine.SetDvar( name, value )
	end
	return true
end

-- Per-session option overrides sit beside the save and never rewrite it. GSC
-- applies difficulty/magic/headshots to the in-memory checkpoint; the lobby
-- applies assist, cheats and unlimited perks at START.
C.CoopOptionKeys = { "difficulty", "magic", "headshots", "assist", "cheats" }

C.ApplyCoopOptions = function ( controller, map, slot, values )
	if C.SupportedMaps[map] == nil or slot < 1 or slot > 4 then return false end
	local meta = C.CoopMeta( map, slot )
	if not meta.has then return false end
	for _, key in ipairs( C.CoopOptionKeys ) do
		if values[key] ~= 0 and values[key] ~= 1 and not ( key == "difficulty" and values[key] == 2 ) then return false end
	end
	if values.perks ~= 0 and values.perks ~= 1 then return false end
	local ovr = C.CoopOverridePrefix( map, slot )
	local out = { [ ovr .. "set" ] = 1, [ ovr .. "perks" ] = values.perks }
	for _, key in ipairs( C.CoopOptionKeys ) do out[ ovr .. key ] = values[key] end
	local settings = values.difficulty .. "/" .. values.magic .. "/" .. values.headshots
	out[ C.CoopSessionPrefix( map, slot ) .. "settings" ] = settings
	if slot == 1 then out[ "zmcp_coop_" .. map .. "_settings" ] = settings end
	for name, value in pairs( out ) do
		Engine.Exec( controller, "seta " .. name .. " " .. value .. "\n" )
		Engine.SetDvar( name, value )
	end
	return true
end

local function wrapItems( items, maxChars, maxLines )
	local lines, current = {}, ""
	for _, item in ipairs( items ) do
		local candidate = current == "" and item or (current .. ", " .. item)
		if #candidate > maxChars and current ~= "" then
			lines[#lines + 1] = current
			current = item
		else
			current = candidate
		end
	end
	if current ~= "" then lines[#lines + 1] = current end
	if #lines > maxLines then
		local kept = {}
		for i = 1, maxLines do kept[i] = lines[i] end
		lines = kept
		lines[maxLines] = string.sub( lines[maxLines], 1, maxChars - 3 ) .. "..."
	end
	return lines
end

local function shortId( id )
	if not id then return "UNKNOWN" end
	return "ID ..." .. string.sub( id, -6 )
end

local function memberLabel( member, people )
	local name = people[member.id] or (member.id and C.DvarString( "zmcp_coop_name_" .. member.id ))
	if name == nil or name == "" then name = shortId( member.id ) end
	return string.upper( name )
end

local perkLabel = function ( name )
	local style = C.Ui.PerkStyle[name]
	return style and style[1] or string.upper( (string.gsub( name, "specialty_", "" )) )
end

-- Player list for one session. Returns a signature so unchanged data is not rebuilt.
local function describe( meta, people, status )
	local lines = { signature = {} }
	local compact = #meta.members > 2
	local maxLines = compact and 1 or 2
	for _, member in ipairs( meta.members ) do
		local connected = people[member.id] ~= nil
		local head = memberLabel( member, people ) .. (member.id == C.NormalizeId( meta.host ) and " (HOST)" or "") ..
			(connected and "" or "  - NOT CONNECTED") .. "   " .. member.score .. " PTS"
		lines[#lines + 1] = { text = head, orange = true }
		local weapons = {}
		for _, w in ipairs( member.weapons ) do weapons[#weapons + 1] = C.Ui.WeaponName( w ) end
		local perks = {}
		for _, p in ipairs( member.perks ) do perks[#perks + 1] = perkLabel( p ) end
		for i, text in ipairs( wrapItems( weapons, 46, maxLines ) ) do
			lines[#lines + 1] = { text = (i == 1 and "WEAPONS  " or "         ") .. text }
		end
		if #weapons == 0 then lines[#lines + 1] = { text = "WEAPONS  NONE" } end
		for i, text in ipairs( wrapItems( perks, 46, maxLines ) ) do
			lines[#lines + 1] = { text = (i == 1 and "PERKS  " or "       ") .. text }
		end
		if #perks == 0 then lines[#lines + 1] = { text = "PERKS  NONE" } end
	end
	for _, line in ipairs( lines ) do lines.signature[#lines.signature + 1] = line.text end
	lines.signature = table.concat( lines.signature, "|" )
	return lines
end

LUI.createMenu.ZMCheckpointCoop = function ( controller )
	local menu, status, list = C.Ui.PageBase( "ZMCheckpointCoop", "CO-OP RESUME",
		"Select a session, then use OPTIONS or START." )
	menu.m_ownerController = controller
	local map = C.CurrentMap( false )
	local selectedSlot, focusedSlot
	local rows, ready = {}, {}
	local deleteVisible = false
	local deletePrompt = CoD.ButtonPrompt.new( "alt1", "Delete", menu, "zmcp_delete_slot", false, nil, false, nil, "DEL" )
	local function setDeleteVisible( visible )
		if deleteVisible == visible then return end
		deleteVisible = visible
		menu.rightButtonPromptBar:removeAllChildren()
		if visible then menu:addRightButtonPrompt( deletePrompt ) end
	end

	-- Details panel (same look as SOLO RESUME's preview).
	local panel = LUI.UIElement.new()
	panel:setLeftRight( true, false, 585, 1050 )
	panel:setTopBottom( true, false, 145, 595 )
	menu:addElement( panel )
	local backdrop = LUI.UIImage.new()
	backdrop:setLeftRight( true, true, 0, 0 )
	backdrop:setTopBottom( true, true, 0, 0 )
	backdrop:setRGB( 0.04, 0.04, 0.04 )
	backdrop:setAlpha( 0.72 )
	panel:addElement( backdrop )
	local accent = LUI.UIImage.new()
	accent:setLeftRight( true, true, 0, 0 )
	accent:setTopBottom( true, false, 0, 3 )
	accent:setRGB( CoD.BOIIOrange.r, CoD.BOIIOrange.g, CoD.BOIIOrange.b )
	panel:addElement( accent )
	local settingsBox = LUI.UIElement.new()
	settingsBox:setLeftRight( true, false, 0, 565 )
	settingsBox:setTopBottom( true, false, 430, 560 )
	menu:addElement( settingsBox )
	local content, settingsContent, shown

	local function render( slot, force )
		local meta = slot and C.CoopMeta( map, slot )
		local _, _, _, people = C.SafeCoopStatus( controller, slot )
		local view = meta and meta.has and describe( meta, people or {} ) or nil
		local key = tostring( slot ) .. "#" .. (view and view.signature or "") .. "#" .. (meta and (meta.settings .. tostring( meta.unlimited ) .. tostring( meta.assist ) .. tostring( meta.cheats )) or "")
		if key == shown and not force then return end
		shown = key
		if content then content:close() end
		if settingsContent then settingsContent:close() end
		content = LUI.UIElement.new()
		content:setLeftRight( true, true, 0, 0 )
		content:setTopBottom( true, true, 0, 0 )
		panel:addElement( content )
		settingsContent = LUI.UIElement.new()
		settingsContent:setLeftRight( true, true, 0, 0 )
		settingsContent:setTopBottom( true, true, 0, 0 )
		settingsBox:addElement( settingsContent )
		if not meta or not meta.has then
			C.Ui.AddText( content, "NO SESSION", 18, 445, 16, 43, true )
			return
		end
		C.Ui.AddText( content, "SESSION " .. slot .. "  /  ROUND " .. meta.round .. "  /  " .. #meta.members .. " PLAYERS", 18, 445, 12, 38, true )
		local top = 44
		for _, line in ipairs( view ) do
			C.Ui.AddText( content, line.text, 18, 445, top, top + 22, line.orange )
			top = top + (line.orange and 26 or 22)
		end
		local enabled = function ( value ) return value == 1 and "ON" or "OFF" end
		C.Ui.AddText( settingsContent, "SAVED SETTINGS", 0, 545, 0, 27, true )
		C.Ui.AddText( settingsContent, "DIFFICULTY " .. (meta.difficulty == 0 and "EASY" or "ORIGINAL") ..
			"    MAGIC " .. enabled( meta.magic ) .. "    HEADSHOTS " .. enabled( meta.headshots ), 0, 555, 34, 60 )
		local extra = {}
		if meta.optionsSet then
			extra[#extra + 1] = "ASSIST " .. enabled( meta.assist )
			extra[#extra + 1] = "CHEATS " .. enabled( meta.cheats )
		end
		if meta.unlimited ~= nil then extra[#extra + 1] = "UNLIMITED PERKS " .. enabled( meta.unlimited ) end
		if #extra > 0 then C.Ui.AddText( settingsContent, table.concat( extra, "    " ), 0, 555, 66, 92 ) end
	end

	local start, options
	local function refresh()
		local anyReady = false
		for slot = 1, 4 do
			if rows[slot] then
				local ok = C.SafeCoopStatus( controller, slot )
				ready[slot] = ok
				-- Greyed while the exact saved host and team are not present.
				rows[slot]:setAlpha( ok and 1 or 0.55 )
			end
		end
		if selectedSlot and ready[selectedSlot] then start:enable() else start:disable() end
		if selectedSlot then options:enable() else options:disable() end
		local view = selectedSlot or focusedSlot
		if view then
			local _, message = C.SafeCoopStatus( controller, view )
			status:setText( (selectedSlot == view and "Session " .. view .. ": " or "") .. message )
		end
		render( view )
	end

	local function build()
		rows = {}
		local anySaved = false
		local focusIndex, savedCount
		savedCount = 0
		if selectedSlot and not C.CoopMeta( map, selectedSlot ).has then selectedSlot = nil end
		for slot = 1, 4 do
			local chosen = slot
			local meta = C.CoopMeta( map, chosen )
			local title = "SESSION " .. chosen .. (meta.has and (" - ROUND " .. meta.round .. " - " .. #meta.members .. " PLAYERS") or " - EMPTY")
			if selectedSlot == chosen then title = title .. " - SELECTED" end
			local button = list:addButton( title, meta.has and "Select this session, then use START or OPTIONS." or "Empty session." )
			if meta.has then
				anySaved = true
				savedCount = savedCount + 1
				rows[chosen] = button
				if selectedSlot == chosen then focusIndex = savedCount end
				local watcher = LUI.UIElement.new()
				button:addElement( watcher )
				watcher:registerEventHandler( "gain_focus", function ()
					focusedSlot = chosen
					setDeleteVisible( true )
					render( chosen )
					refresh()
				end )
				button:setActionEventName( "zmcp_select_slot_" .. chosen )
				menu:registerEventHandler( "zmcp_select_slot_" .. chosen, function ()
					if selectedSlot == chosen then return end
					selectedSlot = chosen
					menu:addElement( LUI.UITimer.new( 1, "zmcp_rebuild", true ) )
				end )
			else
				button:disable()
			end
		end
		options = list:addButton( "OPTIONS", "Change the stored options of the selected session." )
		start = list:addButton( "START", "Start the selected session with its exact team." )
		options:setActionEventName( "zmcp_slot_options" )
		start:setActionEventName( "zmcp_slot_start" )
		for _, button in ipairs( { options, start } ) do
			local watcher = LUI.UIElement.new()
			button:addElement( watcher )
			watcher:registerEventHandler( "gain_focus", function ()
				focusedSlot = nil
				setDeleteVisible( false )
			end )
		end
		if not anySaved then
			status:setText( "No co-op sessions on this PC. Sessions are stored on the host PC that used Save & Exit." )
			options:disable()
			start:disable()
			setDeleteVisible( false )
			render( nil, true )
			return
		end
		list:processEvent( { name = "gain_focus" } )
		if focusIndex and list.selectElementIndex then
			pcall( function () list:selectElementIndex( focusIndex ) end )
		end
		refresh()
	end
	local function rebuild()
		list:removeAllButtons()
		focusedSlot = nil
		shown = nil
		build()
	end
	build()
	menu:registerEventHandler( "zmcp_rebuild", rebuild )
	menu:registerEventHandler( "zmcp_coop_refresh", refresh )
	menu:addElement( LUI.UITimer.new( 500, "zmcp_coop_refresh", false ) )
	menu:registerEventHandler( "zmcp_slot_start", function ( owner, event )
		if not selectedSlot then return end
		local ok, reason = C.CoopResume( owner, event, selectedSlot )
		if not ok and reason then status:setText( reason ) end
	end )
	menu:registerEventHandler( "zmcp_slot_options", function ( owner, event )
		if not selectedSlot or not C.CoopMeta( map, selectedSlot ).has then return end
		C.OptionsTarget = { map = map, slot = selectedSlot, owner = owner }
		owner:openPopup( "ZMCheckpointCoopOptions", event.controller or controller )
	end )
	menu:registerEventHandler( "zmcp_options_applied", function ( owner, event )
		status:setText( "Session " .. event.slot .. " options stored. The save file was not changed." )
		rebuild()
	end )
	menu:registerEventHandler( "zmcp_delete_slot", function ( owner, event )
		if not focusedSlot or menu.zmcpDeleteOpen then return end
		local meta = C.CoopMeta( map, focusedSlot )
		if not meta.has then return end
		menu.zmcpDeleteOpen = true
		local popup = owner:openPopup( "ZMCheckpointDeleteConfirm", event.controller or controller )
		popup.zmcpResume = owner
		popup.zmcpSlot = focusedSlot
		popup.zmcpMessage:setText( "Co-op session " .. focusedSlot .. ", round " .. meta.round .. " will be deleted." )
	end )
	menu:registerEventHandler( "zmcp_delete_closed", function () menu.zmcpDeleteOpen = false end )
	menu:registerEventHandler( "zmcp_delete_confirmed", function ( owner, event )
		menu.zmcpDeleteOpen = false
		if C.DeleteCoopSession( controller, map, event.slot ) then
			status:setText( "Session " .. event.slot .. " deleted." )
		else
			status:setText( "That session could not be deleted." )
		end
		if selectedSlot == event.slot then selectedSlot = nil end
		rebuild()
	end )
	return menu
end

LUI.createMenu.ZMCheckpointCoopOptions = function ( controller )
	local target = C.OptionsTarget or {}
	local map, slot = target.map, target.slot
	local meta = C.CoopMeta( map or "", slot or 0 )
	local menu, status, list = C.Ui.PageBase( "ZMCheckpointCoopOptions",
		"SESSION " .. tostring( slot ) .. " OPTIONS",
		"Stored beside the save; the save file is not modified. Assist and cheats are not saved in co-op files.", 560 )
	local toggle = function ( key, name, hint, value )
		Engine.SetDvar( "zmcp_edit_coop_" .. key, value )
		local row = list:addDvarLeftRightSelector( controller, Engine.Localize( name ), "zmcp_edit_coop_" .. key,
			Engine.Localize( hint ), 220 )
		row:addChoice( controller, Engine.Localize( "MENU_DISABLED_CAPS" ), 0 )
		row:addChoice( controller, Engine.Localize( "MENU_ENABLED_CAPS" ), 1 )
	end
	Engine.SetDvar( "zmcp_edit_coop_difficulty", meta.difficulty or 1 )
	local difficulty = list:addDvarLeftRightSelector( controller, Engine.Localize( "DIFFICULTY" ),
		"zmcp_edit_coop_difficulty", Engine.Localize( "Zombie difficulty used when this session is resumed." ), 220 )
	difficulty:addChoice( controller, Engine.Localize( "EASY" ), 0 )
	difficulty:addChoice( controller, Engine.Localize( "ORIGINAL" ), 1 )
	toggle( "magic", "MAGIC", "Mystery box and other magic items.", meta.magic or 1 )
	toggle( "headshots", "HEADSHOTS ONLY", "Only headshots damage zombies.", meta.headshots or 0 )
	toggle( "assist", "TARGET ASSIST", "Aim assist when this session starts.", meta.assist or tonumber( C.DvarString( "sv_allowAimAssist" ) ) or 1 )
	toggle( "cheats", "CHEATS", "Enable cheats when this session starts.", meta.cheats or tonumber( C.DvarString( "sv_cheats" ) ) or 0 )
	toggle( "perks", "UNLIMITED PERKS", "Allow every perk at once when this session starts.", meta.unlimited or 0 )
	local apply = list:addButton( "APPLY CHANGES", "Store these options for this session." )
	local cancel = list:addButton( "CANCEL", "Leave this session's options as they are." )
	apply:setActionEventName( "zmcp_options_apply" )
	cancel:setActionEventName( "zmcp_options_cancel" )
	menu:registerEventHandler( "zmcp_options_cancel", function ( owner, event ) owner:goBack( event.controller or controller ) end )
	menu:registerEventHandler( "zmcp_options_apply", function ( owner, event )
		local read = function ( key ) return tonumber( C.DvarString( "zmcp_edit_coop_" .. key ) ) end
		local values = { perks = read( "perks" ) }
		for _, key in ipairs( C.CoopOptionKeys ) do values[key] = read( key ) end
		if not C.ApplyCoopOptions( controller, map, slot, values ) then
			status:setText( "Those options could not be stored." )
			return
		end
		owner:goBack( event.controller or controller )
		if target.owner then target.owner:processEvent( { name = "zmcp_options_applied", slot = slot, controller = controller } ) end
	end )
	list:processEvent( { name = "gain_focus" } )
	return menu
end

C.AddCoopLobbyButton = function ( menu, controller )
	if not menu or menu.zmcpCoopButton then return end
	local pane = menu.panelManager and menu.panelManager.panels and menu.panelManager.panels.buttonPane
	local list = pane and pane.body and pane.body.buttonList
	if not list then return end
	local button = list:addButton( "CO-OP RESUME", "Resume a host-stored co-op session with its original host and exact team." )
	list:removeElement( button )
	list:addElementToTop( button )
	button:setActionEventName( "zmcp_open_coop" )
	menu.zmcpCoopButton = button
	menu:registerEventHandler( "zmcp_open_coop", function ( owner, event )
		owner:openPopup( "ZMCheckpointCoop", event.controller or controller )
	end )
end
