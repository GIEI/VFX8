-- VFX8 integration game for TIC-80. Expand the includes before importing.
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
  if life < 0.05 then life = 0.05 end
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
  local x, y, ages, lives = self.x, self.y, self.age, self.life
  local kinds, sizes, end_sizes = self.kind, self.size, self.end_size
  for i = 1, self.count do
    local preset = presets[kinds[i]]
    local t = ages[i] / lives[i]
    local color = preset.c1
    if t >= 0.34 and t < 0.72 then color = preset.c2 end
    if t >= 0.72 then color = preset.c3 end
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
-- VFX8 screen effects for TIC-80.
-- Include this file at build time; it defines vfx8_screen_fx.

vfx8_screen_fx = vfx8_screen_fx or {}
local methods, empty_options = {}, {}

function vfx8_screen_fx.new(options)
  options = options or empty_options
  return {
    width = options.width or 240, height = options.height or 136,
    capacity = options.capacity or 8, trauma = 0, shake_x = 0, shake_y = 0,
    shake_time = 0, shake_duration = 0, offset_x = 0, offset_y = 0, flash_time = 0,
    flash_duration = 0, flash_color = 7, waves = {}, wave_count = 0,
    seed = options.seed or 1, update = methods.update,
    add_trauma = methods.add_trauma, impulse = methods.impulse,
    flash = methods.flash, shockwave = methods.shockwave,
    get_shake_offset = methods.get_shake_offset, draw_overlays = methods.draw_overlays,
    render = methods.render, clear = methods.clear
  }
end
function methods.add_trauma(self, amount)
  self.trauma = math.min(1, self.trauma + math.max(0, amount or 0))
  self.shake_duration = math.max(self.shake_duration, 0.35)
  self.shake_time = math.max(self.shake_time, self.shake_duration)
end
function methods.impulse(self, x, y, duration)
  self.shake_x, self.shake_y = x or 0, y or 0
  self.trauma = math.max(self.trauma, 1)
  self.shake_duration = math.max(0.001, duration or 0.12)
  self.shake_time = self.shake_duration
end
function methods.flash(self, duration, color)
  self.flash_duration = math.max(0.001, duration or 0.08)
  self.flash_time, self.flash_color = self.flash_duration, color or 7
end
function methods.shockwave(self, x, y, radius, strength, duration)
  if self.wave_count >= self.capacity then return false end
  local i = self.wave_count + 1
  local wave = self.waves[i] or {}
  wave.x, wave.y = x, y
  wave.radius, wave.strength = radius or 0, strength or 8
  wave.age, wave.life = 0, math.max(0.05, duration or 0.3)
  self.waves[i], self.wave_count = wave, i
  return true
end
function methods.update(self, dt)
  dt = math.min(0.1, math.max(0, dt or 1 / 60))
  self.trauma = math.max(0, self.trauma - dt * 2.5)
  self.shake_time, self.flash_time = math.max(0, self.shake_time - dt), math.max(0, self.flash_time - dt)
  self.seed = (self.seed * 17 + 31) % 251
  local nx = self.seed / 251 - 0.5
  self.seed = (self.seed * 17 + 31) % 251
  local ny = self.seed / 251 - 0.5
  local trauma = self.trauma * self.trauma
  local decay = self.shake_duration > 0 and self.shake_time / self.shake_duration or 0
  self.offset_x, self.offset_y = (self.shake_x + nx * 8) * trauma * decay, (self.shake_y + ny * 8) * trauma * decay
  local i = 1
  while i <= self.wave_count do
    local wave = self.waves[i]
    wave.age = wave.age + dt
    if wave.age >= wave.life then
      self.waves[i], self.waves[self.wave_count] = self.waves[self.wave_count], wave
      self.wave_count = self.wave_count - 1
    else i = i + 1 end
  end
end
function methods.get_shake_offset(self) return self.offset_x, self.offset_y end
function methods.draw_overlays(self)
  for i = 1, self.wave_count do
    local wave = self.waves[i]
    local t = wave.age / wave.life
    circ(wave.x, wave.y, math.floor(wave.radius + t * wave.strength * 8), t < 0.5 and 7 or 6)
  end
  if self.flash_time > 0 then rect(0, 0, self.width, self.height, self.flash_color) end
end
function methods.render(self, draw_scene)
  local dx, dy = math.floor(self.offset_x), math.floor(self.offset_y)
  if dx ~= 0 or dy ~= 0 then
    -- TIC-80 has no camera transform API. Compose shake with the screen scroll
    -- registers, then restore them before drawing screen-space overlays.
    local screen_x, screen_y = peek(0x3ff9), peek(0x3ffa)
    poke(0x3ff9, (screen_x + dx) % 256)
    poke(0x3ffa, (screen_y + dy) % 256)
    local ok, err = pcall(draw_scene)
    poke(0x3ff9, screen_x)
    poke(0x3ffa, screen_y)
    if not ok then error(err, 0) end
  else
    draw_scene()
  end
  methods.draw_overlays(self)
end
function methods.clear(self) self.trauma, self.shake_time, self.flash_time, self.wave_count = 0, 0, 0, 0; self.offset_x, self.offset_y = 0, 0 end
-- VFX8 pixel deformation helpers for TIC-80.
-- Include this file at build time; it defines vfx8_pixel_deform.

vfx8_pixel_deform = vfx8_pixel_deform or {}
local methods = {}
local bayer = {0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5}
local spiral = {0, 12, 3, 15, 8, 4, 11, 7, 2, 14, 1, 13, 10, 6, 9, 5}
local pi2 = math.pi * 2

