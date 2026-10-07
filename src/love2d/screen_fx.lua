-- VFX8 screen effects for LÖVE.
-- Copy this module into your project as vfx8/screen_fx.lua.

local screen_fx = {}
local methods, empty_options = {}, {}
local white = {1, 1, 1}
local ripple_shader_source = [[
extern vec2 ringCenter;
extern vec2 resolution;
extern float ringRadius;
extern float ringWidth;
extern float ringStrength;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
  vec2 pixel = texture_coords * resolution;
  vec2 delta = pixel - ringCenter;
  float distanceFromCenter = length(delta);
  float ringDistance = distanceFromCenter - ringRadius;
  float envelope = exp(-abs(ringDistance) / max(ringWidth, 1.0));
  float displacement = sin(ringDistance * 0.75 + 1.5707963) * envelope * ringStrength;
  vec2 direction = delta / max(distanceFromCenter, 0.001);
  vec2 samplePoint = texture_coords + direction * displacement / resolution;
  return Texel(texture, samplePoint) * color;
}
]]

function screen_fx.new(options)
  options = options or empty_options
  return {
    width = options.width or 240, height = options.height or 136,
    viewport = options.viewport,
    capacity = math.max(1, math.min(64, math.floor(options.capacity or 8))),
    trauma = 0, shake_x = 0, shake_y = 0, shake_time = 0,
    shake_legacy = options.shake_intensity == nil and options.shake_decay == nil and options.shake_frequency == nil and options.shake_randomness == nil and options.shake_envelope == nil,
    shake_intensity = options.shake_intensity or 8, shake_decay = options.shake_decay or 2.5,
    shake_frequency = options.shake_frequency or 60, shake_randomness = options.shake_randomness == nil and 1 or options.shake_randomness,
    shake_envelope = options.shake_envelope or "linear", shake_direction_x = 0, shake_direction_y = 0,
    shake_phase = 0, shake_noise_x = 0, shake_noise_y = 0,
    offset_x = 0, offset_y = 0,
    shake_duration = 0, flash_time = 0, flash_duration = 0, flash_intensity = 1, flash_mode = "color",
    flash_color = options.flash_color or white, waves = {}, wave_count = 0,
    ripple_enabled = options.ripple ~= false,
    ripple_strength = math.max(0, options.ripple_strength or 4),
    ripple_width = math.max(1, options.ripple_width or 8),
    ripple_canvas = nil, ripple_shader = nil, ripple_supported = nil,
    ripple_canvas_width = 0, ripple_canvas_height = 0,
    ripple_center = {0, 0}, ripple_resolution = {0, 0},
    seed = options.seed or 1, update = methods.update,
    add_trauma = methods.add_trauma, impulse = methods.impulse,
    flash = methods.flash, shockwave = methods.shockwave,
    get_shake_offset = methods.get_shake_offset, draw_overlays = methods.draw_overlays,
    render = methods.render, clear = methods.clear
  }
end

function methods.add_trauma(self, amount, options)
  options = options or empty_options
  if options.intensity ~= nil or options.decay ~= nil or options.frequency ~= nil or options.randomness ~= nil or options.envelope ~= nil then self.shake_legacy = false end
  self.trauma = math.min(1, self.trauma + math.max(0, amount or 0))
  self.shake_duration = math.max(self.shake_duration, 0.35)
  self.shake_time = math.max(self.shake_time, self.shake_duration)
  self.shake_intensity = options.intensity or self.shake_intensity
  self.shake_decay, self.shake_frequency = options.decay or self.shake_decay, options.frequency or self.shake_frequency
  self.shake_randomness = options.randomness == nil and self.shake_randomness or options.randomness
  self.shake_envelope = options.envelope or self.shake_envelope
end

function methods.impulse(self, x, y, duration, options)
  options = options or empty_options
  if options.intensity ~= nil or options.decay ~= nil or options.frequency ~= nil or options.randomness ~= nil or options.envelope ~= nil or options.direction_x ~= nil or options.direction_y ~= nil then self.shake_legacy = false end
  self.shake_x, self.shake_y = x or 0, y or 0
  self.shake_direction_x, self.shake_direction_y = options.direction_x or 0, options.direction_y or 0
  self.shake_intensity, self.shake_decay = options.intensity or 8, options.decay or 2.5
  self.shake_frequency, self.shake_randomness = options.frequency or 60, options.randomness == nil and 1 or options.randomness
  self.shake_envelope = options.envelope or "linear"
  self.trauma = math.max(self.trauma, 1)
  self.shake_duration = math.max(0.001, duration or 0.12)
  self.shake_time = self.shake_duration
