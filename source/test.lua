local core = require("./spallcore")

local _context      = core._context
local _Rect         = core._Rect
local _Blit         = core._Blit
local _Circ         = core._Circ
local _Line         = core._Line

local _commitTemp   = core._commitTemp
local log           = core.test_logBufferToConsole

local blk       = _context.palette.blk
local wht       = _context.palette.wht
local red       = _context.palette.red
local grn       = _context.palette.grn





_context.tiles["demo"] = core._PixelBuffer(8, 8)


_context.temp = _Circ(red, 4, 4, 6)
_commitTemp("demo")

_context.temp = _Circ(grn, 4, 4, 2)
_commitTemp("demo")

_context.temp = _Line(wht, 1, 1, 8, 8)
_commitTemp("demo")

_context.temp = _Line(grn, 8, 1, 1, 8)
_commitTemp("demo")



log("demo", _context.tiles["demo"])
core.test_outputBufferToPPM(_context.tiles["demo"], "../output/demo.ppm", _context.colors)