GetNewData = 1

if n_elements(directorypert) eq 0 then directorypert = '.'
if n_elements(directorybase) eq 0 then directorybase = '.'
directorypert = ask('perturbation directory: ',directorypert)
directorybase = ask('base directory: ',directorybase)

filelist_newpert = findfile(directorypert+'/3DALL*.bin')
filelist_newbase = findfile(directorybase+'/3DALL*.bin')

nfiles_new = min([n_elements(filelist_newpert),n_elements(filelist_newbase)],smalldir)
locs = intarr(nfiles_new)


if n_elements(filename) eq 0 then begin
filename = filelist_newpert(0)
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

for ivars = 0, nvars - 1 do print, ivars, ' ',vars(ivars)
if n_elements(ivar) eq 0 then ivar = 3
ivar = fix(ask('which variable to plot: ',tostr(ivar)))

alts = reform(data1(2,0,0,*))/1000.
for ialt = 2,nalts - 3 do begin
    dalts(ialt-2) = ((alts(ialt+1)+alts(ialt))/2.- $
                    (alts(ialt)+alts(ialt-1))/2.) * 1000.0
endfor

for ialt = 0, nalts - 1 do print, ialt,'  ',alts(ialt)
if n_elements(ialt1) eq 0 then ialt1 = 0
if n_elements(ialt2) eq 0 then ialt2 = 0

ialt1 = fix(ask('first altitude to plot: ',tostr(ialt1)))
ialt2 = fix(ask('second altitude to plot: ',tostr(ialt2)))
re = 6378.

vn = where(vars eq 'V!Dn!N(north)')
ve = where(vars eq 'V!Dn!N(east)')

