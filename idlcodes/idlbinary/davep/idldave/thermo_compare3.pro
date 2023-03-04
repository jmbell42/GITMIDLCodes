
if n_elements(filelist1) eq 0 then filelist1 = ' '
filelist1 = ask('DA filename to plot',filelist1)
if n_elements(filelist2) eq 0 then filelist2 = ' '
filelist2 = ask('NODA filename to plot',filelist2)

if n_elements(filelist_base) eq 0 then filelist_base = ' '
filelist_base = ask('baseline filename to plot',filelist_base)

nfiles = 1
read_thermosphere_file, filelist1, nvars1, nalts1, nlats1, nlons1, $
                        vars1, data1, rb1, cb1, bl_cnt1
read_thermosphere_file, filelist2, nvars2, nalts2, nlats2, nlons2, $
                        vars2, data2, rb2, cb2, bl_cnt2

read_thermosphere_file, filelist_base, nvars_base, $
  nalts_base, nlats_base, nlons_base, vars_base, data_base, $
  rb_base, cb_base, bl_cnt_base



filename = filelist1(0)

alt = reform(data1(2,*,*,*)) / 1000.0
lat = reform(data1(1,*,*,*)) / !dtor
lon = reform(data1(0,*,*,*)) / !dtor

 if (strpos(filename,"save") gt 0) then begin
                
         fn = findfile(filename)
         if (strlen(fn(0)) eq 0) then begin
             print, "Bad filename : ", filename
             stop
         endif else filename = fn(0)
         
         l1 = strpos(filename,'.save')
         fn2 = strmid(filename,0,l1)
         len = strlen(fn2)
         l2 = l1-1
         while (strpos(strmid(fn2,l2,len),'.') eq -1) do l2 = l2 - 1
         l = l2 - 13
         year = fix(strmid(filename,l, 2))
         mont = fix(strmid(filename,l+2, 2))
         day  = fix(strmid(filename,l+4, 2))
         hour = float(strmid(filename, l+7, 2))
         minu = float(strmid(filename,l+9, 2))
         seco = float(strmid(filename,l+11, 2))
     endif else begin
        l1 = strpos(filename,'.bin')
        l2 = 13
        l = l1 - l2
         year = fix(strmid(filename,l, 2))
         mont = fix(strmid(filename,l+2, 2))
         day  = fix(strmid(filename,l+4, 2))
         hour = float(strmid(filename,l+7, 2))
         minu = float(strmid(filename,l+9, 2))
         seco = float(strmid(filename,l+11, 2))
     endelse
     
     if year lt 50 then iyear = year + 2000 else iyear = year + 1900
     stryear = strtrim(string(iyear),2)
     strmth = strtrim(string(mont),2)
     strday = strtrim(string(day),2)
     uttime = hour+minu/60.+seco/60./60.
    
     strdate = stryear+'-'+strmth+'-'+strday
     strdate = strdate(0)
     
shift = 0
if shift then begin
    print, 'WARNING ------ SHIFTING LATITUDES!!!!!!!!!'
    tempdata = data
    for ilon = 2, nlons - 6 do begin
        tempdata(3:*,ilon,*,*) = data_base(3:*,ilon+3,*,*)
    endfor
        tempdata(3:*,nlons-5,*,*) = data_base(3:*,2,*,*)
        tempdata(3:*,nlons-4,*,*) = data_base(3:*,3,*,*)
        tempdata(3:*,nlons-3,*,*) = data_base(3:*,4,*,*)

        data_base(3:*,*,*,*) = tempdata(3:*,*,*,*)
    endif

for i=0,nvars1-1 do print, tostr(i)+'. '+vars1(i)
print, tostr(nvars1)+'. '+'TEC'
if n_elements(sel) eq 0 then sel = 3
sel = fix(ask('which var to plot',tostr(sel)))

if sel eq nvars1 then istec = 1 else istec = 0

if not istec then begin
    if n_elements(plotlogs) eq 0 then plotlogs = 'n'
    plotlogs = ask('whether you want log or not (y/n)',plotlogs)
    if (strpos(plotlogs,'y') eq 0) then plotlog = 1 else plotlog = 0
endif else begin
    plotlog = 0
endelse

if n_elements(psfile) eq 0 then psfile = 'plot.ps'
psfile = ask('ps file name',psfile)

if not istec then begin
    for i=0,nalts1-1 do print, tostr(i)+'. '+string(alt(2,2,i))
    if n_elements(selset) eq 0 then selset = 0
    selset = fix(ask('which altitude to plot',tostr(selset)))
endif else begin
    selset = 0
endelse

if n_elements(sminis) eq 0 then sminis = 0.0
if n_elements(smaxis) eq 0 then smaxis = 0.0
sminis = float(ask('minimum (0.0 for automatic)',tostrf(sminis)))
smaxis = float(ask('maximum (0.0 for automatic)',tostrf(smaxis)))

