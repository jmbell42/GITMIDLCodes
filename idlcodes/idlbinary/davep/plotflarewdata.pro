compare = 1

if n_elements(ndirs) eq 0 then ndirs = 1
ndirs = fix(ask('number of save files to plot: ',tostr(ndirs)))
if n_elements(ndirs_old) eq 0 then ndirs_old = 0
if n_elements(sfiles) eq 0 or ndirs ne ndirs_old then sfiles = strarr(ndirs)
for ifile = 0, ndirs - 1 do begin
    sfiles(ifile) = ask('name of save file ' + tostr(ifile+1)$
                        + ': ', sfiles(ifile))
endfor

names = strarr(ndirs)
len = strpos(sfiles,'.',/reverse_search,/reverse_offset)
for ifile = 0, ndirs - 1 do begin
    names(ifile) = strmid(sfiles(ifile),0,len(ifile))
endfor
reread = 1

if n_elements(sfiles_old) eq 0 then sfiles_old = ' '
if ndirs eq ndirs_old and sfiles(0) eq sfiles_old(0) then begin
    reread = 'n'
    reread = ask('whether to re-restore files: ',reread)
    if strpos(reread,'y') ge 0 then reread = 1 else reread = 0
endif

ndirs_old = ndirs
sfiles_old = sfiles
if reread then begin
    for ifile = 0, ndirs - 1 do begin
        print, 'Working on '+ sfiles(ifile)
        restore, sfiles(ifile)
        
        if ifile eq 0 then begin
            pvar = 3
            nfiles = n_elements(alldata(*,0,0,0))
            nvars = n_elements(alldata(0,*,0,0))
            nlons = n_elements(alldata(0,0,*,0))
            nlats = n_elements(alldata(0,0,0,*))
            
            data = fltarr(ndirs,nfiles,nlons-4,nlats-4)
            otherdata = fltarr(ndirs,nfiles,3,nlons-4,nlats-4)
        endif
        data(ifile,*,*,*) = alldata(*,pvar,2:nlons-3,2:nlats-3)
        otherdata(ifile,*,*,*,*) = $
          allother(*,*,2:nlons-3,2:nlats-3)
    endfor
endif

if reread then begin
    if compare then begin
        if n_elements(base) eq 0 then base = ' '
        base = ask('name of base save file: ',base)
        
        restore, base
        
        basedata = reform(alldata(*,pvar,2:nlons-3,2:nlats-3))
        otherbase = allother(*,*,2:nlons-3,2:nlats-3)
        
    endif


maxs = fltarr(ndirs,nfiles)
mins = fltarr(ndirs,nfiles)
maxs_t = fltarr(ndirs,nfiles)
mins_t = fltarr(ndirs,nfiles)
aves = fltarr(ndirs,nfiles)    
aves_t = fltarr(ndirs,nfiles)    

for idir = 0, ndirs - 1 do begin
    for ifile = 0, nfiles - 1 do begin
        
        maxs_t(idir,ifile) = max(data(idir,ifile,*,*),imax)
        mins_t(idir,ifile) = min(data(idir,ifile,*,*),imin)
        aves_t(idir,ifile) = mean(data(idir,ifile,*,*))
        
        if compare then begin
           
            maxs(idir,ifile) = $
              max((data(idir,ifile,*,*) - basedata(ifile,*,*))$
              /basedata(ifile,*,*)*100.0)
            mins(idir,ifile) = $
              min((data(idir,ifile,*,*) - basedata(ifile,*,*))$
              /basedata(ifile,*,*)*100.0)
            aves(idir,ifile) = $
              mean((data(idir,ifile,*,*) - basedata(ifile,*,*))$
              /basedata(ifile,*,*)*100.0)

        endif else begin
            maxs(idir,ifile) = maxs_t(idir,ifile)
            mins(idir,ifile) = mins_t(idir,ifile)
            aves(idir,ifile) = aves_t(idir,ifile)
        endelse    
        
    endfor
endfor
endif

peak = fltarr(3,ndirs)
peakavetime = fltarr(ndirs)
for idir = 0, ndirs - 1 do begin
    peak(1,idir) = max(maxs(idir,*),imax)
    peak(0,idir) = max(aves(idir,*),iave)
    peak(2,idir) = max(mins(idir,*),imin)
    
    peakavetime(idir) = rtime(iave)

endfor

nflares = ndirs
if n_elements(flarefile) eq 0 then flarefile = strarr(nflares)
nfiles = nflares

for iflare = 0, nflares- 1 do begin
    flarefile(iflare) = names(iflare)+'.dat'
    ;ask('flare file '+tostr(iflare+1)+' :',flarefile(iflare))
