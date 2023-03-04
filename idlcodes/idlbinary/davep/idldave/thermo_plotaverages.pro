nfilesmax = 100
if n_elements(ndirsnew) eq 0 then ndirsnew = 1
ndirsnew = fix(ask('number of directories to plot: ',tostr(ndirsnew)))

if n_elements(ndirs) eq 0 then ndirs = 0
if ndirsnew ne ndirs then dirsnew = strarr(ndirsnew)


for idir = 0, ndirsnew - 1 do begin
    dirsnew(idir) = ask('directory '+tostr(idir+1)+': ',dirsnew(idir))
endfor

if n_elements(nfiles) eq 0 then nfiles = 0
if n_elements(dirs) eq 0 then dirs = ' '

reread = 1 
if dirs(0) eq dirsnew(0) and ndirs eq ndirsnew then begin
    reread = 'n'
    reread = ask('whether to reread files: ',reread)
    if strpos(reread,'y') ge 0 then reread = 1 else reread = 0
endif
ndirs = ndirsnew
dirs = dirsnew

;;;
filelist_t = file_search(dirs(0)+'/3DTHM*')
nfiles = n_elements(filelist_t)
itime = intarr(6,nfiles)
rtime = fltarr(ndirs,nfiles)
if strpos(filelist_t(0),'ALL') ge 0 then isAll = 1 else isAll = 0
for ifile = 0, nfiles - 1 do begin
    itime(*,ifile) = get_gitm_time(filelist_t(ifile))
    c_a_to_r, itime, rt
    rtime(*,ifile) = rt
endfor

fn = filelist_t(0)

read_thermosphere_file, fn, nvars, nalts, nlats, nlons, $
  vars, datat, rb, cb, bl_cnt
nalts = n_elements(datat(0,0,0,*))
alt = reform(datat(2,0,0,*))/1000.0
lat = reform(datat(1,2:nlons-3,2:nlats-3,0))/!dtor

if isall then display,[vars,'NmF2','HmF2','O/N2'] else $
  display,vars

if n_elements(pvar) eq 0 then pvar = 0
pvar = fix(ask('which variable to plot: ',tostr(pvar)))
if n_elements(pvarold) eq 0 then pvarold = 0
if pvarold ne pvar then reread = 1
pvarold = pvar
ndirs_old = ndirs
;sfiles_old = sfiles
;;;
 
if reread then begin

    for idir = 0, ndirs - 1 do begin
        save = 0
