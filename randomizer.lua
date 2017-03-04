_G.Randomizer = Randomizer or {}
Randomizer.data = Randomizer.data or {}
Randomizer.save_path = SavePath
Randomizer.mod_path = ModPath

function Randomizer:save()
  local file = io.open(self.save_path .. "player_randomizer.txt", "w+")
  if file then
    file:write(json.encode(self.data))
    file:close()
  end
end

function Randomizer:load()
  local file = io.open(self.save_path .. "player_randomizer.txt", "r")
  if file then
    self.data = json.decode(file:read("*all"))
    file:close()
  end
end

function Randomizer:in_heist()
  return managers and managers.player and managers.player:player_unit()
end

function Randomizer:chk_setup_weapons()
  if not self.weapons then
    self.weapons = {}
    for weapon, data in pairs(tweak_data.weapon) do
      local owned = not data.global_value or managers.dlc:is_dlc_unlocked(data.global_value)
      if data.autohit and owned then
        local selection_index = data.use_data.selection_index
        self.weapons[selection_index] = self.weapons[selection_index] or {}
        local data = {
          selection_index = selection_index,
          weapon_id = weapon,
          factory_id = managers.weapon_factory:get_factory_id_by_weapon_id(weapon)
        }
        table.insert(self.weapons[selection_index], data)
      end
    end
  end
end

function Randomizer:chk_setup_grenades()
  if not self.grenades then
    self.grenades = {}
    for grenade_id, grenade in pairs(tweak_data.blackmarket.projectiles) do
      local owned = not grenade.dlc or managers.dlc:is_dlc_unlocked(grenade.dlc)
      if grenade.throwable and owned then
        table.insert(self.grenades, { id = grenade_id, amount = grenade.max_amount })
      end
    end
  end
end

function Randomizer:chk_setup_melees()
  if not self.melees then
    self.melees = {}
    for melee_weapon, data in pairs(tweak_data.blackmarket.melee_weapons) do
      if not data.dlc or managers.dlc:is_dlc_unlocked(data.dlc) then
        table.insert(self.melees, { id = melee_weapon })
      end
    end
  end
end

