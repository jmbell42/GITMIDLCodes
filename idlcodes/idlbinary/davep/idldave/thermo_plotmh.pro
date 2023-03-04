GetNewData = 1

filelist_new = findfile("mh*.dat")
nfiles_new = n_elements(filelist_new)

if n_elements(nfiles) gt 0 then begin
    if (nfiles_new eq nfiles) then default = 'n' else default='y'
    GetNewData = mklower(strmid(ask('whether to reread data',default),0,1))
    if (GetNewData eq 'n') then GetNewData = 0 else GetNewData = 1
endif

if (GetNewData) then begin
    readmh, filelist_new, data, mhrtime, n_alts,datasize
endif

nFiles = n_elements(filelist_new)


stime = mhrtime(0)
etime = mhrtime(n_elements(mhrtime)-1)
;sarr = [2003,10,29,0,0,0]
;earr = [2003,11,1,0,0,0]
;c_a_to_r,sarr,stime
;c_a_to_r,earr,etime
   
    time_axis,  stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
    newtime = fltarr(n_alts,datasize)
    for i = 0, datasize - 1 do begin
        for j = 0, n_alts - 1 do begin
            newtime(j,i) = mhrtime(i)
        endfor
    endfor
    loc = where(data.VAR eq data.VAR and data.VAR gt 0)
    vararray = data.VAR
    altarray = data.ALTS
    
        maxi = max(vararray(loc))
        mini = min(vararray(loc))
      ;  maxi = 2500
      ;  mini = 500
    
    loadct, 39    
   setdevice,'plot.ps','l',5,.95
    levels = findgen(31) * (maxi-mini) / 30 + mini
    pos = [.1,.1,.9,.9]
    contour, vararray(loc),newtime(loc)-stime,altarray(loc),/irr,/fill, $
      nlevels = 30, pos = pos,levels = levels,xrange = [stime-stime,etime-stime],  $
      yrange = [0,500], ystyle = 1, ytitle = 'Altitude (km)', $
      xtickname = xtickname, xtitle = xtitle, xtickv = xtickv, $
      xminor = xminor, xticks = xtickn, xstyle = 1, charsize = 1.2,$
      title='Data from Millstone Hill'

; xminor = xminor,xtickname=xtickname,xticks=xtickn,$
;      xstyle = 1, charsize = 1.2,pos=pos,yrange = [0,500],
    
    title = 'log10 electron density'
    ctpos = pos
    ctpos(0) = pos(2)+0.025
    ctpos(2) = ctpos(0)+0.03
    maxmin = [mini,maxi]
    plotct, 255, ctpos, maxmin, title, /right
    closedevice



end
