PRO readmh,filelist,data,mhrtime,galts,datasize

nfiles = n_elements(filelist)
temp = ''
close,1
galts = 0
isfirsttime = 1

for i = 0, nfiles - 1 do begin
    openr, 1, filelist(i)
    readf, 1, temp
    headarr = strsplit(temp,/extract)
    numbers1 = strsplit(headarr(0),':',/extract)
    if numbers1(1) gt galts then galts = numbers1(1)
close,1
end

for j = 0, nfiles - 1 do begin
    openr, 1, filelist(j)
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
    mhtimearr = intarr(6,lines)
    alts = fltarr(n_alts,lines)
    nelec = fltarr(n_alts,lines)
    azm = fltarr(lines)
    elv = fltarr(lines)
    
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
        azm(i) = float(dataarr(4))
        elv(i) = float(dataarr(5))
        alts(*,i) = float(dataarr(6:5+n_alts))
        
        nelec(*,i) = float(dataarr(6+n_alts:n_elements(dataarr)-1))
    endfor
    
    close,1
    
;Fill itimearray
    mhtimearr(0,*) = year
    mhtimearr(1,*) = month
    mhtimearr(2,*) = day
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
    
    d = create_struct('TIME',intarr(6),'ALTS',fltarr(galts),$
         'VAR',fltarr(galts))  
    tempdata = replicate(d,lines)
    for i = 0, lines - 1 do begin
        tempdata(i).TIME = mhtimearr(*,i)
        tempdata(i).ALTS = alts(0:n_alts-1,i)
        tempdata(i).VAR = nelec(0:n_alts-1,i)
    endfor


; temparr = fltarr(galts*2+6,lines)
;  for i = 0, lines - 1 do begin
;      temparr(0:6+n_alts*2-1,i) = [mhtimearr(*,i),alts(*,i),nelec(*,i)]
;  endfor
;  dim1 = lines
; 
;  if n_elements(datanew) eq 0 then begin
;      dim2 = 1
;      datanew = fltarr(galts*2+6,dim1)    
;  endif else begin
;      dim2 = n_elements(datanew(1,*))
;      datanew = fltarr(galts*2+6,dim1+dim2)
;      datanew(*,0:(dim2)-1) = dataarr   
;  endelse
;
;  datanew(*,(dim2)-1:(dim2+dim1)-2) = temparr
;  dataarr = datanew
    
    if isfirsttime then begin
        data = create_struct('TIME',intarr(6),'ALTS',fltarr(galts),'VAR',fltarr(galts))
    isfirsttime = 0
    endif
    data = [data,tempdata]

endfor
data = data(1:*)
datasize = n_elements(data)
mhrtime = fltarr(datasize)
    for i = 0, datasize - 1 do begin
        c_a_to_r, data(i).TIME(0:5),rtime
        mhrtime(i) = rtime
    endfor


end
