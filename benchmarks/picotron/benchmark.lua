-- Headless, fixed-workload Picotron benchmark. The wrapper stages modules before launch.
window{width=240,height=136,title="VFX8 Picotron Benchmark"}

include("/desktop/vfx8-picotron-runtime/vfx8/particles.lua")
include("/desktop/vfx8-picotron-runtime/vfx8/screen_fx.lua")
include("/desktop/vfx8-picotron-runtime/vfx8/pixel_deform.lua")
include("/desktop/vfx8-picotron-runtime/vfx8/palette_fx.lua")
include("/desktop/vfx8-picotron-runtime/vfx8/pseudo3d.lua")
include("/desktop/vfx8-picotron-runtime/vfx8/flames.lua")
include("/desktop/vfx8-picotron-runtime/vfx8/electricity.lua")

local warmup_frames=30
local sample_frames=120
local repetitions=5
local qualities={"low","medium","high"}
local effect_names={"particles","screen_fx","pixel_deform","palette_fx","pseudo3d","flames","electricity"}
local cases={}
local records={}
local case_index, repetition, frame=1,1,0
local effect, active_count, capacity, secondary_count, operation_count
local cpu_samples={}
local fps_samples={}
local heap_setup_kb, heap_warmup_kb, heap_sample_delta_kb=0,0,0
local heap_before_kb=0
local runtime_version=tostr(stat(5))
local dt=1/60
local texture=userdata("u8",64,64)

for y=0,63 do
  for x=0,63 do texture:set(x,y,(flr(x/8)+flr(y/8))%2==0 and 5 or 6) end
end

