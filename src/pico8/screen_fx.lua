-- VFX8 screen effects for PICO-8.
-- Include this file once; it defines vfx8_screen_fx.

vfx8_screen_fx = vfx8_screen_fx or {}

local methods = {}
local empty_options = {}

function vfx8_screen_fx.new(options)
  options = options or empty_options
  return {
    width = options.width or 128,
    height = options.height or 128,
    capacity = min(4, max(1, flr(options.capacity or 4))),
    trauma = 0,
    shake_x = 0,
    shake_y = 0,
    shake_time = 0,
    shake_duration = 0,
    offset_x = 0,
    offset_y = 0,
    flash_time = 0,
    flash_duration = 0,
    flash_color = options.flash_color or 7,
    shake_intensity = options.shake_intensity or 8,
    shake_legacy = options.shake_intensity == nil and options.shake_decay == nil and options.shake_frequency == nil and options.shake_randomness == nil and options.shake_envelope == nil,
    shake_decay = options.shake_decay or 2.5,
    shake_frequency = options.shake_frequency or 60,
    shake_randomness = options.shake_randomness == nil and 1 or options.shake_randomness,
    shake_envelope = options.shake_envelope or "linear",
    shake_direction_x = 0, shake_direction_y = 0, shake_phase = 0, shake_noise_x = 0, shake_noise_y = 0,
    flash_intensity = 1, flash_mode = "color",
    waves = {},
    wave_count = 0,
    seed = options.seed or 1,
    update = methods.update,
    add_trauma = methods.add_trauma,
    impulse = methods.impulse,
    flash = methods.flash,
    shockwave = methods.shockwave,
    get_shake_offset = methods.get_shake_offset,
    draw_overlays = methods.draw_overlays,
    render = methods.render,
    clear = methods.clear
  }
end

function methods.add_trauma(self, amount, options)
  options = options or empty_options
  if options.intensity ~= nil or options.decay ~= nil or options.frequency ~= nil or options.randomness ~= nil or options.envelope ~= nil then self.shake_legacy = false end
  self.trauma = min(1, self.trauma + max(0, amount or 0))
  self.shake_duration = max(self.shake_duration, 0.35)
  self.shake_time = max(self.shake_time, self.shake_duration)
  self.shake_intensity = options.intensity or self.shake_intensity
  self.shake_decay = options.decay or self.shake_decay
  self.shake_frequency = options.frequency or self.shake_frequency
  self.shake_randomness = options.randomness == nil and self.shake_randomness or options.randomness
  self.shake_envelope = options.envelope or self.shake_envelope
end

function methods.impulse(self, x, y, duration, options)
  options = options or empty_options
  if options.intensity ~= nil or options.decay ~= nil or options.frequency ~= nil or options.randomness ~= nil or options.envelope ~= nil or options.direction_x ~= nil or options.direction_y ~= nil then self.shake_legacy = false end
  self.shake_x = x or 0
  self.shake_y = y or 0
  self.shake_direction_x = options.direction_x or 0
  self.shake_direction_y = options.direction_y or 0
  self.shake_intensity = options.intensity or 8
  self.shake_decay = options.decay or 2.5
  self.shake_frequency = options.frequency or 60
  self.shake_randomness = options.randomness == nil and 1 or options.randomness
  self.shake_envelope = options.envelope or "linear"
  self.trauma = max(self.trauma, 1)
  self.shake_duration = max(0.001, duration or 0.12)
  self.shake_time = self.shake_duration
end

function methods.flash(self, duration, color, options)
  options = options or empty_options
  self.flash_duration = max(0.001, duration or 0.08)
  self.flash_time = self.flash_duration
  self.flash_color = color or options.color or 7
  self.flash_intensity = options.intensity == nil and 1 or max(0, min(1, options.intensity))
  self.flash_mode = options.mode or "color"
end

