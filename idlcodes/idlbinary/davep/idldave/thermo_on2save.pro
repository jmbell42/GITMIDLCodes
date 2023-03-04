
filelist = findfile("*.on2.save")
north = 1

nfiles = n_elements(filelist)

ff = 0
lf = nfiles-1

for ifile = ff, lf do begin

    file = filelist(iFile)
;    print, file

    yy = fix(strmid(file, 1,2))
    mo = fix(strmid(file, 3,2))
    dd = fix(strmid(file, 5,2))
    hh = fix(strmid(file, 8,2))
    mi = fix(strmid(file,10,2))
    ss = fix(strmid(file,12,2))

    itime = [yy,mo,dd,hh,mi,ss]

    new3dfile = '../t'+chopr('0'+tostr(itime(0)),2) + $
      chopr('0'+tostr(itime(1)),2) + $
      chopr('0'+tostr(itime(2)),2) + '_'+ $
      chopr('0'+tostr(itime(3)),2) + $
      chopr('0'+tostr(itime(4)),2) + '??.3DALL.save'

    new3dfilelist = findfile(new3dfile)
    new3dfile = new3dfilelist(0)

    c_a_to_r, itime, stime
    oldtime = stime-24.0*3600.0
    c_r_to_a, itime, oldtime
    oldfile = 't'+$
      chopr(tostr(itime(0)),2) + $
      chopr('0'+tostr(itime(1)),2) + $
      chopr('0'+tostr(itime(2)),2) + '_'+ $
      chopr('0'+tostr(itime(3)),2) + $
      chopr('0'+tostr(itime(4)),2) + '??.on2.save'

    oldfilelist = findfile(oldfile)
    
    old3dfile = '../t'+chopr(tostr(itime(0)),2) + $
      chopr('0'+tostr(itime(1)),2) + $
      chopr('0'+tostr(itime(2)),2) + '_'+ $
      chopr('0'+tostr(itime(3)),2) + $
      chopr('0'+tostr(itime(4)),2) + '??.3DALL.save'
    old3dfilelist = findfile(old3dfile)
    old3dfile = old3dfilelist(0)

    if (strlen(oldfilelist) gt 0) then begin

        oldfile = oldfilelist(0)
        print, file, "-> ratioed with ",oldfile

        restore, file
        today = newrat

        restore, oldfile
        yesterday = newrat

        p = strpos(file, '.save')
        if (p eq 0) then p = strlen(file)
        on2file = strmid(file,0,p)

        setdevice, 'plots/'+on2file+'.ps','l',5

        nl = 30
        
        levels = 1.0*findgen(nl+1)/nl + 0.25

        utime = hh*3600.0 + mi*60.0 + ss

        makect,'mid'
        ppp = 8
        space = 0.05
        pos_space, ppp, space, sizes, nx=4

        get_position, ppp, space, sizes, 0, pos
        
        move1 = .03
        move2 = .06
        move3 = .04
        movedown = .04
        pos(0) = pos(0)-move1
        pos(2) = pos(2)-move1
        pos(1) = pos(1)-movedown
        pos(3) = pos(3)-movedown
        !p.position = pos

        p0lon = utime/3600.0 * 360.0 / 24.0

        if (north) then map_set, 40, 288, /orthographic, /cont $
        else map_set, 0.0, 180.0-p0lon, /orthographic, /cont

        contour, today, newlon, newlat, $
          /follow, nlevels = nl, /cell_fill, /over, $
          levels = levels

        map_continents
        map_grid, lats = findgen(19)*10-90, glinethick=3
        tstr = tostr(itime(1))+'/'+tostr(itime(2)+1)+'/'+tostr(itime(0))+$
          '   '+tostr(itime(3))+' UT'
        xyouts, (pos(0)+pos(2))/2.0, pos(3)+0.015,tstr , $
           /norm, align=0.5
        plots, 288.52,42,.6,psym=7,thick=3,color = 254

         !p.position = -1

        ;---------------------------------
        get_position, ppp, space, sizes, 1, pos
        pos(0) = pos(0)-move2
        pos(2) = pos(2)-move2
        pos(1) = pos(1)-movedown
        pos(3) = pos(3)-movedown
        !p.position = pos

        p0lon = utime/3600.0 * 360.0 / 24.0

        if (north) then $
          map_set, 40, 288, /orthographic, /cont, /noerase $
        else map_set, 0.0, 180.0-p0lon, /orthographic, /cont, /noerase

        
        !p.position = -1

        contour, yesterday, newlon, newlat, $
          /follow, nlevels = nl, /cell_fill, /over, $
          levels = levels
       
        map_continents
        map_grid, lats = findgen(19)*10-90, glinethick=3
        plots, 288.52,42,.6,psym=7,thick=3,color = 254
        ctpos = pos
        ctpos(0) = pos(2)+0.01
        ctpos(2) = ctpos(0)+0.03

        plotct, 255, ctpos, mm(levels), 'O/N2', /right
       
        tstr = tostr(itime(1))+'/'+tostr(itime(2))+'/'+tostr(itime(0))+$
          '   '+tostr(itime(3))+' UT'
         xyouts, (pos(0)+pos(2))/2.0, pos(3)+0.015,tstr , $
           /norm, align=0.5
        
        ;--------------------------------- RATIO -----------------
        get_position, ppp, space, sizes, 2, pos

        ;r = pos(2)-pos(0)
        pos(0) = pos(0)+move3
        pos(2) = pos(2)+move3
        pos(1) = pos(1)-movedown
        pos(3) = pos(3)-movedown
        !p.position = pos

        p0lon = utime/3600.0 * 360.0 / 24.0

        if (north) then $
          map_set, 40, 288, /orthographic, /cont, /noerase $
        else map_set, 0.0, 180.0-p0lon, /orthographic, /cont, /noerase

        xyouts, (pos(0)+pos(2))/2.0, pos(3)+0.015, '% Difference', $
          /norm, align=0.5
        !p.position = -1

        ratio = (today-yesterday)/yesterday*100.0

        nl = 30
        levels = 20.0*findgen(nl+1)/nl-10.0

        loc = where(ratio gt levels(nl),count)
        if (count gt 0) then ratio(loc) = levels(nl)

        loc = where(ratio lt levels(0),count)
        if (count gt 0) then ratio(loc) = levels(0)

        contour, ratio, newlon, newlat, $
          /follow, nlevels = nl, /cell_fill, /over, $
          levels = levels, title = file
       
        map_continents
        map_grid, lats = findgen(19)*10-90, glinethick=3
        plots, 288.52,42,.6,psym=7,thick=3,color = 254
        ctpos = pos
        ctpos(0) = pos(2)+0.01
        ctpos(2) = ctpos(0)+0.03

        plotct, 255, ctpos, mm(levels), 'ratio', /right



        ;--------- [e-] today -------------------------
        read_thermosphere_file, old3dfile, nvars, nalts, nlats, nlons, $
          vars, olddata, rb, cb, bl_cnt
        read_thermosphere_file, new3dfile, nvars, nalts, nlats, nlons, $
          vars, newdata, rb, cb, bl_cnt

        get_position, ppp, space, sizes, 4, pos
        pos(0) = pos(0)-move1
        pos(2) = pos(2)-move1
        !p.position = pos
        nl = 30
        p0lon = utime/3600.0 * 360.0 / 24.0

        if (north) then map_set, 40, 288, /orthographic, /cont, /noerase $
        else map_set, 0.0, 180.0-p0lon, /orthographic, /cont

        Alt = reform(olddata(2,0,0,1:nalts-2))/1000.
        naltsnew = n_elements(alt)
        for ialt = 0, naltsnew-1 do begin
            if Alt(ialt) lt 300 then altint = ialt
        endfor

        altplot = min([abs(300-alt(altint)),abs(300-alt(altint+1))],whichmin)
        if whichmin eq 0 then ialtplot = altint else ialtplot = altint+1
        

        enew = reform(newdata(19,1:nlons-2,1:nlons-2,ialtplot))
        lat = reform(newdata(1,*,*,0))*180/!pi
        lon = reform(newdata(0,*,*,0))*180/!pi
        newlat = lat(1:nLons-2,1:nLats-2)
        newlon = lon(1:nLons-2,1:nLats-2)
        nLons  = nLons-2
        nLats  = nLats-2
        newlon(0,*)       = 0.0
        newlon(nLons-1,*) = 360.0
        newlat(*,0) = -90.0
        newlat(*,nLats-1) =  90.0
        
        maxi = max(enew)
        mini = min(enew)
        range = (maxi-mini)
        if (range lt 1.0) then range = 30.0
        mini = mini - .1*range
        maxi = maxi + .1*range

        levels = findgen(31) * (maxi-mini)/30. + mini
        
        contour,enew,newlon,newlat,$
          /follow,nlevels=nl,/cell_fill,/over,levels = levels
                
        map_continents
        map_grid, lats = findgen(19)*10-90, glinethick=3
        plots, 288.52,42,.6,psym=7,thick=3,color = 254
