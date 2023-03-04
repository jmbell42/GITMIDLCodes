if (n_elements(cyear) eq 0) then cyear = '2000'
cyear = ask('year',cyear)

if (n_elements(cmonth) eq 0) then cmonth = '10'
cmonth = string(fix(ask('month',cmonth)), format='(I02)')

if (n_elements(cday) eq 0) then cday = '29'
cday = string(fix(ask('day',cday)), format='(I02)')
cdate = cyear+cmonth+cday

read_radar, cyear, cmonth, cday, eden, position,alts, itimearr,nalts,type

ntimes = n_elements(position(0,*))

outfile = type+cdate+'.dat'
openw,4,outfile

printf,4,''
printf,4,'#START'
for itime = 0, ntimes - 1 do begin
    printf, 4, itimearr(*,itime), 0,position(0,itime),position(1,itime),100.0, format = '(7i5,3f8.2)'
endfor
close, 4
end
