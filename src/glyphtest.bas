1 rem scratch: verify docs/cheatsheet.md graphics petscii table
2 rem black background, white border
3 poke36879,9:dimbx(7)

8 rem page 1: each code the cheatsheet lists, next to its claim
9 rem printed normal (n) and reversed (r)
11 print"{clr}{wht}cheatsheet claims"
12 print"pet n r claim"
20 fori=1to14:readc,c$
30 printright$(str$(c),3);" ";chr$(c);"{wht} {reverse on}";chr$(c);"{reverse off}{wht} ";c$
40 next
50 print:print"any key: all glyphs";:gosub900

100 data93,"box corner",94,"box corner",95,"box corner",160,"upper half"
101 data162,"lower half",221,"diag slash",222,"diag bslash",223,"solid/check"
102 data250,"dotted blk",251,"checkerbd",255,"full block",156,"purple blk"
103 data102,"check rvsoff",230,"check rvson"

200 rem page 2: every printable graphic code, 8 per row, row label = first code
201 rem 192-255 are printed too, to check they repeat 96-127 and 160-191
210 print"{clr}{wht}glyphs 96-127,160-191"
220 g=96:gosub500:g=160:gosub500
230 print"aliases: 192-255"
240 g=192:gosub500:g=224:gosub500
250 print:print"any key: boxes";:gosub900

300 rem page 3: the two box styles from meatloaf-prgs wifi-vic20.bas line 20120
301 rem per style: top-left, top, top-right, bottom-left, bottom, bottom-right,
302 rem left side, right side
310 print"{clr}{wht}wifi-vic20 boxes":print
320 forb=0to1:fori=0to7:readx:bx(i)=x:next
330 printchr$(bx(0));chr$(bx(1));chr$(bx(1));chr$(bx(1));chr$(bx(2))
340 printchr$(bx(6));"box";chr$(bx(7))
350 printchr$(bx(3));chr$(bx(4));chr$(bx(4));chr$(bx(4));chr$(bx(5)):print:next
360 print"any key: exit";:gosub900
370 poke36879,27:print"{clr}{blu}";:end

380 data117,96,105,106,96,107,98,125,176,96,174,173,96,189,179,171

500 rem print codes g to g+31 as 4 rows of 8
510 forc=gtog+31step8:printright$(str$(c),3);" ";
520 forj=0to7:printchr$(c+j);" ";:next:print:next:return

900 rem wait for a key; clear the buffer first so autostart's leftover keys don't count
910 poke198,0
920 getk$:ifk$=""then920
930 return
