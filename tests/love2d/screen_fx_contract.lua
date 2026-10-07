local root = os.getenv("VFX8_TEST_ROOT")
local screen_fx = dofile(root .. "/src/love2d/screen_fx.lua")
local fx = screen_fx.new({width = 240, height = 136, seed = 5})
local dx, dy = fx:get_shake_offset()
assert(dx == 0 and dy == 0)
fx:impulse(8, 3, 0.2)
dx, dy = fx:get_shake_offset()
assert(dx == 0 and dy == 0, "shake offsets are sampled by update")
fx:shockwave(60, 40, 2, 12, 0.3)
fx:flash(0.08, {1, 1, 1})
fx:shockwave(70, 45, 3, 8, 0.4, {center_x = 71, center_y = 46, max_radius = 55, thickness = 3, falloff = 1.4})
fx:flash(0.12, {0.4, 0.2, 0.1}, {intensity = 0.35, mode = "invert"})
assert(fx.waves[2].x == 71 and fx.waves[2].y == 46 and fx.waves[2].max_radius == 55,
  "shockwave center and maximum radius options must be honored")
assert(fx.waves[2].thickness == 3 and fx.waves[2].falloff == 1.4 and fx.flash_intensity == 0.35,
  "wave shape and flash intensity options must be honored")
fx:update(1 / 60)
local first_x, first_y = fx:get_shake_offset()
local repeated_x, repeated_y = fx:get_shake_offset()
assert(first_x == repeated_x and first_y == repeated_y, "offsets stay stable between updates")
assert(first_x ~= 0 or first_y ~= 0, "directional impulse produces camera motion")

local old_graphics = love.graphics
local color = {0.2, 0.3, 0.4, 0.5}
local color_stack = {}
local calls = {scene = 0, circles = 0, rectangles = 0, canvases = 0, shaders = 0, draws = 0}
local shader = {send = function() calls.shaders = calls.shaders + 1 end}
fx.ripple_shader = shader
love.graphics = {
  getColor = function() return color[1], color[2], color[3], color[4] end,
  setColor = function(r, g, b, a) color = {r, g, b, a} end,
  push = function() color_stack[#color_stack + 1] = {color[1], color[2], color[3], color[4]} end,
  translate = function() end,
  pop = function()
    color = color_stack[#color_stack]
    color_stack[#color_stack] = nil
  end,
  getCanvas = function() return nil end,
  getDimensions = function() return 240, 136 end,
  setCanvas = function() calls.canvases = calls.canvases + 1 end,
  clear = function() end,
  origin = function() end,
  transformPoint = function(x, y) return x, y end,
  setShader = function() end,
  setBlendMode = function() end,
  draw = function() calls.draws = calls.draws + 1 end,
  circle = function() calls.circles = calls.circles + 1 end,
  rectangle = function() calls.rectangles = calls.rectangles + 1 end
}
fx:render(function() calls.scene = calls.scene + 1 end)
assert(calls.scene == 1 and calls.circles == 4 and calls.rectangles == 1,
  "wave overlays must honor each configured outline thickness")
assert(calls.canvases == 2 and calls.draws == 1 and calls.shaders == 5,
  "shockwave captures the scene and applies the shader pass")
assert(color[1] == 0.2 and color[2] == 0.3 and color[3] == 0.4 and color[4] == 0.5,
  "screen effects restore draw color")
love.graphics = old_graphics
print("LOVE screen effects runtime contract passed")
