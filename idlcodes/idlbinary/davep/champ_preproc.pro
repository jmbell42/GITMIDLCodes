if n_elements(date) eq 0 then date = ''
date = ask('start date(yyyy-mm-dd): ',date)
if n_elements(ndays) eq 0 then ndays = 0
ndays = fix(ask('number of days: ',tostr(ndays)))

temp = ''
itime = intarr(7)
syear = strmid(date,0,4)
smonth = strmid(date,5,2)
sday = strmid(date,8,2)
cyear = strmid(date,2,2)

sdate = syear+'-'+smonth+'-'+sday
idate = date_conv(sdate,'v')
doy = idate(1)

procfile = '~/CHAMP/champ_'+syear+smonth+sday+'.dat'
openw,2,procfile
printf, 2, '#START'

for iday = 0, ndays - 1 do begin
    doy = doy + iday

    ChampFile = '~/CHAMP/data/'+syear+'/Density_3deg_'+cyear+'_'+tostr(doy)+'.ascii'
    
    idate(1) = doy
    cdate = date_conv(idate,'s')
    cday = cdate(0)

    nlines = file_lines(ChampFile)-1
    
    alt = fltarr(nlines)
    lat = alt
    lon = alt
    rtime = alt
    
    openr, 1, ChampFile
    readf,1,temp
    
    for iline = 0, nlines - 1 do begin
        readf, 1, temp
        t = strsplit(temp,/extract)
        
        rtime(iline) = t(2)
        h = rtime(iline)/3600
        hour = fix(h)
        m =  (h - fix(h)) * 60
        minute = fix(m)
        sec = fix((m - fix(m)) * 60)
        itime = [fix(syear),fix(smonth),fix(cday),hour,minute,sec,0]
        
        lat(iline) = t(3)
        
        lon(iline) = t(4)
        if lon(iline) lt 0 then lon(iline) = 360. + lon(iline)        
        alt(iline) = t(5)
        
        line = [tostr(itime),tostrf(lon(iline)),tostrf(lat(iline)),tostrf(alt(iline))]
        printf, 2, line, format = '(I,I,I,I,I,I,I,F,F,F)'
    endfor

    close,1

endfor

close,2

 
end
