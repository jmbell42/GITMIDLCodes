reread = 1
if (n_elements(eden) gt 0) then begin
    answer = ask('whether to re-read data','n')
    if (strpos(mklower(answer),'n') gt -1) then reread = 0
endif


if (reread) then begin

    if (n_elements(dir) eq 0) then dir = '.'
    dir = ask('gitm directory',dir)
    filelist = file_search(dir+'/*.bin')

    file = filelist(0)

    length = strpos(file,'.bin')
    ls = length-13
    
    yr = strmid(file,ls,2)
    iYear = tostr(2000+fix(yr))
    iMonth = strmid(file,ls+2,2)
    iDay = strmid(file,ls+4,2)
    
    raddir = '/data6/Data/Radar/'
    ndays = 1
    
    thermo_readsat, filelist, data, gtime, nTimes, Vars, nAlts, nSats, nfiles
    stime = gtime(0) 
    etime = max(gtime)
    c_r_to_a, starr,gtime(0)
    c_r_to_a, etarr,max(gtime)
    if etarr(2) - starr(2) ge 0 then begin
        days = intarr(etarr(2) - starr(2)+1)
        months = intarr(etarr(2) - starr(2)+1)
        months(*) = starr(1)
        for iday = 0, ndays - 1 do begin
            days(iday) = starr(2)+iday
        endfor
    endif else begin
        yr = starr(0)
        mt = starr(1)
        dy = starr(2)
        ndays = d_in_m(yr,mt)
        days = intarr(ndays-starr(2)+etarr(2)+1)
        nd = n_elements(days)
        months = intarr(nd)
        for iday = 0, ndays - 1 do begin
            if dy + iday le ndays then begin
                days(iday) = starr(2) + iday
                months(iday) = starr(1)
                idayfin = iday
            endif else begin
                days(iday) = iday - idayfin
                months(iday) = etarr(1)
            endelse
        endfor
    endelse

radfiles = [' ']
    for iday = 0, ndays - 1 do begin
        rfiles = file_search(raddir+'*'+tostr(iyear)+tostr(months(iday))+tostr(days(iday))+'*.txt')
        nradfiles = n_elements(radfiles)
        for ifile = 0, nradfiles - 1 do begin
            radfiles = [radfiles,rfiles(ifile)]
        endfor
    endfor
    nradfiles = n_elements(radfiles)-1
    radfiles = radfiles(1:nradfiles)

    if nradfiles gt 1 then begin
        display, radfiles
        if n_elements(ifile) eq 0 then ifile = 0
        ifile = fix(ask('which radar file: ',tostr(ifile)))
    endif else begin
        ifile = 0
    endelse

    fn = radfiles(ifile)
    
    print, ' '
    print, 'Working on ',fn(ifile)
    print, ' '

    len = strpos(fn,'.txt',/reverse_search,/reverse_offset)-8
    syear = strmid(fn,len,4)
    smonth = strmid(fn,len+4,2)
    sday = strmid(fn,len+6,2)
    
    read_radar, syear, smonth, sday, eden, position,alts, itimearr, nalts, whichtype
    
    nrtimes = n_elements(itimearr(0,*))
    radtime = fltarr(nrtimes)
    for itime = 0, nrtimes - 1 do begin
        c_a_to_r, itimearr(*,itime), rt
        radtime(itime) = rt
    endfor
    
    gitmne = alog10(transpose(reform(data(0,*,33,*))))
    ngalts = n_elements(data(0,0,0,*))
    gx = fltarr(ngalts,ntimes)
    gy = fltarr(ngalts,ntimes)
    galts = reform(data(0,0,2,*))/1000.
    for ialt = 0, ngalts - 1 do begin
        gx(ialt,*) = gtime
    endfor
    for itime = 0, ntimes - 1 do begin
        gy(*,itime) = galts
    endfor
endif



z = alog10(eden)
x = fltarr(nalts,nrtimes)
y = alts
for ialt = 0, nalts - 1 do begin
    x(ialt,*) = radtime
endfor


setdevice,'plot.ps','l',5,.95
ppp = 2
space = 0.02
pos_space, ppp, space, sizes, ny = ppp

get_position, ppp, space, sizes, 0, pos, /rect
pos(0) = pos(0) + 0.05
pos(2) = pos(2) - 0.05

get_position, ppp, space, sizes, 1, pos2, /rect
pos2(0) = pos2(0) + 0.05
pos2(2) = pos2(2) - 0.05
loadct, 39
srtime = x(0)
ertime = max(x)
time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn

min1 = min(gitmne,max=max1)
locs = where(z eq z and z gt 0)
min2 = min(z(locs),max=max2)

minv = min([min1,min2])
maxv = max([max1,max2])
levels = findgen(31) * (maxv-minv) / 30 + minv
locs = where(radtime ge stime and radtime le etime)

contour,z(*,locs),x(*,locs)-stime,y(*,locs),/fill,levels = levels, $
  yrange = [150,400], xtickname=strarr(10)+' ',$
  xtickv=xtickv,xticks=xtickn,xminor=xminor,xrange = [0,etime-stime],pos=pos,/noerase

contour,gitmne,gx-stime,gy,/fill,levels = levels, $
  yrange = [150,400],xtickname=xtickname,xtitle = xtitle, $
  xtickv=xtickv,xticks=xtickn,xminor=xminor,xrange = [0,etime-stime],pos=pos2,/noerase


ctpos = [pos(2)+0.01,pos(1),pos(2)+0.03,pos(3)]
maxmin = mm(levels)
title = 'Radar [e-] log(#/m!U3!N)'
plotct,254,ctpos,maxmin,title,/right,color=color

ctpos = [pos2(2)+0.01,pos2(1),pos2(2)+0.03,pos2(3)]
maxmin = mm(levels)
title = 'GITM [e-] log(#/m!U3!N)'
plotct,254,ctpos,maxmin,title,/right,color=color

closedevice

end
