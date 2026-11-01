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
	commands = {}
	CoD.ZMCheckpointMenu.OpenUpdater( menu, { controller = 0 } )
	local at
	for i, command in ipairs( commands ) do
		if command:find( "^zmcp_update_request_" ) then at = i end
	end
	assert( at, "marker not sent" )
	local id = commands[at]:match( "^zmcp_update_request_20261028_(%d+)\n$" )
	assert( id and #id == 15, "request marker must contain exactly 15 digits" )
	assert( id == CoD.ZMCheckpointMenu.PendingUpdateRequestId )
	-- Padding after the marker must exceed the game's 4 KB log block, and must
	-- never contain another marker.
	local padding = 0
	for i = at + 1, #commands do
		assert( not commands[i]:find( "zmcp_update_", 1, true ), "padding must not look like a marker" )
		padding = padding + #commands[i]
	end
	assert( padding >= 4096 * 1.5, "log flush padding too small: " .. padding )
	return id
end

local first = request()
local second = request()
assert( first ~= second, "request IDs must change between checks" )
CoD.ZMCheckpointMenu.UpdateRequestCounter = 999999
assert( #request() == 15, "counter rollover must retain a digit-only ID" )
print( "PASS: update request markers are fixed-width digits" )
