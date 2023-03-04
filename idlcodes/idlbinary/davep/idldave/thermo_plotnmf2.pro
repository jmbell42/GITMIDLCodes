dotempunit = 'y'

if n_elements(dir)  eq 0 then dir = ''
if n_elements(dir_base) eq 0 then dir_base = ''
compare = 0
usedir = 1
if usedir then begin
    dir = ask('perturbation dir to plot',dir)
if compare then    dir_base = ask('baseline directory to plot',dir_base)
    filelist = file_search(dir+'/3DALL*.bin')
if compare then    filelist_base = file_search(dir_base+'/3DALL*.bin')
endif else begin
    if n_elements(filename) eq 0 then filename = ''
if compare then       if n_elements(filename_base) eq 0 then filename_base = ''
    filelist = ask('filename to plot',filename)
if compare then       filelist_base = ask('base filename to plot',filename_base)
    filelist = findfile(filelist)
if compare then       filelist_base = findfile(filelist_base)
endelse

nfiles = n_elements(filelist)
if compare then   nfiles_base = n_elements(filelist_base)
if compare then   begin
   if nfiles ne nfiles_base then begin
      print, 'Base and perturbation directories do not have the same amount of files:'
      print, 'Quiting...'
    stop
endif
endif
for iFile = 0, nFiles-1 do begin

    filename = filelist(iFile)
if compare then       filename_base = filelist_base(ifile)

    print, 'Reading file ',filename

    read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
      vars, data, rb, cb, bl_cnt


if compare then       read_thermosphere_file, filename_base, nvars_base, nalts_base, nlats_base, nlons_base, $
      vars_base, data_base, rb_base, cb_base, bl_cnt_base

if compare then       data = data(*,*,*,0:nalts_base-1)
if compare then       nalts = nalts_base

    dalt = fltarr(nalts-4)
    alt = reform(data(2,*,*,*)) / 1000.0
    alts = reform(alt(0,0,*))
    for ialt = 2,nalts - 3 do begin
        dalt(ialt-2) = ((alts(ialt+1)+alts(ialt))/2.- $
                        (alts(ialt)+alts(ialt-1))/2.)
    endfor

    
    lat = reform(data(1,*,*,*)) / !dtor
    lon = reform(data(0,*,*,*)) / !dtor

    
    nmf2 = fltarr(nlons,nlats)
    hmf2 = fltarr(nlons,nlats)
if compare then       nmf2_base = fltarr(nlons,nlats)
if compare then       hmf2_base = fltarr(nlons,nlats)
    TEC = fltarr(nlons,nlats)
if compare then       TEC_base = fltarr(nlons,nlats)
    on2 = fltarr(nlons,nlats)
 if compare then      on2_base = fltarr(nlons,nlats)
    rho = fltarr(nlons,nlats)
if compare then       rho_base = fltarr(nlons,nlats)
    ihmf2 = fltarr(nlons,nlats)
    for ilat = 0, nlats - 1 do begin
        for ilon = 0, nlons - 1 do begin
            nmf2(ilon,ilat) = 9.0e-3*sqrt(max(data(32,ilon,ilat,*),h))
            hmf2(ilon,ilat) = alt(0,0,h)
            
            ihmf2(ilon,ilat) = h
            TEC(ilon,ilat) = total(data(32,ilon,ilat,2:nalts-3)*dalt*1000.0)/1.0e16
            rho(ilon,ilat) = data(3,ilon,ilat,36)
            on2(ilon,ilat) = reform(data(4,ilon,ilat,h)/data(6,ilon,ilat,h))
 if compare then              nmf2_base(ilon,ilat) = max(data_base(32,ilon,ilat,*),hb)
 if compare then              hmf2_base(ilon,ilat) = alt(0,0,hb)
 if compare then              TEC_base(ilon,ilat) = total(data_base(32,ilon,ilat,2:nalts-3)$
                                        *dalt*1000.0)
 if compare then              rho_base(ilon,ilat) = data_base(3,ilon,ilat,36)
 if compare then              on2_base(ilon,ilat) = reform(data_base(4,ilon,ilat,h)/ $
                                         data_base(6,ilon,ilat,h))
        endfor
    endfor

    data(19,*,*,nalts-1) = nmf2
    data(20,*,*,nalts-1) = hmf2
    data(21,*,*,nalts-1) = TEC
    data(22,*,*,nalts-1) = on2 
    data(3,*,*,nalts-1) = rho

 if compare then      data_base(19,*,*,nalts-1) = nmf2_base
 if compare then      data_base(20,*,*,nalts-1) = hmf2_base
  if compare then     data_base(21,*,*,nalts-1) = TEC_base
 if compare then      data_base(22,*,*,nalts-1) = on2_base
 if compare then      data_base(3,*,*,nalts-1) = rho_base
    vars(19) = 'NmF2 (m!U-3!N)'
    Vars(20) = 'HmF2 (km)'
    Vars(21) = 'TECU'
    Vars(22) = 'O/N!D2!N'
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
     
     if (iFile eq 0) then begin
         

        cnt1 = 1
        cnt2 = 0
        cnt3 = 0
        
        if n_elements(selvar) eq 0 then selvar = 0
        print, '0.  NmF2'
        print, '1.  HmF2'
        print, '2.  TEC'
        print, '3.  Rho'
        print, '4.  O/N2'

        print, ''
        selvar = fix(ask('which variable to plot: ',tostr(selvar)))
        
        if selvar eq 0 then sel = 19
        if selvar eq 1 then sel = 20
        if selvar eq 2 then sel = 21
           
        
        if selvar eq 3 then sel = 3
        if selvar eq 4 then sel = 22

        if n_elements(pv) eq 0 then pv = 'n'
        plotvector = ask('whether you want vectors or not (y/n)',pv)
        pv = plotvector
        if strpos(plotvector,'y') eq 0 then plotvector=1 else plotvector = 0

        if (plotvector) then begin
            print,'-1  : automatic selection'
            factors = [1.0, 5.0, 10.0, 20.0, 25.0, $
                       50.0, 75.0, 100.0, 150.0, 200.0]
            nfacs = n_elements(factors)
            for i=0,nfacs-1 do print, tostr(i)+'. '+string(factors(i)*10.0)
            if n_elements(vector_factor) eq 0 then vector_factor = -1
            vector_factor = fix(ask('velocity factor',tostr(vector_factor)))
            
            if n_elements(vecalt) eq 0 then vecalt = -1
            vecalt = fix(ask('which alt to plot vectors (-1 for hmf2): ',$
                             tostr(vecalt)))
        endif else vector_factor = 0


       if n_elements(smini) eq 0 then smini = 0.0
       if n_elements(smaxi) eq 0 then smaxi = 0.0
       smini = ask('minimum (0.0 for automatic)',tostrf(smini))
       smaxi = ask('maximum (0.0 for automatic)',tostrf(smaxi))
    