if (GetNewData) then begin

   lenpert = strlen(directorypert) + 1+13-2-2
   lenbase = strlen(directorybase) + 1+13-2-2

   if smalldir eq 0 then begin
       for ifile = 0, nfiles_new-1 do begin
           locs(ifile) = where(strmid(filelist_newbase,lenbase,7) eq $
                               strmid(filelist_newpert(ifile),lenpert,7))
       endfor
       filelist1 = filelist_newpert
       filelist2 = filelist_newbase
   endif else begin
       for ifile = 0, nfiles_new-1 do begin
           locs(ifile) = where(strmid(filelist_newpert,lenpert,7) eq $
                               strmid(filelist_newbase(ifile),lenbase,7))
       endfor
       filelist1 = filelist_newbase
       filelist2 = filelist_newpert
   endelse

   loc = where(locs ne -1)
   nf = n_elements(locs)
   rtime = fltarr(nf)
   nfiles = nfiles_new
   iTimeArray = intarr(6,nf)
  
   maxdiffsza = fltarr(nfiles)
   daydata1 = fltarr(nfiles,nvars,nalts)
   nightdata1 = fltarr(nfiles,nvars,nalts)
   daydata2 = fltarr(nfiles,nvars,nalts)
   nightdata2 = fltarr(nfiles,nvars,nalts)
   maxdata = fltarr(nfiles,nvars,nalts)
   mindata = fltarr(nfiles,nvars,nalts)
   avedata = fltarr(nfiles,nvars,nalts)
   
   daymax = fltarr(nfiles,nvars,nalts)
   nightmax = fltarr(nfiles,nvars,nalts)
   maxtec = fltarr(nfiles)
   mintec = fltarr(nfiles)
   avetec = fltarr(nfiles)
   TEC1 = fltarr(nlons,nlats)
   TEC2 = fltarr(nlons,nlats)
   max1 = fltarr(nfiles,nvars,nalts)
   max2 = fltarr(nfiles,nvars,nalts)
   binres = 7.5
   nbins = fix(180/(binres))
   szabinhigh = findgen(nbins)*binres+5
   szabinlow = findgen(nbins)*binres
   binavg1 = fltarr(nbins,nfiles,nvars,nalts)
   binavg2 = fltarr(nbins,nfiles,nvars,nalts)
   eqdiff = fltarr(nfiles,nlons-4)
   winddotgradsza = fltarr(nfiles,nlons,nlats,nalts) 
   windmag = fltarr(nfiles,nlons,nlats,nalts)
   szagradmag = fltarr(nfiles,nlons,nlats)
   for iFile = 0, nf - 1 do begin
       
       filename1 = filelist1(loc(ifile))
       filename2 = filelist2(locs(ifile))
       
       print, 'Reading files ',filename1, ' and ',filename2
       
       read_thermosphere_file, filename1, nvars, nalts, nlats, nlons, $
         vars, data1, rb, cb, bl_cnt

       read_thermosphere_file, filename2, nvars_t, nalts, nlats, nlons, $
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
       itimearray(*,ifile) = itime

       if year lt 50 then iyear = year + 2000 else iyear = year + 1900
       stryear = strtrim(string(iyear),2)
       strmth = strtrim(string(mont),2)
       strday = strtrim(string(day),2)
       uttime = hour+minu/60.+seco/60./60.
       
       strdate = stryear+'-'+strmth+'-'+strday
       
       daypos = fltarr(nlons,nlats)
       nightpos = fltarr(nlons,nlats)
       daycount = 0
       nightcount = 0
       tempdata1 = [0]
       tempdata2 = [0]
       
       szaarr = fltarr(nlons,nlats)  

       latinds = fltarr(nlons,nlats)
       latt = findgen(nlats)
       for ilon = 0, nlons - 1 do latinds(ilon,*) = latt
       for ilat = 0, nlats - 1 do begin
           for ilon = 0, nlons - 1 do begin
               lat = data1(1,0,ilat,0)*180/!pi
               lon = data1(0,ilon,0,0)*180/!pi
               zsun,strdate,uttime ,lat,lon, zenith,azimuth,solfac
               szaarr(ilon,ilat) = zenith
               
               ;;;;TEC STUFF ;;;;;;;;;;;;;;;;;;
               if vars(ivar) eq '[e-]' then begin
                   if smalldir eq 0 then begin
                       TEC1(ilon,ilat) = $
                         total(data1(ivar,ilon,ilat,2:nalts-3)*dalts)
                       TEC2(ilon,ilat) = $
                         total(data2(ivar,ilon,ilat,2:nalts-3)*dalts)
                       maxTEC(ifile) = $
                         max((TEC1-TEC2)/TEC2)*100.0
                       minTEC(ifile) =  $
                         min((TEC1-TEC2)/TEC2)*100.0
                       aveTEC(ifile) =  $
                         mean((TEC1-TEC2)/TEC2)*100.0
                   endif else begin
                      TEC1(ilon,ilat) = $
                         total(data2(ivar,ilon,ilat,2:nalts-3)*dalts*1000.0)
                       TEC2(ilon,ilat) = $
                         total(data1(ivar,ilon,ilat,2:nalts-3)*dalts*1000.0)
                       maxTEC(ifile) = $
                         max((TEC1-TEC2)/TEC2)*100.0
                       minTEC(ifile) =  $
                         min((TEC1-TEC2)/TEC2)*100.0
                       aveTEC(ifile) =  $
                         mean((TEC1-TEC2)/TEC2)*100.0
                   endelse
               endif
           endfor
       endfor

       dayloc = where(szaarr lt 30)
       nightloc = where(szaarr gt 150)
       
       eqdiff(ifile,*) = data1(16,2:nlons-3,nlats/2.,36) - data2(16,2:nlons-3,nlats/2.,36)
       for ivars = 0, nvars - 1 do begin
           celltotal = 0
          
           for ialts = 0, nalts - 1 do begin
               datatemp1 = reform(data1(ivars,*,*,ialts))
               datatemp2 = reform(data2(ivars,*,*,ialts))
               
               if smalldir eq 0 then begin
                  
                   maxdata(ifile,ivars,ialts) = max((datatemp1-datatemp2) / $
                                                    datatemp2,imax)*100.
                   mindata(ifile,ivars,ialts) = min((datatemp1-datatemp2) / $
                                                    datatemp2,imin)*100.
                   avedata(ifile,ivars,ialts) = mean((datatemp1-datatemp2) / $
                                                    datatemp2)*100.
                   
                   daymax(ifile,ivars,ialts) = max((datatemp1(dayloc)-datatemp2(dayloc)) / $
                                                    datatemp2(dayloc),idaymax)
                   nightmax(ifile,ivars,ialts) = max((datatemp1(nightloc)-datatemp2(nightloc)) / $
                                                    datatemp2(nightloc),inightmax)

               endif else begin
                   maxdata(ifile,ivars,ialts) =  max((datatemp2-datatemp1) / $
                                                     datatemp1,iave)*100.
                   mindata(ifile,ivars,ialts) = min((datatemp2-datatemp1) / $
                                                    datatemp1,iave)*100.
                   avedata(ifile,ivars,ialts) = mean((datatemp2-datatemp1) / $
                                                    datatemp1,iave)*100.

                   daymax(ifile,ivars,ialts) = max((datatemp2(dayloc)-datatemp1(dayloc)) / $
                                       datatemp1(dayloc),idaymax)
                   nightmax(ifile,ivars,ialts) = max((datatemp2(nightloc)-datatemp1(nightloc)) / $
                                         datatemp1(nightloc),inightmax)
               endelse

               daydata1(ifile,ivars,ialts) = mean(datatemp1(dayloc))
               daydata2(ifile,ivars,ialts) = mean(datatemp2(dayloc))
               nightdata1(ifile,ivars,ialts) = mean(datatemp1(nightloc))
               nightdata2(ifile,ivars,ialts) = mean(datatemp2(nightloc))
              

