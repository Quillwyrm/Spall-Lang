-- SPALL INTERNAL DSL CORE --

-- Constructors & Initialization ----------------------------------------------------------------------------------------

-- **`_PixelBuffer(width, height, x_pos?, y_pos?)`**
-- > Construct a new pixel buffer.
-- Returns a 2D table indexed as `[y][x]`, with optional position metadata (`.x`, `.y`).
-- Each cell holds a palette index (integer). All pixels default to 0 (transparent).
-- `width` - Width of the buffer in pixels.
-- `height` - Height of the buffer in pixels.
-- `x_pos` - *(optional)* x-position for alignment during merge/draw.
-- `y_pos` - *(optional)* y-position for alignment during merge/draw.
-- `return` - A new pixel buffer table with metadata.
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

-- **`_initPalette()`**
-- > Initialize default color aliases and index mappings.
-- Returns a palette table mapping named colors (e.g. `red`, `blk`) and canonical keys (`C1`, `C2`) to indices.
-- `C0` / `none` is always 0 (transparent).
-- `return` - A palette table: `{ name → index, Cn → index }`
local _initPalette = function()
  return {
    C0 = 0,
    none = 0,
    C1 = 1,
    blk = 1,
    C2 = 2,
    wht = 2,
    C3 = 3,
    red = 3,
    C4 = 4,
    grn = 4,
    C5 = 5,
    blu = 5,
    C6 = 6,
    yel = 6,
    C7 = 7,
    mag = 7,
    C8 = 8,
    cya = 8,
  }
end

-- **`_initColors()`**
-- > Initialize default RGB color table.
-- Indexed by palette index, returns raw RGB triplets (or RGBA for index 0).
-- Used for output conversion (e.g. to PPM or PNG).
-- `return` - A color map: `{ [index] = {r, g, b [,a]} }`
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
-- **`_initContextState()`**
-- > Initialize global Spall context state.
-- Holds the current palette, color table, temp buffer, and named tiles/user blocks.
-- `return` - A context table used for Spall DSL execution.
local _initContextState = function()
  return {
    palette = _initPalette(),
    colors = _initColors(),
    temp = nil,
    tiles = {},
    user = {},
  }
end

local _context = _initContextState()
-- Utility Ops -----------------------------------------------------------------------------------------------------------

-- **`_mergeUnion(src, dst)`**
-- > Merge two buffers with union logic.
-- Returns a new buffer the size of `dst`, with all non-zero pixels from `src` overwriting `dst`.
-- Inputs are unchanged (pure operation).
-- `src` - Positioned buffer (with `.x` and `.y`) to merge in.
-- `dst` - Base buffer to merge onto (must not be positioned).
-- `return` - A new buffer with the union result.
local _mergeUnion = function(src, dst)
  assert(src.x and src.y, "_mergeUnion: src buffer must have .x and .y") -- enforce shape offset

  local out = _PixelBuffer(dst.w, dst.h) -- allocate output buffer, same size as dst
  for y = 1, dst.h do
    for x = 1, dst.w do
      local src_y = y - src.y + 1 -- map output y to source-relative coordinates
      local src_x = x - src.x + 1 -- map output x to source-relative coordinates
      local s = (src[src_y] and src[src_y][src_x]) or 0 -- get source pixel, or 0 if out-of-bounds
      local d = dst[y][x] or 0 -- get destination pixel
      out[y][x] = (s ~= 0) and s or d -- union logic: src pixel overwrites if non-zero
    end
  end
  return out
end -- return merged result (pure)

-- **`_mergeSubtract(src, dst)`**
-- > Merge two buffers with subtraction logic.
-- Returns a new buffer where any non-zero pixel in `src` erases the corresponding pixel in `dst`.
-- Inputs are unchanged (pure operation).
-- `src` - Positioned buffer (with `.x` and `.y`) acting as the mask to subtract.
-- `dst` - Base buffer to subtract from (must not be positioned).
-- `return` - A new buffer with the subtraction result.
local _mergeSubtract = function(src, dst)
  assert(src.x and src.y, "_mergeSubtract: src buffer must have .x and .y") -- enforce shape offset

  local out = _PixelBuffer(dst.w, dst.h) -- allocate output buffer, same size as dst
  for y = 1, dst.h do
    for x = 1, dst.w do
      local src_y = y - src.y + 1 -- map output y to source-relative coordinates
      local src_x = x - src.x + 1 -- map output x to source-relative coordinates
      local s = (src[src_y] and src[src_y][src_x]) or 0 -- get source pixel, or 0 if out-of-bounds
      local d = dst[y][x] or 0 -- get destination pixel
      out[y][x] = (s ~= 0) and 0 or d -- subtraction logic: erase wherever src is non-zero.
    end
  end
  return out
