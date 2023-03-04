GetNewData = 'y'

f = findfile("ISR._*.dat")
file = f(0)
nlines_new = file_lines(file) - 45

;Setup an empty array the specifies the altitude bins in 5km bins
;between 100 and 800km
AltBins = intarr((800 - 100)/5)
nAltBins = n_elements(AltBins)
for iAlt = 0, nAltBins - 1 do begin
    AltBins(iAlt) = ((iAlt*5) + 100)
endfor

AltCount = intarr(nAltBins)
if n_elements(nlines) eq 0 then nlines = 0
if nlines_new eq nlines then begin
    GetNewData = 'n'
       GetNewData = ask('whether to reread data',GetNewData)
   ; if (GetNewData eq 'n') then GetNewData = 0 else GetNewData = 1
endif
nlines = nlines_new

if (GetNewData eq 'y') then begin
    print, 'Getting Millstone Data...'  
    read_isrfile, file, data, nVars, Variables, nSatPos, iTimeArr,$
      iError,nDT
    if iError lt 0 then return
endif

ntimes = n_elements(itimearr(0,*))
rtime = fltarr(ntimes)
for itime = 0, ntimes - 1 do begin
    taa = iTimeArr(*,itime)
    c_a_to_r,taa,trr
    rtime(itime) = trr
endfor
stime = rtime(0)
etime = rtime(ntimes-1)

for i = 0, nVars - 1 do begin
    print, i, '   ', Variables(i)
endfor

if n_elements(ivar) eq 0 then ivar = 0
ivar = fix(ask('which variable to plot: ', tostr(ivar)))
ialts = where(Variables eq 'Altitude')
nalts = n_elements(data(0,*,0))
Vals = reform(data(ivar,*,*))

alts = reform(data(ialts,*,*))

newtime = fltarr(nalts,ntimes)
for i = 0, ntimes - 1 do begin
    for j = 0, nalts -1 do begin
        newtime(j,i) = rtime(i)
    endfor
endfor

ploc = where(vals ne 0 and vals eq vals)
if (variables(ivar) eq '[e-]') then begin
    Vals(ploc) = alog10(vals(ploc))
endif

mini = min(vals(ploc)) 
maxi = max(vals(ploc))

time_axis,  stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn

levels = findgen(31) * (maxi-mini) / 30 + mini
pos = [.1,.1,.9,.9]


makect, 'all'
setdevice,'contour.ps','l',5,.95


contour, vals(ploc),newtime(ploc)-stime,alts(ploc),/irr,/fill, $
  levels = levels, pos = pos, nlevels = 30,$
  yrange = [0,600], ystyle = 1, ytitle = 'Altitude (km)', $
  xtickname = xtickname, xtitle = xtitle, xtickv = xtickv, $
  xminor = xminor, xticks = xtickn, xstyle = 1, charsize = 1.2,$
  title='GITM Results at Radar Location'

if variables(ivar) eq '[e-]' then begin
    title = 'log10 electron density'
endif else begin
    title = Variables(ivar)
endelse

ctpos = pos
ctpos(0) = pos(2)+0.025
ctpos(2) = ctpos(0)+0.03
maxmin = [mini,maxi]
plotct, 255, ctpos, maxmin, title, /right
closedevice

end
