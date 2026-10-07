-- VFX8 palette effects for LÖVE.
-- Copy this module into your project as vfx8/palette_fx.lua.

local palette_fx = {}
local methods = {}
local filters = {
  night = {0, 1, 1, 1, 4, 5, 1, 1, 2, 4, 10, 3, 1, 1, 2, 4},
  sepia = {0, 4, 4, 4, 4, 5, 6, 7, 4, 4, 10, 4, 4, 5, 4, 7},
  mono = {0, 1, 1, 6, 4, 5, 6, 7, 2, 4, 7, 6, 6, 5, 7, 7}
}

function palette_fx.new(options)
  options = options or {}
  return {quality = options.quality or "low", color_count = math.max(1, math.min(16, math.floor(options.color_count or 16))),
    time = 0, cycle_first = -1, cycle_last = -1, cycle_rate = 0, cycle_shift = 0, cycle_direction = options.cycle_direction or 1, cycle_phase = options.cycle_phase or 0, filter = nil,
    filter_count = 0, custom_filter = {},
    pulse_a = -1, pulse_b = -1, pulse_rate = 0, pulse_phase = 0, pulse_offset = options.pulse_phase or 0, pulse_duty = options.pulse_amount or 0.5,
    flash_first = -1, flash_last = -1, flash_color = 0, flash_time = 0, flash_duration = 0, flash_elapsed = 0,
    flash_intensity = 1, flash_sequence = nil, flash_sequence_rate = 8, invert_map = {}, invert_time = 0,
    invert_matching = options.color_matching or "rgb", priority = {"cycle", "filter", "pulse", "invert", "flash"},
    filter_from = nil, filter_to = nil, filter_transition = 1, filter_transition_duration = 0,
    set_cycle = methods.set_cycle, clear_cycle = methods.clear_cycle, set_priority = methods.set_priority,
    set_filter = methods.set_filter, set_filter_map = methods.set_filter_map,
    clear_filter = methods.clear_filter,
    set_pulse = methods.set_pulse, flash = methods.flash,
    set_invert_palette = methods.set_invert_palette, invert = methods.invert,
    clear_invert = methods.clear_invert,
    map_color = methods.map_color, update = methods.update, clear = methods.clear}
end

function methods.set_cycle(self, first, last, rate, direction, phase)
  first, last = math.floor(first or 0), math.floor(last or 0)
  direction = direction or 1
  if direction ~= 1 and direction ~= -1 then return false end
  if first < 0 or last >= self.color_count or last <= first then return false end
  self.cycle_first, self.cycle_last, self.cycle_rate = first, last, math.max(0, rate or 1)
  self.cycle_direction, self.cycle_phase = direction or 1, phase or 0
  self.cycle_shift = math.floor(self.time * self.cycle_rate + self.cycle_phase)
  return true
end
function methods.clear_cycle(self)
  self.cycle_first, self.cycle_last, self.cycle_rate, self.cycle_shift = -1, -1, 0, 0
  self.cycle_direction, self.cycle_phase = 1, 0
end
function methods.set_filter(self, name, transition_duration)
  local filter = filters[name]
  if not filter then return false end
  if transition_duration and transition_duration > 0 then
    local previous = {}
    for i = 1, self.color_count do previous[i] = self.filter and self.filter[i] or i - 1 end
    self.filter_from, self.filter_to, self.filter_transition_duration = previous, filter, transition_duration
    self.filter_transition = 0
  else self.filter_from, self.filter_to, self.filter_transition = nil, nil, 1 end
  self.filter, self.filter_count = filter, 16
  return true
