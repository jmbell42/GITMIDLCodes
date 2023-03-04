flarefile = '~/GOES/flares.dat'

if n_elements(ChampDensity) ne 0 then reread = 'n' else reread = 'y'
reread = ask('reread data: ',reread)

nflaresmax = 100
ftimearr = intarr(6,nflaresmax) 
mag = fltarr(nflaresmax)
pmag = fltarr(nflaresmax)
t = ' '
iflare = 0
openr, 1, flarefile
while not eof(1) do begin
    readf,1, t
    temp = strsplit(t,/extract)
    ftimearr(*,iflare)  = temp(0:5)
    mag(iflare) = temp(6)
    pmag(iflare) = temp(7)
    iflare = iflare + 1
endwhile
close, 1

nflares = iflare
mag = mag(0:nflares-1)
pmag = pmag(0:nflares-1)
ftimearr = ftimearr(*,0:nflares-1)

t = ' '

if reread eq 'y' then begin
ntimes = intarr(nflares)
nChampMax = 50000L
ChampPosition = fltarr(nflares,3,nChampMax)
ChampTime  = dblarr(nflares,nChampMax)
MassDensity = fltarr(nflares,nChampMax)
Champ400 = fltarr(nflares,nChampMax)
ChampLocalTime=fltarr(nflares,nChampMax)
ChampZenith=fltarr(nflares,nChampMax)

    for iflare = 0, nflares - 1 do begin
        print, 'Working on date: ', ftimearr(0:2,iflare)
        cyear = tostr(ftimearr(0,iflare))
        cmonth = tostr(ftimearr(1,iflare))
        cday = tostr(ftimearr(2,iflare))
        c_a_to_r, ftimearr(*,iflare),rt
        jd = tostr(julian_day(rt))
        
        if jd lt 10 then jd = '00'+jd
        if jd lt 100 and jd ge 10 then jd = '0'+ jd
        
        champfile = '/data6/Data/CHAMP/'+cyear+'/Density_*_'+jd+'*.ascii'
        openr,1,champfile
        readf,1,t
        readf,1,t
        
        line = 0L  
        
        
        while (not eof(1)) do begin
            readf,1,t
            tarr = strsplit(t,/extract)
            year = fix(tarr(0))
            day = fix(tarr(1))
            seconds = float(tarr(2))
            lat =float(tarr(4))
            long = float(tarr(5))
            height = float(tarr(6))
            chlocaltime = float(tarr(7))
            density = float(tarr(8))
            density400 = float(tarr(9))
            year = 2000. + year
            rdate = year*1000+day
            
            sdate = date_conv(rdate,'s')
            iDay = fix(strmid(sdate,0,2))
            itime = [cYear, cMonth, cDay, 0,0,0]
            c_a_to_r, iTime, BaseTime
            
            ChampTime(iflare,line) = seconds+ basetime
            ChampPosition(iflare,0,line) = long
            ChampPosition(iflare,1,line) = lat
            ChampPosition(iflare,2,line) = height
            MassDensity(iflare,line) = density
            ChampLocalTime(iflare,line) = chlocaltime
            Champ400(iflare,line) = density400

            date = cyear+'-'+cmonth+'-'+cday
            ut = seconds/3600.
            zsun,date,ut,lat,long,zenith,a,s
            ChampZenith(iflare,line) = zenith 
            
            line = line + 1
        endwhile
        
        close,1
        ntimes(iflare) = line
    endfor     

 nmax = max(ntimes)
 ChampTime = ChampTime(*,0:nmax-1)
 ChampPosition = ChampPosition(*,*,0:nmax-1)
 ChampDensity = MassDensity(*,0:nmax-1)/1.0e-12
 Champ400 = Champ400(*,0:nmax-1)/1.0e-12
 ChampLocalTime = ChampLocalTime(*,0:nmax-1)
 ChampZenith = ChampZenith(*,0:nmax-1)
endif

itmin = intarr(nflares)

DayLT = fltarr(nflares)
NightLT = fltarr(nflares)

