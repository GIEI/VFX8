-- VFX8 rain for LÖVE.
-- Create one bounded system per scene and call update/draw from the game callbacks.

local rain = {}
local methods = {}
local floor, min, max, sin, cos = math.floor, math.min, math.max, math.sin, math.cos
local counts = {72, 144, 240}
local rates = {90, 240, 480}
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

local function set_drop(self, i, x, y, initial)
  self.x[i] = x or random(self) * self.width
  self.y[i] = y or (initial and random(self) * self.height or -random(self) * self.max_length - 1)
  self.lengths[i] = self.min_length + random(self) * (self.max_length - self.min_length)
  self.speeds[i] = self.speed * (0.78 + random(self) * 0.44)
end

function rain.new(options)
  options = options or empty
  local profile = profile_index(options.quality)
  local width, height = max(1, options.width or 240), max(1, options.height or 136)
  local capacity = max(1, min(512, floor(options.capacity or counts[profile])))
  local angle = max(-35, min(35, options.angle or 0))
  local intensity = options.intensity or "light"
  local self = {
    profile = profile, width = width, height = height, capacity = capacity,
    count = capacity, seed = floor(options.seed or 1) % 251,
    x = {}, y = {}, lengths = {}, speeds = {},
    angle = angle, speed = max(10, options.speed or 260),
    min_length = max(1, options.min_length or 5), max_length = max(1, options.max_length or 9),
    rate = rates[profile], accumulator = 0,
    color = options.color or {0.58, 0.76, 0.94, 0.72}, thickness = max(1, options.thickness or 1)
  }
  if self.seed < 1 then self.seed = 1 end
  for i = 1, capacity do set_drop(self, i, nil, nil, true) end
  self.set_intensity, self.set_angle = methods.set_intensity, methods.set_angle
  self.update, self.draw, self.clear, self.stats = methods.update, methods.draw, methods.clear, methods.stats
  self:set_intensity(intensity)
  return self
end

function methods.set_intensity(self, value)
  local fraction = value == "storm" and 1 or (value == "heavy" and 0.78 or 0.46)
  local multiplier = value == "storm" and 2 or (value == "heavy" and 1.35 or 0.55)
  self.intensity = value == "storm" and "storm" or (value == "heavy" and "heavy" or "light")
  self.rate = rates[self.profile] * multiplier
  local next_count = max(1, floor(self.capacity * fraction))
  for i = self.count + 1, next_count do set_drop(self, i, nil, nil, true) end
  self.count = next_count
  return self.intensity
end

function methods.set_angle(self, degrees)
  self.angle = max(-35, min(35, degrees or 0))
  return self.angle
end

function methods.update(self, dt)
  if self.count < 1 then return end
  dt = max(0, min(0.1, dt or 1 / 60))
  local dx_scale = sin(self.angle * math.pi / 180)
  local dy_scale = cos(self.angle * math.pi / 180)
  for i = 1, self.count do
    local speed = self.speeds[i]
    self.x[i] = self.x[i] + dx_scale * speed * dt
    self.y[i] = self.y[i] + dy_scale * speed * dt
    if self.y[i] - self.lengths[i] > self.height or self.x[i] < -self.lengths[i] or self.x[i] > self.width + self.lengths[i] then
      set_drop(self, i, nil, nil, false)
    end
  end
end

function methods.draw(self)
  local old_r, old_g, old_b, old_a = love.graphics.getColor()
  local old_width = love.graphics.getLineWidth()
  local c = self.color
  love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
  love.graphics.setLineWidth(self.thickness)
  local dx = sin(self.angle * math.pi / 180)
  local dy = cos(self.angle * math.pi / 180)
  for i = 1, self.count do
    local x, y, length = self.x[i], self.y[i], self.lengths[i]
    love.graphics.line(x, y, x - dx * length, y - dy * length)
  end
  love.graphics.setLineWidth(old_width)
  love.graphics.setColor(old_r, old_g, old_b, old_a)
end

function methods.clear(self)
  self.count, self.accumulator = 0, 0
end

function methods.stats(self) return self.count, self.capacity, floor(self.rate + 0.5) end

return rain
