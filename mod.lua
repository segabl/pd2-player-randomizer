if not PlayerRandomizer then

	PlayerRandomizer = {}
	PlayerRandomizer.settings = {
		hide_selections = true,
		only_owned_weapons = false,
		weapon_skin_chance = 0.5,
		random_reticle = true
	}
	PlayerRandomizer.save_path = SavePath
	PlayerRandomizer.mod_path = ModPath
	PlayerRandomizer.mod_instance = ModInstance
	PlayerRandomizer.menu_id = "PlayerRandomizerMenu"
	PlayerRandomizer.weapon_menu_id = "PlayerRandomizerMenuWeaponTypes"
	PlayerRandomizer.part_menu_id = "PlayerRandomizerMenuPartChances"
	PlayerRandomizer.blacklist = {
		weapons = {},
		mods = {},
		melee_weapons = {},
		throwables = {},
		armors = {},
		deployables = {}
	}
	PlayerRandomizer.required = {}

	function PlayerRandomizer:save()
		io.save_as_json(self.settings, self.save_path .. "player_randomizer.txt")
	end

	function PlayerRandomizer:load()
		local file = self.save_path .. "player_randomizer.txt"
		local data = io.file_is_readable(file) and io.load_as_json(file)
		if data then
			for k, v in pairs(data) do
				self.settings[k] = v
			end
		end

		file = self.save_path .. "player_randomizer_blacklist.txt"
		data = io.file_is_readable(file) and io.load_as_json(file)
		if data then
			for k, v in pairs(data) do
				self.blacklist[k] = v
			end
		end
	end

	function PlayerRandomizer:disable_menu()
		local disable_options = {
			only_owned_weapons = true
		}
		local menu = MenuHelper:GetMenu(self.menu_id)
		for _, item in pairs(menu and menu._items_list or {}) do
			if disable_options[item:name()] then
				item:set_enabled(false)
			end
		end
	end

	function PlayerRandomizer:show_profile_settings(multi_profile_item_gui)
		local new_settings = clone(self:current_profile_settings())

		managers.system_menu:show({
			title = managers.localization:text("randomizer_settings_for_profile", { PROFILE = managers.multi_profile:current_profile_name() }),
			button_list = {
				{
					text = managers.localization:text("enabled_name"),
					toggle = true,
					no_close = true,
					initial_toggle_state = new_settings.enabled and true or false,
					toggle_callback_func = function () new_settings.enabled = not new_settings.enabled end
				},
				{
					no_text = true,
					no_selection = true
				},
				{
					text = managers.localization:text("primary_desc"),
					toggle = true,
					no_close = true,
					initial_toggle_state = new_settings.random_primary and true or false,
					toggle_callback_func = function () new_settings.random_primary = not new_settings.random_primary end
				},
				{
					text = managers.localization:text("secondary_desc"),
					toggle = true,
					no_close = true,
					initial_toggle_state = new_settings.random_secondary and true or false,
					toggle_callback_func = function () new_settings.random_secondary = not new_settings.random_secondary end
				},
				{
					text = managers.localization:text("melee_desc"),
					toggle = true,
					no_close = true,
					initial_toggle_state = new_settings.random_melee and true or false,
					toggle_callback_func = function () new_settings.random_melee = not new_settings.random_melee end
				},
				{
					text = managers.localization:text("grenade_desc"),
					toggle = true,
					no_close = true,
					initial_toggle_state = new_settings.random_grenade and true or false,
					toggle_callback_func = function () new_settings.random_grenade = not new_settings.random_grenade end
				},
				{
					text = managers.localization:text("armor_desc"),
					toggle = true,
					no_close = true,
					initial_toggle_state = new_settings.random_armor and true or false,
					toggle_callback_func = function () new_settings.random_armor = not new_settings.random_armor end
				},
				{
					text = managers.localization:text("deployable_desc"),
					toggle = true,
					no_close = true,
					initial_toggle_state = new_settings.random_deployable and true or false,
					toggle_callback_func = function () new_settings.random_deployable = not new_settings.random_deployable end
				},
				{
					no_text = true,
					no_selection = true
				},
				{
					text = managers.localization:text("dialog_ok"),
					callback_func = function ()
						PlayerRandomizer:set_current_profile_settings(new_settings)
						multi_profile_item_gui:_update_randomizer_state()
					end
				},
				{
					text = managers.localization:text("dialog_cancel"),
					cancel_button = true
				}
			}
		})
	end

	function PlayerRandomizer:current_profile_settings()
		local profile_settings = managers.multi_profile and self.settings["profile_" .. tostring(managers.multi_profile._global._current_profile)]

		if type(profile_settings) ~= "table" then
			profile_settings = {
				enabled = profile_settings == true,
				random_primary = Utils:FirstNonNil(self.settings.random_primary, true),
				random_secondary = Utils:FirstNonNil(self.settings.random_secondary, true),
				random_melee = Utils:FirstNonNil(self.settings.random_melee, true),
				random_grenade = Utils:FirstNonNil(self.settings.random_grenade, true),
				random_armor = Utils:FirstNonNil(self.settings.random_armor, true),
				random_deployable = Utils:FirstNonNil(self.settings.random_deployable, true)
			}
		end

		return profile_settings
	end

	function PlayerRandomizer:set_current_profile_settings(new_settings)
		self.settings["profile_" .. tostring(managers.multi_profile._global._current_profile)] = new_settings
		self:update_outfit()
		self:save()
	end

	function PlayerRandomizer:is_current_profile_randomized()
		return self:current_profile_settings().enabled
	end

	function PlayerRandomizer:allow_randomizing()
		local state_name = game_state_machine and game_state_machine:current_state_name() or ""
		return state_name:find("ingame") and not state_name:find("ingame_lobby_menu") and self:is_current_profile_randomized()
	end

	function PlayerRandomizer:is_randomized(selection)
		local profile_settings = self:current_profile_settings()
		local mapping = {
			[1] = profile_settings.random_primary,
			[2] = profile_settings.random_secondary,
			[3] = profile_settings.random_melee,
			[4] = profile_settings.random_grenade,
			[5] = profile_settings.random_armor,
			[6] = profile_settings.random_deployable
		}
		return mapping[selection] and PlayerRandomizer:allow_randomizing()
	end

	function PlayerRandomizer:get_loadout_item_index()
		self._loadout_item_index = self._loadout_item_index or 0
		self._loadout_item_index = self._loadout_item_index + 1
		return self._loadout_item_index
	end

	function PlayerRandomizer:update_outfit()
		if managers.menu_component and managers.menu_component._mission_briefing_gui then
			managers.menu_component._mission_briefing_gui:reload_loadout()
		end
		if managers.network and managers.network:session() and managers.network:session():local_peer() then
			managers.network:session():local_peer():set_outfit_string(managers.blackmarket:outfit_string())
		end
	end

	function PlayerRandomizer:chk_setup_weapons()
		if self.weapons and self.colors then
			return
		end

		self.weapons = {}

		local blacklisted = table.list_to_set(self.blacklist.weapons)
		for weapon, data in pairs(tweak_data.weapon) do
			if data.autohit then
				local disabled = blacklisted[weapon] or self.settings["weapon_" .. data.categories[1]] == false or data.global_value == "super_serious_shooter_weapon"
				if not disabled and Global.blackmarket_manager.weapons[weapon].unlocked then
					local selection_index = data.use_data.selection_index
					self.weapons[selection_index] = self.weapons[selection_index] or {}
					table.insert(self.weapons[selection_index], {
						selection_index = selection_index,
						weapon_id = weapon,
						factory_id = managers.weapon_factory:get_factory_id_by_weapon_id(weapon),
						equipped = true
					})
				end
			end
		end

		self.colors = table.filter_list(tweak_data.blackmarket.weapon_colors, function (v)
			local color_tweak = tweak_data.blackmarket.weapon_skins[v]
			local dlc = color_tweak.dlc or managers.dlc:global_value_to_dlc(color_tweak.global_value)
			local unlocked = not dlc or managers.dlc:is_dlc_unlocked(dlc)
			local have_color = not color_tweak.global_value or managers.blackmarket:has_item(color_tweak.global_value, "weapon_skins", v)
			return unlocked and have_color
		end)
	end

	function PlayerRandomizer:get_random_weapon(selection_index)
		self:chk_setup_weapons()

		self._random_weapon = self._random_weapon or {}
		if self._random_weapon[selection_index] then
			return self._random_weapon[selection_index]
		end

		local data = self.weapons[selection_index][math.random(#self.weapons[selection_index])]
		if math.random() < self.settings.weapon_skin_chance then
			local skins = managers.blackmarket:get_cosmetics_instances_by_weapon_id(data.weapon_id)
			if #skins > 0 and math.random(#skins + #self.colors) <= #skins then
				local inst = table.random(skins)
				local inst_data = managers.blackmarket._global.inventory_tradable[inst]
				data.cosmetics = {
					bonus = inst_data.bonus,
					id = inst_data.entry,
					instance_id = inst,
					quality = inst_data.quality
				}
			elseif #self.colors > 0 then
				local inst = table.random(self.colors)
				data.cosmetics = {
					id = inst,
					quality = table.random_key(tweak_data.economy.qualities),
					color_index = math.random(#tweak_data.blackmarket.weapon_skins[inst])
				}
			end
		end
		data.blueprint = clone(data.cosmetics and tweak_data.blackmarket.weapon_skins[data.cosmetics.id].default_blueprint or tweak_data.weapon.factory[data.factory_id].default_blueprint)

		local blacklisted = table.list_to_set(self.blacklist.mods)
		for part_type, parts in pairs(managers.blackmarket:get_dropable_mods_by_weapon_id(data.weapon_id)) do
			if math.random() < (self.settings[part_type .. "_chance"] or 1) then
				local forbidden = managers.weapon_factory:_get_forbidden_parts(data.factory_id, data.blueprint)
				local filtered_parts = table.filter_list(parts, function (part)
					local part_id = part[1]
					local part_data = tweak_data.weapon.factory.parts[part_id]
					return not part_data.unatainable and not forbidden[part_id] and not blacklisted[part_id] and not managers.weapon_factory:_get_forbidden_parts(data.factory_id, data.blueprint)[part_id] and part_data.global_value ~= "super_serious_shooter_part"
				end)
				local part = table.random(filtered_parts)
				if part then
					managers.weapon_factory:change_part_blueprint_only(data.factory_id, part[1], data.blueprint)
				end
			end
		end

		self._random_weapon[selection_index] = data

		return data
	end

	function PlayerRandomizer:chk_setup_weapons_owned()
		if self.weapons_owned then
			return
		end

		self.weapons_owned = { {}, {} }

		for slot, data in pairs(Global.blackmarket_manager.crafted_items["primaries"]) do
			local unlocked = managers.blackmarket:weapon_unlocked_by_crafted("primaries", slot)
			if unlocked and data.global_value ~= "super_serious_shooter_weapon" then
				data.slot = slot
				table.insert(self.weapons_owned[2], data)
			end
		end

		for slot, data in pairs(Global.blackmarket_manager.crafted_items["secondaries"]) do
			local unlocked = managers.blackmarket:weapon_unlocked_by_crafted("secondaries", slot)
			if unlocked and data.global_value ~= "super_serious_shooter_weapon" then
				data.slot = slot
				table.insert(self.weapons_owned[1], data)
			end
		end
	end

	function PlayerRandomizer:get_random_weapon_owned(selection_index)
		self:chk_setup_weapons_owned()

		self._random_weapon_owned = self._random_weapon_owned or {}
		self._random_weapon_owned[selection_index] = self._random_weapon_owned[selection_index] or table.random(self.weapons_owned[selection_index])
		return self._random_weapon_owned[selection_index]
	end

	function PlayerRandomizer:chk_setup_grenades()
		if self.grenades then
			return
		end

		self.grenades = {}

		local blacklisted = table.list_to_set(self.blacklist.throwables)
		for grenade_id, data in pairs(tweak_data.blackmarket.projectiles) do
			if data.throwable or data.ability then
				local unlocked = Global.blackmarket_manager.grenades[grenade_id].unlocked and (not data.dlc or managers.dlc:is_dlc_unlocked(data.dlc))
				if unlocked and not blacklisted[grenade_id] then
					table.insert(self.grenades, grenade_id)
				end
			end
		end
	end

	function PlayerRandomizer:get_random_grenade()
		self:chk_setup_grenades()

		self._random_grenade = self._random_grenade or self.grenades[math.random(#self.grenades)]
		return self._random_grenade
	end

	function PlayerRandomizer:chk_setup_melees()
		if self.melees then
			return
		end

		self.melees = {}

		local blacklisted = table.list_to_set(self.blacklist.melee_weapons)
		for melee_weapon, data in pairs(tweak_data.blackmarket.melee_weapons) do
			local unlocked = Global.blackmarket_manager.melee_weapons[melee_weapon].unlocked and (not data.dlc or managers.dlc:is_dlc_unlocked(data.dlc))
			if unlocked and not blacklisted[melee_weapon] then
				table.insert(self.melees, melee_weapon)
			end
		end
	end

	function PlayerRandomizer:get_random_melee()
		self:chk_setup_melees()

		self._random_melee = self._random_melee or self.melees[math.random(#self.melees)]
		return self._random_melee
	end

	function PlayerRandomizer:chk_setup_armors()
		if self.armors then
			return
		end

		self.armors = {}

		local blacklisted = table.list_to_set(self.blacklist.armors)
		for armor in pairs(tweak_data.blackmarket.armors) do
			local unlocked = Global.blackmarket_manager.armors[armor].unlocked
			if unlocked and not blacklisted[armor] then
				table.insert(self.armors, armor)
			end
		end
	end

	function PlayerRandomizer:get_random_armor()
		self:chk_setup_armors()

		self._random_armor = self._random_armor or self.armors[math.random(#self.armors)]
		return self._random_armor
	end

	function PlayerRandomizer:chk_setup_deployables()
		if self.deployables then
			return
		end

		self.deployables = {}
		local blacklisted = table.list_to_set(self.blacklist.deployables)
		for deployable in pairs(tweak_data.blackmarket.deployables) do
			if not blacklisted[deployable] then
				table.insert(self.deployables, deployable)
			end
		end
	end

	function PlayerRandomizer:get_random_deployable()
		self:chk_setup_deployables()

		self._random_deployable = self._random_deployable or self.deployables[math.random(#self.deployables)]
		return self._random_deployable
	end

	function PlayerRandomizer:show_weapon_info()
		local player = managers.player:local_player()
		local w = player and player:inventory():equipped_unit():base()
		if not w then
			return
		end
		local factory_parts = tweak_data.weapon.factory.parts
		local w_name = managers.weapon_factory:get_weapon_name_by_weapon_id(w._name_id)
		local blueprint = {}
		for _, part_id in pairs(w._blueprint) do
			local part_tweak = factory_parts[part_id]
			if part_tweak and part_tweak.pcs and part_tweak.name_id and not blueprint[part_tweak.name_id] then
				local name = managers.localization:text(part_tweak.name_id)
				if part_tweak.type == "charm" and not name:lower():match("charm$") then
					name = name .. " Charm"
				elseif part_tweak.type == "bonus" and not name:lower():match("boost$") then
					name = name .. " Boost"
				end
				blueprint[part_tweak.name_id] = name
			end
		end
		local loc_str = table.size(blueprint) == 0 and "weapon_info_string_default" or "weapon_info_string"
		local weap_info = managers.localization:text(loc_str, { WEAPON = w_name, MODS = table.concat(table.map_values(blueprint), ", ") })
		managers.chat:_receive_message(1, managers.localization:to_upper_text("menu_system_message"), weap_info, tweak_data.system_chat_color)
	end

	function PlayerRandomizer:reroll()
		if Utils:IsInHeist() or not PlayerRandomizer:allow_randomizing() then
			return
		end

		PlayerRandomizer._random_armor = nil
		PlayerRandomizer._random_deployable = nil
		PlayerRandomizer._random_grenade = nil
		PlayerRandomizer._random_melee = nil
		PlayerRandomizer._random_weapon = nil
		PlayerRandomizer._random_weapon_owned = nil

		local blm = managers.blackmarket
		blm:clean_weapon_equipped_cache()
		blm:equip_weapon("primaries", blm:equipped_weapon_slot("primaries"))
		blm:equip_weapon("secondaries", blm:equipped_weapon_slot("secondaries"))
		blm:equip_melee_weapon(blm:equipped_melee_weapon())
		blm:equip_grenade(blm:equipped_grenade())
		blm:equip_deployable({target_slot = 1, name = blm:equipped_deployable(1)})
		blm:equip_deployable({target_slot = 2, name = blm:equipped_deployable(2)})
		blm:equip_armor(blm:equipped_armor())

		PlayerRandomizer:update_outfit()

		if managers.chat then
			managers.chat:_receive_message(1, managers.localization:to_upper_text("menu_system_message"), managers.localization:text("randomizer_rerolled"), tweak_data.system_chat_color)
		end
	end

	PlayerRandomizer:load()

	Hooks:Add("MenuManagerOnOpenMenu", "MenuManagerOnOpenMenuRandomizer", function ()
		if Utils:IsInHeist() then
			PlayerRandomizer:disable_menu()
		end
	end)

	Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInitPlayerRandomizer", function(loc)
		loc:load_localization_file(PlayerRandomizer.mod_path .. "loc/english.txt")
		for _, filename in pairs(file.GetFiles(PlayerRandomizer.mod_path .. "loc/")) do
			local str = filename:match('^(.*).txt$')
			if str and Idstring(str) and Idstring(str):key() == SystemInfo:language():key() then
				loc:load_localization_file(PlayerRandomizer.mod_path .. "loc/" .. filename)
				break
			end
		end
		if PD2KR then
			loc:load_localization_file(PlayerRandomizer.mod_path .. "loc/korean.txt")
		end
	end)

	Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenusPlayerRandomizer", function(menu_manager, nodes)

		MenuCallbackHandler.Randomizer_toggle = function(self, item)
			PlayerRandomizer.settings[item:name()] = (item:value() == "on")
			PlayerRandomizer:update_outfit()
		end

		local only_owned_weapons = {}
		MenuCallbackHandler.Randomizer_toggle_only_owned_weapons = function(self, item)
			PlayerRandomizer.settings.only_owned_weapons = (item:value() == "on")
			PlayerRandomizer:update_outfit()
			for _, v in pairs(only_owned_weapons) do
				v:set_enabled(not PlayerRandomizer.settings.only_owned_weapons)
			end
		end

		MenuCallbackHandler.Randomizer_value = function(self, item)
			PlayerRandomizer.settings[item:name()] = item:value()
			PlayerRandomizer:update_outfit()
		end

		MenuCallbackHandler.Randomizer_save = function ()
			PlayerRandomizer:save()
		end

		MenuHelper:NewMenu(PlayerRandomizer.menu_id)
		MenuHelper:NewMenu(PlayerRandomizer.weapon_menu_id)
		MenuHelper:NewMenu(PlayerRandomizer.part_menu_id)

		MenuHelper:AddToggle({
			id = "hide_selections",
			title = "hide_selections_name",
			desc = "hide_selections_desc",
			callback = "Randomizer_toggle",
			value = PlayerRandomizer.settings.hide_selections,
			menu_id = PlayerRandomizer.menu_id,
			priority = 98
		})
		MenuHelper:AddToggle({
			id = "only_owned_weapons",
			title = "only_owned_weapons_name",
			desc = "only_owned_weapons_desc",
			callback = "Randomizer_toggle_only_owned_weapons",
			value = PlayerRandomizer.settings.only_owned_weapons,
			menu_id = PlayerRandomizer.menu_id,
			priority = 97
		})
		table.insert(only_owned_weapons, MenuHelper:AddToggle({
			id = "random_reticle",
			title = "random_reticle_name",
			desc = "random_reticle_desc",
			callback = "Randomizer_toggle",
			disabled = PlayerRandomizer.settings.only_owned_weapons,
			value = PlayerRandomizer.settings.random_reticle,
			menu_id = PlayerRandomizer.menu_id,
			priority = 96
		}))
		table.insert(only_owned_weapons, MenuHelper:AddSlider({
			id = "weapon_skin_chance",
			title = "weapon_skin_chance_name",
			desc = "weapon_skin_chance_desc",
			callback = "Randomizer_value",
			disabled = PlayerRandomizer.settings.only_owned_weapons,
			value = PlayerRandomizer.settings.weapon_skin_chance,
			min = 0,
			max = 1,
			step = 0.05,
			show_value = true,
			display_precision = 0,
			display_scale = 100,
			is_percentage = true,
			menu_id = PlayerRandomizer.menu_id,
			priority = 95
		}))

		table.insert(only_owned_weapons, MenuHelper:AddButton({
			id = "weapon_categories",
			title = "weapon_categories_name",
			desc = "weapon_categories_desc",
			disabled = PlayerRandomizer.settings.only_owned_weapons,
			menu_id = PlayerRandomizer.menu_id,
			next_node = PlayerRandomizer.weapon_menu_id,
			priority = 94
		}))

		local weapon_cat = {}
		for _, weap_data in pairs(tweak_data.weapon) do
			if type(weap_data) == "table" and weap_data.categories and weap_data.stats then
				local cat = weap_data.categories[1]

				if not weapon_cat[cat] then
					weapon_cat[cat] = true

					local id = "weapon_" .. cat
					local loc_id = "menu_" .. cat
					local has_loc = managers.localization:exists(loc_id) or false
					MenuHelper:AddToggle({
						id = id,
						title = has_loc and loc_id or cat,
						localized = has_loc,
						callback = "Randomizer_toggle",
						value = PlayerRandomizer.settings[id] == nil and true or PlayerRandomizer.settings[id],
						menu_id = PlayerRandomizer.weapon_menu_id
					})
				end
			end
		end

		table.insert(only_owned_weapons, MenuHelper:AddButton({
			id = "part_category_chances",
			title = "part_category_chances_name",
			desc = "part_category_chances_desc",
			disabled = PlayerRandomizer.settings.only_owned_weapons,
			menu_id = PlayerRandomizer.menu_id,
			next_node = PlayerRandomizer.part_menu_id,
			priority = 93
		}))

		local part_cat = {}
		for _, part_data in pairs(tweak_data.weapon.factory.parts) do
			local cat = part_data.type
			if not part_cat[cat] and not part_data.inaccessible and (part_data.pcs or part_data.pc) then
				part_cat[cat] = true

				local id = cat .. "_chance"
				local loc_id = "bm_menu_" .. cat
				local has_loc = managers.localization:exists(loc_id) or false
				MenuHelper:AddSlider({
					id = id,
					title = has_loc and loc_id or cat,
					localized = has_loc,
					callback = "Randomizer_value",
					value = PlayerRandomizer.settings[id] or 1,
					min = 0,
					max = 1,
					step = 0.05,
					show_value = true,
					display_precision = 0,
					display_scale = 100,
					is_percentage = true,
					menu_id = PlayerRandomizer.part_menu_id
				})
			end
		end

		MenuHelper:AddDivider({
			size = 24,
			menu_id = PlayerRandomizer.menu_id,
			priority = 10
		})

		BLT.Keybinds:register_keybind(PlayerRandomizer.mod_instance, { id = "display_weapon_info", allow_game = true, show_in_menu = false, callback = function()
			PlayerRandomizer:show_weapon_info()
		end })
		local bind = BLT.Keybinds:get_keybind("display_weapon_info")
		local key = bind and bind:Key() or ""
		MenuHelper:AddKeybinding({
			id = "display_weapon_info",
			title = "display_weapon_info_name",
			desc = "display_weapon_info_desc",
			connection_name = "display_weapon_info",
			binding = key,
			button = key,
			menu_id = PlayerRandomizer.menu_id,
			priority = -11
		})

		BLT.Keybinds:register_keybind(PlayerRandomizer.mod_instance, { id = "reroll_randomizer", allow_game = true, show_in_menu = false, callback = function()
			PlayerRandomizer:reroll()
		end })
		bind = BLT.Keybinds:get_keybind("reroll_randomizer")
		key = bind and bind:Key() or ""
		MenuHelper:AddKeybinding({
			id = "reroll_randomizer",
			title = "reroll_randomizer_name",
			desc = "reroll_randomizer_desc",
			connection_name = "reroll_randomizer",
			binding = key,
			button = key,
			menu_id = PlayerRandomizer.menu_id,
			priority = -13
		})

		nodes[PlayerRandomizer.menu_id] = MenuHelper:BuildMenu(PlayerRandomizer.menu_id, { back_callback = "Randomizer_save" })
		nodes[PlayerRandomizer.weapon_menu_id] = MenuHelper:BuildMenu(PlayerRandomizer.weapon_menu_id, { back_callback = "Randomizer_save" })
		nodes[PlayerRandomizer.part_menu_id] = MenuHelper:BuildMenu(PlayerRandomizer.part_menu_id, { back_callback = "Randomizer_save" })
		MenuHelper:AddMenuItem(nodes["blt_options"], PlayerRandomizer.menu_id, "Randomizer_menu_main_name", "Randomizer_menu_main_desc")

	end)

end

if RequiredScript and not PlayerRandomizer.required[RequiredScript] then

	local fname = PlayerRandomizer.mod_path .. RequiredScript:gsub(".+/(.+)", "lua/%1.lua")
	if io.file_is_readable(fname) then
		dofile(fname)
	end

	PlayerRandomizer.required[RequiredScript] = true

end
