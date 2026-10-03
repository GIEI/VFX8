-- VFX8 integration game for TIC-80. Expand the includes before importing.
--#include "vfx8/particles.lua"
--#include "vfx8/screen_fx.lua"
--#include "vfx8/pixel_deform.lua"
--#include "vfx8/palette_fx.lua"
--#include "vfx8/pseudo3d.lua"
--#include "vfx8/flames.lua"
--#include "vfx8/electricity.lua"

local width,height,top,bottom=240,136,22,124
local catalog={
 {1,"EXPLOSION / POINT","explosion","point"},{1,"EXPLOSION / LINE","explosion","line"},{1,"EXPLOSION / AREA","explosion","area"},
 {1,"SPARKS / POINT","sparks","point"},{1,"SPARKS / LINE","sparks","line"},{1,"SPARKS / AREA","sparks","area"},
 {1,"TRAIL / POINT","trail","point"},{1,"TRAIL / LINE","trail","line"},{1,"TRAIL / AREA","trail","area"},
 {1,"SMOKE / POINT","smoke","point"},{1,"SMOKE / LINE","smoke","line"},{1,"SMOKE / AREA","smoke","area"},
 {1,"DUST / POINT","dust","point"},{1,"DUST / LINE","dust","line"},{1,"DUST / AREA","dust","area"},
 {2,"TRAUMA SHAKE","trauma"},{2,"LEFT IMPULSE","left"},{2,"RIGHT IMPULSE","right"},{2,"SHOCKWAVE / RIPPLE","shockwave"},{2,"SCREEN FLASH","flash"},
 {3,"WAVE WARP","wave"},{3,"WAVE + ROTATION","rotation"},{3,"SQUASH / STRETCH","squash"},{3,"ORDERED DISSOLVE","ordered"},{3,"CHECKER DISSOLVE","checker"},{3,"SPIRAL DISSOLVE","spiral"},
 {4,"COLOR CYCLING","cycle"},{4,"NIGHT FILTER","night"},{4,"SEPIA FILTER","sepia"},{4,"MONOCHROME FILTER","mono"},{4,"GLOW PULSE","glow"},{4,"DAMAGE FLASH","damage"},{4,"NEGATIVE FLASH","negative"},{4,"CUSTOM DUSK MAP","dusk"},
 {5,"MODE 7 TEXTURED PLANE","mode7"},{5,"PARALLAX STARFIELD","stars"},{5,"DEPTH-PROJECTED OBJECT","object"},
 {6,"FLAMETHROWER JET","jet"},{6,"CAMPFIRE PLUME","campfire"},
 {7,"BRANCHED LIGHTNING","branched"},{7,"CLEAN LIGHTNING ARC","clean"}
}
local group_names={"PARTICLES","SCREEN FX","PIXEL WARP","PALETTE FX","PSEUDO-3D","FLAMES","ELECTRICITY"}
local road_colors={sky=1,ground=3,road_a=1,road_b=13,edge=11,stars={12,14,15}}
local rgb_palette={{0,0,0},{0.114,0.169,0.325},{0.494,0.145,0.325},{0,0.529,0.318},{0.671,0.322,0.212},{0.373,0.341,0.31},{0.761,0.765,0.78},{1,0.945,0.91},{1,0.004,0.278},{1,0.639,0},{1,0.925,0.153},{0,0.894,0.165},{0.161,0.678,1},{0.514,0.463,0.616},{1,0.467,0.659},{1,0.8,0.667}}
local dusk_map={0,1,1,2,3,4,5,6,2,3,5,4,1,2,3,6}
local selected,selected_group=1,0
local entry,effect
local player={x=120,y=74,speed=72}
local clock,dissolve_time=0,nil

local function prepare_mode7_texture()
 for y=0,63 do for x=0,63 do
  local color=(math.floor(x/8)+math.floor(y/8))%2==0 and 5 or 6
  if x%32<2 or x%32>29 then color=13 end
  poke4(0xc000+y*128+x,color)
 end end
end
local function create_effect(group)
 if group==1 then return vfx8_particles.new({quality="low"})
 elseif group==2 then return vfx8_screen_fx.new({width=width,height=height,capacity=8})
 elseif group==3 then return vfx8_pixel_deform.new({quality="low"})
 elseif group==4 then
  local fx=vfx8_palette_fx.new({quality="low",color_count=16})
  fx:set_invert_palette(rgb_palette)
  return fx
 elseif group==5 then return vfx8_pseudo3d.new({quality="low",width=width,height=bottom,horizon=34})
 elseif group==6 then return vfx8_flames.new({quality="low"})
 else return vfx8_electricity.new({quality="low"}) end
end
local function configure_entry()
 entry=catalog[selected]
 if selected_group~=entry[1] or not effect then
  if effect and effect.clear then effect:clear() end
  effect=create_effect(entry[1]); selected_group=entry[1]
 elseif effect and effect.clear then effect:clear() end
 if entry[1]==4 then
  if entry[3]=="cycle" then effect:set_cycle(8,11,2)
  elseif entry[3]=="night" or entry[3]=="sepia" or entry[3]=="mono" then effect:set_filter(entry[3])
  elseif entry[3]=="glow" then effect:set_pulse(8,10,4)
  elseif entry[3]=="dusk" then effect:set_filter_map(dusk_map) end
 elseif entry[1]==5 then
  if entry[3]=="mode7" then effect:set_mode7({x=0,y=0,width=64,height=64,scale=0.6})
  else effect:set_mode7(false) end
 end
 dissolve_time=nil
end
local function next_entry()
 selected=selected%#catalog+1
 configure_entry()
