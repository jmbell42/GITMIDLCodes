reread = 1
alt = 300
ivars = [32,33,34]
filetypes = ['eiscat','sondre','pfisr']


if n_elements(season) eq 0 then season = ''
season = ask('season to plot: ',season)

let = strmid(season,0,1)
let = strupcase(let)

season = let+strmid(season,1)

if n_elements(kplev) eq 0 then kplev = 1
kplev = fix(ask('kp level to plot: ',tostr(kplev)))
lev = '0'+tostr(kplev)

display, filetypes
if n_elements(itype) eq 0 then itype = 0
itype = fix(ask('which radar to plot: ',tostr(itype)))

gitmdir = '~ifs1/IPY/'+season+'/'+lev+'/'
radardir = '/ifs1/Gitm/Radars/'+filetypes(itype)+'*/'

filelist_new = file_search(gitmdir+strmid(filetypes(itype),0,4)+'*')
if n_elements(filelist) eq 0 then filelist = ''

if n_elements(filelist_new) eq n_elements(filelist) and filelist_new(0) eq filelist(0) then begin
    reread = 0
    reread = fix(ask('whether to reread data: ',tostr(reread)))
endif 


rfile = file_search(radardir+'*.txt')
rfile = rfile(0)
nrlines = file_lines(rfile)

rdata = fltarr(nrlines,5)
rrtime = fltarr(nrlines)
rtt = fltarr(nrlines)
close,1
openr,1,rfile
t = ''
sline = 0
while not eof(1) do begin

    readf,1, t
    temp = strsplit(t,/extract)
    
    if n_elements(temp) eq 7 then begin
        temp2 = temp
        temp = fltarr(8)
        temp(0:3) = temp2(0:3)
        temp(4) = strmid(tostr(temp2(4)),0,5)
        temp(5) = strmid(tostr(temp2(4)),6)
        temp(6:7) = temp2(5:6)
    endif
    ry = fix(temp(0))
    if ry lt 2000 then ry = ry + 2000
    doy = fix(temp(1))
    if doy gt 365 then doy = doy - 365
    ut = float(temp(2))
    rdata(line,0) = float(temp(7))
    rdata(line,1) = float(temp(3))
    rdata(line,2) = float(temp(4))
    rdata(line,3) = float(temp(5))
    rdata(line,4) = float(temp(6))

    dt = [ry,doy,0,0,0]
    rdate = date_conv(dt,'F')
    rm = strmid(rdate,5,2)
    rd = strmid(rdate,8,2)
    rh = ut
    rmi = (ut-fix(ut))*60.
    rs = (rmi - fix(rmi))*60.
    ritime = [ry,rm,rd,fix(rh),fix(rmi),fix(rs)]
    c_a_to_r,ritime,rt
    rrtime(line) = rt

    rtt(line) = ritime(3)+ ritime(4)/60.+ ritime(5)/3600.

    line = line + 1

endwhile

rtt = rtt*3600.

close,1
filelist = filelist_new
nfiles = n_elements(filelist)

if reread then begin
    itime = intarr(6,nfiles)
    rtime = dblarr(nfiles)
    newline = intarr(nfiles)
    for ifile = 0, nfiles -1 do begin
        file = filelist(ifile)
        l1 = strpos(file,'.bin',0,/reverse_offset,/reverse_search)
        l2 = l1 - 13
        year = '20'+strmid(file,l2,2)
        mon  = strmid(file,l2+2,2)
        day  = strmid(file,l2+4,2)
        hour = strmid(file,l2+7,2)
        min  = strmid(file,l2+9,2)
        sec  = strmid(file,l2+11,2)
        
        it = fix([year,mon,day,hour,min,sec])
        itime(*,ifile) = it
        
        c_a_to_r,it,rt
        rtime(ifile) = rt
        if ifile ne 0 then begin
            if rtime(ifile) - rtime(ifile-1) gt 3600. or itime(2,ifile) ne itime(2,ifile-1) then $
              newline(ifile) = 1 else newline(ifile) = 0
        endif else begin
            newline(ifile) = 1
        endelse
    endfor
    
    locs = where(newline eq 1)

    times = locs(1:n_elements(locs)-1)-locs(0:n_elements(locs)-2)
    nlines = n_elements(times)
    maxtimes = max(times)
    time = fltarr(nlines,maxtimes)
    data = fltarr(nlines,5,maxtimes)
    Vars = ['[e-]','NmF2','HmF2','Te','Ti']
    
    rstart = intarr(nlines)
    rend = intarr(nlines)
    rlocs = intarr(nlines,10000) - 1
    nrl = fltarr(nlines)
    for iline = 0, nlines - 1 do begin
        fl = filelist(locs(iline):locs(iline+1)-1)
        thermo_readsat, fl, data_new, time_new, nTimes_new, Vars_new, nAlts, nSats, Files
        
        nmf2 = fltarr(ntimes_new)
        hmf2 = fltarr(ntimes_new)
        e = fltarr(ntimes_new)
        te = fltarr(ntimes_new)
        ti = fltarr(ntimes_new)
        alts = reform(data_new(0,0,2,*))/1000.
        temp = min(where(alts ge 200.0),f2min)
        for itime = 0, ntimes_new - 1 do begin
            nmf2(itime) = max(data_new(0,itime,32,f2min:nalts-3),imax)
            hmf2(itime) = data_new(0,itime,2,imax+f2min)/1000.
            c_r_to_a,ta,time_new(itime)
            time(iline,itime) = ta(3)+ta(4)/60.+ta(5)/3600.

        endfor

        time(iline,*) = time(iline,*)*3600.

        temp = min(abs(alts - alt),r)
        if r lt alt then r_l = r else r_l = r - 1
        r_h = r_l + 1
        
        a_d = alts(r_h) - alts(r_l)
        a_m = alts(r_h) - alt
        
                data(iline,0,0:ntimes_new-1) = data_new(0,*,ivars(0),r_h) - $
          (((data_new(0,*,ivars(0),r_h) - data_new(0,*,ivars(0),r_l)) * a_m) /  a_d)
        
        data(iline,1,0:ntimes_new-1) = nmf2
        
        data(iline,2,0:ntimes_new-1) = hmf2
        
        data(iline,3,0:ntimes_new-1) = data_new(0,*,ivars(1),r_h) - $
          (((data_new(0,*,ivars(1),r_h) - data_new(0,*,ivars(1),r_l)) * a_m) /  a_d)
        
        data(iline,4,0:ntimes_new-1) = data_new(0,*,ivars(2),r_h) - $
          (((data_new(0,*,ivars(2),r_h) - data_new(0,*,ivars(2),r_l)) * a_m) /  a_d)

        rlocs_new = where(rrtime ge time_new(0) and rrtime le time_new(ntimes_new-1))
        nrl(iline) = n_elements(rlocs_new)
        
        rlocs(iline,0:nrl(iline)-1) = rlocs_new
        c_r_to_a,ta,time_new(0)
        c_r_to_a,taa,time_new(ntimes_new-1)
    endfor
    
    rlocs = rlocs(*,0:max(nrl)-1)

