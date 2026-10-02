local root = os.getenv("VFX8_TEST_ROOT")
local pseudo3d = dofile(root .. "/src/love2d/pseudo3d.lua")
local scene = pseudo3d.new({quality = "low", width = 240, height = 136, star_count = 4, object_capacity = 2})
assert(scene.star_count == 4)
local px, py, scale = scene:project(0, 60, 8)
assert(px == 120 and scale > 0 and py > scene.horizon)
local road_x, road_y, road_scale = scene:project_road(0, 60, 8)
assert(road_x == 120 and road_y == py and road_scale == scale,
  "road projection must share the scene perspective at the center lane")
scene:set_road(80, 2, 1, 40)
assert(scene.road_width == 80 and scene.lane_count == 2 and scene.curve == 1 and scene.curve_strength == 40)
local curved_x = scene:project_road(0, 60, 8)
assert(curved_x > road_x, "road curvature must shift projected objects with depth")
scene:set_road(80, 2, 0, 40)
assert(scene:add_object(-10, 80, 10, 8))
assert(scene:add_object(12, 60, 11, 10))
assert(not scene:add_object(0, 40, 12, 12))
scene.objects[1].active = false
assert(scene:add_object(-4, 40, 12, 12), "inactive pool slots must be reused")
scene:update(1 / 60)
assert(scene.objects[1].z < 40, "reused objects must update in place")
assert(scene.objects[2].z < 60)
scene:set_camera(5, 50, 20)
assert(scene.camera_x == 5 and scene.horizon == 50 and scene.speed == 20)
scene:clear_objects()
assert(scene.object_count == 0)
scene:clear()
assert(scene.camera_z == 0)

local calls = {rectangles = 0, points = 0, pushes = 0, pops = 0}
local old_graphics = love.graphics
local image = old_graphics.newImage(love.image.newImageData(1, 1))
local shader_probe = dofile(root .. "/src/love2d/pseudo3d.lua")
local shader_scene = shader_probe.new({quality = "low", width = 32, height = 24})
local shader_ok, shader_error = shader_scene:set_mode7(image, {scale = 0.1})
assert(shader_ok, shader_error or "Mode 7 shader must compile on the tested LÖVE runtime")
assert(shader_scene.mode7.image == image and shader_scene.mode7.scale == 0.1)
shader_scene:set_mode7(false)
local current_color = {1, 1, 1, 1}
local mode7_draws = 0
local shader_sends = 0
local shader = {send = function() shader_sends = shader_sends + 1 end}
love.graphics = {
  setColor = function(r, g, b, a) current_color = {r, g, b, a} end,
  push = function(mode) assert(mode == "all"); calls.pushes = calls.pushes + 1 end,
  pop = function() calls.pops = calls.pops + 1 end,
  rectangle = function() calls.rectangles = calls.rectangles + 1 end,
  points = function() calls.points = calls.points + 1 end,
  setShader = function(value) if value == shader then mode7_draws = mode7_draws + 1 end end,
  newShader = function() return shader end
}
assert(scene:set_mode7(image, {scale = 0.1}))
assert(scene.mode7.image == image and scene.mode7.scale == 0.1)
love.graphics.newShader = old_graphics.newShader
local draw_colors = scene.draw_colors
local custom_sky = {0, 0, 0}
scene:draw({sky = custom_sky})
assert(mode7_draws == 1 and shader_sends == 7, "Mode 7 should submit its shader and uniforms")
assert(scene.draw_colors.sky == custom_sky)
assert(scene:set_mode7(false) and scene.mode7 == nil)
scene:draw()
assert(scene.draw_colors == draw_colors and scene.draw_colors.sky ~= custom_sky,
  "draw reuses scratch storage and restores default colors when options are omitted")
love.graphics = old_graphics
assert(calls.rectangles > 0 and calls.points > 0)
assert(calls.pushes == 2 and calls.pops == 2, "draw must restore all LÖVE graphics state")
print("LOVE pseudo-3D runtime contract passed")
