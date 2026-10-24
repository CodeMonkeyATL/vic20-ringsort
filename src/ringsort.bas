1 b$=chr$(230):r=rnd(-ti):poke36879,12:sb=7680
2 print"{clr}{home}";
3 gosub 10000

200 rem draw posts from base up to hover
210 for r=1 to 2: for c=1 to 5
220 pp=(r-1)*5+c
221 pb=po(pp,0)
222 gosub2000:gosub2100:gosub2200:gosub2300
230 next c: next r
400 pa=sb+19*22:gosub1000

999 end

1000 rem convert pa to row/column and park cursor
1010 of = pa - sb
1020 yy = int(of/22)
1030 xx = of - yy*22
1040 poke781,yy:poke782,xx:poke783,0
1050 sys65520
1060 return

rem po(pp,0)=hover/top address for the whole post
rem po(pp,1..5)=initial rings (1 just below cap, 5 above extra slot)
rem po(pp,6)=extra stack row just above the base (0=empty)
rem po(pp,7)=hover ring at po(pp,0) (0=none; at most one post)

2000 rem base sits under slot 6 if filled, else under slot 5
2010 pa=pb+22*7
2020 if po(pp,6)<>0 then pa=pb+22*8
2030 gosub1000
2040 print "{reverse on}{wht}";b$;b$;b$;"{reverse off}"
2050 return

2100 rem rings 6 (lowest extra) to 1 (just below cap)
2110 for i=6 to 1 step -1
2120 if i=6 and po(pp,6)=0 then goto 2160
2130 pa=pb+22*(i+1):gosub1000
2140 if po(pp,i)<>0 then print "{reverse on}";chr$(po(pp,i));" ";b$;" {reverse off}"
2150 if po(pp,i)=0 then print " {reverse on}{wht}";b$;"{reverse off} "
2160 next i
2170 return

2200 rem cap (one row, never a ring)
2210 pa=pb+22:gosub1000
2220 print " {reverse on}{wht}";b$;"{reverse off}"
2230 return

2300 rem hover at post origin; blank if empty
2310 pa=pb:gosub1000
2320 if po(pp,7)<>0 then print "{reverse on}";chr$(po(pp,7));" ";b$;" {reverse off}"
2330 if po(pp,7)=0 then print "   "
2340 return

10000 rem initialize color lookup and post colors
10001 dim cl(5):cl(1)=28:cl(2)=30:cl(3)=31:cl(4)=158:cl(5)=159
10010 dim po(10,7):gosub20000
10060 return

20000 rem populate posts: rings 1-5, slot 6 and hover empty
20005 dim cc(50):fori=1to50:cc(i)=int((i-1)/10)+1:next
20010 forpi=50to2step-1
20011 pj=int(rnd(1)*pi)+1
20012 pt=cc(pi)
20013 cc(pi)=cc(pj)
20014 cc(pj)=pt
20015 nextpi

20020 pk=1
20030 forpp=1to10

rem hover address: one row above the cap
20035 r=int((pp-1)/5)
20036 c=(pp-1)-5*r
20037 x=1+c*4
20038 y=1+r*9
20039 po(pp,0)=sb+y*22+x

20040 forpr=1to5
20060 po(pp,pr)=cl(cc(pk))
20070 pk=pk+1
20080 nextpr

20090 nextpp
20100 return