function methods.shockwave(self, x, y, radius, strength, duration, options)
  options = options or empty_options
  if self.wave_count >= self.capacity then return false end
  local i = self.wave_count + 1
  local wave = self.waves[i] or {}
  wave.x, wave.y = options.center_x or x, options.center_y or y
  wave.radius, wave.strength = radius or 0, strength or 8
  wave.age, wave.life = 0, max(0.05, duration or 0.3)
  wave.max_radius = options.max_radius or (radius or 0) + (options.speed or ((strength or 8) * 8 / wave.life)) * wave.life
  wave.thickness = max(1, options.thickness or 1)
  wave.falloff = max(0.1, options.falloff or 1)
  self.waves[i] = wave
  self.wave_count = i
  return true
end

function methods.update(self, dt)
  dt = min(0.1, max(0, dt or 1 / 60))
  self.trauma = max(0, self.trauma - dt * self.shake_decay)
  self.shake_time = max(0, self.shake_time - dt)
  self.flash_time = max(0, self.flash_time - dt)
  local nx, ny
  if self.shake_legacy then
    self.seed = (self.seed * 17 + 31) % 251
    nx = self.seed / 251 - 0.5
    self.seed = (self.seed * 17 + 31) % 251
    ny = self.seed / 251 - 0.5
  else
    self.shake_phase = self.shake_phase + dt * self.shake_frequency
    if self.shake_frequency >= 60 or self.shake_phase >= 1 then
      self.seed = (self.seed * 17 + 31) % 251
      self.shake_noise_x = self.seed / 251 - 0.5
      self.seed = (self.seed * 17 + 31) % 251
      self.shake_noise_y = self.seed / 251 - 0.5
      self.shake_phase = self.shake_phase % 1
    end
  end
  local trauma = self.trauma * self.trauma
  local decay = self.shake_duration > 0 and self.shake_time / self.shake_duration or 0
  if self.shake_envelope == "trapezoid" then decay = min(1, (1 - decay) * 4, decay * 4) end
  if self.shake_envelope == "smooth" then decay = decay * decay * (3 - 2 * decay) end
  if self.shake_legacy then
    self.offset_x = (self.shake_x + nx * 8) * trauma * decay
    self.offset_y = (self.shake_y + ny * 8) * trauma * decay
  else
    self.offset_x = (self.shake_x + self.shake_direction_x + self.shake_noise_x * self.shake_intensity * self.shake_randomness) * trauma * decay
    self.offset_y = (self.shake_y + self.shake_direction_y + self.shake_noise_y * self.shake_intensity * self.shake_randomness) * trauma * decay
  end
  local i = 1
  while i <= self.wave_count do
    local wave = self.waves[i]
    wave.age += dt
    if wave.age >= wave.life then
      self.waves[i] = self.waves[self.wave_count]
      self.waves[self.wave_count] = wave
      self.wave_count -= 1
    else
      i += 1
    end
  end
end

function methods.get_shake_offset(self)
  return self.offset_x, self.offset_y
end

function methods.draw_overlays(self)
  for i = 1, self.wave_count do
    local wave = self.waves[i]
    local t = wave.age / wave.life
    local radius = wave.radius + (wave.max_radius - wave.radius) * (t ^ wave.falloff)
    for band = 0, wave.thickness - 1 do circ(wave.x, wave.y, radius - band, t < 0.5 and 7 or 6) end
  end
  if self.flash_time > 0 and self.flash_intensity > 0 then rectfill(0, 0, self.width - 1, self.height - 1, self.flash_color) end
end

function methods.render(self, draw_scene)
  local camera_x, camera_y = peek2(0x5f28), peek2(0x5f2a)
  camera(camera_x + flr(self.offset_x), camera_y + flr(self.offset_y))
  draw_scene()
  camera()
  methods.draw_overlays(self)
  camera(camera_x, camera_y)
end

function methods.clear(self)
  self.trauma, self.shake_time, self.flash_time, self.wave_count = 0, 0, 0, 0
  self.offset_x, self.offset_y = 0, 0
end
