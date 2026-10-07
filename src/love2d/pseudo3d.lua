-- VFX8 bounded pseudo-3D helpers for LÖVE.
-- Copy this module into your project as vfx8/pseudo3d.lua.

local pseudo3d = {}
local methods = {}
local empty_options = {}
local default_sky = {0.025, 0.035, 0.09}
local default_road_a = {0.07, 0.12, 0.22}
local default_road_b = {0.09, 0.17, 0.29}
local default_edge = {0.28, 0.78, 0.68}
local default_ground = {0.04, 0.20, 0.16}
local default_star = {{0.4, 0.7, 1}, {0.75, 0.85, 1}, {1, 1, 1}}
local mode7_shader_source = [[
extern Image mode7Texture;
extern vec2 planeSize;
extern float cameraHeight;
extern float cameraX;
extern float cameraZ;
extern float heading;
extern float textureScale;
extern float perspectiveFactor;
vec4 effect(vec4 color, Image image, vec2 texture_coords, vec2 screen_coords) {
  float vertical = max(1.0, texture_coords.y * planeSize.y);
  float distance = cameraHeight * cameraHeight * perspectiveFactor / vertical;
  float lateral = (texture_coords.x - 0.5) * planeSize.x * distance / cameraHeight;
  float cs = cos(heading);
  float sn = sin(heading);
  vec2 world = vec2(cameraX + distance * sn + lateral * cs,
                    cameraZ + distance * cs - lateral * sn);
  return Texel(mode7Texture, fract(world * textureScale)) * color;
}
]]
local shared_mode7_shader = nil
local mode7_shader_attempted = false

local profiles = {
  low = {rows = 18, stars = 24, objects = 8},
  medium = {rows = 36, stars = 48, objects = 16},
  high = {rows = 72, stars = 96, objects = 32}
}

local function clamp(value, low, high)
  return math.max(low, math.min(high, value))
end

function pseudo3d.new(options)
  options = options or {}
  local quality = profiles[options.quality] and options.quality or "low"
  local profile = profiles[quality]
  local width, height = options.width or 240, options.height or 136
  local star_count = clamp(math.floor(options.star_count or profile.stars), 0, 256)
  local object_capacity = clamp(math.floor(options.object_capacity or profile.objects), 1, 64)
  local self = {
    width = width, height = height, quality = quality,
    horizon = clamp(options.horizon or height * 0.38, 0, height - 1),
    camera_height = math.max(1, options.camera_height or height * 0.45),
    road_width = math.max(1, options.road_width or width * 0.55),
    camera_x = options.camera_x or 0, camera_z = 0, speed = options.speed or 18,
    perspective = options.perspective or 0.62, star_speed = options.star_speed or 1,
    star_parallax = options.star_parallax or 0.08, star_layers = clamp(math.floor(options.star_layers or 3), 1, 3),
    star_near = options.star_near or 8, star_far = options.star_far or 127,
    star_seed = options.star_seed or 0, custom_star_depth = options.star_near ~= nil or options.star_far ~= nil,
    mode7_time = 0,
    curve = options.curve or 0, curve_strength = options.curve_strength or width * 0.32,
    mode7 = nil, mode7_angle = options.mode7_angle or 0,
    lane_count = clamp(math.floor(options.lane_count or 3), 1, 8),
    rows = profile.rows, stars = {}, star_count = star_count,
    objects = {}, object_count = 0, object_capacity = object_capacity,
    sort_depth = {}, sort_index = {},
    object_palette = {{1, 0.42, 0.35}, {1, 0.82, 0.35}, {0.36, 0.9, 0.78}, {0.78, 0.58, 1}},
    draw_colors = {},
    update = methods.update, draw = methods.draw, add_object = methods.add_object,
    clear_objects = methods.clear_objects, set_camera = methods.set_camera, set_road = methods.set_road,
    project = methods.project, project_road = methods.project_road, set_mode7 = methods.set_mode7,
    clear = methods.clear
  }
  for i = 1, star_count do
    local z = self.custom_star_depth and (self.star_near + (self.star_far - self.star_near) * ((i * 47 % 127) / 127)) or (8 + i * 47 % 120)
    self.stars[i] = {x = (((i * 73 + self.star_seed) % 127) / 63.5 - 1) * 48, y = -0.1 - (i * 47 % 127) / 127 * 0.9, z = z, layer = i % self.star_layers}
  end
  for i = 1, object_capacity do self.objects[i] = {active = false} end
  return self
end

function methods.set_camera(self, x, horizon, speed, curve)
  if x ~= nil then self.camera_x = x end
  if horizon ~= nil then self.horizon = clamp(horizon, 0, self.height - 1) end
  if speed ~= nil then self.speed = speed end
  if curve ~= nil then self.curve = curve end
end