end -- return merged result (pure)

-- **`_mergeIntersect(src, dst)`**
-- > Merge two buffers with intersection logic.
-- Returns a new buffer where only overlapping non-zero pixels from both `src` and `dst` are kept.
-- Inputs are unchanged (pure operation).
-- `src` - Positioned buffer (with `.x` and `.y`) acting as the intersecting mask.
-- `dst` - Base buffer to intersect with (must not be positioned).
-- `return` - A new buffer with the intersection result.
local _mergeIntersect = function(src, dst)
  assert(src.x and src.y, "_mergeIntersect: src buffer must have .x and .y") -- enforce shape offset

  local out = _PixelBuffer(dst.w, dst.h) -- allocate output buffer, same size as dst
  for y = 1, dst.h do
    for x = 1, dst.w do
      local src_y = y - src.y + 1 -- map output y to source-relative coordinates
      local src_x = x - src.x + 1 -- map output x to source-relative coordinates
      local s = (src[src_y] and src[src_y][src_x]) or 0 -- get source pixel, or 0 if out-of-bounds
      local d = dst[y][x] or 0 -- get destination pixel
      out[y][x] = (d ~= 0 and s ~= 0) and d or 0 -- Intersection logic: Keep only overlapping non-zero pixels.
    end
  end
  return out
end -- return merged result (pure)

-- **`_mergeExclude(src, dst)`**
-- > Merge two buffers with exclusion logic (XOR).
-- Returns a new buffer where only non-overlapping non-zero pixels from `src` or `dst` are kept.
-- Inputs are unchanged (pure operation).
-- `src` - Positioned buffer (with `.x` and `.y`) acting as the exclusion mask.
-- `dst` - Base buffer to exclude from (must not be positioned).
-- `return` - A new buffer with the exclusion (XOR) result.
local _mergeExclude = function(src, dst)
  assert(src.x and src.y, "_mergeExclude: src buffer must have .x and .y") -- enforce shape offset

  local out = _PixelBuffer(dst.w, dst.h) -- allocate output buffer, same size as dst
  for y = 1, dst.h do
    for x = 1, dst.w do
      local src_y = y - src.y + 1 -- map output y to source-relative coordinates
      local src_x = x - src.x + 1 -- map output x to source-relative coordinates
      local s = (src[src_y] and src[src_y][src_x]) or 0 -- get source pixel, or 0 if out-of-bounds
      local d = dst[y][x] or 0 -- get destination pixel

      out[y][x] = (s ~= 0 and d == 0) and s -- only in src
        or (d ~= 0 and s == 0) and d -- only in dst
        or 0 -- both or neither → erase
    end
  end
  return out
end -- return merged result (pure)

-- **`_merge(src, dst, mode)`**
-- > Dispatch to a specific merge operation based on `mode`.
-- Supported modes: `UNION`, `SUBTRACT`, `INTERSECT`, `EXCLUDE`.
-- Inputs are unchanged (pure operation); returns a new merged buffer.
-- `src` - Positioned buffer (with `.x` and `.y`) used as the merge operand.
-- `dst` - Base buffer to merge into (must not be positioned).
-- `mode` - Merge strategy: one of `"UNION"`, `"SUBTRACT"`, `"INTERSECT"`, or `"EXCLUDE"`.
-- `return` - A new buffer with the result of the selected merge strategy.
local _merge = function(src, dst, mode)
  assert(mode, "_merge: merge mode required")

  if mode == "UNION" then
    return _mergeUnion(src, dst)
  elseif mode == "SUBTRACT" then
    return _mergeSubtract(src, dst)
  elseif mode == "INTERSECT" then
    return _mergeIntersect(src, dst)
  elseif mode == "EXCLUDE" then
    return _mergeExclude(src, dst)
  else
    error("_merge: unknown merge mode: " .. tostring(mode))
  end
end

-- **`_commitTemp(tile_name)`**
-- > Merge `temp` into the tile buffer then clear `temp`.
-- If the tile doesn’t exist, it is created from `temp` as-is.
-- `tile_name` - The name of the target tile buffer.
-- `⚠️effect` - Mutates `_context.tiles` and clears `temp`.
local _commitTemp = function(tile_name)
  local temp = _context.temp
  if not temp then
    return
  end -- no-op if temp is empty

  assert(tile_name, "_commitTemp: tile name required")
  assert(temp.x and temp.y, "_commitTemp: temp must be a positioned buffer")

  local existing = _context.tiles[tile_name]

  if existing then
    local merged = _mergeUnion(temp, existing) -- merge temp into existing tile using union logic
    _context.tiles[tile_name] = merged -- update tile with merged result
  else
    _context.tiles[tile_name] = temp -- first write: assign directly
  end
  _context.temp = nil -- clear temp after commit
