

# Spall  
***Sequential Pixel Art Layer Language***

### What?  
A minimal and expressive scripting language for creating pixel operation flows, used to generate sprites and tiles.

### Why?  
To let you explore, create, and express pixel art through a code-driven, layered, and generative medium.

- Want to create subtle tile variations? Just tweak a few values.  
- Want to define an entire tileset with variants? Just stack multiple `# tiles` in one file.  
- Want each output to be slightly different? Use `> RAND` vars.  
- Want to define reusable, composable shapes? Bind a `: Block`, and reuse it across scripts.  
- Want to build procedural shape patterns? Use vars from `> LOOPS` to iterate ops with minimal syntax.  
- Want to output logic masks or room shapes? Use Spall’s raw matrix mode; no `.png` required.

It’s not just a novel way to make tiles. It’s a precise, minimal scripting tool for 2D pixel matrix operations.

### Inspirations

Spall draws from a lineage of minimal, expressive languages, each one influencing a different part of its design.

**BASIC**, created in 1964 by John G. Kemeny and Thomas E. Kurtz at Dartmouth College, was designed to make programming simple and accessible for beginners.  
It later became widely adopted on home computers throughout the 70s and 80s.  
BASIC inspired Spall’s procedural simplicity and creative spirit, with its focus on clear structure, immediate feedback, and low-friction exploration.

**PostScript**, developed in 1982 by John Warnock and Chuck Geschke at Adobe, formalized the use of code to define 2D graphics.  
Its clean design and portability led to widespread adoption in publishing, printing, and layout systems.  
Its stack-based model and drawing primitives directly influenced Spall’s idea of composable, code-driven pixel operations.

**Forth**, created in 1970 by Charles H. Moore, was designed for embedded and resource-constrained systems.  
As a stack-based language with postfix syntax and near-zero abstraction overhead, it was used in environments like early robotics, instrumentation, and NASA spacecraft.  
Forth inspired Spall’s focus on minimalism and linear execution.

**ASM**, or Assembly, was the original spark. Spall was born from explorations of bytecode, intermediate representations (IR), and instruction streams,  
where simplicity, control, and direct intent are the core of expressive power.

### Name Meaning  
> **Verb** — "break (ore, rock, or stone) into smaller pieces, especially in preparation for sorting."  
> **Noun** — "a splinter or chip, especially of rock."

### How?  
You write a `.spl` script.  
It outputs `.png` tiles — no GUI, no editor, just pure ops (for now).

<!-- ---------------------------------------------------------------------------------------------------------------------------------------- -->

## 1. File Layout & Execution Model

### Spall Execution
Spall code is written in `.spl` files and executed top-down.  
The order of definition blocks must be:

```
> global config   -- COLORS, LOOPS, RANDS, SIZE W H
: BlockDef        -- Bind the following ops as a reusable named Shape
# tileDef         -- Bind the following ops to output a .png or return a matrix
```

| Prefix | Meaning                             |
|--------|-------------------------------------|
| `>`    | Global directive or config block    |
| `:`    | Reusable **Block** definition           |
| `#`    | Output **Tile** definition (.png saved) |

### Pixel Buffer Types

- **TEMP** — Temporary scratch buffer for the current op.  
  Auto-merged to MAIN after each op unless bound to a name or consumed.  
  Can be used as a shape to mask, stamp, or merge.

- **MAIN** — The cumulative tile buffer.   
  Built by implicitly merging TEMP to MAIN after each op.  
  The accumulated tile data for the current `# tile`.

- **SHAPE** — Predefined Shape buffers,  
  Your named buffers created from bound `TEMP`s or `BlockDef`s.    
  These store reusable pixel data for composition or masking.

### Buffer Merge Behavior

At each stage, if the TEMP buffer is not bound or consumed, it is implicitly merged into the MAIN buffer.  
A TEMP buffer can be bound to a name using `OP : name`, turning it into a SHAPE.

| Situation                     | Result                            |
|------------------------------|------------------------------------|
| TEMP is consumed              | TEMP is discarded (e.g. `ERASE SHAPE`) |
| TEMP is named                 | TEMP is saved (e.g. `LINE 0 0 7 7 : diag`) |
| TEMP is left unbound          | Implicit merge into MAIN on next op |
| TEMP is last op in tile block | Auto-merged to MAIN unless named |

### Output Structure

When run via the `splgen` CLI, a `.spl` file will output the defined tiles  
as either `.png` files or a `.yml` file containing the matrix data, depending on the command-line arguments.  
`splgen` can also be used as a Lua module (`require("splgen")`) to integrate `.spl` parsing and execution into existing Lua projects.

