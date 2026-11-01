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
	local perksChoice = tonumber( C.DvarString( "zmcp_ovr_" .. map .. "_slot" .. slot .. "_perks" ) )
	if perksChoice ~= 0 and perksChoice ~= 1 then perksChoice = nil end
	-- Per-save choices made on the OPTIONS page (nil when the save has none).
	local override = function ( key, maximum )
		local value = tonumber( C.DvarString( "zmcp_ovr_" .. map .. "_slot" .. slot .. "_" .. key ) )
		if value == nil or value ~= math.floor( value ) or value < 0 or value > maximum then return nil end
		return value
	end
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
		unlimited = perksChoice,
		healthcap = override( "healthcap", 255 ),
		autosave = override( "autosave", C.SoloSlotCount ),
		score = tonumber( read( "score" ) ) or 0,
		weapons = collect( "weapon", "weapons", 4 ),
		perks = collect( "perk", "perks", 12 )
	}
end

local function slotHint( meta )
	if not meta.has then return "Empty slot." end
	if not meta.settings then return "Older checkpoint: current lobby settings will be used." end
	return "Select this checkpoint, then use START or OPTIONS."
end

local perkStyle = {
	specialty_armorvest = { "JUGGERNOG", "zmcp_perk_juggernog" },
	specialty_deadshot = { "DEADSHOT", "zmcp_perk_deadshot" },
	specialty_fastreload = { "SPEED COLA", "zmcp_perk_speed_cola" },
	specialty_longersprint = { "STAMIN-UP", "zmcp_perk_stamin_up" },
	specialty_movefaster = { "STAMIN-UP", "zmcp_perk_stamin_up" },
	specialty_quickrevive = { "QUICK REVIVE", "zmcp_perk_quick_revive" },
	specialty_rof = { "DOUBLE TAP", "zmcp_perk_double_tap" },
	specialty_additionalprimaryweapon = { "MULE KICK", "zmcp_perk_mule_kick" },
	specialty_scavenger = { "TOMBSTONE", "zmcp_perk_tombstone" },
	specialty_finalstand = { "WHO'S WHO", "zmcp_perk_whos_who" },
	specialty_grenadepulldeath = { "ELECTRIC CHERRY", "zmcp_perk_electric_cherry" },
	specialty_flakjacket = { "PHD FLOPPER", "zmcp_perk_phd_flopper" },
	specialty_chugabud = { "WHO'S WHO", "zmcp_perk_whos_who" },
	specialty_nomotionsensor = { "VULTURE AID", "zmcp_perk_vulture_aid" }
}

-- These weapon materials are already loaded by the stock Zombies front-end.
local weaponMaterials = {
	["1911"] = "menu_mp_weapons_1911_big", m1911 = "menu_mp_weapons_1911_big",
	["870mcs"] = "menu_mp_weapons_870mcs_big", ak74u = "menu_mp_weapons_ak74u_big",
	ballistic_80 = "menu_mp_weapons_ballistic_80_big", baretta = "menu_mp_weapons_baretta_big",
	dsr1 = "menu_mp_weapons_dsr1_big", fal = "menu_mp_weapons_fal_big",
	five_seven = "menu_mp_weapons_five_seven_big", fiveseven = "menu_mp_weapons_five_seven_big",
	galil = "menu_mp_weapons_galil_big", hamr = "menu_mp_weapons_hamr_big",
	judge = "menu_mp_weapons_judge_big", kard = "menu_mp_weapons_kard_big",
	m14 = "menu_mp_weapons_m14_big", m16 = "menu_mp_weapons_m16_big",
	m32gl = "menu_mp_weapons_m32gl_big", m82a = "menu_mp_weapons_m82a_big",
	mp5 = "menu_mp_weapons_mp5_big", python = "menu_mp_weapons_python_big",
	qcw = "menu_mp_weapons_qcw_big", rottweil72 = "menu_mp_weapons_rottweil72_big",
	rpd = "menu_mp_weapons_rpd_big", rpg = "menu_mp_weapons_rpg_big",
	saiga12 = "menu_mp_weapons_saiga12_big", saritch = "menu_mp_weapons_saritch_big",
	srm = "menu_mp_weapons_srm_big", srm1216 = "menu_mp_weapons_srm_big",
	tar21 = "menu_mp_weapons_tar21_big", type95 = "menu_mp_weapons_type95_big",
	xm8 = "menu_mp_weapons_xm8_big", ray_gun = "menu_zm_weapons_raygun_big",
	raygun = "menu_zm_weapons_raygun_big", jetgun = "menu_zm_weapons_jetgun_big",
	zombie_shield = "menu_zm_weapons_shield_big",
	-- The game's own weapon names differ from the front-end material names.
	fnfal = "menu_mp_weapons_fal_big", mp5k = "menu_mp_weapons_mp5_big",
	beretta93r = "menu_mp_weapons_baretta_big", dsr50 = "menu_mp_weapons_dsr1_big",
	barretm82 = "menu_mp_weapons_m82a_big", usrpg = "menu_mp_weapons_rpg_big",
	m32 = "menu_mp_weapons_m32gl_big", qcw05 = "menu_mp_weapons_qcw_big",
	fivesevendw = "menu_mp_weapons_five_seven_big", m16_gl = "menu_mp_weapons_m16_big",
	ak74u_extclip = "menu_mp_weapons_ak74u_big", beretta93r_extclip = "menu_mp_weapons_baretta_big"
}

