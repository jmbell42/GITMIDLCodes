if n_elements(filedate) eq 0 then filedate = ' '
filedate = ask('MM/DD/YYYY: ',filedate)
if n_elements(ndays) eq 0 then ndays = 1
ndays = fix(ask('Number of days (1 min): ',tostr(ndays)))

iwave1 = 50
iwave2 = 55

gflux1 = fltarr(59)
gflux2 = fltarr(59)
gflux3 = fltarr(59)
gfl1 = gflux1
gfl2 = gflux1
gfl3 = gflux1
openr,1,'/Users/dpawlows/SEE/GITMFLUX29'
readf,1,gflux1
close,1
openr,1,'/Users/dpawlows/SEE/GITMFLUX30'
readf,1,gflux2
close,1
openr,1,'/Users/dpawlows/SEE/GITMFLUX31'
readf,1,gflux3
close,1
    

close, 30
close,31
openr,30,'/Users/dpawlows/SEE/wavelow'
openr,31,'/Users/dpawlows/SEE/wavehigh'
wavelow=fltarr(59)
wavehigh=fltarr(59)
readf,30,wavelow
readf,31,wavehigh

waveavg = (wavehigh + wavelow)/2.
for i=0, 58 do begin
    gfl1[i]=gflux1[i]*6.626e-34*2.998e8/(waveavg[i]*10.^(-10.))
    gfl2[i]=gflux2[i]*6.626e-34*2.998e8/(waveavg[i]*10.^(-10.))
    gfl3[i]=gflux3[i]*6.626e-34*2.998e8/(waveavg[i]*10.^(-10.))
endfor
for i = 0, 58 do begin
    gflux1(i) = gfl1(58-i)
    gflux2(i) = gfl2(58-i)
    gflux3(i) = gfl3(58-i)
endfor
gfluxwave1 = [gflux1(58-iwave1),gflux2(58-iwave1),gflux3(58-iwave1)] 
gfluxwave2 = [gflux1(58-iwave2),gflux2(58-iwave2),gflux3(58-iwave2)] 

filedt = strsplit(filedate,'/',/extract)
filemonth = filedt(0)
fileday = filedt(1)
fileyear = filedt(2)
doy = ymd2dn(fileyear,filemonth,fileday)

plotname = '/Users/dpawlows/SEE/plots/seeplot'+tostr(filedt(0))+$
  tostr(filedt(1))+tostr(filedt(2))+$
  '.ps'
loadct, 39
setdevice,plotname,'p',5,.95
ppp = ndays+1

space = 0.01
pos_space, ppp, space, sizes, ny = ppp

keepwave1 = [0]
keepwave2 = [0]
time = [0]
;i wave out of 59...;;;


for day = 0, ndays - 1 do begin
    file = '/Users/dpawlows/SEE/outfiles/fluxbindata' + fileyear + tostr(doy)
    
    nlines = file_lines(file)/11
    temp = ' '
    timearr = intarr(6,nlines)
    ttemp = intarr(6)
    rtime = fltarr(nlines)
    fluxarr = fltarr(59,nlines)
    ftemp = fltarr(59)
    close, 5
    openr, 5, file
    ft = fltarr(nlines)

    for i = 0, nlines - 1 do begin
        readf, 5, ttemp,ftemp
        timearr(*,i) = ttemp
        fluxarr(*,i) = ftemp
        keepwave1 = [keepwave1,fluxarr(iwave1,i)]
        keepwave2 = [keepwave2,fluxarr(iwave2,i)]
    endfor
    close, 5
    for i = 0, 57 do begin
        if waveavg(i) lt waveavg(i+1) then begin 
            switchi = i
            t = waveavg(switchi)
            waveavg(switchi) = waveavg(switchi+1)
            waveavg(switchi+1) = t
            ft = fluxarr(switchi,*)
            fluxarr(switchi,*) = fluxarr(switchi+1,*)
            fluxarr(switchi+1,*) = ft        
        endif
    endfor
    for i = 0, nlines - 1 do begin
        c_a_to_r, timearr(*,i), rt
        rtime(i) = rt
        time = [time,rt]
    endfor
    
    ;if day eq 0 then begin
    ;     time = rtime
    ;endif
    
   
    ;title = 'SEE flux on '+filedate
    
    get_position, ppp, space, sizes, day, pos, /rect

    pos(0) = pos(0) + 0.1
   if day ne ndays - 1 then begin
       plot, waveavg, /nodata, /ylog, yrange=[10e-7,.01],xrange=[0,1000], $
         background=255, color=1, ytitle='Flux (W/m^2)', $
         pos = pos,xstyle = 1,charsize = 1.3,thick=3,$
         /noerase, xtickname = strarr(10)+' ' 
   endif else begin
        plot, waveavg, /nodata, /ylog, yrange=[10e-7,.01],xrange=[0,1000], $
         background=255, color=1, ytitle='Flux (W/m^2)', $
         pos = pos,xstyle = 1,charsize = 1.3,thick=3,$
          xtitle = 'Wavelength (nm)',/noerase
    endelse

    for i=0, nlines-1 do begin
        oplot, waveavg, fluxarr(*,i), color=(i)*17 + 5 ,thick = 3
    endfor
    dl = tostr(filemonth)+'/'+tostr(fileday)+'/'+fileyear
    xyouts, pos(0) + .7,pos(1) + .18,dl,/norm
