PRO    read_ace, acefile, SWtime, SWdensity, SWvelocity

openr,55,acefile
t = ' '

nlinesmax = 100
Density = fltarr(nlinesmax)
Velocity = fltarr(nlinesmax)
Time = fltarr(nlinesmax)

line = 0
started = 0
while (not eof(55)) do begin

    while not started do begin
        readf,55,t
        if strpos(t,'#START') ge 0 then started = 1
     endwhile

    readf,55,t
    tarr = strsplit(t,/extract)
    n = n_elements(tarr)
    if n eq 15 then begin
       year = fix(tarr(0))
       month = fix(tarr(1))
       day = fix(tarr(2))
       hour = fix(tarr(3))
       minute = fix(tarr(4))
       second = float(tarr(5))
       milli = float(tarr(6))
       magx = float(tarr(7))
       magy = float(tarr(8))
       magz = float(tarr(9))
       velx = float(tarr(10))
       vely = float(tarr(11))
       velz = float(tarr(12))
       dens = float(tarr(13))
       temp = float(tarr(14))
       
       atime = [year,month,day,hour,0,0]
       c_a_to_r,atime,rtime

       tempvel = velx*velx+vely*vely+velz*velz
       vel = SQRT(tempvel)

       Time(line) = rtime
       Density(line) = dens
       Velocity(line) = vel
    endif
    line = line + 1
endwhile

close,55
ntimes =  line - 1

SWtime = Time(0:ntimes-1)
SWdensity = Density(0:ntimes-1)
SWvelocity = Velocity(0:nTimes-1)

end
