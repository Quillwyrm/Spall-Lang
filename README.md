# Spall  
**Sequential Pixel Art Layer Language**

Spall is a minimal and expressive scripting language for defining pixel operation flows — used to generate sprites, tiles, masks, and procedural shapes.

It’s not just a novel way to make tiles.  
It’s a precise, code-driven tool for 2D pixel matrix composition.



##  Features

- Create subtle tile variations by tweaking a few values
- Stack multiple `# tiles` in a single file for full tilesets
- Define reusable shapes with `: Block` syntax
- Iterate shapes procedurally using `> LOOPS`
- Inject randomness with `> RAND` vars
- Output `.png` or raw matrix data (for logic masks, roguelike rooms, etc.)
- No GUI or toolchain required — just plain scripts and ops



##  Inspirations

Spall draws from a lineage of clean, expressive languages:

- **BASIC** (1964) — procedural simplicity and low-friction creativity
- **PostScript** (1982) — graphics via code; composable drawing ops
- **Forth** (1970) — postfix stack logic and minimal control flow
- **ASM** — the spark came from exploring Assembly, bytecode, direct control, linear ops, and intermediate representations (IR)



##  Usage

Write `.spl` scripts and run them via the `splgen` CLI tool:

```bash
splgen input.spl --out output/
```

Or embed the Lua module directly:

```lua
local spall = require("splgen")
local tiles = spall.load("tileset.spl")
```

You’ll get back a table of pixel buffers (2D matrices) to use in your game or tool.



##  Name

> **Spall**  
> *Verb*: "to break rock into smaller pieces"  
> *Noun*: "a splinter or chip of stone"



##  Spec

See the full [language spec](./spall-spec.md) for syntax, ops, buffer model, and output behavior.
