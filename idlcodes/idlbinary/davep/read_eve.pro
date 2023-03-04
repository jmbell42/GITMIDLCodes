PRO read_eve, cdate ;date needs to be in format yyyyddmm

cyear = strmid(cdate,0,4)
cmonth = strmid(cdate,4,2)
cday = strmid(cdate,6,2)

doy = jday(fix(cyear),fix(cmonth),fix(cday))
eve_directory = '~/UpperAtmosphere/EVE/'+cyear+'/'
file = eve_directory+'EVS_L2_'+cyear+chopr('00'+tostr(doy),3)+'_*.fit*'
filelist = file_search(file)

nfiles = n_elements(filelist)
if nfiles ne 24 then begin
   print, 'Warning!  There are not 24 EVE files for this date.  Assuming you are smart and know' 
   print, 'what you are doing and proceeding anyway...'
endif

ntimes = 360*24.
nwavelengths = 5200
data = fltarr(nwavelengths,ntimes)
wavelength = fltarr(nwavelengths)

for ifile = 0, nfiles - 1 do begin
   info = mrdfits(filelist(ifile),1,hdr,/unsigned)
   info_units = mrdfits(filelist(ifile),2,hdr,/unsigned)
   d = mrdfits(filelist(ifile),3,hdr,/unsigned)
   
   if ifile eq 0 then begin
      wavelength = info.wavelength
   endif
   
  data(*,ifile*360:ifile*360+359) = d.irradiance
;  time
   ;data.spectrumunits -> structure containing information on the data
   ;data.spectrum -> structure with the actual data

   

stop
endfor
end


