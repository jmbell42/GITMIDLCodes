nkplevs = 4
reread = 1
alt = 300

if n_elements(directory) eq 0 then directory ='.'
directory = ask('which gitm directory to plot: ',directory)

filelist = file_search(directory+'/*.bin')
nfiles_new = n_elements(filelist)
if n_elements(nfiles) eq 0 then nfiles = 0

if nfiles_new eq nfiles then reread = 0

if not reread then begin
    reread = 'n'
    reread = ask('whether to reread files: ',reread)
    if strpos(reread,'y') ge 0 then reread = 1 else reread = 0
endif
Vars = ['[e-]','NmF2','HmF2','Te','Ti']
if reread then begin
    thermo_readsat, filelist, data_n, time, nTimes, Vars_temp, nAlts, nSats, nFiles

    iv = where(Vars_temp eq Vars(0))
    ivars = [iv,iv+1,iv+2]

    data = fltarr(n_elements(vars),ntimes)
    nmf2 = fltarr(ntimes)
    hmf2 = fltarr(ntimes)
    e = fltarr(ntimes)
    te = fltarr(ntimes)
    ti = fltarr(ntimes)
    alts = reform(data_n(0,0,2,*))/1000.
    f2min = min(where(alts ge 200.0))
    
    itimearr = intarr(6,ntimes)
    kp = strarr(ntimes)
    kplev = intarr(ntimes)
    for itime = 0L, ntimes - 1 do begin
        c_r_to_a,ta,time(itime)
        itimearr(*,itime) = ta
        nmf2(itime) = max(data_n(0,itime,32,f2min:nalts-3),imax)
        hmf2(itime) = data_n(0,itime,2,imax+f2min)/1000.

        kp(itime) = get_kpvalue(itimearr(*,itime))
        
        
        case strtrim(kp(itime),2) of
            '0-': kplev(itime) = 1
            '0' : kplev(itime) = 1
            '0+': kplev(itime) = 1
            '1-': kplev(itime) = 1
            '1' : kplev(itime) = 2
            '1+': kplev(itime) = 2
            '2-': kplev(itime) = 2
            '2' : kplev(itime) = 3
            '2+': kplev(itime) = 3
            '3-': kplev(itime) = 3
            else:  kplev(itime) = 4
            
        endcase 
    endfor

    temp = min(abs(alts - alt),r)
    if r lt alt then r_l = r else r_l = r - 1
    r_h = r_l + 1
    
    a_d = alts(r_h) - alts(r_l)
    a_m = alts(r_h) - alt
    
    data(0,0:ntimes-1) = data_n(0,*,ivars(0),r_h) - $
      (((data_n(0,*,ivars(0),r_h) - data_n(0,*,ivars(0),r_l)) * a_m) /  a_d)
    
    data(1,0:ntimes-1) = nmf2
    
    data(2,0:ntimes-1) = hmf2
    
    data(3,0:ntimes-1) = data_n(0,*,ivars(1),r_h) - $
      (((data_n(0,*,ivars(1),r_h) - data_n(0,*,ivars(1),r_l)) * a_m) /  a_d)
    
    data(4,0:ntimes-1) = data_n(0,*,ivars(2),r_h) - $
      (((data_n(0,*,ivars(2),r_h) - data_n(0,*,ivars(2),r_l)) * a_m) /  a_d)
endif

rdata = fltarr(ntimes,n_elements(vars))
if useradar then begin

endif 

stime = time(0)
etime = max(time)

c_r_to_a,istime,stime
c_r_to_a,ietime,etime


display, vars
if n_elements(pvar) eq 0 then pvar = 0
pvar = fix(ask('which variable to plot: ',tostr(pvar)))

setdevice, 'plot.ps', 'p',5,.95
ppp = 4
space = 0.1
pos_space, ppp, space, sizes,ny=ppp




values = reform(data(pvar,*))
rvalues = reform(rdata(*,pvar)) 


locs = where(kplev) eq 1
dt = time(1) - time(0)
nints = 24*3600./dt
ndays = itimearr(2,ntimes-1) - itimearr(2,0) + 1

