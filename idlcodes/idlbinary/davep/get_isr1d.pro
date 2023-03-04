PRO   get_isr1d,gitmdirectory, data,alts,lons,lats,time,vars,nalts,nsats,npts

GetNewData = 1
fpi = 0

gitmfiles = gitmdirectory + 'b0001_*.*ALL'
filelist_new = findfile(gitmfiles)
nfilesgitm_new = n_elements(filelist_new)

if n_elements(ngitmfiles) gt 0 then begin
    if (nfilesgitm_new eq ngitmfiles) then default = 'n' else default='y'
    GetNewData = mklower(strmid(ask('whether to reread data',default),0,1))
    if (GetNewData eq 'n') then GetNewData = 0 else GetNewData = 1
endif

if (GetNewData) then begin

    thermo_readsat, filelist_new, data, time, nTimes, Vars, nAlts, nSats, Files
    ngitmFiles = n_elements(filelist_new)

endif

if (nSats eq 1) then begin

    nPts = nTimes

    Alts = reform(data(0,0:nPts-1,2,0:nalts-1))/1000.0
    Lons = reform(data(0,0:nPts-1,0,0)) * 180.0 / !pi
    Lats = reform(data(0,0:nPts-1,1,0)) * 180.0 / !pi

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

    t  = reform(data(0,0:nPts-1,4,0:nalts-1))

    ; o / n2 stuff
    o  = reform(data(0,0:nPts-1,5,0:nalts-1))
    o2 = reform(data(0,0:nPts-1,6,0:nalts-1))
    n2 = reform(data(0,0:nPts-1,7,0:nalts-1))
    n4s = reform(data(0,0:nPts-1,9,0:nalts-1))
    n = o + n2 + o2 + n4s
    k = 1.3807e-23
    mp = 1.6726e-27
    rho = o*mp*16 + o2*mp*32 + n2*mp*14
    data(0,0:nPts-1,3,0:nalts-1) = rho

    p = n*k*t
    oon  = o/n
    n2on = n2/n
    o2on = o2/n
    non = n4s/n

    oInt = fltarr(nPts)
    n2Int = fltarr(nPts)
    on2ratio = o/n2
    AltInt = fltarr(nPts)

    MaxValN2 = 1.0e21

    for i=0,nPts-1 do begin

        iAlt = nalts-1
        Done = 0
        while (Done eq 0) do begin
            dAlt = (Alts(i,iAlt)-Alts(i,iAlt-1))*1000.0
            n2Mid = (n2(i,iAlt) + n2(i,iAlt-1))/2.0
            oMid  = ( o(i,iAlt) +  o(i,iAlt-1))/2.0
            if (n2Int(i) + n2Mid*dAlt lt MaxValN2) then begin
                n2Int(i) = n2Int(i) + n2Mid*dAlt
                oInt(i)  =  oInt(i) +  oMid*dAlt
                iAlt = iAlt - 1
            endif else begin
                dAlt = (MaxValN2 - n2Int(i)) / n2Mid
                n2Int(i) = n2Int(i) + n2Mid*dAlt
                oInt(i)  =  oInt(i) +  oMid*dAlt
                AltInt(i) = Alts(i,iAlt) - dAlt/1000.0
                Done = 1
            endelse
        endwhile

    endfor

    re = 6372000.0
    r = re + Alts*1000.0
    g = 9.8 * (re/r)^2
    mp = 1.6726e-27
    k = 1.3807e-23
    mo = 16.0 * mp
    mo2 = mo*2.0

    t  = reform(data(0,0:nPts-1,4,0:nalts-1))

    o_scale_est  = k*t / (mo*g) / 1000.0
    o2_scale_est = k*t / (mo2*g) / 1000.0

    o_scale = o
    alogo = alog(o(*,1:nalts-1)/o(*,0:nalts-2))
    mini = 0.1
    loc = where(alogo ge -mini,count)
    if (count gt 0) then alogo(loc) = -mini
    o_scale(*,1:nalts-1) = - (Alts(*,1:nalts-1) - Alts(*,0:nalts-2))/$
      alogo
    o_scale(*,0) = o_scale(*,1)

    o2_scale = o2
    o2_scale(*,1:nalts-1) = -(Alts(*,1:nalts-1) - Alts(*,0:nalts-2))/$
      alog(o2(*,1:nalts-1)/o2(*,0:nalts-2))
    o2_scale(*,0) = o2_scale(*,1)

    d = Lats - Lats(0)
;    if (max(abs(d)) lt 1.0) then stationary = 1 else stationary = 0
    stationary = 1

    time2d = dblarr(nPts,nalts)
    for i=0,nPts-1 do time2d(i,*) = time(i)- time(0)
endif


end
