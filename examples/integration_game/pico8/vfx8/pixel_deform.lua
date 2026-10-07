-- VFX8 pixel deformation helpers for PICO-8.
-- Include this file once; it defines vfx8_pixel_deform.

vfx8_pixel_deform = vfx8_pixel_deform or {}

local methods = {}
local bayer = {0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5}
local spiral = {0, 12, 3, 15, 8, 4, 11, 7, 2, 14, 1, 13, 10, 6, 9, 5}

function vfx8_pixel_deform.new(options)
  options = options or {}
  local quality = options.quality or "low"
  local wave_amplitude, wave_wavelength, wave_speed = options.amplitude or 2, max(1, options.wavelength or 16), options.speed or 1
  return {
    quality = quality,
    wave_amplitude = wave_amplitude, wave_wavelength = wave_wavelength, wave_speed = wave_speed,
    wave_phase = options.wave_phase or 0, wave_axis = options.axis or "y", wave_direction = options.direction or 1,
    warp_speed_x = options.scroll_speed_x or 0, warp_speed_y = options.scroll_speed_y or 0,
    warp_amplitude = options.warp_amplitude or wave_amplitude, warp_wavelength = max(1, options.warp_wavelength or wave_wavelength),
    warp_frequency = options.frequency or 0, warp_phase = options.warp_phase or 0, warp_rotation = options.rotation or 0,
    warp_center_x = options.center_x or 0, warp_center_y = options.center_y or 0,
    sample_step = max(1, flr(options.sample_step or (quality == "high" and 1 or quality == "medium" and 2 or 4))),
    squash_overshoot = options.overshoot or 0, squash_easing = options.easing or "sine",
    squash_anchor_x = options.anchor_x or 0.5, squash_anchor_y = options.anchor_y or 0.5,
    dissolve_amount = options.amount or 0, dissolve_mode = options.mode or "ordered",
    dissolve_direction = options.dissolve_direction or "in", dissolve_seed = options.seed or 0, dissolve_matrix = nil,
    phase = options.phase or 0,
    squash_x = 1,
    squash_y = 1,
    squash_time = 0,
    squash_duration = 0.2,
    rotation_x = 0,
    rotation_y = 0,
    rotation_sin = 0,
    rotation_cos = 1,
    wave_offset = methods.wave_offset, set_wave = methods.set_wave, warp_point = methods.warp_point, warp_step = methods.warp_step, set_dissolve = methods.set_dissolve,
    set_squash = methods.set_squash,
    update = methods.update,
    scale = methods.scale,
    visible = methods.visible,
    set_rotation = methods.set_rotation,
    rotate_point = methods.rotate_point,
    rotation_bounds = methods.rotation_bounds,
    clear = methods.clear
  }
end

function methods.set_rotation(self, center_x, center_y, angle)
  self.rotation_x, self.rotation_y = center_x, center_y
  local turns = (angle or 0) / 6.283185
  self.rotation_sin, self.rotation_cos = sin(turns), cos(turns)
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
  local sin_a, cos_a = self.rotation_sin, self.rotation_cos
  local ax, ay = self.rotation_x + x1 * cos_a + y1 * sin_a, self.rotation_y - x1 * sin_a + y1 * cos_a
  local bx, by = self.rotation_x + x2 * cos_a + y2 * sin_a, self.rotation_y - x2 * sin_a + y2 * cos_a
  local cx, cy = self.rotation_x + x3 * cos_a + y3 * sin_a, self.rotation_y - x3 * sin_a + y3 * cos_a
  local dx, dy = self.rotation_x + x4 * cos_a + y4 * sin_a, self.rotation_y - x4 * sin_a + y4 * cos_a
  local pad = margin or 0
  return min(min(ax, bx), min(cx, dx)) - pad, min(min(ay, by), min(cy, dy)) - pad,
    max(max(ax, bx), max(cx, dx)) + pad, max(max(ay, by), max(cy, dy)) + pad
end


function methods.set_wave(self, options)
  if type(options) ~= "table" then return false end
  local axis, direction = options.axis or self.wave_axis, options.direction or self.wave_direction
  if (axis ~= "x" and axis ~= "y") or (direction ~= 1 and direction ~= -1) then return false end
  self.wave_amplitude = options.amplitude or self.wave_amplitude
  self.wave_wavelength = max(1, options.wavelength or self.wave_wavelength)
  self.wave_speed, self.wave_phase = options.speed or self.wave_speed, options.phase or self.wave_phase
  self.wave_axis, self.wave_direction = axis, direction
  return true
