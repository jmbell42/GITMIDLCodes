restore,'~/idllocal/spidr_client.sav'

  if n_elements(startdate) eq 0 then startdate = ' '
  if n_elements(enddate) eq 0 then enddate = ' '
  startdate = ask('start date: ',startdate)
  enddate = ask('end date: ',enddate)

  params = ['hmF2','nmF2']
  display,params
  if n_elements(whichpar) eq 0 then whichpar = 0
  whichpar = fix(ask('which param to download: ',tostr(whichpar)))

  case whichpar of
     0: par = 'hmF2'
     1: par = 'foF2'
  endcase


btime = [fix(strmid(startdate,0,4)),fix(strmid(startdate,4,2)),fix(strmid(startdate,6,2)),0,0,0]
ftime = [fix(strmid(enddate,0,4)),fix(strmid(enddate,4,2)),fix(strmid(enddate,6,2)),0,0,0]

spidr_get_ionostation,startdate,enddate,codes,names,coordinates
ncodes = n_elements(codes)
nmax = 10000
value = fltarr(ncodes,nmax)
rtime = dblarr(ncodes,nmax)
ntimes = intarr(ncodes)
nstations = -1
station = strarr(ncodes)
for icode = 0, ncodes-1 do begin
   print, 'Getting data for '+names(icode)+'...'
   data = spidr_get_data(par+'.'+codes(icode),btime,ftime)
   
   if n_tags(data) gt 0 then begin
      locs = where(data.value eq data.value,nlocs)
      if nlocs gt 0 then begin
         nstations = nstations + 1
         station(nstations) = names(icode)
         ntimes(nstations) = nlocs
         value(nstations,0:nlocs-1) = data.value(locs)
         
         for itime = 0, nlocs -1 do begin
            jtime = data.time(locs(itime))
            caldat,jtime,month,day,year
            it = [year,month,day,12,0,0]
            c_a_to_r,it,rt
            addsecs = (jtime-floor(jtime))*24*3600.
            rt = rt + addsecs
            rtime(nstations,0:nlocs-1) = rt

         endfor
      endif
   endif
endfor

ntimemax = max(ntimes)
value = value(0:nstations-1,0:ntimemax-1)
rtime = rtime(0:nstations-1,0:ntimemax-1)
ntimes = ntimes(0:nstations-1)
station = station(0:nstations-1)
stop
if whichpar eq 1 then begin
   value = 1.24e10*(value)^2
endif


end
