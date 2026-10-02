-- Minimal VFX8 integration game for LÖVE.
local particles = require("vfx8.particles")
local screen_fx = require("vfx8.screen_fx")
local pixel_deform = require("vfx8.pixel_deform")
local palette_fx = require("vfx8.palette_fx")
local pseudo3d = require("vfx8.pseudo3d")
local flames = require("vfx8.flames")
local electricity = require("vfx8.electricity")

local width, height, scale = 480, 272, 2
local play_top, play_bottom = 36, height - 24
local catalog = {
  {1, "EXPLOSION / POINT", "explosion", "point"},
  {1, "EXPLOSION / LINE", "explosion", "line"},
  {1, "EXPLOSION / AREA", "explosion", "area"},
  {1, "SPARKS / POINT", "sparks", "point"},
  {1, "SPARKS / LINE", "sparks", "line"},
  {1, "SPARKS / AREA", "sparks", "area"},
  {1, "TRAIL / POINT", "trail", "point"},
  {1, "TRAIL / LINE", "trail", "line"},
  {1, "TRAIL / AREA", "trail", "area"},
  {1, "SMOKE / POINT", "smoke", "point"},
  {1, "SMOKE / LINE", "smoke", "line"},
  {1, "SMOKE / AREA", "smoke", "area"},
  {1, "DUST / POINT", "dust", "point"},
  {1, "DUST / LINE", "dust", "line"},
  {1, "DUST / AREA", "dust", "area"},
  {2, "TRAUMA SHAKE", "trauma"},
  {2, "LEFT IMPULSE", "left"},
  {2, "RIGHT IMPULSE", "right"},
  {2, "SHOCKWAVE / RIPPLE", "shockwave"},
  {2, "SCREEN FLASH", "flash"},
  {3, "WAVE WARP", "wave"},
  {3, "WAVE + ROTATION", "rotation"},
  {3, "SQUASH / STRETCH", "squash"},
  {3, "ORDERED DISSOLVE", "ordered"},
  {3, "CHECKER DISSOLVE", "checker"},
  {3, "SPIRAL DISSOLVE", "spiral"},
  {4, "COLOR CYCLING", "cycle"},
  {4, "NIGHT FILTER", "night"},
  {4, "SEPIA FILTER", "sepia"},
  {4, "MONOCHROME FILTER", "mono"},
  {4, "GLOW PULSE", "glow"},
  {4, "DAMAGE FLASH", "damage"},
  {4, "NEGATIVE FLASH", "negative"},
  {4, "CUSTOM DUSK MAP", "dusk"},
  {5, "MODE 7 TEXTURED PLANE", "mode7"},
  {5, "PARALLAX STARFIELD", "stars"},
  {5, "DEPTH-PROJECTED OBJECT", "object"},
  {6, "FLAMETHROWER JET", "jet"},
  {6, "CAMPFIRE PLUME", "campfire"},
  {7, "BRANCHED LIGHTNING", "branched"},
  {7, "CLEAN LIGHTNING ARC", "clean"}
}
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

local selected = 1
local selected_group = 0
local entry = catalog[selected]
local effect
local player = {x = width * 0.5, y = height * 0.54, speed = 144}
local clock = 0
local dissolve_time = nil
local campfire_x, campfire_y
local mode7_texture
local wave_x_samples, wave_y_samples = {}, {}

local function create_effect(group)
  if group == 1 then return particles.new({quality = "medium"})
  elseif group == 2 then return screen_fx.new({width = width, height = height, capacity = 8})
  elseif group == 3 then return pixel_deform.new({quality = "medium"})
  elseif group == 4 then
    local instance = palette_fx.new({quality = "low", color_count = 16})
    instance:set_invert_palette(palette)
    return instance
  elseif group == 5 then
    return pseudo3d.new({quality = "high", width = width, height = play_bottom, horizon = 84, camera_height = 60, road_width = 200})
  elseif group == 6 then return flames.new({quality = "medium"})
  else return electricity.new({quality = "medium"}) end
end

local function configure_entry()
  if effect then effect:clear() end
  entry = catalog[selected]
  if selected_group ~= entry[1] or not effect then
    effect = create_effect(entry[1])
    selected_group = entry[1]
  end
  if entry[1] == 4 then
    if entry[2] == "cycle" then effect:set_cycle(8, 11, 2)
    elseif entry[2] == "night" or entry[2] == "sepia" or entry[2] == "mono" then effect:set_filter(entry[2])
    elseif entry[2] == "glow" then effect:set_pulse(8, 10, 3)
    elseif entry[2] == "dusk" then effect:set_filter_map(dusk_map) end
  elseif entry[1] == 5 then
    if entry[2] == "mode7" then effect:set_mode7(mode7_texture, {scale = 0.09})
    else effect:set_mode7(false) end
  end
  dissolve_time = nil