end

-- **`_last()`**
-- > Return the current `temp` buffer.
-- Used to refer to the most recent unnamed shape.
-- `return` - The current `_context.temp` buffer.
local _last = function()
  return _context.temp
end

-- Drawing Primitives ----------------------------------------------------------------------------------------------------

-- **`_Rect(color, origin_x, origin_y, width, height)`**
-- > Create a rectangular shape buffer filled with `color`.
-- Returns a buffer of size `width × height`, positioned at (`origin_x`, `origin_y`).
-- `color` - Palette index to fill with.
-- `origin_x` - X-position of the top-left corner.
-- `origin_y` - Y-position of the top-left corner.
-- `width` - Width of the rectangle in pixels.
-- `height` - Height of the rectangle in pixels.
-- `return` - A new positioned shape buffer.
local _Rect = function(color, origin_x, origin_y, width, height)
  local buf = _PixelBuffer(width, height, origin_x, origin_y) -- allocate minimal buffer at (origin_x, origin_y)
  for py = 1, height do
    for px = 1, width do
      buf[py][px] = color -- fill entire region with color
    end
  end
  return buf
end -- positioned shape buffer

-- **`_Blit(color, x, y)`**
-- > Create a 1×1 buffer with a single pixel.
-- Pixel is placed at (`x`, `y`) in tile space.
-- `color` - Palette index to use.
-- `x` - X-coordinate of the pixel.
-- `y` - Y-coordinate of the pixel.
-- `return` - A new 1×1 buffer positioned at (x, y).
local _Blit = function(color, x, y)
  local buf = _PixelBuffer(1, 1, x, y) -- 1×1 buffer at position (x, y)
  buf[1][1] = color -- set pixel
  return buf
end -- positioned shape buffer

-- **`_Circ(color, center_x, center_y, diameter)`**
-- > Create a filled circular shape buffer.
-- Circle is centered at (`center_x`, `center_y`) and packed tightly in its buffer.
-- `color` - Palette index to fill with.
-- `center_x` - X-coordinate of the circle center.
-- `center_y` - Y-coordinate of the circle center.
-- `diameter` - Pixel width of the circle.
-- `return` - A new positioned circular buffer.
local _Circ = function(color, center_x, center_y, diameter)
  local size = diameter -- buffer width and height
  local r = diameter / 2 -- radius as float
  local r2 = (r - 0.25) ^ 2 -- radius², biased for tighter fill (pixel perfect)

  local origin_x = math.floor(center_x - r + 1) -- buffer x-pos so circle center lands on (center_x, center_y)
  local origin_y = math.floor(center_y - r + 1) -- buffer y-pos (same logic for vertical)

  local buf = _PixelBuffer(size, size, origin_x, origin_y) -- allocate centered, minimal buffer

  local mid = (diameter + 1) / 2 -- circle center in local buffer coords

  for py = 1, size do
    for px = 1, size do
      local offset_x = px - mid -- x offset from center
      local offset_y = py - mid -- y offset from center
      if offset_x * offset_x + offset_y * offset_y <= r2 then
        buf[py][px] = color -- fill pixel if inside circle
      end
    end
  end
  return buf
end -- positioned shape buffer