-- Base name of a saved weapon: drops attachments, upgrade suffixes and "_zm".
local function weaponBase( name )
	local base = string.gsub( name, "%+.*$", "" )
	base = string.gsub( base, "_zm.*$", "" )
	base = string.gsub( base, "_upgraded.*$", "" )
	return base
end

local function weaponMaterial( name )
	return weaponMaterials[weaponBase( name )]
end

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

local function addImage( parent, material, left, top, width, height )
	local icon = LUI.UIImage.new()
	icon:setLeftRight( true, false, left, left + width )
	icon:setTopBottom( true, false, top, top + height )
	icon:setImage( RegisterMaterial( material ) )
	parent:addElement( icon )
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
			local material = weaponMaterial( name )
			if material then addImage( content, material, 18, top - 2, 76, 38 ) end
			addText( content, label, material and 107 or 18, 445, top + 5, top + 31 )
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
			if style then addImage( content, style[2], left, top, 25, 25 ) end
			addText( content, label, left + (style and 29 or 0), left + 141, top + 2, top + 25 )
		end
	end
	return show
end

local function pageBase( name, title, message, listBottom, noList )
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
	if noList then return menu, status end
	local list = CoD.ButtonList.new( { leftAnchor = true, rightAnchor = false,
		left = 0, right = 600, topAnchor = true, bottomAnchor = false,
		top = 170, bottom = listBottom or 410 } )
	menu:addElement( list )
	return menu, status, list
end

-- The solo slots are shown as a grid of two columns: odd slots on the left, even
-- slots on the right (SLOT 1 SLOT 2 / SLOT 3 SLOT 4 / ...). Each column is its
-- own ButtonList; left and right move between the columns through the buttons'
-- navigation links, and both columns share a single hint line.
local GRID_TOP, GRID_COLUMN_WIDTH, GRID_RIGHT_LEFT = 170, 295, 305

local function gridPitch()
	return CoD.CoD9Button.Height + ( CoD.ButtonList.ButtonSpacing or 2 )
end

local function gridRows()
	return math.ceil( C.SoloSlotCount / 2 )
end

-- The first row below the grid, where the page's own buttons start.
local function gridBottom()
	return GRID_TOP + gridRows() * gridPitch()
end

local function newSlotGrid( menu, hintElement )
	local bottom = gridBottom()
	local function column( left, hint )
		local list = CoD.ButtonList.new( { leftAnchor = true, rightAnchor = false,
			left = left, right = left + GRID_COLUMN_WIDTH, topAnchor = true, bottomAnchor = false,
			top = GRID_TOP, bottom = bottom }, nil, nil, hint )
		menu:addElement( list )
		return list
	end
	local grid = { buttons = {} }
	grid.left = column( 0, hintElement )
	grid.right = column( GRID_RIGHT_LEFT, hintElement or grid.left.hintText )
	return grid
