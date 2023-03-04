filelist = file_search('3D*')
nfiles = n_elements(filelist)

itimearray = intarr(6,nfiles)
    spos = strpos(filelist(0),'t',/reverse_search,/reverse_offset)+1
for ifile = 0, nfiles - 1 do begin

    cyear = strmid(filelist(ifile),spos,2)
    cmon  = strmid(filelist(ifile),spos+2,2)
    cday  = strmid(filelist(ifile),spos+4,2)
    chour = strmid(filelist(ifile),spos+7,2)
    cmin  = strmid(filelist(ifile),spos+9,2)
    csec  = strmid(filelist(ifile),spos+11,2)

    if fix(cyear) gt 50 then cyear = tostr(1900+fix(cyear)) else cyear = tostr(2000 + fix(cyear)) 
    itimearray(*,ifile) = fix([cyear,cmon,cday,chour,cmin,csec])
endfor

time_display, itimearray

if n_elements(whichfile) eq 0 then whichfile = 0
whichfile = fix(ask('which time to plot: ',tostr(whichfile)))
filename = filelist(whichfile)

print, 'Reading file ',filename

read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
  vars, data, rb, cb, bl_cnt

alt = reform(data(2,0,0,*)) / 1000.0
lat = reform(data(1,*,*,0)) / !dtor
lon = reform(data(0,*,*,0)) / !dtor
 

itemp = where(vars eq 'Temperature') 
ie = where(vars eq '[e-]') 
irho = where(vars eq 'Rho') 
iO = where(vars eq '[O]') 
iN2 = where(vars eq '[N!D2!N]') 

temp = reform(data(itemp,2:nlons-3,2:nlats-3,2:nalts-3))
tinf = reform(temp(*,*,nalts-9))
eDen = reform(data(ie,2:nlons-3,2:nlats-3,2:nalts-3))
rho = reform(data(irho,2:nlons-3,2:nlats-3,2:nalts-3))

Aloc = where(alt gt 400.0)
i = Aloc(0)
x = (400.0 - Alt(i-1)) / $
  (Alt(i) - Alt(i-1))
Rho400 = exp((1.0 - x) * alog(Rho(*,*,i-1-2)) + $
             (      x) * alog(Rho(*,*,i-2)))

ODen = reform(data(iO,2:nlons-3,2:nlats-3,2:nalts-3))
N2Den = reform(data(iN2,2:nlons-3,2:nlats-3,2:nalts-3))

sza = fltarr(nlons-4,nlats-4)
NmF2 = fltarr(nlons-4,nlats-4)
HmF2 = fltarr(nlons-4,nlats-4)

for ilat = 0, nlats - 5 do begin
    for ilon = 0, nlons - 5 do begin
        tlat = lat(ilon+2,ilat+2,0)
        tlon = lon(ilon+2,ilat+2,0)
        if tlon gt 180.0 then tlon = tlon - 360
        day = cyear+'-'+cmon+'-'+cday
        ut = fix(chour) + fix(cmin)/60. + fix(csec)/3600.
        zsun,day,ut,tlat,tlon,zenith,azimuth,solfac
        sza(ilon,ilat) = zenith

        loc = where(alt(2:nalts-3) gt 200.0)
        ialt200 = loc(0)
        NmF2(ilon,ilat) = max(eden(ilon,ilat,ialt200:*),ihmf2)
        HmF2(ilon,ilat) = alt(ihmf2+ialt200+2)
    endfor
endfor

o      = fltarr(nLons-4, nLats-4)
n2     = fltarr(nLons-4, nLats-4)
AltInt = fltarr(nLons-4, nLats-4)

MaxValN2 = 1.0e21

