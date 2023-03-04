if (n_elements(dirin) eq 0) then dirin = '/Users/dpawlows/SNOE'
dirin = ask('directory for SNOE data',dirin)

if (n_elements(year) eq 0) then year = '2000'
year = ask('year',year)

if (n_elements(month) eq 0) then month = '10'
month = string(fix(ask('month',month)), format='(I02)')

if (n_elements(day) eq 0) then day = '29'
day = string(fix(ask('day',day)), format='(I02)')

read_snoe,  year, month, day, noden, lats, lons, alts, ut, norbits, nlats,julday

fileout = 'snoe'+year+month+day+'.dat'
close,2
openw,2,fileout

printf,2,''
printf,2,'#START'

utold = 0.0
for iorbit = 0, norbits - 1 do begin
    for ilat = 0, nlats - 1 do begin
        if ut(iorbit,ilat) ne -999 and ut(iorbit,ilat) gt utold then begin
            date = date_conv([fix(year),julday(iorbit),0,0,0],'S')
            dy = fix(strmid(date,0,2))
            hour = fix(ut(iorbit,ilat)/3600.)
            min = fix((ut(iorbit,ilat)/3600.-hour)*60.)
            sec =fix(((ut(iorbit,ilat)/3600.-hour)*60.-min)*60) 
            itime = [fix(year),fix(month),dy,hour,min,sec,0]
            utold = ut(iorbit,ilat)
            printf, 2, itime, lons(iorbit,ilat),lats(iorbit,ilat),100.0, format = '(7i5,3f8.2)'
        endif
    endfor
endfor
close,2
end
