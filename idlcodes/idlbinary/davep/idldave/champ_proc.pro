filelist = findfile('champdata*.txt')

nfilesnew = n_elements(filelist) 

default = 1
;if n_elements(nfiles) eq 0 then nfiles = 0
;if nfilesnew eq nfiles then begin
;    default = 0
;    reread = 'n'
;    reread = ask('reread champ files: ',reread)
;    if reread eq 'y' then default = 1 else default = 0
;endif

nfiles = nfilesnew

close,6
close,7
close,8

head = ['UT','LAT','LON','Height (km)']
openw,7, 'champ_pos_all.dat'
printf,7,head
openw,8,'champ_acc_all.dat'

if default then begin
    for ifile = 0, nfiles - 1 do begin
        read_champfile, filelist(ifile), itimearr, lat, lon, alt, mass, rho,$
          nlines
        openw, 6, 'champ_'+tostr(itimearr(0,0))+tostr(itimearr(1,0))+$
          tostr(itimearr(2,0))+'.dat'
        printf, 6, "#START"

        for iline = 0L, nlines - 1 do begin
            if lon(iline) lt 0 then begin
                lons = 360. + lon(iline)
            endif else begin
                lons = lon(iline)
            endelse
            printf, 6, itimearr(*,iline),0,lons,lat(iline),alt(iline),$
              format = '(7I,3F)'

            hours = itimearr(3,iline)+itimearr(4,iline)/60.+itimearr(5,iline)$
              /3600.
            printf, 7, hours, lat(iline),lon(iline),alt(iline)
            printf,8, hours,lat(iline),lon(iline),rho(iline)
        endfor
        close, 6
        
    endfor
    close,7
    close,8
endif

end
