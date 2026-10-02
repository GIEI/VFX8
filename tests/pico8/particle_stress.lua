-- Measure a saturated particle pool over 600 rendered frames.
function vfx8_particle_stress(quality, capacity)
  local particles = nil
  local frame, cpu_sum, cpu_min, cpu_max = 0, 0, 1, 0

  function _init()
    particles = vfx8_particles.new({quality = quality, capacity = capacity, max_emit = capacity, seed = 17})
    assert(particles:emit("explosion", 64, 48, {
      count = capacity, life = 100, speed = 20, gravity = 0, drag = 0
    }) == capacity, "particle pool did not accept its configured capacity")
    assert(particles:emit("sparks", 64, 48) == 0, "particle pool accepted an item past capacity")
  end

  function _update60()
    if particles then particles:update(1 / 60) end
  end

  function _draw()
    if not particles then return end
    cls(0)
    particles:draw()
    print(quality .. " PARTICLE STRESS " .. max(0, frame - 3) .. "/600", 2, 2, 7)
    if frame > 2 then
      local cpu = stat(1)
      cpu_sum += cpu
      cpu_min = min(cpu_min, cpu)
      cpu_max = max(cpu_max, cpu)
    end
    frame += 1
    if frame == 603 then
      printh("VFX8_PARTICLE_STRESS," .. quality .. ",600," .. cpu_sum / 600 .. "," .. cpu_min .. "," .. cpu_max)
      particles = nil
    end
  end
end
