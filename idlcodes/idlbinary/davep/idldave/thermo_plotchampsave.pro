dorestore = 'y'
savelist = file_search('*.sav')

if n_elements(champdensity) gt 0 then begin
    dorestore = 'n'
    dorestore = ask('whether to restore: ',dorestore)
endif

if dorestore eq 'y' then begin 
    if n_elements(ifile) eq 0 then ifile = 0
    display, savelist
    ifile = fix(ask('which file to restore: ',tostr(ifile)))
    restore, savelist(ifile)
endif
;;;;;;scatter plot;;;;;;;;;;;;;;
;setdevice,'plot.ps','p',5,.95
;
;locs = where(gitmdensity lt 20)
;plot, champdensity(locs),gitmdensity(locs),psym=sym(1),xtitle='Champ Density',$
;  ytitle='GITM Density', yrange = [0,15],xrange = [0,15]
;
;closedevice
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
reread = 'y'
if n_elements(seas) gt 0 then begin
    reread = 'n'
    reread = ask('whether to reread seasons and kps: ',reread)
endif

if reread eq 'y' then begin
ntimes = n_elements(time)
seas = strarr(ntimes)
kp = strarr(ntimes)
kpbin = intarr(ntimes)
ut = fltarr(ntimes)
it = intarr(6,ntimes)
ndays = 0
tempday = 0
for itime = 0L, ntimes - 1 do begin
    c_r_to_a,itt,time(itime)
    if itt(2) ne tempday then begin
        ndays = ndays + 1
        tempday = itt(2)
    endif
    it(*,itime) = itt
    date = tostr(itt(1))+chopl('0'+tostr(itt(2)),2)
    print, 'Working on: ',tostr(itt)
    julian = julian_day(time(itime))
    seas(itime) = season(julian)
    kp(itime) = get_kpvalue(itt)

    ut(itime) = itt(3)*3600. + itt(4)*60. + itt(5)

    case strtrim(kp(itime),2) of
        '0-': kpbin(itime) = 1
        '0' : kpbin(itime) = 1
        '0+': kpbin(itime) = 1
        '1-': kpbin(itime) = 1
        '1' : kpbin(itime) = 2
        '1+': kpbin(itime) = 2
        '2-': kpbin(itime) = 2
        '2' : kpbin(itime) = 3
        '2+': kpbin(itime) = 3
        '3-': kpbin(itime) = 3
        else:  kpbin(itime) = 4
    endcase
endfor

endif

seasons = ['Winter','Spring','Summer','Fall']
display,seasons
if n_elements(is) eq 0 then is = 0
is = fix(ask('which season to plot: ',tostr(is)))
kplev = [1,2,3,4]

ppp = 4
space = 0.01
pos_space, ppp, space, sizes
loadct, 39

istime = [2007,03,01,00,00,00]
ietime = [2007,03,02,00,00,00]
c_a_to_r, istime,stime
c_a_to_r, ietime,etime

time_axis, stime, etime,btr,etr, xticknames, xtitles, xtickv, xminor, xtickn

iplot = 0
yrange = [0,15];mm([champdensity,gitmdensity]) 

setdevice,'champplot_'+season(is)+'.ps','p',5,.95
for ikp = 0, 3 do begin
get_position, ppp, space, sizes, ikp, pos , /rect        
pos(0) = pos(0) + .02
pos(2) = pos(2) + .02

locs = where(seasons(is) eq seas and kplev(ikp) eq kpbin)
nlocs = n_elements(locs)
newline = intarr(nlocs)
locsdiff = locs(1:nlocs-1) - locs(0:nlocs-2) 

ld = [0,time(locs(1:nlocs-1)) - time(locs(0:nlocs-2))]

for iloc = 0, nlocs - 2 do begin
    if iloc ne 0 then begin
        if ld(iloc) gt 3600. or it(2,locs(iloc)) ne it(2,locs(iloc-1)) then $
          newline(iloc) = 1 else newline(iloc) = 0
    endif else begin
        newline(iloc) = 1
    endelse
