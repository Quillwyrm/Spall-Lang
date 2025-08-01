# Spall 

`Sequential Pixel Art Layer Language`

An expressive procedural instruction language for generating pixel art tiles and sprites.



## Whats Spall?
A scripting language tailored for creating simple and expressive pixel operation flows; to output sprites and tiles.



## Why Spall?
To let you explore, create, and express pixel art through a code-driven, layered, and generative medium.

- Want to create subtle tile variations? Just tweak a few values.

- Want to define an entire tileset with variants? Just stack multiple `# tiles` in one file.

- Want each output to be slightly different? Use `> RAND` vars.

- Want to define reusable, composable shapes? Bind a `: Block`, and reuse it across scripts.

- Want to build procedural shape patterns? Use vars from `> LOOPS` to iterate ops with minimal syntax.

- Want to output logic masks or room shapes? Use Spall’s raw matrix mode; no .png required.

It’s not just a novel way to make tiles. it’s a precise, minimal scripting tool for 2D pixel matrix operations.



## Inspirations

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



## How?

You write a `.spl` script.  
It outputs `.png` tiles — no GUI, no editor, just pure ops. (for now)


## Core Concepts

### Buffers

- **TEMP** — Temporary scratch buffer for the current op.  
  Auto-merged to MAIN after each op unless bound to a name or consumed.
- **MAIN** — The cumulative tile buffer.  
  Built by implicitly merging TEMP to MAIN after each op.

### Merge Semantics

| Situation                     | Result                            |
|------------------------------|------------------------------------|
| TEMP is consumed              | TEMP is discarded (e.g. `ERASE SHAPE`) |
| TEMP is named                 | TEMP is saved (e.g. `LINE 0 0 7 7 : diag`) |
| TEMP is left unbound          | Implicit merge into MAIN on next op |
| TEMP is last op in tile block | Auto-merged to MAIN unless named |

### Identifiers and Prefixes

| Prefix | Meaning                             |
|--------|-------------------------------------|
| `>`    | Global directive or config block    |
| `:`    | Reusable **Block** definition           |
| `#`    | Output **Tile** definition (.png saved) |



## Global Directives

Use `>` to declare global settings.

### Set tile size:

```
> TILESIZE 8 8
```

### Define a color palette:

```
> COLORS
  C1 #000000 : blk
  C2 #ffffff : wht
  C3 #ff0044 : red
  C4 #44ccff : ice
```

You can then use color aliases (e.g. `blk`, `red`) in drawing ops:

```
LINE 0 0 7 7 red
```

---

## Blocks and Tiles

### Block Definitions (`: name w h`)

Reusable shape buffers.  
TEMP buffers bound to names are **local** to the block.

Example:
```
: CrossLines 8 8
  LINE 0 0 7 7 : diag1
  LINE 0 7 7 0 : diag2
  MELD diag1 diag2 OR : cross
```

### Tile Definitions (`# name w h`)

Declares a final output tile.  
After the block runs, the tile’s MAIN buffer is saved as `name.png`.

Example:
```
# charged_core 8 8
  SparkCore          -- draws into MAIN
  CrossLines ERASE   -- uses TEMP 'cross' to erase
  FrameBox           -- draws a border
```

---

## Drawing Ops

- `RECT x y w h [color]`
- `LINE x1 y1 x2 y2 [color]`
- `CIRC cx cy r [color]`
- `GRID w h [color]` — grid pattern fill

Color is optional; defaults to C1 (palette index 1).

---

## Stack Ops

### TEMP Naming

```
LINE 0 0 7 7 : diag
```

### Merge TEMPs

```
MELD a b OR
```

Supported logic ops: `OR`, `AND`, `XOR`, `SUB`


### Shapes
```
CIRC 1 2 3 : Foo     -- Circle shape bound to Foo
RECT 0 0 8 8         -- Draw rect
ERASE Foo            -- Erase Foo from MAIN buffer

LINE 0 0 8 8         -- Line with no name, used by SHAPE implicitly
ERASE SHAPE          -- Erase previous op from MAIN
```

`SHAPE` uses the previous op’s TEMP buffer — allowing you to apply simple shapes without naming them.

`ERASE` expects a *Shape* input. A Shape can be:
- an anonymous TEMP buffer (via `SHAPE`)
- a named TEMP (via `OP : name`)
- or a named Block (i.e. a `: BlockName` definition)




## Examples

### A radial shape block

```
: RadialShape 8 8
  CIRC 4 4 3
  GRID 8 8
  ERASE SHAPE
```

### A composite tile using the above

```
# walk_diag 8 8
  RECT 0 0 8 8 blk
  ERASE RadialShape
  LINE 0 0 7 7 wht
```

### A colored glowing core

```
: SparkCore
  CIRC 4 4 2 red
  CIRC 4 4 1 ice
  ERASE SHAPE
```

---

## Output

- Each `# name w h` → outputs `name.png`
- Each `: name w h` → defines a reusable drawing block
- TEMPs are merged, consumed by OPs like `SHAPE`, or saved explicitly

---

## Why Spall?

- You want **procedural control** over tile graphics
- You love **stack languages** or **IR-style graphics pipelines**
- You’re building **1-bit** or **palette-driven** tools and games
- You want to **see your code become pixels**

---

## Project Structure

| Layer        | Role                                 |
|--------------|--------------------------------------|
| Spall DSL    | Concise graphics IR syntax           |
| Transpiler   | Converts Spall code into Lua ops     |
| Lua Runtime  | Executes buffer mutation logic       |
| Matrix<int>  | Backing tile data structure          |

---

## 🧾 License

MIT