function vfx8_pixel_deform.new(options)
  options = options or {}
  return {quality = options.quality or "low", phase = options.phase or 0,
    squash_x = 1, squash_y = 1, squash_time = 0, squash_duration = 0.2,
    rotation_x = 0, rotation_y = 0, rotation_sin = 0, rotation_cos = 1,
    wave_offset = methods.wave_offset, set_squash = methods.set_squash,
    update = methods.update, scale = methods.scale, visible = methods.visible,
    set_rotation = methods.set_rotation, rotate_point = methods.rotate_point,
    rotation_bounds = methods.rotation_bounds,
    clear = methods.clear}
end
function methods.set_rotation(self, center_x, center_y, angle)
  self.rotation_x, self.rotation_y = center_x, center_y
  self.rotation_sin, self.rotation_cos = math.sin(angle or 0), math.cos(angle or 0)
end
function methods.rotate_point(self, x, y)
  local dx, dy = x - self.rotation_x, y - self.rotation_y
  return self.rotation_x + dx * self.rotation_cos - dy * self.rotation_sin,
    self.rotation_y + dx * self.rotation_sin + dy * self.rotation_cos
end
function methods.rotation_bounds(self, left, top, right, bottom, margin)
  local x1, y1 = left - self.rotation_x, top - self.rotation_y
  local x2, y2 = right - self.rotation_x, top - self.rotation_y
  local x3, y3 = right - self.rotation_x, bottom - self.rotation_y
  local x4, y4 = left - self.rotation_x, bottom - self.rotation_y
  local s, c = self.rotation_sin, self.rotation_cos
  local ax, ay = self.rotation_x + x1 * c + y1 * s, self.rotation_y - x1 * s + y1 * c
  local bx, by = self.rotation_x + x2 * c + y2 * s, self.rotation_y - x2 * s + y2 * c
  local cx, cy = self.rotation_x + x3 * c + y3 * s, self.rotation_y - x3 * s + y3 * c
  local dx, dy = self.rotation_x + x4 * c + y4 * s, self.rotation_y - x4 * s + y4 * c
  local pad = margin or 0
  return math.min(ax, bx, cx, dx) - pad, math.min(ay, by, cy, dy) - pad,
    math.max(ax, bx, cx, dx) + pad, math.max(ay, by, cy, dy) + pad
end
function methods.wave_offset(self, x, time, amplitude, wavelength, speed, phase)
  wavelength = math.max(1, wavelength or 16)
  return (amplitude or 2) * math.sin(((x / wavelength + (time or self.phase) * (speed or 1) + (phase or 0)) % 1) * pi2)
end
function methods.set_squash(self, horizontal, vertical, duration)
  self.squash_x, self.squash_y = math.max(0.1, horizontal or 1.25), math.max(0.1, vertical or 0.75)
  self.squash_duration = math.max(0.01, duration or 0.2)
  self.squash_time = self.squash_duration
end
function methods.update(self, dt)
  dt = math.min(0.1, math.max(0, dt or 1 / 60))
  self.phase = self.phase + dt
  self.squash_time = math.max(0, self.squash_time - dt)
end
function methods.scale(self)
  if self.squash_time <= 0 then return 1, 1 end
  local t = 1 - self.squash_time / self.squash_duration
  local envelope = math.sin(t * pi2 * 0.5)
  return 1 + (self.squash_x - 1) * envelope, 1 + (self.squash_y - 1) * envelope
end
function methods.visible(self, x, y, amount, mode)
  local ix, iy = math.floor(x) % 4, math.floor(y) % 4
  local threshold = (mode == "spiral" and spiral or bayer)[iy * 4 + ix + 1]
  if mode == "checker" then threshold = (ix + iy) % 2 * 8 end
  return threshold / 16 >= math.min(1, math.max(0, amount or 0))
end
function methods.clear(self)
  self.phase, self.squash_time = 0, 0
  self.squash_x, self.squash_y = 1, 1
  self.rotation_x, self.rotation_y = 0, 0
  self.rotation_sin, self.rotation_cos = 0, 1
end
-- VFX8 palette effects for TIC-80.
-- Include this file at build time; it defines vfx8_palette_fx.

vfx8_palette_fx = vfx8_palette_fx or {}
local methods = {}
local filters = {
  night = {0, 1, 1, 1, 4, 5, 1, 1, 2, 4, 10, 3, 1, 1, 2, 4},
  sepia = {0, 4, 4, 4, 4, 5, 6, 7, 4, 4, 10, 4, 4, 5, 4, 7},
  mono = {0, 1, 1, 6, 4, 5, 6, 7, 2, 4, 7, 6, 6, 5, 7, 7}
}

function vfx8_palette_fx.new(options)
  options = options or {}
  return {quality = options.quality or "low", color_count = math.max(1, math.min(16, math.floor(options.color_count or 16))),
    time = 0, cycle_first = -1, cycle_last = -1, cycle_rate = 0, cycle_shift = 0, filter = nil,
    filter_count = 0, custom_filter = {},
    pulse_a = -1, pulse_b = -1, pulse_rate = 0, pulse_phase = 0, flash_first = -1, flash_last = -1,
    flash_color = 0, flash_time = 0, invert_map = {}, invert_time = 0,
    set_cycle = methods.set_cycle, clear_cycle = methods.clear_cycle,
    set_filter = methods.set_filter, set_filter_map = methods.set_filter_map,
    clear_filter = methods.clear_filter,
    set_pulse = methods.set_pulse, flash = methods.flash,
    set_invert_palette = methods.set_invert_palette, invert = methods.invert,
    clear_invert = methods.clear_invert,
    map_color = methods.map_color, update = methods.update, clear = methods.clear}
