local root = assert(os.getenv("VFX8_TEST_ROOT"), "VFX8_TEST_ROOT is required")
local flames_module = dofile(root .. "/src/love2d/flames.lua")

local old_love = love
local draw_calls = 0
local graphics_color = {0.2, 0.3, 0.4, 0.5}
love = {graphics = {
  getColor = function() return graphics_color[1], graphics_color[2], graphics_color[3], graphics_color[4] end,
  setColor = function(r, g, b, a) graphics_color = {r, g, b, a} end,
  rectangle = function() draw_calls = draw_calls + 1 end
}}

local system = flames_module.new({capacity = 4, max_emit = 3, seed = 7})
assert(system:emit_jet(0, 0, 0, 0) == 0, "zero direction must not emit")
assert(system:emit_jet(10, 10, 1, 0, {count = 8, life = 0.05}) == 3, "jet emission must respect update cap")
assert(system:emit_campfire(10, 10, {count = 4}) == 0, "all effect types must share one update cap")
system:update(0.01)
local active_count, capacity, emitted = system:stats()
assert(active_count == 3 and capacity == 4 and emitted == 3, "stats must expose bounded active and emitted counts")
system:draw()
assert(draw_calls == 3, "draw must render each live flame particle")
assert(graphics_color[1] == 0.2 and graphics_color[2] == 0.3 and graphics_color[3] == 0.4 and graphics_color[4] == 0.5, "draw must restore caller color")
system:update(0.1)
assert(system:stats() == 0, "expired particles must be removed")
assert(system:emit_campfire(10, 10, {count = 2}) == 2, "campfire mode must emit from its base")
system:clear()
assert(system:stats() == 0, "clear must empty the system")
love = old_love
print("LOVE flames runtime contract passed")
