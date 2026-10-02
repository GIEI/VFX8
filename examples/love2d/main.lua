-- VFX8 demo harness. Run the staged build folder with LÖVE via stage_demo.py.
local fx = require("demo_extension")

local names = {"particles", "screen fx", "pixel warp", "palette fx", "pseudo 3d", "flames", "electricity"}
local qualities = {"low", "medium", "high"}
local selected, quality = 1, 1
local fx_enabled, active = true, nil
local tick = 0
local wave_time = 0
local wave_samples = {}
VFX8_DEMO_STATE = {}
local mcp = nil

local colors = {
  bg = 0,
  field = 1,
  grid = 13,
  ground = 3,
  actor = 8,
  target = 7,
  label = 12,
  dim = 14
}
local palette_colors = {
  {0.05, 0.07, 0.14}, {0.11, 0.17, 0.27}, {0.49, 0.15, 0.32}, {0.12, 0.46, 0.34},
  {0.67, 0.32, 0.21}, {0.36, 0.37, 0.42}, {0.76, 0.77, 0.80}, {0.95, 0.93, 0.78},
  {0.95, 0.35, 0.27}, {0.98, 0.58, 0.19}, {0.98, 0.82, 0.25}, {0.88, 0.35, 0.54},
  {0.50, 0.85, 0.95}, {0.20, 0.27, 0.36}, {0.55, 0.57, 0.63}, {0.95, 0.74, 0.58}
}
local palette_scene = false

local function color(index)
  if palette_scene and active and active.map_color then index = active.map_color(index) end
  local c = palette_colors[index + 1] or palette_colors[1]
  love.graphics.setColor(c[1], c[2], c[3], 1)
end

local function refresh_fx()
  if active and active.on_exit then active.on_exit() end
  active = nil
  if fx_enabled then
    active = fx[selected]
    if active and active.on_enter then active.on_enter(qualities[quality]) end
  end
end

local function sync_mcp_state()
  local particle_count = 0
  if active and active.stats then particle_count = active.stats() end
  VFX8_DEMO_STATE.module = names[selected]
  VFX8_DEMO_STATE.quality = qualities[quality]
  VFX8_DEMO_STATE.effects_enabled = fx_enabled
  VFX8_DEMO_STATE.particle_effect = active and active.label and active.label() or "unavailable"
  VFX8_DEMO_STATE.active_particles = particle_count
end

function love.load()
  love.window.setMode(720, 408, {resizable = false})
  love.window.setTitle("VFX8 demo")
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.graphics.setFont(love.graphics.newFont(8))
  refresh_fx()
  sync_mcp_state()
  if love.filesystem.getInfo("vfx8_mcp_enabled") then
    mcp = require("love_mcp")
    mcp.init({host = "127.0.0.1", port = 21110, game_state = VFX8_DEMO_STATE})
  end
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  elseif key == "left" then
    selected = (selected + 5) % 7 + 1
    refresh_fx()
  elseif key == "right" then
    selected = selected % 7 + 1
    refresh_fx()
  elseif key == "up" then
    quality = quality % 3 + 1
    refresh_fx()
  elseif key == "down" then
    quality = (quality + 1) % 3 + 1
    refresh_fx()
  elseif key == "x" then
    fx_enabled = not fx_enabled
    refresh_fx()
  elseif key == "p" and active then
    if active.cycle_variant then active.cycle_variant()
    elseif active.cycle_preset then active.cycle_preset() end
  elseif key == "m" and active and active.cycle_shape then
    active.cycle_shape()
  elseif (key == "space" or key == "z") and active and active.trigger then
    active.trigger(120, 70)
  end
end

function love.update(dt)
  tick = (tick + dt * 60) % 240
  wave_time = wave_time + dt
  if active and active.update then active.update(dt) end
  sync_mcp_state()
end

