; Small code to set colors for plotting below ------------------>

device, decomposed = 0
bottom = 0

; fixes all plots to specifications later on

!x.style =1 

; Load graphics colors:----------------->

red = [   0, 255,   0, 255,   0, 255,   0, 255,$ 
          0, 255, 255, 112, 219, 127,   0, 255]
grn = [   0,   0, 255, 255, 255,   0,   0, 255,$ 
          0, 187, 127, 219, 112, 127, 163, 171]
blu = [   0, 255, 255,   0,   0,   0, 255, 255,$ 
        115,   0, 127, 147, 219, 127, 255, 127]

tvlct, red, grn, blu, bottom

; Set color names :----------------->
names = [ 'Black', 'Magenta', 'Cyan', 'Yellow', $
          'Green', 'Red', 'Blue', 'White',      $
          'Navy', 'Gold', 'Pink', 'Aquamarine', $
          'Orchid', 'Gray', 'Sky', 'Beige']

    filelist = findfile("*.bin")
    nFiles = n_elements(filelist)
    iFile = nFiles-1

    filename = filelist(iFile)

    read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
      vars, data, rb, cb, bl_cnt

    longitude = reform(data(0,*,*,*))/ !dtor
    latitude = reform(data(1,*,*,*)) / !dtor
    altitude = reform(data(2,*,*,*)) / 1000.0
    localtime = reform(data(3,*,*,*)) 

AACS = 3.0


    alt = altitude(2,2,*)
    lat = latitude(2,*,2)
    lon = longitude(*,2,2)
    slt = localtime(*,2,2)




    LonAveData = fltarr(nvars,nlats-4,nalts)  
    SData = fltarr(nvars,nlats-4,nalts)  
    AveData = fltarr(nvars,nalts)  
    LonAveData  = reform( total(data(0:nvars-1,2:nlons-3,2:nlats-3,0:nalts-1), 2) / (nlons - 4) )

; Cosine weighting function in Latitude

     scos = fltarr(nlats-4) 
     scos = cos(lat(*)*!dtor)

; The summation of our weighting function in Latitude

     sumcos = total(scos(2:nlats-3),1) 


           for k = 0,nvars-1 do begin
             for i = 2,nlats-3 do begin
                 j = i - 2
                 SData(k, j, 0:nalts-1) = (cos(lat(i)*!dtor)*LonAveData(k, j,0:nalts-1))/sumcos               
             endfor
           endfor


          AveData  = reform( total(SData(0:nvars-1,0:nlats-5,0:nalts-1), 2) )
          Alts = alt[0:nAlts-1]

    display, Vars
    if (n_elements(iVar) eq 0) then iVar = 3
    nVars = n_elements(Vars)

    iVar = fix(ask('variable to plot',tostr(iVar)))

    if (iVar lt nVars) then value = reform(AveData[iVar,0:nalts-1])

    print, 'Selection: ',Vars[iVar]
            plotlog = 0

    if (min(value) gt 0) then begin
        if (n_elements(an) eq 0) then an = 'y'
        an = ask('whether you would like variable to be alog10',an)
        if (strpos(mklower(an),'y') eq 0) then begin
            plotlog = 1
            title = Vars(iVar)
        endif else title = Vars(iVar)
    endif else title = Vars(iVar)

    if (plotlog) then begin 

           LowerMask = where(Alts le 600.0)
           ;plotvalue = smooth(value[LowerMask], 8, /EDGE_TRUNCATE)
           plotvalue = value[LowerMask]
           plotalts = Alts[LowerMask]
       
       plot, plotvalue, plotalts, $
             background = 7, color = 0, thick = 2.0, $
             xrange = [min(plotvalue), max(plotvalue)], xstyle = 1, $
             yrange = [min(plotAlts), max(plotAlts)], ystyle = 1, /XLOG, $
             charsize = 2.0
        
        
    endif else begin

           LowerMask = where(Alts le 600.0)
           ;plotvalue = smooth(value[LowerMask], 8, /EDGE_TRUNCATE)
           plotvalue = value[LowerMask]
           plotalts = Alts[LowerMask]

       plot, plotvalue, plotalts, $
             background = 7, color = 0, thick = 2.0, $
             xrange = [min(plotvalue), max(plotvalue)], xstyle = 1, $
             yrange = [min(plotalts), max(plotalts)], ystyle = 1, $
             charsize = 2.0

    endelse


end
