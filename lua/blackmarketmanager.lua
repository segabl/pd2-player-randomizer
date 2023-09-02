function BlackMarketManager:get_weapon_name_by_category_slot(category, slot)
	local forced_weapon = category == "primaries" and self:forced_primary() or category == "secondaries" and self:forced_secondary()
	if forced_weapon then
		slot = forced_weapon.slot
		if not slot then
			return managers.weapon_factory:get_weapon_name_by_factory_id(forced_weapon.factory_id)
		end
	end

	local crafted_slot = self:get_crafted_category_slot(category, slot)
	if crafted_slot then
		local cosmetics = crafted_slot.cosmetics
		local cosmetic_name = cosmetics and cosmetics.id and tweak_data.blackmarket.weapon_skins[cosmetics.id] and tweak_data.blackmarket.weapon_skins[cosmetics.id].unique_name_id and managers.localization:text(tweak_data.blackmarket.weapon_skins[cosmetics.id].unique_name_id)
		local custom_name = cosmetic_name or crafted_slot.custom_name
		if cosmetic_name and crafted_slot.locked_name then
			return utf8.to_upper(cosmetic_name)
		end
		if custom_name then
			return "\"" .. custom_name .. "\""
		end
		return managers.weapon_factory:get_weapon_name_by_factory_id(crafted_slot.factory_id)
	end
	return ""
end

local forced_primary_original = BlackMarketManager.forced_primary
function BlackMarketManager:forced_primary(...)
	if not PlayerRandomizer:current_profile_settings().random_primary or not PlayerRandomizer:allow_randomizing() then
		return forced_primary_original(self, ...)
	end
	return PlayerRandomizer.settings.only_owned_weapons and PlayerRandomizer:get_random_weapon_owned(2) or PlayerRandomizer:get_random_weapon(2)
end

local forced_secondary_original = BlackMarketManager.forced_secondary
function BlackMarketManager:forced_secondary(...)
	if not PlayerRandomizer:current_profile_settings().random_secondary or not PlayerRandomizer:allow_randomizing() then
		return forced_secondary_original(self, ...)
	end
	return PlayerRandomizer.settings.only_owned_weapons and PlayerRandomizer:get_random_weapon_owned(1) or PlayerRandomizer:get_random_weapon(1)
end

local forced_throwable_original = BlackMarketManager.forced_throwable
function BlackMarketManager:forced_throwable(...)
	if not PlayerRandomizer:current_profile_settings().random_grenade or not PlayerRandomizer:allow_randomizing() then
		return forced_throwable_original(self, ...)
	end
	return PlayerRandomizer:get_random_grenade()
end

local equipped_melee_weapon_original = BlackMarketManager.equipped_melee_weapon
function BlackMarketManager:equipped_melee_weapon(...)
	local forced_melee_weapon = self:forced_melee_weapon()
	if forced_melee_weapon then
		return forced_melee_weapon
	end
	return equipped_melee_weapon_original(self, ...)
end

function BlackMarketManager:forced_melee_weapon(...)
	if not PlayerRandomizer:current_profile_settings().random_melee or not PlayerRandomizer:allow_randomizing() then
		return
	end
	return PlayerRandomizer:get_random_melee()
end

local forced_armor_original = BlackMarketManager.forced_armor
function BlackMarketManager:forced_armor(...)
	if not PlayerRandomizer:current_profile_settings().random_armor or not PlayerRandomizer:allow_randomizing() then
		return forced_armor_original(self, ...)
	end
	return PlayerRandomizer:get_random_armor()
end

local forced_deployable_original = BlackMarketManager.forced_deployable
function BlackMarketManager:forced_deployable(...)
	if not PlayerRandomizer:current_profile_settings().random_deployable or not PlayerRandomizer:allow_randomizing() then
		return forced_deployable_original(self, ...)
	end
	return PlayerRandomizer:get_random_deployable()
end

-- Ignore weapon caching
local equipped_secondary_original = BlackMarketManager.equipped_secondary
function BlackMarketManager:equipped_secondary(...)
	local forced_secondary = self:forced_secondary()
	if forced_secondary then
		return forced_secondary
	end

	return equipped_secondary_original(self, ...)
end

local equipped_primary_original = BlackMarketManager.equipped_primary
function BlackMarketManager:equipped_primary(...)
	local forced_primary = self:forced_primary()
	if forced_primary then
		return forced_primary
	end

	return equipped_primary_original(self, ...)
end

local texture_switches_cache = {}
local get_weapon_texture_switches_original = BlackMarketManager.get_weapon_texture_switches
function BlackMarketManager:get_weapon_texture_switches(category, slot, weapon, ...)
	local texture_switches = get_weapon_texture_switches_original(self, category, slot, weapon, ...)

	local cat_index = category == "primaries" and 1 or category == "secondaries" and 2
	if not weapon or PlayerRandomizer.settings.only_owned_weapons or not cat_index or not PlayerRandomizer:is_randomized(cat_index) then
		return texture_switches
	end

	if texture_switches_cache[category] then
		return texture_switches_cache[category]
	end

	texture_switches = texture_switches or {}

	local wts = tweak_data.gui.weapon_texture_switches
	for _, part_id in pairs(weapon.blueprint or {}) do
		if tweak_data.gui.part_texture_switches[part_id] then
			texture_switches[part_id] = tweak_data.gui.part_texture_switches[part_id]
		elseif PlayerRandomizer.settings.random_reticle then
			local part_data = tweak_data.weapon.factory.parts[part_id]
			local switches = part_data and part_data.texture_switch and wts.types[part_data.type] or wts.types[part_data.sub_type]
			if switches then
				texture_switches[part_id] = math.random(#wts.color_indexes) .. " " .. math.random(#switches)
			end
		else
			local part_data = tweak_data.weapon.factory.parts[part_id]
			if part_data and part_data.texture_switch then
				texture_switches[part_id] = tweak_data.gui.default_part_texture_switch
			end
		end
	end

	texture_switches_cache[category] = texture_switches

	return texture_switches
end
