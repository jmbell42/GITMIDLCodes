if n_elements(file) eq 0 then file = ''
file = ask('file to plot: ',file)

header = 3
head1 = ''
head2 = ''
head3 = ''
temp = ''
nVars = 10
nEmis = 10
Variables = strarr(nVars)
Evars = strarr(nEmis)
nlines = (file_lines(file)-5)/2.
Values = fltarr(nlines,nVars)
Evals = fltarr(nlines,nEmis)
Alts = fltarr(nlines)

openr, 5, file 
readf, 5, head1
readf, 5, head2
readf, 5, head3


date = strmid(head1,strpos(head1,'Date=')+5,5)
UT = strmid(head1,strpos(head1,'UT=')+3,6)
Lat = strmid(head1,strpos(head1,'Lat=')+4,6)
Lon = strmid(head1,strpos(head1,'Lon=')+4,7)
F107 = strmid(head1,strpos(head1,'F107=')+5,4)
F107A = strmid(head1,strpos(head1,'F107A=')+6,4)
AP =  strmid(head1,strpos(head1,'Ap=')+3,4)
SZA = strmid(head2,strpos(head2,'SZA=')+4,6)
LST = strmid(head2,strpos(head2,'LST=')+4,7)
Dip = strmid(head2,strpos(head2,'Dip=')+4,6)
Clat = strmid(head2,strpos(head2,'Clat=')+5,6)
Clon = strmid(head2,strpos(head2,'Clon=')+5,7)
CSZA = strmid(head2,strpos(head2,'CSZA=')+5,6)
Ec = strmid(head2,strpos(head2,'Ec=')+3,9)
Ie = strmid(head2,strpos(head2,'Ie=')+3,1)

Variables = strsplit(head3,/extract)

for iline = 0, nlines - 1 do begin
    readf, 5, temp 
    temparr = strsplit(temp,/extract)
    Alts(iline) = temparr(0)
    for ivar = 0, nVars - 1 do begin
        Values(iline,iVar) = float(temparr(iVar)+1)
    endfor
endfor

readf,5, temp
Evars = strsplit(temp,/extract)

for iline = 0, nlines - 1 do begin
    readf, 5, temp
    temparr = strsplit(temp,/extract)
    for ivar = 0, nEmis - 1 do begin
       Evals(iline,ivar) = float(temparr(ivar)+1)
   endfor
endfor
close,5

for iVar = 1, nVars - 1 do begin
    print, ivar, '  ' , Variables(ivar)
endfor

if n_elements(plotval) eq 0 then plotval = 1
plotval = fix(ask('variable to plot: ',tostr(plotval)))

loadct, 39
setdevice, 'plot.ps', 'p', 5, .95
plot, values(*,plotval),alts, xtitle = variables(plotval), ytitle = $
  'Altitude (km)'

closedevice     

end
