close,1
openr, 1, 'cond.txt'

nalts = 52
pr = fltarr(nalts)
Kt = fltarr(nalts)
Ke = fltarr(nalts)
rCv = fltarr(nalts)
tU = fltarr(nalts)
T = fltarr(nalts)
P = fltarr(nalts)
alt = fltarr(nalts)
m = fltarr(nalts)
e = fltarr(nalts)
ea = fltarr(nalts)

temp = ' '
for ialt = 0, nalts - 1 do begin
    
    readf, 1, temp
    arr = strsplit(temp,/extract)

    pr(ialt) = arr(0)
    Kt(ialt) = arr(1)
    Ke(ialt) = arr(2)
    rCv(ialt) = arr(3)
    tU(ialt) = arr(4)
    T(ialt) = arr(5)
    P(ialt) = arr(6)
    alt(ialt) = arr(7)
    dt = arr(8)
    m(ialt) = arr(9)
    e(ialt) = arr(10)
    ea(ialt) = -arr(11)

endfor

close,1


;Molecular

mt1 =  deriv(alt,Kt)*deriv(alt,T)
mt2 =  Kt*deriv(alt,deriv(alt,T))
Mole =dt/rCv *(mt1 + mt2)


;Eddy

et1 =  dt/rCv * deriv(alt,pr)*deriv(alt,T)
et2 =  dt/rCv * pr*deriv(alt,deriv(alt,T))
Eddy =  (et1 + et2)


;EddyA
ea1 = -dt/rCv *deriv(alt,Ke)*deriv(alt,P)
ea2 = -dt/rCv * ke*deriv(alt,deriv(alt,P))
Eddya = (ea1+ea2)

loadct, 39
plot, Mole(1:nalts-2),alt/1000.,xrange = [-.005,.005],yrange=[100,140]
oplot,eddy(1:nalts-2),alt/1000.,color = 100
oplot,eddya(1:nalts-2),alt/1000,color = 254
oplot,m(1:nalts-2),alt/1000,color = 0,linestyle = 1
oplot,e(1:nalts-2),alt/1000,color = 100,linestyle = 1
oplot,ea(1:nalts-2),alt/1000,color = 254,linestyle = 1


end
