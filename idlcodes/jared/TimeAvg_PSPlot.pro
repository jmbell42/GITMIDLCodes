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

  nN2 = TimeAveData[5,*]
  nCH4 = TimeAveData[6,*]
  Temp = TimeAveData[4,*]


;Filled Circles
         phi = findgen(32)*(!PI*2/32.)

         phi = [phi, phi(0)]

          usersym, cos(phi), sin(phi), /fill 
; end Filled Circles


; N2 Data Restore

           restore, filename = '/Users/jbell/INMSDataRepository/GlobalAverageData/Brian_N2_10km_bin.data'

           oplot,Bin_N2Density*1.0e+06, Bin_altitude, psym = 8, $
               color = 5, thick = 4.0

           err_plot, Bin_altitude, $
                     (Bin_N2Density - Bin_N2DensityError)*1.0e+06, $
                     (Bin_N2Density + Bin_N2DensityError)*1.0e+06, $
                     width = 0.01, color = 5, thick = 2.0

            DataArrayN2 = fltarr(n_elements(Bin_N2Density))
            DataAltsN2 = fltarr(n_elements(Bin_N2Density))
 
            DataArrayN2 = Bin_N2Density*1.0e+06
            DataAltsN2 = Bin_altitude

            LogDataArrayN2 = alog(DataArrayN2)
            LogDataFitN2 = GAUSSFIT (DataAltsN2,LogDataArrayN2, A)
            DataFitN2 = exp(LogDataFitN2)   ; Non-Linear Least-Squares Fit

