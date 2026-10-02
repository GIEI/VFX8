pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- Check the bounded lightning API on PICO-8.
#include ../../src/pico8/electricity.lua

local arcs=nil
local failed=nil

function _init()
 arcs=vfx8_electricity.new({quality="medium",capacity=32,max_emit=12,seed=13})
 assert(arcs:strike(4,8,4,8)==0,"zero-length strike should be ignored")
 local emitted=arcs:strike(10,20,90,40,{segments=6,branches=2,life=0.05})
 local extra=arcs:strike(0,0,80,30,{segments=10,life=0.05})
 assert(emitted+extra<=12,"strikes should share the update budget")
 local overflow=arcs:strike(0,0,90,30,{segments=24,branches=8,life=0.05})
 assert(emitted+extra+overflow<=12,"later strikes should be capped")
 arcs:update(0.01)
 local count,capacity,last=arcs:stats()
 assert(emitted>6 and emitted<=12,"strike should respect its segment budget")
 assert(count==emitted+extra+overflow and capacity==32 and last==count,"stats should report active segments")
end

function _update60()
 if failed then return end
 arcs:update(1/60)
end

function _draw()
 cls(0)
 arcs:draw()
 print("ELECTRICITY CONTRACT PASSED",2,2,7)
end
