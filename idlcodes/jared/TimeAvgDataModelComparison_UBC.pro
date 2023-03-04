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

; END COLOR SETUP

AACS = 3.0

GetNewData = 1
fpi = 0

filelist_new = findfile("*.bin")
nfiles_new = n_elements(filelist_new)
if (nfiles_new eq 1) then begin
    filelist_new = findfile("????_*.dat")
    nfiles_new = n_elements(filelist_new)
endif

if n_elements(nfiles) gt 0 then begin
    if (nfiles_new eq nfiles) then default = 'n' else default='y'
    GetNewData = mklower(strmid(ask('whether to reread data',default),0,1))
    if (GetNewData eq 'n') then GetNewData = 0 else GetNewData = 1
endif

if (GetNewData) then begin

    thermo_readsat, filelist_new, data, time, nTimes, Vars, nAlts, nSats, Files
    nFiles = n_elements(filelist_new)

endif


; Now Time-Average the Profiles

; First, remove the first array index (spurious)
  newdata = reform(data)

; Next, Time Average the Data
  TimeAveData = total(newdata, 1)/nfiles

  Alts = reform(TimeAveData[2,*])/1000.0

  nGcs = 2  ; the Number of Ghost Cells (Top and Bottom) 
; \
; Display Variables to plot
; Ask for a selection

    display, Vars
    if (n_elements(iVar) eq 0) then iVar = 3
    nVars = n_elements(Vars)

    iVar = fix(ask('variable to plot',tostr(iVar)))

    if (iVar lt nVars) then value = reform(TimeAveData[iVar,0:nalts-1])

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

            UBCMask = where(Alts gt 1400.0)
            plotvalue = value[UBCMask]
            plotalts = Alts[UBCMask]

       plot, plotvalue, plotalts, $
             background = 7, color = 0, thick = 2.0, $
             xrange = [min(plotvalue), max(plotvalue)], xstyle = 1, $
             yrange = [min(plotAlts), max(plotAlts)], ystyle = 1, /XLOG
        
        
    endif else begin

            UBCMask = where(Alts gt 1400.0)
            plotvalue = value[UBCMask]
            plotalts = Alts[UBCMask]

       plot, plotvalue, plotalts, $
             background = 7, color = 0, thick = 2.0, $
             xrange = [min(plotvalue), max(plotvalue)], xstyle = 1, $
             yrange = [min(plotAlts), max(plotalts)], ystyle = 1

    endelse

;; Set Variable Index Variables
  iN2_ = 4
  iN2isoRatio_ = 71
  iN2iso_ = 9

  iCH4_ = 5
  iCH4isoRatio_ = 72
  iCH4iso_ = 10

  iH2_ = 8
  iAr_ = 58

  iCH4Mix_ = 57
  iH2Mix_ = 60

  iH2Vel_ = 27
  iCH4Vel_ = 24
  iN2Vel_ = 23


   if ( (iVar eq iN2_) or (iVar eq iCH4_) or (iVar eq iAr_) or (iVar eq iH2_) or (iVar eq iN2iso_) or (iVar eq iCH4iso_) or $
             (iVar eq iCH4Mix_) or (iVar eq iH2Mix_) or (iVar eq iN2isoRatio_) or (iVar eq iCH4isoRatio_) ) then begin

   
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
       if ( (iVar eq iN2isoRatio_) ) then begin
           iData = 5
       endif
       if ( (iVar eq iCH4isoRatio_) ) then begin
           iData = 6
       endif
       if ( (iVar eq iCH4Mix_) ) then begin
           iData = 7
       endif
       if ( (iVar eq iH2Mix_) ) then begin
           iData = 8
       endif
       if ( (iVar eq iN2iso_) ) then begin
           iData = 9
       endif
       if ( (iVar eq iCH4iso_) ) then begin
           iData = 10
       endif

;==============Filled Circles
         phi = findgen(32)*(!PI*2/32.)
         phi = [phi, phi(0)]
         usersym, cos(phi), sin(phi), /fill 
