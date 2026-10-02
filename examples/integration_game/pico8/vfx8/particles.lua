-- VFX8 particle system for PICO-8.
-- Include this file in a cartridge; it defines vfx8_particles.

vfx8_particles = vfx8_particles or {}

local p8_particle_profiles = {
  capacity = {24, 48, 72},
  max_emit = {12, 24, 32}
}

local p8_particle_presets = {
  {name = "explosion", count = {10, 16, 22}, life = 0.42, speed = 42, gravity = 18, drag = 0.7, size = 3, end_size = 0, c1 = 9, c2 = 10, c3 = 7, radial = true},
  {name = "sparks", count = {8, 12, 18}, life = 0.30, speed = 58, gravity = 34, drag = 0.25, size = 2, end_size = 1, c1 = 10, c2 = 9, c3 = 7, radial = true},
  {name = "trail", count = {1, 2, 3}, life = 0.24, speed = 8, gravity = 2, drag = 1.2, size = 2, end_size = 0, c1 = 12, c2 = 13, c3 = 1},
  {name = "smoke", count = {5, 8, 12}, life = 0.72, speed = 13, gravity = -8, drag = 1.4, size = 3, end_size = 1, c1 = 5, c2 = 6, c3 = 13},
  {name = "dust", count = {6, 10, 14}, life = 0.32, speed = 17, gravity = 24, drag = 2.0, size = 2, end_size = 0, c1 = 4, c2 = 5, c3 = 6}
}

local p8_dir_x = {1, 0.707, 0, -0.707, -1, -0.707, 0, 0.707}
local p8_dir_y = {0, 0.707, 1, 0.707, 0, -0.707, -1, -0.707}
local p8_empty_options = {}
local p8_methods = {}

local function p8_particle_profile(value)
  if value == "medium" or value == 2 then return 2 end
  if value == "high" or value == 3 then return 3 end
  return 1
end

local function p8_particle_preset(value)
  for i = 1, 5 do
    if p8_particle_presets[i].name == value then return i end
  end
  return 0
end

local function p8_particle_random(self)
  self.seed = (self.seed * 17 + 31) % 251
  return self.seed / 251
end

function vfx8_particles.new(options)
  options = options or p8_empty_options
  local profile = p8_particle_profile(options.quality)
  local capacity = flr(options.capacity or p8_particle_profiles.capacity[profile])
  if capacity < 1 then capacity = 1 end
  if capacity > 96 then capacity = 96 end
  local max_emit = flr(options.max_emit or p8_particle_profiles.max_emit[profile])
  if max_emit < 1 then max_emit = 1 end
  if max_emit > capacity then max_emit = capacity end
  local seed = flr(options.seed or 1) % 251
  if seed < 1 then seed = 1 end

  local self = {
    profile = profile,
    capacity = capacity,
    max_emit = max_emit,
    count = 0,
    frame_used = 0,
    last_emitted = 0,
    seed = seed,
    x = {}, y = {}, vx = {}, vy = {}, age = {}, life = {},
    size = {}, end_size = {}, gravity = {}, drag = {}, kind = {}
  }
  for i = 1, capacity do
    self.x[i], self.y[i], self.vx[i], self.vy[i] = 0, 0, 0, 0
    self.age[i], self.life[i] = 0, 0
    self.size[i], self.end_size[i] = 0, 0
    self.gravity[i], self.drag[i], self.kind[i] = 0, 0, 0
  end
  self.emit = p8_methods.emit
  self.emit_line = p8_methods.emit_line
  self.emit_area = p8_methods.emit_area
  self.update = p8_methods.update
  self.draw = p8_methods.draw
  self.clear = p8_methods.clear
  self.stats = p8_methods.stats
  return self
end

