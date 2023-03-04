compare = 1
isall = 1

if n_elements(ndirs) eq 0 then ndirs = 1
ndirs = fix(ask('number of save files to plot: ',tostr(ndirs)))

if n_elements(sfiles_old) eq 0 then sfiles_old = ' '
if n_elements(sfiles) eq 0 or sfiles_old(0) ne sfiles_old(0) then sfiles = strarr(ndirs)
for ifile = 0, ndirs - 1 do begin
    sfiles(ifile) = ask('name of save file ' + tostr(ifile+1)$
                        + ': ', sfiles(ifile))
endfor

if isall then len = strpos(sfiles(0),'.sav') else len = strpos(sfiles(0),'THM') 
rootdir = strmid(sfiles(0),0,len)+'/data.2/'

if isall then tname = 'ALL' else tname = 'THM'
filelist = file_search('../'+rootdir+'3D'+tname+'*')
fn = filelist(0)

read_thermosphere_file, fn, nvars, nalts, nlats, nlons, $
  vars, datatemp, rb, cb, bl_cnt
if n_elements(pvar) eq 0 then pvar = 3
display, vars
pvar = fix(ask('which variable to plot: ',tostr(pvar)))

reread = 1
if n_elements(ndirs_old) eq 0 then ndirs_old = 0
if n_elements(pvarold) eq 0 then pvarold = -1

if pvar eq pvarold then begin
    if ndirs eq ndirs_old and sfiles(0) eq sfiles_old(0) then begin
        reread = 'n'
        reread = ask('whether to re-restore files: ',reread)
        if strpos(reread,'y') ge 0 then reread = 1 else reread = 0
    endif
endif

pvarold = pvar
ndirs_old = ndirs
sfiles_old = sfiles
if reread then begin
    for ifile = 0, ndirs - 1 do begin
        print, 'Working on '+ sfiles(ifile)
        restore, sfiles(ifile)
        
        if ifile eq 0 then begin
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


stime = rtime(0)
etime = max(rtime)

time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
xrange = [0,etime-stime]

loadct,39
ppp = 4
space = 0.01
pos_space, ppp, space, sizes, ny = ppp
setdevice, 'plot.ps','p',5,.95

if strpos(sfiles(0),'min') ge 0 then $
len = strpos(sfiles,'min',/reverse_search,/reverse_offset) $
else len = strpos(sfiles,'.',/reverse_search,/reverse_offset)
names = strarr(ndirs)
for idir = 0, ndirs - 1 do begin
    names(idir) = strmid(sfiles(idir),0,len(idir))
endfor

colors = findgen(ndirs)*254/ndirs + 254/ndirs
lines = fltarr(ndirs)


get_position, ppp, space, sizes, 0, pos1, /rect
post = pos1
pos1(0) = pos1(0) + 0.1

if compare then    ytitle = vars(pvar)+'(Glb Avg % Diff)' else ytitle = $
  vars(pvar)+' Global Average'
yrange = mm(aves)
;yrange = [0,4e-12]

plot, rtime-stime,/nodata,yrange=yrange,xrange=xrange,$
  xtickname=strarr(10)+' ',xminor=xminor,$
  xticks=xtickn,xtickv=xtickv,charsize=1.2,$
  xstyle=1,pos=pos1,/noerase,ytitle=ytitle


for idir = 0, ndirs - 1 do begin
    oplot,rtime-stime, aves(idir,*),color=colors(idir),thick=3,$
      linestyle=lines(idir)
endfor
;legend,names,color=colors,linestyle=lines,box=0,$
;  pos = [pos1(2) - .25,pos1(3) - .01],/norm


if compare then begin
    get_position, ppp, space, sizes, 1, pos1, /rect
    post = pos1
    pos1(0) = pos1(0) + 0.1
    ytitle = vars(pvar)+'(Max % Diff)'
    yrange = mm(maxs)
;    yrange = [0,30]
;    ytickv=[0,5,10,15,20,25,30]
    plot, rtime-stime,/nodata,yrange=yrange,xrange=xrange,$
      xtickname=strarr(10)+' ',xminor=xminor,$
      xticks=xtickn,xtickv=xtickv,charsize=1.2,$
      xstyle=1,pos=pos1,/noerase,ytitle=ytitle,yminor=5
    
    for idir = 0, ndirs - 1 do begin
        oplot,rtime-stime, maxs(idir,*),color=colors(idir),thick=3,$
          linestyle=lines(idir)
    endfor
    
    get_position, ppp, space, sizes, 2, pos1, /rect
    post = pos1
    pos1(0) = pos1(0) + 0.1

   ytitle = vars(pvar)+'(Min % Diff)'
    yrange = mm(mins)
;    yrange = [-6,6]
    plot, rtime-stime,/nodata,yrange=yrange,xrange=xrange,$
      xtickname=xtickname,xtitle=xtitle,xminor=xminor,$
      xticks=xtickn,xtickv=xtickv,charsize=1.2,$
      xstyle=1,pos=pos1,/noerase,ytitle=ytitle
    
    for idir = 0, ndirs - 1 do begin
        oplot,rtime-stime, mins(idir,*),color=colors(idir),thick=3,$
          linestyle=lines(idir)
    endfor
endif



closedevice
end

