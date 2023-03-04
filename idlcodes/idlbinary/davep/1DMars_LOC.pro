

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

filelist = findfile("-t *.save")
if (strlen(filelist(0)) eq 0) then filelist = findfile("-t *.3DALL")


filelist = ask('filename to plot',filelist(0))
filelist = findfile(filelist)
nfiles = n_elements(filelist)
iFile = nFiles-1


    filename = filelist(iFile)

    read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
      vars, data, rb, cb, bl_cnt

;    help, data
; \
; Data for a 1-D file is given in the following format:
; data = float[nvars,1,1,nAlts] 
; /
; the following reform statement should re-shape the data size to
; be only a 2-D matrix of size [nvars,nAlts]
    
   data = reform(data)
 
;   help, data

    longitude = data(0,*) / !dtor        ; This gives longitude in radians
    latitude = data(1,*) / !dtor         ; This gives latitude in radians
    altitude = data(2,*) / 1000.0        ; gives the altitude in km
    localtime = data(1,*)                ; local time [0-24 titan hours]

    alt = altitude(*)
    lat = latitude(1)                    ; \
    lon = longitude(1)                   ; lat, lon, and slt are indep of altitude
    slt = localtime(1)                   ; /

    for i=0,nvars-1 do print, tostr(i)+'. '+vars(i)
    sel = fix(ask('which var to plot','9'))

    plotlog = ask('whether you want log or not (y/n)','n')
    if (strpos(plotlog,'y') eq 0) then plotlog = 1 else plotlog = 0

    print, ' Plots will be at ', lat, ' Degrees Latitude by ', lon, ' Degrees Longitude', slt, 'Hours Local Time.'

    slice = 1

; cntr is the number of selections made
    cntr = 1
    plotarr = fltarr(nvars,nalts-4)

; selarr is an array of selection indicies.
; selarr is used for the multiplots later.

    selarr = fltarr(cntr)
    selarr[0] = sel


    if (slice eq 1) then begin

        maxd = max(reform(data(sel,2:nalts-3)))*(1.05)
        mind = min(reform(data(sel,2:nalts-3)))*(.95)

        maxa = max(alt(2:nalts-3))*1.05
        mina = min(alt(2:nalts-3))*.95

        if (plotlog eq 1) then begin
        plot, data(sel,2:nalts-3), alt(2:nalts-3), $
             title ='Logarithmic Plot of'+vars(sel)+' versus Altitude', $
             subtitle ='Latitude: ' + string(lat)+ '  Longitude:' +string(lon)+ '   SLT:' +string(slt), $
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
        plot, data(sel,2:nalts-3), alt(2:nalts-3), $
             title ='Linear Plot of'+vars(sel)+' versus Altitude', $
             subtitle ='Latitude: ' + string(lat)+ '  Longitude:' +string(lon)+ '   SLT:' +string(slt), $
             ytitle = 'Altitude (km)', $
             xtitle = vars(sel),  $
             yrange = [mina,maxa], $
             xrange = [mind,maxd],  $ 
             xstyle = 1, $
             ystyle = 1, $ 
             background = 7, color = 0
        endif

        plotarr[cntr - 1,*] = data(sel,2:nalts-3)

    endif  ; Case Slice = 1


     multi = ask('Multiple Plots on the Same Image ?  (y/n)','n')
     if (strpos(multi,'y') eq 0) then multiplot = 1 else multiplot = 0

	     while (multiplot eq 1) do begin

; add another choice to the counter

     		cntr = cntr + 1 

     		for i=0,nvars-1 do print, tostr(i)+'. '+vars(i)
     		sel = fix(ask('which var to plot','9'))

     		plotlog = ask('whether you want log or not (y/n)','n')
     		if (strpos(plotlog,'y') eq 0) then plotlog = 1 else plotlog = 0

    print, ' Plots will be at ', lat, ' Degrees Latitude by ', lon, ' Degrees Longitude', slt, 'Hours Local Time.'

        	slice = 1 

	    	if (slice eq 1) then begin

       	 	maxd = max(reform(data(sel,2:nalts-3)))*(1.05)
       	 	mind = min(reform(data(sel,2:nalts-3)))*(.95)

       	 	maxa = max(alt(2:nalts-3))*1.05
       	 	mina = min(alt(2:nalts-3))*.95

                plotarr[cntr - 1,*] = data(sel,2:nalts-3)

    	endif ;  Case Slice = 1


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

           deltax = log(maxd)-log(mind)
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

           deltax = log(maxd)-log(mind)
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

       device, /close_file
       set_plot, entry_device

        endif

  print, 'Finished 1-D Plotting Routine... Exiting'

end