;Gradient of SZA
               gradlatsza = fltarr(nlons,nlats)
               gradlonsza = fltarr(nlons,nlats)
                              
               dellon = (data1(0,4,0,0)-data1(0,2,0,0))*(re+alts(ialt2))
               dellat = (data1(1,0,4,0)-data1(1,0,2,0))*(re+alts(ialt2))
               gradlonsza(2:nlons-3,2:nlats-3) = $
                 (szaarr(3:nlons-2,2:nlats-3) - szaarr(1:nlons-4,2:nlats-3))/dellon
               gradlatsza(2:nlons-3,2:nlats-3) = $
                 (szaarr(2:nlons-3,3:nlats-2) - szaarr(2:nlons-3,1:nlats-4))/dellat
               
               vnorth = reform(data1(vn,*,*,ialts));-data2(vn,*,*,ialt2))
               veast = reform(data1(ve,*,*,ialts));-data2(ve,*,*,ialt2))
               winddotgradsza(ifile,*,*,ialts) = $
                 vnorth*gradlatsza + veast*gradlonsza
               
               windmag(ifile,*,*,ialts) = (vnorth^2+veast^2)^.5
               szagradmag(ifile,*,*) = $
                 (gradlatsza^2 + gradlonsza^2)^.5
                 
               celltotal = 0

               if ialts gt 1 and ialts lt nalts - 2 then begin
                   dalt = (data1(2,0,0,ialts) - data1(2,0,0,ialts-1))/1000.
                   
                   latavg = (data1(1,0,3:nlats-3,0) + data1(1,0,2:nlats-4,0))/2.
                   
                   cellvol = ((re+alts(ialts))^2*abs(cos(latavg(0,0,*))))*dalt*$
                     (dlat*!dtor*dlon*!dtor)
                  
                   for ibin = 0, nbins - 1 do begin
                       binloc = where(szaarr ge szabinlow(ibin) and szaarr lt szabinhigh(ibin))
                       latindex = latinds(binloc)
                       celltotal = total(cellvol(latindex))
                       binavg1(ibin,ifile,ivars,ialts) = $
                         total(datatemp1(binloc)*cellvol(latindex))/celltotal
                       binavg2(ibin,ifile,ivars,ialts) = $
                         total(datatemp2(binloc)*cellvol(latindex))/celltotal
                   endfor
               endif
           endfor
           if ivars eq ivar then maxdiffsza(ifile) = szaarr(imax)
       endfor
   endfor

   stime = rtime(0)
   etime = max(rtime)
   
   time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
   
   save,/all,filename = savetime+'.sav'
