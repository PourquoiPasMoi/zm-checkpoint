-- Run with .tools/lua-validator/node_modules/.bin/fengari tools/Test-StartRound.lua
-- Loads the shipped lobby hook with a mocked LeftRightSelector and exercises the
-- CUSTOM STARTING ROUND row: relabel, steps, mouse wheel, typed input and clamps.
local dvars, execs, built = {}, {}, {}
local function newSelector( name )
	local s = { name = name, handlers = {}, focused = true, choiceText = {} }
	s.choiceText.setText = function ( _, t ) s.text = t end
	s.registerEventHandler = function ( self, e, fn ) self.handlers[e] = fn end
	s.isInFocus = function ( self ) return self.focused end
	s.stockButtons = 0
	s.handleGamepadButton = function ( self ) self.stockButtons = self.stockButtons + 1 end
	s.cycle = function () end
	s.updateChoice = function () s.text = "STOCK" end
	built[#built + 1] = s
	return s
end
CoD = { isMultiplayer = false, ButtonPrompt = { Height = 30 }, KEYBOARD_TYPE_TEXT_MESSAGE = 7,
	LeftRightSelector = { new = newSelector }, GameLobby = {} }
CoD.PrivateGameLobby = { Dvars = {}, DvarDefaults = {}, New = function () return { setPreviousMenu = function () end,
	addTitle = function () end, registerEventHandler = function () end, panelManager = { panels = { buttonPane = {} } } } end }
CoD.ZMCheckpointMenu = { HookLobby = function () end, AddLobbyResumeButton = function () end,
	DvarString = function ( k ) return dvars[k] == nil and "" or tostring( dvars[k] ) end }
LUI = { createMenu = {} }
Engine = { Localize = function ( s ) return s == "ZMUI_STARTING_ROUND_CAPS" and "STARTING ROUND" or s end,
	SetDvar = function ( k, v ) dvars[k] = v end, Exec = function ( _, t ) execs[#execs + 1] = t end }
function require() end
local chunk = assert( loadfile( "src/ui/ui/t6/menus/privateonlinegamelobby.lua" ) )
chunk()
local hooked = CoD.LeftRightSelector.new
chunk() -- loading twice must not wrap the constructor twice
assert( CoD.LeftRightSelector.new == hooked )
local C = CoD.ZMCheckpointMenu

-- Other rows are untouched and no dvar appears until the row is built.
local other = CoD.LeftRightSelector.new( "MAGIC", "x" )
assert( other.name == "MAGIC" and not other.zmcpCustomRound and dvars.zmcp_start_round == nil )

-- The stock row is relabelled and starts at 1; choice building cannot change it.
local row = CoD.LeftRightSelector.new( "STARTING ROUND", "stock" )
assert( row.name == "CUSTOM STARTING ROUND" and row.zmcpCustomRound and row.text == "1" and dvars.zmcp_start_round == 1 )
row:updateChoice(); row:cycle() -- stock AddChoice calls cycle() with no arguments
assert( row.text == "1" and dvars.zmcp_start_round == 1, "choice building must not move the value" )
assert( CoD.LeftRightSelector.new( "ZMUI_STARTING_ROUND_CAPS" ).name == "CUSTOM STARTING ROUND", "raw string id" )

-- Left/right: user cycles step by one and clamp at both ends.
row:cycle( true, true ); row:cycle( true, true )
assert( row.text == "3" and dvars.zmcp_start_round == 3 )
row:cycle( nil, true )
assert( row.text == "2" )
row:cycle( nil, true ); row:cycle( nil, true )
assert( row.text == "1" and dvars.zmcp_start_round == 1, "never below 1" )
assert( table.concat( execs ):find( "seta zmcp_start_round 3\n", 1, true ), "value is archived" )

-- Mouse wheel steps only while the row is focused; other buttons reach the stock handler.
row:handleGamepadButton( { qualifier = "mwheel", down = true, button = "up" } )
row:handleGamepadButton( { qualifier = "mwheel", down = true, button = "up" } )
assert( row.text == "3" )
row:handleGamepadButton( { qualifier = "mwheel", down = true, button = "down" } )
assert( row.text == "2" )
row.focused = false
row:handleGamepadButton( { qualifier = "mwheel", down = true, button = "up" } )
assert( row.text == "2" and row.stockButtons == 1, "unfocused wheel falls through" )
row.focused = true
row:handleGamepadButton( { button = "left", down = true } )
assert( row.stockButtons == 2 )

-- Click or Enter opens the stock keyboard with the current value; typed text is validated.
local opened = row.handlers.button_action( row, { controller = 0 } )
local command = execs[#execs]
assert( opened and command:find( "ui_keyboard_new 7 ", 1, true ) and command:find( "\"2\" 3", 1, true ) and command:find( "(1-255)", 1, true ) )
local type_ = function ( text ) row.handlers.ui_keyboard_input( row, { type = 7, input = text } ) end
type_( "150" ); assert( row.text == "150" and dvars.zmcp_start_round == 150 )
type_( " 99 " ); assert( row.text == "99" )
type_( "0" ); assert( row.text == "1", "zero clamps to 1" )
type_( "999" ); assert( row.text == "255" and dvars.zmcp_start_round == 255, "clamped to 255" )
type_( "12abc" ); assert( row.text == "255", "non-numeric input ignored" )
type_( "-5" ); assert( row.text == "255" )
type_( "" ); assert( row.text == "255" )
type_( "123456" ); assert( row.text == "255", "overlong input ignored" )
row.handlers.ui_keyboard_input( row, { type = 3, input = "40" } ); assert( row.text == "255", "other keyboard types ignored" )
row:cycle( true, true ); assert( row.text == "255", "never above 255" )

-- A stored value is shown, an invalid stored value falls back to 1, and an existing dvar is not reset.
dvars.zmcp_start_round = "77"
assert( CoD.LeftRightSelector.new( "STARTING ROUND" ).text == "77" and dvars.zmcp_start_round == "77" )
dvars.zmcp_start_round = "junk"
assert( C.StartRoundValue() == 1 )
assert( C.ClampStartRound( "12.9" ) == 12 and C.ClampStartRound( nil ) == nil and C.ClampStartRound( "x" ) == nil )

-- STARTING POINTS: typed or stepped number, 0 means DEFAULT.
C.PointsMax = 1000000
local pts = CoD.LeftRightSelector.new( "STARTING POINTS", "stock" )
assert( pts.zmcpCustomPoints and pts.name == "STARTING POINTS" and pts.text == "DEFAULT" )
pts:updateChoice(); pts:cycle()
assert( pts.text == "DEFAULT", "choice building must not move the value" )
pts:cycle( true, true ); pts:cycle( true, true )
assert( pts.text == "10,000" and dvars.zmcp_start_points == 10000 )
pts:cycle( nil, true ); pts:cycle( nil, true ); pts:cycle( nil, true )
assert( pts.text == "DEFAULT" and dvars.zmcp_start_points == 0, "never below DEFAULT" )
pts:handleGamepadButton( { qualifier = "mwheel", down = true, button = "up" } )
assert( pts.text == "5,000" )
pts.handlers.button_action( pts, { controller = 0 } )
assert( execs[#execs]:find( "ui_keyboard_new 7 ", 1, true ) and execs[#execs]:find( "\"5000\" 7", 1, true ) )
local typedPoints = function ( text ) pts.handlers.ui_keyboard_input( pts, { type = 7, input = text } ) end
typedPoints( "123456" ); assert( pts.text == "123,456" and dvars.zmcp_start_points == 123456 )
typedPoints( "1000000" ); assert( pts.text == "1,000,000" )
typedPoints( "99999999" ); assert( pts.text == "1,000,000" and dvars.zmcp_start_points == 1000000, "clamped to 1,000,000" )
typedPoints( "0" ); assert( pts.text == "DEFAULT" and dvars.zmcp_start_points == 0 )
typedPoints( "12abc" ); typedPoints( "-5" ); typedPoints( "" ); assert( pts.text == "DEFAULT" )
assert( C.FormatStartPoints( 250 ) == "250" and C.FormatStartPoints( 1000 ) == "1,000" )
print( "PASS: custom starting round row relabelled, stepped, wheel, typed input and 1-255 clamps; typed STARTING POINTS row" )
