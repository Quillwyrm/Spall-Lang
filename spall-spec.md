

# Spall  
***Sequential Pixel Art Layer Language***

## Introduction

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

-

## 1. File Layout & Execution Model

### Execution
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

### Buffers

- **TEMP** — Temporary scratch buffer for the current op.  
  Auto-merged to MAIN after each op unless bound to a name or consumed.  
  Can be used as a shape to mask, stamp, or merge.

- **MAIN** — The cumulative tile buffer.  
  Built by implicitly merging TEMP to MAIN after each op.  
  The accumulated tile data for the current `# tile`.

- **SHAPE buffers** — Predefined Shapes, 
  Your named buffers created from bound `TEMP`s or `BlockDef`s.  
  These store reusable pixel data for composition or masking.

### Merge Behavior

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

-

## 4. Directives

> SIZE

> COLORS

> LOOPS

> RANDS

Others you plan (> EXPORT, > DOC, etc.)








--
													1. Introduction
													One-paragraph pitch (you’ve already nailed this)

													Purpose of the language

													Core inspiration and intended use cases

													2. File Structure & Execution Model
													.spl file layout (top-down execution)

													How Spall is interpreted (one pass, no control flow, buffer state)

													Output structure: .png, matrix return, etc.



4. Directives
> TILESIZE

> COLORS

> LOOPS

Others you plan (> EXPORT, > DOC, etc.)

5. Block Types
: name — SHAPE/block definition

# name — tile output definition

Scoping rules

What blocks return (a TMP buffer)

TMP naming rules inside blocks

6. Instruction Set (OPs)
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

7. Iteration
> LOOPS syntax

How iterator values are injected

Static expansion model

Loop naming convention (ix, iy etc.)

8. Naming and Scope
What names are valid

Where names can be reused

TMP name lifespan

Block vs TILE scope

9. Output Modes
Default: .png

Optional: matrix return (for programmatic use)

Future: binary/CSV/JSON exports

10. Transpilation Model (Optional)
How Spall maps to Lua (or other backends)

What the output runtime expects

11. Appendix / Glossary
SHAPE vs TMP vs MASK

TMP Merge Rules Table

Reserved OP names

Reserved directive names