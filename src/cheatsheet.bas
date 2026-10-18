🎨VIC‑20 petcat color tokens
These are the only valid {color} tokens for VIC‑20.
(Anything like {brn}, {pur}, {gry} is C64‑only and does not exist on VIC‑20.)

PETSCII	petcat token	Color
144		{blk}			black
5		{wht}			white
28		{red}			red
30		{grn}			green
31		{blu}			blue (dark blue)
158		{yel}			yellow
159		{cyn}			cyan / light blue


That’s the full VIC‑20 set.  
The VIC‑20 has 7 text colors, not 16.

🖥️ Screen‑manipulation PETSCII control codes
These are the codes you embed in strings (e.g., print "{clr}") and are recognized by VIC‑20 BASIC V2.

PETSCII	petcat token	Action
147		{clr}			clear screen
19		{home}			move cursor to top‑left
17		{down}			cursor down
29		{right}			cursor right
145		{up}			cursor up
157		{left}			cursor left
18		{reverse on}	enable reverse video
146		{reverse off}	disable reverse video


These are the full set of VIC‑20 cursor/mode controls supported by petcat.

🔳 Useful VIC‑20 graphics PETSCII codes
These are not petcat tokens (because they’re glyphs, not actions), but they are essential for PETSCII art and UI:

PETSCII	Description
93–95	box corners
160	upper‑half block
162	lower‑half block
221	diagonal slash
222	diagonal backslash
223	solid/checker block
250	dotted block
251	checkerboard
255	full block
156	magenta/purple block (VIC‑20 glyph)
102 checker w/reverse off
230 checker w/reverse on

🧠 VIC‑20 Color Registers
Address		Function					Range	Notes
36879		Border color				0–7		Controls only the border color.
36878		Background color			0–7		Controls the main screen background.
36874–36877	Character color registers	0–7		Used for multicolor text modes and graphics.


8	black/black
9	black/white
10	black/red
11	black/cyan
12	black/purple
13	black/green
14	black/blue
15	black/yellow


Value	Color
0	black
1	white
2	red
3	cyan
4	purple
5	green
6	blue
7	yellow