;        savefile = file_search(dirs(idir)+'/.sav')
        if save then begin
            print, "Working on ",savefile(0)
            restore,saveflie(0)
            if idir eq 0 then begin
                dataavg = fltarr(3,nfiles,4,nvars,nalts-4)
            endif

           dataavg = get_averages_from_save(savefile(0),'global,day,night,highlat')
            
        endif else begin

            
            filelist = file_search(dirs(idir)+'/3DALL*')
            nfiles = n_elements(filelist)
            
            dataavg = get_averages(filelist,'global,day,night,highlat')
            
            iglb = 0
            iday = 1
            init = 2
            ihlt = 3
            iavg = 0
            imin = 1
            imax = 2
            if idir eq 0 then begin
                
                
                read_thermosphere_file, filelist(0), nvars, nalts, nlats, nlons, $
                  vars, data, rb, cb, bl_cnt
                nvarsold = nvars
                if isall then begin
                    nvars = nvars + 3
                    vars = [vars,'NmF2','HmF2','O/N!D2!N']
                endif
                nalts = n_elements(data(0,0,0,*))
                
                
                rtime = fltarr(ndirs,nfiles)
                for ifile = 0,nfiles - 1 do begin
                    itime = get_gitm_time(filelist(ifile))
                    c_a_to_r, itime, rt
                    rtime(*,ifile) = rt
                endfor
               
                if isall then begin
                    NmF2avg_glb  = fltarr(ndirs, nfiles)
                    HmF2avg_glb  = fltarr(ndirs, nfiles)
                    on2avg_glb   = fltarr(ndirs, nfiles)
                    NmF2avg_day  = fltarr(ndirs, nfiles)
                    HmF2avg_day  = fltarr(ndirs, nfiles)
                    on2avg_day   = fltarr(ndirs, nfiles)
                    NmF2avg_night = fltarr(ndirs, nfiles)
                    HmF2avg_night = fltarr(ndirs, nfiles)
                    on2avg_night = fltarr(ndirs, nfiles)
                    NmF2avg_hlat = fltarr(ndirs, nfiles)
                    HmF2avg_hlat = fltarr(ndirs, nfiles)
                    on2avg_hlat  = fltarr(ndirs, nfiles)
                    
                    NmF2ext_glb  = fltarr(2,ndirs, nfiles)
                    HmF2ext_glb  = fltarr(2,ndirs, nfiles)
                    on2ext_glb   = fltarr(2,ndirs, nfiles)
                    NmF2ext_day  = fltarr(2,ndirs, nfiles)
                    HmF2ext_day  = fltarr(2,ndirs, nfiles)
                    on2ext_day   = fltarr(2,ndirs, nfiles)
                    NmF2ext_night = fltarr(2,ndirs, nfiles)
                    HmF2ext_night = fltarr(2,ndirs, nfiles)
                    on2ext_night = fltarr(2,ndirs, nfiles)
                    NmF2ext_hlat = fltarr(2,ndirs, nfiles)
                    HmF2ext_hlat = fltarr(2,ndirs, nfiles)
                    on2ext_hlat  = fltarr(2,ndirs, nfiles)
                endif
            alldataavg = fltarr(ndirs,nfiles,4,nvarsold,nalts-4)
            alldataext = fltarr(2,ndirs,nfiles,4,nvarsold,nalts-4)
        endif

        if isall then begin
            NmF2avg_glb(idir,*)   = dataavg(iavg,*,iglb,nvars-3,nalts-5)
            HmF2avg_glb(idir,*)   = dataavg(iavg,*,iglb,nvars-2,nalts-5)
            on2avg_glb(idir,*)    = dataavg(iavg,*,iglb,nvars-1,nalts-5)
            NmF2avg_day(idir,*)   = dataavg(iavg,*,iday,nvars-3,nalts-5)
            HmF2avg_day(idir,*)   = dataavg(iavg,*,iday,nvars-2,nalts-5)
            on2avg_day(idir,*)    = dataavg(iavg,*,iday,nvars-1,nalts-5)
            NmF2avg_night(idir,*) = dataavg(iavg,*,init,nvars-3,nalts-5)
            HmF2avg_night(idir,*) = dataavg(iavg,*,init,nvars-2,nalts-5)
            on2avg_night(idir,*)  = dataavg(iavg,*,init,nvars-1,nalts-5)
            NmF2avg_hlat(idir,*)  = dataavg(iavg,*,ihlt,nvars-3,nalts-5)
            HmF2avg_hlat(idir,*)  = dataavg(iavg,*,ihlt,nvars-2,nalts-5)
            on2avg_hlat(idir,*)   = dataavg(iavg,*,ihlt,nvars-1,nalts-5)
            alldataavg(idir,*,*,*,*) = dataavg(iavg,*,*,0:nvarsold-1,*)
            
            NmF2ext_glb(*,idir,*)   = dataavg(1:2,*,iglb,nvars-3,nalts-5)
            HmF2ext_glb(*,idir,*)   = dataavg(1:2,*,iglb,nvars-2,nalts-5)
            on2ext_glb(*,idir,*)    = dataavg(1:2,*,iglb,nvars-1,nalts-5)
            NmF2ext_day(*,idir,*)   = dataavg(1:2,*,iday,nvars-3,nalts-5)
            HmF2ext_day(*,idir,*)   = dataavg(1:2,*,iday,nvars-2,nalts-5)
            on2ext_day(*,idir,*)    = dataavg(1:2,*,iday,nvars-1,nalts-5)
            NmF2ext_night(*,idir,*) = dataavg(1:2,*,init,nvars-3,nalts-5)
            HmF2ext_night(*,idir,*) = dataavg(1:2,*,init,nvars-2,nalts-5)
            on2ext_night(*,idir,*)  = dataavg(1:2,*,init,nvars-1,nalts-5)
            NmF2ext_hlat(*,idir,*)  = dataavg(1:2,*,ihlt,nvars-3,nalts-5)
            HmF2ext_hlat(*,idir,*)  = dataavg(1:2,*,ihlt,nvars-2,nalts-5)
            on2ext_hlat(*,idir,*)   = dataavg(1:2,*,ihlt,nvars-1,nalts-5)
            alldataext(*,idir,*,*,*,*) = dataavg(1:2,*,*,0:nvarsold-1,*)
        endif
    endelse
