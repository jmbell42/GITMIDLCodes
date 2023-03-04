GetNewData = 1

ndirs = 3

if n_elements(directorypert1) eq 0 then directorypert1 = '.'
if n_elements(directorypert2) eq 0 then directorypert2 = '.'
if n_elements(directorybase) eq 0 then directorybase = '.'
directorypert1 = ask('perturbation directory 1: ',directorypert1)
directorypert2 = ask('perturbation directory 2: ',directorypert2)
directorybase = ask('base directory: ',directorybase)

filelist_newpert1 = findfile(directorypert1+'/t*3DALL*')
filelist_newpert2 = findfile(directorypert2+'/t*3DALL*')
filelist_newbase = findfile(directorybase+'/t*3DALL*')

nfiles_new1 = n_elements(filelist_newpert1) 
nfiles_new2 = n_elements(filelist_newpert2) 
nfiles_newbase = n_elements(filelist_newbase)

if nfiles_new1 ne nfiles_new2 or nfiles_new2 ne nfiles_newbase then begin
    print, 'Directories are not the same size... Quitting...'
    stop
endif

nfiles_new = nfiles_new1

if n_elements(filename) eq 0 then begin
filename = filelist_newpert1(0)
read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
  vars, data1, rb, cb, bl_cnt
lon = fltarr(nlons)
endif
dlon = (data1(0,1,0,0) - data1(0,0,0,0))/!dtor
dlat = (data1(1,0,1,0) - data1(1,0,0,0))/!dtor
dalts = fltarr(nalts-4)
fl = strlen(filename)
savetime = strmid(filename,fl-13,2)

if file_test(savetime+'.sav') eq 1 then begin
    if n_elements(notrestored) eq 0 then notrestored = 1
    savefile = file_search(savetime+'.sav')
    print, ' '
    print, 'The session can be restored ----- ',savefile
    print, 'Choose n to use saved data...'
    print, ' '
    
    if notrestored then begin 
        restore, savefile(0)
        notrestored = 0
    endif
    default = 'n'
    GetNewData = mklower(strmid(ask('whether to reread data',default),0,1))
    if (GetNewData eq 'n') then GetNewData = 0 else GetNewData = 1
    
endif else begin
    if n_elements(nfiles) gt 0 then begin
        if (nfiles_new eq nfiles) then default = 'n' else default = 'y'
        GetNewData = mklower(strmid(ask('whether to reread data',default),0,1))
        if (GetNewData eq 'n') then GetNewData = 0 else GetNewData = 1
    endif
endelse

nfiles = nfiles_new

for ivar = 0, nvars - 1 do print, ivar, ' ',vars(ivar)
print, ivar, '  ','TEC'
if n_elements(ivars) eq 0 then ivars = 3
ivars = fix(ask('which variable to plot: ',tostr(ivars)))

alts = reform(data1(2,0,0,*))/1000.
dalts = fltarr(nalts - 4)

for ialt = 2,nalts - 3 do begin
    dalts(ialt-2) = ((alts(ialt+1)+alts(ialt))/2.- $
                    (alts(ialt)+alts(ialt-1))/2.) * 1000.0
endfor

for ialt = 0, nalts - 1 do print, ialt,'  ',alts(ialt)
if n_elements(ialts) eq 0 then ialts = 0

ialts = fix(ask('altitude to plot: ',tostr(ialts)))
re = 6378.

vn = where(vars eq 'V!Dn!N(north)')
ve = where(vars eq 'V!Dn!N(east)')

