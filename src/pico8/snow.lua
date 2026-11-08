-- VFX8 snow effects for PICO-8. Include this module once per cartridge.

vfx8_snow = vfx8_snow or {}
local snow = vfx8_snow
local methods = {}
local floor, min, max, sin = flr, min, max, sin
local capacities = {16, 24, 32}
local rates = {20, 70, 150}
local empty = {}

local function profile_index(value)
  if value == "medium" or value == 2 then return 2 end
  if value == "high" or value == 3 then return 3 end
  return 1
end

local function random(self)
  self.seed = (self.seed * 17 + 31) % 251
  return self.seed / 251
end

local function respawn(self, i, initial)
  self.x[i] = random(self) * self.width
  self.y[i] = initial and random(self) * self.height or -random(self) * 10 - 2
  self.speed[i] = self.fall_speed * (0.65 + random(self) * 0.7)
  self.phase[i] = random(self) * 6.2831853
  self.amplitude[i] = self.min_amplitude + random(self) * (self.max_amplitude - self.min_amplitude)
  self.frequency[i] = 1 + random(self) * 2
end

function snow.new(options)
  options = options or empty
  local profile = profile_index(options.quality)
  local width, height = max(1, options.width or 240), max(1, options.height or 136)
  local capacity = max(1, min(40, floor(options.capacity or capacities[profile])))
  local self = {profile = profile, width = width, height = height, capacity = capacity,
    count = capacity, seed = floor(options.seed or 1) % 251, x = {}, y = {}, speed = {}, phase = {}, amplitude = {}, frequency = {},
    fall_speed = max(5, options.speed or 28), min_amplitude = max(0, options.min_amplitude or 1), max_amplitude = max(0, options.max_amplitude or 4),
    size = max(1, min(4, floor(options.flake_size or 2))),
    time = 0, rate = rates[profile], accumulator = 0,
    intensity = "light", color = options.color or 7,
    surface_x = {0}, surface_y = {height - 2}, surface_width = {width}, surface_count = 1,
    settle_x = {}, settle_y = {}, settle_age = {}, settle_life = {}, settle_capacity = max(8, min(80, floor(options.settle_capacity or capacities[profile] * 2))), settle_count = 0,
    settle_min = max(1, min(3, options.settle_min or 1)), settle_max = max(1, min(3, options.settle_max or 3))
  }
  if self.seed < 1 then self.seed = 1 end
  if self.settle_max < self.settle_min then self.settle_min, self.settle_max = self.settle_max, self.settle_min end
  for i = 1, capacity do respawn(self, i, true) end
  for i = 1, self.settle_capacity do
    self.settle_x[i], self.settle_y[i], self.settle_age[i], self.settle_life[i] = 0, 0, 0, 0
  end
  self.set_intensity, self.add_surface, self.set_surface, self.clear_surfaces = methods.set_intensity, methods.add_surface, methods.set_surface, methods.clear_surfaces
  self.update, self.draw, self.clear, self.stats = methods.update, methods.draw, methods.clear, methods.stats
  self:set_intensity(options.intensity or "light")
  return self
end

function methods.set_intensity(self, value)
  local fraction = value == "storm" and 1 or (value == "heavy" and 0.76 or 0.42)
  local multiplier = value == "storm" and 2 or (value == "heavy" and 1.4 or 0.55)
  self.intensity = value == "storm" and "storm" or (value == "heavy" and "heavy" or "light")
  self.rate = rates[self.profile] * multiplier
  local next_count = max(1, floor(self.capacity * fraction))
  for i = self.count + 1, next_count do respawn(self, i, true) end
  self.count = next_count
  return self.intensity
end

function methods.add_surface(self, x, y, width)
  if self.surface_count >= 32 then return nil end
  local i = self.surface_count + 1
  self.surface_count = i
  self.surface_x[i], self.surface_y[i], self.surface_width[i] = x, y, max(1, width)
  return i
end

function methods.set_surface(self, id, x, y, width)
  if id < 2 or id > self.surface_count then return false end
  self.surface_x[id], self.surface_y[id], self.surface_width[id] = x, y, max(1, width)
  return true
end

function methods.clear_surfaces(self)
  self.surface_count = 1
end

local function settle(self, i, surface, x)
  if self.settle_count >= self.settle_capacity then return end
  local n = self.settle_count + 1
  self.settle_count = n
  self.settle_x[n] = max(self.surface_x[surface], min(self.surface_x[surface] + self.surface_width[surface] - 1, x))
  self.settle_y[n] = self.surface_y[surface]
  self.settle_age[n] = 0
  self.settle_life[n] = self.settle_min + random(self) * (self.settle_max - self.settle_min)
end

function methods.update(self, dt)
  if self.count < 1 then return end
  dt = max(0, min(0.1, dt or 1 / 60))
  self.time = self.time + dt
  local i = 1
  while i <= self.settle_count do
    self.settle_age[i] = self.settle_age[i] + dt
    if self.settle_age[i] >= self.settle_life[i] then
      local last = self.settle_count
      self.settle_x[i], self.settle_y[i] = self.settle_x[last], self.settle_y[last]
      self.settle_age[i], self.settle_life[i] = self.settle_age[last], self.settle_life[last]
      self.settle_count = last - 1
    else i = i + 1 end
  end
  for f = 1, self.count do
    local old_y = self.y[f]
    self.phase[f] = self.phase[f] + self.frequency[f] * dt
    local x = self.x[f] + sin(self.phase[f]) * self.amplitude[f] * dt * 5
    local y = old_y + self.speed[f] * dt
    local hit = 0
    for s = 1, self.surface_count do
      if x >= self.surface_x[s] and x <= self.surface_x[s] + self.surface_width[s] and old_y <= self.surface_y[s] and y >= self.surface_y[s] then
        if hit == 0 or self.surface_y[s] < self.surface_y[hit] then hit = s end
      end
    end
    if hit > 0 then settle(self, f, hit, x); respawn(self, f, false)
    else
      self.x[f], self.y[f] = x, y
      if self.x[f] < 0 then self.x[f] = self.width elseif self.x[f] > self.width then self.x[f] = 0 end
      if self.y[f] > self.height then respawn(self, f, false) end
    end
  end
end

function methods.draw(self)
  local c = self.color
  for i = 1, self.count do
    local x, y = floor(self.x[i] + 0.5), floor(self.y[i] + 0.5)
    rectfill(x, y, x + self.size - 1, y + self.size - 1, c)
  end
  for i = 1, self.settle_count do
    rectfill(self.settle_x[i] - 1, self.settle_y[i] - 1, self.settle_x[i] + 1, self.settle_y[i], c)
  end
end

function methods.clear(self)
  self.count, self.settle_count, self.accumulator = 0, 0, 0
end

function methods.stats(self) return self.count, self.capacity, self.settle_count end
