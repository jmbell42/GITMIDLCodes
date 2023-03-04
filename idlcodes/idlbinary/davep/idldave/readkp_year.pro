pro readkp,year,kp,rtime
  file = '~/UpperAtmosphere/Indices/Kp/'+tostr(year)+'.dat'

  nlines = file_lines(file)
  itime = intarr(6,nlines*8)
  rtime = dblarr(nlines*8)
  kp = str(nlines*8)
  temp = ''

  close,5
  openr,5,file
  il = 0

  ktime = [0,3,6,9,12,15,18,21,24]
  done = 0
  for iline = 0, nlines - 1 do begin
     readf,5,temp

     ttemp = fix(strmid(temp,0,2))
     if ttemp gt 50 then ttemp = 1900 + ttemp else ttemp = 2000 + ttemp
     itime(0,il:il+7) = ttemp
     itime(1,il:il+7) = fix(strmid(temp,2,2))
     itime(2,il:il+7) = fix(strmid(temp,4,2))

     for itimes = 0, 7 do begin
        itime(3,il) = ktime(itimes)
        c_a_to_r,itime(*,il),rt
        rtime(il) = rt
        kp_t = strmid(temp,itimes*2 + 12,2)
        if strmid(kp_t,0,1) eq ' ' then kp_t = '0'+strmid(kp_t,1,1)
         
        if strmid(kp_t,1,1) eq 0 then kp(il) = strmid(kp_t,0,1)
        if strmid(kp_t,1,1) eq 3 then kp(il) = fix(strmid(kp_t,0,1))+.3
        if strmid(kp_t,1,1) eq 7 then kp(il) = fix(strmid(kp_t,0,1))+1)-.3
        il = il + 1
     endfor

endfor
    
  close,5

end
