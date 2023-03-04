nmaxtimes = 10000
nmaxfiles = 300000
if n_elements(ndirs) eq 0 then ndirs = 1
ndirs = fix(ask('how many directories: ',tostr(ndirs)))
if n_elements(ndirsold) eq 0 then ndirsold = 0
if n_elements(dir) eq 0 or ndirs ne ndirsold then dir = strarr(ndirs)
for idir = 0, ndirs - 1 do begin
   dir(idir) = ask('directory ' +tostr(idir)+': ',dir(idir))
endfor


reread = 1
if n_elements(filelist) gt 0 and ndirsold eq ndirs then begin
   reread = 'n'
   reread = ask('whether to reread directories: ',reread)
   if strpos(reread,'y') ge 0 then reread = 1 else reread = 0
endif

savefile = file_search('filelist.sav',count = savcount)
if reread then begin

   readsav = 0
   if savcount gt 0 then begin
      print, 'A sav set with the names of the files exists'
      readsav = 'y'
      readsav = ask('read sav: ',readsav)
      if strpos(readsav,'y') ge 0 then readsav = 1 else readsav = 0
   endif

   if readsav then begin
      restore, savefile
   endif else begin
      
      filelist = strarr(ndirs,nmaxfiles)
      nfiles = intarr(ndirs)
      maxfiles = 0
      
      for idir = 0, ndirs - 1 do begin
         print, 'Working on directory: ',dir(idir)
         files = file_search(dir(idir)+'/[^13]*.bin',count = nf)
         filelist(idir,0:nf-1) = files
         nfiles(idir) = nf
      endfor
      print, ''
      maxfiles = max(nfiles,imaxdir)
      filelist = filelist(*,0:maxfiles-1)
      
      save,filelist,nfiles,maxfiles,dir,imaxdir,filename='filelist.sav'
   endelse
endif
  nf = maxfiles
ndirsold = ndirs

loc = ['']
tloc = ['']
oloc = ''
len = strpos(filelist(0,0),'/',/reverse_search,/reverse_offset)+1
for ifile = 0,nfiles(0) - 1 do begin
   nloc = strmid(filelist(0,ifile),len,3)
    if nloc ne oloc then loc = [loc,nloc]
    oloc = nloc
 endfor
nlocs = n_elements(loc) - 1
loc = loc(1:nlocs)

ntimes = 0
for iloc = 0, nlocs - 1 do begin
   files = file_search(dir(imaxdir)+'/'+loc(iloc)+'*.bin',count=num)
   if ntimes lt num then begin
      ntimes = num
      imaxloc = iloc
   endif
endfor

tfiles = file_search(dir(imaxdir)+'/'+loc(imaxloc)+'*.bin')
ntimes = n_elements(tfiles)
itimearr = intarr(6,ntimes)
rtime = dblarr(ntimes)

for itime = 0, ntimes - 1 do begin
    itimearr(*,itime) = get_gitm_time(tfiles(itime))
    c_a_to_r,itimearr(*,itime),rt
    rtime(itime) = rt
;    print, itime, itimearr(*,itime)
endfor

print, " "
print, tostr(nlocs)+" locations found"

