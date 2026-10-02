-- VFX8 pixel deformation helpers for PICO-8.
-- Include this file once; it defines vfx8_pixel_deform.

vfx8_pixel_deform = vfx8_pixel_deform or {}

local methods = {}
local bayer = {0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5}
local spiral = {0, 12, 3, 15, 8, 4, 11, 7, 2, 14, 1, 13, 10, 6, 9, 5}

function vfx8_pixel_deform.new(options)
  options = options or {}
  return {
    quality = options.quality or "low",
    phase = options.phase or 0,
    squash_x = 1,
    squash_y = 1,
    squash_time = 0,
    squash_duration = 0.2,
    rotation_x = 0,
    rotation_y = 0,
    rotation_sin = 0,
    rotation_cos = 1,
    wave_offset = methods.wave_offset,
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


function methods.wave_offset(self, x, time, amplitude, wavelength, speed, phase)
  wavelength = max(1, wavelength or 16)
  return (amplitude or 2) * sin(x / wavelength + (time or self.phase) * (speed or 1) + (phase or 0))
end

function methods.set_squash(self, horizontal, vertical, duration)
  self.squash_x = max(0.1, horizontal or 1.25)
  self.squash_y = max(0.1, vertical or 0.75)
  self.squash_duration = max(0.01, duration or 0.2)
  self.squash_time = self.squash_duration
end

function methods.update(self, dt)
  dt = min(0.1, max(0, dt or 1 / 60))
  self.phase += dt
  self.squash_time = max(0, self.squash_time - dt)
end

function methods.scale(self)
  if self.squash_time <= 0 then return 1, 1 end
  local t = 1 - self.squash_time / self.squash_duration
  local envelope = sin(t * 0.5)
  return 1 + (self.squash_x - 1) * envelope, 1 + (self.squash_y - 1) * envelope
end

function methods.visible(self, x, y, amount, mode)
  amount = min(1, max(0, amount or 0))
  local ix, iy = flr(x) % 4, flr(y) % 4
  local threshold = (mode == "spiral" and spiral or bayer)[iy * 4 + ix + 1]
  if mode == "checker" then threshold = (ix + iy) % 2 * 8 end
  return threshold / 16 >= amount
end

function methods.clear(self)
  self.phase, self.squash_time = 0, 0
  self.squash_x, self.squash_y = 1, 1
  self.rotation_x, self.rotation_y = 0, 0
  self.rotation_sin, self.rotation_cos = 0, 1
end
