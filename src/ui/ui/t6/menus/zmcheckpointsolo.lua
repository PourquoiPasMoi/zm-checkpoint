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
	zombie_shield = "menu_zm_weapons_shield_big"
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
			local base = string.gsub( name, "_zm.*$", "" )
			base = string.gsub( base, "_upgraded.*$", "" )
			local material = weaponMaterials[base]
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