gitmavg = fltarr(nints,nkplevs)
gitmstd = fltarr(nints,nkplevs)
rtime = fltarr(nints)
by = itimearr(0,0)
bm = itimearr(1,0)
bd = itimearr(2,0)
beginta = [by,bm,bd,0,0,0]
c_a_to_r,beginta,brt

for iint = 0, nints - 1 do begin
    secofday = iint*dt
    
    begintr = brt + secofday
    ltlocs = where(fix((time-begintr)/86400.) eq (time-begintr)/86400.)
    rtime(iint) = begintr    
    for ilev = 1, nkplevs do begin
        kplocs = where(kplev(ltlocs) eq ilev)
        if kplocs(0) gt -1 then begin
            gitmavg(iint,ilev-1) = mean(values(ltlocs(kplocs)))
            gitmstd(iint,ilev-1) = stddev(values(ltlocs(kplocs)))

        endif
    endfor
endfor


if pvar eq 0 or pvar eq 1 or pvar eq 2 then begin 
    plotradar = 'y'
    plotradar = ask("if you would like to plot the radar data also: ",plotradar)
    
    if plotradar eq 'y' then begin
        radardir = '/ifs1/Gitm/Radars/'
        radars = file_search(radardir+'*')
        display,radars
        close,5
        if n_elements(iradarfile) eq 0 then iradarfile = 0
        iradarfile = fix(ask("radar file to plot: ",tostr(iradarfile)))
        
        radarfile = file_search(radars(iradarfile)+'/*.txt')
        if n_elements(radarfile) gt 0 then radarfile = radarfile(0)
        
        temp = ' '
        openr, 5, radarfile
        nmax = 20000
        radtime = intarr(6,nMax)
        radrtime = fltarr(nMax)
        raddata = fltarr(2,nMax)
        seasons = strarr(nMax)
        itime = 0
        while not eof(5) do begin
            readf, 5, temp
            arr = strsplit(temp,/extract)
            year = fix(arr(0))
            doy = fix(arr(1))
            
            if doy gt 365 then begin
                doy = doy - 365
                year = year + 1
            endif
            ut = float(arr(2))
            hour = fix(ut)
            min = fix((ut - hour)*60.0)
            sec = fix((((ut - hour)*60.0)-min)*60.0)
            
            if year lt 2000 then year = 2000 + year
            
            date = fromjday(year,doy)
            
            c_a_to_r,[year,date(0),date(1),hour,min,sec], rt
            radtime(*,itime) = [year,date(0),date(1),hour,min,sec]
            radrtime(itime) = rt
            
            raddata(0,itime) = arr(3)
            raddata(1,itime) = arr(4)
            seasons(itime) = season(doy)
            
            itime = itime + 1
        endwhile
        
        radtime = reform(radtime(*,0:itime-1))
        radrtime = reform(radrtime(0:itime-1))
        raddata = reform(raddata(*,0:itime-1))

  
        sloc = min(where(radrtime ge stime))
        eloc = max(where(radrtime le etime))
        
        radardata = reform(raddata(*,sloc:eloc))
        radarrtime = reform(radrtime(sloc:eloc))
        radartime = reform(radtime(*,sloc:eloc))
        
        radavg = fltarr(2,nints)
        radstd = fltarr(2,nints)
        radt = fltarr(nints)
        
        for itime = 0, nints - 1 do begin
            
            hour = itimearr(3,itime)
            mins = itimearr(4,itime)
            lmin = mins - 7
            hmin = mins + 7
            
            if lmin lt 0 then lmin = 0
            if hmin gt 60 then hmin = 60
            
            radhours = where(radtime(3,*) eq hour)
            radmins = where(radtime(4,radhours) ge lmin and radtime(4,radhours) le hmin)
            
            radts = reform(radtime(*,radhours(radmins)))
            for ivar = 0, 1 do begin
                radavg(ivar,itime) = mean(raddata(ivar,radhours(radmins)))
                radstd(ivar,itime) = stddev(raddata(ivar,radhours(radmins)))
            endfor
            
            c_a_to_r,[radtime(0),radtime(1),radtime(2),hour,mins,0],rt
            radt(itime) = rt
            
        endfor
    endif
endif else begin
    plotradar = 'n'
