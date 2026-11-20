100 i=0:z=36874:dimpo%(10,7),mb%(2),tw%(2):pokez+5,12:pokez+4,15:rem init
110 forpp=1to10:po%(pp,7)=19+4*pp-178*(pp>5):next:gosub300

200 getk$:ifk$=""thengosub6100:goto200:rem main loop
210 ifk$="r"thengosub3000
220 ifk$="q"then900
230 n=val(k$)-10*(k$="0")-hp*(k$=" "):ifnthengosub500
240 ifk$<>"n"then200
250 gosub1100:print"new game? c/h/e";:wait198,255:getk$:j=-(k$="h")-2*(k$="e"):rem new game prompt
260 ifj-(k$="c")thenmd=j:gosub400:gosub300
270 gosub1200:goto200

300 ifdn=0thent=rnd(-ti):t=rnd(1):dn=int(rnd(1)*99999)+1:rem start a game
310 mv=0:wn=0:te=0:t=rnd(-dn):t=rnd(1):t=rnd(1):gosub2500:tb=ti:return

400 gosub1200:print"#";:dn=0:j=0:rem read deal number
410 wait198,255:getk$:a=asc(k$):ifa=13thenreturn
420 ifa=20andj>0thenj=j-1:dn=int(dn/10):printk$;
430 ifa>47anda<58andj<5thenj=j+1:dn=dn*10+a-48:printk$;
440 goto410

500 gosub1200:pp=n:gosub4000:ifhpthen600:rem post key: lift or drop
510 gosub4100:ift=7orlthen540
520 po%(pp,0)=po%(pp,t):po%(pp,t)=0:hp=pp:gosub1300:print"from";n;
530 v=z+1:f=200:e=240:s=4:gosub5010:goto2000
540 gosub1100:print"invalid move";:v=z:f=150:e=130:s=-1:goto5010:rem invalid move
550 pa=430:gosub1000:print"{red}to";n;"{wht}";:goto540:rem invalid drop

600 ift<2-(md=2)then550:rem drop
610 ifmd>0andhp<>nandt<7andpo%(pp,t)<>po%(hp,0)then550
620 po%(pp,t-1)=po%(hp,0):po%(hp,0)=0:ifhp=nthen800
630 mv=mv+1:w=mv:a=7689:d=3:gosub6000:pa=430:gosub1000:print"to";n;
640 v=z+1:f=240:e=190:s=-2:gosub5010:gosub2000:gosub4100:iflthengosub5200
650 pp=hp:hp=0:gosub2000:pp=n:gosub4100:ifl=0thenreturn
660 forpp=1to10:gosub4100:ifl=0andpo%(pp,6)>0thenreturn

700 next:gosub6110:wn=-1:gosub1300:gosub1100:print"solved!";:rem win
710 ifmb%(md)=0ormv<mb%(md)thenmb%(md)=mv
720 iftw%(md)=0orte<tw%(md)thentw%(md)=te
730 gosub3200:poke900,4:poke901,251:poke902,md+1:poke903,2:rem result for the launcher
740 poke904,255andmv:poke905,mv/256:poke907,255andte:poke908,te/256:goto5100

800 gosub1300:print"move canceled";:pokez+3,250:gosub5000:rem cancel
810 pokez+3,0:hp=0:goto2000

900 pokez+4,0:pokez+5,27:print"{clr}{blu}";:ifpeek(841)=0thenend:rem quit, or load the launcher
910 print"{down}{down}load"chr$(34);:fori=1topeek(842):printchr$(peek(842+i));:next
920 printchr$(34)","peek(841)"{home}";:poke631,13:poke632,82:poke633,85
930 poke634,78:poke635,13:poke198,5:end

1000 poke781,pa/22:poke782,pa-22*int(pa/22):poke783,0:sys65520:return:rem cursor to pa

1100 pa=441:goto1000:rem cursor to message row

1200 gosub1100:goto1310:rem clear message row

1300 pa=419:gosub1000:rem clear move row
1310 print"                  ";:goto1000:rem 18 spaces, cursor back

2000 pa=po%(pp,7):gosub1000:fori=0to6:rem draw post pp
2010 ifpo%(pp,i)thenprint"{reverse on}"chr$(po%(pp,i))" "chr$(32-134*(i>0))" {reverse off}";:goto2040
2020 ifi=0or(i=1andmd=2)thenprint"   ";:goto2040
2030 print" {reverse on}{wht}{CBM-+}{reverse off} ";
2040 print"{down}{left}{left}{left}";:next:gosub4110:iflthenprint"{reverse on}"chr$(po%(pp,2))"   {reverse off}{wht}":return
2050 print"{reverse on}{wht}{CBM-+}{CBM-+}{CBM-+}{reverse off}":return

2400 a=int((j+4)/5):j=j-5*a+6:a=a+int(a/5)*sgn(md):return:rem ring j to post a, slot j

2500 print"{clr}{wht}dealing...":pa=139:gosub1000:print"{red}r{grn}i{pur}n{yel}g{cyn}s{red}o{grn}r{pur}t":rem deal, with the title
2510 pa=180:gosub1000:print"{wht}codemonkeyatl":hp=0:d=50+10*(md>0)
2520 forpp=1to10:fori=0to6:po%(pp,i)=0:next:next
2530 forn=1tod:j=n:gosub2400:po%(a,j)=asc(mid$("{red}{grn}{blu}{yel}{cyn}{red}{grn}{yel}{cyn}",(n+9)/10+5*sgn(md))):next
2540 poke7690,160:pokez+4,6:forn=dto1step-1:j=n:gosub2400:pp=a:i=j
2550 j=int(rnd(1)*n)+1:poke38410,(jand7)or1:pokez+1,200+j:gosub2400
2560 t=po%(pp,i):po%(pp,i)=po%(a,j):po%(a,j)=t:next:pokez+1,0:pokez+4,15

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
