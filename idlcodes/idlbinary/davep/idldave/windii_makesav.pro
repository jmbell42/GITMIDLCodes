;****************************************************************
; WINDII Level 2 V500 CD HDF Data Reading Utility
; Date: December 1996
; Written by Shengpan Zhang
;
; Email: sheng@windop.yorku.ca
; Phone: (416) 736-2100 ext 77730
;
; Solar Terrestrial Physics Laboratory,
; Institute for Space and Terrestrial Science and
; York University
;
; 4700 Keele Street,
; North York, Ontario, Canada
; M3J 1P3
;
; input from scren: 1) filename : file path and name
;                   2) n : the No. of measurements to read, if not given, it
;                          reads the last measurement
;                   3) select : header or data
; output file : herder or data file of one measurement
;
; Modified: April 1997, fixed a bug in the header file. 
;****************************************************************

;****************************************************************
; Procedure VERSION
; Displays current version of WINDII L2FD HDF data files
;****************************************************************

pro version
        print,' '
        print,'     WINDII Level 2 V500 CD HDF Data Reading Utility'
        print,'     Revision: 1.3, Date: 96/12'
        print,'     Written by Shengpan Zhang'
        print,'     Solar Terrestrial Physics Laboratory'
        print,'     Institute for Space and Terrestrial Science and'
        print,'     York University'
        print,' '
end

;****************************************************************
; Procedure usage
; Preset the procedure to read HDF file
;****************************************************************
pro usage
  print,' '
  print,'(1) Run program FILE as :'
  print,' '
  print,"    file,'address+cd_+uday' "
  print,' '
  print,"    Example: file,'sdp:[sdpps.cdhf.dat.hdf_v500]cd_0502'"
  print,' '
  print,'(2) Run program GET_MEAS as : '
  print,' '
  print,"    get_meas,measurement_number,'select',output_struc"
  print,"    'select' can be either 'header' or 'data'" 
  print,' '
  print,"    Example: get_meas,450,'header',h"
  print,' '
end

;*****************************************************************
; Procedure file
; Opens a WINDII FD HDF data file and extract its label and data group
; ralational indexes, and output a header and a data file
;*****************************************************************
pro file,fname,nv
  common hdf_file,mhead,mdata,vname,hname_h,hname_d,nv0,n_z,index

; set file names, header : hname_h, data : hname_d

  hname_h = fname + 'h.hdf'
  hname_d = fname + 'd.hdf'
  hname_h = strupcase(hname_h)
  hname_d = strupcase(hname_d)
  print, 'working on '+hname_h
; open the HDF head file to read, return 0 if it fails

  fd = HDF_OPEN(hname_h,/READ)
  if (fd LE 0) then begin 
    print, 'Failed to open the HDF head file'
    return
  endif

  if fd ne 0 then begin 

; HDF_VD_GETID gets the Vdata reference number 

    vid = HDF_VD_GETID(fd,-1)
    if vid eq -1 then begin 
      print,'Failed to get the reference number'
      return
    endif
    if vid ne -1 then begin 
      vdat = HDF_VD_ATTACH(fd,vid)
      if vdat eq 0 then begin 
        print,'Failed to attatch the HDF head file'
        return
      endif
      if vdat ne 0 then begin 
        HDF_VD_GET,vdat,CLASS=c,COUNT=nv0,NAME=vname,FIELD=fld

; read the head HDF file 

        retn = HDF_VD_READ(vdat,mhead) 
      endif
      HDF_VD_DETACH,vdat
    endif 
  endif

; close the HDF head file

  HDF_CLOSE,fd

; get N_alt and filter for each measurement 

  n_z = lonarr(nv0) 
  index = lonarr(nv0) 
  for i = 0, nv0-1 do begin 
    n_z(i) = mhead(28,i)    ; number of altitudes in each meausment 
    index(i) = mhead(29,i)  ; index for data file location
  endfor 
