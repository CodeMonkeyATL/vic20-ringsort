# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A color-sorting ring puzzle for an **unexpanded VIC-20**, written in Commodore BASIC V2 (petcat text format). There are 10 posts holding 5 rings each; 50 rings in 5 colors (10 per color) are shuffled onto the posts. The README has the rules and controls; `docs/design.md` explains how the program works (data model, routine map, variable table, memory history).

## Build and run

- **Build + run (what the IDE Build does):** `powershell -NoProfile -ExecutionPolicy Bypass -File buildtools/build-and-run.ps1 -BasFile src/<name>.bas`
  - Runs `petcat.exe -w2 -l 1001 -o prgs/<name> src/<name>.bas`, then autostarts the PRG in xvic. If xvic is already running, it's sent over the remote monitor (127.0.0.1:6510); otherwise xvic is started with `-memory none -keymap 0 -remotemonitor`.
  - `petcat.exe` and `xvic.exe` must be on PATH (VICE 3.10 GTK3). Copies of petcat/c1541 are also in `tools/`.
- **See the screen:** `powershell -NoProfile -ExecutionPolicy Bypass -File buildtools/screenshot.ps1` saves a PNG to `screenshots/temp/` (gitignored). The `/screenshot` skill wraps this (a user-level skill; its master copy is in the `meta` repo, `claude/user/skills/`).
- **Press keys:** `powershell -NoProfile -ExecutionPolicy Bypass -File buildtools/keys.ps1 -Keys "<keys>"` types into the running program through the monitor's `keybuf` command. Use it freely for testing, e.g. play moves and screenshot the result. `\x20` types a space, RingSort's cancel key. Example: after `q`, `-Keys "?fre(0)\n"` prints free memory.
- **Remote monitor and autostart:** the rules for driving xvic safely (never send `x`, one command per connection, autostart replaying the last `keybuf` string, escape syntax) are in `meta/claude/xvic.md`, loaded through the workspace CLAUDE.md. The stray `z` that `build-and-run.ps1` leaves for autostart is discarded by the splash's `poke198,0`.
- **Lint:** `buildtools/check-basic.ps1 -BasFile <file>` checks a source file against the guidelines: missing `goto`/`gosub`/`then` targets (including `on … goto` lists), lines over 88 characters as listed, spaces outside strings and `rem`s, and line numbers that are unnumbered, duplicated or out of order. `build-and-run.ps1` runs it before petcat; it only prints warnings and never stops the build. `ringsort.bas` should stay at 0 warnings; `prototype.bas` and `randomcolors.bas` are old experiments and have warnings.
- There are no tests. Verify changes by building and looking at the emulator screen.
- **IDE tasks:** the user works in Visual Studio (Open Folder). VS reads only `.vs/tasks.vs.json`, which is gitignored; `buildtools/tasks.vs.json` is the committed copy (and `buildtools/tasks.json` is the VS Code equivalent). Keep the copies in sync. Every VS Build prints a harmless "The system cannot find the file specified." that comes from VS itself, not the script.
- **CI:** `.github/workflows/build-prg.yml` runs petcat on changed `.bas` files when a PR is merged (or a `v*` tag is pushed) and commits the PRGs to `prgs/`. A filename suffix picks the petcat flags (`-vic20-8k.bas`, `-c64.bas`, …); plain names get `-w2 -l 1001`, the same as the local build.

## Source files (`src/`)

- `ringsort.bas`: the actual program (formerly `singlepost.bas`). It draws all 10 posts from a data model; this is where development happens.
- `prototype.bas`: an earlier hard-coded PRINT prototype of the board.
- `randomcolors.bas`: an earlier shuffle/debug experiment.
- The cheatsheet's test programs (`colortest.bas`, `glyphtest.bas`) moved to the private `meta` repo.

## Docs

