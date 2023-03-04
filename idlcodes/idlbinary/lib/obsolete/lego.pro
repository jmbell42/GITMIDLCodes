; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/lego.pro#1 $
;
; Copyright (c) 1991-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

;+
; NAME:	
;	LEGO
;
; PURPOSE:
;	This procedure plots a lego graph of 2-dimensional data. 
;
; CATEGORY:
;	Plotting.
;
; CALLING SEQUENCE:
;	LEGO, Data, Xa, Ya
;
; INPUTS:
;	Data:	  A 2-dimensional array.
;	Xa:	  If present, a 1-dimensional array of X coordinates.
;    	Ya:	  If present, a 1-dimensional array of Y coordinates.
;
; KEYWORD PARAMETERS:
; 	BARSPACE: If this keyword is specified, LEGO will leave space
;		  between the bars. The value of BARSPACE must be
;		  between 0.0 and 0.8.
;	OUTLINE:  If this keyword is specified, LEGO will draw ONLY the
;	          outline of the bars. This is useful when creating black
;		  and white hardcopy.
;	SHADES:   If this keyword is specified, LEGO will draw ONLY the
;	          shaded part of the bars.
;	DELTA:    This keyword allows fine adjustment of the width
;		  of the bar outlines. RECOMMENDED USE: lower delta value
;		  for a small data set and higher delta value for a
;		  large data set. The value of DELTA must be between
;		  0.07 and 0.15
;       The following keywords to SURFACE are also applicable:
;		  AX, AZ, CHARSIZE, CHARTHICK, FONT, XMARGIN, YMARGIN,
;		  SUBTITLE, TICKLEN, TITLE, (XYZ)CHARSIZE, (XYZ)MINOR,
;		  (XYZ)RANGE, (XYZ)STYLE, (XYZ)TICKNAME, (XYZ)TICKS,
;		  (XYZ)TICKV, (XYZ)TITLE, BACKGROUND
;
; OUTPUTS:
;	The LEGO procedure creates a lego graph on the currently selected
;	device.
;
; SIDE EFFECTS:
;	A graphics window is created if none currently exist.
;
; RESTRICTIONS:
;       This procedure does not work with the HP device. Of Tektronix
;	terminals, only the 4100 series is supported.
;
; PROCEDURE:
;	Straightforward.
;
; EXAMPLE:
;	X = FINDGEN(10, 10)	; create 2D array to plot
;	LEGO, X			; create plot
;
; MODIFICATION HISTORY:
;       12/20/91 - Initial creation - jiy (RSI)
;	06/15/92 - Modified to produce better PS output - jiy (RSI)
;       08/28/92 - modified to better deal with small arrays -jiy (RSI)
;-

