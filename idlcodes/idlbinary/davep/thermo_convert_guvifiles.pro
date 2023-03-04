if n_elements(sitime) eq 0 then sitime = [2003,10,28,0, 0, 0] 
sitime = fix(strsplit(ask('date to convert: ', strjoin(tostr(sitime),' ')),/extract))
c_a_to_r,sitime,stime
etime = stime + 3600.*24
bdoy = jday(sitime(0),sitime(1),sitime(2))

naltsmax = 100
nscansmax = 5000
altitude = fltarr(naltsmax,nscansmax)
rtime = dblarr(nscansmax)
day = intarr(nscansmax)
sza = fltarr(nscansmax)
lat = sza
lon=sza
iscan = 0
maxscans = 0
maxalts = 0
cyear = tostr(sitime(0))
cdoy = tostr(bdoy)

cmonth = tostr(sitime(1))
cdt = fromjday(fix(cyear),fix(cdoy))
cday = tostr(cdt(1))
guvidir = '~/GUVI/'+strjoin([strmid(cyear,2,2),chopr('0'+cmonth,2),chopr('0'+cday,2)])+'/'

filelist = file_search(guvidir+'*_'+cyear+chopr('00'+cdoy,3)+'*.sav')
nfiles = n_elements(filelist)

satfile = 'guvi'+cyear+chopr('0'+cmonth,2)+chopr('0'+cday,2)+'.dat'
close,1
openw,1,satfile
printf,1,'#START'

for ifile = 0, nfiles - 1 do begin
    restore, filelist(ifile)

    nscans = n_elements(ndpsorbit.sec)
    nalts = n_elements(ndpsorbit(0).zm)
    if nalts gt maxalts then maxalts = nalts
    if nscans gt maxscans then maxscans = nscans

    for is = iscan, nscans + iscan - 1 do begin
        altitude(0:nalts-1,is) = ndpsorbit(is-iscan).zm
       
        tt = fromjday(fix(cyear),ndpsorbit(is-iscan).iyd)
        month = tt(0)
        day = tt(1)
        hour = fix(ndpsorbit(is-iscan).sec/3600.)
        min = fix((ndpsorbit(is-iscan).sec/3600. - hour)*60)
        sec = fix((((ndpsorbit(is-iscan).sec/3600. -hour)*60)-min)*60)
        itime = [fix(cyear),month,day,hour,min,sec]
        
        c_a_to_r,itime,rt
        rtime(is) = rt
        sza(is) = ndpsorbit(is-iscan).sza
        lat(is) = ndpsorbit(is-iscan).glat
        lon(is) = ndpsorbit(is-iscan).glong
        alt = 200.0
        if lon(is) lt 0 then lon(is) = 360 + lon(is)
        
        if rtime(is) ge stime and rtime(is) le etime then $
          printf,1,cyear,month,day,hour,min,sec,0,lon(is),lat(is),alt,format='(7I,3F12.2)'

    endfor
    iscan = is
endfor



close,1

end