hmf2 = fltarr(nlocs,nmaxtimes)
fof2 = fltarr(nlocs,nmaxtimes)
drtime = dblarr(nlocs,nmaxtimes)
frtime = dblarr(nlocs,nmaxtimes)
nodata = intarr(nlocs)
nodataf = intarr(nlocs)
close,1
itimemax = 0
ftimemax = 0
for iloc = 0, nlocs - 1 do begin
    datafile = $
      file_search('~/UpperAtmosphere/IONO/'+tostr(itimearr(0,0))+'/iono_*'+loc(iloc)+'*_hmF2.dat')
    
    if datafile eq '' then begin
        print, "hmF2 data not available for: "+loc(iloc)
        nodata(iloc) = 1
    endif else begin
        openr, 1,datafile(0)
        done = 0
        t = ' '
        itime = -1
        while not done do begin
            readf,1,t
            if strpos(t,'#START') ge 0 then done = 1
        endwhile

        while not eof(1) do begin
            itime = itime + 1
            readf,1,t
            tarr = strsplit(t,/extract)
            cyear = strmid(tarr(0),0,4)
            cmonth = strmid(tarr(0),5,2)
            cday = strmid(tarr(0),8,2)
            chour = strmid(tarr(1),0,2)
            cmin = strmid(tarr(1),3,2)
            it = fix([cyear,cmonth,cday,chour,cmin,'0'])
            c_a_to_r,it,rt
            drtime(iloc,itime) = rt
            
            hmf2(iloc,itime) = float(tarr(2))
        endwhile
        if itime gt itimemax then itimemax = itime
        close, 1
    endelse     

   datafile = $
      file_search('~/UpperAtmosphere/IONO/'+tostr(itimearr(0,0))+'/iono_*'+loc(iloc)+'*foF2.dat')
    
    if datafile eq '' then begin
        print, "foF2 data not available for: "+loc(iloc)
        nodataf(iloc) = 1
    endif else begin
        openr, 1,datafile(0)
        done = 0
        t = ' '
        itime = -1
        while not done do begin
            readf,1,t
            if strpos(t,'#START') ge 0 then done = 1
        endwhile

        while not eof(1) do begin
            itime = itime + 1
            readf,1,t
            tarr = strsplit(t,/extract)
            cyear = strmid(tarr(0),0,4)
            cmonth = strmid(tarr(0),5,2)
            cday = strmid(tarr(0),8,2)
            chour = strmid(tarr(1),0,2)
            cmin = strmid(tarr(1),3,2)
            it = fix([cyear,cmonth,cday,chour,cmin,'0'])
            c_a_to_r,it,rt
            frtime(iloc,itime) = rt
            
            fof2(iloc,itime) = float(tarr(2))
        endwhile
        if itime gt ftimemax then ftimemax = itime
        close, 1
    endelse         
endfor
hmf2 = hmf2(*,0:itimemax-1)
fof2 = fof2(*,0:ftimemax-1)
drtime = drtime(*,0:itimemax-1)
frtime = frtime(*,0:ftimemax-1)

dhmf2 = fltarr(nlocs,ntimes)
dfof2 = fltarr(nlocs,ntimes)
for itime = 0, ntimes - 1 do begin
    gettime = rtime(itime)
    for iloc =0, nlocs - 1 do begin
        if nodata(iloc) eq 0 then begin

            min = min(abs(drtime(iloc,*) - gettime),im)
            if min ge 30*60. then begin
                dhmf2(iloc,itime) = -99999.
            endif else begin
                if drtime(iloc,im) gt gettime then ilow = im - 1 else ilow = im
                if ilow eq -1 then ilow = 0
                r = (drtime(iloc,ilow+1) - gettime)/(drtime(iloc,ilow+1)-drtime(iloc,ilow))
                dhmf2(iloc,itime) = $
                  hmf2(iloc,ilow+1) -r*(hmf2(iloc,ilow+1)-hmf2(iloc,ilow))
      endelse
         endif

        if nodataf(iloc) eq 0 then begin

            min = min(abs(frtime(iloc,*) - gettime),im)
            if min ge 30*60. then begin
                dfof2(iloc,itime) = -99999.
            endif else begin
                if frtime(iloc,im) gt gettime then ilow = im - 1 else ilow = im
                if ilow eq -1 then ilow = 0
                r = (frtime(iloc,ilow+1) - gettime)/(frtime(iloc,ilow+1)-frtime(iloc,ilow))
                dfof2(iloc,itime) = $
                  fof2(iloc,ilow+1) -r*(fof2(iloc,ilow+1)-fof2(iloc,ilow))
      endelse
         endif


     endfor

   
 endfor
;dfo = dfof2

if n_elements(gitmhmf2) eq 0 then reread = 1 else reread = 0

if not reread then begin
   reread = 'n'
   reread = ask('whether to reread gitm results: ',reread)
   if strpos(reread,'y') ge 0 then reread = 1 else reread = 0
endif

