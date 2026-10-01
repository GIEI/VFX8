-- VFX8 screen effects for Picotron.
-- Include this file once from the cartridge root.

vfx8_screen_fx = vfx8_screen_fx or {}
local methods, empty_options = {}, {}

function vfx8_screen_fx.new(options)
  options = options or empty_options
  return {
    width = options.width or 240, height = options.height or 136,
    capacity = options.capacity or 8, trauma = 0, shake_x = 0, shake_y = 0,
    shake_time = 0, shake_duration = 0, flash_time = 0,
    flash_duration = 0, flash_color = 7, waves = {}, wave_count = 0,
    seed = options.seed or 1, update = methods.update,
    add_trauma = methods.add_trauma, impulse = methods.impulse,
    flash = methods.flash, shockwave = methods.shockwave,
    render = methods.render, clear = methods.clear
  }
end

function methods.add_trauma(self, amount) self.trauma = min(1, self.trauma + max(0, amount or 0)) end
function methods.impulse(self, x, y, duration)
  self.shake_x, self.shake_y = x or 0, y or 0
  self.trauma = max(self.trauma, 1)
  self.shake_duration = max(0.001, duration or 0.12)
  self.shake_time = self.shake_duration
end
function methods.flash(self, duration, color)
  self.flash_duration = max(0.001, duration or 0.08)
  self.flash_time, self.flash_color = self.flash_duration, color or 7
end
function methods.shockwave(self, x, y, radius, strength, duration)
  if self.wave_count >= self.capacity then return false end
  local i = self.wave_count + 1
  local wave = self.waves[i] or {}
  wave.x, wave.y = x, y
  wave.radius, wave.strength = radius or 0, strength or 8
  wave.age, wave.life = 0, max(0.05, duration or 0.3)
  self.waves[i], self.wave_count = wave, i
  return true
end
function methods.update(self, dt)
  dt = min(0.1, max(0, dt or 1 / 60))
  self.trauma = max(0, self.trauma - dt * 2.5)
  self.shake_time, self.flash_time = max(0, self.shake_time - dt), max(0, self.flash_time - dt)
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
function methods.render(self, draw_scene)
  self.seed = (self.seed * 17 + 31) % 251
  local nx = self.seed / 251 - 0.5
  self.seed = (self.seed * 17 + 31) % 251
  local ny = self.seed / 251 - 0.5
  local trauma = self.trauma * self.trauma
  local decay = self.shake_duration > 0 and self.shake_time / self.shake_duration or 0
  camera(flr((self.shake_x + nx * 2) * trauma * decay), flr((self.shake_y + ny * 2) * trauma * decay))
  draw_scene()
  camera()
  for i = 1, self.wave_count do
    local wave = self.waves[i]
    local t = wave.age / wave.life
    circ(wave.x, wave.y, wave.radius + t * wave.strength * 8, t < 0.5 and 7 or 6)
  end
  if self.flash_time > 0 then rectfill(0, 0, self.width - 1, self.height - 1, self.flash_color) end
end
function methods.clear(self) self.trauma, self.shake_time, self.flash_time, self.wave_count = 0, 0, 0, 0 end