end
function methods.set_filter_map(self, map, transition_duration)
  if type(map) ~= "table" then return false end
  for i = 1, self.color_count do
    local value = map[i]
    if type(value) ~= "number" or value ~= math.floor(value) or value < 0 or value >= self.color_count then return false end
  end
  local previous
  if transition_duration and transition_duration > 0 then
    previous = {}
    for i = 1, self.color_count do previous[i] = self.filter and self.filter[i] or i - 1 end
  end
  for i = 1, self.color_count do self.custom_filter[i] = map[i] end
  if transition_duration and transition_duration > 0 then
    self.filter_from, self.filter_to, self.filter_transition_duration = previous, self.custom_filter, transition_duration
    self.filter_transition = 0
  else self.filter_from, self.filter_to, self.filter_transition = nil, nil, 1 end
  self.filter, self.filter_count = self.custom_filter, self.color_count
  return true
end
function methods.clear_filter(self)
  self.filter, self.filter_count = nil, 0
  self.filter_from, self.filter_to, self.filter_transition = nil, nil, 1
end
function methods.set_priority(self, order)
  if type(order) ~= "table" or #order ~= 5 then return false end
  local seen = {}
  for i = 1, 5 do
    local key = order[i]
    if key ~= "cycle" and key ~= "filter" and key ~= "pulse" and key ~= "invert" and key ~= "flash" or seen[key] then return false end
    seen[key] = true
  end
  for i = 1, 5 do self.priority[i] = order[i] end
  return true
end
function methods.set_pulse(self, first, second, rate, phase, amount)
  first, second = math.floor(first or -1), math.floor(second or -1)
  if first < 0 or first >= self.color_count or second < 0 or second >= self.color_count then return false end
  self.pulse_a, self.pulse_b, self.pulse_rate = first, second, math.max(0, rate or 0)
  self.pulse_offset, self.pulse_duty = phase or 0, math.max(0, math.min(1, amount or 0.5))
  self.pulse_phase = (self.time * self.pulse_rate + self.pulse_offset) % 1
  return true
end
function methods.flash(self, first, last, target, duration, intensity, sequence, sequence_rate)
  if sequence ~= nil then
    if type(sequence) ~= "table" or #sequence == 0 then return false end
    for i = 1, #sequence do
      if type(sequence[i]) ~= "number" or sequence[i] ~= math.floor(sequence[i]) or sequence[i] < 0 or sequence[i] >= self.color_count then return false end
    end
  end
  self.flash_first = math.max(0, math.min(self.color_count - 1, math.floor(first or 0)))
  self.flash_last = math.max(self.flash_first, math.min(self.color_count - 1, math.floor(last or first or 0)))
  self.flash_color, self.flash_time = math.max(0, math.min(self.color_count - 1, math.floor(target or 7))), math.max(0, duration or 0.1)
  self.flash_duration, self.flash_elapsed = self.flash_time, 0
  self.flash_intensity, self.flash_sequence, self.flash_sequence_rate = math.max(0, math.min(1, intensity or 1)), sequence, math.max(0, sequence_rate or 8)
  return true
end
function methods.set_invert_palette(self, palette, matching)
  matching = matching or self.invert_matching
  if matching ~= "rgb" and matching ~= "luminance" and matching ~= "reverse" then return false end
  self.invert_matching = matching
  if matching == "reverse" then
    for i = 1, self.color_count do self.invert_map[i] = self.color_count - i end
    return true
  end
  if type(palette) ~= "table" or #palette < self.color_count then return false end
  for i = 1, self.color_count do
    local color = palette[i]
    if type(color) ~= "table" then return false end
    for component = 1, 3 do
      local value = color[component]
      if type(value) ~= "number" or value ~= value or value < 0 or value > 1 then return false end
    end
  end
  for i = 1, self.color_count do
    local source = palette[i]
    local target, best_distance = 0, math.huge
    for j = 1, self.color_count do
      local candidate = palette[j]
      local distance
      if matching == "luminance" then
        local brightness = source[1] * 0.299 + source[2] * 0.587 + source[3] * 0.114
        local candidate_brightness = candidate[1] * 0.299 + candidate[2] * 0.587 + candidate[3] * 0.114
        distance = (1 - brightness - candidate_brightness) ^ 2
      else
        local dr, dg, db = 1 - source[1] - candidate[1], 1 - source[2] - candidate[2], 1 - source[3] - candidate[3]
        distance = dr * dr + dg * dg + db * db
      end
      if distance < best_distance then target, best_distance = j - 1, distance end
    end
    self.invert_map[i] = target
  end
  return true
