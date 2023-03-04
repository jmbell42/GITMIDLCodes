dirs2plot = 3
print, ' '
print, 'Plotting '+tostr(dirs2plot)+' directories...'
print, ' '

getnewdata = 1
if file_test('*.sav') eq 1 then begin
    if n_elements(notrestored) eq 0 then notrestored = 1
    savefile = file_search('*.sav')
    display,savefile
    
    print, ' '
    print, 'The session can be restored ----- ',savefile
    print, 'Choose n to use saved data...'
    print, ' '
    

    default = 'n'
    GetNewData = mklower(strmid(ask('whether to reread data',default),0,1))
    if (GetNewData eq 'n') then getnewdata = 0 else getnewdata = 1
    if getnewdata eq 0 then begin   
        if n_elements(sf) eq 0 then sf = 0
        sf = fix(ask('which save file: ',tostr(sf)))
        
        if notrestored then begin 
            restore, savefile(sf)
            notrestored = 0
            reread = 0
            getnewdata = 0
        endif
    endif
endif

pvar = [3,30,19];

if getnewdata then begin
    nfiles_tot = intarr(dirs2plot)
    if n_elements(ndirs) eq 0 then ndirs = intarr(1000)
    if n_elements(dirs) eq 0 or dirs2plot ne ndirs(0) then dirs=strarr(dirs2plot)
    print, 'Enter truth, noda, then DA directories...'
    for idir = 0, dirs2plot - 1 do begin
        dirs(idir) = ask('directory '+tostr(idir+1)+': ',dirs(idir))
    endfor
    
    dir = dirs
    ndirs = n_elements(dir)
    
    print, ' '
    print, 'Obtaining file lists... '
    

    filelist_totnew = strarr(dirs2plot,30000)
    nfiles_totnew = intarr(dirs2plot)
    for idir = 0, dirs2plot - 1 do begin
        fltemp = file_search(dir(idir)+'/*.dat')
        nfiles_totnew(idir) = n_elements(fltemp)
        filelist_totnew(idir,0:nfiles_totnew(idir)-1) = fltemp
    endfor
    
    
    filelist_tot = strarr(dirs2plot,30000)
    for idir = 0,dirs2plot - 1 do begin
        filelist_tot(idir,0:nfiles_totnew(idir)-1) = filelist_totnew(idir,0:nfiles_totnew(idir)-1)
        nfiles_tot(idir) = nfiles_totnew(idir,*)
    endfor

    filelist_totnew = 0
    nfiles_totnew = 0




;    if n_elements(filelist_tot(0,*)) eq n_elements(filelist_totnew1) and $
;      n_elements(filelist_tot(1,*)) eq n_elements(filelist_totnew2) and $
;      n_elements(filelist_tot(3,*)) eq n_elements(filelist_totnew3) and $
;      getnewdata eq 0 then begin
;        answer = ask('whether to re-read data','n')
;        if (strpos(mklower(answer),'n') gt -1) then reread = 0
;    endif

   
    filelist = strarr(dirs2plot,30,10000)
    nfiles = intarr(dirs2plot,30)
    sats = strarr(dirs2plot,100)

    for idir = 0, dirs2plot - 1 do begin 
        nsats = 0
        fl = strpos(filelist_tot(idir),'/')+1
        sats(idir,0) = strmid(filelist_tot(idir,0),fl,3)
        n = 1
        for i=0L,nFiles_tot(idir)-1 do begin
            cFile = filelist_tot(idir,i)
            if (strpos(cFile, sats(idir,nSats)) ne fl) then begin
                nSats = nSats + 1
                sats(idir,nSats) = strmid(filelist_tot(idir,i),fl,3)
