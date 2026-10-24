1 b$=chr$(230):r=rnd(-ti):rem:poke36879,12
2 print"{clr}{home}";

10000 rem initialize color lookup and post colors
10000 rem only one post for now, later will be 10 posts
10001 dim cl(4):cl(0)=28:cl(1)=30:cl(2)=31:cl(3)=158:cl(4)=159
10010 dim po(10,6)

20000 rem populate posts
20005 dim cc(50):fori=1to50:cc(i)=int((i-1)/10)+1:next
20010 forpi=50to2step-1
20011 pj=int(rnd(1)*pi)+1
20012 pt=cc(pi)
20013 cc(pi)=cc(pj)
20014 cc(pj)=pt
20015 nextpi
20020 pk=1
20030 forpp=1to10
20040 forpr=1to5
20050 print pp;pr;pk
20055 a=po(pp,pr):print "po(pp,pr):";a
20056 a=cc(pk):print "cc(pk):";a
20057 a=cl(a-1):print "cl(a):";a
20060 po(pp,pr)=cl(cc(pk)-1)
20070 pk=pk+1
20080 nextpr
20090 nextpp
20100 return