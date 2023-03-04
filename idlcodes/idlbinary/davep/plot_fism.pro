if n_elements(date) eq 0 then date = ' '
date = ask("date (yyyy-mm-dd): ",date)
cyear = strmid(date,0,4)
cmonth = strmid(date,5,2)
sday = strmid(date,8,2)

if n_elements(ndays) eq 0 then ndays = 1
ndays = fix(ask('number of days to plot (min 1): ' ,tostr(ndays)))
fismdir = './' ;'~/UpperAtmosphere/FISM/BinnedFiles/'+cyear+'/'
;fismdir = '~/UpperAtmosphere/FISM/Mars/BinnedFiles/'

;fismdir = '~/FISM/BinnedFiles/Hourly/'

;read in GITM wavelength information
close,/all
openr,30, '/Users/dpawlows/UpperAtmosphere/SEE/wavelow'
openr,31,'/Users/dpawlows/UpperAtmosphere/SEE/wavehigh'
nbins = 59
wavelow=fltarr(nbins)
wavehigh=fltarr(nbins)
readf,30,wavelow
readf,31,wavehigh

close,30
close,31
   ;convert to nm
wavelow=wavelow/10.
wavehigh=wavehigh/10.
waveavg = (wavelow+wavehigh)/2.

nlines = 1440.*ndays
;nlines = 24*ndays
itimearr = intarr(6,nlines)
rtime = dblarr(nlines)
fismflux = fltarr(59,nlines)
t = intarr(6)
a = fltarr(59)
 iline = 0L
for iday = 0, ndays - 1 do begin
    cday = chopr('0'+tostr(fix(sday) + iday),2)  

    fismfile = 'fismflux'+cyear+cmonth+cday+'.dat'
;    fismfile = 'fismflux_hourly'+cyear+cmonth+'.dat'
    openr,5,fismdir+fismfile

    temp = ' '
    while strpos(temp,'#START') lt 0 do begin
        readf,5,temp
    endwhile

    while not eof(5) do begin
        readf,5,t,a
        itimearr(*,iline) = t
        fismflux(*,iline) = a
        c_a_to_r,itimearr(*,iline),rt
        rtime(iline) = rt
        iline = iline + 1
    endwhile
    close, 5
endfor
locs = where(rtime ne 0,nlines)

rtime = rtime(locs)
fismflux = fismflux(*,locs)
itimearr = itimearr(*,locs)

fismrange = fltarr(nlines)
for iline = 0, nlines - 1 do begin
   fismrange(iline) = total(fismflux(42:46,iline))
endfor

stime = rtime(0)
etime = max(rtime)

time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn

setdevice, 'plot.ps','p',5,.95
ppp = 3
space = 0.01
pos_space, ppp, space, sizes, ny = ppp
get_position, ppp, space, sizes, 0, pos1, /rect
pos1(0) = pos1(0) + 0.1
display, waveavg
pwave = intarr(4)
pwave(0) = 56
pwave(1) = 32
pwave(2) = 18
pwave(3) = 11

for iwave = 0, 3 do begin
    pwave(iwave) = fix(ask('wavelength '+tostr(iwave)+' to plot: ',tostr(pwave(iwave))))
endfor

yrange = [1.2e-3,4e-3]
plot,rtime-stime,fismrange,xtickv=xtickv,xticks=xtickn,$
  xminor=xminor,xtickname=strarr(10)+' ',xstyle=1,pos=pos1,/noerase,$
  ytitle='Flux ('+tostrf(waveavg(pwave(0)))+' nm) W/m!U2!D',yrange=yrange,thick=3
closedevice




ppp = 4
space = 0.01
pos_space, ppp, space, sizes, ny = ppp

setdevice, 'fism'+cyear+cmonth+cday+'.ps','p',5,.95

get_position, ppp, space, sizes, 0, pos1, /rect
pos1(0) = pos1(0) + 0.1

yrange = [0,2e-5]
plot,rtime-stime,fismflux(pwave(0),*),xtickv=xtickv,xticks=xtickn,$
  xminor=xminor,xtickname=strarr(10)+' ',xstyle=1,pos=pos1,/noerase,$
  ytitle='Flux ('+tostrf(waveavg(pwave(0)))+' nm) W/m!U2!D';,yrange=yrange,$
;     ystyle=1

get_position, ppp, space, sizes, 1, pos1, /rect
pos1(0) = pos1(0) + 0.1

yrange = [0,3e-4]
plot,rtime-stime,fismflux(pwave(1),*),xtickv=xtickv,xticks=xtickn,$
  xminor=xminor,xtickname=strarr(10)+' ',xstyle=1,pos=pos1,/noerase,$
  ytitle='Flux ('+tostrf(waveavg(pwave(1)))+' nm) W/m!U2!D';,yrange=yrange,$
;     ystyle=1

get_position, ppp, space, sizes, 2, pos1, /rect
pos1(0) = pos1(0) + 0.1

