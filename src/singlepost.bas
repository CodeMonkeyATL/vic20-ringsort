1 b$=chr$(230):r=rnd(-ti):poke36879,12
2 print"{clr}{home}";
3 gosub 10000

200 for r=1to2:forc=1to5
210 x=1+(c-1)*4:y=2+(r-1)*9:gosub2000
220 nextc:nextr
299 end

1000 a=7680+yy*22:d=a-256*int(a/256):e=int(a/256)
1020 poke 209,d:poke 210,e
1030 poke 211,xx:poke 214,yy
1040 return

2000 rem draw the post with rings
2001 xx=x:yy=y:gosub1000:print" {reverse on}{wht}";b$;"{reverse off}"
2010 fori=0to4:yy=y+1+i:gosub1000:print"{reverse on}";chr$(po(0,i));"   {reverse off} ":nexti
2020 yy=y+6:gosub1000:print "{reverse on}{wht}";b$;b$;b$;"{reverse off}"
2030 return

10000 rem initialize color lookup and post colors
10000 rem only one post for now, later will be 10 posts
10001 dim cl(4):cl(0)=28:cl(1)=30:cl(2)=31:cl(3)=158:cl(4)=159
10010 dim po(0,6):po(0,0)=cl(int(rnd(1)*5))
10020 po(0,1)=cl(int(rnd(1)*5))
10030 po(0,2)=cl(int(rnd(1)*5))
10040 po(0,3)=cl(int(rnd(1)*5))
10050 po(0,4)=cl(int(rnd(1)*5))
10060 return

