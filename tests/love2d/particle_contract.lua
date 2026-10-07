local root = os.getenv("VFX8_TEST_ROOT")
local actual_love = love
local draw_calls = 0
local draw_color = {0.2, 0.3, 0.4, 0.5}

local function run_contract()
  love = {
    graphics = {
      getColor = function() return unpack(draw_color) end,
      setColor = function(r, g, b, a) draw_color = {r, g, b, a} end,
      rectangle = function() draw_calls = draw_calls + 1 end
    }
  }

  local function check(condition, message)
    if not condition then error(message or "contract check failed", 2) end
  end

  local particles = dofile(root .. "/src/love2d/particles.lua")
  local system = particles.new({capacity = 3, max_emit = 2, seed = 17})

check(system:emit("explosion", 8, 9, {count = 8, life = 0.2, end_size = 0}) == 2,
  "emission must respect both configured limits")
check(system:emit("sparks", 8, 9) == 0, "per-update emission budget must be shared")
local active, capacity, emitted = system:stats()
check(active == 2 and capacity == 3 and emitted == 0,
  "stats must expose active count, capacity, and last completed tick")

system:update(1)
active, capacity, emitted = system:stats()
check(active == 2 and emitted == 2, "dt must be clamped and emitted count retained")
check(system:emit("sparks", 8, 9, {life = 0.05}) == 1, "remaining pool capacity must be respected")
system:update(0.1)
active, _, emitted = system:stats()
check(active == 0 and emitted == 1, "expired entries must be removed")
check(system:emit("invalid", 0, 0) == 0, "unknown presets must be ignored")

system:emit("sparks", 8, 9, {count = 1})
local tuned = particles.new({capacity = 2, max_emit = 2, seed = 3})
check(tuned:emit("explosion", 40, 40, {
  count = 1, direction = {x = 1, y = 0}, direction_spread = 0,
  min_speed = 12, max_speed = 12, radius = 5, emission_shape = "ring",
  gravity = 0, drag = 0, wind = {x = 0, y = 0}, start_size = 6,
  end_size = 2, colors = {2, 3, 4}
}) == 1, "expanded particle options must still emit within limits")
check(math.abs(math.sqrt((tuned.x[1] - 40)^2 + (tuned.y[1] - 40)^2) - 5) < 0.001,
  "ring emission must place particles at the configured radius")
check(math.abs(tuned.vx[1] - 12) < 0.001 and tuned.vy[1] == 0,
  "explicit direction and speed range must set velocity")
check(tuned.gravity[1] == 0 and tuned.drag[1] == 0 and tuned.wind_x[1] == 0 and tuned.size[1] == 6 and tuned.end_size[1] == 2,
  "particle acceleration and size options must be stored")
check(tuned.color_1[1] == 2 and tuned.color_2[1] == 3 and tuned.color_3[1] == 4,
  "custom particle palette ramp must be stored")
local ok_rotation = pcall(function() tuned:emit("dust", 0, 0, {rotation = 0.2}) end)
check(not ok_rotation, "unsupported rotated square particles must fail explicitly")
local r, g, b, a = unpack(draw_color)
system:draw()
check(draw_calls > 0, "draw must issue a primitive for a visible particle")
check(draw_color[1] == r and draw_color[2] == g and draw_color[3] == b and draw_color[4] == a,
  "draw must restore the previous color")
  system:clear()
  active = system:stats()
  check(active == 0, "clear must remove all active particles")

  print("LOVE particle runtime contract passed")
end

local ok, err = xpcall(run_contract, debug.traceback)
love = actual_love
if not ok then error(err, 0) end