;==============Filled Circles

        if (iData eq 1) then begin
     
           DataSelected = 1

           restore, filename = 'HotBinned_INMS_Data.save'

            AltMask = where(ModelBinCenters ge 1020.0)
            NewDataN2 = AverageIngress_DatanN2[AltMask]

            NewDataArray = NewDataN2
            NewDataAlts = ModelBinCenters[AltMask]

            Err_DatanN2 = AverageIngress_DatanN2_TotalError[AltMask]

           oplot,NewDataN2, NewDataAlts, psym = 8, $
               color = 5, thick = 4.0

            err_plot, NewDataAlts, $
                      NewDataN2 - Err_DatanN2, $
                      NewDataN2 + Err_DatanN2, $
                      width = 0.01, color = 5, thick = 2.0
 

        endif
        if (iData eq 2) then begin

           DataSelected = 1

           restore, filename = 'HotBinned_INMS_Data.save'

            AltMask = where(ModelBinCenters ge 1020.0)
            NewDataCH4 = AverageIngress_DatanCH4[AltMask]

            NewDataArray = NewDataCH4
            NewDataAlts = ModelBinCenters[AltMask]

            Err_DatanCH4 = AverageIngress_DatanCH4_TotalError[AltMask]

           oplot,NewDataCH4, NewDataAlts, psym = 8, $
               color = 5, thick = 4.0

            err_plot, NewDataAlts, $
                      NewDataCH4 - Err_DatanCH4, $
                      NewDataCH4 + Err_DatanCH4, $
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

           restore, filename = 'HotBinned_INMS_Data.save'

            AltMask = where(ModelBinCenters ge 1020.0)
            NewDataH2 = AverageIngress_DatanH2[AltMask]

            NewDataArray = NewDataH2
            NewDataAlts = ModelBinCenters[AltMask]

            Err_DatanH2 = AverageIngress_DatanH2_TotalError[AltMask]

           oplot,NewDataH2, NewDataAlts, psym = 8, $
               color = 5, thick = 4.0

            err_plot, NewDataAlts, $
                      NewDataH2 - Err_DatanH2, $
                      NewDataH2 + Err_DatanH2, $
                      width = 0.01, color = 5, thick = 2.0

         endif

        if (iData eq 5) then begin

            DataSelected = 1

     INMSDataFile = 'GITM_neutrals.sav'
     restore, INMSDataFile
     
     Data14N15NRatio = AXNRATIOMEAN.RATIO
     Data14N15NRatioStd = AXNRATIOMEAN.RATIO_Stdev
     Data14N15NRatioError = AXNRATIOMEAN.RATIO_Error
     Data14N15NRatioAlts = AXNRATIOMEAN.Alt

   ;; Reduce the Data to the values above 1100 km

            RatioIndex = where( (Data14N15NRatioAlts ge 1125) and (Data14N15NRatioAlts le 1300) )
            NewData14N15NRatio = Data14N15NRatio[RatioIndex]
            NewData14N15NRatioStd = Data14N15NRatioStd[RatioIndex]
            NewData14N15NRatioError = Data14N15NRatioError[RatioIndex]
            NewData14N15NRatioAlts = Data14N15NRatioAlts[RatioIndex]

            NewDataArray = NewData14N15NRatio
            NewDataAlts = NewData14N15NRatioAlts

             oplot,NewDataArray, NewDataAlts, psym = 8, $
                 color = 5, thick = 4.0

        endif 

        if (iData eq 6) then begin

            DataSelected = 1

            restore, filename = 'Brian_CH4isoRatio_10km_bin.data'

            NewIndex = where((Bin_CH4isoRatio gt 0.0) and (Bin_Altitude ge 1100.0))

            NewDataCH4iso = Bin_CH4isoRatio[NewIndex]

            NewDataArray = NewDataCH4iso
            NewDataAlts = Bin_altitude[NewIndex]

           oplot,NewDataCH4iso, NewDataAlts, psym = 8, $
               color = 5, thick = 4.0

        endif 

        if (iData eq 7) then begin

           DataSelected = 1

           restore, filename = 'HotBinned_INMS_Data.save'

            AltMask = where(ModelBinCenters ge 1020.0)
            NewDataCH4Mix = IngressXCH4[AltMask]

            NewDataArray = NewDataCH4Mix
            NewDataAlts = ModelBinCenters[AltMask]

            Err_DatanCH4Mix = IngressXCH4_Error[AltMask]

           oplot,NewDataCH4Mix, NewDataAlts, psym = 8, $
               color = 5, thick = 4.0

            err_plot, NewDataAlts, $
                      NewDataCH4Mix - Err_DatanCH4Mix, $
                      NewDataCH4Mix + Err_DatanCH4Mix, $
                      width = 0.01, color = 5, thick = 2.0

        endif
      
        if (iData eq 8) then begin

           DataSelected = 1

           restore, filename = 'HotBinned_INMS_Data.save'

            AltMask = where(ModelBinCenters ge 1020.0)
            NewDataH2Mix = IngressXH2[AltMask]

            NewDataArray = NewDataH2Mix
            NewDataAlts = ModelBinCenters[AltMask]

            Err_DatanH2Mix = IngressXH2_Error[AltMask]

           oplot,NewDataH2Mix, NewDataAlts, psym = 8, $
               color = 5, thick = 4.0

            err_plot, NewDataAlts, $
                      NewDataH2Mix - Err_DatanH2Mix, $
                      NewDataH2Mix + Err_DatanH2Mix, $
                      width = 0.01, color = 5, thick = 2.0

        endif

        if (iData eq 9) then begin

            DataSelected = 1

     INMSDataFile = 'GITM_neutrals.sav'
     restore, INMSDataFile

     Data14N15N = AXN2IsoMean.Density*AACS*1.0e+06
     Data14N15NStd = AXN2IsoMean.density_Stdev*AACS*1.0e+06
     Data14N15NError = AXN2IsoMean.density_Error*AACS*1.0e+06
     Data14N15NAlts = AXN2IsoMean.Alt

   ;; Reduce the Data to the values above 1100 km

            IsoIndex = where( Data14N15NAlts ge 1100) 
            NewData14N15N = Data14N15N[IsoIndex]
            NewData14N15NStd = Data14N15NStd[IsoIndex]
            NewData14N15NError = Data14N15NError[IsoIndex]
            NewData14N15NAlts = Data14N15NAlts[IsoIndex]

            NewDataArray = NewData14N15N
            NewDataAlts = NewData14N15NAlts

             oplot,NewDataArray, NewDataAlts, psym = 8, $
                 color = 5, thick = 4.0


        endif 

        if (iData eq 10) then begin

            DataSelected = 1

            INMSDataFile = 'GITM_neutrals.sav'
            restore, INMSDataFile

            DatanCH4 = XCH4Mean.Density*AACS*1.0e+06
            Ratio13CH4 = XCRatioMean.Ratio
            Data13CH4Alts = XCRatioMean.Alt

            GoodIndex = where(Ratio13CH4 gt 0.0)


            Datan13CH4 = fltarr(n_elements(GoodIndex))
            Datan13CH4Alts = fltarr(n_elements(GoodIndex))

            for i = 0, n_elements(GoodIndex) - 1 do begin
               Datan13CH4[i] = DatanCH4[GoodIndex[i]]/Ratio13CH4[GoodIndex[i]]
               Datan13CH4Alts[i] = Data13CH4Alts[i]
            endfor
            IsoIndex = where( Datan13CH4Alts ge 1100) 

            NewData13CH4 = Datan13CH4[IsoIndex]
            NewData13CH4Alts = Datan13CH4Alts[IsoIndex]

            NewDataArray = NewData13CH4
            NewDataAlts = NewData13CH4Alts

             oplot,NewDataArray, NewDataAlts, psym = 8, $
                 color = 5, thick = 4.0


        endif 

       if (DataSelected eq 0) then begin
         print, 'Silly person, you no select correct Data!!'
       endif

      endif else begin
         print, 'No Data for You!!'
      endelse


    endif ;  Checking the iVars for N2, CH4, or Argon Mixing Ratio

   ; First, find the altitude locations of the bins in the model output

    if (DataSelected eq 1) then begin

       InterpolatedModelData = SPLINE(plotalts, plotvalue, NewDataAlts, /DOUBLE)

         Deviations = fltarr(n_elements(NewDataAlts))


         for i = 0, n_elements(NewDataAlts) - 1 do begin
              Deviations[i] = abs( InterpolatedModelData[i]  - NewDataArray[i])/NewDataArray[i]
         endfor

             CorrelationCoefModel = correlate( InterpolatedModelData, NewDataArray[*])
             PercentError = total(Deviations)/n_elements(Deviations)

     print, 'Model Percent Error:',PercentError
     print, 'Model Correlation Coefficient (Squared) :',CorrelationCoefModel^2.0

     print, '======================================= <> ================================================'
     print, '================== FLUXES THROUGH THE MODEL BOUNDARIES (RELATIVE TO SURFACE) =============='
     print, '======================================= <> ================================================'

