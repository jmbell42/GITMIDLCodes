close,1
close,6
openr, 1, 'sat_guvi_data_june.dat'
satname = 'guvi'
started = 0
temp = ' '
line = 0
dayeline = -1
daylast = 1
while not eof(1) do begin

    while not started do begin
        readf,1,temp
        if strpos(temp,'#START') ge 0 then begin
            started = 1
            daysline = line + 1
        endif
        line = line + 1
    endwhile
    
    readf,1,temp
    arr = strsplit(temp,/extract)
    year = fix(arr(0))
    mon = fix(arr(1))
    day = fix(arr(2))
    hour = fix(arr(3))
    min = fix(arr(4))
    sec = fix(arr(5))
    msec = fix(arr(6))
    lon = float(arr(7))
    lat = float(arr(8))
    alt = float(arr(9))
    
    if day ne daylast then begin
        dayeline = line
        daysline = line
    endif
    
    daylast = day
    
    if line eq dayeline then close,6
    
    if line eq daysline then begin
        outfile = satname+chopr(tostr(year),4)+chopr('0'+tostr(mon),2)+ $
          chopr('0'+tostr(day),2)+'.dat'
        openw,6,outfile
        printf,6,'#START'
    endif

    printf, 6, temp
     
    line = line + 1

endwhile

close, /all
end