;                filelist(idir,nsats,nfiles(idir,nsats)) = filelist_tot(idir,i)         
;                nfiles(idir,nsats) = nfiles(idir,nsats) + 1
            endif
            filelist(idir,nsats,nfiles(idir,nsats)) = filelist_tot(idir,i)
            nfiles(idir,nsats) = nfiles(idir,nsats) + 1
        endfor
        nSats = nSats + 1
    endfor
    filelist = filelist(*,0:nsats-1,0:max(nfiles)-1)
    sats = sats(*,0:nsats-1)
    time = dblarr(dirs2plot,nsats,max(nfiles))

    for idir = 0, dirs2plot - 1 do begin
        for isat = 0, nsats - 1 do begin
            thermo_readsat, filelist(idir,isat,0:nfiles(idir,isat)-1), data_temp, $
              time_temp, nTimes, Vars, nAlts, nSats_temp, Files
            nvars = n_elements(vars)
    
            if isat eq 0 and idir eq 0 then $
              data = fltarr(dirs2plot,nsats,max(nfiles),nvars,nalts-4)
            data(idir,isat,0:nfiles(idir,isat)-1,*,*) = data_temp(*,*,*,2:nalts-3)
            time(idir,isat,0:nfiles(idir,isat)-1) = time_temp
        endfor
    endfor

save, /all,filename = 'sat.sav'
endif


        
sats = sats(0,*)

st = dblarr(dirs2plot)
et = dblarr(dirs2plot)
for idir = 0, dirs2plot - 1 do begin
    st(idir) = time(idir,0,0)
    et(idir) = max(time(idir,0,*))
endfor

stime = double(max(st))
etime = double(min(et))

endtime = [2002,10,09,21,0,0]
c_a_to_r,endtime,timeend
maxt1  = max(where(time(1,psats(isat),*) - timeend le 0),imax) 
endtime1 = imax
maxt2  = max(where(time(2,psats(isat),*) - timeend le 0),imax) 
endtime2 = imax
etime = timeend
time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
   
alts = reform(data(0,0,0,2,*))/1000.

if vars(nvars - 1) ne 'TEC' then begin
    nvars = nvars + 1
    vars = [vars,'TEC']
endif
;display,vars
;if n_elements(svar) eq 0 then svar = 3
;svar = fix(ask('which var to plot: ',tostr(svar)))

npvars = n_elements(pvar)
print, ' '
print, 'Plotting...'
for ivar = 0, npvars - 1 do print, vars(pvar(ivar))
dalt = fltarr(nalts)
for ialt = 1,nalts - 6 do begin
    dalt(ialt) = ((alts(ialt+1)+alts(ialt))/2.- $
                    (alts(ialt)+alts(ialt-1))/2.)
endfor
dalt(0) = dalt(1)
dalt(nalts-5) = dalt(nalts-6)


tec = fltarr(dirs2plot,nsats,max(nfiles))
for idir = 0, dirs2plot - 1 do begin
    for isat = 0, nsats - 1 do begin
        for ifile = 0, nfiles(idir,isat) - 1 do begin
            TEC(idir,isat,ifile) = total(data(idir,isat,ifile,19,*)*dalt*1000.0)
        endfor
    endfor
endfor


display,sats
if n_elements(ssats) eq 0 then ssats = '-1'
ssats = ask('which sats to plot (-1 for all,separate by space or comma): ',ssats)
if ssats eq -1 then psats = indgen(nsats) else psats = fix(strsplit(ssats,' ,',/extract))

display,alts
if n_elements(palt) eq 0 then palt = 8
palt = fix(ask('which alt to plot: ',tostr(palt))) 

xrange = [0,etime-stime]


