dt = 10                         ;Minutes
  outdt = 15
  nIntervals = 24*60./dt
  nInts = 24*60./outdt

 

  binbykp = 0
reread = 1
if n_elements(hour) gt 0 then begin
   reread = 'n'
   reread = ask('whether to reread',reread)
   if strpos(reread,'y') ge 0 then reread = 1 else reread = 0
endif
  if reread then begin
     if binbykp then nkps = 4 else nkps = 1
     attime = strarr(nkps,3,nIntervals)
     asciitime = strarr(nkps,3,nInts)
     atdata = fltarr(nkps,4,nIntervals)
     asciidata = fltarr(nkps,4,nInts)
     
     
     
     for ikp = 0, nkps - 1 do begin
 hour = 0
        for iint = 0, nIntervals - 1 do begin

           mins = tostr(fix((iint*dt) mod 60.))
           if iint ne 0 and mins eq '0' then hour = hour + 1
           hour = chopr('0'+tostr(hour),2)
           mins = chopr('0'+tostr(mins),2)
          
           filelist = file_search('*??????_'+hour+mins+'??*.bin')

           nfiles_new = n_elements(filelist)
           if iint eq 0 and ikp eq 0 then begin
              if nfiles_new gt 1 then begin
                 ift = 0
                 type = ' '
                 filetype = strarr(nfiles_new)
                 for ifile = 0, nfiles_new - 1 do begin
                    l1 = strpos(filelist(ifile),'/',/reverse_search)+1
                    type = strmid(filelist(ifile),l1,5)
                    if ifile eq 0 then filetype(0) = type
                    
                    if filetype(ift) ne type then begin
                       ift = ift + 1
                       filetype(ift) = type
                    endif
                 endfor
                 filetype = filetype(0:ift)
                 display, filetype
                 if n_elements(ft) eq 0 then ft = 0
                 ft = fix(ask('which filetype: ',tostr(ft)))
                 whichtype = filetype(ft)
              endif
           endif
           filelist = file_search(whichtype+'*_'+hour+mins+'??*.bin')
           nfiles_new = n_elements(filelist)
           kp = intarr(nfiles_new)

           gseason = strarr(nfiles_new)
           
           gseasonlast = ' '
           stypes = ' '
           for ifile = 0, nfiles_new - 1 do begin
              fn = filelist(ifile)
              itime = get_gitm_time(fn)
              
              if binbykp then begin
                 kpt = get_kpvalue(itime)
                 case strtrim(kpt,2) of
                    '0-': kpbin = 1
                    '0' : kpbin = 1
                    '0+': kpbin = 1
                    '1-': kpbin = 1
                    '1' : kpbin = 2
                    '1+': kpbin = 2
                    '2-': kpbin = 2
                    '2' : kpbin = 3
                    '2+': kpbin = 3
                    '3-': kpbin = 3
                    else:  kpbin = 4
                 endcase 
                 
                 kp(ifile) = kpbin
              endif
              doy = jday(itime(0),itime(1),itime(2))
              
              gseason(ifile) = season(doy)
              
              if gseason(ifile) ne gseasonlast and where(stypes eq gseason(ifile)) lt 0 then begin
                 stypes = [stypes,gseason(ifile)]
                 gseasonlast = gseason(ifile)
                 
              endif
           endfor

           ntypes = n_elements(stypes) -1
           stypes= stypes(1:*)
           
           if iint eq 0 and ikp eq 0 then begin
              display,stypes
              if n_elements(iseas) eq 0 then iseas = 0
              iseas = fix(ask('which season to plot: ',tostr(iseas)))
              
              seas = stypes(iseas)           
           endif


           
           if binbykp then begin
              locs = where(gseason eq seas and kp eq ikp + 1)
           endif else begin
              locs = where(gseason eq seas)
           endelse
           filelist = filelist(locs)
           
           nfiles = n_elements(filelist)

           for ifile = 0, nfiles - 1 do begin
              fn = filelist(ifile)
              
              print, 'Working on file '+fn
              read_thermosphere_file, fn ,nvars, nalts, nlats, nlons, $
                                      vars, data, nBLKlat, nBLKlon, nBLK
              
              if ifile eq 0 then begin
                 alldata = fltarr(nfiles,2)
                 evar = where(vars eq '[e-]')
              endif
              
              alt = reform(data(2,0,0,2:nalts-3))/1000.0
              
              minalt = min(where(alt gt 200.0))
              maxalt = min(where(alt gt 450.0))
              ialth = min(where(alt ge 300.0))
              ialtl = ialth - 1
              
              ralt = (alt(ialth) - 300.0)/(alt(ialth) - alt(ialtl))
              
              nmf2 = max(data(evar,0,0,minalt+2:maxalt+2),inmf2)
              inmf2 = inmf2 + minalt
              hmf2 = alt(inmf2)
              if inmf2 ge nalts - 7 then begin
                 newalt = min(abs(alt-230),imin)
                 nmf2 = data(evar,0,0,imin+2)
                 hmf2 = 230.0
              endif
              
              alldata(ifile,*) = [nmf2,hmf2]
              
           endfor
           

           attime(ikp,*,iint) = [hour,mins,'00']
           if n_elements(filelist) gt 1 then begin
              atdata(ikp,0,iint) =  mean(alldata(*,0))
              atdata(ikp,1,iint) =  stddev(alldata(*,0))
              atdata(ikp,2,iint) =  mean(alldata(*,1))
              atdata(ikp,3,iint) =  stddev(alldata(*,1))
           endif else begin
              atdata(ikp,0,iint) =  (alldata(0,0))
              atdata(ikp,1,iint) =  (alldata(0,0))
              atdata(ikp,2,iint) =  (alldata(0,1))
              atdata(ikp,3,iint) =  (alldata(0,1))
           endelse
           
        endfor
     endfor
  endif


  for ikp = 0, nkps-1 do begin
     close,5
     if binbykp then title = '../'+strmid(whichtype,0,4)+'_'+seas+'_'+tostr(ikp+1)+'.txt' else $
        title = '../'+strmid(whichtype,0,4)+'_'+seas+'.txt'
     openw,5,title
     printf,5,'GITM results file: Hour   Minute   Second   NmF2_mean  NmF2_stdev  HmF2_mean Hmf2_stdev'
     smallint = 0               ;0 and nInts
     for iint = 0, nIntervals - 1 do begin
        if attime(ikp,1,iint) eq '10' or attime(ikp,1,iint) eq '40' then begin
           
           asciitime(ikp,1,smallint) = tostr(fix(attime(ikp,1,iint) + 5))
           asciitime(ikp,0,smallint) = attime(ikp,0,iint) 
           asciitime(ikp,2,smallint) = attime(ikp,2,iint) 
           tfac = (20-15)/(20.-10)
           asciidata(ikp,*,smallint) = -tfac*(atdata(ikp,*,iint+1) - atdata(ikp,*,iint)) $
                                   + atdata(ikp,*,iint+1)

           iint = iint + 1
           printf, 5, format='(3(A7),4(G))', asciitime(ikp,*,smallint),asciidata(ikp,*,smallint)
        endif else begin
           asciidata(ikp,*,smallint) = atdata(ikp,*,iint)
           asciitime(ikp,*,smallint) = attime(ikp,*,iint)
           printf, 5, format='(3(A7),4(G))', asciitime(ikp,*,smallint),asciidata(ikp,*,smallint)
        endelse
        smallint = smallint + 1

     endfor
     close,5
  endfor




;for ifile = 0, nfiles - 1 do begin
;    fn = filelist(ifile)
;    l = strpos(fn,'.bin')
;    fbase = strmid(fn,0,l-1)
;    afile = fbase+'.txt'
end

    
