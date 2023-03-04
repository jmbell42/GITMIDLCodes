if n_elements(sitime) eq 0 then sitime = [2003,10,28,0, 0, 0] 
sitime = fix(strsplit(ask('start time: ', strjoin(tostr(sitime),' ')),/extract))
if n_elements(eitime) eq 0 then eitime = [2003,10,29,0,0,0] 
eitime = fix(strsplit(ask('end time: ', strjoin(tostr(eitime),' ')),/extract))
c_a_to_r,sitime,stime
c_a_to_r,eitime,etime
bdoy = jday(sitime(0),sitime(1),sitime(2))
edoy = jday(eitime(0),eitime(1),eitime(2))

ndays = edoy - bdoy + 1
cyear = tostr(sitime(0))
cdoy = tostr(bdoy)
cmonth = tostr(sitime(1))
cday = tostr(sitime(2))
guvidir = '~/GUVI/'+cyear+'/'
filelist = strarr(ndays)

nptsmax = 5000
norbitsmax = 200
if n_elements(bdoyold) eq 0 then bdoyold = 0
reread = 1 
if bdoy eq bdoyold then begin
    reread = 'n'
    reread = ask('whether to reread data: ',reread)
    if strpos(reread,'y') ge 0 then reread = 1 else reread = 0
endif
bdoyold = bdoy

if reread then begin
    lat = fltarr(norbitsmax,nptsmax)
    lon = lat
    ut = lat
    rtime = dblarr(norbitsmax,nptsmax)
    on2 = lat
    sza = lat
    iorb = 0
    npts = intarr(ndays)
    norbits = intarr(ndays)
    for ifile = 0, ndays -1  do begin
        fn = file_search(guvidir+'ON2_'+cyear+'_'+chopr('00'+tostr(bdoy+ifile),3)+'*.sav')
        filelist(ifile) = fn(0)
        
        restore,filelist(ifile)
        norbits(ifile) = n_elements(saved_data)
        npts(ifile)  = min(saved_data.points)
        
        for iorbit = iorb, iorb+norbits(ifile) - 1 do begin
            on2(iorbit,0:npts(ifile)-1) = saved_data(iorbit-iorb).on2(0:npts(ifile)-1)
            lat(iorbit,0:npts(ifile)-1) = saved_data(iorbit-iorb).lat(0:npts(ifile)-1)
            lon(iorbit,0:npts(ifile)-1) = saved_data(iorbit-iorb).lon(0:npts(ifile)-1)
            sza(iorbit,0:npts(ifile)-1) = saved_data(iorbit-iorb).sza(0:npts(ifile)-1)
            ut(iorbit,0:npts(ifile)-1) = saved_data(iorbit-iorb).ut(0:npts(ifile)-1)

            year=saved_data(iorbit-iorb).year
            day = saved_data(iorbit-iorb).day
            month = saved_data(iorbit-iorb).month

            for i = 0L, npts(ifile) - 1 do begin
                t = ut(iorbit,i)
                hour = fix(t)
                min = fix((t-hour)*60.)
                sec = fix((((t-hour)*60.)-min)*60.)
                itime = [year,month,day,hour,min,sec]
                c_a_to_r,itime,rt
                rtime(iorbit,i) = rt
            endfor

        endfor
        iorb = iorbit
        
    endfor

    npoints = max(npts)
    norbs = fix(total(norbits))
    on2 = on2(0:norbs-1,0:npoints-1)
    lon = lon(0:norbs-1,0:npoints-1)
    lat = lat(0:norbs-1,0:npoints-1)
    sza = sza(0:norbs-1,0:npoints-1)
    ut = ut(0:norbs-1,0:npoints-1)
    rtime = rtime(0:norbs-1,0:npoints-1)

endif

file = 'guvi_'+cyear+cmonth+cday+'.ps'
setdevice,file,'p',5,.95
loadct, 39
ppp = 2
space = 0.03
pos_space, ppp, space, sizes, ny = ppp
get_position, ppp, space, sizes, 0, pos, /rect
pos(0) = pos(0) + 0.1
pos(2) = pos(2) - .1

range = [0,1.4]
mini = range(0)
maxi = range(1)
levels = findgen(31) * (range(1)-range(0)) / 30 + range(0)
xrange = [0,360]
yrange = [-90,90]

loadct,39
map_set,/continents,pos=pos

locs = where(rtime(*,0) ge stime and rtime(*,0) le etime)

contour, on2(locs,*),lon(locs,*),lat(locs,*),levels=levels,/overplot,xtitle = 'Longitude',$
  ytitle='Latitude',/fill

ctpos = pos
ctpos(0) = pos(2)+0.025
ctpos(2) = ctpos(0)+0.03
maxmin = [mini,maxi]
plotct, 255, ctpos, maxmin, title, /right

closedevice

end

