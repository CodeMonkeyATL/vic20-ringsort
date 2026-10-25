# ringsort design notes

How `src/ringsort.bas` works. The source has no comments: they cost too much memory on an unexpanded VIC-20. This file is where the explanations live, so update it whenever the code changes.

## The game

- 10 posts, 50 rings, 5 colors with 10 rings of each.
- A new game deals 5 shuffled rings onto every post.
- **Moves:**
  - Press a post's key (`1`-`9`, `0` for post 10) to lift its top ring.
  - Press another post's key to drop the ring there. Any color can go on any color.
  - Pressing the same post again, or space, puts the ring back.
- **Capacity:** each post holds up to 6 rings. The sixth sits in the post's cap slot, and that slot is what makes the first move from a full board possible.
- **Locked posts:** a post holding exactly 5 rings of one color is locked. You can't lift from it, but you can park a ring in its cap slot and lift that ring again later.
- **Winning:** you win when all 10 posts are locked.
- **Score:** moves (successful drops; cancels and invalid moves don't count) and time, both live on the top row. The timer starts when the board is drawn, freezes on a win, and stops at 99:59. The session's best moves and best time (tracked separately) show on row 21 once a game is won. They're lost on quit.
- **Splash:** at launch a title screen waits for a key; that keypress seeds the random numbers.
- **Other keys:** `n` new game (asks y/n first), `r` redraw, `q` quit.

## Screen layout

The screen is 22×23 characters; screen RAM starts at 7680 (`sb`).

- **Posts:** 2 rows of 5. Post `pp` (1-10) has its origin (top-left cell) at `x=1+col*4`, `y=1+row*9`, where `row=int((pp-1)/5)` and `col=pp-1-5*row`.
- **Each post is 8 screen rows tall:**

```
row 0   rrr   hover: the lifted ring, or blank
row 1    #    cap slot: pole top, or a 6th ring
row 2   rrr   ring slots 2-6, stacked on the base
...
row 6   rrr
row 7   ###   base (never moves)
```

- **Characters:** a ring is 3 cells: `{rvs on}<color> <checker> {rvs off}`. The pole and base use the checker glyph `chr$(230)` (`b$`) in white.
- **Complete posts:** when slots 2-6 hold one color, the base is drawn as 3 reverse spaces in that color instead of the white checker, so the post looks like a filled vessel. The solid base ends with `{wht}`, so the text printed next (the move row, messages) stays white.
- **Messages start at column 1,** aligned with the left edge of the posts.
- **Row 19** is the move row: `MOVE N` when a ring is lifted from post N, `TO M` at column 12 when it's dropped on post M, and `MOVE CANCELED` when it's put back. A new lift clears the row. A new game or redraw clears the whole screen, including this row. Row 18 stays blank as a gap below the bottom posts' bases.
  - Dropping on a full post prints `TO M` in red (and "invalid move" on row 20). The ring stays lifted; the next valid drop overwrites the red text with a white `TO M`.
  - The text is printed *before* the posts are redrawn, so the player sees the response at once; a post redraw takes about half a second.
- **Row 20** is the message row: "new game? y/n", "invalid move", "solved!". On a win, the move row is cleared first.
- **Row 0** is the status row: `MOVES 000 TIME 00:00` from column 1 to 20 (moves digits at columns 7-9, minutes 16-17, seconds 19-20). Printed by 6300 on every full draw; after that only the digits are poked (6000).
- **Row 21** is the session best, in cyan: `BEST  000      00:00`, digits in the same columns as row 0. Drawn only once a game has been won.
- **Splash (7000):** "RINGSORT" one letter per ring color at row 9, column 7; "CODEMONKEYATL" at row 11, column 4; "PRESS A KEY" at row 20, column 5.
- **While dealing,** row 0 shows "dealing..." followed by a block in column 10 that changes color on every swap of the shuffle.

## Data model

`po%(10,7)`: one row per post (`pp`=1-10; row 0 is unused). **Index `k` is the screen row below the post origin**, so slot `k` is drawn at `origin+22*k`.

| `k` | Holds |
|---|---|
| 0 | hover ring: the ring lifted from this post (at most one post at a time) |
| 1 | cap slot: a 6th ring, empty at the start |
| 2-6 | rings 1-5, stacked on the base |
| 7 | the post origin's screen address |

Ring values are PETSCII color codes (red 28, green 30, blue 31, yellow 158, cyan 159), from `cl%(0..4)`. 0 = empty.

**Rules expressed in the model:**
- **Top ring:** the lowest non-zero index from 1 to 6. Routine 4000 scans up from index 1 and needs no bounds check: index 7 holds a screen address, which is never 0, so the scan always stops there at the latest. `t=7` means the post is empty.
- **Drop target:** the index just above the top ring (`t-1`). It's legal only if `t>1`; `t=1` means the post is full.
- **Complete:** slots 2-6 all hold the same color (routine 4110). The base shows this.
- **Locked:** complete, and slot 1 is empty (routine 4100, which falls into 4110). The lift rule and the win check use this.
- Both are computed when needed, not stored, so they can't get out of sync with the board.
- **Why the base follows "complete", not "locked":** parking a ring in a locked post's cap slot makes it unlocked (so that ring can be lifted again), but it stays complete. If the base followed the lock, it would switch to checker and back every time a ring is parked and lifted. A complete post also can't become incomplete: its slots 2-6 can only be lifted from when the cap slot is empty, and then the post is locked. So once a base turns solid, it stays solid until the next deal.

## Routines

| Line | Routine | In | Out |
|---|---|---|---|
| 1-2 | init: variables, arrays, setup, splash (which seeds), first deal and draw, start the timer | | |
| 110 | main loop: `get` a key and dispatch; while no key, tick the timer (6100) | | |
| 200 | new game: ask y/n on row 20; on `y` reseed, deal, draw, start the timer | | |
| 300 | post key: lift post `n`'s top ring, or drop onto `n` if a ring is lifted | `n` | |
| 390 | print "invalid move" | | |
| 395 | invalid drop: print `TO n` in red on the move row, then "invalid move" (390) | `n` | |
| 400 | drop the lifted ring onto post `n`, count the move (425), print `TO n`, redraw both posts (playing the lock sound if `n` just locked), check for a win | `n`, `hp` | |
| 470 | win: freeze the timer, clear the move row, print "solved!", update and show the session best, play the chime | | |
| 480 | the drop was a cancel (`n` = `hp`): print `MOVE CANCELED` | | |
| 990 | quit: restore screen colors and blue text | | |
| 1000 | move the cursor to screen address `pa` (KERNAL PLOT) | `pa` | |
| 1100 | move the cursor to the start of the message row | | |
| 1200 | clear the message row | | |
| 1300 | clear the move row (19) and park the cursor at its start | | |
| 2000 | draw post `pp`: rows 0-6 from `po%`, then the base (solid if complete, checker otherwise) | `pp` | `l` is clobbered |
| 3000 | clear the screen, draw all posts and the status rows (6300), discard keys typed meanwhile | | |
| 4000 | find the top ring of post `pp` | `pp` | `t` |
| 4100 | is post `pp` locked? (cap slot empty, then falls into 4110) | `pp` | `l` (-1/0) |
| 4110 | is post `pp` complete? (slots 2-6 one color) | `pp` | `l` (-1/0) |
| 5000 | sound sweep: step register `v` from `f` to `e` by `s`, then poke `v` with 0 | `v`, `f`, `e`, `s` | |
| 5100 | win chime: 4 rising notes on the high voice | | |
| 5200 | lock sound: two bells on the high voice | | |
| 6000 | poke `w` as `d` digits, right-aligned so the last digit is at screen address `a` | `w`, `d`, `a` | `a` moves left `d` cells |
| 6100 | timer tick: return if frozen; else compute elapsed seconds, stop at 99:59, and redraw if the second changed (falls into 6200) | | `te` |
| 6110 | the same without the frozen check (the win calls it for the final time) | | `te` |
| 6200 | show `w` seconds as mm:ss, the last seconds digit at `a` | `w`, `a` | |
| 6300 | draw the status row (row 0), then fall into 6400 | | |
| 6400 | draw the session best (row 21), if a game has been won | | |
| 7000 | splash screen: wait for a key, then seed `rnd` from `ti` | | |
| 10000 | one-time setup: color codes, post addresses | | |
| 20000 | deal: fill posts in order, then shuffle | | |

## Variables

| Name | Meaning |
|---|---|
| `pa` | screen address passed to 1000 |
| `of`, `yy`, `xx` | 1000's temporaries: offset from `sb`, row, column |
| `sb` | screen RAM base, 7680 |
| `pp` | post number (parameter and loop variable) |
| `pb` | origin address of the post being drawn |
| `i` | loop temporary (draw rows, deal slots, lock check) |
| `b$` | checker glyph, `chr$(230)` |
| `po%(10,7)` | posts (see Data model) |
| `cl%(4)` | ring color codes |
| `r`, `c` | setup: post row and column. `r` also takes the dummy result of `rnd(-ti)` |
| `k$` | key read by `get` |
| `n` | post selected by a key (1-10) |
| `hp` | post with a lifted ring (0 = none) |
| `t` | top ring index (from 4000); swap temporary in the deal |
| `l` | lock result from 4100, or complete result from 4110 |
| `j`, `a` | deal: random ring number, then its slot (`j`) and post (`a`). `j` is also the delay loop of the win chime and the lock sound; `a` is also 6000's screen address |
| `mv`, `mb` | moves this game; session best moves (0 = no win yet) |
| `tb`, `te`, `tw` | timer: `ti` when the board was drawn; elapsed seconds last shown (the final time after a win); session best time in seconds |
| `wn` | timer state: 0 running, -1 frozen by a win, 1 stopped at 99:59 |
| `w`, `d`, `q`, `m` | 6000/6200: value to show, digit count, quotient temporary, minutes |
| `v`, `f`, `e`, `s` | sound sweep (5000): register, from, end, step |

`pa` through `b$` are created first, on line 1, because BASIC searches variables in creation order and these are read most often while drawing. `po%` is dimmed before `cl%` for the same reason: arrays are searched in creation order too.

## Details worth knowing

- **Key to post:** `n=val(k$)-10*(k$="0")`. A comparison is -1 when true, so key `0` gives 0+10=10, and keys `1`-`9` give 1-9.
- **The deal:**
  - It fills slots 2-6 in order (posts 1-2 get color 0, posts 3-4 color 1, and so on), clears slots 0-1, then shuffles.
  - The shuffle is Fisher-Yates over the 50 rings, numbered `k=pp*5+i-6` (1-50). Each ring swaps with a random ring `j` from 1 to `k`, which lives at post `a=int((j-1)/5)+1`, slot `j-5*a+6`.
  - The shuffle runs in place in `po%`, so no separate array is needed.
  - **Progress block:** before the shuffle, `poke7690,160` puts a reverse space after "dealing..." (row 0, column 10). Each swap pokes its color RAM (38410) with `(jand7)or1`, using the random ring number `j`. Color RAM takes VIC color numbers 0-7, not the PETSCII codes in `po%`; `or1` keeps the result odd (white, cyan, green, yellow), so the block never turns black and vanishes.
- **Win check:** only a drop that locks its destination post can finish the game, so 400 checks that post first and scans all 10 posts only if it just locked. The scan stops at the first post that isn't locked.
- **Lock sound timing:** 440 redraws the destination post first, then checks its lock and plays the lock sound, and only then redraws the source post. So the solid base appears and the sound plays together. The lock check is repeated at 450 for the win check, because drawing the source post (2000) overwrites `l`. On the winning drop, the lock sound plays before the win chime.
- **Redraws:** a move redraws only the posts it touches (routine 2000); `r` and a new game redraw everything (3000).
- **Seeding:** `rnd(-ti)` seeds from the jiffy clock, so the seed is only as varied as the moment it's taken. Autostart resets the machine and reaches line 2 at almost the same `ti` every time (157 or 158 jiffies, measured in xvic), so seeding at startup gave the same first board on nearly every launch, and `rnd(1)` then repeated the same series of boards. Seeding twice (`rnd(-ti)`, then `rnd(-rnd(1)*1000)`) doesn't help: the same input still gives the same output. So the seed is taken when a human presses a key: the splash (7000) seeds on its keypress, and each new game reseeds on its `y` (230).
- **The live timer:** there's no interrupt code of our own. The KERNAL's interrupt already increments the jiffy clock `ti` 60 times a second.
  - The main loop's idle `get` loop calls 6100 on every pass. It computes the elapsed seconds `int((ti-tb)/60)` and redraws only when they change, so the cost is one calculation per pass.
  - During sounds and redraws the display doesn't update, but the clock keeps counting, and the next idle pass catches up. The time is always computed from `ti`, so it never drifts.
  - The digits are poked into screen memory (screen code 48 + digit) rather than printed with `str$()`. That makes no string garbage, so no garbage-collection pause, and it doesn't move the cursor. The row was printed once in white, so the digit cells' color RAM is already white.
  - **Limits:** elapsed time is clamped to 99:59 (5999 seconds), and the timer stops there (`wn=1`); play continues. A negative elapsed time, from `ti` wrapping 24 hours after power-on, is clamped the same way instead of poking an illegal value. The win takes its final time through the same clamp (6110), so the recorded best always matches the display.
- **Keyboard buffer:** the KERNAL keeps up to 10 keys typed while the program is busy, and address 198 holds the count.
  - The full-screen draw (3000) ends with `poke198,0`, which discards keys typed during the deal or an `r` redraw, so they can't make moves on a board the player hasn't seen yet.
  - Move redraws don't flush: there, type-ahead is wanted (a quick `1` then `2` should lift and drop).
  - The y/n prompt doesn't flush either, so a fast `n` then `y` works.

## Sound

**How the VIC makes sound:**
- **Voices:** three square-wave voices, low (36874), middle (36875) and high (36876), plus noise (36877).
- **Pitch:** a voice plays when its register holds 128-255 (higher = higher pitch) and is silent at 0.
- **Volume:** 36878 holds the volume (0-15) for all voices. Line 2 sets it to 15, and quitting (990) sets it to 0, so no stuck note keeps playing.
- **No envelopes or timers:** a sweep is a BASIC loop poking the pitch, and the game waits while it runs.

**Where each sound plays:** the move sounds play after the move text is printed and before the posts are redrawn, so the text appears first.

**Tuning:** I can't hear xvic, so these values are a starting point to adjust by ear. In routine 5000, a smaller step (`s`, which may be a fraction such as `.5`, since `poke` drops the fraction) makes a sweep longer and smoother.

| Sound | Line | Voice | Values |
|---|---|---|---|
| ring up | 360 | middle 36875 | `f=200`, `e=240`, `s=4` (rising) |
| ring down | 430 | middle 36875 | `f=240`, `e=190`, `s=-2` (a longer, deeper fall than ring up, so it doesn't sound like cancel) |
| invalid move (lift or drop) | 390 | low 36874 | `f=150`, `e=130`, `s=-1` (falling buzz) |
| cancel | 480-485 | noise 36877 at 250 | sweeps the **volume** 36878 from 15 to 0 by -1 (a short, airy fade), then restores it to 15 |
| win | 5100 | high 36876 | notes `195+i*12` for `i`=1-4 (207, 219, 231, 243), each held by a 99-step delay loop |
| lock ("ding-ding") | 5200-5220 | high 36876 | a bell at 230: the volume fades 15 to 0 by -1. Then a bell at 240: held at volume 15 for a 60-step delay loop, then the same fade. Then the voice goes off and the volume back to 15. Chosen by ear to sound unlike the lift and drop sweeps (middle voice) and the win chime (rising notes, no fade). A slower fade alone wasn't audible as longer; the hold is what makes the second bell ring out. |
| deal | 20070-20150 | middle 36875 | `200+j` on every shuffle swap (random pitch), at volume 6 so it stays in the background; after the shuffle the voice goes off and the volume back to 15 |

## Memory

On an unexpanded VIC-20, program and variables share 3583 bytes.

| Date | PRG | Free during play | Note |
|---|---|---|---|
| 2026-10-24 | 3245 | ~16 | move logic, with development `rem`s |
| 2026-10-24 | 1519 | ~1738 | tightened: `rem`s moved here, lines joined |
| 2026-10-24 | 1526 | ~1731 | keyboard flush after full draws |
| 2026-10-24 | 1748 | ~1509 | move row messages (red `TO M` on an invalid drop), the dealing progress block, white "dealing..." |
| 2026-10-24 | 2061 | ~1170 | sounds: ring up/down, invalid, cancel, win, deal (quieter and lower) |
| 2026-10-25 | 2243 | 984 | solid base on complete posts, lock sound (measured: `?fre(0)` after a move and quit) |
| 2026-10-25 | 2932 | 239 | score: moves, live timer, session best; splash screen; keypress seeding (measured the same way; not tightened) |

The arrays take 204 bytes (`po%` 185, `cl%` 19), and the 18 simple variables take 7 bytes each (126).
