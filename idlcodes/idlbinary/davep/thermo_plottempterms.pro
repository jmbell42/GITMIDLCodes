GetNewData = 1
plotall = 0

files = file_search('3D*')

for ifile = 0, n_elements(files) - 1 do print, tostr(ifile)+'   '+files(ifile)
ifile = 0
if n_elements(filenum1) eq 0 then filenum1 = 0
filenum1 = fix(ask('which file (1): ',tostr(filenum1)))
if n_elements(filenum2) eq 0 then filenum2 = 0
filenum2 = fix(ask('which file (2): ',tostr(filenum2)))

l = 24
l2 = strlen(files(filenum1))
filenamenew1 = strmid(files(filenum1),l2 - l)
filenamenew2 = strmid(files(filenum2),l2 - l)
l1 = 17
year = strmid(files(filenum1),l2 - l1,2)
month =strmid(files(filenum1),l2 - l1 + 2,2)
day = strmid(files(filenum1),l2 - l1 + 4,2)
hour =strmid(files(filenum1),l2 - l1+7,2)
min = strmid(files(filenum1),l2 - l1+9,2)
sec = strmid(files(filenum1),l2 - l1+11,2)

if n_elements(filename1) eq 0 then filename1 = ' '
if filenamenew eq filename1 then begin
    GetNewData = 0
    GetNewData = fix(ask('whether to get new data: ',tostr(GetNewData)))
endif
filename1 = filenamenew1
filename2 = filenamenew2

if GetNewData eq 1 then begin
    fn = filename1
    print, 'Reading file ',fn
    
    read_thermosphere_file, fn, nvars, nalts, nlats, nlons, $
      vars, data1, rb, cb, bl_cnt
    
    alts = reform(data1(2,0,0,*))/1000.
    lons = reform(data1(0,*,0,0))/!dtor
    lats = reform(data1(1,0,*,0))/!dtor
   
    fn = filename2
    print, 'Reading file ',fn
    
    read_thermosphere_file, fn, nvars, nalts, nlats, nlons, $
      vars, data2, rb, cb, bl_cnt
    
endif


for ivar = 0, nvars - 1 do print, tostr(ivar)+'  '+vars(ivar)

uttime =fix(hour)+(min)/60.+fix(sec)/60./60.

if year lt 50 then year = tostr(fix(year) + 2000) else year = tostr(fix(year) + 1900)
strdate = year+'-'+month+'-'+day
sza = fltarr(nlons)
for ilon = 2, nlons - 3 do begin
    zsun,strdate,uttime ,0,lons(ilon),zenith,azimuth,solfac
    sza(ilon) = zenith
endfor

for ilon = 2, nlons - 3 do print, tostr(ilon), '  ', tostrf(sza(ilon))
if n_elements(whichlt) eq 0 then whichlt = 0
whichlt = fix(ask('which sza: ',tostr(whichlt)))

totalden = fltarr(nalts)
mass = fltarr(nalts)
tempunit = fltarr(nalts)
cp = tempunit
for ialt = 0, nalts - 1 do begin
    totalden(ialt) = data1(4,whichlt,nlats/2.,ialt)+data1(5,whichlt,nlats/2.,ialt)+ $
      data1(6,whichlt,nlats/2.,ialt)
    
    mass(ialt) = (data1(4,whichlt,nlats/2.,ialt)*16 + data1(5,whichlt,nlats/2.,ialt)*32 + $
            data1(6,whichlt,nlats/2.,ialt)*28) / totalden(ialt) * 1.66054886e-27

    cp(ialt) =  1.38065e-23/(2 * mass(ialt))
endfor    

tempunit = mass / 1.38065e-23

chemical = where(vars eq 'ChemicalHeating')
oc = where(vars eq 'OCooling')
noc = where(vars eq 'NOCooling')
euvh = where(vars eq 'EUVHeating')
cond = where(vars eq 'Conduction')
radc = where(vars eq 'RadCooling')
jouleh = where(vars eq 'JouleHeating')


chemheat = data2(chemical,whichlt,nlats/2.,2:nalts-3)  * tempunit(2:nalts-3); $
;  *3600*24. / (cp(2:nalts-3) /86400.)
ocooling = data2(oc,whichlt,nlats/2.,2:nalts-3)        * tempunit(2:nalts-3); $
;  *3600*24. / (cp(2:nalts-3) /86400.)
nocooling = data2(noc,whichlt,nlats/2.,2:nalts-3)      * tempunit(2:nalts-3); $ 
;  *3600*24. / (cp(2:nalts-3) /86400.)
conduction = data2(cond,whichlt,nlats/2.,2:nalts-3)    * tempunit(2:nalts-3); $
;  *3600*24. / (cp(2:nalts-3) /86400.)
radcooling = data2(radc,whichlt,nlats/2.,2:nalts-3) * (-1)  * tempunit(2:nalts-3); $
;  *3600*24. / (cp(2:nalts-3) /86400.)
jouleheat = data2(jouleh,whichlt,nlats/2.,2:nalts-3)   * tempunit(2:nalts-3); $
;  *3600*24. / (cp(2:nalts-3) /86400.)
euvheating = data2(euvh,whichlt,nlats/2.,2:nalts-3)    * tempunit(2:nalts-3); $
;  *3600*24. / (cp(2:nalts-3) /86400.)

altsnew = alts(2:nalts-3)
setdevice, 'plot.ps','p',5,.95

ppp = 2
space = 0.01
pos_space, ppp, space, sizes, ny = ppp

get_position, ppp, space, sizes, 0, pos, /rect
pos(0) = pos(0) + 0.05
pos(2) = pos(2) - 0.05
pos(1) = pos(1) + 0.025
pos(3) = pos(3) - 0.025
xrange = [min([min(chemheat),min(euvheating),min(jouleheat)])$
          ,max([max(chemheat),max(euvheating),max(jouleheat)])]
yrange = [100,800]
plot, xrange,yrange,/nodata,pos = pos, xtitle = 'Heating rate (K/s)', $
  ytitle = 'Altitude (km)', charsize = 1.2, ystyle = 1

oplot, chemheat, altsnew,thick = 3
oplot, euvheating, altsnew, thick = 3, linestyle = 1
oplot, jouleheat, altsnew, thick = 3, linestyle = 2

legend, ['Chemical','EUV','Joule'],linestyle = [0,1,2], pos = [.7,.95],/norm


xrange = [min([min(radcooling),min(conduction)]),max(conduction)]
yrange = [100,800]

get_position, ppp, space, sizes, 1, pos, /rect
pos(0) = pos(0) + 0.05
pos(2) = pos(2) - 0.05
pos(1) = pos(1) + 0.025
pos(3) = pos(3) - 0.025
plot, xrange,yrange,/nodata,pos = pos, xtitle = 'Cooling rate (K/s)', $
  ytitle = 'Altitude (km)', charsize = 1.2, ystyle = 1,/noerase

oplot, conduction, altsnew,thick = 3
oplot, radcooling, altsnew, thick = 3, linestyle = 1

legend, ['Conduction','Radiational'],linestyle = [0,1], pos = [.1,.4],/norm


closedevice


end
