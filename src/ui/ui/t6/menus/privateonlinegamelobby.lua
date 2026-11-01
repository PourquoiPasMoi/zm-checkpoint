-- Stock T6 private lobby entry point with the ZM Checkpoint hook loaded last.

require( "T6.Menus.PrivateGameLobby" )
require( "T6.Menus.ZMCheckpointMenu" )

CoD.ZMCheckpointMenu.HookLobby()

CoD.PrivateOnlineGameLobby = {}

local C = CoD.ZMCheckpointMenu

-- The mod's own options live on a MORE OPTIONS page (opened by one button in the
-- lobby list) instead of as extra rows in the stock option list. The page binds
-- each row to the same dvars the rows used before, so GSC is unchanged.
C.MoreOptions = C.MoreOptions or {}
local addMoreOption = function ( id, default, name, hint, labels, values )
	for _, option in ipairs( C.MoreOptions ) do
		if option.id == id then
			return
		end
	end
	C.MoreOptions[#C.MoreOptions + 1] = {
		id = id,
		default = default,
		name = name,
		hintText = hint,
		labels = labels or { "MENU_DISABLED_CAPS", "MENU_ENABLED_CAPS" },
		values = values or { 0, 1 }
	}
end

addMoreOption( "zmcp_all_perks", 0, "UNLIMITED PERKS",
	"Allow every perk at once (normally four)." )
addMoreOption( "zmcp_start_weapons", 0, "STARTING WEAPONS",
	"New match: random map weapons. Two replace the M1911.",
	{ "NONE", "1 RANDOM WEAPON", "2 RANDOM WEAPONS", "1 PACKED WEAPON", "2 PACKED WEAPONS" }, { 0, 1, 2, 3, 4 } )
addMoreOption( "zmcp_start_perks", 0, "STARTING PERK",
	"New match: one random perk from this map.",
	{ "NONE", "1 RANDOM PERK" }, { 0, 1 } )
addMoreOption( "zmcp_start_points", 0, "STARTING POINTS",
	"New match: start with this many points. Click to type.",
	{ "DEFAULT", "5,000", "10,000", "25,000", "50,000", "100,000", "250,000", "500,000", "1,000,000" },
	{ 0, 5000, 10000, 25000, 50000, 100000, 250000, 500000, 1000000 } )
addMoreOption( "zmcp_start_world", 0, "OPENING",
	"New match: power on and/or all doors and debris open.",
	{ "NORMAL", "POWER ON", "DOORS OPEN", "POWER + DOORS" }, { 0, 1, 2, 3 } )

-- CUSTOM STARTING ROUND. The stock STARTING ROUND row only offers a few fixed
-- values. Its selector is replaced in place (found by its label when the stock
-- lobby builds it) with a number that is stored in the archived dvar
-- zmcp_start_round and applied by GSC; the stock gametype setting is left alone.
-- Left/right and the mouse wheel step by one, a click or Enter opens the stock
-- on-screen keyboard to type a number. Values are clamped to 1-255.
C.StartRoundMin, C.StartRoundMax = 1, 255

C.ClampStartRound = function ( value )
	value = tonumber( value )
	if value == nil or value ~= value then return nil end
	value = math.floor( value )
	if value < C.StartRoundMin then return C.StartRoundMin end
	if value > C.StartRoundMax then return C.StartRoundMax end
	return value
end

C.StartRoundValue = function ()
	return C.ClampStartRound( C.DvarString( "zmcp_start_round" ) ) or C.StartRoundMin
end

C.SetStartRound = function ( value )
	value = C.ClampStartRound( value )
	if value == nil then return nil end
	Engine.SetDvar( "zmcp_start_round", value )
	Engine.Exec( 0, "seta zmcp_start_round " .. value .. "\n" )
	return value
end

