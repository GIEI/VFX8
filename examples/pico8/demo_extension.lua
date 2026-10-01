-- Adapt the particle module to the shared demo controls.
fx={}
local particles=nil
local preset="explosion"
local shape="point"
local presets={"explosion","sparks","trail","smoke","dust"}
local shapes={"point","line","area"}
fx[1]={
 on_enter=function(q) particles=vfx8_particles.new({quality=q}) end,
 on_exit=function() if particles then particles:clear() end end,
 trigger=function(x,y)
  if not particles then return end
  if shape=="line" then particles:emit_line(preset,x-12,y,x+12,y,{spread=2})
  elseif shape=="area" then particles:emit_area(preset,x-10,y-6,20,12)
  else particles:emit(preset,x,y) end
 end,
 update=function(dt) if particles then particles:update(dt) end end,
 draw=function() if particles then particles:draw() end end,
 cycle_preset=function()
  for i=1,5 do if presets[i]==preset then preset=presets[i%5+1] return end end
 end,
 cycle_shape=function()
  for i=1,3 do if shapes[i]==shape then shape=shapes[i%3+1] return end end
 end,
 label=function() return preset.." / "..shape end
}
