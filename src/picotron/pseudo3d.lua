-- VFX8 bounded pseudo-3D helpers for Picotron.
-- Include this file once; it defines vfx8_pseudo3d.

vfx8_pseudo3d = vfx8_pseudo3d or {}
local methods = {}
local empty_colors = {}
local profiles = {low = {rows = 20, stars = 24, objects = 8}, medium = {rows = 36, stars = 48, objects = 16}, high = {rows = 56, stars = 80, objects = 32}}

function vfx8_pseudo3d.new(options)
  options = options or {}
  local profile = profiles[options.quality or "low"] or profiles.low
  local width, height = options.width or 240, options.height or 136
  local count = min(160, max(0, flr(options.star_count or profile.stars)))
  local capacity = min(64, max(1, flr(options.object_capacity or profile.objects)))
  local self = {width = width, height = height, horizon = options.horizon or 48,
    camera_height = options.camera_height or 52, road_width = options.road_width or 96,
    camera_x = 0, camera_z = 0, speed = options.speed or 18,
    perspective = options.perspective or 0.62, star_speed = options.star_speed or 1,
    star_parallax = options.star_parallax or 0.08, star_layers = min(3, max(1, flr(options.star_layers or 3))),
    star_near = options.star_near or 8, star_far = options.star_far or 127,
    star_seed = options.star_seed or 0, custom_star_depth = options.star_near ~= nil or options.star_far ~= nil, mode7_time = 0,
    curve = options.curve or 0, curve_strength = options.curve_strength or width * 0.32,
    mode7 = nil, mode7_angle = options.mode7_angle or 0,
    lane_count = min(8, max(1, flr(options.lane_count or 3))), rows = profile.rows,
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
  if horizon ~= nil then self.horizon = max(0, min(self.height - 2, horizon)) end
  if speed ~= nil then self.speed = speed end
  if curve ~= nil then self.curve = curve end
end

function methods.set_road(self, width, lanes, curve, curve_strength)
  if width ~= nil then self.road_width = max(1, width) end
  if lanes ~= nil then self.lane_count = min(8, max(1, flr(lanes))) end
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
  local width = mode7_power2(math.max(8, math.min(1024, math.floor(texture.width or 128))))
  local height = mode7_power2(math.max(8, math.min(1024, math.floor(texture.height or 128))))
  self.mode7 = {source = texture.source, width = width, height = height,
    scale = options.scale or texture.scale or 0.08, offset_x = texture.offset_x or 0, offset_y = texture.offset_y or 0,
    scroll_speed_x = options.scroll_speed_x or texture.scroll_speed_x or 0,
    scroll_speed_y = options.scroll_speed_y or texture.scroll_speed_y or 0,
    high_quality = texture.high_quality == true}
  if options.angle ~= nil then self.mode7_angle = options.angle
  elseif texture.angle ~= nil then self.mode7_angle = texture.angle end
  return true
end

function methods.project_road(self, lateral, z, size)
  local safe_z = max(2.1, z or 60)
  local scale = self.camera_height / safe_z
  local y = self.horizon + scale * self.camera_height * self.perspective
  local vertical = max(0, y - self.horizon)
  local depth = max(0, min(1, 1 - vertical / max(1, self.height - self.horizon)))
  local half = self.road_width * vertical / self.camera_height
  local bend = self.curve * self.curve_strength * depth * depth
  local x = self.width * 0.5 + (lateral or 0) * half - self.camera_x * depth + bend
  return x, y, (size or 1) * scale
end

function methods.update(self, dt)
  dt = max(0, min(0.1, dt or 1 / 60))
  self.camera_z = self.camera_z + self.speed * dt
  self.mode7_time = self.mode7_time + dt
  for i = 1, self.star_count do
    local star = self.stars[i]
    star.z = star.z - self.speed * self.star_speed * dt * (0.45 + star.layer * 0.35)
    if star.z < 2 then
      local seed = flr(self.camera_z)
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
  object.x, object.z, object.color = x or 0, max(2.1, z or 60), color or 11
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
  local horizon = max(0, min(self.height - 2, flr(self.horizon)))
  local old_x, old_y = peek2(0x5530), peek2(0x5532)
  local old_w, old_h = peek2(0x5534), peek2(0x5536)
  local angle = self.mode7_angle
  local cosine, sine = math.cos(angle), math.sin(angle)
  local flags = texture.high_quality and 0x400 or 0
  poke2(0x5530, texture.offset_x); poke2(0x5532, texture.offset_y)
  poke2(0x5534, texture.width); poke2(0x5536, texture.height)
  for y = horizon + 1, self.height - 1 do
    local vertical = y - horizon
    local distance = self.camera_height * self.camera_height * self.perspective / vertical
    local lateral = distance / self.camera_height
    local center_u = (self.camera_x + distance * sine + self.mode7_time * texture.scroll_speed_x) * texture.scale
    local center_v = (self.camera_z + distance * cosine + self.mode7_time * texture.scroll_speed_y) * texture.scale
    local du, dv = lateral * cosine * texture.scale, -lateral * sine * texture.scale
    local u0, v0 = center_u - self.width * 0.5 * du, center_v - self.width * 0.5 * dv
    tline3d(texture.source, 0, y, self.width - 1, y, u0, v0,
      u0 + du * (self.width - 1), v0 + dv * (self.width - 1), 1, 1, flags)
  end
  poke2(0x5530, old_x); poke2(0x5532, old_y)
  poke2(0x5534, old_w); poke2(0x5536, old_h)
end

function methods.project(self, x, z, size)
  local scale = self.camera_height / max(2.1, z or 60)
  return self.width * 0.5 + ((x or 0) - self.camera_x) * scale,
    self.horizon + scale * self.camera_height * self.perspective, (size or 1) * scale
end

function methods.draw(self, colors)
  colors = colors or empty_colors
  local sky, road_a, road_b, edge, ground = colors.sky or 1, colors.road_a or 1, colors.road_b or 13, colors.edge or 11, colors.ground or 3
  local cx = self.width * 0.5
  cls(sky)
  if self.mode7 then draw_mode7(self)
  else rectfill(0, self.horizon, self.width - 1, self.height - 1, ground) end
  if not self.mode7 then for row = 1, self.rows do
    if self.horizon + row < self.height then
      local y = self.horizon + flr((row - 1) * (self.height - self.horizon) / self.rows) + 1
      local next_y = min(self.height - 1, self.horizon + flr(row * (self.height - self.horizon) / self.rows))
      if next_y < y then next_y = y end
      local distance = y - self.horizon
      local depth = max(0, min(1, 1 - distance / (self.height - self.horizon)))
      local half = min(self.width * 1.5, self.road_width * distance / self.camera_height)
      local shift = self.camera_x * depth + self.curve * self.curve_strength * depth * depth
      local left, right = cx - half - shift, cx + half - shift
      local x0, x1 = max(0, flr(left)), min(self.width - 1, flr(right))
      local c = (flr(self.camera_z / 8 + distance * 0.2) % 2 == 0) and road_a or road_b
      if x0 <= x1 then
        rectfill(x0, y, x1, next_y, c)
        if row % 3 == 0 then line(x0, y, x0, y, edge); line(x1, y, x1, y, edge) end
        if self.lane_count > 1 and row % 2 == 0 and flr(self.camera_z / 6 + distance * 0.12) % 2 == 0 then
          for lane = 1, self.lane_count - 1 do
            local lane_x = left + half * 2 * lane / self.lane_count
            rectfill(lane_x, y, lane_x + max(1, distance / self.camera_height * 4), next_y, edge)
          end
        end
      end
    end
  end end
  for i = 1, self.star_count do
    local star = self.stars[i]
    local scale = self.camera_height / star.z
    local x, y = cx + (star.x - self.camera_x * self.star_parallax) * scale, self.horizon + star.y * scale
    if x >= 0 and x < self.width and y >= 0 and y < self.horizon then pset(x, y, (colors.stars and colors.stars[star.layer + 1]) or 7) end
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
    local size = max(1, flr(projected_size))
    if x + size >= 0 and x - size < self.width and y + size >= self.horizon and y - size < self.height then
      rectfill(x - size / 2, y - size, x + size / 2, y, object.color)
    end
  end
end

function methods.clear(self) methods.clear_objects(self); self.camera_z = 0 end
