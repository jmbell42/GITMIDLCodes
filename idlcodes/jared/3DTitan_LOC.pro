

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

filelist = findfile("-t "+"/*.save")
if (strlen(filelist(0)) eq 0) then filelist = findfile("-t *.save")


filelist = ask('filename to plot',filelist(0))
filelist = findfile(filelist)
nfiles = n_elements(filelist)
iFile = nFiles-1


    filename = filelist(iFile)

    read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
      vars, data, rb, cb, bl_cnt

    longitude = reform(data(0,*,*,*))/ !dtor
    latitude = reform(data(1,*,*,*)) / !dtor
    altitude = reform(data(2,*,*,*)) / 1000.0
    localtime = reform(data(3,*,*,*)) 

    alt = altitude(1,1,*)
    lat = latitude(1,*,1)
    lon = longitude(*,1,1)
    slt = localtime(*,1,1)

    for i=0,nvars-1 do print, tostr(i)+'. '+vars(i)
    sel = fix(ask('which var to plot','9'))

    plotlog = ask('whether you want log or not (y/n)','n')
    if (strpos(plotlog,'y') eq 0) then plotlog = 1 else plotlog = 0

    print, '1. Plot at a Single Geographic Location '
    print, '2. Plot of a Globally Averaged Quantity'
    print, '3. Plot at a Specific Local Time'

    slice = fix(ask('type of plot to make','1'))

; cntr is the number of selections made
    cntr = 1
    plotarr = fltarr(nvars,nalts-4)

; selarr is an array of selection indicies.
; selarr is used for the multiplots later.

    selarr = fltarr(cntr)
    selarr[0] = sel
        


    if (slice eq 1) then begin

        for i=2,nlons-3 do print, tostr(i)+'. '+string(lon(i))
        lonset = fix(ask('which longitude to plot','0'))

        for i=2,nlats-3 do print, tostr(i)+'. '+string(lat(i))
        latset = fix(ask('which latitude to plot','0'))

        maxd = max(reform(data(sel,lonset,latset,2:nalts-3)))*(1.05)
        mind = min(reform(data(sel,lonset,latset,2:nalts-3)))*(.95)

        maxa = max(alt(2:nalts-3))*1.05
        mina = min(alt(2:nalts-3))*.95

        if (plotlog eq 1) then begin
        plot, data(sel,lonset,latset,2:nalts-3), alt(2:nalts-3), $
             title ='Logarithmic Plot of'+vars(sel)+' versus Altitude', $
             subtitle ='Latitude: ' + string(lat(latset))+ '     Longitude:' +string(lon(lonset)), $
             /XLOG,  $
             ytitle = 'Altitude (km)', $
             xtitle = vars(sel), $
             yrange = [mina,maxa], $
             xrange = [mind,maxd], $ 
             xstyle = 1, $
             ystyle = 1, $
             background = 7, color = 0
        
        endif

        if (plotlog eq 0) then begin
        plot, data(sel,lonset,latset,2:nalts-3), alt(2:nalts-3), $
             title ='Linear Plot of'+vars(sel)+' versus Altitude', $
             subtitle ='Latitude: ' + string(lat(latset))+ '     Longitude:' +string(lon(lonset)), $
             ytitle = 'Altitude (km)', $
             xtitle = vars(sel),  $
             yrange = [mina,maxa], $
             xrange = [mind,maxd],  $ 
             xstyle = 1, $
             ystyle = 1, $ 
             background = 7, color = 0
        endif

        plotarr[cntr - 1,*] = data(sel,lonset,latset,2:nalts-3)

    endif  ; Case Slice = 1


    if (slice eq 2) then begin

           LonAveData = fltarr(nlats-4,nalts-4)  
           SData = fltarr(nlats-4,nalts-4)  
           AveData = fltarr(nalts-4)  

           LonAveData  = total(data(sel,2:nlons-3,2:nlats-3,2:nalts-3), 2) / (nlons - 4)

;\
; Gets rid of the extraneous 1-dimension created by total above
; by using the reform statement.
;/
           LonAveData = reform(LonAveData)


; Cosine weighting function in Latitude

           scos = fltarr(nlats-4) 
           scos = cos(lat(*)*!dtor)

