pro calc_derpy_conductance, filelist, OutSigma_Pedersen, OutSigma_Hall

;filelist = '3DALL_t970109_094500.bin'
 
read_thermosphere_file, filelist, nvars, nalts, nlats, nlons,vars,data

op_  = 24
o2p_ = 25
n2p_ = 26
nop_ = 28
np_  = 27
e_   = 33

numden = fltarr(nlons, nlats, nalts)
B0     = fltarr(nlons, nlats, nalts)

lat_save = reform(data(1,0,*,0,0))

for i=4,8 do numden = numden + reform(data(i,*,*,*))
mmm = 0.0
mass = [16.0,32.0,28.0,14.0,30.0]
for i=4,8 do mmm = mmm + mass(i-4) * reform(data(i,*,*,*)) / numden

altitude = reform(data( 2,*,*,*))
mmd      = reform(data( 3,*,*,*))
tn       = reform(data(15,*,*,*))
electron = reform(data(33,*,*,*))
te       = reform(data(34,*,*,*))

ec = 1.602e-19
e2 = ec ^ 2
;mi = mmm * 1.6726e-27             ; pretend that mass ions = mass neutrals
mi = mmm * 1.6726e-27             ; pretend that mass ions = mass neutrals
me = 9.1094e-31


;massI = [16.0, 32.0, 28.0, 14.0, 30.0, 32.0, 32.0]

;op_  = 24
;o2p_ = 25
;n2p_ = 26
;np_  = 27
;nop_ = 28
;no2(2d)p_ = 29
;no2(2P)p_ = 30
;e_   = 33

;    mi = fltarr(nlons, nlats, nalts)
;    mi(*,*,*) = 0.0
;
;    ITotal = fltarr(nlons,nlats,nalts)
;    ITotal(*,*,*) = 0.0
; for i = 24, 30 do begin
;    ITotal(*,*,*) = ITotal(*,*,*) + $
;      reform(data(i,*,*,*))
; endfor 
;    
; for i = 24, 30 do begin
;     mi = mi + $
;       massI(i-24) * reform(data(i,*,*,*)) / ITotal(*,*,*)
; endfor 
;
;     mi(*,*,*) = mi(*,*,*)*1.6726e-27


;   for i = 0, nalts -1 do begin
;    print, 'iAlt, mi(iAlt), mmm(iAlt)', $
;               i, $
;               mi(1,1,i), $
;               mmm(1,1,i)
;   endfor 
;
;stop

   
; print, mi(0,0,0:nalts-1)
; print, mmm(0,0,0:nalts-1)
;stop

Vi = 2.6e-15 * (numden + electron)*(mmm^(-0.5))
Ve = 5.4e-16 * (numden)*(TE^0.5)

MeVe = me * ve
MiVi = mi * vi

B0_1d = 31000.0e-9 * (1.0 + 3.0*sin(lat_save)^2)^0.5

for i=0,nlons-1 do for k=0,nalts-1 do B0(i,*,k) = B0_1d

GyroFrequency_Ion = ec*B0/Mi
GyroFrequency_Electron = ec*B0/me

VeOe = Ve^2 + GyroFrequency_Electron^2
ViOi = Vi^2 + GyroFrequency_Ion^2


Sigma_Pedersen = ((1.0/MeVe) * (Ve*Ve/VeOe) + $
                  (1.0/MiVi) * (Vi*Vi/ViOi)) * electron * e2

Sigma_Hall = ((1.0/MeVe) * (Ve*GyroFrequency_Electron/VeOe) - $
              (1.0/MiVi) * (Vi*GyroFrequency_Ion/ViOi)) * electron * e2

Cond_Pedersen = fltarr(nlons,nlats)
Cond_Hall     = fltarr(nlons,nlats)

;for k=2,nalts-3 do begin
;  da = reform(altitude(*,*,k+1) - altitude(*,*,k-1))/2
;  cond_pedersen(*,*) = cond_pedersen(*,*) + da * Sigma_Pedersen(*,*,k)
;  cond_hall(*,*)     = cond_hall(*,*)     + da * Sigma_Hall(*,*,k)
;endfor

for k=1,nalts-1 do begin
  da = reform(altitude(*,*,k) - altitude(*,*,k-1))
  cond_pedersen(*,*) = cond_pedersen(*,*) + da * Sigma_Pedersen(*,*,k)
  cond_hall(*,*)     = cond_hall(*,*)     + da * Sigma_Hall(*,*,k)
endfor

;; fill an extra array with dimensions of data
 
OutSigma_Pedersen = fltarr(nlons, nlats, nalts)
OutSigma_Hall     = fltarr(nlons, nlats, nalts)

for i = 0, nalts - 1 do begin

;  OutSigma_Pedersen(0:nLons-1,0:nLats-1,i) = cond_pedersen(0:nLons-1,0:nLats-1)
  OutSigma_Hall(0:nLons-1,0:nLats-1,i) = cond_hall(0:nLons-1,0:nLats-1)

  OutSigma_Pedersen(0:nLons-1,0:nLats-1,i) = cond_pedersen(0:nLons-1,0:nLats-1) + $
    OutSigma_Hall(0:nLons-1,0:nLats-1,i) 
endfor 
 

;  print, max(sigma_pedersen), min(sigma_pedersen)

end
