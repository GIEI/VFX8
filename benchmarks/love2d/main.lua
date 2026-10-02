local particles_module
local scenario_names = {"baseline", "typical", "saturated"}
local repetitions = 5
local warmup_frames = 120
local sample_frames = 600
local current_rep, current_scenario = 1, 1
local frame, system = 0, nil
local update_samples, draw_samples = {}, {}
local heap_setup_kb, heap_warmup_kb = 0, 0
local records = {}
local finished = false

local function begin_block()
  local scenario = scenario_names[current_scenario]
  collectgarbage("collect")
  local before_setup = collectgarbage("count")
  system = nil

  if scenario == "typical" then
    system = particles_module.new({quality = "low", seed = 17})
    assert(system:emit("explosion", 160, 90, {count = 16, life = 100}) == 16,
      "typical workload did not create the expected particles")
  elseif scenario == "saturated" then
    system = particles_module.new({quality = "high", capacity = 640, max_emit = 640, seed = 17})
    assert(system:emit("explosion", 160, 90, {
      count = 640, life = 100, speed = 24, gravity = 0, drag = 0
    }) == 640, "saturated workload did not fill the particle pool")
  end

  heap_setup_kb = collectgarbage("count") - before_setup
  frame = 0
  update_samples, draw_samples = {}, {}
  for i = 1, sample_frames do
    update_samples[i], draw_samples[i] = 0, 0
  end
  heap_warmup_kb = 0
end

local function percentile(values, fraction)
  table.sort(values)
  return values[math.max(1, math.ceil(#values * fraction))]
end

local function finish_block()
  local update_sum, draw_sum = 0, 0
  for i = 1, sample_frames do
    update_sum = update_sum + update_samples[i]
    draw_sum = draw_sum + draw_samples[i]
  end
  local heap_after_samples = collectgarbage("count")
  local record = {
    scenario_names[current_scenario], current_rep,
    system and system.capacity or 0, system and system.count or 0,
    update_sum / sample_frames, percentile(update_samples, 0.95),
    draw_sum / sample_frames, percentile(draw_samples, 0.95),
    heap_setup_kb, heap_after_samples - heap_warmup_kb
  }
  records[#records + 1] = record
  print(string.format(
    "VFX8_LOVE_PARTICLES,%s,%d,%d,%d,%.6f,%.6f,%.6f,%.6f,%.3f,%.3f",
    unpack(record)))

  system = nil
  current_scenario = current_scenario + 1
  if current_scenario > #scenario_names then
    current_scenario = 1
    current_rep = current_rep + 1
  end
  if current_rep > repetitions then
    finished = true
    local output_path = os.getenv("VFX8_BENCH_OUTPUT")
    if output_path then
      local output = assert(io.open(output_path, "w"), "Unable to open benchmark output")
      output:write("scenario,run,capacity,active_particles,mean_update_ms,p95_update_ms,mean_draw_ms,p95_draw_ms,setup_heap_kb,sample_heap_delta_kb\n")
      for _, row in ipairs(records) do
        output:write(table.concat(row, ","), "\n")
      end
      output:close()
    end
    love.event.quit(0)
  else
    begin_block()
  end
end

function love.load()
  particles_module = require("vfx8.particles")
  local major, minor, revision, codename = love.getVersion()
  print(string.format("VFX8_LOVE_RUNTIME,%d.%d.%d,%s,%s", major, minor, revision, codename, love.system.getOS()))
  begin_block()
end

function love.update()
  frame = frame + 1
  local scenario = scenario_names[current_scenario]
  local started = love.timer.getTime()
  if system then system:update(1 / 60) end
  local elapsed = (love.timer.getTime() - started) * 1000
  if frame == warmup_frames then heap_warmup_kb = collectgarbage("count") end
  if frame > warmup_frames then
    local sample = frame - warmup_frames
    update_samples[sample] = elapsed
  end
  if scenario == "saturated" and system and system.count ~= 640 then
    error("saturated pool lost active particles")
  end
end

function love.draw()
  love.graphics.clear(0.05, 0.07, 0.12, 1)
  love.graphics.setColor(0.2, 0.28, 0.4, 1)
  for i = 1, 40 do
    local x = (i * 37) % 320
    local y = (i * 19) % 180
    love.graphics.rectangle("fill", x, y, 3, 3)
  end

  local started = love.timer.getTime()
  if system then system:draw() end
  local elapsed = (love.timer.getTime() - started) * 1000
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(scenario_names[current_scenario] .. " / run " .. current_rep, 8, 8)
  if frame > warmup_frames then
    draw_samples[frame - warmup_frames] = elapsed
  end

  if frame >= warmup_frames + sample_frames then finish_block() end
end
