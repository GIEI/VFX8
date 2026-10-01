pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- vfx8 demo harness; effects are loaded from demo_extension.lua.
-- pico-8 expands this at cartridge boot, like a c-style include.
#include demo_extension.lua
#include ../../src/pico8/particles.lua

names={"particles","screen fx","pixel warp","palette fx","pseudo 3d"}
qualities={"low","medium","high"}
selected=1
quality=1
fx_enabled=true
active=nil
tick=0

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
 if btnp(0) then
  selected=(selected+3)%5+1
  refresh_fx()
 end
 if btnp(1) then
  selected=selected%5+1
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
 if btnp(5) and active and active.cycle_preset then active.cycle_preset() end
 if active and active.update then active.update(1/60) end
end

function draw_scene()
 cls(1)
 rectfill(0,28,127,103,2)
 for x=0,127,16 do line(x,28,x,103,13) end
 for y=28,103,16 do line(0,y,127,y,13) end
 rectfill(0,96,127,103,3)
 local x=24+tick%80
 rectfill(x-3,64,x+3,70,8)
 line(59,67,69,67,7)
 line(64,62,64,72,7)
end

function _draw()
 if active and active.render_scene then
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
 print("o:fire x:preset",2,122,7)
end