; The summation of our weighting function in Latitude

           sumcos = total(scos(2:nlats-3),1) 

           for i = 2,nlats-3 do begin
               j = i - 2
               SData(j,0:nalts-5) = (cos(lat(i)*!dtor)*LonAveData(j,0:nalts-5))/sumcos               
           endfor

           ;print, size(SData,/dimensions)

           AveData  = total(SData(0:nlats-5,0:nalts-5), 1)

           AveData = reform(AveData)

          maxd = max( Avedata(0:nalts-5) )*1.05
          mind = min( Avedata(0:nalts-5) )*.95

          maxa = max(alt(2:nalts-3))*1.05
          mina = min(alt(2:nalts-3))*.95

        if (plotlog eq 1) then begin
        plot, Avedata(*), alt(2:nalts-3), $
             title ='Global Average Logarithmic Plot of'+vars(sel)+' versus Altitude', $
             /XLOG,  $
             ytitle = 'Altitude (km)', $
             xtitle = vars(sel), $
             yrange = [mina,maxa], $
             xrange = [mind,maxd], $ 
             xstyle = 1, $
             ystyle = 1, $ 
             background = 7, color = 0
        endif

        if (plotlog eq 0) then begin

        plot, Avedata(*), alt(2:nalts-3), $
             title ='Global Average Linear Plot of'+vars(sel)+' versus Altitude', $
             ytitle = 'Altitude (km)', $
             xtitle = vars(sel),  $
             yrange = [mina,maxa], $
             xrange = [mind,maxd], $ 
             xstyle = 1, $
             ystyle = 1, $ 
             background = 7, color = 0

        endif

        plotarr[cntr - 1,*] = Avedata(*)

   endif ; end case eq 2

    if (slice eq 3) then begin

            for i=2,nlons-3 do print, tostr(i)+'. '+string(slt(i))
            sltset = fix(ask('which solar local time to plot','0'))

            for i=2,nlats-3 do print, tostr(i)+'. '+string(lat(i))
            latset = fix(ask('which latitude to plot','0'))



        maxd = max(reform(data(sel,sltset,latset,2:nalts-3)))*(1.05)
        mind = min(reform(data(sel,sltset,latset,2:nalts-3)))*(.95)

        maxa = max(alt(2:nalts-3))*1.05
        mina = min(alt(2:nalts-3))*.95

        if (plotlog eq 1) then begin
        plot, data(sel,sltset,latset,2:nalts-3), alt(2:nalts-3), $
             title ='Logarithmic Plot of'+vars(sel)+' versus Altitude', $
             subtitle ='Latitude: ' + string(lat(latset))+ '     Solar Local Time:' +string(slt(sltset)), $
             /XLOG,  $
             ytitle = 'Altitude (km)', $
             xtitle = vars(sel), $
             yrange = [mina,maxa], $
             xrange = [mind,maxd], $ 
             xstyle = 1, $
             ystyle = 1, $ 
             background = 7, color = 0
        endif

        if (plotlog eq 0) then begin
        plot, data(sel,sltset,latset,2:nalts-3), alt(2:nalts-3), $
             title ='Linear Plot of'+vars(sel)+' versus Altitude', $
             subtitle ='Latitude: ' + string(lat(latset))+ '     Solar Local Time:' +string(slt(sltset)), $
             ytitle = 'Altitude (km)', $
             xtitle = vars(sel),  $
             yrange = [mina,maxa], $
             xrange = [mind,maxd],  $ 
             xstyle = 1, $
             ystyle = 1, $ 
             background = 7, color = 0
        endif

        plotarr[cntr - 1,*] = data(sel,sltset,latset,2:nalts-3)

     endif ; Slice eq 3



     multi = ask('Multiple Plots on the Same Image ?  (y/n)','n')
     if (strpos(multi,'y') eq 0) then multiplot = 1 else multiplot = 0

	     while (multiplot eq 1) do begin

