PRO getheader, file, nVars, Variables

temp = ''

openr, 5, file

while strtrim(temp,2) ne 'NUMERICAL VALUES' do begin
    readf, 5, temp
endwhile

readf, 5, temp
tarr = strsplit(temp,/extract)
nVars = tarr(0)
v = strarr(nVars)
readf,5,temp
tarr = strsplit(temp,/extract)
nAlts = tarr(0)

while strtrim(temp,2) ne 'VARIABLE LIST' do begin
    readf, 5, temp
endwhile

for i = 0, nVars - 1 do begin
    readf, 5, temp
    tarr = strsplit(temp,/extract)
    V(i) = tarr(1)
endfor

Variables = v(6:*)
close, 5
end
