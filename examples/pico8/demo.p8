pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- vfx8 demo harness; effects are loaded from demo_extension.lua.
-- pico-8 expands this at cartridge boot, like a c-style include.
#include demo_extension.lua
#include ../../src/pico8/particles.lua
#include ../../src/pico8/screen_fx.lua
#include ../../src/pico8/pixel_deform.lua
#include ../../src/pico8/palette_fx.lua
#include ../../src/pico8/pseudo3d.lua
#include ../../src/pico8/flames.lua
#include ../../src/pico8/electricity.lua

names={"particles","screen fx","pixel warp","palette fx","pseudo 3d","flames","electricity"}
qualities={"low","medium","high"}
selected=1
quality=1
fx_enabled=true
active=nil
tick=0
wave_time=0
wave_samples={}

function scene_color(index)
 if active and active.map_color then return active.map_color(index) end
 return index
end

function refresh_fx()
 if active and active.on_exit then active.on_exit() end
 active=nil
 if fx_enabled then
  active=fx[selected]
  if active and active.on_enter then
   active.on_enter(qualities[quality])
  end
 end
end

function _init()
 refresh_fx()
end

function _update60()
 tick=(tick+1)%240
 wave_time+=1/60
 if btnp(0) then
  selected=(selected+5)%7+1
  refresh_fx()
 end
 if btnp(1) then
  selected=selected%7+1
  refresh_fx()
 end
 if btnp(2) then
  quality=quality%3+1
  refresh_fx()
 end
 if btnp(3) then
  quality=(quality+1)%3+1
  refresh_fx()
 end
 if btnp(4) and active and active.trigger then active.trigger(64,67) end
 if btnp(5) and active then
  if active.cycle_variant then active.cycle_variant()
  elseif active.cycle_preset then active.cycle_preset() end
 end
 if active and active.update then active.update(1/60) end
end

function draw_scene()
 local x=24+tick%80
 if active and active.prepare_rotation then active.prepare_rotation(wave_time,x,67) end
 local rotating=active and active.rotation_enabled and active.rotation_enabled()
 local min_x,min_y,max_x,max_y=0,28,127,103
 if rotating then min_x,min_y,max_x,max_y=active.rotation_bounds(0,28,127,103,8) end
 local grid_x,grid_y=flr(min_x/16)*16,28+flr((min_y-28)/16)*16
 local wave_x=flr(min_x/4)*4
 local wave_count=flr((max_x-wave_x+3)/4)
 cls(scene_color(1))
 rectfill(0,28,127,103,scene_color(2))
 clip(0,28,128,76)
 for gx=grid_x,max_x,16 do
  local x1,y1=gx,min_y
  local x2,y2=gx,max_y
  if rotating then x1,y1=active.rotate_point(x1,y1); x2,y2=active.rotate_point(x2,y2) end
  line(x1,y1,x2,y2,scene_color(13))
 end
 if active and active.wave_offset then
  for i=0,wave_count do wave_samples[i]=active.wave_offset(wave_x+i*4,wave_time) end
 end
 for y=grid_y,max_y,16 do
  if active and active.wave_offset then
   for i=0,wave_count-1 do
    local x1,y1=wave_x+i*4,y+wave_samples[i]
    local x2,y2=x1+4,y+wave_samples[i+1]
    if rotating then x1,y1=active.rotate_point(x1,y1); x2,y2=active.rotate_point(x2,y2) end
    line(x1,y1,x2,y2,scene_color(13))
   end
  else
   local x1,y1,x2,y2=min_x,y,max_x,y
   if rotating then x1,y1=active.rotate_point(x1,y1); x2,y2=active.rotate_point(x2,y2) end
   line(x1,y1,x2,y2,scene_color(13))
  end
 end
 clip()
 rectfill(0,96,127,103,scene_color(3))
 if active and active.scale then
  local sx,sy=active.scale()
  local w,h=flr(7*sx),flr(7*sy)
  local px,py=x-3+(7-w)/2,64+(7-h)/2
  for iy=0,h-1 do for ix=0,w-1 do
   if active.visible(px+ix,py+iy,(tick%120)/120) then
    rectfill(px+ix,py+iy,px+ix,py+iy,scene_color(8))
   end
  end end
 else rectfill(x-3,64,x+3,70,scene_color(8)) end
 local x1,y1,x2,y2=59,67,69,67
 line(x1,y1,x2,y2,scene_color(7))
 x1,y1,x2,y2=64,62,64,72
 line(x1,y1,x2,y2,scene_color(7))
end

function _draw()
 if active and active.draw_scene then
  active.draw_scene()
 elseif active and active.render_scene then
  active.render_scene(draw_scene)
 else
  draw_scene()
 end
 if active and active.draw then active.draw() end
 rectfill(0,0,127,27,0)
 print("vfx8 demo",2,2,7)
 print(names[selected],2,9,10)
 if active and active.label then print(active.label(),2,25,11) end
 print("q:"..qualities[quality].." fx:"..(fx_enabled and "on" or "off"),2,17,7)
 rectfill(0,105,127,127,0)
 local status=not fx_enabled and "fx disabled" or (active and "ready" or "not implemented")
 print(status,2,107,active and 11 or 6)
 print("<>:fx ^v:q",2,115,7)
 print("o:fire x:variant/preset",2,122,7)
end
