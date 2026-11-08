pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- VFX8 weather integration cart: game callbacks own movement, selection, update, and draw.
#include vfx8/rain.lua
#include vfx8/snow.lua

local w,h,top,bottom=128,128,18,108
local catalog={
 {8,"RAIN / VERTICAL LIGHT","light",0},{8,"RAIN / VERTICAL HEAVY","heavy",0},{8,"RAIN / VERTICAL STORM","storm",0},
 {8,"RAIN / OBLIQUE LIGHT","light",16},{8,"RAIN / OBLIQUE HEAVY","heavy",16},{8,"RAIN / OBLIQUE STORM","storm",16},
 {9,"SNOW / LIGHT","light"},{9,"SNOW / HEAVY","heavy"},{9,"SNOW / BLIZZARD","storm"}
}
local variant,enabled=1,false
local player={x=64,y=63,speed=72}
local effect,surface

local function configure()
 if effect and effect.clear then effect:clear() end
 local entry=catalog[variant]
 local mode=entry[3]
 if entry[1]==8 then
  effect=vfx8_rain.new({quality="low",width=w,height=bottom,angle=entry[4],intensity=mode,seed=13})
 else
  effect=vfx8_snow.new({quality="low",width=w,height=bottom,intensity=mode,seed=17})
  effect:add_surface(0,top,w)
  surface=effect:add_surface(player.x-4,player.y-4,8)
 end
end

local function handoff()
 load("main.p8","BACK TO VFX8 CORE",tostr(player.x)..","..tostr(player.y))
end

function _init()
 local arg=stat(6)
 if arg and #arg>0 then local pos=split(arg,","); player.x=tonum(pos[1]) or player.x; player.y=tonum(pos[2]) or player.y end
 configure()
end

function _update60()
 local dx=(btn(1) and 1 or 0)-(btn(0) and 1 or 0)
 local dy=(btn(3) and 1 or 0)-(btn(2) and 1 or 0)
 player.x=max(4,min(w-4,player.x+dx*player.speed/60))
 player.y=max(top+5,min(bottom-5,player.y+dy*player.speed/60))
 if btnp(5) then
  if variant==#catalog then handoff() else variant+=1; enabled=false; configure() end
 end
 if btnp(4) then
  enabled=not enabled
  if enabled then configure() elseif effect then effect:clear() end
 end
 if enabled and effect then
  if variant>6 then effect:set_surface(surface,player.x-4,player.y-4,8) end
  effect:update(1/60)
 end
end

function _draw()
 cls(1); rectfill(0,top,w-1,bottom,1)
 for x=0,w,16 do line(x,top,x,bottom,13) end
 for y=top,bottom,16 do line(0,y,w-1,y,13) end
 rectfill(0,102,w-1,bottom,3)
 rectfill(player.x-4,player.y-4,player.x+3,player.y+3,8)
 if enabled and effect then effect:draw() end
 rectfill(0,0,w-1,top-1,0)
 local title=catalog[variant][2]
 print(title,max(1,(w-#title*4)/2),5,7)
 print(enabled and "WEATHER: ON" or "WEATHER: OFF",4,12,enabled and 11 or 6)
 rectfill(0,bottom+1,w-1,h-1,0)
 print("ARROWS MOVE  O: TOGGLE",10,h-13,6)
 print("X: NEXT VARIANT",30,h-6,6)
end
