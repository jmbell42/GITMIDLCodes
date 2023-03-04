;************************************************************** WAVETEST
; NAME:   WAVETEST
;
; PURPOSE:   Example IDL program for WAVELET, using NINO3 SST dataset
;
;------------------------------------------------------ Plotting
pro box,x0,y0,x1,y1,col
polyfill, [x0,x0,x1,x1],[y0,y1,y1,y0], Col=col
end

printfile =0
!P.FONT = -1
!P.CHARSIZE = 1
IF (printfile) THEN BEGIN
    SET_PLOT,'PS'
    Device,filename='\\IDL\color39.ps'
    DEVICE,/Land,/INCH,/COLOR,BITS=8
    !P.FONT = 0
    !P.CHARSIZE = 1.25
ENDIF ELSE begin
  ;set_plot, 'WIN'
  device, decomposed=0
 WINDOW,0,XSIZE=1200,YSIZE=600
 endelse
!P.MULTI = 0
!X.STYLE = 1
!Y.STYLE = 1
 ;xloadct
tb=39    ;;; 0 --- 400 ; 12 -16 COL
 LOADCT, tb
colors=indgen(256)
x=indgen(16);
y=x & y(*)=0 ; & y(15)=15
plot, x,y, yrange=[0,15], title='Table ' +string(tb), background=255
axis, xaxis=4, yaxis=4
for i=0,255  do begin
  s=string(i)
  xyouts, 0.95*(i mod 16)-0.4, 0.95*fix(i/16),s,Col=colors(i)
  endfor

IF (printfile) THEN DEVICE,/CLOSE
END
