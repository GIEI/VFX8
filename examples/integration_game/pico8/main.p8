pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- VFX8 integration game: particles, screen FX, deformation, and palette.
#include vfx8/particles.lua
#include vfx8/screen_fx.lua
#include vfx8/pixel_deform.lua
#include vfx8/palette_fx.lua

local w,h,top,bottom=128,128,18,116
local catalog={
 {1,"EXPLOSION / POINT","explosion","point"},{1,"EXPLOSION / LINE","explosion","line"},{1,"EXPLOSION / AREA","explosion","area"},
 {1,"SPARKS / POINT","sparks","point"},{1,"SPARKS / LINE","sparks","line"},{1,"SPARKS / AREA","sparks","area"},
 {1,"TRAIL / POINT","trail","point"},{1,"TRAIL / LINE","trail","line"},{1,"TRAIL / AREA","trail","area"},
 {1,"SMOKE / POINT","smoke","point"},{1,"SMOKE / LINE","smoke","line"},{1,"SMOKE / AREA","smoke","area"},
 {1,"DUST / POINT","dust","point"},{1,"DUST / LINE","dust","line"},{1,"DUST / AREA","dust","area"},
 {2,"TRAUMA SHAKE","trauma"},{2,"LEFT IMPULSE","left"},{2,"RIGHT IMPULSE","right"},{2,"SHOCKWAVE / RIPPLE","shockwave"},{2,"SCREEN FLASH","flash"},
 {3,"WAVE WARP","wave"},{3,"WAVE + ROTATION","rotation"},{3,"SQUASH / STRETCH","squash"},{3,"ORDERED DISSOLVE","ordered"},{3,"CHECKER DISSOLVE","checker"},{3,"SPIRAL DISSOLVE","spiral"},
 {4,"COLOR CYCLING","cycle"},{4,"NIGHT FILTER","night"},{4,"SEPIA FILTER","sepia"},{4,"MONOCHROME FILTER","mono"},{4,"GLOW PULSE","glow"},{4,"DAMAGE FLASH","damage"},{4,"NEGATIVE FLASH","negative"},{4,"CUSTOM DUSK MAP","dusk"}
}
local group_names={"PARTICLES","SCREEN FX","PIXEL WARP","PALETTE FX"}
local rgb_palette={{0,0,0},{0.114,0.169,0.325},{0.494,0.145,0.325},{0,0.529,0.318},{0.671,0.322,0.212},{0.373,0.341,0.31},{0.761,0.765,0.78},{1,0.945,0.91},{1,0.004,0.278},{1,0.639,0},{1,0.925,0.153},{0,0.894,0.165},{0.161,0.678,1},{0.514,0.463,0.616},{1,0.467,0.659},{1,0.8,0.667}}
local dusk_map={0,1,1,2,3,4,5,6,2,3,5,4,1,2,3,6}
local selected,selected_group=1,0
local entry,effect
local player={x=64,y=68,speed=72}
local clock,dissolve_time=0,nil

local function create_effect(group)
 if group==1 then return vfx8_particles.new({quality="low"})
 elseif group==2 then return vfx8_screen_fx.new({width=w,height=h,capacity=4})
 elseif group==3 then return vfx8_pixel_deform.new({quality="low"})
 else
  local fx=vfx8_palette_fx.new({quality="low",color_count=16})
  fx:set_invert_palette(rgb_palette)
  return fx
 end
end
local function configure_entry()
 entry=catalog[selected]
 if selected_group~=entry[1] or not effect then
  if effect and effect.clear then effect:clear() end
  effect=create_effect(entry[1]); selected_group=entry[1]
 elseif effect and effect.clear then effect:clear() end
 if entry[1]==4 then
  if entry[2]=="cycle" then effect:set_cycle(8,11,2)
  elseif entry[2]=="night" or entry[2]=="sepia" or entry[2]=="mono" then effect:set_filter(entry[2])
  elseif entry[2]=="glow" then effect:set_pulse(8,10,4)
  elseif entry[2]=="dusk" then effect:set_filter_map(dusk_map) end
 end
 dissolve_time=nil
end
local function handoff()
 load("advanced.p8","NEXT: PSEUDO-3D",tostr(player.x)..","..tostr(player.y))
