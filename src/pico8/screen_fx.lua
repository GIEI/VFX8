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
    capacity = options.capacity or 4,
    trauma = 0,
    shake_x = 0,
    shake_y = 0,
    shake_time = 0,
    shake_duration = 0,
    offset_x = 0,
    offset_y = 0,
    flash_time = 0,
    flash_duration = 0,
    flash_color = 7,
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

function methods.add_trauma(self, amount)
  self.trauma = min(1, self.trauma + max(0, amount or 0))
end

function methods.impulse(self, x, y, duration)
  self.shake_x = x or 0
  self.shake_y = y or 0
  self.trauma = max(self.trauma, 1)
  self.shake_duration = max(0.001, duration or 0.12)
  self.shake_time = self.shake_duration
end

function methods.flash(self, duration, color)
  self.flash_duration = max(0.001, duration or 0.08)
  self.flash_time = self.flash_duration
  self.flash_color = color or 7
end

function methods.shockwave(self, x, y, radius, strength, duration)
  if self.wave_count >= self.capacity then return false end
  local i = self.wave_count + 1
  local wave = self.waves[i] or {}
  wave.x, wave.y = x, y
  wave.radius, wave.strength = radius or 0, strength or 8
  wave.age, wave.life = 0, max(0.05, duration or 0.3)
  self.waves[i] = wave
  self.wave_count = i
  return true
end

function methods.update(self, dt)
  dt = min(0.1, max(0, dt or 1 / 60))
  self.trauma = max(0, self.trauma - dt * 2.5)
  self.shake_time = max(0, self.shake_time - dt)
  self.flash_time = max(0, self.flash_time - dt)
  self.seed = (self.seed * 17 + 31) % 251
  local nx = self.seed / 251 - 0.5
  self.seed = (self.seed * 17 + 31) % 251
  local ny = self.seed / 251 - 0.5
  local trauma = self.trauma * self.trauma
  local decay = self.shake_duration > 0 and self.shake_time / self.shake_duration or 0
  self.offset_x = (self.shake_x + nx * 2) * trauma * decay
  self.offset_y = (self.shake_y + ny * 2) * trauma * decay
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
    circ(wave.x, wave.y, wave.radius + t * wave.strength * 8, t < 0.5 and 7 or 6)
  end
  if self.flash_time > 0 then rectfill(0, 0, self.width - 1, self.height - 1, self.flash_color) end
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
