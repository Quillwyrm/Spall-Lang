# Spall - [IN DEVELOPMENT]
**Sequential Pixel Art Layer Language**

Spall is a minimal and expressive scripting language for defining pixel operations. Used to generate sprites, tiles, masks, and procedural shapes.  
It's currently under development with an alpha available soon. 





### What?  
A minimal scripting language, with a core written in Lua, for procedurally defining pixel art. Used to generate sprites, tiles, masks, and procedural shapes.

### Why?  
To let you explore, create, and express pixel art through an intuative, code-driven, layered, and generative medium.

- Want to create subtle tile variations? Just tweak a few values.  
- Want to define an entire tileset with variants? Just stack multiple `# tiles` in one file.  
- Want each output to be slightly different? Use vars from the `> rands` block.  
- Want to define reusable, composable shapes? Bind a `: Block`, and reuse it across tiles in a script.  
- Want to build procedural shape patterns? Use vars from `> loops` to iterate ops with minimal syntax.  
- Want to output logic masks or room shapes? Use the Spall Pixel Data `.spd` format, and use the 2D int array (stored as a Lua table).

It’s not just a novel way to make tiles.  
It’s a precise, expressive, code-driven tool for 2D pixel matrix composition.


## Features

- Minimal syntax, stack-influenced structure
- Built-in color palette, loop, and randomness directives
- Reusable blocks for procedural shape composition
- Multiple output formats: `.png`, pixel data `.spd`
- Works as a CLI or Lua module
- Zero dependencies, no GUI or editor required

### Example:

```lua
<<<<<<< HEAD
> size 8 8            -- Set global tile dimensions
=======
> size 16 16  -- Set global Tile size
>>>>>>> 4cb847f7645f480d1aecdb665ab94d4bb53c9b39

> palette
  C1 2b2b2b : blk
  C2 e6ddd2 : mrt     -- mortar
  C3 a4442f : brk     -- brick
  C4 5aa64e : mos     -- moss
  C5 143d12 : deep    -- moss shade

> vars
  4    : cell_w
  3    : cell_h
  2    : stagger_px
  0.20 : mossDensity      -- 0..1 fraction of placements

> rands
  -1 1 : rx
  -1 1 : ry

> loops
  1 16 4 : ix
  1 16 3 : iy

--== Create Mask Blocks (Named reusable buffers, no set color denotes we're only using the shape.) 

: MortarLines                 -- thin lines = mask of mortar seams
  grid 1 1, 4 6 cell_w cell_h stagger ROW stagger_px

: BrickFill                   -- full field mask (before removing mortar)
  rect 1 1, 16 16

: BrickMass                   -- bricks = field minus mortar seams
  merge BrickFill MortarLines EXCLUDE           -- mask: 1 inside bricks, 0 elsewhere

: Cracks                      -- hairline chips to subtract from bricks
  line 2 3, 15 12
  line 8 1, 9 16

: BrokenBricks                -- bricks with cracks removed
  merge BrickMass Cracks EXCLUDE

-- Moss sprite as a tiny mask
: Moss
  blit 0 0; blit 1 0
  blit 0 1; blit 1 1
  blit 1 2; blit 2 1

: MossScatter
  scatter Moss mossDensity     -- produces a mask of moss placements

: ShadedMoss
 MossScatter deep 2 2
 MossScatter

: MossOnBricks                -- keep moss only where bricks exist
  merge ShadedMoss BrokenBricks INTERSECT

--== Output Tiles 

# bricks_moss
  rect mrt 1 1, 16 16               -- paint background mortar
  BrokenBricks brk 1 1              -- draw brick mass recolored to brick
  MossOnBricks mos 1 1              -- draw moss on top (uses moss color)
  blit deep ix+rx iy+ry             -- subtle random speckle 
```

## Inspirations

**`Spall`** draws from a lineage of minimal, expressive languages — each one influencing a different part of its design.

**`BASIC`**, created in 1964 by John G. Kemeny and Thomas E. Kurtz at Dartmouth College, was designed to make programming simple and accessible for beginners.
It later became widely adopted on home computers throughout the 70s and 80s.
BASIC inspired Spall’s procedural simplicity and creative spirit, with its focus on clear structure, immediate feedback, and low-friction exploration.

**`PostScript`**, developed in 1982 by John Warnock and Chuck Geschke at Adobe, formalized the use of code to define 2D graphics.
Its clean design and portability led to widespread adoption in publishing, printing, and layout systems.
Its stack-based model and drawing primitives directly influenced Spall’s idea of composable, code-driven pixel operations.

**`Forth`**, created in 1970 by Charles H. Moore, was designed for embedded and resource-constrained systems.
As a stack-based language with postfix syntax and near-zero abstraction overhead, it was used in environments like early robotics, instrumentation, and NASA spacecraft.
Forth inspired Spall’s focus on minimalism and linear execution.

**`ASM`**, or Assembly, was the original spark; Spall was born from explorations of bytecode, intermediate representations (IR), and instruction streams,
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