local function draw_scene()
  palette_scene = true
  local actor_x = 24 + math.floor(tick % 180)
  if active and active.prepare_rotation then
    active.prepare_rotation(wave_time, actor_x + 4.5, 70.5)
  end
  local rotating = active and active.rotation_enabled and active.rotation_enabled()
  local min_x, min_y, max_x, max_y = 0, 29, 240, 109
  if rotating then min_x, min_y, max_x, max_y = active.rotation_bounds(0, 29, 240, 109, 8) end
  local grid_x = math.floor(min_x / 16) * 16
  local grid_y = 29 + math.floor((min_y - 29) / 16) * 16
  local wave_x = math.floor(min_x / 4) * 4
  local wave_count = math.floor((max_x - wave_x + 3) / 4)
  color(colors.bg)
  love.graphics.rectangle("fill", 0, 0, 240, 136)
  color(colors.field)
  love.graphics.rectangle("fill", 0, 29, 240, 80)
  color(colors.grid)
  love.graphics.setScissor(0, 29 * 3, 240 * 3, 80 * 3)
  for x = grid_x, max_x, 16 do
    local x1, y1, x2, y2 = x, min_y, x, max_y
    if rotating then
      x1, y1 = active.rotate_point(x1, y1)
      x2, y2 = active.rotate_point(x2, y2)
    end
    love.graphics.line(x1, y1, x2, y2)
  end
  if active and active.wave_offset then
    for i = 0, wave_count do wave_samples[i] = active.wave_offset(wave_x + i * 4, wave_time) end
  end
  for y = grid_y, max_y, 16 do
    if active and active.wave_offset then
      for i = 0, wave_count - 1 do
        local x1, y1 = wave_x + i * 4, y + wave_samples[i]
        local x2, y2 = x1 + 4, y + wave_samples[i + 1]
        if rotating then
          x1, y1 = active.rotate_point(x1, y1)
          x2, y2 = active.rotate_point(x2, y2)
        end
        love.graphics.line(x1, y1, x2, y2)
      end
    else
      local x1, y1, x2, y2 = min_x, y, max_x, y
      if rotating then
        x1, y1 = active.rotate_point(x1, y1)
        x2, y2 = active.rotate_point(x2, y2)
      end
      love.graphics.line(x1, y1, x2, y2)
    end
  end
  love.graphics.setScissor()
  color(colors.ground)
  love.graphics.rectangle("fill", 0, 101, 240, 8)
  color(colors.actor)
  if active and active.scale then
    local sx, sy = active.scale()
    local w, h = math.floor(9 * sx), math.floor(9 * sy)
    local px, py = actor_x + (9 - w) / 2, 66 + (9 - h) / 2
    for iy = 0, h - 1 do for ix = 0, w - 1 do
      if active.visible(px + ix, py + iy, (tick % 2) / 2) then
        love.graphics.rectangle("fill", px + ix, py + iy, 1, 1)
      end
    end end
  else love.graphics.rectangle("fill", actor_x, 66, 9, 9) end
  color(colors.target)
  love.graphics.line(114, 70, 126, 70)
  love.graphics.line(120, 64, 120, 76)
  palette_scene = false
end

function love.draw()
  love.graphics.push("all")
  love.graphics.scale(3, 3)
  if active and active.draw_scene then
    love.graphics.push()
    love.graphics.translate(0, 29)
    love.graphics.scale(1, 80 / 110)
    active.draw_scene()
    love.graphics.pop()
  elseif active and active.render_scene then
    active.render_scene(draw_scene)
  else
    draw_scene()
  end
  if active and active.draw then active.draw() end
  color(colors.bg)
  love.graphics.rectangle("fill", 0, 0, 240, 28)
  color(colors.target)
  love.graphics.print("VFX8 DEMO  " .. names[selected], 4, 2)
  color(colors.label)
  love.graphics.print("QUALITY: " .. qualities[quality] .. "   FX: " .. (fx_enabled and "ON" or "OFF"), 4, 14)
  if active and active.label then love.graphics.print(active.label(), 4, 23) end
  color(colors.bg)
  love.graphics.rectangle("fill", 0, 110, 240, 26)
  color(active and colors.label or colors.dim)
  local status = not fx_enabled and "FX DISABLED" or (active and "READY" or "NOT IMPLEMENTED")
  love.graphics.print(status, 4, 110)
  color(colors.target)
  love.graphics.print("LEFT/RIGHT: MODULE   UP/DOWN: QUALITY", 4, 118)
  love.graphics.print("SPACE: TRIGGER X: TOGGLE P: GRID ROT/PRESET M: SHAPE", 4, 126)
  love.graphics.pop()
  if mcp_bridge then mcp_bridge.captureIfPending() end
end

function love.quit()
  if mcp then mcp.shutdown() end
end
