1 rem scratch: verify docs/cheatsheet.md color tables. black background, white border
2 poke36879,9:print"{clr}{wht}v pet tok  ch tk rm"

100 rem vic-20 colors, one row per color value 0-7
101 rem ch = chr$(pet) then a block, tk = petcat token then a block
102 rem rm = white block, recolored at line 300 by poking color ram with v
103 rem each swatch starts from white, so a code with no effect shows a white block
110 print"0 144 blk  ";chr$(144);"{reverse on}  {reverse off}{wht} {blk}{reverse on}  {reverse off}{wht} {reverse on}  {reverse off}"
111 print"1   5 wht  ";chr$(5);"{reverse on}  {reverse off}{wht} {wht}{reverse on}  {reverse off}{wht} {reverse on}  {reverse off}"
112 print"2  28 red  ";chr$(28);"{reverse on}  {reverse off}{wht} {red}{reverse on}  {reverse off}{wht} {reverse on}  {reverse off}"
113 print"3 159 cyn  ";chr$(159);"{reverse on}  {reverse off}{wht} {cyn}{reverse on}  {reverse off}{wht} {reverse on}  {reverse off}"
114 print"4 156 pur  ";chr$(156);"{reverse on}  {reverse off}{wht} {pur}{reverse on}  {reverse off}{wht} {reverse on}  {reverse off}"
115 print"5  30 grn  ";chr$(30);"{reverse on}  {reverse off}{wht} {grn}{reverse on}  {reverse off}{wht} {reverse on}  {reverse off}"
116 print"6  31 blu  ";chr$(31);"{reverse on}  {reverse off}{wht} {blu}{reverse on}  {reverse off}{wht} {reverse on}  {reverse off}"
117 print"7 158 yel  ";chr$(158);"{reverse on}  {reverse off}{wht} {yel}{reverse on}  {reverse off}{wht} {reverse on}  {reverse off}"

200 rem c64-only color codes: a white block means the vic-20 ignores the code
201 print:print"- pet tok  ch tk c64"
210 print"- 129 orng ";chr$(129);"{reverse on}  {reverse off}{wht} {orng}{reverse on}  {reverse off}{wht}"
211 print"- 149 brn  ";chr$(149);"{reverse on}  {reverse off}{wht} {brn}{reverse on}  {reverse off}{wht}"
212 print"- 150 lred ";chr$(150);"{reverse on}  {reverse off}{wht} {lred}{reverse on}  {reverse off}{wht}"
213 print"- 151 gry1 ";chr$(151);"{reverse on}  {reverse off}{wht} {gry1}{reverse on}  {reverse off}{wht}"
214 print"- 152 gry2 ";chr$(152);"{reverse on}  {reverse off}{wht} {gry2}{reverse on}  {reverse off}{wht}"
215 print"- 153 lgrn ";chr$(153);"{reverse on}  {reverse off}{wht} {lgrn}{reverse on}  {reverse off}{wht}"
216 print"- 154 lblu ";chr$(154);"{reverse on}  {reverse off}{wht} {lblu}{reverse on}  {reverse off}{wht}"
217 print"- 155 gry3 ";chr$(155);"{reverse on}  {reverse off}{wht} {gry3}{reverse on}  {reverse off}{wht}"

230 print:print"black shows as a gap"
231 print"white block = no-op":print"rm=poke color ram 0-7";

300 rem recolor the rm swatches (columns 17-18 of rows 1-8) with color ram values 0-7
310 forr=1to8:t=38400+r*22+17:poket,r-1:poket+1,r-1:next

390 rem clear the keyboard buffer so autostart's leftover keys don't end the program
391 poke198,0
400 getk$:ifk$=""then400
410 poke36879,27:print"{clr}{blu}";:end