;;     FluxIndexLower1 = nGCs  - 1 
;;     FluxIndexUpper1 = nAlts - nGCs  - 1 

        FluxIndexLower1 = 1
        FluxIndexUpper1 = nAlts - nGCs 


;;     FluxIndexLower1 = nGCs  - 1 + 10 
;;     FluxIndexLower2 = nGCs  - 1 

;;     FluxIndexUpper1 = nAlts  - nGCs - 1 
;;     FluxIndexUpper2 = nAlts  - nGCs - 1 

;;     FluxIndexLower1 = nGCs  - 1 + 10 
;;     FluxIndexUpper1 = nAlts  - nGCs - 1 

;; ================ H2 FlUXES
     print, 'H2 Upper Boundary Fluxes:', TimeAveData[iH2_,FluxIndexUpper1]*TimeAveData[iH2Vel_,FluxIndexUpper1]*((TimeAveData[2,FluxIndexUpper1] + 2575.0*1000.0 )/(2575.0*1000.0) )^2.0, $
             ' (1/m^2/s) ', $
             TimeAveData[iH2_,FluxIndexUpper1]*TimeAveData[iH2Vel_,FluxIndexUpper1]*4.0*!pi*(TimeAveData[2,FluxIndexUpper1] + 2575.0*1000.0)^2.0, $
             ' (molecules/s) ', $
             TimeAveData[iH2_,FluxIndexUpper1]*TimeAveData[iH2Vel_,FluxIndexUpper1]*2.0*4.0*!pi*(TimeAveData[2,FluxIndexUpper1] + 2575.0*1000.0)^2.0, $
             ' (amu/s) '

     print, 'H2 Lower Boundary Fluxes:', TimeAveData[iH2_,FluxIndexLower1]*TimeAveData[iH2Vel_,FluxIndexLower1]*((TimeAveData[2,FluxIndexLower1] + 2575.0*1000.0 )/(2575.0*1000.0) )^2.0, $
             ' (1/m^2/s) ', $
             TimeAveData[iH2_,FluxIndexLower1]*TimeAveData[iH2Vel_,FluxIndexLower1]*4.0*!pi*(TimeAveData[2,FluxIndexLower1] + 2575.0*1000.0)^2.0, $
             ' (molecules/s) ', $
             TimeAveData[iH2_,FluxIndexLower1]*TimeAveData[iH2Vel_,FluxIndexLower1]*2.0*4.0*!pi*(TimeAveData[2,FluxIndexLower1] + 2575.0*1000.0)^2.0, $
             ' (amu/s) '

