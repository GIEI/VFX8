pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- VFX8 compact showcase for core effects.
#include ../../src/pico8/particles.lua
#include ../../src/pico8/screen_fx.lua
#include ../../src/pico8/pixel_deform.lua
#include ../../src/pico8/palette_fx.lua

local names={"particles","screen fx","pixel warp","palette fx"}
local quality_names={"low","medium","high"}
local selected,quality,tick=1,1,0
local system=nil
local particle_preset,shape="explosion",1
local preset_names={"explosion","sparks","trail","smoke","dust"}
local particle_mode=1
local rotate_grid=false
local wave_time=0
local wave_samples_x,wave_samples_y={},{}
local palette_mode=1
local palette_names={"color cycle","night filter","sepia filter","mono filter","glow pulse","negative flash"}
local colors={{0,0,0},{0.114,0.169,0.325},{0.494,0.145,0.325},{0,0.529,0.318},{0.671,0.322,0.212},{0.373,0.341,0.31},{0.761,0.765,0.78},{1,0.945,0.91},{1,0.004,0.278},{1,0.639,0},{1,0.925,0.153},{0,0.894,0.165},{0.161,0.678,1},{0.514,0.463,0.616},{1,0.467,0.659},{1,0.8,0.667}}
local function exit_effect()
 if system and system.clear then system:clear() end
 system=nil
end
local function enter_effect()
 exit_effect()
 if selected==1 then system=vfx8_particles.new({quality=quality_names[quality]})
 elseif selected==2 then system=vfx8_screen_fx.new({width=128,height=128,capacity=quality==3 and 8 or 4})
 elseif selected==3 then system=vfx8_pixel_deform.new({quality=quality_names[quality]}); rotate_grid=false
 else
  system=vfx8_palette_fx.new({quality=quality_names[quality],color_count=16})
  system:set_invert_palette(colors)
  system:set_cycle(8,11,2)
 end
end
local function map_color(i) if selected==4 and system then return system:map_color(i) end return i end
local function cache_waves()
 if selected~=3 then return end
 wave_time=(tick%120)/60
 for y=28,108,8 do wave_samples_x[y]=system:wave_offset(y,wave_time,3.5,48,0.5) end
 for x=0,128,8 do wave_samples_y[x]=system:wave_offset(x,wave_time,2.5,48,0.5) end
end
function _init() enter_effect() end
function _update60()
 tick+=1
 if btnp(0) then selected=(selected+2)%4+1; enter_effect() end
 if btnp(1) then selected=selected%4+1; enter_effect() end
 if btnp(2) then quality=quality%3+1; enter_effect() end
 if btnp(3) then quality=(quality+1)%3+1; enter_effect() end
 if btnp(4) then
  if selected==1 then
   if shape==2 then system:emit_line(particle_preset,52,64,76,64,{spread=2})
   elseif shape==3 then system:emit_area(particle_preset,54,58,20,12)
   else system:emit(particle_preset,64,64) end
  elseif selected==2 then system:add_trauma(0.8); system:impulse(3,1,0.18); system:flash(0.06,7); system:shockwave(64,64,2,8,0.28)
  elseif selected==3 then system:set_squash(1.35,0.68,0.3)
  elseif palette_mode==6 then system:invert(0.18) else system:flash(8,11,7,0.18) end
 end
 if btnp(5) then
  if selected==1 then
   particle_mode=particle_mode%15+1
   particle_preset=preset_names[flr((particle_mode-1)/3)+1]
   shape=(particle_mode-1)%3+1
  elseif selected==2 then system:add_trauma(0.25)
  elseif selected==3 then rotate_grid=not rotate_grid
  else
   palette_mode=palette_mode%6+1; system:clear_cycle(); system:clear_filter(); system:clear_invert(); system:set_pulse(-1,-1,0)
   if palette_mode==1 then system:set_cycle(8,11,2)
   elseif palette_mode==2 then system:set_filter("night")
   elseif palette_mode==3 then system:set_filter("sepia")
   elseif palette_mode==4 then system:set_filter("mono")
   elseif palette_mode==5 then system:set_pulse(8,10,4) end
  end
 end
 system:update(1/60)
 cache_waves()
end
local function deform_point(x,y)
 return system:rotate_point(x+(wave_samples_x[y] or 0),y+(wave_samples_y[x] or 0))
end
local function grid()
 cls(map_color(1)); rectfill(0,28,127,103,map_color(2)); clip(0,28,128,76)
 local actor_x=24+tick%80
 if selected==3 then
  system:set_rotation(actor_x,64,rotate_grid and (tick%180)*0.035 or 0)
  for x=0,128,16 do for y=28,100,8 do
   local x1,y1=deform_point(x,y); local x2,y2=deform_point(x,y+8)
   line(x1,y1,x2,y2,map_color(13))
  end end
  for y=28,104,16 do for x=0,120,8 do
   local x1,y1=deform_point(x,y); local x2,y2=deform_point(x+8,y)
   line(x1,y1,x2,y2,map_color(13))
  end end
 else
  for x=0,128,16 do line(x,28,x,103,map_color(13)) end
  for y=28,104,16 do line(0,y,127,y,map_color(13)) end
 end
 rectfill(0,96,127,103,map_color(3)); clip()
 rectfill(actor_x-3,61,actor_x+3,67,map_color(8)); line(59,64,69,64,map_color(7)); line(64,59,64,69,map_color(7))
end
function _draw()
 if selected==2 then system:render(grid) else grid() end
 if selected==1 then system:draw() elseif selected==4 and palette_mode==1 then
  local c=({8,9,10,11})[1+tick%4]; circfill(100,64,5,c)
 end
 rectfill(0,0,127,27,0); print("vfx8 core demo",2,2,7); print(names[selected],2,9,10)
 local label=selected==1 and (particle_preset.." / "..({"point","line","area"})[shape]) or (selected==3 and (rotate_grid and "wave + line rotation" or "wave only") or (selected==4 and palette_names[palette_mode] or "trauma shake + distortion"))
 print(label,2,17,7); print(quality_names[quality].."  O: trigger",2,25,6)
 rectfill(0,105,127,127,0); print("READY",2,108,11); print("< > effect  ^ v quality",2,117,7); print("X: variant / preset",2,124,7)
end
