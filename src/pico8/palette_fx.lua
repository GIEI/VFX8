-- VFX8 palette effects for PICO-8.
-- Include this file once; it defines vfx8_palette_fx.

vfx8_palette_fx = vfx8_palette_fx or {}
local methods = {}
local filters = {
  night = {0, 1, 1, 1, 4, 5, 1, 1, 2, 4, 10, 3, 1, 1, 2, 4},
  sepia = {0, 4, 4, 4, 4, 5, 6, 7, 4, 4, 10, 4, 4, 5, 4, 7},
  mono = {0, 1, 1, 6, 4, 5, 6, 7, 2, 4, 7, 6, 6, 5, 7, 7}
}

function vfx8_palette_fx.new(options)
  options = options or {}
  return {
    quality = options.quality or "low",
    color_count = max(1, min(16, flr(options.color_count or 16))),
    time = 0,
    cycle_first = -1,
    cycle_last = -1,
    cycle_rate = 0,
    cycle_shift = 0,
    filter = nil,
    filter_count = 0,
    custom_filter = {},
    pulse_a = -1,
    pulse_b = -1,
    pulse_rate = 0,
    pulse_phase = 0,
    flash_first = -1,
    flash_last = -1,
    flash_color = 0,
    flash_time = 0,
    invert_map = {},
    invert_time = 0,
    set_cycle = methods.set_cycle,
    clear_cycle = methods.clear_cycle,
    set_filter = methods.set_filter,
    set_filter_map = methods.set_filter_map,
    clear_filter = methods.clear_filter,
    set_pulse = methods.set_pulse,
    flash = methods.flash,
    set_invert_palette = methods.set_invert_palette,
    invert = methods.invert,
    clear_invert = methods.clear_invert,
    map_color = methods.map_color,
    update = methods.update,
    clear = methods.clear
  }
end

function methods.set_cycle(self, first, last, rate)
  first, last = flr(first or 0), flr(last or 0)
  if first < 0 or last >= self.color_count or last <= first then return false end
  self.cycle_first, self.cycle_last = first, last
  self.cycle_rate = max(0, rate or 1)
  self.cycle_shift = flr(self.time * self.cycle_rate)
  return true
end

function methods.clear_cycle(self)
  self.cycle_first, self.cycle_last, self.cycle_rate, self.cycle_shift = -1, -1, 0, 0
end

function methods.set_filter(self, name)
  local filter = filters[name]
  if not filter then return false end
  self.filter, self.filter_count = filter, 16
  return true
end

function methods.set_filter_map(self, map)
  if type(map) ~= "table" then return false end
  for i = 1, self.color_count do
    local value = map[i]
    if type(value) ~= "number" or value ~= flr(value) or value < 0 or value >= self.color_count then return false end
  end
  for i = 1, self.color_count do self.custom_filter[i] = map[i] end
  self.filter, self.filter_count = self.custom_filter, self.color_count
  return true
end

function methods.clear_filter(self)
  self.filter, self.filter_count = nil, 0
end

function methods.set_pulse(self, first, second, rate)
  self.pulse_a, self.pulse_b = flr(first or -1), flr(second or -1)
  self.pulse_rate = max(0, rate or 0)
  self.pulse_phase = flr(self.time * self.pulse_rate * 2) % 2
end

function methods.flash(self, first, last, target, duration)
  self.flash_first = max(0, min(self.color_count - 1, flr(first or 0)))
  self.flash_last = max(self.flash_first, min(self.color_count - 1, flr(last or first or 0)))
  self.flash_color = max(0, min(self.color_count - 1, flr(target or 7)))
  self.flash_time = max(0, duration or 0.1)
end

function methods.set_invert_palette(self, palette)
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
    local target, best_distance = 0, 1000000
    for j = 1, self.color_count do
      local candidate = palette[j]
      local dr, dg, db = 1 - source[1] - candidate[1], 1 - source[2] - candidate[2], 1 - source[3] - candidate[3]
      local distance = dr * dr + dg * dg + db * db
      if distance < best_distance then target, best_distance = j - 1, distance end
    end
    self.invert_map[i] = target
  end
  return true
end

function methods.invert(self, duration)
  if #self.invert_map < self.color_count then return false end
  self.invert_time = max(0, duration or 0.1)
  return true
end

function methods.clear_invert(self) self.invert_time = 0 end

function methods.map_color(self, index)
  local color = flr(index or 0)
  if color < 0 or color >= self.color_count then return color end
  local source_color = color
  if self.cycle_rate > 0 and color >= self.cycle_first and color <= self.cycle_last then
    local count = self.cycle_last - self.cycle_first + 1
    color = self.cycle_first + (color - self.cycle_first + self.cycle_shift) % count
  end
  if self.filter and color < self.filter_count then color = self.filter[color + 1] end
  if self.pulse_rate > 0 and (color == self.pulse_a or color == self.pulse_b) then
    color = self.pulse_phase == 0 and self.pulse_a or self.pulse_b
  end
  if self.invert_time > 0 then color = self.invert_map[color + 1] end
  if self.flash_time > 0 and source_color >= self.flash_first and source_color <= self.flash_last then color = self.flash_color end
  return color
end

function methods.update(self, dt)
  dt = min(0.1, max(0, dt or 1 / 60))
  self.time += dt
  self.cycle_shift = self.cycle_rate > 0 and flr(self.time * self.cycle_rate) or 0
  self.pulse_phase = self.pulse_rate > 0 and flr(self.time * self.pulse_rate * 2) % 2 or 0
  self.flash_time = max(0, self.flash_time - dt)
  self.invert_time = max(0, self.invert_time - dt)
end

function methods.clear(self)
  self.time, self.flash_time, self.invert_time = 0, 0, 0
  self.cycle_first, self.cycle_last, self.cycle_rate, self.cycle_shift = -1, -1, 0, 0
  self.filter, self.filter_count = nil, 0
  self.pulse_a, self.pulse_b, self.pulse_rate, self.pulse_phase = -1, -1, 0, 0
  self.flash_first, self.flash_last, self.flash_color = -1, -1, 0
end