;--------- [e-] yesterday  -------------------------
        
        get_position, ppp, space, sizes, 5, pos
        
        pos(0) = pos(0)-move2
        pos(2) = pos(2)-move2
        !p.position = pos
        nl = 30
        p0lon = utime/3600.0 * 360.0 / 24.0

        if (north) then map_set, 40, 288, /orthographic, /cont,/noerase $
        else map_set, 0.0, 180.0-p0lon, /orthographic, /cont

        eold = reform(olddata(19,1:nlons,1:nlons,ialtplot))
       
        contour,eold,newlon,newlat,$
          /follow,nlevels=nl,/cell_fill,/over,levels = levels
        
        map_continents
        map_grid, lats = findgen(19)*10-90, glinethick=3
        plots, 288.52,42,.6,psym=7,thick=3,color = 254
        ctpos = pos
        ctpos(0) = pos(2)+0.01
        ctpos(2) = ctpos(0)+0.03

        plotct, 255, ctpos, mm(levels), '[e-]', /right

;--------- [e-] ratio  -------------------------
        
        get_position, ppp, space, sizes, 6, pos
        
        pos(0) = pos(0)+move3
        pos(2) = pos(2)+move3
        !p.position = pos
        nl = 30
        p0lon = utime/3600.0 * 360.0 / 24.0

        if (north) then map_set, 40, 288, /orthographic, /cont,/noerase $
        else map_set, 0.0, 180.0-p0lon, /orthographic, /cont

        erat = (enew - eold)/eold * 100
        maxi = max(erat)
        mini = min(erat)
        range = (maxi-mini)
        if (range lt 1.0) then range = 30.0
        mini = mini - .1*range
        maxi = maxi + .1*range

        levels = 400.0*findgen(nl+1)/nl-200.0

        loc = where(erat gt levels(nl),count)
        if (count gt 0) then erat(loc) = levels(nl)

        loc = where(erat lt levels(0),count)
        if (count gt 0) then erat(loc) = levels(0)

        contour,erat,newlon,newlat,$
          /follow,nlevels=nl,/cell_fill,/over,levels = levels
        
        map_continents
        map_grid, lats = findgen(19)*10-90, glinethick=3
        plots, 288.52,42,.6,psym=7,thick=3,color = 254
        ctpos = pos
        ctpos(0) = pos(2)+0.01
        ctpos(2) = ctpos(0)+0.03

        plotct, 255, ctpos, mm(levels), 'ratio', /right

    closedevice


    endif

endfor


end
