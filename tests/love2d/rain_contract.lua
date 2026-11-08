local root = assert(os.getenv("VFX8_TEST_ROOT"), "VFX8_TEST_ROOT is required")
local module = dofile(root .. "/src/love2d/rain.lua")
local old_love, calls = love, 0
local color, width = {0.1, 0.2, 0.3, 0.4}, 1
love = {graphics = {
  getColor = function() return color[1], color[2], color[3], color[4] end,
  setColor = function(r, g, b, a) color = {r, g, b, a} end,
  getLineWidth = function() return width end,
  setLineWidth = function(value) width = value end,
  line = function() calls = calls + 1 end
}}
local system = module.new({quality = "low", width = 100, height = 60, seed = 7})
local count, capacity = system:stats()
assert(count == 33 and capacity == 72, "light rain should use a bounded sparse pool")
assert(system:set_intensity("storm") == "storm" and system:stats() == 72, "storm should use the full pool")
assert(system:set_intensity("heavy") == "heavy" and system:stats() == 56, "heavy rain should use the middle density")
assert(system:set_angle(90) == 35 and system.angle == 35, "rain angle must clamp to the supported oblique range")
system:update(1 / 60)
system:draw()
assert(calls == system.count, "draw should render one streak per active drop")
assert(color[1] == 0.1 and color[4] == 0.4 and width == 1, "draw must restore caller graphics state")
system:clear()
system:update(0.1)
assert(system:stats() == 0, "clear should stop update and draw work")
love = old_love
print("LOVE rain runtime contract passed")