end

function methods.flash(self, duration, color, options)
  options = options or empty_options
  self.flash_duration = math.max(0.001, duration or 0.08)
  self.flash_time = self.flash_duration
  self.flash_color = color or options.color or white
  self.flash_intensity = options.intensity == nil and 1 or math.max(0, math.min(1, options.intensity))
  self.flash_mode = options.mode or "color"
end

function methods.shockwave(self, x, y, radius, strength, duration, options)
  options = options or empty_options
  if self.wave_count >= self.capacity then return false end
  local i = self.wave_count + 1
  local wave = self.waves[i] or {}
  wave.x, wave.y = options.center_x or x, options.center_y or y
  wave.radius, wave.strength = radius or 0, strength or 8
  wave.age, wave.life = 0, math.max(0.05, duration or 0.3)
  wave.max_radius = options.max_radius or wave.radius + (options.speed or ((strength or 8) * 8 / wave.life)) * wave.life
  wave.thickness, wave.falloff = math.max(1, options.thickness or 1), math.max(0.1, options.falloff or 1)
  self.waves[i], self.wave_count = wave, i
  if self.ripple_enabled and self.ripple_supported == nil then methods._create_ripple_resources(self) end
  return true
end

function methods._create_ripple_resources(self)
  local graphics = love.graphics
  if not graphics.newCanvas or not graphics.newShader then self.ripple_supported = false; return false end
  local canvas_ok, canvas = pcall(graphics.newCanvas, self.width, self.height)
  if not canvas_ok or not canvas then self.ripple_supported = false; return false end
  local shader_ok, shader = pcall(graphics.newShader, ripple_shader_source)
  if not shader_ok or not shader then self.ripple_supported = false; return false end
  self.ripple_canvas, self.ripple_shader = canvas, shader
  self.ripple_canvas_width, self.ripple_canvas_height = self.width, self.height
  self.ripple_supported = true
  return true
end

function methods.update(self, dt)
  dt = math.max(0, math.min(dt or 1 / 60, 0.1))
  self.trauma = math.max(0, self.trauma - dt * self.shake_decay)
  self.shake_time = math.max(0, self.shake_time - dt)
  self.flash_time = math.max(0, self.flash_time - dt)
  local nx, ny
  if self.shake_legacy then
    self.seed = (self.seed * 17 + 31) % 251
    nx = self.seed / 251 - 0.5
    self.seed = (self.seed * 17 + 31) % 251
    ny = self.seed / 251 - 0.5
  else
    self.shake_phase = self.shake_phase + dt * self.shake_frequency
    if self.shake_frequency >= 60 or self.shake_phase >= 1 then
      self.seed = (self.seed * 17 + 31) % 251
      self.shake_noise_x = self.seed / 251 - 0.5
      self.seed = (self.seed * 17 + 31) % 251
      self.shake_noise_y = self.seed / 251 - 0.5
      self.shake_phase = self.shake_phase % 1
    end
  end
  local trauma = self.trauma * self.trauma
  local decay = self.shake_duration > 0 and self.shake_time / self.shake_duration or 0
  if self.shake_envelope == "trapezoid" then decay = math.min(1, (1 - decay) * 4, decay * 4) end
  if self.shake_envelope == "smooth" then decay = decay * decay * (3 - 2 * decay) end
  if self.shake_legacy then
    self.offset_x = (self.shake_x + nx * 8) * trauma * decay
    self.offset_y = (self.shake_y + ny * 8) * trauma * decay
  else
    self.offset_x = (self.shake_x + self.shake_direction_x + self.shake_noise_x * self.shake_intensity * self.shake_randomness) * trauma * decay
    self.offset_y = (self.shake_y + self.shake_direction_y + self.shake_noise_y * self.shake_intensity * self.shake_randomness) * trauma * decay
  end
  local i = 1
  while i <= self.wave_count do
    local wave = self.waves[i]
    wave.age = wave.age + dt
    if wave.age >= wave.life then
      self.waves[i], self.waves[self.wave_count] = self.waves[self.wave_count], wave
      self.wave_count = self.wave_count - 1
    else i = i + 1 end
  end
end

function methods.get_shake_offset(self)
  return self.offset_x, self.offset_y
end

