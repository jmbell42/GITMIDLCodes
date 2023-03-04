pro calc_energy

wvavg = fltarr(59)

path = '/Users/dpawlows/Gitm/run/davesrc/idealflux'
print, '1)baseline'
print, '2)step'
print, '3)linear'
print, '4)inst-linear'
print, '5)inst-exponential'
pathname = fix(ask('which flux profile: ',tostr(1)))

case pathname of
1   : path = path + '/baseline'
2   : path = path + '/step'
3   : path = path + '/linear'
4   : path = path + '/instant-linear'
5   : path = path + '/instant-exponential'
endcase

case pathname of
1   : dim = 34
2   : dim = 34
3   : dim = 4 * 34
4   : dim = 4 * 34
5   : dim = 6 * 34
endcase

flux = fltarr(65,dim)

close,1
openr, 1, path
readf, 1, flux
close,1

openr, 1, '/Users/dpawlows/Gitm/run/wavedata'
readf, 1, wvavg
close, 1

for N = 6, 64 do begin
flux(N,*) = flux(N,*) * 6.626e-34 * 2.998e8 / (wvavg(N-6) * 1.0e-10)
endfor

i=0
totalflux=fltarr(36)
for j = 0, dim - 1 do begin
    while(flux(2,j) eq 29 and flux(3,j) lt 3) do begin
        totalflux(i) = total(flux(6:64,j))
        i = i + 1
        j = j + 1
    end
endfor
counter = 0
for i = 0, n_elements(totalflux)-1 do begin
    if totalflux(i) ne 0.0 then counter = counter + 1
endfor

eflux = fltarr(counter)

if flux(4,1) - flux(4,0) eq 0 then begin
    dt = 3600 
endif else dt = (flux(4,1) - flux(4,0))*60

for i = 0, counter -1 do begin
    eflux(i) = totalflux(i) * dt
endfor

energyflux = total(eflux) 
print, 'Total integrated enery flux: ',energyflux,' J/m^2'

end