- `docs/design.md`: how `ringsort.bas` works, including its sound design. Keep it in sync with code changes.
- The general VIC-20 reference (petcat tokens, colors, glyphs, registers, keyboard buffer) is the user's cheatsheet in the `meta` repo, `meta/docs/cheatsheet.md`; general facts learned here go there, RingSort specifics in `design.md`. Cross-repo plans are in `meta/ideas.md`.

## Program architecture (`ringsort.bas`)

The source is tightened: no `rem`s, statements joined. The full explanation, including the variable table, is in `docs/design.md`; keep it in sync with code changes. Free memory during play is about 133 bytes (2026-10-25, after the blank expert cap and the solid hover ring); `docs/design.md` has the history. Measure with `keys.ps1`: quit with `q`, then type `?fre(0)\n`.

- **Flow:** line 1-2 init (variables, `po%`, post offsets) → splash (7000: waits for a key, which picks the mode `md`: `h` hard, `e` expert, else classic) → new game (210: if `dn` is 0, seed from `ti` and pick a random deal number `dn` (1-99999); then seed `rnd(-dn)`, deal 2500, which falls into the full draw 3000, then start the timer `tb=ti`) → main loop (110), which waits on `get` (ticking the timer, 6100, while idle) and dispatches `r` (redraw), `q` (quit, 990), space (put the lifted ring back) and keys `1`-`0` (posts 1-10) to 300, and `n` (170: asks "new game? c/h/e" on row 20; `c`/`h`/`e` set `md` (175), read a deal number with 250, where Return alone means random, then run 210; any other key cancels). `n` is tested last because its prompt reads a new `k$`.
- **Moves (300/400):** `hp` is the post whose top ring is lifted (0 = none). A post key with nothing lifted lifts that post's top ring into its hover slot; with a ring lifted, it drops the ring onto that post (the same post = cancel). Lifting from an empty or locked post, or dropping on a full post (in expert: 5 rings is full) or, in hard and expert, on a different color, prints "invalid move" on row 20; the next post key clears it. Row 19 shows the move (`FROM N`, `TO M`, `MOVE CANCELED`), printed before the post redraws. In classic, colors don't have to match.
- **Locks and win (4100):** a post is locked when slot 1 is empty and slots 2-6 hold one color. A locked post can't be lifted from, but can still take a ring in its cap slot, and that ring can be lifted again. The win scan (every post locked or empty) runs only after a drop that locks its destination post. Locks are computed, not stored.
- **Complete posts (4110):** slots 2-6 hold one color, ignoring the cap slot; 4100 is "cap slot empty" plus 4110. The base is drawn solid in the ring color when the post is complete, so parking a ring on a locked post doesn't flicker the base. A drop that locks its destination plays the lock sound (5200) right after that post is redrawn.
- **Data model:** `po%(pp,k)` for post `pp` = 1..10. Index `k` is the screen row below the post origin, so slot `k` is drawn at `origin+22*k`. Ring values are PETSCII color codes; 0 = empty.
  - `k=0`: hover, a ring lifted above the post (at most one post at a time).
  - `k=1`: cap slot. It's empty at the start and takes a 6th ring dropped onto a full post; without it no first move is possible. When empty it draws as the pole top.
  - `k=2..6`: rings 1-5, stacked on the base. The top ring of a post is its lowest non-zero index from 1 to 6, and a dropped ring goes in the index just above it (legal only if that index is at least 1).
  - `k=7`: the post origin's screen offset from 7680 (the hover cell; at least 23, never 0). The base is always drawn on row 7 and never moves.
