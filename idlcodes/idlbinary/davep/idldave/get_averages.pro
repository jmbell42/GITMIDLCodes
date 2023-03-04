FUNCTION get_averages,filelist,type

nfiles = n_elements(filelist)
itimearray = intarr(6,nfiles)
rtime = fltarr(nfiles)
spos = strpos(filelist(0),'t',/reverse_search,/reverse_offset)+1

if strpos(filelist(0),'ALL') ge 0 then isAll = 1 else isAll = 0
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

    NmF2avg = fltarr(nfiles)
    HmF2avg = fltarr(nfiles)
    on2avg = fltarr(nfiles)

for ifile = 0, nfiles - 1 do begin
        
    filename = filelist(ifile)

     print, 'Reading file ',filename
     
     read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
       vars, data, rb, cb, bl_cnt
     nvarsold = nvars
     if isall then begin
         nvars = nvars + 3
         vars = [vars,'NmF2','HmF2','O/N!D2!N']
     endif

     if ifile eq 0 then begin
         ;3 for avg,min,max
         ;4 for glb,day,night,hlat
         dataavg = fltarr(3,nfiles,4,nvars,nalts-4)
         iavg = 0
         imin = 1
         imax = 2
     endif

     alt = reform(data(2,0,0,*)) / 1000.0
     lat = reform(data(1,*,*,0)) / !dtor
     lon = reform(data(0,*,*,0)) / !dtor
     
     if isall then begin
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
 endif

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
             if isall then begin
                 NmF2(ilon,ilat) = max(eden(ilon,ilat,ialt200:*),ihmf2)
                 HmF2(ilon,ilat) = alt(ihmf2+ialt200+2)
             endif
         endfor
     endfor
     
     o      = fltarr(nLons-4, nLats-4)
     n2     = fltarr(nLons-4, nLats-4)
     AltInt = fltarr(nLons-4, nLats-4)
     
     MaxValN2 = 1.0e21
     
     if isall then begin
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
         
         dlat = lat(0,1)-lat(0,0)
         dlon = lon(1,0)-lon(0,0)
         re = 6378000.
         
         iglb = 0
         iday = 1
         init = 2
         ihlt = 3
     endif

     if strpos(type,'global') ge 0 then begin
         hmf2avg = 0
         nmf2avg = 0
         on2avg = 0
         for ialt = 2, nalts - 3 do begin
             cellvoltotal = 0
             
             if fix(alt(ialt)) eq fix(hmf2(2,2)) then begin
                 dohmf2 = 1
             endif else begin
                 dohmf2 = 0
             endelse
             if not isall then dohmf2 = 0
             
             for ilon = 2, nlons - 4 do begin
                 for ilat = 2, nlats - 4 do begin
                     latavg = lat(0,ilat) + dlat
                     cellvol = ((re+((alt(ialt)+alt(ialt-1))/2.))^2 * $
                                abs(cos(latavg)))*(alt(ialt)-alt(ialt-1))*1000.0 *$
                       (dlat*!dtor*dlon*!dtor)
                     
                     dataavg(iavg,ifile,iglb,0:nvarsold-1,ialt-2) = $
                       dataavg(iavg,ifile,iglb,0:nvarsold-1,ialt-2) + $
                       (reform(data(*,ilon,ilat,ialt)) * cellvol)

                     cellvoltotal = cellvoltotal + cellvol
                     
                     if dohmf2 then begin
                         hmf2avg = hmf2avg + (hmf2(ilon-2,ilat-2) * cellvol)
                         nmf2avg = nmf2avg + (nmf2(ilon-2,ilat-2) * cellvol)
                         on2avg  = on2avg + (ratio(ilon-2,ilat-2) * cellvol)
                     endif
                     
                 endfor
             endfor
             dataavg(iavg,ifile,iglb,0:nvarsold-1,ialt-2) = $
               dataavg(iavg,ifile,iglb,0:nvarsold-1,ialt-2) / cellvoltotal
             
             if isall then begin
                 for ivar = 0, nvars - 4 do begin
                     dataavg(imin,ifile,iglb,ivar,ialt-2) = min(data(ivar,2:nlons-3,2:nlats-3,ialt))
                     dataavg(imax,ifile,iglb,ivar,ialt-2) = max(data(ivar,2:nlons-3,2:nlats-3,ialt))
                 endfor
             endif else begin
                 for ivar = 0, nvars - 1 do begin
                     dataavg(imin,ifile,iglb,ivar,ialt-2) = min(data(ivar,2:nlons-3,2:nlats-3,ialt))
                     dataavg(imax,ifile,iglb,ivar,ialt-2) = max(data(ivar,2:nlons-3,2:nlats-3,ialt))
                 endfor
             endelse

                 if dohmf2 then begin
                     hmf2avg = hmf2avg/cellvoltotal
                     nmf2avg = nmf2avg/cellvoltotal
                     on2avg  = on2avg/cellvoltotal
                 endif

         endfor

         if isall then begin
             dataavg(iavg,ifile,iglb,nvarsold:nvarsold+2,nalts-5) = $
               [nmf2avg,hmf2avg,on2avg]
             dataavg(imin,ifile,iglb,nvarsold:nvarsold+2,nalts-5) = [min(nmf2),min(hmf2),min(ratio)]
             dataavg(imax,ifile,iglb,nvarsold:nvarsold+2,nalts-5) = [max(nmf2),max(hmf2),max(ratio)]
         endif
     end 

     if strpos(type,'day') ge 0 then begin
         hmf2avg = 0
         nmf2avg = 0
         on2avg = 0
         for ialt = 2, nalts - 3 do begin
             cellvoltotal = 0
             
             if fix(alt(ialt)) eq fix(hmf2(2,2)) then begin
                 dohmf2 = 1
             endif else begin
                 dohmf2 = 0
             endelse
             if not isall then dohmf2 = 0
             
             for ilon = 2, nlons - 4 do begin
                 for ilat = 2, nlats - 4 do begin
                     if sza(ilon-2,ilat-2) le 30.0 then begin
                         latavg = lat(0,ilat) + dlat
                         cellvol = ((re+((alt(ialt)+alt(ialt-1))/2.))^2 * $
                                    abs(cos(latavg)))*(alt(ialt)-alt(ialt-1))*1000.0 *$
                           (dlat*!dtor*dlon*!dtor)
                         
                         dataavg(iavg,ifile,iday,0:nvarsold-1,ialt-2) = $
                           dataavg(iavg,ifile,iday,0:nvarsold-1,ialt-2) + $
                           (reform(data(*,ilon,ilat,ialt)) * cellvol)

                         cellvoltotal = cellvoltotal + cellvol
                         
                         if dohmf2 then begin
                             hmf2avg = hmf2avg + (hmf2(ilon-2,ilat-2) * cellvol)
                             nmf2avg = nmf2avg + (nmf2(ilon-2,ilat-2) * cellvol)
                             on2avg  = on2avg + (ratio(ilon-2,ilat-2) * cellvol)
                         endif
                     endif  
                 endfor
             endfor
             dataavg(iavg,ifile,iday,0:nvarsold-1,ialt-2) = $
               dataavg(iavg,ifile,iday,0:nvarsold-1,ialt-2) / cellvoltotal

                 
             locs = where(sza le 30.0)
             
             if isall then begin
                 for ivar = 0, nvars - 4 do begin
                     tempdata = reform(data(ivar,2:nlons-3,2:nlats-3,ialt))
                     dataavg(imin,ifile,iday,ivar,ialt-2) = min(tempdata(locs))
                     dataavg(imax,ifile,iday,ivar,ialt-2) = max(tempdata(locs))
                 endfor
             endif else begin
                 for ivar = 0, nvars - 1 do begin
                     tempdata = reform(data(ivar,2:nlons-3,2:nlats-3,ialt))
                     dataavg(imin,ifile,iday,ivar,ialt-2) = min(tempdata(locs))
                     dataavg(imax,ifile,iday,ivar,ialt-2) = max(tempdata(locs))
                 endfor
             endelse 
             
             if dohmf2 then begin
                 hmf2avg = hmf2avg/cellvoltotal
                 nmf2avg = nmf2avg/cellvoltotal
                 on2avg  = on2avg/cellvoltotal
             endif
         endfor

         if isall then begin
             dataavg(iavg,ifile,iday,nvarsold:nvarsold+2,nalts-5) = $
               [nmf2avg,hmf2avg,on2avg]
             
             dataavg(imin,ifile,iday,nvarsold:nvarsold+2,nalts-5) = $
               [min(nmf2(locs)),min(hmf2(locs)),min(ratio(locs))]
             dataavg(imax,ifile,iday,nvarsold:nvarsold+2,nalts-5) = $
               [max(nmf2(locs)),max(hmf2(locs)),max(ratio(locs))]
         endif
     end 



     if strpos(type,'night') ge 0 then begin
         hmf2avg = 0
         nmf2avg = 0
         on2avg = 0
 for ialt = 2, nalts - 3 do begin
             cellvoltotal = 0
             
             if fix(alt(ialt)) eq fix(hmf2(2,2)) then begin
                 dohmf2 = 1
             endif else begin
                 dohmf2 = 0
             endelse
             if not isall then dohmf2 = 0
             
             for ilon = 2, nlons - 4 do begin
                 for ilat = 2, nlats - 4 do begin
                     if sza(ilon-2,ilat-2) ge 150.0 then begin
                         latavg = lat(0,ilat) + dlat
                         cellvol = ((re+((alt(ialt)+alt(ialt-1))/2.))^2 * $
                                    abs(cos(latavg)))*(alt(ialt)-alt(ialt-1))*1000.0 *$
                           (dlat*!dtor*dlon*!dtor)
                         
                         dataavg(iavg,ifile,init,0:nvarsold-1,ialt-2) = $
                           dataavg(iavg,ifile,init,0:nvarsold-1,ialt-2) + $
                           (reform(data(*,ilon,ilat,ialt)) * cellvol)
                         
                         cellvoltotal = cellvoltotal + cellvol
                         
                         if dohmf2 then begin

                             hmf2avg = hmf2avg + (hmf2(ilon-2,ilat-2) * cellvol)
                             nmf2avg = nmf2avg + (nmf2(ilon-2,ilat-2) * cellvol)
                             on2avg  = on2avg + (ratio(ilon-2,ilat-2) * cellvol)
                         endif
                     endif  
                 endfor
             endfor
             dataavg(iavg,ifile,init,0:nvarsold-1,ialt-2) = $
               dataavg(iavg,ifile,init,0:nvarsold-1,ialt-2) / cellvoltotal
             
             locs = where(sza ge 150.0)
             if isall then begin
                 for ivar = 0, nvars - 4 do begin
                     tempdata = reform(data(ivar,2:nlons-3,2:nlats-3,ialt))
                     dataavg(imin,ifile,init,ivar,ialt-2) = min(tempdata(locs))
                     dataavg(imax,ifile,init,ivar,ialt-2) = max(tempdata(locs))
                 endfor
             endif else begin
                 for ivar = 0, nvars - 1 do begin
                     tempdata = reform(data(ivar,2:nlons-3,2:nlats-3,ialt))
                     dataavg(imin,ifile,init,ivar,ialt-2) = min(tempdata(locs))
                     dataavg(imax,ifile,init,ivar,ialt-2) = max(tempdata(locs))
                 endfor
             endelse

             if dohmf2 then begin
                 hmf2avg = hmf2avg/cellvoltotal
                 nmf2avg = nmf2avg/cellvoltotal
                 on2avg  = on2avg/cellvoltotal
             endif
         endfor
         if isall then begin
             dataavg(iavg,ifile,init,nvarsold:nvarsold+2,nalts-5) = $
               [nmf2avg,hmf2avg,on2avg]
             
             dataavg(imin,ifile,init,nvarsold:nvarsold+2,nalts-5) = $
               [min(nmf2(locs)),min(hmf2(locs)),min(ratio(locs))]
             dataavg(imax,ifile,init,nvarsold:nvarsold+2,nalts-5) = $
               [max(nmf2(locs)),max(hmf2(locs)),max(ratio(locs))]
         endif
 end


     if strpos(type,'highlat') ge 0 then begin
         hmf2avg = 0
         nmf2avg = 0
         on2avg = 0
         for ialt = 2, nalts - 3 do begin
             cellvoltotal = 0
             
             if fix(alt(ialt)) eq fix(hmf2(2,2)) then begin
                 dohmf2 = 1
             endif else begin
                 dohmf2 = 0
             endelse
             if not isall then dohmf2 = 0
             for ilon = 2, nlons - 4 do begin
                 for ilat = 2, nlats - 4 do begin
                     if sza(ilon-2,ilat-2) ge  60.0 and sza(ilon-2,ilat-2) le 120.0 then begin
                         latavg = lat(0,ilat) + dlat
                         cellvol = ((re+((alt(ialt)+alt(ialt-1))/2.))^2 * $
                                    abs(cos(latavg)))*(alt(ialt)-alt(ialt-1))*1000.0 *$
                           (dlat*!dtor*dlon*!dtor)
                         
                         dataavg(iavg,ifile,ihlt,0:nvarsold-1,ialt-2) = $
                           dataavg(iavg,ifile,ihlt,0:nvarsold-1,ialt-2) + $
                           (reform(data(*,ilon,ilat,ialt)) * cellvol)
                         
                         cellvoltotal = cellvoltotal + cellvol
                         
                         if dohmf2 then begin
                             hmf2avg = hmf2avg + (hmf2(ilon-2,ilat-2) * cellvol)
                             nmf2avg = nmf2avg + (nmf2(ilon-2,ilat-2) * cellvol)
                             on2avg  = on2avg + (ratio(ilon-2,ilat-2) * cellvol)
                         endif
                     endif  
                 endfor
             endfor
             dataavg(iavg,ifile,ihlt,0:nvarsold-1,ialt-2) = $
               dataavg(iavg,ifile,ihlt,0:nvarsold-1,ialt-2) / cellvoltotal
             
             locs = where(sza ge 60.0 and sza le 120.0)
           if isall then begin
               for ivar = 0, nvars - 4 do begin
                   tempdata = reform(data(ivar,2:nlons-3,2:nlats-3,ialt))
                   dataavg(imin,ifile,ihlt,ivar,ialt-2) = min(tempdata(locs))
                   dataavg(imax,ifile,ihlt,ivar,ialt-2) = max(tempdata(locs))
               endfor
           endif else begin
               for ivar = 0, nvars - 1 do begin
                   tempdata = reform(data(ivar,2:nlons-3,2:nlats-3,ialt))
                   dataavg(imin,ifile,ihlt,ivar,ialt-2) = min(tempdata(locs))
                   dataavg(imax,ifile,ihlt,ivar,ialt-2) = max(tempdata(locs))
               endfor
           endelse
           if dohmf2 then begin
               hmf2avg = hmf2avg/cellvoltotal
               nmf2avg = nmf2avg/cellvoltotal
               on2avg  = on2avg/cellvoltotal
           endif
       endfor

         if isall then begin
             dataavg(iavg,ifile,ihlt,nvarsold:nvarsold+2,nalts-5) = $
               [nmf2avg,hmf2avg,on2avg]
             
             dataavg(imin,ifile,ihlt,nvarsold:nvarsold+2,nalts-5) = $
               [min(nmf2(locs)),min(hmf2(locs)),min(ratio(locs))]
             dataavg(imax,ifile,ihlt,nvarsold:nvarsold+2,nalts-5) = $
               [max(nmf2(locs)),max(hmf2(locs)),max(ratio(locs))]
         endif
     end
     
  endfor

return,dataavg

end