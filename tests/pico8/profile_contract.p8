pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- Exercise each effect through setup, update, and rendering at every quality profile.
#include ../../examples/pico8/demo_extension.lua
#include ../../src/pico8/particles.lua
#include ../../src/pico8/screen_fx.lua
#include ../../src/pico8/pixel_deform.lua
#include ../../src/pico8/palette_fx.lua
#include ../../src/pico8/pseudo3d.lua
#include ../../src/pico8/flames.lua
#include ../../src/pico8/electricity.lua

local qualities={"low","medium","high"}
local quality_index=1
local slot_index=0
local frames_in_slot=0
local active_fx=nil
local completed=0
local elapsed=0
local cpu_count=0
local cpu_sum=0
local cpu_min=1
local cpu_max=0

function scene_color(index)
 if slot_index==4 then return fx[4].map_color(index) end
 return index
end

function profile_scene()
 cls(1)
 rectfill(0,32,127,95,scene_color(2))
 line(0,32,127,95,scene_color(13))
end

function enter_profile_slot()
 if quality_index>#qualities then
  assert(completed==24,"not all profile/effect scenarios completed")
  active_fx=nil
  print("PROFILE CONTRACT PASSED",2,2,11)
  return
 end
 if slot_index==0 then
  active_fx=nil
  frames_in_slot=0
  cpu_count=0
  cpu_sum=0
  cpu_min=1
  cpu_max=0
  return
 end
 active_fx=fx[slot_index]
 assert(active_fx,"effect slot missing")
 assert(active_fx.on_enter and active_fx.update,"effect lifecycle missing")
 active_fx.on_enter(qualities[quality_index])
 if slot_index==4 then for i=1,6 do active_fx.cycle_variant() end end
 if active_fx.trigger then active_fx.trigger(64,64) end
 frames_in_slot=0
 cpu_count=0
 cpu_sum=0
 cpu_min=1
 cpu_max=0
end

function _init()
 enter_profile_slot()
end

function _update60()
 elapsed+=1/60
 if quality_index>#qualities then return end
 if active_fx then active_fx.update(1/60) end
 if slot_index==3 then
  active_fx.prepare_rotation(elapsed,64,64)
  local x,y=active_fx.rotate_point(72,64)
  assert(type(x)=="number" and type(y)=="number")
  local sx,sy=active_fx.scale()
  assert(sx>0 and sy>0)
  active_fx.visible(64,64,0.5)
 elseif slot_index==4 then
  assert(active_fx.map_color(8)>=0)
 end
 frames_in_slot+=1
 if frames_in_slot>=13 then
  printh("VFX8_CPU,"..qualities[quality_index]..","..(slot_index==0 and "base" or slot_index)..","..cpu_count..","..cpu_sum/max(1,cpu_count)..","..cpu_min..","..cpu_max)
  if active_fx and active_fx.on_exit then active_fx.on_exit() end
  completed+=1
  slot_index+=1
  if slot_index>7 then slot_index=0; quality_index+=1 end
  enter_profile_slot()
 end
end

function _draw()
 if quality_index>#qualities then
  print("PROFILE CONTRACT PASSED",2,2,11)
  return
 end
 cls(0)
 if slot_index==0 then profile_scene()
 elseif slot_index==1 then profile_scene(); active_fx.draw()
 elseif slot_index==2 then active_fx.render_scene(profile_scene)
 elseif slot_index==3 then profile_scene()
 elseif slot_index==4 then profile_scene()
 elseif slot_index==5 then active_fx.draw_scene()
 elseif slot_index==6 or slot_index==7 then active_fx.draw() end
 print(qualities[quality_index].." / fx "..slot_index,2,2,7)
 if frames_in_slot>2 then
  local cpu=stat(1)
  cpu_count+=1
  cpu_sum+=cpu
  cpu_min=min(cpu_min,cpu)
  cpu_max=max(cpu_max,cpu)
 end
end
