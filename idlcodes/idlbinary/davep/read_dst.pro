
pro parse_line, line, subdst, subtime

  year  = fix(strmid(line,0,4))
  month = fix(strmid(line,4,3))
  day   = fix(strmid(line,7,3))

  subdst  = fltarr(24)
  subtime = dblarr(24)

  itime = [year, month, day, 0, 0, 0]

  for i=0,23 do begin

      subdst(i) = float(strmid(line,10+i*4,4))
      itime(3) = i
      c_a_to_r, itime, rtime
      subtime(i) = rtime

  endfor

end

pro read_dst, file, dst, time

  openr,1,file

  line = ''
  while (strpos(line,'19') ne 0 and $
         strpos(line,'20') ne 0 and $
         not eof(1)) do readf,1,line
  print, line

  dst  = fltarr(31*24)
  time = dblarr(31*24)

  parse_line, line, subdst, subtime
  dst(0:23)  = subdst
  time(0:23) = subtime

  iDay = 1
  while ((strpos(line,'19') eq 0 or $
          strpos(line,'20') eq 0) and $
         not eof(1)) do begin
      readf,1,line
      parse_line, line, subdst, subtime
      dst(iDay*24:iDay*24+23)  = subdst
      time(iDay*24:iDay*24+23) = subtime
      iDay = iDay + 1
  endwhile

  dst  = dst(0:iDay*24-1)
  time = time(0:iDay*24-1)

  close,1

end

