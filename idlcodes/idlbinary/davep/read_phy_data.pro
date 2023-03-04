nlinesmax = 1000

files = file_search('*.csv')
if n_elements(ifile) eq 0 then ifile = 0
display, files
ifile = fix(ask('which file to process: ',tostr(ifile)))

openr, 1, files(ifile)
temp = ''
readf,1,temp
t = strsplit(temp,',',/extract)

nvars = n_elements(t)

vars = t
data = strarr(nvars,nlinesmax)
iline = 0
while not eof(1) do begin
   readf,1,temp
   t = strsplit(temp,',',/extract,/preserve_null)
   for ivar = 0, nvars - 1 do begin
      data(ivar,iline) = t(ivar)
   endfor
   iline = iline + 1
endwhile
close,1
nlines = iline
data = data(*,0:nlines-1)

majorvar = where(vars eq 'MAJOR1')
collegevar = where(vars eq 'COLLEGE')

major = []
majornumbers = intarr(nlines)
college =[]
collegenumbers = intarr(nlines)
nmajors = 0
ncolleges = 0
for  iline = 0, nlines - 1 do begin
   thismajor = reform(data(majorvar,iline))
   thismajor = getmajor(thismajor)
      
   loc = where(major eq thismajor(0), count)

   if count eq 0 then begin
      major = [major,thismajor]
      nmajors = nmajors + 1
      loc = nmajors - 1
   endif
   majornumbers(loc) = majornumbers(loc) + 1
     
   thiscollege = reform(data(collegevar,iline))
   loc = where(college eq thiscollege(0), count)
   if count eq 0 then begin
      college = [college,thiscollege]
      ncolleges = ncolleges + 1
   endif
   collegenumbers(loc) = collegenumbers(loc) + 1

endfor

majornumbers = majornumbers(0:nmajors-1)
collegenumbers = collegenumbers(0:ncolleges-1)


sorted = reverse(sort(majornumbers))
major = major(sorted)
majornumbers = majornumbers(sorted)
totalmajors = total(majornumbers)
majorpercent = majornumbers/totalmajors * 100.

sorted = reverse(sort(collegenumbers))
college = college(sorted)
collegenumbers = collegenumbers(sorted)
totalcolleges = total(collegenumbers)
collegepercent = collegenumbers/totalcolleges * 100.

openw,1, 'data.dat'
printf, 1,'Sorted data'
printf,1,'Rank','Major','Count','Percent',format='(A10,A30,A10,A10)'
for i =0, 6 do begin
   printf,1,i+1,major(i),majornumbers(i),majorpercent(i),format='(A10,A30,I10,F9.1)'
endfor
close,1


end