end

function methods.set_cycle(self, first, last, rate)
  first, last = math.floor(first or 0), math.floor(last or 0)
  if first < 0 or last >= self.color_count or last <= first then return false end
  self.cycle_first, self.cycle_last, self.cycle_rate = first, last, math.max(0, rate or 1)
  self.cycle_shift = math.floor(self.time * self.cycle_rate)
  return true
end
function methods.clear_cycle(self) self.cycle_first, self.cycle_last, self.cycle_rate, self.cycle_shift = -1, -1, 0, 0 end
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
    if type(value) ~= "number" or value ~= math.floor(value) or value < 0 or value >= self.color_count then return false end
  end
  for i = 1, self.color_count do self.custom_filter[i] = map[i] end
  self.filter, self.filter_count = self.custom_filter, self.color_count
  return true
end
function methods.clear_filter(self) self.filter, self.filter_count = nil, 0 end
function methods.set_pulse(self, first, second, rate)
  self.pulse_a, self.pulse_b, self.pulse_rate = math.floor(first or -1), math.floor(second or -1), math.max(0, rate or 0)
  self.pulse_phase = math.floor(self.time * self.pulse_rate * 2) % 2
end
function methods.flash(self, first, last, target, duration)
  self.flash_first = math.max(0, math.min(self.color_count - 1, math.floor(first or 0)))
  self.flash_last = math.max(self.flash_first, math.min(self.color_count - 1, math.floor(last or first or 0)))
  self.flash_color, self.flash_time = math.max(0, math.min(self.color_count - 1, math.floor(target or 7))), math.max(0, duration or 0.1)
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
  self.invert_time = math.max(0, duration or 0.1)
  return true
end
function methods.clear_invert(self) self.invert_time = 0 end
function methods.map_color(self, index)
  local color = math.floor(index or 0)
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
  dt = math.max(0, math.min(0.1, dt or 1 / 60))
  self.time, self.flash_time = self.time + dt, math.max(0, self.flash_time - dt)
  self.cycle_shift = self.cycle_rate > 0 and math.floor(self.time * self.cycle_rate) or 0
  self.pulse_phase = self.pulse_rate > 0 and math.floor(self.time * self.pulse_rate * 2) % 2 or 0
  self.invert_time = math.max(0, self.invert_time - dt)
end
function methods.clear(self)
  self.time, self.flash_time, self.invert_time = 0, 0, 0
  self.cycle_first, self.cycle_last, self.cycle_rate, self.cycle_shift = -1, -1, 0, 0
  self.filter, self.filter_count = nil, 0
  self.pulse_a, self.pulse_b, self.pulse_rate, self.pulse_phase = -1, -1, 0, 0
  self.flash_first, self.flash_last, self.flash_color = -1, -1, 0
end
-- VFX8 bounded pseudo-3D helpers for TIC-80.
-- Include this file once; it defines vfx8_pseudo3d.

vfx8_pseudo3d = vfx8_pseudo3d or {}
local methods = {}
local empty_colors = {}
local profiles = {low = {rows = 20, stars = 24, objects = 8}, medium = {rows = 40, stars = 56, objects = 18}, high = {rows = 70, stars = 104, objects = 36}}

function vfx8_pseudo3d.new(options)
  options = options or {}
  local profile = profiles[options.quality or "low"] or profiles.low
  local width, height = options.width or 240, options.height or 136
  local count = math.min(192, math.max(0, math.floor(options.star_count or profile.stars)))
  local capacity = math.min(64, math.max(1, math.floor(options.object_capacity or profile.objects)))
  local self = {width = width, height = height, horizon = options.horizon or 48,
    camera_height = options.camera_height or 52, road_width = options.road_width or 96,
    camera_x = 0, camera_z = 0, speed = options.speed or 18,
    curve = options.curve or 0, curve_strength = options.curve_strength or width * 0.32,
    mode7 = nil, mode7_angle = options.mode7_angle or 0,
    mode7_step = (options.quality == "high" and 1) or (options.quality == "medium" and 2) or 4,
    lane_count = math.min(8, math.max(1, math.floor(options.lane_count or 3))), rows = profile.rows,
    stars = {}, star_count = count, objects = {}, object_count = 0, object_capacity = capacity,
    sort_depth = {}, sort_index = {}, update = methods.update, draw = methods.draw,
    add_object = methods.add_object, clear_objects = methods.clear_objects,
    set_camera = methods.set_camera, set_road = methods.set_road,
    project = methods.project, project_road = methods.project_road,
    set_mode7 = methods.set_mode7, clear = methods.clear}
  for i = 1, count do self.stars[i] = {x = ((i * 73 % 127) / 63.5 - 1) * 48, y = -0.1 - (i * 47 % 127) / 127 * 0.9, z = 8 + i * 47 % 120, layer = i % 3} end
  for i = 1, capacity do self.objects[i] = {active = false} end
  return self
end

function methods.set_camera(self, x, horizon, speed, curve)
  if x ~= nil then self.camera_x = x end
  if horizon ~= nil then self.horizon = math.max(0, math.min(self.height - 2, horizon)) end
  if speed ~= nil then self.speed = speed end
  if curve ~= nil then self.curve = curve end
end