end
local function trigger_effect()
 local mode=entry[2]
 if entry[1]==1 then
  local preset,shape=entry[3],entry[4]
  if shape=="line" then effect:emit_line(preset,max(8,player.x-18),player.y,min(w-8,player.x+18),player.y,{spread=2})
  elseif shape=="area" then effect:emit_area(preset,player.x-8,player.y-6,16,12)
  else effect:emit(preset,player.x,player.y) end
 elseif entry[1]==2 then
  if mode=="trauma" then effect:add_trauma(0.9)
  elseif mode=="left" then effect:impulse(-4,0,0.2)
  elseif mode=="right" then effect:impulse(4,0,0.2)
  elseif mode=="shockwave" then effect:shockwave(player.x,player.y,2,8,0.35)
  else effect:flash(0.12,7) end
 elseif entry[1]==3 then
  if mode=="squash" then effect:set_squash(1.5,0.62,0.3)
  elseif mode=="ordered" or mode=="checker" or mode=="spiral" then dissolve_time=0
  else effect.phase=0 end
 elseif mode=="damage" then effect:flash(8,10,7,0.2)
 elseif mode=="negative" then effect:invert(0.2)
 else effect:flash(8,10,7,0.15) end
end
local function update_game()
 local dx=(btn(1) and 1 or 0)-(btn(0) and 1 or 0)
 local dy=(btn(3) and 1 or 0)-(btn(2) and 1 or 0)
 player.x=max(4,min(w-4,player.x+dx*player.speed/60))
 player.y=max(top+4,min(bottom-4,player.y+dy*player.speed/60))
 clock+=1/60
 effect:update(1/60)
 if dissolve_time then dissolve_time+=1/60; if dissolve_time>=0.7 then dissolve_time=nil end end
end
local function mapped_color(index)
 if entry[1]==4 then return effect:map_color(index) end
 return index
end
local function draw_warp_grid()
 local rotating=entry[2]=="rotation"
 local left,t,right,b=0,top,w-1,bottom
 if rotating then
  effect:set_rotation(player.x,player.y,clock*0.45)
  left,t,right,b=effect:rotation_bounds(left,t,right,b,8)
 end
 clip(0,top,w,bottom-top+1)
 local function point(x,y)
  local px=x+effect:wave_offset(y,clock,4,42,0.7,x/16)
  local py=y+effect:wave_offset(x,clock,4,42,0.7,y/16)
  if rotating then return effect:rotate_point(px,py) end
  return px,py
 end
 local gx=flr(left/16)*16
 for x=gx,right+16,16 do
  for y=flr(t/8)*8,b-8,8 do
   local x1,y1=point(x,y); local x2,y2=point(x,y+8)
   line(x1,y1,x2,y2,mapped_color(13))
  end
 end
 for y=flr(t/16)*16,b+16,16 do
  for x=flr(left/8)*8,right-8,8 do
   local x1,y1=point(x,y); local x2,y2=point(x+8,y)
   line(x1,y1,x2,y2,mapped_color(13))
  end
 end
 clip()
end
local function draw_world()
 cls(mapped_color(1)); rectfill(0,top,w-1,bottom,mapped_color(2))
 if entry[1]==3 and (entry[2]=="wave" or entry[2]=="rotation") then draw_warp_grid()
 else
  for x=0,w,16 do line(x,top,x,bottom,mapped_color(13)) end
  for y=top,bottom,16 do line(0,y,w-1,y,mapped_color(13)) end
 end
 if entry[1]==3 and (entry[2]=="ordered" or entry[2]=="checker" or entry[2]=="spiral") and dissolve_time then
  local amount=min(1,dissolve_time/0.7)
  for y=0,7 do for x=0,7 do
   if effect:visible(player.x-4+x,player.y-4+y,amount,entry[2]) then pset(player.x-4+x,player.y-4+y,mapped_color(8)) end
  end end
 else
  local sx,sy=1,1
  if entry[1]==3 and entry[2]=="squash" then sx,sy=effect:scale() end
  local pw,ph=max(2,flr(8*sx)),max(2,flr(8*sy))
  rectfill(flr(player.x-pw/2),flr(player.y-ph/2),flr(player.x-pw/2)+pw-1,flr(player.y-ph/2)+ph-1,mapped_color(8))
 end
 if entry[1]==1 then effect:draw() end
end
function _init() configure_entry() end
function _update60()
 if btnp(5) then
  if selected==#catalog then handoff() else selected+=1; configure_entry() end
 end
 if btnp(4) then trigger_effect() end
 update_game()
end
function _draw()
 if entry[1]==2 then effect:render(draw_world) else draw_world() end
 rectfill(0,0,w-1,top-1,0)
 local title=group_names[entry[1]].." / "..entry[2]
 print(title,max(1,(w-#title*4)/2),5,7)
 rectfill(0,bottom+1,w-1,h-1,0)
 print("ARROWS  O: FIRE  X: NEXT",9,h-8,6)
end