end

local function next_entry()
  selected = selected % #catalog + 1
  configure_entry()
end

local function trigger_effect()
  local mode = entry[2]
  if entry[1] == 1 then
    local preset, shape = entry[3], entry[4]
    if shape == "line" then effect:emit_line(preset, math.max(8, player.x - 48), player.y, math.min(width - 8, player.x + 48), player.y, {spread = 2})
    elseif shape == "area" then effect:emit_area(preset, player.x - 24, player.y - 16, 48, 32)
    else effect:emit(preset, player.x, player.y) end
  elseif entry[1] == 2 then
    if mode == "trauma" then effect:add_trauma(0.9)
    elseif mode == "left" then effect:impulse(-12, 0, 0.2)
    elseif mode == "right" then effect:impulse(12, 0, 0.2)
    elseif mode == "shockwave" then effect:shockwave(player.x, player.y, 4, 22, 0.36)
    else effect:flash(0.14, {1, 0.88, 0.7, 1}) end
  elseif entry[1] == 3 then
    if mode == "squash" then effect:set_squash(1.65, 0.58, 0.32)
    elseif mode == "ordered" or mode == "checker" or mode == "spiral" then dissolve_time = 0
    else effect.phase = 0 end
  elseif entry[1] == 4 then
    if mode == "damage" then effect:flash(8, 10, 7, 0.2)
    elseif mode == "negative" then effect:invert(0.22)
    else effect:flash(8, 10, 7, 0.16) end
  elseif entry[1] == 5 then
    local lateral = (player.x - width * 0.5) / (width * 0.5) * 0.72
    effect:add_object(lateral, 96, 11, 12)
  elseif entry[1] == 6 then
    if mode == "jet" then effect:emit_jet(player.x, player.y, 1, -0.16)
    else effect:emit_campfire(player.x, player.y + 12, {count = 16, radius = 7}) end
  else
    local x2 = math.min(width - 20, player.x + 112)
    local y2 = math.max(play_top + 12, player.y - 80)
    effect:strike(player.x, player.y, x2, y2, {branches = mode == "branched" and 3 or 0, jaggedness = mode == "clean" and 3 or 12})
  end
end

local function update_game(dt)
  local dx = (love.keyboard.isDown("right") and 1 or 0) - (love.keyboard.isDown("left") and 1 or 0)
  local dy = (love.keyboard.isDown("down") and 1 or 0) - (love.keyboard.isDown("up") and 1 or 0)
  player.x = math.max(8, math.min(width - 8, player.x + dx * player.speed * dt))
  player.y = math.max(play_top + 8, math.min(play_bottom - 8, player.y + dy * player.speed * dt))
  clock = clock + dt
  if entry[1] == 6 and entry[2] == "campfire" then
    campfire_x, campfire_y = player.x, player.y + 12
    effect:emit_campfire(campfire_x, campfire_y, {count = 5, radius = 5})
  end
  effect:update(dt)
  if dissolve_time then
    dissolve_time = dissolve_time + dt
    if dissolve_time >= 0.8 then dissolve_time = nil end
  end
end

local function set_index_color(index)
  if entry[1] == 4 then index = effect:map_color(index) end
  local color = palette[(index % 16) + 1]
  love.graphics.setColor(color[1], color[2], color[3], 1)
end

local function draw_pixel_grid()
  local rotating = entry[2] == "rotation"
  local left, top, right, bottom = 0, play_top, width, play_bottom
  if rotating then
    effect:set_rotation(player.x, player.y, clock * 0.45)
    left, top, right, bottom = effect:rotation_bounds(left, top, right, bottom, 28)
  end
  local spacing, segment = 40, 20
  local grid_left, grid_top = math.floor(left / spacing) * spacing, math.floor(top / spacing) * spacing
  local sample_left, sample_top = math.floor(left / segment) * segment, math.floor(top / segment) * segment
  for x = sample_left, right + spacing + segment, segment do
    wave_x_samples[x] = effect:wave_offset(x, clock, 12, 112, 0.7)
  end
  for y = sample_top, bottom + spacing + segment, segment do
    wave_y_samples[y] = effect:wave_offset(y, clock, 12, 112, 0.7)
  end
  love.graphics.setColor(0.23, 0.31, 0.43, 1)
  love.graphics.setScissor(0, play_top * scale, width * scale, (play_bottom - play_top) * scale)
  local function point(x, y)
    local wave_x = x + wave_y_samples[y]
    local wave_y = y + wave_x_samples[x]
    if rotating then return effect:rotate_point(wave_x, wave_y) end
    return wave_x, wave_y
  end
  for x = grid_left, right + spacing, spacing do
    for y = sample_top, bottom - segment, segment do
      local ax, ay = point(x, y)
      local bx, by = point(x, math.min(bottom, y + segment))
      love.graphics.line(ax, ay, bx, by)
    end
  end
  for y = grid_top, bottom + spacing, spacing do
    for x = sample_left, right - segment, segment do
      local ax, ay = point(x, y)
      local bx, by = point(math.min(right, x + segment), y)
      love.graphics.line(ax, ay, bx, by)
    end
  end
  love.graphics.setScissor()
