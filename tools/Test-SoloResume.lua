-- Run with .tools/lua-validator/node_modules/.bin/fengari tools/Test-SoloResume.lua
-- Exercises the shipped solo Resume action without starting Plutonium.
local d, settings, commands, count = {}, {}, {}, 1
CoD = { ZMCheckpointMenu = {} }
LUI = { createMenu = {} }
UIExpression = { DvarString = function (_, key) return d[key] or "" end }
local C = CoD.ZMCheckpointMenu
Engine = {
 PartyGetPlayerCount = function () return count end,
 SetGametypeSetting = function (key, value) settings[key] = value end,
 GetGametypeSetting = function (key) return settings[key] end,
 SetDvar = function (key, value) d[key] = tostring(value) end,
 Exec = function (_, text) commands[#commands + 1] = text end,
 PlaySound = function () end
}
function require() end
dofile("src/ui/ui/t6/menus/zmcheckpointmenu.lua")
function C.CoopValue(value) return value == "" and "-" or value end
dofile("src/ui/ui/t6/menus/zmcheckpointsolo.lua")
local function reset(slot)
 d = { ui_mapname="zm_nuked", ui_gametype="zclassic", ui_zm_gamemodegroup="zclassic",
       ui_zm_mapstartlocation="nuked", sv_allowAimAssist="1", sv_cheats="0" }
 settings = { zmDifficulty=0, magic=1, headshotsonly=0 }
 commands = {}
 count = 1
 local prefix = "zmcp_solo_zm_nuked_slot" .. slot .. "_"
 d["zmcp_has_zm_nuked" .. (slot == 1 and "" or "_slot" .. slot)] = "1"
 d[prefix .. "settings"] = "1"
 d[prefix .. "difficulty"] = "1"
 d[prefix .. "magic"] = "0"
 d[prefix .. "headshots"] = "1"
 d[prefix .. "assist"] = "0"
 d[prefix .. "cheats"] = "1"
 d[prefix .. "mode"] = "zclassic"
 d[prefix .. "group"] = "zclassic"
 d[prefix .. "location"] = "nuked"
 return prefix
end
local prefix = reset(3)
local ok, reason = C.Resume({}, {controller=0}, 3)
assert(ok, tostring(reason))
assert(settings.zmDifficulty == 1 and settings.magic == 0 and settings.headshotsonly == 1)
assert(d.sv_allowAimAssist == "0" and d.sv_cheats == "1")
assert(table.concat(commands):find("set zmcp_solo_slot 3", 1, true))
assert(table.concat(commands):find("xpartygo", 1, true))
assert(not table.concat(commands):find("map ", 1, true))
reset(2)
d.ui_zm_mapstartlocation = "town"
ok = C.Resume({}, {controller=0}, 2)
assert(not ok and #commands == 0)
reset(2)
d["zmcp_solo_zm_nuked_slot2_cheats"] = "invalid"
ok = C.Resume({}, {controller=0}, 2)
assert(not ok and #commands == 0)
reset(1)
d["zmcp_solo_zm_nuked_slot1_settings"] = "0"
ok = C.Resume({}, {controller=0}, 1)
assert(ok and table.concat(commands):find("set zmcp_solo_slot 1", 1, true))
reset(4)
count = 2
ok = C.Resume({}, {controller=0}, 4)
assert(not ok and #commands == 0)
print("PASS: solo slot Resume, five settings, legacy slot, and launch guards")
