;PRO   ace_array, realtime, winddensity, vectorvelocity

linesmax = 120000
real_time = fltarr(linesmax)
wind_density = fltarr(linesmax)
vector_velocity = fltarr(linesmax)

year=1998
month=2
day=4
eyear = 2010
emonth = 4
eday = 30

istime = [year,month,day,0,0,0]
c_a_to_r,istime,stime
ietime = [eyear,emonth,eday,0,0,0]
c_a_to_r,ietime,etime

count=0
time = stime
while time lt etime do begin
   c_r_to_a,ta,time
   year=ta(0)
   month = ta(1)
   day = ta(2)
   file = '~/ace_data/imf'+tostr(year)+chopr('0'+tostr(month),2)+chopr('0'+tostr(day),2)+'.dat'
   read_ace, file, SWtime, SWdensity, SWvelocity
   real_time[count:count+n_elements(SWtime)-1]=SWtime
   wind_density[count:count+n_elements(SWdensity)-1]=SWdensity
   vector_velocity[count:count+n_elements(SWvelocity)-1]=SWvelocity
   count=count+n_elements(SWtime)
   oneday = 3600.*24
   time = time + oneday
endwhile

realtime = real_time(0:count-1)
winddensity = wind_density(0:count-1)
vectorvelocity = vector_velocity(0:count-1)

end
