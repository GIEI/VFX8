-- VFX8 flame effects for Picotron.
-- Include this file once from the cartridge root.

vfx8_flames = vfx8_flames or {}
local methods = {}
local capacities = {48, 96, 160}
local emission_caps = {16, 32, 48}
local jet_counts = {8, 12, 18}
local fire_counts = {3, 5, 8}
local empty_options = {}

function vfx8_flames.new(options)
  options = options or {}
  local profile = 1
  if options.quality == "medium" or options.quality == 2 then profile = 2 end
  if options.quality == "high" or options.quality == 3 then profile = 3 end
  local capacity = flr(options.capacity or capacities[profile])
  capacity = max(1, min(256, capacity))
  local max_emit = max(1, min(capacity, flr(options.max_emit or emission_caps[profile])))
  local seed = flr(options.seed or 1) % 251
  if seed < 1 then seed = 1 end
  local self = {profile = profile, capacity = capacity, max_emit = max_emit,
    count = 0, frame_used = 0, last_emitted = 0, seed = seed,
    x = {}, y = {}, vx = {}, vy = {}, age = {}, life = {}, size = {}, end_size = {},
    gravity = {}, drag = {}, wind_x = {}, wind_y = {}, kind = {}, color_1 = {}, color_2 = {}, color_3 = {}, color_4 = {}, flicker = {}, flicker_speed = {}}
  for i = 1, capacity do
    self.x[i], self.y[i], self.vx[i], self.vy[i] = 0, 0, 0, 0
    self.age[i], self.life[i], self.size[i], self.end_size[i] = 0, 0, 0, 0
    self.gravity[i], self.drag[i], self.wind_x[i], self.wind_y[i], self.kind[i] = 0, 0, 0, 0, 0
    self.color_1[i], self.color_2[i], self.color_3[i], self.color_4[i] = 0, 0, 0, 0
    self.flicker[i], self.flicker_speed[i] = 0, 0
  end
  self.emit_jet, self.emit_campfire = methods.emit_jet, methods.emit_campfire
  self.update, self.draw = methods.update, methods.draw
  self.clear, self.stats = methods.clear, methods.stats
  return self
end

local function random(self)
  self.seed = (self.seed * 17 + 31) % 251
  return self.seed / 251
end

local function emit(self, kind, x, y, dx, dy, options)
  options = options or empty_options
  local requested = flr(options.count or options.emission_rate or (kind == 1 and jet_counts[self.profile] or fire_counts[self.profile]))
  if requested < 1 then return 0 end
  local spawn = min(requested, self.max_emit - self.frame_used, self.capacity - self.count)
  if spawn < 1 then return 0 end
  local life = max(0.05, options.life or (kind == 1 and 0.42 or 0.72))
  local speed = options.speed or (kind == 1 and 92 or 42)
  if kind == 1 and options.distance ~= nil then speed = max(0, options.distance) / life end
  if kind == 2 and options.height ~= nil then speed = max(0, options.height) / life end
  local spread = options.spread
  if spread == nil then spread = kind == 1 and 0.22 or 5 end
  spread = max(0, spread)
  local radius = max(0, options.width and options.width * 0.5 or options.base_radius or options.radius or 1)
  local fire_radius = max(0, options.base_radius or options.radius or spread)
  local gravity = options.gravity
  if gravity == nil then gravity = kind == 1 and 8 or -3 end
  local drag = options.drag
  if drag == nil then drag = kind == 1 and 1.2 or 0.9 end
  local base_size = max(1, options.size or (kind == 1 and 3 or 4))
  local end_size = options.end_size
  if end_size == nil then end_size = base_size * 0.18 end
  local wind = options.wind or empty_options
  local wind_x, wind_y = wind.x or wind[1] or 0, wind.y or wind[2] or 0
  local flicker = options.flicker == nil and 1 or options.flicker
  local flicker_speed = options.flicker_speed or 0
  local colors = options.colors or empty_options
  local c1, c2, c3, c4 = colors[1] or (kind == 1 and 7 or 10), colors[2] or (kind == 1 and 10 or 9), colors[3] or (kind == 1 and 9 or 8), colors[4] or (kind == 1 and 8 or 4)
  for n = 1, spawn do
    local px, py, vx, vy
    if kind == 1 then
      local offset = (random(self) - 0.5) * 2 * radius
      local along = speed * (0.72 + random(self) * 0.56)
      local side = (random(self) - 0.5) * 2 * spread * speed
      px, py = x - dy * offset, y + dx * offset
      vx, vy = dx * along - dy * side, dy * along + dx * side
    else
      px = x + (random(self) - 0.5) * fire_radius * 2
      py = y + random(self) * 2
      vx = (random(self) - 0.5) * speed * 0.48
      vy = -speed * (0.68 + random(self) * 0.64)
    end
    local i = self.count + 1
    self.count = i
    self.x[i], self.y[i], self.vx[i], self.vy[i] = px, py, vx, vy
    local variation = 0.72 + random(self) * 0.56
    self.age[i], self.life[i] = 0, life
    self.size[i], self.end_size[i] = base_size * (1 + (variation - 1) * flicker), end_size
    self.gravity[i], self.drag[i], self.wind_x[i], self.wind_y[i], self.kind[i] = gravity, drag, wind_x, wind_y, kind
    self.color_1[i], self.color_2[i], self.color_3[i], self.color_4[i] = c1, c2, c3, c4
    self.flicker[i], self.flicker_speed[i] = flicker, flicker_speed
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

