iVernalTime = [1998,7,14,16,0,0] ;Vernal Equinox at Midnight (LS = 0)
c_a_to_r,ivernaltime,vernaltime
daysperyear = 670.0
rotation_period = 88775.0             
earth_rotation_period = 86400.0    
hoursperday = rotation_period/3600.0

secondsperyear = daysperyear*rotation_period

if n_elements(cutime) eq 0 then cutime = '20010101 000000'
cutime=ask("time: yyyymmdd hhmmss",cutime)
cyear = strmid(cutime,0,4)
cmon = strmid(cutime,4,2)
cday = strmid(cutime,6,2)
chour =strmid(cutime,9,2)
cmin = strmid(cutime,11,2)
csec = strmid(cutime,13,2)
iutime = fix([cyear,cmon,cday,chour,cmin,csec])
c_a_to_r,iutime,currenttime

dtime = currenttime - vernaltime

while dtime gt secondsperyear do begin
   vernaltime = vernaltime + fix(daysperyear)*rotation_period
   dtime = currenttime - vernaltime
endwhile

iday = dtime/rotation_period
utime = (dtime / earth_rotation_period - iDay) * rotation_period


if n_elements(longitutde) eq 0 then longitude = 0.0
longitude = float(ask('which longitude: ',tostrf(longitude)))

localtime = (utime/3600.0 + longitude*!dtor *hoursperday/(2*!pi)) mod hoursperday


print, 'Local time at that location is: ',localtime

end
