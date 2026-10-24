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
- **Messages start at column 1,** aligned with the left edge of the posts.
- **Row 19** is the move row: `MOVE N` when a ring is lifted from post N, `TO M` at column 12 when it's dropped on post M, and `MOVE CANCELED` when it's put back. A new lift clears the row. A new game or redraw clears the whole screen, including this row. Row 18 stays blank as a gap below the bottom posts' bases.
  - Dropping on a full post prints `TO M` in red (and "invalid move" on row 20). The ring stays lifted; the next valid drop overwrites the red text with a white `TO M`.
  - The text is printed *before* the posts are redrawn, so the player sees the response at once; a post redraw takes about half a second.
- **Row 20** is the message row: "new game? y/n", "invalid move", "solved!".
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
- **Locked:** slot 1 is empty and slots 2-6 all hold the same color. This is computed when needed (routine 4100), not stored, so it can't get out of sync with the board.

## Routines

| Line | Routine | In | Out |
|---|---|---|---|
| 1-2 | init: variables, arrays, seed, setup, first deal and draw | | |
| 110 | main loop: `get` a key and dispatch | | |
| 200 | new game: ask y/n on row 20, then deal and draw | | |
| 300 | post key: lift post `n`'s top ring, or drop onto `n` if a ring is lifted | `n` | |
| 390 | print "invalid move" | | |
| 395 | invalid drop: print `TO n` in red on the move row, then "invalid move" (390) | `n` | |
| 400 | drop the lifted ring onto post `n`, redraw both posts, print `TO n`, check for a win | `n`, `hp` | |
| 480 | the drop was a cancel (`n` = `hp`): print `MOVE CANCELED` | | |
| 990 | quit: restore screen colors and blue text | | |
| 1000 | move the cursor to screen address `pa` (KERNAL PLOT) | `pa` | |
| 1100 | move the cursor to the start of the message row | | |
| 1200 | clear the message row | | |
| 1300 | clear the move row (19) and park the cursor at its start | | |
| 2000 | draw post `pp`: rows 0-6 from `po%`, then the base | `pp` | |
| 3000 | clear the screen, draw all posts, discard keys typed meanwhile | | |
| 4000 | find the top ring of post `pp` | `pp` | `t` |
| 4100 | is post `pp` locked? | `pp` | `l` (-1/0) |
| 5000 | sound sweep: step register `v` from `f` to `e` by `s`, then poke `v` with 0 | `v`, `f`, `e`, `s` | |
| 5100 | win chime: 4 rising notes on the high voice | | |
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
| `l` | lock result from 4100 |
| `j`, `a` | deal: random ring number, then its slot (`j`) and post (`a`). `j` is also the win chime's delay loop |
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
- **Redraws:** a move redraws only the posts it touches (routine 2000); `r` and a new game redraw everything (3000).
- **Seeding:** `rnd(-ti)` at startup. In xvic, autostart takes the same time on every run, so the first deal can repeat between runs; on real hardware, the time spent typing `RUN` varies it.
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
| deal | 20120, 20150 | high 36876 | `200+j` on every shuffle swap (random pitch); off after the shuffle |

## Memory

On an unexpanded VIC-20, program and variables share 3583 bytes.

| Date | PRG | Free during play | Note |
|---|---|---|---|
| 2026-10-24 | 3245 | ~16 | move logic, with development `rem`s |
| 2026-10-24 | 1519 | ~1738 | tightened: `rem`s moved here, lines joined |
| 2026-10-24 | 1526 | ~1731 | keyboard flush after full draws |
| 2026-10-24 | 1748 | ~1509 | move row messages (red `TO M` on an invalid drop), the dealing progress block, white "dealing..." |
| 2026-10-24 | 2039 | ~1190 | sounds: ring up/down, invalid, cancel, win, deal |

The arrays take 204 bytes (`po%` 185, `cl%` 19), and the 18 simple variables take 7 bytes each (126).