function methods.emit_campfire(self, x, y, options) return emit(self, 2, x, y, 0, -1, options) end

function methods.update(self, dt)
  dt = min(0.1, max(0, dt or 1 / 60))
  local x, y, vx, vy = self.x, self.y, self.vx, self.vy
  local ages, lives = self.age, self.life
  local gravity, drag = self.gravity, self.drag
  local sizes, ends, kinds = self.size, self.end_size, self.kind
  local wind_x, wind_y = self.wind_x, self.wind_y
  local count, i = self.count, 1
  while i <= count do
    local age = ages[i] + dt
    if age >= lives[i] then
      local last = count
      x[i], y[i], vx[i], vy[i] = x[last], y[last], vx[last], vy[last]
      ages[i], lives[i], sizes[i], ends[i] = ages[last], lives[last], sizes[last], ends[last]
      gravity[i], drag[i], wind_x[i], wind_y[i], kinds[i] = gravity[last], drag[last], wind_x[last], wind_y[last], kinds[last]
      self.color_1[i], self.color_2[i], self.color_3[i], self.color_4[i] = self.color_1[last], self.color_2[last], self.color_3[last], self.color_4[last]
      self.flicker[i], self.flicker_speed[i] = self.flicker[last], self.flicker_speed[last]
      count = last - 1
    else
      local keep = max(0, 1 - drag[i] * dt)
      ages[i] = age
      vx[i], vy[i] = vx[i] * keep + wind_x[i] * dt, vy[i] * keep + (gravity[i] + wind_y[i]) * dt
      x[i], y[i] = x[i] + vx[i] * dt, y[i] + vy[i] * dt
      i = i + 1
    end
  end
  self.count = count
  self.last_emitted, self.frame_used = self.frame_used, 0
end

function methods.draw(self)
  local x, y, ages, lives = self.x, self.y, self.age, self.life
  local sizes, ends, kinds = self.size, self.end_size, self.kind
  for i = 1, self.count do
    local t = ages[i] / lives[i]
    local col
    if kinds[i] == 1 then
      col = t < 0.18 and self.color_1[i] or (t < 0.48 and self.color_2[i] or (t < 0.78 and self.color_3[i] or self.color_4[i]))
    else
      col = t < 0.30 and self.color_1[i] or (t < 0.68 and self.color_2[i] or (t < 0.90 and self.color_3[i] or self.color_4[i]))
    end
    local flicker_scale = 1 + self.flicker[i] * 0.12 * sin(ages[i] * self.flicker_speed[i])
    local size = max(1, flr((sizes[i] + (ends[i] - sizes[i]) * t) * flicker_scale + 0.5))
    local px, py = flr(x[i] + 0.5), flr(y[i] + 0.5)
    rectfill(px, py, px + size - 1, py + size, col)
  end
end

function methods.clear(self) self.count, self.frame_used, self.last_emitted = 0, 0, 0 end
function methods.stats(self) return self.count, self.capacity, self.last_emitted end
