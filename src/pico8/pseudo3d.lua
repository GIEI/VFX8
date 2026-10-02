-- VFX8 bounded pseudo-3D helpers for PICO-8.
-- Include this file once; it defines vfx8_pseudo3d.

vfx8_pseudo3d = vfx8_pseudo3d or {}
local methods = {}
local empty_colors = {}
local profiles = {low = {rows = 10, stars = 8, objects = 3, mode7_width = 0.55}, medium = {rows = 16, stars = 14, objects = 6, mode7_width = 0.75}, high = {rows = 24, stars = 22, objects = 10, mode7_width = 1}}

function vfx8_pseudo3d.new(options)
  options = options or {}
  local quality = options.quality or "low"
  local profile = profiles[quality] or profiles.low
  local width, height = options.width or 128, options.height or 96
  local count = min(32, max(0, flr(options.star_count or profile.stars)))
  local capacity = min(16, max(1, flr(options.object_capacity or profile.objects)))
  local self = {width = width, height = height, horizon = options.horizon or 42,
    camera_height = options.camera_height or 40, road_width = options.road_width or 54,
    camera_x = 0, camera_z = 0, speed = options.speed or 18,
    curve = options.curve or 0, curve_strength = options.curve_strength or width * 0.32,
    mode7 = nil, mode7_angle = options.mode7_angle or 0,
    mode7_width = min(1, max(0.25, options.mode7_width or profile.mode7_width)),
    lane_count = min(6, max(1, flr(options.lane_count or 3))), rows = profile.rows,
    stars = {}, star_count = count, objects = {}, object_count = 0, object_capacity = capacity,
    sort_depth = {}, sort_index = {}, update = methods.update, draw = methods.draw,
    add_object = methods.add_object, clear_objects = methods.clear_objects,
    set_camera = methods.set_camera, set_road = methods.set_road,
    project = methods.project, project_road = methods.project_road,
    set_mode7 = methods.set_mode7, clear = methods.clear}
  for i = 1, count do self.stars[i] = {x = ((i * 73 % 127) / 63.5 - 1) * 48, y = -0.1 - (i * 47 % 127) / 127 * 0.9, z = 8 + i * 47 % 120, layer = i % 3} end
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
  if lanes ~= nil then self.lane_count = min(6, max(1, flr(lanes))) end
  if curve ~= nil then self.curve = curve end
  if curve_strength ~= nil then self.curve_strength = curve_strength end
end

function methods.set_mode7(self, texture)
  if texture == nil or texture == false then self.mode7 = nil; return end
  if type(texture) ~= "table" and texture ~= true then self.mode7 = nil; return false end
  texture = texture == true and {} or texture
  local requested_width = min(128, max(1, flr(texture.width_tiles or 16)))
  local requested_height = min(64, max(1, flr(texture.height_tiles or 16)))
  local width, height = 1, 1
  while width * 2 <= requested_width do width = width * 2 end
  while height * 2 <= requested_height do height = height * 2 end
  self.mode7 = {width_tiles = width, height_tiles = height,
    scale = texture.scale or 0.35, offset_x = texture.offset_x or 0, offset_y = texture.offset_y or 0,
    width_fraction = min(1, max(0.25, texture.width_fraction or self.mode7_width))}
  if texture.angle ~= nil then self.mode7_angle = texture.angle end
  return true
end

function methods.project_road(self, lateral, z, size)
  local safe_z = max(2.1, z or 60)
  local scale = self.camera_height / safe_z
  local y = self.horizon + scale * self.camera_height * 0.62
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
  for i = 1, self.star_count do
    local star = self.stars[i]
    star.z = star.z - self.speed * dt * (0.45 + star.layer * 0.35)
    if star.z < 2 then
      local seed = flr(self.camera_z)
      star.z = 100 + (i % 23) * 2
      star.x = (((i * 73 + seed) % 127) / 63.5 - 1) * 48
      star.y = -0.1 - (i * 47 % 127) / 127 * 0.9
    end
  end
  for i = self.object_count, 1, -1 do
    local object = self.objects[i]
    if object.active then object.z = object.z - self.speed * dt; if object.z <= 2 then object.active = false end end
  end
  while self.object_count > 0 and not self.objects[self.object_count].active do self.object_count = self.object_count - 1 end