function methods.set_road(self, width, lanes, curve, curve_strength)
  if width ~= nil then self.road_width = math.max(1, width) end
  if lanes ~= nil then self.lane_count = clamp(math.floor(lanes), 1, 8) end
  if curve ~= nil then self.curve = curve end
  if curve_strength ~= nil then self.curve_strength = curve_strength end
end

function methods.set_mode7(self, texture, options)
  if texture == nil or texture == false then self.mode7 = nil; return true end
  if type(texture) ~= "userdata" or not texture.typeOf or not texture:typeOf("Image") then
    self.mode7 = nil
    return false
  end
  options = options or empty_options
  if options.angle ~= nil then self.mode7_angle = options.angle
  elseif texture.angle ~= nil then self.mode7_angle = texture.angle end
  self.mode7 = {image = texture, scale = options.scale or 0.08,
    scroll_speed_x = options.scroll_speed_x or 0, scroll_speed_y = options.scroll_speed_y or 0}
  if not mode7_shader_attempted then
    mode7_shader_attempted = true
    local ok, shader = pcall(love.graphics.newShader, mode7_shader_source)
    if ok then shared_mode7_shader = shader end
  end
  if not shared_mode7_shader then self.mode7 = nil; return false end
  return true
end

function methods.project_road(self, lateral, z, size)
  local safe_z = math.max(2.1, z or 60)
  local scale = self.camera_height / safe_z
  local y = self.horizon + scale * self.camera_height * self.perspective
  local vertical = math.max(0, y - self.horizon)
  local depth = clamp(1 - vertical / math.max(1, self.height - self.horizon), 0, 1)
  local half = self.road_width * vertical / self.camera_height
  local bend = self.curve * self.curve_strength * depth * depth
  local x = self.width * 0.5 + (lateral or 0) * half - self.camera_x * depth + bend
  return x, y, (size or 1) * scale
end

function methods.update(self, dt)
  dt = clamp(dt or 1 / 60, 0, 0.1)
  self.camera_z = self.camera_z + self.speed * dt
  self.mode7_time = self.mode7_time + dt
  for i = 1, self.star_count do
    local star = self.stars[i]
    star.z = star.z - self.speed * self.star_speed * dt * (0.45 + star.layer * 0.35)
    if star.z < 2 then
      star.z = self.custom_star_depth and (self.star_near + (self.star_far - self.star_near) * ((i * 47 % 127) / 127)) or (100 + (i % 23) * 2)
      star.x = (((i * 73 + math.floor(self.camera_z) + self.star_seed) % 127) / 63.5 - 1) * 48
      star.y = -0.1 - (i * 47 % 127) / 127 * 0.9
    end
  end
  for i = self.object_count, 1, -1 do
    local object = self.objects[i]
    if object.active then
      object.z = object.z - object.speed * dt
      if object.z <= 2 then object.active = false end
    end
  end
  while self.object_count > 0 and not self.objects[self.object_count].active do self.object_count = self.object_count - 1 end
end

function methods.add_object(self, x, z, color, size, options)
  local index = 1
  while index <= self.object_capacity and self.objects[index].active do index = index + 1 end
  if index > self.object_capacity then return false end
  local object = self.objects[index]
  options = options or empty_options
  object.x, object.z = x or 0, math.max(2.1, z or 60)
  object.color, object.size, object.active = color or 11, size or 8, true
  object.speed, object.sort_z = options.speed or self.speed, options.z_order or object.z
  if index > self.object_count then self.object_count = index end
  return true
end

function methods.clear_objects(self)
  for i = 1, self.object_count do self.objects[i].active = false end
  self.object_count = 0
end

function methods.project(self, x, z, size)
  local scale = self.camera_height / math.max(2.1, z or 60)
  return self.width * 0.5 + ((x or 0) - self.camera_x) * scale,
    self.horizon + scale * self.camera_height * self.perspective, (size or 1) * scale
end

local function draw_starfield(self, g, colors)
  local center_x = self.width * 0.5
  for i = 1, self.star_count do
    local star = self.stars[i]
    local scale = self.camera_height / star.z
    local x = center_x + (star.x - self.camera_x * self.star_parallax) * scale * 2.2
    local y = self.horizon + star.y * scale
    if x >= 0 and x < self.width and y >= 0 and y < self.horizon then
      local c = colors.star[star.layer + 1]
      g.setColor(c[1], c[2], c[3], c[4] or 1)
      g.points(math.floor(x), math.floor(y))
    end
  end
end

