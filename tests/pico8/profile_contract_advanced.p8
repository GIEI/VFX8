pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- Exercise advanced effect profiles, variants, and draw paths.
#include ../../src/pico8/pseudo3d.lua
#include ../../src/pico8/flames.lua
#include ../../src/pico8/electricity.lua

local qualities={"low","medium","high"}
local colors={sky=1,ground=3,road_a=1,road_b=13,edge=11,stars={7,6,5}}
local passed=false
local function prepare_texture()
 for y=0,7 do for x=0,7 do
  sset(8+x,y,((flr(x/2)+flr(y/2))%2==0) and 5 or 6)
 end end
 for y=0,15 do for x=0,15 do mset(x,y,1) end end
end

function _init()
 prepare_texture()
 for q in all(qualities) do
  local road=vfx8_pseudo3d.new({quality=q,width=128,height=96,horizon=34})
  assert(not road:set_mode7("invalid"))
  road:set_camera(8,40,18,0.2); road:set_road(58,3,-0.2)
  assert(road:set_mode7({width_tiles=16,height_tiles=16,scale=0.55}))
  assert(road:add_object(0,80,11,4)); road:update(1/60); road:draw(colors)
  assert(type(road:project(0,80,4))=="number"); road:set_mode7(false); road:draw(colors); road:clear()

  local flames=vfx8_flames.new({quality=q})
  assert(flames:emit_jet(48,70,0,0,{count=8})==0)
  assert(flames:emit_campfire(64,90,{count=8})>0); flames:update(1/60); flames:draw(); flames:clear()
  assert(flames:emit_jet(48,70,1,-0.1,{count=8})>0); flames:update(1/60); flames:draw(); flames:clear()

  local electricity=vfx8_electricity.new({quality=q})
  assert(electricity:strike(16,32,16,32,{branches=0})==0)
  assert(electricity:strike(16,80,112,32,{branches=2})>0); electricity:update(1/60); electricity:draw(); electricity:clear()
  assert(electricity:strike(16,32,112,80,{branches=0,jaggedness=3})>0); electricity:update(1/60); electricity:draw(); electricity:clear()
 end
 passed=true
 printh("VFX8_ADVANCED_PROFILE_CONTRACT,PASS")
end

function _update60() end
function _draw() cls(0); print(passed and "ADVANCED CONTRACT PASSED" or "ADVANCED CONTRACT FAILED",2,2,passed and 11 or 8) end
