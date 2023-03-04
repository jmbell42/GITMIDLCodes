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


GetNewData = 1
fpi = 0

filelist_new = findfile("*.3DALL")
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

;            if (iVar eq 5) then begin
;              plotvalue = 0.25*value[nGcs-1:nAlts-nGcs-1]
;            endif else begin
;              plotvalue = value[nGcs-1:nAlts-nGcs-1]
;            endelse
;
;            if (iVar eq 6) then begin
;              plotvalue = 0.25*value[nGcs-1:nAlts-nGcs-1]
;            endif else begin
;               plotvalue = value[nGcs-1:nAlts-nGcs-1]
;            endelse
;
;            if (iVar eq 9) then begin
;               plotvalue = 2.00*value[nGcs-1:nAlts-nGcs-1]
;            endif else begin
;               plotvalue = value[nGcs-1:nAlts-nGcs-1]
;            endelse

            plotvalue = value[nGcs-1:nAlts-nGcs-1]
            plotalts = Alts[nGcs-1:nAlts-nGcs-1]
       plot, plotvalue, plotalts, $
             background = 7, color = 0, thick = 2.0, $
             xrange = [min(plotvalue), max(plotvalue)], xstyle = 1, $
             yrange = [min(plotAlts), max(plotAlts)], ystyle = 1, /XLOG
    endif else begin
            plotvalue = value[nGcs-1:nAlts-nGcs-1]
            plotalts = Alts[nGcs-1:nAlts-nGcs-1]
       plot, plotvalue, plotalts, $
             background = 7, color = 0, thick = 2.0, $
             xrange = [min(plotvalue), max(plotvalue)], xstyle = 1, $
             yrange = [min(plotalts), max(plotalts)], ystyle = 1

    endelse



   if ( (iVar eq 5) or (iVar eq 6) or (iVar eq 17) or (iVar eq 9) ) then begin

   
       DataSelected = 0
       DataAsk = ask('Would you like to plot INMS Data? [y/n]', 'y')

      if (strpos(mklower(DataAsk),'y') eq 0) then begin  ; Data is desired

       iData = 1

       if ( (iVar eq 5) ) then begin
           iData = 1
       endif
       if ( (iVar eq 6) ) then begin
           iData = 2
       endif
       if ( (iVar eq 17) ) then begin
           iData = 3
       endif
       if ( (iVar eq 9) ) then begin
           iData = 4
       endif

;        print, 'Data Value Selected ', iData

;Filled Circles
         phi = findgen(32)*(!PI*2/32.)

         phi = [phi, phi(0)]

          usersym, cos(phi), sin(phi), /fill 
; end Filled Circles

        if (iData eq 1) then begin
     
           DataSelected = 1

; Jared's Binned Data
;           restore, filename = 'GlobalAverageINMSMajors.data'
;           oplot, BinData_nN2, BinDataAlts, psym = 8, color = 5
;           oplot, SmoothDataN2, BinDataAlts, linestyle = 2, thick = 4.0

           restore, filename = 'Brian_N2_10km_bin.data'

           oplot,Bin_N2Density*1.0e+06, Bin_altitude, psym = 8, $
               color = 5, thick = 4.0

           err_plot, Bin_altitude, $
                     (Bin_N2Density - Bin_N2DensityError)*1.0e+06, $
                     (Bin_N2Density + Bin_N2DensityError)*1.0e+06, $
                     width = 0.01, color = 5, thick = 2.0

            DataArray = fltarr(n_elements(Bin_N2Density))
            DataAlts = fltarr(n_elements(Bin_N2Density))
 
            DataArray = Bin_N2Density*1.0e+06
            DataAlts = Bin_altitude

         

            LogDataArray = alog(DataArray)
            LogDataFit = GAUSSFIT (DataAlts,LogDataArray, A)
            DataFit = exp(LogDataFit)   ; Non-Linear Least-Squares Fit

           oplot,DataFit, DataAlts,$
               color = 14, thick = 4.0