endif
 
if smalldir eq 0 then begin
    daydiff =  (daydata1 - daydata2)/daydata2*100
    nightdiff = (nightdata1 - nightdata2)/nightdata2*100
    bindiff = (binavg1 - binavg2)/binavg2*100
endif else begin
    daydiff = (daydata2 - daydata1)/daydata1*100
    nightdiff = (nightdata2 - nightdata1)/nightdata1*100
    bindiff = (binavg2 - binavg1)/binavg1*100
endelse


dayv1 = (daydiff(*,ivar,ialt1))
dayv2 = (daydiff(*,ivar,ialt2))
nightv1 = (nightdiff(*,ivar,ialt1))
nightv2 = (nightdiff(*,ivar,ialt2))
daymax1 = daymax(*,ivar,ialt1)*100.0
daymax2 = daymax(*,ivar,ialt2)*100.0
nightmax1 = nightmax(*,ivar,ialt1)*100.0
nightmax2 = nightmax(*,ivar,ialt2)*100.0
binplot1 = bindiff(*,*,ivar,ialt1)
binplot2 = bindiff(*,*,ivar,ialt2)


xrange = [0,etime - stime]
yranged1 = [.95*min(dayv1),1.05*max(daymax1)]
yranged2 = [.95*min(dayv2),1.05*max(daymax2)]
yrangen1 = [.95*min(nightv1),1.05*max(nightmax1)]
yrangen2 = [.95*min(nightv2),1.05*max(nightmax2)]
ybr1 = [.95*min(binplot1),1.05*max(binplot1)]
ybr2 = [.95*min(binplot2),1.05*max(binplot2)]
;ybr2 = [-2,2]
ppp = 4
space = 0.01
pos_space, ppp, space, sizes, ny = ppp
    
 get_position, ppp, space, sizes, 0, pos, /rect
pos(0) = pos(0) + .1
variable = strmid(vars(ivar),0,4)
if variable eq '[e-]' then variable = 'e-'
setdevice,"avecomp_"+tostr(itime(2))+"_"+variable+".ps",'p',5,.95
plot, rtime-stime,/nodata, ytitle = strmid(vars(ivar),0,4) + ' % diff', /noerase, $
          xtickname = strarr(10)+' ', xtickv = xtickv, xrange = xrange,$
          xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
          yrange = yranged1, ystyle = 1, thick = 3, charsize = 1.2

oplot,rtime-stime,dayv1
oplot,rtime-stime,daymax1,linestyle = 2
xyouts, pos(0)+.05,pos(3)-.03,'Dayside average at '+tostr(alts(ialt1))+ ' km',/norm

get_position, ppp, space, sizes, 1, pos, /rect
pos(0) = pos(0) + .1
plot, rtime-stime,/nodata, ytitle = strmid(vars(ivar),0,4) + ' % diff', /noerase, $
          xtickname = strarr(10)+' ', xtickv = xtickv, xrange = xrange, $
          xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
          yrange = yranged2, ystyle = 1, thick = 3, charsize = 1.2

oplot,rtime-stime,dayv2
oplot,rtime-stime,daymax2,linestyle = 2
xyouts, pos(0)+.05,pos(3)-.03,'Dayside average at '+tostr(alts(ialt2))+ ' km',/norm

get_position, ppp, space, sizes, 2, pos, /rect
pos(0) = pos(0) + .1
plot, rtime-stime,/nodata, ytitle = strmid(vars(ivar),0,4) + ' % diff', /noerase, $
          xtickname = strarr(10)+' ', xtickv = xtickv, xrange = xrange,$
          xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
          yrange = yrangen1, ystyle = 1, thick = 3, charsize = 1.2