yrange = [0,6e-4]
plot,rtime-stime,fismflux(pwave(2),*),xtickv=xtickv,xticks=xtickn,$
  xminor=xminor,xtickname=strarr(10)+' ',xstyle=1,pos=pos1,/noerase,$
  ytitle='Flux ('+tostrf(waveavg(pwave(2)))+' nm) W/m!U2!D';,yrange=yrange,$
;     ystyle=1

get_position, ppp, space, sizes, 3, pos1, /rect
pos1(0) = pos1(0) + 0.1

yrange = [0,0.1]
plot,rtime-stime,fismflux(pwave(3),*),xtitle=xtitle,xtickv=xtickv,xticks=xtickn,$
     xminor=xminor,xtickname=xtickname,xstyle=1,pos=pos1,$
     ytitle='Flux ('+tostrf(waveavg(pwave(3)))+' nm) W/m!U2!D',/noerase;,yrange=yrange,$
;     ystyle=1
closedevice

;ppp = 4
;space = 0.01
;pos_space, ppp, space, sizes, ny = ppp
;
;get_position, ppp, space, sizes, 1, pos1, /rect
;pos1(0) = pos1(0) + 0.1
;setdevice,'plot.ps','p',5,.95
;
;plot,waveavg(*),fismflux(*,0),xtitle='Wavelength (nm)',ytitle='Flux (W/m!U2!N)',$
;pos = pos1,/ylog,thick = 3, xrange = [.1,170],xstyle=1,charsize=1.2
;
;
;;plots, [.1,.1],[1e-6,.1],color = 254,thick=3
;;plots, [170,170],[1e-6,.1],color = 254,thick=3
;;legend, ['GOES'],color=[254],thick=3,box=0,pos=[0,6e-2],/data,linestyle=0;
;
;;plots, [.1,.1],[1e-6,.1],color = 50,thick=3
;;plots, [.8,.8],[1e-6,.1],color = 50,thick=3
;;legend, ['GOES'],color=[50],thick=3,box=0,pos=[0,6e-2],/data,linestyle=0
;
;;plots, [.1,.1],[1e-6,.1],color = 50,thick=3
;;plots, [.8,.8],[1e-6,.1],color = 50,thick=3
;;legend, ['GOES'],color=[50],thick=3,box=0,pos=[0,6e-2],/data,linestyle=0
;
;
;closedevice

