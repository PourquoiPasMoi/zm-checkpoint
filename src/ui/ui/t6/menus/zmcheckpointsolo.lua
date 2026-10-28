-- Separate solo save and resume pages. Slot 1 uses the legacy checkpoint.
local C = CoD.ZMCheckpointMenu

C.SoloSlotMeta = function ( map, slot )
	local suffix = slot == 1 and "" or ("_slot" .. slot)
	local prefix = "zmcp_solo_" .. map .. "_slot" .. slot .. "_"
	local read = function ( key ) return C.DvarString( prefix .. key ) end
	local flag = function ( key )
		local value = tonumber( read( key ) )
		if value ~= 0 and value ~= 1 then return nil end
		return value
	end
	local preview = read( "preview" ) == "1"
	local collect = function ( kind, count, maximum )
		local values = {}
		if not preview then return values end
		for i = 0, math.min( tonumber( read( count ) ) or 0, maximum ) - 1 do
			local value = read( kind .. i )
			if value ~= "" then values[#values + 1] = value end
		end
		return values
	end
	return {
		has = C.DvarString( "zmcp_has_" .. map .. suffix ) == "1",
		round = tonumber( C.DvarString( "zmcp_round_" .. map .. suffix ) ) or 0,
		settings = read( "settings" ) == "1",
		difficulty = flag( "difficulty" ),
		magic = flag( "magic" ),
		headshots = flag( "headshots" ),
		assist = flag( "assist" ),
		cheats = flag( "cheats" ),
		mode = read( "mode" ),
		group = read( "group" ),
		location = read( "location" ),
		preview = preview,
		score = tonumber( read( "score" ) ) or 0,
		weapons = collect( "weapon", "weapons", 4 ),
		perks = collect( "perk", "perks", 12 )
	}
end

local function slotHint( meta )
	if not meta.has then return "Empty slot." end
	if not meta.settings then return "Older checkpoint: current lobby settings will be used." end
	return "Select to view this checkpoint's equipment and settings."
end

local perkStyle = {
	specialty_armorvest = { "JUGGERNOG", "JG", 0.60, 0.13, 0.13 },
	specialty_deadshot = { "DEADSHOT", "DS", 0.36, 0.36, 0.36 },
	specialty_fastreload = { "SPEED COLA", "SC", 0.18, 0.48, 0.23 },
	specialty_longersprint = { "STAMIN-UP", "SU", 0.65, 0.44, 0.12 },
	specialty_quickrevive = { "QUICK REVIVE", "QR", 0.14, 0.40, 0.62 },
	specialty_rof = { "DOUBLE TAP", "DT", 0.63, 0.33, 0.12 },
	specialty_additionalprimaryweapon = { "MULE KICK", "MK", 0.32, 0.40, 0.15 },
	specialty_finalstand = { "TOMBSTONE", "TS", 0.38, 0.36, 0.50 },
	specialty_grenadepulldeath = { "CHERRY", "EC", 0.48, 0.16, 0.48 },
	specialty_flakjacket = { "PHD FLOPPER", "PH", 0.38, 0.19, 0.55 },
	specialty_chugabud = { "WHO'S WHO", "WW", 0.20, 0.39, 0.56 }
}

local function addText( parent, value, left, right, top, bottom, orange )
	local label = LUI.UIText.new()
	label:setLeftRight( true, false, left, right )
	label:setTopBottom( true, false, top, bottom )
	label:setFont( CoD.fonts.Condensed )
	label:setAlignment( LUI.Alignment.Left )
	if orange then label:setRGB( CoD.BOIIOrange.r, CoD.BOIIOrange.g, CoD.BOIIOrange.b ) end
	label:setText( value )
	parent:addElement( label )
	return label
end

local function addBadge( parent, letters, left, top, width, height, red, green, blue )
	local background = LUI.UIImage.new()
	background:setLeftRight( true, false, left, left + width )
	background:setTopBottom( true, false, top, top + height )
	background:setRGB( red, green, blue )
	background:setAlpha( 0.85 )
	parent:addElement( background )
	local mark = addText( parent, letters, left, left + width, top + 3, top + height - 3 )
	mark:setAlignment( LUI.Alignment.Center )
end

local function weaponName( name )
	local clean = string.gsub( name, "_zm.*$", "" )
	clean = string.gsub( clean, "_", " " )
	return string.upper( clean )
end

local function addPreview( menu, list )
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
	local content
	local function show( slot, meta )
		if content then content:close() end
		content = LUI.UIElement.new()
		content:setLeftRight( true, true, 0, 0 )
		content:setTopBottom( true, true, 0, 0 )
		panel:addElement( content )
		addText( content, "SLOT " .. slot .. "  /  ROUND " .. (meta.has and meta.round or "-"), 18, 445, 16, 43, true )
		if not meta.has then
			addText( content, "EMPTY SLOT", 18, 445, 64, 91 )
			return
		end
		if not meta.preview then
			addText( content, "Run details will appear after this save is", 18, 445, 67, 92 )
			addText( content, "loaded once with the new version.", 18, 445, 95, 120 )
			return
		end
		addText( content, "POINTS", 18, 180, 61, 86, true )
		addText( content, tostring( meta.score ), 180, 445, 58, 88 )
		addText( content, "WEAPONS", 18, 445, 101, 126, true )
		if #meta.weapons == 0 then addText( content, "NONE", 18, 445, 137, 162 ) end
		for i, name in ipairs( meta.weapons ) do
			local top = 132 + (i - 1) * 43
			local label = weaponName( name )
			addBadge( content, string.sub( label, 1, 3 ), 18, top, 76, 34,
				CoD.BOIIOrange.r * 0.65, CoD.BOIIOrange.g * 0.65, CoD.BOIIOrange.b * 0.65 )
			addText( content, label, 107, 445, top + 5, top + 31 )
		end
		addText( content, "PERKS", 18, 445, 298, 325, true )
		if #meta.perks == 0 then addText( content, "NONE", 18, 445, 333, 359 ) end
		for i, name in ipairs( meta.perks ) do
			local col = (i - 1) % 3
			local row = math.floor( (i - 1) / 3 )
			local left = 18 + col * 145
			local top = 329 + row * 29
			local style = perkStyle[name]
			local label = style and style[1] or string.upper( string.gsub( name, "specialty_", "" ) )
			addBadge( content, style and style[2] or "?", left, top, 25, 24,
				style and style[3] or 0.35, style and style[4] or 0.35, style and style[5] or 0.35 )
			addText( content, label, left + 29, left + 141, top + 2, top + 25 )
		end
	end
	return show
end

local function pageBase( name, title, message )
	local menu = CoD.Menu.New( name )
	menu:addLargePopupBackground()
	menu:addTitle( title )
	menu:addBackButton()
	local status = LUI.UIText.new()
	status:setLeftRight( true, false, 0, 750 )
	status:setTopBottom( true, false, 95, 125 )
	status:setFont( CoD.fonts.Condensed )
	status:setAlignment( LUI.Alignment.Left )
	status:setText( message )
	menu:addElement( status )
	local list = CoD.ButtonList.new( { leftAnchor = true, rightAnchor = false,
		left = 0, right = 600, topAnchor = true, bottomAnchor = false,
		top = 170, bottom = 410 } )
	menu:addElement( list )
	return menu, status, list
end

local function attachSlotDetails( menu, list )
	local showPreview = addPreview( menu, list )
	local settings = LUI.UIElement.new()
	settings:setLeftRight( true, false, 0, 565 )
	settings:setTopBottom( true, false, 430, 560 )
	menu:addElement( settings )
	local content
	local function show( slot, meta )
		showPreview( slot, meta )
		if content then content:close() end
		content = LUI.UIElement.new()
		content:setLeftRight( true, true, 0, 0 )
		content:setTopBottom( true, true, 0, 0 )
		settings:addElement( content )
		if not meta.has then return end
		addText( content, "SAVED SETTINGS", 0, 545, 0, 27, true )
		if not meta.settings then
			addText( content, "Older save: current lobby settings apply.", 0, 545, 34, 62 )
			return
		end
		local enabled = function ( value ) return value == 1 and "ON" or "OFF" end
		addText( content, "DIFFICULTY " .. (meta.difficulty == 0 and "EASY" or "ORIGINAL") ..
			"    MAGIC " .. enabled( meta.magic ) .. "    HEADSHOTS " .. enabled( meta.headshots ), 0, 555, 34, 60 )
		addText( content, "ASSIST " .. enabled( meta.assist ) .. "    CHEATS " .. enabled( meta.cheats ), 0, 555, 66, 92 )
	end
	return function ( button, slot, meta )
		local watcher = LUI.UIElement.new()
		button:addElement( watcher )
		watcher:registerEventHandler( "gain_focus", function () show( slot, meta ) end )
	end
end

LUI.createMenu.ZMCheckpointSoloSave = function ( controller )
	local menu, status, list = pageBase( "ZMCheckpointSoloSave", "SAVE SOLO CHECKPOINT",
		"Choose a slot. Select an occupied slot twice to replace it." )
	local map = C.CurrentMap( true )
	local pending = 0
	local watch = attachSlotDetails( menu, list )
	for slot = 1, 4 do
		local chosenSlot = slot
		local meta = C.SoloSlotMeta( map, chosenSlot )
		local title = "SLOT " .. chosenSlot .. (meta.has and (" - ROUND " .. meta.round) or " - EMPTY")
		local button = list:addButton( title, slotHint( meta ) )
		watch( button, chosenSlot, meta )
		button:setActionEventName( "zmcp_save_slot_" .. chosenSlot )
		menu:registerEventHandler( "zmcp_save_slot_" .. chosenSlot, function ()
			if meta.has and pending ~= chosenSlot then
				pending = chosenSlot
				status:setText( "Slot " .. chosenSlot .. " has a save. Select it again to replace it." )
				return
			end
			C.CommitSaveAndExit( menu, controller, chosenSlot )
		end )
	end
	list:processEvent( { name = "gain_focus" } )
	return menu
end

LUI.createMenu.ZMCheckpointSoloResume = function ( controller )
	local menu, status, list = pageBase( "ZMCheckpointSoloResume", "SOLO RESUME",
		"Choose a checkpoint for the selected map." )
	local map = C.CurrentMap( false )
	local watch = attachSlotDetails( menu, list )
	for slot = 1, 4 do
		local chosenSlot = slot
		local meta = C.SoloSlotMeta( map, chosenSlot )
		local title = "SLOT " .. chosenSlot .. (meta.has and (" - ROUND " .. meta.round) or " - EMPTY")
		local button = list:addButton( title, slotHint( meta ) )
		watch( button, chosenSlot, meta )
		if meta.has then
			button:setActionEventName( "zmcp_resume_slot_" .. chosenSlot )
			menu:registerEventHandler( "zmcp_resume_slot_" .. chosenSlot, function ( owner, event )
				local ok, reason = C.Resume( owner, event, chosenSlot )
				if not ok then status:setText( reason ) end
			end )
		else
			button:disable()
		end
	end
	list:processEvent( { name = "gain_focus" } )
	return menu
end
