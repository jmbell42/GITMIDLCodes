
pro psoff, quiet=quiet

; \
; Check that the PostScript output is active

if (!d.name ne 'PS') then begin
    message, 'POSTSCRIPT output not active:' + $
   'nothing done', /continue
    return 
endif

; \
; Get entry device information from the common block (from pson)

common pson_information, info

if (n_elements(info) eq 0) then begin
   
   message, 'PSON was not called prior to PSOFF: ' + $
       'nothing done', /continue
   return
endif

; \
; Close postscript device

device, /close_file

; \
; Switch to entry graphics device

set_plot, info.device

; \
; Restore window and font

if (info.window ge 0) then wset, info.window
!p.font = info.font

; \
; Report to the User

if (keyword_set(quiet) eq 0) then $
    print, info.filename, $
    format = '("Ended POSTSCRIPT output to ", a )'

end
