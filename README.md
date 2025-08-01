# Spall  
**Sequential Pixel Art Layer Language**

Spall is a minimal and expressive scripting language for defining pixel operation flows — used to generate sprites, tiles, masks, and procedural shapes.





### What?  
A minimal and expressive scripting language for creating pixel operation flows, used to generate sprites, tiles, masks, and procedural shapes.

### Why?  
To let you explore, create, and express pixel art through an intuative, code-driven, layered, and generative medium.

- Want to create subtle tile variations? Just tweak a few values.  
- Want to define an entire tileset with variants? Just stack multiple `# tiles` in one file.  
- Want each output to be slightly different? Use `> RAND` vars.  
- Want to define reusable, composable shapes? Bind a `: Block`, and reuse it across scripts.  
- Want to build procedural shape patterns? Use vars from `> LOOPS` to iterate ops with minimal syntax.  
- Want to output logic masks or room shapes? Use Spall’s matrix output mode, or itegrate it as a Lua module.

It’s not just a novel way to make tiles.  
It’s a precise, expressive, code-driven tool for 2D pixel matrix composition.


## Features

- Minimal syntax, stack-influenced structure
- Built-in color palette, loop, and randomness directives
- Reusable blocks for procedural shape composition
- Multiple output formats: `.png`, matrix data (`.yml`)
- Works as a CLI or Lua module
- Zero dependencies, no GUI or editor required

### Example:

```
> SIZE 8 8          	-- Set global tile dimensions
> COLORS            	-- Define Global Palette
  C1 #000000 : blk
  C2 #ffffff : wht
  C3 #ff0044 : red

: RedRing             -- Define a custom Shape Block, A red ring
  CIRC 4 4 6 red
  CIRC 4 4 3          -- Color undefined because we dont need it, this Shape consumed by the next Op
  ERASE SHAPE         -- Erase last TEMP from the MAIN buffer ('SHAPE' Op consumes last TEMP buffer)

# tileA               -- Define an output Tile, this is what will be exported.
  RECT 0 0 8 8 wht
  RedRing             -- Previously defined Shape 'RedRing' being drawn with no offsets
  LINE 0 0 7 7 blk    -- A white diagonal line is drawn from top-left to bottom-right 
```

## Inspirations

**`Spall`** draws from a lineage of minimal, expressive languages — each one influencing a different part of its design.

**`BASIC`**, created in 1964 by John G. Kemeny and Thomas E. Kurtz at Dartmouth College, was designed to make programming simple and accessible for beginners.  
It later became widely adopted on home computers throughout the 1970s and 80s.  
BASIC inspired Spall’s procedural simplicity and creative spirit, with its focus on clear structure, immediate feedback, and low-friction exploration.

**`PostScript`**, developed in 1982 by John Warnock and Chuck Geschke at Adobe, formalized the use of code to define 2D graphics.  
Its clean design and portability led to widespread adoption in publishing, printing, and layout systems.  
Its stack-based model and drawing primitives directly influenced Spall’s idea of composable, code-driven pixel operations.

**`Forth`**, created in 1970 by Charles H. Moore, was designed for embedded and resource-constrained systems.  
As a stack-based language with postfix syntax and near-zero abstraction overhead, it was used in environments like early robotics, instrumentation, and NASA spacecraft.  
Forth inspired Spall’s focus on minimalism and linear execution.

**`ASM`**, or Assembly, was the original spark. Spall was born from explorations of bytecode, intermediate representations (IR), and instruction streams,
where simplicity, control, and direct intent are the core of expressive power.



## How?

Write `.spl` scripts and run them via the `splgen` CLI tool:

```bash
splgen input.spl --out output/
```

Or embed the Lua module directly:

```lua
local spall = require("splgen")
local tiles = spall.load("tileset.spl")
```

You’ll get back a table of pixel buffers (2D intiger matrices) to use in your game or tool.


## Specification

See the full [language spec](./spall-spec.md) for syntax, ops, buffer model, and output behavior.

---

> **Spall**  
> *Verb*: "to break rock into smaller pieces"  
> *Noun*: "a splinter or chip of stone"
