-- VFX8 pixel deformation helpers for LÖVE.
-- Copy this module into your project as vfx8/pixel_deform.lua.

local pixel_deform = {}
local methods = {}
local bayer = {0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5}
local spiral = {0, 12, 3, 15, 8, 4, 11, 7, 2, 14, 1, 13, 10, 6, 9, 5}
local pi2 = math.pi * 2

function pixel_deform.new(options)
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
  local cycles = x / wavelength + (time or self.phase) * (speed or 1) + (phase or 0)
  return (amplitude or 2) * math.sin((cycles % 1) * pi2)
end
function methods.set_squash(self, horizontal, vertical, duration)
  self.squash_x, self.squash_y = math.max(0.1, horizontal or 1.25), math.max(0.1, vertical or 0.75)
  self.squash_duration = math.max(0.01, duration or 0.2)
  self.squash_time = self.squash_duration
end
function methods.update(self, dt)
  dt = math.max(0, math.min(dt or 1 / 60, 0.1))
  self.phase, self.squash_time = self.phase + dt, math.max(0, self.squash_time - dt)
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
  self.phase, self.squash_time, self.squash_x, self.squash_y = 0, 0, 1, 1
  self.rotation_x, self.rotation_y = 0, 0
  self.rotation_sin, self.rotation_cos = 0, 1
end
return pixel_deform
