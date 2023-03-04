;fac is the factor to multiply 1.0e-4 by to limit the minimum maximum
;magnitude
;to search for.

fac = 1.0
if n_elements(cyear) eq 0 then cyear = '2001'
cyear = ask("which year to search: ",cyear)

dir = '/Users/dpawlows/UpperAtmosphere/GOES/'+cyear+'/data/'

filelist = file_search(dir+'A*.TXT')
nfiles = n_elements(filelist)

temp = ' '
nSpecMax = 100
nFlaresMax = 2000
flareSpec = fltarr(nFlaresMax)
nFlares = 0
FlareTime=fltarr(nflaresmax)
lastFlareTime = fltarr(nflaresmax)
itimearr = intarr(6,nflaresmax)

close,/all
for ifile = 0, nfiles - 1 do begin
    openr, 5, filelist(ifile)
    done = 0
    inFlare = 0

    while not done do begin
        readf, 5, temp
        if strpos(temp,'-------') ge 0 then done = 1
    endwhile
    newflare = 0
    while not eof(5) do begin
        readf, 5, temp
        t = strsplit(temp,/extract)
        
        xl = t(3)
        if xl ge fac*1.0e-4 and xl lt 1.0 then begin
            inFlare = 1
            if xlold lt fac*1.0e-4 then newflare =1 else newflare = 0
;            if nflares eq 13 then stop
        endif

        if inFlare then begin
            if xl lt fac*1.0e-4 then begin
                inFlare = 0
                newflare = 0
                lastFlareTime(nflares) = rt
;                if nflares eq 12 or nflares eq 13 then stop
            endif else begin

                cmon = strmid(t(0),2,2)
                cday = strmid(t(0),4,2)
                chour = strmid(t(1),0,2)
                cmin = strmid(t(1),2,2)
                csec = '00'
                it = fix([cyear,cmon,cday,chour,cmin,csec])
                c_a_to_r,it,rt
;                if cmon eq '06' and cday eq '15' and chour eq '23' and cmin eq '45' then stop
                if newflare then begin
                    nFlares = nFlares + 1
                    itimearr(*,nflares) = it
                    flareTime(nflares) = rt

                endif
 ;                   if nflares eq 12 or nflares eq 13 then stop
                flareSpec(nFlares) = max([flarespec(nflares),xl])               
                
            endelse
        endif
        xlold = xl
        if xlold gt 1.0 then begin
            xlold = -1
        endif
    endwhile
    close, 5
endfor

flarespec = flarespec(1:nflares)
itimearr = itimearr(*,1:nflares)
flaretime = flaretime(1:nflares)
lastflaretime = lastflaretime(1:nflares)

filename  = 'flares'+cyear+'.dat'
openw,1,filename
for iflare = 0, nflares - 1 do begin
    if (flarespec(iflare) gt fac*1.0e-4 and $
      (lastflaretime(iflare)-flaretime(iflare))/60.  gt 30 ) or $
      flarespec(iflare) gt 1.0e-4 then begin
        cdate =  tostr(itimearr(0,iflare))+' '+chopr('0'+tostr(itimearr(1,iflare)),2)+' '+$
          chopr('0'+tostr(itimearr(2,iflare)),2)+' '+$
          chopr('0'+tostr(itimearr(3,iflare)),2)+' '+chopr('0'+tostr(itimearr(4,iflare)),2)$
          +' '+chopr('0'+tostr(itimearr(5,iflare)),2)
        
        
        printf,1, 'Magnitude '+tostrf(flarespec(iflare))+' beginning at '+cdate+$
          ' lasting for '+tostr(((lastflaretime(iflare)-flaretime(iflare))/60.0))+' minutes'
    endif
endfor
close,1
end
