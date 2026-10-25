# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A color-sorting ring puzzle for an **unexpanded VIC-20**, written in Commodore BASIC V2 (petcat text format). There are 10 posts holding 5 rings each; 50 rings in 5 colors (10 per color) are shuffled onto the posts. The README has the rules and controls; `docs/design.md` explains how the program works (data model, routine map, variable table, memory history).

## Build and run

- **Build + run (what the IDE Build does):** `powershell -NoProfile -ExecutionPolicy Bypass -File buildtools/build-and-run.ps1 -BasFile src/<name>.bas`
  - Runs `petcat.exe -w2 -l 1001 -o prgs/<name> src/<name>.bas`, then autostarts the PRG in xvic. If xvic is already running, it's sent over the remote monitor (127.0.0.1:6510); otherwise xvic is started with `-memory none -keymap 0 -remotemonitor`.
  - `petcat.exe` and `xvic.exe` must be on PATH (VICE 3.10 GTK3). Copies of petcat/c1541 are also in `tools/`.
- **See the screen:** `powershell -NoProfile -ExecutionPolicy Bypass -File buildtools/screenshot.ps1` saves a PNG to `screenshots/temp/` (gitignored). The `/screenshot` skill wraps this.
- **Press keys:** `powershell -NoProfile -ExecutionPolicy Bypass -File buildtools/keys.ps1 -Keys "<keys>"` types into the running program through the monitor's `keybuf` command. Use it freely for testing, e.g. play moves and screenshot the result. `keybuf` types its argument literally; `\n` types Return and `\xNN` any character (`\x20` for space, e.g. RingSort's cancel key). Verified in xvic. Example: after `q`, `-Keys "?fre(0)\n"` prints free memory.
- **Remote monitor:** talk to xvic only through these scripts (`build-and-run.ps1` autostart, `screenshot.ps1`, `keys.ps1`). Never send `x`, and always read the reply before disconnecting; otherwise the remote monitor wedges.
- **Lint:** `buildtools/check-basic.ps1 -BasFile <file>` checks a source file against the guidelines: missing `goto`/`gosub`/`then` targets (including `on … goto` lists), lines over 88 characters as listed, spaces outside strings and `rem`s, and line numbers that are unnumbered, duplicated or out of order. `build-and-run.ps1` runs it before petcat; it only prints warnings and never stops the build. `ringsort.bas` should stay at 0 warnings; `prototype.bas` and `randomcolors.bas` are old experiments and have warnings.
- There are no tests. Verify changes by building and looking at the emulator screen.
- **IDE tasks:** the user works in Visual Studio (Open Folder). VS reads only `.vs/tasks.vs.json`, which is gitignored; `buildtools/tasks.vs.json` is the committed copy (and `buildtools/tasks.json` is the VS Code equivalent). Keep the copies in sync. Every VS Build prints a harmless "The system cannot find the file specified." that comes from VS itself, not the script.
- **CI:** `.github/workflows/build-prg.yml` runs petcat on changed `.bas` files when a PR is merged (or a `v*` tag is pushed) and commits the PRGs to `prgs/`. A filename suffix picks the petcat flags (`-vic20-8k.bas`, `-c64.bas`, …); plain names get `-w2 -l 1001`, the same as the local build.

## Source files (`src/`)

- `ringsort.bas`: the actual program (formerly `singlepost.bas`). It draws all 10 posts from a data model; this is where development happens.
- `prototype.bas`: an earlier hard-coded PRINT prototype of the board.
- `randomcolors.bas`: an earlier shuffle/debug experiment.
- `colortest.bas`: test screen that verifies the cheatsheet's color tables (color codes via `chr$()` and petcat tokens, color RAM values, and that the C64-only codes do nothing). Waits for a key.
- `glyphtest.bas`: verifies the cheatsheet's graphics glyph table in three pages: the old table's claims, every graphic glyph (96-127, 160-191, and their repeats at 192-255), and two box styles. Any key advances.
- The test programs follow the guidelines (0 lint warnings) but aren't tightened; they keep their `rem`s.

## Docs

- `docs/design.md`: how `ringsort.bas` works, including its sound design. Keep it in sync with code changes.
- `docs/cheatsheet.md`: general VIC-20 reference (petcat tokens, colors, graphics glyphs, color and sound registers, sound patterns). It's meant to be shared with other projects, so keep it free of RingSort specifics; RingSort details go in `design.md`. Some overlap between the two is fine. Facts in it are verified in xvic, with the test programs and screenshots in `screenshots/`.

## Program architecture (`ringsort.bas`)

The source is tightened: no `rem`s, statements joined. The full explanation, including the variable table, is in `docs/design.md`; keep it in sync with code changes. Free memory during play is about 650 bytes (2026-10-25, after the second tightening pass); `docs/design.md` has the history. Measure with `keys.ps1`: quit with `q`, then type `?fre(0)\n`.

