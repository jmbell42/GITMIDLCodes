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




    LonAveData = fltarr(nvars,nlats-4,nalts-4)  
    SData = fltarr(nvars,nlats-4,nalts-4)  
    AveData = fltarr(nvars,nalts-4)  
    LonAveData  = reform( total(data(0:nvars-1,2:nlons-3,2:nlats-3,2:nalts-3), 2) / (nlons - 4) )

; Cosine weighting function in Latitude

     scos = fltarr(nlats-4) 
     scos = cos(lat(*)*!dtor)

; The summation of our weighting function in Latitude

     sumcos = total(scos(2:nlats-3),1) 


           for k = 0,nvars-1 do begin
             for i = 2,nlats-3 do begin
                 j = i - 2
                 SData(k, j, 0:nalts-5) = (cos(lat(i)*!dtor)*LonAveData(k, j,0:nalts-5))/sumcos               
             endfor
           endfor


          AveData  = reform( total(SData(0:nvars-1,0:nlats-5,0:nalts-5), 2) )
          Alts = alt[2:nAlts-3]

    display, Vars
    if (n_elements(iVar) eq 0) then iVar = 3
    nVars = n_elements(Vars)

    iVar = fix(ask('variable to plot',tostr(iVar)))

    if (iVar lt nVars) then value = reform(AveData[iVar,0:nalts-5])

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

            ;plotvalue = smooth(value[*], 8, /EDGE_TRUNCATE)
            plotvalue = value[*]
            plotalts = Alts[*]
       
       plot, plotvalue, plotalts, $
             background = 7, color = 0, thick = 2.0, $
             xrange = [min(plotvalue), max(plotvalue)], xstyle = 1, $
             yrange = [min(plotAlts), max(plotAlts)], ystyle = 1, /XLOG, $
             charsize = 2.0
        
        
    endif else begin

            ;plotvalue = smooth(value[*], 8, /EDGE_TRUNCATE)
            plotvalue = value[*]
            plotalts = Alts[*]

       plot, plotvalue, plotalts, $
             background = 7, color = 0, thick = 2.0, $
             xrange = [min(plotvalue), max(plotvalue)], xstyle = 1, $
             yrange = [min(plotAlts), max(plotAlts)], ystyle = 1,  $
             charsize = 2.0

    endelse



;; Set Variable Index Variables
  iN2_ = 4
  iN2iso_ = 71

  iCH4_ = 5
  iCH4iso_ = 72

  iH2_ = 13
  iAr_ = 58

  iCH4Mix_ = 57
  iH2Mix_ = 65

  iH2Vel_ = 27
  iCH4Vel_ = 24
  iN2Vel_ = 23


   if ( (iVar eq iN2_) or (iVar eq iCH4_) or (iVar eq iAr_) or (iVar eq iH2_) or (iVar eq iN2iso_) or (iVar eq iCH4iso_) or $
             (iVar eq iCH4Mix_) or (iVar eq iH2Mix_) ) then begin

   
       DataSelected = 0
       DataAsk = ask('Would you like to plot INMS Data? [y/n]', 'y')

      if (strpos(mklower(DataAsk),'y') eq 0) then begin  ; Data is desired

       iData = 1

       if ( (iVar eq iN2_) ) then begin
           iData = 1
       endif
       if ( (iVar eq iCH4_) ) then begin
           iData = 2
       endif
       if ( (iVar eq iAr_) ) then begin
           iData = 3
       endif
       if ( (iVar eq iH2_) ) then begin
           iData = 4
       endif
       if ( (iVar eq iN2iso_) ) then begin
           iData = 5
       endif
       if ( (iVar eq iCH4iso_) ) then begin
           iData = 6
       endif
       if ( (iVar eq iCH4Mix_) ) then begin
           iData = 7
       endif

       if ( (iVar eq iH2Mix_) ) then begin
           iData = 8
       endif