endfor
endif

alt = reform(data(2,0,0,*))/1000.0
display,vars

if n_elements(pvar) eq 0 then pvar = 0
pvar = fix(ask('which variable to plot: ',tostr(pvar)))

display, alt
if n_elements(palt) eq 0 then palt = 0
palt = fix(ask('which altitude to plot: ',tostr(palt)))


stime = rtime(0,0)
etime = max(rtime)
time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
xrange = [0,etime-stime]

ppp = 4
space = 0.01
pos_space, ppp, space, sizes, ny = ppp
setdevice, 'plot.ps','p',5,.95
get_position, ppp, space, sizes, 0, pos1, /rect
post = pos1
pos1(0) = pos1(0) + 0.1
if pvar lt nvarsold then begin
    title = Vars(pvar) +' at '+tostr(alt(palt))+' km'

    get_position, ppp, space, sizes, 0, pos1, /rect
    pos1(0) = pos1(0) + 0.1
    yrange = mm(alldataavg(*,*,0,pvar,palt+2))
;    if pvar eq 15 then yrange = [600,1500]
;    if pvar eq 3 then yrange = [0,2.5e-12]
    if pvar eq 15 then yrange = [800,2000]
    if pvar eq 3 then yrange = [0,1e-11]
    plot,rtime(0,*)-stime,alldataavg(0,*,0,pvar,palt-2),pos=pos1,yrange=yrange,xrange=xrange,$
      xtickname=strarr(10)+' ',xticks=xtickn,xminor=xminor,charsize = 1.2,thick=3,$
      xtickv = xtickv,ytitle = strmid(vars(pvar),0,4) +' global ave',xstyle = 1,title = title,/noerase
    for idir = 0, ndirs - 1 do begin
        oplot,rtime(idir,*)-stime, alldataavg(idir,*,0,pvar,palt-2), linestyle = idir, thick = 3

  endfor
    
    get_position, ppp, space, sizes, 1, pos2, /rect
    pos2(0) = pos2(0) + 0.1
    
    plot,rtime(0,*)-stime,alldataavg(0,*,1,pvar,palt-2),pos=pos2,charsize = 1.2,thick=3,$
      xtickname=strarr(10)+' ',xticks=xtickn,xminor=xminor,yrange=yrange,xrange=xrange,$
      xtickv = xtickv,ytitle = strmid(vars(pvar),0,4) +' dayside ave',xstyle = 1,/noerase

    for idir = 0, ndirs - 1 do begin

        oplot,rtime(idir,*)-stime, alldataavg(idir,*,1,pvar,palt-2), linestyle = idir, thick = 3
    endfor

    get_position, ppp, space, sizes, 2, pos3, /rect
    pos3(0) = pos3(0) + 0.1



    plot,rtime(0,*)-stime,alldataavg(0,*,2,pvar,palt-2),pos=pos3,charsize = 1.2,thick=3,$
      xtickname=strarr(10) + ' ',xticks=xtickn,xminor=xminor,yrange=yrange,xrange=xrange,$
      ytitle = strmid(vars(pvar),0,4) +' nightside ave',$
      xtickv = xtickv,xstyle = 1,/noerase
      
    for idir=0, ndirs - 1 do begin
        oplot, rtime(idir,*)-stime,alldataavg(idir,*,2,pvar,palt-2), linestyle = idir, thick = 3
    endfor

    get_position, ppp, space, sizes, 3, pos4, /rect
    pos4(0) = pos4(0) + 0.1

    plot,rtime(0,*)-stime,alldataavg(0,*,3,pvar,palt-2),pos=pos4,charsize = 1.2,thick=3,$
      xtickname=xtickname,xticks=xtickn,xminor=xminor,yrange=yrange,xrange=xrange,$
      ytitle = strmid(vars(pvar),0,4) +' high-lat ave',$
      xtickv = xtickv,xstyle = 1,/noerase,xtitle = xtitle
      
    for idir=0, ndirs - 1 do begin
        oplot, rtime(idir,*)-stime,alldataavg(idir,*,3,pvar,palt-2), linestyle = idir, thick = 3
    endfor
