PRO read_saber,date,data,szaave,rtime,altitude,latitude,longitude,vars
;date: yyyymmdd

cyear = strmid(date,0,4)
cmonth=strmid(date,4,2)
cday = strmid(date,6,2)

saberdir = '~/SABER/'+cyear+'/'
files = file_search(saberdir+'timed*_'+cyear+cmonth+cday+'*.cdf')
nfiles = n_elements(files)

nrecsmax = 300
naltsmax  = 500
iline = 0


nrecs = intarr(nfiles)
nalts = intarr(nfiles)
altitude = fltarr(naltsmax,nfiles*nrecsmax)
latitude = fltarr(naltsmax,nfiles*nrecsmax)
longitude = fltarr(naltsmax,nfiles*nrecsmax)
no = altitude
temp = altitude
density = altitude
sza = altitude
o2 = altitude
o2_unfilt = altitude
no120 = fltarr(nfiles*nrecsmax)
orbitstime = fltarr(nfiles)
date = fltarr(nfiles*nrecsmax)
time = altitude
szaave = date
slt = sza
sltave = szaave

nvars = 5

for ifile = 0, nfiles - 1 do begin
    file = files(ifile)
    id = cdf_open(file)
    result = cdf_inquire(id)
    
    cdf_control,id,var='event',/z,get_var_info=v
    nrecs(ifile) = v.maxrec
    nzVars = result.nzVars
    natts = result.natts
    svars = strarr(nzVars)
    
    for i=0,nzVars-1 do begin
        r = cdf_varinq(id,i,/z)
        svars(i) = r.name
     ;   if ifile eq 0 then  print, r.name, i
    endfor
    
    
    cdf_varget, id, 1, event,rec_count=nrecs(ifile),/z
    cdf_varget, id, 16, t,rec_count=nrecs(ifile),/z
    cdf_varget, id, 2, dte,rec_count=nrecs(ifile),/z
    cdf_varget, id, 33,lon,rec_count=nrecs(ifile),/z
    cdf_varget, id, 32, lat,rec_count=nrecs(ifile),/z
    cdf_varget, id, 31, alt,rec_count=nrecs(ifile),/z
    cdf_varget, id, 34, tpsza,rec_count=nrecs(ifile),/z
    cdf_varget, id, 27, tpszaave,rec_count=nrecs(ifile),/z
    cdf_varget, id, 36, tpslt,rec_count=nrecs(ifile),/z
    cdf_varget, id, 29, tpsltave,rec_count=nrecs(ifile),/z
    cdf_varget, id, 89, no_ver,rec_count=nrecs(ifile),/z
    cdf_varget, id, 55, dens,rec_count=nrecs(ifile),/z
    cdf_varget, id, 53, ktemp,rec_count=nrecs(ifile),/z
    cdf_varget, id, 91, no_ver120,rec_count=nrecs(ifile),/z
    cdf_varget, id, 70, o2_ver,rec_count=nrecs(ifile),/z
    cdf_varget, id, 68, o2_ver_unfilt,rec_count=nrecs(ifile),/z
    
    nalts(ifile) = n_elements(alt(*,0))
        
    altitude(0:nalts(ifile)-1,iline:nrecs(ifile)+iline-1) = alt  
    latitude(0:nalts(ifile)-1,iline:nrecs(ifile)+iline-1) = lat
    longitude(0:nalts(ifile)-1,iline:nrecs(ifile)+iline-1) = lon  
    no(0:nalts(ifile)-1,iline:nrecs(ifile)+iline-1) = no_ver
    o2(0:nalts(ifile)-1,iline:nrecs(ifile)+iline-1) = o2_ver
    o2_unfilt(0:nalts(ifile)-1,iline:nrecs(ifile)+iline-1) = o2_ver_unfilt
    temp(0:nalts(ifile)-1,iline:nrecs(ifile)+iline-1) = ktemp
    density(0:nalts(ifile)-1,iline:nrecs(ifile)+iline-1) = dens
    no120(iline:nrecs(ifile)+iline-1) = no_ver120
    date(iline:nrecs(ifile)+iline-1) = dte
    time(0:nalts(ifile)-1,iline:nrecs(ifile)+iline-1) = t
    sza(0:nalts(ifile)-1,iline:nrecs(ifile)+iline-1) = tpsza
    szaave(iline:nrecs(ifile)+iline-1) = tpszaave
    slt(0:nalts(ifile)-1,iline:nrecs(ifile)+iline-1) = tpslt
    sltave(iline:nrecs(ifile)+iline-1) = tpsltave
    iline = iline + nrecs(ifile)
    cdf_close,id
    
    cdate = tostr(dte(0))
    hour = t(0)/1000./3600.
    ih = fix(hour)
    im = fix((hour-ih)*60.)
    is  = fix(((hour-ih)*60-im)*60)
    iy = fix(strmid(cdate,0,4))
    doy = fix(strmid(cdate,4,3))
    dt = fromjday(iy,doy)
    imo = dt(0)
    id = dt(1)
    it = [iy,imo,id,ih,im,is]
    c_a_to_r,it,rt
    orbitstime(ifile) = rt
