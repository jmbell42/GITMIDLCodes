;if n_elements(date) eq 0 then date = ''
;date = ask('date (yyyy-mm-dd): ',date)
;if n_elements(flaretime) eq 0 then flaretime = ''
;flaretime = ask('approx start of flare (hh-mm): ',flaretime)

PRO calc_flareenergygoes, genergy,date, flaretime

iyear = fix(strmid(date,0,4))
imonth = fix(strmid(date,5,2))
iday = fix(strmid(date,8,2))
flarestime = [iyear,imonth,iday,fix(strmid(flaretime,0,2)),fix(strmid(flaretime,3,2)),0]
nexthour = fix(strmid(flaretime,0,2)) + 6

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
    
flareetime = [iyear,nextmonth,nextday,nexthour,0,0]
c_a_to_r,flarestime, fstime
c_a_to_r,flareetime, fetime

reread = 1
vdate = date_conv(date,'V')
doy = vdate(1)
year = vdate(0)

strdate = tostr(year)+tostr(doy)


;GOES flux

if imonth ne nextmonth then begin
    ngoesfiles = 2 

endif else begin
    ngoesfiles = 1
endelse

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

glocs = where(grtime ge fstime and grtime le fetime)

genergy = 0

for itime = 0, n_elements(glocs) - 1 do begin
    genergy = genergy + (goesflux(0,glocs(itime)) * (grtime(glocs(itime)+1) - $
                                                     grtime(glocs(itime))))
endfor

end

