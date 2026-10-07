-- VFX8 electric arcs for LÖVE.
-- Copy this module into your project as vfx8/electricity.lua.

local electricity = {}
local methods = {}
local floor, min, max, sqrt = math.floor, math.min, math.max, math.sqrt
local capacities = {96, 192, 320}
local emission_caps = {64, 128, 192}
local segment_counts = {7, 11, 15}
local branch_counts = {1, 2, 3}
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

function electricity.new(options)
  options = options or empty
  local profile = profile_index(options.quality)
  local capacity = max(1, min(320, floor(options.capacity or capacities[profile])))
  local max_emit = max(1, min(capacity, floor(options.max_emit or emission_caps[profile])))
  local seed = floor(options.seed or 1) % 251
  if seed < 1 then seed = 1 end
  local self = {profile = profile, capacity = capacity, max_emit = max_emit,
    count = 0, frame_used = 0, last_emitted = 0, seed = seed,
    x1 = {}, y1 = {}, x2 = {}, y2 = {}, age = {}, life = {}, width = {}, colors = {}, core_colors = {}, point_x = {}, point_y = {},
    color = options.color, core_color = options.core_color, flicker = options.flicker or false,
    flicker_speed = options.flicker_speed or 12, pulse_count = options.pulse_count or 0,
    flicker_segments = {}}
  for i = 1, capacity do
    self.x1[i], self.y1[i], self.x2[i], self.y2[i] = 0, 0, 0, 0
    self.age[i], self.life[i], self.width[i] = 0, 0, 1
  end
  for i = 1, 25 do self.point_x[i], self.point_y[i] = 0, 0 end
  self.strike, self.update, self.draw = methods.strike, methods.update, methods.draw
  self.clear, self.stats = methods.clear, methods.stats
  return self
end

local function append(self, ax, ay, bx, by, life, width, color, core_color)
  if self.count >= self.capacity or self.frame_used >= self.max_emit then return false end
  local i = self.count + 1
  self.count = i
  self.x1[i], self.y1[i], self.x2[i], self.y2[i] = ax, ay, bx, by
  self.age[i], self.life[i], self.width[i] = 0, life, width
  self.colors[i], self.core_colors[i] = color, core_color
  self.frame_used = self.frame_used + 1
  return true
end

function methods.strike(self, x1, y1, x2, y2, options)
  options = options or empty
  local dx, dy = x2 - x1, y2 - y1
  local length = sqrt(dx * dx + dy * dy)
  if length <= 0 then return 0 end
  local nx, ny = -dy / length, dx / length
  local steps = max(2, min(24, floor(options.segments or segment_counts[self.profile])))
  local amplitude = max(0, options.jaggedness or min(12, length * 0.16))
  local life = max(0.025, options.life or 0.14)
  local width = max(1, options.width or (self.profile == 1 and 1 or 2))
  local branches = max(0, min(8, floor(options.branches == nil and branch_counts[self.profile] or options.branches)))
  local branch_probability = max(0, min(1, options.branch_probability == nil and 1 or options.branch_probability))
  local branch_angle = options.branch_angle
  local branch_length = options.branch_length
  local color, core_color = options.color or self.color, options.core_color or self.core_color
  local flicker = options.flicker == nil and self.flicker or options.flicker
  if options.pulse_count ~= nil then self.pulse_count = max(0, floor(options.pulse_count)) end
  local before = self.frame_used
  local px, py = x1, y1
  local points_x, points_y = self.point_x, self.point_y
  points_x[1], points_y[1] = x1, y1
  for i = 1, steps do
    local t = i / steps
    local offset = i == steps and 0 or (random(self) - 0.5) * 2 * amplitude * min(1, t * 4, (1 - t) * 4)
    local qx, qy = x1 + dx * t + nx * offset, y1 + dy * t + ny * offset
    if not append(self, px, py, qx, qy, life, width, color, core_color) then break end
    self.flicker_segments[self.count] = flicker and 1 or 0
    points_x[i + 1], points_y[i + 1] = qx, qy
    px, py = qx, qy
  end
  for b = 1, branches do
    local at = max(2, min(steps, floor(steps * (b / (branches + 1)))))
    local sx, sy = points_x[at], points_y[at]
    if sx and (branch_probability >= 1 or random(self) < branch_probability) and self.frame_used < self.max_emit and self.count < self.capacity then
      local side = random(self) < 0.5 and -1 or 1
      local reach = length * (branch_length or (0.16 + random(self) * 0.16))
      local bx, by
      if branch_angle == nil and branch_length == nil then
        bx = sx + dx / length * reach * 0.55 + nx * reach * side
        by = sy + dy / length * reach * 0.55 + ny * reach * side
      else
        local angle = branch_angle or 1.068
        local lateral = math.max(0.001, math.sin(angle))
        bx = sx + (dx / length * math.cos(angle) / lateral + nx * side) * reach
        by = sy + (dy / length * math.cos(angle) / lateral + ny * side) * reach
      end
      local branch_steps = 2 + floor(random(self) * 2)
      local lx, ly = sx, sy
      for j = 1, branch_steps do
        local t = j / branch_steps
        local jitter = (random(self) - 0.5) * amplitude * 0.7
        local qx = sx + (bx - sx) * t + nx * jitter
        local qy = sy + (by - sy) * t + ny * jitter
        if not append(self, lx, ly, qx, qy, life, width, color, core_color) then break end
        self.flicker_segments[self.count] = flicker and 1 or 0
        lx, ly = qx, qy
      end
    end
  end
  local emitted = self.frame_used - before
  local bolts = max(1, min(8, floor(options.bolt_count or 1)))
  for bolt = 2, bolts do
    local spread = (random(self) - 0.5) * amplitude
    local bx1, by1 = x1 + nx * spread, y1 + ny * spread
    local bx2, by2 = x2 + nx * spread, y2 + ny * spread
    emitted = emitted + methods.strike(self, bx1, by1, bx2, by2, {
      segments = steps, jaggedness = amplitude, life = life, width = width,
      branches = 0, color = color, core_color = core_color, flicker = flicker, bolt_count = 1})
  end
  return emitted