if reread then begin
   
   readsav = 0
   savefile = file_search('gitmiono.sav',count = savcount)
   if savcount gt 0 then begin
      print, 'A sav set with the gitm ionosphere results exsits, use it?'
      readsav = 'y'
      readsav = ask('read sav: ',readsav)
      if strpos(readsav,'y') ge 0 then readsav = 1 else readsav = 0
   endif

   if readsav then begin
      restore, savefile
   endif else begin
   gitmhmf2 = fltarr(ndirs,nlocs,ntimes)
   gitmnmf2 = fltarr(ndirs,nlocs,ntimes)
   gitmTEC = fltarr(ndirs,nlocs,ntimes)
   gitmrtime = fltarr(ndirs,nlocs,ntimes)
   ngitmtimes = intarr(ndirs,nlocs)
   for idir = 0, ndirs - 1 do begin
      if idir eq 2 then startloc = 1 else startloc = 0
      for iloc = startloc, nlocs - 1 do begin
         flocs = where(strpos(filelist(idir,*),loc(iloc)) ge 0)
         filelist_new = filelist(idir,flocs)
         thermo_readsat, filelist_new, data, time, nTimesgitm, Vars, nAlts, nSats, Files
         
         if idir eq 0 and iloc eq 0 then begin
            alt = reform(data(0,0,2,*)) / 1000.
            locs = where(alt gt 200.0)
            ialt200 = locs(0)
            locs = where(alt lt 500)
            ialt500 = max(locs)
            
            dalt = fltarr(nalts-4)
            for ialt = 2,nalts - 3 do begin
               dalt(ialt-2) = ((alt(ialt+1)+alt(ialt))/2.- $
                               (alt(ialt)+alt(ialt-1))/2.)
            endfor
            evar = where(vars eq '[e-]')
         endif

            gitmrtime(idir,iloc,0:ntimesgitm-1) = time
            ngitmtimes(idir,iloc) = n_elements(time)
         for itime = 0, ntimesgitm - 1 do begin
            gitmNmF2(idir,iloc,itime) = max(data(0,itime,evar,ialt200:ialt500),ihmf2)
            gitmHmF2(idir,iloc,itime) = alt(ihmf2+ialt200)
            gitmTEC(idir,iloc,itime) = total(data(0,itime,evar,2:nalts-3)*dalt*1000.0)
         endfor
      endfor
   endfor

      save,gitmnmf2,gitmhmf2,gitmtec,gitmrtime,alt,ngitmtimes,filename='gitmiono.sav'
   endelse
endif

dfof2 = ((dfof2/9.0e-3)^2./1e-6)
gitmfof2 = gitmnmf2;9.0e-3*sqrt(gitmnmf2*1e-6)

;variables = ['FoF2','HmF2']
;display, variables
;if n_elements(pvar) eq 0 then pvar = 0
;pvar = fix(ask('Which variable to plot: ',tostr(pvar)))
; 
;if pvar eq 0 then begin
;   gitmfof2 = gitmfo
;   dfof2 = dfo
;endif else begin
;   gitmfof2 = gitmhmf2
;   dfof2 = dfo
;endelse


gitmmean = fltarr(nlocs,ntimes)
gitmmax = fltarr(nlocs,ntimes)
gitmmin = fltarr(nlocs,ntimes)


tlocs = intarr(ndirs)
valarr = fltarr(ndirs)
for iloc = 0, nlocs - 1 do begin
   for itime = 0, ntimes - 1 do begin
      gettime = rtime(itime)
      gettime2 = gettime + 24*3600.
      for idir = 0, ndirs - 1 do begin
         tmin = min(abs(gitmrtime(idir,iloc,*) - gettime),imin)

         if tmin le 15*60. then begin
            tlocs(idir) = imin 
            valarr(idir) = gitmfof2(idir,iloc,imin)
         endif else begin
            tlocs(idir) = -1
            valarr(idir) = 1/0.
         endelse
      endfor

      gitmmean(iloc,itime) = mean(valarr,/nan)
      gitmmin(iloc,itime) = min(valarr,/nan)
      gitmmax(iloc,itime) = max(valarr,/nan)

      
   endfor
endfor 

totaltime = max(rtime) - rtime(0)
ndays = totaltime/24./3600. + 1
daytime = dblarr(ndays)
gitmdaymean = fltarr(nlocs,ndays)
gitmdaymin = fltarr(nlocs,ndays)
gitmdaymax = fltarr(nlocs,ndays) 
gitmdaystdev = fltarr(nlocs,ndays)
gitmdayupper =  fltarr(nlocs,ndays)
gitmdaylower =  fltarr(nlocs,ndays)

datadaymean = fltarr(nlocs,ndays)
datadaymin = fltarr(nlocs,ndays)
datadaymax = fltarr(nlocs,ndays) 
datadaystdev = fltarr(nlocs,ndays)
datadayupper = fltarr(nlocs,ndays)
datadaylower = fltarr(nlocs,ndays)


