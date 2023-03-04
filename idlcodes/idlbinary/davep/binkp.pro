FUNCTION season, doy

doy = fix(doy)

if doy lt 34 or doy ge 309 then return, 'Winter'
if doy ge 34 and doy le 125 then return, 'Spring'
if doy ge 126 and doy le 217 then return, 'Summer'
if doy ge 218 and doy lt 309 then return, 'Fall'

;return, s

end

PRO binkp, date, filetype
;if n_elements(date) eq 0 then date = ''
;date = ask('date (yyyy-mm-dd): ',date)

;if n_elements(filetype) eq 0 then filetype = ' '
;filetype = ask('which files to bin: (include wildcards)',filetype)

cyear = strmid(date,0,4)
cmonth = strmid(date,5,2)
cday = strmid(date,8,2)
cdate = strmid(date,2,2)+strmid(date,5,2)+strmid(date,8,2)
gitmdir = '~/ifs1/IPY/'+strmid(date,5,2)+'/iono/data.'+cyear+cmonth+cday+'/'
kpfile = '~/UpperAtmosphere/Indices/KP/'+strmid(date,0,4)+'.dat'


kp = strarr(8)
ktime = [0,3,6,9,12,15,18,21,24]

done = 0
close,/all
openr,1,kpfile

t = ''
while not done do begin
    readf,1,t
    
    temp = strmid(t,0,6)
    if temp eq cdate then done = 1
endwhile
close,1

for itimes = 0, 7 do begin
    kp_t = strmid(t,itimes*2 + 12,2)
    if fix(kp_t) lt 10 then kp_t='07'
    if strmid(kp_t,1,1) eq 0 then kp(itimes) = strmid(kp_t,0,1)
    if strmid(kp_t,1,1) eq 3 then kp(itimes) = strmid(kp_t,0,1)+'+'
    if strmid(kp_t,1,1) eq 7 then kp(itimes) = tostr(fix(strmid(kp_t,0,1))+1)+'-'

endfor

filelist = file_search(gitmdir+filetype+'*t'+strmid(cyear,2,2)+cmonth+cday+'*')
nfiles = n_elements(filelist)
hour = strarr(nfiles)

for ifile = 0, nfiles - 1 do begin
    filename = filelist(ifile)

    if strpos(filename,'header') lt 0 and strpos(filename,'sat') lt 0 then begin
        l = strpos(filename,'/',0,/reverse_offset,/reverse_search)
        file = strmid(filename,l+1)
        
        l1 = strpos(filename,'.bin',0,/reverse_offset,/reverse_search)
        hour(ifile) = fix(strmid(filename,l1-6,2))

        loc = where(hour(ifile) ge ktime(0:7) and hour(ifile) lt ktime(1:8))
        case strtrim(kp(loc),2) of
            '0-': kpbin = 1
            '0' : kpbin = 1
            '0+': kpbin = 1
            '1-': kpbin = 1
            '1' : kpbin = 2
            '1+': kpbin = 2
            '2-': kpbin = 2
            '2' : kpbin = 3
            '2+': kpbin = 3
            '3-': kpbin = 3
            else:  kpbin = 4
            
        endcase 
        c_a_to_r, [fix(cyear),fix(cmonth),fix(cday),0,0,0],rt
        julian = julian_day(rt)
        season = season(julian)
        print, hour(ifile), tostr(kpbin)
        command = 'cp -f '+ filename + ' ' + season +'/0'+tostr(kpbin)+'/ &'
        
        spawn, command

    endif else begin
        openw, 2, 'binkplog.dat',/append
        printf,2, 'Header file found: ',filename
        close,2
    endelse

endfor

end



    