nplots = 7
frt = fltarr(nflares)
Density = fltarr(nplots,nflares)
Time = fltarr(nplots,nflares)
cosSZA = fltarr(nplots,nflares)
CLT = fltarr(nplots,nflares)
for iflare = 0, nflares - 1 do begin
     cyear = tostr(ftimearr(0,iflare))
     cmonth = tostr(ftimearr(1,iflare))
     cday = tostr(ftimearr(2,iflare))

     dayloc = where(champlocaltime(iflare,0:ntimes(iflare)-1) gt 6.0 and $
                    champlocaltime(iflare,0:ntimes(iflare)-1) lt 18.0)

     nightloc = where(champlocaltime(iflare,0:ntimes(iflare)-1) lt 6.0 or $
                      champlocaltime(iflare,0:ntimes(iflare)-1) gt 18.0)
     
     DayLT(iflare) = mean(champlocaltime(iflare,dayloc))
     NightLT(iflare) = DayLT(iflare) + 12.00
     if NightLT(iflare) gt 24 then NightLT(iflare) = NightLT(iflare) - 24.0
     
     c_a_to_r, ftimearr(*,iflare),rt
     c_a_to_r, [ftimearr(0:2,iflare),0,0,0],rtb
     frt(iflare) = rt
     ut = (rt-rtb) / 3600.
     zsun, cyear+'-'+cmonth+'-'+cday,ut,0,0,z,a,s,lonsun=lonsun,latsun=latsun

     locs = where(champposition(iflare,1,0:ntimes(iflare)-1) lt latsun + 2.0 and $
                  champposition(iflare,1,0:ntimes(iflare)-1) gt latsun - 2.0 and $
                  champlocaltime(iflare,0:ntimes(iflare)-1) gt 6 and $
                  champlocaltime(iflare,0:ntimes(iflare)-1) lt 18)

     tdiff = abs(champtime(iflare,locs) - rt)
     tdmin = min(tdiff,imin)

     itmin(iflare) = locs(imin)
     
     locsnew = locs(0)

     for iloc = 1, n_elements(locs) - 1 do begin
         if locs(iloc) - locs(iloc-1) ne 1 then begin
             locsnew = [locsnew,locs(iloc)]
         endif else begin
             if locs(iloc) eq itmin(iflare) then begin
                 locsnew(n_elements(locsnew)-1) = locs(iloc)
             endif
         endelse
     endfor
         
     isame = where(locsnew eq itmin(iflare))
     
     noff = floor(nplots/2.)
     for itime = -noff, noff do begin
         Density(itime+noff,iflare) = ChampDensity(iflare,locsnew(isame+itime))
         Time(itime+noff,iflare) = ChampTime(iflare,locsnew(isame+itime))
         cossza(itime+noff,iflare) = cos(ChampZenith(iflare,locsnew(isame+itime))*!dtor)
         CLT(itime+noff,iflare) = ChampLocalTime(iflare,locsnew(isame+itime))
     endfor
        
 endfor

setdevice,'plot.ps','p',5,.95

ppp = 6
space = 0.04
pos_space, ppp, space, sizes

for itime = -noff, noff do begin
     get_position, ppp, space, sizes, (itime+noff) mod 6, pos, /rect
     pos(0) = pos(0) + 0.06
     pos(2) = pos(2) - 0.01

     if (itime + noff) mod 6 ne 0 then begin
         plot, (10^mag)/(10^pmag), (Density(itime+noff,*)/cossza(itime+noff,*))/(Density(0,*)/cossza(0,*)), psym = 2, symsize = 2, thick = 3,  $
           pos = pos, /noerase
     endif else begin
         plot, (10^mag)/(10^pmag), (Density(itime+noff,*)/cossza(itime+noff,*))/(Density(0,*)/cossza(0,*)), psym = 2, symsize = 2, thick = 3,  $
           pos = pos
         if itime ne noff then begin
             xyouts, .001, .4,'Density x1.0e12/cos(SZA) normalized (kg m!U-3!N)',/norm,orientation = 90
             xyouts, .4, .001 ,'Normalized Flare Magnitude (log W m!U-2!N)',/norm
         endif
     endelse

;    /SZA(itime+noff,*)/Density(0,*)/SZA(0,*)

     if itime lt 0 then str = tostr(abs(itime)) + ' orbits before max'
     if itime gt 0 then str = tostr(abs(itime)) + ' orbits after max'
     if itime eq 0 then str = 'Orbit of max'
     
     xyouts, pos(0) + .03, pos(1) + .016, str,/norm

 endfor
 xyouts, .001, .4,'Density x1.0e12 (kg m!U-3!N)',/norm,orientation = 90
 xyouts, .4, pos(1) - .05 ,'Flare Magnitude (log W m!U-2!N)',/norm

closedevice

     
setdevice,'flares.ps','p',5,.95
ppp=6
space = 0.01
pos_space, ppp, space, sizes,ny=ppp
loadct, 39

for iflare = 0, nflares -1 do begin
    stime = champtime(iflare,0)
    etime = max(champtime(iflare,*))
    
    time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
    get_position, ppp, space, sizes, iflare mod 6, pos, /rect
    ytitle = strmid(xtitle,0,12)    
    if iflare eq ppp - 1 or iflare eq nflares - 1 then begin
        xtickname = xtickname 
        xtitle = 'Universal Time'
    endif else begin
        xtickname = strarr(10) + ' '
        xtitle = ' '
    endelse
    
    if iflare mod 6 eq 0 then begin
        plotdumb 
    endif 
    xrange = [0,max(champtime(iflare,0:ntimes(iflare)-1))-champtime(iflare,0)]
    yrange = mm([champdensity(iflare,*),champ400(iflare,*)])
    
    plot,champtime(iflare,0:ntimes(iflare)-1)-champtime(iflare,0),$
      champ400(iflare,0:ntimes(iflare)-1),/nodata,pos=pos ,$
      /noerase, xtitle = xtitle, ytitle = ytitle,yrange = yrange,$
      xrange = xrange, xstyle = 1,xtickname=xtickname,xtickv=xtickv,xticks=xtickn,xminor=xminor

    oplot,champtime(iflare,0:ntimes(iflare)-1)-champtime(iflare,0),$
      champ400(iflare,0:ntimes(iflare)-1),color = 254, linestyle=2

    oplot,champtime(iflare,0:ntimes(iflare)-1)-champtime(iflare,0),$
      champdensity(iflare,0:ntimes(iflare)-1)

    oplot, [frt(iflare)-champtime(iflare,0),frt(iflare)-champtime(iflare,0)+1],[0,1000],thick = 3
endfor
closedevice

end
