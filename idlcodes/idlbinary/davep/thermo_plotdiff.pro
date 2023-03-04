hemis = 's'

dir1 = './amie/'
dir2 = './weimer/'
filelist1 = file_search(dir1+'t*.save')
filelist2 = file_search(dir2+'t*.save')
nfiles1 = n_elements(filelist1)
nfiles2 = n_elements(filelist2)
if n_elements(nfiles) eq 0 then nfiles = 0
nfilesmax = max([nfiles1,nfiles2],imx)
nfilesmin = min([nfiles1,nfiles2],imn)
if imx eq 0 then begin
    fu = filelist1 
    name = 'AMIE'
    fd = filelist2
    name_base = 'Weimer'
endif else begin   
    fu = filelist2
    name = 'Weimer'
    fd = filelist1
    name_base = 'AMIE'
endelse

filelist_base = strarr(nfilesmin)
filelist = filelist_base

str1 = strsplit(fd(0),'/',/extract)
str2 = strsplit(fu(0),'/',/extract)

jfile = 0
for ifile = 0, nfilesmin - 1 do begin
    farr1 = strsplit(fd(ifile),'/',/extract)
    filecomp = str2(0)+'/'+farr1(1)
    filenum = where(filecomp eq fu)

    if filenum ne -1 then begin
        filelist_base(jfile) = fd(ifile)
        filelist(jfile) = fu(filenum)
        jfile = jfile + 1
    endif
    
endfor
ishrink = min(where(filelist eq ''))
filelist = filelist(0:ishrink-1)
filelist_base = filelist_base(0:ishrink-1)

nfilesmin = n_elements(filelist)
if nfilesmin eq nfiles then getnewdata = 0 else getnewdata = 1
getnewdata = fix(ask('get new data? (0/1)' ,tostr(getnewdata)))
nfiles = nfilesmin

itimearr = intarr(6,nfilesmin)

if getnewdata then begin
    phimin = fltarr(nfilesmin)
    phimin_base = fltarr(nfilesmin)
    phimax = fltarr(nfilesmin)
    phimax_base = fltarr(nfilesmin)
    avgval = phimax
    avgval_base = phimax
endif

isfirst = 1
for ifile = 0, nfilesmin - 1 do begin
    
    temp = strsplit(filelist(ifile),'/',/extract)
    itimearr(0,ifile) = strmid(temp(1),1,2)
    itimearr(1,ifile) = strmid(temp(1),3,2)
    itimearr(2,ifile) = strmid(temp(1),5,2)
    itimearr(3,ifile) = strmid(temp(1),8,2)
    itimearr(4,ifile) = strmid(temp(1),10,2)
    
    if itimearr(0,ifile) lt 50 then itimearr(0,ifile) = itimearr(0,ifile)$
      + 2000 else itimearr(0,ifile) = itimearr(0,ifile) + 1900
    
    if getnewdata then begin
        
        print, 'Working on '+filelist(ifile)+'...'
        read_thermosphere_file, filelist(ifile), nvars, nalts, nlats, nlons, $
          vars, data, rb, cb, bl_cnt
        
        read_thermosphere_file, filelist_base(ifile), nvars_base, $
          nalts_base, nlats_base, nlons_base, vars_base, data_base, $
          rb_base, cb_base, bl_cnt_base
        
        
        alt = reform(data(2,*,*,*)) / 1000.0
        lat = reform(data(1,*,*,*)) / !dtor
        lon = reform(data(0,*,*,*)) / !dtor
        
;lineplot of cpcp/averages??
        minlat = 40.0
        
        if hemis eq 'N' then loc = where(lat(0,*,0) gt minlat)
        if hemis eq 'S' then loc = where(lat(0,*,0) lt (-1)*minlat)
        if hemis eq 'A' then loc = where(abs(lat(0,*,0)) gt minlat)
        if isfirst then begin
            for ivar = 0, nvars - 1 do print, ivar, vars(ivar)
            if n_elements(iplot) eq 0 then iplot = 0
            iplot = fix(ask('which variable to plot',tostr(iplot)))
        endif
        
         ;special for phi
        if vars(iplot) eq ' Potential (kV)' then begin
            ialt = 20
            phimin(ifile) = min(data(iplot,*,loc,20))
            phimax(ifile) = max(data(iplot,*,loc,20))
            phimin_base(ifile) = min(data_base(iplot,*,loc,ialt))
            phimax_base(ifile) = max(data_base(iplot,*,loc,ialt))
            isfirst = 0
        endif else begin
            if isfirst then begin
                for nalt = 0, nalts - 1 do print, nalt, alt(0,0,nalt)
                if n_elements(ialt) eq 0 then ialt = 0
                ialt = fix(ask('which altitude to plot',tostr(ialt)))
                isfirst = 0
            endif
            avgval(ifile) =  mean(data(iplot,*,loc,ialt))
            avgval_base(ifile) = mean(data_base(iplot,*,loc,ialt))
        endelse
    endif 
endfor

print, 'Working on plot... '

if vars(iplot) eq ' Potential (kV)' then begin
    cpcp = phimax - phimin
    cpcp_base = phimax_base - phimin_base
    diff = cpcp - cpcp_base
endif else begin
    diff = avgval - avgval_base
endelse

setdevice, 'plot.ps', 'p',5,.93

 ppp = 3
 space = 0.01
 pos_space, ppp, space, sizes, ny = ppp
 
 get_position, ppp, space, sizes, 0, pos, /rect

rtime = fltarr(nfilesmin)

for itime = 0, nfilesmin - 1 do begin
    taa = itimearr(*,itime)
    c_a_to_r, taa, rt
    rtime(itime) = rt
endfor
   
stime = rtime(0)
etime = rtime(nfilesmin-1)
time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn

plot, rtime-stime, cpcp, ytitle = name ,/noerase,$
   xtickv = xtickv,xtickname = strarr(10)+' ', $
  xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
  thick = 3, charsize = 1.2
get_position, ppp, space, sizes, 1, pos, /rect
plot, rtime-stime, cpcp_base, ytitle = name_base,/noerase,$
  xtickv = xtickv,xtickname = strarr(10)+' ', $
  xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
  thick = 3, charsize = 1.2

get_position, ppp, space, sizes, 2, pos, /rect
ytitle = vars(iplot)+tostr(alt(0,0,ialt))+'km ('$
  +name+ ' - '+name_base +')'

plot, rtime-stime, diff, ytitle = ytitle, /noerase,$
  xtickname = xtickname, xtickv = xtickv, $
  xminor = xminor, xticks = xtickn, xstyle = 1, pos = pos, $
  thick = 3, charsize = 1.2,xtitle = xtitle
oplot,[rtime(0)-stime,rtime(nfilesmin-1)-stime],[-1e-32,1e-32],$
  thick=3,linestyle=2
closedevice

end

    
    