;            window, 1, title = 'Least Squares Fit to N2'
;
;            plot, DataArray, DataAlts, /XLOG, psym = 8
;            oplot, DataFit, DataAlts
            

        endif
        if (iData eq 2) then begin

           DataSelected = 1

; Jared's Binned Data
;           restore, filename = 'GlobalAverageINMSMajors.data'
;           oplot, BinData_nCH4, BinDataAlts, psym = 8, color = 5
;           oplot, SmoothDataCH4, BinDataAlts, linestyle = 2, thick = 4.0

           restore, filename = 'Brian_CH4_10km_bin.data'
           oplot,Bin_CH4Density*1.0e+06, Bin_altitude, psym = 8, $
               color = 5, thick = 4.0

           err_plot, Bin_altitude, $
                     (Bin_CH4Density - Bin_CH4DensityError)*1.0e+06, $
                     (Bin_CH4Density + Bin_CH4DensityError)*1.0e+06, $
                     width = 0.01, color = 5, thick = 2.0

            DataArray = fltarr(n_elements(Bin_CH4Density))
            DataAlts = fltarr(n_elements(Bin_CH4Density))
 
            DataArray = Bin_CH4Density * 1.0e+06
            DataAlts = Bin_altitude

            LogDataArray = alog(DataArray)
            LogDataFit = GAUSSFIT (DataAlts,LogDataArray, A)
            DataFit = exp(LogDataFit)   ; Non-Linear Least-Squares Fit

           oplot,DataFit, DataAlts,$
               color = 14, thick = 4.0

        endif

        if (iData eq 3) then begin

; Jared's Binned Data
;           restore, filename = 'GlobalAverageArgon.data'
;           oplot, BinData_Ar_Mixing, BinDataAltsAr, linestyle = 1
;           oplot, SmoothDataAr, BinDataAltsAr, linestyle = 2, thick = 4.0


           DataSelected = 1

           restore, filename = 'Brian_ArgonMixing_10km_bin.data'


            NewIndex = where( (Bin_ArMix gt 0.0) and (Bin_altitude le 1200.0))

;           print, NewIndex

            NewDataAr = Bin_ArMix[NewIndex]
            NewDataAlts = Bin_altitude[NewIndex]
            NewArError = Bin_ArMixError[NewIndex]
            NewArErrorLow = NewDataAr - NewArError
            NewArErrorHigh = NewDataAr + NewArError

            for i = 1, n_elements(NewArErrorLow) do begin
            NewArErrorLow[i-1] = 1.0e-9 > NewArErrorLow[i-1]
            endfor
            

;print, NewArError

           oplot,NewDataAr, NewDataAlts, psym = 8, $
               color = 5, thick = 4.0

;           err_plot, NewDataAlts, $
;                     NewDataAr - Bin_ArMixError[NewIndex], $
;                     NewDataAr + Bin_ArMixError[NewIndex], $
;                     width = 0.01, color = 5, thick = 2.0

           err_plot, NewDataAlts, $
                     NewArErrorLow , $
                     NewArErrorHigh, $
                     width = 0.01, color = 5, thick = 2.0

            DataArray = fltarr(n_elements(NewDataAr))
            DataAlts = fltarr(n_elements(NewDataAr))
 
            DataArray = NewDataAr
            DataAlts = NewDataAlts

            LogDataArray = alog(DataArray)
            LogDataFit = GAUSSFIT (DataAlts,LogDataArray, A)
            DataFit = exp(LogDataFit)   ; Non-Linear Least-Squares Fit

                  
           oplot,DataFit, DataAlts,$
               color = 14, thick = 4.0

        endif

        if (iData eq 4) then begin

           DataSelected = 1

