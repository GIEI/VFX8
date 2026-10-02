-- VFX8 flame effects for PICO-8.
-- Include this file in a cartridge; it defines vfx8_flames.

vfx8_flames = {}
local m={}
local caps={24,40,56}
local emits={8,12,16}
local jets={6,10,14}
local fires={2,4,6}
function vfx8_flames.new(options)
  options = options or {}
  local profile = 1
  if options.quality == "medium" or options.quality == 2 then profile = 2 end
  if options.quality == "high" or options.quality == 3 then profile = 3 end
  local capacity = flr(options.capacity or caps[profile])
  capacity = max(1, min(64, capacity))
  local max_emit = max(1, min(capacity, flr(options.max_emit or emits[profile])))
  local seed = flr(options.seed or 1) % 251
  if seed < 1 then seed = 1 end
  local self = {profile=profile,capacity=capacity,max_emit=max_emit,count=0,frame_used=0,last_emitted=0,seed=seed,
    x={},y={},vx={},vy={},age={},life={},size={},gravity={},drag={},kind={}}
  for i = 1, capacity do
    self.x[i], self.y[i], self.vx[i], self.vy[i] = 0, 0, 0, 0
    self.age[i], self.life[i], self.size[i] = 0, 0, 0
    self.gravity[i], self.drag[i], self.kind[i] = 0, 0, 0
  end
  self.emit_jet,self.emit_campfire=m.emit_jet,m.emit_campfire
  self.update,self.draw=m.update,m.draw
  self.clear,self.stats=m.clear,m.stats
  return self
end

local function rnd(self)
  self.seed = (self.seed * 17 + 31) % 251
  return self.seed / 251
end

local function emit(self,kind,x,y,dx,dy,options)
  options=options or {}
  local requested=flr(options.count or (kind==1 and jets[self.profile] or fires[self.profile]))
  if requested < 1 then return 0 end
  local spawn=min(requested,self.max_emit-self.frame_used,self.capacity-self.count)
  if spawn < 1 then return 0 end
  local speed=options.speed or (kind==1 and 92 or 42)
  local spread=options.spread
  if spread==nil then spread=kind==1 and 0.22 or 5 end
  spread=max(0,spread)
  local radius=max(0,options.radius or 1)
  local gravity=options.gravity
  if gravity==nil then gravity=kind==1 and 8 or -3 end
  local drag=options.drag
  if drag==nil then drag=kind==1 and 1.2 or 0.9 end
  local life=max(0.05,options.life or (kind==1 and 0.42 or 0.72))
  local base_size=max(1,options.size or (kind==1 and 3 or 4))
  for n = 1, spawn do
    local px, py, vx, vy
    if kind == 1 then
      local offset=(rnd(self)-0.5)*2*radius
      local along=speed*(0.72+rnd(self)*0.56)
      local side=(rnd(self)-0.5)*2*spread*speed
      px, py = x - dy * offset, y + dx * offset
      vx, vy = dx * along - dy * side, dy * along + dx * side
    else
      px=x+(rnd(self)-0.5)*spread*2
      py=y+rnd(self)*2
      vx=(rnd(self)-0.5)*speed*0.48
      vy=-speed*(0.68+rnd(self)*0.64)
    end
    local i=self.count+1
    self.count = i
    self.x[i],self.y[i],self.vx[i],self.vy[i]=px,py,vx,vy
    self.age[i],self.life[i],self.size[i]=0,life,base_size*(0.72+rnd(self)*0.56)
    self.gravity[i],self.drag[i],self.kind[i]=gravity,drag,kind
  end
  self.frame_used+=spawn
  return spawn
end

function m.emit_jet(self,x,y,dx,dy,options)
  dx, dy = dx or 0, dy or 0
  local length = sqrt(dx * dx + dy * dy)
  if length <= 0 then return 0 end
  return emit(self,1,x,y,dx/length,dy/length,options)
end

function m.emit_campfire(self,x,y,options) return emit(self,2,x,y,0,-1,options) end

function m.update(self,dt)
  dt=min(0.1,max(0,dt or 1/60))
  local x, y, vx, vy = self.x, self.y, self.vx, self.vy
  local ages, lives = self.age, self.life
  local gravity, drag = self.gravity, self.drag
  local sizes, kinds = self.size, self.kind
  local count,i=self.count,1
  while i <= count do
    local age = ages[i] + dt
    if age >= lives[i] then
      local last=count
      x[i], y[i], vx[i], vy[i] = x[last], y[last], vx[last], vy[last]
      ages[i], lives[i], sizes[i] = ages[last], lives[last], sizes[last]
      gravity[i], drag[i], kinds[i] = gravity[last], drag[last], kinds[last]
      count=last-1
    else
      local keep=max(0,1-drag[i]*dt)
      ages[i] = age
      vx[i], vy[i] = vx[i] * keep, vy[i] * keep + gravity[i] * dt
      x[i],y[i]=x[i]+vx[i]*dt,y[i]+vy[i]*dt
      i = i + 1
    end
  end
  self.count=count
  self.last_emitted,self.frame_used=self.frame_used,0
end

function m.draw(self)
  local x, y, ages, lives = self.x, self.y, self.age, self.life
  local sizes, kinds = self.size, self.kind
  for i = 1, self.count do
    local t = ages[i] / lives[i]
    local col
    if kinds[i] == 1 then
      col=t<0.18 and 7 or (t<0.48 and 10 or (t<0.78 and 9 or 8))
    else
      col=t<0.30 and 10 or (t<0.68 and 9 or (t<0.90 and 8 or 4))
    end
    local size=max(1,flr(sizes[i]*(1-t*0.82)+0.5))
    local px,py=flr(x[i]+0.5),flr(y[i]+0.5)
    rectfill(px, py, px + size - 1, py + size, col)
  end
end

function m.clear(self) self.count,self.frame_used,self.last_emitted=0,0,0 end
function m.stats(self) return self.count,self.capacity,self.last_emitted end
