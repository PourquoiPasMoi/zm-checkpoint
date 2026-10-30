-- Run with .tools/lua-validator/node_modules/.bin/fengari tools/Test-CoopLobby.lua
-- Exercises the actual shipped Lua predicates and launch action with engine mocks.
local d, roster, localId, gameHost, partyHost, launching, count, commands, gameSettings
CoD = { ZMCheckpointMenu = {}, isPartyHost = function () return partyHost end }
LUI = { createMenu = {} }
local C = CoD.ZMCheckpointMenu
C.SupportedMaps = { zm_nuked = "NUKETOWN" }
C.CurrentMap = function () return "zm_nuked" end
C.DvarString = function ( key ) return d[key] or "" end
Engine = {
 GetXUIDStringForController = function () return localId end,
 GetPlayersInLobby = function () return roster end,
 PartyGetPlayerCount = function () return count end,
 GetGametypeSetting = function ( key ) return gameSettings[key] end,
 SetGametypeSetting = function ( key, value ) gameSettings[key] = value end,
 PartyHostIsReadyToStart = function () return launching end,
 Exec = function (_, command) commands[#commands + 1] = command end
}
UIExpression = { GameHost = function () return gameHost end }
dofile("src/ui/ui/t6/menus/zmcheckpointcoop.lua")
local function reset()
 d = { ui_gametype="zclassic", ui_zm_gamemodegroup="zclassic", ui_zm_mapstartlocation="nuked", fs_game="mods/zm_checkpoint" }
 local values = { has="1", host="abcdef1234567890", ids="abcdef1234567890/123456789abcdef0", round="12", mode="zclassic", group="zclassic", location="nuked", mod="mods/zm_checkpoint", settings="0/1/0" }
 for key,value in pairs(values) do d["zmcp_coop_zm_nuked_"..key]=value end
 roster = { {xuid="abcdef1234567890",gamertag="Host"}, {xuid="123456789abcdef0",gamertag="Guest"} }
 localId="abcdef1234567890"; gameHost=1; partyHost=true; launching=false; count=2; commands={}
 gameSettings={zmDifficulty=0,magic=1,headshotsonly=0}
end
local total=0
local function check(name, expected, change)
 reset(); if change then change() end
 local ready,message=C.SafeCoopStatus(0)
 assert(ready==expected, name..": "..tostring(message))
 local closed=false
 C.CoopResume({goBack=function() closed=true end},{controller=0})
 assert((#commands==1)==expected, name..": launch gate")
 assert(closed==expected, name..": close gate")
 if expected then
  assert(string.find(commands[1],"xpartygo",1,true))
  assert(not string.find(commands[1],"map ",1,true))
 end
 total=total+1
end
check("matching team",true)
check("three players",true,function() roster[3]={xuid="aaa"};count=3;d.zmcp_coop_zm_nuked_ids=d.zmcp_coop_zm_nuked_ids.."/aaa" end)
check("four players",true,function() roster[3]={xuid="aaa"};roster[4]={xuid="bbb"};count=4;d.zmcp_coop_zm_nuked_ids=d.zmcp_coop_zm_nuked_ids.."/aaa/bbb" end)
check("different connection order",true,function() roster[1],roster[2]=roster[2],roster[1] end)
check("renamed player",true,function() roster[2].gamertag="New name" end)
check("hex formatting",true,function() roster[2].xuid="0x123456789ABCDEF0" end)
check("decimal lobby XUIDs",true,function()
 roster[1].xuid="12379813812177893520"; roster[2].xuid="1311768467463790320"
 localId="12379813812177893520"
end)
check("mixed decimal and hex lobby XUIDs",true,function()
 roster[1].xuid="12379813812177893520"; localId="12379813812177893520"
end)
check("missing player",false,function() roster[2]=nil;count=1 end)
check("extra player",false,function() roster[3]={xuid="f00"};count=3 end)
check("replacement player",false,function() roster[2].xuid="f00" end)
check("duplicate ID",false,function() roster[2].xuid=roster[1].xuid end)
check("wrong host account",false,function() localId=roster[2].xuid end)
check("host migration",false,function() gameHost=0 end)
check("wrong party host",false,function() partyHost=false end)
check("wrong map variant",false,function() d.ui_zm_mapstartlocation="town" end)
check("wrong mode",false,function() d.ui_gametype="zstandard" end)
check("wrong mod",false,function() d.fs_game="mods/dlc5" end)
check("changed settings",false,function() d.zmcp_coop_zm_nuked_settings="1/1/0" end)
reset()
gameSettings.magic=0
local ready,message,details,canRestore=C.SafeCoopStatus(0)
assert(not ready and canRestore and message=="Restore saved game settings to unlock Resume.")
assert(C.ApplyCoopSettings(0))
assert(C.SafeCoopStatus(0))
assert(gameSettings.magic==1)
reset()
-- Exact mode, location and IDs from the host checkpoint inspected on 2026-10-30.
d.ui_gametype="zstandard"; d.ui_zm_gamemodegroup="zsurvival"
d.zmcp_coop_zm_nuked_mode="zstandard"; d.zmcp_coop_zm_nuked_group="zsurvival"
d.zmcp_coop_zm_nuked_host="1000000006cf5bb"
d.zmcp_coop_zm_nuked_ids="1000000006cf5bb/1000000006cff03"
localId="1000000006cf5bb"
roster={{xuid=localId,gamertag="Sharelocked"},{xuid="1000000006cff03",gamertag="wathson"}}
gameSettings.magic=0
assert(select(4,C.SafeCoopStatus(0)))
assert(C.ApplyCoopSettings(0) and C.SafeCoopStatus(0))
check("consumed checkpoint",false,function() d.zmcp_coop_zm_nuked_has="0" end)
check("duplicate saved roster",false,function() d.zmcp_coop_zm_nuked_ids="aa/aa" end)
check("numeric ID precision refused",false,function() roster[2].xuid=12345 end)
check("stale lobby count",false,function() count=3 end)
check("already launching",false,function() launching=true end)
check("missing API fails closed",false,function() Engine.GetPlayersInLobby=function() error("unavailable") end end)
assert(C.NormalizeId("000000000000000A")=="a")
assert(C.NormalizeId("0")==nil)
assert(C.DecimalIdToHex("12379813812177893520")=="abcdef1234567890")
assert(C.DecimalIdToHex("18446744073709551615")=="ffffffffffffffff")
assert(C.DecimalIdToHex("18446744073709551616")==nil)
assert(C.DecimalIdToHex("0")==nil)
print("PASS: "..total.." co-op lobby and launch cases; 64-bit IDs kept as strings")
