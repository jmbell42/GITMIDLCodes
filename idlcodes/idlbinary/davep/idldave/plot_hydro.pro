getnewdata = 1
loadct, 39
filelist_new = file_search('*out.dat')
nfiles_new = n_elements(filelist_new)

;for ifile = 0, nfiles_new - 1 do print, tostr(ifile),' ', filelist_new(ifile) 
;if n_elements(whichfile) eq 0 then whichfile = 0
;whichfile = fix(ask("which file to plot: ",tostr(whichfile)))
;ifile = whichfiles

nfiles = nfiles_new
print, tostr(nfiles)+' to plot'
if n_elements(nskip) eq 0 then nskip = 0
nskip = fix(ask('number of files to skip: ',tostr(nskip)))

for ifile = 0, nfiles - 1 do begin
    filename = filelist_new(ifile)

    print, 'Reading '+filename

  IsDone = 0
  close,1
  openr, 1, filename
    while IsDone eq 0 do begin
        line = ' '
       
        readf, 1, line
        
        temp = strtrim(line,2)
        
        case temp of
            "NUMERICAL VALUES" : begin
                readf, 1, line
                temp = strsplit(line,/extract)
                nVars = temp(0)
                
                Vars = strarr(nVars)
                
                readf, 1, line
                temp = strsplit(line,/extract)
                nLats = temp(0)
                
                readf, 1, line
                temp = strsplit(line,/extract)
                nLons = temp(0)
                
                readf, 1, line
                temp = strsplit(line,/extract)
                nAlts = temp(0)
                
            end
            
            "VARIABLE LIST" : begin
                for iVar = 0, nVars - 1 do begin
                    readf, 1, line
                    temp = strsplit(line,/extract)
                    Vars(iVar) = temp(1)
                endfor
                readf,1,line
                
                IsDone = 1
            end
            
            else: 
        endcase


    endwhile

    data = fltarr(nVars,nLons,nLats,nAlts)

    for iAlt = 0, nAlts - 1 do begin
        for iLon = 0, nLons - 1 do begin
            for iLat = 0, nLats - 1 do begin
                
                readf, 1, line
                temp = strsplit(line,/extract)
                
                for iVar = 0, nVars - 1 do begin
                    data(iVar,iLon,iLat,iAlt) = temp(iVar)
                endfor
                
            endfor
            
        endfor
        
    endfor
    
    alts = reform(data(2,0,0,*))
    lats = reform(data(1,0,*,0))
    lons = reform(data(0,*,0,0))
    close,1
    
    
    if ifile eq 0 then begin
        for ivar = 0, nvars - 1 do print, tostr(ivar), ' ', vars(ivar)
        
        if n_elements(plotvar) eq 0 then plotvar = 3
        
        plotvar = fix(ask("which variable to plot: ", tostr(plotvar)))
        
        print, tostr(0), " Constant Altitude"
        print, tostr(1), " Constant Latitude"
        print, tostr(2), " Constant Longitude"
        
        if n_elements(plottype) eq 0 then plottype = 0
        plottype = fix(ask("plot type: ",tostr(plottype)))
        
    endif
    
    if plottype eq 0 then begin
        if ifile eq 0 then begin
            for ialt = 0, nalts - 1 do print, tostr(ialt), alts(ialt)
            if n_elements(whichalt) eq 0 then whichalt = 0
            whichalt = fix(ask("which alt to plot: ",tostr(whichalt)))
        endif
        x = reform(data(0,*,*,whichalt))
        y = reform(data(1,*,*,whichalt))
        val = reform(data(plotvar,*,*,whichalt))
        
        xtitle = 'Longitude'
        ytitle = 'Latitude'
        num = tostr(alts(whichalt)) + ' altitude'
    endif 
    
    if plottype eq 1 then begin
        if ifile eq 0 then begin
            for ilat = 0, nlats - 1 do print, tostr(ilat),' ', lats(ilat)
            if n_elements(whichlat) eq 0 then whichlat = 0
            whichlat = fix(ask("which lat to plot: ", tostr(whichlat)))
        endif
        x = reform(data(0,*,whichlat,*))
        y = reform(data(2,*,whichlat,*))
        val = reform(data(plotvar,*,whichlat,*))
        
        xtitle = 'Longitude'
        ytitle = 'Altitude'
        
        num = tostr(lats(whichlat)) + ' latitutde'
        
    endif
    
    if plottype eq 2 then begin
        if ifile eq 0 then begin
            for ilon = 0, nlons - 1 do print, tostr(ilon),' ', lons(ilon)
            if n_elements(whichlon) eq 0 then whichlon = 0
            whichlon = fix(ask("which lon to plot: ",tostr(whichlon)))
        endif
        x = reform(data(1,whichlon,*,*))
        y = reform(data(2,whichlon,*,*))
        val = reform(data(plotvar,whichlon,*,*))
        
        xtitle = 'Latitude'
        ytitle = 'Altitude'
        
        num = tostr(lons(whichlon)) + ' longitude'
    endif
    
    
;if plottype ne 0 and vars(plotvar) eq 'Neutral' then begin
;    if n_elements(plotlog) eq 0 then plotlog = 'y'
;    plotlog = ask("whether to plot log: ", plotlog)
;endif else begin
;    plotlog = 'n'
;endelse
;
;if plotlog then value = alog10(val) else value = val
    value = val
    if ifile eq 0 then begin
        if n_elements(minv) eq 0 then minv = 0.0 
        if n_elements(maxv) eq 0 then maxv = 0.0 
        
        minv = float(ask("min value for plot (0.0 for auto): ",tostrf(minv)))
        maxv = float(ask("max value for plot (0.0 for auto): ",tostrf(maxv)))
    endif
     mini = min(value) - (0.1) * abs(min(value)) 
     maxi = max(value) + (.08) * abs(max(value)) 
    
    xrange = [min(x),max(x)]
    yrange = [min(y),max(y)]
    
    levels = findgen(31) * (maxi-mini) / 30 + mini
    
    title = vars(plotvar)+' at '+ num
    pos = [.2,.2,.8,.8]
    

    
   plottitle = 'plot'+chopr('000'+tostr(ifile),4)+'.ps'
;plottitle = ask("name of plot: ",plottitle)
    setdevice, plottitle,'l',5,.95
    
    if mean(value) -  max(value) lt .0001*mean(value) then value(0) = .5*value(0)
    contour, value, x, y, /follow, /fill,  pos = pos, $
      yrange = yrange, xrange = xrange, ystyle = 1, xstyle = 1, $
      xtitle = xtitle, ytitle = ytitle, charsize = 1.2, title = title,levels = levels
    
    ctpos = pos
    ctpos(0) = pos(2)+0.025
    ctpos(2) = ctpos(0)+0.03
maxmin = [mini,maxi]
plotct, 255, ctpos, maxmin, title, /right

closedevice

ifile = ifile + nskip
endfor



end


            