smini = sminis
smaxi = smaxis
if n_elements(pv) eq 0 then pv = 'n'
pv = ask('whether you want vectors or not (y/n)',pv)
if strpos(pv,'y') eq 0 then plotvector=1 else plotvector = 0

if (plotvector) then begin
  print,'-1  : automatic selection'
  factors = [1.0, 5.0, 10.0, 20.0, 25.0, $
             50.0, 75.0, 100.0, 150.0, 200.0]
  nfacs = n_elements(factors)
  for i=0,nfacs-1 do print, tostr(i)+'. '+string(factors(i)*10.0)
  if n_elements(vector_factor) eq 0 then vector_factor = -1
  vector_factor = fix(ask('velocity factor',tostr(vector_factor)))
endif else vector_factor = 0

; cursor position variables, which don't matter at this point
cursor_x = 0.0
cursor_y = 0.0
strx = '0.0'
stry = '0.0'

;cnt1 is a lat/lon plot
cnt1 = 1

;cnt2 is a lat/alt plot
cnt2 = 0

;cnt3 is a lon/alt plot
cnt3 = 0

; yes is whether ghostcells are plotted or not:
yes = 0
no  = 1

; yeslog is whether variable should be logged or not:
if (plotlog) then begin 
  yeslog = 1
  nolog  = 0
endif else begin
  yeslog = 0
  nolog = 1
endelse

; yeswrite_cnt is whether we have to output to a ps file or not.
yeswrite_cnt = 1

; polar is variable to say whether we have polar plots or not

if cnt1 eq 1 then begin
    polar = 0
    ortho = 0
    if n_elements(poro) eq 0 then poro = 0 
    poro = fix(ask("if polar or ortho (0,1,2): ",tostr(poro)))
    
    if poro eq 2 then begin
        polar = 0
        ortho = 1
        
        if n_elements(tlat) eq 0 then tlat = 0
        if n_elements(tlon) eq 0 then tlon = 0
        tlat = float(ask('ortho center latitude (0.0 for subsolar): ',$
                         tostrf(tlat)))
        tlon = float(ask('ortho center longitude (0.0 for subsolar): ',$
                         tostrf(tlon)))
        
    endif else begin
        if poro eq 1 then polar = 1
    endelse
endif

if ortho eq 1 then begin
    if tlat eq 0.0 and tlon eq 0.0 then begin
    
    zsun,strdate,uttime ,0,0,zenith,azimuth,solfac,$
      lonsun=lonsun,latsun=latsun
    
    plat = latsun
    plon = lonsun

    if plon lt 0.0 then plon = 360.0 - abs(plon)   
;    if plon lt 180.0 then plon = plon + 180.0 else plon = plon - 180.0
    
    print, 'Coordinates: ',plon ,' Long. ',plat,' Lat.'
endif else begin
    
    plat = tlat
    plon = tlon
    
endelse
endif


; npolar is whether we are doing the northern or southern hemisphere
npolar = 1

; MinLat is for polar plots:
MinLat = 40.0

; showgridyes says whether to plot the grid or not.
showgridyes = 0

;plotvectoryes says whether to plot vectors or not
plotvectoryes = plotvector

; plot vector difference or not
plotvecdiff = 0

; number of points to skip when plotting vectors:
step = 2

; vi_cnt is whether to plot vectors of Vi
vi_cnt = 0

; vn_cnt is whether to plot vectors of Vn
vn_cnt = 1


cursor_cnt = 0

xrange = [0.0,0.0]

yrange = [0.0,0.0]

data_sub = fltarr(nvars1+1,nlons1,nlats1,nalts1)

iviu = where(vars1 eq 'V!Di!N(up)')
ivnu = where(vars1 eq 'V!Dn!N(up)')

alts = reform(data1(2,0,0,*))/1000.0
dalt = fltarr(nalts1-4)
if istec then begin
    tec1 = fltarr(nlons1,nlats1)
    tec2 = fltarr(nlons1,nlats1)
    tec_base = fltarr(nlons1,nlats1)
endif

for ialt = 2,nalts1 - 3 do begin
    dalt(ialt-2) = ((alts(ialt+1)+alts(ialt))/2.- $
                    (alts(ialt)+alts(ialt-1))/2.)
endfor