endfor
linestart = [where(newline eq 1)]
nlines = n_elements(linestart)
   
case ikp of
    0: begin
        xtickname = strarr(10)+' '
        xtitle = ''
        ytickname = [0,2,4,6,8,10,12,14]
        ytitle = 'Density (x10e!U-12!N kg/m!U3!N)'
    end
     1: begin
        xtickname = strarr(10)+' '
        xtitle = ' '
        ytickname = strarr(10)+ ' '
        ytitle = ' '
    end
    2: begin
        xtickname = xticknames
        xtitle = 'UT Hours'
        ytickname = [0,2,4,6,8,10,12,14]
        ytitle = 'Density (x10e!U-12!N kg/m!U3!N)'
    end
    3: begin
        xtickname = xticknames
        xtitle = 'UT Hours'
        ytickname = strarr(10)+' '
        ytitle = ' '
    end
endcase

plot,[0,3600.*24],/nodata,yrange = yrange,xtickname=xtickname,xstyle=1,$
  xticks=xtickn,xtickv=xtickv,xminor=xminor,xtitle=xtitle,ystyle = 1,$
  xrange = [0,3600.*24],pos = pos,/noerase,ytickname = ytickname,ytitle = ytitle

for iline = 0, nlines - 1 do begin
    if iline lt nlines - 1 then begin
        oplot, ut(locs(linestart(iline)):locs(linestart(iline+1)-1)), $
          ChampDensity(locs(linestart(iline)):locs(linestart(iline+1)-1))
        oplot, ut(locs(linestart(iline)):locs(linestart(iline+1)-1)), $
          GITMDensity(locs(linestart(iline)):locs(linestart(iline+1)-1)),color = 254,$
          linestyle=2
    endif else begin
        oplot, ut(locs(linestart(iline)):locs(nlocs-1)), $
          ChampDensity(locs(linestart(iline)):locs(nlocs-1))
        oplot, ut(locs(linestart(iline)):locs(nlocs-1)), $
          GITMDensity(locs(linestart(iline)):locs(nlocs-1)),color=254,$
          linestyle=2
    endelse
endfor
xyouts,pos(2)-.13,pos(3)-.02,'KP Level '+tostr(kplev(ikp)),/norm
endfor
closedevice

champavg = fltarr(ndays)
gitmavg = fltarr(ndays)
day = fltarr(ndays)
itime = 0
for iday = 0, ndays - 2 do begin
   
    utstart = time(itime)
    nextday = min(where((time - time(itime)) ge 24.*3600))
    champavg(iday) = mean(champdensity(itime:nextday-1))
    gitmavg(iday) = mean(gitmdensity(itime:nextday-1))
    day(iday) = time(itime)
    itime = nextday
endfor

ppp=3
space = 0.01
pos_space, ppp, space, sizes,ny=ppp
get_position, ppp, space, sizes, 0, pos , /rect        
pos(0) = pos(0) + .02
pos(2) = pos(2) + .02

champavg(ndays-1) = mean(champdensity(itime:*))
gitmavg(ndays-1) = mean(gitmdensity(itime:*))
day(ndays-1) = time(itime)
stime = day(0)
etime = max(day)
time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
setdevice,'champall.ps','p',5,.95
ytitle = 'Density (x10e!U-12!N kg/m!U3!N)'
plot, day-stime,/nodata,yrange=[0,15],xticks=xtickn,xtickv=xtickv,xtickname=xtickname,$
  xminor=xminor,xtitle=xtitle,ytitle=ytitle,xstyle=1,ystyle=1,xrange = [0,etime-stime],$
  pos=pos
oplot,day-stime,champavg,thick=3
oplot,day-stime,gitmavg,thick=3,color=254,linestyle=2
closedevice

end
