local quality_names = {"low", "medium", "high"}
local effect_names = {"particles", "screen_fx", "pixel_deform", "palette_fx", "pseudo3d", "flames", "electricity"}
local scenarios = {"baseline", "typical", "saturated"}
local repetitions, warmup_frames, sample_frames = 5, 30, 600
local quality_index, repetition = 1, 1
local frame, active_effect = 0, nil
local active_name, active_scenario = "baseline", "baseline"
local block_warmup_frames, block_sample_frames = warmup_frames, sample_frames
local active_effect_limit, active_count, operation_count = 0, 0, 0
local table_index, block_index = 1, 1
local update_samples, draw_samples, records = {}, {}, {}
local setup_heap_kb, warmup_heap_kb = 0, 0
local texture_memory_before_kb, texture_memory_after_kb = 0, 0
local mode7_shader = false
local modules = {}
local advance_block, finish_benchmark

local palette = {
  {0.02, 0.03, 0.08}, {0.08, 0.13, 0.23}, {0.49, 0.15, 0.32}, {0.06, 0.48, 0.34},
  {0.93, 0.24, 0.20}, {0.37, 0.34, 0.31}, {0.76, 0.77, 0.78}, {1, 0.94, 0.55},
  {1, 0.25, 0.16}, {1, 0.62, 0.05}, {1, 0.88, 0.12}, {0, 0.89, 0.21},
  {0.16, 0.68, 1}, {0.51, 0.46, 0.62}, {1, 0.47, 0.66}, {1, 0.8, 0.67}
}
local dusk_map = {0, 1, 1, 2, 3, 4, 5, 6, 2, 3, 5, 4, 1, 2, 3, 6}
local road_colors = {
  sky = {0.025, 0.035, 0.09}, ground = {0.04, 0.20, 0.16},
  road_a = {0.07, 0.12, 0.22}, road_b = {0.09, 0.17, 0.29},
  edge = {0.28, 0.78, 0.68}, star = {{0.4, 0.7, 1}, {0.75, 0.85, 1}, {1, 1, 1}}
}
local capacities = {
  particles = {128, 320, 640}, screen_fx = {4, 8, 16},
  flames = {128, 256, 512}, electricity = {96, 192, 320},
  pseudo3d = {8, 16, 32}, helper_calls = {32, 128, 512}
}
local emission_limits = {
  particles = {96, 192, 384}, flames = {32, 64, 128}, electricity = {64, 128, 192}
}

local function texture_memory_kb()
  return (love.graphics.getStats().texturememory or 0) / 1024
end

local function make_texture()
  local data = love.image.newImageData(64, 64)
  for y = 0, 63 do
    for x = 0, 63 do
      local tile = (math.floor(x / 8) + math.floor(y / 8)) % 2
      local lane = x % 32 < 2 or x % 32 > 29
      local shade = lane and 0.65 or (tile == 0 and 0.14 or 0.22)
      data:setPixel(x, y, shade, shade * 1.35, shade * 1.7, 1)
    end
  end
  local image = love.graphics.newImage(data)
  image:setFilter("nearest", "nearest")
  return image
end