-- **`_Line(color, start_x, start_y, end_x, end_y)`**
-- > Create a line-shaped shape buffer using Bresenham’s algorithm.
-- Line spans from (`start_x`, `start_y`) to (`end_x`, `end_y`) in `color`.
-- `color` - Palette index for the line.
-- `start_x` - X of the start point.
-- `start_y` - Y of the start point.
-- `end_x` - X of the end point.
-- `end_y` - Y of the end point.
-- `return` - A new buffer containing the line, positioned at min(start, end).
local _Line = function(color, start_x, start_y, end_x, end_y)
  local min_x = math.min(start_x, end_x) -- bounding box origin x
  local min_y = math.min(start_y, end_y) -- bounding box origin y

  local max_x = math.max(start_x, end_x) -- bounding box extent x
  local max_y = math.max(start_y, end_y) -- bounding box extent y

  local buffer_width = max_x - min_x + 1 -- buffer size in x
  local buffer_height = max_y - min_y + 1 -- buffer size in y

  local buffer = _PixelBuffer(buffer_width, buffer_height, min_x, min_y)

  -- Translate line coordinates into local buffer space (1-indexed)
  local px = start_x - min_x + 1 -- current x position in buffer
  local py = start_y - min_y + 1 -- current y position in buffer

  local target_x = end_x - min_x + 1 -- target x position in buffer
  local target_y = end_y - min_y + 1 -- target y position in buffer

  -- Bresenham's Line Algorithm (integer-only)
  local delta_x = math.abs(target_x - px)
  local delta_y = math.abs(target_y - py)

  local step_x = (px < target_x) and 1 or -1
  local step_y = (py < target_y) and 1 or -1

  local error_term = delta_x - delta_y

  while true do
    if buffer[py] and buffer[py][px] ~= nil then
      buffer[py][px] = color -- draw pixel if in bounds
    end

    if px == target_x and py == target_y then
      break
    end

    local error2 = 2 * error_term
    if error2 > -delta_y then
      error_term = error_term - delta_y
      px = px + step_x
    end
    if error2 < delta_x then
      error_term = error_term + delta_x
      py = py + step_y
    end
  end

  return buffer -- positioned shape buffer
end

-- **`_draw(source_buffer, color, target_x, target_y)`**
-- > Copy and recolor a buffer, placing it at a new position.
-- Input buffer is untouched; result is a fresh recolored + repositioned copy.
-- Cannot recolor to `0` (transparent), as that would strip buffer structure.
-- `source_buffer` - A shape buffer to reuse.
-- `color` - New color to apply to all non-zero pixels (must not be 0).
-- `target_x` - X-position to place the buffer.
-- `target_y` - Y-position to place the buffer.
-- `return` - A new buffer placed and recolored.
local _draw = function(source_buffer, color, target_x, target_y)
  assert(source_buffer and source_buffer.w and source_buffer.h, "_draw: source_buffer must be a valid pixel buffer")
  assert(color ~= 0, "_draw: cannot recolor to transparent (index 0)")

  local width = source_buffer.w
  local height = source_buffer.h

  local drawn = _PixelBuffer(width, height, target_x, target_y)

  for py = 1, height do
    for px = 1, width do
      local src_color = source_buffer[py][px]
      if src_color and src_color ~= 0 then
        drawn[py][px] = color
      end
    end
  end
  return drawn
end

-- Debug --------------------------------------------------------------------------------------------------------------

local test_logBufferToConsole = function(name, buf)
  local width = buf.w
  local height = buf.h
  print(name .. string.rep("-", 20 - #name))
  print("w: " .. width .. " - h: " .. height)
  print(string.rep("-", 4 + (width * 2)))
  io.write("   X")
  for x = 1, width do
    io.write(" " .. x)
  end
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
-- Useful for previewing Spall output in an image viewer or converting to PNG later
local test_outputBufferToPPM = function(buf, path, palette)
  assert(buf and buf.w and buf.h, "Invalid buffer")
  assert(palette, "Palette (color index → RGB) required")

  local file = assert(io.open(path, "w"))
  file:write("P3\n", buf.w, " ", buf.h, "\n255\n") -- ASCII PPM header

  for y = 1, buf.h do
    for x = 1, buf.w do
      local idx = buf[y][x] or 0
      local rgb = palette[idx] or { 0, 0, 0 }
      file:write(rgb[1], " ", rgb[2], " ", rgb[3], "  ")
    end
    file:write("\n")
  end

  file:close()
end

-- Export --------------------------------------------------------------------------------------------------------------

return {
  -- Core constructors
  _PixelBuffer = _PixelBuffer,
  _initContextState = _initContextState,
  _initPalette = _initPalette,
  _initColors = _initColors,

  -- Merge operations
  _mergeUnion = _mergeUnion,
  _mergeSubtract = _mergeSubtract,
  _mergeIntersect = _mergeIntersect,
  _mergeExclude = _mergeExclude,
  _merge = _merge,

  -- Temp / tile ops
  _commitTemp = _commitTemp,
  _last = _last,

  -- Drawing primitives
  _Rect = _Rect,
  _Blit = _Blit,
  _Circ = _Circ,
  _Line = _Line,
  _draw = _draw,

  -- Debug / testing
  test_logBufferToConsole = test_logBufferToConsole,
  test_outputBufferToPPM = test_outputBufferToPPM,

  -- Global state
  _context = _context,
}

------------------------------------