; add another choice to the counter
     		cntr = cntr + 1 

     		for i=0,nvars-1 do print, tostr(i)+'. '+vars(i)
     		sel = fix(ask('which var to plot','9'))

     		plotlog = ask('whether you want log or not (y/n)','n')
     		if (strpos(plotlog,'y') eq 0) then plotlog = 1 else plotlog = 0


      		print, '1. Plot at a Single Geographic Location '
       		print, '2. Plot of a Globally Averaged Quantity'
       		print, '3. Plot at a Specific Local Time'

        	slice = fix(ask('type of plot to make','1'))

	    	if (slice eq 1) then begin
	
       	     	for i=2,nlons-3 do print, tostr(i)+'. '+string(lon(i))
                lonset = fix(ask('which longitude to plot','0'))

       	     	for i=2,nlats-3 do print, tostr(i)+'. '+string(lat(i))
       	        latset = fix(ask('which latitude to plot','0'))



       	 	maxd = max(reform(data(sel,lonset,latset,2:nalts-3)))*(1.05)
       	 	mind = min(reform(data(sel,lonset,latset,2:nalts-3)))*(.95)

       	 	maxa = max(alt(2:nalts-3))*1.05
       	 	mina = min(alt(2:nalts-3))*.95


                plotarr[cntr - 1,*] = data(sel,lonset,latset,2:nalts-3)

    	endif ;  Case Slice = 1


    if (slice eq 2) then begin

              LonAveData = fltarr(nlats-4,nalts-4)  
              SData = fltarr(nlats-4,nalts-4)  
              AveData = fltarr(nalts-4)  

              LonAveData  = total(data(sel,2:nlons-3,2:nlats-3,2:nalts-3), 2) / (nlons - 4)

;\
; Gets rid of the extraneous 1-dimension created by total above
; by using the reform statement.
;/
              LonAveData = reform(LonAveData)


; Cosine weighting function in Latitude

              scos = fltarr(nlats-4) 
              scos = cos(lat(*)*!dtor)

; The summation of our weighting function in Latitude

              sumcos = total(scos(2:nlats-3),1) 

              for i = 2,nlats-3 do begin
                  j = i - 2
                  SData(j,0:nalts-5) = (cos(lat(i)*!dtor)*LonAveData(j,0:nalts-5))/sumcos               
              endfor

               AveData  = total(SData(0:nlats-5,0:nalts-5), 1)


               AveData = reform(AveData)

               maxd = max( Avedata(0:nalts-5) )*1.05
               mind = min( Avedata(0:nalts-5) )*.95

               maxa = max(alt(2:nalts-3))*1.05
	       mina = min(alt(2:nalts-3))*.95

               plotarr[cntr - 1,*] = Avedata(*)

   endif ; end case eq 2

    if (slice eq 3) then begin

              for i=2,nlons-3 do print, tostr(i)+'. '+string(slt(i))
              sltset = fix(ask('which solar local time to plot','0'))

              for i=2,nlats-3 do print, tostr(i)+'. '+string(lat(i))
              latset = fix(ask('which latitude to plot','0'))



               maxd = max(reform(data(sel,sltset,latset,2:nalts-3)))*(1.05)
               mind = min(reform(data(sel,sltset,latset,2:nalts-3)))*(.95)

               maxa = max(alt(2:nalts-3))*1.05
               mina = min(alt(2:nalts-3))*.95

               plotarr[cntr - 1,*] = data(sel,sltset,latset,2:nalts-3)

     endif ; Slice eq 3
;\
; Begin Plotting The variables
;/

        maxd = max(plotarr[0:cntr-1,*])*(1.05)
        mind = min(plotarr[0:cntr-1,*])*(0.95)
        maxa = max(alt(2:nalts-3))*1.05
        mina = min(alt(2:nalts-3))*.95

        deltaalt = maxa-mina
        spacing = 25 ; 25 km
        yticknum = floor(deltaalt/spacing) + 1
         
       
        if (plotlog eq 0) then begin

           deltax = maxd-mind
           xticknum = 25 

           plot, plotarr[0,*], alt[2:nalts-3], $
           /nodata, $
           /noclip, $
           xrange = [mind,maxd], $
           yrange = [mina,maxa], $
           xstyle = 1, $
           ystyle = 1, $
           ytitle = 'Altitude (km)', $
           background = 7, color = 0
