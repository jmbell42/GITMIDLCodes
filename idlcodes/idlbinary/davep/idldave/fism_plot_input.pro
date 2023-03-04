
if (n_elements(filein) eq 0) then begin
   filein = findfile('fismflux*.dat')
   filein = filein(0)
endif

filein = ask('file to plot',filein)

fism_read_input, filein, time, data

stime = min(time)
etime = max(time)

plot, (time-stime)/3600.0, data(0,*), ystyle = 1, xstyle = 1
plot, (time-stime)/3600.0, data(58,*), ystyle = 1, xstyle = 1

end
