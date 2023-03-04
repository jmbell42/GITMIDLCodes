PRO read_champfile, file, itimearr, lat, lon, alt, mass, rho,nlines

nlines = file_lines(file)
lat = fltarr(nlines)
lon = lat
alt = lat
mass = lat
rho = lat
mjd = lat
itimearr = intarr(6,nlines)
temp = ''

close,5 
openr, 5, file
for iline = 0L, nlines - 1 do begin
    readf, 5, temp
    t = strsplit(temp, /extract)
    mjd(iline) = t(0)
    lat(iline) = t(1)
    lon(iline) = t(2)
    alt(iline) = t(3)
    mass(iline) = t(4)
    rho(iline) = t(5)

    mjd2000, mjd(iline), timearr
    itimearr(*,iline) = timearr


endfor 
close, 5

end
