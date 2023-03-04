PRO mjd2000, d2000, itimearr

mjd = floor(d2000)+51544

mjd2date,mjd,year,month,day

th = d2000 - floor(d2000)
hour = th * 24
tm = hour - floor(hour)
min = tm * 60
ts = min - floor(min)
sec = fix(ts * 60)


itimearr = [floor(year),floor(month),floor(day),floor(hour),floor(min),sec]

end