;; value plots ;;;;;;;;;;;;;;;;;;;;;;;;;
;loadct, 39
;setdevice,'plot.ps','p',5,.95
;
;ppp = 6
;space = 0.005
;pos_space, ppp, space, sizes, ny = ppp
;
;npsats = n_elements(psats)
;for isat = 0, npsats-1 do begin
;    get_position, ppp, space, sizes, isat, pos, /rect
;    
;    pos(0) = pos(0) + .05
;    pos(2) = pos(2) - .05
;    
;    for idir = 0, dirs2plot - 1 do begin
;        if istec then val = reform(tec(idir,psats(isat),*)) else $
;          val = reform(data(idir,psats(isat),*,svar,palt))
;        ptime = reform(time(idir,psats(isat),*)-stime)
;        yrange = mm(val(0:nfiles(isat)-1))
;        if isat eq nsats/2. then ytitle = Vars(svar) else ytitle = ' '
;        if isat lt nsats - 1 then begin
;            
;            if idir eq 0 then begin
;                plot,ptime(0:nfiles(idir,psats(isat))-1), $
;                  val(0:nfiles(idir,psats(isat))-1),$
;                  xstyle = 1,ystyle = 1,$
;                  xtickname = strarr(10) + ' ',xtickv = xtickv, xticks = xtickn, $
;                  xminor = xminor,pos=pos,$
;                  yrange = yrange,ytitle = ytitle,/noerase,xrange=xrange
;            endif else begin
;                oplot, ptime(0:nfiles(idir,psats(isat))-1), $
;                  val(0:nfiles(idir,psats(isat))-1), $
;                  linestyle = idir
;            endelse
;            
;        endif else begin
;            if idir eq 0 then begin
;                plot,ptime(0:nfiles(idir,psats(isat))-1),$
;                  val(0:nfiles(idir,psats(isat))-1),$
;                  xstyle = 1,ystyle = 1,$
;                  xtickname = xtickname,xtickv = xtickv, xticks = xtickn, xminor = xminor,$
;                  xtitle = xtitle,pos=pos,yrange=yrange,/noerase,ytitle = ytitle,color = 0,$
;                  xrange=xrange
;                  
;            endif else begin
;                oplot, ptime(0:nfiles(idir,psats(isat))-1), $
;                  val(0:nfiles(idir,psats(isat))-1), $
;                  linestyle = idir
;            endelse
;        endelse
;
;    endfor
;endfor
;
;closedevice

;; difference plots ;;;;;;;;;;;;;;;;;;;;;;;;;
plotdiff = 1 
if plotdiff then begin
    loadct, 39
    setdevice,'diff.ps','p',5,.95
    
    ppp = 6
    space = 0.005
    pos_space, ppp, space, sizes, ny = ppp
    
    
  ;  for isat = 0, npsats-1 do begin



    for ivar = 0, npvars -1 do begin
        isat = 0

        get_position, ppp, space, sizes, ivar, pos, /rect
        
        pos(0) = pos(0) + .05
        pos(2) = pos(2) - .05
        
        locs1 = intarr(nfiles(1,psats(isat)))
        locs2 = intarr(nfiles(2,psats(isat)))
            for itime = 0, nfiles(1,psats(isat)) - 1 do begin
                tloc = where(time(1,psats(isat),itime) eq time(0,psats(isat),*))
                if tloc eq -1 then begin
                    print, time(1,psats(isat),itime) 
                endif else begin
                    locs1(itime) = tloc
                endelse
            endfor
            for itime = 0, nfiles(2,psats(isat)) - 1 do begin
                tloc = where(time(2,psats(isat),itime) eq time(0,psats(isat),*))
                if tloc eq -1 then begin
                    print, time(2,psats(isat),itime) 
                endif else begin
                    locs2(itime) = tloc
                endelse
            endfor
            
            svar = pvar(ivar)

            if svar eq 31 then begin
                vald1 = reform((tec(1,psats(isat),0:nfiles(1,psats(isat))-1) - $
                                tec(0,psats(isat),locs1)) / $
                               tec(0,psats(isat),locs1)) * 100.
                vald2 = reform((tec(2,psats(isat),0:nfiles(2,psats(isat))-1) - $
                                tec(0,psats(isat),locs2)) / $
                               tec(0,psats(isat),locs2)) * 100.
                
                rmse_noda = sqrt(mean((tec(1,psats(isat),0:nfiles(1,psats(isat))-1) - $
                                       tec(0,psats(isat),locs1))^2))
                rmse_da = sqrt(mean((tec(2,psats(isat),0:nfiles(2,psats(isat))-1) - $
                                     tec(0,psats(isat),locs2))^2))
                
                rmsd1 = sqrt(mean((tec(0,psats(isat),locs1)^2)))
                rmsd2 = sqrt(mean((tec(0,psats(isat),locs2)^2)))
                
                
                
            endif else begin
                vald1 = reform((data(1,psats(isat),0:nfiles(1,psats(isat))-1,svar,palt)-$
                                data(0,psats(isat),locs1,svar,palt))/ $
                               data(0,psats(isat),locs1,svar,palt))*100.
                vald2 = reform((data(2,psats(isat),0:nfiles(2,psats(isat))-1,svar,palt)-$
                                data(0,psats(isat),locs2,svar,palt))/ $
                               data(0,psats(isat),locs2,svar,palt))*100.
                
                
                rmse_noda = sqrt(mean((data(1,psats(isat),0:nfiles(1,psats(isat))-1,svar,palt)-$
                                       data(0,psats(isat),locs1,svar,palt))^2))
                rmse_da = sqrt(mean((data(2,psats(isat),0:nfiles(2,psats(isat))-1,svar,palt)-$
                                     data(0,psats(isat),locs2,svar,palt))^2))
                
                rmsd1 = sqrt(mean(data(0,psats(isat),locs1,svar,palt)^2))
                rmsd2 = sqrt(mean(data(0,psats(isat),locs2,svar,palt)^2))
          
