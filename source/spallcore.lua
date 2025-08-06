
-- SPALL INTERNAL DSL CORE --


-- Constructors & Initialization ----------------------------------------------------------------------------------------

-- _PixelBuffer(width, height)
-- Constructs a 2D pixel buffer table (indexed as [y][x]) with .w and .h metadata
local _PixelBuffer = function(width, height, x_pos, y_pos)
	local buffer = {}

	buffer.w = width
	buffer.h = height

	buffer.x = x_pos or nil
	buffer.y = y_pos or nil

	for y = 1, height do
		buffer[y] = {}
		for x = 1, width do
            buffer[y][x] = 0 -- C0 = transparent
          end
        end
        return buffer
      end

-- _initPalette()
local _initPalette = function()
	return {
		C0 = 0, none = 0,
		C2 = 1, blk = 1,
		C1 = 2, wht = 2,
		C3 = 3, red = 3,
		C4 = 4, grn = 4,
		C5 = 5, blu = 5,
		C6 = 6, yel = 6,
		C7 = 7, mag = 7,
		C8 = 8, cya = 8,
	}
end

-- _initColors()
local _initColors = function()
	return {
		[0] = { 0, 0, 0, 0 },
		[1] = { 0, 0, 0 },
		[2] = { 255, 255, 255 },

		[3] = { 255, 0, 0 },
		[4] = { 0, 255, 0 },
		[5] = { 0, 0, 255 },
		[6] = { 255, 255, 0 },
		[7] = { 255, 0, 255 },
		[8] = { 0, 255, 255 },
	}
end

-- _initContextState()
local _initContextState = function()
	return {
		palette = _initPalette(),
		colors  = _initColors(),
		temp    = nil,
		tiles   = {},
		user    = {},
	}
end


local _context = _initContextState()
-- Utility Ops -----------------------------------------------------------------------------------------------------------

-- _mergeUnion(dst, src)
-- Returns a new buffer equal in size to `dst`, with `src` shape merged in at its (.x, .y) position.
-- Union logic: if a pixel exists in `src` (non-zero), it overwrites the corresponding pixel in `dst`.
-- Both inputs remain unchanged. This is a pure compositional operation.
-- `dst` is a tile or main buffer (no .x/.y); `src` must be a positioned shape buffer.
local _mergeUnion = function(dst, src)
  assert(src.x and src.y, "_mergeUnion: src buffer must have .x and .y") -- enforce shape offset

  local out = _PixelBuffer(dst.w, dst.h)                      -- allocate output buffer, same size as dst
  for y = 1, dst.h do
    for x = 1, dst.w do
      local src_y = y - src.y + 1                                 -- map output y to source-relative coordinates
      local src_x = x - src.x + 1                                -- map output x to source-relative coordinates
      local s = (src[src_y] and src[src_y][src_x]) or 0       -- get source pixel, or 0 if out-of-bounds
      local d = dst[y][x] or 0                                -- get destination pixel
      out[y][x] = (s ~= 0) and s or d                         -- union logic: src pixel overwrites if non-zero
    end
  end
return out end -- return merged result (pure)



-- _commitTemp(tile_name)
-- Merges `_context.temp` into the named tile buffer; then clears temp
local _commitTemp = function(tile_name)
  local temp = _context.temp
  if not temp then return end                               -- no-op if temp is empty

  assert(tile_name, "_commitTemp: tile name required")
  assert(temp.x and temp.y, "_commitTemp: temp must be a positioned buffer")

  local existing = _context.tiles[tile_name]

  if existing then
    local merged = _mergeUnion(existing, temp)              -- merge temp into existing tile using union logic
    _context.tiles[tile_name] = merged                      -- update tile with merged result
  else
    _context.tiles[tile_name] = temp                        -- first write: assign directly
  end
  _context.temp = nil                                       -- clear temp after commit
end



local _last = function()
	return _context.temp
end

-- Drawing Primitives ----------------------------------------------------------------------------------------------------

-- _Rect(color, x, y, w, h)
-- Returns a shape buffer of size w×h filled with `color`, positioned at (x, y)
local _Rect = function(color, x, y, w, h)
  local buf = _PixelBuffer(w, h, x, y)                -- allocate minimal buffer at (x, y)
  for dy = 1, h do
    for dx = 1, w do
      buf[dy][dx] = color                             -- fill entire region with color
    end
  end
  return buf                                          -- positioned shape buffer
end



-- _Blit(color, x, y)
-- Returns a 1×1 shape buffer with a single pixel at (x, y)
local _Blit = function(color, x, y)
  local buf = _PixelBuffer(1, 1, x, y)                -- 1×1 buffer at position (x, y)
  buf[1][1] = color                                    -- set pixel
  return buf                                          -- positioned shape buffer
end

local _Circ = function(color, cx, cy, diameter)
  local size = diameter
  local r = diameter / 2
  local r2 = (r - 0.25)^2  -- tighter fit

  -- Compute top-left of buffer so (cx, cy) is center of shape
  local ox = math.floor(cx - r + 1)
  local oy = math.floor(cy - r + 1)

  local buf = _PixelBuffer(size, size, ox, oy)

  local mid = (diameter + 1) / 2

  for py = 1, size do
    for px = 1, size do
      local dx = px - mid
      local dy = py - mid
      if dx * dx + dy * dy <= r2 then
        buf[py][px] = color
      end
    end
  end

  return buf
end


-- Debug --------------------------------------------------------------------------------------------------------------

local test_logBufferToConsole = function(name, buf)
	local width  = buf.w
	local height = buf.h
	print(name .. string.rep("-", 20 - #name))
	print("w: " .. width .. " - h: " .. height)
	print(string.rep("-", 4 + (width * 2)))
	io.write("   X")
	for x = 1, width do io.write(" " .. x) end
	print()
	io.write(" Y +")
	io.write(string.rep("-", width * 2))
	print()
	for y = 1, height do
		io.write(" " .. y .. " |")
		for x = 1, width do
			io.write(" " .. tostring(buf[y][x] or 0))
		end
		print()
	end
	print(string.rep("-", 4 + (width * 2)))
end


-- outputBufferToPPM(buf, path)
-- Writes a .ppm (P3) file from a pixel buffer and current palette (color index → RGB)
-- Useful for previewing Spall output in FilePilot or converting to PNG later
local test_outputBufferToPPM = function(buf, path, palette)
  assert(buf and buf.w and buf.h, "Invalid buffer")
  assert(palette, "Palette (color index → RGB) required")

  local file = assert(io.open(path, "w"))
  file:write("P3\n", buf.w, " ", buf.h, "\n255\n")  -- ASCII PPM header

  for y = 1, buf.h do
    for x = 1, buf.w do
      local idx = buf[y][x] or 0
      local rgb = palette[idx] or {0, 0, 0}
      file:write(rgb[1], " ", rgb[2], " ", rgb[3], "  ")
    end
    file:write("\n")
  end

  file:close()
end

-- Export --------------------------------------------------------------------------------------------------------------

return {
	_PixelBuffer        = _PixelBuffer,
	_initContextState   = _initContextState,
	_initPalette        = _initPalette,
	_initColors         = _initColors,
	_commitTemp         = _commitTemp,
	_mergeUnion         = _mergeUnion,

	_last               = _last,
	_Rect               = _Rect,
	_Blit               = _Blit,
  _Circ               = _Circ, 

	test_logBufferToConsole = test_logBufferToConsole,
	test_outputBufferToPPM  = test_outputBufferToPPM, 

	_context = _context,
}