;           background = 7, color = 0, $
;           xticks = xticknum,      $
;           yticks = yticknum

           cnt = cntr - 1

           for i = 0,cnt do begin

             oplot, plotarr[i,*], alt(2:nalts-3), $
             color = i

           endfor
        endif

        if (plotlog eq 1) then begin

           deltax = alog(maxd)-alog(mind)
           xticknum = 25 

           plot, plotarr[0,*], alt[2:nalts-3], $
           /nodata, $
           /noclip, $
           /XLOG, $
           xrange = [mind,maxd], $
           yrange = [mina,maxa], $
           xstyle = 1, $
           ystyle = 1, $
           ytitle = 'Altitude (km)',$
           background = 7, color = 0
;           background = 7, color = 0, $
;           xtickformat = '(e6.3)', $ 
;           xticks = xticknum,      $
;           yticks = yticknum

           cnt = cntr - 1

           for i = 0,cnt do begin

             oplot, plotarr[i,*], alt(2:nalts-3), $
             color = i

           endfor
        endif

        multi = ask('Multiple Plots on the Same Image ?  (y/n)','n')
        if (strpos(multi,'y') eq 0) then multiplot = 1 else multiplot = 0

       endwhile

; \
; Comparison Sequence with Cassini Data
; /
        compask = ask('Would you like to overplot Cassini TA data  (y/n)','n')
        if (strpos(compask,'y') eq 0) then compplot = 1 else compplot = 0

        if (compplot eq 1) then begin

           print, 'Reading in the TA save file' 
           restore, 'Cassini500km.dat' 

           print, 'Reading in the INMS Ingress save file' 
           restore, 'INMS.dat' 

           test = data.(0)
; \
; "test" now has the Cassini Data in it!
; 14 fields
; (0) = altitude, (1) Temperature
; (2) = nH,   (3) nH2,   (4) nCH, 
; (5) n1CH2,  (6) 3CH2,  (7) nCH3,
; (8) = nCH4, (9) nC2H4, (10) nN4S, 
; (11) nN2,   (12) nHCN, (13) nH2CN
; /

          CTemperature = test(1,*)
          CnN2 = test(11,*)*(0.45e06)   ; Converts from cm^-3 to m^-3 also scaled to ingress values only
          CnCH4 = test(8,*)*(0.20e06)  ; Converts from cm^-3 to m^-3 also scaled to ingress values only

          ; help, datatemp, /structure
          ; help, datatemp.CAltitude
          ; help, datatemp.CTemmperature
          ; help, datatemp.CnN2
          ; help, datatemp.CnCH4

           print, 'Begin Plotting Cassini Data' 
           cvarsel = ask('What Cassini data would you like to overplot? (1) Temperature (2) N2, CH4 Densities','1')

           if (cvarsel eq 1) then begin
              print, 'Cassini Temperature Selected' 

                maxd = max(plotarr[0:cntr-1,*])*(1.05)
                mind = min(plotarr[0:cntr-1,*])*(0.95)
                maxa = max(alt(2:nalts-3))*1.05
                mina = min(alt(2:nalts-3))*.95

                deltaalt = maxa-mina
                spacing = 25 ; 25 km
                yticknum = floor(deltaalt/spacing) + 1

               deltax = maxd-mind
               xticknum = 25 

               plot, plotarr[0,*], alt[2:nalts-3], $
               /nodata, $
               /noclip, $
               xrange = [mind,maxd], $
               yrange = [mina,maxa], $
               xstyle = 1, $
               ystyle = 1, $
               ytitle = 'Altitude (km)', $
               background = 7, color = 0