endelse



time_axis,brt , max(rtime),btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
xrange = [0,max(rtime)-stime]

yrange = mm(gitmavg)

get_position, ppp, space, sizes, 0, pos, /rect
pos(0) = pos(0)+.05
pos(2) = pos(2)+.05
;pos(3) = pos(3) - .1

plot, [0,etime-stime],/nodata,xrange = xrange,yrange = yrange, ystyle = 1, $
   ytitle = ytitle, xticks=xtickn, xtickv=xtickv,xminor = xminor, $
  xtickname = strarr(10) + ' ', pos = pos,charsize = 1.3,/noerase

loadct,39
oplot, rtime-stime,gitmavg(*,0),thick=3,color = 0
loadct,0
errplot,rtime-stime,gitmavg(*,0)-gitmstd(*,0),gitmavg(*,0)+gitmstd(*,0),color=120

if plotradar then begin
    loadct,39
    oplot,rtime-stime,radavg(pvar,*),thick=3,color = 254
    loadct,0
    errplot,rtime-stime,radavg(pvar,*)-radstd(pvar,*),radavg(pvar,*)+radstd(pvar,*),color=120
endif



get_position, ppp, space, sizes, 1, pos, /rect
pos(0) = pos(0)+.05
pos(2) = pos(2)+.05

plot, [0,etime-stime],/nodata,xrange = xrange,yrange = yrange, ystyle = 1, $
 ytitle = ytitle, xticks=xtickn, xtickv=xtickv,xminor = xminor, $
  xtickname = strarr(10) + ' ', pos = pos,charsize = 1.3,/noerase

loadct,39
oplot, rtime-stime,gitmavg(*,1),thick=3,color = 0
loadct,0
errplot,rtime-stime,gitmavg(*,1)-gitmstd(*,1),gitmavg(*,1)+gitmstd(*,1),color=120

if plotradar then begin
    loadct,39
    oplot,rtime-stime,radavg(pvar,*),thick=3,color = 254
    loadct,0
    errplot,rtime-stime,radavg(pvar,*)-radstd(pvar,*),radavg(pvar,*)+radstd(pvar,*),color=120
endif




get_position, ppp, space, sizes, 2, pos, /rect
pos(0) = pos(0)+.05
pos(2) = pos(2)+.05

plot, [0,etime-stime],/nodata,xrange = xrange,yrange = yrange, ystyle = 1, $
 ytitle = ytitle, xticks=xtickn, xtickv=xtickv,xminor = xminor, $
  xtickname = strarr(10) + ' ', pos = pos,charsize = 1.3,/noerase

loadct,39
oplot, rtime-stime,gitmavg(*,2),thick=3,color = 0
loadct,0
errplot,rtime-stime,gitmavg(*,2)-gitmstd(*,2),gitmavg(*,2)+gitmstd(*,2),color=120

if plotradar then begin
    loadct,39
    oplot,rtime-stime,radavg(pvar,*),thick=3,color = 254
    loadct,0
    errplot,rtime-stime,radavg(pvar,*)-radstd(pvar,*),radavg(pvar,*)+radstd(pvar,*),color=120
endif




get_position, ppp, space, sizes, 3, pos, /rect
pos(0) = pos(0)+.05
pos(2) = pos(2)+.05

plot, [0,etime-stime],/nodata,xrange = xrange,yrange = yrange, ystyle = 1, $
  xtitle = xtitle, ytitle = ytitle, xticks=xtickn, xtickv=xtickv,xminor = xminor, $
  xtickname = xtickname, pos = pos,charsize = 1.3,/noerase

loadct,39
oplot, rtime-stime,gitmavg(*,3),thick=3,color = 0
loadct,0
errplot,rtime-stime,gitmavg(*,3)-gitmstd(*,3),gitmavg(*,3)+gitmstd(*,3),color=120

if plotradar then begin
    loadct,39
    oplot,rtime-stime,radavg(pvar,*),thick=3,color = 254
    loadct,0
    errplot,rtime-stime,radavg(pvar,*)-radstd(pvar,*),radavg(pvar,*)+radstd(pvar,*),color=120
endif




;endfor
closedevice




end
