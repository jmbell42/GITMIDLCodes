filelist = file_search('1DTHM*.bin')
nfilesnew = n_elements(filelist)

if nfilesnew gt 0 then begin
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

rateloc = fltarr(nvars)

for ivar = 0, nvars - 1 do begin
    if strpos(vars(ivar),'ProductionRate') ge 0 then rateloc(ivar) = ivar
endfor
rates = where(rateloc gt 0)
nrates = n_elements(rates)

display, vars(rates)
if n_elements(pvar) eq 0 then pvar = 0
pvar = fix(ask('which rate to plot: ',tostr(pvar)))

varP = pvar + 11
varL = varP + nrates

ppp = 4
space = 0.1
pos_space, ppp, space, sizes
get_position, ppp, space, sizes, 0, pos0, /rect
get_position, ppp, space, sizes, 2, pos2, /rect
pos0(2) = pos0(2) + .1
pos2(2) = pos2(2) + .1

dataP = reform(data(varP,0,0,2:nalts-3))
dataL = reform(data(varL,0,0,2:nalts-3))*(-1)
xrange = mm([dataP,dataL])
yrange = [100,300]

l2 = strpos(vars(varP),'Rate') + 4
Species = strmid(vars(varP),l2)
setdevice,'plot.ps','p',5,.95

plot,datap,alts,xrange=xrange,xtitle = 'Production and Loss Rates '+Species,ytitle = 'Altitude', $
  pos = pos0,yrange = yrange,/noerase

oplot,dataL,alts

xrange = mm(datap+datal)
plot,datap+dataL,alts,xrange=xrange,xtitle = 'Total Production Rate '+ Species, $
  ytitle = 'Altitude', $
  pos = pos2,yrange=yrange,/noerase
closedevice

end
