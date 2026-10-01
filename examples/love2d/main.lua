-- VFX8 demo harness. Run this folder with LÖVE.
local fx = require("demo_extension")

local names = {"particles", "screen fx", "pixel warp", "palette fx", "pseudo 3d"}
local qualities = {"low", "medium", "high"}
local selected, quality = 1, 1
local fx_enabled, active = true, nil
local tick = 0

local colors = {
  bg = {0.05, 0.07, 0.14},
  field = {0.11, 0.17, 0.27},
  grid = {0.20, 0.27, 0.36},
  ground = {0.12, 0.46, 0.34},
  actor = {0.95, 0.35, 0.27},
  target = {0.95, 0.93, 0.78},
  label = {0.50, 0.85, 0.95},
  dim = {0.55, 0.57, 0.63}
}

local function color(c)
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

function love.load()
  love.window.setMode(720, 408, {resizable = false})
  love.window.setTitle("VFX8 demo")
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.graphics.setFont(love.graphics.newFont(8))
  refresh_fx()
end

function love.keypressed(key)
  if key == "left" then
    selected = (selected + 3) % 5 + 1
    refresh_fx()
  elseif key == "right" then
    selected = selected % 5 + 1
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
  elseif (key == "space" or key == "z") and active and active.trigger then
    active.trigger(120, 70)
  end
end

function love.update(dt)
  tick = (tick + dt * 60) % 240
  if active and active.update then active.update(dt) end
end

local function draw_scene()
  color(colors.bg)
  love.graphics.rectangle("fill", 0, 0, 240, 136)
  color(colors.field)
  love.graphics.rectangle("fill", 0, 29, 240, 80)
  color(colors.grid)
  for x = 0, 239, 16 do love.graphics.line(x, 29, x, 108) end
  for y = 29, 108, 16 do love.graphics.line(0, y, 239, y) end
  color(colors.ground)
  love.graphics.rectangle("fill", 0, 101, 240, 8)
  color(colors.actor)
  love.graphics.rectangle("fill", 24 + math.floor(tick % 180), 66, 9, 9)
  color(colors.target)
  love.graphics.line(114, 70, 126, 70)
  love.graphics.line(120, 64, 120, 76)
end

function love.draw()
  love.graphics.push("all")
  love.graphics.scale(3, 3)
  if active and active.render_scene then
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
  color(colors.bg)
  love.graphics.rectangle("fill", 0, 110, 240, 26)
  color(active and colors.label or colors.dim)
  local status = not fx_enabled and "FX DISABLED" or (active and "READY" or "NOT IMPLEMENTED")
  love.graphics.print(status, 4, 110)
  color(colors.target)
  love.graphics.print("LEFT/RIGHT: MODULE   UP/DOWN: QUALITY", 4, 118)
  love.graphics.print("SPACE/Z: TRIGGER   X: FX ON/OFF", 4, 126)
  love.graphics.pop()
end