; print, sqrt(mean((data(1,2,0:nfiles(1,2)-1,3,29)-data(0,2,locs1,3,29))^2))/(mean((data(0,2,locs1,3,29))^2)^.5)
            endelse
            nrms_noda = rmse_noda/rmsd1 * 100.0
            nrms_da = rmse_da/rmsd2 * 100.0
            
            print, ' '
            print, vars(svar)
            print, 'Normalized RMS error NoDA: ', tostrf(nrms_noda)
            print, 'Normalized RMS error DA: ', tostrf(nrms_da)
            print, 'NRMS Difference: ',tostrf(nrms_noda-nrms_da)
            print, 'Percent improvement:  ',tostrf((nrms_noda-nrms_da)/nrms_noda)
            print, ' '
            
           
            ptime1 = reform(time(1,psats(isat),0:endtime1)-stime)
            yrange1 = mm(vald1(0:nfiles(1,psats(isat))-1))
            ptime2 = reform(time(2,psats(isat),0:endtime2)-stime)
            yrange2 = mm(vald2(0:nfiles(2,psats(isat))-1))
            yr = min([yrange1(0),yrange2(0)])
            
            yl = max([yrange1(1),yrange2(1)])
            if svar eq 19 or svar eq 31 then begin
                yr = max([yr,-100])
                yl = min([yl,100])
            endif            
            yrange = [yr,yl]
            ytitle = strmid(strtrim(vars(svar),2),0,4)+' % Diff'
;            yrange = [-50,110] 
;            if isat eq nsats/2. then ytitle = '    '+Vars(svar)+' %
;            Diff' else ytitle = ' '
;            if isat eq npsats/2. then ytitle = '    % Difference' else ytitle = ' '
;            if isat lt npsats - 1 then begin
;            if ivar eq 1 then ytitle = '% Difference' else ytitle = ' '
            if ivar lt npvars - 1 then begin
                plot,ptime1, $
                      vald1,$
                      xstyle = 1,ystyle = 1,$
                      xtickname = strarr(10) + ' ',xtickv = xtickv, xticks = xtickn, $
                      xminor = xminor,pos=pos,$
                      yrange = yrange,ytitle = ytitle,/noerase,xrange=xrange,/nodata,charsize = 1.3
                
                oplot, ptime1, $
                      vald1, $
                      linestyle = 0,thick=3
                oplot, ptime2,  vald2, $
                      linestyle = 2,thick=3
               
                oplot,[0,100000.],[0,0],linestyle = 1
                
            endif else begin
                
                plot,ptime1, $
                  vald1,$
                  xstyle = 1,ystyle = 1,$
                  xtickname = xtickname,xtickv = xtickv, $
                  xticks = xtickn, xminor = xminor,$
                  xtitle = xtitle,pos=pos,yrange=yrange,/noerase,ytitle = ytitle,$
                  xrange=xrange,/nodata,charsize = 1.3
                
                
                oplot, ptime1, $
                  vald1, $
                  linestyle = 0,thick=3
                
                oplot, ptime2, $
                  vald2, $
                  linestyle = 2,thick=3
                 
                oplot,[0,100000.],[0,0],linestyle = 1
            endelse
            
        endfor
        legend,['DA','No DA'],linestyle=[2,0],pos = [.75,1.05],/norm,box=0
        if vars(svar) ne 'TEC' then begin 
            legend,[tostr(alts(palt))+' km Altitude'],box=0,pos=[.05,1.03],/norm
           ; legend,[vars(svar),vars(19),strmid(vars(30),1,4)],$
           ;   colors=[0,50,254],linestyle=[0,0,0],box=0,$
           ;   pos=[pos(2)-.13,pos(1)-.01],/norm
        endif
endif  

closedevice

end
