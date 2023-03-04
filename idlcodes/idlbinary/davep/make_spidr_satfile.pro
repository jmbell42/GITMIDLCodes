close,/all
;if n_elements(filename) eq 0 then filename = ' '
;filename = ask('which file to plot: ',filename)

  filelist = file_search('iono*.dat')
  nfiles = n_elements(filelist)
  for ifile = 0, nfiles -1 do begin
     filename = filelist(ifile)
     print, 'Working on '+filename
     openr, 1, filename

     done = 0
     t = ' '
     while not done do begin
        readf, 1, t
        if strpos(t,'Coordinates') ge 0 then begin
           temp = strsplit(t,/extract)
           lon = float(temp(1))
           lat = float(temp(3))
        endif

        if strpos(t,'Station') ge 0 then begin
           temp = strsplit(t,/extract)
           station = strjoin(temp(2:*),'_')
        endif
        if strpos(t,'#START') ge 0 then done = 1
     endwhile

     file = station+'_pos.dat'
     openw,2,file
     printf,2,'#START'
     while not eof(1) do begin
        readf, 1, t
        if t ne '' then begin
           temp = strsplit(t,/extract)
           cyear = fix(strmid(temp(0),0,4))
           cmon = fix(strmid(temp(0),5,2))
           cday = fix(strmid(temp(0),8,2))
           chour = fix(strmid(temp(1),0,2))
           cmin = fix(strmid(temp(1),3,2))
           csec = 0
           cmsec = 0
           
           
           printf, 2, cyear,cmon,cday,chour,cmin,csec,cmsec, lon,lat,100,format='(7I,3F9.3)'
        endif
     endwhile
     close,/all
  endfor
  end