;               background = 7, color = 0, $
;               xticks = xticknum,      $
;               yticks = yticknum

               cnt = cntr - 1

               for i = 0,cnt do begin

                 oplot, plotarr[i,*], alt(2:nalts-3), $
                 color = i

               endfor

           endif ; End Select Cassini Temperature

           if (cvarsel eq 2) then begin

               
              denask = ask('Would you like N2 ? (y/n)','y')
              if (strpos(denask,'y') eq 0) then denplot = 1 else denlot = 0


              if(denplot eq 1) then begin
              print, 'Cassini Nitrogen Selected' 

                 maxd = max(plotarr[0:cntr-1,*])*(1.05)
       		 mind = min(plotarr[0:cntr-1,*])*(0.95)
       		 maxa = max(alt(2:nalts-3))*1.05
       		 mina = min(alt(2:nalts-3))*.95

       		 deltaalt = maxa-mina
       		 spacing = 25 ; 25 km
       		 yticknum = floor(deltaalt/spacing) + 1

                	if (plotlog eq 1) then begin
                  	print, 'Logarithm of densities desired' 
                 	deltax = alog(maxd)-alog(mind)
                 	xticknum = 25 

                 	plot, plotarr[0,*], alt[2:nalts-3], $
                 	/nodata, $
                 	/noclip, $
                 	/XLOG, $
                 	xrange = [mind,maxd], $
                 	yrange = [mina,maxa], $
                 	xstyle = 1, $
                 	ystyle = 1, $
                 	ytitle = 'Altitude (km)',$
                 	background = 7, color = 0
;                	 background = 7, color = 0, $
;                 	xtickformat = '(e6.3)', $ 
;                 	xticks = xticknum,      $
;                 	yticks = yticknum

                 	cnt = cntr - 1

                 	for i = 0,cnt do begin

                   	oplot, plotarr[i,*], alt(2:nalts-3), $
                   	color = i

                 	endfor

                   	oplot, smooth(Avg_nN2,10), AverageAlt, $
                   	color = 0,$
                        thick = 2.0, $
                        linestyle = 0 

                   	oplot, smooth(Global_upper_nN2,10), AverageAlt, $
                   	color = 0,   $
                        thick = 2.0, $
                        linestyle = 2 

                   	oplot, smooth(Global_lower_nN2,10), AverageAlt, $
                   	color = 0,   $
                        thick = 2.0, $
                        linestyle = 2 

                	endif ; End PlotLog 

            endif ; End Nitrogen Check 

            denask = ask('Would you like CH4 ? (y/n)','y')
            if (strpos(denask,'y') eq 0) then denplot = 2 else denlot = 0

              if(denplot eq 2) then begin
              print, 'Cassini CH4 Selected' 

                 maxd = max(plotarr[0:cntr-1,*])*(1.05)
       		 mind = min(plotarr[0:cntr-1,*])*(0.95)
       		 maxa = max(alt(2:nalts-3))*1.05
       		 mina = min(alt(2:nalts-3))*.95

       		 deltaalt = maxa-mina
       		 spacing = 25 ; 25 km
       		 yticknum = floor(deltaalt/spacing) + 1


	                if (plotlog eq 1) then begin
       		           print, 'Logarithm of densities desired' 
       		          deltax = alog(maxd)-alog(mind)
       		          xticknum = 25 

       		          plot, plotarr[0,*], alt[2:nalts-3], $
       		          /nodata, $
       		          /noclip, $
       		          /XLOG, $
       		          xrange = [0.5e11,maxd], $
;       		          xrange = [mind,maxd], $
       		          yrange = [mina,maxa], $
       		          xstyle = 1, $
       		          ystyle = 1, $
       		          ytitle = 'Altitude (km)',$
       		          background = 7, color = 0
