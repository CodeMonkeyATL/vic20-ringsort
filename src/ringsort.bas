1 pa=0:of=0:yy=0:xx=0:sb=7680:pp=0:pb=0:i=0:b$=chr$(230):dimpo%(10,7),cl%(4)
2 r=rnd(-ti):poke36879,12:gosub10000:gosub20000:gosub3000

110 getk$:ifk$=""then110
120 ifk$="n"thengosub200:goto110
130 ifk$="r"thengosub3000:goto110
140 ifk$="q"then990
160 ifk$=" "thenifhpthenn=hp:gosub300:goto110
170 ifk$>="0"andk$<="9"thenn=val(k$)-10*(k$="0"):gosub300:goto110
180 goto110

200 gosub1100:print"new game? y/n";
220 getk$:ifk$=""then220
230 ifk$="y"thengosub20000:gosub3000:return
240 gosub1200:return

300 gosub1200:ifhpthen400
330 pp=n:gosub4000:ift=7then390
340 gosub4100:iflthen390
350 po%(pp,0)=po%(pp,t):po%(pp,t)=0:hp=pp:gosub2000:return
390 gosub1100:print"invalid move";:return

400 pp=n:gosub4000:ift=1then390
420 po%(pp,t-1)=po%(hp,0):po%(hp,0)=0:gosub2000:pp=hp:hp=0:ifpp<>nthengosub2000
450 pp=n:gosub4100:ifl=0thenreturn
460 forpp=1to10:gosub4100:ifl=0thenreturn
470 next:gosub1100:print"solved!";:return

990 poke36879,27:print"{clr}{blu}";:end

1000 of=pa-sb:yy=int(of/22):xx=of-yy*22:poke781,yy:poke782,xx:poke783,0:sys65520:return

1100 pa=sb+19*22:gosub1000:return

1200 gosub1100:print"             ";:return

2000 pb=po%(pp,7):fori=0to6:pa=pb+22*i:gosub1000
2040 ifpo%(pp,i)thenprint"{reverse on}";chr$(po%(pp,i));" ";b$;" {reverse off}":goto2070
2050 ifi=0thenprint"   ":goto2070
2060 print" {reverse on}{wht}";b$;"{reverse off} "
2070 next:pa=pb+22*7:gosub1000:print"{reverse on}{wht}";b$;b$;b$;"{reverse off}":return

3000 print"{clr}";:forpp=1to10:gosub2000:next:gosub1100:poke198,0:return

4000 t=0
4030 t=t+1:ifpo%(pp,t)=0then4030
4040 return

4100 l=0:ifpo%(pp,1)<>0orpo%(pp,2)=0thenreturn
4120 fori=3to6:ifpo%(pp,i)<>po%(pp,2)thenreturn
4130 next:l=-1:return

10000 cl%(0)=28:cl%(1)=30:cl%(2)=31:cl%(3)=158:cl%(4)=159:forpp=1to10
10050 r=int((pp-1)/5):c=pp-1-5*r:po%(pp,7)=sb+(1+r*9)*22+1+c*4:next:return

20000 print"{clr}dealing...":hp=0:forpp=1to10:fori=2to6:po%(pp,i)=cl%(int((pp-1)/2)):next
20070 po%(pp,0)=0:po%(pp,1)=0:next:forpp=10to1step-1:fori=6to2step-1
20120 j=int(rnd(1)*(pp*5+i-6))+1:a=int((j-1)/5)+1:j=j-5*a+6
20140 t=po%(pp,i):po%(pp,i)=po%(a,j):po%(a,j)=t:next:next:return
