-- SPALLCORE TEST

local core = require("./spallcore")

-- state
local _context = core._context

-- draw prims
local _Rect = core._Rect
local _Blit = core._Blit
local _Circ = core._Circ
local _Line = core._Line
local _draw = core._draw

-- core util
local _commitTemp = core._commitTemp

-- palette
local blk = _context.palette.blk
local wht = _context.palette.wht
local red = _context.palette.red
local grn = _context.palette.grn

-- debug/test
local log = core.test_logBufferToConsole
--------------------------------------------------------

-- Create destination tile (unpositioned base buffer)
-- # demo 16 16
_context.tiles["demo"] = core._PixelBuffer(16, 16)

-- line grn 8 1 1 8
_context.temp = _Line(grn, 8, 1, 1, 8)
_commitTemp("demo")

-- circ red 4 4 6
_context.temp = _Circ(red, 4, 4, 6)
_commitTemp("demo")

-- circ red 13 3 4
_context.temp = _Circ(red, 13, 3, 4)
_commitTemp("demo")

-- circ red 12 12 10
_context.temp = _Circ(red, 12, 12, 10)
_commitTemp("demo")

-- circ wht 12 12 6
_context.temp = _Circ(wht, 12, 12, 6)
_commitTemp("demo")

-- line grn 16 1 1 16
_context.temp = _Line(grn, 16, 1, 1, 16)
_commitTemp("demo")

-- rect grn 1 12 5 5
_context.temp = _Rect(grn, 1, 12, 5, 5)
_commitTemp("demo")

-- blit wht 3 14 5 5
_context.temp = _Blit(wht, 3, 14, 5, 5)
_commitTemp("demo")

-- line grn 1 1 16 16
_context.temp = _Line(grn, 1, 1, 16, 16)
_commitTemp("demo")

-- Output result -- implicit in final dsl
log("demo", _context.tiles["demo"])
core.test_outputBufferToPPM(_context.tiles["demo"], "../output/demo.ppm", _context.colors)

--[[ .spl equivelent

# demo 16 16
  line grn 8 1 1 8
  circ red 4 4 6
  circ red 13 3 4
  circ red 12 12 10
  circ wht 12 12 6
  line grn 16 1 1 16
  rect grn 1 12 5 5
  blit wht 3 14 5 5
  line grn 1 1 16 16

]]