<!-- ---------------------------------------------------------------------------------------------------------------------------------------- -->


## 2. Config & Directives
`> SIZE`

`> COLORS`

`> VARS`

`> LOOPS`

`> RANDS`



Others you plan (`> FRAMES, > INFO`)

C0 is a reserved color constant representing transparency.
It is automatically aliased to 'none'.
These aliases are built-in and cannot be overridden.

<!-- ---------------------------------------------------------------------------------------------------------------------------------------- -->


## 3. Block & Tile definitions
`: name` — Shape block definition

`# name` — Tile output definition

Scoping rules

What blocks return (a TMP buffer)

TMP naming rules inside blocks

<!-- ---------------------------------------------------------------------------------------------------------------------------------------- -->


## 4. Pixel Operations - Ops
Format: OP arg1 arg2 ...

Per-op entry:

Name

Args

Writes to TMP? Y/N

Example

You can categorize:

Draw Ops (RECT, CIRC, LINE, GRID, BLIT)

Logic Ops (MELD, INVERT, WIPE)

Meta Ops (MASK, RAND etc.)

Shape stroke & fill 

(Summarized)
```
CIRC x y r c	              -- Fill only
CIRC x y r c EDGE	          -- Stroke only (default width 1)
CIRC x y r c EDGE 2	        -- Stroke only, width 2
CIRC x y r c EDGE 2 IN	    -- Stroke only, width 2, inner edge
CIRC x y r c1 c2	          -- Fill + stroke, stroke width 1
CIRC x y r c1 c2 2	        -- Fill + stroke, stroke width 2
CIRC x y r c1 c2 2 OUT	    -- Fill + stroke, stroke outer edge
```
✅ Why this rocks
No sentinel tokens (none, C0) — instead, use positional awareness

Backward compatible — single-color still means fill

Postfix STROKE adds flexibility without breaking simplicity

Optional args (width, edge mode) follow classic IR/forth-style extension

Totally parseable: arity of args drives dispatch

<!-- ---------------------------------------------------------------------------------------------------------------------------------------- -->


## 5. Iterators (LOOPS)
`> LOOPS` syntax

How iterator values are injected

Static expansion model

Loop naming convention (ix, iy etc.)

<!-- ---------------------------------------------------------------------------------------------------------------------------------------- -->


## 6. Random Variables (RANDS)
```
> RANDS
  1 5 : rx
  2 6 : ry
```

<!-- ---------------------------------------------------------------------------------------------------------------------------------------- -->


## 7. Output Modes
.png

.yml

future: .json, raw matrix, preview shell

<!-- ---------------------------------------------------------------------------------------------------------------------------------------- -->


## 8. Embedding / Integration
Lua module usage

Matrix API (access pattern, structure)

<!-- ---------------------------------------------------------------------------------------------------------------------------------------- -->






## Expression binding model:
```
<math expr> : <name>
```
And conditional expressions are a special case:
```
IF <cond> THEN <val1> ELSE <val2> : <name>
```


## ✅ .spd — Spall Pixel Data

`> IMPORT` loads named shape buffers from a `.spd` file — a plain Lua table.
`.spd` files can be generated from `.spl` scripts using the `splgen` CLI tool.

Each file returns a table of named shapes:
```lua
return {
  room = {
    w = 4, h = 4,
    px = {
      {0, 1, 1, 0},
      {1, 2, 2, 1},
      {1, 2, 2, 1},
      {0, 1, 1, 0},
    }
  },

  fog = {
    w = 4, h = 4,
    px = {
      {0, 0, 0, 0},
      {0, 1, 1, 0},
      {0, 1, 1, 0},
      {0, 0, 0, 0},
    }
  }
}
```

### potential future custom format (transpiled to lua tables):
```

> META
  NAME : tileset1
  TAGS : tilesets masks
	AUTHOR : Quillwyrm

: room 4 4
  0 1 1 0 
  1 2 2 1 
  1 2 2 1 
  0 1 1 0
	
```

– `px` must be a 2D array of raw color indices  
– Values are `0..n` where `0` is transparent (`C0`), others are user-defined (`C1`..`Cn`)  


```
> IMPORT
  tiles/tileset.spd
  room : base_room
  fog  : fog_mask

```

– Each `.spd` file can define multiple named shapes  
– Bind names manually after file path  
– Shapes are inert until used in ops





													