end

local function draw_world()
  if entry[1] == 5 then
    effect:draw(road_colors)
  else
    set_index_color(1)
    love.graphics.rectangle("fill", 0, 0, width, height)
    set_index_color(2)
    love.graphics.rectangle("fill", 0, play_top, width, play_bottom - play_top)
    if entry[1] == 3 and (entry[2] == "wave" or entry[2] == "rotation") then
      draw_pixel_grid()
    else
      set_index_color(13)
      for x = 0, width, 40 do love.graphics.line(x, play_top, x, play_bottom) end
      for y = play_top, play_bottom, 40 do love.graphics.line(0, y, width, y) end
    end
  end

  set_index_color(8)
  if entry[1] == 3 and (entry[2] == "ordered" or entry[2] == "checker" or entry[2] == "spiral") and dissolve_time then
    local amount = math.min(1, dissolve_time / 0.8)
    for iy = 0, 15 do
      for ix = 0, 15 do
        if effect:visible(player.x - 8 + ix, player.y - 8 + iy, amount, entry[2]) then
          love.graphics.rectangle("fill", math.floor(player.x - 8 + ix), math.floor(player.y - 8 + iy), 1, 1)
        end
      end
    end
  else
    local sx, sy = 1, 1
    if entry[1] == 3 and entry[2] == "squash" then sx, sy = effect:scale() end
    local w, h = math.max(4, math.floor(16 * sx)), math.max(4, math.floor(16 * sy))
    love.graphics.rectangle("fill", math.floor(player.x - w / 2), math.floor(player.y - h / 2), w, h)
  end

  if entry[1] == 1 or entry[1] == 6 or entry[1] == 7 then effect:draw() end
end

local function make_mode7_texture()
  local image_data = love.image.newImageData(64, 64)
  for y = 0, 63 do
    for x = 0, 63 do
      local tile = (math.floor(x / 8) + math.floor(y / 8)) % 2
      local lane_mark = x % 32 < 2 or x % 32 > 29
      local shade = lane_mark and 0.65 or (tile == 0 and 0.14 or 0.22)
      image_data:setPixel(x, y, shade, shade * 1.35, shade * 1.7, 1)
    end
  end
  mode7_texture = love.graphics.newImage(image_data)
  mode7_texture:setFilter("nearest", "nearest")
end

function love.load()
  love.window.setMode(width * scale, height * scale, {resizable = false})
  love.window.setTitle("VFX8 Integration Game")
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.graphics.setFont(love.graphics.newFont(16))
  make_mode7_texture()
  configure_entry()
end

function love.update(dt)
  update_game(math.min(dt, 0.1))
end

function love.keypressed(key)
  if key == "escape" then love.event.quit()
  elseif key == "tab" then next_entry()
  elseif key == "space" then trigger_effect() end
end

function love.draw()
  love.graphics.push("all")
  love.graphics.scale(scale, scale)
  if entry[1] == 2 then effect:render(draw_world) else draw_world() end
  love.graphics.setColor(0.02, 0.03, 0.08, 1)
  love.graphics.rectangle("fill", 0, 0, width, play_top)
  local title = ({"PARTICLES", "SCREEN FX", "PIXEL WARP", "PALETTE FX", "PSEUDO-3D", "FLAMES", "ELECTRICITY"})[entry[1]] .. " / " .. entry[2]
  love.graphics.setColor(0.94, 0.92, 0.78, 1)
  love.graphics.printf(title, 4, 8, width - 8, "center")
  love.graphics.setColor(0.02, 0.03, 0.08, 1)
  love.graphics.rectangle("fill", 0, play_bottom, width, height - play_bottom)
  love.graphics.setColor(0.45, 0.85, 1, 1)
  love.graphics.print("ARROWS MOVE   SPACE: TRIGGER   TAB: NEXT VARIANT", 8, play_bottom + 4)
  love.graphics.pop()
end
