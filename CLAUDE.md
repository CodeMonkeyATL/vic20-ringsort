# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A color-sorting ring puzzle for an **unexpanded VIC-20**, written in Commodore BASIC V2 (petcat text format). There are 10 posts holding 5 rings each; 50 rings in 5 colors (10 per color) are shuffled onto the posts. The repo was started from a generic template, so the README's feature/how-to-play sections and `docs/design.md` are still placeholders.

## Build and run

- **Build + run (what the IDE Build does):** `powershell -NoProfile -ExecutionPolicy Bypass -File buildtools/build-and-run.ps1 -BasFile src/<name>.bas`
  - Runs `petcat.exe -w2 -l 1001 -o prgs/<name> src/<name>.bas`, then autostarts the PRG in xvic. If xvic is already running, it's sent over the remote monitor (127.0.0.1:6510); otherwise xvic is started with `-memory none -keymap 0 -remotemonitor`.
  - `petcat.exe` and `xvic.exe` must be on PATH (VICE 3.10 GTK3). Copies of petcat/c1541 are also in `tools/`.
- **See the screen:** `powershell -NoProfile -ExecutionPolicy Bypass -File buildtools/screenshot.ps1` saves a PNG to `screenshots/temp/` (gitignored). The `/screenshot` skill wraps this. Don't send raw monitor commands to xvic: sending `x`, or disconnecting before reading the reply, wedges the remote monitor.
- There are no tests or linter. Verify changes by building and looking at the emulator screen.
- **IDE tasks:** the user works in Visual Studio (Open Folder). VS reads only `.vs/tasks.vs.json`, which is gitignored; `buildtools/tasks.vs.json` is the committed copy (and `buildtools/tasks.json` is the VS Code equivalent). Keep the copies in sync. Every VS Build prints a harmless "The system cannot find the file specified." that comes from VS itself, not the script.
- **CI:** `.github/workflows/build-prg.yml` runs petcat on changed `.bas` files when a PR is merged (or a `v*` tag is pushed) and commits the PRGs to `prgs/`. A filename suffix picks the petcat flags (`-vic20-8k.bas`, `-c64.bas`, …); plain names get `-w2 -l 1001`, the same as the local build.

## Source files (`src/`)

- `ringsort.bas`: the actual program (formerly `singlepost.bas`). It draws all 10 posts from a data model; this is where development happens.
- `prototype.bas`: an earlier hard-coded PRINT prototype of the board.
- `randomcolors.bas`: an earlier shuffle/debug experiment.
- `docs/cheatsheet.md`: reference notes (petcat tokens, VIC color codes, color registers).

## Program architecture (`ringsort.bas`)

- **Data model:** `po(pp,k)` for post `pp` = 1..10:
  - `k=0`: screen address of the post's top (hover) cell.
  - `k=1..5`: rings, where 1 is just below the cap; the value is a PETSCII color code, 0 = empty.
  - `k=6`: the extra stack slot just above the base (0 = empty; when filled, the base drops one row).
  - `k=7`: a ring hovering above the post (at most one post at a time).
- `cl(1..5)` holds the color codes (red 28, green 30, blue 31, yellow 158, cyan 159). Init (line 20000+) fills `cc(1..50)` with 10 of each color index, Fisher-Yates shuffles it, and deals it into `po`.
- **Layout:** the posts are in 2 rows × 5 columns. A post's origin is `x=1+col*4`, `y=1+row*9` on the 22×23 screen. Screen RAM starts at `sb=7680` ($1E00).
- **Drawing:** routines take a screen address in `pa`; `gosub 1000` converts it to row/column and moves the cursor with KERNAL PLOT (`poke781,row:poke782,col:poke783,0:sys65520`). Then PRINT draws with reverse video and color codes. The per-post draw order is base (2000), rings (2100), cap (2200), hover (2300). `b$=chr$(230)` is the checker glyph used for the pole, cap and base. A ring is `{rvs on}<color> <checker> {rvs off}`, 3 cells wide.
- Subroutines live at fixed line-number blocks (1000, 2000-2300, 10000, 20000). Keep new routines in their own blocks.

## BASIC V2 gotchas that matter here

- Only the first two characters of a variable name are significant (`pp` and `ppx` are the same variable), and a name must not contain a BASIC keyword (e.g. `to`, `if`, `or`). `r` and `c` are reused as loop variables after init, so watch for collisions.
- Unexpanded RAM means about 3.5 KB for program plus variables, so keep code and arrays lean.
- petcat auto-numbers unnumbered source lines (previous line + 2; e.g. the `rem po(...)` notes after line 1060 become 1062-1068). So they end up in the PRG and use RAM, and they need a numbering gap after the preceding line. Lowercase in the source becomes unshifted PETSCII (displayed as uppercase on the VIC).
- In xvic, `-keymap 0` (symbolic) makes PC keys type their printed symbols. Under the positional keymap, `=` is on Page Down.
