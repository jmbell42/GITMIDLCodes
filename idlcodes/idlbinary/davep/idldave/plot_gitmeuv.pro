euvfiles = file_search('euv*')
nfiles = n_elements(euvfiles)

flux = fltarr(nfiles,59)
wave = fltarr(nfiles,59)
for ifile = 0, nfiles - 1 do begin
    openr,1, euvfiles(ifile)
    
    for iwave = 0, 58 do begin

        readf,1,w,f
        wave(ifile,iwave) = w
        flux(ifile,iwave) = f
    endfor
    close,1
endfor

tflux = fltarr(59)
openr,1,'test.txt'
readf,1,tflux
close,1

loadct,39

tflux2 = tflux*wave(0,*)*1.0e-10/(6.626e-34*2.998e8)

plot,wave(0,*),flux(0,*),/ylog,xrange=mm(wave),xstyle=1
for ifile = 1, nfiles - 1 do begin
    oplot,wave(ifile,*),flux(ifile,*),color = 50 * ifile
endfor
;oplot, wave(0,*),tflux2,color = 254

flux2 = flux(0,*) / ((wave(0,*)*1.0e-10)/(6.626e-34*2.998e8))
end
