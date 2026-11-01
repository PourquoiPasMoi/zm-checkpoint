-- Run with .tools/lua-validator/node_modules/.bin/fengari tools/Test-MoreOptions.lua
-- The lobby gets one MORE OPTIONS button; the page it opens holds the five mod
-- options bound to their dvars, and the stock option list is left alone.
local dvars, rows, buttons, popups = {}, {}, {}, {}
local function newButton( label )
	local b = { label = label, handlers = {} }
	function b:setActionEventName( name ) self.action = name end
	return b
end
local lobbyList = {}
function lobbyList:addButton( label ) local b = newButton( label ); buttons[#buttons + 1] = b; return b end
local lobbyMenu
CoD = { isMultiplayer = false, ButtonPrompt = { Height = 30 }, GameLobby = {} }
CoD.PrivateGameLobby = { Dvars = { { id = "sv_cheats" } }, DvarDefaults = {}, New = function ()
	lobbyMenu = { handlers = {}, setPreviousMenu = function () end, addTitle = function () end,
		openPopup = function ( _, name ) popups[#popups + 1] = name end,
		panelManager = { panels = { buttonPane = { body = { buttonList = lobbyList } } } } }
	function lobbyMenu:registerEventHandler( e, fn ) self.handlers[e] = fn end
	return lobbyMenu
end }
CoD.ZMCheckpointMenu = { HookLobby = function () end, AddLobbyResumeButton = function () end,
	DvarString = function ( k ) return dvars[k] == nil and "" or tostring( dvars[k] ) end }
LUI = { createMenu = {} }
Engine = { Localize = function ( s ) return s end, SetDvar = function ( k, v ) dvars[k] = v end }
function require() end
assert( loadfile( "src/ui/ui/t6/menus/zmcheckpointloadout.lua" ) )()
local lobby = assert( loadfile( "src/ui/ui/t6/menus/privateonlinegamelobby.lua" ) )
lobby(); lobby()

-- One button, added once per lobby, opening the page as a popup.
LUI.createMenu.PrivateOnlineGameLobby( 0 )
assert( #buttons == 1 and buttons[1].label == "MORE OPTIONS" and buttons[1].action == "zmcp_more_options" )
lobbyMenu.handlers.zmcp_more_options( lobbyMenu, { controller = 0 } )
assert( popups[1] == "ZMCheckpointMoreOptions" )
assert( #CoD.PrivateGameLobby.Dvars == 1, "stock option list untouched" )

-- The page: one selector per option with its choices, then DONE.
local pageList = {}
function pageList:addDvarLeftRightSelector( controller, name, dvar, hint )
	local row = { name = name, dvar = dvar, choices = {} }
	function row:addChoice( _, label, value ) self.choices[#self.choices + 1] = { label, value } end
	row.handlers, row.choiceText = {}, { setText = function ( _, t ) row.text = t end }
	function row:registerEventHandler( e, fn ) self.handlers[e] = fn end
	function row:isInFocus() return true end
	function row:handleGamepadButton() end
	function row:cycle() self.stockCycled = true end
	function row:updateChoice() self.text = "STOCK" end
	rows[#rows + 1] = row
	return row
end
function pageList:addButton( label ) local b = newButton( label ); b.label = label; rows[#rows + 1] = b; return b end
function pageList:processEvent() end
local page = { handlers = {} }
function page:registerEventHandler( e, fn ) self.handlers[e] = fn end
function page:goBack() self.wentBack = true end
CoD.ZMCheckpointMenu.Ui = { PageBase = function ( name, title ) page.name, page.title = name, title; return page, {}, pageList end }
dvars.zmcp_start_weapons, dvars.zmcp_start_points, dvars.zmcp_health_cap, dvars.zmcp_autosave = "9", "99999999", "999", "99"
local built = LUI.createMenu.ZMCheckpointMoreOptions( 0 )
assert( built == page and page.name == "ZMCheckpointMoreOptions" and page.title == "MORE OPTIONS" )
assert( #rows == 8, "seven options and DONE, got " .. #rows )
local want = { "zmcp_all_perks", "zmcp_start_weapons", "zmcp_start_perks", "zmcp_start_points", "zmcp_start_world", "zmcp_health_cap", "zmcp_autosave" }
for i, dvar in ipairs( want ) do assert( rows[i].dvar == dvar, "row " .. i .. " is " .. tostring( rows[i].dvar ) ) end
assert( #rows[2].choices == 5 and rows[2].choices[5][2] == 4 and #rows[4].choices == 9 and #rows[5].choices == 4 )
assert( tostring( dvars.zmcp_start_weapons ) == "4" and tostring( dvars.zmcp_start_points ) == "1000000", "stored values are clamped before the rows are built" )
assert( dvars.zmcp_all_perks == 0, "unlimited perks dvar seeded" )
assert( tostring( dvars.zmcp_health_cap ) == "255", "health cap clamps to 255" )
assert( tostring( dvars.zmcp_autosave ) == "8", "autosave slot clamps to 8" )
assert( rows[8].label == "DONE" and rows[8].action == "zmcp_more_done" )
assert( #rows[7].choices == 9 and rows[7].choices[9][2] == 8 and rows[7].choices[1][2] == 0 )
assert( #rows[6].choices == 7 and rows[6].choices[1][2] == 0 and rows[6].choices[5][2] == 50 )
-- Typed rows: clicking opens the keyboard (it must not step through the fallback list).
CoD.KEYBOARD_TYPE_TEXT_MESSAGE = 7
local execs = {}
Engine.Exec = function ( _, text ) execs[#execs + 1] = text end
for _, index in ipairs( { 4, 6 } ) do
	local row = rows[index]
	assert( row.zmcpCustomPoints or row.zmcpCustomHealth, "row " .. index .. " is a typed row" )
	assert( row.handlers.button_action( row, { controller = 0, mouse = true } ) )
	assert( execs[#execs]:find( "ui_keyboard_new 7 ", 1, true ) and not row.stockCycled )
end
assert( rows[6].text == "OFF" or rows[6].text == "ROUND 255" )
assert( not rows[1].zmcpCustomPoints and not rows[5].zmcpCustomHealth, "other rows stay stock" )
page.handlers.zmcp_more_done( page, { controller = 0 } )
assert( page.wentBack )
print( "PASS: MORE OPTIONS button opens a page with the seven mod options, DONE returns, stock list untouched" )
