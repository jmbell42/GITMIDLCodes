
; \
; This routine represents a functional improvement over
; the standard, built-in package.
; This version allows for customizable error bar settings.
; /

; x = Alt, ylow = DataLow, yhigh = DataHigh

pro err_plot, x, ylow, yhigh, width=width,$
 _extra = extra_keywords

; \
; Checking arguments
; /

if (n_params() ne 3) then message, $
    'USAGE:  err_plot, x, ylow, yhigh'

if (n_elements(x) eq 0) then message, $
    'Argument x is Undefined'

if (n_elements(ylow) eq 0) then message, $
    'Argument ylow is Undefined'

if (n_elements(yhigh) eq 0) then message, $
    'Argument yhigh is Undefined'

; \
; Checking Keywords
; /

if (n_elements(width) eq 0) then width = 0.02

; \
; Plotting the error bars:
; /

for index = 0L, n_elements(x) - 1L do begin

   ; Plot vertical bars using data coordinates

   xdata = [x[index], x[index]]
   ydata = [ylow[index], yhigh[index]]

   plots, ydata, xdata, /data, noclip=0,$
      _extra=extra_keywords


; Compute horizontal bar width in normal coordinates

normalwidth = (!x.window[1] - !x.window[0])*width

; plot horizontal bar using normal coordinates

lower = convert_coord(ylow[index], x[index], $
       /data, /to_normal)

upper = convert_coord(yhigh[index], x[index], $
       /data, /to_normal)

xdata = [lower[0] - 0.5*width, lower[0] + 0.5*width]

ylower = [lower[1], lower[1]]
yupper = [upper[1], upper[1]]

plots, xdata, ylower, /normal, noclip=0, $
       _extra=extra_keywords

plots, xdata, yupper, /normal, noclip=0, $
       _extra=extra_keywords



endfor



end
