# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A color-sorting ring puzzle for an **unexpanded VIC-20**, written in Commodore BASIC V2 (petcat text format). There are 10 posts holding 5 rings each; 50 rings in 5 colors (10 per color) are shuffled onto the posts. The README has the rules and controls; `docs/design.md` explains how the program works (data model, routine map, variable table, memory history).

## Build and run

- **Build + run (what the IDE Build does):** `powershell -NoProfile -ExecutionPolicy Bypass -File buildtools/build-and-run.ps1 -BasFile src/<name>.bas`
  - Runs `petcat.exe -w2 -l 1001 -o prgs/<name> src/<name>.bas`, then autostarts the PRG in xvic. If xvic is already running, it's sent over the remote monitor (127.0.0.1:6510); otherwise xvic is started with `-memory none -keymap 0 -remotemonitor`.
  - `petcat.exe` and `xvic.exe` must be on PATH (VICE 3.10 GTK3). Copies of petcat/c1541 are also in `tools/`.
- **See the screen:** `powershell -NoProfile -ExecutionPolicy Bypass -File buildtools/screenshot.ps1` saves a PNG to `screenshots/temp/` (gitignored). The `/screenshot` skill wraps this. Don't send raw monitor commands to xvic: sending `x`, or disconnecting before reading the reply, wedges the remote monitor.
- **Lint:** `buildtools/check-basic.ps1 -BasFile <file>` checks a source file against the guidelines: missing `goto`/`gosub`/`then` targets (including `on … goto` lists), lines over 88 characters as listed, spaces outside strings and `rem`s, and line numbers that are unnumbered, duplicated or out of order. `build-and-run.ps1` runs it before petcat; it only prints warnings and never stops the build. `ringsort.bas` should stay at 0 warnings; `prototype.bas` and `randomcolors.bas` are old experiments and have warnings.
- There are no tests. Verify changes by building and looking at the emulator screen.
- **IDE tasks:** the user works in Visual Studio (Open Folder). VS reads only `.vs/tasks.vs.json`, which is gitignored; `buildtools/tasks.vs.json` is the committed copy (and `buildtools/tasks.json` is the VS Code equivalent). Keep the copies in sync. Every VS Build prints a harmless "The system cannot find the file specified." that comes from VS itself, not the script.
- **CI:** `.github/workflows/build-prg.yml` runs petcat on changed `.bas` files when a PR is merged (or a `v*` tag is pushed) and commits the PRGs to `prgs/`. A filename suffix picks the petcat flags (`-vic20-8k.bas`, `-c64.bas`, …); plain names get `-w2 -l 1001`, the same as the local build.

## Source files (`src/`)

- `ringsort.bas`: the actual program (formerly `singlepost.bas`). It draws all 10 posts from a data model; this is where development happens.
- `prototype.bas`: an earlier hard-coded PRINT prototype of the board.
- `randomcolors.bas`: an earlier shuffle/debug experiment.
- `docs/cheatsheet.md`: reference notes (petcat tokens, VIC color codes, color registers).

## Program architecture (`ringsort.bas`)

The source is tightened: no `rem`s, statements joined. The full explanation, including the variable table, is in `docs/design.md`; keep it in sync with code changes. Free memory during play is about 1,700 bytes (2026-10-24).

- **Flow:** setup (10000) → deal (20000) → draw (3000) → main loop (110), which waits on `get` and dispatches `n` (200: asks "new game? y/n" on row 20, then deal + draw), `r` (redraw), `q` (quit, 990), keys `1`-`0` (posts 1-10) and space (put the lifted ring back) to 300.
- **Moves (300/400):** `hp` is the post whose top ring is lifted (0 = none). A post key with nothing lifted lifts that post's top ring into its hover slot; with a ring lifted, it drops the ring onto that post (the same post = cancel). Lifting from an empty or locked post, or dropping on a full post, prints "invalid move" on row 20; the next post key clears it. Row 19 shows the move (`MOVE N`, `TO M`, `MOVE CANCELED`), printed before the slow post redraws. Colors don't have to match.
- **Locks and win (4100):** a post is locked when slot 1 is empty and slots 2-6 hold one color. A locked post can't be lifted from, but can still take a ring in its cap slot, and that ring can be lifted again. The win scan (all 10 posts locked) runs only after a drop that locks its destination post. Locks are computed, not stored.
- **Data model:** `po%(pp,k)` for post `pp` = 1..10. Index `k` is the screen row below the post origin, so slot `k` is drawn at `origin+22*k`. Ring values are PETSCII color codes; 0 = empty.
  - `k=0`: hover, a ring lifted above the post (at most one post at a time).
  - `k=1`: cap slot. It's empty at the start and takes a 6th ring dropped onto a full post; without it no first move is possible. When empty it draws as the pole top.
  - `k=2..6`: rings 1-5, stacked on the base. The top ring of a post is its lowest non-zero index from 1 to 6, and a dropped ring goes in the index just above it (legal only if that index is at least 1).
  - `k=7`: the post origin's screen address (the hover cell). The base is always drawn on row 7 and never moves.
- `cl%(0..4)` holds the color codes (red 28, green 30, blue 31, yellow 158, cyan 159). Line 1 creates the hot draw variables first, then dims `po%` before `cl%`, because BASIC searches variables and arrays in creation order. Setup (10000) fills in the colors and the post addresses `po%(pp,7)`. Deal (20000) can run repeatedly: it fills slots 2-6 in order (two posts per color), clears slots 0-1, then Fisher-Yates shuffles the 50 rings in place in `po%` (ring k = post `int((k-1)/5)+1`, slot `k-5*post+6`).
- **Layout:** the posts are in 2 rows × 5 columns. A post's origin is `x=1+col*4`, `y=1+row*9` on the 22×23 screen. Screen RAM starts at `sb=7680` ($1E00).
- **Drawing:** routines take a screen address in `pa`; `gosub 1000` converts it to row/column and moves the cursor with KERNAL PLOT (`poke781,row:poke782,col:poke783,0:sys65520`). Then PRINT draws with reverse video and color codes. One routine (2000) draws a post: rows 0-6 from `po%(pp,0..6)` (a ring, or else the pole, or blanks for an empty hover row), then the base on row 7. `b$=chr$(230)` is the checker glyph used for the pole and base. A ring is `{rvs on}<color> <checker> {rvs off}`, 3 cells wide.
- Subroutines live at fixed line-number blocks (1000 cursor, 1100 message row, 1200 clear message, 2000 draw post, 3000 draw all, 4000 top ring, 4100 lock check, 10000 setup, 20000 deal). Keep new routines in their own blocks.

## Coding guidelines

Follow these for all BASIC written in this repo:

@docs/basic-guidelines.md

## petcat and xvic notes

- petcat auto-numbers unnumbered source lines (previous line + 2). So they end up in the PRG, and they need a numbering gap after the preceding line. Lowercase in the source becomes unshifted PETSCII (displayed as uppercase on the VIC).
- In xvic, `-keymap 0` (symbolic) makes PC keys type their printed symbols. Under the positional keymap, `=` is on Page Down.