oplot,rtime-stime,nightv1
oplot,rtime-stime,nightmax1,linestyle = 2
xyouts, pos(0)+.05,pos(3)-.03,'Nightside average at '+tostr(alts(ialt1))+ ' km',/norm

get_position, ppp, space, sizes, 3, pos, /rect
pos(0) = pos(0) + .1
plot, rtime-stime,/nodata, ytitle =  strmid(vars(ivar),0,4) + ' % diff', /noerase, $
          xtickname = xtickname, xtickv = xtickv,xrange = xrange, $
          xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
          yrange = yrangen2, ystyle = 1, thick = 3, charsize = 1.2,xtitle=xtitle

oplot,rtime-stime,nightv2
oplot,rtime-stime,nightmax2,linestyle = 2

xyouts, pos(0)+.05,pos(3)-.03,'Nightside average at '+tostr(alts(ialt2))+ ' km',/norm

legend, ['Ave Difference','Max Difference'], linestyle = [0,2], pos = [.65,.97],/norm,box = 0

closedevice
ppp = 2
space = 0.01
pos_space, ppp, space, sizes, ny = ppp
    
loadct, 39
setdevice,"szaplot"+tostr(itime(2))+"_"+variable+".ps",'p',5,.95
get_position, ppp, space, sizes, 1, pos1, /rect
pos(0) = pos(0) + .1
plot, szabinlow,fltarr(nbins),/nodata,ytitle =  strmid(vars(ivar),0,4) + ' %diff', /noerase,$
  yrange = ybr1,xrange = [5,175],pos = pos1,thick=3,charsize=1.2,$
  xstyle = 1,ystyle = 1,xtitle = 'Solar Zenith Angle'

legend, [tostr(alts(ialt1))+' km'],color=[0],box=0,pos = [.85,.47],/norm

;1106
;start = 0
;endi = 10

;1028 
start = 5 ;23
endi = 14 ;36

for ifile = 0, nfiles - 1 do begin
colors = 250./(endi-start-1)*(ifile-start)
    if ifile ge start and ifile le endi then $
      oplot,(szabinlow+szabinhigh)/2.,binplot1(*,ifile+1),color = colors
endfor
;- binplot1(*,ifile)
get_position, ppp, space, sizes, 0, pos2, /rect
pos(0) = pos(0) + .1
plot, szabinlow,fltarr(nbins),/nodata,ytitle =  strmid(vars(ivar),0,4) + ' %diff', /noerase,$
 yrange = ybr2,pos = pos2,xrange = [5,175],thick=3,charsize=1.2,$
  xstyle = 1,ystyle = 1,xtickname = strarr(10) + ' '
legend, [tostr(alts(ialt2))+' km'],box=0,pos = [.85,.97],/norm
for ifile = 0, nfiles - 1 do begin
colors = 250./(endi-start-1)*(ifile-start) 
   if ifile ge start and ifile le endi then $
      oplot,(szabinlow+szabinhigh)/2.,binplot2(*,ifile+1),color = colors
endfor

;newstart = start+2
nf = endi - start
dr = fltarr(nf,nbins)
maxlocs = intarr(nf)
maxbin = fltarr(nf)
vel = fltarr(nf)
itime = intarr(6,nf)
for i = 0, nf - 1 do begin
    c_r_to_a, taa, rtime(i+start)
    itime(*,i) = taa
endfor
;for ifile = 0, nf-1  do begin
;    dr(ifile,*) = (binplot2(*,ifile+newstart)-binplot2(*,start+1))
;    maxlocs(ifile) = max(where(dr(ifile,*) ge 0.25))
;    maxbin(ifile) = (szabinlow(maxlocs(ifile))+szabinhigh(maxlocs(ifile)))/2.
;
;endfor


