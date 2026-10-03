-- VFX8 integration game for Picotron.
include("vfx8/particles.lua")
include("vfx8/screen_fx.lua")
include("vfx8/pixel_deform.lua")
include("vfx8/palette_fx.lua")
include("vfx8/pseudo3d.lua")
include("vfx8/flames.lua")
include("vfx8/electricity.lua")

local width,height=240,136
local play_top,play_bottom=22,124
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
local colors={sky=1,ground=3,road_a=1,road_b=13,edge=11,stars={7,6,5}}
local rgb_palette={{0,0,0},{0.114,0.169,0.325},{0.494,0.145,0.325},{0,0.529,0.318},{0.671,0.322,0.212},{0.373,0.341,0.31},{0.761,0.765,0.78},{1,0.945,0.91},{1,0.004,0.278},{1,0.639,0},{1,0.925,0.153},{0,0.894,0.165},{0.161,0.678,1},{0.514,0.463,0.616},{1,0.467,0.659},{1,0.8,0.667}}
local dusk_map={0,1,1,2,3,4,5,6,2,3,5,4,1,2,3,6}
local selected,selected_group=1,0
local entry,effect
local player={x=120,y=74,speed=72}
local clock,dissolve_time=0,nil
local pseudo_texture

local function prepare_texture()
 if pseudo_texture then return end
 pseudo_texture=userdata("u8",64,64)
 for y=0,63 do for x=0,63 do
  local c=(flr(x/8)+flr(y/8))%2==0 and 5 or 6
  if x%32<2 or x%32>29 then c=13 end
  pseudo_texture:set(x,y,c)
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
 elseif group==5 then return vfx8_pseudo3d.new({quality="low",width=width,height=play_bottom,horizon=34})
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
  if entry[3]=="mode7" then prepare_texture(); effect:set_mode7({source=pseudo_texture,width=64,height=64,scale=0.6})
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
  if shape=="line" then effect:emit_line(preset,max(8,player.x-24),player.y,min(width-8,player.x+24),player.y,{spread=2})
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
  elseif mode=="negative" then effect:invert(0.22)
  else effect:flash(8,10,7,0.16) end
 elseif entry[1]==5 then effect:add_object((player.x-width/2)/(width/2)*0.7,90,11,6)
 elseif entry[1]==6 then
  if mode=="jet" then effect:emit_jet(player.x,player.y,1,-0.12)
  else effect:emit_campfire(player.x,player.y+8,{count=8,radius=5}) end
 else effect:strike(player.x,player.y,min(width-12,player.x+52),max(play_top+8,player.y-40),{branches=mode=="branched" and 2 or 0,jaggedness=mode=="clean" and 2 or 8}) end
end
local function update_game(dt)
 local dx=(btn(1) and 1 or 0)-(btn(0) and 1 or 0)
 local dy=(btn(3) and 1 or 0)-(btn(2) and 1 or 0)
 player.x=max(4,min(width-4,player.x+dx*player.speed*dt))
 player.y=max(play_top+4,min(play_bottom-8,player.y+dy*player.speed*dt))
 clock=clock+dt
 if entry[1]==6 and entry[3]=="campfire" then effect:emit_campfire(player.x,player.y+8,{count=2,radius=3}) end
 effect:update(dt)
 if dissolve_time then dissolve_time=dissolve_time+dt; if dissolve_time>=0.7 then dissolve_time=nil end end
 if entry[1]==5 then effect:set_road(nil,nil,math.sin(clock*0.25)*0.35) end
end
local function mapped_color(index)
 if entry[1]==4 then return effect:map_color(index) end
 return index
end
local function draw_warp_grid()
 local rotating=entry[3]=="rotation"
 local left,top,right,bottom=0,play_top,width-1,play_bottom
 if rotating then
  effect:set_rotation(player.x,player.y,clock*0.45)
  left,top,right,bottom=effect:rotation_bounds(left,top,right,bottom,12)
 end
 local function point(x,y)
  local px=x+effect:wave_offset(y,clock,4,44,0.65,x/16)
  local py=y+effect:wave_offset(x,clock,4,44,0.65,y/16)
  if rotating then return effect:rotate_point(px,py) end
  return px,py
 end
 clip(0,play_top,width,play_bottom-play_top)
 local x0=flr(left/16)*16
 for x=x0,right+16,16 do
  for y=flr(top/8)*8,bottom-8,8 do
   local x1,y1=point(x,y); local x2,y2=point(x,y+8)
   line(x1,y1,x2,y2,mapped_color(13))
  end
 end
 for y=flr(top/16)*16,bottom+16,16 do
  for x=flr(left/8)*8,right-8,8 do
   local x1,y1=point(x,y); local x2,y2=point(x+8,y)
   line(x1,y1,x2,y2,mapped_color(13))
  end
 end
 clip()
end
local function draw_world()
 if entry[1]==5 then effect:draw(colors)
 else
  cls(mapped_color(1)); rectfill(0,play_top,width-1,play_bottom,mapped_color(2))
  if entry[1]==3 and (entry[3]=="wave" or entry[3]=="rotation") then draw_warp_grid()
  else
   for x=0,width,16 do line(x,play_top,x,play_bottom,mapped_color(13)) end
   for y=play_top,play_bottom,16 do line(0,y,width-1,y,mapped_color(13)) end
  end
 end
 if entry[1]==3 and (entry[3]=="ordered" or entry[3]=="checker" or entry[3]=="spiral") and dissolve_time then
  local amount=min(1,dissolve_time/0.7)
  for y=0,7 do for x=0,7 do
   if effect:visible(player.x-4+x,player.y-4+y,amount,entry[3]) then pset(player.x-4+x,player.y-4+y,mapped_color(8)) end
  end end
 else
  local sx,sy=1,1
  if entry[1]==3 and entry[3]=="squash" then sx,sy=effect:scale() end
  local pw,ph=max(4,flr(8*sx)),max(4,flr(8*sy))
  rectfill(flr(player.x-pw/2),flr(player.y-ph/2),flr(player.x-pw/2)+pw-1,flr(player.y-ph/2)+ph-1,mapped_color(8))
 end
 if (entry[1]==1 or entry[1]==6 or entry[1]==7) and effect.draw then effect:draw() end
end
function _init()
 window{width=width,height=height,title="VFX8 Integration Game",resizeable=false}
 configure_entry()
end
function _update()
 if btnp(5) then next_entry() end
 if btnp(4) then trigger_effect() end
 update_game(1/60)
end
function _draw()
 if entry[1]==2 then effect:render(draw_world) else draw_world() end
 rectfill(0,0,width-1,play_top-1,0)
 local title=group_names[entry[1]].." / "..entry[2]
 print(title,max(1,(width-#title*4)/2),5,7)
 rectfill(0,play_bottom+1,width-1,height-1,0)
 print("ARROWS MOVE  Z: FIRE  X: NEXT VARIANT",5,height-8,6)
end