;get_position, ppp, space, sizes, 1, pos1, /rect
;pos1(0) = pos1(0) + 0.1
;setdevice,'plot.ps','p',5,.95
;plot,rtime-stime,alog10(total(fismflux(56:58,*),1)),xtitle=xtitle,xtickv=xtickv,xticks=xtickn,$
;  xminor=xminor,xtickname=xtickname,xstyle=1,pos=pos1,yrange = [-7,-3],$
;  ytitle='Flux (.1-.8 nm) W/m!U2!D',/noerase
;
;closedevice
;
;flarecontour = 0
;nwaves = 59
;if flarecontour then begin
;    waves2d = fltarr(nwaves,nlines)
;    time2d = dblarr(nwaves,nlines)
;    for iwave = 0, nwaves - 1 do begin
;        waves2d(iwave,*) = waveavg(iwave)
;        time2d(iwave,*) = rtime
;    endfor
;
;
;if n_elements(fstime) eq 0 then begin
;    c_r_to_a,fstime,stime
;    fetime = fstime
;endif
;fstime = fix(strsplit(ask('flare start time: ',strjoin(tostr(fstime),' ')),/extract))
;fetime = fix(strsplit(ask('flare end time: ',strjoin(tostr(fetime),' ')),/extract))
;
;c_a_to_r, fstime,fst
;c_a_to_r, fetime,fet
;
;locs = where(rtime ge fst and rtime le fet)
;loadct, 39
;setdevice,'flare.ps','p',5,.95
;ppp = 2
;space = 0.03
;pos_space, ppp, space, sizes
;    
;get_position, ppp, space, sizes, 0, pos, /rect
;pos(2) = pos(2) - 0.05
;pos(0) = pos(0) + 0.03
;fluxlog = alog10(fismflux)
;maxi = max(fluxlog(*,locs))
;mini=min(fluxlog(*,locs))
;levels = findgen(31) * (maxi-mini) / 30 + mini
;
;stime = fst
;etime = fet
;time_axis,  stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
;xrange = [btr,etr]
;;contour,fluxlog(*,locs),time2d(*,locs)-stime,waves2d(*,locs),xtickname=strarr(10)+' ',$
;; xtickv=xtickv,xticks=xtickn,xminor=xminor,xrange=xrange,$
;;  yrange = mm(waveavg),xstyle=1,ystyle=1,pos=pos,/fill,levels=levels,$
;;  ytitle = 'Wavelength (nm)',/noerase
;title = 'Solar Flux (W/m!U2!N/s)'
; ctpos = pos
; ctpos(0) = pos(2)+0.025
; ctpos(2) = ctpos(0)+0.03
; maxmin = [mini,maxi]
; plotct, 255, ctpos, maxmin, title, /right
;;----------------------
;tlocs = where(rtime ge fst and rtime le fet)
;wlocs = where(waveavg lt 30)
;get_position, ppp, space, sizes, 1, pos, /rect
;pos(2) = pos(2) - 0.05
;pos(0) = pos(0) + 0.03
;
;wloc1 = min(wlocs)
;wloc2 = max(wlocs)
;fluxlog = alog10(fismflux(wloc1:wloc2,tlocs))
;time2d = time2d(wloc1:wloc2,tlocs)
;waves2d = waves2d(wloc1:wloc2,tlocs)
;
;maxi = max(fluxlog)
;mini=min(fluxlog)
;mini = -6.1
;maxi = -2.1
;levels = findgen(31) * (maxi-mini) / 30 + mini
;
;stime = fst
;etime = fet
;time_axis,  stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
;xrange = [btr,etr]
;
;contour,fluxlog,time2d-stime,waves2d,$
;  xtickname=xtickname,$
;  xtitle = xtitle,xtickv=xtickv,xticks=xtickn,xminor=xminor,xrange=xrange,$
;  yrange = mm(waves2d),xstyle=1,ystyle=1,pos=pos,/fill,levels=levels,$
;  ytitle = 'Wavelength (nm)',/noerase
;
;title = 'Solar Flux (W/m!U2!N/s)'
; ctpos = pos
; ctpos(0) = pos(2)+0.025
; ctpos(2) = ctpos(0)+0.03
; maxmin = [mini,maxi]
; plotct, 255, ctpos, maxmin, title, /right
;closedevice
;
;
;; ---------- Difference
;waves2d = fltarr(nwaves,nlines)
;time2d = dblarr(nwaves,nlines)
;for iwave = 0, nwaves - 1 do begin
;    waves2d(iwave,*) = waveavg(iwave)
;    time2d(iwave,*) = rtime
;endfor
;
;locs = where(rtime ge fst and rtime le fet)
;bmin = min(where(rtime ge fst-3600.),ibst)
;begflux = fismflux(*,ibst)
;loadct, 39
;setdevice,'flarediff.ps','p',5,.95
;ppp = 2
;space = 0.03
;pos_space, ppp, space, sizes
;    
;get_position, ppp, space, sizes, 0, pos, /rect
;pos(2) = pos(2) - 0.1
;pos(0) = pos(0) + 0.03
;
;nlocs = n_elements(locs)
;compflux = fltarr(nwaves,nlocs)
;for i = 0, nlocs - 1  do begin
;;    compflux(*,i) =
;;    (alog10(fismflux(*,locs(i)))-alog10(begflux))/alog10(begflux)*100.
;    compflux(*,i) = (alog10(fismflux(*,locs(i)))/alog10(begflux))
;endfor
;
;fluxlog = (compflux)
;zerolocs = where(fluxlog); ge 0)
;;fluxlog = compflux(*,locs)
;
;maxi = max(fluxlog)
;mini=min(fluxlog(zerolocs))
;maxi = min([100,maxi])
;mini = 0
;maxi = 1.145
;levels = findgen(31) * (maxi-mini) / 30 + mini
;
;stime = fst
;etime = fet
;time_axis,  stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
;xrange = [btr,etr]
;contour,fluxlog,time2d(*,locs)-stime,waves2d(*,locs),xtickname=strarr(10)+' ',$
; xtickv=xtickv,xticks=xtickn,xminor=xminor,xrange=xrange,$
;  yrange = mm(waveavg),xstyle=1,ystyle=1,pos=pos,/fill,levels=levels,$
;  ytitle = 'Wavelength (nm)',/noerase
;title = 'Solar Flux  % Diff'
; ctpos = pos 
; ctpos(0) = pos(2)+0.025
; ctpos(2) = ctpos(0)+0.03
; maxmin = [mini,maxi]
; plotct, 255, ctpos, maxmin, title, /right
;;----------------------
;
;
;tlocs = where(rtime ge fst and rtime le fet)
;wlocs = where(waveavg lt 30)
;get_position, ppp, space, sizes, 1, pos, /rect
;pos(2) = pos(2) - 0.1
;pos(0) = pos(0) + 0.03
;maxi = max(fluxlog)
;mini=min(fluxlog(zerolocs))
;
;levels = findgen(31) * (maxi-mini) / 30 + mini
;contour,fluxlog,time2d(*,locs)-stime,waves2d(*,locs),$
;  xtickname=xtickname,$
;  xtitle = xtitle,xtickv=xtickv,xticks=xtickn,xminor=xminor,xrange=xrange,$
;  yrange = [0,30],xstyle=1,ystyle=1,pos=pos,/fill,levels=levels,$
;  ytitle = 'Wavelength (nm)',/noerase
;
;title = 'Solar Flux % Diff'
; ctpos = pos
; ctpos(0) = pos(2)+0.025
; ctpos(2) = ctpos(0)+0.03
; maxmin = [mini,maxi]
; plotct, 255, ctpos, maxmin, title, /right
;closedevice


;endif
end
