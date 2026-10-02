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
