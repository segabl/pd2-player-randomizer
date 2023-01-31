NewRaycastWeaponBase.GADGET_COLORS = {}

Hooks:PostHook(NewRaycastWeaponBase, "clbk_assembly_complete", "clbk_assembly_complete_player_randomizer", function (self)
	if PlayerRandomizer.settings.only_owned_weapons or not PlayerRandomizer:is_randomized(3 - self:selection_index()) then
		return
	end

	local function try_set_color(part_id)
		NewRaycastWeaponBase.GADGET_COLORS[part_id] = NewRaycastWeaponBase.GADGET_COLORS[part_id] or {
			laser = Color(hsv_to_rgb(math.random(360), math.random() * 0.25 + 0.75, math.random() * 0.25 + 0.75)),
			flashlight = Color(1, 1, math.random() * 0.25 + 0.75)
		}

		local mod_td = tweak_data.weapon.factory.parts[part_id]
		local part_data = self._parts[part_id]
		local colors = NewRaycastWeaponBase.GADGET_COLORS[part_id]

		if part_data and colors[mod_td.sub_type] then
			local alpha = part_data.unit:base().GADGET_TYPE == "laser" and tweak_data.custom_colors.defaults.laser_alpha or 1
			part_data.unit:base():set_color(colors[mod_td.sub_type]:with_alpha(alpha))
		end

		if mod_td.adds then
			for _, add_part_id in ipairs(mod_td.adds) do
				try_set_color(add_part_id)
			end
		end
	end

	for _, part_id in ipairs(self._blueprint) do
		try_set_color(part_id)
	end
end)
