
   


    filelists = file_search('guvi**.bin', count = nlist)

    thermo_readsat,filelists, data, time, nTimes, Vars, nALts, nSats, Files

    nPts = nTimes

    Alts = reform(data(0,0:nPts-1,2,0:nalts-1))/1000.0
    Lons = reform(data(0,0:nPts-1,0,0)) * 180.0 / !pi
    Lats = reform(data(0,0:nPts-1,1,0)) * 180.0 / !pi
    o  = reform(data(0,0:nPts-1,5,0:nalts-1))
    n2 = reform(data(0,0:nPts-1,7,0:nalts-1)) 


    c_r_to_a, itime, time(0)
    itime(3:5) = 0
    c_a_to_r, itime, basetime
    hour = (time/3600.0 mod 24.0) + fix((time-basetime)/(24.0*3600.0))*24.0
    localtime = (Lons/15.0 + hour) mod 24.0
    
    angle = 23.0 * !dtor * $
      sin((jday(itime(0),itime(1),itime(2)) - jday(itime(0),3,21))*2*!pi/365.0)
    angle = 0
    sza =  acos(sin(angle)*sin(Lats*!dtor) + $
                cos(angle)*cos(Lats*!dtor) * $ 
                cos(!pi*(LocalTime-12.0)/12.0))
    
    gitm_temp = reform(data(0,*,15,*))
    gitm_eden = reform(data(0,*,32,*))
    gitm_lons = reform(data(0,*,0,*))*180.0/!pi
    gitm_alts = reform(data(0,*,2,*))/1000.
    gitm_lats = reform(data(0,*,1,*))*180.0/!pi
    gitm_on2  = o/n2
    gitm_nmf2 = DBLARR(nPts)
    gitm_hmf2 = DBLARR(nPts)
    gitm_tec  = DBLARR(nPts)

    dz        = DBLARR(nAlts)
    sums      = DBLARR(nAlts)

    FOR j=0, nPts-1 DO BEGIN

       gitm_nmf2(j) = max(gitm_eden(j,*),s)
       gitm_hmf2(j) = gitm_alts(j,s)

       FOR k=0, nALts-1 DO BEGIN

         

          IF (k eq 0) THEN BEGIN

             dz(k) = 1.
             sums(k) = gitm_eden(j,k)*dz(k)

          ENDIF ELSE BEGIN
             
             l = k - 1

             dz(k) = gitm_alts(j,k) - gitm_alts(j,l)
             sums(k) = gitm_eden(j,k)*dz(k)

          ENDELSE

       ENDFOR

       gitm_tec(j) = (total(sums))*1000.
       
    ENDFOR


          

;;;;;;;;;GUVI;;;;;;;;;;;;;;;;;;;;;;;;;;


    day = 87 ; change day of year
    RESTORE, 'summary07804_14204.sav'

    year=bs.yy(0)
    yr=strcompress(year,/remove_all)

    index= where( bs.doy eq day AND bs.nmf2 ge 0 AND bs.hmf2 ge 200 , count)

    day=strcompress(day,/remove_all)

        orb_nmf2= bs.nmf2(index)
        orb_hmf2=bs.hmf2(index)
        morb=(bs.orbit(index))
        orb_lat=bs.glat(index)
        orb_time=bs.time(index)/3600000.
        origt=bs.time(index)
        orb_lon=bs.glon(index)
        orb_tec=bs.tec(index)        
        itime=fltarr(6,count)
    

        CALDAT,JULDAY(1,day,year),mon,da
        itime= [year,mon,da,0,0,0]
        c_a_to_r, itime, basetime
        
        result=morb[UNIQ(morb)]
        nresult= n_elements(result)
        ncolur= 256/nresult
        ncolura=indgen(ncolur)*ncolur +10
        mino=min(morb)
         morb=(bs.orbit(index))
         nsort = sort(orb_time)
         orb_time = orb_time(nsort)
         orb_nmf2 = orb_nmf2(nsort)
         orb_hmf2 = orb_hmf2(nsort)
         morb = morb(nsort)
         orb_lon = orb_lon(nsort)
         orb_lat = orb_lat(nsort)
         orb_tec = orb_tec(nsort) 
         origt = origt(nsort)
         loadct,39 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
orb_secs= orb_time*3600.
gitm_secs= hour*3600.