function methods.set_road(self, width, lanes, curve, curve_strength)
  if width ~= nil then self.road_width = math.max(1, width) end
  if lanes ~= nil then self.lane_count = math.min(8, math.max(1, math.floor(lanes))) end
  if curve ~= nil then self.curve = curve end
  if curve_strength ~= nil then self.curve_strength = curve_strength end
end

local function mode7_power2(value)
  local result = 1
  while result * 2 <= value do result = result * 2 end
  return result
end

function methods.set_mode7(self, texture)
  if texture == nil or texture == false then self.mode7 = nil; return end
  if type(texture) ~= "table" and texture ~= true then self.mode7 = nil; return false end
  texture = texture == true and {} or texture
  local x = math.max(0, math.min(127, math.floor(texture.x or 0)))
  local y = math.max(0, math.min(127, math.floor(texture.y or 0)))
  local requested_width = math.max(1, math.min(128 - x, math.floor(texture.width or 128)))
  local requested_height = math.max(1, math.min(128 - y, math.floor(texture.height or 128)))
  local width = mode7_power2(requested_width)
  local height = mode7_power2(requested_height)
  if x % width ~= 0 then x = math.floor(x / width) * width end
  if y % height ~= 0 then y = math.floor(y / height) * height end
  self.mode7 = {x = x, y = y, width = width, height = height, scale = texture.scale or 0.08}
  if texture.angle ~= nil then self.mode7_angle = texture.angle end
  return true
end

function methods.project_road(self, lateral, z, size)
  local safe_z = math.max(2.1, z or 60)
  local scale = self.camera_height / safe_z
  local y = self.horizon + scale * self.camera_height * 0.62
  local vertical = math.max(0, y - self.horizon)
  local depth = math.max(0, math.min(1, 1 - vertical / math.max(1, self.height - self.horizon)))
  local half = self.road_width * vertical / self.camera_height
  local bend = self.curve * self.curve_strength * depth * depth
  local x = self.width * 0.5 + (lateral or 0) * half - self.camera_x * depth + bend
  return x, y, (size or 1) * scale
end

function methods.update(self, dt)
  dt = math.max(0, math.min(0.1, dt or 1 / 60))
  self.camera_z = self.camera_z + self.speed * dt
  for i = 1, self.star_count do
    local star = self.stars[i]
    star.z = star.z - self.speed * dt * (0.45 + star.layer * 0.35)
    if star.z < 2 then
      local seed = math.floor(self.camera_z)
      star.z = 100 + (i % 23) * 2
      star.x = (((i * 73 + seed) % 127) / 63.5 - 1) * 48
      star.y = -0.1 - (i * 47 % 127) / 127 * 0.9
    end
  end
  for i = self.object_count, 1, -1 do
    local object = self.objects[i]
    if object.active then object.z = object.z - self.speed * dt; if object.z <= 2 then object.active = false end end
  end
  while self.object_count > 0 and not self.objects[self.object_count].active do self.object_count = self.object_count - 1 end
end

function methods.add_object(self, x, z, color, size)
  local i = 1
  while i <= self.object_capacity and self.objects[i].active do i = i + 1 end
  if i > self.object_capacity then return false end
  local object = self.objects[i]
  object.x, object.z, object.color = x or 0, math.max(2.1, z or 60), color or 11
  object.size, object.active = size or 8, true
  if i > self.object_count then self.object_count = i end
  return true
end

function methods.clear_objects(self)
  for i = 1, self.object_count do self.objects[i].active = false end
  self.object_count = 0
end

local function draw_mode7(self)
  local texture = self.mode7
  local horizon = math.max(0, math.min(self.height - 2, math.floor(self.horizon)))
  local cosine, sine = math.cos(self.mode7_angle), math.sin(self.mode7_angle)
  local step = self.mode7_step
  local row_step = step > 1 and step or 1
  local mask_x, mask_y = texture.width - 1, texture.height - 1
  local uv_scale = texture.scale
  for y = horizon + 1, self.height - 1, row_step do
    local vertical = y + row_step * 0.5 - horizon
    local distance = self.camera_height * self.camera_height * 0.62 / vertical
    local lateral = distance / self.camera_height
    local center_u = (self.camera_x + distance * sine) * uv_scale
    local center_v = (self.camera_z + distance * cosine) * uv_scale
    for x = 0, self.width - 1, step do
      local screen_lateral = x + step * 0.5 - self.width * 0.5
      local world_u = center_u + screen_lateral * lateral * cosine * uv_scale
      local world_v = center_v - screen_lateral * lateral * sine * uv_scale
      local tx = texture.x + (math.floor(world_u) & mask_x)
      local ty = texture.y + (math.floor(world_v) & mask_y)
      local color = peek4(0xc000 + ty * 128 + tx)
      rect(x, y, step, row_step, color)
    end
  end
end

function methods.project(self, x, z, size)
  local scale = self.camera_height / math.max(2.1, z or 60)
  return self.width * 0.5 + ((x or 0) - self.camera_x) * scale,
    self.horizon + scale * self.camera_height * 0.62, (size or 1) * scale
end