end
local function trigger_effect()
 local mode=entry[3]
 if entry[1]==1 then
  local preset,shape=entry[3],entry[4]
  if shape=="line" then effect:emit_line(preset,math.max(8,player.x-24),player.y,math.min(width-8,player.x+24),player.y,{spread=2})
  elseif shape=="area" then effect:emit_area(preset,player.x-12,player.y-8,24,16)
  else effect:emit(preset,player.x,player.y) end
 elseif entry[1]==2 then
  if mode=="trauma" then effect:add_trauma(0.9)
  elseif mode=="left" then effect:impulse(-5,0,0.2)
  elseif mode=="right" then effect:impulse(5,0,0.2)
  elseif mode=="shockwave" then effect:shockwave(player.x,player.y,2,10,0.35)
  else effect:flash(0.13,7) end
 elseif entry[1]==3 then
  if mode=="squash" then effect:set_squash(1.55,0.6,0.3)
  elseif mode=="ordered" or mode=="checker" or mode=="spiral" then dissolve_time=0
  else effect.phase=0 end
 elseif entry[1]==4 then
  if mode=="damage" then effect:flash(8,10,7,0.2)
  elseif mode=="negative" then effect:invert(0.2)
  else effect:flash(8,10,7,0.15) end
 elseif entry[1]==5 then effect:add_object((player.x-width/2)/(width/2)*0.7,90,11,6)
 elseif entry[1]==6 then
  if mode=="jet" then effect:emit_jet(player.x,player.y,1,-0.12)
  else effect:emit_campfire(player.x,player.y+8,{count=8,radius=5}) end
 else effect:strike(player.x,player.y,math.min(width-12,player.x+52),math.max(top+8,player.y-40),{branches=mode=="branched" and 2 or 0,jaggedness=mode=="clean" and 2 or 8}) end
end
local function update_game()
 local dx=(btn(3) and 1 or 0)-(btn(2) and 1 or 0)
 local dy=(btn(1) and 1 or 0)-(btn(0) and 1 or 0)
 player.x=math.max(4,math.min(width-4,player.x+dx*player.speed/60))
 player.y=math.max(top+4,math.min(bottom-8,player.y+dy*player.speed/60))
 clock=clock+1/60
 if entry[1]==6 and entry[3]=="campfire" then effect:emit_campfire(player.x,player.y+8,{count=2,radius=3}) end
 effect:update(1/60)
 if dissolve_time then dissolve_time=dissolve_time+1/60; if dissolve_time>=0.7 then dissolve_time=nil end end
 if entry[1]==5 then effect:set_road(nil,nil,math.sin(clock*0.25)*0.35) end
end
local function mapped_color(index)
 if entry[1]==4 then return effect:map_color(index) end
 return index
end
local function draw_warp_grid()
 local rotating=entry[3]=="rotation"
 local left,min_y,right,max_y=0,top,width-1,bottom
 if rotating then
  effect:set_rotation(player.x,player.y,clock*0.45)
  left,min_y,right,max_y=effect:rotation_bounds(left,min_y,right,max_y,16)
 end
 local function point(x,y)
  local px=x+effect:wave_offset(y,clock,7,84,0.7,x/24)
  local py=y+effect:wave_offset(x,clock,7,84,0.7,y/24)
  if rotating then return effect:rotate_point(px,py) end
  return px,py
 end
 clip(0,top,width,bottom-top+1)
 for x=math.floor(left/24)*24,right+24,24 do
  for y=math.floor(min_y/12)*12,max_y-12,12 do
   local x1,y1=point(x,y); local x2,y2=point(x,y+12)
   line(x1,y1,x2,y2,mapped_color(13))
  end
 end
 for y=math.floor(min_y/24)*24,max_y+24,24 do
  for x=math.floor(left/12)*12,right-12,12 do
   local x1,y1=point(x,y); local x2,y2=point(x+12,y)
   line(x1,y1,x2,y2,mapped_color(13))
  end
 end
 clip()
end
local function draw_world()
 if entry[1]==5 then effect:draw(road_colors)
 else
  cls(mapped_color(1)); rect(0,top,width-1,bottom,mapped_color(2))
  if entry[1]==3 and (entry[3]=="wave" or entry[3]=="rotation") then draw_warp_grid()
  else
   for x=0,width,24 do line(x,top,x,bottom,mapped_color(13)) end
   for y=top,bottom,24 do line(0,y,width-1,y,mapped_color(13)) end
  end
 end
 if entry[1]==3 and (entry[3]=="ordered" or entry[3]=="checker" or entry[3]=="spiral") and dissolve_time then
  local amount=math.min(1,dissolve_time/0.7)
  for y=0,7 do for x=0,7 do if effect:visible(player.x-4+x,player.y-4+y,amount,entry[3]) then pix(player.x-4+x,player.y-4+y,mapped_color(8)) end end end
 else
  local sx,sy=1,1
  if entry[1]==3 and entry[3]=="squash" then sx,sy=effect:scale() end
  local pw,ph=math.max(4,math.floor(8*sx)),math.max(4,math.floor(8*sy))
  rect(math.floor(player.x-pw/2),math.floor(player.y-ph/2),pw,ph,mapped_color(8))
 end
 if (entry[1]==1 or entry[1]==6 or entry[1]==7) and effect.draw then effect:draw() end
end
function TIC()
 if btnp(5) then next_entry() end
 if btnp(4) then trigger_effect() end
 update_game()
 if entry[1]==2 then effect:render(draw_world) else draw_world() end
 rect(0,0,width-1,top-1,0)
 local title=group_names[entry[1]].." / "..entry[2]
 print(title,math.max(1,(width-#title*6)/2),5,15)
 rect(0,bottom+1,width-1,height-bottom-1,0)
 print("ARROWS MOVE  A: FIRE  B: NEXT VARIANT",4,height-8,12)
end
