-- Exercise the shipped menu's request marker without launching the game UI.
local commands = {}
CoD = { ZMCheckpointMenu = { DvarString = function () return "1" end } }
LUI = { createMenu = {} }
Engine = {
	Exec = function ( _, command ) commands[#commands + 1] = command end,
	SetDvar = function () end
}
dofile( "src/ui/ui/t6/menus/zmcheckpointupdater.lua" )
local menu = { openPopup = function () end }

local function request()
	CoD.ZMCheckpointMenu.OpenUpdater( menu, { controller = 0 } )
	local marker = commands[#commands]
	local id = marker:match( "^zmcp_update_request_20261028_(%d+)\n$" )
	assert( id and #id == 15, "request marker must contain exactly 15 digits" )
	assert( id == CoD.ZMCheckpointMenu.PendingUpdateRequestId )
	return id
end

local first = request()
local second = request()
assert( first ~= second, "request IDs must change between checks" )
CoD.ZMCheckpointMenu.UpdateRequestCounter = 999999
assert( #request() == 15, "counter rollover must retain a digit-only ID" )
print( "PASS: update request markers are fixed-width digits" )
