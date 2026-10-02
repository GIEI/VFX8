-- VFX8 particle system for LÖVE.
-- Copy this module into your project as vfx8/particles.lua.

local particles = {}

local profile_capacity = {128, 320, 640}
local profile_emit = {96, 192, 384}
local presets = {
  {name = "explosion", count = {16, 28, 40}, life = 0.48, speed = 52, gravity = 26, drag = 0.7, size = 4, end_size = 0, c1 = 9, c2 = 10, c3 = 7, radial = true},
  {name = "sparks", count = {12, 22, 32}, life = 0.34, speed = 70, gravity = 42, drag = 0.25, size = 3, end_size = 1, c1 = 10, c2 = 9, c3 = 7, radial = true},
  {name = "trail", count = {2, 4, 6}, life = 0.30, speed = 10, gravity = 2, drag = 1.2, size = 3, end_size = 0, c1 = 12, c2 = 13, c3 = 1},
  {name = "smoke", count = {8, 14, 22}, life = 0.90, speed = 16, gravity = -10, drag = 1.4, size = 5, end_size = 1, c1 = 5, c2 = 6, c3 = 13},
  {name = "dust", count = {10, 18, 26}, life = 0.40, speed = 22, gravity = 28, drag = 2.0, size = 3, end_size = 0, c1 = 4, c2 = 5, c3 = 6}
}

local dir_x = {1, 0.707, 0, -0.707, -1, -0.707, 0, 0.707}
local dir_y = {0, 0.707, 1, 0.707, 0, -0.707, -1, -0.707}
local palette = {
  {0.00, 0.00, 0.00}, {0.11, 0.17, 0.33}, {0.49, 0.15, 0.33}, {0.00, 0.53, 0.32},
  {0.67, 0.32, 0.21}, {0.37, 0.34, 0.31}, {0.76, 0.76, 0.78}, {1.00, 1.00, 1.00},
  {1.00, 0.00, 0.30}, {1.00, 0.64, 0.00}, {1.00, 0.93, 0.15}, {0.00, 0.89, 0.21},
  {0.16, 0.68, 1.00}, {0.51, 0.46, 0.61}, {1.00, 0.47, 0.66}, {1.00, 0.80, 0.67}
}

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

function particles.new(options)
  options = options or empty_options
  local profile = profile_index(options.quality)
  local capacity = math.floor(options.capacity or profile_capacity[profile])
  capacity = math.max(1, math.min(capacity, 1024))
  local max_emit = math.floor(options.max_emit or profile_emit[profile])
  max_emit = math.max(1, math.min(max_emit, capacity))
  local seed = math.floor(options.seed or 1) % 251
  if seed < 1 then seed = 1 end

  local self = {
    profile = profile, capacity = capacity, max_emit = max_emit,
    count = 0, frame_used = 0, last_emitted = 0, seed = seed,
    x = {}, y = {}, vx = {}, vy = {}, age = {}, life = {},
    size = {}, end_size = {}, gravity = {}, drag = {}, kind = {}
  }
  for i = 1, capacity do
    self.x[i], self.y[i], self.vx[i], self.vy[i] = 0, 0, 0, 0
    self.age[i], self.life[i] = 0, 0
    self.size[i], self.end_size[i] = 0, 0
    self.gravity[i], self.drag[i], self.kind[i] = 0, 0, 0
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
  life = math.max(0.05, life)
  local spread = options.spread or 0

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
    end

    local speed = base_speed * (0.55 + random(self) * 0.75)
    local vx, vy
    if preset.radial then
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
    self.size[i], self.end_size[i] = preset.size, end_size
    self.gravity[i], self.drag[i], self.kind[i] = gravity, drag, kind
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
  width, height = math.max(0, width), math.max(0, height)
  return methods._emit(self, preset, x, y, x, y, width, height, 3, options)
end

function methods.update(self, dt)
  dt = math.max(0, math.min(dt or 1 / 60, 0.1))
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
      local keep = math.max(0, 1 - drag[i] * dt)
      ages[i] = particle_age
      vx[i] = vx[i] * keep
      vy[i] = vy[i] * keep + gravity[i] * dt
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
  local old_r, old_g, old_b, old_a = love.graphics.getColor()
  local x, y, ages, lives = self.x, self.y, self.age, self.life
  local kinds, sizes, end_sizes = self.kind, self.size, self.end_size
  for i = 1, self.count do
    local preset = presets[kinds[i]]
    local t = ages[i] / lives[i]
    local color_index = preset.c1
    if t >= 0.34 and t < 0.72 then color_index = preset.c2 end
    if t >= 0.72 then color_index = preset.c3 end
    local rgb = palette[color_index + 1]
    local size = math.floor(sizes[i] + (end_sizes[i] - sizes[i]) * t + 0.5)
    if size > 0 then
      local px, py = math.floor(x[i] + 0.5), math.floor(y[i] + 0.5)
      love.graphics.setColor(rgb[1], rgb[2], rgb[3], 1)
      love.graphics.rectangle("fill", px, py, size, size)
    end
  end
  love.graphics.setColor(old_r, old_g, old_b, old_a)
end

function methods.clear(self)
  self.count = 0
  self.frame_used = 0
  self.last_emitted = 0
end

function methods.stats(self)
  return self.count, self.capacity, self.last_emitted
end

return particles
