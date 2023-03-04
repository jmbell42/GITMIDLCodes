PRO read_radar, syear, smonth, sday, eden, position,alts, itimearr, nalts, whichtype

raddir = './'
cdate = syear+smonth+sday

files = file_search(raddir+'*'+cdate+'*')
nfiles = n_elements(files)
types = strarr(nfiles)
for ifile = 0, nfiles - 1 do begin
    len2 = strpos(files(ifile),syear,/reverse_search,/reverse_offset)
    len1 = strpos(files(ifile),'/',/reverse_search,/reverse_offset)+1
    
    types(ifile) = strmid(files(ifile),len1,len2-len1)
endfor

if nfiles gt 1 then begin
    display, types
    if n_elements(itype) eq 0 then itype = 0
    itype = fix(ask('which radar type: ', tostr(itype)))
endif else begin
    print, 'There is one radar file for this day: '+types(0)
    itype = 0
endelse
whichtype = types(itype)
fn = files(itype)
close, 5
openr,5, fn
temp = ' '

started = 0
ialt = 0
itime = -1
while not started do begin
    readf,5, temp
    if strpos(temp,'Millstone Hill UHF') ge 0 then started = 1
endwhile
if strpos(temp,'Steerable') ge 0 then begin 
    steer = 1
    zen = 0
endif else begin
    steer = 0
    zen = 1
    itime = itime + 1
    ialt = 0
endelse
readf,5,temp
nmax = 10000
altsmax = 150
itimearr = intarr(6,nmax)
position = fltarr(2,nmax)
alts = fltarr(altsmax,nmax)
nalts = intarr(nmax)
eden = fltarr(altsmax,nmax)

ialtmax = 0
while not eof(5) do begin
    
    readf, 5, temp
     if strpos(temp,'Millstone Hill UHF') ge 0 then begin
        
        if strpos(temp,'Steerable') ge 0 then begin 
            steer = 1
            zen = 0
        endif
        
        if strpos(temp,'Zenith') ge 0 then begin 
            steer = 0
            zen = 1
            itime = itime + 1
            ialt = 0
        endif
        readf, 5, temp
    endif else begin
        
        if zen then begin
            
            arr = strsplit(temp,/extract)
            if n_elements(arr) gt 1 then begin
                day = fix(arr(0))
                ut = chopr('00000'+arr(1),6)

                mon = fix(arr(2))
                year = fix(arr(3))
                alt = float(arr(4))
                lat = float(arr(5))
                lon = float(arr(6))
                if lon lt 0 then lon = 360.0 + lon
                SN = float(arr(7))
                stop
                if strpos(arr(8),'missing') ge 0 then arr(8) = -999
                nelec = float(arr(8))
                
                if sn ge .1 and nelec gt 0 then begin
                    alts(ialt,itime) = alt
                    eden(ialt,itime) = nelec
                    
                    if ialt eq 0 then begin
                        
                        hour = fix(strmid(ut,0,2))
                        min = fix(strmid(ut,2,2))
                        sec = fix(strmid(ut,4,2))
                        itimearr(*,itime) = [year,mon,day,hour,min,sec]
                        position(*,itime) = [lon,lat]
                    endif

                    ialt = ialt + 1
                    nalts(itime) = ialt
                    if ialt gt ialtmax then ialtmax = ialt
                endif
            endif
        endif
    endelse

endwhile

locs = where(itimearr(0,*) ne 0)
itimearr = itimearr(*,locs)
alts = alts(0:ialtmax-1,locs)
eden = eden(0:ialtmax-1,locs)
position = position(*,locs)
nalts = nalts(locs)

ntimes = n_elements(itimearr(0,*))
rtime = fltarr(ntimes)
locs = [0]
for itime = 0, ntimes - 1 do begin
    c_a_to_r, itimearr(*,itime), tr
    rtime(itime) = tr
    
    if itime gt 0 then begin
        if rtime(itime) - rtime(itime-1) lt 10 then locs = [locs,itime-1]

    endif
endfor

locs = locs(1:n_elements(locs)-1)
itimearr = itimearr(*,locs)
alts = alts(0:ialtmax-1,locs)
eden = eden(0:ialtmax-1,locs)
position = position(*,locs)
nalts = n_elements(alts(*,0))

close, 5

end
