title = 'Solar Mod Conditions'

filelist = findfile('t*.save')

nfiles = n_elements(filelist)

if nfiles gt 1 then begin
    for ifile = 0, nfiles - 1 do begin
        print, ifile,' ', filelist(ifile)
    endfor
    if n_elements(file) eq 0 then file = 0
    file = fix(ask('file number to plot: ',tostr(file)))
endif else begin
    file = 0
endelse

filename = filelist(file)
print, 'Reading file: ', filename

read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
      vars, data, rb, cb, bl_cnt

;;;;;;;;;;;; data = fltarr(nvars, nlo, nla, nalts) ;;;;;;;;;

aveNO = fltarr(nalts)
aveO = fltarr(nalts)
aveEUV = fltarr(nalts)

alt = reform(data(2,*,*,*)) / 1000.0
lat = reform(data(1,*,*,*)) / !dtor
lon = reform(data(0,*,*,*)) / !dtor

iNO = where(vars eq ' NO Cooling')
iO = where(vars eq ' O Cooling')
iEUV = where(vars eq ' EUV Heating')
itempunit = where(vars eq ' TempUnit')

for ialt = 0, nalts - 1 do begin
    aveNO(ialt) = mean(data(iNO,*,*,ialt)*data(itempunit,*,*,ialt))
    aveO(ialt) = mean(data(iO,*,*,ialt)*data(itempunit,*,*,ialt))
    aveEUV(ialt) = mean(data(iEUV,*,*,ialt)*data(itempunit,*,*,ialt))
endfor

ppp = 2
space = 0.1
pos_space, ppp, space, sizes, ny = ppp

get_position, ppp, space, sizes, 0, pos, /rect
pos(0) = pos(0) + 0.1    

setdevice,'plot.ps','p',5,.95
loadct, 39

plot, aveNO,data(2,0,0,*)/1000.,/nodata,xtitle = 'Cooling', $
  ytitle = 'Altitude (m)', charsize = 1.3,pos = pos,/noerase, $
  title = title, xrange = [-15,0]

oplot, aveNO,data(2,0,0,*)/1000., color = 50, thick = 3

oplot, aveO,data(2,0,0,*)/1000.,color = 140, thick = 3

legend,['NO cooling','O cooling'],colors = [50,140],linestyle = [0,0], $
  pos = [.2,.85],/norm

get_position, ppp, space, sizes, 1, pos, /rect
pos(0) = pos(0) + 0.1    

plot, aveEUV,data(2,0,0,*)/1000.,/nodata,xtitle = 'EUV Heating',$
  ytitle = 'Altitude (m)', charsize = 1.3,pos = pos,/noerase,$
  xrange = [0,23]
oplot, aveEUV, data(2,0,0,*)/1000.,color = 230, thick = 3

closedevice

end
