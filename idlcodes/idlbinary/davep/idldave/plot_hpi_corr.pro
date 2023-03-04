filename = 'power_2005.txt'
  close,/all
  openr, 1, filename
  openw,2,'power_shift'+tostr(year)+'.txt'
 

  done = 0
  t = ''
  while not done do begin
     readf,1,t
     printf,2,t
     if strpos(t,'Normalizing') ge 0 then done = 1
  endwhile

readf,1,t
printf,2,t
readf,1,t
printf,2,t
year = fix(t)

rtime = dblarr(50000)
time = strarr(50000)
str = strarr(50000)

itime = 0L
while not eof(1) do begin
   readf,1,t
   str(itime) = strmid(t,0,10)
   time(itime) = strmid(t,10,7)
   
   doy = fix(strmid(time(itime),0,3))
   h = strmid(time(itime),3,2)
   m = strmid(time(itime),5,2)
   ctime = fromjday(year,doy)
   itimearr = [year,ctime(0),ctime(1),h,m,0]
   c_a_to_r,itimearr,rt
   rtime(itime) = rt
   hp=strmid(t,17,8)
   hpi = strmid(t,25,3)
   fac = strmid(t,28,8)

   sdoy= doy + 27
   if sdoy gt 365 then sdoy = sdoy - 365
   stime = chopr('      '+tostr(sdoy)+h+m,7)
   printf,2,str(itime),stime,hp,hpi,fac
   
itime = itime + 1
endwhile
ntimes = itime - 1

close,1
close,2

  
end
   
