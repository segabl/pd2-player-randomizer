function FPCameraPlayerBase:spawn_grenade()
	if alive(self._grenade_unit) then
		return
	end
	local align_obj_l_name = Idstring("a_weapon_left")
	local align_obj_r_name = Idstring("a_weapon_right")
	local align_obj_l = self._unit:get_object(align_obj_l_name)
	local align_obj_r = self._unit:get_object(align_obj_r_name)
	local grenade_entry = managers.blackmarket:equipped_grenade()
  log("ABOUT TO SPAWN GRENADE!")
	self._grenade_unit = World:spawn_unit(Idstring(tweak_data.blackmarket.projectiles[grenade_entry].unit_dummy), align_obj_r:position(), align_obj_r:rotation())
  log("SPAWNED GRENADE, ABOUT TO LINK!")
	self._unit:link(align_obj_r:name(), self._grenade_unit, self._grenade_unit:orientation_object():name())
  log("LINKED GRENADE!")
end