;==============Filled Circles
         phi = findgen(32)*(!PI*2/32.)
         phi = [phi, phi(0)]
         usersym, cos(phi), sin(phi), /fill 
;==============Filled Circles

        if (iData eq 1) then begin
     
           DataSelected = 1

           restore, filename = 'Major_neutrals_02-11-10.sav'

            NewDataN2 = AACS*XN2Mean.Density*1.0e+06

            NewDataArray = NewDataN2
            NewDataAlts = XN2Mean.Alt

            Err_DatanN2 = XN2Mean.Density_Error*AACS*1.0e+06
            Std_DatanN2 = XN2Mean.Density_Stdev*AACS*1.0e+06

           oplot,NewDataN2, NewDataAlts, psym = 8, $
               color = 5, thick = 4.0

;           err_plot, NewDataAlts, $
;                     NewDataN2 - Err_DatanN2*1.0e+06, $
;                     NewDataN2 + Err_DatanN2*1.0e+06, $
;                     width = 0.01, color = 5, thick = 2.0
;

        endif
        if (iData eq 2) then begin

           DataSelected = 1

           restore, filename = 'Major_neutrals_02-11-10.sav'

            NewDataCH4 = AACS*XCH4Mean.Density*1.0e+06

            NewDataArray = NewDataCH4
            NewDataAlts = XCH4Mean.Alt

            Err_DatanCH4 = XCH4Mean.Density_Error*AACS*1.0e+06
            Std_DatanCH4 = XCH4Mean.Density_Stdev*AACS*1.0e+06

           oplot,NewDataCH4, NewDataAlts, psym = 8, $
               color = 5, thick = 4.0

           err_plot, NewDataAlts, $
                     NewDataCH4 - Err_DatanCH4*1.0e+06, $
                     NewDataCH4 + Err_DatanCH4*1.0e+06, $
                     width = 0.01, color = 5, thick = 2.0


        endif

        if (iData eq 3) then begin


           DataSelected = 1

           restore, filename = 'Brian_ArgonMixing_10km_bin.data'

            NewIndex = where((Bin_ArMix gt 0.0) and (Bin_Altitude le 1125.0) and (Bin_Altitude ge 1000.0) )

            NewDataAr = Bin_ArMix[NewIndex]

            NewDataArray = NewDataAr
            NewDataAlts = Bin_altitude[NewIndex]

           oplot,NewDataAr, NewDataAlts, psym = 8, $
               color = 5, thick = 4.0

           err_plot, NewDataAlts, $
                     NewDataAr - Bin_ArMixError[NewIndex], $
                     NewDataAr + Bin_ArMixError[NewIndex], $
                     width = 0.01, color = 5, thick = 2.0

            DataArray = fltarr(n_elements(NewDataAr))
            DataAlts = fltarr(n_elements(NewDataAr))
 
            DataArray = NewDataAr
            DataAlts = NewDataAlts

           restore, filename = 'RogerYelle_Argon.data'

           oplot,ArMixingRoger, AltitudeRoger, psym = 8, $
               color = 8, thick = 8.0

           err_plot, AltitudeRoger, $
                     ArMixingRoger - ArMixingRogerError, $
                     ArMixingRoger + ArMixingRogerError, $
                     width = 0.01, color = 8, thick = 3.0


        endif

        if (iData eq 4) then begin

           DataSelected = 1

           restore, filename = 'Major_neutrals_02-11-10.sav'

            NewDataH2 = AACS*XH2Mean.Density*1.0e+06

            NewDataArray = NewDataH2
            NewDataAlts = XH2Mean.Alt

            Err_DatanH2 = XH2Mean.Density_Error*AACS*1.0e+06
            Std_DatanH2 = XH2Mean.Density_Stdev*AACS*1.0e+06

           oplot,NewDataH2, NewDataAlts, psym = 8, $
               color = 5, thick = 4.0

           err_plot, NewDataAlts, $
                     NewDataH2 - Err_DatanH2*1.0e+06, $
                     NewDataH2 + Err_DatanH2*1.0e+06, $
                     width = 0.01, color = 5, thick = 2.0


         endif

        if (iData eq 5) then begin

            DataSelected = 1

            restore, filename = 'N_densities_T16_to_T32_01-18-10.sav'

            NewDataN2iso = AXNRATIOMEAN.RATIO
            PreDataAlts = AXNRATIOMEAN.Alt

            RatioIndex = where(PreDataAlts ge 1100.0)

            NewDataArray = NewDataN2iso[RatioIndex]
            NewDataAlts = PreDataAlts[RatioIndex]

            oplot,NewDataN2iso[RatioIndex], NewDataAlts, psym = 8, $
                color = 5, thick = 4.0

        endif 

        if (iData eq 6) then begin

            DataSelected = 1

            restore, filename = 'Brian_CH4isoRatio_10km_bin.data'

            NewIndex = where((Bin_CH4isoRatio gt 0.0) and (Bin_Altitude ge 1100.0))

            NewDataCH4iso = 1.075*Bin_CH4isoRatio[NewIndex]

            NewDataArray = NewDataCH4iso
            NewDataAlts = Bin_altitude[NewIndex]

           oplot,NewDataCH4iso, NewDataAlts, psym = 8, $
               color = 5, thick = 4.0

        endif 

        if (iData eq 7) then begin

           DataSelected = 1

            restore, filename = 'Major_neutrals_02-11-10.sav'

            NewDataN2 = AACS*XN2Mean.Density*1.0e+06
            NewDataCH4 = AACS*XCH4Mean.Density*1.0e+06
            NewDataH2 = AACS*XH2Mean.Density*1.0e+06

            NewDataAlts = XCH4Mean.Alt

            Err_DatanN2 = XN2Mean.Density_Error*AACS*1.0e+06
            Std_DatanN2 = XN2Mean.Density_Stdev*AACS*1.0e+06

            Err_DatanCH4 = XCH4Mean.Density_Error*AACS*1.0e+06
            Std_DatanCH4 = XCH4Mean.Density_Stdev*AACS*1.0e+06

            NewDataCH4Mix = NewDataCH4/(NewDataCH4 + NewDataN2 + NewDataH2)
            NewDataArray = NewDataCH4Mix

            oplot,NewDataCH4Mix, NewDataAlts, psym = 8, $
                color = 5, thick = 4.0


        endif
      
        if (iData eq 8) then begin

           DataSelected = 1

            restore, filename = 'Major_neutrals_02-11-10.sav'

            NewDataN2 = AACS*XN2Mean.Density*1.0e+06
            NewDataCH4 = AACS*XCH4Mean.Density*1.0e+06
            NewDataH2 = AACS*XH2Mean.Density*1.0e+06

            NewDataAlts = XCH4Mean.Alt

            Err_DatanN2 = XN2Mean.Density_Error*AACS*1.0e+06
            Std_DatanN2 = XN2Mean.Density_Stdev*AACS*1.0e+06

            Err_DatanCH4 = XCH4Mean.Density_Error*AACS*1.0e+06
            Std_DatanCH4 = XCH4Mean.Density_Stdev*AACS*1.0e+06

            NewDataH2Mix = NewDataH2/(NewDataCH4 + NewDataN2 + NewDataH2)
            NewDataArray = NewDataH2Mix

            oplot,NewDataH2Mix, NewDataAlts, psym = 8, $
                color = 5, thick = 4.0


        endif


       if (DataSelected eq 0) then begin
         print, 'Silly person, you no select correct Data!!'
       endif

      endif else begin
         print, 'No Data for You!!'
      endelse


    endif ;  Checking the iVars for N2, CH4, or Argon Mixing Ratio

