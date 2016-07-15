MenuUI = MenuUI or class()
function MenuUI:init( params )
	local ws = managers.gui_data:create_fullscreen_workspace()   
 	ws:connect_keyboard(Input:keyboard())  
    ws:connect_mouse(Input:mouse())  
    params.position = params.position or "Left"
	self._fullscreen_ws = ws
    self._fullscreen_ws_pnl = ws:panel():panel({alpha = 0})
    self._options = {}
    self._menus = {}

    if params.w == "full" then
        params.w = self._fullscreen_ws_pnl:w()
    elseif params.w == "half" then
        params.w = self._fullscreen_ws_pnl:w() / 2
    end    
    self._panel = self._fullscreen_ws_pnl:panel({
        name = "menu_panel",
        halign = "center", 
        align = "center",
        layer = params.layer or 500,
        h = params.h or self._fullscreen_ws_pnl:h(),
        w = params.w or self._fullscreen_ws_pnl:w(),
    })      
    self._panel:rect({
        name = "bg", 
        halign="grow", 
        valign="grow", 
        visible = params.background_color ~= nil, 
        color = params.background_color,
        alpha = params.background_alpha, 
        layer = 0 
    })         
    if type(params.position) == "table" then
        self._panel:position(params.position[1] or self._panel:x(), params.position[2] or self._panel:y())
    else
         if string.match(params.position, "Center") then
            self._panel:set_center(self._fullscreen_ws_pnl:center())
        end      
        if string.match(params.position, "Bottom") then
            self._panel:set_bottom(self._fullscreen_ws_pnl:bottom())
        end         
        if string.match(params.position, "Top") then
            self._panel:set_top(self._fullscreen_ws_pnl:top())
        end     
        if string.match(params.position, "Right") then
            self._panel:set_right(self._fullscreen_ws_pnl:right())
        end       
    end
    self._scroll_panel = self._panel:panel({
        name = "scroll_panel",
        halign = "center", 
        align = "center",
    })	
    local bar_h = self._scroll_panel:top() - self._scroll_panel:bottom()
    self._scroll_panel:panel({
        name = "scroll_bar",
        halign = "center", 
        align = "center",
        w = 4,
        layer = 20,
    }):rect({
		name = "rect",
		color = params.text_color or Color.black,
		layer = 4,
		alpha = params.alpha or 0.5,
		h = bar_h,
    })
	self._help_panel = self._fullscreen_ws_pnl:panel({
        name = "help_panel",   
	    w = self._panel:w() - 100,
        layer = 30,
     })   
    self._help_panel:set_left(self._panel:right())
    self._help_panel:rect({
        name = "bg",
        color = params.background_color or Color.white,
        alpha = params.background_alpha or 0.8,      
    })

	self._help_text = self._help_panel:text({
	    name = "help_text",
	    text = "",
	    layer = 1,
	    wrap = true,
	    x = 4,
	    word_wrap = true,
	    valign = "left",
	    align = "left",
	    vertical = "top",	    
	    color = params.text_color or Color.black,
	    font = "fonts/font_large_mf",
	    font_size = 16
	})      
    self._tabs_panel = self._panel:panel({
        y = 10, 
        x = 5,
        h = 24,
        layer = 20,
    })
    table.merge(self, params)
	local _,_,w,h = self._help_text:text_rect()
	self._help_panel:set_size(w + 10,h)
	if params.create_items then
		params.create_items(self)
	else
		BeardLib:log("No create items callback found")
	end
    self._menu_closed = params.closed or params.closed == nil    
    self._fullscreen_ws_pnl:key_press(callback(self, self, "KeyPressed"))    
    self._fullscreen_ws_pnl:key_release(callback(self, self, "KeyReleased"))    
    return self
end
 
function MenuUI:NewMenu(params) 
    local menu = Menu:new(self, params)
    table.insert(self._menus, menu)  
    return menu
end

