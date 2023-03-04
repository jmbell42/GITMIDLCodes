pro getxpsflux, startdate
common v9data, xpsv9

read_netcdf, '/Users/dpawlows/SEE/seefiles/see_xps_L4A_merged_2007261_009.ncdf',xps,att
startdate = long(startdate)
enddate = startdate + 1
filename = 'xps_v9_'+strtrim(string(startdate),2)
starti=0
for i=0, n_elements(xps.date) do begin
    if xps(i).date eq startdate and starti eq 0 then begin
        starti = i
        goto, next
    endif
    next:
    if xps(i).date eq enddate then begin
        endi = i
        goto, afterfor
    endif
endfor

afterfor:
N = n_elements(xps(starti:endi-1).date)
xpsflux = fltarr(40,N)

v9 = {date:1L,time:1.0,flux:fltarr(40)}
xpsv9 = replicate(v9,N)

for j = starti, endi-1 do begin
    xpsv9(j-starti).time = xps(j).time
    xpsv9(j-starti).date = xps(j).date
    for iwave = 0, 39 do begin
        xpsv9(j-starti).flux(iwave) = total(xps(j).modelflux[(10*iwave):(10*iwave)+9])/10.
    endfor
endfor



end
