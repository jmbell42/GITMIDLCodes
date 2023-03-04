FUNCTION season, doy

doy = fix(doy)

if doy lt 34 or doy ge 309 then return, 'Winter'
if doy ge 34 and doy le 125 then return, 'Spring'
if doy ge 126 and doy le 217 then return, 'Summer'
if doy ge 218 and doy lt 309 then return, 'Fall'

end

