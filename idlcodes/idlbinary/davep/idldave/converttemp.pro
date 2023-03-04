PRO converttemp, data,nlons,nlats,nalts, temperature
K = 1.3807e-23
amu = 1.6726e-27

temp = reform(data(4,*,*,*))
alt = reform(data(2,*,*,*)) / 1000.0
lat = reform(data(1,*,*,*)) / !dtor
lon = reform(data(0,*,*,*)) / !dtor
nspecies = 4

nd = fltarr(nlons,nlats,nalts)
nds = fltarr(nlons,nlats,nalts,nspecies)

;o,o2,n2,n
 iO_  = 0
 iO2_ = 1
 iN2_ = 2
 iN_4S_ =  3
 iN_2D_ =  4
 iN_2P_ =  5
 
Mass = fltarr(6)

Mass(iN_4S_) = 14.0 * AMU
Mass(iO_)    = 16.0 * AMU
Mass(iN_2D_) = Mass(iN_4S_)
Mass(iN_2P_) = Mass(iN_4S_)
Mass(iN2_)   = 2*Mass(iN_4S_)
Mass(iO2_)   = 2*Mass(iO_)

nds(*,*,*,0) = reform(data(5,*,*,*))
nds(*,*,*,1) = reform(data(6,*,*,*))
nds(*,*,*,2) = reform(data(7,*,*,*))
nds(*,*,*,3) = reform(data(9,*,*,*))


for ispecies = 0, 5 do begin
    nd = nd+data(5+ispecies,*,*,*)
endfor

MMM = fltarr(nlons,nlats,nalts)

for ispecies = 0, nspecies - 1 do begin
    MMM = MMM + Mass(ispecies) * nds(*,*,*,ispecies)/nd
endfor 

TempUnit = MMM / K

temperature = temp*TempUnit

end
