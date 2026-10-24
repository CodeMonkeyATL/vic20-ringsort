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
150 rem space puts a lifted ring back; keys 1-9 and 0 are posts 1-10
160 ifk$=" "thenifhpthenn=hp:gosub300:goto110
170 ifk$>="0"andk$<="9"thenn=val(k$)-10*(k$="0"):gosub300:goto110
180 goto110

200 rem new game: ask first, so a stray n doesn't lose the game
210 gosub1100:print"new game? y/n";
220 getk$:ifk$=""then220
230 ifk$="y"thengosub20000:gosub3000:return
240 gosub1200:return

300 rem post key n: drop the lifted ring onto post n, or lift n's top ring
310 gosub1200
320 ifhpthen400
330 pp=n:gosub4000:ift=7then390
340 gosub4100:iflthen390
350 po%(pp,0)=po%(pp,t):po%(pp,t)=0:hp=pp
360 gosub2000:return
390 gosub1100:print"invalid move";:return

400 rem drop: the ring lifted from post hp goes just above n's top ring
410 pp=n:gosub4000:ift=1then390
420 po%(pp,t-1)=po%(hp,0):po%(hp,0)=0
430 gosub2000:pp=hp:hp=0:ifpp<>nthengosub2000
440 rem only a drop that locks post n can win the game
450 pp=n:gosub4100:ifl=0thenreturn
460 forpp=1to10:gosub4100:ifl=0thenreturn
470 next
480 gosub1100:print"solved!";:return

990 poke36879,27:print"{clr}{blu}";:end

1000 rem convert pa to row/column and park cursor
1010 of = pa - sb
1020 yy = int(of/22)
1030 xx = of - yy*22
1040 poke781,yy:poke782,xx:poke783,0
1050 sys65520
1060 return

1100 rem park cursor at the start of the message row (19)
1110 pa=sb+19*22:gosub1000:return

1200 rem clear the message row
1210 gosub1100:print"             ";:return

rem po%(pp,k): index k is the screen row below the post origin
rem 0=hover ring (0=none; at most one post), 1=cap slot (6th ring)
rem 2-6=rings stacked on the base, 7=post origin address
rem the base is always drawn on row 7

2000 rem draw post pp: rows 0-6 from po%(pp,k), then the base
2010 pb=po%(pp,7)
2020 fori=0to6
2030 pa=pb+22*i:gosub1000
2040 ifpo%(pp,i)thenprint"{reverse on}";chr$(po%(pp,i));" ";b$;" {reverse off}":goto2070
2050 ifi=0thenprint"   ":goto2070
2060 print" {reverse on}{wht}";b$;"{reverse off} "
2070 next
2080 pa=pb+22*7:gosub1000
2090 print"{reverse on}{wht}";b$;b$;b$;"{reverse off}"
2100 return

3000 rem clear screen, draw every post, park cursor
3010 print"{clr}";
3020 forpp=1to10:gosub2000:next
3030 gosub1100
3040 return

4000 rem top ring of post pp: t=lowest non-zero index 1-6, or 7 if empty
4010 rem (slot 7 holds the post address, never 0, so the scan stops there)
4020 t=0
4030 t=t+1:ifpo%(pp,t)=0then4030
4040 return

4100 rem is post pp locked? l=-1 when slot 1 is empty and 2-6 are one color
4110 l=0:ifpo%(pp,1)<>0orpo%(pp,2)=0thenreturn
4120 fori=3to6:ifpo%(pp,i)<>po%(pp,2)thenreturn
4130 next:l=-1:return

10000 rem one-time setup: color codes, post addresses
10010 cl%(0)=28:cl%(1)=30:cl%(2)=31:cl%(3)=158:cl%(4)=159
10030 rem post origin: x=1+col*4, y=1+row*9 (2 rows of 5)
10040 forpp=1to10
10050 r=int((pp-1)/5):c=pp-1-5*r
10060 po%(pp,7)=sb+(1+r*9)*22+1+c*4
10070 next
10080 return

20000 rem new game: 10 rings per color, shuffled, 5 per post
20010 print"{clr}dealing...":hp=0
20020 rem in order first: posts 1-2 get color 0, 3-4 color 1, ...
20030 rem rings go in slots 2-6; hover (0) and cap (1) start empty
20040 forpp=1to10:fori=2to6
20050 po%(pp,i)=cl%(int((pp-1)/2))
20060 next
20070 po%(pp,0)=0:po%(pp,1)=0
20080 next
20090 rem fisher-yates: ring k=pp*5+i-6 runs 50 down to 1,
20100 rem and swaps with random ring j (1..k) at post a, slot j
20110 forpp=10to1step-1:fori=6to2step-1
20120 j=int(rnd(1)*(pp*5+i-6))+1
20130 a=int((j-1)/5)+1:j=j-5*a+6
20140 t=po%(pp,i):po%(pp,i)=po%(a,j):po%(a,j)=t
20150 next:next
20160 return
