function MultiProfileItemGui:_update_randomizer_state()
	if not alive(self._randomizer_panel) then
		return
	end

	local randomized = PlayerRandomizer:is_current_profile_randomized()
	self._randomizer_panel:child(0):set_alpha(randomized and 1 or 0.5)
	self._randomizer_panel:child(1):set_visible(not randomized)
end

Hooks:PostHook(MultiProfileItemGui, "init", "init_player_randomizer", function (self)
	if alive(self._randomizer_panel) then
		return
	end

	local w_increase = self.padding + self.quick_panel_w
	self._panel:set_w(self._panel:w() + w_increase)
	self._box_panel:set_size(self._panel:size())
	self._box_panel:child(0):set_size(self._panel:size())
	self._profile_panel:move(w_increase, 0)
	if alive(self._quick_select_panel) then
		self._quick_select_panel:move(w_increase, 0)
	end

	self._randomizer_panel = self._panel:panel({
		w = self.quick_panel_w,
		h = self.quick_panel_h
	})

	local color = PlayerRandomizer.settings.enabled and tweak_data.screen_colors.button_stage_3 or Color(0.25, 0.25, 0.25)

	self._randomizer_panel:bitmap({
		texture = "guis/textures/pd2/dice_icon",
		color = color,
		x = self.padding,
		y = self.padding,
		w = self.quick_panel_w - self.padding * 2,
		h = self.quick_panel_h - self.padding * 2
	})

	self._randomizer_panel:polyline({
		layer = 1,
		line_width = 3,
		color = color,
		points = {
			Vector3(self.padding * 1.5, self.quick_panel_h - self.padding * 1.5, 0),
			Vector3(self.quick_panel_w - self.padding * 1.5, self.padding * 1.5, 0)
		}
	})

	self._randomizer_panel:set_right(self._profile_panel:left() - self.padding)
	self._randomizer_panel:set_center_y(self._panel:h() / 2)
	self._randomizer_panel:set_top(math.round(self._randomizer_panel:top()))

	self:_update_randomizer_state()
end)

Hooks:PostHook(MultiProfileItemGui, "mouse_moved", "mouse_moved_player_randomizer", function (self, x, y)
	if self._arrow_selection then
		return
	end

	if alive(self._randomizer_panel) then
		if self._randomizer_panel:inside(x, y) then
			if self._is_randomizer_selected ~= true then
				for _, element in pairs(self._randomizer_panel:children()) do
					element:set_color(PlayerRandomizer.settings.enabled and tweak_data.screen_colors.button_stage_2 or Color(0.5, 0.5, 0.5))
				end

				managers.menu_component:post_event("highlight")

				self._is_randomizer_selected = true
			end

			self._arrow_selection = "randomizer"

			return true, "link"
		elseif self._is_randomizer_selected == true then
			for _, element in pairs(self._randomizer_panel:children()) do
				element:set_color(PlayerRandomizer.settings.enabled and tweak_data.screen_colors.button_stage_3 or Color(0.25, 0.25, 0.25))
			end

			self._is_randomizer_selected = false
		end
	end
end)

Hooks:PostHook(MultiProfileItemGui, "mouse_pressed", "mouse_pressed_player_randomizer", function (self, button, x, y)
	if button == Idstring("0") and self:arrow_selection() == "randomizer" then
		PlayerRandomizer:set_current_profile_randomized(not PlayerRandomizer:is_current_profile_randomized())
		PlayerRandomizer:update_outfit()
		PlayerRandomizer:save()
		managers.menu_component:post_event("menu_enter")
	end

	self:_update_randomizer_state()
end)