;      		           background = 7, color = 0, $
;      		           xtickformat = '(e6.3)', $ 
;      		           xticks = xticknum,      $
;      		           yticks = yticknum

       		          cnt = cntr - 1

       		          for i = 0,cnt do begin
	
       		            oplot, plotarr[i,*], alt(2:nalts-3), $
       		            color = i

       		          endfor

                   	oplot, smooth(Avg_nCH4,10), AverageAlt, $
                   	color = 0,$
                        thick = 2.0, $
                        linestyle = 0 

                   	oplot, smooth(Global_upper_nCH4,10), AverageAlt, $
                   	color = 0,   $
                        thick = 2.0, $
                        linestyle = 2 

                   	oplot, smooth(Global_lower_nCH4,10), AverageAlt, $
                   	color = 0,   $
                        thick = 2.0, $
                        linestyle = 2 

                   	oplot, smooth(Avg_nN2,10), AverageAlt, $
                   	color = 0,$
                        thick = 2.0, $
                        linestyle = 0 

                   	oplot, smooth(Global_upper_nN2,10), AverageAlt, $
                   	color = 0,   $
                        thick = 2.0, $
                        linestyle = 2 

                   	oplot, smooth(Global_lower_nN2,10), AverageAlt, $
                   	color = 0,   $
                        thick = 2.0, $
                        linestyle = 2 

       		        endif ; End Plot Log Check 

            endif ; End CH4 

        endif ; Plot Densities 


      endif ; Cassini Data Plotting



    
        psfask = ask('Would you like to save this image to a PostScript File  (y/n)','n')
        if (strpos(psfask,'y') eq 0) then psplot = 1 else psplot = 0

        if (psplot eq 1) then begin


        entry_device = !d.name
        set_plot, 'PS'
        page_width = 8.5
        page_height = 11.0
        xsize = 6.5
        ysize = 6.5
        xoffset = (page_width -xsize)*.5
        yoffset = (page_height -ysize)*.5

        device, filename = 'Titan_line.ps', /portrait
        device, xsize = xsize, ysize = ysize, $
               xoffset = xoffset, yoffset = yoffset, /inches 
        device, /color

        maxd = max(plotarr[0:cntr-1,*])*(1.05)
        mind = min(plotarr[0:cntr-1,*])*(0.95)
        maxa = max(alt(2:nalts-3))*1.05
        mina = min(alt(2:nalts-3))*.95
         
        deltaalt = maxa-mina
        spacing = 25  ; 25 km
        yticknum = floor(deltaalt/spacing) + 1
       
        if (plotlog eq 0) then begin

           deltax = maxd-mind
           xticknum = 25 

           plot, plotarr[0,*], alt[2:nalts-3], $
           /nodata, $
           /noclip, $
           xrange = [5.0e11,maxd], $
;           xrange = [mind,maxd], $
           yrange = [mina,maxa], $
           xstyle = 1, $
           ystyle = 1, $
           ytitle = 'Altitude (km)', $
           background = 7, color = 0
;           background = 7, color = 0, $
;           xticks = xticknum,      $
;           yticks = yticknum

           cnt = cntr - 1

           for i = 0,cnt do begin

             oplot, plotarr[i,*], alt(2:nalts-3), $
             color = i

           endfor
        endif

        if (plotlog eq 1) then begin

           deltax = alog(maxd)-alog(mind)
           xticknum = 25 

           plot, plotarr[0,*], alt[2:nalts-3], $
           /nodata, $
           /noclip, $
           /XLOG, $
           xrange = [5.0e11,maxd], $
;           xrange = [mind,maxd], $
           yrange = [mina,maxa], $
           xstyle = 1, $
           ystyle = 1, $
           ytitle = 'Altitude (km)',$
           background = 7, color = 0
;           background = 7, color = 0, $
;           xtickformat = '(e6.3)', $ 
;           xticks = xticknum,      $
;           yticks = yticknum
            

           cnt = cntr - 1

           for i = 0,cnt do begin

             oplot, plotarr[i,*], alt(2:nalts-3), $
             color = i

           endfor

                   	oplot, smooth(Avg_nCH4,10), AverageAlt, $
                   	color = 14,$
                        thick = 2.0, $
                        linestyle = 0 

                   	oplot, smooth(Global_upper_nCH4,10), AverageAlt, $
                   	color = 14,   $
                        thick = 2.0, $
                        linestyle = 2 

                   	oplot, smooth(Global_lower_nCH4,10), AverageAlt, $
                   	color = 14,   $
                        thick = 2.0, $
                        linestyle = 2 

                   	oplot, smooth(Avg_nN2,10), AverageAlt, $
                   	color = 0,$
                        thick = 2.0, $
                        linestyle = 0 

                   	oplot, smooth(Global_upper_nN2,10), AverageAlt, $
                   	color = 0,   $
                        thick = 2.0, $
                        linestyle = 2 

                   	oplot, smooth(Global_lower_nN2,10), AverageAlt, $
                   	color = 0,   $
                        thick = 2.0, $
                        linestyle = 2 
        endif

       device, /close_file
       set_plot, entry_device

        endif

  print, 'Finished 1-D Plotting Routine... Exiting'

end
