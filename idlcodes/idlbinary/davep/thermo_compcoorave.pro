GetNewData = 1

if n_elements(directorypert) eq 0 then directorypert = '.'
if n_elements(directorybase) eq 0 then directorybase = '.'
directorypert = ask('perturbation directory: ',directorypert)
directorybase = ask('base directory: ',directorybase)

filelist_newpert = findfile(directorypert+'/3DALL*.bin')
filelist_newbase = findfile(directorybase+'/3DALL*.bin')
nfiles_new = min([n_elements(filelist_newpert),n_elements(filelist_newbase)],smalldir)
locs = intarr(nfiles_new)

dlon = 5.0
dlat = 5.0

if n_elements(nfiles) gt 0 then begin
    if (nfiles_new eq nfiles) then default = 'n' else default = 'y'
    GetNewData = mklower(strmid(ask('whether to reread data',default),0,1))
    if (GetNewData eq 'n') then GetNewData = 0 else GetNewData = 1
endif

if n_elements(filename) eq 0 then begin
filename = filelist_newpert(0)
read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
  vars, data1, rb, cb, bl_cnt
lon = fltarr(nlons)
endif

for ivars = 0, nvars - 1 do print, ivars, ' ',vars(ivars)
if n_elements(ivar) eq 0 then ivar = 3
ivar = fix(ask('which variable to plot: ',tostr(ivar)))

alts = reform(data1(2,0,0,*))/1000.
for ialt = 0, nalts - 1 do print, ialt,'  ',alts(ialt)
if n_elements(ialt2) eq 0 then ialt2 = 0

ialt2 = fix(ask('second altitude to plot: ',tostr(ialt2)))
re = 6378.

if (GetNewData) then begin

   lenpert = strlen(directorypert) + 1+13
   lenbase = strlen(directorybase) + 1+13

   if smalldir eq 0 then begin
       for ifile = 0, nfiles_new-1 do begin
           locs(ifile) = where(strmid(filelist_newbase,lenbase) eq $
                               strmid(filelist_newpert(ifile),lenpert))
       endfor
       filelist1 = filelist_newpert
       filelist2 = filelist_newbase
   endif else begin
       for ifile = 0, nfiles_new-1 do begin
           locs(ifile) = where(strmid(filelist_newpert,lenpert) eq $
                               strmid(filelist_newbase(ifile),lenbase))
       endfor
       filelist1 = filelist_newbase
       filelist2 = filelist_newpert
   endelse

   loc = where(locs ne -1)
   nf = n_elements(locs)
   rtime = fltarr(nf)
   nfiles = nfiles_new
   iTimeArray = intarr(6,nf)
   londiff = fltarr(nvars,nfiles,nlons-4)
   latdiff = fltarr(nvars,nfiles,nlats-4)

   for iFile = 0, nf - 1 do begin
       filename1 = filelist1(loc(ifile))
       filename2 = filelist2(locs(ifile))
       
       print, 'Reading files ',filename1, ' and ',filename2
       
       read_thermosphere_file, filename1, nvars, nalts, nlats, nlons, $
         vars, data1, rb, cb, bl_cnt
       
       read_thermosphere_file, filename2, nvars, nalts, nlats, nlons, $
         vars, data2, rb, cb, bl_cnt
       
       if smalldir eq 0 then fn = file_search(filename1) else fn = file_search(filename2)
       if (strlen(fn(0)) eq 0) then begin
           print, "Bad filename : ", filename
           stop
       endif else filename = fn(0)
       
       l1 = strpos(filename,'.bin')
       fn2 = strmid(filename,0,l1)
       len = strlen(fn2)
       l = len - 13
       year = fix(strmid(filename,l, 2))
       mont = fix(strmid(filename,l+2, 2))
       day  = fix(strmid(filename,l+4, 2))
       hour = float(strmid(filename, l+7, 2))
       if ifile eq 0 then minu = 0 else minu = float(strmid(filename, l+9, 2))
       seco = 0
       
       itime = [year,mont,day,fix(hour),fix(minu),fix(seco)]
       c_a_to_r,itime,rt
       rtime(ifile) = rt
       
       
       londiff(*,ifile,*) = (data1(*,2:nlons-3,nlats/2.,ialt2) - $
                           data2(*,2:nlons-3,nlats/2.,ialt2)) / data1(*,2:nlons-3,nlats/2.,ialt2)
       latdiff(*,ifile,*) = (data1(*,nlons/2.,2:nlats-3,ialt2) - $
                           data2(*,nlons/2.,2:nlats-3,ialt2)) / data1(*,nlons/2.,2:nlats-3,ialt2)
       
   endfor
   
   time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
endif

variable = strmid(vars(ivar),0,4)
if ivar eq 32 then variable = 'e-'
title = 'coorprofile'+tostr(itime(2))+'_'+variable+'.ps'
setdevice,title,'p',5,.95

makect, 'mid'
lons = reform(data1(0,2:nlons-3,0,0))/!dtor
lats = reform(data1(0,0,2:nlats-3,0))/!dtor

ppp = 2
space = 0.075
pos_space, ppp, space, sizes, ny = 1

minlon = -1*max([abs(min(londiff(ivar,*,*))),abs(max(londiff(ivar,*,*)))])
maxlon = -1 * minlon
minlat = -1*max([abs(min(latdiff(ivar,*,*))),abs(max(latdiff(ivar,*,*)))])
maxlat = -1 * minlon

levels = findgen(31)*(maxlon-minlon)/30.+minlon
get_position, ppp, space, sizes, 0, pos
contour, londiff(ivar,*,*),rtime-stime,lons,/follow,/fill,levels = levels, nlevels = 30, $
  yrange = [lons(0),max(lons)], ystyle = 1, ytitle = 'Longitude', $
  xtickname = xtickname,  xtickv = xtickv, $
  xminor = xminor, xticks = xtickn, xstyle = 1, charsize = 1.2,pos = pos

ctpos = pos
ctpos(0) = pos(2)+0.025
ctpos(2) = ctpos(0)+0.03
maxmin = [minlat,maxlat]
plotct, 255, ctpos, maxmin, title, /right


levels = findgen(31)*(maxlat-minlat)/30.+minlat
get_position, ppp, space, sizes, 1, pos
contour, latdiff(ivar,*,*),rtime-stime,lats,/follow,/fill,levels = levels, nlevels = 30, $
  yrange = [lats(0),max(lats)], ystyle = 1, ytitle = 'Latitude', $
  xtickname = xtickname,  xtickv = xtickv, $
  xminor = xminor, xticks = xtickn, xstyle = 1, charsize = 1.2,pos = pos

ctpos = pos
ctpos(0) = pos(2)+0.025
ctpos(2) = ctpos(0)+0.03
maxmin = [minlat,maxlat]
plotct, 255, ctpos, maxmin, title, /right
closedevice



end
