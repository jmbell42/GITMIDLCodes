PRO read_snoe, year, month, day, noden, lats, lons, alts, ut, norbs, nlats,julday

doy = jday(fix(year),fix(month),fix(day))

nalts = 17
nlats = 37

snoedir = '/Users/dpawlows/SNOE/'+year+'/'
filelist = file_search(snoedir+'*'+year+'_'+chopr('00'+tostr(doy),3)+'_*.ascii')
norbs = n_elements(filelist)

noden = fltarr(norbs,nlats,nalts)
lats = fltarr(norbs,nlats)
lons = fltarr(norbs,nlats)
alts = fltarr(norbs,nalts)
ut = fltarr(norbs,nlats)
julday = intarr(norbs)
meant = fltarr(norbs)
close,1
for iorb = 0, norbs - 1 do begin
    openr, 1, filelist(iorb)
    temp = ' '
    for ialt = 0, nalts - 1 do begin
        readf,1,temp
        arr = strsplit(temp,/extract)
        noden(iorb,*,ialt) = arr(0:36)
        alts(iorb,ialt) = arr(37)
    endfor
    
    
    readf, 1, temp
    arr = strsplit(temp,/extract)
    lats(iorb,*) = float(arr(0:nlats-1))
    lons(iorb,*) = float(arr(nlats+1:2*nlats))
    julday(iorb) = fix(arr(2*nlats+1))
    ut(iorb,*) = float(arr(2*nlats+2:3*nlats+1))
    
    thistime = reform(ut(iorb,*))
    locs = where(thistime ne -999)
    meant(iorb) = mean(thistime)
    close,1
endfor

noden = noden * 100.^3
plotcontour = 0
if plotcontour then begin
    display,meant
    if n_elements(whichtime) eq 0 then whichtime = 0
    whichtime = fix(ask('which time to plot: ', tostr(whichtime)))
   
    setdevice,'plot.ps','l',5,.95
    pos = [.05,.05,.85,.95]
    loadct, 39
    den = reform(noden(whichtime,*,*))
    locs = where(den gt 1)
    minv = min(den(locs),max=maxv)

    levels = findgen(31) * (maxv-minv) / 30 + minv

    contour,den,lats(whichtime,*),alts(whichtime,*),/fill,levels=levels,$
      xrange = mm(lats(whichtime,*)),yrange=mm(alts(whichtime,*)),$
      xstyle = 1, ystyle = 1, xtitle = 'Latitude', ytitle = 'Altitude',$
      title = 'Nitric Oxide Density '+year+'-'+month+'-'+day+':'+chopl(tostrf(meant(whichtime)/3600.),4)+ ' UT Hours',$
      pos = pos,charsize=1.2,/follow
    
    pos(0) = pos(2)+0.025
    pos(2) = pos(0)+0.03
    maxmin = mm(levels)
    title = '[NO] #/m!U3!N'
    plotct,254,pos,maxmin,title,/right,color=color
    closedevice
endif
    


end