function MenuUI:SetSize( w, h )    
    self._panel:set_size(w, h)
    if self.position == "right" then
        self._panel:set_right(self._fullscreen_ws_pnl:right())
    elseif self.position == "center" then     
        self._panel:set_center(self._fullscreen_ws_pnl:center())
    end
    self._scroll_panel:set_size(w,  h - (self.tabs and 35 or 0))
    self._scroll_panel:set_x(0)
    self._scroll_panel:child("scroll_bar"):set_h(h)
    self._help_panel:set_left(self._panel:right())
    for i, menu in pairs(self._menus) do
        menu.items_panel:set_size(w- 12, h)
        menu:RecreateItems()
    end
end
function MenuUI:enable()
	self._fullscreen_ws_pnl:set_alpha(1)
	self._menu_closed = false
	managers.mouse_pointer:use_mouse({
		mouse_move = callback(self, self, "MouseMoved"),
		mouse_press = callback(self, self, "MousePressed"),
		mouse_release = callback(self, self, "MouseReleased"),
		id = self._mouse_id
	}) 	
    self._fullscreen_ws_pnl:key_press(callback(self, self, "KeyPressed"))    
    self._fullscreen_ws_pnl:key_release(callback(self, self, "KeyReleased"))       
end

function MenuUI:disable()
	self._fullscreen_ws_pnl:set_alpha(0)
	self._menu_closed = true
	self._highlighted = nil
	if self._current_menu then
		for _, item in pairs(self._current_menu._items) do
			item.highlight = false
		end	
	end
	if self._openlist then
	 	self._openlist.list:hide()
	 	self._openlist = nil
	end		
	self._fullscreen_ws_pnl:key_press(nil)    
    self._fullscreen_ws_pnl:key_release(nil)    
	managers.mouse_pointer:remove_mouse(self._mouse_id)
end

function MenuUI:KeyReleased( o, k )
	self._key_pressed = nil
    if self.key_released then
        self.key_release(o, k)
    end
end
 
function MenuUI:MouseInside()
    for _, menu in pairs(self._menus) do
        if menu:MouseInside() then
            return true
        end
    end
end 

function MenuUI:KeyPressed( o, k )
    if self._menu_closed then
        return
    end
	self._key_pressed = k 
	for _, menu in ipairs(self._menus) do
        if menu:KeyPressed( o, k ) then
            return true
        end		
	end		
    if self.key_press then
        self.key_press(o, k)
    end	
end

function MenuUI:SetHelp(help)
	self._help_text:set_text(help)
	local _,_,w,h = self._help_text:text_rect()
	self._help_panel:set_size(w + 10,h)
end
function MenuUI:MouseReleased( o, button, x, y )
	self._slider_hold = nil
	self._grabbed_scroll_bar = nil
    for _, menu in ipairs(self._menus) do
        if menu:MouseReleased( button, x, y ) then
            return
        end
    end     
    if self.mouse_release then
        self.mouse_release(o, k)
    end    
end
 
function MenuUI:MousePressed( o, button, x, y )
	for _, menu in ipairs(self._menus) do
		if menu:MousePressed( button, x, y ) then
            return    
		end
	end	
    if self.mouse_press then
        self.mouse_press(button, x, y)
    end      	
end
function MenuUI:MouseMoved( o, x, y )
	for _, menu in ipairs( self._menus ) do
		menu:MouseMoved( x, y )
	end
    if self.mouse_move then
        self.mouse_move( x, y )
    end         
	self._old_x = x	
	self._old_y = y	
end
function MenuUI:SwitchMenu( Menu )  
    self._current_menu:SetVisible(false)
    Menu:SetVisible(true)
    self._current_menu = Menu
end
function MenuUI:GetItem( name )  
	for _,menu in pairs(self._menus) do
		if menu.name == name then			
			return menu
		else
			local item = menu:GetItem(name) 
			if item and item.name then
				return item
			end 
		end
	end
end  
 