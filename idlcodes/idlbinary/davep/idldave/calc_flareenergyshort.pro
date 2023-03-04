if n_elements(date) eq 0 then date = ''
date = ask('date (yyyy-mm-dd): ',date)
if n_elements(flaretime) eq 0 then flaretime = ''
flaretime = ask('approx start of flare (hh-mm): ',flaretime)

iyear = fix(strmid(date,0,4))
imonth = fix(strmid(date,5,2))
iday = fix(strmid(date,8,2))
flarestime = [iyear,imonth,iday,fix(strmid(flaretime,0,2)),fix(strmid(flaretime,2,2)),0]
flareetime = [iyear,imonth,iday,fix(strmid(flaretime,0,2))+6,0,0]
c_a_to_r,flarestime, fstime
c_a_to_r,flareetime, fetime

reread = 1
vdate = date_conv(date,'V')
doy = vdate(1)
year = vdate(0)

strdate = tostr(year)+tostr(doy)

;fismfile = 'fismflux'+tostr(iyear)+ chopr('0'+tostr(imonth),2)+ chopr('0'+tostr(iday),2)+'.dat'
fismfile = '~/FISM/BinnedFiles/'+tostr(iyear)+'/fismflux'+tostr(iyear)+ $
  chopr('0'+tostr(imonth),2)+ chopr('0'+tostr(iday),2)+'.dat'


;fism flux

nwaves = 59
waveL = fltarr(nwaves)
waveH = fltarr(nwaves)

close,1
lowfile = '~/see/wavelow'
openr,1,lowfile
readf, 1, waveL
close,1

highfile = '~/see/wavehigh'
openr,1,highfile
readf, 1, waveH
close,1

nfismlinesmax = 10000

fismflux = fltarr(nwaves,nfismlinesmax)
fismtime = intarr(6,nfismlinesmax)
srtime = dblarr(nfismlinesmax)

close,1
temp = fltarr(nwaves+6)
openr,1,fismfile
iline = 0
start = 0 
t = ' '
while not start do begin
    readf,1,t
    if strpos(t,'#START') ge 0 then start = 1
endwhile

while not eof(1) do begin
    readf, 1,temp
    fismtime(*,iline) = fix(temp(0:5))
    fismflux(*,iline) = temp(6:*)
    c_a_to_r,fismtime(*,iline),rt
    srtime(iline) = rt

    iline = iline + 1
endwhile
close,1

srtime = srtime(0:iline - 1)
fismtime = fismtime(*,0:iline - 1)
fismflux = fismflux(*,0:iline - 1)
nfismtimes = iline - 1
fismenergy = fltarr(nfismtimes-1)


;GOES flux

shortdate =  strmid(tostr(iyear),2,2)+chopr('0'+tostr(imonth),2)
goesfile = '~/GOES/'+tostr(iyear)+'/data/*'+shortdate+'.TXT'
nlinesskip = 26
ngoeslines = file_lines(goesfile)-nlinesskip
goestime = intarr(6,ngoeslines)
goesflux = fltarr(2,ngoeslines)
grtime = fltarr(ngoeslines)

temp = ' '
openr,1,goesfile
for i = 0, nlinesskip - 1 do begin
    readf,1,temp
endfor

for iline = 0, ngoeslines - 1 do begin
    readf, 1, temp
    t = strsplit(temp, /extract)
    goestime(*,iline) = fix([strmid(t(0),0,2)+2000,strmid(t(0),2,2),strmid(t(0),4,2),$
                         strmid(t(1),0,2),strmid(t(1),2,2),0])
    goesflux(*,iline) = t(3:4)
    c_a_to_r,goestime(*,iline),rt
    grtime(iline) = rt

endfor
close,1

svtime = [iyear,imonth,iday,0,0,0]
nextday = next_day(imonth,iday)
evtime = [iyear,imonth,nextday,0,0,0]
c_a_to_r,svtime,stime
c_a_to_r,evtime,etime

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
for itime = 0, nfismtimes - 2 do begin
    for iwave = 0, nwaves - 1 do begin
        fismenergy(itime) = fismenergy(itime) + (fismflux(iwave,itime) * $
          (waveL(iwave) + waveH(iwave))/2. * (srtime(itime+1) - srtime(itime)))
    endfor
endfor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn

setdevice,'plot.ps','p',5,.95

plot, srtime - stime, fismenergy,xtickname = xtickname, xticks=xtickn,$
  xtickv = xtickv, xminor = xminor,/noerase,xrange = [0,etime-stime],xtitle = xtitle

closedevice

setdevice,'energy.ps','p',5,.95
time_axis, fstime, fetime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
slocs = where(srtime ge fstime and srtime le fetime)
glocs = where(grtime ge fstime and grtime le fetime)

plot, grtime(glocs)-fstime,alog10(goesflux(0,glocs)),psym=10,xtickname = xtickname, xticks=xtickn,$
  xtickv = xtickv, xminor = xminor, xtitle = xtitle,/noerase,pos=[.05,.05,.9,.7]
;oplot, srtime(slocs)-fstime,fismflux(56,slocs)+fismflux(57,slocs)+fismflux(58,slocs),linestyle=2,$
;  psym=10
oplot, srtime(slocs)-fstime,alog10(fismflux(56,slocs)+fismflux(57,slocs)+fismflux(58,slocs)),$
  psym=-sym(2),symsize = 1.5,linestyle=2
legend, ['GOES','fism'],linestyle = [0,1],psym=[0,-8], box = 0,pos = [.61,.68],/norm


fenergy = fltarr(nwaves)
baseenergy = fltarr(nwaves)
genergy = 0
for iwave = 0, nwaves - 1 do begin
    for itime = slocs(0), max(slocs-1) do begin
        fenergy(iwave) = fenergy(iwave)+(fismflux(iwave,itime) * (srtime(itime+1) - $
                                                                  srtime(itime)))
        baseenergy(iwave) = baseenergy(iwave) + fismflux(iwave,slocs(0))* $
          (srtime(itime+1) - srtime(itime))

    endfor
endfor

compenergy = total(fenergy(56:58))

for itime = 0, n_elements(glocs) - 1 do begin
    genergy = genergy + (goesflux(0,glocs(itime)) * (grtime(glocs(itime)+1) - $
                                                     grtime(glocs(itime))))
end
xyouts, .63,.6,'GOES energy: '+tostrf(genergy),/norm
xyouts, .63,.57,'FISM energy: '+tostrf(compenergy),/norm

print, ' '
print, 'The .1-.8 nm fism energy is: ', tostrf(compenergy), ' and GOES energy is: ',tostrF(genergy), ' in J/m^2'

print, 'The total fism energy is: ', tostrf(total(fenergy))
print, 'The total fism energy-base energy is: ', tostrf(total(fenergy)-total(baseenergy))
print, ' '
closedevice


printflaredata = 1


if printflaredata then begin
    fmax = max(fismflux(56,*),im)
    openw,1,'flaredata.dat'
    printf,1,'Pre-Flare Values (from FISM (W/m2))'
    printf,1,fismflux(*,slocs(0)),format = '(59E9.2)'
    printf,1,' '
    printf,1,'Maximum Flare Values (from FISM (W/m2))'
    printf,1,fismflux(*,im),format = '(59E9.2)'

    close,1
endif
end