for _,quality in ipairs(qualities) do
  cases[#cases+1]={quality=quality,effect="baseline",load="baseline"}
  for _,name in ipairs(effect_names) do
    cases[#cases+1]={quality=quality,effect=name,load="typical"}
    cases[#cases+1]={quality=quality,effect=name,load="saturated"}
  end
end

local function setup_case()
  collectgarbage("collect")
  heap_before_kb=collectgarbage("count")
  effect=nil
  active_count,capacity,secondary_count,operation_count=0,0,0,0
  cpu_samples={}
  fps_samples={}
  frame=0
  heap_setup_kb=0
  heap_warmup_kb=0
  heap_sample_delta_kb=0
  local current=cases[case_index]
  local q, name, load=current.quality,current.effect,current.load
  local seed=17+case_index*13+repetition

  if name=="particles" then
    effect=vfx8_particles.new({quality=q,seed=seed})
    capacity=effect.capacity
    if load=="saturated" then effect.max_emit=capacity end
    local count=load=="saturated" and capacity or min(12,capacity)
    assert(effect:emit("explosion",120,68,{count=count,life=100,speed=20,gravity=0,drag=0})==count)
  elseif name=="screen_fx" then
    effect=vfx8_screen_fx.new({width=240,height=136,capacity=8,seed=seed})
    capacity=effect.capacity
    local count=load=="saturated" and capacity or 1
    for i=1,count do assert(effect:shockwave(120,68,i*2,12,100)) end
    effect:add_trauma(0.8)
    effect:flash(100,7)
    effect:impulse(4,2,100)
  elseif name=="pixel_deform" then
    effect=vfx8_pixel_deform.new({quality=q})
    local profile_calls=q=="low" and 32 or (q=="medium" and 96 or 240)
    operation_count=load=="saturated" and profile_calls*8 or profile_calls
    effect:set_rotation(120,68,0.25)
    effect:set_squash(1.2,0.8,100)
    capacity=operation_count
  elseif name=="palette_fx" then
    effect=vfx8_palette_fx.new({quality=q,color_count=64})
    assert(effect:set_cycle(8,15,2))
    assert(effect:set_filter("night"))
    effect:set_pulse(8,10,4)
    operation_count=load=="saturated" and 1024 or 32
    capacity=operation_count
  elseif name=="pseudo3d" then
    effect=vfx8_pseudo3d.new({quality=q,width=240,height=110,horizon=34})
    effect:set_camera(12,42,0,0.2)
    effect:set_road(96,3,-0.2)
    assert(effect:set_mode7({source=texture,width=64,height=64,scale=0.08}))
    capacity=effect.object_capacity
    secondary_count=effect.star_count
    local count=load=="saturated" and capacity or 1
    for i=1,count do assert(effect:add_object((i%3-1)*0.5,20+i*4,11,4)) end
  elseif name=="flames" then
    effect=vfx8_flames.new({quality=q,seed=seed})
    capacity=effect.capacity
    effect.max_emit=load=="saturated" and capacity or effect.max_emit
    local count=load=="saturated" and capacity or min(8,capacity)
    assert(effect:emit_campfire(120,112,{count=count,life=100})==count)
  elseif name=="electricity" then
    effect=vfx8_electricity.new({quality=q,seed=seed})
    capacity=effect.capacity
    local wanted=load=="saturated" and capacity or min(effect.max_emit,12)
    local attempts=0
    while effect.count<wanted and attempts<64 do
      local before=effect.count
      effect:strike(24,28,216,104,{segments=q=="low" and 6 or (q=="medium" and 9 or 12),branches=q=="low" and 1 or (q=="medium" and 2 or 3),life=100})
      if load=="saturated" then effect:update(0) end
      attempts+=1
      if effect.count==before then break end
    end
  end

  active_count=active_count_for(name)
  heap_setup_kb=collectgarbage("count")-heap_before_kb
end

function active_count_for(name)
  if not effect then return 0 end
  if name=="particles" or name=="flames" or name=="electricity" then return effect.count end
  if name=="screen_fx" then return effect.wave_count end
  if name=="pseudo3d" then return effect.object_count end
  return operation_count
end

local function draw_background()
  cls(1)
  rectfill(0,0,239,135,1)
  for x=0,232,16 do line(x,30,120,135,5) end
  for y=64,128,16 do line(0,y,239,y,5) end
end

local function draw_effect()
  local current=cases[case_index]
  local name=current.effect
  if name=="particles" then effect:draw()
  elseif name=="screen_fx" then effect:draw_overlays()
  elseif name=="pixel_deform" then
    for i=1,operation_count do
      local x=i%240
      local offset=effect:wave_offset(x,frame/60,3,48,0.5)
      local rx,ry=effect:rotate_point(x,68+offset)
      local visible=effect:visible(x%240,flr(i/240)+64,0.5,"checker")
      if visible then pset(rx,ry,12) end
    end
    effect:scale()
  elseif name=="palette_fx" then
    for i=0,operation_count-1 do
      local color=effect:map_color(i%16)
      if i%8==0 then pset(i%240,flr(i/240),color) end
    end
  elseif name=="pseudo3d" then
    effect:draw({sky=1,ground=3,road_a=1,road_b=13,edge=11,stars={7,6,5}})
  elseif name=="flames" or name=="electricity" then effect:draw() end
end

local function percentile95(values)
  local copy={}
  for i=1,#values do copy[i]=values[i] end
  for i=2,#copy do
    local value,j=copy[i],i-1
    while j>=1 and copy[j]>value do copy[j+1]=copy[j]; j-=1 end
    copy[j+1]=value
  end
  return copy[max(1,math.ceil(#copy*0.95))]
end

local function minimum(values)
  local result=values[1]
  for i=2,#values do result=min(result,values[i]) end
  return result
end

local function finish_repetition()
  local total,low,high=0,1,0
  for i=1,#cpu_samples do
    local value=cpu_samples[i]
    total+=value
    low=min(low,value)
    high=max(high,value)
  end
  local current=cases[case_index]
  heap_sample_delta_kb=collectgarbage("count")-heap_warmup_kb
  records[#records+1]={runtime_version,current.quality,current.effect,current.load,repetition,
    warmup_frames,sample_frames,active_count_for(current.effect),capacity,secondary_count,
    total/#cpu_samples,percentile95(cpu_samples),low,high,minimum(fps_samples),heap_setup_kb,heap_sample_delta_kb}
  repetition+=1
  if repetition>repetitions then repetition=1; case_index+=1 end
  if case_index>#cases then
    printh("VFX8_PICOTRON_BENCH,engine_version,quality,effect,scenario,repetition,warmup_frames,sample_frames,active_items,capacity,secondary_items,mean_cpu,p95_cpu,min_cpu,max_cpu,min_fps,setup_heap_kb,sample_heap_delta_kb")
    for _,row in ipairs(records) do
      printh("VFX8_PICOTRON_BENCH,"..table.concat(row,","))
    end
    printh("VFX8_PICOTRON_BENCH,PASS,"..#records)
    exit()
  else setup_case() end
end

function _init() setup_case() end

function _update60()
  local current=cases[case_index]
  if effect and current.effect=="electricity" and current.load=="saturated" and effect.count<effect.capacity then
    effect:strike(24,28,216,104,{segments=current.quality=="low" and 6 or (current.quality=="medium" and 9 or 12),branches=current.quality=="low" and 1 or (current.quality=="medium" and 2 or 3),life=100})
  end
  if effect and effect.update then effect:update(dt) end
end

function _draw()
  draw_background()
  draw_effect()
  local cpu=stat(1)
  frame+=1
  if frame==warmup_frames then
    heap_warmup_kb=collectgarbage("count")
  elseif frame>warmup_frames then
    cpu_samples[#cpu_samples+1]=cpu
    fps_samples[#fps_samples+1]=stat(7)
  end
  if frame>=warmup_frames+sample_frames then finish_repetition() end
end
