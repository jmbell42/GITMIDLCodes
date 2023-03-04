
pro labelvalue, btr, etr, mini, maxi, value, title

      v = value
      m = mean(v)
      s = abs(100.0 * stddev(v)/m)

  oplot, [btr,etr], [m,m], linestyle = 2
  
  if (abs(m) lt 10000 and abs(m) gt 0.01) then begin
      ms = strcompress(string(m,format="(f8.2)"),/remove)
  endif else begin
      ms = strcompress(string(m,format="(e10.2)"),/remove)
  endelse

  xyouts, etr+(etr-btr)/25.0, (mini+maxi)/2, ms, $
    orient=270, align=0.5,charsize = 1.2

  xyouts, etr+(etr-btr)/200.0, (mini+maxi)/2, tostr(fix(s))+"%", $
    orient=270,align=0.5,charsize = 1.2

end


GetNewData = 1
fpi = 0

filelist_new = findfile("*.bin")
nfiles_new = n_elements(filelist_new)
if (nfiles_new eq 1) then begin
    filelist_new = findfile("????_*.dat")
    nfiles_new = n_elements(filelist_new)
endif

if n_elements(nfiles) gt 0 then begin
    if (nfiles_new eq nfiles) then default = 'n' else default='y'
    GetNewData = mklower(strmid(ask('whether to reread data',default),0,1))
    if (GetNewData eq 'n') then GetNewData = 0 else GetNewData = 1
endif

if (GetNewData) then begin

    thermo_readsat, filelist_new, data, time, nTimes, Vars, nAlts, nSats, Files
    nFiles = n_elements(filelist_new)

endif

if (nSats eq 1) then begin

    nPts = nTimes

    Alts = reform(data(0,0:nPts-1,2,0:nAlts-1))/1000.0
    Lons = reform(data(0,0:nPts-1,0,0)) * 180.0 / !pi
    Lats = reform(data(0,0:nPts-1,1,0)) * 180.0 / !pi
    localtime = reform(data(0,0:nPts-1,2,0)) 

    t  = reform(data(0,0:nPts-1,5,0:nalts-1))

    MaxValN2 = 1.0e21

    t  = reform(data(0,0:nPts-1,5,0:nalts-1))

    d = Lats - Lats(0)
    stationary = 1

    time2d = dblarr(nPts,nalts)
    for i=0,nPts-1 do time2d(i,*) = time(i)- time(0)

    display, vars
    if (n_elements(iVar) eq 0) then iVar = 3
    nVars = n_elements(Vars)
    iVar = fix(ask('variable to plot',tostr(iVar)))

    if (iVar lt nVars) then value = reform(data(0,0:nPts-1,iVar,0:nalts-1))
; \
;  The line below is the "old" way of doing things
; /

    if (min(value) gt 0) then begin
        if (n_elements(an) eq 0) then an = 'y'
        an = ask('whether you would like variable to be alog10',an)
        if (strpos(mklower(an),'y') eq 0) then begin
            value = alog10(value)
            title = textoidl('Log_{10}') + '(' +vars(ivar)+')'
        endif else title = vars(ivar)
    endif else title = vars(ivar)

    if (stationary and iVar ne nVars) then begin

        if (n_elements(alt1) eq 0) then alt1 = 1000.0 else alt1 = alt1(0)
        if (n_elements(alt2) eq 0) then alt2 = 1400.0 else alt2 = alt2(0)
        alt1 = float(ask('altitude of first cut', string(alt1)))
        alt2 = float(ask('altitude of second cut', string(alt2)))

        d = abs(alt1 - reform(Alts(0,*)))
        loc = where(d eq min(d))
        iAlt1 = loc(0)

        d = abs(alt2 - reform(Alts(0,*)))
        loc = where(d eq min(d))
        iAlt2 = loc(0)

    endif

    setdevice, 'test.eps', 'p', 5, 0.95

    makect, 'all'

    ppp = 8
    space = 0.01
    pos_space, ppp, space, sizes, ny = ppp
    