- **Flow:** line 1-2 init (variables, `po%`, post offsets) → splash (7000: waits for a key) → new game (210: seed `rnd(-ti)`, deal 2500, which falls into the full draw 3000, then start the timer `tb=ti`) → main loop (110), which waits on `get` (ticking the timer, 6100, while idle) and dispatches `r` (redraw), `q` (quit, 990), space (put the lifted ring back) and keys `1`-`0` (posts 1-10) to 300, and `n` (170: asks "new game? y/n" on row 20; `y` runs 210). `n` is tested last because its prompt reads a new `k$`.
- **Moves (300/400):** `hp` is the post whose top ring is lifted (0 = none). A post key with nothing lifted lifts that post's top ring into its hover slot; with a ring lifted, it drops the ring onto that post (the same post = cancel). Lifting from an empty or locked post, or dropping on a full post, prints "invalid move" on row 20; the next post key clears it. Row 19 shows the move (`MOVE N`, `TO M`, `MOVE CANCELED`), printed before the post redraws. Colors don't have to match.
- **Locks and win (4100):** a post is locked when slot 1 is empty and slots 2-6 hold one color. A locked post can't be lifted from, but can still take a ring in its cap slot, and that ring can be lifted again. The win scan (all 10 posts locked) runs only after a drop that locks its destination post. Locks are computed, not stored.
- **Complete posts (4110):** slots 2-6 hold one color, ignoring the cap slot; 4100 is "cap slot empty" plus 4110. The base is drawn solid in the ring color when the post is complete, so parking a ring on a locked post doesn't flicker the base. A drop that locks its destination plays the lock sound (5200) right after that post is redrawn.
- **Data model:** `po%(pp,k)` for post `pp` = 1..10. Index `k` is the screen row below the post origin, so slot `k` is drawn at `origin+22*k`. Ring values are PETSCII color codes; 0 = empty.
  - `k=0`: hover, a ring lifted above the post (at most one post at a time).
  - `k=1`: cap slot. It's empty at the start and takes a 6th ring dropped onto a full post; without it no first move is possible. When empty it draws as the pole top.
  - `k=2..6`: rings 1-5, stacked on the base. The top ring of a post is its lowest non-zero index from 1 to 6, and a dropped ring goes in the index just above it (legal only if that index is at least 1).
  - `k=7`: the post origin's screen offset from 7680 (the hover cell; at least 23, never 0). The base is always drawn on row 7 and never moves.
- **Colors:** the ring colors (red 28, green 30, blue 31, yellow 158, cyan 159) live only in a string literal in the deal (2510), read with `asc(mid$(...))`; there's no color array. Line 1 creates the hot draw variables first, then dims `po%`, because BASIC searches variables in creation order. Line 2 fills in the post offsets `po%(pp,7)`. Deal (2500) can run repeatedly: it fills slots 2-6 in order (two posts per color), clears slots 0-1, then Fisher-Yates shuffles the 50 rings in place in `po%` (ring k = post `int((k-1)/5)+1`, slot `k-5*post+6`).
- **Score:** row 0 shows moves (`mv`, successful drops) and a live timer; row 21 the session best (`mb`, `tw`). Digits are poked into screen memory by 6000, never built with `str$()` (no string garbage). The timer is computed from the KERNAL jiffy clock: `int((ti-tb)/60)`, frozen on a win (`wn=-1`) and stopped at 99:59 (`wn=1`).
- **Seeding:** autostart reaches line 2 at nearly the same `ti` every time, so the seed comes from human keypresses: the splash key and each new game's `y`.
- **Layout:** the posts are in 2 rows × 5 columns. A post's origin is `x=1+col*4`, `y=1+row*9` on the 22×23 screen. Screen RAM starts at 7680 ($1E00); cursor positions are passed as offsets from it.
- **Drawing:** routines take a screen offset (0-505) in `pa`; `gosub 1000` converts it to row/column and moves the cursor with KERNAL PLOT (`poke781,pa/22:poke782,pa-22*int(pa/22):poke783,0:sys65520`; `poke` drops the fraction). Then PRINT draws with reverse video and color codes. One routine (2000) draws a post with a single PLOT: rows 0-6 from `po%(pp,0..6)` (a ring, or else the pole, or blanks for an empty hover row), each ending in `{down}{left}{left}{left}` to step to the next row, then the base on row 7. `b$=chr$(230)` is the checker glyph used for the pole and base. A ring is `{rvs on}<color> <checker> {rvs off}`, 3 cells wide.
- Subroutines live at fixed line-number blocks (1000 cursor, 1100 message row, 1200 clear message, 1300 clear move row, 2000 draw post, 2500 deal, 3000 draw all, 3100 status row, 3200 best row, 4000 top ring, 4100 lock check, 4110 complete check, 5000 sound sweep, 5100 win chime, 5200 lock sound, 6000 poke digits, 6100 timer tick, 6200 show mm:ss, 7000 splash). Some fall into the next on purpose (2500 → 3000 → 3100 → 3200). Keep new routines in their own blocks.
- **Sound:** line 1 sets the volume (36878) to 15 and quitting sets it to 0. Each sound turns its voice off when done. `docs/design.md` has a table of every sound's register and values for tuning by ear; Claude can't hear xvic, so the user judges how sounds actually sound.

## Coding guidelines

Follow these for all BASIC written in this repo:

@docs/basic-guidelines.md

## petcat and xvic notes

- petcat auto-numbers unnumbered source lines (previous line + 2). So they end up in the PRG, and they need a numbering gap after the preceding line. Lowercase in the source becomes unshifted PETSCII (displayed as uppercase on the VIC).
- In xvic, `-keymap 0` (symbolic) makes PC keys type their printed symbols. Under the positional keymap, `=` is on Page Down.
