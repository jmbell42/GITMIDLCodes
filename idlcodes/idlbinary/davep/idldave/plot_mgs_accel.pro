if n_elements(date) eq 0 then date = ' '
date = ask('which date to plot (yyyymmdd): ',date)

cyear = strmid(date,0,4)
cmon = strmid(date,4,2)
cday = strmid(date,6,2)


mgsdir = '~/UpperAtmosphere/MGS/Accel/'
files = file_search(mgsdir+'P*TAB')
nfiles_new = n_elements(files)
if n_elements(nfiles) eq 0 then nfiles = -99
getnewdata = 1
if nfiles_new eq nfiles then begin
   getnewdata = 'n'
   getnewdata = ask('whether to get new data ',getnewdata)
   if strpos( getnewdata,'y') ge 0 then getnewdata = 1 else getnewdata=0
endif
nfiles = nfiles_new

t=' '
foundstart = 0
foundend = 0
close,3
if getnewdata then begin
   for ifile = 0, nfiles - 1 do begin
      openr,3,files(ifile)
      finished = 0
      while not finished do begin
         readf,3,t
         if strpos(t,"START_TIME") ge 0 then begin
            finished = 1
            if not foundstart then begin
               temp = strsplit(t,/extract)
               fileyear = strmid(temp(2),0,4)
               filemonth = strmid(temp(2),5,2)
               fileday = strmid(temp(2),8,2)
               
               if fileyear+filemonth+fileday eq date then begin
                  foundstart = 1
                  ifilestart = ifile
               endif
            endif
            if foundstart and not foundend then begin
               temp = strsplit(t,/extract)
               fileyear = strmid(temp(2),0,4)
               filemonth = strmid(temp(2),5,2)
               fileday = strmid(temp(2),8,2)
               
               readf,3,t
                if fileyear+filemonth+fileday ne date then begin
                  ifileend = ifile - 1
                  foundend = 1
               endif
             endif
         endif
      endwhile
      close, 3
   endfor


filesuse = files(ifilestart:ifileend)
nfilesuse = n_elements(filesuse)

nlinesmax = 1000
density = fltarr(nlinesmax,nfilesuse)
lon = fltarr(nlinesmax,nfilesuse)
lat = fltarr(nlinesmax,nfilesuse)
lst = fltarr(nlinesmax,nfilesuse)
alt = fltarr(nlinesmax,nfilesuse)
time = fltarr(nlinesmax,nfilesuse)
nlines = intarr(nfilesuse)

for ifile = 0, nfilesuse - 1 do begin
   openr,3,filesuse(ifile)
   started = 0
   newfile = 1
   iline = 0
   while not started do begin
      readf,3,t
      if strpos(t,'SOLAR_LONGITUDE') ge 0 then begin
         temp = strsplit(t,/extract)
         Ls = temp(2)
      endif
      if strpos(t,'START_TIME') ge 0 then begin
         temp = strsplit(t,/extract)
         year = fix(strmid(temp(2),0,4))
         month =fix( strmid(temp(2),5,2))
         day =fix( strmid(temp(2),8,2))
         shour = fix(strmid(temp(2),11,2))
         smin =fix( strmid(temp(2),14,2))
         ssec =fix( strmid(temp(2),17,2))
         ta = [year,month,day,shour,smin,ssec]
         c_a_to_r,ta,stime
         
      endif
      if strpos(t,'END') ge 0 and strpos(t,'OBJECT') lt 0 then begin
         readf,3,t
         started = 1

      endif
   endwhile

   while not eof(3) do begin
      readf,3,t
      temp = strsplit(t,/extract)
      if newfile then initialtime = float(temp(0))
      newfile = 0
      if temp(5) ne 0 then begin
         time(iline,ifile) = stime + ( t(0) - initialtime)
         lat(iline,ifile) = float(temp(1))
         lon(iline,ifile) =float( temp(2))
         lst(iline,ifile) = float(temp(3))
         alt(iline,ifile) =float(temp(5))
         density(iline,ifile) = float(temp(6))
         iline = iline + 1
      endif
      
   endwhile
   nlines(ifile) = iline - 1
close,3

   
endfor
endif

nlinesmax = max(nlines)

setdevice,'density_'+date+'.ps','p',5,.95
ppp = 2
space = 0.1
pos_space, ppp, space, sizes, ny = ppp
    
get_position, ppp, space, sizes, 0, pos, /rect
pos(0) = pos(0) + 0.05
pos(2) = pos(2) - 0.05
yrange = mm(density)
colors = get_colors(nfilesuse)
loadct,39
plot,density(0:nlinesmax,0),pos=pos,/nodata,xtitle='Time',ytitle='Density Kg/m!U3!N',title = $
     'MGS Accelerometer Derived Density '+cday+'/'+cmon+'/'+cyear,yrange=yrange
for ifile = 0, nfilesuse - 1 do begin
   oplot,density(0:nlines(ifile),ifile),color=colors(ifile)
endfor

get_position, ppp, space, sizes, 1, pos, /rect
pos(0) = pos(0) + 0.05
pos(2) = pos(2) - 0.05
yrange = mm(alt)
colors = get_colors(nfilesuse)
loadct,39
plot,alt(0:nlinesmax,0),pos=pos,/nodata,xtitle='Time',ytitle='Altitude',title = $
     'MGS Altitude '+cday+'/'+cmon+'/'+cyear,yrange=yrange,/noerase
for ifile = 0, nfilesuse - 1 do begin
   oplot,alt(0:nlines(ifile),ifile),color=colors(ifile)
endfor

closedevice
end
