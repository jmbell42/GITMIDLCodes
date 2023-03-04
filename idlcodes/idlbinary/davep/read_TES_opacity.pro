filelist = file_search('~/UpperAtmosphere/TES/*van')
display,filelist
if n_elements(ifile) eq 0 then ifile = 0
ifile = fix(ask('which file to read',tostr(ifile)))

openr,1,filelist(ifile)
temp = ''
readf,1,temp
header = strsplit(temp,/extract)
nvars = n_elements(header)

nlinesmax = 10000
tes_data = fltarr(nvars,nlinesmax)

iline = 0
while not eof(1) do begin
   readf,1,temp
   tes_data(*,iline) = strsplit(temp,/extract)
   iline = iline + 1
endwhile
close,1
nlines = iline

tes_data = tes_data(*,0:nlines - 1)

lonvar = where(header eq 'LONGITUDE_IAU2000')
latvar = where(header eq 'LATITUDE')
tauvar = where(header eq 'ATM.NADIR_OPACITY[1]')

tau = tes_data(tauvar,*)
lon = tes_data(lonvar,*)
lat = tes_data(latvar,*)
loadct,39
contour,tau,lon,lat,xrange = [0,360],yrange=[-90,90],/fill,nlevels=30,/irregular


end
