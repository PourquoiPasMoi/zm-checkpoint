-- This module is deliberately separate from ZMCheckpointMenu. The frontend
-- loads and caches that common module before T6.HUD.class exists. InGameMenus
-- requires this file only after the real pause-menu class has been created,
-- guaranteeing that both the injected row and its action handler are hooked.

require( "T6.Menus.ZMCheckpointMenu" )

local C = CoD.ZMCheckpointMenu

-- The requested 0 keys control only this client's numeric zombie counter.
Engine.Exec( 0, "bind 0 zmcp_counter_toggle\nbind KP_INS zmcp_counter_toggle\n" )

if not C.InGameHooked then
	C.InGameHooked = true

	if CoD.Class ~= nil and CoD.Class.AddButton ~= nil and CoD.Class.PrepareClassButtonList ~= nil then
		local addButton = CoD.Class.AddButton
		local prepareList = CoD.Class.PrepareClassButtonList
		local building = false

		CoD.Class.AddButton = function ( menu, label, action, disabled )
			if building and action == "open_options" and C.IsSupportedMap( true ) then
				building = false
				addButton( menu, "SAVE & EXIT", "zmcp_save_exit", false )
				menu.zmcpButtonAdded = true
			end
			return addButton( menu, label, action, disabled )
		end

		CoD.Class.PrepareClassButtonList = function ( controller, menu )
			building = true
			prepareList( controller, menu )
			building = false
		end
	end

	local createClass = LUI.createMenu.class
	if createClass ~= nil then
		LUI.createMenu.class = function ( controller, userData )
			local menu = createClass( controller, userData )
			-- A server-observed capability handshake; retries while pause is open.
			local hello = function ()
				Engine.SendMenuResponse( controller, C.MenuResponseName, "hello_040" )
			end
			hello()
			menu:registerEventHandler( "zmcp_hello", hello )
			menu:addElement( LUI.UITimer.new( 1000, "zmcp_hello", false ) )
			menu:registerEventHandler( "zmcp_save_exit", C.SaveAndExit )
			if C.IsSupportedMap( true ) and not menu.zmcpButtonAdded then
				C.AddFallbackButton( menu, controller )
			end
			return menu
		end
	end
end