doy = doy + 1

YDN2MD,fileyear,doy,m,d
fileday = d
filemonth = m
endfor
colors=intarr(nlines)
names=strarr(nlines)
label=strarr(16)
label[0]='0 UT'
label[8]='12 UT'
label[15]='23 UT'
usersym,[0,0,2,2,0],[0,2,2,0,0],/fill

for i=0,nlines-1 do begin
    colors[i]=5+17*i
    names[i]=''
endfor
p = pos(1)-.06
legend,names, position=[.08,p],/norm,psym=8,/horizontal,color=colors,pspacing=5,box=0
legend,label,position=[.08,p-.02],/norm,/horizontal,box=0

closedevice
stime = time(1)
etime = time(n_elements(time)-1)
time_axis,  stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn

plotname2 = '/Users/dpawlows/SEE/plots/dtwave'+tostr(filedt(0))+$
  tostr(filedt(1))+tostr(filedt(2))+$
  '.ps'
setdevice,plotname2,'p',5,.95
ppp = 5
space = 0.01
pos_space, ppp, space, sizes, ny = ppp

get_position, ppp, space, sizes, 0, pos, /rect
pos(0) = pos(0) + 0.1
min1 = min(keepwave1(where(keepwave1 ne 0)))-.3*min(keepwave1(where(keepwave1 ne 0)))
max1 = max(keepwave1)+.3*max(keepwave1)
min2 = max(keepwave2(where(keepwave2 ne 0)))-.3*min(keepwave2(where(keepwave2 ne 0)))
max2 = max(keepwave2)+.3*max(keepwave2)
plot,time(1:n_elements(time)-1)-stime,[0,12],/nodata,/noerase,/ylog,$
       ytitle='Flux (' +tostr(waveavg(iwave1)/10.)+'nm)', yrange =[min1,2e-3],$
      xtickname = strarr(10)+' ',pos = pos, xtickv = xtickv, xminor = xminor, $
      xticks = xtickn,xstyle = 1, ystyle = 1,charsize = 1.3

oplot,time-stime,keepwave1(1:n_elements(keepwave1)-1),color = 254,thick=3
oplot,[0,etime-stime],[gfluxwave1,gfluxwave1],color = 60,thick=3

get_position, ppp, space, sizes, 1, pos, /rect
pos(0) = pos(0) + 0.1

plot,time(1:n_elements(time)-1)-stime,[0,12],/nodata,/noerase,/ylog,$
       ytitle='Flux (' +tostr(waveavg(iwave2)/10.)+'nm)', yrange = [1e-5,max2],$
      xtickname = xtickname,pos = pos, xtickv = xtickv, xminor = xminor, $
      xticks = xtickn,xstyle = 1, ystyle = 1,charsize = 1.3,xtitle = xtitle

oplot,time-stime,keepwave2(1:n_elements(keepwave2)-1),color = 254,thick=3
oplot,[0,etime-stime],[gfluxwave2,gfluxwave2],color = 60,thick=3
legend,['SEE','F107'],position=[pos(0)+.7,pos(1)+.17],colors=[254,60],/norm,$
  linestyle = 0,box=0

closedevice
end


