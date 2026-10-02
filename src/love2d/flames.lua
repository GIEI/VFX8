-- VFX8 flame effects for LÖVE.
-- Copy this module into your project as vfx8/flames.lua.

local flames = {}
local methods = {}
local flr, sqrt, max, min = math.floor, math.sqrt, math.max, math.min
local capacity_by_profile = {128, 256, 512}
local emission_by_profile = {32, 64, 128}
local jet_count_by_profile = {6, 10, 14}
local fire_count_by_profile = {2, 4, 6}
local colors = {
  {1.00, 0.96, 0.57}, {1.00, 0.73, 0.16},
  {1.00, 0.34, 0.06}, {0.68, 0.09, 0.025}
}
local empty_options = {}

local function profile_index(value)
  if value == "medium" or value == 2 then return 2 end
  if value == "high" or value == 3 then return 3 end
  return 1
end

local function random(self)
  self.seed = (self.seed * 17 + 31) % 251
  return self.seed / 251
end

function flames.new(options)
  options = options or empty_options
  local profile = profile_index(options.quality)
  local capacity = max(1, min(512, flr(options.capacity or capacity_by_profile[profile])))
  local max_emit = max(1, min(capacity, flr(options.max_emit or emission_by_profile[profile])))
  local seed = flr(options.seed or 1) % 251
  if seed < 1 then seed = 1 end
  local self = {
    profile = profile, capacity = capacity, max_emit = max_emit,
    count = 0, frame_used = 0, last_emitted = 0, seed = seed,
    x = {}, y = {}, vx = {}, vy = {}, age = {}, life = {},
    size = {}, gravity = {}, drag = {}, kind = {}
  }
  for i = 1, capacity do
    self.x[i], self.y[i], self.vx[i], self.vy[i] = 0, 0, 0, 0
    self.age[i], self.life[i], self.size[i] = 0, 0, 0
    self.gravity[i], self.drag[i], self.kind[i] = 0, 0, 0
  end
  self.emit_jet, self.emit_campfire = methods.emit_jet, methods.emit_campfire
  self.update, self.draw = methods.update, methods.draw
  self.clear, self.stats = methods.clear, methods.stats
  return self
end

local function emit(self, kind, x, y, dx, dy, options)
  options = options or empty_options
  local requested = flr(options.count or (kind == 1 and jet_count_by_profile[self.profile] or fire_count_by_profile[self.profile]))
  if requested < 1 then return 0 end
  local spawn = min(requested, self.max_emit - self.frame_used, self.capacity - self.count)
  if spawn < 1 then return 0 end

  local speed = options.speed or (kind == 1 and 92 or 42)
  local spread = options.spread
  if spread == nil then spread = kind == 1 and 0.22 or 5 end
  spread = max(0, spread)
  local radius = max(0, options.radius or 1)
  local gravity = options.gravity
  if gravity == nil then gravity = kind == 1 and 8 or -3 end
  local drag = options.drag
  if drag == nil then drag = kind == 1 and 1.2 or 0.9 end
  local life = max(0.05, options.life or (kind == 1 and 0.42 or 0.72))
  local base_size = max(1, options.size or (kind == 1 and 3 or 4))

  for n = 1, spawn do
    local px, py, vx, vy
    if kind == 1 then
      local offset = (random(self) - 0.5) * 2 * radius
      local along = speed * (0.72 + random(self) * 0.56)
      local side = (random(self) - 0.5) * 2 * spread * speed
      px, py = x - dy * offset, y + dx * offset
      vx, vy = dx * along - dy * side, dy * along + dx * side
    else
      px = x + (random(self) - 0.5) * spread * 2
      py = y + random(self) * 2
      vx = (random(self) - 0.5) * speed * 0.48
      vy = -speed * (0.68 + random(self) * 0.64)
    end
    local i = self.count + 1
    self.count = i
    self.x[i], self.y[i], self.vx[i], self.vy[i] = px, py, vx, vy
    self.age[i], self.life[i], self.size[i] = 0, life, base_size * (0.72 + random(self) * 0.56)
    self.gravity[i], self.drag[i], self.kind[i] = gravity, drag, kind
  end
  self.frame_used = self.frame_used + spawn
  return spawn
end

function methods.emit_jet(self, x, y, dx, dy, options)
  dx, dy = dx or 0, dy or 0
  local length = sqrt(dx * dx + dy * dy)
  if length <= 0 then return 0 end
  return emit(self, 1, x, y, dx / length, dy / length, options)
end

function methods.emit_campfire(self, x, y, options)
  return emit(self, 2, x, y, 0, -1, options)
end

function methods.update(self, dt)
  dt = max(0, min(0.1, dt or 1 / 60))
  local x, y, vx, vy = self.x, self.y, self.vx, self.vy
  local ages, lives = self.age, self.life
  local gravity, drag = self.gravity, self.drag
  local sizes, kinds = self.size, self.kind
  local count, i = self.count, 1
  while i <= count do
    local age = ages[i] + dt
    if age >= lives[i] then
      local last = count
      x[i], y[i], vx[i], vy[i] = x[last], y[last], vx[last], vy[last]
      ages[i], lives[i], sizes[i] = ages[last], lives[last], sizes[last]
      gravity[i], drag[i], kinds[i] = gravity[last], drag[last], kinds[last]
      count = last - 1
    else
      local keep = max(0, 1 - drag[i] * dt)
      ages[i] = age
      vx[i] = vx[i] * keep
      vy[i] = vy[i] * keep + gravity[i] * dt
      x[i], y[i] = x[i] + vx[i] * dt, y[i] + vy[i] * dt
      i = i + 1
    end
  end
  self.count, self.last_emitted, self.frame_used = count, self.frame_used, 0
end

function methods.draw(self)
  local old_r, old_g, old_b, old_a = love.graphics.getColor()
  local x, y, ages, lives = self.x, self.y, self.age, self.life
  local sizes, kinds = self.size, self.kind
  for i = 1, self.count do
    local t = ages[i] / lives[i]
    local ramp
    if kinds[i] == 1 then
      ramp = t < 0.18 and 1 or (t < 0.48 and 2 or (t < 0.78 and 3 or 4))
    else
      ramp = t < 0.30 and 1 or (t < 0.68 and 2 or (t < 0.90 and 3 or 4))
    end
    local rgb = colors[ramp]
    local size = max(1, flr(sizes[i] * (1 - t * 0.82) + 0.5))
    love.graphics.setColor(rgb[1], rgb[2], rgb[3], 1)
    love.graphics.rectangle("fill", flr(x[i] + 0.5), flr(y[i] + 0.5), size, size * 1.5)
  end
  love.graphics.setColor(old_r, old_g, old_b, old_a)
end

function methods.clear(self)
  self.count, self.frame_used, self.last_emitted = 0, 0, 0
end

function methods.stats(self)
  return self.count, self.capacity, self.last_emitted
end

return flames
