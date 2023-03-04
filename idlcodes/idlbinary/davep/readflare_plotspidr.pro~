doall = 1
  
  if not doall then begin
     if n_elements(flarefiles) eq 0 then flarefiles = ' '
     flarefiles = ask('which flare file to plot: ',flarefiles)
  endif else begin
     flarefiles = file_search('flares????.dat')
endelse
     nfiles = n_elements(flarefiles)

for ifile = 0, nfiles -1 do begin
   fn = file_search(flarefiles(ifile))

   if ifile eq 0 then begin
      if n_elements(buffer) eq 0 then buffer = 1
      buffer = float(ask('number of days before and after event to plot',tostrf(buffer)))
      
      params = ['hmF2','nmF2']
      display,params
      if n_elements(whichpar) eq 0 then whichpar = 0
      ipar = fix(ask('which param to download: ',tostr(whichpar)))
      
      case ipar of
         0: par = 'hmF2'
         1: par = 'foF2'
      endcase
      
      if n_elements(minv) eq 0 then minv = 0.0
      if n_elements(maxv) eq 0 then maxv = 0.0
      minv = float(ask('minimum value to plot (0 for auto): ',tostr(minv)))
      maxv = float(ask('minimum value to plot (0 for auto): ',tostr(maxv)))
   endif

   close,1
   close,5
   openr,1,fn
   openw,5,'idlrunfile'
   nmax = 1000
   ftime = intarr(6,nmax)
   magnitude = fltarr(nmax)
   length = fltarr(nmax)
   temp = ' '
   iflare = 0

   while not eof(1) do begin
      readf,1,temp
      t = strsplit(temp,/extract)
      magnitude(iflare) = t(1)
      year = t(4)
      mon = t(5)
      day = t(6)
      hour = t(7)
      min = t(8)
      sec = t(9)
      it = fix([year,mon,day,hour,min,sec])
      ftime(*,iflare)= it
      
      length(iflare) = t(12)


      st = fix([year,mon,day,hour,'0','0'])
;   st = it
      c_a_to_r,st,rt
      srt = rt - buffer*24*3600.
      c_r_to_a,stime,srt
      ert = rt + buffer*24*3600
      c_r_to_a,etime,ert
      cyear = tostr(stime(0))
      cmon = chopr('0'+tostr(stime(1)),2)
      cday = chopr('0'+tostr(stime(2)),2)
      chour = chopr('0'+tostr(stime(3)),2)
      cmin = chopr('0'+tostr(stime(4)),2)
      csec = chopr('0'+tostr(stime(5)),2)

      eyear = tostr(etime(0))
      emon = chopr('0'+tostr(etime(1)),2)
      eday = chopr('0'+tostr(etime(2)),2)
      ehour = chopr('0'+tostr(etime(3)),2)
      emin = chopr('0'+tostr(etime(4)),2)
      esec = chopr('0'+tostr(etime(5)),2)
      
      fyear = tostr(ftime(0,iflare))
      fmon = chopr('0'+tostr(ftime(1,iflare)),2)
      fday = chopr('0'+tostr(ftime(2,iflare)),2)
      fhour = chopr('0'+tostr(ftime(3,iflare)),2)
      fmin = chopr('0'+tostr(ftime(4,iflare)),2)
      fsec = chopr('0'+tostr(ftime(5,iflare)),2)
      
      starttime = cyear+cmon+cday
      endtime = eyear+emon+eday
      flaretime = fyear+fmon+fday+' '+fhour+fmin

      
      printf,5,'.r spidr_plot_data'
      printf,5,starttime
      printf,5,endtime
      printf,5,tostr(ipar)
      printf,5,'y'
      printf,5,flaretime
      printf,5,'-1'
      printf,5,tostrf(minv)
      printf,5,tostrf(maxv)
      printf,5,'$mv plot.ps '+params(ipar)+fyear+fmon+fday+'.ps'
      printf,5,' '
      

      iflare = iflare + 1
   endwhile
   close,1
   close,5
   nflares = iflare

   spawn,'idl < idlrunfile'
endfor



end

