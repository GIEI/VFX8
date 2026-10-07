-- VFX8 particle system for TIC-80.
-- Include this file at build time; it defines vfx8_particles.

vfx8_particles = vfx8_particles or {}

local profile_capacity = {48, 96, 160}
local profile_emit = {32, 64, 96}
local presets = {
  {name = "explosion", count = {10, 16, 24}, life = 0.42, speed = 44, gravity = 20, drag = 0.7, size = 3, end_size = 0, c1 = 9, c2 = 10, c3 = 7, radial = true},
  {name = "sparks", count = {8, 14, 20}, life = 0.30, speed = 58, gravity = 36, drag = 0.25, size = 2, end_size = 1, c1 = 10, c2 = 9, c3 = 7, radial = true},
  {name = "trail", count = {1, 2, 4}, life = 0.25, speed = 8, gravity = 2, drag = 1.2, size = 2, end_size = 0, c1 = 12, c2 = 13, c3 = 1},
  {name = "smoke", count = {5, 9, 14}, life = 0.75, speed = 13, gravity = -8, drag = 1.4, size = 3, end_size = 1, c1 = 5, c2 = 6, c3 = 13},
  {name = "dust", count = {6, 11, 16}, life = 0.34, speed = 18, gravity = 24, drag = 2.0, size = 2, end_size = 0, c1 = 4, c2 = 5, c3 = 6}
}

local dir_x = {1, 0.707, 0, -0.707, -1, -0.707, 0, 0.707}
local dir_y = {0, 0.707, 1, 0.707, 0, -0.707, -1, -0.707}
local empty_options = {}
local methods = {}

local function profile_index(value)
  if value == "medium" or value == 2 then return 2 end
  if value == "high" or value == 3 then return 3 end
  return 1
end

local function preset_index(value)
  for i = 1, 5 do
    if presets[i].name == value then return i end
  end
  return 0
end

local function random(self)
  self.seed = (self.seed * 17 + 31) % 251
  return self.seed / 251
end

function vfx8_particles.new(options)
  options = options or empty_options
  local profile = profile_index(options.quality)
  local capacity = math.floor(options.capacity or profile_capacity[profile])
  if capacity < 1 then capacity = 1 end
  if capacity > 256 then capacity = 256 end
  local max_emit = math.floor(options.max_emit or profile_emit[profile])
  if max_emit < 1 then max_emit = 1 end
  if max_emit > capacity then max_emit = capacity end
  local seed = math.floor(options.seed or 1) % 251
  if seed < 1 then seed = 1 end

  local self = {
    profile = profile, capacity = capacity, max_emit = max_emit,
    count = 0, frame_used = 0, last_emitted = 0, seed = seed,
    x = {}, y = {}, vx = {}, vy = {}, age = {}, life = {},
    size = {}, end_size = {}, gravity = {}, drag = {}, wind_x = {}, wind_y = {}, color_1 = {}, color_2 = {}, color_3 = {}, kind = {}
  }
  for i = 1, capacity do
    self.x[i], self.y[i], self.vx[i], self.vy[i] = 0, 0, 0, 0
    self.age[i], self.life[i] = 0, 0
    self.size[i], self.end_size[i] = 0, 0
    self.gravity[i], self.drag[i], self.wind_x[i], self.wind_y[i], self.kind[i] = 0, 0, 0, 0, 0
    self.color_1[i], self.color_2[i], self.color_3[i] = 0, 0, 0
  end
  self.emit, self.emit_line, self.emit_area = methods.emit, methods.emit_line, methods.emit_area
  self.update, self.draw, self.clear, self.stats = methods.update, methods.draw, methods.clear, methods.stats
  return self
end