if (GetNewData) then begin

   lenpert1 = strlen(directorypert1) + 1+13-2
   lenpert2 = strlen(directorypert2) + 1+13-2
   lenbase = strlen(directorybase) + 1+13-2

   filelist_pert1 = filelist_newpert1
   filelist_pert2 = filelist_newpert2
   filelist_base = filelist_newbase

   iTime = intarr(6,nfiles)
   rtime = fltarr(nfiles)
    glbmax1 = fltarr(nfiles,nvars,nalts)
    glbmax2 = fltarr(nfiles,nvars,nalts)
    glbmin1 = fltarr(nfiles,nvars,nalts)
    glbmin2 = fltarr(nfiles,nvars,nalts)
    glbminbase = fltarr(nfiles,nvars,nalts)
    glbmaxbase = fltarr(nfiles,nvars,nalts)
    glbnrms1 = fltarr(nfiles,nvars,nalts)
    glbnrms2 = fltarr(nfiles,nvars,nalts)

    maxtec1 = fltarr(nfiles)
    mintec1 = fltarr(nfiles)
    maxtec2 = fltarr(nfiles)
    mintec2 = fltarr(nfiles)
    tecnrms1 = fltarr(nfiles)
    tecnrms2 = fltarr(nfiles)

    TEC1 = fltarr(nlons-4,nlats-4)
    TEC2 = fltarr(nlons-4,nlats-4)
    TECbase = fltarr(nlons-4,nlats-4)
    evar = where(vars eq ' [e-]')
    for iFile = 0, nfiles - 1 do begin
        
        filename1 = filelist_pert1(ifile)
        filename2 = filelist_pert2(ifile)
        filenamebase = filelist_base(ifile)

       print, 'Reading files like... ',filename1

       read_thermosphere_file, filename1, nvars, nalts, nlats, nlons, $
         vars, data1, rb, cb, bl_cnt
       
       read_thermosphere_file, filename2, nvars, nalts, nlats, nlons, $
         vars, data2, rb, cb, bl_cnt

       read_thermosphere_file, filenamebase, nvars, nalts, nlats, nlons, $
         vars, database, rb, cb, bl_cnt
       
       if (strpos(filename1,"save") gt 0) then begin
                
           fn = findfile(filename1)
           if (strlen(fn(0)) eq 0) then begin
               print, "Bad filename : ", filename
               stop
           endif else filename1 = fn(0)
           
           l1 = strpos(filename1,'.save')
           fn2 = strmid(filename1,0,l1)
           len = strlen(fn2)
           l2 = l1-1
           while (strpos(strmid(fn2,l2,len),'.') eq -1) do l2 = l2 - 1
           l = l2 - 13
           year = fix(strmid(filename1,l, 2))
           mont = fix(strmid(filename1,l+2, 2))
           day  = fix(strmid(filename1,l+4, 2))
           hour = float(strmid(filename1, l+7, 2))
           minu = float(strmid(filename1,l+9, 2))
           seco = float(strmid(filename1,l+11, 2))
       endif else begin
           l1 = strpos(filename1,'.bin')
           l2 = 13
           l = l1 - l2
           year = fix(strmid(filename1,l, 2))
           mont = fix(strmid(filename1,l+2, 2))
           day  = fix(strmid(filename1,l+4, 2))
           hour = float(strmid(filename1,l+7, 2))
           minu = float(strmid(filename1,l+9, 2))
           seco = float(strmid(filename1,l+11, 2))
       endelse
       
       if year lt 50 then iyear = year + 2000 else iyear = year + 1900     
       itime(*,ifile) = [year,mont,day,hour,minu,seco]
       c_a_to_r,itime(*,ifile),rt
       rtime(ifile) = rt
       stryear = strtrim(string(iyear),2)
       strmth = strtrim(string(mont),2)
       strday = strtrim(string(day),2)
       uttime = hour+minu/60.+seco/60./60.
       
       strdate = stryear+'-'+strmth+'-'+strday
       strdate = strdate(0)
       
       for ivar = 0, nvars - 1 do begin
           for ialt = 0, nalts - 1 do begin
               glbmin1(ifile,ivar,ialt) = min(data1(ivar,*,*,ialt))
               glbmin2(ifile,ivar,ialt) = min(data2(ivar,*,*,ialt))
               glbmax1(ifile,ivar,ialt) = max(data1(ivar,*,*,ialt))
               glbmax2(ifile,ivar,ialt) = max(data2(ivar,*,*,ialt))
               glbminbase(ifile,ivar,ialt) = min(database(ivar,*,*,ialt))
               glbmaxbase(ifile,ivar,ialt) = max(database(ivar,*,*,ialt))
               
               glbnrms1(ifile,ivar,ialt) = $
                 (mean((data1(ivar,*,*,ialt)-database(ivar,*,*,ialt))^2)^.5) / $
                 (mean((database(ivar,*,*,ialt))^2)^.5)
               
               glbnrms2(ifile,ivar,ialt) = $
                 (mean((data2(ivar,*,*,ialt)-database(ivar,*,*,ialt))^2)^.5) / $
                 (mean((database(ivar,*,*,ialt))^2)^.5)
               
           endfor
       endfor
       for ilat = 2, nlats - 3 do begin
           for ilon = 2, nlons - 3 do begin
               ;;;;TEC STUFF ;;;;;;;;;;;;;;;;;;
               TEC1(ilon-2,ilat-2) = $
                 total(data1(evar,ilon,ilat,2:nalts-3)*dalts)
               TEC2(ilon-2,ilat-2) = $
                 total(data2(evar,ilon,ilat,2:nalts-3)*dalts)
               TECbase(ilon-2,ilat-2) = $
                 total(database(evar,ilon,ilat,2:nalts-3)*dalts)
           endfor
       endfor
       maxtec1(ifile) = max((tec1-tecbase)/tecbase)
       maxtec2(ifile) = max((tec2-tecbase)/tecbase)
       mintec1(ifile) = min((tec1-tecbase)/tecbase)
       mintec2(ifile) = min((tec2-tecbase)/tecbase)
       tecnrms1(ifile) = (mean((tec1-tecbase)^2))^.5/(mean((tecbase)^2))^.5
       tecnrms2(ifile) = (mean((tec2-tecbase)^2))^.5/(mean((tecbase)^2))^.5
   endfor

   stime = rtime(0)
   etime = max(rtime)
   
   time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
   
   save,/all,filename = savetime+'.sav'
   
endif

ppp = 4
space = 0.01
pos_space, ppp, space, sizes, ny = ppp

setdevice,'plot.ps','p',5,.95
    
get_position, ppp, space, sizes, 0, pos, /rect
pos(0) = pos(0) + 0.05
pos(2) = pos(2) + 0.05

if ivars eq nvars then begin
    val1 = tecnrms1
    val2 = tecnrms2
    ytitle = 'TEC NRMS Average'
endif else begin
    val1 = reform(glbnrms1(*,ivars,ialts))
    val2 = reform(glbnrms2(*,ivars,ialts))
    ytitle = vars(ivars)+ ' NRMS Average'
endelse

yrange = mm([val1,val2])

plot, rtime-stime,val1,/nodata,charsize=1.2,xtickname=xtickname,xtitle=xtitle, $
  ytitle=ytitle,pos=pos,xticks=xtickn, xtickv = xtickv,$
  xminor = xminor, xstyle = 1, yrange = yrange, ystyle = 1

oplot, rtime-stime,val1,linestyle=0,thick = 3
oplot, rtime-stime,val2,linestyle=2,thick = 3

legend,['NoDA','DA'],linestyle=[0,2],box=0,pos=[pos(2)-.25,pos(3)+.05],/norm
closedevice

end

  

