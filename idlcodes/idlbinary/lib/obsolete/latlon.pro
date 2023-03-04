; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/latlon.pro#1 $
;
; Copyright (c) 1990-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

pro LatLon
;+
; NAME:
;	LATLON
;
; PURPOSE:
;	If the current window has map coordinates (i.e., MAP_SET has been used
;	to set up a map projection), LATLON tracks the longitude and latitude 
;	of the mouse location and displays them in a separate window. 
;
;	To activate tracking, click on the left mouse button while the cursor 
;	is in the plotting window. To stop, position the cursor in the 
;	plotting  window and press the right button.
;
; CATEGORY:
;	Mapping.
;
; CALLING SEQUENCE:
;	LATLON 
;
; INPUTS:
;	None.
;
; KEYWORD PARAMETERS:
;	None.
;
; OUTPUTS:
;	Latitude and longitude values are printed in a new window.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	A new window is created.
;
; RESTRICTIONS:
;	The window must have map coordinates.
;
; EXAMPLE:
;	Set up a Mercator map projection by entering the following command:
;		MAP_SET, /MERCATOR, /GRID, /CONTINENT
;
;	Invoke LATLON by entering:
;		LATLON
;
;	A new window labeled "Latitude/Longitude" should appear.  Put the mouse
;	cursor in the map window and press the left mouse button to begin
;	tracking the position of the cursor.  Press the right mouse button 
;	over the map to end LATLON.
;
; MODIFICATION HISTORY:
;	Written by Ann Bateson, June 1990
;
;-
 
if (!x.type NE 2) THEN GOTO,DONE   ;Need Mapping Coordinates

Save=!D.Window
supports_windows = (!d.flags and 256) ne 0
if (supports_windows) then  $  ;Display window for latlon
 Window,1,Title="Latitude/Longitude",XSIZE=300,YSIZE=25

S2=!D.Window
if (supports_windows) then WSET,Save
cursor,x,y,/Normal
x2=x & y2=y

while ( !ERR NE 4) DO BEGIN   ; Read cursor from plotting window and 
                              ; print latitude and longitude in
                              ; plotting window or latlon display window 
cursor,x1,y1,/nowait
if(ABS(X1-X2) GE.01) or (ABS(Y1-Y2) GE .01) THEN BEGIN
 if (supports_windows) then WSet,S2
; erase
 xyouts,50,10,   $
       string(Format='(f9.4)',y2)+' /'+string(Format='(f9.4)',x2),/Device,col=0
 xyouts,50,10,   $
       string(Format='(f9.4)',y1)+' /'+string(Format='(f9.4)',x1),/Device
 if (supports_windows) then WSet,Save 
                 ;switch back to plot window to read coordinates

 X2=X1 & Y2=Y1
ENDIF
ENDWHILE

if (supports_windows) then WDelete,S2
Return
DONE  : print,"latlon- Current window must have map coordinates"
RETURN
END


