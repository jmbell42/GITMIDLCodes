nReactions = 27
nStable = 14
nMeta = 11

if n_elements(dir) eq 0 then dir = '.'
dir = ask('which directory: ',dir)

filelist = file_search(dir+'/3DCHM*')
nfiles_new = n_elements(filelist)

if nfiles_new gt 0 then begin
    display, filelist
    if n_elements(pfile) eq 0 then pfile = (0)
    pfile = fix(ask('which file to plot: ',tostr(pfile)))
endif else begin
    pfile = 0
endelse

filename_new = filelist(pfile)
if n_elements(filename) eq 0 then filename = ' '
if filename_new eq filename then begin
    reread = 'n'
    reread = ask('whether to reread data: ',reread)
    if strpos(reread,'y') ge 0 then reread = 1 else reread = 0
endif else begin
    reread = 1
endelse

filename = filename_new(0)

if reread then begin
    print, 'Reading file ',filename
    
    read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
      vars, data, rb, cb, bl_cnt
    
    alts = reform(data(2,0,0,*))/1000.
    lons = reform(data(0,*,0,0))/!dtor
    lats = reform(data(1,0,*,0))/!dtor
    
endif
filename = filename(0)
sza = fltarr(nlons,nlats)+9000.
len = strpos(filename,'t')+1
date = strmid(filename,len,6)
time = strmid(filename,len+7,6)

cyear = strmid(date,0,2)
cmon = strmid(date,2,2)
cday = strmid(date,4,2)
chour = strmid(time,0,2)
cmin = strmid(time,2,2)
csec = strmid(time,4,2)

if fix(cyear) lt 50 then cyear = tostr(2000+fix(cyear)) else cyear = tostr(1900+fix(cyear))
strdate = cyear+'-'+cmon+'-'+cday
uttime = fix(csec)+fix(cmin)*60+fix(chour)*3600

lowdayavg = fltarr(nvars,nalts)
for ilon = 2, nlons - 3 do begin
    for ilat = 2, nlats - 3 do begin
        lon = data(0,ilon,0,0)/!dtor
        if lon gt 360.0 then lon = lon - 360
        lat = data(1,0,ilat,0)/!dtor
        
        zsun,strdate,uttime ,lat,lon, zenith,azimuth,solfac
        sza(ilon,ilat) = zenith
    endfor
endfor


locs = where(sza le 65.0 and sza ge 55.0)

for ialt = 0, nalts - 1 do begin
    for ivar = 0, nvars - 1 do begin
        temp = reform(data(ivar,*,*,ialt))
        lowdayavg(ivar,ialt) = mean(temp(locs))
    endfor
endfor

vars(nstable+2) = 'N!U+!N+N!D2!N'

setdevice,'chemical.ps','p',5,.95
ppp = 4
space = 0.1
pos_space, ppp, space, sizes
get_position, ppp, space, sizes, 0, pos0, /rect
get_position, ppp, space, sizes, 2, pos2, /rect
pos0(2) = pos0(2) + .2
pos2(2) = pos2(2) + .2

symbols = [0,0,0,0,0,-1,-2,-4,-5,-6,-7,-8,-8,-8]
lines = [0,1,2,3,5,0,0,0,0,0,0,0,0,0]
plot, alts,/nodata,yrange = [100,450],pos=pos0, xrange=[1e7,1e11],/xlog,$
  ytitle = 'Altitude (km)',charsize = 1.3,symsize=.5,ystyle=1,$
  xtitle='Energy Loss (Stable) (ev m!U-3!N sec!U-1!N)',/noerase
for ireac = 0, nStable - 1 do begin
    ivar = ireac + 3
    if ireac ge 11 then psymbol = sym(1+ireac-11)
    oplot, lowdayavg(ivar,*),alts,psym=symbols(ireac),$
      linestyle=lines(ireac)
endfor
oplot,total(lowdayavg(3:nstable+2,*),1),alts,thick = 4
temp = sym(1)
legend,vars(3:nStable),linestyle=lines(0:11),psym=symbols(0:11),pos = [pos0(2)+.05,pos0(3)],/norm,box=0
temp = sym(2)
legend,vars(nStable+1),linestyle=lines(12),psym=-8,pos = [pos0(2)+.05,pos0(3)-.22],/norm,box=0
temp = sym(3)
legend,vars(nStable+2),linestyle=lines(12),psym=-8,pos = [pos0(2)+.05,pos0(3)-.24],/norm,box=0
legend,'Total',linestyle=0,pos = [pos0(2)+.05,pos0(3)-.26],/norm,box=0,  thick=4


plot, alts,/nodata,xrange=[1e7,1e11],yrange = [100,450],ystyle=1,/xlog,pos=pos2, $
  ytitle = 'Altitude (km)', xtitle='Energy Loss Rate (Metastable) (ev m!U-3!N sec!U-1!N)',$
  charsize = 1.3,/noerase
for ireac = 0, nMeta - 1 do begin
    ivar = ireac + 17
;    if ireac ge 11 then psymbol = sym(1+ireac-11)
    oplot, lowdayavg(ivar,*),alts,psym=symbols(ireac),$
      linestyle=lines(ireac)
endfor
oplot,total(lowdayavg(3+nstable:nstable+nmeta+3,*),1),alts,thick = 4
temp = sym(1)
legend,vars(3+nStable:nstable+nmeta+3), $
  linestyle=lines(0:nmeta),psym=symbols(0:nmeta),pos = [pos2(2)+.05,pos2(3)],/norm,box=0
;temp = sym(2)
;legend,vars(nStable+1),linestyle=lines(12),psym=-8,pos = [pos0(2)+.05,pos0(3)-.22],/norm,box=0
;temp = sym(3)
;legend,vars(nStable+1),linestyle=lines(12),psym=-8,pos = [pos0(2)+.05,pos0(3)-.24],/norm,box=0
legend,'Total',linestyle=0,pos = [pos2(2)+.05,pos2(3)-.22],/norm,box=0,  thick=4


closedevice

setdevice,'chemtot.ps','p',5,.95
ppp = 4
space = 0.1
pos_space, ppp, space, sizes
get_position, ppp, space, sizes, 0, pos0, /rect
pos0(2) = pos0(2) + .2
plot, alts,/nodata,xrange=[1e8,1e12],yrange = [100,450],ystyle=1,/xlog,pos=pos0, $
  ytitle = 'Altitude (km)', xtitle='Energy Loss Rate (ev m!U-3!N sec!U-1!N)',$
  charsize = 1.3,/noerase
oplot,total(lowdayavg(3:nstable+2,*),1),alts,thick = 2,linestyle=3
oplot,total(lowdayavg(3+nstable:nstable+nmeta+3,*),1),alts,thick = 2,linestyle=4
oplot,total(lowdayavg(3:nstable+nmeta+3,*),1),alts,thick = 2,linestyle=2
oplot,lowdayavg(nvars-1,*),alts,thick=4

legend,['Chem Heating Total','Output Total','Stable','Metastable'],linestyle=[0,2,3,4],pos = [pos0(2)+.05,pos0(3)],/norm,box=0  
closedevice

end