C.AttachCustomStartRound = function ( selector )
	if selector.zmcpCustomRound then return end
	selector.zmcpCustomRound = true
	-- The dvar only exists while this row is active, so a lobby that could not
	-- be patched keeps using the stock setting.
	if C.DvarString( "zmcp_start_round" ) == "" then C.SetStartRound( C.StartRoundMin ) end
	local show = function ( self )
		if self.choiceText then self.choiceText:setText( tostring( C.StartRoundValue() ) ) end
	end
	local step = function ( self, amount )
		C.SetStartRound( C.StartRoundValue() + amount )
		show( self )
	end
	-- Stock choice-building calls these; only the user-requested cycle counts.
	selector.updateChoice = show
	selector.refreshChoice = show
	selector.setChoice = function ( self ) show( self ) end
	selector.cycle = function ( self, forward, userRequested )
		if userRequested then step( self, forward and 1 or -1 ) end
	end
	local stockButton = selector.handleGamepadButton
	selector.handleGamepadButton = function ( self, event )
		if event.qualifier == "mwheel" and event.down == true and self:isInFocus() then
			if event.button == "up" then
				step( self, 1 )
				return true
			elseif event.button == "down" then
				step( self, -1 )
				return true
			end
		end
		return stockButton( self, event )
	end
	local openKeyboard = function ( self, event )
		local keyboardType = CoD.KEYBOARD_TYPE_TEXT_MESSAGE
		if keyboardType == nil then
			step( self, 1 )
			return true
		end
		Engine.Exec( event.controller or 0, "ui_keyboard_new " .. keyboardType ..
			" \"CUSTOM STARTING ROUND (" .. C.StartRoundMin .. "-" .. C.StartRoundMax .. ")\" \"" ..
			C.StartRoundValue() .. "\" 3" )
		return true
	end
	selector:registerEventHandler( "button_action", openKeyboard )
	selector:registerEventHandler( "ui_keyboard_input", function ( self, event )
		if event.type ~= CoD.KEYBOARD_TYPE_TEXT_MESSAGE or type( event.input ) ~= "string" then return end
		local digits = string.match( event.input, "^%s*(%d+)%s*$" )
		if digits and #digits <= 4 then
			C.SetStartRound( tonumber( digits ) )
			show( self )
		end
	end )
	show( selector )
end

-- STARTING POINTS. The row keeps its fixed list as a fallback; when the stock
-- lobby builds it, the selector is replaced in place by a number (0 = DEFAULT)
-- stored in the archived dvar zmcp_start_points. Left/right and the mouse wheel
-- step by 5,000; a click or Enter opens the on-screen keyboard to type a value.
C.PointsStep = 5000

C.ClampStartPoints = function ( value )
	value = tonumber( value )
	if value == nil or value ~= value then return nil end
	value = math.floor( value )
	if value < 0 then return 0 end
	if value > C.PointsMax then return C.PointsMax end
	return value
end

C.StartPointsValue = function ()
	return C.ClampStartPoints( C.DvarString( "zmcp_start_points" ) ) or 0
end

C.FormatStartPoints = function ( value )
	if value < 1 then return "DEFAULT" end
	local text = tostring( value )
	while true do
		local replaced, count = string.gsub( text, "^(%d+)(%d%d%d)", "%1,%2" )
		text = replaced
		if count == 0 then break end
	end
	return text
end

C.SetStartPoints = function ( value )
	value = C.ClampStartPoints( value )
	if value == nil then return nil end
	Engine.SetDvar( "zmcp_start_points", value )
	Engine.Exec( 0, "seta zmcp_start_points " .. value .. "\n" )
	return value
end

C.AttachCustomStartPoints = function ( selector )
	if selector.zmcpCustomPoints then return end
	selector.zmcpCustomPoints = true
	local show = function ( self )
		if self.choiceText then self.choiceText:setText( C.FormatStartPoints( C.StartPointsValue() ) ) end
	end
	local step = function ( self, amount )
		C.SetStartPoints( C.StartPointsValue() + amount )
		show( self )
	end
	selector.updateChoice = show
	selector.refreshChoice = show
	selector.setChoice = function ( self ) show( self ) end
	selector.cycle = function ( self, forward, userRequested )
		if userRequested then step( self, forward and C.PointsStep or -C.PointsStep ) end
	end
	local stockButton = selector.handleGamepadButton
	selector.handleGamepadButton = function ( self, event )
		if event.qualifier == "mwheel" and event.down == true and self:isInFocus() then
			if event.button == "up" then
				step( self, C.PointsStep )
				return true
			elseif event.button == "down" then
				step( self, -C.PointsStep )
				return true
			end
		end
		return stockButton( self, event )
	end
	selector:registerEventHandler( "button_action", function ( self, event )
		local keyboardType = CoD.KEYBOARD_TYPE_TEXT_MESSAGE
		if keyboardType == nil then
			step( self, C.PointsStep )
			return true
		end
		Engine.Exec( event.controller or 0, "ui_keyboard_new " .. keyboardType ..
			" \"STARTING POINTS (0 = DEFAULT, MAX " .. C.PointsMax .. ")\" \"" ..
			C.StartPointsValue() .. "\" 7" )
		return true
	end )
	selector:registerEventHandler( "ui_keyboard_input", function ( self, event )
		if event.type ~= CoD.KEYBOARD_TYPE_TEXT_MESSAGE or type( event.input ) ~= "string" then return end
		local digits = string.match( event.input, "^%s*(%d+)%s*$" )
		if digits and #digits <= 8 then
			C.SetStartPoints( tonumber( digits ) )
			show( self )
		end
	end )
	show( selector )
