PRO makeflux

timesteps = 35
iYear = 2003
iMonth = 10
iDay = 28
iHour = 00
iMinute = 00
iSecond = 00

iTimeArray = [iYear, iMonth, iDay, iHour, iMinute, iSecond]

baseline = fltarr(59)
flare = fltarr(59)

close,1
openr,1,'/home/dpawlows/Gitm/run/fluxfromGitm/d280311'
readf,1,baseline
close,1
openr,1,'/home/dpawlows/Gitm/run/fluxfromGitm/d292118'
readf,1,flare
close,1

fluxdiff = (flare - baseline)/6.
fluxdifflin = (flare - baseline)/12.
fluxdiffexp = (flare - baseline)

openw,1,'/home/dpawlows/Gitm/run/davesrc/idealflux/baseline'
for i = 0, timesteps - 1 do begin
    printf,1,iTimeArray, baseline
       iTimeArray(3) = iTimeArray(3)+ 1
    if iTimeArray(3) eq 24 then begin
        iTimeArray(3) = 00
        iTimeArray(2) = iTimeArray(2) + 1
    endif
endfor
close,1


iTimeArray = [iYear, iMonth, iDay, iHour, iMinute, iSecond]
openw,1,'/home/dpawlows/Gitm/run/davesrc/idealflux/step'
for i = 0, timesteps - 1 do begin
  if iTimeArray(2) eq iDay + 1 and iTimeArray(3) le 3 then begin
      printf, 1, iTimeArray, flare
      iTimeArray(3) = iTimeArray(3) + 1
      
  endif else begin
      printf, 1, iTimeArray, baseline
      iTimeArray(3) = iTimeArray(3)+ 1
      if iTimeArray(3) eq 24 then begin
          iTimeArray(3) = 00
          iTimeArray(2) = iTimeArray(2) + 1
      endif
  endelse
endfor
close,1

iTimeArray = [iYear, iMonth, iDay, iHour, iMinute, iSecond]
openw,1,'/home/dpawlows/Gitm/run/davesrc/idealflux/linear'

for i = 0, (timesteps * 4) - 1 do begin
   if iTimeArray(2) eq iDay + 1 and iTimeArray(3) le 1 then begin
        if iTimeArray(3) eq 0 then begin
            for j = 1, 4 do begin
                printf, 1, iTimeArray, baseline + (fluxdiff * j)
                iTimeArray(4) = iTimeArray(4) + (15)
                if iTimeArray(4) eq 60 then begin
                    iTimeArray(4) = 0
                    iTimeArray(3) = iTimeArray(3) + 1
                endif
            endfor
        endif
        if iTimeArray(3) eq 1 then begin
            for j = 1, 2 do begin
                printf, 1, iTimeArray, baseline + (fluxdiff * (4 + j))
                iTimeArray(4) = iTimeArray(4) + (15)
            endfor
            for j = 3, 4 do begin
                printf, 1, iTimeArray, baseline  + (fluxdiff * (8 - j ))
                iTimeArray(4) = iTimeArray(4) + (15)
                if iTimeArray(4) eq 60 then begin
                     iTimeArray(4) = 0
                    iTimeArray(3) = iTimeArray(3) + 1
                endif 
            endfor
        endif
    endif

    if iTimeArray(2) eq iDay + 1 and iTimeArray(3) eq 2 then begin
        for j = 1 , 4 do begin
            printf, 1, iTimeArray, baseline + (fluxdiff * (4 - j))
            iTimeArray(4) = iTimeArray(4) + (15)
            if iTimeArray(4) eq 60 then begin
                iTimeArray(4) = 0
                iTimeArray(3) = iTimeArray(3) + 1
            endif
        endfor
    endif else begin
        printf, 1, iTimeArray, baseline
        iTimeArray(4) = iTimeArray(4) + 15
        if iTimeArray(4) eq 60 then begin
            iTimeArray(4) = 0
            iTimeArray(3) = iTimeArray(3) + 1
        endif
        if iTimeArray(3) eq 24 then begin
            iTimeArray(3) = 00
            iTimeArray(2) = iTimeArray(2) + 1
        endif
    endelse
endfor
close,1

iTimeArray = [iYear, iMonth, iDay, iHour, iMinute, iSecond]
openw,1,'/home/dpawlows/Gitm/run/davesrc/idealflux/instant-linear'
for i = 0, (timesteps * 4) - 1 do begin
  if iTimeArray(2) eq iDay + 1 and iTimeArray(3) le 1 then begin
      if iTimeArray(3) eq 0 then begin
          if iTimeArray(4) eq 0 then begin
              printf, 1, iTimeArray, flare
              iTimeArray(4) = iTimeArray(4) + 15
          endif else begin
              for j = 1, 11 do begin
                  printf ,1, iTimeArray,  baseline + (fluxdifflin * (12 - j))
                  iTimeArray(4) = iTimeArray(4) + 15
                  if iTimeArray(4) eq 60 then begin
                      iTimeArray(4) = 0
                      iTimeArray(3) = iTimeArray(3) + 1
                  endif
              endfor
             ; for j =1,3 do begin
             ;     printf, 1, iTimeArray, baseline
             ;      iTimeArray(4) = iTimeArray(4) + 15
             ;     if iTimeArray(4) eq 60 then begin
             ;         iTimeArray(4) = 0
             ;         iTimeArray(3) = iTimeArray(3) + 1
             ;     endif
             ; endfor
          endelse
      endif
  endif else begin
      printf, 1, iTimeArray, baseline
      iTimeArray(4) = iTimeArray(4) + 15
      if iTimeArray(4) eq 60 then begin
          iTimeArray(4) = 0
          iTimeArray(3) = iTimeArray(3) + 1
      endif
      if iTimeArray(3) eq 24 then begin
          iTimeArray(3) = 00
          iTimeArray(2) = iTimeArray(2) + 1
      endif
  endelse
endfor
close,1

iTimeArray = [iYear, iMonth, iDay, iHour, iMinute, iSecond]
openw,1,'/home/dpawlows/Gitm/run/davesrc/idealflux/instant-exponential'
for i = 0, (timesteps * 6) - 1 do begin
  if iTimeArray(2) eq iDay + 1 and iTimeArray(3) le 1 then begin
      if iTimeArray(3) eq 0 then begin
          if iTimeArray(4) eq 0 then begin
              printf, 1, iTimeArray, flare
              iTimeArray(4) = iTimeArray(4) + 10
          endif else begin
              for j = 1, 17 do begin
                  printf ,1, iTimeArray,  baseline + (fluxdiffexp * exp(-j))
                  iTimeArray(4) = iTimeArray(4) + 10
                  if iTimeArray(4) eq 60 then begin
                      iTimeArray(4) = 0
                      iTimeArray(3) = iTimeArray(3) + 1
                  endif
              endfor
          endelse
      endif
  endif else begin
      printf, 1, iTimeArray, baseline
      iTimeArray(4) = iTimeArray(4) + 10
      if iTimeArray(4) eq 60 then begin
          iTimeArray(4) = 0
          iTimeArray(3) = iTimeArray(3) + 1
      endif
      if iTimeArray(3) eq 24 then begin
          iTimeArray(3) = 00
          iTimeArray(2) = iTimeArray(2) + 1
      endif
  endelse
endfor

close,1

stop
end