for ilon = 0,nlons1 - 1 do begin
    for ilat = 0, nlats1 - 1 do begin
       ;1)
        if istec then begin
            TEC1(ilon,ilat) = total(data1(19,ilon,ilat,2:nalts1-3)*dalt*1000.0)
            TEC2(ilon,ilat) = total(data2(19,ilon,ilat,2:nalts1-3)*dalt*1000.0)
            TEC_base(ilon,ilat) = total(data_base(19,ilon,ilat,2:nalts1-3)*dalt*1000.0)
            data_sub(sel,ilon,ilat,selset) = (abs(TEC2(ilon,ilat)-TEC_base(ilon,ilat)) / $
                                              TEC_base(ilon,ilat)) - $
                                                 (abs(TEC1(ilon,ilat)-TEC_base(ilon,ilat)) / $
                                                 TEC_base(ilon,ilat))
        endif else begin
            data_sub(sel,ilon,ilat,selset) = $
              (abs(data2(sel,ilon,ilat,selset)-data_base(sel,ilon,ilat,selset)) / $
               data_base(sel,ilon,ilat,selset)) - $
              (abs(data1(sel,ilon,ilat,selset)-data_base(sel,ilon,ilat,selset)) / $
               data_base(sel,ilon,ilat,selset))
        endelse

       ; if data1(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset) lt 1.0 and $
       ;   data2(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset) lt 1.0 and $
       ;   data1(sel,ilon,ilat,selset) lt data2(sel,ilon,ilat,selset) then $
       ;   data_sub(sel,ilon,ilat,selset) = $
       ;   (data1(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset) - $
       ;                        data2(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset))/ $
       ;   (data1(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset))
       ;   
       ; ;2)
       ; if data1(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset) lt 1.0 and $
       ;   data2(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset) lt 1.0 and $
       ;   data1(sel,ilon,ilat,selset) gt data2(sel,ilon,ilat,selset) then $
       ;   data_sub(sel,ilon,ilat,selset) = $
       ;   (data1(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset) - $
       ;                        data2(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset))/ $
       ;   (data1(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset))
       ; 
       ; ;3)
       ; if data1(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset) ge 1.0 and $
       ;   data2(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset) ge 1.0 and $
       ;   data1(sel,ilon,ilat,selset) ge data2(sel,ilon,ilat,selset) then $
       ;   data_sub(sel,ilon,ilat,selset) = -1 * $
       ;   (data1(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset) - $
       ;                        data2(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset))/ $
       ;   (data1(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset))
       ; 
       ; ;4)
       ; if data1(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset) ge 1.0 and $
       ;   data2(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset) ge 1.0 and $
       ;   data1(sel,ilon,ilat,selset) le data2(sel,ilon,ilat,selset) then $
       ;   data_sub(sel,ilon,ilat,selset) = -1 * $
       ;   (data1(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset) - $
       ;                        data2(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset))/ $
       ;   (data1(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset))
       ; 
       ; ;5)
       ; if (data1(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset) ge 1.0 and $
       ;   data2(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset) lt 1.0) or $
       ;    (data1(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset) le 1.0 and $
       ;   data2(sel,ilon,ilat,selset)/data_base(sel,ilon,ilat,selset) gt 1.0) then begin
       ;      data_sub(sel,ilon,ilat,selset) = -1 * $
       ;        ((data1(sel,ilon,ilat,selset)-$
       ;          (2*(data1(sel,ilon,ilat,selset)-data_base(sel,ilon,ilat,selset))))/$
       ;         data_base(sel,ilon,ilat,selset) - $
       ;         (data2(sel,ilon,ilat,selset) / data_base(sel,ilon,ilat,selset)))/$
       ;        ((data1(sel,ilon,ilat,selset)-$
       ;          2*(data1(sel,ilon,ilat,selset)-data_base(sel,ilon,ilat,selset)))/ $
       ;         data_base(sel,ilon,ilat,selset))
       ;
       ;  endif
     endfor
 endfor  
if plotvectoryes then begin
    if plotvecdiff then begin
        if vi_cnt eq 1 then begin
            eastsel = where(vars1 eq 'V!Di!N(east)')
            northsel = where(vars1 eq 'V!Di!N(north)')
        endif 
        
        if vn_cnt eq 1 then begin
            eastsel = where(vars1 eq 'V!Dn!N(east)')
            northsel = where(vars1 eq 'V!Dn!N(north)')
        endif
        
        data_sub(eastsel,*,*,*) = (data(eastsel,*,*,*) - $
                                   data_base(eastsel,*,*,*))
        data_sub(northsel,*,*,*) = (data(northsel,*,*,*) - $
                                    data_base(northsel,*,*,*))
    endif
endif

vars = vars1
if sel eq iviu or sel eq ivnu then begin  
    vars(sel) = vars1(sel) + ' Difference' 
endif else begin
    if istec then begin
        vars = [vars1, 'TEC']
    endif
    vars(sel) = vars(sel) + ' Normalized Difference' 
endelse

thermo_plotbatch,cursor_x,cursor_y,strx,stry,step,nvars1,sel,nfiles, $	  
  cnt1,cnt2,cnt3,yes,no,yeslog,  	  $
  1-yeslog,nalts1,nlats1,nlons1,yeswrite_cnt,$
  polar,npolar,MinLat,showgridyes,	  $
  plotvectoryes,vi_cnt,vn_cnt,vector_factor,	  $
  cursor_cnt,data_sub,alt,lat,lon,	  $
  xrange,yrange,selset,smini,smaxi,	  $
  filename,vars, psfile, 0, 'mid',itime,ortho,plat,plon


end