end

local isStartRoundLabel = function ( name )
	if type( name ) ~= "string" then return false end
	if name == "ZMUI_STARTING_ROUND_CAPS" then return true end
	local localized = Engine.Localize( "ZMUI_STARTING_ROUND_CAPS" )
	return name == localized or string.upper( name ) == "STARTING ROUND"
end

if CoD.LeftRightSelector and CoD.LeftRightSelector.new and not CoD.LeftRightSelector.zmcpStartRoundHook then
	CoD.LeftRightSelector.zmcpStartRoundHook = true
	local stockNew = CoD.LeftRightSelector.new
	CoD.LeftRightSelector.new = function ( name, ... )
		if name == "STARTING POINTS" then
			local selector = stockNew( name, ... )
			local ok = pcall( C.AttachCustomStartPoints, selector )
			if not ok then selector.zmcpCustomPoints = nil end
			return selector
		end
		if not isStartRoundLabel( name ) then return stockNew( name, ... ) end
		local selector = stockNew( "CUSTOM STARTING ROUND", ... )
		local ok = pcall( C.AttachCustomStartRound, selector )
		if not ok then selector.zmcpCustomRound = nil end
		return selector
	end
end

LUI.createMenu.ZMCheckpointMoreOptions = function ( controller )
	-- Selectors read their dvar when built, so make sure each one holds a valid value.
	if C.DvarString( "zmcp_all_perks" ) == "" then Engine.SetDvar( "zmcp_all_perks", 0 ) end
	if C.RefreshLoadoutOptions then C.RefreshLoadoutOptions() end
	local menu, status, list = C.Ui.PageBase( "ZMCheckpointMoreOptions", "MORE OPTIONS",
		"Starting options apply to new matches. Changes take effect at once.", 560 )
	for _, option in ipairs( C.MoreOptions ) do
		local row = list:addDvarLeftRightSelector( controller, Engine.Localize( option.name ), option.id,
			Engine.Localize( option.hintText ), 220 )
		for index, label in ipairs( option.labels ) do
			row:addChoice( controller, Engine.Localize( label ), option.values[index] )
		end
	end
	local done = list:addButton( "DONE", "Return to the lobby." )
	done:setActionEventName( "zmcp_more_done" )
	menu:registerEventHandler( "zmcp_more_done", function ( owner, event )
		owner:goBack( event.controller or controller )
	end )
	list:processEvent( { name = "gain_focus" } )
	return menu
end

LUI.createMenu.PrivateOnlineGameLobby = function ( controller )
	-- The selector reads its dvar when it is built; make sure it exists first.
	if CoD.ZMCheckpointMenu.DvarString( "zmcp_all_perks" ) == "" then
		Engine.SetDvar( "zmcp_all_perks", 0 )
	end
	-- Stored loadout values are clamped so the rows and GSC agree.
	if CoD.ZMCheckpointMenu.RefreshLoadoutOptions then
		CoD.ZMCheckpointMenu.RefreshLoadoutOptions()
	end
	local menu = CoD.PrivateGameLobby.New( "PrivateOnlineGameLobby", controller )
	if CoD.isMultiplayer then
		menu:setPreviousMenu( "MainLobby" )
	end
	local title = Engine.Localize( "MPUI_CUSTOM_GAMES_CAPS" )
	menu:addTitle( title )
	menu.panelManager.panels.buttonPane.titleText = title
	CoD.ZMCheckpointMenu.AddLobbyResumeButton( menu, controller )
	-- One button opens the MORE OPTIONS page; it follows the stock option rows.
	local optionList = menu.panelManager and menu.panelManager.panels and menu.panelManager.panels.buttonPane
	optionList = optionList and optionList.body and optionList.body.buttonList
	if optionList and not menu.zmcpMoreButton then
		local more = optionList:addButton( "MORE OPTIONS", "Starting weapons, perk, points, opening and unlimited perks." )
		more:setActionEventName( "zmcp_more_options" )
		menu.zmcpMoreButton = more
		menu:registerEventHandler( "zmcp_more_options", function ( owner, event )
			owner:openPopup( "ZMCheckpointMoreOptions", event.controller or controller )
		end )
	end
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
