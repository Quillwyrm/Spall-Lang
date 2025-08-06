
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

-- _Rect(color, origin_x, origin_y, width, height)
-- Returns a shape buffer of size width×height filled with `color`, positioned at (origin_x, origin_y)
local _Rect = function(color, origin_x, origin_y, width, height)
  local buf = _PixelBuffer(width, height, origin_x, origin_y)    -- allocate minimal buffer at (origin_x, origin_y)
  for py = 1, height do
    for px = 1, width do
      buf[py][px] = color                                        -- fill entire region with color
    end
  end
return buf end                                                   -- positioned shape buffer



-- _Blit(color, x, y)
-- Returns a 1×1 shape buffer with a single pixel at (x, y)
local _Blit = function(color, x, y)
  local buf = _PixelBuffer(1, 1, x, y)                -- 1×1 buffer at position (x, y)
  buf[1][1] = color                                   -- set pixel
return buf end                                        -- positioned shape buffer



-- _Circ(color, center_x, center_y, diameter)
-- Returns a circular shape buffer with center at (center_x, center_y) and pixel width = `diameter`
-- Shape is centered around origin; buffer is tightly packed and positioned at top-left (origin_x, origin_y)
local _Circ = function(color, center_x, center_y, diameter)
  local size = diameter                               -- buffer width and height
  local r = diameter / 2                              -- radius as float
  local r2 = (r - 0.25)^2                             -- radius², biased for tighter fill (pixel perfect)

  local origin_x = math.floor(center_x - r + 1)                   -- buffer x-pos so circle center lands on (center_x, center_y)
  local origin_y = math.floor(center_y - r + 1)                   -- buffer y-pos (same logic for vertical)

  local buf = _PixelBuffer(size, size, origin_x, origin_y)        -- allocate centered, minimal buffer

  local mid = (diameter + 1) / 2                      -- circle center in local buffer coords

  for py = 1, size do
    for px = 1, size do
      local offset_x = px - mid                             -- x offset from center
      local offset_y = py - mid                             -- y offset from center
      if offset_x * offset_x + offset_y * offset_y <= r2 then
        buf[py][px] = color                           -- fill pixel if inside circle
      end
    end
  end
return buf end                                        -- positioned shape buffer



-- _Line(color, start_x, start_y, end_x, end_y)
-- Returns a shape buffer containing a line from (start_x, start_y) to (end_x, end_y) in `color`
-- Buffer is tightly sized and positioned at the top-left of the line’s bounding box
local _Line = function(color, start_x, start_y, end_x, end_y)
  local min_x = math.min(start_x, end_x)                          -- bounding box origin x
  local min_y = math.min(start_y, end_y)                          -- bounding box origin y

  local max_x = math.max(start_x, end_x)                          -- bounding box extent x
  local max_y = math.max(start_y, end_y)                          -- bounding box extent y

  local buffer_width  = max_x - min_x + 1                         -- buffer size in x
  local buffer_height = max_y - min_y + 1                         -- buffer size in y

  local buffer = _PixelBuffer(buffer_width, buffer_height, min_x, min_y)

  -- Translate line coordinates into local buffer space (1-indexed)
  local px = start_x - min_x + 1                             -- current x position in buffer
  local py = start_y - min_y + 1                             -- current y position in buffer

  local target_x = end_x   - min_x + 1                            -- target x position in buffer
  local target_y = end_y   - min_y + 1                            -- target y position in buffer

  -- Bresenham's Line Algorithm (integer-only)
  local delta_x = math.abs(target_x - px)
  local delta_y = math.abs(target_y - py)

  local step_x = (px < target_x) and 1 or -1
  local step_y = (py < target_y) and 1 or -1

  local error_term = delta_x - delta_y

  while true do
    if buffer[py] and buffer[py][px] ~= nil then
      buffer[py][px] = color                            -- draw pixel if in bounds
    end

    if px == target_x and py == target_y then break end

    local error2 = 2 * error_term
    if error2 > -delta_y then error_term = error_term - delta_y; px = px + step_x end
    if error2 <  delta_x then error_term = error_term + delta_x; py = py + step_y end
  end

  return buffer                                                   -- positioned shape buffer
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
  _Line               = _Line, 

  test_logBufferToConsole = test_logBufferToConsole,
  test_outputBufferToPPM  = test_outputBufferToPPM, 

  _context = _context,
}