endfor
maxalts = max(nalts)
altitude = altitude(0:maxalts-1,0:iline-1)
latitude = latitude(0:maxalts-1,0:iline-1)
longitude = longitude(0:maxalts-1,0:iline-1)
no = no(0:maxalts-1,0:iline-1)
o2 = o2(0:maxalts-1,0:iline-1)
o2_unfilt=o2_unfilt(0:maxalts-1,0:iline-1)
temp = temp(0:maxalts-1,0:iline-1)
density = density(0:maxalts-1,0:iline-1)
time = time(0:maxalts-1,0:iline-1)
no120 = no120(0:iline-1)
date = date(0:iline-1)
szaave = szaave(0:iline-1)
sza = sza(0:maxalts-1,0:iline-1)
sltave = sltave(0:iline-1)
slt = slt(0:maxalts-1,0:iline-1)


ntimes = n_elements(altitude(0,*))
data = fltarr(nvars,maxalts,iline)
rtime = dblarr(maxalts,ntimes)
cdate = tostr(date(0))
hour = time(0,0)/1000./3600.
ih = fix(hour)
im = fix((hour-ih)*60.)
is  = fix(((hour-ih)*60-im)*60)
iy = fix(strmid(cdate,0,4))
doy = fix(strmid(cdate,4,3))
dt = fromjday(iy,doy)
imo = dt(0)
id = dt(1)
it = [iy,imo,id,ih,im,is]
c_a_to_r,it,rt
rtime(*,0) = rt

for itime = 1, ntimes -1 do begin
    for ialt = 0, maxalts - 1 do begin
        if no(ialt,itime) lt 0 then begin
            no(ialt,itime) = (no(ialt,itime-1)) 
            o2(ialt,itime) = (o2(ialt,itime-1)) 
            o2_unfilt(ialt,itime) = (o2_unfilt(ialt,itime-1)) 
            temp(ialt,itime) = (temp(ialt,itime-1))
            altitude(ialt,itime) = (altitude(ialt,itime-1))
            density(ialt,itime) = (density(ialt,itime-1))
        endif           
        hour = time(ialt,itime)/1000./3600.
        ih = fix(hour)
        im = fix((hour-ih)*60.)
        is  = fix(((hour-ih)*60-im)*60)
        
        cdate = tostr(date(itime))
        iy = fix(strmid(cdate,0,4))
        doy = fix(strmid(cdate,4,3))
        dt = fromjday(iy,doy)
        imo = dt(0)
        id = dt(1)
        if ih gt 23 then begin
            ih = ih - 24
        endif
        it = [iy,imo,id,ih,im,is]
        c_a_to_r,it,rt
        rtime(ialt,itime) = rt
;if rt eq stime then stop
    endfor
endfor
Vars = ['NO_ver','O2_ver','Temperature','Density','O2_ver(unfiltered)']
data(0,*,*) = no
data(1,*,*) = o2
data(2,*,*) = temp
data(3,*,*) = density
data(4,*,*) = o2_unfilt


end
