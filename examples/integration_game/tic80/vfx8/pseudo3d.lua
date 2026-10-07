-- VFX8 bounded pseudo-3D helpers for TIC-80.
-- Include this file once; it defines vfx8_pseudo3d.

vfx8_pseudo3d = vfx8_pseudo3d or {}
local methods = {}
local empty_colors = {}
local profiles = {low = {rows = 20, stars = 24, objects = 8}, medium = {rows = 40, stars = 56, objects = 18}, high = {rows = 70, stars = 104, objects = 36}}

function vfx8_pseudo3d.new(options)
  options = options or {}
  local profile = profiles[options.quality or "low"] or profiles.low
  local width, height = options.width or 240, options.height or 136
  local count = math.min(192, math.max(0, math.floor(options.star_count or profile.stars)))
  local capacity = math.min(64, math.max(1, math.floor(options.object_capacity or profile.objects)))
  local self = {width = width, height = height, horizon = options.horizon or 48,
    camera_height = options.camera_height or 52, road_width = options.road_width or 96,
    camera_x = 0, camera_z = 0, speed = options.speed or 18,
    perspective = options.perspective or 0.62, star_speed = options.star_speed or 1,
    star_parallax = options.star_parallax or 0.08, star_layers = math.min(3, math.max(1, math.floor(options.star_layers or 3))),
    star_near = options.star_near or 8, star_far = options.star_far or 127,
    star_seed = options.star_seed or 0, custom_star_depth = options.star_near ~= nil or options.star_far ~= nil, mode7_time = 0,
    curve = options.curve or 0, curve_strength = options.curve_strength or width * 0.32,
    mode7 = nil, mode7_angle = options.mode7_angle or 0,
    mode7_step = (options.quality == "high" and 1) or (options.quality == "medium" and 2) or 4,
    lane_count = math.min(8, math.max(1, math.floor(options.lane_count or 3))), rows = profile.rows,
    stars = {}, star_count = count, objects = {}, object_count = 0, object_capacity = capacity,
    sort_depth = {}, sort_index = {}, update = methods.update, draw = methods.draw,
    add_object = methods.add_object, clear_objects = methods.clear_objects,
    set_camera = methods.set_camera, set_road = methods.set_road,
    project = methods.project, project_road = methods.project_road,
    set_mode7 = methods.set_mode7, clear = methods.clear}
  for i = 1, count do
    local z = self.custom_star_depth and (self.star_near + (self.star_far - self.star_near) * ((i * 47 % 127) / 127)) or (8 + i * 47 % 120)
    self.stars[i] = {x = (((i * 73 + self.star_seed) % 127) / 63.5 - 1) * 48, y = -0.1 - (i * 47 % 127) / 127 * 0.9, z = z, layer = i % self.star_layers}
  end
  for i = 1, capacity do self.objects[i] = {active = false} end
  return self
end

function methods.set_camera(self, x, horizon, speed, curve)
  if x ~= nil then self.camera_x = x end
  if horizon ~= nil then self.horizon = math.max(0, math.min(self.height - 2, horizon)) end
  if speed ~= nil then self.speed = speed end
  if curve ~= nil then self.curve = curve end
end

function methods.set_road(self, width, lanes, curve, curve_strength)
  if width ~= nil then self.road_width = math.max(1, width) end
  if lanes ~= nil then self.lane_count = math.min(8, math.max(1, math.floor(lanes))) end
  if curve ~= nil then self.curve = curve end
  if curve_strength ~= nil then self.curve_strength = curve_strength end
end

local function mode7_power2(value)
  local result = 1
  while result * 2 <= value do result = result * 2 end
  return result
end

