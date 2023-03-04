compare = 1

if n_elements(ndirs) eq 0 then ndirs = 1
ndirs = fix(ask('number of save files to plot: ',tostr(ndirs)))

if n_elements(sfiles) eq 0 then sfiles = strarr(ndirs)
for ifile = 0, ndirs - 1 do begin
    sfiles(ifile) = ask('name of save file ' + tostr(ifile+1)$
                        + ': ', sfiles(ifile))
endfor

reread = 1
if n_elements(ndirs_old) eq 0 then ndirs_old = 0
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

maxs = fltarr(ndirs,nfiles)
mins = fltarr(ndirs,nfiles)
maxs_t = fltarr(ndirs,nfiles)
mins_t = fltarr(ndirs,nfiles)
aves = fltarr(ndirs,nfiles)    
aves_t = fltarr(ndirs,nfiles)    
maxloc = fltarr(ndirs,nfiles)    
minloc = fltarr(ndirs,nfiles)    

if reread then begin
    if compare then begin
        if n_elements(base) eq 0 then base = ' '
        base = ask('name of base file: ',base)
        
        restore, base
        
        basedata = reform(alldata(*,pvar,2:nlons-3,2:nlats-3))
        otherbase = allother(*,*,2:nlons-3,2:nlats-3)
        
    endif
endif

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


peak = fltarr(3,ndirs)

for idir = 0, ndirs - 1 do begin
    peak(1,idir) = max(maxs(idir,*))
    peak(0,idir) = max(aves(idir,*))
    peak(2,idir) = max(mins(idir,*))
endfor

len = strpos(sfiles,'.',/reverse_search,/reverse_offset)
names = strarr(ndirs)
for idir = 0, ndirs - 1 do begin
    names(idir) = strmid(sfiles(idir),0,len(idir))
endfor

factors = float(names)

ppp = 4
space = 0.01
pos_space, ppp, space, sizes
setdevice, 'correlation.ps','p',5,.95



lines = findgen(ndirs)
get_position, ppp, space, sizes, 0, pos1, /rect
;pos1(0) = pos1(0) + 0.1
yrange = mm(peak)
xrange = [0,2.5]
plot,factors,peak,/nodata,ytitle = 'Peak Dayside Density Percent Difference',$
  xtitle='Relative EUV Maginitude',pos=pos1,/noerase,yrange=yrange,$
  xrange=xrange

for idir = 0, ndirs - 3 do begin
    oplot, factors, peak(idir,*),thick=3,linestyle=lines(idir)
endfor

legend,['Average','Maximum','Minimum'],linestyle=indgen(3),box=0,$
  pos = [pos1(2) - .25,pos1(3) - .08],/norm



closedevice
end
