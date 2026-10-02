pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
#include ../../src/pico8/palette_fx.lua

function _init()
 local palette=vfx8_palette_fx.new({color_count=4})
 assert(palette:set_filter_map({0,2,3,1}),"valid custom map rejected")
 assert(palette:map_color(1)==2 and palette:map_color(3)==1,"custom map result mismatch")
 assert(not palette:set_filter_map({0,4,3,1}),"invalid target accepted")
 assert(palette:map_color(1)==2,"invalid map changed the active map")
 assert(not palette:set_filter("unknown"),"unknown filter accepted")
 assert(palette:map_color(1)==2,"unknown filter changed the active map")
 palette:clear_filter()
 assert(palette:map_color(1)==1,"clear_filter did not restore identity")
 assert(palette:set_cycle(0,3,2),"valid color cycle rejected")
 assert(palette:map_color(0)==0,"cycle phase did not start immediately")
 palette:update(0.1)
 assert(palette:map_color(0)==0,"cycle phase changed between integer steps")
 for i=1,5 do palette:update(0.1) end
 assert(palette:map_color(0)==1,"cached cycle phase did not advance")
 palette:clear()
 palette:set_pulse(2,3,1)
 assert(palette:map_color(2)==2,"pulse phase did not start immediately")
 for i=1,6 do palette:update(0.1) end
 assert(palette:map_color(2)==3,"cached pulse phase did not advance")
 palette:clear()
 local rgb={{0,0,0},{1,1,1},{1,0,0},{0,1,1}}
 assert(palette:set_invert_palette(rgb),"valid RGB palette rejected")
 assert(palette:invert(0.18),"configured palette could not invert")
 assert(palette:map_color(0)==1 and palette:map_color(1)==0,"negative map mismatch")
 assert(not palette:set_invert_palette({{0,0,0}}),"incomplete RGB palette accepted")
 palette:update(0.2)
 assert(palette:map_color(0)==1,"negative flash expired before its clamped timer elapsed")
 palette:update(0.1)
 assert(palette:map_color(0)==0,"negative flash did not expire")
 print("palette contract passed")
end

function _update60() end

function _draw()
 cls()
 print("palette contract",2,2,7)
end