- **Modes (`md`):** 0 classic (50 rings, 5 colors, any color on any), 1 hard (40 rings, 4 colors without blue, posts 5 and 10 start empty, drop only on the same color or an empty post), 2 expert (as hard, but no cap slot: 5 rings is full, and the cap row is drawn blank). Session bests are per mode in `mb%(md)`, `tw%(md)`. Row 22 shows `(HARD)`/`(EXPERT)` in red after the deal number. Classic deals are unchanged from before modes, so old classic deal numbers still give the same boards.
- **Colors:** the ring colors (red 28, green 30, blue 31, yellow 158, cyan 159) live only in a string literal in the deal (2510), read with `asc(mid$(...))`: five for classic, then the four without blue for hard/expert; there's no color array. BASIC searches variables in creation order, so line 1 creates `i` and dims `po%` first; line 2 then creates `pp` and the splash `pa`. Line 2 fills in the post offsets `po%(pp,7)`. Deal (2500) can run repeatedly: it clears all posts, fills rings 1..`d` in order (`d` doubles as the ring count, `n` as the ring loop) (two posts per color), then Fisher-Yates shuffles them in place in `po%`. Routine 2400 maps ring `j` to post `a` and slot `j` (`a=int((j-1)/5)+1`, slot `j-5*a+6`, then `a=a+int(a/5)*sgn(md)` shifts posts 5-8 to 6-9 when `md>0`).
- **Score:** row 0 shows moves (`mv`, successful drops) and a live timer; row 21 the session best for the current mode (`mb%(md)`, `tw%(md)`). Digits are poked into screen memory by 6000, never built with `str$()` (no string garbage). The timer is computed from the KERNAL jiffy clock: `int((ti-tb)/60)`, frozen on a win (`wn=-1`) and stopped at 99:59 (`wn=1`).
- **Seeding and deal numbers:** autostart reaches line 2 at nearly the same `ti` every time, so the random seed comes from human keypresses (the splash key, each new game's entry). The deal number `dn` is the actual seed (`rnd(-dn)`), shown on row 22; typing it again replays the same board. Deal numbers are tied to the deal code: changing the shuffle changes every board.
- **Layout:** the posts are in 2 rows × 5 columns. A post's origin is `x=1+col*4`, `y=1+row*9` on the 22×23 screen. Screen RAM starts at 7680 ($1E00); cursor positions are passed as offsets from it.
- **Drawing:** routines take a screen offset (0-505) in `pa`; `gosub 1000` converts it to row/column and moves the cursor with KERNAL PLOT (`poke781,pa/22:poke782,pa-22*int(pa/22):poke783,0:sys65520`; `poke` drops the fraction). Then PRINT draws with reverse video and color codes. One routine (2000) draws a post with a single PLOT: rows 0-6 from `po%(pp,0..6)` (a ring, or else the pole, or blanks for an empty hover row), each ending in `{down}{left}{left}{left}` to step to the next row, then the base on row 7. The checker glyph for the pole and base is embedded in the strings as `{CBM-+}`. A ring is `{rvs on}<color> <checker> {rvs off}`, 3 cells wide; a lifted ring in the hover row is solid (a space instead of the checker).
- Subroutines live at fixed line-number blocks (1000 cursor, 1100 message row, 1200 clear message, 1300 clear move row, 2000 draw post, 2400 ring to post/slot, 2500 deal, 3000 draw all, 3100 status row, 3200 best row, 3300 moves/time digits, 4000 top ring, 4100 lock check, 4110 complete check, 5000 sound sweep, 5100 win chime, 5200 lock sound, 6000 poke digits, 6100 timer tick, 6200 show mm:ss, 7000 splash). Some fall into the next on purpose (2500 → 3000 → 3100 → 3200 → 3300). 5000 restores the volume to 15 after every sweep. Keep new routines in their own blocks.
- **Sound:** line 1 sets the volume (36878) to 15 and quitting sets it to 0. Each sound turns its voice off when done. `docs/design.md` has a table of every sound's register and values for tuning by ear; Claude can't hear xvic, so the user judges how sounds actually sound.

## Coding guidelines

Follow the BASIC coding rules in the private `meta` repo (`meta/docs/basic-guidelines.md`). The workspace CLAUDE.md one folder up imports them, along with the xvic and petcat notes (`meta/claude/xvic.md`).
