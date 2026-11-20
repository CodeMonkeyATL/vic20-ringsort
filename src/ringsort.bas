1 i=0:z=36874:dimpo%(10,7),mb%(2),tw%(2):pokez+5,12:pokez+4,15:rem init
2 forpp=1to10:po%(pp,7)=19+4*pp-178*(pp>5):next:gosub210

110 getk$:ifk$=""thengosub6100:goto110:rem main loop
120 ifk$="r"thengosub3000
130 ifk$="q"then990
150 n=val(k$)-10*(k$="0")-hp*(k$=" "):ifnthengosub300
160 ifk$<>"n"then110
170 gosub1100:print"new game? c/h/e";:wait198,255:getk$:j=-(k$="h")-2*(k$="e"):rem new game prompt
175 ifj-(k$="c")thenmd=j:gosub250:gosub210
180 gosub1200:goto110

210 ifdn=0thent=rnd(-ti):t=rnd(1):dn=int(rnd(1)*99999)+1:rem start a game
220 mv=0:wn=0:te=0:t=rnd(-dn):t=rnd(1):t=rnd(1):gosub2500:tb=ti:return

250 gosub1200:print"#";:dn=0:j=0:rem read deal number
260 wait198,255:getk$:a=asc(k$):ifa=13thenreturn
270 ifa=20andj>0thenj=j-1:dn=int(dn/10):printk$;
280 ifa>47anda<58andj<5thenj=j+1:dn=dn*10+a-48:printk$;
290 goto260

300 gosub1200:pp=n:gosub4000:ifhpthen400:rem post key: lift or drop
330 gosub4100:ift=7orlthen390
350 po%(pp,0)=po%(pp,t):po%(pp,t)=0:hp=pp:gosub1300:print"from";n;
360 v=z+1:f=200:e=240:s=4:gosub5010:goto2000
390 gosub1100:print"invalid move";:v=z:f=150:e=130:s=-1:goto5010:rem invalid move
395 pa=430:gosub1000:print"{red}to";n;"{wht}";:goto390:rem invalid drop

400 ift<2-(md=2)then395:rem drop
410 ifmd>0andhp<>nandt<7andpo%(pp,t)<>po%(hp,0)then395
420 po%(pp,t-1)=po%(hp,0):po%(hp,0)=0:ifhp=nthen480
425 mv=mv+1:w=mv:a=7689:d=3:gosub6000:pa=430:gosub1000:print"to";n;
430 v=z+1:f=240:e=190:s=-2:gosub5010:gosub2000:gosub4100:iflthengosub5200
445 pp=hp:hp=0:gosub2000:pp=n:gosub4100:ifl=0thenreturn
460 forpp=1to10:gosub4100:ifl=0andpo%(pp,6)>0thenreturn
470 next:gosub6110:wn=-1:gosub1300:gosub1100:print"solved!";:rem win
475 ifmb%(md)=0ormv<mb%(md)thenmb%(md)=mv
476 iftw%(md)=0orte<tw%(md)thentw%(md)=te
478 gosub3200:goto5100
480 gosub1300:print"move canceled";:pokez+3,250:gosub5000:rem cancel
485 pokez+3,0:hp=0:goto2000

990 pokez+4,0:pokez+5,27:print"{clr}{blu}";:end:rem quit

1000 poke781,pa/22:poke782,pa-22*int(pa/22):poke783,0:sys65520:return:rem cursor to pa

1100 pa=441:goto1000:rem cursor to message row

1200 gosub1100:goto1310:rem clear message row

1300 pa=419:gosub1000:rem clear move row
1310 print"                  ";:goto1000:rem 18 spaces, cursor back

2000 pa=po%(pp,7):gosub1000:fori=0to6:rem draw post pp
2040 ifpo%(pp,i)thenprint"{reverse on}"chr$(po%(pp,i))" "chr$(32-134*(i>0))" {reverse off}";:goto2070
2050 ifi=0or(i=1andmd=2)thenprint"   ";:goto2070
2060 print" {reverse on}{wht}{CBM-+}{reverse off} ";
2070 print"{down}{left}{left}{left}";:next:gosub4110:iflthenprint"{reverse on}"chr$(po%(pp,2))"   {reverse off}{wht}":return
2080 print"{reverse on}{wht}{CBM-+}{CBM-+}{CBM-+}{reverse off}":return

2400 a=int((j+4)/5):j=j-5*a+6:a=a+int(a/5)*sgn(md):return:rem ring j to post a, slot j

2500 print"{clr}{wht}dealing...":pa=139:gosub1000:print"{red}r{grn}i{pur}n{yel}g{cyn}s{red}o{grn}r{pur}t":rem deal, with the title
2505 pa=180:gosub1000:print"{wht}codemonkeyatl":hp=0:d=50+10*(md>0)
2507 forpp=1to10:fori=0to6:po%(pp,i)=0:next:next
2510 forn=1tod:j=n:gosub2400:po%(a,j)=asc(mid$("{red}{grn}{blu}{yel}{cyn}{red}{grn}{yel}{cyn}",(n+9)/10+5*sgn(md))):next
2520 poke7690,160:pokez+4,6:forn=dto1step-1:j=n:gosub2400:pp=a:i=j
2530 j=int(rnd(1)*n)+1:poke38410,(jand7)or1:pokez+1,200+j:gosub2400
2540 t=po%(pp,i):po%(pp,i)=po%(a,j):po%(a,j)=t:next:pokez+1,0:pokez+4,15

3000 print"{clr}":forpp=1to10:gosub2000:next:poke198,0:rem draw all
3100 pa=1:gosub1000:print"{wht}moves 000 time 00:00";:w=mv:j=te:a=7689:gosub3300:rem status and deal rows
3110 pa=485:gosub1000:print"#";dn;
3120 ifmdthenprint"{red}("mid$("hardexpert",4*md-3,2*md+2)"){wht}";
3200 ifmb%(md)=0thenreturn:rem best row
3210 pa=463:gosub1000:print"{cyn}best  000      00:00{wht}";:w=mb%(md):j=tw%(md):a=8151
3300 d=3:gosub6000:w=j:a=a+14:goto6200:rem moves and time digits

4000 fort=1to7:ifpo%(pp,t)=0thennext:rem top ring t
4010 return

4100 l=0:ifpo%(pp,1)thenreturn:rem locked?
4110 l=0:ifpo%(pp,2)=0thenreturn:rem complete?
4120 fori=3to6:ifpo%(pp,i)<>po%(pp,2)thenreturn
4130 next:l=-1:return

5000 v=z+4:f=15:e=0:s=-1:rem volume fade
5010 fori=ftoesteps:pokev,i:next:pokev,0:pokez+4,15:return:rem sound sweep

5100 v=z+2:fori=1to4:pokev,195+i*12:forj=1to99:next:next:pokev,0:return:rem win chime

5200 pokez+2,230:gosub5000:rem lock sound
5210 pokez+2,240:forj=1to60:next:gosub5000:pokez+2,0:return

6000 fori=1tod:t=int(w/10):pokea,48+w-10*t:w=t:a=a-1:next:return:rem poke digits

6100 ifwnthenreturn:rem timer tick
6110 w=int((ti-tb)/60):ifw<0orw>5999thenw=5999:wn=1
6120 ifw=tethenreturn
6130 te=w:a=7700
6200 j=int(w/60):w=w-60*j:d=2:gosub6000:w=j:a=a-1:goto6000:rem show mm:ss
