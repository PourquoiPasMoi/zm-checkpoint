-- Run with .tools/lua-validator/node_modules/.bin/fengari tools/Test-CoopLobby.lua
-- Exercises the actual shipped Lua predicates and launch action with engine mocks.
local d, roster, localId, gameHost, partyHost, launching, count, commands
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
 GetGametypeSetting = function ( key ) return key == "magic" and 1 or 0 end,
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
check("consumed checkpoint",false,function() d.zmcp_coop_zm_nuked_has="0" end)
check("duplicate saved roster",false,function() d.zmcp_coop_zm_nuked_ids="aa/aa" end)
check("numeric ID precision refused",false,function() roster[2].xuid=12345 end)
check("stale lobby count",false,function() count=3 end)
check("already launching",false,function() launching=true end)
check("missing API fails closed",false,function() Engine.GetPlayersInLobby=function() error("unavailable") end end)
assert(C.NormalizeId("000000000000000A")=="a")
assert(C.NormalizeId("0")==nil)
print("PASS: "..total.." co-op lobby and launch cases; 64-bit IDs kept as strings")