limit =n_elements(orb_time)

FOR p=1, limit-1 DO BEGIN


   IF (orb_secs(p)-orb_secs(p-1)) gt 300. THEN BEGIN

      L= where( gitm_secs gt orb_secs(p-1) AND gitm_secs lt orb_secs(p) , count)
      
      IF count gt 0 THEN BEGIN
          
         gitm_tec(L)=1.*10.^32
         gitm_nmf2(L)=1.*10^32
         gitm_hmf2(L)= 1000.
         gitm_lons(L)=0.
         gitm_lats(L)=0.

      ENDIF
   ENDIF
ENDFOR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




        setdevice,'guvi_orbits_log032704.ps', 'p',5
        !p.charsize = .8
        ppp =4
        space=.01
        pos_space,ppp,space,sizes, ny=ppp


;;;;;;; PLOT 1  ;;;;;;;;;;;;;;;;;;;;;;;;;;

        get_position,ppp,space,sizes,0,pos1,/rect
        pos=pos1
        pos(0)=pos(0)+.07

        Map_set,/Miller,/advance, title='Orbit for Day '+day+' of '+yr,pos=pos,/noerase,mlinestyle=0
        Map_continents
        Map_grid


        oplot,bs.glon(index),bs.glat(index), color=-1


        for i=0, nresult-1 DO BEGIN

            corbs= where( morb eq result(i))
           
            oplot, orb_lon(corbs), orb_lat(corbs), color=ncolura(i),psym=2, symsize=.1

        endfor

        oplot, gitm_lons(*,0), gitm_lats(*,0), psym=2, symsize=.01
        
        !p.position=0


;;;;;;; PLOT 4  ;;;;;;;;;;;;;;;;;;;;;;

        get_position,ppp,space,sizes,3,pos4,/rect
        pos=pos4
        pos(0)=pos(0)+.07

        corbs=0


        plot,[min(orb_time),max(orb_time)],[200.0,max(orb_hmf2)],/nodata, $
              xtitle=' Universal Time (hrs)',ytitle='HFM2 (km)',pos=pos,/noerase, ystyle=1, xstyle=1


              for i=0, nresult-1 DO BEGIN

                  corbs= where( morb eq result(i))
 
                  oplot, orb_time(corbs), (orb_hmf2(corbs)), color=ncolura(i), min_value=200 , $
                         psym=2, symsize=.3

              endfor

          
              oplot, hour,gitm_hmf2, max_value=500., thick=2;, psym=2,symsize=.1
;;;;;;  PLOT 2  ;;;;;;;;;;;;;;;;;;;;;;

        get_position,ppp,space,sizes,1,pos2,/rect
        pos=pos2
        pos(0)=pos(0)+.07


        plot,[min(orb_time),max(orb_time)],[0,$
                (max((orb_tec/.0001/(10.^16))))],/nodata, xstyle=1,ystyle=1,$
                xtickname=strarr(10)+' ',ytitle='TEC',pos=pos,/noerase
              
        
        oplot, hour,( gitm_tec/(10.^16)),thick=2,  max_value=1E4
        corbs=0

        for i=0, nresult-1 DO BEGIN

            corbs= where( morb eq result(i))

            oplot, orb_time(corbs),((orb_tec(corbs))/.0001/(10.^16)), color=ncolura(i), psym=2, symsize=.3


         endfor

     

;;;;;;  PLOT 3 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        !p.position=0


        get_position,ppp,space,sizes,2,pos3,/rect
        pos=pos3
        pos(0)=pos(0)+.07


        plot,[min(orb_time),max(orb_time)],[alog10(min(orb_nmf2/.000001)),alog10(((max(orb_nmf2/.000001))))],/nodata,xstyle=1,ystyle=1, $
                xtickname=strarr(10)+' ',ytitle='LOG[NFM2 (/m3)]', pos=pos,/noerase


        corbs=0

        for i=0, nresult-1 DO BEGIN

            corbs= where( morb eq result(i))

            oplot, orb_time(corbs), alog10(((orb_nmf2(corbs))/.000001)), color=ncolura(i),psym=2, symsize=.3

        endfor


        oplot, hour, alog10(gitm_nmf2),max_value=20, thick=2;,psym=2, symsize=.1
        closedevice




end