c_r_to_a,itimestart,min(rtime)
itimestart(3:5) = 0
c_a_to_r,itimestart,starttime
for iday = 0,ndays - 1 do begin
   lowtime = starttime + iday*24*3600.
   hightime = lowtime + 24*3600.
   daytime(iday) = (lowtime+hightime)/2.

   for iloc = 0, nlocs -1 do begin
      arr = [1]
      for idir = 0, ndirs - 1 do begin
         locs = where(gitmrtime(idir,iloc,*) ge lowtime and gitmrtime(idir,iloc,*) lt hightime,count)
         if count gt 0 then values = gitmfof2(idir,iloc,locs) else values = transpose([-9999,-9999])
         arr = [arr,transpose(values)]
      endfor
      arr = arr(1:n_elements(arr)-1)
      
      goodlocs = where(arr ge 0, gcount)
      badlocs = where(arr lt 0,count)
      if count gt 0 then arr(badlocs) = -9999
      if gcount gt 0 then begin
         rstat,arr(goodlocs),Med,Hinge1, Hinge2, Ifence1, Ifence2, Ofence1, Ofence2, Mind, Maxd
         gitmdaymean(iloc,iday) = mean(arr(goodlocs))
         gitmdaymin(iloc,iday) = min(arr(goodlocs))
         gitmdaymax(iloc,iday) = max(arr(goodlocs))
         gitmdaystdev(iloc,iday) = stddev(arr(goodlocs))
         gitmdayupper(iloc,iday) = Hinge2
         gitmdaylower(iloc,iday) = Hinge1
      endif else begin
          gitmdaymean(iloc,iday) = -9999
         gitmdaymin(iloc,iday) = -9999
         gitmdaymax(iloc,iday) = -9999
         gitmdaystdev(iloc,iday) = -9999
         gitmdayupper(iloc,iday) = -9999
         gitmdaylower(iloc,iday) = -9999
      endelse

      locs = where(rtime ge lowtime and rtime lt hightime)
      values = dfof2(iloc,locs)
      badlocs = where(values lt 0 or values gt 80,count)
      if count gt 0 then values(badlocs) = -99999
      goodlocs = where(values gt 0 and values lt 80,gcount)
      
      if gcount gt 0 then begin
         rstat,values(goodlocs),Med,Hinge1, Hinge2, Ifence1, Ifence2, Ofence1, Ofence2, Mind, Maxd
         datadaymean(iloc,iday) = mean(values(goodlocs))
         datadaymin(iloc,iday) = min(values(goodlocs))
         datadaymax(iloc,iday) = max(values(goodlocs))
         datadaystdev(iloc,iday) = stdev(values(goodlocs))
         datadayupper(iloc,iday) = Hinge2
         datadaylower(iloc,iday) = Hinge1
      endif else begin
         datadaymean(iloc,iday) = -9999
         datadaymin(iloc,iday) = -9999
         datadaymax(iloc,iday) = -9999
         datadaystdev(iloc,iday) = -9999
         datadayupper(iloc,iday) = -9999
         datadaylower(iloc,iday) = -9999
      endelse

     
   endfor



endfor
   
doepoch = 0
if doepoch then begin
readsav = 0
   savefile = file_search('gitmaverages.sav',count = savcount)
   if savcount gt 0 then begin
      print, 'A sav set with the gitm ionosphere epoch results exsits, use it?'
      readsav = 'y'
      readsav = ask('read sav: ',readsav)
      if strpos(readsav,'y') ge 0 then readsav = 1 else readsav = 0
   endif

   if readsav then begin
      restore, savefile
   endif else begin
nepochs = 4*24.
eptime = dblarr(nepochs)
gitmepmean = fltarr(nlocs,nepochs)
gitmepmin = fltarr(nlocs,nepochs)
gitmepmax = fltarr(nlocs,nepochs) 
gitmepstdev = fltarr(nlocs,nepochs)
gitmepupper =  fltarr(nlocs,nepochs)
gitmeplower =  fltarr(nlocs,nepochs)

dataepmean = fltarr(nlocs,nepochs)
dataepmin = fltarr(nlocs,nepochs)
dataepmax = fltarr(nlocs,nepochs) 
dataepstdev = fltarr(nlocs,nepochs)
dataepupper = fltarr(nlocs,nepochs)
dataeplower = fltarr(nlocs,nepochs)