endif


begtime = [2007,03,01,00,00,00]
c_a_to_r,begtime,stime
etime = stime + 24*3600.

display, vars
if n_elements(pvar) eq 0 then pvar = 0
pvar = fix(ask('which variable to plot: ',tostr(pvar)))

values = reform(data(*,pvar,*))
rvalues = reform(rdata(*,pvar))
case pvar of
    0: begin
        var = alog10(values)
        rvar = alog10(rvalues)
        yrange = [9,12]
        ytitle = Vars(pvar)+' at 300 km'
    end
    1: begin
        var = alog10(values)
        rvar = alog10(rvalues)
        yrange = [9,12]
        ytitle = Vars(pvar)
    end
    2: begin
        var = values
        rvar = rvalues
        yrange = [100,500]
        ytitle = Vars(pvar)
    end
    else: begin
        var = values
        rvar = rvalues
        yrange = [700,1700]
        ytitle = Vars(pvar)+' at 300 km'
    end
endcase

time_axis, stime, etime,btr,etr, xtickname, xtitle, xtickv, xminor, xtickn
xtitle = 'Universal Time'
title = season

xrange = [0,24*3600.]

setdevice, season+'_0'+tostr(kplev)+'.ps', 'p',5,.95
ppp = 4
space = 0.01
pos_space, ppp, space, sizes

loadct, 39
get_position, ppp, space, sizes, 0, pos, /rect
pos(3) = pos(3) - .1

plot, [0,24*3600.],/nodata,xrange = xrange,yrange = yrange, xstyle = 1, ystyle = 1, $
  xtitle = xtitle, ytitle = ytitle, xticks=xtickn, xtickv=xtickv,xminor = xminor, $
  xtickname = xtickname, pos = pos,title=title,thick=2

for iline = 0, nlines - 1 do begin
    
    oplot, time(iline,0:times(iline)-1),var(iline,0:times(iline)-1)
    
    if nrl(iline) gt 1 then begin
        oplot, rtt(rlocs(iline,0:nrl(iline)-1)),rvar(rlocs(iline,0:nrl(iline)-1)),$
          color = 254, linestyle = 2
    endif

endfor

legend,['GITM',filetypes(itype)],linestyle=[0,2],color=[0,254],pos = [pos(2) - .2,pos(1)+.05],$
  /norm,box=0
xyouts, pos(0) + .02,pos(1)+.02,'KP lev '+tostr(kplev),/norm
closedevice    

;plot, [0,24*3600.],/nodata,xrange = xrange,yrange = yrange, xstyle = 1, ystyle = 1, $
;  xtitle = xtitle, ytitle = ytitle, xticks=xtickn, xtickv=xtickv,xminor = xminor, $
;  xtickname = xtickname, pos = pos,title=title,thick=2
;for iline = 0, nlines - 1 do begin
;    
;    oplot, time(iline,0:times(iline)-1),var(iline,0:times(iline)-1)
;    
;    if nrl(iline) gt 1 then begin
;;        oplot, rtt(rlocs(iline,0:nrl(iline)-1)),rvar(rlocs(iline,0:nrl(iline)-1)),$
;          color = 254, linestyle = 2
;    endif
;stop
;endfor
    
end
