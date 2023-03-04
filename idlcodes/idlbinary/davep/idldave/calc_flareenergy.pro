PRO calc_flareenergy, energy,date, flaretime
iyear = fix(strmid(date,0,4))
imonth = fix(strmid(date,5,2))
iday = fix(strmid(date,8,2))
flarestime = [iyear,imonth,iday,fix(strmid(flaretime,0,2)),fix(strmid(flaretime,3,2)),0]

nexthour = fix(strmid(flaretime,0,2)) + 6
c_a_to_r, flarestime,fstime

if nexthour gt 23 then begin
    nexthour = nexthour -24
    nextday = next_day(imonth,iday)
    if nextday eq 1 then begin
        nextmonth = imonth + 1
    endif else begin
        nextmonth = imonth
    endelse
endif else begin
    nextday = iday
    nextmonth = imonth
endelse

if nextmonth - imonth eq 1 then ngoesfiles = 2 else ngoesfiles = 1
;;; find background flux value based on goes data
shortdate =  strmid(tostr(iyear),2,2)+chopr('0'+tostr(imonth),2)
goesfile = '~/GOES/'+tostr(iyear)+'/data/*'+shortdate+'.TXT'
nlinesskip = 26
ngoeslines = file_lines(goesfile)-nlinesskip
goestime = intarr(6,ngoeslines*ngoesfiles)
goesflux = fltarr(2,ngoeslines*ngoesfiles)
grtime = dblarr(ngoeslines*ngoesfiles)
    
for igoesfile = 0, ngoesfiles - 1 do begin
   shortdate =  strmid(tostr(iyear),2,2)+chopr('0'+tostr(imonth+igoesfile),2)
   goesfile = '~/GOES/'+tostr(iyear)+'/data/*'+shortdate+'.TXT'
temp = ' '
openr,55,goesfile
for i = 0, nlinesskip - 1 do begin
    readf,55,temp
endfor

for iline = 0, ngoeslines - 1 do begin
    readf, 55, temp
    t = strsplit(temp, /extract)
    year = fix(strmid(t(0),0,2))
    if year lt 20 then year = year+2000 else year = year+1900
    goestime(*,iline) = [year,strmid(t(0),2,2),strmid(t(0),4,2),$
                         strmid(t(1),0,2),strmid(t(1),2,2),0]
    goesflux(*,iline) = t(3:4)
    c_a_to_r,goestime(*,iline),rt
    grtime(iline) = rt

endfor
close,55
endfor

gstartlocs = where(grtime ge fstime-3*3600 and grtime le fstime)
gstartval = mean(goesflux(0,gstartlocs))

gendlocs = where(grtime ge fstime)
gendloc = min(where(goesflux(0,gendlocs) lt gstartval))

flareetime = goestime(*,gendlocs(gendloc))

c_a_to_r,flarestime, fstime
c_a_to_r,flareetime, fetime

genergy = 0

glocs = where(grtime ge fstime and grtime le fetime)
for itime = 0, n_elements(glocs) - 2 do begin
    genergy = genergy + (goesflux(0,glocs(itime)) * (grtime(glocs(itime)+1) - $
                                                     grtime(glocs(itime))))
endfor

nwaves = 59
waveL = fltarr(nwaves)
waveH = fltarr(nwaves)

close,93
lowfile = '~/see/wavelow'
openr,93,lowfile
readf, 93, waveL
close,93

highfile = '~/see/wavehigh'
openr,93,highfile
readf, 93, waveH
close,93
nfiles = flareetime(2) - flarestime(2)+1

nlinesmax = 10000

fflux = fltarr(nwaves,nlinesmax)
time = intarr(6,nlinesmax)
rtime = dblarr(nlinesmax)

    iline = 0
for ifile = 0, nfiles - 1 do begin
    if ifile eq 0 then sdate = tostr(flarestime(0))+chopr('0'+tostr(flarestime(1)),2)+ $
                                      chopr('0'+tostr(flarestime(2)),2)
    if ifile eq 1 then sdate = tostr(flareetime(0))+chopr('0'+tostr(flareetime(1)),2)+ $
                                      chopr('0'+tostr(flareetime(2)),2)

    fluxfile = '~/FISM/BinnedFiles/'+tostr(flarestime(0))+'/fismflux'+sdate+'.dat'
        
    close,93
    temp = fltarr(nwaves+6)
    openr,93,fluxfile

    start = 0 
    t = ' '
    while not start do begin
        readf,93,t
        if strpos(t,'#START') ge 0 then start = 1
    endwhile
    
    while not eof(93) do begin

        readf, 93,temp
        time(*,iline) = fix(temp(0:5))
        fflux(*,iline) = temp(6:*)
        c_a_to_r,time(*,iline),rt
        rtime(iline) = rt
        
        iline = iline + 1
    endwhile
    close,93
endfor

fflux = fflux(*,0:iline-1)
rtime = rtime(0:iline-1)
time = time(*,0:iline-1)



fstartlocs = where(rtime ge fstime-3*3600 and rtime le fstime)
fstartval = fltarr(nwaves)
for iwave = 0, nwaves - 1 do begin
    fstartval(iwave) = mean(fflux(iwave,fstartlocs))
endfor
fismenergybackground = 0.0

flocs = where(rtime ge fstime and rtime le fetime,nflocs)

fismenergy = fltarr(nflocs)
fismeb = fltarr(nflocs)
fe = 0.0
feb = 0.0
for itime = 0, n_elements(flocs)-1 do begin
    fismenergy(itime) = total(fflux(*,flocs(itime)))* $
      (rtime(flocs(itime)+1)-rtime(flocs(itime)))
    fismeb(itime) = total(fstartval)*$
        (rtime(flocs(itime)+1)-rtime(flocs(itime)))
endfor
fe = total(fismenergy)
feb = total(fismeb)
fismenergycomp = 0.0
for itime = 0, n_elements(flocs)-1 do begin
    fismenergycomp = fismenergycomp +(fflux(56,flocs(itime)) + $
                                                     fflux(57,flocs(itime)) +$
                                                      fflux(58,flocs(itime))) * $
                                      (rtime(flocs(itime)+1)-rtime(flocs(itime)))
endfor


energy = fe-feb

end
