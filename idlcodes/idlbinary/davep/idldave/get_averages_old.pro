PRO get_averages_old,filelist,rtime,Vars,alt,dataavg, other_day,other_night,other_hlat, nFiles

nfiles = n_elements(filelist)
itimearray = intarr(6,nfiles)
rtime = fltarr(nfiles)
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
    c_a_to_r,itimearray(*,ifile),rt
    rtime(ifile) = rt
endfor




    rhoavg_day = fltarr(nfiles)
    tempavg_day = fltarr(nfiles)
    NmF2avg_day = fltarr(nfiles)
    HmF2avg_day = fltarr(nfiles)
    on2avg_day = fltarr(nfiles)
    rhoavg_night = fltarr(nfiles)
    tempavg_night = fltarr(nfiles)
    NmF2avg_night = fltarr(nfiles)
    HmF2avg_night = fltarr(nfiles)
    on2avg_night = fltarr(nfiles)
    rhoavg_hlat = fltarr(nfiles)
    tempavg_hlat = fltarr(nfiles)
    NmF2avg_hlat = fltarr(nfiles)
    HmF2avg_hlat = fltarr(nfiles)
    on2avg_hlat = fltarr(nfiles)


    for ifile = 0, nfiles - 1 do begin
        
     filename = filelist(ifile)

     print, 'Reading file ',filename
     
     read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
       vars, data, rb, cb, bl_cnt
     
     if ifile eq 0 then dataavg = fltarr(nfiles,nvars,3,nalts-4)

     alt = reform(data(2,0,0,*)) / 1000.0
     lat = reform(data(1,*,*,0)) / !dtor
     lon = reform(data(0,*,*,0)) / !dtor
     
     
     itemp = where(vars eq 'Temperature') 
     ie = where(vars eq '[e-]') 
     irho = where(vars eq 'Rho') 
     iO = where(vars eq '[O(!U3!NP)]') 
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
             cyear = tostr(itimearray(0,ifile))
             cmon = tostr(itimearray(1,ifile))
             cday = tostr(itimearray(2,ifile))
             chour = tostr(itimearray(3,ifile))
             cmin = tostr(itimearray(4,ifile))
             csec = tostr(itimearray(5,ifile))
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
     



;;;;;Day side average;;;
     dayloc = where(sza le 30.0)
     rhoavg_day(ifile) = mean(rho400(dayloc))
     tempavg_day(ifile) = mean(tinf(dayloc))
     NmF2avg_day(ifile) = mean(NmF2(dayloc))
     HmF2avg_day(ifile) = mean(HmF2(dayloc))
     on2avg_day(ifile) = mean(ratio(dayloc))

;;;;;Night side average;;;;
     nightloc = where(sza gt 150.0)
     rhoavg_night(ifile) = mean(rho400(nightloc))
     tempavg_night(ifile) = mean(tinf(nightloc))
     NmF2avg_night(ifile) = mean(NmF2(nightloc))
     HmF2avg_night(ifile) = mean(HmF2(nightloc))
     on2avg_night(ifile) = mean(ratio(nightloc))

     dlat = lat(0,1)-lat(0,0)
     dlon = lon(1,0)-lon(0,0)
     re = 6378000.
;;;;;Glb average
     for ialt = 1, nalts - 1 do begin
         for ilat = 0, nlats - 1 do begin
             latavg = (lat(ilat)+(dlat/2.))*!dtor
             cellvol = ((re+400000.)^2*abs(cos(latavg)))*(alt(ialt)-alt(ialt-1))*1000.0 *$
           (dlat*!dtor*dlon*!dtor)

         cellvolrho =  ((re+400000.)^2*abs(cos(latavg)))*(alt(i)-alt(i-1))*1000.0 *$
           (dlat*!dtor*dlon*!dtor)
         
         cellvoltemp =  ((re+400000.)^2*abs(cos(latavg)))*(alt(nalts-5)-alt(nalts-6))*1000.0 *$
           (dlat*!dtor*dlon*!dtor)
         
         cellvolon2 =  ((re+400000.)^2*abs(cos(latavg)))*(5000.)*$
           (dlat*!dtor*dlon*!dtor)
         
         cellvolnmf2 =  ((re+400000.)^2*abs(cos(latavg)))*(10000.)*$
           (dlat*!dtor*dlon*!dtor)
     endfor

     for ivar = 0, nvars - 1 do begin
         for 
;;;;;High-lat average;;;;
     hlatloc = where(abs(lat(2:nlons-3,2:nlats-3)) gt 60.0)
     for iloc = 0, n_elements(hlatloc) - 1 do begin
         latavg = (lat(iloc)+(dlat/2.))*!dtor
         cellvolrho =  ((re+400000.)^2*abs(sin(latavg)))*(alt(i)-alt(i-1))*1000.0 *$
           (dlat*!dtor*dlon*!dtor)
         
         cellvoltemp =  ((re+400000.)^2*abs(cos(latavg)))*(alt(nalts-5)-alt(nalts-6))*1000.0 *$
           (dlat*!dtor*dlon*!dtor)
         
         cellvolon2 =  ((re+400000.)^2*abs(cos(latavg)))*(5000.)*$
           (dlat*!dtor*dlon*!dtor)
         
         cellvolnmf2 =  ((re+400000.)^2*abs(cos(latavg)))*(10000.)*$
           (dlat*!dtor*dlon*!dtor)
         
     endfor
     
     for ivar = 0, nvars - 1 do begin
         for ialt = 2, nalts - 3 do begin
             datatemp = reform(data(ivar,*,*,ialt))
             cellvol =  ((re+400000.)^2*abs(cos(latavg)))*(alt(ialt)-alt(ialt+1))*1000.0 *$
           (dlat*!dtor*dlon*!dtor)
             dataavg(ifile,ivar,0,ialt-2) = mean(datatemp(dayloc))
             dataavg(ifile,ivar,1,ialt-2) = mean(datatemp(nightloc))
             dataavg(ifile,ivar,2,ialt-2) = total(datatemp(hlatloc)*cellvol)/total(cellvol)
         endfor
     endfor

     rhoavg_hlat(ifile) = total(rho400(hlatloc)*cellvolrho)/total(cellvolrho)
     tempavg_hlat(ifile) = total(tinf(hlatloc)*cellvoltemp)/total(cellvoltemp)
     NmF2avg_hlat(ifile) = total(NmF2(hlatloc)*cellvolnmf2)/total(cellvolnmf2)
     HmF2avg_hlat(ifile) = total(HmF2(hlatloc)*cellvolnmf2)/total(cellvolnmf2)
     on2avg_hlat(ifile) = total(ratio(hlatloc)*cellvolon2)/total(cellvolon2)

     NmF2avg_hlat(ifile) = mean(NmF2(hlatloc))
     HmF2avg_hlat(ifile) = mean(HmF2(hlatloc))
     on2avg_hlat(ifile) = mean(ratio(hlatloc))
 endfor


 other_day = fltarr(3,nfiles)
 other_night = fltarr(3,nfiles)
 other_hlat = fltarr(3,nfiles)

    other_day(0,*) = nmf2avg_day
    other_day(1,*) = hmf2avg_day
    other_day(2,*) = on2avg_day
    other_night(0,*) =  nmf2avg_night
    other_night(1,*) =  hmf2avg_night
    other_night(2,*) =  on2avg_night
    other_hlat(0,*) =  nmf2avg_hlat
    other_hlat(1,*) =  hmf2avg_hlat
    other_hlat(2,*) =  on2avg_hlat
    

end
