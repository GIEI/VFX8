local root = assert(os.getenv("VFX8_TEST_ROOT"), "VFX8_TEST_ROOT is required")
local module = dofile(root .. "/src/love2d/snow.lua")
local old_love, calls = love, 0
local color = {0.1, 0.2, 0.3, 0.4}
love = {graphics = {
  getColor = function() return color[1], color[2], color[3], color[4] end,
  setColor = function(r, g, b, a) color = {r, g, b, a} end,
  rectangle = function() calls = calls + 1 end
}}
local system = module.new({quality = "low", width = 100, height = 60, speed = 100, seed = 7, settle_min = 1, settle_max = 1})
local flakes, capacity = system:stats()
assert(flakes == 26 and capacity == 64, "light snowfall should use a bounded sparse pool")
assert(system:set_intensity("storm") == "storm" and system:stats() == 64, "blizzard should use the full pool")
assert(system:set_intensity("heavy") == "heavy" and system:stats() == 48, "heavy snow should use the middle density")
local ledge = system:add_surface(0, 6, 100)
assert(ledge == 2 and system:set_surface(ledge, 0, 6, 100), "objects should register/update horizontal catch surfaces")
for i = 1, system.count do system.x[i], system.y[i] = 10 + i, 0 end
system:update(0.1)
local _, _, settled = system:stats()
assert(settled > 0 and system.settle_y[1] == 6, "falling flakes should settle onto the upper object surface")
system:draw()
assert(calls >= system.count + settled, "draw should render flakes and settled snow")
assert(color[1] == 0.1 and color[4] == 0.4, "draw must restore caller color")
for i = 1, system.count do system.y[i], system.speed[i] = system.height, 0 end
for _ = 1, 11 do system:update(0.1) end
assert(system.settle_count == 0, "settled snow must expire after its configured one-second lifetime")
system:clear()
assert(system:stats() == 0, "clear should release active and settled counts")
love = old_love
print("LOVE snow runtime contract passed")