function methods.draw(self, colors)
  colors = colors or empty_colors
  local sky, road_a, road_b, edge, ground = colors.sky or 1, colors.road_a or 1, colors.road_b or 13, colors.edge or 11, colors.ground or 3
  local cx = self.width * 0.5
  cls(sky)
  if self.mode7 then draw_mode7(self)
  else rect(0, self.horizon, self.width, self.height - self.horizon, ground) end
  if not self.mode7 then for row = 1, self.rows do
    if self.horizon + row < self.height then
      local y = self.horizon + math.floor((row - 1) * (self.height - self.horizon) / self.rows) + 1
      local next_y = math.min(self.height - 1, self.horizon + math.floor(row * (self.height - self.horizon) / self.rows))
      if next_y < y then next_y = y end
      local distance = y - self.horizon
      local depth = math.max(0, math.min(1, 1 - distance / (self.height - self.horizon)))
      local half = math.min(self.width * 1.5, self.road_width * distance / self.camera_height)
      local shift = self.camera_x * depth + self.curve * self.curve_strength * depth * depth
      local left, right = cx - half - shift, cx + half - shift
      local x0, x1 = math.max(0, math.floor(left)), math.min(self.width - 1, math.floor(right))
      local c = (math.floor(self.camera_z / 8 + distance * 0.2) % 2 == 0) and road_a or road_b
      if next_y < y then next_y = y end
      if x0 <= x1 then
        rect(x0, y, x1 - x0 + 1, next_y - y, c)
        if row % 3 == 0 then line(x0, y, x0, y, edge); line(x1, y, x1, y, edge) end
        if self.lane_count > 1 and row % 2 == 0 and math.floor(self.camera_z / 6 + distance * 0.12) % 2 == 0 then
          for lane = 1, self.lane_count - 1 do
            local lane_x = left + half * 2 * lane / self.lane_count
            rect(lane_x, y, math.max(1, distance / self.camera_height * 4), math.max(1, next_y - y), edge)
          end
        end
      end
    end
  end end
  for i = 1, self.star_count do
    local star = self.stars[i]
    local scale = self.camera_height / star.z
    local x, y = cx + (star.x - self.camera_x * 0.08) * scale, self.horizon + star.y * scale
    if x >= 0 and x < self.width and y >= 0 and y < self.horizon then pix(x, y, (colors.stars and colors.stars[star.layer + 1]) or 12) end
  end
  local count = 0
  for i = 1, self.object_count do
    local object = self.objects[i]
    if object.active then
      count = count + 1
      local at = count
      while at > 1 and self.sort_depth[at - 1] < object.z do self.sort_depth[at], self.sort_index[at] = self.sort_depth[at - 1], self.sort_index[at - 1]; at = at - 1 end
      self.sort_depth[at], self.sort_index[at] = object.z, i
    end
  end
  for n = 1, count do
    local object = self.objects[self.sort_index[n]]
    local x, y, projected_size = self:project_road(object.x, object.z, object.size)
    local size = math.max(1, math.floor(projected_size))
    if x + size >= 0 and x - size < self.width and y + size >= self.horizon and y - size < self.height then
      rect(x - size / 2, y - size, size, size, object.color)
    end
  end
end

function methods.clear(self) methods.clear_objects(self); self.camera_z = 0 end
-- VFX8 flame effects for TIC-80.
-- Include this file at build time; it defines vfx8_flames.

vfx8_flames = vfx8_flames or {}
local methods = {}
local capacities = {24, 48, 80}
local emission_caps = {8, 16, 24}
local jet_counts = {6, 10, 14}
local fire_counts = {2, 4, 6}
local empty_options = {}

function vfx8_flames.new(options)
  options = options or {}
  local profile = 1
  if options.quality == "medium" or options.quality == 2 then profile = 2 end
  if options.quality == "high" or options.quality == 3 then profile = 3 end
  local capacity = math.floor(options.capacity or capacities[profile])
  capacity = math.max(1, math.min(128, capacity))
  local max_emit = math.max(1, math.min(capacity, math.floor(options.max_emit or emission_caps[profile])))
  local seed = math.floor(options.seed or 1) % 251
  if seed < 1 then seed = 1 end
  local self = {profile = profile, capacity = capacity, max_emit = max_emit,
    count = 0, frame_used = 0, last_emitted = 0, seed = seed,
    x = {}, y = {}, vx = {}, vy = {}, age = {}, life = {}, size = {},
    gravity = {}, drag = {}, kind = {}}
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

local function random(self)
  self.seed = (self.seed * 17 + 31) % 251
  return self.seed / 251
end

local function emit(self, kind, x, y, dx, dy, options)
  options = options or empty_options
  local requested = math.floor(options.count or (kind == 1 and jet_counts[self.profile] or fire_counts[self.profile]))
  if requested < 1 then return 0 end
  local spawn = math.min(requested, self.max_emit - self.frame_used, self.capacity - self.count)
  if spawn < 1 then return 0 end
  local speed = options.speed or (kind == 1 and 92 or 42)
  local spread = options.spread
  if spread == nil then spread = kind == 1 and 0.22 or 5 end
  spread = math.max(0, spread)
  local radius = math.max(0, options.radius or 1)
  local gravity = options.gravity
  if gravity == nil then gravity = kind == 1 and 8 or -3 end
  local drag = options.drag
  if drag == nil then drag = kind == 1 and 1.2 or 0.9 end
  local life = math.max(0.05, options.life or (kind == 1 and 0.42 or 0.72))
  local base_size = math.max(1, options.size or (kind == 1 and 3 or 4))
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
  local length = math.sqrt(dx * dx + dy * dy)
  if length <= 0 then return 0 end
  return emit(self, 1, x, y, dx / length, dy / length, options)
end

function methods.emit_campfire(self, x, y, options) return emit(self, 2, x, y, 0, -1, options) end

