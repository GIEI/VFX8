pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- VFX8 pseudo-3D showcase for PICO-8.
#include ../../src/pico8/pseudo3d.lua

local effect_name="pseudo3d"
local quality_names={"low","medium","high"}
local quality=1
local tick=0
local road=nil
local curved=true
local colors={sky=1,ground=3,road_a=1,road_b=13,edge=11,stars={7,6,5}}
local function prepare_texture()
 for y=0,7 do for x=0,7 do
  local c=((flr(x/2)+flr(y/2))%2==0) and 5 or 6
  if x==0 or y==0 then c=13 end
  sset(8+x,y,c)
 end end
 for y=0,15 do for x=0,15 do mset(x,y,1) end end
end
local function reset_road()
 if road then road:clear() end
 prepare_texture()
 road=vfx8_pseudo3d.new({quality=quality_names[quality],width=128,height=96,horizon=34,lane_count=3})
 if road.set_mode7 then road:set_mode7({width_tiles=16,height_tiles=16,scale=0.55}) end
end
function _init() reset_road() end
function _update60()
 tick+=1
 if btnp(2) then quality=quality%3+1; reset_road() end
 if btnp(3) then quality=(quality+1)%3+1; reset_road() end
 if btnp(4) then road:add_object(((road.object_count%3)-1)*0.48,100,11,4) end
 if btnp(5) then curved=not curved; road:set_camera(road.camera_x==0 and 10 or 0,nil,road.speed==18 and 30 or 18) end
 road:set_road(nil,nil,curved and sin(tick/150)*0.55 or 0)
 road:update(1/60)
end
function _draw()
 road:draw(colors)
 rectfill(0,0,127,26,0); print("VFX8 "..effect_name,3,3,7)
 print("MODE 7 / STARS / OBJECTS",3,13,12)
 print(quality_names[quality].."  O: ADD OBJECT",3,23,6)
 rectfill(0,108,127,127,0); print("X: CAMERA / ROAD",3,116,7)
end
