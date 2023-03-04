
pro contour_circle, data, lons, lats, $
                    mini = mini, maxi = maxi, sym = sym, $
                    nLevels = nLevels, $
                    no00 = no00, no06 = no06, no12 = no12, no18 = no18, $
                    pos = pos, $
                    maxrange = maxrange, title = title, nolines = nolines, $
                    grid = grid

  if (n_elements(mini) eq 0) then mini = min(data)
  if (n_elements(maxi) eq 0) then maxi = max(data)
  if (n_elements(sym) gt 0 and mini lt 0.0) then begin
      maxi = max([maxi, abs(mini)])
      mini = -maxi
  endif
  if (n_elements(maxrange) eq 0) then maxrange = 90.0 - min(lats)
  if (n_elements(pos) eq 0) then begin
      ppp = 1
      space = 0.1
      pos_space, ppp, space, sizes
      get_position, ppp, space, sizes, 0, pos
  endif
  if (n_elements(nlevels) eq 0) then nlevels = 31
  if (n_elements(nolines) eq 0) then nolines = 0
  if (n_elements(grid) eq 0) then grid = 0

  if (max(lons) lt 30.0 and max(lons) gt 10.0) then londiv = 12.0 
  if (max(lons) lt 10.0) then londiv = !pi
  if (max(lons) gt 30.0) then londiv = 180.0

  nlats = n_elements(lats)
  nlons = n_elements(lons)

  lat2d = fltarr(nlons,nlats)
  lon2d = fltarr(nlons,nlats)

  for i=0,nlats-1 do lon2d(*,i) = lons*!pi/londiv - !pi/2.0
  for i=0,nlons-1 do lat2d(i,*) = lats

  x = (90.0-lat2d)*cos(lon2d)
  y = (90.0-lat2d)*sin(lon2d)

  loc = where(lat2d(0,*) ge 90.0-maxrange, count)

  if (count gt 0) then begin

      contour, data(*,loc), x(*,loc), y(*,loc), /noerase, pos = pos, $
        levels = findgen(nlevels)*(maxi-mini)/(nlevels-1) + mini, $
        c_colors = findgen(nlevels)*250/(nlevels-1) + 3, $
        /fill, /follow, xstyle = 5, ystyle = 5, $
        xrange = [-maxrange,maxrange], yrange = [-maxrange,maxrange]
      if (not nolines) then begin
          contour, data(*,loc), x(*,loc), y(*,loc), /noerase, pos = pos, $
            levels = findgen(nlevels/4)*(maxi-mini)/(nlevels/4-1) + mini, $
            /follow, xstyle = 5, ystyle = 5, $
        xrange = [-maxrange,maxrange], yrange = [-maxrange,maxrange]
      endif
      plotmlt, maxrange, $
        no00 = no00, no06 = no06, no12 = no12, no18 = no18

      if (grid) then begin
          for i=0,nLats-1 do begin
              if (90-lat2d(0,i) lt maxrange-1) then plots, x(*,i), y(*,i)
          endfor
          for i=0,nlons-1 do oplot, x(i,loc), y(i,loc)
      endif

      mini_tmp = min(data(*,loc))
      maxi_tmp = max(data(*,loc))

      if (abs(mini_tmp) gt 1000.0) or (abs(maxi_tmp) gt 1000.0) or        $
         (abs(maxi_tmp) lt 0.1) then begin
        maxs = string(maxi_tmp,format="(e8.2)")
        mins = string(mini_tmp,format="(e9.2)")
      endif else begin
        maxs = string(maxi_tmp,format="(f6.2)")
        mins = string(mini_tmp,format="(f7.2)")
      endelse

      xyouts, pos(0),pos(1), mins, /norm, charsize = 0.8
      xyouts, pos(2),pos(1), maxs, /norm, align=1.0, charsize = 0.8

      if (n_elements(title) gt 0) then begin

          p1 = pos(0)+(pos(2) - pos(0))*0.50 * (1.0 - sin(45.0*!pi/180.0))*0.95
          p2 = pos(3)-(pos(3) - pos(1))*0.50 * (1.0 - sin(45.0*!pi/180.0))*0.95

          xyouts, p1, p2, title, $
                /norm, alignment = 0.5, charsize = 0.8, orient = 45.0

      endif

  endif

end