; CH4 Data Restore

           restore, filename = '/Users/jbell/INMSDataRepository/GlobalAverageData/Brian_CH4_10km_bin.data'
           oplot,Bin_CH4Density*1.0e+06, Bin_altitude, psym = 8, $
               color = 5, thick = 4.0

           err_plot, Bin_altitude, $
                     (Bin_CH4Density - Bin_CH4DensityError)*1.0e+06, $
                     (Bin_CH4Density + Bin_CH4DensityError)*1.0e+06, $
                     width = 0.01, color = 5, thick = 2.0

            DataArrayCH4 = fltarr(n_elements(Bin_CH4Density))
            DataAltsCH4 = fltarr(n_elements(Bin_CH4Density))
 
            DataArrayCH4 = Bin_CH4Density * 1.0e+06
            DataAltsCH4 = Bin_altitude

            LogDataArrayCH4 = alog(DataArrayCH4)
            LogDataFitCH4 = GAUSSFIT (DataAltsCH4,LogDataArrayCH4, A)
            DataFitCH4 = exp(LogDataFitCH4)   ; Non-Linear Least-Squares Fit

         ;  oplot,DataFit, DataAlts,$
         ;      color = 14, thick = 4.0


      MinData = min(DataArrayCH4)
      MinData = MinData < min(DataArrayN2)
      MinData = MinData < min(nCH4)
      MinData = MinData < min(nN2)

      MaxData = max(DataArrayCH4)
      MaxData = MaxData > max(DataArrayN2)
      MaxData = MaxData > max(nCH4)
      MaxData = MaxData > max(nN2)

      MinData = 1e10
      MaxData = 1e19

      plot, nN2, Alts, $
          xrange = [MinData, MaxData], $
          yrange = [min(Alts), max(Alts)], $
          ystyle = 4, xstyle = 4, /XLOG, background = 7, $
          color =0, thick = 2.0, /nodata

      axis, yaxis = 0, yrange = [min(Alts), max(Alts)], ticklen = 0.04, ystyle = 1, color = 0, $
            ythick = 2.0, charthick = 2.0, charsize = 2.0
      axis, yaxis = 1, yrange = [min(Alts), max(Alts)], ticklen = 0.04, ystyle = 1, color = 0, $
              ytickname = replicate(' ', 10), ythick = 2.0, charsize = 2.0

      axis, xaxis = 0, xrange = [MinData, MaxData], ticklen = 0.04, xstyle = 1, color = 0, $
             xthick = 2.0, charthick = 2.0, charsize = 2.0
      axis, xaxis = 1, xrange = [MinData, MaxData], ticklen = 0.04, xstyle = 1, color = 0, $
              xtickname = replicate(' ', 10), xthick = 2.0, charsize = 2.0


      oplot, nN2, Alts, color = 0, thick = 4.0
      oplot, nCH4, Alts, color = 0, thick = 4.0

       oplot, DataArrayCH4, DataAltsCH4,  psym = 8, color = 14, thick = 4.0
       oplot, DataFitCH4, DataAltsCH4,  color = 5, thick = 4.0
       oplot, DataArrayN2, DataAltsN2,  psym = 8, color = 14, thick = 4.0
       oplot, DataFitN2, DataAltsN2,  color = 5, thick = 4.0

       label_N2xpos = 0.60
       label_N2ypos = 0.55

       label_CH4xpos = 0.33
       label_CH4ypos = 0.55

       labelN2text = 'N!D2'
       labelCH4text = 'CH!D4'

       xyouts, label_N2xpos, label_N2ypos, labelN2text, /normal, $
           color = 0, charsize = 2.0, charthick = 2.0

       xyouts, label_CH4xpos, label_CH4ypos, labelCH4text, /normal, $
           color = 0, charsize = 2.0, charthick = 2.0

      xaxis_xpos = 0.45
      xaxis_ypos = 0.00

      xaxis_text = 'Density (m!U-3!N)'

      yaxis_xpos = 0.00
      yaxis_ypos = 0.45

      yaxis_text = 'Altitude (km) '


       xyouts, xaxis_xpos, xaxis_ypos, xaxis_text, /normal, $
          color = 0, charsize = 2.0, charthick = 2.0

       xyouts, yaxis_xpos, yaxis_ypos, yaxis_text, /normal, $
          color = 0, charsize = 2.0, charthick = 2.0, $
          orientation = 90.0


   pson, filename = 'TimeAvgDensities.ps', margin = 1.00, /quiet

      plot, nN2, Alts, $
          xrange = [MinData, MaxData], $
          yrange = [min(Alts), max(Alts)], $
          ystyle = 4, xstyle = 4, /XLOG, background = 7, $
          color =0, thick = 2.0, /nodata

      axis, yaxis = 0, yrange = [min(Alts), max(Alts)], ticklen = 0.04, ystyle = 1, color = 0, $
            ythick = 2.0, charthick = 2.0, charsize = 2.0
      axis, yaxis = 1, yrange = [min(Alts), max(Alts)], ticklen = 0.04, ystyle = 1, color = 0, $
              ytickname = replicate(' ', 10), ythick = 2.0, charsize = 2.0

      axis, xaxis = 0, xrange = [MinData, MaxData], ticklen = 0.04, xstyle = 1, color = 0, $
             xthick = 2.0, charthick = 2.0, charsize = 2.0
      axis, xaxis = 1, xrange = [MinData, MaxData], ticklen = 0.04, xstyle = 1, color = 0, $
              xtickname = replicate(' ', 10), xthick = 2.0, charsize = 2.0


      oplot, nN2, Alts, color = 0, thick = 4.0
      oplot, nCH4, Alts, color = 0, thick = 4.0

       oplot, DataArrayCH4, DataAltsCH4,  psym = 8, color = 14, thick = 4.0
       oplot, DataFitCH4, DataAltsCH4,  color = 5, thick = 4.0
       oplot, DataArrayN2, DataAltsN2,  psym = 8, color = 14, thick = 4.0
       oplot, DataFitN2, DataAltsN2,  color = 5, thick = 4.0

       label_N2xpos = 0.60
       label_N2ypos = 0.55

       label_CH4xpos = 0.33
       label_CH4ypos = 0.55

       labelN2text = 'N!D2'
       labelCH4text = 'CH!D4'

       xyouts, label_N2xpos, label_N2ypos, labelN2text, /normal, $
           color = 0, charsize = 2.0, charthick = 2.0

       xyouts, label_CH4xpos, label_CH4ypos, labelCH4text, /normal, $
           color = 0, charsize = 2.0, charthick = 2.0

      xaxis_xpos = 0.45
      xaxis_ypos = -0.03

      xaxis_text = 'Density (m!U-3!N)'

      yaxis_xpos = -0.015
      yaxis_ypos = 0.45

      yaxis_text = 'Altitude (km) '


       xyouts, xaxis_xpos, xaxis_ypos, xaxis_text, /normal, $
          color = 0, charsize = 2.0, charthick = 2.0

       xyouts, yaxis_xpos, yaxis_ypos, yaxis_text, /normal, $
          color = 0, charsize = 2.0, charthick = 2.0, $
          orientation = 90.0

   psoff, /quiet


end