local function make_effect(name, quality, scenario)
  local profile = quality_index
  local limit = capacities[name] and capacities[name][profile] or capacities.helper_calls[profile]
  if name == "particles" then
    local emission_limit = emission_limits.particles[profile]
    local fx = modules.particles.new({quality = quality, capacity = limit, max_emit = emission_limit, seed = 17})
    if scenario == "typical" then
      fx:emit("explosion", 160, 90, {count = 16, life = 100, gravity = 0, drag = 0})
    elseif scenario == "saturated" then
      while fx.count < limit do
        local emitted = fx:emit("explosion", 160, 90, {count = limit, life = 100, gravity = 0, drag = 0})
        assert(emitted > 0 and emitted <= emission_limit)
        fx:update(0)
      end
    end
    return fx, limit, fx.count, 0
  elseif name == "screen_fx" then
    local fx = modules.screen_fx.new({width = 320, height = 180, capacity = limit, seed = 17})
    if scenario == "typical" then
      fx:add_trauma(0.6)
      fx:shockwave(160, 90, 2, 14, 100)
    elseif scenario == "saturated" then
      fx:add_trauma(0.8)
      for i = 1, limit do assert(fx:shockwave(32 + i * 13, 90, 2, 14, 100)) end
    end
    return fx, limit, fx.wave_count, fx.wave_count
  elseif name == "pixel_deform" then
    local fx = modules.pixel_deform.new({quality = quality})
    if scenario ~= "baseline" then
      fx:set_squash(1.4, 0.7, 100)
      fx:set_rotation(160, 90, 0.35)
    end
    return fx, limit, scenario == "baseline" and 0 or limit, scenario == "baseline" and 0 or limit
  elseif name == "palette_fx" then
    local fx = modules.palette_fx.new({quality = quality, color_count = 16})
    if scenario ~= "baseline" then
      fx:set_invert_palette(palette)
      fx:set_cycle(8, 11, 2)
      fx:set_filter_map(dusk_map)
      fx:set_pulse(8, 10, 3)
      fx:flash(8, 10, 7, 100)
    end
    return fx, limit, scenario == "baseline" and 0 or limit, scenario == "baseline" and 0 or limit
  elseif name == "pseudo3d" then
    local fx = modules.pseudo3d.new({quality = quality, width = 320, height = 180, horizon = 54,
      star_count = scenario == "baseline" and 0 or nil})
    local image
    if scenario ~= "baseline" then
      image = make_texture()
      mode7_shader = fx:set_mode7(image, {scale = 0.09})
    end
    if scenario == "typical" then
      fx:add_object(0, 96, 11, 14)
    elseif scenario == "saturated" then
      for i = 1, limit do assert(fx:add_object((i % 9 - 4) * 0.18, 60 + i * 2, 8 + i % 8, 8)) end
    end
    fx.texture = image
    return fx, limit, fx.object_count, fx.star_count
  elseif name == "flames" then
    local emission_limit = emission_limits.flames[profile]
    local fx = modules.flames.new({quality = quality, capacity = limit, max_emit = emission_limit, seed = 17})
    local count = scenario == "typical" and math.min(8, limit) or (scenario == "saturated" and limit or 0)
    if count > 0 then
      if scenario == "saturated" then
        while fx.count < limit do
          local emitted = fx:emit_jet(60, 110, 1, -0.15, {count = count, life = 100, gravity = 0, drag = 0})
          assert(emitted > 0 and emitted <= emission_limit)
          fx:update(0)
        end
      else
        assert(fx:emit_jet(60, 110, 1, -0.15, {count = count, life = 100, gravity = 0, drag = 0}) == count)
      end
    end
    return fx, limit, fx.count, 0
  elseif name == "electricity" then
    local emission_limit = emission_limits.electricity[profile]
    local fx = modules.electricity.new({quality = quality, capacity = limit, max_emit = emission_limit, seed = 17})
    if scenario == "typical" then
      fx:strike(60, 120, 250, 48, {life = 100, branches = 2})
    elseif scenario == "saturated" then
      while fx.count < limit do
        local emitted = fx:strike(24, 150, 296, 28, {segments = 24, life = 100, branches = 0})
        assert(emitted > 0 and emitted <= emission_limit)
        fx:update(0)
      end
    end
    return fx, limit, fx.count, 0
  end
end

local function setup_block()
  active_effect = nil
  collectgarbage("collect")
  mode7_shader = false
  local before_heap = collectgarbage("count")
  texture_memory_before_kb = texture_memory_kb()
  active_name = active_name or "baseline"
  active_scenario = scenarios[block_index]
  local quality = quality_names[quality_index]
  block_warmup_frames = active_scenario == "saturated" and warmup_frames or math.min(warmup_frames, 30)
  block_sample_frames = active_scenario == "saturated" and sample_frames or math.min(sample_frames, 120)
  local limit, active_items, operations = 0, 0, 0
  if active_name ~= "baseline" then
    active_effect, limit, active_items, operations = make_effect(active_name, quality, active_scenario)
  end
  setup_heap_kb = collectgarbage("count") - before_heap
  texture_memory_after_kb = texture_memory_kb()
  frame, update_samples, draw_samples = 0, {}, {}
  for i = 1, block_sample_frames do update_samples[i], draw_samples[i] = 0, 0 end
  active_effect_limit, active_count, operation_count = limit, active_items, operations
  warmup_heap_kb = 0
end

local function draw_background()
  love.graphics.clear(0.05, 0.07, 0.12, 1)
  love.graphics.setColor(0.2, 0.28, 0.4, 1)
  for i = 1, 40 do
    local x, y = (i * 37) % 320, (i * 19) % 180
    love.graphics.rectangle("fill", x, y, 3, 3)
  end
end

local function draw_effect()
  if not active_effect then return end
  if active_name == "particles" or active_name == "flames" or active_name == "electricity" then
    active_effect:draw()
  elseif active_name == "screen_fx" then
    active_effect:render(draw_background)
  elseif active_name == "pseudo3d" then
    if active_scenario == "baseline" then return end
    active_effect:draw(road_colors)
  elseif active_name == "pixel_deform" then
    if active_scenario == "baseline" then return end
    local offset = 0
    for i = 1, active_effect_limit do
      local x, y = i % 320, math.floor(i / 320) % 180
      offset = offset + active_effect:wave_offset(x, frame / 60, 3, 48, 0.5)
      if active_effect:visible(x, y, 0.5, i % 2 == 0 and "checker" or "spiral") then
        local sx, sy = active_effect:scale()
        if i % 16 == 0 then active_effect:rotate_point(x * sx, y * sy) end
      end
    end
    if offset == math.huge then error("invalid deformation benchmark result") end
  elseif active_name == "palette_fx" then
    if active_scenario == "baseline" then return end
    local color = 0
    for i = 1, active_effect_limit do color = color + active_effect:map_color(i % 16) end
    if color == math.huge then error("invalid palette benchmark result") end
  end
