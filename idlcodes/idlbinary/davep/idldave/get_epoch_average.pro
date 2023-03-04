PRO get_epoch_average,data,rtime,eptime,epochave,newtimearray,neptimes=neptimes, $
                      nmins=nmins

neptimes = 24/(eptime/60.)
epochave = fltarr(neptimes)
pad = eptime/2.
newtimearray = intarr(3,neptimes)
for itime = 0,neptimes - 1 do begin
   mins = itime * eptime
   nhours = fix(mins / 60.)
   nmins =  fix((mins/60. - nhours) * 60.)
   newtimearray(*,itime) = [nhours,nmins,0]

endfor

ntimes = n_elements(data)

nmins = fltarr(ntimes)
nminsinday = 24*60.
for itime = 0, ntimes -1  do begin
   c_r_to_a,ta,rtime(itime)
   nmins(itime) = ta(3)*60.+ta(4)
   if nmins(itime) gt nminsinday-pad then nmins(itime) = nminsinday - nmins(itime)
endfor


for itime = 0, neptimes - 1 do begin
   findmins = newtimearray(0,itime) * 60. + newtimearray(1,itime)
   mint = findmins - pad
   maxt = findmins + pad
   
   locs = where(nmins ge mint and nmins lt maxt and data ne 0.0,count)
   case count of 
      0: epochave(itime) = -9999.0
      1: epochave(itime) = data(locs)
      else:  epochave(itime) = mean(data(locs))
   endcase

endfor


end
