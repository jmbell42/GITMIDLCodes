nalts = 50
nwaves = 59

alt = fltarr(nalts)
tau = fltarr(nwaves,nalts)
close, 30
close,31
openr,30,'/Users/dpawlows/SEE/wavelow'
openr,31,'/Users/dpawlows/SEE/wavehigh'
wavelow=fltarr(nwaves)
wavehigh=fltarr(nwaves)
readf,30,wavelow
readf,31,wavehigh
close,30
close,31
waveavg = (wavehigh + wavelow)/2.
unittau = intarr(nwaves)
file = '~/GITM2/run/taufile.dat'
openr, 30,file
t = ''
for ialt = 0, nalts - 1 do begin
    readf, 30, t
    temp = strsplit(t,/extract)
    temp = temp(1:*)
    
    alt(ialt) = float(temp(0))
    npts = n_elements(temp)

    tau(0:npts-2,ialt) = float(temp(1:npts-1))
    if npts le nwaves then begin
        readf,30,t
        temp = strsplit(t,/extract)
        tau(npts-1:nwaves-1,ialt) = float(temp)
    endif
        
endfor
close,30

for iwave = 0, nwaves - 1 do begin
    h = where(tau(iwave,*) - 1 gt 0)
    l = where(tau(iwave,*) - 1 lt 0)

    if n_elements(h) gt 1 then begin
        high = min(tau(iwave,h))
    endif else begin
        if h ge 0 then high = min(tau(iwave,h)) else high = tau(iwave,0) 
    endelse

    if n_elements(l) gt 1 then begin
        low = max(tau(iwave,l)) 
    endif else begin
        if l ge 0 then low = max(tau(iwave,l)) else low = tau(iwave,nalts-1)
    endelse
    
    hi = where(tau(iwave,*) eq high)
    lo = where(tau(iwave,*) eq low)

    unittau(iwave) = alt(hi) - (tau(hi) - 1.)/(tau(hi) - tau(lo))*(alt(hi) -alt(lo))

endfor

ppp = 4
space = 0.01
pos_space, ppp, space, sizes, ny = ppp

get_position, ppp, space, sizes, 3, pos, /rect
setdevice, 'plot.ps','p',5,.95

plot, waveavg, unittau, xtitle = 'Wavelength (A)', ytitle = 'Altitude (km)',$
title = 'Height of unit optical depth vs. wavelength',pos=pos,xrange = [0,700],xstyle = 1, $
  yrange = [100,240], ystyle = 1

closedevice
end