function methods.update(self, dt)
  dt = math.min(0.1, math.max(0, dt or 1 / 60))
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
      local keep = math.max(0, 1 - drag[i] * dt)
      ages[i] = age
      vx[i], vy[i] = vx[i] * keep, vy[i] * keep + gravity[i] * dt
      x[i], y[i] = x[i] + vx[i] * dt, y[i] + vy[i] * dt
      i = i + 1
    end
  end
  self.count = count
  self.last_emitted, self.frame_used = self.frame_used, 0
end

function methods.draw(self)
  local x, y, ages, lives = self.x, self.y, self.age, self.life
  local sizes, kinds = self.size, self.kind
  for i = 1, self.count do
    local t = ages[i] / lives[i]
    local col
    if kinds[i] == 1 then
      col = t < 0.18 and 7 or (t < 0.48 and 10 or (t < 0.78 and 9 or 8))
    else
      col = t < 0.30 and 10 or (t < 0.68 and 9 or (t < 0.90 and 8 or 4))
    end
    local size = math.max(1, math.floor(sizes[i] * (1 - t * 0.82) + 0.5))
    local px, py = math.floor(x[i] + 0.5), math.floor(y[i] + 0.5)
    rect(px, py, size, size + 1, col)
  end
end

function methods.clear(self) self.count, self.frame_used, self.last_emitted = 0, 0, 0 end
function methods.stats(self) return self.count, self.capacity, self.last_emitted end
-- VFX8 electric arcs for TIC-80.
-- Include this module in your game project; it defines vfx8_electricity.

local electricity = {}
vfx8_electricity = electricity
local methods = {}
local floor, min, max, sqrt = math.floor, math.min, math.max, math.sqrt
local capacities = {32, 64, 112}
local emission_caps = {16, 24, 32}
local segment_counts = {5, 7, 10}
local branch_counts = {1, 1, 2}
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
  local capacity = max(1, min(112, floor(options.capacity or capacities[profile])))
  local max_emit = max(1, min(capacity, floor(options.max_emit or emission_caps[profile])))
  local seed = floor(options.seed or 1) % 251
  if seed < 1 then seed = 1 end
  local self = {profile = profile, capacity = capacity, max_emit = max_emit,
    count = 0, frame_used = 0, last_emitted = 0, seed = seed,
    x1 = {}, y1 = {}, x2 = {}, y2 = {}, age = {}, life = {}, width = {}, point_x = {}, point_y = {}}
  for i = 1, capacity do
    self.x1[i], self.y1[i], self.x2[i], self.y2[i] = 0, 0, 0, 0
    self.age[i], self.life[i], self.width[i] = 0, 0, 1
  end
  for i = 1, 25 do self.point_x[i], self.point_y[i] = 0, 0 end
  self.strike, self.update, self.draw = methods.strike, methods.update, methods.draw
  self.clear, self.stats = methods.clear, methods.stats
  return self
end

local function append(self, ax, ay, bx, by, life, width)
  if self.count >= self.capacity or self.frame_used >= self.max_emit then return false end
  local i = self.count + 1
  self.count = i
  self.x1[i], self.y1[i], self.x2[i], self.y2[i] = ax, ay, bx, by
  self.age[i], self.life[i], self.width[i] = 0, life, width
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
  local before = self.frame_used
  local px, py = x1, y1
  local points_x, points_y = self.point_x, self.point_y
  points_x[1], points_y[1] = x1, y1
  for i = 1, steps do
    local t = i / steps
    local offset = i == steps and 0 or (random(self) - 0.5) * 2 * amplitude * min(1, t * 4, (1 - t) * 4)
    local qx, qy = x1 + dx * t + nx * offset, y1 + dy * t + ny * offset
    if not append(self, px, py, qx, qy, life, width) then break end
    points_x[i + 1], points_y[i + 1] = qx, qy
    px, py = qx, qy
  end
  for b = 1, branches do
    local at = max(2, min(steps, floor(steps * (b / (branches + 1)))))
    local sx, sy = points_x[at], points_y[at]
    if sx and self.frame_used < self.max_emit and self.count < self.capacity then
      local side = random(self) < 0.5 and -1 or 1
      local reach = length * (0.16 + random(self) * 0.16)
      local bx = sx + dx / length * reach * 0.55 + nx * reach * side
      local by = sy + dy / length * reach * 0.55 + ny * reach * side
      local branch_steps = 2 + floor(random(self) * 2)
      local lx, ly = sx, sy
      for j = 1, branch_steps do
        local t = j / branch_steps
        local jitter = (random(self) - 0.5) * amplitude * 0.7
        local qx = sx + (bx - sx) * t + nx * jitter
        local qy = sy + (by - sy) * t + ny * jitter
        if not append(self, lx, ly, qx, qy, life, width) then break end
        lx, ly = qx, qy
      end
    end
  end
  return self.frame_used - before
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
      age[i], life[i], self.width[i] = age[last], life[last], self.width[last]
      count = last - 1
    else
      age[i] = next_age
      i = i + 1
    end
  end
  self.count, self.last_emitted, self.frame_used = count, self.frame_used, 0
end

function methods.draw(self)
  for i = 1, self.count do
    local fade = 1 - self.age[i] / self.life[i]
    local col = fade > 0.55 and 7 or (fade > 0.2 and 12 or 13)
    line(self.x1[i], self.y1[i], self.x2[i], self.y2[i], col)
  end
end
function methods.clear(self)
  self.count, self.frame_used, self.last_emitted = 0, 0, 0
end

function methods.stats(self)
  return self.count, self.capacity, self.last_emitted
end


