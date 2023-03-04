close,1 
openr,1,'velocity.txt'
mt = 200000

oldn = fltarr(mt)
newn = fltarr(mt)
dv = fltarr(mt)
dnv = fltarr(mt)
diff = fltarr(mt)
v = fltarr(mt)
dn = fltarr(mt)

i = 0L
t = ' '
while not eof(1) do begin
    readf,1,t
    tarr = strsplit(t,/extract)
    oldn(i)=tarr(1)
    newn(i)=tarr(2)
    dv(i)=tarr(3)
    dnv(i)=tarr(4)
    diff(i)=tarr(5)
    v(i)=tarr(6)
    dn(i)=tarr(7)

    i = i + 1
endwhile
close,1
nt = i - 1 
oldn = oldn(0:nt-1)
newn = newn(0:nt-1)
dv = dv(0:nt-1)
dnv =dnv(0:nt-1)
diff = diff(0:nt-1)
v = v(0:nt-1)
dn = dn(0:nt-1)


openr,1,'../run.100/velocity100.txt'

oldn2 = fltarr(mt)
newn2 = fltarr(mt)
dv2 = fltarr(mt)
dnv2 = fltarr(mt)
diff2 = fltarr(mt)
v2 = fltarr(mt)
dn2 = fltarr(mt)

i = 0L
t = ' '
while not eof(1) do begin
    readf,1,t
    tarr = strsplit(t,/extract)
    oldn2(i)=tarr(1)
    newn2(i)=tarr(2)
    dv2(i)=tarr(3)
    dnv2(i)=tarr(4)
    diff2(i)=tarr(5)
    v2(i)=tarr(6)
    dn2(i)=tarr(7)
    
i = i + 1
endwhile
close,1
nt2 = i - 1 
oldn2 = oldn2(0:nt2-1)
newn2 = newn2(0:nt2-1)
dv2 = dv2(0:nt2-1)
dnv2 =dnv2(0:nt2-1)
diff2 = diff2(0:nt2-1)
v2 = v2(0:nt2-1)
dn2 = dn2(0:nt2-1)


print, "old n: ",mean(oldn), mean(oldn2)
print, "n: ",mean(newn), mean(newn2)
print, "dv: ",mean(dv), mean(dv2)
print, "dnv: ",mean(dnv), mean(dnv2)
print, "diff: ",mean(diff), mean(diff2)
print, "v: ",mean(v), mean(v2)
print, "dn: ",mean(dn), mean(dn2)


end
