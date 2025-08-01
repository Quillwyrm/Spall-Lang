# Spall 
> Sequential Pixel Art Layer Language
A procedural instruction language for generating pixel tiles and sprites, inspired by minimal stack scripting (PostScript, Forth), BASIC, and ASM.

---

## What is Spall?

Spall is a procedural art language for describing how to *construct* sprites and tile graphics by composing operations 
like `CIRC`, `LINE`, `GRID`, `MELD`, and `ERASE`. Each operation manipulates pixel buffers in an immediate-mode, linear stack flow.

You write a `.spl` script.  
It outputs `.png` tiles — no GUI, no editor, just pure ops. (for now)

---

## Core Concepts

### Buffers

- **TEMP** — Temporary scratch buffer for the current op.  
  Auto-merged to MAIN after each op unless saved or consumed.
- **MAIN** — The cumulative tile buffer.  
  Built by merging TEMPs over time.

### Merge Semantics

| Situation                     | Result                            |
|------------------------------|------------------------------------|
| TEMP is consumed              | TEMP is discarded (e.g. `ERASE MASK`) |
| TEMP is named                 | TEMP is saved (e.g. `LINE 0 0 7 7 : diag`) |
| TEMP is left unbound          | Implicit merge into MAIN on next op |
| TEMP is last op in tile block | Auto-merged to MAIN unless named |

### Identifiers and Prefixes

| Prefix | Meaning                             |
|--------|-------------------------------------|
| `>`    | Global directive or config block    |
| `:`    | Reusable block definition           |
| `#`    | Output tile definition (.png saved) |

---

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

Reusable procedural components.  
TEMP names are **local** to the block.

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

Common operations that draw to TEMP:

- `RECT x y w h [color]`
- `LINE x1 y1 x2 y2 [color]`
- `CIRC cx cy r [color]`
- `GRID w h [color]` — grid pattern fill

Color is optional; defaults to palette index 1.

---

## Stack Ops

### TEMP Naming

```
LINE 0 0 7 7 : diag
```

### Merge TEMPs

```
MELD a b OR : combo
```

Supported logic ops: `OR`, `AND`, `XOR`, `SUB`

### Masking

```
Foo MASK
ERASE MASK
```

This uses TEMP as a mask for the next op.

---

## Examples

### A radial mask block

```
: RadialMask 8 8
  CIRC 4 4 3
  GRID 8 8
  ERASE MASK
```

### A composite tile using the above

```
# walk_diag 8 8
  RECT 0 0 8 8 blk
  ERASE RadialMask
  LINE 0 0 7 7 wht
```

### A colored glowing core

```
: SparkCore
  CIRC 4 4 2 red
  CIRC 4 4 1 ice
  ERASE MASK
```

---

## Output

- Each `# name w h` → outputs `name.png`
- Each `: name w h` → defines a reusable drawing block
- TEMPs are merged, masked, or saved explicitly

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