local function draw_plane(self, g, colors)
  local horizon, height, center_x = self.horizon, self.height, self.width * 0.5
  local ground = colors.ground
  g.setColor(ground[1], ground[2], ground[3], ground[4] or 1)
  g.rectangle("fill", 0, horizon, self.width, height - horizon)
  if self.mode7 and shared_mode7_shader then
    shared_mode7_shader:send("mode7Texture", self.mode7.image)
    shared_mode7_shader:send("planeSize", {self.width, height - horizon})
    shared_mode7_shader:send("cameraHeight", self.camera_height)
    shared_mode7_shader:send("heading", self.mode7_angle)
    shared_mode7_shader:send("textureScale", self.mode7.scale)
    shared_mode7_shader:send("perspectiveFactor", self.perspective)
    shared_mode7_shader:send("cameraX", self.camera_x + self.mode7_time * self.mode7.scroll_speed_x)
    shared_mode7_shader:send("cameraZ", self.camera_z + self.mode7_time * self.mode7.scroll_speed_y)
    g.setColor(1, 1, 1, 1)
    g.setShader(shared_mode7_shader)
    g.rectangle("fill", 0, horizon, self.width, height - horizon)
    g.setShader()
  else
  local steps = math.min(self.rows, height - horizon)
  for row = 1, steps do
    local y = horizon + math.floor((row - 1) * (height - horizon) / steps) + 1
    local next_y = math.min(height, horizon + math.floor(row * (height - horizon) / steps) + 1)
    if next_y < y then next_y = y end
    local distance = y - horizon
    local depth = clamp(1 - distance / (height - horizon), 0, 1)
    local half = math.min(self.width * 1.5, self.road_width * distance / self.camera_height)
    local shift = self.camera_x * depth + self.curve * self.curve_strength * depth * depth
    local left = center_x - half - shift
    local stripe = math.floor((self.camera_z / 8 + distance * 0.2)) % 2 == 0
    local c = stripe and colors.road_a or colors.road_b
    g.setColor(c[1], c[2], c[3], c[4] or 1)
    g.rectangle("fill", math.floor(left), y, math.ceil(half * 2), next_y - y)
    local edge = colors.edge
    g.setColor(edge[1], edge[2], edge[3], edge[4] or 1)
    local lx = math.floor(left)
    local rx = math.floor(center_x + half - shift)
    g.points(lx, y, rx, y)
    if self.lane_count > 1 and row % 2 == 0 then
      local lane_y = y + math.floor((next_y - y) * 0.5)
      local dash = math.max(1, math.floor(distance / self.camera_height * 5))
      for lane = 1, self.lane_count - 1 do
        if math.floor(self.camera_z / 6 + distance * 0.12) % 2 == 0 then
          local lane_x = left + half * 2 * lane / self.lane_count
          g.setColor(edge[1], edge[2], edge[3], edge[4] or 1)
          g.rectangle("fill", math.floor(lane_x), lane_y, dash, math.max(1, next_y - y))
        end
      end
    end
  end
  local sky = colors.sky
  g.setColor(sky[1], sky[2], sky[3], sky[4] or 1)
  g.rectangle("fill", 0, 0, self.width, horizon)
  end
end

local function draw_objects(self, g)
  local count = 0
  for i = 1, self.object_count do
    local object = self.objects[i]
    if object.active then
      count = count + 1
      local insert = count
      while insert > 1 and self.sort_depth[insert - 1] < object.sort_z do
        self.sort_depth[insert], self.sort_index[insert] = self.sort_depth[insert - 1], self.sort_index[insert - 1]
        insert = insert - 1
      end
      self.sort_depth[insert], self.sort_index[insert] = object.sort_z, i
    end
  end
  local center_x = self.width * 0.5
  for n = 1, count do
    local object = self.objects[self.sort_index[n]]
      local x, y, projected_size = self:project_road(object.x, object.z, object.size)
    local size = math.max(1, projected_size)
    if x + size >= 0 and x - size < self.width and y + size >= self.horizon and y - size < self.height then
      g.setColor(0.12, 0.08, 0.18, 1)
      g.rectangle("fill", math.floor(x - size * 0.6), math.floor(y - size), math.ceil(size * 1.2), math.ceil(size))
      local c = self.object_palette[(object.color % #self.object_palette) + 1]
      g.setColor(c[1], c[2], c[3], 1)
      g.rectangle("fill", math.floor(x - size * 0.5), math.floor(y - size), math.ceil(size), math.ceil(size * 0.85))
    end
  end
end

function methods.draw(self, options)
  local g = love.graphics
  options = options or empty_options
  local colors = self.draw_colors
  colors.sky = options.sky or default_sky
  colors.road_a = options.road_a or default_road_a
  colors.road_b = options.road_b or default_road_b
  colors.edge = options.edge or default_edge
  colors.ground = options.ground or default_ground
  colors.star = options.star or default_star
  g.push("all")
  local ok, err = xpcall(function()
    draw_plane(self, g, colors)
    draw_starfield(self, g, colors)
    draw_objects(self, g)
  end, debug.traceback)
  g.pop()
  if not ok then error(err, 0) end
end

function methods.clear(self)
  methods.clear_objects(self)
  self.camera_z = 0
end

return pseudo3d
