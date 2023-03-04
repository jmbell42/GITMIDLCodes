;PRO   ace_velocity

n = 3
v0_50 = 0
v50_100 = 0
v100_150 = 0
v150_200 = 0
v200_250 = 0
v250_300 = 0
v300_350 = 0
v350_400 = 0
v400_450 = 0
v450_500 = 0
v500_550 = 0
v550_600 = 0
v600_650 = 0
v650_700 = 0
v700_750 = 0
v750_800 = 0
v800_850 = 0
v850_900 = 0
v900_950 = 0
v950_1000 = 0
gt1000 = 0

while n lt n_elements(vectorvelocity) do begin
   a = mean(vectorvelocity(n-3:n+3))
   if a ge 300 and a lt 350 then begin
      diff = realtime - realtime(n)
      minval = min(abs(diff-2332800),imin)
      a27 = mean(vectorvelocity(imin-3:imin+3))
      if a27 ge 0 and a27 lt 50 then v0_50=v0_50+1
      if a27 ge 50 and a27 lt 100 then v50_100=v50_100+1
      if a27 ge 100 and a27 lt 150 then v100_150=v100_150+1
      if a27 ge 150 and a27 lt 200 then v150_200=v150_200+1
      if a27 ge 200 and a27 lt 250 then v200_250=v200_250+1
      if a27 ge 250 and a27 lt 300 then v250_300=v250_300+1
      if a27 ge 300 and a27 lt 350 then v300_350=v300_350+1
      if a27 ge 350 and a27 lt 400 then v350_400=v350_400+1
      if a27 ge 400 and a27 lt 450 then v400_450=v400_450+1
      if a27 ge 450 and a27 lt 500 then v450_500=v450_500+1
      if a27 ge 500 and a27 lt 550 then v500_550=v500_550+1
      if a27 ge 550 and a27 lt 600 then v550_600=v550_600+1
      if a27 ge 600 and a27 lt 650 then v600_650=v600_650+1
      if a27 ge 650 and a27 lt 700 then v650_700=v650_700+1
      if a27 ge 700 and a27 lt 750 then v700_750=v700_750+1
      if a27 ge 750 and a27 lt 800 then v750_800=v750_800+1
      if a27 ge 800 and a27 lt 850 then v800_850=v800_850+1
      if a27 ge 850 and a27 lt 900 then v850_900=v850_900+1
      if a27 ge 900 and a27 lt 950 then v900_950=v900_950+1
      if a27 ge 950 and a27 lt 1000 then v950_1000=v950_1000+1
      if a27 ge 1000 then gt1000=gt1000+1
   endif
   n=n+1
endwhile
end
