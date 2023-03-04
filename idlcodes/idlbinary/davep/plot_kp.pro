filelist = file_search('*[^.]*')
if n_elements(date) eq 0 then date = ''
date = ask("date to plot (mmyyyy): ", date)

year = strmid(date,0,4)
month = strmid(date,4,2)

readkp,year,kp,rtime

ntimes = n_elements(rtime)
itimearr = intarr(6,ntimes)
for itime = 0, ntimes -1 do begin
   c_r_to_a,ta,rtime(itime)
   itimearr(*,itime) = ta
endfor

istart = min(where(itimearr(1,*) eq month))
iend = max(where(itimearr(1,*) eq month))

stime = rtime(istart)
etime = rtime(iend)

time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
xrange = [btr,etr]


setdevice,'plot.ps','p',5,.95
ppp = 2
space = 0.01
pos_space, ppp, space, sizes,ny=ppp
get_position, ppp, space, sizes, 0, pos, /rect

plot, rtime(istart:iend)-stime, kp(istart:iend), ytitle = 'Kp',$
      xtickname = xtickname, xtickv = xtickv, $
      xminor = xminor, xticks = xtickn, xstyle = 1, $
      ystyle = 1, thick = 3, charsize = 1.2,xrange=xrange,pos=pos,$
      xtitle=xtitle,yrange = [0,9],psym=-sym(1),symsize = .7


closedevice
end
