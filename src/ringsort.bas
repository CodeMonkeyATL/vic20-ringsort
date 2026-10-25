1 pa=0:of=0:yy=0:xx=0:sb=7680:pp=0:pb=0:i=0:b$=chr$(230):dimpo%(10,7),cl%(4)
2 poke36879,12:poke36878,15:gosub10000:gosub7000:gosub20000:gosub3000:tb=ti

110 getk$:ifk$=""thengosub6100:goto110
120 ifk$="n"thengosub200:goto110
130 ifk$="r"thengosub3000:goto110
140 ifk$="q"then990
160 ifk$=" "thenifhpthenn=hp:gosub300:goto110
170 ifk$>="0"andk$<="9"thenn=val(k$)-10*(k$="0"):gosub300:goto110
180 goto110

200 gosub1100:print"new game? y/n";
220 getk$:ifk$=""then220
230 ifk$="y"thenr=rnd(-ti):gosub20000:gosub3000:tb=ti:return
240 gosub1200:return

300 gosub1200:ifhpthen400
330 pp=n:gosub4000:ift=7then390
340 gosub4100:iflthen390
350 po%(pp,0)=po%(pp,t):po%(pp,t)=0:hp=pp:gosub1300:print"move";n;
360 v=36875:f=200:e=240:s=4:gosub5000:gosub2000:return
390 gosub1100:print"invalid move";:v=36874:f=150:e=130:s=-1:gosub5000:return
395 pa=sb+19*22+12:gosub1000:print"{red}to";n;"{wht}";:goto390

400 pp=n:gosub4000:ift=1then395
420 po%(pp,t-1)=po%(hp,0):po%(hp,0)=0:ifhp=nthen480
425 mv=mv+1:w=mv:a=7689:d=3:gosub6000
430 pa=sb+19*22+12:gosub1000:print"to";n;:v=36875:f=240:e=190:s=-2:gosub5000
440 gosub2000:gosub4100:iflthengosub5200
445 pp=hp:hp=0:gosub2000
450 pp=n:gosub4100:ifl=0thenreturn
460 forpp=1to10:gosub4100:ifl=0thenreturn
470 next:gosub6110:wn=-1
472 gosub1300:gosub1100:print"solved!";
475 ifmb=0ormv<mbthenmb=mv
476 iftw=0orte<twthentw=te
478 gosub6400:gosub5100:return
480 gosub1300:print"move canceled";:poke36877,250:v=36878:f=15:e=0:s=-1:gosub5000
485 poke36877,0:poke36878,15:gosub2000:hp=0:return

990 poke36878,0:poke36879,27:print"{clr}{blu}";:end

1000 of=pa-sb:yy=int(of/22):xx=of-yy*22:poke781,yy:poke782,xx:poke783,0:sys65520:return

1100 pa=sb+20*22+1:gosub1000:return

1200 gosub1100:print"             ";:return

1300 pa=sb+19*22+1:gosub1000:print"                  ";:gosub1000:return

2000 pb=po%(pp,7):fori=0to6:pa=pb+22*i:gosub1000
2040 ifpo%(pp,i)thenprint"{reverse on}";chr$(po%(pp,i));" ";b$;" {reverse off}":goto2070
2050 ifi=0thenprint"   ":goto2070
2060 print" {reverse on}{wht}";b$;"{reverse off} "
2070 next:pa=pb+22*7:gosub1000:gosub4110:iflthenprint"{reverse on}";chr$(po%(pp,2));"   {reverse off}{wht}":return
2080 print"{reverse on}{wht}";b$;b$;b$;"{reverse off}":return

3000 print"{clr}";:forpp=1to10:gosub2000:next:gosub6300:gosub1100:poke198,0:return

4000 t=0
4030 t=t+1:ifpo%(pp,t)=0then4030
4040 return

4100 l=0:ifpo%(pp,1)thenreturn
4110 l=0:ifpo%(pp,2)=0thenreturn
4120 fori=3to6:ifpo%(pp,i)<>po%(pp,2)thenreturn
4130 next:l=-1:return

5000 fori=ftoesteps:pokev,i:next:pokev,0:return

5100 v=36876:fori=1to4:pokev,195+i*12:forj=1to99:next:next:pokev,0:return

5200 poke36876,230:v=36878:f=15:e=0:s=-1:gosub5000
5210 poke36876,240:poke36878,15:forj=1to60:next:f=15:gosub5000
5220 poke36876,0:poke36878,15:return

6000 fori=1tod:q=int(w/10):pokea,48+w-10*q:w=q:a=a-1:next:return

6100 ifwnthenreturn
6110 w=int((ti-tb)/60):ifw<0orw>5999thenw=5999:wn=1
6120 ifw=tethenreturn
6130 te=w:a=7700
6200 m=int(w/60):w=w-60*m:d=2:gosub6000:w=m:a=a-1:goto6000

6300 pa=7681:gosub1000:print"{wht}moves 000 time 00:00";:w=mv:a=7689:d=3:gosub6000
6310 w=te:a=7700:gosub6200
6400 ifmb=0thenreturn
6410 pa=8143:gosub1000:print"{cyn}best  000      00:00{wht}";:w=mb:a=8151:d=3:gosub6000
6420 w=tw:a=8162:goto6200

7000 print"{clr}";:pa=sb+139:gosub1000
7010 print"{red}r{grn}i{pur}n{yel}g{cyn}s{red}o{grn}r{pur}t"
7020 pa=sb+180:gosub1000:print"{wht}codemonkeyatl":pa=sb+445:gosub1000:print"press a key"
7030 poke198,0
7040 getk$:ifk$=""then7040
7050 r=rnd(-ti):return

10000 cl%(0)=28:cl%(1)=30:cl%(2)=31:cl%(3)=158:cl%(4)=159:forpp=1to10
10050 r=int((pp-1)/5):c=pp-1-5*r:po%(pp,7)=sb+(1+r*9)*22+1+c*4:next:return

20000 print"{clr}{wht}dealing...":hp=0:forpp=1to10:fori=2to6:po%(pp,i)=cl%(int((pp-1)/2)):next
20070 po%(pp,0)=0:po%(pp,1)=0:next:poke7690,160:poke36878,6
20080 forpp=10to1step-1:fori=6to2step-1
20120 j=int(rnd(1)*(pp*5+i-6))+1:poke38410,(jand7)or1:poke36875,200+j
20130 a=int((j-1)/5)+1:j=j-5*a+6:t=po%(pp,i):po%(pp,i)=po%(a,j):po%(a,j)=t:next:next
20150 poke36875,0:poke36878,15:mv=0:wn=0:te=0:return
