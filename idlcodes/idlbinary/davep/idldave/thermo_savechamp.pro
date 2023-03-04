if n_elements(directory) eq 0 then directory = '.'
directory = ask('which directory: ',directory)

filelist = file_search(directory+'/cham*')
nfiles_new = n_elements(filelist)

file = filelist(0)
length = strpos(file,'.bin')
ls = length-13

yr = strmid(file,ls,2)
iYear = tostr(2000+fix(yr))
iMonth = strmid(file,ls+2,2)
iDay = strmid(file,ls+4,2)

champdir = '~/CHAMP/data/'+tostr(iyear)+'/'
date = iyear+'-'+imonth+'-'+iday
realdate = date_conv(date,'r')

doy = strmid(tostr(realdate),4,3)

if n_elements(nfiles) eq 0 then nfiles = -1
if nfiles_new eq nfiles then reread = 'n' else reread = 'y'

if reread eq 'n' then begin
    reread = ask('whether to reread the data:',reread)
    if strpos(reread,'y') gt -1 then reread = 1 else reread = 0
endif

nfiles = nfiles_new
ntimes = nfiles


if reread then begin
    nalts = 0
    nvars = 0
    for i=0L,nFiles-1 do begin
        cFile = filelist(i)
        print, 'Working on ' + cfile + ' ...'
        
        read_thermosphere_file, cFile,nvars_t, nalts_t, nlats_t, nlons_t, $
          vars_t, data_t, nBLKlat_t, nBLKlon_t, nBLK_t
        
        if (i eq 0) then begin
            data_new = fltarr(nFiles, 70, 70)
            time = dblarr(nFiles)
        endif
        
        if nvars_t gt nvars then nvars = nvars_t
        if nalts_t gt nalts then nalts = nalts_t

        data_new(i,0:nvars_t-1,0:nalts_t-1) = data_t(*,0,0,*)
        
        iSP = strpos(cfile,'.bin')-13
        itime = [ $
                  fix(strmid(cfile,iSP   ,2)), $
                  fix(strmid(cfile,iSP+ 2,2)), $
                  fix(strmid(cfile,iSP+ 4,2)), $
                  fix(strmid(cfile,iSP+ 7,2)), $
                  fix(strmid(cfile,iSP+ 9,2)), $
                  fix(strmid(cfile,iSP+11,2))]
        c_a_to_r, itime, rtime
        
        time(i) = rtime
    endfor
endif

data = data_new(*,0:nvars-1,0:nalts-1)
GitmRho  = reform(data(*,3,*))
GitmAlts = reform(data(*,2,*))/1000.
GitmLons = reform(data(*,0,*))
c_r_to_a, itime, time(0)
itime(3:5) = 0
ndays = round((time(ntimes-1)-time(0))/3600. /24.)

c_a_to_r, itime, basetime
hour = (time/3600.0 mod 24.0) + fix((time-basetime)/(24.0*3600.0))*24.0
localtime = (GitmLons/15.0 + hour) mod 24.0
    
ChampDensity    = fltarr(nTimes)
GitmDensity     = fltarr(nTimes)
GitmDensityHigh = fltarr(nTimes)
GitmDensityLow  = fltarr(nTimes)
ChampPosition   = fltarr(3,nTimes)
ChampAltitude   = fltarr(nTimes)
nChampMax = 700000L
ChampPos = fltarr(3,nChampMax)
ChampTime  = dblarr(nChampMax)
MassDensity = fltarr(nChampMax)

t = ' '
line = 0L
for cday = 0, ndays - 1 do begin
    leapyear = isleapyear(yr)
    if leapyear then maxdays = 366 else maxdays = 365

    if doy ge 100 then doy = tostr(doy)
    if doy lt 10 then doy = '00'+tostr(doy)
    if doy ge 10 and doy lt 100 then doy = '0'+tostr(doy)
    
    if fix(doy) gt maxdays then begin
        doy = '001'
        yr = chopr('0'+tostr(fix(yr) + 1),2)
    endif
    
    champ_file_a = champdir+'Density_3deg_'+yr+'_'+doy+'.ascii'
    print, 'Working on ',+champ_file_a

    close,/all
    openr,1,champ_file_a
    readf,1,t
    readf,1,t
    
    while (not eof(1)) do begin
        readf,1,t
        tarr = strsplit(t,/extract)
        year = fix(tarr(0))
        day = fix(tarr(1))
        caldat,day,imonth,day,ty
        seconds = float(tarr(2))
        lat =float(tarr(4))
        long = float(tarr(5))
        height = float(tarr(6))
        chlocaltime = float(tarr(7))
        density = float(tarr(8))
        
        year = 2000. + year
        rdate = year*1000+day
        
        sdate = date_conv(rdate,'s')
        iDay = fix(strmid(sdate,0,2))
        itime = [iYear, iMonth, iDay, 0,0,0]
        c_a_to_r, iTime, BaseTime
        
        ChampTime(line) = seconds+ basetime
        ChampPos(0,line) = long
        ChampPos(1,line) = lat
        ChampPos(2,line) = height
        MassDensity(line) = density
        line = line + 1

    endwhile
    
    close,1,2
    doy = fix(doy) + 1
endfor

for itime = 0L, ntimes - 1 do begin
    
    dt = abs(time(iTime)-ChampTime)
    loc = where(dt eq min(dt))
    
    i = loc(0)
    
    ChampDensity(iTime)  = MassDensity(i)/1.e-12
    ChampPosition(*,iTime) = ChampPos(*,i)
    ChampAltitude(iTime) = ChampPosition(2,itime)
    
    loc = where(GitmAlts(itime,*) gt ChampAltitude(iTime))
    i = loc(0)
    x = (ChampAltitude(iTime) - GitmAlts(itime,i-1)) / $
      (GitmAlts(itime,i) - GitmAlts(itime,i-1))
    GitmDensity(iTime) = exp((1.0 - x) * alog(GitmRho(iTime,i-1)) + $
                             (      x) * alog(GitmRho(iTIme,i)))
endfor

GitmDensity = GitmDensity*1.0e12



stime = time(0)
etime = max(time)

c_r_to_a,istime,stime
c_r_to_a,ietime,etime
st = tostr(istime)
et = tostr(ietime)

savefile = 'Champ'+strmid(st(0),2,2)+chopr('0'+st(1),2)+chopr('0'+st(2),2)+'_'+$
strmid(et(0),2,2)+chopr('0'+et(1),2)+chopr('0'+et(2),2)+'.sav'

save,GitmDensity,ChampDensity,time,champposition,file=savefile
end