;; ============= END H2 FLUXES

;; ================ CH4 FlUXES
     print, 'CH4 Upper Boundary Fluxes:', TimeAveData[iCH4_,FluxIndexUpper1]*TimeAveData[iCH4Vel_,FluxIndexUpper1]*((TimeAveData[2,FluxIndexUpper1] + 2575.0*1000.0 )/(2575.0*1000.0) )^2.0, $
             ' (1/m^2/s) ', $
             TimeAveData[iCH4_,FluxIndexUpper1]*TimeAveData[iCH4Vel_,FluxIndexUpper1]*4.0*!pi*(TimeAveData[2,FluxIndexUpper1] + 2575.0*1000.0)^2.0, $
             ' (molecules/s) ', $
             TimeAveData[iCH4_,FluxIndexUpper1]*TimeAveData[iCH4Vel_,FluxIndexUpper1]*16.0*4.0*!pi*(TimeAveData[2,FluxIndexUpper1] + 2575.0*1000.0)^2.0, $
             ' (amu/s) '

     print, 'CH4 Lower Boundary Fluxes:', TimeAveData[iCH4_,FluxIndexLower1]*TimeAveData[iCH4Vel_,FluxIndexLower1]*((TimeAveData[2,FluxIndexLower1] + 2575.0*1000.0 )/(2575.0*1000.0) )^2.0, $
             ' (1/m^2/s) ', $
             TimeAveData[iCH4_,FluxIndexLower1]*TimeAveData[iCH4Vel_,FluxIndexLower1]*4.0*!pi*(TimeAveData[2,FluxIndexLower1] + 2575.0*1000.0)^2.0, $
             ' (molecules/s) ', $
             TimeAveData[iCH4_,FluxIndexLower1]*TimeAveData[iCH4Vel_,FluxIndexLower1]*16.0*4.0*!pi*(TimeAveData[2,FluxIndexLower1] + 2575.0*1000.0)^2.0, $
             ' (amu/s) '