function methods.set_mode7(self, texture, options)
  if texture == nil or texture == false then self.mode7 = nil; return end
  if type(texture) ~= "table" and texture ~= true then self.mode7 = nil; return false end
  texture = texture == true and {} or texture
  options = options or empty_colors
  local x = math.max(0, math.min(127, math.floor(texture.x or 0)))
  local y = math.max(0, math.min(127, math.floor(texture.y or 0)))
  local requested_width = math.max(1, math.min(128 - x, math.floor(texture.width or 128)))
  local requested_height = math.max(1, math.min(128 - y, math.floor(texture.height or 128)))
  local width = mode7_power2(requested_width)
  local height = mode7_power2(requested_height)
  if x % width ~= 0 then x = math.floor(x / width) * width end
  if y % height ~= 0 then y = math.floor(y / height) * height end
  self.mode7 = {x = x, y = y, width = width, height = height,
    scale = options.scale or texture.scale or 0.08,
    scroll_speed_x = options.scroll_speed_x or texture.scroll_speed_x or 0,
    scroll_speed_y = options.scroll_speed_y or texture.scroll_speed_y or 0,
    sample_step = options.sample_step or texture.sample_step}
  if options.angle ~= nil then self.mode7_angle = options.angle
  elseif texture.angle ~= nil then self.mode7_angle = texture.angle end
  return true
end

function methods.project_road(self, lateral, z, size)
  local safe_z = math.max(2.1, z or 60)
  local scale = self.camera_height / safe_z
  local y = self.horizon + scale * self.camera_height * self.perspective
  local vertical = math.max(0, y - self.horizon)
  local depth = math.max(0, math.min(1, 1 - vertical / math.max(1, self.height - self.horizon)))
  local half = self.road_width * vertical / self.camera_height
  local bend = self.curve * self.curve_strength * depth * depth
  local x = self.width * 0.5 + (lateral or 0) * half - self.camera_x * depth + bend
  return x, y, (size or 1) * scale
end

function methods.update(self, dt)
  dt = math.max(0, math.min(0.1, dt or 1 / 60))
  self.camera_z = self.camera_z + self.speed * dt
  self.mode7_time = self.mode7_time + dt
  for i = 1, self.star_count do
    local star = self.stars[i]
    star.z = star.z - self.speed * self.star_speed * dt * (0.45 + star.layer * 0.35)
    if star.z < 2 then
      local seed = math.floor(self.camera_z)
      star.z = self.custom_star_depth and (self.star_near + (self.star_far - self.star_near) * ((i * 47 % 127) / 127)) or (100 + (i % 23) * 2)
      star.x = (((i * 73 + seed + self.star_seed) % 127) / 63.5 - 1) * 48
      star.y = -0.1 - (i * 47 % 127) / 127 * 0.9
    end
  end
  for i = self.object_count, 1, -1 do
    local object = self.objects[i]
    if object.active then object.z = object.z - object.speed * dt; if object.z <= 2 then object.active = false end end
  end
  while self.object_count > 0 and not self.objects[self.object_count].active do self.object_count = self.object_count - 1 end
end

function methods.add_object(self, x, z, color, size, options)
  local i = 1
  while i <= self.object_capacity and self.objects[i].active do i = i + 1 end
  if i > self.object_capacity then return false end
  local object = self.objects[i]
  options = options or empty_colors
  object.x, object.z, object.color = x or 0, math.max(2.1, z or 60), color or 11
  object.size, object.active = size or 8, true
  object.speed, object.sort_z = options.speed or self.speed, options.z_order or object.z
  if i > self.object_count then self.object_count = i end
  return true
end

function methods.clear_objects(self)
  for i = 1, self.object_count do self.objects[i].active = false end
  self.object_count = 0
end

local function draw_mode7(self)
  local texture = self.mode7
  local horizon = math.max(0, math.min(self.height - 2, math.floor(self.horizon)))
  local cosine, sine = math.cos(self.mode7_angle), math.sin(self.mode7_angle)
  local step = texture.sample_step and math.max(1, math.min(4, math.floor(texture.sample_step))) or self.mode7_step
  local row_step = step > 1 and step or 1
  local mask_x, mask_y = texture.width - 1, texture.height - 1
  local uv_scale = texture.scale
  for y = horizon + 1, self.height - 1, row_step do
    local vertical = y + row_step * 0.5 - horizon
    local distance = self.camera_height * self.camera_height * self.perspective / vertical
    local lateral = distance / self.camera_height
    local center_u = (self.camera_x + distance * sine + self.mode7_time * texture.scroll_speed_x) * uv_scale
    local center_v = (self.camera_z + distance * cosine + self.mode7_time * texture.scroll_speed_y) * uv_scale
    for x = 0, self.width - 1, step do
      local screen_lateral = x + step * 0.5 - self.width * 0.5
      local world_u = center_u + screen_lateral * lateral * cosine * uv_scale
      local world_v = center_v - screen_lateral * lateral * sine * uv_scale
      local tx = texture.x + (math.floor(world_u) & mask_x)
      local ty = texture.y + (math.floor(world_v) & mask_y)
      local color = peek4(0xc000 + ty * 128 + tx)
      rect(x, y, step, row_step, color)
    end
  end
