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

- **Flow:** setup (10000) → deal (20000) → draw (3000) → main loop (100), which waits on `get` and dispatches `n` (200: asks "new game? y/n" on row 19, then deal + draw), `r` (redraw) and `q` (quit, 990). Keys `1`-`0` (posts 1-10) are not handled yet.
- **Data model:** `po%(pp,k)` for post `pp` = 1..10:
  - `k=0`: screen address of the post's top (hover) cell.
  - `k=1..5`: rings, where 1 is just below the cap; the value is a PETSCII color code, 0 = empty.
  - `k=6`: the extra stack slot just above the base (0 = empty; when filled, the base drops one row).
  - `k=7`: a ring hovering above the post (at most one post at a time).
- `cl%(0..4)` holds the color codes (red 28, green 30, blue 31, yellow 158, cyan 159). Lines 2-4 create the hot draw variables first, then dim `po%` before `cl%`, because BASIC searches variables and arrays in creation order. Setup (10000) fills in the colors and the post addresses `po%(pp,0)`. Deal (20000) can run repeatedly: it fills slots 1-5 in order (two posts per color), clears slots 6-7, then Fisher-Yates shuffles the 50 rings in place in `po%` (ring k = post `int((k-1)/5)+1`, slot `k-5*post+5`).
- **Layout:** the posts are in 2 rows × 5 columns. A post's origin is `x=1+col*4`, `y=1+row*9` on the 22×23 screen. Screen RAM starts at `sb=7680` ($1E00).
- **Drawing:** routines take a screen address in `pa`; `gosub 1000` converts it to row/column and moves the cursor with KERNAL PLOT (`poke781,row:poke782,col:poke783,0:sys65520`). Then PRINT draws with reverse video and color codes. The per-post draw order is base (2000), rings (2100), cap (2200), hover (2300). `b$=chr$(230)` is the checker glyph used for the pole, cap and base. A ring is `{rvs on}<color> <checker> {rvs off}`, 3 cells wide.
- Subroutines live at fixed line-number blocks (1000, 2000-2300, 3000, 10000, 20000). Keep new routines in their own blocks.

## Coding guidelines

Follow these for all BASIC written in this repo:

@docs/basic-guidelines.md

## petcat and xvic notes

- petcat auto-numbers unnumbered source lines (previous line + 2). So they end up in the PRG, and they need a numbering gap after the preceding line. Lowercase in the source becomes unshifted PETSCII (displayed as uppercase on the VIC).
- In xvic, `-keymap 0` (symbolic) makes PC keys type their printed symbols. Under the positional keymap, `=` is on Page Down.
