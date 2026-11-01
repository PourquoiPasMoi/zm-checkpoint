-- Run with .tools/lua-validator/node_modules/.bin/fengari tools/Test-SoloDelete.lua
-- Drives the shipped SOLO RESUME page and DELETE confirmation with mocked widgets.
local d, execs = {}, {}
local function proxy()
	local p = {}
	return setmetatable( p, {
		__index = function ( t, k ) local v = proxy(); rawset( t, k, v ); return v end,
		__call = function () return proxy() end
	} )
end
local function widget( name )
	local w = proxy()
	w.handlers, w.menuName, w.opened, w.buttons = {}, name, {}, {}
	w.zmcpDeleteOpen, w.popup = false, false -- real menus start nil; stop proxy auto-creation
	w.registerEventHandler = function ( self, event, fn ) self.handlers[event] = fn end
	w.processEvent = function ( self, event )
		local fn = self.handlers[event.name]
		if fn then return fn( self, event ) end
	end
	w.addButton = function ( self, title )
		local b = proxy()
		b.title = title
		b.setActionEventName = function ( s, n ) s.action = n end
		b.disable = function ( s ) s.disabled = true end
		b.watchers = {}
		b.addElement = function ( s, e ) s.watchers[#s.watchers + 1] = e end
		self.buttons[#self.buttons + 1] = b
		return b
	end
	w.removeAllButtons = function ( self ) self.buttons = {} end
	w.rightPrompts = {}
	w.addRightButtonPrompt = function ( self, p ) self.rightPrompts[#self.rightPrompts + 1] = p end
	w.rightButtonPromptBar = { removeAllChildren = function () end }
	w.goBack = function ( self ) self.closed = true end
	return w
end
local current
local menus = {}
CoD = {
	fonts = {}, textSize = { Big = 30, Default = 20 }, BOIIOrange = { r = 1, g = 0.5, b = 0 },
	ButtonPrompt = { Height = 25, new = function ( btn, label, owner, event, a, b, c, d2, key )
		local p = proxy(); p.button, p.label, p.event, p.key = btn, label, event, key; return p
	end },
	CoD9Button = { Height = 40 },
	ButtonList = { new = function () return current.list end },
	Menu = {
		New = function ( name ) local m = widget( name ); menus[name] = m; current = m; m.list = widget( "list" ); return m end,
		NewSmallPopup = function ( name )
			local m = widget( name ); menus[name] = m; m.buttonLists = {}; current = m; m.list = widget( "list" ); return m
		end,
		ButtonPromptBack = function ( owner ) owner.closed = true end
	},
	ZMCheckpointMenu = {}
}
LUI = { createMenu = {}, Alignment = { Left = 0 }, UIText = { new = function () return proxy() end },
	UIImage = { new = function () return proxy() end }, UIElement = { new = function () return widget( "el" ) end } }
UIExpression = { DvarString = function ( _, k ) return d[k] or "" end }
Engine = { SetDvar = function ( k, v ) d[k] = tostring( v ) end, Exec = function ( _, t ) execs[#execs + 1] = t end,
	PartyGetPlayerCount = function () return 1 end, PlaySound = function () end }
function RegisterMaterial() return 0 end
function require() end
dofile( "src/ui/ui/t6/menus/zmcheckpointmenu.lua" )
dofile( "src/ui/ui/t6/menus/zmcheckpointsolo.lua" )
local C = CoD.ZMCheckpointMenu

local function seed( slot, round )
	local suffix = slot == 1 and "" or ( "_slot" .. slot )
	d["zmcp_has_zm_nuked" .. suffix] = "1"
	d["zmcp_round_zm_nuked" .. suffix] = tostring( round )
	d["zmcp_solo_zm_nuked_slot" .. slot .. "_preview"] = "1"
end
d.ui_mapname = "zm_nuked"
seed( 1, 8 ); seed( 3, 5 )

-- Backend: tombstone set, slot hidden at once, archived with seta.
assert( not C.DeleteSoloSlot( 0, "zm_bogus", 1 ) and not C.DeleteSoloSlot( 0, "zm_nuked", 5 ) )
assert( C.DeleteSoloSlot( 0, "zm_nuked", 3 ) )
assert( d.zmcp_del_zm_nuked_slot3 == "1" and d.zmcp_has_zm_nuked_slot3 == "0" and d.zmcp_round_zm_nuked_slot3 == "0" )
assert( d.zmcp_has_zm_nuked == "1" and d.zmcp_round_zm_nuked == "8", "other slots untouched" )
assert( table.concat( execs ):find( "seta zmcp_del_zm_nuked_slot3 1\n", 1, true ) )
seed( 3, 5 ); d.zmcp_del_zm_nuked_slot3 = nil

-- Page: DELETE prompt shows only for a saved slot; confirm flow removes that slot only.
local page = LUI.createMenu.ZMCheckpointSoloResume( 0 )
local buttons = function () return page.list.buttons end
assert( #buttons() == 4 and buttons()[1].title == "SLOT 1 - ROUND 8" and buttons()[2].disabled )
page:processEvent( { name = "zmcp_delete_slot", controller = 0 } ) -- nothing focused yet: ignored
assert( not menus.ZMCheckpointDeleteConfirm, "must not open without a focused saved slot" )
assert( #page.rightPrompts == 0 )
buttons()[3].watchers[1]:processEvent( { name = "gain_focus" } )
assert( #page.rightPrompts == 1 and page.rightPrompts[1].key == "DEL" and page.rightPrompts[1].label == "Delete" )
assert( page.rightPrompts[1].button == "alt1" and page.rightPrompts[1].event == "zmcp_delete_slot" )
page.openPopup = function ( self, name )
	local pop = LUI.createMenu[name]( 0 )
	pop.zmcpMessage = { setText = function ( _, t ) pop.text = t end }
	self.popup = pop
	return pop
end
page:processEvent( { name = "zmcp_delete_slot", controller = 0 } )
assert( page.popup and page.popup.zmcpSlot == 3 and page.popup.text:find( "Slot 3, round 5", 1, true ) )
-- A confirmed delete rebuilds the list without that slot and leaves the others.
page:processEvent( { name = "zmcp_delete_confirmed", slot = 3, controller = 0 } )
assert( d.zmcp_has_zm_nuked_slot3 == "0" and d.zmcp_has_zm_nuked == "1" )
assert( #buttons() == 4 and buttons()[3].title == "SLOT 3 - EMPTY" and buttons()[1].title == "SLOT 1 - ROUND 8" )
page:processEvent( { name = "zmcp_delete_confirmed", slot = 1, controller = 0 } )
for _, b in ipairs( buttons() ) do assert( b.title:find( "EMPTY" ) and b.disabled ) end
page:processEvent( { name = "zmcp_delete_slot", controller = 0 } )
assert( not page.popup.zmcpSlot or page.popup.zmcpSlot ~= 1, "no saved slot is left to delete" )

-- Confirmation popup: NO and Esc keep the save; YES reports the slot to the page.
local popup = LUI.createMenu.ZMCheckpointDeleteConfirm( 0 )
local got
local owner = { handlers = {}, processEvent = function ( _, e ) got = e end }
popup.zmcpResume, popup.zmcpSlot = owner, 2
popup:processEvent( { name = "zmcp_delete_no", controller = 0 } )
assert( got.name == "zmcp_delete_closed" and popup.closed )
popup.closed, got = nil, nil
popup:processEvent( { name = "button_prompt_back", controller = 0 } )
assert( got.name == "zmcp_delete_closed" )
popup.closed, got = nil, nil
popup:processEvent( { name = "zmcp_delete_yes", controller = 0 } )
assert( got.name == "zmcp_delete_confirmed" and got.slot == 2 and popup.closed )
print( "PASS: solo delete tombstone, slot rebuild and confirmation popup events" )
