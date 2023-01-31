Hooks:PostHook(MissionBriefingGui, "init", "init_player_randomizer", function ()
	PlayerRandomizer:update_outfit()
end)

Hooks:PostHook(NewLoadoutTab, "init", "init_player_randomizer", function ()
	PlayerRandomizer._loadout_item_index = 0
end)

Hooks:PostHook(NewLoadoutItem, "init", "init_player_randomizer", function (self)
	if not PlayerRandomizer:is_randomized(PlayerRandomizer:get_loadout_item_index()) then
		return
	end

	if PlayerRandomizer.settings.hide_selections then
		self._item_panel:hide()
		self._info_panel:hide()

		local questionmark = self._panel:text({
			name = "questionmark",
			text = "?",
			font = tweak_data.menu.eroded_font,
			font_size = 140,
			align = "center",
			vertical = "center",
			color = Color.black
		})
		questionmark:set_center(self._item_panel:center_x(), self._item_panel:center_y() + 8)
	end

	local lock = self._panel:bitmap({
		name = "lock",
		texture = "guis/textures/pd2/skilltree/padlock",
		w = 32,
		h = 32,
		color = tweak_data.screen_colors.text,
		layer = 2
	})
	lock:set_center(self._item_panel:center_x(), self._item_panel:center_y())
end)

local set_slot_outfit_original = TeamLoadoutItem.set_slot_outfit
function TeamLoadoutItem:set_slot_outfit(slot, criminal_name, outfit, ...)
	local peer_id = managers.network and managers.network:session() and managers.network:session():local_peer():id() or 1
	if slot ~= peer_id or not outfit or not PlayerRandomizer.settings.hide_selections then
		return set_slot_outfit_original(self, slot, criminal_name, outfit, ...)
	end
	local new_outfit = deep_clone(outfit)
	new_outfit.primary.factory_id = not (PlayerRandomizer.settings.random_primary and PlayerRandomizer:allow_randomizing()) and new_outfit.primary.factory_id
	new_outfit.secondary.factory_id = not (PlayerRandomizer.settings.random_secondary and PlayerRandomizer:allow_randomizing()) and new_outfit.secondary.factory_id
	new_outfit.melee_weapon = not (PlayerRandomizer.settings.random_melee and PlayerRandomizer:allow_randomizing()) and new_outfit.melee_weapon
	new_outfit.grenade = not (PlayerRandomizer.settings.random_grenade and PlayerRandomizer:allow_randomizing()) and new_outfit.grenade
	new_outfit.armor = not (PlayerRandomizer.settings.random_armor and PlayerRandomizer:allow_randomizing()) and new_outfit.armor
	new_outfit.deployable = not (PlayerRandomizer.settings.random_deployable and PlayerRandomizer:allow_randomizing()) and new_outfit.deployable
	return set_slot_outfit_original(self, slot, criminal_name, new_outfit, ...)
end

local confirm_pressed_original = NewLoadoutTab.confirm_pressed
function NewLoadoutTab:confirm_pressed(...)
	if not PlayerRandomizer:is_randomized(self._item_selected) then
		return confirm_pressed_original(self, ...)
	end
end
