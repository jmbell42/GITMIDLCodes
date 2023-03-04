if n_elements(day) eq 0 then day = ''
day = ask('date to plot: (yyyy-mm-dd)',day)

if n_elements(time) eq 0 then time = ''
time = ask('time to plot: (hh:mm)',time)

date = strmid(day,0,10)
hour = fix(strmid(time,0,2))
min = fix(strmid(time,3,2))

ut = hour + min/60.

nlats = 36
nlons = 72

lat = fltarr(nlats-1,nlons)
lon = fltarr(nlats-1,nlons)
sza = fltarr(nlats-1,nlons)
sun = fltarr(nlats-1,nlons)

for ilat = 0, nlats - 2 do begin
    lat(ilat,*) = -90 + 5 + ilat * float(180/(nlats-1))
endfor

for ilon = 0, nlons - 1 do begin
    lon(*,ilon) = 5 + ilon * float(360/(nlons))
endfor

zsun,date,ut,lat,lon,zenith,az,sol
for ilat = 0, nlats - 2 do begin
    for ilon = 0, nlons - 2 do begin
        if zenith(ilat,ilon) le 90 then sun(ilat,ilon) = 1000.
        if zenith(ilat,ilon) gt 90 then sun(ilat,ilon) = -1000.
        
    endfor
endfor 

lon(*,nlons-1) = lon(*,0)
sun(*,nlons-1) = sun(*,0)

loadct, 39
;setdevice,'plot.ps','l',5,.95

space = 0.075
ppp = 1
pos_space, ppp, space, sizes, ny = 1
get_position, ppp, space, sizes, 0, pos

get_position, ppp, space, sizes, 0, pos, /rect
pos(1) = pos(1) + space
pos(3) = pos(3) - space*2.0
pos(0) = pos(0) + space*1.0
pos(2) = pos(2) - space*1.0

!p.position = pos

xrange = [0,360]
yrange = [-85,85] 

;contour,d2,x2,y2,/follow,levels = [999,1000,1001],/noerase,pos = pos,$
;  xrange = xrange,yrange = yrange, xstyle = 1, ystyle = 1

window,0
map_set, /noerase,title = 'Day and night at '+time+' UT on ' + date
contour,sun,lon,lat,/cell_fill,$
  levels = [-1001,-1000,-999],c_colors = [190,60,190],xrange = xrange,$
  yrange = yrange, xstyle = 1, ystyle = 1,/over,xtitle = 'Longitude',ytitle = 'Latitude'


map_continents, color = 0

window,1
szacolors = 253-(findgen(20) * 253/20.)
map_set, /noerase,title = 'Solar zenith angle at '+time+' UT on ' + date
contour,zenith,lon,lat,/cell_fill,c_colors = szacolors, $
  nlevels = 20,  xrange = xrange,$
  yrange = yrange, xstyle = 1, ystyle = 1,/over,xtitle = 'Longitude',ytitle = 'Latitude'

contour,zenith,lon,lat,/follow,$
  nlevels = 20,  xrange = xrange,charsize = 1.3,$
  yrange = yrange, xstyle = 1, ystyle = 1,/over,xtitle = 'Longitude',ytitle = 'Latitude'

map_continents, color = 0


;closedevice
end