nsec = fltarr(ndirs,nlocs,ntimes)
dnsec = fltarr(ndirs,nlocs,ntimes)
for iep = 0, nepochs - 1 do begin
   eptime(iep) = starttime + (iep *15*60.) + 15*60.
   
    for iloc = 0, nlocs -1 do begin
      arr = [1]
      for idir = 0, ndirs - 1 do begin
        
          for itime = 0, ntimes - 1 do begin
            c_r_to_a,timearr,gitmrtime(idir,iloc,itime)
           hour = timearr(3)
            min = timearr(4)
            sec = timearr(5)
            if timearr(0) gt 1990 then nsec(idir,iloc,itime) = min * 60 + hour * 3600. + sec $ 
               else nsec(idir,iloc,itime) = -9999

            c_r_to_a,dta,rtime(itime)
            hour = dta(3)
            min = dta(4)
            sec = dta(5)
            if dta(0) gt 1990 then dnsec(itime) = min * 60 + hour * 3600. + sec $ 
               else dnsec(itime) = -9999

         endfor
       endfor
      
      sarr = nsec(*,iloc,*)
      locs = where(abs(sarr - (eptime(iep) - starttime)) lt 65.,gcount)
      tarr = reform(gitmfof2(*,iloc,*))
      if gcount gt 0 then  arr = tarr(locs) else arr = -9999
      goodlocs = where(arr ge 0, gcount)
      badlocs = where(arr lt 0,count)
      if count gt 0 then arr(badlocs) = -9999
      if gcount gt 0 then begin
       
         rstat,arr(goodlocs),Med,Hinge1, Hinge2, Ifence1, Ifence2, Ofence1, Ofence2, Mind, Maxd
         gitmepmean(iloc,iep) = mean(arr(goodlocs))
         gitmepmin(iloc,iep) = min(arr(goodlocs))
         gitmepmax(iloc,iep) = max(arr(goodlocs))
         gitmepstdev(iloc,iep) = stddev(arr(goodlocs))
         gitmepupper(iloc,iep) = Hinge2
         gitmeplower(iloc,iep) = Hinge1
      endif else begin
          gitmepmean(iloc,iep) = -9999
         gitmepmin(iloc,iep) = -9999
         gitmepmax(iloc,iep) = -9999
         gitmepstdev(iloc,iep) = -9999
         gitmepupper(iloc,iep) = -9999
         gitmeplower(iloc,iep) = -9999
      endelse

      locs = where(abs(dnsec - (eptime(iep) - starttime)) lt 65.,gcount)
      if gcount gt 0 then  values = dfof2(iloc,locs) else values = -99999
      badlocs = where(values lt 0 or values gt 80,count)
      if count gt 0 then values(badlocs) = -99999
      goodlocs = where(values gt 0 and values lt 80,gcount)
      
      if gcount gt 0 then begin
         rstat,values(goodlocs),Med,Hinge1, Hinge2, Ifence1, Ifence2, Ofence1, Ofence2, Mind, Maxd
         dataepmean(iloc,iep) = mean(values(goodlocs))
         dataepmin(iloc,iep) = min(values(goodlocs))
         dataepmax(iloc,iep) = max(values(goodlocs))
         dataepstdev(iloc,iep) = stdev(values(goodlocs))
         dataepupper(iloc,iep) = Hinge2
         dataeplower(iloc,iep) = Hinge1
      endif else begin
         dataepmean(iloc,iep) = -9999
         dataepmin(iloc,iep) = -9999
         dataepmax(iloc,iep) = -9999
         dataepstdev(iloc,iep) = -9999
         dataepupper(iloc,iep) = -9999
         dataeplower(iloc,iep) = -9999
      endelse


   endfor


endfor
save,gitmepmean,gitmepmin,gitmepmax,gitmepstdev,gitmepupper,gitmeplower,$
     eptime,nepochs,dataepmean,dataepmin,dataepmax,dataepstdev,dataepupper,$
     dataeplower,nepochs,nsec,dnsec,filename='gitmaverages.sav'
