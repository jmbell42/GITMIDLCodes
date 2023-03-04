if n_elements(byear) eq 0 then byear = '2001'
byear = ask("beginning year: ",byear)

flarefile = '/Users/dpawlows/GOES/xclass/flares'+byear+'.dat'
fb = file_search(flarefile)
if n_elements(fb) lt 1 then begin
    print, 'There is no flare file for that date'
    stop
endif

if n_elements(eyear) eq 0 then eyear = '2001'
eyear = ask("end year: ",eyear)

nyears = fix(eyear) - fix(byear) + 1
neventsmax = 100

flares = fltarr(nyears,neventsmax)
energy = fltarr(nyears,neventsmax)
nflares = intarr(nyears)
rt = fltarr(neventsmax*nyears)
nfall = intarr(neventsmax*nyears)
eall = fltarr(neventsmax*nyears)
years = intarr(nyears)
iflare = 0
for iyear = 0, nyears - 1 do begin
    flarefile = '/Users/dpawlows/GOES/xclass/flares'+tostr(fix(byear)+iyear)+'.dat'
    fn = file_search(flarefile)
    if n_elements(fn) lt 1 then begin
        print, 'There is no flare file for the year: ', fn
        stop
    endif
    years(iyear) = byear + iyear
    print, "Looking at year ",years(iyear)
close,/all
    openr,1,fn
    temp = ' '
    
    ievent = 0
    while not eof(1) do begin
        
        readf,1, temp
        t = strsplit(temp,/extract)
        timearr = t(4:9)
        length = fix(t(12))
        magnitude = float(t(1))
        c_a_to_r,fix(timearr),rtime
        rt(iflare) = rtime
        stime = rtime - 6*3600.
        etime = rtime + 24 * 3600.
        retime = rtime+length*60
        
        nflares(iyear) = nflares(iyear) + 1
        flares(iyear,ievent) = magnitude
        ievent = ievent + 1
        nfall(iflare) = years(iyear)

        date = timearr(0)+'-'+timearr(1)+'-'+timearr(2)
        flaretime = timearr(3)+'-'+timearr(4)
        calc_flareenergy, genergy,date, flaretime
        energy(iyear,ievent) = genergy
        eall(iflare) = genergy

        iflare = iflare + 1

    endwhile
endfor
nfall = nfall(0:iflare-1) 
eall = eall(0:iflare-1) 
rt = rt(0:iflare-1)
hist_data = Histo( nfall, BinVals, NBIN=nyears)
itime = intarr(6,iflare)
for i = 0, iflare - 1 do begin
    c_r_to_a,ta,rt(i)
    itime(*,i) = ta

endfor
    

setdevice,'plot.ps','p',5,.95
ppp=3
space = 0.1
pos_space, ppp, space, sizes, ny = ppp

loadct,39
get_position, ppp, space, sizes, 0, pos, /rect
hist_data = Histo( nfall, BinVals, NBIN=17)
plothist,nfall,xhist,yhist,/boxplot,xtitle = 'Year',ytitle='Number of X-class flares',$
  pos=pos,charsize = 1.2,/noplot,bin=bin

xtickname 
plot,xhist,yhist,charsize=1.2,pos=pos,xtitle = 'Year',$
  ytitle='Number of X-class flares',/nodata,xrange = [years(0)-.5,years(nyears-1)+.5],$
  xstyle=1,/noerase,xticks=nyears
plothist,nfall,/boxplot,/overplot,fcolor=220,/fill,bin=bin,/halfbin


;---------------------------------

get_position, ppp, space, sizes, 1, pos, /rect
plothist,eall,xhist,yhist,/boxplot,xtitle = 'Year',ytitle='Number of X-class flares',$
  pos=pos,charsize = 1.2,/noplot,/autobin,/noerase

plot,xhist,yhist,charsize=1.2,pos=pos,xtitle = 'Energy above background (J/m!U2!N)',$
  ytitle='Number of X-class flares',/nodata,/noerase;,;xrange = [years(0)-.5,years(nyears-1)+.5],$
;  xstyle=1,/noerase
plothist,eall,/boxplot,/overplot,fcolor=220,/fill

;-------------------------------------
ta = [byear,1,1,0,0,0]
c_a_to_r,ta,stime
ta = [eyear+1,1,1,0,0,0]
c_a_to_r,ta,etime
time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
    
get_position, ppp, space, sizes, 2, pos, /rect
plot,rt-stime,eall,/nodata,$
  charsize=1.2,pos=pos,xtitle = 'Year',xtickv=xtickv,xticks=xtickn,$
  xtickname=xtickname,xminor=xminor,xrange=[0,etr],$
  ytitle='Energy above background',/noerase;
oplot,rt-stime,eall,psym=sym(5),color = 220
closedevice


;plot,BinVals,hist_data;xrange = [years(0)-.5,years(nyears-1)+.5],xstyle = 1,$
;  xtitle = 'Year', ytitle='Number of X-class flares'

end