;; This make the Contour Plot much Bigger (Works well for Titan)

    get_position, ppp, space, sizes, 2.00, pos1, /rect
    get_position, ppp, space, sizes, 7.00, pos2, /rect
    pos = [pos1(0)+0.05,pos2(1), pos1(2)-0.07,pos1(3)]

    mini = min(value)
    maxi = max(value)
    range = (maxi-mini)
    if (range eq 0.0) then range = 1.0
    if (mini lt 0.0 or mini-0.1*range gt 0) then mini = mini - 0.1*range $
    else mini = 0.0
    maxi = maxi + 0.1*range

    mini = float(ask('minimum values for contour',tostrf(mini)))
    maxi = float(ask('maximum values for contour',tostrf(maxi)))

    levels = findgen(31) * (maxi-mini) / 30 + mini

    stime = time(0)
    etime = max(time)
    time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
    xtitle = strmid(xtitle,0,16)

    v = reform(value(*,0:nalts-1))
    l = where(v gt maxi,c)
    if (c gt 0) then v(l) = maxi
    l = where(v lt mini,c)
    if (c gt 0) then v(l) = mini

    contour, v, time2d(*,0:nalts-1), Alts(*,0:nalts-1), $
      /follow, /fill, $
      nlevels = 30, pos = pos, levels = levels, $
      yrange = [min(alts),max(alts)], ystyle = 1, ytitle = 'Altitude (km)', $
      xtickname = xtickname, xtitle = xtitle, xtickv = xtickv, $
      xminor = xminor, xticks = xtickn, xstyle = 1, charsize = 1.5, charthick = 3.0, $
      thick = 4.0, xthick = 4.0, ythick = 4.0

    ; Plot a dashed line on the altitudes where the line plots are going
    ; to be made.

     if (stationary) then begin
         if (iVar ne nVars) then begin
 
             oplot, [time2d(0,0),time2d(nPts-1,0)], $
               [Alts(0,iAlt1),Alts(0,iAlt1)], $
               linestyle = 0, thick = 8.0
 
             oplot, [time2d(0,0),time2d(nPts-1,0)], $
               [Alts(0,iAlt2),Alts(0,iAlt2)], $
               linestyle = 2, thick = 8.0
 
         endif
     endif

    ctpos = pos
    ctpos(0) = pos(2)+0.025
    ctpos(2) = ctpos(0)+0.03
    maxmin = [mini,maxi]
    plotct, 255, ctpos, maxmin, title, /right

; Put the max and min on the plot

    mini_tmp = min(value)
    maxi_tmp = max(value)

    r = (maxi_tmp - mini_tmp)/50.0

;; This Plots Arrows in the ColorBar
    if (mini_tmp gt mini) then begin
        plots, [0.0,1.0], [mini_tmp, mini_tmp], thick = 8
        plots, [1.0,0.6], [mini_tmp, mini_tmp+r], thick = 2
        plots, [1.0,0.6], [mini_tmp, mini_tmp-r], thick = 2
    endif
    if (maxi_tmp lt maxi) then begin
        plots, [0.0,1.0], [maxi_tmp, maxi_tmp], thick = 8
        plots, [1.0,0.6], [maxi_tmp, maxi_tmp+r], thick = 2
        plots, [1.0,0.6], [maxi_tmp, maxi_tmp-r], thick = 2
    endif

;; Plots the Numbers on the ColorBar
    if (abs(mini_tmp) lt 10000.0 and abs(mini_tmp) gt 0.01) then begin
        smin = strcompress(string(mini_tmp, format = '(f10.2)'), /remove)
    endif else begin
        smin = strcompress(string(mini_tmp, format = '(e12.3)'), /remove)
    endelse

    if (mini_tmp gt mini) then $
      xyouts, -0.1, mini_tmp, smin, align = 0.5, charsize = 1.0, orient = 90, $
              charthick = 8.0 

    if (abs(maxi_tmp) lt 10000.0 and abs(maxi_tmp) gt 0.01) then begin
        smax = strcompress(string(maxi_tmp, format = '(f10.2)'), /remove)
    endif else begin
        smax = strcompress(string(maxi_tmp, format = '(e12.3)'), /remove)
    endelse
    if (maxi_tmp lt maxi) then $
      xyouts, -0.1, maxi_tmp, smax, align = 0.5, charsize = 1.0, orient = 90, $
          charthick = 8.0

     get_position, ppp, space, sizes, 0.75, pos1, /rect
     ;pos = [pos1(0)+0.05,pos1(1), pos1(2)-0.07,pos1(3)]
     pos = [pos1(0)+0.05,pos1(1)-0.075, pos1(2)-0.07,pos1(3)]

     value2 = value

     mini = min([value(*, iAlt1),value(*, iAlt2)])
     maxi = max([value(*, iAlt1),value(*, iAlt2)])

     range = maxi-mini
     mini = mini - 0.02*range
     maxi = maxi + 0.02*range

     mini = float(ask('minimum values for alt1',tostrf(mini)))
     maxi = float(ask('maximum values for alt1',tostrf(maxi)))

     plot, time-stime, value(*, iAlt1), ytitle = title, /noerase, $
       xtickname = strarr(10)+' ', xtickv = xtickv, $
       xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
       thick = 4, yrange = [mini,maxi], ystyle = 1, charsize = 1.2, $
       ytickname = ['',' ','',' ','',' ','',' ','',' ','',' ']

     oplot, time-stime, value(*, iAlt2), thick = 4.0, linestyle = 2

    closedevice

endif else begin


endelse

!p.position = -1

end