endfor

nlinesmax = 10000
flux = fltarr(nfiles,59,nlinesmax)
itime = intarr(6,nlinesmax)
srtime = dblarr(nfiles,nlinesmax)
iline = intarr(nfiles)
for iflare = 0, nflares - 1 do begin
    openr, 1, flarefile(iflare)

    started = 0 
    temp = ' '
    t = 0
    while not started do begin
        readf,1,temp
        if strpos(temp,'#START') ge 0 then started = 1

    endwhile
    

    line = fltarr(59+7)
    while not eof(1) do begin
        readf,1,line
        
        itime(*,iline(iflare)) = fix(line(0:5))
        c_a_to_r, itime(*,iline(iflare)),rt
        srtime(iflare,iline(iflare)) = rt

        flux(iflare,*,iline(iflare)) = line(7:*)
        iline(iflare) = iline(iflare) + 1
    endwhile


close,1
endfor
il = max(iline)
flux = flux(*,*,0:il-1)
for i = 0, il - 2 do begin
    for iflare = 0, nflares - 1 do begin
        for iwave = 0, 58 do begin
            
            if flux(iflare,iwave,i) eq 0 then flux(iflare,iwave,i) = flux(iflare,iwave,i-1)
        endfor
    endfor
endfor

itime = itime(*,0:il-1)
srtime = srtime(*,0:il-1)
satime = [2005,09,20,23,0,0]

fluxavepeak = fltarr(ndirs)
fluxavelow = fltarr(ndirs)
fluxavehigh = fltarr(ndirs)
for idir = 0, ndirs - 1 do begin
    maxi = max(where(peakavetime(idir) - srtime(idir,*) ge 0 and srtime(idir,*) gt 1000),imax)
    maxi = max(where(peakavetime(idir) -(7.5*60) - srtime(idir,*) ge 0 and srtime(idir,*) gt 1000),iml)
    maxi = max(where(peakavetime(idir)+(7.5*60) - srtime(idir,*) ge 0 and srtime(idir,*) gt 1000),imh)

    fluxavepeak(idir) = total(flux(idir,56:58,imax),2)
    fluxavelow(idir) = total(flux(idir,56:58,iml),2)
    fluxavehigh(idir) = total(flux(idir,56:58,imh),2)
endfor 


eatime = [2005,09,21,8,0,0]
c_a_to_r,satime,stime
c_a_to_r,eatime,etime



;yrange = mm(alog10(total(flux(*,56:58,*),2)))
;yrange = [-10,-3]

time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
xrange = [0,etime-stime]

;yrange(0) = 10e-7

loadct,39
;plot, rtime(0,*)-stime,/nodata,xrange = xrange,$
;  xtickname = xtickname,xtitle = xtitle, xtickv=xtickv,xticks=xtickn,xminor=xminor,$
;  pos = [.1,.1,.9,.6],ystyle=1,yrange = [-6,-2],xrange=xrange

ppp = 3
space = 0.01
pos_space, ppp, space, sizes,ny=ppp

setdevice, 'plot2.ps','p',5,.95

get_position, ppp, space, sizes, 0, pos1, /rect
pos1(0) = pos1(0) + 0.1
plot, srtime(0,*)-stime,xrange = xrange,$
  xtickname = xtickname,xtitle = xtitle, xtickv=xtickv,xticks=xtickn,xminor=xminor,$
  pos = pos1,ystyle=1,/nodata,yrange = [1e-5,1e-2],xstyle=1,$
  ytitle='Flux (.1-.8 nm)',charsize=1.2,/ylog


colors = findgen(nflares)*254/nflares+254/nflares
for iflare = 0, nflares - 1 do begin
    oplot, srtime(iflare,*)-stime,total(flux(iflare,56:58,0:iline(iflare)-1),2),color = colors(iflare), thick = 3

endfor

legend,names,color=colors,linestyle=fltarr(nflares),box = 0, $
  pos = [pos1(2)-.25,pos1(3)-.03],/norm



for idir = 0, ndirs - 1 do begin
   plots, peakavetime(idir)-stime(0),fluxavepeak(idir),psym=sym(1), $
      color=colors(idir),symsize = 1.3,thick=3
   plots,peakavetime(idir)-(7.5*60)-stime(0),fluxavelow(idir),psym=1, $
      color=colors(idir),symsize = 1.3,thick=3
   plots,peakavetime(idir)+(7.5*60)-stime(0),fluxavehigh(idir),psym=1, $
      color=colors(idir),symsize = 1.3,linestyle = 2,thick=3
endfor

closedevice




end

