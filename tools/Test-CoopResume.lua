-- Run with .tools/lua-validator/node_modules/.bin/fengari tools/Test-CoopResume.lua
-- Drives the shipped CO-OP RESUME page (sessions, selection, START, OPTIONS, DEL).
local d, execs, texts, recorded = {}, {}, {}, {}
local roster, localId, gameHost, partyHost, count, gameSettings
local function proxy()
	local p = {}
	return setmetatable( p, {
		__index = function ( t, k ) local v = proxy(); rawset( t, k, v ); return v end,
		__call = function () return proxy() end
	} )
end
local function widget( name )
	local w = proxy()
	w.handlers, w.menuName, w.buttons = {}, name, {}
	w.zmcpDeleteOpen, w.popup, w.closed = false, false, false
	w.registerEventHandler = function ( self, event, fn ) self.handlers[event] = fn end
	w.processEvent = function ( self, event )
		local fn = self.handlers[event.name]
		if fn then return fn( self, event ) end
	end
	w.addButton = function ( self, title )
		local b = proxy()
		b.title, b.disabled, b.alpha, b.watchers = title, false, 1, {}
		b.setActionEventName = function ( s, n ) s.action = n end
		b.disable = function ( s ) s.disabled = true end
		b.enable = function ( s ) s.disabled = false end
		b.setAlpha = function ( s, a ) s.alpha = a end
		b.addElement = function ( s, e ) s.watchers[#s.watchers + 1] = e end
		self.buttons[#self.buttons + 1] = b
		return b
	end
	w.removeAllButtons = function ( self ) self.buttons = {} end
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
	isPartyHost = function () return partyHost end,
	ButtonPrompt = { Height = 25, new = function ( btn, label, owner, event, a, b, c, d2, key )
		local p = proxy(); p.button, p.label, p.event, p.key = btn, label, event, key; return p
	end },
	CoD9Button = { Height = 40 },
	ButtonList = { new = function () return current.list end },
	Menu = {
		New = function ( name ) local m = widget( name ); menus[name] = m; current = m; m.list = widget( "list" ); return m end,
		NewSmallPopup = function ( name )
			local m = widget( name ); menus[name] = m; current = m; m.list = widget( "list" ); return m
		end,
		ButtonPromptBack = function ( owner ) owner.closed = true end
	},
	ZMCheckpointMenu = {}
}
LUI = { createMenu = {}, Alignment = { Left = 0 },
	UIText = { new = function ()
		local t = proxy()
		rawset( t, "setText", function ( s, v ) rawset( s, "text", v ) end )
		texts[#texts + 1] = t
		return t
	end },
	UIImage = { new = function () return proxy() end }, UITimer = { new = function () return proxy() end },
	UIElement = { new = function () return widget( "el" ) end } }
UIExpression = { DvarString = function ( _, k ) return d[k] or "" end, GameHost = function () return gameHost end }
Engine = { Localize = function ( s ) return s end,
	SetDvar = function ( k, v ) d[k] = tostring( v ) end, Exec = function ( _, t ) execs[#execs + 1] = t end,
	PartyGetPlayerCount = function () return count end, PlaySound = function () end,
	PartyHostIsReadyToStart = function () return false end,
	GetXUIDStringForController = function () return localId end,
	GetPlayersInLobby = function () return roster end,
	GetGametypeSetting = function ( k ) return gameSettings[k] end,
	SetGametypeSetting = function ( k, v ) gameSettings[k] = v end }
function RegisterMaterial() return 0 end
function require() end
dofile( "src/ui/ui/t6/menus/zmcheckpointmenu.lua" )
dofile( "src/ui/ui/t6/menus/zmcheckpointcoop.lua" )
dofile( "src/ui/ui/t6/menus/zmcheckpointsolo.lua" )
local C = CoD.ZMCheckpointMenu
C.Ui.AddText = function ( _, value ) recorded[#recorded + 1] = value; return proxy() end

local HOST, GUEST, THIRD = "1000000006cf5bb", "1000000006cff03", "abc"
local function seed( slot, ids, round, extra )
	local p = "zmcp_coop_zm_nuked_s" .. slot .. "_"
	d[p .. "has"], d[p .. "round"], d[p .. "host"] = "1", tostring( round ), HOST
	d[p .. "ids"], d[p .. "mode"], d[p .. "group"] = table.concat( ids, "/" ), "zstandard", "zsurvival"
	d[p .. "location"], d[p .. "mod"], d[p .. "settings"] = "nuked", "mods/zm_checkpoint", "1/1/0"
	for i, _ in ipairs( ids ) do
		d[p .. "m" .. ( i - 1 ) .. "_pts"] = tostring( 1000 * i + 110 )
		d[p .. "m" .. ( i - 1 ) .. "_w"] = "m1911_zm,galil_upgraded_zm"
		d[p .. "m" .. ( i - 1 ) .. "_p"] = i == 1 and "specialty_armorvest,specialty_quickrevive" or "-"
	end
end
local function reset()
	d = { ui_mapname = "zm_nuked", ui_gametype = "zstandard", ui_zm_gamemodegroup = "zsurvival", ui_zm_mapstartlocation = "nuked",
		fs_game = "mods/zm_checkpoint", sv_cheats = "0", sv_allowAimAssist = "1" }
	execs = {}
	roster = { { xuid = HOST, gamertag = "Sharelocked" } }
	localId, gameHost, partyHost, count = HOST, 1, true, 1
	gameSettings = { zmDifficulty = 0, magic = 0, headshotsonly = 1 }
	seed( 1, { HOST, GUEST }, 4 )
	seed( 3, { HOST, GUEST, THIRD }, 9 )
	d.zmcp_coop_name_1000000006cff03 = "wathson"
end
local function build()
	texts, recorded = {}, {}
	local page = LUI.createMenu.ZMCheckpointCoop( 0 )
	return page, texts[1]
end
local joined = function () roster = { { xuid = HOST, gamertag = "Sharelocked" }, { xuid = GUEST, gamertag = "wathsonLive" } }; count = 2 end
local function select( page, slot )
	page:processEvent( { name = "zmcp_select_slot_" .. slot } )
	page:processEvent( { name = "zmcp_rebuild" } )
end

-- Page shape: four session rows, OPTIONS, START; empty slots disabled; no selection yet.
reset()
local page, status = build()
local b = function () return page.list.buttons end
assert( #b() == 6 and b()[1].title == "SESSION 1 - ROUND 4 - 2 PLAYERS" and b()[3].title:find( "ROUND 9 - 3 PLAYERS", 1, true ) )
assert( b()[2].disabled and b()[4].disabled and b()[5].title == "OPTIONS" and b()[6].title == "START" and b()[5].disabled and b()[6].disabled )
-- Roster is incomplete: the listed rows are dimmed, not removed.
assert( b()[1].alpha < 1 and b()[3].alpha < 1, "sessions without their team are greyed" )
-- Highlighting shows per-player points, weapons, perks and offline players.
b()[1].watchers[1]:processEvent( { name = "gain_focus" } )
local all = table.concat( recorded, "|" )
assert( all:find( "SESSION 1  /  ROUND 4  /  2 PLAYERS", 1, true ) and all:find( "1110 PTS", 1, true ) and all:find( "2110 PTS", 1, true ) )
assert( all:find( "SHARELOCKED (HOST)", 1, true ) and all:find( "WATHSON  - NOT CONNECTED", 1, true ), "remembered name for offline player" )
assert( all:find( "GALIL", 1, true ) and all:find( "JUGGERNOG, QUICK REVIVE", 1, true ) and all:find( "PERKS  NONE", 1, true ) )
assert( all:find( "DIFFICULTY ORIGINAL", 1, true ) and all:find( "MAGIC ON", 1, true ) and all:find( "HEADSHOTS OFF", 1, true ) )
assert( #page.rightPrompts == 1 and page.rightPrompts[1].key == "DEL" )

-- START stays locked until the session is selected and the exact team is present.
page:processEvent( { name = "zmcp_slot_start", controller = 0 } )
assert( #execs == 0 )
select( page, 1 )
assert( b()[1].title:find( "SELECTED", 1, true ) and not b()[5].disabled and b()[6].disabled, "OPTIONS on, START still locked" )
page:processEvent( { name = "zmcp_slot_start", controller = 0 } )
assert( #execs == 0, "start refused while a player is missing" )
joined()
page:processEvent( { name = "zmcp_coop_refresh" } )
assert( not b()[6].disabled and b()[1].alpha == 1 and b()[3].alpha < 1, "only the complete session becomes startable" )
page:processEvent( { name = "zmcp_slot_start", controller = 0 } )
local launch = execs[#execs]
assert( launch:find( "set zmcp_coop_slot 1", 1, true ) and launch:find( "zmcp_coop_autoload 1", 1, true ) and launch:find( "xpartygo", 1, true ) )
assert( not launch:find( "map ", 1, true ) and page.closed )
assert( gameSettings.zmDifficulty == 1 and gameSettings.magic == 1 and gameSettings.headshotsonly == 0, "START applied the saved settings" )

-- Host and roster stay fail-closed.
reset(); joined(); page = build(); select( page, 1 )
localId = GUEST; page:processEvent( { name = "zmcp_slot_start", controller = 0 } )
assert( #execs == 0, "wrong host" )
localId = HOST; roster[2].xuid = "f00"; page:processEvent( { name = "zmcp_slot_start", controller = 0 } )
assert( #execs == 0, "replacement player" )
roster[2].xuid = GUEST; d.fs_game = "mods/other"; page:processEvent( { name = "zmcp_slot_start", controller = 0 } )
assert( #execs == 0, "other mod" )
d.fs_game = "mods/zm_checkpoint"
d.zmcp_coop_zm_nuked_s1_settings = "9/1/0"
page:processEvent( { name = "zmcp_slot_start", controller = 0 } )
assert( #execs == 0, "invalid settings" )

-- A second session launches with its own slot number and roster.
reset(); roster = { { xuid = HOST }, { xuid = GUEST }, { xuid = THIRD } }; count = 3
page = build(); select( page, 3 )
page:processEvent( { name = "zmcp_slot_start", controller = 0 } )
assert( execs[#execs]:find( "set zmcp_coop_slot 3", 1, true ) )

-- OPTIONS: stored beside the save, shown in the panel, applied at START.
reset(); joined(); page = build(); select( page, 1 )
assert( not C.ApplyCoopOptions( 0, "zm_nuked", 2, { difficulty = 1, magic = 1, headshots = 0, assist = 1, cheats = 0, perks = 0 } ), "empty slot" )
assert( not C.ApplyCoopOptions( 0, "zm_nuked", 1, { difficulty = 1, magic = 1, headshots = 0, assist = 1, cheats = 5, perks = 0 } ), "invalid" )
page.openPopup = function ( self, name )
	local pop = LUI.createMenu[name]( 0 )
	self.popup = pop
	return pop
end
page:processEvent( { name = "zmcp_slot_options", controller = 0 } )
local options = page.popup
assert( options and options.menuName == "ZMCheckpointCoopOptions" and #options.list.selectors == 6, "six selectors" )
assert( options.list.selectors[1].value == "1" and options.list.selectors[3].value == "0" )
d.zmcp_edit_coop_difficulty, d.zmcp_edit_coop_magic, d.zmcp_edit_coop_headshots = "0", "0", "1"
d.zmcp_edit_coop_assist, d.zmcp_edit_coop_cheats, d.zmcp_edit_coop_perks = "0", "1", "1"
options:processEvent( { name = "zmcp_options_apply", controller = 0 } )
assert( d.zmcp_ovr_coop_zm_nuked_s1_set == "1" and d.zmcp_ovr_coop_zm_nuked_s1_perks == "1" and d.zmcp_ovr_coop_zm_nuked_s1_cheats == "1" )
assert( d.zmcp_coop_zm_nuked_s1_settings == "0/0/1" and d.zmcp_coop_zm_nuked_settings == "0/0/1", "published settings follow the override" )
assert( d.zmcp_coop_zm_nuked_s3_settings == "1/1/0", "other session untouched" )
local s = table.concat( execs )
assert( s:find( "seta zmcp_ovr_coop_zm_nuked_s1_cheats 1\n", 1, true ) and not s:find( "CHECKPOINT", 1, true ) )
page:processEvent( { name = "zmcp_coop_refresh" } )
page:processEvent( { name = "zmcp_slot_start", controller = 0 } )
assert( d.sv_cheats == "1" and d.sv_allowAimAssist == "0" and d.zmcp_all_perks == "1", "assist, cheats, perks applied at START" )
assert( gameSettings.zmDifficulty == 0 and gameSettings.magic == 0 and gameSettings.headshotsonly == 1 )

-- DEL: confirmation, tombstone for that session only, legacy dvars for session 1.
reset(); joined(); page = build()
b()[3].watchers[1]:processEvent( { name = "gain_focus" } )
page.openPopup = function ( self, name )
	local pop = LUI.createMenu[name]( 0 )
	pop.zmcpMessage = { setText = function ( _, t ) pop.text = t end }
	self.popup = pop
	return pop
end
page:processEvent( { name = "zmcp_delete_slot", controller = 0 } )
assert( page.popup.zmcpSlot == 3 and page.popup.text:find( "session 3, round 9", 1, true ) )
page:processEvent( { name = "zmcp_delete_confirmed", slot = 3, controller = 0 } )
assert( d.zmcp_del_coop_zm_nuked_s3 == "1" and d.zmcp_coop_zm_nuked_s3_has == "0" and d.zmcp_coop_zm_nuked_s1_has == "1" )
assert( #b() == 6 and b()[3].disabled and b()[3].title == "SESSION 3 - EMPTY" and not b()[1].disabled )
assert( d.zmcp_del_coop_zm_nuked_s1 == nil and not C.DeleteCoopSession( 0, "zm_nuked", 5 ) and not C.DeleteCoopSession( 0, "zm_bogus", 1 ) )
d.zmcp_coop_zm_nuked_has = "1"
assert( C.DeleteCoopSession( 0, "zm_nuked", 1 ) and d.zmcp_coop_zm_nuked_has == "0" and d.zmcp_del_coop_zm_nuked_s1 == "1" )

-- Guests and empty hosts see an explanation, never a launchable row.
reset()
d.zmcp_coop_zm_nuked_s1_has, d.zmcp_coop_zm_nuked_s3_has = "0", "0"
page, status = build()
assert( status.text:find( "host PC that used Save & Exit", 1, true ) and b()[5].disabled and b()[6].disabled )
print( "PASS: co-op sessions list, greyed rows, details, select/START gate, OPTIONS, DEL, fail-closed host and roster" )