end

local function slotColumn( grid, slot )
	return slot % 2 == 1 and grid.left or grid.right
end

local function addGridButton( grid, slot, title, hint )
	local button = slotColumn( grid, slot ):addButton( title, hint )
	grid.buttons[slot] = button
	return button
end

-- Buttons are removed one by one. The stock removeAllButtons would re-add the
-- list's hint element to each list it clears, and the columns share one hint
-- element, so it would end up inside the wrong lists and break the layout.
local function clearGrid( grid )
	for slot, button in pairs( grid.buttons ) do
		slotColumn( grid, slot ):removeElement( button )
	end
	grid.buttons = {}
end

-- Left/right between a slot and its row partner (1 <-> 2, 3 <-> 4, ...). A
-- disabled (empty) partner is not focusable, so the move is simply ignored.
local function linkGrid( grid )
	for slot = 1, C.SoloSlotCount do
		local button = grid.buttons[slot]
		local partner = grid.buttons[slot % 2 == 1 and slot + 1 or slot - 1]
		if button and partner and button.navigation then
			button.navigation[slot % 2 == 1 and "right" or "left"] = partner
		end
	end
end

-- Focus one slot: its column takes focus and selects the slot among that
-- column's focusable (saved) buttons.
local function focusGridSlot( grid, slot, isFocusable )
	local list = slotColumn( grid, slot )
	local index = 0
	for candidate = slot % 2 == 1 and 1 or 2, slot, 2 do
		if isFocusable( candidate ) then index = index + 1 end
	end
	list:processEvent( { name = "gain_focus" } )
	if index > 0 and list.selectElementIndex then
		pcall( function () list:selectElementIndex( index ) end )
	end
end