PRO lego,data,xa,ya,ax=ax,az=az,charsize=charsize,charthick=charthick,$
              font=font,xmargin=xmargin,ymargin=ymargin,subtitle=subtitle,$
              ticklen=ticklen,title=title,xcharsize=xcharsize,$
              ycharsize=ycharsize,zcharsize=zcharsize,$
              xminor=xminor,yminor=yminor,zminor=zminor,$
              xrange=xrange,yrange=yrange,zrange=zrange,$
              xstyle=xstyle,ystyle=ystyle,zstyle=zstyle,$
              xtickname=xtickname,ytickname=ytickname,ztickname=ztickname,$
              xticks=xticks,yticks=yticks,zticks=zticks,$
              xtickv=xtickv,ytickv=ytickv,ztickv=ztickv,$
              xtitle=xtitle,ytitle=ytitle,ztitle=ztitle,$
              background=background,color=color,barspace=barspace, $
              outline=outline,shades=shades,delta=delta

   ; get the type of the data passed in
   form = size(data);
   sizx = size(xa);
   sizy = size(ya);

   if (form(0) ne 2) then begin
      message,'Array must have 2 dimensions',/traceback
      return;
   endif;

   if (sizx(0) ne 0) then begin
      if (sizx(0) ne 1) then begin
         print,'X array must have 1 Dimension -> Using default';
         sizx(0) = 0;
      endif;
      if (sizx(1) ne form(1)) then begin
         print,'X array dimension incompatible with Z array - Using Default';
         sizx(0) = 0;
      endif;
   endif;

   if (sizy(0) ne 0) then begin
      if (sizy(0) ne 1) then begin
         print,'Y array must have 1 Dimension -> Using default';
         sizy(0) = 0;
      endif;
      if (sizy(1) ne form(2)) then begin
         print,'Y array dimension incompatible with Z array - Using Default';
         sizy(0) = 0;
      endif;
   endif;

   ; setting default
   if (sizx(0) eq 0) then xa = indgen (form(1));
   if (sizy(0) eq 0) then ya = indgen (form(2));

   if (n_elements(ax) eq 0) then ax=30;
   if (n_elements(az) eq 0) then az=30;

   if (n_elements(charsize)  eq 0) then charsize =1;
   if (n_elements(charthick) eq 0) then charthick=1;
   if (n_elements(font)      eq 0) then font     =0;

   if (n_elements(xmargin) eq 0) then xmargin = [10,3];
   if (n_elements(ymargin) eq 0) then ymargin = [ 4,2];

   if (n_elements(subtitle) eq 0) then subtitle = '';
   if (n_elements(title)    eq 0) then title    = '';
   if (n_elements(ticklen)  eq 0) then ticklen  = 0.02;

   if (n_elements(xcharsize) eq 0) then xcharsize = 1;
   if (n_elements(ycharsize) eq 0) then ycharsize = 1;
   if (n_elements(zcharsize) eq 0) then zcharsize = 1;

   if (n_elements(xminor) eq 0) then xminor = 0;
   if (n_elements(yminor) eq 0) then yminor = 0;
   if (n_elements(zminor) eq 0) then zminor = 0;

   if (n_elements(xstyle) eq 0) then xstyle = 0;
   if (n_elements(ystyle) eq 0) then ystyle = 0;
   if (n_elements(zstyle) eq 0) then zstyle = 0;

   if (n_elements(xtickname) eq 0) then xtickname = [''];
   if (n_elements(ytickname) eq 0) then ytickname = [''];
   if (n_elements(ztickname) eq 0) then ztickname = [''];

   if (n_elements(xticks) eq 0) then xticks=0;
   if (n_elements(yticks) eq 0) then yticks=0;
   if (n_elements(zticks) eq 0) then zticks=0;

   if (n_elements(xtickv) eq 0) then xtickv = [''];
   if (n_elements(ytickv) eq 0) then ytickv = [''];
   if (n_elements(ztickv) eq 0) then ztickv = [''];

   if (n_elements(xtitle) eq 0) then xtitle = '';
   if (n_elements(ytitle) eq 0) then ytitle = '';
   if (n_elements(ztitle) eq 0) then ztitle = '';

   if (n_elements(xrange) eq 0) then xrange = [min(xa),max(xa)+1];
   if (n_elements(yrange) eq 0) then yrange = [min(ya),max(ya)+1];
   if (n_elements(zrange) eq 0) then zrange = [min(data),max(data)];

   if (n_elements(background) eq 0) then background = !p.background;
   if (n_elements(color)      eq 0) then color      = !p.color;
   if (n_elements(barspace)   eq 0) then barspace   = 0.0;
   if (barspace gt 0.8)             then barspace   = 0.0;

   if (n_elements(shades)     eq 0) then draw       = 1 else draw = 0;

   dev_name = !D.NAME;   get the name of the current device

   ; define polygons - one face at a time & counterclock-wise
   polys  = [4,0,1,2,3, 4,4,5,6,7, 4,0,1,5,4,$
	     4,1,2,6,5, 4,2,3,7,6, 4,3,0,4,7];
   poly   = [0,1,2,3,0, 4,5,6,7,4, 0,1,5,4,0,$
	     1,2,6,5,1, 2,3,7,6,2, 3,0,4,7,3];

   if (n_elements(outline)    eq 0) then $
      shades = [0.8,0.8,1.0,0.7,1.0,0.7] * (!d.n_colors-1) $
   else $
      shades = [0,0,0,0,0,0];

   ; calculate the equivalent size in z-buffer
   zsize = lonarr (2)
   
   if (!d.name eq 'PS') then begin
      zsize(0) = 640.0 * !d.x_size / 17780.0;
      zsize(1) = 512.0 * !d.y_size / 12700.0;
   endif else if (!d.name eq 'TEK') then begin
      zsize(0) = 640.0 * !d.x_size / 4096.0;
      zsize(1) = 512.0 * !d.y_size / 3129.0;
   endif else if (!d.name eq 'PCL') then begin
      zsize(0) = 640.0 * !d.x_size / 2100.0;
      zsize(1) = 512.0 * !d.y_size / 1500.0;
   endif else if (!d.name eq 'CGM') then begin
      zsize(0) = 512.0 * !d.x_size / 32768.0;
      zsize(1) = 512.0 * !d.y_size / 32768.0;
   endif else begin
      zsize(0) = !d.x_size;
      zsize(1) = !d.y_size;
   endelse;

   set_plot,'z';
   device,set_res = zsize;
   erase; 

   surface,data,xa,ya,/nodata,/save, ax=ax, az=az, charsize=charsize, $
           charthick = charthick, font=font, $
           xmargin=xmargin,ymargin=ymargin,subtitle=subtitle,$
           ticklen=ticklen,title=title,xcharsize=xcharsize,$
           ycharsize=ycharsize,zcharsize=zcharsize,$
           xminor=xminor,yminor=yminor,zminor=zminor,$
           xrange=xrange,yrange=yrange,zrange=zrange,$
           xstyle=xstyle,ystyle=ystyle,zstyle=zstyle,$
           xtickname=xtickname,ytickname=ytickname,ztickname=ztickname,$
           xticks=xticks,yticks=yticks,zticks=zticks,$
           xtickv=xtickv,ytickv=ytickv,ztickv=ztickv,$
           xtitle=xtitle,ytitle=ytitle,ztitle=ztitle,$
           background=background

   set_shading,/gouraud;

   if (barspace) then begin
      add = barspace/2.0;
      del = 1.0 - add;
   endif else begin
      add = 0;
      del = 1;
   endelse;

   if (n_elements(delta) eq 0) then $
      delta = sqrt(form(1)*form(2))/500. $
   else delta = delta;

   if (delta lt .015) then delta = .015;
   if (delta gt .07) then delta = .07;
   
   add1 = add+delta;
   del1 = del-delta;
   maxi = max (data);

   zmin = min (data);

   for i=0,form(1)-1 do begin
      for j=0,form(2)-1 do begin
         x = xa(i);
         y = ya(j);
         z = data(i,j);
	 if z eq zmin then begin
            kin = 0 & kfin = 0;
         endif else begin
            kin = 0 & kfin = 5;
         endelse;

         v = [ [x+add,y+add,zmin ],  [x+del,y+add, zmin ],	$
	       [x+del,y+del, zmin ], [x+add,y+del,zmin ],	$
	       [x+add,y+add,z ],  [x+del,y+add,z ],	$
	       [x+del,y+del,z ], [x+add,y+del,z ] ];
	 z=z-delta;
         vs = [ [x+add1,y+add1,zmin ],  [x+del1,y+add1, zmin ],	$
	       [x+del1,y+del1, zmin ], [x+add1,y+del1,zmin ],	$
	       [x+add1,y+add1,z ],  [x+del1,y+add1,z ],$
	       [x+del1,y+del1,z ], [x+add1,y+del1,z ] ];

         if (draw) then begin
	    if (kin eq kfin) then begin
               plots,v(*,poly(kin*5:kin*5+4)),/t3d,thick=1.8,/data;
	    endif else begin	       
               for k=kin,kfin do begin
                  col = shades(k) * (z/maxi);
                  polyfill,vs(*,polys(k*5+1:k*5+4)),/t3d,color = col,/data;
                  plots,v(*,poly(k*5:k*5+4)),/t3d,thick=1.8,/data;
               endfor;
            endelse;
         endif else begin
            a = polyshade(v,polys,/t3d);
         endelse;

      endfor;
   endfor;

   a = tvrd ();
   set_plot,dev_name;

   ; reverse byte array for postscript output
   if (dev_name eq 'PS') then begin
      a = 255 - a;
   endif;

   tv,a;

end;