function methods.draw_overlays(self)
  local old_r, old_g, old_b, old_a = love.graphics.getColor()
  for i = 1, self.wave_count do
    local wave = self.waves[i]
    local t = wave.age / wave.life
    local radius = wave.radius + (wave.max_radius - wave.radius) * (t ^ wave.falloff)
    love.graphics.setColor(0.75, 0.9, 1, 1 - t)
    for band = 0, wave.thickness - 1 do love.graphics.circle("line", wave.x, wave.y, radius - band) end
  end
  if self.flash_time > 0 and self.flash_intensity > 0 then
    local alpha = self.flash_time / self.flash_duration * self.flash_intensity
    local c = self.flash_color
    love.graphics.setColor(c[1], c[2], c[3], alpha)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)
  end
  love.graphics.setColor(old_r, old_g, old_b, old_a)
end

function methods._render_ripple(self, draw_scene)
  if not self.ripple_enabled or not self.ripple_supported or self.wave_count == 0 then return false end
  local graphics = love.graphics
  if not graphics.getCanvas or not graphics.transformPoint then return false end
  local target_canvas, second_canvas = graphics.getCanvas()
  if second_canvas ~= nil then return false end
  local width, height
  if target_canvas then width, height = target_canvas:getDimensions()
  else width, height = graphics.getDimensions() end
  if width ~= self.ripple_canvas_width or height ~= self.ripple_canvas_height then
    local ok, canvas = pcall(graphics.newCanvas, width, height)
    if not ok or not canvas then self.ripple_supported = false; return false end
    self.ripple_canvas = canvas
    self.ripple_canvas_width, self.ripple_canvas_height = width, height
  end

  graphics.push("all")
  graphics.setCanvas(self.ripple_canvas)
  graphics.clear(0, 0, 0, 0)
  graphics.translate(math.floor(self.offset_x + 0.5), math.floor(self.offset_y + 0.5))
  local ok, draw_error = pcall(draw_scene)
  if not ok then
    if target_canvas then graphics.setCanvas(target_canvas) else graphics.setCanvas() end
    graphics.pop()
    error(draw_error, 0)
  end
  local wave = self.waves[self.wave_count]
  local t = wave.age / wave.life
  local center_x, center_y = graphics.transformPoint(wave.x, wave.y)
  local edge_x, edge_y = graphics.transformPoint(wave.x + 1, wave.y)
  local scale = math.sqrt((edge_x - center_x) ^ 2 + (edge_y - center_y) ^ 2)
  local radius = (wave.radius + (wave.max_radius - wave.radius) * (t ^ wave.falloff)) * scale
  if target_canvas then graphics.setCanvas(target_canvas) else graphics.setCanvas() end
  graphics.origin()
  graphics.setShader(self.ripple_shader)
  self.ripple_center[1], self.ripple_center[2] = center_x, center_y
  self.ripple_resolution[1], self.ripple_resolution[2] = width, height
  self.ripple_shader:send("ringCenter", self.ripple_center)
  self.ripple_shader:send("resolution", self.ripple_resolution)
  self.ripple_shader:send("ringRadius", radius)
  self.ripple_shader:send("ringWidth", math.max(self.ripple_width, wave.thickness) * scale)
  self.ripple_shader:send("ringStrength", self.ripple_strength * scale * (1 - t))
  graphics.setColor(1, 1, 1, 1)
  graphics.setBlendMode("alpha", "premultiplied")
  graphics.draw(self.ripple_canvas, 0, 0)
  graphics.pop()
  methods.draw_overlays(self)
  return true
end

function methods.render(self, draw_scene)
  local graphics = love.graphics
  local previous_scissor
  if self.viewport and graphics.getScissor and graphics.setScissor then
    previous_scissor = {graphics.getScissor()}
    graphics.setScissor(self.viewport.x or 0, self.viewport.y or 0,
      self.viewport.width or self.width, self.viewport.height or self.height)
  end
  if not methods._render_ripple(self, draw_scene) then
    graphics.push()
    graphics.translate(math.floor(self.offset_x + 0.5), math.floor(self.offset_y + 0.5))
    draw_scene()
    graphics.pop()
    methods.draw_overlays(self)
  end
  if previous_scissor then
    if previous_scissor[1] then graphics.setScissor(previous_scissor[1], previous_scissor[2], previous_scissor[3], previous_scissor[4])
    else graphics.setScissor() end
  end
end

function methods.clear(self)
  self.trauma, self.shake_time, self.flash_time, self.wave_count = 0, 0, 0, 0
  self.offset_x, self.offset_y = 0, 0
end

return screen_fx
