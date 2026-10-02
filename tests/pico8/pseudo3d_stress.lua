-- Measure one bounded pseudo-3D profile over 600 steady frames.
function vfx8_pseudo3d_stress(quality, star_limit, object_limit)
  local scene = nil
  local frame = 0
  local sample_count = 0
  local cpu_sum = 0
  local cpu_min = 1
  local cpu_max = 0

  function _init()
    scene = vfx8_pseudo3d.new({quality = quality, width = 128, height = 96,
      horizon = 34, star_count = star_limit, object_capacity = object_limit, speed = 0})
    scene:set_mode7({width_tiles = 16, height_tiles = 16, scale = 0.55})
    for object = 1, object_limit do
      assert(scene:add_object((object % 3 - 1) * 0.5, 16 + object * 7, 11, 4), "object pool rejected an in-capacity item")
    end
    assert(scene.object_count == object_limit, "object pool was not saturated")
    assert(not scene:add_object(0, 80, 8, 4), "object pool accepted an item past capacity")
  end

  function _update60()
    if scene then scene:update(0) end
  end

  function _draw()
    if not scene then return end
    cls(0)
    scene:draw({sky = 1, ground = 3, road_a = 1, road_b = 13, edge = 11})
    print(quality .. " MODE 7 STRESS " .. sample_count .. "/600", 2, 2, 7)
    if frame > 2 then
      local cpu = stat(1)
      sample_count += 1
      cpu_sum += cpu
      cpu_min = min(cpu_min, cpu)
      cpu_max = max(cpu_max, cpu)
    end
    frame += 1
    if sample_count == 600 then
      printh("VFX8_STRESS," .. quality .. "," .. sample_count .. "," .. cpu_sum / sample_count .. "," .. cpu_min .. "," .. cpu_max)
      scene = nil
    end
  end
end