local width,height,top,bottom=240,136,22,124
local catalog={
 {1,"EXPLOSION / POINT","explosion","point"},{1,"EXPLOSION / LINE","explosion","line"},{1,"EXPLOSION / AREA","explosion","area"},
 {1,"SPARKS / POINT","sparks","point"},{1,"SPARKS / LINE","sparks","line"},{1,"SPARKS / AREA","sparks","area"},
 {1,"TRAIL / POINT","trail","point"},{1,"TRAIL / LINE","trail","line"},{1,"TRAIL / AREA","trail","area"},
 {1,"SMOKE / POINT","smoke","point"},{1,"SMOKE / LINE","smoke","line"},{1,"SMOKE / AREA","smoke","area"},
 {1,"DUST / POINT","dust","point"},{1,"DUST / LINE","dust","line"},{1,"DUST / AREA","dust","area"},
 {2,"TRAUMA SHAKE","trauma"},{2,"LEFT IMPULSE","left"},{2,"RIGHT IMPULSE","right"},{2,"SHOCKWAVE / RIPPLE","shockwave"},{2,"SCREEN FLASH","flash"},
 {3,"WAVE WARP","wave"},{3,"WAVE + ROTATION","rotation"},{3,"SQUASH / STRETCH","squash"},{3,"ORDERED DISSOLVE","ordered"},{3,"CHECKER DISSOLVE","checker"},{3,"SPIRAL DISSOLVE","spiral"},
 {4,"COLOR CYCLING","cycle"},{4,"NIGHT FILTER","night"},{4,"SEPIA FILTER","sepia"},{4,"MONOCHROME FILTER","mono"},{4,"GLOW PULSE","glow"},{4,"DAMAGE FLASH","damage"},{4,"NEGATIVE FLASH","negative"},{4,"CUSTOM DUSK MAP","dusk"},
 {5,"MODE 7 TEXTURED PLANE","mode7"},{5,"PARALLAX STARFIELD","stars"},{5,"DEPTH-PROJECTED OBJECT","object"},
 {6,"FLAMETHROWER JET","jet"},{6,"CAMPFIRE PLUME","campfire"},
 {7,"BRANCHED LIGHTNING","branched"},{7,"CLEAN LIGHTNING ARC","clean"}
}
local group_names={"PARTICLES","SCREEN FX","PIXEL WARP","PALETTE FX","PSEUDO-3D","FLAMES","ELECTRICITY"}
local road_colors={sky=1,ground=3,road_a=1,road_b=13,edge=11,stars={12,14,15}}
local rgb_palette={{0,0,0},{0.114,0.169,0.325},{0.494,0.145,0.325},{0,0.529,0.318},{0.671,0.322,0.212},{0.373,0.341,0.31},{0.761,0.765,0.78},{1,0.945,0.91},{1,0.004,0.278},{1,0.639,0},{1,0.925,0.153},{0,0.894,0.165},{0.161,0.678,1},{0.514,0.463,0.616},{1,0.467,0.659},{1,0.8,0.667}}
local dusk_map={0,1,1,2,3,4,5,6,2,3,5,4,1,2,3,6}
local selected,selected_group=1,0
local entry,effect
local player={x=120,y=74,speed=72}
local clock,dissolve_time=0,nil

local function prepare_mode7_texture()
 for y=0,63 do for x=0,63 do
  local color=(math.floor(x/8)+math.floor(y/8))%2==0 and 5 or 6
  if x%32<2 or x%32>29 then color=13 end
  poke4(0xc000+y*128+x,color)
 end end
end
local function create_effect(group)
 if group==1 then return vfx8_particles.new({quality="low"})
 elseif group==2 then return vfx8_screen_fx.new({width=width,height=height,capacity=8})
 elseif group==3 then return vfx8_pixel_deform.new({quality="low"})
 elseif group==4 then
  local fx=vfx8_palette_fx.new({quality="low",color_count=16})
  fx:set_invert_palette(rgb_palette)
  return fx
 elseif group==5 then return vfx8_pseudo3d.new({quality="low",width=width,height=bottom,horizon=34})
 elseif group==6 then return vfx8_flames.new({quality="low"})
 else return vfx8_electricity.new({quality="low"}) end
end
local function configure_entry()
 entry=catalog[selected]
 if selected_group~=entry[1] or not effect then
  if effect and effect.clear then effect:clear() end
  effect=create_effect(entry[1]); selected_group=entry[1]
 elseif effect and effect.clear then effect:clear() end
 if entry[1]==4 then
  if entry[3]=="cycle" then effect:set_cycle(8,11,2)
  elseif entry[3]=="night" or entry[3]=="sepia" or entry[3]=="mono" then effect:set_filter(entry[3])
  elseif entry[3]=="glow" then effect:set_pulse(8,10,4)
  elseif entry[3]=="dusk" then effect:set_filter_map(dusk_map) end
 elseif entry[1]==5 then
  if entry[3]=="mode7" then effect:set_mode7({x=0,y=0,width=64,height=64,scale=0.6})
  else effect:set_mode7(false) end
 end
 dissolve_time=nil
end
local function next_entry()
 selected=selected%#catalog+1
 configure_entry()
