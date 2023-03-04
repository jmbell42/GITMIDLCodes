PRO spidr_get_ionostation, startdate,enddate,code,name,coordinates

;Looks up ionospheric data stations that reside in the spidr VO and
;returns stations that are available and their coordinates.
;
;startdate and enddate should be inform yyyymmdd


stationfile = file_search('~/UpperAtmosphere/SPIDR/ionostations.dat')
close,55
openr,55,stationfile
done = 0
temp = ' '


nmax = 1000
code = strarr(nmax)
name = strarr(nmax)
coordinates = fltarr(2,nmax)
startdate = tostr(startdate)
enddate = tostr(enddate)

btime = [fix(strmid(startdate,0,4)),fix(strmid(startdate,4,2)),fix(strmid(startdate,6,2)),0,0,0]
ftime = [fix(strmid(enddate,0,4)),fix(strmid(enddate,4,2)),fix(strmid(enddate,6,2)),0,0,0]
c_a_to_r,btime,st
c_a_to_r,ftime,et
while not done do begin
   readf,55,temp
   if strmid(temp,0,1) eq '#' then done = 1
endwhile


icode = 0
while not eof(55) do begin
   readf,55,temp   
   t = strsplit(temp,/extract)
   code(icode) = t(1)
   name(icode) = t(2)
   
   done = 0
   i = 0
   while not done do begin
      if strpos(t(i),'(') ge 0 and strpos(t(i),')') ge 0 then done = 1 else i = i + 1
   endwhile
   ilatpos = i + 1
   
   coordinates(*,icode) = float(t(ilatpos:ilatpos+1))
   
   sdate = t(ilatpos+2)
   edate = t(ilatpos+4)
   
   sitime = [fix(strmid(sdate,0,4)),fix(strmid(sdate,5,2)),fix(strmid(sdate,8,2)),0,0,0]
   eitime = [fix(strmid(edate,0,4)),fix(strmid(edate,5,2)),fix(strmid(edate,8,2)),0,0,0]
   c_a_to_r,sitime,stime
   c_a_to_r,eitime,etime
   
   if st ge stime and et lt etime then icode = icode + 1

endwhile

ncodes = icode
code = code(0:icode-1)
name = name(0:icode-1)
coordinates = coordinates(*,0:icode-1)





end
