;;;;;;;;;;;;;;;GITM STUFF;;;;;;;;;;;;;;;;;;;;;;;
GetNewData = 1
filelist_new = findfile("t*.3D*.save")
nfiles_new = n_elements(filelist_new)

if n_elements(nfiles) gt 0 then begin
    if (nfiles_new eq nfiles) then default = 'n' else default = 'y'
    GetNewData = mklower(strmid(ask('whether to reread data',default),0,1))
    if (GetNewData eq 'n') then GetNewData = 0 else GetNewData = 1
endif

if (GetNewData) then begin
    nfiles = n_elements(filelist_new)
    sscoords = fltarr(2,nfiles)
    iTimeArray = intarr(6,nFiles)
    
    for iFile = 0, nFiles-1 do begin
        
        filename = filelist_new(iFile)
        
        print, 'Reading file ',filename
        
        read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
          vars, data, rb, cb, bl_cnt

        if iFile eq 0 then begin
            ssdata = fltarr(nvars,nfiles,nalts)
            realtime = fltarr(nfiles)
        endif

            if (strpos(filename,"save") gt 0) then begin
                
                fn = findfile(filename)
                if (strlen(fn(0)) eq 0) then begin
                    print, "Bad filename : ", filename
                    stop
                endif else filename = fn(0)
                
                l1 = strpos(filename,'.save')
                fn2 = strmid(filename,0,l1)
                len = strlen(fn2)
                l2 = l1-1
                while (strpos(strmid(fn2,l2,len),'.') eq -1) do l2 = l2 - 1
                l = l2 - 13
                year = fix(strmid(filename,l, 2))
                mont = fix(strmid(filename,l+2, 2))
                day  = fix(strmid(filename,l+4, 2))
                hour = float(strmid(filename, l+7, 2))
                minu = float(strmid(filename,l+9, 2))
                seco = float(strmid(filename,l+11, 2))
            endif else begin
                year = fix(strmid(filename,07, 2))
                mont = fix(strmid(filename,09, 2))
                day  = fix(strmid(filename,11, 2))
                hour = float(strmid(filename,14, 2))
                minu = float(strmid(filename,16, 2))
                seco = float(strmid(filename,18, 2))
            endelse
            
            itime = [year,mont,day,fix(hour),fix(minu),fix(seco)]
       
        
        iTimeArray(*,iFile) = itime
        iyear = year+2000
        stryear = strtrim(string(iyear),2)
        strmth = strtrim(string(mont),2)
        strday = strtrim(string(day),2)
        uttime = hour+minu/60.+seco/60./60.
        
    endfor
endif

for i=0, nfiles-1 do begin
    c_a_to_r, iTimeArray(*,i),rtime
    realtime(i) = rtime
endfor

stime = realtime(0)
etime = realtime(nfiles-1)

time_axis,stime, etime, btr, etr, xtickname,xtitle,xtickv,xminor,xtickn

iVar = 19

;;;;;;;;;;;;; ISR STUFF ;;;;;;;;;;;;;;;;;;;;;;;;


GetNewMHData = 1
if n_elements(mhdir) eq 0 then mhdir = '~/Runs/IncoherentScatter/'
mhdir = ask('directory for ISR data',mhdir)
filename = mhdir+"mh*.dat"
mhfl = findfile(filename)
mhf = n_elements(mhfl_new)
filetime = intarr(6)
for ifile = 1, mhf-1 do begin
    filetime(0) = strmid(mhfilelist_new(ifile),6,4)
    filetime(1) = strmid(mhfilelist_new(ifile),4,2)
    filetime(2) = strmid(mhfilelist_new(ifile),2,2)
    c_a_to_r,filetime,frtime
    if frtime lt stime then sfile = ifile
    if frtime gt etime then efile = ifile
endfor

mhfiles_new = efile - sfile
if n_elements(mhfiles) gt 0 then begin
    if (mhfiles_new eq mhfiles) then default = 'n' else default='y'
    GetNewMHData = mklower(strmid(ask('whether to reread data',default),0,1))
    if (GetNewMHData eq 'n') then GetNewMHData = 0 else GetNewMHData = 1
endif
mhfilelist_new = mhfl(sfile:efile)

if (GetNewMHData) then begin
    print, 'Getting Millstone Data...'    
    readmh, mhfilelist_new, mhdata, mhrtime, n_alts,datasize
endif

mhFiles = n_elements(mhfilelist_new)


stime = min(mhrtime)
etime = max(mhrtime)
time_axis,  stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
newtime = fltarr(n_alts,datasize)
for i = 0, datasize - 1 do begin
    for j = 0, n_alts - 1 do begin
        newtime(j,i) = mhrtime(i)
    endfor
endfor