end
local function trigger_effect()
 local mode=entry[3]
 if entry[1]==1 then
  local preset,shape=entry[3],entry[4]
  if shape=="line" then effect:emit_line(preset,math.max(8,player.x-24),player.y,math.min(width-8,player.x+24),player.y,{spread=2})
  elseif shape=="area" then effect:emit_area(preset,player.x-12,player.y-8,24,16)
  else effect:emit(preset,player.x,player.y) end
 elseif entry[1]==2 then
  if mode=="trauma" then effect:add_trauma(0.9)
  elseif mode=="left" then effect:impulse(-5,0,0.2)
  elseif mode=="right" then effect:impulse(5,0,0.2)
  elseif mode=="shockwave" then effect:shockwave(player.x,player.y,2,10,0.35)
  else effect:flash(0.13,7) end
 elseif entry[1]==3 then
  if mode=="squash" then effect:set_squash(1.55,0.6,0.3)
  elseif mode=="ordered" or mode=="checker" or mode=="spiral" then dissolve_time=0
  else effect.phase=0 end
 elseif entry[1]==4 then
  if mode=="damage" then effect:flash(8,10,7,0.2)
  elseif mode=="negative" then effect:invert(0.2)
  else effect:flash(8,10,7,0.15) end
 elseif entry[1]==5 then effect:add_object((player.x-width/2)/(width/2)*0.7,90,11,6)
 elseif entry[1]==6 then
  if mode=="jet" then effect:emit_jet(player.x,player.y,1,-0.12)
  else effect:emit_campfire(player.x,player.y+8,{count=8,radius=5}) end
 else effect:strike(player.x,player.y,math.min(width-12,player.x+52),math.max(top+8,player.y-40),{branches=mode=="branched" and 2 or 0,jaggedness=mode=="clean" and 2 or 8}) end
end
local function update_game()
 local dx=(btn(3) and 1 or 0)-(btn(2) and 1 or 0)
 local dy=(btn(1) and 1 or 0)-(btn(0) and 1 or 0)
 player.x=math.max(4,math.min(width-4,player.x+dx*player.speed/60))
 player.y=math.max(top+4,math.min(bottom-8,player.y+dy*player.speed/60))
 clock=clock+1/60
 if entry[1]==6 and entry[3]=="campfire" then effect:emit_campfire(player.x,player.y+8,{count=2,radius=3}) end
 effect:update(1/60)
 if dissolve_time then dissolve_time=dissolve_time+1/60; if dissolve_time>=0.7 then dissolve_time=nil end end
 if entry[1]==5 then effect:set_road(nil,nil,math.sin(clock*0.25)*0.35) end
end
local function mapped_color(index)
 if entry[1]==4 then return effect:map_color(index) end
 return index
end
local function draw_warp_grid()
 local rotating=entry[3]=="rotation"
 local left,min_y,right,max_y=0,top,width-1,bottom
 if rotating then
  effect:set_rotation(player.x,player.y,clock*0.45)
  left,min_y,right,max_y=effect:rotation_bounds(left,min_y,right,max_y,16)
 end
 local function point(x,y)
  local px=x+effect:wave_offset(y,clock,7,84,0.7,x/24)
  local py=y+effect:wave_offset(x,clock,7,84,0.7,y/24)
  if rotating then return effect:rotate_point(px,py) end
  return px,py
 end
 clip(0,top,width,bottom-top+1)
 for x=math.floor(left/24)*24,right+24,24 do
  for y=math.floor(min_y/12)*12,max_y-12,12 do
   local x1,y1=point(x,y); local x2,y2=point(x,y+12)
   line(x1,y1,x2,y2,mapped_color(13))
  end
 end
 for y=math.floor(min_y/24)*24,max_y+24,24 do
  for x=math.floor(left/12)*12,right-12,12 do
   local x1,y1=point(x,y); local x2,y2=point(x+12,y)
   line(x1,y1,x2,y2,mapped_color(13))
  end
 end
 clip()
end
local function draw_world()
 if entry[1]==5 then effect:draw(road_colors)
 else
  cls(mapped_color(1)); rect(0,top,width-1,bottom,mapped_color(2))
  if entry[1]==3 and (entry[3]=="wave" or entry[3]=="rotation") then draw_warp_grid()
  else
   for x=0,width,24 do line(x,top,x,bottom,mapped_color(13)) end
   for y=top,bottom,24 do line(0,y,width-1,y,mapped_color(13)) end
  end
 end
 if entry[1]==3 and (entry[3]=="ordered" or entry[3]=="checker" or entry[3]=="spiral") and dissolve_time then
  local amount=math.min(1,dissolve_time/0.7)
  for y=0,7 do for x=0,7 do if effect:visible(player.x-4+x,player.y-4+y,amount,entry[3]) then pix(player.x-4+x,player.y-4+y,mapped_color(8)) end end end
 else
  local sx,sy=1,1
  if entry[1]==3 and entry[3]=="squash" then sx,sy=effect:scale() end
  local pw,ph=math.max(4,math.floor(8*sx)),math.max(4,math.floor(8*sy))
  rect(math.floor(player.x-pw/2),math.floor(player.y-ph/2),pw,ph,mapped_color(8))
 end
 if (entry[1]==1 or entry[1]==6 or entry[1]==7) and effect.draw then effect:draw() end
end
function TIC()
 if btnp(5) then next_entry() end
 if btnp(4) then trigger_effect() end
 update_game()
 if entry[1]==2 then effect:render(draw_world) else draw_world() end
 rect(0,0,width-1,top-1,0)
 local title=group_names[entry[1]].." / "..entry[2]
 print(title,math.max(1,(width-#title*6)/2),5,15)
 rect(0,bottom+1,width-1,height-bottom-1,0)
 print("ARROWS MOVE  A: FIRE  B: NEXT VARIANT",4,height-8,12)
end