;****************************************************************************
; Displays current file status of a WINDII HDF data file
;****************************************************************
;        print,' '
;        print,'Current File Status: '
;        print,"     Work files                  : ",hname_h
;        print,"            and                  : ",hname_d
;;        print,"     File label                  : "
;        print,'              ',vname
;        print,"     Total number of measurements: ",nv0
;        print,' '
;****************************************************************
nv = nv0
end

;*****************************************************************
; Procedure fields
; get No. n file, header or data
;*****************************************************************
pro get_meas,n,select,fout
  common hdf_file,mhead,mdata,vname,hname_h,hname_d,nv0,n_z,index

  INT4 = 0L
  REAL4 = 0.0

; head file structure:

     MHEADER ={ID:INT4,              $
               UT:LONARR(2),         $
               LTIME:REAL4,          $
               UTR:LONARR(2),        $
               LTIMER:REAL4,         $
               OBSCAT:INT4,          $
               FWDREV:INT4,          $
               FILGR:INT4,           $
               FILT:INT4,            $
               NBIMA:INT4,           $
               REPT:INT4,            $
               NHB:INT4,             $
               NVB:INT4,             $
               NI:INT4,              $
               NJ:INT4,              $
               NHO:INT4,             $
               NTOP:INT4,            $
               APST:INT4,            $
               EXPTIM:INT4,          $
               LAT:REAL4,            $
               LONG:REAL4,           $
               QUALY:INT4,           $
               QUALYR:INT4,          $
               QUFLAG:INT4,          $
               OTFLAG:INT4,          $
               OEFLAG:INT4,          $
               N_ALT:INT4,           $
               INDEX:INT4            $
              }
        
; get the head file of measuremnt No. n 

    MHEADER.ID      = mhead(0,n-1)
    MHEADER.UT(0)   = mhead(1,n-1)
    MHEADER.UT(1)   = mhead(2,n-1)
    MHEADER.LTIME   = float(mhead(3,n-1)*1.0/1000.0)
    MHEADER.UTR(0)  = mhead(4,n-1)
    MHEADER.UTR(1)  = mhead(5,n-1)
    MHEADER.LTIMER  = float(mhead(6,n-1)*1.0/1000.0)
    MHEADER.OBSCAT  = mhead(7,n-1)
    MHEADER.FWDREV  = mhead(8,n-1)
    MHEADER.FILGR   = mhead(9,n-1)
    MHEADER.FILT    = mhead(10,n-1)
    MHEADER.NBIMA   = mhead(11,n-1)
    MHEADER.REPT    = mhead(12,n-1)
    MHEADER.NHB     = mhead(13,n-1)
    MHEADER.NVB     = mhead(14,n-1)
    MHEADER.NI      = mhead(15,n-1)
    MHEADER.NJ      = mhead(16,n-1)
    MHEADER.NHO     = mhead(17,n-1)
    MHEADER.NTOP    = mhead(18,n-1)
    MHEADER.APST    = mhead(19,n-1)
    MHEADER.EXPTIM  = mhead(20,n-1)
    MHEADER.LAT     = float(mhead(21,n-1)*1.0/1000.0)
    MHEADER.LONG    = float(mhead(22,n-1)*1.0/1000.0)
    MHEADER.QUALY   = mhead(23,n-1)
    MHEADER.QUALYR  = mhead(24,n-1)
    MHEADER.QUFLAG  = mhead(25,n-1)
    MHEADER.OTFLAG  = mhead(26,n-1)
    MHEADER.OEFLAG  = mhead(27,n-1)
    MHEADER.N_ALT   = mhead(28,n-1)
    MHEADER.INDEX   = mhead(29,n-1)
    fhead = mheader           ; for output 
    flt = mheader.filt 

  if select eq 'header' then begin
    fout = fhead