;; ============= END CH4 FLUXES

;; ================ N2 FlUXES
     print, 'N2 Upper Boundary Fluxes:', TimeAveData[iN2_,FluxIndexUpper1]*TimeAveData[iN2Vel_,FluxIndexUpper1]*((TimeAveData[2,FluxIndexUpper1] + 2575.0*1000.0 )/(2575.0*1000.0) )^2.0, $
             ' (1/m^2/s) ', $
             TimeAveData[iN2_,FluxIndexUpper1]*TimeAveData[iN2Vel_,FluxIndexUpper1]*4.0*!pi*(TimeAveData[2,FluxIndexUpper1] + 2575.0*1000.0)^2.0, $
             ' (molecules/s) ', $
             TimeAveData[iN2_,FluxIndexUpper1]*TimeAveData[iN2Vel_,FluxIndexUpper1]*28.0*4.0*!pi*(TimeAveData[2,FluxIndexUpper1] + 2575.0*1000.0)^2.0, $
             ' (amu/s) '

     print, 'N2 Lower Boundary Fluxes:', TimeAveData[iN2_,FluxIndexLower1]*TimeAveData[iN2Vel_,FluxIndexLower1]*((TimeAveData[2,FluxIndexLower1] + 2575.0*1000.0 )/(2575.0*1000.0) )^2.0, $
             ' (1/m^2/s) ', $
             TimeAveData[iN2_,FluxIndexLower1]*TimeAveData[iN2Vel_,FluxIndexLower1]*4.0*!pi*(TimeAveData[2,FluxIndexLower1] + 2575.0*1000.0)^2.0, $
             ' (molecules/s) ', $
             TimeAveData[iN2_,FluxIndexLower1]*TimeAveData[iN2Vel_,FluxIndexLower1]*28.0*4.0*!pi*(TimeAveData[2,FluxIndexLower1] + 2575.0*1000.0)^2.0, $
             ' (amu/s) '

;; ============= END N2 FLUXES

     print, '======================================= <> ================================================'
     print, '================== FLUXES THROUGH THE MODEL BOUNDARIES (RELATIVE TO SURFACE) =============='
     print, '======================================= <> ================================================'

;    print, Alts[nGCs -1 + 10]
;    print, Alts[nGCs -1 + 11]
;
;    print, Alts[nAlts - nGCs - 6]
;    print, Alts[nAlts - nGCs - 5]

;     print, DataArray
;    print, ModelAltCntr
;    print, plotalts[ModelAltCntr]
;    print, Bin_altitude[*]

; Next, perform a least-squares analysis on the profiles



    endif

end