end
function methods.invert(self, duration)
  if #self.invert_map < self.color_count then return false end
  self.invert_time = math.max(0, duration or 0.1)
  return true
end
function methods.clear_invert(self) self.invert_time = 0 end
function methods.map_color(self, index)
  local color = math.floor(index or 0)
  if color < 0 or color >= self.color_count then return color end
  local source_color = color
  for i = 1, 5 do
    local effect = self.priority[i]
    if effect == "cycle" and self.cycle_rate > 0 and color >= self.cycle_first and color <= self.cycle_last then
      local count = self.cycle_last - self.cycle_first + 1
      color = self.cycle_first + (color - self.cycle_first + self.cycle_shift * self.cycle_direction) % count
    elseif effect == "filter" and self.filter and color < self.filter_count then
      local target = self.filter[color + 1]
      if self.filter_from and self.filter_to and self.filter_transition < 1 then
        local from = self.filter_from[color + 1] or color
        local to = self.filter_to[color + 1] or target
        target = math.floor(from + (to - from) * self.filter_transition + 0.5)
      end
      color = target
    elseif effect == "pulse" and self.pulse_rate > 0 and (color == self.pulse_a or color == self.pulse_b) then
      color = self.pulse_phase >= 1 - self.pulse_duty and self.pulse_b or self.pulse_a
    elseif effect == "invert" and self.invert_time > 0 then color = self.invert_map[color + 1]
    elseif effect == "flash" and self.flash_time > 0 and source_color >= self.flash_first and source_color <= self.flash_first + math.floor((self.flash_last - self.flash_first + 1) * self.flash_intensity) - 1 then
      local sequence = self.flash_sequence
      color = sequence and #sequence > 0 and sequence[(math.floor(self.flash_elapsed * self.flash_sequence_rate) % #sequence) + 1] or self.flash_color
    end
  end
  return color
end
function methods.update(self, dt)
  dt = math.max(0, math.min(0.1, dt or 1 / 60))
  self.time, self.flash_time = self.time + dt, math.max(0, self.flash_time - dt)
  if self.flash_time > 0 then self.flash_elapsed = self.flash_elapsed + dt end
  self.cycle_shift = self.cycle_rate > 0 and math.floor(self.time * self.cycle_rate + self.cycle_phase) or 0
  self.pulse_phase = self.pulse_rate > 0 and (self.time * self.pulse_rate + self.pulse_offset) % 1 or 0
  if self.filter_from and self.filter_transition < 1 then
    self.filter_transition = math.min(1, self.filter_transition + dt / math.max(0.001, self.filter_transition_duration))
    if self.filter_transition >= 1 then self.filter_from, self.filter_to = nil, nil end
  end
  self.invert_time = math.max(0, self.invert_time - dt)
end
function methods.clear(self)
  self.time, self.flash_time, self.invert_time = 0, 0, 0
  self.cycle_first, self.cycle_last, self.cycle_rate, self.cycle_shift = -1, -1, 0, 0
  self.cycle_direction, self.cycle_phase = 1, 0
  self.filter, self.filter_count = nil, 0
  self.pulse_a, self.pulse_b, self.pulse_rate, self.pulse_phase = -1, -1, 0, 0
  self.flash_first, self.flash_last, self.flash_color = -1, -1, 0
  self.flash_duration, self.flash_elapsed, self.flash_intensity = 0, 0, 1
  self.flash_sequence, self.flash_sequence_rate = nil, 8
  self.pulse_offset, self.pulse_duty = 0, 0.5
  self.filter_from, self.filter_to, self.filter_transition, self.filter_transition_duration = nil, nil, 1, 0
  self.invert_matching = "rgb"
  self.priority[1], self.priority[2], self.priority[3], self.priority[4], self.priority[5] = "cycle", "filter", "pulse", "invert", "flash"
end

return palette_fx