end

function methods.add_object(self, x, z, color, size)
  local i = 1
  while i <= self.object_capacity and self.objects[i].active do i = i + 1 end
  if i > self.object_capacity then return false end
  local object = self.objects[i]
  object.x, object.z, object.color = x or 0, max(2.1, z or 60), color or 11
  object.size, object.active = size or 8, true
  if i > self.object_count then self.object_count = i end
  return true
end

function methods.clear_objects(self)
  for i = 1, self.object_count do self.objects[i].active = false end
  self.object_count = 0
end

local function draw_mode7(self, ground)
  local texture = self.mode7
  local horizon = max(0, min(self.height - 2, flr(self.horizon)))
  local old_flags = peek(0x5f36)
  local old_width, old_height = peek(0x5f38), peek(0x5f39)
  local old_offset_x, old_offset_y = peek(0x5f3a), peek(0x5f3b)
  local angle = self.mode7_angle or 0
  local cosine, sine = cos(angle), sin(angle)
  local uv_scale = texture.scale / 8
  local draw_width = max(1, flr(self.width * texture.width_fraction))
  local left = flr((self.width - draw_width) * 0.5)
  local right = left + draw_width - 1
  if draw_width < self.width then rectfill(0, horizon + 1, self.width - 1, self.height - 1, ground) end
  poke(0x5f36, bor(old_flags, 0x8))
  poke(0x5f38, texture.width_tiles); poke(0x5f39, texture.height_tiles)
  poke(0x5f3a, texture.offset_x); poke(0x5f3b, texture.offset_y)
  for y = horizon + 1, self.height - 1 do
    local vertical = y - horizon
    local distance = self.camera_height * self.camera_height * 0.62 / vertical
    local lateral = distance / self.camera_height
    local center_u = (self.camera_x + distance * sine) * uv_scale
    local center_v = (self.camera_z + distance * cosine) * uv_scale
    local du, dv = lateral * cosine * uv_scale, -lateral * sine * uv_scale
    local start_u = center_u + (left - self.width * 0.5) * du
    local start_v = center_v + (left - self.width * 0.5) * dv
    tline(left, y, right, y, start_u, start_v, du, dv)
  end
  poke(0x5f36, old_flags)
  poke(0x5f38, old_width); poke(0x5f39, old_height)
  poke(0x5f3a, old_offset_x); poke(0x5f3b, old_offset_y)
end

function methods.project(self, x, z, size)
  local scale = self.camera_height / max(2.1, z or 60)
  return self.width * 0.5 + ((x or 0) - self.camera_x) * scale,
    self.horizon + scale * self.camera_height * 0.62, (size or 1) * scale
end

function methods.draw(self, colors)
  colors = colors or empty_colors
  local sky, road_a, road_b, edge, ground = colors.sky or 1, colors.road_a or 1, colors.road_b or 13, colors.edge or 11, colors.ground or 3
  local cx = self.width * 0.5
  cls(sky)
  if self.mode7 then draw_mode7(self, ground)
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
        if self.lane_count > 1 and row % 3 == 0 and flr(self.camera_z / 6 + distance * 0.12) % 2 == 0 then
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
    local x, y = cx + (star.x - self.camera_x * 0.08) * scale, self.horizon + star.y * scale
    if x >= 0 and x < self.width and y >= 0 and y < self.horizon then pset(x, y, (colors.stars and colors.stars[star.layer + 1]) or 7) end
  end
  local count = 0
  for i = 1, self.object_count do
    local object = self.objects[i]
    if object.active then
      count = count + 1
      local at = count
      while at > 1 and self.sort_depth[at - 1] < object.z do self.sort_depth[at], self.sort_index[at] = self.sort_depth[at - 1], self.sort_index[at - 1]; at = at - 1 end
      self.sort_depth[at], self.sort_index[at] = object.z, i
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
