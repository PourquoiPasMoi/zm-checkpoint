-- Stock T6 private lobby entry point with the ZM Checkpoint hook loaded last.

require( "T6.Menus.PrivateGameLobby" )
require( "T6.Menus.ZMCheckpointMenu" )

CoD.ZMCheckpointMenu.HookLobby()

CoD.PrivateOnlineGameLobby = {}

-- Extra lobby option rows. The stock lobby builds one selector row per entry of
-- CoD.PrivateGameLobby.Dvars, so appending here places the row directly under
-- CHEATS with the same spacing, font, hint and focus behavior as the stock rows.
local addLobbyDvarOption = function ( id, default, name, hint, labels, values )
	for _, option in ipairs( CoD.PrivateGameLobby.Dvars ) do
		if option.id == id then
			return
		end
	end
	local option = {
		id = id,
		name = name,
		hintText = hint,
		labels = labels or { "MENU_DISABLED_CAPS", "MENU_ENABLED_CAPS" },
		values = values or { 0, 1 }
	}
	CoD.PrivateGameLobby.DvarDefaults[id] = default
	CoD.PrivateGameLobby.Dvars[#CoD.PrivateGameLobby.Dvars + 1] = option
end

addLobbyDvarOption( "zmcp_all_perks", 0, "UNLIMITED PERKS",
	"Allow every perk at once instead of the normal limit of four." )
addLobbyDvarOption( "zmcp_start_weapon1", "none", "STARTING WEAPON 1",
	"Begin a new match with this weapon. Only weapons from this map are listed.", { "NONE" }, { "none" } )
addLobbyDvarOption( "zmcp_start_weapon2", "none", "STARTING WEAPON 2",
	"A second starting weapon. With two, the M1911 is replaced.", { "NONE" }, { "none" } )
addLobbyDvarOption( "zmcp_start_perks", 0, "STARTING PERKS",
	"Begin a new match with random perks from this map's perk machines.",
	{ "NONE", "1 RANDOM PERK", "2 RANDOM PERKS", "3 RANDOM PERKS", "4 RANDOM PERKS" }, { 0, 1, 2, 3, 4 } )

-- CUSTOM STARTING ROUND. The stock STARTING ROUND row only offers a few fixed
-- values. Its selector is replaced in place (found by its label when the stock
-- lobby builds it) with a number that is stored in the archived dvar
-- zmcp_start_round and applied by GSC; the stock gametype setting is left alone.
-- Left/right and the mouse wheel step by one, a click or Enter opens the stock
-- on-screen keyboard to type a number. Values are clamped to 1-255.
local C = CoD.ZMCheckpointMenu
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
		if not isStartRoundLabel( name ) then return stockNew( name, ... ) end
		local selector = stockNew( "CUSTOM STARTING ROUND", ... )
		local ok = pcall( C.AttachCustomStartRound, selector )
		if not ok then selector.zmcpCustomRound = nil end
		return selector
	end
end

LUI.createMenu.PrivateOnlineGameLobby = function ( controller )
	-- The selector reads its dvar when it is built; make sure it exists first.
	if CoD.ZMCheckpointMenu.DvarString( "zmcp_all_perks" ) == "" then
		Engine.SetDvar( "zmcp_all_perks", 0 )
	end
	-- Weapon rows list the weapons of the map being shown; stale choices reset.
	if CoD.ZMCheckpointMenu.RefreshLoadoutOptions then
		CoD.ZMCheckpointMenu.RefreshLoadoutOptions( CoD.ZMCheckpointMenu.CurrentMap( false ) )
	end
	local menu = CoD.PrivateGameLobby.New( "PrivateOnlineGameLobby", controller )
	if CoD.isMultiplayer then
		menu:setPreviousMenu( "MainLobby" )
	end
	local title = Engine.Localize( "MPUI_CUSTOM_GAMES_CAPS" )
	menu:addTitle( title )
	menu.panelManager.panels.buttonPane.titleText = title
	CoD.ZMCheckpointMenu.AddLobbyResumeButton( menu, controller )
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