;   ; First, find the altitude locations of the bins in the model output
;
;    if (DataSelected eq 1) then begin
;
;       InterpolatedModelData = SPLINE(plotalts, plotvalue, NewDataAlts, /DOUBLE)
;
;         Deviations = fltarr(n_elements(NewDataAlts))
;
;
;         for i = 0, n_elements(NewDataAlts) - 1 do begin
;              Deviations[i] = abs( InterpolatedModelData[i]  - NewDataArray[i])/NewDataArray[i]
;         endfor
;
;             CorrelationCoefModel = correlate( InterpolatedModelData, NewDataArray[*])
;             PercentError = total(Deviations)/n_elements(Deviations)
;
;     print, 'Model Percent Error:',PercentError
;     print, 'Model Correlation Coefficient (Squared) :',CorrelationCoefModel^2.0
;
;     print, '======================================= <> ================================================'
;     print, '================== FLUXES THROUGH THE MODEL BOUNDARIES (RELATIVE TO SURFACE) =============='
;     print, '======================================= <> ================================================'
;
;;;     FluxIndexLower1 = nGCs  - 1 
;;;     FluxIndexUpper1 = nAlts - nGCs  - 1 
;
;     FluxIndexLower1 = 1
;     FluxIndexUpper1 = nAlts - nGCs 
;
;
;;;     FluxIndexLower1 = nGCs  - 1 + 10 
;;;     FluxIndexLower2 = nGCs  - 1 
;
;;;     FluxIndexUpper1 = nAlts  - nGCs - 1 
;;;     FluxIndexUpper2 = nAlts  - nGCs - 1 
;
;;;     FluxIndexLower1 = nGCs  - 1 + 10 
;;;     FluxIndexUpper1 = nAlts  - nGCs - 1 
;
;;; ================ H2 FlUXES
;     print, 'H2 Upper Boundary Fluxes:', TimeAveData[iH2_,FluxIndexUpper1]*TimeAveData[iH2Vel_,FluxIndexUpper1]*((TimeAveData[2,FluxIndexUpper1] + 2575.0*1000.0 )/(2575.0*1000.0) )^2.0, $
;             ' (1/m^2/s) ', $
;             TimeAveData[iH2_,FluxIndexUpper1]*TimeAveData[iH2Vel_,FluxIndexUpper1]*4.0*!pi*(TimeAveData[2,FluxIndexUpper1] + 2575.0*1000.0)^2.0, $
;             ' (molecules/s) ', $
;             TimeAveData[iH2_,FluxIndexUpper1]*TimeAveData[iH2Vel_,FluxIndexUpper1]*2.0*4.0*!pi*(TimeAveData[2,FluxIndexUpper1] + 2575.0*1000.0)^2.0, $
;             ' (amu/s) '
;
;     print, 'H2 Lower Boundary Fluxes:', TimeAveData[iH2_,FluxIndexLower1]*TimeAveData[iH2Vel_,FluxIndexLower1]*((TimeAveData[2,FluxIndexLower1] + 2575.0*1000.0 )/(2575.0*1000.0) )^2.0, $
;             ' (1/m^2/s) ', $
;             TimeAveData[iH2_,FluxIndexLower1]*TimeAveData[iH2Vel_,FluxIndexLower1]*4.0*!pi*(TimeAveData[2,FluxIndexLower1] + 2575.0*1000.0)^2.0, $
;             ' (molecules/s) ', $
;             TimeAveData[iH2_,FluxIndexLower1]*TimeAveData[iH2Vel_,FluxIndexLower1]*2.0*4.0*!pi*(TimeAveData[2,FluxIndexLower1] + 2575.0*1000.0)^2.0, $
;             ' (amu/s) '
;
;;; ============= END H2 FLUXES
;
;;; ================ CH4 FlUXES
;     print, 'CH4 Upper Boundary Fluxes:', TimeAveData[iCH4_,FluxIndexUpper1]*TimeAveData[iCH4Vel_,FluxIndexUpper1]*((TimeAveData[2,FluxIndexUpper1] + 2575.0*1000.0 )/(2575.0*1000.0) )^2.0, $
;             ' (1/m^2/s) ', $
;             TimeAveData[iCH4_,FluxIndexUpper1]*TimeAveData[iCH4Vel_,FluxIndexUpper1]*4.0*!pi*(TimeAveData[2,FluxIndexUpper1] + 2575.0*1000.0)^2.0, $
;             ' (molecules/s) ', $
;             TimeAveData[iCH4_,FluxIndexUpper1]*TimeAveData[iCH4Vel_,FluxIndexUpper1]*16.0*4.0*!pi*(TimeAveData[2,FluxIndexUpper1] + 2575.0*1000.0)^2.0, $
;             ' (amu/s) '
;
;     print, 'CH4 Lower Boundary Fluxes:', TimeAveData[iCH4_,FluxIndexLower1]*TimeAveData[iCH4Vel_,FluxIndexLower1]*((TimeAveData[2,FluxIndexLower1] + 2575.0*1000.0 )/(2575.0*1000.0) )^2.0, $
;             ' (1/m^2/s) ', $
;             TimeAveData[iCH4_,FluxIndexLower1]*TimeAveData[iCH4Vel_,FluxIndexLower1]*4.0*!pi*(TimeAveData[2,FluxIndexLower1] + 2575.0*1000.0)^2.0, $
;             ' (molecules/s) ', $
;             TimeAveData[iCH4_,FluxIndexLower1]*TimeAveData[iCH4Vel_,FluxIndexLower1]*16.0*4.0*!pi*(TimeAveData[2,FluxIndexLower1] + 2575.0*1000.0)^2.0, $
;             ' (amu/s) '
;
;;; ============= END CH4 FLUXES
;
;;; ================ N2 FlUXES
;     print, 'N2 Upper Boundary Fluxes:', TimeAveData[iN2_,FluxIndexUpper1]*TimeAveData[iN2Vel_,FluxIndexUpper1]*((TimeAveData[2,FluxIndexUpper1] + 2575.0*1000.0 )/(2575.0*1000.0) )^2.0, $
;             ' (1/m^2/s) ', $
;             TimeAveData[iN2_,FluxIndexUpper1]*TimeAveData[iN2Vel_,FluxIndexUpper1]*4.0*!pi*(TimeAveData[2,FluxIndexUpper1] + 2575.0*1000.0)^2.0, $
;             ' (molecules/s) ', $
;             TimeAveData[iN2_,FluxIndexUpper1]*TimeAveData[iN2Vel_,FluxIndexUpper1]*28.0*4.0*!pi*(TimeAveData[2,FluxIndexUpper1] + 2575.0*1000.0)^2.0, $
;             ' (amu/s) '
;
;     print, 'N2 Lower Boundary Fluxes:', TimeAveData[iN2_,FluxIndexLower1]*TimeAveData[iN2Vel_,FluxIndexLower1]*((TimeAveData[2,FluxIndexLower1] + 2575.0*1000.0 )/(2575.0*1000.0) )^2.0, $
;             ' (1/m^2/s) ', $
;             TimeAveData[iN2_,FluxIndexLower1]*TimeAveData[iN2Vel_,FluxIndexLower1]*4.0*!pi*(TimeAveData[2,FluxIndexLower1] + 2575.0*1000.0)^2.0, $
;             ' (molecules/s) ', $
;             TimeAveData[iN2_,FluxIndexLower1]*TimeAveData[iN2Vel_,FluxIndexLower1]*28.0*4.0*!pi*(TimeAveData[2,FluxIndexLower1] + 2575.0*1000.0)^2.0, $
;             ' (amu/s) '
;
;;; ============= END N2 FLUXES
;
;     print, '======================================= <> ================================================'
;     print, '================== FLUXES THROUGH THE MODEL BOUNDARIES (RELATIVE TO SURFACE) =============='
;     print, '======================================= <> ================================================'
;
;;    print, Alts[nGCs -1 + 10]
;;    print, Alts[nGCs -1 + 11]
;
;    print, Alts[nAlts - nGCs - 6]
;    print, Alts[nAlts - nGCs - 5]







end
