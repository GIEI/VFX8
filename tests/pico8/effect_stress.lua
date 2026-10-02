-- Measure one saturated PICO-8 effect pool or helper workload over 600 frames.
function vfx8_effect_stress(kind, quality, operations)
  local effect=nil
  local frame,samples=0,0
  local cpu_sum,cpu_min,cpu_max=0,1,0
  local peak_count,peak_emitted=0,0
  local capacity=0
  local memory_before,memory_after=0,0
  local finished=false
  local colors={{0,0,0},{0.114,0.169,0.325},{0.494,0.145,0.325},{0,0.529,0.318},{0.671,0.322,0.212},{0.373,0.341,0.31},{0.761,0.765,0.78},{1,0.945,0.91},{1,0.004,0.278},{1,0.639,0},{1,0.925,0.153},{0,0.894,0.165},{0.161,0.678,1},{0.514,0.463,0.616},{1,0.467,0.659},{1,0.8,0.667}}

  local function draw_scene()
    cls(1)
    rectfill(0,88,127,127,3)
    for x=0,120,8 do line(x,32,64,127,5) end
  end

  function _init()
    memory_before=stat(0)
    if kind=="screen_fx" then
      effect=vfx8_screen_fx.new({width=128,height=96,capacity=4,seed=17})
      capacity=effect.capacity
      for i=1,capacity do effect:shockwave(64,48,i*3,12,100) end
      effect:add_trauma(1); effect:impulse(3,1,100); effect:flash(100,7)
    elseif kind=="pixel_deform" then
      effect=vfx8_pixel_deform.new({quality=quality})
      capacity=operations
      effect:set_rotation(64,48,0.25); effect:set_squash(1.2,0.8,100)
    elseif kind=="palette_fx" then
      effect=vfx8_palette_fx.new({quality=quality,color_count=16})
      effect:set_cycle(8,11,2); effect:set_filter("night"); effect:set_pulse(8,10,4)
      effect:set_invert_palette(colors); effect:invert(1000); effect:flash(8,11,7,1000)
      capacity=operations
    elseif kind=="flames" then
      effect=vfx8_flames.new({quality=quality})
      capacity=effect.capacity
    elseif kind=="electricity" then
      effect=vfx8_electricity.new({quality=quality})
      capacity=effect.capacity
    end
    memory_after=stat(0)
  end

  function _update60()
    if finished or not effect then return end
    if kind=="screen_fx" or kind=="flames" or kind=="electricity" then
      effect:update(1/60)
      if kind=="flames" then
        effect:emit_campfire(64,112,{count=effect.max_emit,life=100})
      elseif kind=="electricity" and effect.count<effect.capacity then
        effect:strike(8,20,120,70,{life=100})
      end
    elseif kind=="palette_fx" then
      effect:update(1/60)
    else
      effect:update(1/60)
    end
    local current=0
    if kind=="screen_fx" then current=effect.wave_count
    elseif kind=="flames" or kind=="electricity" then current=effect.count
    else current=capacity end
    peak_count=max(peak_count,current)
    if effect.last_emitted then peak_emitted=max(peak_emitted,effect.last_emitted) end
  end

  function _draw()
    if finished then return end
    if kind=="screen_fx" then
      effect:render(draw_scene)
    else
      draw_scene()
    end
    if kind=="pixel_deform" then
      for i=0,operations-1 do
        local x=i%128
        local offset=effect:wave_offset(x,frame/60,3,48,0.5)
        local rx,ry=effect:rotate_point(x,48+offset)
        if effect:visible(x,48,0.5,"checker") then pset(rx,ry,12) end
      end
      effect:scale()
    elseif kind=="palette_fx" then
      for i=0,operations-1 do
        local color=effect:map_color(i%16)
        if i%8==0 then pset(i%128,flr(i/128),color) end
      end
    elseif kind=="flames" or kind=="electricity" then
      effect:draw()
    end
    print(kind.." "..quality.." "..samples.."/600",2,2,7)
    if frame>3 then
      local cpu=stat(1)
      samples+=1; cpu_sum+=cpu; cpu_min=min(cpu_min,cpu); cpu_max=max(cpu_max,cpu)
    end
    frame+=1
    if samples==600 then
      local before=stat(0)
      local active=peak_count
      if kind=="screen_fx" then active=effect.wave_count
      elseif kind=="flames" or kind=="electricity" then active=effect.count end
      memory_after=before
      printh("VFX8_EFFECT_STRESS,"..kind..","..quality..",600,"..active..","..capacity..","..peak_emitted..","..cpu_sum/samples..","..cpu_min..","..cpu_max..","..memory_before..","..memory_after)
      finished=true
    end
  end
end
