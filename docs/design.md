# ringsort design notes

How `src/ringsort.bas` works. The source has no comments: they cost too much memory on an unexpanded VIC-20. This file is where the explanations live, so update it whenever the code changes.

## The game

- 10 posts. Three modes (`md`):

| Mode | `md` | Rings | Start | Drop rule | Post capacity |
|---|---|---|---|---|---|
| classic | 0 | 50, 5 colors (red, green, blue, yellow, cyan) | 5 rings on every post | any color on any color | 6 (5 + the cap slot) |
| hard | 1 | 40, 4 colors (no blue) | 5 rings on posts 1-4 and 6-9; posts 5 and 10 empty | only on the same color, or on an empty post | 6 |
| expert | 2 | as hard | as hard | as hard | 5 (no cap slot) |

- **Moves:**
  - Press a post's key (`1`-`9`, `0` for post 10) to lift its top ring.
  - Press another post's key to drop the ring there.
  - Pressing the same post again, or space, puts the ring back.
- **Capacity:** in classic and hard, a post holds up to 6 rings. The sixth sits in the post's cap slot, and in classic that slot is what makes the first move from a full board possible. In expert, a post with 5 rings is full.
- **Locked posts:** a post holding exactly 5 rings of one color is locked. You can't lift from it, but (in classic and hard) you can park a ring in its cap slot and lift that ring again later.
- **Winning:** you win when every post is locked or empty.
- **Score:** moves (successful drops; cancels and invalid moves don't count) and time, both live on the top row. The timer starts when the board is drawn, freezes on a win, and stops at 99:59. The session's best moves and best time (tracked separately, and per mode) show on row 21 once a game in the current mode is won. They're lost on quit.
- **Splash:** at launch a title screen waits for a key; that keypress seeds the random numbers and picks the mode (`h` hard, `e` expert, any other key classic).
- **Other keys:** `n` new game (asks `c/h/e` for the mode, then a deal number; any other key cancels), `r` redraw, `q` quit.
- **Deal numbers:** every deal has a number from 1 to 99999, shown on row 22 with the mode. After `n` and a mode key, the player types a deal number to replay or share a deal, or presses Return alone for a random one. The first game after the splash is random. Hard and expert share their deal code, so the same number gives the same board in both.
- **Difficulty** (measured with a solver on random deals, not the VIC's own random numbers): every sampled hard and expert deal (2000 and 300) was winnable. Shortest solutions are about 36 moves in both, versus about 67 in classic. What differs is how easy it is to get stuck: a greedy player with no lookahead gets stuck in about 12% of hard deals and 40% of expert deals; in classic you can't get stuck at all. The free space (20 empty slots in hard, 10 in expert) is what sets the difficulty; one empty post instead of two made almost no difference.

## Screen layout

The screen is 22×23 characters; screen RAM starts at 7680. The program passes cursor positions as **offsets** from it (`22*row+column`, 0-505); only the digit pokes (6000) and the dealing block use absolute addresses.

- **Posts:** 2 rows of 5. Post `pp` (1-10) has its origin (top-left cell) at `x=1+col*4`, `y=1+row*9`, where `row=int((pp-1)/5)` and `col=pp-1-5*row`. Multiplied out, the offset is `19+4*pp+178*row`, and line 2 computes it as `19+4*pp-178*(pp>5)` (a comparison is -1 when true).
- **Each post is 8 screen rows tall:**

```
row 0   rrr   hover: the lifted ring, or blank
row 1    #    cap slot: pole top, or a 6th ring
row 2   rrr   ring slots 2-6, stacked on the base
...
row 6   rrr
row 7   ###   base (never moves)
```

- **Characters:** a ring is 3 cells: `{rvs on}<color> <checker> {rvs off}`. The pole and base use the checker glyph in white, written in the strings as `{CBM-+}` (PETSCII 166; 230 is the same glyph). It sits inside the string literals, so it costs 1 byte per use and needs no variable.
- **Drawing a post:** one PLOT to the post origin, then each of rows 0-6 is printed with a trailing `{down}{left}{left}{left}`, which steps the cursor to the start of the next row. One PLOT per row was slower and cost more bytes.
- **Complete posts:** when slots 2-6 hold one color, the base is drawn as 3 reverse spaces in that color instead of the white checker, so the post looks like a filled vessel. The solid base ends with `{wht}`, so the text printed next (the move row, messages) stays white.
- **Messages start at column 1,** aligned with the left edge of the posts.
- **Row 19** is the move row: `FROM N` when a ring is lifted from post N, `TO M` at column 12 when it's dropped on post M, and `MOVE CANCELED` when it's put back. A new lift clears the row. A new game or redraw clears the whole screen, including this row. Row 18 stays blank as a gap below the bottom posts' bases.
  - Dropping on a full post (or, in hard and expert, on a different color) prints `TO M` in red (and "invalid move" on row 20). The ring stays lifted; the next valid drop overwrites the red text with a white `TO M`.
  - The text is printed *before* the posts are redrawn, so the player sees the response at once; a post redraw takes a moment.
- **Row 20** is the message row: "new game? c/h/e", "deal #" (with the digits typed so far), "invalid move", "solved!". On a win, the move row is cleared first.
- **Row 0** is the status row: `MOVES 000 TIME 00:00` from column 1 to 20 (moves digits at columns 7-9, minutes 16-17, seconds 19-20). Printed by 3100 on every full draw; after that only the digits are poked (6000).
- **Row 21** is the session best, in cyan: `BEST  000      00:00`, digits in the same columns as row 0. Drawn only once a game in the current mode has been won, and shows that mode's best.
- **Row 22** shows `DEAL n`, the current deal number, printed by 3110 on every full draw. In hard and expert, 3120 adds `(HARD)` or `(EXPERT)` in red, cut from the string `"hardexpert"` with `mid$` (start `4*md-3`, length `2*md+2`); the label ends with `{wht}`. Classic has no label for now.
- **Splash (7000):** "RINGSORT" at row 6, column 7, each letter in a color (red, green, purple, yellow, cyan, repeating; no blue, which is hard to read on black); "CODEMONKEYATL" at row 8, column 4; "PRESS A KEY" at row 20, column 5.
- **While dealing,** row 0 shows "dealing..." followed by a block in column 10 that changes color on every swap of the shuffle.

## Data model

`po%(10,7)`: one row per post (`pp`=1-10; row 0 is unused). **Index `k` is the screen row below the post origin**, so slot `k` is drawn at `origin+22*k`.

| `k` | Holds |
|---|---|
| 0 | hover ring: the ring lifted from this post (at most one post at a time) |
| 1 | cap slot: a 6th ring, empty at the start |
| 2-6 | rings 1-5, stacked on the base |
| 7 | the post origin's screen offset (see Screen layout) |

Ring values are PETSCII color codes (red 28, green 30, blue 31, yellow 158, cyan 159). 0 = empty. The colors exist only as the string literal `"{red}{grn}{blu}{yel}{cyn}{red}{grn}{yel}{cyn}"` in the deal (2510): the first five for classic, the last four (no blue) for hard and expert. There's no color array.

**Rules expressed in the model:**
- **Top ring:** the lowest non-zero index from 1 to 6. Routine 4000 scans up from index 1 and needs no bounds check: index 7 holds a screen offset, which is at least 23 and never 0, so the scan always stops there at the latest. `t=7` means the post is empty. The scan is `fort=1to7:ifpo%(pp,t)=0thennext`: when the `if` is false, the rest of the line is skipped and the next line returns, leaving the `for` unfinished. That's safe because `return` discards any unfinished `for` loops started inside the subroutine (4120 relies on the same thing).
- **Drop target:** the index just above the top ring (`t-1`). It's legal only if `t>1` (`t=1` means the post is full), and in expert only if `t>2` (5 rings is full): 400 tests `t<2-(md=2)`.
- **Color rule (hard and expert):** 410 rejects the drop when `md>0`, the target isn't the ring's own post (that's a cancel), the target isn't empty (`t<7`), and its top ring `po%(pp,t)` differs from the lifted ring. All four tests are safe to evaluate together: when `t=7`, `po%(pp,7)` is a screen offset, which just fails the color test harmlessly.
- **Complete:** slots 2-6 all hold the same color (routine 4110). The base shows this.
- **Locked:** complete, and slot 1 is empty (routine 4100, which falls into 4110). The lift rule and the win check use this. The win check (460) also accepts empty posts (`po%(pp,6)=0`), for hard and expert.
- Both are computed when needed, not stored, so they can't get out of sync with the board.
- **Why the base follows "complete", not "locked":** parking a ring in a locked post's cap slot makes it unlocked (so that ring can be lifted again), but it stays complete. If the base followed the lock, it would switch to checker and back every time a ring is parked and lifted. A complete post also can't become incomplete: its slots 2-6 can only be lifted from when the cap slot is empty, and then the post is locked. So once a base turns solid, it stays solid until the next deal.

## Routines

| Line | Routine | In | Out |
|---|---|---|---|
| 1-2 | init: hot variables, `po%`, volume and colors, post offsets `po%(pp,7)`; then the splash and the first game (210) | | |
| 110 | main loop: `get` a key and dispatch; while no key, tick the timer (6100). Only `n` (tested last, at 160) ends with `goto110`; the other branches fall through the remaining tests, which can't match their key | | |
| 170 | new game prompt: ask `c/h/e` on row 20; `j` becomes 0, -1 or -2 for `c`, `h`, `e`. On one of those keys (175) set `md=-j`, read a deal number (250) and start a game (210); clear the prompt either way | | `md` |
| 210 | start a game: if `dn` is 0, seed from `ti` and pick a random deal number; then (220) seed `rnd(-dn)`, deal and draw (2500), start the timer | `dn` | `dn` |
| 250 | read a deal number on the message row: digits (up to 5) are echoed, DEL erases one, other keys are ignored, Return ends. Nothing typed (or 0) leaves `dn`=0, which 210 turns into a random deal | | `dn` |
| 300 | post key: lift post `n`'s top ring, or drop onto `n` if a ring is lifted | `n` | |
| 390 | print "invalid move" | | |
| 395 | invalid drop: print `TO n` in red on the move row, then "invalid move" (390) | `n` | |
| 400 | drop the lifted ring onto post `n` (full post, or in hard/expert a different color at 410: invalid via 395), count the move (425), print `TO n`, redraw both posts (playing the lock sound if `n` just locked), check for a win | `n`, `hp` | |
| 470 | win: freeze the timer, clear the move row, print "solved!", update and show the current mode's session best (`mb%(md)`, `tw%(md)`), play the chime | | |
| 480 | the drop was a cancel (`n` = `hp`): print `MOVE CANCELED` | | |
| 990 | quit: restore screen colors and blue text | | |
| 1000 | move the cursor to screen offset `pa` (KERNAL PLOT; `poke` drops the fraction of `pa/22`) | `pa` | |
| 1100 | move the cursor to the start of the message row | | |
| 1200 | clear the message row | | |
| 1300 | clear the move row (19) and park the cursor at its start | | |
| 2000 | draw post `pp`: rows 0-6 from `po%`, then the base (solid if complete, checker otherwise) | `pp` | `l` is clobbered |
| 2400 | map ring number `j` to its post `a` and slot `j` (posts 5 and 10 skipped when `md>0`) | `j`, `md` | `a`, `j` |
| 2500 | deal for mode `md`: clear all posts, fill in order, then shuffle; falls into 3000 | `md` | |
| 3000 | clear the screen, draw all posts, discard keys typed meanwhile; falls into 3100 | | |
| 3100 | draw the status row (row 0) and the deal row (row 22, with the mode label at 3120), then fall into 3200 | | |
| 3200 | draw the current mode's session best (row 21), if a game in that mode has been won | `md` | |
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
| 7000 | splash screen: wait for a key (`wait198,255`), read it and pick the mode: `md=-(k$="h")-2*(k$="e")` | | `md` |

## Variables

| Name | Meaning |
|---|---|
| `pa` | screen offset passed to 1000 |
| `pp` | post number (parameter and loop variable) |
| `i` | loop temporary (draw rows, deal slots, lock check, digits) |
| `po%(10,7)` | posts (see Data model) |
| `md` | mode: 0 classic, 1 hard, 2 expert |
| `mb%(2)`, `tw%(2)` | session best moves and time, one per mode (0 = no win yet in that mode). Integer arrays: moves stay under 1000 and times under 6000 |
| `k`, `r` | deal: ring number (loop), number of rings (50, or 40 when `md>0`) |
| `k$` | key read by `get` |
| `n` | post selected by a key (1-10) |
| `dn` | deal number (1-99999; 0 = pick a random one) |
| `hp` | post with a lifted ring (0 = none) |
| `t` | top ring index (from 4000); swap temporary in the deal; 6000's quotient; the dummy result of `rnd(-ti)` |
| `l` | lock result from 4100, or complete result from 4110 |
| `j`, `a` | deal: random ring number, then its slot (`j`) and post (`a`). `j` is also the delay loop of the win chime and the lock sound, 6200's minutes and 250's digit count; `a` is also 6000's screen address and 250's key code |
| `mv` | moves this game |
| `tb`, `te` | timer: `ti` when the board was drawn; elapsed seconds last shown (the final time after a win) |
| `wn` | timer state: 0 running, -1 frozen by a win, 1 stopped at 99:59 |
| `w`, `d` | 6000/6200: value to show, digit count |
| `v`, `f`, `e`, `s` | sound sweep (5000): register, from, end, step |

`pa`, `pp` and `i` are created first, on line 1, because BASIC searches variables in creation order and these are read most often while drawing.

The temporaries `t`, `j` and `i` are shared between routines that never run inside each other's use of them: 6000 runs from the move code only after 420 is done with `t`, and 6200 runs only from the idle loop, the win and the full draw, none of which is inside the deal's or a sound's use of `j`.

## Details worth knowing

- **Key to post:** `n=val(k$)-10*(k$="0")`. A comparison is -1 when true, so key `0` gives 0+10=10, and keys `1`-`9` give 1-9.
- **The deal:**
  - It clears every post, fills the rings in order (each pair of posts gets one color), then shuffles. Rings are numbered `k` from 1 to `r` (50, or 40 when `md>0`). Routine 2400 maps a ring number `j` to its post and slot: post `a=int((j-1)/5)+1`, slot `j-5*a+6`; when `md>0`, `a=a-int((a-1)/4)*(md>0)` then shifts posts 5-8 to 6-9, so posts 5 and 10 stay empty.
  - Ring `k`'s color is `asc(mid$("{red}{grn}{blu}{yel}{cyn}{red}{grn}{yel}{cyn}",(k-1)/10+1-5*(md>0)))`: `mid$` drops the fraction of its position, and `md>0` moves the start to the four colors without blue. Each `mid$` leaves a 1-byte string as garbage, 40-50 per deal; with so few live strings, garbage collection is quick and happens off the gameplay path.
  - The shuffle is Fisher-Yates over the rings, from `k=r` down to 1. Each ring swaps with a random ring `j` from 1 to `k`. Both positions come from 2400.
  - **Classic deals didn't change** when modes were added: for `md=0` the fill, the order of `rnd` calls and every swap are exactly what the earlier nested `pp`/`i` loops did, so classic deal numbers shared before still give the same boards (checked in xvic with deal 123).
  - The shuffle runs in place in `po%`, so no separate array is needed.
  - **Progress block:** before the shuffle, `poke7690,160` puts a reverse space after "dealing..." (row 0, column 10). Each swap pokes its color RAM (38410) with `(jand7)or1`, using the random ring number `j`. Color RAM takes VIC color numbers 0-7, not the PETSCII codes in `po%`; `or1` keeps the result odd (white, cyan, green, yellow), so the block never turns black and vanishes.
- **Win check:** only a drop that locks its destination post can finish the game, so 400 checks that post first and scans all 10 posts only if it just locked. The scan stops at the first post that isn't locked.
- **Lock sound timing:** 430 redraws the destination post first, then checks its lock and plays the lock sound, and only then redraws the source post. So the solid base appears and the sound plays together. The lock check is repeated at 445 for the win check, because drawing the source post (2000) overwrites `l`. On the winning drop, the lock sound plays before the win chime.
- **Redraws:** a move redraws only the posts it touches (routine 2000); `r` and a new game redraw everything (3000).
- **Seeding:** `rnd(-ti)` seeds from the jiffy clock, so the seed is only as varied as the moment it's taken. Autostart resets the machine and reaches line 2 at almost the same `ti` every time (157 or 158 jiffies, measured in xvic), so seeding at startup gave the same first board on nearly every launch, and `rnd(1)` then repeated the same series of boards. Seeding twice (`rnd(-ti)`, then `rnd(-rnd(1)*1000)`) doesn't help: the same input still gives the same output. So the seed is taken when a human presses a key: 210 seeds right after the splash's keypress, and again after each new game's deal number entry (250).
- **Deal numbers:** a deal is fully determined by its seed, so the deal number is the seed. For a random deal, 210 seeds from `ti`, discards one `rnd(1)`, picks `dn=int(rnd(1)*99999)+1` from the next; then 220 reseeds with `rnd(-dn)`, discards two `rnd(1)` values, and deals. A typed number skips straight to 220. So the same number always gives the same board. Details:
  - `dn` is an ordinary float variable, so 5 digits need no range check: any 1-99999 is valid. It's never used with `and`/`or` or stored in an integer array, which is where the 32767 limit applies.
  - 0 is never a seed: `rnd(0)` reads a hardware timer instead of seeding. Entering 0 (or nothing) gives a random deal instead.
  - **Why the discards:** the first `rnd(1)` after `rnd(-x)` is almost a linear function of `x` when neighboring seeds have the same float exponent. Measured in xvic: seeds 150-159 gave deal numbers 4629, 99758, 95278, 90410, … (each about 4870 lower, wrapping), and seeds 50000-50004 gave first values .001, .908, .814, .721, .627. The second value is still partly patterned; the third and later look independent. So the random pick uses the 2nd value after the `ti` seed, and the shuffle starts at the 3rd value after the `dn` seed. Without the discards, neighboring `ti` values gave evenly stepped deal numbers, and neighboring deal numbers shared the first swaps of the shuffle.
  - **Measured fairness** (2000 consecutive `ti` seeds, bucketed by 10000): the first value gave a suspiciously perfect 195-205 per bucket (the fixed step wrapping); the second value gave 185-217 with 47 neighbor pairs within 1000 of each other (about 40 expected), which is what independent random numbers look like.
  - **Variety of the first game:** its seed is the `ti` jiffy count when the splash key is pressed, so a press 1-10 seconds after launch can give about 540 different first deals, each equally likely. Every jiffy (1/60 s) gives a different deal, and human timing isn't that precise, so it isn't predictable. Later games seed from `ti` at the deal prompt, which ranges much wider.
  - **Deal numbers are tied to the deal code** (2400-2550) and to the order of `rnd` calls. Changing the shuffle or the colors changes what every number means. The mode shown next to the number on row 22 tells the deal variants apart: classic deal 123 and hard deal 123 are different boards (hard and expert deal 123 are the same board).
  - The entry routine (250) builds the number arithmetically (`dn=dn*10+a-48`, `dn=int(dn/10)` for DEL), so it makes no string garbage. It echoes accepted keys by printing `k$` itself; printing DEL (20) erases the last digit on screen.
- **The live timer:** there's no interrupt code of our own. The KERNAL's interrupt already increments the jiffy clock `ti` 60 times a second.
  - The main loop's idle `get` loop calls 6100 on every pass. It computes the elapsed seconds `int((ti-tb)/60)` and redraws only when they change, so the cost is one calculation per pass.
  - During sounds and redraws the display doesn't update, but the clock keeps counting, and the next idle pass catches up. The time is always computed from `ti`, so it never drifts.
  - The digits are poked into screen memory (screen code 48 + digit) rather than printed with `str$()`. That makes no string garbage, so no garbage-collection pause, and it doesn't move the cursor. The row was printed once in white, so the digit cells' color RAM is already white.
  - **Limits:** elapsed time is clamped to 99:59 (5999 seconds), and the timer stops there (`wn=1`); play continues. A negative elapsed time, from `ti` wrapping 24 hours after power-on, is clamped the same way instead of poking an illegal value. The win takes its final time through the same clamp (6110), so the recorded best always matches the display.
- **Keyboard buffer:** the KERNAL keeps up to 10 keys typed while the program is busy, and address 198 holds the count.
  - The full-screen draw (3000) runs `poke198,0` after drawing the posts, which discards keys typed during the deal or an `r` redraw, so they can't make moves on a board the player hasn't seen yet.
  - Move redraws don't flush: there, type-ahead is wanted (a quick `1` then `2` should lift and drop).
  - The new game prompt doesn't flush either, so a fast `n` then `c` works.
  - The splash, the new game prompt and the deal number entry wait with `wait198,255`, which pauses until the count is non-zero (any key), with no loop line of its own. `wait198,1` would hang when 2 keys are already waiting.

## Sound

**How the VIC makes sound:**
- **Voices:** three square-wave voices, low (36874), middle (36875) and high (36876), plus noise (36877).
- **Pitch:** a voice plays when its register holds 128-255 (higher = higher pitch) and is silent at 0.
- **Volume:** 36878 holds the volume (0-15) for all voices. Line 1 sets it to 15, and quitting (990) sets it to 0, so no stuck note keeps playing.
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
| deal | 2520-2550 | middle 36875 | `200+j` on every shuffle swap (random pitch), at volume 6 so it stays in the background; after the shuffle the voice goes off and the volume back to 15 |

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
| 2026-10-25 | 2569 | 690 | second tightening: 10 fewer variables (screen offsets instead of addresses, shared temporaries, the checker glyph embedded as `{CBM-+}` instead of `b$`), no color array, one PLOT per post draw, tail calls and joined lines (measured the same way) |
| 2026-10-25 | 2817 | 435 | deal numbers: random 1-99999 or typed after `n`/`y`, shown on row 22 (entry ~150 bytes, seeding ~80 including the `rnd` discards, display ~25) |
| 2026-10-25 | 3123 | 75 | modes: classic, hard, expert (deal +77 bytes, drop rules +52, row 22 label +48, per-mode bests +59, mode keys +66, win with empty posts +12); not tightened |

`po%` takes 185 bytes, `mb%` and `tw%` 13 each, and the 24 simple variables take 7 bytes each (168).