endelse
endif
;for iloc = 0, nlocs - 1 do begin
;   for itime = 0, max(ngitmtimes(
setdevice, 'plot.ps','p',5,.95
ppp = 6
 space = 0.1
 pos_space, ppp, space, sizes
 
timelocs = where(gitmrtime gt 0)
 stime = min(gitmrtime(timelocs))
etime = max(gitmrtime)
time_axis, stime, etime,btr,etr, xticknames, xtitle, xtickv, xminor, xtickn
len = strpos(xtitle,'Univers')
xtitles = strmid(xtitle,0,len-1)+' UT'
xrange = [0,etime - stime]

dlocs = where(nodata eq 0)
nl = n_elements(dlocs)

window = 0;18*60/15./2
 loadct, 39


for il = 0, nlocs - 1 do begin
    get_position, ppp, space, sizes, il mod ppp, pos, /rect

    yrange = mm(gitmmean)
    yrange(0) = min(gitmmin(il,*))
    yrange(1) = max(gitmmax(il,*),/nan)
    if il mod ppp eq 0 then plotdumb
    
    plot, rtime - stime,/nodata,yrange = yrange,xrange = xrange , $
          xtickname = xticknames, xtitle = xtitle,xticks=xtickn,xtickv=xtickv, $
          xminor=xminor,ytitle = loc(il) + ' NmF2',/noerase,pos=pos

       val = smooth(gitmmean(il,*),window,/nan)
       oplot, rtime-stime,val,thick = 3,color = 1,linestyle = 0,max_value = 1e20

       val = smooth(gitmmin(il,*),window,/nan)
       oplot, rtime-stime,val,thick = 3,color = 1,linestyle = 2,max_value = 1e20

       val = smooth(gitmmax(il,*),window,/nan)
       oplot, rtime-stime,val,thick = 3,color = 1,linestyle = 2,max_value = 1e20
;stop
;    endfor
;    plot, rtime - stime,/nodata,yrange = yrange,xrange = xrange, $
;      xtickname = xtickname, xtitle = xtitle,xticks=xtickn,xtickv=xtickv, $
;      xminor=xminor,ytitle = loc(iloc) + ' HmF2',/noerase,pos=pos
       frelocs = where(dfof2(il,*) gt 0 and dfof2(il,*) lt 1.e12 )
    if n_elements(frelocs) ge 2 then begin
       dval = smooth(dfof2(il,frelocs), window,/nan)
       oplot, rtime(frelocs) - stime, dval,color = 254,thick=1
    endif
endfor
closedevice

 setdevice, 'dayplot.ps','p',5,.95
 ppp = 9
  space = 0.03
  pos_space, ppp, space, sizes
 
 for il = 1, nlocs - 1 do begin
     get_position, ppp, space, sizes, il-1 mod ppp, pos, /rect
     locs = where(gitmdaymean(il,*) gt 0)
     dlocs = where(datadaymean(il,*) gt 0 and datadaymean(il,*) lt 2000)
     
  if il-1 mod ppp eq 0 then plotdumb
  if il - 1 lt 6 then begin
     xtitle = ' ' 
     xtickname = strarr(10) + ' '
     endif else begin
        xtitle = xtitles
        xtickname = xticknames
     endelse
     
  if il-1 ne 0 and il - 1 ne 3 and il - 1 ne 6 then begin
     ytickname = strarr(10) + ' '
     ytitle = ' '
  endif else begin
     ytickname = tostr([0,2,4,6,8,10,12])
     ytitle = 'F!Do!NF!D2!N (Mhz)'
  endelse

   yrange = mm(gitmdaymean)
     yrange(0) = min([min(gitmdaymin(il,locs)),min(datadaymin(il,dlocs))])
     yrange(1) = max([max(gitmdaymax(il,locs)),max(datadaymax(il,dlocs))],/nan)
yrange = [0,12]
     plot, daytime - stime,/nodata,yrange = yrange,xrange = xrange , $
           xtickname = xtickname, xtitle = xtitle,xticks=xtickn,xtickv=xtickv, $
           xminor=xminor,/noerase,pos=pos,ytickname=ytickname,ytitle= ytitle

     oplot, daytime(locs)-stime,gitmdaymean(il,locs),thick = 3,color = 1,linestyle = 0,max_value = 1e20
     oplot, daytime(locs)-stime,gitmdaymin(il,locs),thick = 3,color = 1,linestyle = 2,max_value = 1e20
     oplot, daytime(locs)-stime,gitmdaymax(il,locs),thick = 3,color = 1,linestyle = 2,max_value = 1e20

     oplot,daytime(dlocs)-stime,datadaymean(il,dlocs),color=254,max_value=1e12,thick = 2
     oplot,daytime(dlocs)-stime,datadaymin(il,dlocs),color=254,max_value=1e12,linestyle = 2,thick = 2
     oplot,daytime(dlocs)-stime,datadaymax(il,dlocs),color=254,max_value=1e12,linestyle = 2,thick = 2

     xyouts,pos(0)+.01,pos(3)-.03,loc(il) ,/norm
     if il-1 eq 4 then begin
         legend,['GITM','Data'],color = [0,254],pos=[pos(0)+.1,pos(3)-.015],box=2,/norm,linestyle=[0,0],$
                thick = 3
      endif
  endfor

closedevice

if doepoch then begin
 setdevice, 'epochplot.ps','p',5,.95
 ppp = 9
  space = 0.03
  pos_space, ppp, space, sizes
 
stime = min(eptime)
etime = max(eptime)
time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xticknr
len = strpos(xtitle,'UT')
xtitles = strmid(xtitle,len)
xrange = [0,etime-stime]
xticknames = ['04','08','12','16','20','24']
 xtickn = n_elements(xticknames)-1
xtickv = fltarr(xtickn+1)
for itick = 0, xtickn do begin
   xtickv(itick) = fix(xticknames(itick))*3600.
endfor

 for il = 1, nlocs - 1 do begin
     get_position, ppp, space, sizes, il-1 mod ppp, pos, /rect
     locs = where(gitmepmean(il,*) gt 0)
     dlocs = where(dataepmean(il,*) gt 0 and dataepmean(il,*) lt 2000)

  if il-1 mod ppp eq 0 then plotdumb
if il-1 mod ppp eq 0 then plotdumb
  if il - 1 lt 6 then begin
     xtitle = ' ' 
     xtickname = strarr(10) + ' '
     endif else begin
        xtitle = xtitles
        xtickname = xticknames
     endelse
     
  if il-1 ne 0 and il - 1 ne 3 and il - 1 ne 6 then begin
     ytickname = strarr(10) + ' '
     ytitle = ' '
  endif else begin
     ytickname = tostr([0,2,4,6,8,10,12])
     ytitle = 'F!Do!NF!D2!N (Mhz)'
  endelse

  yrange = mm(gitmepmean)
  yrange(0) = min([min(gitmepmin(il,locs)),min(dataepmin(il,dlocs))])
     yrange(1) = max([max(gitmepmax(il,locs)),max(dataepmax(il,dlocs))],/nan)
yrange = [0,12]
     plot, eptime - stime,/nodata,yrange = yrange,xrange = xrange , $
           xtickname = xtickname, xtitle = xtitle,xticks=xtickn,xtickv=xtickv, $
           xminor=xminor,ytitle = ytitle,/noerase,pos=pos,ytickname=ytickname

     oplot, eptime(locs)-stime,gitmepmean(il,locs),thick = 3,color = 1,linestyle = 0,max_value = 1e20
     oplot, eptime(locs)-stime,gitmepmin(il,locs),thick = 3,color = 1,linestyle = 2,max_value = 1e20
     oplot, eptime(locs)-stime,gitmepmax(il,locs),thick = 3,color = 1,linestyle = 2,max_value = 1e20
;     oplot, eptime(locs)-stime,gitmeplower(il,locs),thick = 3,color = 1,linestyle = 2,max_value = 1e20
;     oplot, eptime(locs)-stime,gitmepupper(il,locs),thick = 3,color = 1,linestyle = 2,max_value = 1e20

     oplot,eptime(dlocs)-stime,dataepmean(il,dlocs),color=254,max_value=1e12,thick=2
     oplot,eptime(dlocs)-stime,dataepmin(il,dlocs),color=254,max_value=1e12,linestyle = 2,thick = 2
     oplot,eptime(dlocs)-stime,dataepmax(il,dlocs),color=254,max_value=1e12,linestyle = 2,thick = 2
;     oplot,eptime(dlocs)-stime,dataeplower(il,dlocs),color=254,max_value=1e12,linestyle = 2
;     oplot,eptime(dlocs)-stime,dataepupper(il,dlocs),color=254,max_value=1e12,linestyle = 2

 xyouts,pos(0)+.01,pos(3)-.03,loc(il) ,/norm
     if il-1 eq 4 then begin
         legend,['GITM','Data'],color = [0,254],pos=[pos(0)+.1,pos(3)-.015],box=2,/norm,linestyle=[0,0],$
                thick = 3
      endif
  endfor
    

closedevice
endif
end