local function attachSlotDetails( menu, list, onFocus )
	local showPreview = addPreview( menu, list )
	local settings = LUI.UIElement.new()
	settings:setLeftRight( true, false, 0, 565 )
	settings:setTopBottom( true, false, 430, 560 )
	menu:addElement( settings )
	local content
	local function runChoices( meta )
		local parts = {}
		if meta.healthcap ~= nil then
			parts[#parts + 1] = "ZOMBIE HEALTH CAP " .. ( meta.healthcap == 0 and "OFF" or ( "ROUND " .. meta.healthcap ) )
		end
		if meta.autosave ~= nil then
			parts[#parts + 1] = "AUTOSAVE " .. ( meta.autosave == 0 and "OFF" or ( "SLOT " .. meta.autosave ) )
		end
		return table.concat( parts, "    " )
	end
	local function show( slot, meta )
		showPreview( slot, meta )
		if content then content:close() end
		content = LUI.UIElement.new()
		content:setLeftRight( true, true, 0, 0 )
		content:setTopBottom( true, true, 0, 0 )
		settings:addElement( content )
		if not meta.has then return end
		addText( content, "SAVED SETTINGS", 0, 545, 0, 27, true )
		local enabled = function ( value ) return value == 1 and "ON" or "OFF" end
		if not meta.settings then
			addText( content, "Older save: current lobby settings apply.", 0, 545, 34, 62 )
			if meta.unlimited ~= nil then
				addText( content, "UNLIMITED PERKS " .. enabled( meta.unlimited ), 0, 555, 66, 92 )
			end
			if runChoices( meta ) ~= "" then addText( content, runChoices( meta ), 0, 555, 98, 124 ) end
			return
		end
		if meta.unlimited ~= nil then
			addText( content, "UNLIMITED PERKS " .. enabled( meta.unlimited ), 0, 555, 98, 124 )
		end
		addText( content, "DIFFICULTY " .. (meta.difficulty == 0 and "EASY" or "ORIGINAL") ..
			"    MAGIC " .. enabled( meta.magic ) .. "    HEADSHOTS " .. enabled( meta.headshots ), 0, 555, 34, 60 )
		addText( content, "ASSIST " .. enabled( meta.assist ) .. "    CHEATS " .. enabled( meta.cheats ), 0, 555, 66, 92 )
		if runChoices( meta ) ~= "" then addText( content, runChoices( meta ), 0, 555, 130, 156 ) end
	end
	return function ( button, slot, meta )
		local watcher = LUI.UIElement.new()
		button:addElement( watcher )
		watcher:registerEventHandler( "gain_focus", function ()
			show( slot, meta )
			if onFocus then onFocus( slot, meta ) end
		end )
	end, show
end

LUI.createMenu.ZMCheckpointSoloSave = function ( controller )
	local menu, status = pageBase( "ZMCheckpointSoloSave", "SAVE SOLO CHECKPOINT",
		"Choose a slot. Select an occupied slot twice to replace it.", nil, true )
	local grid = newSlotGrid( menu )
	local map = C.CurrentMap( true )
	local pending = 0
	local watch = attachSlotDetails( menu, grid.left )
	for slot = 1, C.SoloSlotCount do
		local chosenSlot = slot
		local meta = C.SoloSlotMeta( map, chosenSlot )
		local title = "SLOT " .. chosenSlot .. (meta.has and (" - ROUND " .. meta.round) or " - EMPTY")
		local button = addGridButton( grid, chosenSlot, title, slotHint( meta ) )
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
	linkGrid( grid )
	focusGridSlot( grid, 1, function () return true end )
	return menu
end

-- Deleting works from the front-end, where no GSC is running, so it hides the
-- slot immediately through its archived dvars and leaves a tombstone dvar. The
-- next load of that map overwrites the old file (see zmcp_apply_solo_deletes).
C.DeleteSoloSlot = function ( controller, map, slot )
	if C.SupportedMaps[map] == nil or slot < 1 or slot > C.SoloSlotCount then return false end
	local suffix = slot == 1 and "" or ("_slot" .. slot)
	local prefix = "zmcp_solo_" .. map .. "_slot" .. slot .. "_"
	local values = {
		[ "zmcp_del_" .. map .. "_slot" .. slot ] = 1,
		[ "zmcp_has_" .. map .. suffix ] = 0,
		[ "zmcp_round_" .. map .. suffix ] = 0,
		[ prefix .. "preview" ] = 0,
		[ prefix .. "settings" ] = 0,
		[ "zmcp_ovr_" .. map .. "_slot" .. slot .. "_set" ] = 0,
		[ "zmcp_ovr_" .. map .. "_slot" .. slot .. "_perks" ] = -1,
		[ "zmcp_ovr_" .. map .. "_slot" .. slot .. "_healthcap" ] = -1,
		[ "zmcp_ovr_" .. map .. "_slot" .. slot .. "_autosave" ] = -1
	}
	for name, value in pairs( values ) do
		-- seta keeps the value across restarts; SetDvar applies it to this frame.
		Engine.Exec( controller, "seta " .. name .. " " .. value .. "\n" )
		Engine.SetDvar( name, value )
	end
	return true
end

LUI.createMenu.ZMCheckpointSoloResume = function ( controller )
	local menu, status = pageBase( "ZMCheckpointSoloResume", "SOLO RESUME",
		"Select a checkpoint, then use OPTIONS or START.", nil, true )
	-- OPTIONS and START sit below the slot grid and own the shared hint line.
	local actions = CoD.ButtonList.new( { leftAnchor = true, rightAnchor = false,
		left = 0, right = 600, topAnchor = true, bottomAnchor = false,
		top = gridBottom(), bottom = gridBottom() + 3 * gridPitch() } )
	menu:addElement( actions )
	local grid = newSlotGrid( menu, actions.hintText )
	local map = C.CurrentMap( false )
	local focusedSlot
	local selectedSlot -- chosen with Enter/click; OPTIONS and START act on this slot
	local deleteVisible = false
	local deletePrompt = CoD.ButtonPrompt.new( "alt1", "Delete", menu, "zmcp_delete_slot",
		false, nil, false, nil, "DEL" )
	local function setDeleteVisible( visible )
		if deleteVisible == visible then return end
		deleteVisible = visible
		menu.rightButtonPromptBar:removeAllChildren()
		if visible then menu:addRightButtonPrompt( deletePrompt ) end
	end
	local watch, showDetails = attachSlotDetails( menu, actions, function ( slot, meta )
		focusedSlot = meta.has and slot or nil
		setDeleteVisible( meta.has )
	end )
	-- DEL deletes the highlighted slot, so hide it while a non-slot row is focused.
	local function hideDeleteOnFocus( button )
		local watcher = LUI.UIElement.new()
		button:addElement( watcher )
		watcher:registerEventHandler( "gain_focus", function ()
			focusedSlot = nil
			setDeleteVisible( false )
		end )
	end
	local actionButtons = {}
	local function build()
		local anySaved = false
		local firstSaved
		local saved = {}
		if selectedSlot and not C.SoloSlotMeta( map, selectedSlot ).has then selectedSlot = nil end
		for slot = 1, C.SoloSlotCount do
			local chosenSlot = slot
			local meta = C.SoloSlotMeta( map, chosenSlot )
			local title = "SLOT " .. chosenSlot .. (meta.has and (" - ROUND " .. meta.round) or " - EMPTY")
			if selectedSlot == chosenSlot then title = "> " .. title end
			local button = addGridButton( grid, chosenSlot, title, slotHint( meta ) )
			watch( button, chosenSlot, meta )
			if meta.has then
				anySaved = true
				saved[chosenSlot] = true
				firstSaved = firstSaved or chosenSlot
				button:setActionEventName( "zmcp_select_slot_" .. chosenSlot )
				menu:registerEventHandler( "zmcp_select_slot_" .. chosenSlot, function ( owner )
					if selectedSlot == chosenSlot then return end
					selectedSlot = chosenSlot
					status:setText( "Slot " .. chosenSlot .. " selected. Use START to resume or OPTIONS to change it." )
					-- Rebuild after this click has finished dispatching.
					menu:addElement( LUI.UITimer.new( 1, "zmcp_rebuild", true ) )
				end )
			else
				button:disable()
			end
		end
		local options = actions:addButton( "OPTIONS", "Change the saved settings of the selected checkpoint." )
		local start = actions:addButton( "START", "Start the selected checkpoint." )
		actionButtons = { options, start }
		options:setActionEventName( "zmcp_slot_options" )
		start:setActionEventName( "zmcp_slot_start" )
		hideDeleteOnFocus( options )
		hideDeleteOnFocus( start )
		if not selectedSlot then
			options:disable()
			start:disable()
		end
		linkGrid( grid )
		-- Down from the last saved slot of each column reaches OPTIONS, and up
		-- from OPTIONS returns to the lowest saved slot.
		local lowestSaved
		for slot = 1, C.SoloSlotCount do
			if saved[slot] then lowestSaved = slot end
		end
		for column = 1, 2 do
			local last
			for slot = column, C.SoloSlotCount, 2 do
				if saved[slot] then last = slot end
			end
			if last and grid.buttons[last].navigation then grid.buttons[last].navigation.down = options end
		end
		if lowestSaved and options.navigation then options.navigation.up = grid.buttons[lowestSaved] end
		if anySaved then
			focusGridSlot( grid, selectedSlot or firstSaved, function ( slot ) return saved[slot] end )
		else
			focusedSlot = nil
			setDeleteVisible( false )
			showDetails( 1, C.SoloSlotMeta( map, 1 ) )
		end
	end
	build()
	local function rebuild()
		clearGrid( grid )
		for _, button in ipairs( actionButtons ) do actions:removeElement( button ) end
		actionButtons = {}
		focusedSlot = nil
		build()
	end
	menu:registerEventHandler( "zmcp_rebuild", rebuild )
	menu:registerEventHandler( "zmcp_slot_options", function ( owner, event )
		if not selectedSlot or not C.SoloSlotMeta( map, selectedSlot ).has then return end
		C.OptionsTarget = { map = map, slot = selectedSlot, owner = owner }
		owner:openPopup( "ZMCheckpointSoloOptions", event.controller or controller )
	end )
	menu:registerEventHandler( "zmcp_slot_start", function ( owner, event )
		if not selectedSlot then return end
		local ok, reason = C.Resume( owner, event, selectedSlot )
		if not ok then status:setText( reason ) end
	end )
	menu:registerEventHandler( "zmcp_options_applied", function ( owner, event )
		status:setText( "Slot " .. event.slot .. " options saved. The save file was not changed." )
		rebuild()
	end )
	menu:registerEventHandler( "zmcp_delete_slot", function ( owner, event )
		if not focusedSlot or menu.zmcpDeleteOpen then return end
		local meta = C.SoloSlotMeta( map, focusedSlot )
		if not meta.has then return end
		menu.zmcpDeleteOpen = true
		local popup = owner:openPopup( "ZMCheckpointDeleteConfirm", event.controller or controller )
		popup.zmcpResume = owner
		popup.zmcpSlot = focusedSlot
		popup.zmcpMessage:setText( "Slot " .. focusedSlot .. ", round " .. meta.round .. " will be deleted." )
	end )
	menu:registerEventHandler( "zmcp_delete_closed", function () menu.zmcpDeleteOpen = false end )
	menu:registerEventHandler( "zmcp_delete_confirmed", function ( owner, event )
		menu.zmcpDeleteOpen = false
		if C.DeleteSoloSlot( controller, map, event.slot ) then
			status:setText( "Slot " .. event.slot .. " deleted." )
		else
			status:setText( "That save could not be deleted." )
		end
		if selectedSlot == event.slot then selectedSlot = nil end
		rebuild()
	end )
	return menu
end

LUI.createMenu.ZMCheckpointDeleteConfirm = function ( controller )
	local popup = CoD.Menu.NewSmallPopup( "ZMCheckpointDeleteConfirm" )
	popup:setOwner( controller )
	popup:addSelectButton()
	popup:addBackButton()
	local title = LUI.UIText.new()
	title:setLeftRight( true, true, 0, 0 )
	title:setTopBottom( true, false, 5, 5 + CoD.textSize.Big )
	title:setFont( CoD.fonts.Big )
	title:setAlignment( LUI.Alignment.Left )
	title:setText( "DELETE SAVE?" )
	popup:addElement( title )
	local message = LUI.UIText.new()
	message:setLeftRight( true, true, 0, 0 )
	message:setTopBottom( true, false, 12 + CoD.textSize.Big, 12 + CoD.textSize.Big + CoD.textSize.Default )
	message:setFont( CoD.fonts.Default )
	message:setAlignment( LUI.Alignment.Left )
	message:setText( "This save will be deleted." )
	popup:addElement( message )
	popup.zmcpMessage = message
	local warning = LUI.UIText.new()
	warning:setLeftRight( true, true, 0, 0 )
	warning:setTopBottom( true, false, 16 + CoD.textSize.Big + CoD.textSize.Default,
		16 + CoD.textSize.Big + CoD.textSize.Default * 2 )
	warning:setFont( CoD.fonts.Default )
	warning:setAlignment( LUI.Alignment.Left )
	warning:setText( "This cannot be undone." )
	popup:addElement( warning )
	local buttons = CoD.ButtonList.new( { leftAnchor = true, rightAnchor = true,
		left = 0, right = 0, topAnchor = false, bottomAnchor = true,
		top = -CoD.ButtonPrompt.Height - CoD.CoD9Button.Height * 3 + 10, bottom = 0 } )
	popup:addElement( buttons )
	local confirm = buttons:addButton( "YES, DELETE" )
	local keep = buttons:addButton( "NO, KEEP" )
	confirm:setActionEventName( "zmcp_delete_yes" )
	keep:setActionEventName( "zmcp_delete_no" )
	-- Esc and NO both leave the save untouched; either way the page may be asked again.
	local function close( owner, event, deleted )
		local resume, slot = owner.zmcpResume, owner.zmcpSlot
		CoD.Menu.ButtonPromptBack( owner, event )
		if resume then
			resume:processEvent( deleted and { name = "zmcp_delete_confirmed", slot = slot,
				controller = event.controller } or { name = "zmcp_delete_closed" } )
		end
	end
	popup:registerEventHandler( "zmcp_delete_yes", function ( owner, event ) close( owner, event, true ) end )
	popup:registerEventHandler( "zmcp_delete_no", function ( owner, event ) close( owner, event, false ) end )
	popup:registerEventHandler( "button_prompt_back", function ( owner, event ) close( owner, event, false ) end )
	keep:processEvent( { name = "gain_focus" } )
	return popup
end

-- Per-save setting changes are stored beside the save, never inside it. GSC
-- applies them whenever it reads the checkpoint (see zmcp_apply_solo_overrides)
-- and drops them when the slot is saved over, consumed or deleted.
C.SoloOptionKeys = { "difficulty", "magic", "headshots", "assist", "cheats" }

C.ApplySoloOptions = function ( controller, map, slot, values )
	if C.SupportedMaps[map] == nil or slot < 1 or slot > C.SoloSlotCount then return false end
	local meta = C.SoloSlotMeta( map, slot )
	if not meta.has then return false end
	local out = {}
	if meta.settings then
		for _, key in ipairs( C.SoloOptionKeys ) do
			local value = values[key]
			if value ~= 0 and value ~= 1 then return false end
			local prefix = "zmcp_solo_" .. map .. "_slot" .. slot .. "_"
			out[ "zmcp_ovr_" .. map .. "_slot" .. slot .. "_" .. key ] = value
			-- The lobby reads these published values when Resume applies the settings.
			out[ prefix .. key ] = value
		end
		out[ "zmcp_ovr_" .. map .. "_slot" .. slot .. "_set" ] = 1
	end
	if values.perks ~= 0 and values.perks ~= 1 then return false end
	out[ "zmcp_ovr_" .. map .. "_slot" .. slot .. "_perks" ] = values.perks
	-- Run settings added later than the first options page are optional.
	local function integer( value, maximum )
		return type( value ) == "number" and value == math.floor( value ) and value >= 0 and value <= maximum
	end
	if values.healthcap ~= nil then
		if not integer( values.healthcap, 255 ) then return false end
		out[ "zmcp_ovr_" .. map .. "_slot" .. slot .. "_healthcap" ] = values.healthcap
	end
	if values.autosave ~= nil then
		if not integer( values.autosave, C.SoloSlotCount ) then return false end
		out[ "zmcp_ovr_" .. map .. "_slot" .. slot .. "_autosave" ] = values.autosave
	end
	for name, value in pairs( out ) do
		Engine.Exec( controller, "seta " .. name .. " " .. value .. "\n" )
		Engine.SetDvar( name, value )
	end
	return true
end

LUI.createMenu.ZMCheckpointSoloOptions = function ( controller )
	local target = C.OptionsTarget or {}
	local map, slot = target.map, target.slot
	local meta = C.SoloSlotMeta( map or "", slot or 0 )
	local menu, status, list = pageBase( "ZMCheckpointSoloOptions",
		"SLOT " .. tostring( slot ) .. " OPTIONS",
		"Changes are stored beside the save. The save file itself is not modified.", 560 )
	local disabledLabel, enabledLabel = "MENU_DISABLED_CAPS", "MENU_ENABLED_CAPS"
	local function toggle( key, name, hint, value )
		local dvar = "zmcp_edit_" .. key
		Engine.SetDvar( dvar, value )
		local row = list:addDvarLeftRightSelector( controller, Engine.Localize( name ), dvar,
			Engine.Localize( hint ), 220 )
		row:addChoice( controller, Engine.Localize( disabledLabel ), 0 )
		row:addChoice( controller, Engine.Localize( enabledLabel ), 1 )
		return row
	end
	if meta.settings then
		-- Selectors read their dvar when built, so seed it first.
		Engine.SetDvar( "zmcp_edit_difficulty", meta.difficulty or 1 )
		local difficulty = list:addDvarLeftRightSelector( controller, Engine.Localize( "DIFFICULTY" ),
			"zmcp_edit_difficulty", Engine.Localize( "Zombie difficulty used when this save is resumed." ), 220 )
		difficulty:addChoice( controller, Engine.Localize( "EASY" ), 0 )
		difficulty:addChoice( controller, Engine.Localize( "ORIGINAL" ), 1 )
		toggle( "magic", "MAGIC", "Mystery box and other magic items.", meta.magic or 1 )
		toggle( "headshots", "HEADSHOTS ONLY", "Only headshots damage zombies.", meta.headshots or 0 )
		toggle( "assist", "TARGET ASSIST", "Aim assist for this checkpoint.", meta.assist or 1 )
		toggle( "cheats", "CHEATS", "Enable cheats when this save is resumed.", meta.cheats or 0 )
	else
		status:setText( "Older save: only unlimited perks can be changed." )
	end
	toggle( "perks", "UNLIMITED PERKS", "Allow every perk at once when this save is resumed.", meta.unlimited or 0 )
	-- Run settings from MORE OPTIONS that make sense during a run. Settings that
	-- only shape a new match (starting weapons, perk, points, opening) are not here.
	-- They start from the lobby's current value, so applying without touching them
	-- keeps what the lobby has.
	local function clamp( value, maximum )
		value = tonumber( value ) or 0
		if value < 0 then return 0 end
		if value > maximum then return maximum end
		return math.floor( value )
	end
	Engine.SetDvar( "zmcp_edit_healthcap", meta.healthcap or clamp( C.DvarString( "zmcp_health_cap" ), 255 ) )
	local healthcap = list:addDvarLeftRightSelector( controller, Engine.Localize( "ZOMBIE HEALTH CAP" ),
		"zmcp_edit_healthcap", Engine.Localize( "Zombies stop getting tougher after this round (OFF = normal). Click to type 1-255." ), 220 )
	for _, choice in ipairs( { { "OFF", 0 }, { "ROUND 20", 20 }, { "ROUND 30", 30 }, { "ROUND 40", 40 },
		{ "ROUND 50", 50 }, { "ROUND 75", 75 }, { "ROUND 100", 100 } } ) do
		healthcap:addChoice( controller, Engine.Localize( choice[1] ), choice[2] )
	end
	if C.AttachCustomHealthCap then pcall( C.AttachCustomHealthCap, healthcap ) end
	Engine.SetDvar( "zmcp_edit_autosave", meta.autosave or clamp( C.DvarString( "zmcp_autosave" ), C.SoloSlotCount ) )
	local autosave = list:addDvarLeftRightSelector( controller, Engine.Localize( "AUTOSAVE" ),
		"zmcp_edit_autosave", Engine.Localize( "Save automatically when each round ends, into this slot (OFF = never)." ), 220 )
	autosave:addChoice( controller, Engine.Localize( "OFF" ), 0 )
	for number = 1, C.SoloSlotCount do
		autosave:addChoice( controller, Engine.Localize( "SLOT " .. number ), number )
	end
	local apply = list:addButton( "APPLY CHANGES", "Store these settings for this checkpoint." )
	local cancel = list:addButton( "CANCEL", "Leave this checkpoint's settings as they are." )
	apply:setActionEventName( "zmcp_options_apply" )
	cancel:setActionEventName( "zmcp_options_cancel" )
	menu:registerEventHandler( "zmcp_options_cancel", function ( owner, event ) owner:goBack( event.controller or controller ) end )
	menu:registerEventHandler( "zmcp_options_apply", function ( owner, event )
		local read = function ( key ) return tonumber( C.DvarString( "zmcp_edit_" .. key ) ) end
		local values = { perks = read( "perks" ), healthcap = read( "healthcap" ), autosave = read( "autosave" ) }
		for _, key in ipairs( C.SoloOptionKeys ) do values[key] = read( key ) end
		if not C.ApplySoloOptions( controller, map, slot, values ) then
			status:setText( "Those settings could not be stored." )
			return
		end
		owner:goBack( event.controller or controller )
		local resume = target.owner
		if resume then resume:processEvent( { name = "zmcp_options_applied", slot = slot, controller = controller } ) end
	end )
	list:processEvent( { name = "gain_focus" } )
	return menu
end

-- Shared with the CO-OP RESUME page.
C.Ui = { PageBase = pageBase, AddText = addText, WeaponName = weaponName, PerkStyle = perkStyle, WeaponMaterial = weaponMaterial }