;colors=intarr(nf)
num = min([nf, 15])
names=strarr(num)
label=strarr(num+1)
col = intarr(num)
label[0]=tostr(itime(3,0))+':'+tostr(itime(4,0))+ ' UT'
label[num/2-1]=tostr(itime(3,nf/2+1.))+':'+tostr(itime(4,nf/2))+' UT'
label[num-3]=tostr(itime(3,nf-1))+':'+chopr('00'+tostr(itime(4,nf-1)),2)+' UT'
usersym,[0,0,2,2,0],[0,2,2,0,0],/fill

for i=0,num-1 do begin
    col(i) = 250./(num-1)*(i) 
endfor

p = pos1(1)-.06
legend,names, position=[.25,p],/norm,psym=8,/horizontal,color=col,pspacing=5,box=0
legend,label,position=[.25,p-.02],/norm,/horizontal,box=0


closedevice

;plot, szabinlow,fltarr(nbins),/nodata,ytitle =  strmid(vars(ivar),0,4) + ' %diff', /noerase,$
;  xtitle = 'Solar Zenith Angle',yrange = ybr2,pos = pos,xrange = [5,175],thick=3,charsize=1.2,$
;  xstyle = 1,ystyle = 1
;legend, [tostr(alts(ialt2))+' km'],box=0,pos = [.85,.47],/norm
;for ifile = 0, nfiles - 1 do begin
;colors = 250./(endi-start)*(ifile-start) 
;   if ifile ge start and ifile le endi then $
;      oplot,(szabinlow+szabinhigh)/2.,binplot2(*,ifile+1)-binplot2(*,42),color = colors
;endfor



ioff = 8
loadct, 39
ppp = 8
index = intarr(ppp)
allbinplots = fltarr(nbins,nfiles,nalts)
for ip = 0, ppp - 1 do begin
    index(ip) = ioff + 4*ip   
    allbinplots(*,*,ip) = reform(bindiff(*,*,ivar,index(ip)))
endfor
space = 0.01
pos_space, ppp, space, sizes, ny = ppp
    
setdevice,"szaalts"+tostr(itime(2))+"_"+variable+".ps",'p',5,.95
for ia = 0, ppp - 1 do begin
   
    get_position, ppp, space, sizes, ia, pos, /rect
    pos(0) = pos(0) + .1
     ybr1 = [.95*min(allbinplots(*,*,ia)),1.05*max(allbinplots(*,*,ia))]    
    if ia eq ppp -1 then begin
        plot, szabinlow,fltarr(nbins),/nodata,$
          /noerase,$
          yrange = ybr1,xrange = [5,175],pos = pos,thick=3,charsize=1.2,$
          xstyle = 1,ystyle = 1,xtitle = 'Solar Zenith Angle'
    endif else begin
        plot, szabinlow,fltarr(nbins),/nodata,$
           /noerase,$
          yrange = ybr1,xrange = [5,175],pos = pos,thick=3,charsize=1.2,$
          xstyle = 1,ystyle = 1,xtickname = strarr(10) + ' '
    endelse
    
    legend, [tostr(alts(index(ia)))+' km'],color=[0],box=0,pos = [pos(2)-.15,pos(1)+.03],/norm

    
    for ifile = 0, nfiles - 1 do begin
        colors = 250./(endi-start-1)*(ifile-start)
        if ifile ge start and ifile lt endi then begin
            
            oplot,(szabinlow+szabinhigh)/2.,allbinplots(*,ifile+1,ia),color = colors
        endif
    endfor

endfor


p = pos1(1)-.06
legend,names, position=[.25,p],/norm,psym=8,/horizontal,color=col,pspacing=5,box=0
legend,label,position=[.25,p-.02],/norm,/horizontal,box=0

xyouts,.015,.4,'Rho Percent Difference',/norm,orient=90
closedevice
  


closedevice
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
setdevice,"aveonly_"+tostr(itime(2))+"_"+variable+".ps",'p',5,.95

xrange = [0,etime - stime]
yranged1 = [.95*min(dayv1),1.05*max(dayv1)]
yranged2 = [.95*min(dayv2),1.05*max(dayv2)]
yrangen1 = [.95*min(nightv1),1.05*max(nightv1)]
yrangen2 = [.95*min(nightv2),1.05*max(nightv2)]

