PRO    read_champ, champfile, rho, position,time,localtime

openr,55,champfile
t = ' '

nlinesmax = 10000
ChampTime = dblarr(nlinesmax)
ChampLocalTime = fltarr(nlinesmax)
ChampPosition = fltarr(3,nlinesmax)
MassDensity = fltarr(nlinesmax)

line = 0
started = 0
while (not eof(55)) do begin

    while not started do begin
        readf,55,t
        if strpos(t,'Two-digit') ge 0 then started = 1
     endwhile

    readf,55,t
stop
    tarr = strsplit(t,/extract)
    year = fix(tarr(0))
    day = fix(tarr(1))
    seconds = float(tarr(2))
    lat =float(tarr(4))
    long = float(tarr(5))
    height = float(tarr(6))
    chlocaltime = float(tarr(7))
    density = float(tarr(11))
    density400 = float(tarr(12))
    density410 =float(tarr(13))

    fyear = 2000.+year
    iyear = 2000 + year

    rdate = fyear*1000.+day

    sdate = date_conv(rdate,'F')
    iMonth = fix(strmid(sdate,5,2))
    iDay = fix(strmid(sdate,8,2))
    itime = [Year, iMonth, iDay, 0,0,0]
    c_a_to_r, iTime, BaseTime
    
    ChampTime(line) = seconds+ basetime
    ChampPosition(0,line) = long
    ChampPosition(1,line) = lat
    ChampPosition(2,line) = height
    MassDensity(line) = density
    ChampLocalTime(line) = chlocaltime
    line = line + 1
endwhile

close,55
ntimes =  line - 1

rho  = MassDensity(0:ntimes-1)
position = ChampPosition(*,0:ntimes-1)
time = ChampTime(0:nTimes-1)
localtime = ChampLocalTime(0:nTimes-1)

end
