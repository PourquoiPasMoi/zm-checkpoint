-- Run with .tools/lua-validator/node_modules/.bin/fengari tools/Test-WeaponIcons.lua
-- Every weapon name the game can save must map to the right stock front-end material.
local function proxy()
	return setmetatable( {}, { __index = function ( t, k ) local v = proxy(); rawset( t, k, v ); return v end, __call = function () return proxy() end } )
end
CoD = { ZMCheckpointMenu = {}, fonts = {}, BOIIOrange = { r = 1, g = 0, b = 0 } }
LUI = { createMenu = {} }
function require() end
dofile( "src/ui/ui/t6/menus/zmcheckpointsolo.lua" )
local material = CoD.ZMCheckpointMenu.Ui.WeaponMaterial
local expected = {
	saiga12_zm = "saiga12", fnfal_zm = "fal", fnfal_upgraded_zm = "fal", mp5k_zm = "mp5", mp5k_upgraded_zm = "mp5",
	beretta93r_zm = "baretta", dsr50_zm = "dsr1", barretm82_zm = "m82a", usrpg_zm = "rpg", m32_zm = "m32gl",
	qcw05_zm = "qcw", fivesevendw_zm = "five_seven", fiveseven_zm = "five_seven", m16_gl_upgraded_zm = "m16",
	ak74u_extclip_zm = "ak74u", ["galil_upgraded_zm+reflex"] = "galil", ["xm8_zm+dualoptic"] = "xm8",
	m1911_zm = "1911", ray_gun_zm = "zm_weapons_raygun", jetgun_zm = "zm_weapons_jetgun"
}
for name, key in pairs( expected ) do
	local found = material( name )
	assert( found and found:find( key, 1, true ), name .. " -> " .. tostring( found ) )
end
-- Weapons with no stock front-end material show text only; the Mark II must not borrow the Ray Gun art.
for _, name in ipairs( { "raygun_mark2_zm", "hk416_zm", "lsat_zm", "svu_zm", "thompson_zm", "unknown" } ) do
	assert( material( name ) == nil, name .. " should have no icon" )
end
print( "PASS: weapon icon names map to stock front-end materials, including real game weapon names" )