end

function methods.project(self, x, z, size)
  local scale = self.camera_height / math.max(2.1, z or 60)
  return self.width * 0.5 + ((x or 0) - self.camera_x) * scale,
    self.horizon + scale * self.camera_height * self.perspective, (size or 1) * scale
end

function methods.draw(self, colors)
  colors = colors or empty_colors
  local sky, road_a, road_b, edge, ground = colors.sky or 1, colors.road_a or 1, colors.road_b or 13, colors.edge or 11, colors.ground or 3
  local cx = self.width * 0.5
  cls(sky)
  if self.mode7 then draw_mode7(self)
  else rect(0, self.horizon, self.width, self.height - self.horizon, ground) end
  if not self.mode7 then for row = 1, self.rows do
    if self.horizon + row < self.height then
      local y = self.horizon + math.floor((row - 1) * (self.height - self.horizon) / self.rows) + 1
      local next_y = math.min(self.height - 1, self.horizon + math.floor(row * (self.height - self.horizon) / self.rows))
      if next_y < y then next_y = y end
      local distance = y - self.horizon
      local depth = math.max(0, math.min(1, 1 - distance / (self.height - self.horizon)))
      local half = math.min(self.width * 1.5, self.road_width * distance / self.camera_height)
      local shift = self.camera_x * depth + self.curve * self.curve_strength * depth * depth
      local left, right = cx - half - shift, cx + half - shift
      local x0, x1 = math.max(0, math.floor(left)), math.min(self.width - 1, math.floor(right))
      local c = (math.floor(self.camera_z / 8 + distance * 0.2) % 2 == 0) and road_a or road_b
      if next_y < y then next_y = y end
      if x0 <= x1 then
        rect(x0, y, x1 - x0 + 1, next_y - y, c)
        if row % 3 == 0 then line(x0, y, x0, y, edge); line(x1, y, x1, y, edge) end
        if self.lane_count > 1 and row % 2 == 0 and math.floor(self.camera_z / 6 + distance * 0.12) % 2 == 0 then
          for lane = 1, self.lane_count - 1 do
            local lane_x = left + half * 2 * lane / self.lane_count
            rect(lane_x, y, math.max(1, distance / self.camera_height * 4), math.max(1, next_y - y), edge)
          end
        end
      end
    end
  end end
  for i = 1, self.star_count do
    local star = self.stars[i]
    local scale = self.camera_height / star.z
    local x, y = cx + (star.x - self.camera_x * self.star_parallax) * scale, self.horizon + star.y * scale
    if x >= 0 and x < self.width and y >= 0 and y < self.horizon then pix(x, y, (colors.stars and colors.stars[star.layer + 1]) or 12) end
  end
  local count = 0
  for i = 1, self.object_count do
    local object = self.objects[i]
    if object.active then
      count = count + 1
      local at = count
      while at > 1 and self.sort_depth[at - 1] < object.sort_z do self.sort_depth[at], self.sort_index[at] = self.sort_depth[at - 1], self.sort_index[at - 1]; at = at - 1 end
      self.sort_depth[at], self.sort_index[at] = object.sort_z, i
    end
  end
  for n = 1, count do
    local object = self.objects[self.sort_index[n]]
    local x, y, projected_size = self:project_road(object.x, object.z, object.size)
    local size = math.max(1, math.floor(projected_size))
    if x + size >= 0 and x - size < self.width and y + size >= self.horizon and y - size < self.height then
      rect(x - size / 2, y - size, size, size, object.color)
    end
  end
end

function methods.clear(self) methods.clear_objects(self); self.camera_z = 0 end
