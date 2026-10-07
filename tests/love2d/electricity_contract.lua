local root = assert(os.getenv("VFX8_TEST_ROOT"), "VFX8_TEST_ROOT is required")
local electricity_module = dofile(root .. "/src/love2d/electricity.lua")

local old_love = love
local color = {0.2, 0.3, 0.4, 0.5}
local line_width, line_calls = 3, 0
love = {graphics = {
  getColor = function() return color[1], color[2], color[3], color[4] end,
  setColor = function(r, g, b, a) color = {r, g, b, a} end,
  getLineWidth = function() return line_width end,
  setLineWidth = function(value) line_width = value end,
  line = function() line_calls = line_calls + 1 end
}}

local system = electricity_module.new({quality = "high", capacity = 32, max_emit = 12, seed = 13})
assert(system:strike(4, 8, 4, 8) == 0, "zero-length strikes must be ignored")
local emitted = system:strike(10, 20, 90, 40, {segments = 6, branches = 2, life = 0.05})
assert(emitted > 6 and emitted <= 12, "jagged bolts must add branches within the segment budget")
local extra = system:strike(0, 0, 80, 30, {segments = 10, life = 0.05})
assert(emitted + extra <= 12, "additional strikes must share the update cap")
local total = emitted + extra
local overflow = system:strike(0, 0, 90, 30, {segments = 24, branches = 8, life = 0.05})
assert(total + overflow <= 12, "later strikes must be truncated at the update cap")
total = total + overflow
system:update(0.01)
local count, capacity, previous = system:stats()
assert(count == total and capacity == 32 and previous == total, "stats must report the bounded arc pool")
system:draw()
assert(line_calls == total * 2, "LÖVE must draw a glow line and bright core per segment")
assert(line_width == 3, "draw must restore incoming line width")
assert(color[1] == 0.2 and color[2] == 0.3 and color[3] == 0.4 and color[4] == 0.5, "draw must restore incoming color")
system:update(0.1)
assert(system:stats() == 0, "expired line segments must be removed")
assert(system:strike(2, 3, 40, 20, {segments = 4, branches = 0}) == 4, "a clean arc must honor its requested segment count")
system:clear()
assert(system:stats() == 0, "clear must empty the arc system")
local tuned = electricity_module.new({quality = "low", capacity = 24, max_emit = 20, seed = 9,
  color = {0.2, 0.5, 1}, core_color = {1, 1, 1}, pulse_count = 2})
local tuned_count = tuned:strike(8, 10, 70, 40, {segments = 5, branches = 2,
  branch_probability = 0, branch_angle = 0.9, branch_length = 0.3, bolt_count = 2,
  width = 3, life = 0.2, flicker = true})
assert(tuned_count == 10 and tuned.capacity == 24 and tuned.max_emit == 20,
  "parallel bolts and explicit segment budgets must be honored")
assert(tuned.colors[1][1] == 0.2 and tuned.core_colors[1][1] == 1 and tuned.flicker_segments[1] == 1,
  "custom colors and per-strike flicker must be stored with segments")
love = old_love
print("LOVE electricity runtime contract passed")