; Jared's Binned Data
;           restore, filename = 'GlobalAverageINMSMajors.data'
;           oplot, BinData_nCH4, BinDataAlts, psym = 8, color = 5
;           oplot, SmoothDataCH4, BinDataAlts, linestyle = 2, thick = 4.0

           restore, filename = 'Brian_H2_10km_bin.data'
           oplot,Bin_H2Density*1.0e+06, Bin_altitude, psym = 8, $
               color = 5, thick = 4.0

           err_plot, Bin_altitude, $
                     (Bin_H2Density - Bin_H2DensityError)*1.0e+06, $
                     (Bin_H2Density + Bin_H2DensityError)*1.0e+06, $
                     width = 0.01, color = 5, thick = 2.0

            DataArray = fltarr(n_elements(Bin_H2Density))
            DataAlts = fltarr(n_elements(Bin_H2Density))
 
            DataArray = Bin_H2Density * 1.0e+06
            DataAlts = Bin_altitude

            LogDataArray = alog(DataArray)
            LogDataFit = GAUSSFIT (DataAlts,LogDataArray, A)
            DataFit = exp(LogDataFit)   ; Non-Linear Least-Squares Fit

           oplot,DataFit, DataAlts,$
               color = 14, thick = 4.0

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

       DeltaAlt = fltarr(n_elements(plotalts))            ; The numberof model alts
       ModelAltCntr = fltarr(n_elements(DataAlts))   ; The numberof data alts
   
       for i = 0, n_elements(DataAlts) - 1 do begin
         ; First calculate DeltaAlt for each model altitude
                DeltaAlt[*] = 0.0

            for j = 0, n_elements(plotalts) - 1 do begin
                DeltaAlt[j] = abs(plotalts[j] -  DataAlts[i])
            endfor

               MinDeltaAlt = min(DeltaAlt[*],MinAltIndex) 

            ModelAltCntr[i] = MinAltIndex

       endfor
;   Next, calculate the % deviation between the model and the data
;   along the subset of altitudes.

         Deviations = fltarr(n_elements(DataAlts))

         RMSDeviations = fltarr(n_elements(DataAlts))
         RMSData = fltarr(n_elements(DataAlts))
         NRMS = fltarr(n_elements(DataAlts))

         LSDeviations = fltarr(n_elements(DataAlts))
         LSRMSDeviations = fltarr(n_elements(DataAlts))
         LSRMSData = fltarr(n_elements(DataAlts))
         LSNRMS = fltarr(n_elements(DataAlts))

         for i = 0, n_elements(DataAlts) - 1 do begin
              Deviations[i] = abs( plotvalue[ModelAltCntr[i]] - DataArray[i])/DataArray[i]

              RMSDeviations[i] = ( plotvalue[ModelAltCntr[i]] - DataArray[i])^2.0

              RMSData[i] = (DataArray[i])^2.0

              LSDeviations[i] = abs( DataFit[i] - DataArray[i])/DataArray[i]
              LSRMSDeviations[i] = ( DataFit[i] - DataArray[i])^2.0

         endfor

             CorrelationCoefModel = correlate( plotvalue[ModelAltCntr[*]], DataArray[*])
             CorrelationCoefLeast = correlate( DataFit[*], DataArray[*])

             PercentError = total(Deviations)/n_elements(Deviations)
             NRMSError = sqrt( total(RMSDeviations) )/ sqrt( total(RMSData))

             LSPercentError = total(LSDeviations)/n_elements(LSDeviations)
             LSNRMSError = sqrt( total(LSRMSDeviations) )/ sqrt( total(RMSData))

     print, 'Model Percent Error:',PercentError,'        Least Squares Error:',LSPercentError
     print, 'Model NRMSE Error:',NRMSError,'        Least Squares NRMS Error:',LSNRMSError

     print, 'Model Correlation Coefficient (Squared) :',CorrelationCoefModel^2.0
     print, 'Least Squares Correlation Coefficient (Squared) :',CorrelationCoefLeast^2.0

;     print, DataArray
;    print, ModelAltCntr
;    print, plotalts[ModelAltCntr]
;    print, Bin_altitude[*]

; Next, perform a least-squares analysis on the profiles



    endif

end