end

function methods.update(self, dt)
  dt = max(0, min(0.1, dt or 1 / 60))
  local age, life = self.age, self.life
  local count, i = self.count, 1
  while i <= count do
    local next_age = age[i] + dt
    if next_age >= life[i] then
      local last = count
      self.x1[i], self.y1[i], self.x2[i], self.y2[i] = self.x1[last], self.y1[last], self.x2[last], self.y2[last]
      age[i], life[i], self.width[i], self.colors[i], self.core_colors[i], self.flicker_segments[i] = age[last], life[last], self.width[last], self.colors[last], self.core_colors[last], self.flicker_segments[last]
      count = last - 1
    else
      age[i] = next_age
      i = i + 1
    end
  end
  self.count, self.last_emitted, self.frame_used = count, self.frame_used, 0
end

function methods.draw(self)
  local old_r, old_g, old_b, old_a = love.graphics.getColor()
  local old_width = love.graphics.getLineWidth()
  for i = 1, self.count do
    local fade = 1 - self.age[i] / self.life[i]
    local core = self.core_colors[i]
    local glow = self.colors[i]
    if self.flicker_segments[i] == 1 and math.floor(self.age[i] * self.flicker_speed) % 2 == 1 then fade = fade * 0.25 end
    if self.pulse_count > 0 then
      local phase = (self.age[i] / self.life[i]) * self.pulse_count * math.pi * 2
      fade = fade * (0.45 + 0.55 * (0.5 + 0.5 * math.sin(phase)))
    end
    if glow then love.graphics.setColor(glow[1], glow[2], glow[3], (glow[4] or 1) * 0.25 * fade)
    else love.graphics.setColor(0.15, 0.55, 1, 0.25 * fade) end
    love.graphics.setLineWidth(self.width[i] + 2)
    love.graphics.line(self.x1[i], self.y1[i], self.x2[i], self.y2[i])
    if core then love.graphics.setColor(core[1], core[2], core[3], (core[4] or 1) * fade)
    elseif glow then love.graphics.setColor(glow[1], glow[2], glow[3], (glow[4] or 1) * fade)
    else love.graphics.setColor(0.68 + 0.32 * fade, 0.86 + 0.14 * fade, 1, fade) end
    love.graphics.setLineWidth(self.width[i])
    love.graphics.line(self.x1[i], self.y1[i], self.x2[i], self.y2[i])
  end
  love.graphics.setLineWidth(old_width)
  love.graphics.setColor(old_r, old_g, old_b, old_a)
end

function methods.clear(self)
  self.count, self.frame_used, self.last_emitted = 0, 0, 0
end

function methods.stats(self)
  return self.count, self.capacity, self.last_emitted
end

return electricity
