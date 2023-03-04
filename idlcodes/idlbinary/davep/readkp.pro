pro readkp,year,kp,rtime
file = '~/UpperAtmosphere/Indices/Kp/'+tostr(year)+'.dat'

nlines = file_lines(file)
itimearr = intarr(6,nlines*8)
rtime = dblarr(nlines*8)
kp = fltarr(nlines*8)
temp = ''

close,5
openr,5,file
il = 0
for iline = 0, nlines-1 do begin
    readf,5,temp

    ttemp = fix(strmid(temp,0,2))
     if ttemp gt 50 then ttemp = 1900 + ttemp else ttemp = 2000 + ttemp
    
        itimearr(0,il:il+7) =ttemp
        itimearr(1,il:il+7) = fix(strmid(temp,2,2))
        itimearr(2,il:il+7) = fix(strmid(temp,4,2))

       for i = 0, 7 do begin
           
           itimearr(3,il) = i*3
           
           if i eq 0 then val = strmid(temp,12,2)
           if i eq 1 then val = strmid(temp,14,2)
           if i eq 2 then val = strmid(temp,16,2)
           if i eq 3 then val = strmid(temp,18,2)
           if i eq 4 then val = strmid(temp,20,2)
           if i eq 5 then val = strmid(temp,22,2)
           if i eq 6 then val = strmid(temp,24,2)
           if i eq 7 then val = strmid(temp,26,2)

           if strmid(val,0,1) eq ' ' then val = '0'+strmid(val,1,1)

           case strmid(val,1) of
               '3': value = fix(strmid(val,0,1))+.3
               '7': value = fix(strmid(val,0,1))+.7
               '0': value = fix(strmid(val,0,1))
           endcase

           kp(il) = value
           c_a_to_r,itimearr(*,il),rt

           rtime(il) = rt
           il = il + 1
    endfor
    

  
endfor

close,5


end