endif else begin

    if pvar eq nvarsold then begin
         title = ''
         
         get_position, ppp, space, sizes, 0, pos1, /rect
         pos1(0) = pos1(0) + 0.1
         yrange = mm(nmf2avg_glb)
         yrange = [0,1.5e12]
         plot,rtime(0,*)-stime,nmf2avg_glb(0,*),pos=pos1,yrange = yrange,xrange=xrange,$
           xtickname=strarr(10)+' ',xticks=xtickn,xminor=xminor,charsize = 1.2,thick=3,$
           xtickv = xtickv,ytitle = 'NmF2 global ave',xstyle = 1,title = title,/noerase
        
         for idir=0, ndirs - 1 do begin
             oplot,rtime(idir,*)-stime, nmf2avg_glb(idir,*), linestyle = idir, thick = 3
         endfor

         get_position, ppp, space, sizes, 1, pos2, /rect
         pos2(0) = pos2(0) + 0.1
           yrange = [0,2.5e12]
         plot,rtime(0,*)-stime,nmf2avg_day(0,*),pos=pos2,charsize = 1.2,thick=3,$
           xtickname=strarr(10)+' ',xticks=xtickn,xminor=xminor,yrange = yrange,xrange=xrange,$
           xtickv = xtickv,ytitle = 'NmF2 dayside ave',xstyle = 1,/noerase
         
         for idir=0, ndirs - 1 do begin
             oplot,rtime(idir,*)-stime, nmf2avg_day(idir,*), linestyle = idir, thick = 3
         endfor

         get_position, ppp, space, sizes, 2, pos3, /rect
         pos3(0) = pos3(0) + 0.1
         yrange = [0,2e12]
         plot,rtime(0,*)-stime,nmf2avg_night(0,*),pos=pos3,charsize = 1.2,thick=3,$
           xtickname=strarr(10) + ' ',xticks=xtickn,xminor=xminor,yrange = yrange,xrange=xrange,$
           ytitle = 'NmF2 nightside ave',$
           xtickv = xtickv,xstyle = 1,/noerase
         
           
         for idir=0, ndirs - 1 do begin
             oplot,rtime(idir,*)-stime, nmf2avg_night(idir,*), linestyle = idir, thick = 3
         endfor

          get_position, ppp, space, sizes, 3, pos4, /rect
         pos4(0) = pos4(0) + 0.1
         yrange = [0,1e12]
         plot,rtime(0,*)-stime,nmf2avg_hlat(0,*),pos=pos4,charsize = 1.2,thick=3,$
           xtickname=xtickname,xticks=xtickn,xminor=xminor,yrange = yrange,xrange=xrange,$
           ytitle = 'NmF2 high-lat ave',$
           xtickv = xtickv,xstyle = 1,/noerase,xtitle = xtitle
         
           
         for idir=0, ndirs - 1 do begin
             oplot,rtime(idir,*)-stime, nmf2avg_hlat(idir,*), linestyle = idir, thick = 3
         endfor

     endif
     
     if pvar eq nvarsold + 1 then begin
         title = ' '
         
         yrange = mm(hmf2avg_day)
         yrange = [300,600]
         get_position, ppp, space, sizes, 0, pos1, /rect
         pos1(0) = pos1(0) + 0.1
         plot,rtime(0,*)-stime,hmf2avg_glb(0,*),pos=pos1,yrange=yrange,xrange=xrange,$
           xtickname=strarr(10)+' ',xticks=xtickn,xminor=xminor,charsize = 1.2,thick=3,$
           xtickv = xtickv,ytitle = 'HmF2 global ave',xstyle = 1,title = title,/noerase
            
         for idir=0, ndirs - 1 do begin
             oplot, rtime(idir,*)-stime,hmf2avg_glb(idir,*), linestyle = idir, thick = 3
         endfor

         get_position, ppp, space, sizes, 1, pos2, /rect
         pos2(0) = pos2(0) + 0.1
         plot,rtime(0,*)-stime,hmf2avg_day(0,*),pos=pos2,charsize = 1.2,thick=3,$
           xtickname=strarr(10)+' ',xticks=xtickn,xminor=xminor,yrange=yrange,xrange=xrange,$
           xtickv = xtickv,ytitle = 'HmF2 dayside ave',xstyle = 1,/noerase
           
         for idir=0, ndirs - 1 do begin
             oplot, rtime(idir,*)-stime,hmf2avg_day(idir,*), linestyle = idir, thick = 3
         endfor

         get_position, ppp, space, sizes, 2, pos3, /rect
         pos3(0) = pos3(0) + 0.1
         plot,rtime(0,*)-stime,Hmf2avg_night(0,*),pos=pos3,charsize = 1.2,thick=3,$
           xtickname=strarr(10)+ ' ',xticks=xtickn,xminor=xminor,yrange=yrange,xrange=xrange,$
           ytitle = 'HmF2 nightside ave',$
           xtickv = xtickv,xstyle = 1,/noerase
            
         for idir=0, ndirs - 1 do begin
             oplot,rtime(idir,*)-stime, hmf2avg_night(idir,*), linestyle = idir, thick = 3
         endfor

         get_position, ppp, space, sizes, 3, pos4, /rect
         pos4(0) = pos4(0) + 0.1
         plot,rtime(0,*)-stime,Hmf2avg_hlat(0,*),pos=pos4,charsize = 1.2,thick=3,$
           xtickname=xtickname,xticks=xtickn,xminor=xminor,yrange=yrange,xrange=xrange,$
           ytitle = 'HmF2 hight-lat ave',$
           xtickv = xtickv,xstyle = 1,/noerase,xtitle = xtitle
            
         for idir=0, ndirs - 1 do begin
             oplot,rtime(idir,*)-stime, hmf2avg_hlat(idir,*), linestyle = idir, thick = 3
         endfor

     endif
     
     
     if pvar eq nvarsold + 2 then begin
         title = ' '

         get_position, ppp, space, sizes, 0, pos1, /rect
         pos1(0) = pos1(0) + 0.1

         yrange = mm([on2avg_glb,on2avg_day,on2avg_night,on2avg_hlat])
