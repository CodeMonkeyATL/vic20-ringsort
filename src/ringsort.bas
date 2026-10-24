1 rem hot draw variables first: basic searches them in creation order
2 pa=0:of=0:yy=0:xx=0:sb=7680:pp=0:pb=0:i=0:b$=chr$(230)
3 rem po% first: arrays are searched in creation order too
4 dimpo%(10,7),cl%(4)
5 r=rnd(-ti):poke36879,12:gosub10000
6 gosub20000:gosub3000

100 rem main loop: wait for a key and dispatch
110 getk$:ifk$=""then110
120 ifk$="n"thengosub200:goto110
130 ifk$="r"thengosub3000:goto110
140 ifk$="q"then990
150 rem 1-0 (posts 1-10) not handled yet
160 goto110

200 rem new game: ask first, so a stray n doesn't lose the game
210 pa=sb+19*22:gosub1000:print"new game? y/n";
220 getk$:ifk$=""then220
230 ifk$="y"thengosub20000:gosub3000:return
240 gosub1000:print"             ";:return

990 poke36879,27:print"{clr}{blu}";:end

1000 rem convert pa to row/column and park cursor
1010 of = pa - sb
1020 yy = int(of/22)
1030 xx = of - yy*22
1040 poke781,yy:poke782,xx:poke783,0
1050 sys65520
1060 return

rem po%(pp,0)=hover/top address for the whole post
rem po%(pp,1..5)=initial rings (1 just below cap, 5 above extra slot)
rem po%(pp,6)=extra stack row just above the base (0=empty)
rem po%(pp,7)=hover ring at po%(pp,0) (0=none; at most one post)

2000 rem base sits under slot 6 if filled, else under slot 5
2010 pa=pb+22*7
2020 if po%(pp,6)<>0 then pa=pb+22*8
2030 gosub1000
2040 print "{reverse on}{wht}";b$;b$;b$;"{reverse off}"
2050 return

2100 rem rings 6 (lowest extra) to 1 (just below cap)
2110 for i=6 to 1 step -1
2120 if i=6 and po%(pp,6)=0 then goto 2160
2130 pa=pb+22*(i+1):gosub1000
2140 if po%(pp,i)<>0 then print "{reverse on}";chr$(po%(pp,i));" ";b$;" {reverse off}"
2150 if po%(pp,i)=0 then print " {reverse on}{wht}";b$;"{reverse off} "
2160 next i
2170 return

2200 rem cap (one row, never a ring)
2210 pa=pb+22:gosub1000
2220 print " {reverse on}{wht}";b$;"{reverse off}"
2230 return

2300 rem hover at post origin; blank if empty
2310 pa=pb:gosub1000
2320 if po%(pp,7)<>0 then print "{reverse on}";chr$(po%(pp,7));" ";b$;" {reverse off}"
2330 if po%(pp,7)=0 then print "   "
2340 return

3000 rem clear screen, draw every post base up to hover, park cursor
3010 print"{clr}";
3020 forpp=1to10
3030 pb=po%(pp,0)
3040 gosub2000:gosub2100:gosub2200:gosub2300
3050 next
3060 pa=sb+19*22:gosub1000
3070 return

10000 rem one-time setup: color codes, post addresses
10010 cl%(0)=28:cl%(1)=30:cl%(2)=31:cl%(3)=158:cl%(4)=159
10030 rem post origin: x=1+col*4, y=1+row*9 (2 rows of 5)
10040 forpp=1to10
10050 r=int((pp-1)/5):c=pp-1-5*r
10060 po%(pp,0)=sb+(1+r*9)*22+1+c*4
10070 next
10080 return

20000 rem new game: 10 rings per color, shuffled, 5 per post
20010 print"{clr}dealing..."
20020 rem in order first: posts 1-2 get color 0, 3-4 color 1, ...
20030 rem slot 6 and hover start empty
20040 forpp=1to10:fori=1to5
20050 po%(pp,i)=cl%(int((pp-1)/2))
20060 next
20070 po%(pp,6)=0:po%(pp,7)=0
20080 next
20090 rem fisher-yates: ring k=pp*5+i-5 runs 50 down to 1,
20100 rem and swaps with random ring j (1..k) at post a, slot j
20110 forpp=10to1step-1:fori=5to1step-1
20120 j=int(rnd(1)*(pp*5+i-5))+1
20130 a=int((j-1)/5)+1:j=j-5*a+5
20140 t=po%(pp,i):po%(pp,i)=po%(a,j):po%(a,j)=t
20150 next:next
20160 return
