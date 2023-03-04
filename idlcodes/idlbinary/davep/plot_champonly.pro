iyear = 2003
imonth = 10
iday = 28

iyear = tostr(iyear)
imonth = tostr(imonth)
iday = tostr(iday)


reread = 1

if (n_elements(GitmDensity) gt 0) then begin
    answer = ask('whether to re-read data','n')
    if (strpos(mklower(answer),'n') gt -1) then reread = 0
endif

if (reread) then begin
    ntimes = 0
    champdir = '~/CHAMP/data/'+tostr(iyear)+'/'
    date = iyear+'-'+imonth+'-'+iday
    realdate = date_conv(date,'r')

    nChampMax = 50000L
    ChampPosition = fltarr(3,nChampMax)
    ChampTime  = dblarr(nChampMax)
    MassDensity = fltarr(nChampMax)
    cWind = fltarr(nChampMax)
    
    t = ' '
    line = 0L
   
for cday = 0, ndays - 1 do begin
    doy = doy + cday
    champ_file_a = champdir+'Density_3deg_'+yr+'_'+tostr(doy)+'.ascii'
    champ_file_w = champdir+'Wind_3deg_'+yr+'_'+tostr(doy)+'.ascii'
    
    close,/all
    openr,1,champ_file_a
    openr,2,champ_file_w
    readf,1,t
    readf,2,t
    
    while (not eof(1)) do begin
        readf,1,t
        tarr = strsplit(t,/extract)
        year = fix(tarr(0))
        day = fix(tarr(1))
        seconds = float(tarr(2))
        lat =float(tarr(3))
        long = float(tarr(4))
        height = float(tarr(5))
        chlocaltime = float(tarr(6))
        density = float(tarr(7))
        density400 = float(tarr(8))
        density410 =float(tarr(9))
        
        readf,2,t
        tarr = strsplit(t,/extract)
        wind = float(tarr(7)) 
        
        year = 2000. + year
        rdate = year*1000+day
        
        sdate = date_conv(rdate,'s')
        iDay = fix(strmid(sdate,0,2))
        itime = [iYear, iMonth, iDay, 0,0,0]
        c_a_to_r, iTime, BaseTime
        
        ChampTime(line) = seconds+ basetime
        ChampPosition(0,line) = long
        ChampPosition(1,line) = lat
        ChampPosition(2,line) = height
        MassDensity(line) = density
        cWind(line) = wind
        
        line = line + 1
    endwhile
    
    close,1,2
    ntimes = ntimes + line - 1
    
endfor
endif

ChampDensity    = fltarr(nTimes)
ChampAltitude   = fltarr(nTimes)
ChampWind       = fltarr(nTimes)

ChampDensity  = MassDensity(0:ntimes-1)/1.e-12
ChampAltitude = ChampPosition(2,0:ntimes-1)
ChampWind = cWind(0:ntimes-1)

ChampAve = fltarr(nTimes)
 for iTime = 0, nTimes-1 do begin

     loc = where(abs(champtime-champtime(iTime)) lt 45.0*60.0, count)
     if (count gt 0) then begin
         ChampAve(iTime) = mean(ChampDensity(loc))
     endif
     
 endfor