ppp = 4
space = 0.01
pos_space, ppp, space, sizes, ny = ppp
    
get_position, ppp, space, sizes, 0, pos, /rect
pos(0) = pos(0) + .1
variable = strmid(vars(ivar),0,4)

if variable eq '[e-]' then variable = 'e-'

plot, rtime-stime,/nodata, ytitle = strmid(vars(ivar),0,4) + '!N % diff', /noerase, $
          xtickname = strarr(10)+' ', xtickv = xtickv, xrange = xrange,$
          xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
          yrange = yranged1, ystyle = 1, thick = 3, charsize = 1.2

oplot,rtime-stime,dayv1
xyouts, pos(0)+.05,pos(3)-.03,'Dayside average at '+tostr(alts(ialt1))+ ' km',/norm

get_position, ppp, space, sizes, 1, pos, /rect
pos(0) = pos(0) + .1
plot, rtime-stime,/nodata, ytitle = strmid(vars(ivar),0,4) + '!N % diff', /noerase, $
          xtickname = strarr(10)+' ', xtickv = xtickv, xrange = xrange, $
          xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
          yrange = yranged2, ystyle = 1, thick = 3, charsize = 1.2

oplot,rtime-stime,dayv2
xyouts, pos(0)+.05,pos(3)-.03,'Dayside average at '+tostr(alts(ialt2))+ ' km',/norm

get_position, ppp, space, sizes, 2, pos, /rect
pos(0) = pos(0) + .1
plot, rtime-stime,/nodata, ytitle = strmid(vars(ivar),0,4) + '!N % diff', /noerase, $
          xtickname = strarr(10)+' ', xtickv = xtickv, xrange = xrange,$
          xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
          yrange = yrangen1, ystyle = 1, thick = 3, charsize = 1.2

oplot,rtime-stime,nightv1
xyouts, pos(0)+.05,pos(3)-.03,'Nightside average at '+tostr(alts(ialt1))+ ' km',/norm

get_position, ppp, space, sizes, 3, pos, /rect
pos(0) = pos(0) + .1
plot, rtime-stime,/nodata, ytitle =  strmid(vars(ivar),0,4) + '!N % diff', /noerase, $
          xtickname = xtickname, xtickv = xtickv,xrange = xrange, $
          xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
          yrange = yrangen2, ystyle = 1, thick = 3, charsize = 1.2,xtitle=xtitle

oplot,rtime-stime,nightv2

xyouts, pos(0)+.05,pos(3)-.03,'Nightside average at '+tostr(alts(ialt2))+ ' km',/norm

closedevice

plottemp = 0
if plottemp then begin
    setdevice,"temp.ps",'p',5,.95
    ppp = 9
    space = 0.03
    pos_space, ppp, space, sizes
    
    get_position, ppp, space, sizes, 0, pos, /rect
    
    plot,(daydata1(8,15,*)-daydata2(8,15,*))/daydata2(8,15,*)*100., $
      daydata1(8,2,*)/$
      1000.,  ytitle = 'Altitude (km)', $
      yrange = [100,600], ystyle = 1, xrange = [0,4.0],xstyle = 1,thick = 3,$
      charsize = 1.2,pos=pos,/noerase
    
    get_position, ppp, space, sizes, 1, pos, /rect
    
    xyouts, 1.5,550,'12 UT, SZA < 30!Uo!N'
    
    plot,(daydata1(12,15,*)-daydata2(12,15,*))/daydata2(12,15,*)*100.,$
      daydata1(12,2,*)/$
      1000., $
      yrange = [100,600], ystyle = 1, xstyle = 1, xrange = [0,4.0], thick = 3,$
      charsize = 1.2,pos = pos,/noerase,ytickname = strarr(10)+' ' 
    
    xyouts, .2,550,'13 UT, SZA < 30!Uo!N'
    xyouts, -2.5,0,'Temperature % Difference',charsize = 1.2
    
    closedevice
endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GLOBAL TEC
    plotline = 1
    latime = [2003,10,28,11,3,00]
    c_a_to_r,latime,ltime
if vars(ivar) eq '[e-]' then begin
   
    mini = mm(mintec)
    maxi = mm(maxtec)
    yrange = [-100,100]
    setdevice,"glb_"+tostr(itime(2))+"_TEC.ps",'p',5,.95
    ppp = 3
    space = 0.01
    pos_space, ppp, space, sizes, ny = ppp
    
    get_position, ppp, space, sizes, 0, pos, /rect
    pos(0) = pos(0) + .05    
    plot, rtime-stime,/nodata, ytitle = 'TEC % diff', $
      /noerase, $
      xtickname = xtickname, xtickv = xtickv, xrange = xrange,$
      xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
      yrange = yrange, ystyle = 1, thick = 3, charsize = 1.2, $
      xtitle = xtitle
    
    
    oplot, rtime-stime, maxTEC, thick = 3
    oplot, rtime-stime, minTEC, thick = 3, linestyle = 1
    oplot, rtime-stime, aveTEC, thick = 3, linestyle = 2
    

    if plotline then begin
        loadct, 0
        oplot, [ltime-stime,ltime-stime+1],[-1000,1000],color = 100
        oplot, [0,etime-stime],[0,0],color = 150
    endif
    legend, ['Global Max','Global Min','Global Ave'],linestyle = [0,1,2],$
      pos = [pos(2) - .3,.98],/norm,box=0
    closedevice
endif 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GLOBAL Neutrals
plotglobal = 1
if plotglobal then begin
    
    mini = mm(mindata(*,ivar,ialt2))
    maxi = mm(maxdata(*,ivar,ialt2))

    yrange = [mini(0),maxi(1)]
    yrange = [-100,100]
    setdevice,"glb_"+tostr(itime(2))+"_"+variable+".ps",'p',5,.95
    ppp = 4
    space = 0.01
    pos_space, ppp, space, sizes, ny = ppp
    
    get_position, ppp, space, sizes, 0, pos, /rect
    pos(0) = pos(0) + .1    
    plot, rtime-stime,/nodata, ytitle = vars(ivar) + ' % Diff', $
      /noerase, $
      xtickname = xtickname, xtickv = xtickv, xrange = xrange,$
      xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
      yrange = yrange, ystyle = 0, thick = 3, charsize = 1.2, $
      xtitle = xtitle
    
    
    oplot, rtime-stime, maxdata(*,ivar,ialt2)
    oplot, rtime-stime, mindata(*,ivar,ialt2),linestyle = 1
    oplot, rtime-stime, avedata(*,ivar,ialt2),linestyle = 2
    if plotline then begin
          loadct, 0
        oplot, [ltime-stime,ltime-stime+1],[-1000,1000],color = 100
    endif
    legend, ['Global Max','Global Min','Global Ave'],linestyle = [0,1,2],$
      pos = [pos(2) - .3,.98],/norm,box=0
    closedevice
endif 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

print, 'The sza dependant velocities are: '
print, vel
print, 'sza: ', (maxbin(1:nf-1)+maxbin(0:nf-2))/2

print, ' '
print, 'The global average sound speed is: ',$
  tostr(((mean(data1(4,*,*,36)) *1.381e-23*mean(data1(15,*,*,36))*5/3)/$
         (mean(data1(3,*,*,36))))^.5), ' m/s'


 

maxd = max(dayv2,imaxd)
maxn = max(nightv2,imaxn)

maxdtime = rtime(imaxd)
maxntime = rtime(imaxn)

responcetime = (maxntime-maxdtime)/3600.

print, 'Time delay at nightside: ',tostr(floor(responcetime)), ' hours ', $
  tostr((responcetime-floor(responcetime))*60), ' minutes ' 

c_r_to_a,itmday,maxdtime
c_r_to_a,itmnight,maxntime


end