;    print,' '
;    print, string(format= $
;           '("It is a header file of File No.",i4," with 28 fields:")',n)
;    print, ' '
;    print,'     ID:        measurement ID number'
;    print,'     UT(2):     Universal time of measurement (Jday,milliseconds)'
;    print,'     Ltime:     Local time of measurement'
;    print,'     UTR(2):    UT of repeated measurement'
;    print,'     LtimeR:    Local time of repeated measurement'
;    print,'     obscat:    observation catagory'
;    print,'     fwdrev:    forward-reverse flag'
;    print,'     filgr:     filter group'
;    print,'     filt:      filter number'
;    print,'     NBima:     number of images in measurement'
;    print,'     rept:      repeated measurement flag'
;    print,'     Nhb:       number of pixels in horizontal in bin'
;    print,'     Nvb:       number of pixels in vertical in bin'
;    print,'     Ni:        number of rows of bins in window'
;    print,'     Nj:        number of columns of bins in window'
;    print,'     Nho:       number of pixels in horizontal offset'
;    print,'     Ntop:      pixel location of top of window'
;    print,'     apst:      aperture status(0-day, 1-night)'
;    print,'     exptim:    image exposure time in milliseconds'
;    print,'     lat:       latitude of 100 km tangent point'
;    print,'     long:      longitude of 100 km tangent point'
;    print,'     Qualy:     Quality flag for measurement'
;    print,'     QualyR:    Quality flag for repeat'
;    print,'     QuFlag:    Quality flag for overlap'
;    print,'     OtFlag:    Overlap Temperature flag'
;    print,'     OeFlag:    Overlap Emission flag'
;    print,'     N_Alt:     number of altitudes in data profiles'
;    print,'     Index:     location of data record in data file'
;    print,' '
;    print,'Filter number : ',flt,'      N_ALT :',MHEADER.N_ALT
;    print,' '
;    print,'To get header information such as ID, type: print, output_struc.id'
;    print,' '
  endif

  if select eq 'data' then begin

; measurement data structure 

    MDATAS ={SZA:      fltarr(MHEADER.N_ALT),     $
             AVE_Z:    fltarr(MHEADER.N_ALT),     $
             AVE_E:    fltarr(MHEADER.N_ALT),     $
             SIGMA_E:  fltarr(MHEADER.N_ALT),     $
             AVE_T:    fltarr(MHEADER.N_ALT),     $
             SIGMA_T:  fltarr(MHEADER.N_ALT),     $
             ZONAL_W:  fltarr(MHEADER.N_ALT),     $
             SIGMA_ZW: fltarr(MHEADER.N_ALT),     $
             MERID_W:  fltarr(MHEADER.N_ALT),     $
             SIGMA_MW: fltarr(MHEADER.N_ALT)      $
            }

;-----------------------------------------------------
; open the HDF data file to read, return 0 if it fails

    fd = HDF_OPEN(hname_d,/READ)
    if (fd LE 0) then begin 
      print, 'Failed to open the HDF data file'
      return
    endif
   
    if fd ne 0 then begin 

; HDF_VD_GETID gets the Vdata reference number 

      vid = HDF_VD_GETID(fd,-1)
      if vid eq -1 then begin 
        print,'Failed to get the reference number'
        return
      endif
      if vid ne -1 then begin 
        vdat = HDF_VD_ATTACH(fd,vid)
        if vdat eq 0 then begin 
          print,'Failed to attatch the HDF data file'
          return
        endif
        if vdat ne 0 then begin 
          HDF_VD_GET,vdat,CLASS=c,COUNT=nv,NAME=vname0,FIELD=fld

; seek the first line of record no. n by index(n-1) 

          HDF_VD_SEEK,vdat,index(n-1)

; read the data of record no. n and return the number of data (retn) and fdata

          retn = HDF_VD_READ(vdat,fdata,NRECORDS=n_z(n-1))
        endif
        HDF_VD_DETACH,vdat
      endif

