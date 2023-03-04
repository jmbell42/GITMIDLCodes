if n_elements(cyear) eq 0 then cyear = '2001'
cyear = ask("which year to search: ",cyear)

dir = '/Users/dpawlows/GOES/'+cyear+'/data/'

filelist = file_search(dir+'A*.TXT')
nfiles = n_elements(filelist)

temp = ' '
nSpecMax = 100
nFlaresMax = 2000
flareSpec = fltarr(nFlaresMax)
nFlares = 0
lastFlareTime = 0
nSequenFlaresMax = 100
sequenFlare = 1
nSequenFlares = 0
SequenTime = fltarr(nSequenFlaresMax)
inSeqFlare = 0

close,/all
for ifile = 0, nfiles - 1 do begin
    openr, 5, filelist(ifile)
    done = 0
    inFlare = 0

    while not done do begin
        readf, 5, temp
        if strpos(temp,'-------') ge 0 then done = 1
    endwhile

    while not eof(5) do begin
        readf, 5, temp
        t = strsplit(temp,/extract)
        
        ;;;;(t_dim = [yymmdd hhmm day xl xs ...])
        xl = t(3)
        if xl ge 2.0e-5 and xl lt 1.0 then inFlare = 1
        
        if inFlare then begin
            if xl lt 2.0e-5 then begin
                inFlare = 0
                lastFlareTime = flareTime
                inSeqFlare = 0
            endif else begin
                nFlares = nFlares + 1
                flareSpec(nFlares) = max([flarespec(nflares),xl])

                cmon = strmid(t(0),2,2)
                cday = strmid(t(0),4,2)
                chour = strmid(t(1),0,2)
                cmin = strmid(t(1),2,2)
                csec = '00'
                iTimeArr = fix([cyear,cmon,cday,chour,cmin,csec])
                c_a_to_r,iTimeArr,rt
                flareTime = rt
                
                if not inSeqFlare then begin
                    if flareTime - lastFlareTime le 6.0 * 3600.0 then begin
                        inSeqFlare = 1
                        sequenFlare = sequenFlare + 1
                        
                        if sequenFlare ge 3 then begin
                            sequenTime(nSequenFlares) = flareTime
                            nSequenFlares = nSequenFlares + 1
                        endif
                    endif else begin
                        sequenFlare = 1
                    endelse
                endif
            endelse
        endif
    endwhile
    close, 5
endfor

for itime = 0, nSequenFlares - 1 do begin
    c_r_to_a,timeArr,sequenTime(itime)
    print, '3 flares at: ',timearr
endfor
end
