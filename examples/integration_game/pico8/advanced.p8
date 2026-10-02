pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- VFX8 integration game: pseudo-3D, flames, and electricity.
#include vfx8/pseudo3d.lua
#include vfx8/flames.lua
#include vfx8/electricity.lua

local w,h,top,bottom=128,128,18,116
local catalog={
 {5,"MODE 7 ROAD","mode7"},{5,"STARFIELD","stars"},{5,"ROAD OBJECT","object"},
 {6,"FLAMETHROWER","jet"},{6,"CAMPFIRE","campfire"},
 {7,"BRANCHED BOLT","branched"},{7,"CLEAN BOLT","clean"}
}
local group_names={[5]="PSEUDO-3D",[6]="FLAMES",[7]="ELECTRICITY"}
local colors={sky=1,ground=3,road_a=1,road_b=13,edge=11,stars={7,6,5}}
local selected,selected_group=1,0
local entry,effect
local player={x=64,y=68,speed=72}
local clock=0

local function prepare_mode7_texture()
 for y=0,7 do for x=0,7 do
  local color=(flr(x/2)+flr(y/2))%2==0 and 5 or 6
  if x%2==0 then color=13 end
  sset(8+x,y,color)
 end end
 for y=0,15 do for x=0,15 do mset(x,y,1) end end
end
local function create_effect(group)
 if group==5 then return vfx8_pseudo3d.new({quality="low",width=w,height=bottom,horizon=38})
 elseif group==6 then return vfx8_flames.new({quality="low"})
 else return vfx8_electricity.new({quality="low"}) end
end
local function configure_entry()
 entry=catalog[selected]
 if selected_group~=entry[1] or not effect then
  if effect and effect.clear then effect:clear() end
  effect=create_effect(entry[1]); selected_group=entry[1]
 elseif effect and effect.clear then effect:clear() end
 if entry[1]==5 then
  if entry[2]=="mode7" then prepare_mode7_texture(); effect:set_mode7({width_tiles=16,height_tiles=16,scale=0.55})
  else effect:set_mode7(false) end
 end
end
local function handoff()
 load("main.p8","BACK TO VFX8 CORE",tostr(player.x)..","..tostr(player.y))
end
local function trigger_effect()
 local mode=entry[2]
 if entry[1]==5 then effect:add_object((player.x-w/2)/(w/2)*0.7,90,11,6)
 elseif entry[1]==6 then
  if mode=="jet" then effect:emit_jet(player.x,player.y,1,-0.12)
  else effect:emit_campfire(player.x,player.y+8,{count=8,radius=5}) end
 else effect:strike(player.x,player.y,min(w-12,player.x+50),max(top+8,player.y-38),{branches=mode=="branched" and 2 or 0,jaggedness=mode=="clean" and 2 or 8}) end
end
local function update_game()
 local dx=(btn(1) and 1 or 0)-(btn(0) and 1 or 0)
 local dy=(btn(3) and 1 or 0)-(btn(2) and 1 or 0)
 player.x=max(4,min(w-4,player.x+dx*player.speed/60))
 player.y=max(top+4,min(bottom-4,player.y+dy*player.speed/60))
 clock+=1/60
 if entry[1]==6 and entry[2]=="campfire" then effect:emit_campfire(player.x,player.y+8,{count=2,radius=3}) end
 effect:update(1/60)
 if entry[1]==5 then effect:set_road(nil,nil,sin(clock*0.25)*0.35) end
end
local function draw_world()
 if entry[1]==5 then effect:draw(colors)
 else
  cls(1); rectfill(0,top,w-1,bottom,1)
  for x=0,w,16 do line(x,top,x,bottom,13) end
  for y=top,bottom,16 do line(0,y,w-1,y,13) end
 end
 rectfill(player.x-4,player.y-4,player.x+3,player.y+3,8)
 if (entry[1]==6 or entry[1]==7) and effect.draw then effect:draw() end
end
function _init()
 local arg=stat(6)
 if arg and #arg>0 then local pos=split(arg,","); player.x=tonum(pos[1]) or player.x; player.y=tonum(pos[2]) or player.y end
 configure_entry()
end
function _update60()
 if btnp(5) then if selected==#catalog then handoff() else selected+=1; configure_entry() end end
 if btnp(4) then trigger_effect() end
 update_game()
end
function _draw()
 draw_world()
 rectfill(0,0,w-1,top-1,0)
 local title=group_names[entry[1]].." / "..entry[2]
 print(title,max(1,(w-#title*4)/2),5,7)
 rectfill(0,bottom+1,w-1,h-1,0)
 print("ARROWS  O: FIRE  X: NEXT",5,h-8,6)
end
