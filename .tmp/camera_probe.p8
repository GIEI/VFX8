pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
 camera(12,7)
 printh("CAMERA,"..peek2(0x5f28)..","..peek2(0x5f2a))
 camera(-5,-9)
 printh("CAMERA_NEG,"..peek2(0x5f28)..","..peek2(0x5f2a))
end
function _draw() cls() end
