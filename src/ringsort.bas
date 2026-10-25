1 pa=0:pp=0:i=0:dimpo%(10,7):poke36879,12:poke36878,15
2 forpp=1to10:po%(pp,7)=19+4*pp-178*(pp>5):next:gosub7000:gosub210

110 getk$:ifk$=""thengosub6100:goto110
120 ifk$="r"thengosub3000
130 ifk$="q"then990
140 ifk$=" "thenifhpthenn=hp:gosub300
150 ifk$>="0"andk$<="9"thenn=val(k$)-10*(k$="0"):gosub300
160 ifk$<>"n"then110
170 gosub1100:print"new game? y/n";:wait198,255:getk$:ifk$="y"thengosub250:gosub210
180 gosub1200:goto110

210 ifdn=0thent=rnd(-ti):t=rnd(1):dn=int(rnd(1)*99999)+1
220 t=rnd(-dn):t=rnd(1):t=rnd(1):gosub2500:tb=ti:return

250 gosub1200:gosub1100:print"deal #";:dn=0:j=0
260 wait198,255:getk$:a=asc(k$):ifa=13thenreturn
270 ifa=20andj>0thenj=j-1:dn=int(dn/10):printk$;
280 ifa>47anda<58andj<5thenj=j+1:dn=dn*10+a-48:printk$;
290 goto260

300 gosub1200:ifhpthen400
330 pp=n:gosub4000:gosub4100:ift=7orlthen390
350 po%(pp,0)=po%(pp,t):po%(pp,t)=0:hp=pp:gosub1300:print"move";n;
360 v=36875:f=200:e=240:s=4:gosub5000:goto2000
390 gosub1100:print"invalid move";:v=36874:f=150:e=130:s=-1:goto5000
395 pa=430:gosub1000:print"{red}to";n;"{wht}";:goto390

400 pp=n:gosub4000:ift=1then395
420 po%(pp,t-1)=po%(hp,0):po%(hp,0)=0:ifhp=nthen480
425 mv=mv+1:w=mv:a=7689:d=3:gosub6000:pa=430:gosub1000:print"to";n;
430 v=36875:f=240:e=190:s=-2:gosub5000:gosub2000:gosub4100:iflthengosub5200
445 pp=hp:hp=0:gosub2000:pp=n:gosub4100:ifl=0thenreturn
460 forpp=1to10:gosub4100:ifl=0thenreturn
470 next:gosub6110:wn=-1:gosub1300:gosub1100:print"solved!";
475 ifmb=0ormv<mbthenmb=mv
476 iftw=0orte<twthentw=te
478 gosub3200:goto5100
480 gosub1300:print"move canceled";:poke36877,250:v=36878:f=15:e=0:s=-1:gosub5000
485 poke36877,0:poke36878,15:hp=0:goto2000

990 poke36878,0:poke36879,27:print"{clr}{blu}";:end

1000 poke781,pa/22:poke782,pa-22*int(pa/22):poke783,0:sys65520:return

1100 pa=441:goto1000

1200 gosub1100:print"             ";:return

1300 pa=419:gosub1000:print"                  ";:goto1000

2000 pa=po%(pp,7):gosub1000:fori=0to6
2040 ifpo%(pp,i)thenprint"{reverse on}";chr$(po%(pp,i));" {CBM-+} {reverse off}{down}{left}{left}{left}";:goto2070
2050 ifi=0thenprint"   {down}{left}{left}{left}";:goto2070
2060 print" {reverse on}{wht}{CBM-+}{reverse off} {down}{left}{left}{left}";
2070 next:gosub4110:iflthenprint"{reverse on}";chr$(po%(pp,2));"   {reverse off}{wht}":return
2080 print"{reverse on}{wht}{CBM-+}{CBM-+}{CBM-+}{reverse off}":return

2500 print"{clr}{wht}dealing...":hp=0:forpp=1to10:po%(pp,0)=0:po%(pp,1)=0
2510 fori=2to6:po%(pp,i)=asc(mid$("{red}{grn}{blu}{yel}{cyn}",pp/2+.5)):next:next
2520 poke7690,160:poke36878,6:forpp=10to1step-1:fori=6to2step-1
2530 j=int(rnd(1)*(pp*5+i-6))+1:poke38410,(jand7)or1:poke36875,200+j
2540 a=int((j-1)/5)+1:j=j-5*a+6:t=po%(pp,i):po%(pp,i)=po%(a,j):po%(a,j)=t:next:next
2550 poke36875,0:poke36878,15:mv=0:wn=0:te=0

3000 print"{clr}";:forpp=1to10:gosub2000:next:poke198,0
3100 pa=1:gosub1000:print"{wht}moves 000 time 00:00";:w=mv:a=7689:d=3:gosub6000
3110 w=te:a=7700:gosub6200:pa=485:gosub1000:print"deal";dn;
3200 ifmb=0thenreturn
3210 pa=463:gosub1000:print"{cyn}best  000      00:00{wht}";:w=mb:a=8151:d=3:gosub6000
3220 w=tw:a=8162:goto6200

4000 fort=1to7:ifpo%(pp,t)=0thennext
4010 return

4100 l=0:ifpo%(pp,1)thenreturn
4110 l=0:ifpo%(pp,2)=0thenreturn
4120 fori=3to6:ifpo%(pp,i)<>po%(pp,2)thenreturn
4130 next:l=-1:return

5000 fori=ftoesteps:pokev,i:next:pokev,0:return

5100 v=36876:fori=1to4:pokev,195+i*12:forj=1to99:next:next:pokev,0:return

5200 poke36876,230:v=36878:f=15:e=0:s=-1:gosub5000
5210 poke36876,240:poke36878,15:forj=1to60:next:f=15:gosub5000
5220 poke36876,0:poke36878,15:return

6000 fori=1tod:t=int(w/10):pokea,48+w-10*t:w=t:a=a-1:next:return

6100 ifwnthenreturn
6110 w=int((ti-tb)/60):ifw<0orw>5999thenw=5999:wn=1
6120 ifw=tethenreturn
6130 te=w:a=7700
6200 j=int(w/60):w=w-60*j:d=2:gosub6000:w=j:a=a-1:goto6000

7000 print"{clr}";:pa=139:gosub1000:print"{red}r{grn}i{pur}n{yel}g{cyn}s{red}o{grn}r{pur}t"
7010 pa=180:gosub1000:print"{wht}codemonkeyatl":pa=445:gosub1000:print"press a key"
7020 poke198,0:wait198,255:return