function Randomizer:build_random_weapon(selection_index)
  self:chk_setup_weapons()
  local data = self.weapons[selection_index][math.random(#self.weapons[selection_index])]
  data.blueprint = {}
  local has_part_of_type = {}
  local is_forbidden = {}
  local parts = deep_clone(tweak_data.weapon.factory[data.factory_id].uses_parts)
  local optional_parts = {}
  for _, part in ipairs(tweak_data.weapon.factory[data.factory_id].optional_parts or {}) do
    optional_parts[part] = true
  end
  while #parts > 0 do
    local index = math.random(#parts)
    local part_name = parts[index]
    local part = tweak_data.weapon.factory.parts[part_name]
    if part and not part.unatainable and not has_part_of_type[part.type] and not is_forbidden[part_name] and (not part.dlc or managers.dlc:is_dlc_unlocked(part.dlc)) then
      local skip_chance = math.random()
      local skip_part_type = part.type == "custom" and skip_chance <= 0.7 or part.type == "ammo" and skip_chance <= 0.4 or optional_parts[part.type] and skip_chance <= 0.2
      if not skip_part_type then
        table.insert(data.blueprint, part_name)
        for _, p in ipairs(part.forbids or {}) do
          is_forbidden[p] = true
        end
      end
      has_part_of_type[part.type] = true
    end
    table.remove(parts, index)
  end
  return data
end

function Randomizer:get_random_grenade()
  self:chk_setup_grenades()
  return Randomizer.grenades[math.random(#Randomizer.grenades)]
end

function Randomizer:get_random_melee()
  self:chk_setup_melees()
  return Randomizer.melees[math.random(#Randomizer.melees)]
end

------------------------ MOD STUFF ------------------------
if RequiredScript == "lib/managers/blackmarketmanager" then
  
  local equipped_primary_original = BlackMarketManager.equipped_primary
  function BlackMarketManager:equipped_primary(...)
    if not Randomizer.data.random_primary or not Randomizer:in_heist() then
      return equipped_primary_original(self, ...)
    end
    self._random_primary = self._random_primary or Randomizer:build_random_weapon(2)
    return self._random_primary
  end

  local equipped_secondary_original = BlackMarketManager.equipped_secondary
  function BlackMarketManager:equipped_secondary(...)
    if not Randomizer.data.random_secondary or not Randomizer:in_heist() then
      return equipped_secondary_original(self, ...)
    end
    self._random_secondary = self._random_secondary or Randomizer:build_random_weapon(1)
    return self._random_secondary
  end

  local equipped_grenade_original = BlackMarketManager.equipped_grenade
  function BlackMarketManager:equipped_grenade(...)
    if not Randomizer.data.random_grenade or not Randomizer:in_heist() then
      return equipped_grenade_original(self, ...)
    end
    self._original_grenade = equipped_grenade_original(self, ...)
    self._random_grenade = self._random_grenade or Randomizer:get_random_grenade()
    return self._random_grenade.id, self._random_grenade.amount
  end
  
  local equipped_melee_weapon_original = BlackMarketManager.equipped_melee_weapon
  function BlackMarketManager:equipped_melee_weapon(...)
    if not Randomizer.data.random_melee or not Randomizer:in_heist() then
      return equipped_melee_weapon_original(self, ...)
    end
    self._original_melee = equipped_melee_weapon_original(self, ...)
    self._random_melee = self._random_melee or Randomizer:get_random_melee()
    return self._random_melee.id
  end
  
  local save_original = BlackMarketManager.save
  function BlackMarketManager:save(data)
    save_original(self, data)
    data.blackmarket.equipped_grenade = self._original_grenade or data.blackmarket.equipped_grenade
    data.blackmarket.equipped_melee_weapon = self._original_melee or data.blackmarket.equipped_melee_weapon
  end
  
end

-------------------- MENU STUFF --------------------
if RequiredScript == "lib/managers/menumanager" then

  Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInitPlayerRandomizer", function(loc)
    loc:load_localization_file(Randomizer.mod_path .. "loc/english.txt")
    for _, filename in pairs(file.GetFiles(Randomizer.mod_path .. "loc/")) do
      local str = filename:match('^(.*).txt$')
      if str and Idstring(str) and Idstring(str):key() == SystemInfo:language():key() then
        loc:load_localization_file(Randomizer.mod_path .. "loc/" .. filename)
        break
      end
    end
  end)

  local menu_id_main = "PlayerRandomizerMenu"
  Hooks:Add("MenuManagerSetupCustomMenus", "MenuManagerSetupCustomMenusPlayerRandomizer", function(menu_manager, nodes)
    MenuHelper:NewMenu(menu_id_main)
  end)

  Hooks:Add("MenuManagerPopulateCustomMenus", "MenuManagerPopulateCustomMenusPlayerRandomizer", function(menu_manager, nodes)
    
    Randomizer:load()
    
    MenuCallbackHandler.Randomizer_toggle = function(self, item)
      Randomizer.data[item:name()] = (item:value() == "on");
      Randomizer:save()
    end

    MenuHelper:AddToggle({
      id = "random_primary",
      title = "bm_menu_primaries",
      desc = "primary_desc",
      callback = "Randomizer_toggle",
      value = Randomizer.data.random_primary,
      menu_id = menu_id_main,
      priority = 100
    })
    MenuHelper:AddToggle({
      id = "random_secondary",
      title = "bm_menu_secondaries",
      desc = "secondary_desc",
      callback = "Randomizer_toggle",
      value = Randomizer.data.random_secondary,
      menu_id = menu_id_main,
      priority = 99
    })
    MenuHelper:AddToggle({
      id = "random_melee",
      title = "bm_menu_melee_weapons",
      desc = "melee_desc",
      callback = "Randomizer_toggle",
      value = Randomizer.data.random_melee,
      menu_id = menu_id_main,
      priority = 98
    })
    MenuHelper:AddToggle({
      id = "random_grenade",
      title = "bm_menu_grenades",
      desc = "grenade_desc",
      callback = "Randomizer_toggle",
      value = Randomizer.data.random_grenade,
      menu_id = menu_id_main,
      priority = 97
    })
    
  end)

  Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenusPlayerRandomizer", function(menu_manager, nodes)
    nodes[menu_id_main] = MenuHelper:BuildMenu(menu_id_main)
    MenuHelper:AddMenuItem(MenuHelper:GetMenu("lua_mod_options_menu"), menu_id_main, "Randomizer_menu_main_name", "Randomizer_menu_main_desc")
  end)

end