function p8_methods._emit(self, preset_name, ax, ay, bx, by, width, height, shape, options)
  local kind = p8_particle_preset(preset_name)
  if kind == 0 then return 0 end
  options = options or p8_empty_options
  local preset = p8_particle_presets[kind]
  local requested = flr(options.count or preset.count[self.profile])
  if requested < 1 then return 0 end
  local spawn = requested
  local frame_room = self.max_emit - self.frame_used
  local pool_room = self.capacity - self.count
  if spawn > frame_room then spawn = frame_room end
  if spawn > pool_room then spawn = pool_room end
  if spawn < 1 then return 0 end

  local base_speed = options.speed or preset.speed
  local gravity = options.gravity
  if gravity == nil then gravity = preset.gravity end
  local drag = options.drag
  if drag == nil then drag = preset.drag end
  local life = options.life
  if life == nil then life = preset.life end
  if life < 0.05 then life = 0.05 end
  local spread = options.spread or 0

  for n = 1, spawn do
    local px, py = ax, ay
    if shape == 2 then
      local t = 0.5
      if spawn > 1 then t = (n - 1) / (spawn - 1) end
      px = ax + (bx - ax) * t
      py = ay + (by - ay) * t
      px += (p8_particle_random(self) - 0.5) * spread
      py += (p8_particle_random(self) - 0.5) * spread
    elseif shape == 3 then
      px = ax + p8_particle_random(self) * width
      py = ay + p8_particle_random(self) * height
    else
      px += (p8_particle_random(self) - 0.5) * spread
      py += (p8_particle_random(self) - 0.5) * spread
    end

    local speed = base_speed * (0.55 + p8_particle_random(self) * 0.75)
    local vx, vy
    if preset.radial then
      local direction = (n - 1 + flr(p8_particle_random(self) * 8)) % 8 + 1
      vx = p8_dir_x[direction] * speed
      vy = p8_dir_y[direction] * speed
    elseif kind == 3 then
      vx = (p8_particle_random(self) - 0.5) * speed
      vy = (p8_particle_random(self) - 0.5) * speed * 0.45
    elseif kind == 4 then
      vx = (p8_particle_random(self) - 0.5) * speed * 0.65
      vy = -p8_particle_random(self) * speed
    else
      vx = (p8_particle_random(self) - 0.5) * speed
      vy = -p8_particle_random(self) * speed * 0.45
    end

    local i = self.count + 1
    self.count = i
    self.x[i], self.y[i] = px, py
    self.vx[i], self.vy[i] = vx, vy
    self.age[i], self.life[i] = 0, life
    local end_size = options.end_size
    if end_size == nil then end_size = preset.end_size end
    self.size[i], self.end_size[i] = preset.size, end_size
    self.gravity[i], self.drag[i], self.kind[i] = gravity, drag, kind
  end

  self.frame_used += spawn
  return spawn
end

function p8_methods.emit(self, preset, x, y, options)
  return p8_methods._emit(self, preset, x, y, x, y, 0, 0, 1, options)
end

function p8_methods.emit_line(self, preset, x1, y1, x2, y2, options)
  return p8_methods._emit(self, preset, x1, y1, x2, y2, 0, 0, 2, options)
end

function p8_methods.emit_area(self, preset, x, y, width, height, options)
  if width < 0 then width = 0 end
  if height < 0 then height = 0 end
  return p8_methods._emit(self, preset, x, y, x, y, width, height, 3, options)
end

function p8_methods.update(self, dt)
  dt = dt or 1 / 60
  if dt < 0 then dt = 0 end
  if dt > 0.1 then dt = 0.1 end
  local x, y, vx, vy = self.x, self.y, self.vx, self.vy
  local ages, lives = self.age, self.life
  local gravity, drag = self.gravity, self.drag
  local sizes, end_sizes, kinds = self.size, self.end_size, self.kind
  local count = self.count
  local i = 1
  while i <= count do
    local particle_age = ages[i] + dt
    if particle_age >= lives[i] then
      local last = count
      x[i], y[i], vx[i], vy[i] = x[last], y[last], vx[last], vy[last]
      ages[i], lives[i] = ages[last], lives[last]
      sizes[i], end_sizes[i] = sizes[last], end_sizes[last]
      gravity[i], drag[i], kinds[i] = gravity[last], drag[last], kinds[last]
      count = last - 1
    else
      local keep = 1 - drag[i] * dt
      if keep < 0 then keep = 0 end
      ages[i] = particle_age
      vx[i] *= keep
      vy[i] = vy[i] * keep + gravity[i] * dt
      x[i] += vx[i] * dt
      y[i] += vy[i] * dt
      i += 1
    end
  end
  self.count = count
  self.last_emitted = self.frame_used
  self.frame_used = 0
end

function p8_methods.draw(self)
  local x, y, ages, lives = self.x, self.y, self.age, self.life
  local kinds, sizes, end_sizes = self.kind, self.size, self.end_size
  for i = 1, self.count do
    local preset = p8_particle_presets[kinds[i]]
    local t = ages[i] / lives[i]
    local col = preset.c1
    if t >= 0.34 and t < 0.72 then col = preset.c2 end
    if t >= 0.72 then col = preset.c3 end
    local size = flr(sizes[i] + (end_sizes[i] - sizes[i]) * t + 0.5)
    if size > 0 then
      local px, py = flr(x[i] + 0.5), flr(y[i] + 0.5)
      rectfill(px, py, px + size - 1, py + size - 1, col)
    end
  end
end

function p8_methods.clear(self)
  self.count = 0
  self.frame_used = 0
  self.last_emitted = 0
end

function p8_methods.stats(self)
  return self.count, self.capacity, self.last_emitted
end