end

local function percentile(values, fraction)
  table.sort(values)
  return values[math.max(1, math.ceil(#values * fraction))]
end

local function finish_block()
  local update_sum, draw_sum = 0, 0
  for i = 1, block_sample_frames do
    update_sum, draw_sum = update_sum + update_samples[i], draw_sum + draw_samples[i]
  end
  local stats = love.graphics.getStats()
  texture_memory_after_kb = (stats.texturememory or 0) / 1024
  local update_p95, draw_p95 = percentile(update_samples, 0.95), percentile(draw_samples, 0.95)
  records[#records + 1] = {
    quality_names[quality_index], active_name, active_scenario, repetition, block_warmup_frames,
    block_sample_frames, active_count, active_effect_limit, operation_count,
    update_sum / block_sample_frames, update_p95, draw_sum / block_sample_frames, draw_p95,
    setup_heap_kb, collectgarbage("count") - warmup_heap_kb,
    texture_memory_before_kb, texture_memory_after_kb, mode7_shader and 1 or 0
  }
  print(string.format("VFX8_LOVE_EFFECT,%s,%s,%s,%d,%d,%d", quality_names[quality_index], active_name,
    active_scenario, repetition, active_count, active_effect_limit))
  advance_block()
end

advance_block = function()
  block_index = block_index + 1
  if block_index > #scenarios then
    block_index, table_index = 1, table_index + 1
  end
  if table_index > #effect_names + 1 then
    table_index, repetition = 1, repetition + 1
  end
  if repetition > repetitions then
    repetition, quality_index = 1, quality_index + 1
  end
  if quality_index > #quality_names then
    finish_benchmark()
    return
  end
  active_name = table_index == 1 and "baseline" or effect_names[table_index - 1]
  setup_block()
end

finish_benchmark = function()
  local output_path = os.getenv("VFX8_EFFECT_BENCH_OUTPUT")
  if output_path then
    local output = assert(io.open(output_path, "w"), "Unable to open effects benchmark output")
    output:write("quality,effect,scenario,run,warmup_frames,sample_frames,active_items,capacity,operations_per_frame,mean_update_ms,p95_update_ms,mean_draw_ms,p95_draw_ms,setup_heap_kb,sample_heap_delta_kb,texture_memory_before_kb,texture_memory_after_kb,mode7_shader\n")
    for _, row in ipairs(records) do
      local fields = {}
      for i, value in ipairs(row) do fields[i] = tostring(value) end
      output:write(table.concat(fields, ","), "\n")
    end
    output:close()
  end
  love.event.quit(0)
end

function love.load()
  modules.particles = require("vfx8.particles")
  modules.screen_fx = require("vfx8.screen_fx")
  modules.pixel_deform = require("vfx8.pixel_deform")
  modules.palette_fx = require("vfx8.palette_fx")
  modules.pseudo3d = require("vfx8.pseudo3d")
  modules.flames = require("vfx8.flames")
  modules.electricity = require("vfx8.electricity")
  local major, minor, revision, codename = love.getVersion()
  print(string.format("VFX8_LOVE_RUNTIME,%d.%d.%d,%s,%s", major, minor, revision, codename, love.system.getOS()))
  quality_index, table_index, repetition, block_index = 1, 1, 1, 1
  active_name = "baseline"
  setup_block()
end

function love.update(dt)
  frame = frame + 1
  local started = love.timer.getTime()
  if active_effect then
    active_effect:update(active_scenario == "saturated" and 0 or dt)
  end
  local elapsed = (love.timer.getTime() - started) * 1000
  if frame == block_warmup_frames then warmup_heap_kb = collectgarbage("count") end
  if frame > block_warmup_frames then update_samples[frame - block_warmup_frames] = elapsed end
end

function love.draw()
  local started = love.timer.getTime()
  if active_name ~= "screen_fx" then draw_background() end
  draw_effect()
  local elapsed = (love.timer.getTime() - started) * 1000
  if frame > block_warmup_frames then draw_samples[frame - block_warmup_frames] = elapsed end
  if frame >= block_warmup_frames + block_sample_frames then finish_block() end
end

function love.keypressed(key)
  if key == "escape" then love.event.quit() end
end

local function configure_counts(warmup, samples, runs)
  warmup_frames, sample_frames, repetitions = warmup or warmup_frames, samples or sample_frames, runs or repetitions
end

local warmup_setting = tonumber(os.getenv("VFX8_EFFECT_BENCH_WARMUP"))
local sample_setting = tonumber(os.getenv("VFX8_EFFECT_BENCH_SAMPLES"))
local repetition_setting = tonumber(os.getenv("VFX8_EFFECT_BENCH_REPETITIONS"))
if warmup_setting or sample_setting or repetition_setting then
  configure_counts(warmup_setting, sample_setting, repetition_setting)
end
