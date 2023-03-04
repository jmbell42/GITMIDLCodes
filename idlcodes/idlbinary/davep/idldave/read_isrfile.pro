PRO read_isrfile,file, data, nVars, Variables, nSatPos, iTimeArray,iError,$
                 nDiffTimes

nlinesheader = 45
nlines = file_lines(file) - nlinesheader
iError = 0

temp = ''
iTA = intarr(6,nlines)
time = intarr(6)
rtime = fltarr(nlines)
close,5

getHeader, file, nv, Variables
nVars = nv - 6
nPosMax = 150

nSatPos = intarr(nLines)
tempdata = fltarr(nvars,nLines)

openr, 5, file

while strtrim(temp,2) ne 'BEGIN' do begin
    readf, 5, temp
endwhile


for iLine = 0, nLines - 1 do begin
    readf, 5, temp
    tarr = strsplit(temp,/extract)
    time = tarr(0:5)
    c_a_to_r,time,rt
    rtime(iLine) = rt
    iTA(*,iLine) = time
    tempdata(*,iLine) = tarr(6:*)
    
endfor
  
i = 0
nSatPos(0) = 1
for iline = 1, nlines - 1 do begin
    if (rtime(iLine) eq rtime(iLine-1)) then begin
        nSatPos(i) = nSatPos(i) + 1
    endif else begin
        i = i + 1
        nSatPos(i) = 1
    endelse

endfor

tp = where(nsatpos ne 0,nDiffTimes)
data = fltarr(nvars,nPosMax,nDiffTimes)
iTimeArray = intarr(6,nDiffTimes)
iLine = 0
for iTime = 0, nDiffTimes - 1 do begin
    for iPos = 0, nSatPos(iTime) - 1 do begin
        data(*,iPos,iTime)  = tempdata(*,iLine)
        iTimeArray(*,iTime) = iTA(*,iLine)
        iLine = iLine + 1
    endfor
endfor

close,5

ialtvar = where(Variables eq 'Altitude') 
data(ialtvar,*,*) = data(ialtvar,*,*)/1000.

end
    
    
    

