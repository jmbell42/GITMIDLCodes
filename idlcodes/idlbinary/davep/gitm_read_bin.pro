
pro gitm_read_bin, file, data, time, nVars, Vars, version

  if (n_elements(file) eq 1) then filelist = findfile(file) $
  else filelist = file

  nFiles = n_elements(filelist)

  if (nFiles gt 1) then Time = dblarr(nFiles) else Time = 0.0D

  for iFile = 0, nFiles-1 do begin

      filein = filelist(iFile)

      print, 'reading ',filein

      close, 1
      openr, 1, filein, /f77

      version = 0.0D

      nLons = 0L
      nLats = 0L
      nAlts = 0L
      nVars = 0L

      readu, 1, version
      readu, 1, nLons, nLats, nAlts
      readu, 1, nVars

      Vars = strarr(nVars)
      line = bytarr(40)
      for iVars = 0, nVars-1 do begin
          readu, 1, line
          Vars(iVars) = strcompress(string(line),/remove)
      endfor

      lTime = lonarr(7)
      readu, 1, lTime

      iTime = fix(lTime(0:5))
      c_a_to_r, itime, rtime
      Time(iFile) = rTime + lTime(6)/1000.0

      if (nFiles eq 1) then begin
          Data = dblarr(nVars, nLons, nLats, nAlts)
      endif else begin
          if (iFile eq 0) then $
            Data = dblarr(nFiles, nVars, nLons, nLats, nAlts)
      endelse

      tmp = dblarr(nLons, nLats, nAlts)
      for i=0,nVars-1 do begin
          readu,1,tmp
          if (nFiles eq 1) then data(i,*,*,*) = tmp $
          else data(iFile,i,*,*,*) = tmp
      endfor
          
      close, 1

  endfor

end

