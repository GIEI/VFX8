pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- Exercise core effect profiles, variants, and draw paths.
#include ../../src/pico8/particles.lua
#include ../../src/pico8/screen_fx.lua
#include ../../src/pico8/pixel_deform.lua
#include ../../src/pico8/palette_fx.lua

local qualities={"low","medium","high"}
local presets={"explosion","sparks","trail","smoke","dust"}
local filters={"night","sepia","mono"}
local custom_map={0,1,1,2,3,4,5,6,2,3,5,4,1,2,3,6}
local palette_rgb={{0,0,0},{0.114,0.169,0.325},{0.494,0.145,0.325},{0,0.529,0.318},{0.671,0.322,0.212},{0.373,0.341,0.31},{0.761,0.765,0.78},{1,0.945,0.91},{1,0.004,0.278},{1,0.639,0},{1,0.925,0.153},{0,0.894,0.165},{0.161,0.678,1},{0.514,0.463,0.616},{1,0.467,0.659},{1,0.8,0.667}}
local directions={{2,0},{-2,0},{0,2},{0,-2}}
local modes={0,"checker"}
local passed=false

function _init()
 for q in all(qualities) do
  local particles=vfx8_particles.new({quality=q})
  assert(particles:emit("unknown",64,64)==0)
  for preset in all(presets) do
   assert(particles:emit(preset,64,64)>0); particles:update(1/60); particles:draw(); particles:clear()
   assert(particles:emit_line(preset,48,64,80,64)>0); particles:update(1/60); particles:draw(); particles:clear()
   assert(particles:emit_area(preset,52,56,24,16)>0); particles:update(1/60); particles:draw(); particles:clear()
  end

  local screen=vfx8_screen_fx.new({width=128,height=128})
  for direction in all(directions) do
   screen:add_trauma(0.5); screen:impulse(direction[1],direction[2],0.2); screen:flash(0.05,7)
   assert(screen:shockwave(64,64,2,8,0.2)); screen:update(1/60)
   screen:render(function() cls(0); rectfill(32,32,96,96,1) end)
   screen:clear()
  end

  local deform=vfx8_pixel_deform.new({quality=q})
  for angle in all({0,0.5,1}) do
   deform:set_squash(1.3,0.7,0.2); deform:set_rotation(64,64,angle); deform:update(1/60)
   local x,y=deform:rotate_point(70,64); assert(type(x)=="number" and type(y)=="number")
   local left,top,right,bottom=deform:rotation_bounds(0,0,128,128,4); assert(left<right and top<bottom)
   assert(type(deform:wave_offset(20,1,3,48,0.5))=="number")
   for mode in all(modes) do assert(type(deform:visible(64,64,0.5,mode))=="boolean") end
  end
  deform:clear()

  local palette=vfx8_palette_fx.new({quality=q,color_count=16})
  assert(palette:set_invert_palette(palette_rgb)); assert(palette:set_cycle(8,11,2))
  assert(not palette:set_filter("unknown"))
  for filter in all(filters) do assert(palette:set_filter(filter)); palette:update(1/60); assert(palette:map_color(8)>=0) end
  palette:clear_filter(); assert(palette:set_filter_map(custom_map)); palette:set_pulse(8,10,4)
  palette:flash(8,11,7,0.18); assert(palette:invert(0.18)); palette:update(1/60)
  assert(palette:map_color(8)>=0); palette:clear()
 end
 passed=true
 printh("VFX8_CORE_PROFILE_CONTRACT,PASS")
end

function _update60() end
function _draw() cls(0); print(passed and "CORE CONTRACT PASSED" or "CORE CONTRACT FAILED",2,2,passed and 11 or 8) end
