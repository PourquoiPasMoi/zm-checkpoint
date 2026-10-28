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
		location = read( "location" )
	}
end

local function slotHint( meta )
	if not meta.has then return "Empty slot." end
	if not meta.settings then return "Older checkpoint: current lobby settings will be used." end
	local enabled = function ( n ) return n == 1 and "ON" or "OFF" end
	return "ROUND " .. meta.round .. " | DIFFICULTY " .. (meta.difficulty == 0 and "EASY" or "ORIGINAL") ..
		" | MAGIC " .. enabled( meta.magic ) .. " | HEADSHOTS " .. enabled( meta.headshots ) ..
		" | ASSIST " .. enabled( meta.assist ) .. " | CHEATS " .. enabled( meta.cheats )
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

LUI.createMenu.ZMCheckpointSoloSave = function ( controller )
	local menu, status, list = pageBase( "ZMCheckpointSoloSave", "SAVE SOLO CHECKPOINT",
		"Choose a slot. Select an occupied slot twice to replace it." )
	local map = C.CurrentMap( true )
	local pending = 0
	for slot = 1, 4 do
		local chosenSlot = slot
		local meta = C.SoloSlotMeta( map, chosenSlot )
		local title = "SLOT " .. chosenSlot .. (meta.has and (" - ROUND " .. meta.round) or " - EMPTY")
		local button = list:addButton( title, slotHint( meta ) )
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
	for slot = 1, 4 do
		local chosenSlot = slot
		local meta = C.SoloSlotMeta( map, chosenSlot )
		local title = "SLOT " .. chosenSlot .. (meta.has and (" - ROUND " .. meta.round) or " - EMPTY")
		local button = list:addButton( title, slotHint( meta ) )
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