;         yrange = [.2,.8]
         yrange = [.4,1]
         plot,rtime(0,*)-stime, on2avg_glb(0,*),pos=pos1,yrange = yrange,xrange=xrange,$
           xtickname=strarr(10)+' ',xticks=xtickn,xminor=xminor,charsize = 1.2,thick=3,$
           xtickv = xtickv,ytitle = 'O/N!D2!N global ave',xstyle = 1,title = title,/noerase
          
         for idir=0, ndirs - 1 do begin
             oplot,rtime(idir,*)-stime, on2avg_glb(idir,*), linestyle = idir, thick = 3
         endfor

         get_position, ppp, space, sizes, 1, pos2, /rect
         pos2(0) = pos2(0) + 0.1

         plot,rtime(0,*)-stime,on2avg_day(0,*),pos=pos2,charsize = 1.2,thick=3,$
           xtickname=strarr(10)+' ',xticks=xtickn,xminor=xminor,yrange = yrange,xrange=xrange,$
           xtickv = xtickv,ytitle = 'O/N!D2!N dayside ave',xstyle = 1,/noerase
          
         for idir=0, ndirs - 1 do begin
             oplot,rtime(idir,*)-stime, on2avg_day(idir,*), linestyle = idir, thick = 3
         endfor

         get_position, ppp, space, sizes, 2, pos3, /rect
         pos3(0) = pos3(0) + 0.1

         plot,rtime(0,*)-stime,on2avg_night(0,*),pos=pos3,charsize = 1.2,thick=3,$
           xtickname=strarr(10)+' ',xticks=xtickn,xminor=xminor,yrange = yrange,xrange=xrange,$
           ytitle = 'O/N!D2!N nightside ave',$
           xtickv = xtickv,xstyle = 1,/noerase
          
         for idir=0, ndirs - 1 do begin
             oplot,rtime(idir,*)-stime, on2avg_night(idir,*), linestyle = idir, thick = 3
         endfor

         get_position, ppp, space, sizes, 3, pos4, /rect
         pos4(0) = pos4(0) + 0.1

         plot,rtime(0,*)-stime,on2avg_hlat(0,*),pos=pos4,charsize = 1.2,thick=3,$
           xtickname=xtickname,xticks=xtickn,xminor=xminor,yrange = yrange,xrange=xrange,$
           ytitle = 'O/N!D2!N high-lat ave',$
           xtickv = xtickv,xstyle = 1,/noerase,xtitle = xtitle
          
         for idir=0, ndirs - 1 do begin
             oplot,rtime(idir,*)-stime, on2avg_hlat(idir,*), linestyle = idir, thick = 3
         endfor
     endif
         

 endelse

 legend, dirs,linestyle = findgen(ndirs),box=0,pos=[post(2)-.25,post(3)+.08],/norm
 closedevice
 
 
 
end
