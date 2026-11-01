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
	w.zmcpDeleteOpen, w.popup, w.removedAll = false, false, false -- real menus start nil; stop proxy auto-creation
	w.registerEventHandler = function ( self, event, fn ) self.handlers[event] = fn end
	w.processEvent = function ( self, event )
		local fn = self.handlers[event.name]
		if fn then return fn( self, event ) end
	end
	w.addButton = function ( self, title )
		local b = proxy()
		b.title, b.disabled = title, false
		b.setActionEventName = function ( s, n ) s.action = n end
		b.disable = function ( s ) s.disabled = true end
		b.watchers = {}
		b.addElement = function ( s, e ) s.watchers[#s.watchers + 1] = e end
		self.buttons[#self.buttons + 1] = b
		return b
	end
	w.removeAllButtons = function ( self ) self.buttons, self.removedAll = {}, true end
	w.removeElement = function ( self, el )
		for i, b in ipairs( self.buttons ) do
			if b == el then table.remove( self.buttons, i ) break end
		end
	end
	w.selectElementIndex = function ( self, i ) self.selectedIndex = i end
	w.selectors = {}
	w.addDvarLeftRightSelector = function ( self, controller, name, dvar )
		local sel = { name = name, dvar = dvar, choices = {}, value = d[dvar] }
		sel.addChoice = function ( s, c, label, value ) s.choices[#s.choices + 1] = { label, value } end
		self.selectors[#self.selectors + 1] = sel
		return sel
	end
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
	ButtonList = { new = function ()
		local l = widget( "list" )
		current.lists[#current.lists + 1] = l
		if current.list == false then current.list = l end
		return l
	end },
	Menu = {
		New = function ( name ) local m = widget( name ); menus[name] = m; current = m; m.lists, m.list = {}, false; return m end,
		NewSmallPopup = function ( name )
			local m = widget( name ); menus[name] = m; m.buttonLists = {}; current = m; m.lists = {}; m.list = widget( "list" ); m.lists[1] = m.list; return m
		end,
		ButtonPromptBack = function ( owner ) owner.closed = true end
	},
	ZMCheckpointMenu = {}
}
LUI = { createMenu = {}, Alignment = { Left = 0 }, UIText = { new = function () return proxy() end },
	UIImage = { new = function () return proxy() end }, UITimer = { new = function () return proxy() end }, UIElement = { new = function () return widget( "el" ) end } }
UIExpression = { DvarString = function ( _, k ) return d[k] or "" end }
Engine = { Localize = function ( s ) return s end, SetDvar = function ( k, v ) d[k] = tostring( v ) end, Exec = function ( _, t ) execs[#execs + 1] = t end,
	PartyGetPlayerCount = function () return 1 end, PlaySound = function () end }
function RegisterMaterial() return 0 end
function require() end
dofile( "src/ui/ui/t6/menus/zmcheckpointmenu.lua" )
dofile( "src/ui/ui/t6/menus/zmcheckpointsolo.lua" )
local C = CoD.ZMCheckpointMenu

-- Resume page: lists[1] holds OPTIONS and START, lists[2] slots 1,3,5,7, lists[3] slots 2,4,6,8.
local function slotBtn( p, n ) return p.lists[n % 2 == 1 and 2 or 3].buttons[math.ceil( n / 2 )] end

local function seed( slot, round )
	local suffix = slot == 1 and "" or ( "_slot" .. slot )
	d["zmcp_has_zm_nuked" .. suffix] = "1"
	d["zmcp_round_zm_nuked" .. suffix] = tostring( round )
	d["zmcp_solo_zm_nuked_slot" .. slot .. "_preview"] = "1"
end
d.ui_mapname = "zm_nuked"
seed( 1, 8 ); seed( 3, 5 )

-- Backend: tombstone set, slot hidden at once, archived with seta.
assert( not C.DeleteSoloSlot( 0, "zm_bogus", 1 ) and not C.DeleteSoloSlot( 0, "zm_nuked", 9 ) )
assert( C.SoloSlotCount == 8 )
assert( C.DeleteSoloSlot( 0, "zm_nuked", 3 ) )
assert( d.zmcp_del_zm_nuked_slot3 == "1" and d.zmcp_has_zm_nuked_slot3 == "0" and d.zmcp_round_zm_nuked_slot3 == "0" )
assert( d.zmcp_has_zm_nuked == "1" and d.zmcp_round_zm_nuked == "8", "other slots untouched" )
assert( table.concat( execs ):find( "seta zmcp_del_zm_nuked_slot3 1\n", 1, true ) )
seed( 3, 5 ); d.zmcp_del_zm_nuked_slot3 = nil

-- Page: DELETE prompt shows only for a saved slot; confirm flow removes that slot only.
local page = LUI.createMenu.ZMCheckpointSoloResume( 0 )
local actions = function () return page.list.buttons end
assert( #actions() == 2 and actions()[1].title == "OPTIONS" and actions()[2].title == "START" and actions()[1].disabled and actions()[2].disabled )
assert( #page.lists == 3 and #page.lists[2].buttons == 4 and #page.lists[3].buttons == 4, "eight slots in two columns" )
assert( slotBtn( page, 1 ).title == "SLOT 1 - ROUND 8" and slotBtn( page, 2 ).disabled and slotBtn( page, 8 ).title == "SLOT 8 - EMPTY" )
assert( slotBtn( page, 1 ).navigation.right == slotBtn( page, 2 ) and slotBtn( page, 4 ).navigation.left == slotBtn( page, 3 ), "left/right between a row's two slots" )
assert( slotBtn( page, 3 ).navigation.down == actions()[1], "down from the last saved slot of a column reaches OPTIONS" )
page:processEvent( { name = "zmcp_delete_slot", controller = 0 } ) -- nothing focused yet: ignored
assert( not menus.ZMCheckpointDeleteConfirm, "must not open without a focused saved slot" )
assert( #page.rightPrompts == 0 )
slotBtn( page, 3 ).watchers[1]:processEvent( { name = "gain_focus" } )
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
for _, l in ipairs( page.lists ) do assert( not l.removedAll, "rebuild must not use removeAllButtons (shared hint element)" ) end
assert( #actions() == 2 and slotBtn( page, 3 ).title == "SLOT 3 - EMPTY" and slotBtn( page, 1 ).title == "SLOT 1 - ROUND 8" )
page:processEvent( { name = "zmcp_delete_confirmed", slot = 1, controller = 0 } )
for i = 1, 8 do assert( slotBtn( page, i ).title:find( "EMPTY" ) and slotBtn( page, i ).disabled ) end
assert( actions()[1].disabled and actions()[2].disabled, "OPTIONS and START need a selected slot" )
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
-- OPTIONS: per-save overrides are stored in dvars; the save itself is never touched.
d = { ui_mapname = "zm_nuked" }
execs = {}
local function seedFull( slot )
	seed( slot, 6 )
	local pre = "zmcp_solo_zm_nuked_slot" .. slot .. "_"
	d[pre .. "settings"], d[pre .. "difficulty"], d[pre .. "magic"] = "1", "0", "1"
	d[pre .. "headshots"], d[pre .. "assist"], d[pre .. "cheats"] = "0", "1", "1"
	d[pre .. "mode"], d[pre .. "group"], d[pre .. "location"] = "zclassic", "zclassic", "nuked"
end
seedFull( 2 ); seed( 4, 3 ) -- slot 4 is an older save without SETTINGS
local page2 = LUI.createMenu.ZMCheckpointSoloResume( 0 )
local page2Process = page2.processEvent
local btns = function () return page2.list.buttons end
assert( #btns() == 2 and btns()[1].title == "OPTIONS" and btns()[2].title == "START" )
assert( btns()[1].disabled and btns()[2].disabled, "greyed out until a slot is selected" )
assert( slotBtn( page2, 2 ).action == "zmcp_select_slot_2", "clicking a slot selects it instead of resuming" )
page2:processEvent( { name = "zmcp_slot_options", controller = 0 } ) -- nothing selected: ignored
page2:processEvent( { name = "zmcp_slot_start", controller = 0 } )
assert( #execs == 0 and not C.OptionsTarget, "no start or options without a selection" )
slotBtn( page2, 2 ).watchers[1]:processEvent( { name = "gain_focus" } )
assert( #page2.rightPrompts == 1 )
page2:processEvent( { name = "zmcp_select_slot_2", controller = 0 } )
page2:processEvent( { name = "zmcp_rebuild" } )
assert( slotBtn( page2, 2 ).title == "> SLOT 2 - ROUND 6" and not btns()[1].disabled and not btns()[2].disabled )
assert( page2.lists[3].selectedIndex == 1, "focus returns to the selected slot" )
btns()[2].watchers[1]:processEvent( { name = "gain_focus" } )
page2.openPopup = function ( self, name ) self.opened = name; return LUI.createMenu[name]( 0 ) end
page2:processEvent( { name = "zmcp_slot_options", controller = 0 } )
assert( page2.opened == "ZMCheckpointSoloOptions" and C.OptionsTarget.slot == 2 )
local opts = LUI.createMenu.ZMCheckpointSoloOptions( 0 )
local rows = opts.list.selectors
assert( #rows == 8 and rows[1].dvar == "zmcp_edit_difficulty" and rows[6].dvar == "zmcp_edit_perks" )
assert( rows[7].dvar == "zmcp_edit_healthcap" and rows[8].dvar == "zmcp_edit_autosave" and #rows[8].choices == 9 and rows[8].choices[9][2] == 8 )
assert( d.zmcp_edit_healthcap == "0" and d.zmcp_edit_autosave == "0", "new rows start from the lobby values" )
assert( d.zmcp_edit_difficulty == "0" and d.zmcp_edit_cheats == "1" and d.zmcp_edit_perks == "0" )
assert( #opts.list.buttons == 2 and opts.list.buttons[1].title == "APPLY CHANGES" )
-- Apply: disable cheats, enable unlimited perks.
d.zmcp_edit_cheats, d.zmcp_edit_perks = "0", "1"
d.zmcp_edit_healthcap, d.zmcp_edit_autosave = "50", "3"
local applied
page2.processEvent = function ( self, e ) applied = e end
opts:processEvent( { name = "zmcp_options_apply", controller = 0 } )
assert( opts.closed and applied.name == "zmcp_options_applied" and applied.slot == 2 )
assert( d.zmcp_ovr_zm_nuked_slot2_set == "1" and d.zmcp_ovr_zm_nuked_slot2_cheats == "0" and d.zmcp_ovr_zm_nuked_slot2_perks == "1" )
assert( d.zmcp_solo_zm_nuked_slot2_cheats == "0" and d.zmcp_solo_zm_nuked_slot2_difficulty == "0", "published values follow" )
assert( d.zmcp_has_zm_nuked_slot2 == "1" and d.zmcp_round_zm_nuked_slot2 == "6", "save metadata untouched" )
local m = C.SoloSlotMeta( "zm_nuked", 2 )
assert( m.cheats == 0 and m.unlimited == 1 and m.magic == 1 )
assert( d.zmcp_ovr_zm_nuked_slot2_healthcap == "50" and d.zmcp_ovr_zm_nuked_slot2_autosave == "3" and m.healthcap == 50 and m.autosave == 3 )
-- Resume applies the saved-with-override settings and the perks choice.
d.ui_gametype, d.ui_zm_gamemodegroup, d.ui_zm_mapstartlocation = "zclassic", "zclassic", "nuked"
C.CoopValue = function ( v ) return v end
local settings = {}
Engine.SetGametypeSetting = function ( k, v ) settings[k] = v end
Engine.GetGametypeSetting = function ( k ) return settings[k] end
d.sv_allowAimAssist, d.sv_cheats = "1", "1"
execs = {}
page2.processEvent = page2Process
page2:processEvent( { name = "zmcp_slot_start", controller = 0 } ) -- START resumes the selected slot
assert( table.concat( execs ):find( "set zmcp_solo_slot 2", 1, true ) and table.concat( execs ):find( "xpartygo", 1, true ) )
assert( d.sv_cheats == "0" and d.zmcp_all_perks == "1", "override cheats off, perks on" )
assert( d.zmcp_health_cap == "50" and d.zmcp_autosave == "3", "per-save health cap and autosave slot applied at START" )
assert( table.concat( execs ):find( "seta zmcp_health_cap 50", 1, true ) and table.concat( execs ):find( "seta zmcp_autosave 3", 1, true ) )
assert( table.concat( execs ):find( "seta zmcp_all_perks 1", 1, true ) )
-- Older save: only perks can change and no settings override is written.
C.OptionsTarget = { map = "zm_nuked", slot = 4 }
local old = LUI.createMenu.ZMCheckpointSoloOptions( 0 )
assert( #old.list.selectors == 3 and old.list.selectors[1].dvar == "zmcp_edit_perks" and old.list.selectors[2].dvar == "zmcp_edit_healthcap" )
assert( C.ApplySoloOptions( 0, "zm_nuked", 4, { perks = 1 } ) )
assert( d.zmcp_ovr_zm_nuked_slot4_perks == "1" and d.zmcp_ovr_zm_nuked_slot4_set == nil )
-- Invalid values are refused without writing anything.
local before = {}
for k, v in pairs( d ) do before[k] = v end
assert( not C.ApplySoloOptions( 0, "zm_nuked", 2, { difficulty = 2, magic = 1, headshots = 0, assist = 1, cheats = 0, perks = 0 } ) )
assert( not C.ApplySoloOptions( 0, "zm_nuked", 3, { perks = 1 } ), "empty slot" )
assert( not C.ApplySoloOptions( 0, "zm_nuked", 4, { perks = 1, healthcap = 300 } ) and not C.ApplySoloOptions( 0, "zm_nuked", 4, { perks = 1, autosave = 9 } ) )
assert( not C.ApplySoloOptions( 0, "zm_nuked", 9, { perks = 1 } ), "slot 9 does not exist" )
for k, v in pairs( d ) do assert( before[k] == v ) end
-- Deleting a slot also drops its override.
C.DeleteSoloSlot( 0, "zm_nuked", 2 )
assert( d.zmcp_ovr_zm_nuked_slot2_set == "0" and d.zmcp_ovr_zm_nuked_slot2_perks == "-1" )
assert( d.zmcp_ovr_zm_nuked_slot2_healthcap == "-1" and d.zmcp_ovr_zm_nuked_slot2_autosave == "-1" )
assert( C.SoloSlotMeta( "zm_nuked", 2 ).unlimited == nil and C.SoloSlotMeta( "zm_nuked", 2 ).healthcap == nil )
-- SAVE popup: the same eight-slot grid, odd slots left and even slots right.
d = { mapname = "zm_nuked", ui_mapname = "zm_nuked" }
seed( 1, 8 ); seed( 8, 2 )
local save = LUI.createMenu.ZMCheckpointSoloSave( 0 )
assert( #save.lists == 2 and #save.lists[1].buttons == 4 and #save.lists[2].buttons == 4 )
assert( save.lists[1].buttons[1].action == "zmcp_save_slot_1" and save.lists[2].buttons[1].action == "zmcp_save_slot_2" )
assert( save.lists[2].buttons[4].action == "zmcp_save_slot_8" and save.lists[2].buttons[4].title == "SLOT 8 - ROUND 2" )
assert( save.lists[1].buttons[2].navigation.right == save.lists[2].buttons[2], "slot 3 moves right to slot 4" )
print( "PASS: solo delete tombstone, slot rebuild and confirmation popup events" )
print( "PASS: solo OPTIONS page, overrides, perks on Resume, older saves, invalid input" )
