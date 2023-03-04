tesfile = file_search('~/UpperAtmosphere/TES/TesOrbitInfo.txt')
if tesfile eq '' then begin
   print, 'Cant find TES orbit file'
   stop
endif

openr,1,tesfile
done = 0
temp = ''
while not done do begin
   readf,1,temp
   if strpos(temp,'#START') ge 0 and strpos(temp,'MarsYear') lt 0 then begin
      done = 1
   endif

endwhile


Tes_Info = fltarr(4,1500)
iline = 0
while not eof(1) do begin
   readf,1,temp
   t = strsplit(temp,/extract)
   Tes_info(0,iline) = fix(strmid(t(0),2,2))
   Tes_info(1,iline) = fix(strmid(t(0),5,3))
   Tes_info(2,iline) = fix(t(1))
   Tes_info(3,iline) = fix(t(2))
   iline = iline + 1
endwhile
close,1
nlines = iline - 1

if n_elements(whichinfo) eq 0 then whichinfo = 0
display,['Orbit Range (given Ls and year)','Ls (given orbit number)']
whichinfo = fix(ask('which info you would like',tostr(whichinfo)))

if whichinfo eq 0 then begin
   if n_elements(inyear) eq 0 then inyear = 24
   inyear = fix(ask('which Mars year',tostr(inyear)))

   if n_elements(inLs) eq 0 then inLs = 0
   inLs = fix(ask('which Ls',tostr(inLs)))

   pos = where(Tes_info(0,*) eq inYear and Tes_info(1,*) eq inLs,count)
   
   orbitstart = min([Tes_info(2,pos(0)),tes_info(2,pos(count-1))])
   orbitend = max([Tes_info(3,pos(0)),Tes_info(3,pos(count-1))])

   print, "The orbits that pertain to that date range are: "+tostr(orbitstart)+" - "+tostr(orbitend)
endif


if whichinfo eq 1 then begin
   if n_elements(orbitnum) eq 0 then orbitnum = 0
   orbitnum = fix(ask('which orbit number',tostr(orbitnum)))

   pos = where(Tes_info(2,*) le orbitnum and Tes_info(3,*) ge orbitnum)
   myear = Tes_info(0,pos(0))
   outLs = Tes_info(1,pos(0))

   print, "MYear: "+tostr(myear)
   print, "Ls: "+tostr(outLs)



endif
end
  