for iLon = 2, nLons-3 do begin
    for iLat = 2, nLats-3 do begin
        
        iAlt = nAlts-1
        Done = 0
        if (max(data(in2,iLon,iLat,*)) eq 0.0) then Done = 1
        while (Done eq 0) do begin
            dAlt = (Alt(iAlt)-Alt(iAlt-1))*1000.0
            n2Mid = (data(in2,iLon,iLat,iAlt) + $
                     data(in2,iLon,iLat,iAlt-1)) /2.0
            oMid  = (data(io,iLon,iLat,iAlt) + $
                     data(io,iLon,iLat,iAlt-1)) /2.0
            
            if (n2(iLon-2,iLat-2) + n2Mid*dAlt lt MaxValN2) then begin
                n2(iLon-2,iLat-2) = n2(iLon-2,iLat-2) + n2Mid*dAlt
                o(iLon-2,iLat-2)  =  o(iLon-2,iLat-2) +  oMid*dAlt
                iAlt = iAlt - 1
            endif else begin
                dAlt = (MaxValN2 - n2(iLon-2,iLat-2)) / n2Mid
                n2(iLon-2,iLat-2) = n2(iLon-2,iLat-2) + n2Mid*dAlt
                o(iLon-2,iLat-2)  =  o(iLon-2,iLat-2) +  oMid*dAlt
                AltInt(iLon-2,iLat-2) = Alt(iAlt) - dAlt
                Done = 1
            endelse
        endwhile
        
        
    endfor
endfor

ratio = n2*0.0
loc = where(n2 gt 0.0,count)
if (count gt 0) then ratio(loc) = o(loc)/n2(loc)
    
;;;;;Day side average;;;;
dayloc = where(sza le 30.0)
rhoavg_day = mean(rho400(dayloc))
tempavg_day = mean(tinf(dayloc))
NmF2avg_day = mean(NmF2(dayloc))
HmF2avg_day = mean(HmF2(dayloc))
on2avg_day = mean(ratio(dayloc))

;;;;;Night side average;;;;
nightloc = where(sza gt 150.0)
rhoavg_night = mean(rho400(nightloc))
tempavg_night = mean(tinf(nightloc))
NmF2avg_night = mean(NmF2(nightloc))
HmF2avg_night = mean(HmF2(nightloc))
on2avg_night = mean(ratio(nightloc))

;;;;;High-lat average;;;;
dlat = lat(0,1)-lat(0,0)
dlon = lon(1,0)-lon(0,0)
re = 6378000.

hlatloc = where(abs(lat(2:nlons-3,2:nlats-3)) gt 60.0)
for iloc = 0, n_elements(hlatloc) - 1 do begin
    latavg = (lat(iloc)+(dlat/2.))*!dtor
    cellvolrho =  ((re+400000.)^2*abs(cos(latavg(0,0,*))))*(alt(i)-alt(i-1))*1000.0 *$
                     (dlat*!dtor*dlon*!dtor)

    cellvoltemp =  ((re+400000.)^2*abs(cos(latavg(0,0,*))))*(alt(nalts-5)-alt(nalts-6))*1000.0 *$
                     (dlat*!dtor*dlon*!dtor)

    cellvolon2 =  ((re+400000.)^2*abs(cos(latavg(0,0,*))))*(5000.)*$
                     (dlat*!dtor*dlon*!dtor)

    cellvolnmf2 =  ((re+400000.)^2*abs(cos(latavg(0,0,*))))*(10000.)*$
                     (dlat*!dtor*dlon*!dtor)

endfor

rhoavg_hlat = total(rho400(hlatloc)*cellvolrho)/total(cellvolrho)
tempavg_hlat = total(tinf(hlatloc)*cellvoltemp)/total(cellvoltemp)
NmF2avg_hlat = total(NmF2(hlatloc)*cellvolnmf2)/total(cellvolnmf2)
HmF2avg_hlat = total(HmF2(hlatloc)*cellvolnmf2)/total(cellvolnmf2)
on2avg_hlat = total(ratio(hlatloc)*cellvolon2)/total(cellvolon2)

print, ' '
print, '-----Dayside Averages------'
print, 'rho(400) = ',rhoavg_day
print, 'T(inf) = ',tempavg_day
print, 'O/N2 = ',on2avg_day
print, 'NmF2 = ', nmf2avg_day
print, 'HmF2 = ', hmf2avg_day
print, '---------------------------'
print, ' '
print, '-----Nightside Averages------'
print, 'rho(400) = ',rhoavg_night
print, 'T(inf) = ',tempavg_night
print, 'O/N2 = ',on2avg_night
print, 'NmF2 = ', nmf2avg_night
print, 'HmF2 = ', hmf2avg_night
print, '------------------------------'
print, ' '
print, '-----High lat Averages------'
print, 'rho(400) = ',rhoavg_hlat
print, 'T(inf) = ',tempavg_hlat
print, 'O/N2 = ',on2avg_hlat
print, 'NmF2 = ', nmf2avg_hlat
print, 'HmF2 = ', hmf2avg_hlat
print, '---------------------------'

end