; cursor position variables, which don't matter at this point
        cursor_x = 0.0
        cursor_y = 0.0
        strx = '0.0'
        stry = '0.0'

; yes is whether ghostcells are plotted or not:
        yes = 0
        no  = 1

; yeslog is whether variable should be logged or not:
        plotlog = 0
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
        slice = 1
        if slice eq 1 then begin
           polar = 0
           ortho = 0
           polar = fix(ask("if polar or ortho (0,1,2): ",tostr(polar)))
           
           if polar eq 2 then begin
               polar = 0
               ortho = 1
            
               if n_elements(tlat) eq 0 then tlat = 0
               if n_elements(tlon) eq 0 then tlon = 0
               tlat = float(ask('ortho center latitude (0.0 for subsolar): ',$
                                tostrf(tlat)))
               tlon = float(ask('ortho center longitude (0.0 for subsolar): ',$
                                tostrf(tlon)))
            
           endif 
       endif
       
       if ortho eq 1 then begin
           if tlat eq 0.0 and tlon eq 0.0 then begin
               
               zsun,strdate,uttime ,0,0,zenith,azimuth,solfac,$
                 lonsun=lonsun,latsun=latsun
               
               if lonsun lt 0.0 then lonsun = 360.0 - abs(lonsun)
               
               plat = latsun
               plon = lonsun
               
               print, 'Coordinates: ',lonsun ,' Long. ',latsun,' Lat.'
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
        plotvecdiff = 1
; number of points to skip when plotting vectors:
        step = 2

; vi_cnt is whether to plot vectors of Vi
        vi_cnt = 1

; vn_cnt is whether to plot vectors of Vn

        vn_cnt = 0

        cursor_cnt = 0

        xrange = [0.0,0.0]

        yrange = [0.0,0.0]



    endif

    psfile = 'plot_0000.ps'
    if (nFiles gt 1) then begin
        p = strpos(psfile,'.ps')
        if (p gt -1) then psfile = strmid(psfile,0,p-5)
        psfile_final = psfile+'_'+chopr('000'+tostr(iFile),4)+'.ps'
    endif else begin
        psfile_final = psfile
    endelse
    psfile = psfile_final
    smini_final = smini
    smaxi_final = smaxi

    selset = nalts - 1
if compare then    selset_b = nalts_base - 1
    datasub = data
 if compare then      datasub(sel,*,*,selset) = (data(sel,*,*,selset) $
                               - data_base(sel,*,*,selset_b))/$
      data_base(sel,*,*,selset_b)*100.0 else datasub(sel,*,*,selset) = data(sel,*,*,selset)

if plotvectoryes then begin
    if vi_cnt eq 1 then begin
        eastsel = where(vars eq 'V!Di!N(east)')
        northsel = Where(vars eq 'V!Di!N(north)')
    endif 
    
    if vn_cnt eq 1 then begin
        eastsel = where(vars eq 'V!Dn!N(east)')
        northsel = where(vars eq 'V!Dn!N(north)')
    endif

    if plotvecdiff then begin
        for ilat = 0, nlats - 1 do begin
         if compare then   begin
           for ilon = 0, nlons -1 do begin
                datasub(eastsel,ilon,ilat,selset) = $
                  (data(eastsel,ilon,ilat,ihmf2(ilon,ilat)) - $
                   data_base(eastsel,ilon,ilat,ihmf2(ilon,ilat)))
                datasub(northsel,ilon,ilat,selset) = $
                  (data(northsel,ilon,ilat,ihmf2(ilon,ilat)) - $
                   data_base(northsel,ilon,ilat,ihmf2(ilon,ilat)))

            endfor
             endif
        endfor
    endif
endif

    thermo_nmf2,cursor_x,cursor_y,strx,stry,step,nvars,sel,nfiles,	$
      cnt1,cnt2,cnt3,yes,no,yeslog,  	  $
      1-yeslog,nalts,nlats,nlons,yeswrite_cnt,$
      polar,npolar,MinLat,showgridyes,	  $
      plotvectoryes,vi_cnt,vn_cnt,vector_factor,	  $
      cursor_cnt,datasub,alt,lat,lon,	  $
      xrange,yrange,selset,smini_final,smaxi_final,	  $
      filename,vars, psfile_final, 0, 'mid',itime,ortho,plat,plon


endfor


end