end
function methods.warp_point(self, x, y, time, options)
  options = options or {}
  local t = time or self.phase
  local amp = options.amplitude or self.warp_amplitude
  local wavelength = max(1, options.wavelength or self.warp_wavelength)
  local frequency, phase = options.frequency or self.warp_frequency, options.phase or self.warp_phase
  local cx, cy = options.center_x or self.warp_center_x, options.center_y or self.warp_center_y
  local dx, dy = x - cx, y - cy
  local sx = dx + (options.scroll_speed_x or self.warp_speed_x) * t + amp * sin(dy / wavelength + t * frequency + phase)
  local sy = dy + (options.scroll_speed_y or self.warp_speed_y) * t + amp * sin(dx / wavelength + t * frequency + phase)
  local angle = options.rotation or self.warp_rotation
  local c, sn = cos(angle / 6.283185), sin(angle / 6.283185)
  return cx + sx * c - sy * sn, cy + sx * sn + sy * c
end
function methods.warp_step(self) return self.sample_step end
function methods.set_dissolve(self, amount, mode, direction, seed, matrix)
  if mode and mode ~= "ordered" and mode ~= "checker" and mode ~= "spiral" and mode ~= "reverse" then return false end
  if direction and direction ~= "in" and direction ~= "out" then return false end
  if matrix then
    if type(matrix) ~= "table" or #matrix < 16 then return false end
    for i = 1, 16 do if type(matrix[i]) ~= "number" or matrix[i] ~= flr(matrix[i]) or matrix[i] < 0 or matrix[i] > 15 then return false end end
  end
  self.dissolve_amount, self.dissolve_mode = amount or self.dissolve_amount, mode or self.dissolve_mode
  self.dissolve_direction, self.dissolve_seed = direction or self.dissolve_direction, seed or self.dissolve_seed
  self.dissolve_matrix = matrix or self.dissolve_matrix
  return true
end

function methods.wave_offset(self, x, time, amplitude, wavelength, speed, phase, axis, direction)
  wavelength = max(1, wavelength or self.wave_wavelength)
  local offset = (amplitude or self.wave_amplitude) * sin((x / wavelength + (time or self.phase) * (speed or self.wave_speed)) * (direction or self.wave_direction) + (phase or self.wave_phase))
  return offset, axis or self.wave_axis
end

function methods.set_squash(self, horizontal, vertical, duration, overshoot, easing, anchor_x, anchor_y)
  easing = easing or self.squash_easing
  if easing ~= "linear" and easing ~= "smooth" and easing ~= "sine" then return false end
  self.squash_x = max(0.1, horizontal or 1.25)
  self.squash_y = max(0.1, vertical or 0.75)
  self.squash_duration = max(0.01, duration or 0.2)
  self.squash_overshoot, self.squash_easing = overshoot or self.squash_overshoot, easing
  self.squash_anchor_x, self.squash_anchor_y = anchor_x or self.squash_anchor_x, anchor_y or self.squash_anchor_y
  self.squash_time = self.squash_duration
  return true
end

function methods.update(self, dt)
  dt = min(0.1, max(0, dt or 1 / 60))
  self.phase += dt
  self.squash_time = max(0, self.squash_time - dt)
end

function methods.scale(self)
  if self.squash_time <= 0 then return 1, 1 end
  local t = 1 - self.squash_time / self.squash_duration
  local envelope = self.squash_easing == "linear" and t or self.squash_easing == "smooth" and t * t * (3 - 2 * t) or sin(t * 0.5)
  envelope = envelope + self.squash_overshoot * sin(t)
  return 1 + (self.squash_x - 1) * envelope, 1 + (self.squash_y - 1) * envelope, self.squash_anchor_x, self.squash_anchor_y
end

function methods.visible(self, x, y, amount, mode, direction, seed, matrix)
  amount, mode = amount == nil and self.dissolve_amount or amount, mode or self.dissolve_mode
  direction, seed, matrix = direction or self.dissolve_direction, seed or self.dissolve_seed, matrix or self.dissolve_matrix
  amount = min(1, max(0, amount or 0))
  local ix, iy = flr(x) % 4, flr(y) % 4
  ix, iy = (ix + seed) % 4, (iy + flr(seed / 4)) % 4
  local values = matrix or (mode == "spiral" and spiral or bayer)
  local threshold = values[iy * 4 + ix + 1]
  if mode == "checker" then threshold = (ix + iy) % 2 * 8 end
  if mode == "reverse" or direction == "out" then threshold = 15 - threshold end
  return threshold / 16 >= amount
end

function methods.clear(self)
  self.phase, self.squash_time = 0, 0
  self.squash_x, self.squash_y = 1, 1
  self.rotation_x, self.rotation_y = 0, 0
  self.rotation_sin, self.rotation_cos = 0, 1
end
