
;;;;;set up altitude bins;;;;;;;
altbins = intarr(12000)
for i = 0, n_elements(altbins)-1 do begin
    altbins(i) = 100 + i*5
endfor

whichISR = 'MH'
whichISR = ask('which ISR (MH,SRI,ACO,EIS): ',whichISR)

case whichISR of
    'MH': begin
        filelist = file_search('[Mm][Hh]*ne.dat')
        ns = 2
    end
    'SRI': begin
        filelist = file_search('SRI*ne.dat') 
        ns = 3
    end
    'ACO': begin
        filelist = file_search('ACO*ne.dat')
        ns = 3
    end
    'EIS': begin
        filelist = file_search('EIS*ne.dat')
        ns = 3
    end
endcase

if filelist(0) eq '' then begin
    print, 'No ',whichISR, ' files found!'
    stop
endif
print, filelist
nfiles = n_elements(filelist)

if n_elements(startday) eq 0 then startday = ''
startday = fix(ask('startday (1-31): ',tostr(startday)))

ndays = fix(ask('Number of days: ',tostr(1)))
ifile = 0
month = fix(strmid(filelist(ifile),ns,2))

tempday = 0
while tempday ne startday do begin
    tempday = fix(strmid(filelist(ifile),ns+2,2))
ifile = ifile + 1
endwhile
ifile = ifile - 1
istartfile = ifile

daysinmonth = d_in_m(month)
if (startday + ndays) gt daysinmonth then begin
    month = month + 1
    if month gt 12 then month = 1
    endday = ndays - (daysinmonth - startday)
endif else begin
    endday = startday + ndays - 1
endelse

tempday = 0

while tempday ne endday do begin
      tempday = fix(strmid(filelist(ifile),ns+2,2))
      ifile = ifile + 1
endwhile
iendfile = ifile - 1

temp = ''
close,1
galts = 0
isFirstTime = 1
ifile = istartfile

while ifile le iendfile do begin
filename = filelist(ifile)
openr, 1, filename
readf, 1, temp
headarr = strsplit(temp,/extract)
numbers1 = strsplit(headarr(0),':',/extract)
if numbers1(1) gt galts then galts = numbers1(1)
close,1

openr, 1, filename
readf, 1, temp
headarr = strsplit(temp,/extract)
numbers1 = strsplit(headarr(0),':',/extract)
numbers2 = strsplit(headarr(1),':',/extract)
n_alts = numbers1(1)
lines = numbers2(1)
    
year = intarr(lines)
month = intarr(lines)
day = intarr(lines)
time = strarr(lines)
azm = strarr(lines)
elv = strarr(lines)
mhtimearr = intarr(7,lines)
alts = fltarr(n_alts,lines)
lons = fltarr(n_alts,lines)
lats = fltarr(n_alts,lines)
nelec = fltarr(n_alts,lines)

    
IsStartFound = 0

while (NOT IsStartFound) do begin
    readf,1, temp
    if temp eq '#START' then IsStartFound = 1
endwhile


for i = 0, lines - 1 do begin
    readf, 1, temp
    dataarr = strsplit(temp,/extract)
    year(i) = fix(dataarr(0))
    month(i) = fix(dataarr(1))
    day(i) = fix(dataarr(2))
    time(i) = dataarr(3)
    azm(i) = dataarr(4)
    elv(i) = dataarr(5)
    alts(*,i) = float(dataarr(6:5+n_alts))
    nelec(*,i) = float(dataarr(6+n_alts:n_elements(dataarr)-1))
endfor

close,1

;;;;;;;Fill itimearray
mhtimearr(0,*) = year
mhtimearr(1,*) = month
mhtimearr(2,*) = day
mhtimearr(6,*) = 0
timesav = time
time = time/10000.
mhtimearr(3,*) = fix(time)

for i = 0, lines - 1 do begin
    time(i) = (time(i)-mhtimearr(3,i))*100
endfor
mhtimearr(4,*) = fix(time)

for i = 0, lines - 1 do begin
    time(i) = (time(i)-mhtimearr(4,i))*100
endfor
mhtimearr(5,*) = fix(time)

if month(0) lt 10 then strmonth = '0'+tostr(month(0)) else strmonth = $
  tostr(month(0))

if day(0) lt 10 then strday = '0'+tostr(day(0)) else strday = $
  tostr(day(0))
;;;;;;;;;

;;;;;Fill lat and lon
mhlat = 42.62
mhlon = 288.51

for i = 0, lines-1 do begin
    for j = 0, n_alts-1 do begin
        lats(j,i) = alts(j,i)*cos(elv(i))*sin(azm(i))/111.36+mhlat
        lons(j,i) = alts(j,i)*cos(elv(i))*cos(azm(i))/111.36+mhlon
    endfor
endfor
;;;;;;

if isFirstTime then begin
    stryear = tostr(year(0))
    outfile = 'ISR.'+whichisr+strmonth+strday+stryear
    openw,2,outfile
    printf,2,'#START'
    isFirstTime = 0
endif 

for i = 0, lines - 1 do begin
    loc = where(alts(*,i) eq alts(*,i) and alts(*,i) ne 0)
    for j = 0, n_elements(loc)-1 do begin
        printf,2,mhtimearr(*,i),lons(loc(j),i),lats(loc(j),i),$
          alts(loc(j),i),format = '(7i4,3(2x,d6.2))'
    endfor
endfor

ifile = ifile + 1
endwhile
close,2
end