; close the HDF data file
      HDF_CLOSE,fd
    endif

    MDATAS.SZA      = fdata(0,*)
    MDATAS.AVE_Z    = fdata(1,*)
    MDATAS.AVE_E    = fdata(2,*)
    MDATAS.SIGMA_E  = fdata(3,*)
    MDATAS.AVE_T    = fdata(4,*)
    MDATAS.SIGMA_T  = fdata(5,*)
    MDATAS.ZONAL_W  = fdata(6,*)
    MDATAS.SIGMA_ZW = fdata(7,*)
    MDATAS.MERID_W  = fdata(8,*)
    MDATAS.SIGMA_MW = fdata(9,*)
    fout = MDATAS

;    print,' '
;    print, string(format= $
; '("It is a data file of File No.",i4," Filter ",i2," with 10 fields:")',n,flt)
;    print,' '
;    print,'      SZA:          Solar Zenith Angle'
;    print,'      AVE_Z:        Altitude in km'
;    print,'      AVE_E:        Colume Emission Rate(Photons cm-3 s-1)'
;    print,'      Sigma_E:      Sigma of Colume Emission Rate'
;    print,'      AVE_T:        Temperature(K)'
;    print,'      Sigma_T:      Sigma of Temperature'
;    print,'      Zonal_W:      Zonal Wind in m/s'
;    print,'      Sigma_ZW:     Sigma of Zonal Wind'
;    print,'      MERID_W:      Meridional Wind in m/s'
;    print,'      Sigma_MW:     Sigma of Meridional Wind'
;    print,' '
;    print,'Filter number : ',flt,'      N_ALT :',MHEADER.N_ALT
;    print,' '
;    print,'To get data information such as emission rate, type :'
;    print,'               print,output_struc.ave_e'
  endif

end
    

filelist = file_search('CD_*D.HDF')
nfiles = n_elements(filelist)
nmax = 200000
altsmax = 500
temp = fltarr(nmax,altsmax)
alts = fltarr(nmax,altsmax)
nalts = fltarr(nmax)
rtime = fltarr(nmax)

;itime = 0L
close,1
openw,1,'WINDII_times_CD.dat'
for ifile = 0, nfiles - 1 do begin
   fn = filelist(ifile)
   len = strpos(fn,'.HDF')-1
   base = strmid(fn,0,len)
   file,base,nmeas

   for imeas = 1, 1  do begin
      get_meas,imeas,'header',header
      get_meas,imeas,'data',data
      
;      nalts(itime) = header.n_alt
;      na = nalts(itime)
      cyear = tostr(header.ut(0))
      fsec = header.ut(1)/1000.0
      year = fix(strmid(cyear,0,2))
      doy = fix(strmid(cyear,2,3))
      if year lt 50 then year = 2000+year else year = 1900 + year
      
      date = fromjday(year,doy)
      hour = fix(fsec/3600.0)
      min = fix((fsec/3600.-hour)*60.)
      sec = fix((((fsec/3600.-hour)*60.) - min)*60.)
      itimearr = [year,date(0),date(1),hour,min,sec]
      
      c_a_to_r,itimearr,rt
      cyear = tostr(itimearr(0))
      cmon = chopr('0'+tostr(itimearr(1)),2)
      cday = chopr('0'+tostr(itimearr(2)),2)
      chour = chopr('0'+tostr(itimearr(3)),2)
      cmin = chopr('0'+tostr(itimearr(4)),2)
      csec = chopr('0'+tostr(itimearr(5)),2)
      cit = [cyear,cmon,cday,chour,cmin,csec]
      ctime = strjoin(cit,' ')

      printf,1,fn+' '+ctime+' '+tostrf(rt)


;      rtime(itime) = rt
;      temp(itime,0:na-1) = data.ave_t
;      alts(itime,0:na-1) = data.ave_z
;itime = itime + 1

   endfor
endfor
      close,1


end
