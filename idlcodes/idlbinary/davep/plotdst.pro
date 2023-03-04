dstfile = findfile('dst*.txt')
ifile = 0

if n_elements(dstfile) gt 1 then begin
    for i = 0, n_elements(dstfile) do begin
        print, i, dstfile(i)
        endfor
    ifile = ask('which file to plot: ',tostr(ifile))
endif

headerlines = 17
nlines = file_lines(dstfile(ifile)) - headerlines
itimearr = intarr(6,nlines)
rtime = fltarr(nlines)
dst = fltarr(nlines)

temp = ''
openr, 5,dstfile(ifile)

header = 1
while header do begin
    readf, 5, temp 
    pound = strmid(temp,0,1)
    if pound ne '#' then header = 0
endwhile

t = strsplit(temp,/extract)
itimearr(0,0) = strmid(t(0),0,4)
itimearr(1,0) = strmid(t(0),5,2)
itimearr(2,0) = strmid(t(0),8,2)
itimearr(3,0) = strmid(t(1),0,2)
dst(0) = t(2)
st = itimearr(*,0) 
c_a_to_r, st ,rt
rtime(0) = rt

itime = 1
while ~ EOF(5) do begin
    readf, 5, temp    
    t = strsplit(temp,/extract)
    itimearr(0,itime) = strmid(t(0),0,4)
    itimearr(1,itime) = strmid(t(0),5,2)
    itimearr(2,itime) = strmid(t(0),8,2)
    itimearr(3,itime) = strmid(t(1),0,2)
    dst(itime) = t(2)

    at = itimearr(*,itime)
    c_a_to_r,at,rt
    rtime(itime) = rt
    itime = itime + 1
endwhile
close,5

stime = rtime(0)
etime = rtime(nlines - 1)

time_axis,  stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
setdevice, 'dst.ps','l',5,.95
plot, rtime - stime, dst, ytitle = 'Dst', yrange = yrange,$
  xtitle = xtitle, xtickname = xtickname,pos = pos, xtickv = xtickv, $
  xminor = xminor, xticks = xtickn,xstyle = 1, ystyle = 1,charsize = 1.3,$
  thick = 3
closedevice
end