mhnmf2 = fltarr(datasize)
mhhmf2 = fltarr(datasize)
stop
;for itime = 0, datasize-1 do begin
;    mhnmf2 = max(mhdata(
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
    


;;; Nm-F2 stuff ;;;;
default = 'n'
if whichvar eq 1 then default = 'y'

if default eq 'y' then begin
        donmf2 = 'y'
    donmf2 = ask('Do nmf2? ',donmf2)
        
    if donmf2 then begin
        tgcount = intarr(datasize)
        for j = 0, datasize - 1 do begin
            tgtemp2 = where(altarray(*,j) eq altarray(*,j) and $
                            altarray(*,j) gt 200 and altarray(*,j) le $
                            400 ,tcount)
            tgcount(j) = tcount 
        endfor
        
        hmf2times = where(tgcount gt 10)
        nptshm = n_elements(hmf2times)
        nmmhtime = rtime(hmf2times)
        nmf2 =fltarr(nptshm)
        hmf2 =fltarr(nptshm)
        
        for i = 0, n_elements(hmf2times)-1 do begin
            nmf2(i) = max(vararray(*,hmf2times(i)),ihmf2)
            hmf2(i) = altarray(ihmf2,hmf2times(i))
        endfor
        
        ;gitmnmf2 = fltarr(n_elements(gitmrtime))
        ;gitmhmf2 = fltarr(n_elements(gitmrtime))
        
        ;for i = 0, n_elements(gitmrtime)-1 do begin
        ;    gitmnmf2(i) = max(alog10(data(plotvar,*,i),igitmhmf2)
        ;    gitmhmf2(i) = data(ialtvar,igitmhmf2)
        ;endfor
        
get_position, ppp, space, sizes, 2, pos, /rect

pos(0) = pos(0) + 0.1

        i = 0
        j = 1
        ;setdevice,'othernm-f2.ps','l',5,.95    
        title = 'Nm-F2'
        yrange = [min(nmf2) - .01*min(nmf2),max(nmf2)+.01*max(nmf2)]
        
        plot,[min(nmmhtime),max(nmmhtime)]-stime,[0,12],/nodata,/noerase,$
          ytitle = 'log!D10!N'+vars1d(var)+' '+unit, yrange = yrange,pos = pos,$
          xtickname = strarr(10)+' ', xtickv = xtickv, xminor = xminor, $
          xticks = xtickn,xstyle = 1, ystyle = 1,charsize = 1.3
        while j lt nptshm do begin
            btdiff = nmmhtime(j) - nmmhtime(j-1)
            if (nmmhtime(j) - nmmhtime(j-1) gt 25000.) then begin
                
                oplot, nmmhtime(i:j-1)-stime, nmf2(i:j-1),psym = psym ,$
                  symsize = symsize,thick = 3
                loc = where(gitmrtime gt nmmhtime(i) and gitmrtime lt nmmhtime(j-1),count)
                if count gt 1 then begin
                    oplot, gitmrtime(loc)-stime,gitmnmf2(loc), color = 254,$
                      psym = psym, symsize= symsize,$
                      thick = 3
                endif
                i = j
            endif
            j = j+1
        endwhile
        xyouts, pos(2) + .04,pos(1)+.02, '(c) NmF2', $
          orientation = 90, /normal      

get_position, ppp, space, sizes, 3, pos, /rect

pos(0) = pos(0) + 0.1
        i = 0
        j = 1
        ;setdevice,'otherhm-f2.ps','l',5,.95    
        title = 'Hm-F2'
        yrange = [150,400]
        plot,[min(nmmhtime),max(nmmhtime)]-stime,[0,12],/nodata,/noerase,$
          ytitle = 'Altitude (km)', xtitle = xtitle,yrange = yrange,$
          xtickname = xtickname, xtickv = xtickv, xminor = xminor, $
          xticks = xtickn,xstyle = 1, ystyle = 1,charsize = 1.3,pos=pos
        while j lt nptshm do begin
            if (nmmhtime(j) - nmmhtime(j-1) gt 25000.) then begin
                oplot, nmmhtime(i:j-1)-stime, hmf2(i:j-1)$
                  ,thick = 3
                loc = where(gitmrtime gt nmmhtime(i) and gitmrtime lt nmmhtime(j-1),count)
                if count gt 1 then begin
                    oplot, gitmrtime(loc)-stime,gitmhmf2(loc), color = 254,$
                      thick = 3
                endif
                i = j
            endif
            j = j+1
        endwhile

        xyouts, pos(2) + .04,pos(1)+.02, '(d) HmF2', $
          orientation = 90, /normal
        legend,['MH data','GITM'],colors = [0,254],linestyle = [0,0],$
          pos=[.035,.2],/norm
       hcomp = intarr(n_elements(nmmhtime))
       for i = 0, n_elements(nmmhtime)-1 do begin
           htdiff = abs(gitmrtime - nmmhtime(i))
           minhtdiff = min(htdiff,imindiff)
           hcomp(i) = imindiff
       endfor 
       hdiff = gitmhmf2(hcomp) - hmf2
       hdiffmean = mean(hdiff)
       ndiff = abs(10^gitmnmf2(hcomp)-10^nmf2)/(10^gitmnmf2(hcomp))
       ndiffmean = mean(ndiff)
   endif
endif


end