function methods._emit(self, preset_name, ax, ay, bx, by, width, height, shape, options)
  local kind = preset_index(preset_name)
  if kind == 0 then return 0 end
  options = options or empty_options
  local preset = presets[kind]
  local requested = math.floor(options.count or preset.count[self.profile])
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
  local wind = options.wind or empty_options
  local wind_x, wind_y = wind.x or wind[1] or 0, wind.y or wind[2] or 0
  local min_speed, max_speed = options.min_speed, options.max_speed
  local custom_direction = options.direction
  local direction_spread = options.direction_spread or 0
  local start_size = options.start_size
  if start_size == nil then start_size = options.size end
  if start_size == nil then start_size = preset.size end
  local colors = options.colors
  local color_1 = colors and colors[1] or preset.c1
  local color_2 = colors and colors[2] or preset.c2
  local color_3 = colors and colors[3] or preset.c3
  if (options.rotation and options.rotation ~= 0) or (options.angular_speed and options.angular_speed ~= 0) then
    error("VFX8 particles use square pixels; rotation and angular_speed are unsupported")
  end
  if shape == 2 and options.spacing and options.spacing > 0 then
    local dx, dy = bx - ax, by - ay
    requested = math.max(1, math.floor(math.sqrt(dx * dx + dy * dy) / options.spacing) + 1)
    spawn = math.min(requested, frame_room, pool_room)
  end
  local emission_shape = options.emission_shape or (options.radius and "disc")
  local radius = options.radius or 0
  if emission_shape ~= nil and emission_shape ~= "point" and emission_shape ~= "ring" and emission_shape ~= "disc" then
    error("emission_shape must be point, ring, or disc")
  end
  if emission_shape ~= nil and emission_shape ~= "point" and shape ~= 1 then
    error("ring and disc emission shapes are supported only by emit()")
  end

  for n = 1, spawn do
    local px, py = ax, ay
    if shape == 2 then
      local t = 0.5
      if spawn > 1 then t = (n - 1) / (spawn - 1) end
      px = ax + (bx - ax) * t + (random(self) - 0.5) * spread
      py = ay + (by - ay) * t + (random(self) - 0.5) * spread
    elseif shape == 3 then
      px = ax + random(self) * width
      py = ay + random(self) * height
    else
      px = px + (random(self) - 0.5) * spread
      py = py + (random(self) - 0.5) * spread
      if (emission_shape == "ring" or emission_shape == "disc") and radius > 0 then
        local angle = random(self) * math.pi * 2
        local distance = radius
        if emission_shape == "disc" then distance = distance * math.sqrt(random(self)) end
        px, py = px + math.cos(angle) * distance, py + math.sin(angle) * distance
      end
    end

    local speed = base_speed * (0.55 + random(self) * 0.75)
    if min_speed ~= nil or max_speed ~= nil then
      local lo, hi = min_speed or base_speed, max_speed or base_speed
      speed = lo + random(self) * math.max(0, hi - lo)
    end
    local vx, vy
    if custom_direction then
      local dx, dy = custom_direction.x or custom_direction[1] or 0, custom_direction.y or custom_direction[2] or 0
      local length = math.sqrt(dx * dx + dy * dy)
      if length > 0 then
        dx, dy = dx / length, dy / length
        local side = (random(self) - 0.5) * 2 * direction_spread
        vx, vy = (dx - dy * side) * speed, (dy + dx * side) * speed
      else vx, vy = 0, 0 end
    elseif preset.radial then
      local direction = (n - 1 + math.floor(random(self) * 8)) % 8 + 1
      vx, vy = dir_x[direction] * speed, dir_y[direction] * speed
    elseif kind == 3 then
      vx = (random(self) - 0.5) * speed
      vy = (random(self) - 0.5) * speed * 0.45
    elseif kind == 4 then
      vx = (random(self) - 0.5) * speed * 0.65
      vy = -random(self) * speed
    else
      vx = (random(self) - 0.5) * speed
      vy = -random(self) * speed * 0.45
    end

    local i = self.count + 1
    self.count = i
    self.x[i], self.y[i], self.vx[i], self.vy[i] = px, py, vx, vy
    self.age[i], self.life[i] = 0, life
    local end_size = options.end_size
    if end_size == nil then end_size = preset.end_size end
    self.size[i], self.end_size[i] = start_size, end_size
    self.gravity[i], self.drag[i], self.wind_x[i], self.wind_y[i], self.kind[i] = gravity, drag, wind_x, wind_y, kind
    self.color_1[i], self.color_2[i], self.color_3[i] = color_1, color_2, color_3
  end
  self.frame_used = self.frame_used + spawn
  return spawn
end

function methods.emit(self, preset, x, y, options)
  return methods._emit(self, preset, x, y, x, y, 0, 0, 1, options)
end

function methods.emit_line(self, preset, x1, y1, x2, y2, options)
  return methods._emit(self, preset, x1, y1, x2, y2, 0, 0, 2, options)
end

function methods.emit_area(self, preset, x, y, width, height, options)
  if width < 0 then width = 0 end
  if height < 0 then height = 0 end
  return methods._emit(self, preset, x, y, x, y, width, height, 3, options)
end

function methods.update(self, dt)
  dt = dt or 1 / 60
  if dt < 0 then dt = 0 end
  if dt > 0.1 then dt = 0.1 end
  local x, y, vx, vy = self.x, self.y, self.vx, self.vy
  local ages, lives = self.age, self.life
  local gravity, drag = self.gravity, self.drag
  local sizes, end_sizes, kinds = self.size, self.end_size, self.kind
  local wind_x, wind_y = self.wind_x, self.wind_y
  local count = self.count
  local i = 1
  while i <= count do
    local particle_age = ages[i] + dt
    if particle_age >= lives[i] then
      local last = count
      x[i], y[i], vx[i], vy[i] = x[last], y[last], vx[last], vy[last]
      ages[i], lives[i] = ages[last], lives[last]
      sizes[i], end_sizes[i] = sizes[last], end_sizes[last]
      gravity[i], drag[i], wind_x[i], wind_y[i], kinds[i] = gravity[last], drag[last], wind_x[last], wind_y[last], kinds[last]
      self.color_1[i], self.color_2[i], self.color_3[i] = self.color_1[last], self.color_2[last], self.color_3[last]
      count = last - 1
    else
      local keep = 1 - drag[i] * dt
      if keep < 0 then keep = 0 end
      ages[i] = particle_age
      vx[i] = vx[i] * keep + wind_x[i] * dt
      vy[i] = vy[i] * keep + (gravity[i] + wind_y[i]) * dt
      x[i] = x[i] + vx[i] * dt
      y[i] = y[i] + vy[i] * dt
      i = i + 1
    end
  end
  self.count = count
  self.last_emitted = self.frame_used
  self.frame_used = 0
end

function methods.draw(self)
  local x, y, ages, lives = self.x, self.y, self.age, self.life
  local kinds, sizes, end_sizes = self.kind, self.size, self.end_size
  for i = 1, self.count do
    local t = ages[i] / lives[i]
    local color = self.color_1[i]
    if t >= 0.34 and t < 0.72 then color = self.color_2[i] end
    if t >= 0.72 then color = self.color_3[i] end
    local size = math.floor(sizes[i] + (end_sizes[i] - sizes[i]) * t + 0.5)
    if size > 0 then
      local px, py = math.floor(x[i] + 0.5), math.floor(y[i] + 0.5)
      rect(px, py, size, size, color)
    end
  end
end

function methods.clear(self)
  self.count = 0
  self.frame_used = 0
  self.last_emitted = 0
end

function methods.stats(self)
  return self.count, self.capacity, self.last_emitted
end
