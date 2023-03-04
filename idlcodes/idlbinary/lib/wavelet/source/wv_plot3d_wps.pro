;----------------------------------------------------------------
; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/wavelet/source/wv_plot3d_wps.pro#1 $
;
; Copyright (c) 1999-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;+
; NAME:
;    WV_PLOT3D_WPS
;
; PURPOSE:
;
;    This function runs the IDL Wavelet Toolkit wavelet power
;    spectrum widget.
;
; CALLING SEQUENCE:
;
;    Result = WV_PLOT3D_WPS( Array [, X] [, Y]
;        [, XTITLE=xtitle] [, YTITLE=ytitle]
;        [, XUNITS=xunits] [, YUNITS=yunits]
;        [, UNITS=units] [, TITLE=title] )
;
; INPUTS:
;
;    Array: A one- or two-dimensional array of data to be analyzed.
;
;    X: An optional vector of uniformly-spaced values giving the
;       location of points along the first dimension of Array.
;       The default is 0, 1, 2,..., Nx-1, where Nx is the size
;       of the first dimension.
;
;    Y: An optional vector of uniformly-spaced values giving the
;       location of points along the second dimension of Array.
;       The default is 0, 1, 2,..., Ny-1, where Ny is the size
;       of the second dimension.
;
; KEYWORDS:
;
;    GROUP_LEADER: The widget ID of an existing widget that serves
;      as "group leader" for the newly-created widget. When a group
;      leader is killed, for any reason, all widgets in the group are
;      also destroyed.
;
;    TITLE: A scalar string giving the label to be used for the widget.
;      The default is "WPS:".
;
;    UNITS: A scalar string giving the units of Array.
;
;    XTITLE: A scalar string giving the label to be used for the
;      first dimension.
;
;    XUNITS: A scalar string giving the units of X.
;
;    YTITLE: A scalar string giving the label to be used for the
;      y-axis (for a 1D vector) or for the second dimension (for a 2D array).
;
;    YUNITS: A scalar string giving the units of Array (for a 1D vector)
;      or the units of Y (for a 2D array).
;
; OUTPUTS:
;
;    Result: The widget ID of the newly-created widget.
;
; REFERENCE:
;    IDL Wavelet Toolkit Online Manual
;
; MODIFICATION HISTORY:
;    Written by CT, 1999
;    May 2000, CT: Removed RESOLVE_ALL
;    August 2000, CT: Add "Open State", "Save State".
;                     Add hide/show Wavelet & View panels.
;                     Add "zero phase lines" button.
;-
;  Variable name conventions used herein:
;       r==Reference to Object
;       p==pointer
;       w==widget ID
;


;+
; NAME:
;   CW_FONT_SELECT
;
; PURPOSE:
;
; CALLING SEQUENCE:
;
; INPUTS:
;       Parent:     The ID of the parent widget.
;
; KEYWORD PARAMETERS:
;   FRAME:      Set this keyword to have a frame drawn around the
;           widget. The default is FRAME=0.
;   UVALUE:     The user value for the widget.
;   UNAME:      The user name for the widget.
;   VALUE:      The initial value of the slider
;
; OUTPUTS:
;       The ID of the created widget is returned.
;
; PROCEDURE:
;   WIDGET_CONTROL, id, SET_VALUE=value can be used to change the
;       current value displayed by the widget.
;
;   WIDGET_CONTROL, id, GET_VALUE=var can be used to obtain the current
;       value displayed by the widget.
;
; MODIFICATION HISTORY:
;-


;-----------------------------------------------------------------------------
PRO cw_font_select_set_value, id, set_value

    COMPILE_OPT hidden, idl2

; Set the value of both the slider and the label
    ON_ERROR, 2      ;return to caller

    stash = WIDGET_INFO(id, /CHILD)
    WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY
    IF (N_TAGS(set_value) NE 2) THEN MESSAGE, $
        'Incorrect structure for Value.'

    fontIndex = (WHERE(state.sFontList EQ set_value.name))[0]
    IF (fontIndex EQ -1) THEN BEGIN  ; now try fontcode
        fontIndex = (WHERE(state.sFontCode EQ set_value.name))[0]
        IF (fontIndex EQ -1) THEN MESSAGE, /INFO, $
            'Unknown font name: '+set_value.name
    ENDIF
    IF (fontIndex GE 0) THEN WIDGET_CONTROL, state.wFontList, $
        SET_DROPLIST_SELECT=fontIndex

    sizeIndex = MAX(WHERE(state.sFontSize LE set_value.size)) > 0
    WIDGET_CONTROL, state.wFontSize, $
        SET_DROPLIST_SELECT=sizeIndex

    WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
    RETURN
END



;-----------------------------------------------------------------------------
FUNCTION cw_font_select_get_value, id

    COMPILE_OPT hidden, idl2

; Return the value
    ON_ERROR, 2     ;return to caller

    stash = WIDGET_INFO(id, /CHILD)
    WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY

; See which widget was adjusted
    fontIndex = WIDGET_INFO(state.wFontList, /DROPLIST_SELECT)
    fname = state.sFontList[fontIndex]

    sizeIndex = WIDGET_INFO(state.wFontSize, /DROPLIST_SELECT)
    fsize = state.sFontSize[sizeIndex]

    WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
    RETURN, { NAME:fname, SIZE:fsize }

END


;-----------------------------------------------------------------------------
FUNCTION cw_font_select_event, event

    COMPILE_OPT hidden, idl2

; Retrieve the structure from the child that contains the sub ids
    parent = event.handler
    stash = WIDGET_INFO(parent, /CHILD)
    WIDGET_CONTROL, stash, GET_UVALUE=state, /NO_COPY

; See which widget was adjusted
    fontIndex = WIDGET_INFO(state.wFontList, /DROPLIST_SELECT)
    fname = state.sFontCode[fontIndex]

    sizeIndex = WIDGET_INFO(state.wFontSize, /DROPLIST_SELECT)
    fsize = state.sFontSize[sizeIndex]

    WIDGET_CONTROL, stash, SET_UVALUE=state, /NO_COPY
    RETURN, { ID:parent, TOP:event.top, HANDLER:0L, $
        NAME:fname, SIZE:fsize}
END


;-----------------------------------------------------------------------------
FUNCTION cw_font_select, parent, $
        FRAME=frame, $
        VALUE = set_value, $
        UNAME=uname, $
        _EXTRA=_extra

    COMPILE_OPT hidden, idl2
    ON_ERROR, 2                       ;return to caller

    IF (N_PARAMS() EQ 0) THEN MESSAGE, 'Incorrect number of arguments'

    ; Defaults for keywords
    IF NOT KEYWORD_SET(uname) THEN $
        uname='CW_FONT_SELECT_UNAME'
    IF (N_ELEMENTS(set_value) EQ 0) THEN $
        set_value = ""

    wBase = WIDGET_BASE(parent, $
        EVENT_FUNC = 'CW_FONT_SELECT_EVENT', $
        FRAME = frame, $
        FUNC_GET_VALUE='CW_FONT_SELECT_GET_VALUE', $
        PRO_SET_VALUE='CW_FONT_SELECT_SET_VALUE', $
        /ROW, $
        UNAME=uname, $
        _EXTRA=_extra)


    rClip = OBJ_NEW('IDLgrClipboard', $
        DIMENSIONS=[1,1])
    fontlist = rClip->GetFontNames('*',/IDL,STYLE='*')
    OBJ_DESTROY, rClip
    fontcode = fontlist
    hershey = [ $
        ['','3'], $
        ['Bold','5'], $
        ['Serif','6'], $
        ['Italic','8'], $
        ['Heavy','17'], $
        ['Bold Italic','18']]
    hersheyNames = REFORM('Hershey ' + hershey[0,*])
    hersheyCodes = REFORM('Hershey*' + hershey[1,*])
    fontlist = [fontlist, hersheyNames]
    fontcode = [fontcode, hersheyCodes]
    index = SORT(fontlist)
    fontlist = fontlist[index]
    fontcode = fontcode[index]
    wFontList = WIDGET_DROPLIST(wBase, $
        VALUE=fontlist)


    fontsize = [6,7,8,9,10,11,12, $
        14,16,18,20,22,24,26,28, $
        36,48,72]
    wFontSize = WIDGET_DROPLIST(wBase, $
        VALUE=STRTRIM(fontsize,2))


    state = {wBase:wBase, $
        wFontList:wFontList, $
            sFontList:fontlist, $
            sFontCode:fontcode, $
        wFontSize:wFontSize, $
            sFontSize:fontsize}

    WIDGET_CONTROL, WIDGET_INFO(wBase, /CHILD), SET_UVALUE=state
    IF (N_TAGS(set_value) EQ 2) THEN $
        CW_FONT_SELECT_SET_VALUE, wBase, set_value

    RETURN, wBase

END


;--------------------------------------------------------------------
FUNCTION wv_plot3d_cwt, family, order, data, xData, $
    X=x, Y=y

    COMPILE_OPT strictarr, hidden

    nDim = SIZE(data,/N_DIMENSION)
    IF (nDim NE 1) THEN MESSAGE, $
        'CWT not implemented for two-dimensional arrays.'
    cwt = WV_CWT(data,family,order,SCALE=scale,/PAD)
    y = ALOG(scale)/ALOG(2d)
    x = xData
    RETURN, cwt
END


;--------------------------------------------------------------------
FUNCTION wv_plot3d_dwt, family, order, data, xData, $
    X=x, Y=y

    COMPILE_OPT strictarr, hidden

    nDim = SIZE(data,/N_DIMENSION)
    dim = SIZE(data,/DIMENSIONS)
    ; find next larger power of 2 to embed within
    dim = 2L^(LONG(ALOG(dim)/ALOG(2)+0.99999))
    nx = dim[0]
    IF (nDim EQ 1) THEN BEGIN
        data_in = DBLARR(nx)
    ENDIF ELSE BEGIN
        ny = dim[1]
        data_in = DBLARR(nx,ny)
    ENDELSE
    ; embed input data within larger array
    data_in[0,0] = data
    wave_function = STRCOMPRESS('wv_fn_'+family,/REMOVE_ALL)
    wInfo = CALL_FUNCTION(wave_function, order, $
        scaling,wavelet,ioff,joff)
    dwt = WV_DWT(data_in,scaling,wavelet,ioff,joff,/DOUBLE)
    IF (nDim EQ 1) THEN BEGIN ; time series
        dwt[0:1] = SQRT(TOTAL(dwt[0:1]^2)/2.) ; first 2 coeffs are "mean"
        power2 = FIX(ALOG(nx)/ALOG(2))
        ny = power2
        y = LINDGEN(ny) + 1
        nx = N_ELEMENTS(data)/2
        x = xData[2L*LINDGEN(nx)]
;* starred lines are for extending the axes for Logo plots
;*          ny = power2 + 1
;*          y = LINDGEN(ny) + 1
;*          nx = 2L^(power2-1) + 1
;*          x = (*(*pState).pXdata)[2L*LINDGEN(nx-1)]
;*          x = [x,MAX(x) + (x[1]-x[0])]
        dwt_big = FLTARR(nx,ny)
        FOR j=0,power2-1 DO BEGIN
            index = 2L^j + LINDGEN(nx)/(2L^(power2-j-1))
            dwt_big[0,power2-j-1] = dwt[index]
;*              index = 2L^j + LINDGEN(nx-1)/(2L^(power2-j-1))
;*              dwt_big[0,power2-j] = dwt[index]
        ENDFOR
        dwt = TEMPORARY(dwt_big)
;           n = N_ELEMENTS(dwt)
;           y = power2 - FIX(ALOG(LINDGEN(n))/ALOG(2))
;           x = (LINDGEN(n) - 2L^(power2-y))*(2L^y) > 0
    ENDIF ELSE BEGIN ; 2D array
        x = LINDGEN(nx)
        y = LINDGEN(ny)
    ENDELSE
    RETURN, dwt
END


;--------------------------------------------------------------------
FUNCTION wv_rescale_axis, values, $
    EXPONENT=exponent, $
    SCALE_FACTOR=scale_factor, $
    SCALE_STRING=scale_string, $
    TITLE=title

    COMPILE_OPT strictarr, hidden

    n = N_ELEMENTS(values)
    minn = MIN(values[WHERE(values NE 0.)])
    exponent = (N_ELEMENTS(exponent) EQ 0) ? $
        FIX(ALOG10(ABS(minn))) : exponent
    scale_factor = 10d^exponent
    scale_string = '!3!E !Nx!E !N!X10!U' + STRTRIM(exponent,2) + '!N'
    IF (ABS(exponent) LT 4) THEN BEGIN
        dummy = TEMPORARY(exponent)
        scale_factor = 1
        scale_string = ''
        RETURN, values ; no need to rescale
    ENDIF
    result = values/scale_factor
    IF (N_ELEMENTS(title) EQ 1) THEN BEGIN
        units = STRPOS(title,'(')
        CASE (units) OF
        -1: title = title + ' (' + scale_string + ')'
        ELSE: title = STRMID(title,0,units+1) + $
            scale_string + ' ' + STRMID(title,units+1,255)
        ENDCASE
    ENDIF
    scale_string = '(' + scale_string + ')'
    RETURN,result
END


;--------------------------------------------------------------------
PRO wv_plot3d_redraw, pState, $
    THREED=threeD, $
    ZCUTOFF=zcutoff, $
    COLORBARTITLE=colorbartitle

    COMPILE_OPT strictarr, hidden


    rView = (*pState).rView
    pX = (*pState).pX
    pY = (*pState).pY
    pZ = (*pState).pZ
    pGws = (*pState).pGws
    pPhase = (*pState).pPhase


    rView->GetProperty,UVALUE=sWps
    oneD = OBJ_VALID(sWps.rTimeSeries)

; find Z range
    zmin = MIN(*pZ,MAX=zmax)
    zmin = 0.0 < zmin
    IF (N_ELEMENTS(zcutoff) EQ 1) THEN BEGIN
        zmin = (zmin > zcutoff) < zmax
    ENDIF
    IF (zmax EQ zmin) THEN zmin = zmax - 0.1D
    zcutoff = zmin
    zscale = 0.65
    zs = zscale*[-FLOAT(zmin)/(zmax - zmin),1.0/(zmax - zmin)]

; add data to surface plot
    zvalues = zmin > *pZ < zmax
    offset = 0
    IF (threeD EQ 0) THEN offset = zmin

    sWps.rSurface->SetProperty, $
        DATAX=*pX,DATAY=*pY,DATAZ=zvalues*threeD+offset, $
        SKIRT=zmin, $
        VERT_COLORS=(BYTSCL(zvalues,TOP=253)+1b)[*]
    sWps.rSurface->GetProperty, $
        STYLE=style, $
        XRANGE=xrange, $
        YRANGE=yrange

; find coord conversions
    xmin = MIN(xrange,MAX=xmax)
    ymin = MIN(yrange,MAX=ymax)

    xs = [-0.45 - FLOAT(xmin)/(xmax - xmin),1./(xmax - xmin)]
    ys = [-0.45 - FLOAT(ymin)/(ymax - ymin),1./(ymax - ymin)]
    ys2 = ys
;   IF oneD THEN ys2 = [0.55 + FLOAT(ymin)/(ymax - ymin),-1./(ymax - ymin)]

    sWps.rPhaseImage->SetProperty, $
        XCOORD_CONV=xs,YCOORD_CONV=ys2,ZCOORD_CONV=zs

; change coord conversions for surface plot
    sWps.rSurface->SetProperty, $
        UVALUE=style, $
        XCOORD_CONV=xs,YCOORD_CONV=ys2,ZCOORD_CONV=zs

; change X axis ranges & ticks
    sWps.rXaxis->SetProperty, $
        HIDE=0, $
        RANGE=[xmin,xmax], $
        LOCATION=[xmin,ymin,0], $
        TICKLEN=0.02*(ymax-ymin), $
        XCOORD_CONV=xs,YCOORD_CONV=ys;,ZCOORD_CONV=zs

; convert X ticks to exponential notation if necessary
    sWps.rXaxis->GetProperty, $
        TICKVALUES=values
    sWps.rXtitle->GetProperty, UVALUE=title
    values = WV_RESCALE_AXIS(values, $
        EXPONENT=Xexponent, $
        SCALE_FACTOR=Xscale_factor, $
        TITLE=title)
    IF (Xscale_factor NE 1) THEN BEGIN
        sWps.rXaxis->SetProperty, $
            RANGE=[xmin,xmax]/Xscale_factor, $
            LOCATION=[xmin/Xscale_factor,ymin,0], $
            XCOORD_CONV=[xs[0],xs[1]*Xscale_factor], $
            YCOORD_CONV=ys;,ZCOORD_CONV=zs
        sWps.rXtitle->SetProperty, STRINGS=title
    ENDIF


; change Y axis ranges & ticks
    sWps.rYaxis->SetProperty, $
        HIDE=0, $
        MAJOR=-1, $
        RANGE=[ymin,ymax], $
        LOCATION=[xmin,ymin,0], $
        TICKLEN=0.02*(xmax-xmin), $
        TICKVALUES=0, $
        XCOORD_CONV=xs,YCOORD_CONV=ys;,ZCOORD_CONV=zs

; remove last tick mark on y-axis (that power-of-two is off the scale)
;   sWps.rYaxis->GetProperty, $
;       MAJOR=major, $
;       TICKVALUES=tickvalues
;   IF (MAX(tickvalues) EQ ymax) THEN BEGIN
;       sWps.rYaxis->SetProperty, $
;           MAJOR=major-1, $
;           TICKVALUES=tickvalues[0:major-2]
;   ENDIF

; change Z axis ranges & ticks
    sWps.rZaxis->SetProperty, $
        RANGE=[zmin,zmax]
; convert Z ticks to exponential notation if necessary
    sWps.rZaxis->GetProperty, $
        TICKVALUES=values
; use the Colorbartitle as the Z title
    values = WV_RESCALE_AXIS(values, $
        SCALE_FACTOR=Zscale_factor, $
        SCALE_STRING=Zscale_string, $
        TITLE=colorbartitle)
    IF (Zscale_factor NE 1) THEN BEGIN
        sWps.rZaxis->SetProperty, $
            RANGE=[zmin,zmax]/Zscale_factor
    ENDIF


; change ColorBar ticks
    sWps.rZaxis->GetProperty, $
        TICKVALUES=tickvalues, $
        TICKTEXT=Zticktext
    Zticktext->GetProperty,STRINGS=strings
    sWps.rColorBarTicktext->SetProperty, STRINGS=['',strings], $
        LOCATIONS=0
    tickvalues = [0,FIX(255.*(tickvalues*Zscale_factor-zmin)/(zmax-zmin))]
    sWps.rColorBar->SetProperty, $
        MAJOR=N_ELEMENTS(tickvalues), $
        TICKVALUES=tickvalues
    sWps.rColorBarTitle->SetProperty, STRINGS=colorbartitle


; change coord conversions for time series
    IF (oneD) THEN BEGIN
; find coord conversions
        sWps.rTimeSeries->GetProperty, $
            XRANGE=xrange, $
            YRANGE=yrange
        x0 = MIN(xrange,MAX=x1)
        y0 = MIN(yrange,MAX=y1)
        xstime = [-0.45 - FLOAT(x0)/(x1 - x0),1./(x1 - x0)]
        ystime = [0.1 - 0.4*FLOAT(y0)/(y1 - y0), 0.4/(y1 - y0)]

; change coord convert for time series
        sWps.rTimeSeries->SetProperty, $
            XCOORD_CONV=xstime,YCOORD_CONV=ystime

; fix time series Y axis
        sWps.rTsYaxis->SetProperty, $
            LOCATION=[xmin,y0,0], $
            RANGE=[y0,y1], $
            TICKLEN=0.02*(xmax-xmin), $
            XCOORD_CONV=xstime,YCOORD_CONV=ystime

; convert time series Y axis to exponential notation if necessary
        sWps.rTsYaxis->GetProperty, $
            TICKVALUES=values
        sWps.rTsYtitle->GetProperty, UVALUE=title
        values = WV_RESCALE_AXIS(values, $
            SCALE_FACTOR=tYscale_factor, $
            TITLE=title)
        IF (tYscale_factor NE 1) THEN BEGIN
            sWps.rTsYaxis->SetProperty, $
                RANGE=[y0,y1]/tYscale_factor, $
                LOCATION=[xmin,y0/tYscale_factor,0], $
                YCOORD_CONV=[ystime[0],ystime[1]*tYscale_factor]
            sWps.rTsYtitle->SetProperty, STRINGS=title
        ENDIF

; add data for global wavelet spectrum (GWS)
        sWps.rGws->SetProperty, $
            DATAX=*pY, $
            DATAY=REVERSE(*pGws), $
            MIN_VALUE=zmin, $
            XCOORD_CONV=ys2,YCOORD_CONV=zs

; change scaling for GWS "Z" (actually Y) axis
        sWps.rZaxis->SetProperty, $
            HIDE=0, $
            RANGE=[zmin,zmax]/Zscale_factor, $
            LOCATION=[ymax,zmin/Zscale_factor], $
            TICKLEN=0.02*(ymax-ymin), $
            XCOORD_CONV=ys2, $
            YCOORD_CONV=[zs[0],zs[1]*Zscale_factor]

; put just the exponential notation on the Zaxis title
        sWps.rZtitle->SetProperty, STRINGS='Mean '+Zscale_string

; reverse direction of Y axis
        sWps.rYaxis->GetProperty, $
            RANGE=range, $
            TICKVALUES=tickvalues

;   invert the axis values
        new_tickv = range[0]+range[1]-tickvalues

;   convert values to powers-of-two
        dt = (*pX)[1] - (*pX)[0]
        power2_tickv = dt*(2d^tickvalues)

;   check if exponential notation necessary?
        IF (N_ELEMENTS(Xexponent) EQ 1) THEN BEGIN
            sWps.rYtitle->GetProperty, $
                UVALUE=ytitle_str
            power2_tickv = WV_RESCALE_AXIS(power2_tickv, $
                EXPONENT=Xexponent, $
                TITLE=ytitle_str)
            sWps.rYtitle->SetProperty, $
                STRINGS=ytitle_str
        ENDIF

;   fake the axis to construct the tick labels
        sWps.rYaxis->SetProperty, $
            MAJOR=N_ELEMENTS(power2_tickv), $
            TICKVALUES=power2_tickv

;   get the newly-constructed labels
        sWps.rYaxis->GetProperty, $
            TICKTEXT=ticktext
        ticktext->GetProperty,STRINGS=strings

;   convert back to non-power-of-two tick values
        sWps.rYaxis->SetProperty, $
            MAJOR=N_ELEMENTS(new_tickv), $
            TICKVALUES=new_tickv

;   but use the power-of-two tick labels
        ticktext->SetProperty, $
            STRINGS=strings
    ENDIF  ; oneD


; add data to contour plots
    n_levels = 15
    c_value = INTERPOL([zmin,zmax],n_levels)
    c_color = BYTSCL(INDGEN(n_levels))
    sWps.rLineContour->GetProperty, $
        PLANAR=planar,UVALUE=top
    zvalues = TEMPORARY(zvalues) + 1e-2*(zmax-zmin)
; Pass in a scalar geomz in case /PLANAR is set (ignored if PLANAR=0).
    geomz = top ? zmax : zmin
    sWps.rLineContour->SetProperty, $
        C_VALUE=c_value, $
        DATA_VALUES=zvalues, $
        GEOMX=*pX, GEOMY=*pY, GEOMZ=geomz, $
        PLANAR=planar, $
        XCOORD_CONV=xs, YCOORD_CONV=ys2, ZCOORD_CONV=zs

    sWps.rColorContour->GetProperty, $
        PLANAR=planar,UVALUE=top
; Pass in a scalar geomz in case /PLANAR is set (ignored if PLANAR=0).
    geomz = top ? zmax : zmin
    sWps.rColorContour->SetProperty, $
        C_VALUE=c_value, $
        C_COLOR=c_color, $
        DATA_VALUES=zvalues, $
        GEOMX=*pX, GEOMY=*pY, GEOMZ=geomz, $
        XCOORD_CONV=xs, YCOORD_CONV=ys2, ZCOORD_CONV=zs


; redraw significance level
    sWps.rSignifSheet->SetProperty, $
        XCOORD_CONV=xs, YCOORD_CONV=ys2, ZCOORD_CONV=zs
; redraw text label
    sWps.rSignifText->SetProperty, $
        XCOORD_CONV=xs, YCOORD_CONV=ys, ZCOORD_CONV=zs

; redraw significance contour
    sWps.rSignifContour->GetProperty, $
        PLANAR=planar,UVALUE=top
; Pass in a scalar geomz in case /PLANAR is set (ignored if PLANAR=0).
    geomz = top ? zmax : zmin
    sWps.rSignifContour->SetProperty, $
        DATA_VALUES=zvalues, $
        GEOMX=*pX, GEOMY=*pY, GEOMZ=geomz, $
        XCOORD_CONV=xs, YCOORD_CONV=ys2, ZCOORD_CONV=zs


    IF (N_ELEMENTS(*pPhase) GT 1) THEN BEGIN
        top = 255b
        phaseScale = BYTSCL(SQRT(ABS(*pPhase)), $
            MIN=0, MAX=SQRT(!PI), TOP=top)+(255b-top)
        data = [[[phaseScale*0b+255b]],[[phaseScale]]]
        sWps.rPhaseImage->SetProperty, $
            DATA=data, $
            BLEND_FUNCTION=[3,1], $
            INTERLEAVE=2
    ENDIF ELSE BEGIN
;       sWps.rSurface->SetProperty, $
;           TEXTURE_MAP=OBJ_NEW()
        sWps.rPhaseImage->SetProperty, $
            DATA=BYTARR(2,2,2)+255b, $
            BLEND_FUNCTION=[1,2]
    ENDELSE


    RETURN
END ; wv_plot3d_redraw


;--------------------------------------------------------------------
;Purpose: create objects related to the WPS.
;
FUNCTION wv_plot3d_init,array,x,y, $
    TITLE=title, $
    XTITLE=xtitle, $
    YTITLE=ytitle, $
    XUNITS=xunits, $
    YUNITS=yunits, $
    UNITS=units, $
    DRAW_XSIZE=draw_xsize, $
    DRAW_YSIZE=draw_ysize, $
    SURFACE_STYLE=surface_style

    COMPILE_OPT strictarr, hidden

; Set all the defaults
    dim = SIZE(array, /DIMENSIONS)
    oneD = SIZE(array, /N_DIM) EQ 1
    IF (N_ELEMENTS(x) LT 1) THEN x = LINDGEN(dim[0])
    IF (N_ELEMENTS(y) LT 1) THEN y = oneD ? 0 : LINDGEN(dim[1])
    IF (N_ELEMENTS(xtitle) LE 0) THEN xtitle = 'X'
    IF (N_ELEMENTS(ytitle) LE 0) THEN ytitle = 'Y'
    IF (N_ELEMENTS(xunits) LE 0) THEN xunits = ''
    IF (N_ELEMENTS(yunits) LE 0) THEN yunits = ''
    IF (N_ELEMENTS(units) LE 0) THEN units = ''
    IF (N_ELEMENTS(surface_style) LE 0) THEN surface_style = 3


; Create a view
    rView = OBJ_NEW('IDLgrView', $
        COLOR = [208, 208, 208], $
;       COLOR = [128, 128, 128], $
        VIEWPLANE_RECT = [-1.,-1.,2.,2.]);, $
;       EYE=16, $
;       ZCLIP=[15,-15])

; Create models
    rTop = OBJ_NEW('IDLgrModel')
    rGroup = OBJ_NEW('IDLgrModel')

; Create dummy container to make it easier to destroy objects
    rContainer = OBJ_NEW('IDL_Container')

    rFont = OBJ_NEW('IDLgrFont')
    rContainer->Add, rFont

; create axes
    extra = {exact:1, $   ; keywords for all axes
        hide:1, $
        minor:1, $
        tickdir:1}
; Xaxis
    xtitle_str = xtitle
    IF (NOT oneD) THEN xtitle_str = 'X Scale'
    rXtitle = OBJ_NEW('IDLgrText', xtitle_str, $
        /ENABLE_FORMATTING, $
        FONT=rFont, $
        RECOMPUTE_DIMENSIONS=2, $
        UVALUE=xtitle_str)
    rContainer->Add, rXtitle

    rXaxis = OBJ_NEW('IDLgrAxis',0, $
        _EXTRA=extra,TITLE=rXtitle)
    rXaxis->GetProperty, TICKTEXT=ticktext
    ticktext->SetProperty, $
        FONT=rFont, $
        RECOMPUTE_DIMENSIONS=2

; Yaxis
    IF (oneD) THEN BEGIN
        ytitle_str = 'Scale'
        IF (xunits NE '') THEN ytitle_str = ytitle_str + ' (' + xunits + ')'
    ENDIF ELSE BEGIN
        ytitle_str = 'Y Scale'
    ENDELSE
    rYtitle = OBJ_NEW('IDLgrText', ytitle_str, $
        /ENABLE_FORMATTING, $
        FONT=rFont, $
        RECOMPUTE_DIMENSIONS=2, $
        UVALUE=ytitle_str)
    rContainer->Add, rYtitle

    rYaxis = OBJ_NEW('IDLgrAxis',1, $
        _EXTRA=extra,TITLE=rYtitle)
    rYaxis->GetProperty, TICKTEXT=ticktext
    ticktext->SetProperty, $
        FONT=rFont, $
        RECOMPUTE_DIMENSIONS=2

; Zaxis
    ztitle_str = ''
    rZtitle = OBJ_NEW('IDLgrText', ztitle_str, $
        /ENABLE_FORMATTING, $
        FONT=rFont, $
        RECOMPUTE_DIMENSIONS=2, $
        UVALUE=ztitle_str)
    rContainer->Add, rZtitle

    rZaxis = OBJ_NEW('IDLgrAxis',1, $
        _EXTRA=extra, $
        TEXTPOS=1, $
        TITLE=rZtitle)
    rContainer->Add, rZaxis
    rZaxis->GetProperty, TICKTEXT=ticktext
    ticktext->SetProperty, $
        /ENABLE_FORMATTING, $
        FONT=rFont, $
        RECOMPUTE_DIMENSIONS=2

; Create color palettes FOR WPS.
    gray = REPLICATE(128b,256)
    rGrayPalette = OBJ_NEW('IDLgrPalette', $
        gray, gray, gray)
    rContainer->Add, rGrayPalette

    rColorPalette = OBJ_NEW('IDLgrPalette')
    rColorPalette->LOADCT, 39 ; "rainbow+white"
    rContainer->Add, rColorPalette

    rPhaseImage = OBJ_NEW('IDLgrImage', $
        HIDE=0)
    rContainer->Add, rPhaseImage

; Create surface plot
    rSurface = OBJ_NEW('IDLgrSurface', $
        COLOR=[255,255,255], $
        EXTENDED=0, $
        HIDE=0, $
        PALETTE=rColorPalette, $
        SHADING=1, $
        SHADE_RANGE=[0b,255b], $
        SHOW_SKIRT=0, $
        STYLE=surface_style-1, $
        UVALUE=0)

; Create the filled contour version OF the WPS.
    rColorContour = OBJ_NEW('IDLgrContour', $
        DATA_VALUES=FLTARR(2,2), $
        FILL=0, $
        HIDE=1, $
        PALETTE=rColorPalette, $
        UVALUE=0)

; Create the line contour version OF the WPS.
    rLineContour = OBJ_NEW('IDLgrContour', $
        C_LINESTYLE=0, $
        COLOR=[255,255,255], $
        DATA_VALUES=FLTARR(2,2), $
        HIDE=1, $
        FILL=0, $
        UVALUE=0)

; Create the significance polygon sheet
    rSignifSheet = OBJ_NEW('IDLgrPolygon', $
        /HIDE, $
        PALETTE=rColorPalette)
    rSignifText = OBJ_NEW('IDLgrText', $
        /ENABLE_FORMATTING, $
        FONT=rFont, $
        /HIDE, $
        PALETTE=rColorPalette, $
        RECOMPUTE_DIMENSIONS=2)

; Create the line contour version OF the WPS.
    rSignifContour = OBJ_NEW('IDLgrContour', $
        C_LINESTYLE=0, $
        COLOR=[255,255,255], $
        DATA_VALUES=FLTARR(2,2), $
        HIDE=1, $
        FILL=0, $
        C_THICK=[2], $
        UVALUE=0)

; Add objects to the model
    rGroup->Add, rSurface
    rGroup->Add, rXaxis
    rGroup->Add, rYaxis
    rGroup->Add, rColorContour
    rGroup->Add, rLineContour
    rGroup->Add, rSignifSheet
    rGroup->Add, rSignifText
    rGroup->Add, rSignifContour

; Create the 1D time series
    rTimeSeries = 0
    rTsYaxis = 0
    rTsYtitle = 0
    rGws = 0
    rTsModel = 0
    rGwsModel = 0
    IF oneD THEN BEGIN ; oneD
        rTimeSeries = OBJ_NEW('IDLgrPlot',x,array, $
            HIDE=0, $
            THICK=2)
        rTsYtitle = OBJ_NEW('IDLgrText', ytitle, $
            /ENABLE_FORMATTING, $
            FONT=rFont, $
            RECOMPUTE_DIMENSIONS=2, $
            UVALUE=ytitle)
        rContainer->Add, rTsYtitle
        rTsYaxis = OBJ_NEW('IDLgrAxis',1, $
            HIDE=0, $
            /EXACT, $
            MINOR=1, $
            TITLE=rTsYtitle)
        rTsYaxis->GetProperty, TICKTEXT=ticktext
        ticktext->SetProperty, $
            FONT=rFont, $
            RECOMPUTE_DIMENSIONS=2
        rTsModel = OBJ_NEW('IDLgrModel',LIGHTING=0)
        rTsModel->Add, rTimeSeries
        rTsModel->Add, rTsYaxis
        rTsModel->Rotate, [1,0,0], 90  ; bend up
        rTsModel->Translate, 0, 0.57, 0 ; move farther back
        rGws = OBJ_NEW('IDLgrPlot', $
            HIDE=0, $
            THICK=2)
        rGwsModel = OBJ_NEW('IDLgrModel',LIGHTING=0)
        rGwsModel->Add, rGws
        rGwsModel->Rotate, [1,0,0], 90
        rGwsModel->Rotate, [0,0,1], -90
        rGwsModel->Translate, 0.62, 0.1, 0 ; move farther to the right
        rGwsModel->Add, rZaxis
        rGroup->Add, rTsModel
        rGroup->Add, rGwsModel
    ENDIF ; oneD

; Place the model in the view.
    rTop->Add, rGroup
    rView->Add, rTop

; Add lights
    rAmbientLight = OBJ_NEW('IDLgrLight', TYPE=0, INTENSITY=1)
    rTop->Add, rAmbientLight
    rDirectionalLight = OBJ_NEW('IDLgrLight', $
        LOCATION=[0.4,0.4,1], $
        INTENSITY=1, $
        TYPE=2)
    rTop->Add,rDirectionalLight

; Add colorbar legend.
    rColorBarTitle = OBJ_NEW('IDLgrText', 'Power', $
        /ENABLE_FORMATTING, $
        FONT=rFont, $
        RECOMPUTE_DIMENSIONS=2, $
        UVALUE='')
    rContainer->Add, rColorBarTitle
    rColorBarTicktext = OBJ_NEW('IDLgrText',[' ',' '], $
        FONT=rFont, $
        RECOMPUTE_DIMENSIONS=2)
    rContainer->Add, rColorBarTicktext

    maxLen = 256
    xs = [-0.45, 1.0 / maxLen]
    ys = [-.74, 1.0 / maxLen]
    zs = [0.0, 1.0 / maxLen]
    rColorBar = OBJ_NEW('IDLgrColorBar', $
        DIMENSIONS=[256,16], $
        HIDE=0, $
        MAJOR=2, $
        MINOR=0, $
        PALETTE=rColorPalette, $
        SHOW_AXIS=2, $
        /SHOW_OUTLINE, $
        /THREED, $
        TICKLEN=4, $
        TICKTEXT=rColorBarTicktext, $
        TITLE=rColorBarTitle, $
        XCOORD_CONV=xs, YCOORD_CONV=ys);, ZCOORD_CONV=zs)

    rGroup->Add, rColorbar

; Rotate to a nice perspective FOR first draw.
    rGroup->ROTATE, [0,0,1], 25
    rGroup->ROTATE, [1,0,0], -30

    rTrackballRotate = OBJ_NEW('Trackball', $
        [draw_xsize/2, draw_ysize/2.], $
        draw_xsize/2.)
    rContainer->Add, rTrackballRotate

    rTrackballScale= OBJ_NEW('Trackball', $
        [draw_xsize/2, draw_ysize/2.], $
        draw_xsize/2.,MOUSE=2)
    rContainer->Add, rTrackballScale

    rTrackballTranslate = OBJ_NEW('Trackball', $
        [draw_xsize/2, draw_ysize/2.], $
        draw_xsize/2.,MOUSE=4)
    rContainer->Add, rTrackballTranslate

    rView->SetProperty, UVALUE= $
        {rView:rView, $
        rTop:rTop, $
        rGroup:rGroup, $
        rContainer:rContainer, $
        rFont:rFont, $
        rXaxis:rXaxis, $
        rYaxis:rYaxis, $
        rZaxis:rZaxis, $
        rXtitle:rXtitle, $
        rYtitle:rYtitle, $
        rZtitle:rZtitle, $
        rLineContour:rLineContour, $
        rColorContour:rColorContour, $
        rSignifSheet:rSignifSheet, $
        rSignifText:rSignifText, $
        rSignifContour:rSignifContour, $
        rPhaseImage:rPhaseImage, $
        rSurface:rSurface, $
        rTimeSeries:rTimeSeries, $
        rGws:rGws, $
        rTsModel:rTsModel, $
        rGwsModel:rGwsModel, $
        rTsYaxis:rTsYaxis, $
        rTsYtitle:rTsYtitle, $
        rColorPalette:rColorPalette, $
        rGrayPalette:rGrayPalette, $
        rColorBar:rColorBar, $
        rColorBarTitle:rColorBarTitle, $
        rColorBarTicktext:rColorBarTicktext, $
        rTrackballRotate:rTrackballRotate, $
        rTrackballScale:rTrackballScale, $
        rTrackballTranslate:rTrackballTranslate, $
        rDirectionalLight:rDirectionalLight}

; Create the info structure
    meanArray = TOTAL(array)/N_ELEMENTS(array)
    varArray = VARIANCE(array)

    rState = { $
        base_size: [0L,0L], $
        file_path:'', $
        oneD: oneD, $
        pData: PTR_NEW(array - meanArray), $
        pXdata: PTR_NEW(x), $
        pYdata: PTR_NEW(y), $
        pColortable: PTR_NEW(/ALLOCATE_HEAP), $
        meanArray: meanArray, $
        varArray: varArray, $
        var_zscale: 0.0, $
        xtitle:xtitle, $
        xunits:xunits, $
        ytitle:ytitle, $
        yunits:yunits, $
        title:title, $
        units:units, $
        WPS_drag_quality: 1b, $
        btndown: 0b, $
        draw_xsize: draw_xsize, $
        draw_ysize: draw_ysize, $
        rView: rView, $
        rContainer: rContainer, $
        rPrinter: OBJ_NEW(), $
        rClipboard: OBJ_NEW(), $
        rVRML: OBJ_NEW(), $
        pWavelet: PTR_NEW(/ALLOCATE_HEAP), $
        pX: PTR_NEW(/ALLOCATE_HEAP), $
        pY: PTR_NEW(/ALLOCATE_HEAP), $
        pZ: PTR_NEW(/ALLOCATE_HEAP), $
        pGws: PTR_NEW(/ALLOCATE_HEAP), $
        pPhase: PTR_NEW(0) $
    }

    RETURN, rState
END ; wv_plot3d_init


;--------------------------------------------------------------------
FUNCTION wv_plot3d_location, dataxyz, inside, $
    pX, pY, pZ, pW, oneD

    COMPILE_OPT strictarr, hidden

    CASE (inside) OF
    -1: BEGIN
        CASE STRLOWCASE(!VERSION.OS_FAMILY) OF
        'macos': location = 'Mouse button to rotate, ' + $
            '<Option>+button to stretch, ' + $
            '<Command>+button to translate.'
        'windows':location = 'Left mouse button to rotate, ' + $
            '<Ctrl>+Left button to stretch, ' + $
            'Right button to translate.'
        ELSE: location = 'Left mouse button to rotate, ' + $
            'Middle to stretch, ' + $
            'Right to translate.'
        ENDCASE
        END
    0: location = ''
    1: BEGIN
        ix = MAX(WHERE(*pX LE dataxyz[0]))
        iy = MAX(WHERE(*pY LE dataxyz[1]))
        IF ((ix EQ -1) OR (iy LE -1)) THEN RETURN,''
        x = (*pX)[ix]
        y = (*pY)[iy]
        z = (*pZ)[ix,iy]
        power = ABS((*pW)[ix,iy])^2
        IF oneD THEN BEGIN ; convert scale from log2 to actual value
            dt = (*pX)[1] - (*pX)[0]
            y = dt*(2d^y)
        ENDIF
        location = STRCOMPRESS(STRING(x,y,z,power, $
            FORMAT='("Power at (",G10.4,", ",G10.4,", ",G12.6,") = ",G12.6)'))
        END
    ELSE: MESSAGE, 'Unknown mouse location.'
    ENDCASE
    RETURN, location
END ; wv_plot3d_location


;--------------------------------------------------------------------
PRO wv_plot3d_file_restore_event, event

    COMPILE_OPT strictarr, hidden

    ON_ERROR, 2

    WIDGET_CONTROL, Event.top, $
        GET_UVALUE=pState, $
        TLB_GET_OFFSET=tlb_offset

    suffix = '.sav'
pick_again:
    filename = DIALOG_PICKFILE( $
        GROUP=Event.top, $
        FILTER='*'+suffix, $
        GET_PATH=file_path, $
        PATH=(*pState).file_path, $
        TITLE='Open State')
    IF (filename EQ '') THEN RETURN

    WIDGET_CONTROL,/HOURGLASS

; save the file path
    (*pState).file_path = file_path

    IF ((FILE_SEARCH(filename))[0] EQ '') THEN BEGIN
        result = DIALOG_MESSAGE( $
            ['Cannot open the file', $
            '"'+filename+'"'], $
            DIALOG_PARENT=Event.top, $
            /ERROR,TITLE='Open State Error')
        RETURN
    ENDIF

; fire up the new Widget
    newId = WV_PLOT3D_WPS(filename, $
        XOFFSET=tlb_offset[0]+20, $
        YOFFSET=tlb_offset[1]+20)
    RETURN

END  ; wv_plot3d_file_restore_event


;--------------------------------------------------------------------
PRO wv_plot3d_file_save_event, event

    COMPILE_OPT strictarr, hidden

    ON_ERROR, 2

    WIDGET_CONTROL, Event.top, GET_UVALUE=pState

    suffix = '.sav'
pick_again:
    filename = DIALOG_PICKFILE(/WRITE, $
        GROUP=Event.top, $
        FILTER='*'+suffix, $
        GET_PATH=file_path, $
        PATH=(*pState).file_path, $
        TITLE='Save State As')
    IF (filename EQ '') THEN RETURN
    IF ((FILE_SEARCH(filename))[0] NE '') THEN BEGIN
        result = DIALOG_MESSAGE([filename, $
            'This file already exists.', $
            'Do you want to replace it?'], $
            DIALOG_PARENT=Event.top, $
            /QUESTION,TITLE='Save State As')
        IF (result EQ 'No') THEN GOTO,pick_again
    ENDIF
    suffix_pos = STRPOS(filename,suffix)
    correct_suffix = suffix_pos EQ (STRLEN(filename)-STRLEN(suffix))
    IF ((NOT correct_suffix) AND $
        (!VERSION.OS_FAMILY EQ 'Windows')) THEN $
        filename = filename + suffix

    WIDGET_CONTROL,/HOURGLASS

; save the file path
    (*pState).file_path = file_path

    copyState = *pState

; Update data pointers
    (*pState).pX = PTR_NEW([1,2])
    (*pState).pY = PTR_NEW([1,2])
    (*pState).pWavelet = PTR_NEW(FINDGEN(2,2))
    (*pState).pPhase = PTR_NEW(0)

; update the plot by sending a Zscale event
    WV_PLOT3D_ZSCALE_EVENT, {ID:(*pState).wPowerScale, $
        TOP:(*pState).wEnergyBase, $
        HANDLER:(*pState).wEnergyBase, $
        INDEX:(*pState).sPowerScale}, $
        /NO_DRAW

    SAVE, pState, FILE=filename

    *pState = copyState

; update the plot by sending a Zscale event
    WV_PLOT3D_ZSCALE_EVENT, {ID:(*pState).wPowerScale, $
        TOP:(*pState).wEnergyBase, $
        HANDLER:(*pState).wEnergyBase, $
        INDEX:(*pState).sPowerScale}, $
        /NO_DRAW
    RETURN

END  ; wv_plot3d_file_save_event


;--------------------------------------------------------------------
PRO wv_plot3d_font_event, event

    COMPILE_OPT strictarr, hidden

    ON_ERROR, 2

    WIDGET_CONTROL, Event.top, GET_UVALUE=pState
    WIDGET_CONTROL, (*pState).wDraw, GET_VALUE=rWindow
    (*pState).rView->GETPROPERTY,UVALUE=sWps
    sWps.rFont->SetProperty, $
        NAME=event.name, $
        SIZE=event.size
    rWindow->Draw, sWps.rView
END


;--------------------------------------------------------------------
PRO wv_plot3d_draw_event, event

    COMPILE_OPT strictarr, hidden

    ON_ERROR, 2

    WIDGET_CONTROL, Event.top, GET_UVALUE=pState
    WIDGET_CONTROL, (*pState).wDraw, GET_VALUE=rWindow
    (*pState).rView->GETPROPERTY,UVALUE=sWps

    IF (Event.type EQ 4) THEN BEGIN ; expose & redraw
        WIDGET_CONTROL,/HOURGLASS
        rWindow->Draw, sWps.rView
        RETURN
    ENDIF

; Button events
    CASE (Event.type) OF
    0: BEGIN ; button press
        (*pState).btndown = Event.press
        sWps.rGroup->GetProperty, TRANSFORM=old_transform
        sWps.rGroup->SetProperty, UVALUE=old_transform ; save transform
        WIDGET_CONTROL,(*(*pState).wMenuID).Undo, $
            /SENSITIVE,SET_VALUE='Undo'
        CASE Event.press OF
            1: void = sWps.rTrackballRotate->Update(event)
            2: void = sWps.rTrackballScale->Update(event,/TRANSLATE)
            4: void = sWps.rTrackballTranslate->Update(event,/TRANSLATE)
            ELSE: MESSAGE, 'Unknown mouse press.'
        ENDCASE
        quality = (*pState).WPS_drag_quality
        CASE (quality) OF
        0: BEGIN
            sWps.rColorContour->GetProperty, HIDE=hide
            sWps.rColorContour->SetProperty, HIDE=1, UVALUE=hide
            sWps.rSurface->GetProperty, HIDE=hide
            sWps.rSurface->SetProperty, HIDE=1, UVALUE=hide
            END
        1: rWindow->SetProperty, QUALITY=0
        2: rWindow->SetProperty, QUALITY=2
        ELSE: MESSAGE,'Unknown drag quality.'
        ENDCASE
        rWindow->Draw, sWps.rView
        END ; Button press
    1: BEGIN ; Button release
        (*pState).btndown = 0
        WIDGET_CONTROL, /HOURGLASS
        CASE (*pState).WPS_drag_quality OF
        0: BEGIN
            sWps.rColorContour->GetProperty, UVALUE=hide
            sWps.rColorContour->SetProperty, HIDE=hide
            sWps.rSurface->GetProperty, UVALUE=hide
            sWps.rSurface->SetProperty, HIDE=hide
            END
        ELSE: rWindow->SetProperty, QUALITY=2
        ENDCASE
        rWindow->Draw, sWps.rView
        (*pState).btndown = 0b

;       sWps.rGroup->GetProperty, TRANSFORM=t
;       xTranslate = t[3,0]
;       yTranslate = t[3,1]
;       geom = WIDGET_INFO((*pState).wDraw,/GEOMETRY)
;       xCenter = geom.xsize*(0.5 + xTranslate/2.)
;       yCenter = geom.ysize*(0.5 + yTranslate/2.)
;       radius = (geom.xsize < geom.ysize)/2.
;       print,xcenter,ycenter
;       sWps.rTrackballRotate->Reset, [xCenter,yCenter], radius

        END
    2: BEGIN ; Button motion
        CASE (*pState).btndown OF
        1b: BEGIN ; Handle rotate trackball updates
            do_rotate = sWps.rTrackballRotate->Update(event, TRANSFORM=qmat, MOUSE=1)
            IF (do_rotate) THEN BEGIN
                sWps.rGroup->GetProperty, TRANSFORM=t
                sWps.rGroup->SetProperty, TRANSFORM=t#qmat  ; new transform
                rWindow->Draw, sWps.rView
                RETURN
            ENDIF
            END
        2b: BEGIN ; Handle scale trackball updates
            do_scale = sWps.rTrackballScale-> $
                Update(event, TRANSFORM=qmat,/TRANSLATE,MOUSE=2)
            IF (do_scale) THEN BEGIN ; convert from translate coords to scale
                sWps.rGroup->Scale,1.0 + qmat[3,0],1.0 + qmat[3,1],1,/PREMULTIPLY
                rWindow->Draw, sWps.rView
                RETURN
            ENDIF
            END
        4b: BEGIN ; Handle translate trackball updates
            do_translate = sWps.rTrackballTranslate-> $
                Update(event, TRANSFORM=qmat,/TRANSLATE,MOUSE=4)
            IF (do_translate) THEN BEGIN
                sWps.rGroup->GetProperty, TRANSFORM=t
                sWps.rGroup->SetProperty, TRANSFORM=t#qmat  ; new transform
                rWindow->Draw, sWps.rView
                RETURN
            ENDIF
            END
        ELSE: BEGIN ; no mouse button
            inside = rWindow->PickData( $
                sWps.rView, $
                sWps.rLineContour, $
                [Event.x,Event.y], $
                dataxyz $
                )
            IF ((Event.x LT 10) OR (Event.y LT 10)) THEN inside = -1
            location = WV_PLOT3D_LOCATION(dataxyz,inside, $
                (*pState).pX, (*pState).pY, (*pState).pZ, $
                (*pState).pWavelet, (*pState).oneD)
            IF (location NE '') THEN WIDGET_CONTROL,(*pState).wMessage, $
                SET_VALUE=location
            END
        ENDCASE ; (*pState).btndown
        END
    ELSE: MESSAGE, 'Unknown button event.'
    ENDCASE ; Button motion

END ; wv_plot3d_draw_event


;--------------------------------------------------------------------
PRO wv_plot3d_signif_event, Event

    COMPILE_OPT strictarr, hidden

    ON_ERROR, 2

    WIDGET_CONTROL, /HOURGLASS
    WIDGET_CONTROL, Event.top, GET_UVALUE=pState
    WIDGET_CONTROL, (*pState).wDraw, GET_VALUE=rWindow
    (*pState).rView->GETPROPERTY,UVALUE=sWps

    CASE Event.id OF
    (*pState).wSignifLevel: BEGIN ; Significance level
        (*pState).sSignifLevel = Event.index
        WIDGET_CONTROL, (*pState).wSignifLevel, GET_UVALUE=siglvls
        siglvl = siglvls[Event.index]
; compute significance level
        is_cmplx = SIZE(*(*pState).pWavelet,/TNAME) EQ 'DCOMPLEX'
        degreesFreedom = (is_cmplx) ? 2 : 1
        sig05 = CHISQR_CVF(siglvl,degreesFreedom)
        signif = (*pState).var_zscale
        CASE ((*pState).sPowerScale) OF
            0: signif = signif*sig05
            1: signif = signif*SQRT(sig05)
            2: signif = signif + 10*ALOG10(sig05)
            ELSE: MESSAGE,'Unknown power scaling.'
        ENDCASE
        sWps.rXaxis->GetProperty,RANGE=xrange
        sWps.rYaxis->GetProperty,RANGE=yrange
        sWps.rSurface->GetProperty,ZRANGE=zrange
; construct polygon sheet
        color = 255*(signif-zrange[0])/(zrange[1]-zrange[0])
        color = 0 > color < 255
        x = xrange[[0,1,1,0]]
        y = yrange[[0,0,1,1]]
        z = signif+[0,0,0,0]
        sWps.rSignifSheet->SetProperty, $
            DATA=TRANSPOSE([[x],[y],[z]]), $
            COLOR=color
; add text label
        siglvl_str = STRTRIM(siglvl*100.0,2)
        y = STRMID(siglvl_str,STRLEN(siglvl_str)-1,1)
        WHILE (y EQ '0') DO BEGIN
            siglvl_str = STRMID(siglvl_str,0,STRLEN(siglvl_str)-1)
            y = STRMID(siglvl_str,STRLEN(siglvl_str)-1,1)
        ENDWHILE
        IF (y EQ '.') THEN siglvl_str = $
            STRMID(siglvl_str,0,STRLEN(siglvl_str)-1)
        siglvl_str = siglvl_str + '%'
        sWps.rXaxis->GetProperty, $
            YCOORD_CONV=ys
        sWps.rSignifText->SetProperty, $
            STRINGS=siglvl_str, $
            COLOR=color, $
            LOCATION=[xrange[1],yrange[1],signif]
; add contour level
        sWps.rSignifContour->SetProperty, $
            C_VALUE=[signif]
        END ; Significance level
    (*pState).wSignifStyle: BEGIN ; Significance style
        (*pState).sSignifStyle = Event.index
        WIDGET_CONTROL, (*pState).wSignifLevel, $
            SENSITIVE=(Event.index GT 0)
        sWps.rSignifSheet->SetProperty, HIDE=(Event.index NE 1)
        sWps.rSignifText->SetProperty, HIDE=(Event.index NE 1)
        CASE (Event.index) OF ; style
            0: sWps.rSignifContour->SetProperty, /HIDE
            1: sWps.rSignifContour->SetProperty, /HIDE
            2: BEGIN
                sWps.rZaxis->GetProperty,RANGE=zrange
                sWps.rSignifContour->SetProperty, HIDE=0, $
                    GEOMZ=zrange[1], $
                    /PLANAR, $
                    UVALUE=1 ; contour top
                END
            3: BEGIN
                sWps.rZaxis->GetProperty,RANGE=zrange
                sWps.rSignifContour->SetProperty, HIDE=0, $
                    GEOMZ=zrange[0], $
                    /PLANAR, $
                    UVALUE=0 ; contour bottom
                END
            4: BEGIN ; contour 3D
                sWps.rSignifContour->GetProperty, DATA_VALUES=z
                sWps.rSignifContour->SetProperty, HIDE=0, $
                    PLANAR=0, $
                    GEOMZ=TEMPORARY(z)
                END
            ELSE: MESSAGE,'Unknown style'
        ENDCASE ; style
        END ; Significance style
        ELSE: MESSAGE,'Unknown event.'
    ENDCASE

    rWindow->Draw, sWps.rView
    RETURN
END ; wv_plot3d_signif_event


;--------------------------------------------------------------------
PRO wv_plot3d_wavelet_event, event

    COMPILE_OPT strictarr, hidden
    ON_ERROR, 2

    WIDGET_CONTROL, /HOURGLASS

    WIDGET_CONTROL, Event.handler, GET_UVALUE=wBase
    WIDGET_CONTROL, wBase, GET_UVALUE=pState
    WIDGET_CONTROL, (*pState).wDraw, GET_VALUE=rWindow
    (*pState).rView->GETPROPERTY,UVALUE=sWps
    (*pState).sWaveletFamily = Event.family
    (*pState).sWaveletOrder = Event.order

    wave_function = STRCOMPRESS('wv_fn_'+Event.family,/REMOVE_ALL)
    wInfo = CALL_FUNCTION(wave_function)
    CASE wInfo.discrete OF
        0: waveTransform = WV_PLOT3D_CWT(Event.family, Event.order, $
            *(*pState).pData, (*(*pState).pXdata), X=x, Y=y)
        1: waveTransform = WV_PLOT3D_DWT(Event.family, Event.order, $
            *(*pState).pData, (*(*pState).pXdata), X=x, Y=y)
        ELSE: MESSAGE, 'Unknown wavelet type'
    ENDCASE

    IF (*pState).oneD THEN BEGIN
        y = REVERSE(TEMPORARY(y))
;       waveTransform = ROTATE(TEMPORARY(waveTransform), 7)
    ENDIF

; Update data pointers
    *(*pState).pX = x
    *(*pState).pY = y
    *(*pState).pWavelet = TEMPORARY(waveTransform)

; compute phase?
    tname = SIZE(*(*pState).pWavelet,/TNAME)
    IF ((tname EQ 'COMPLEX') OR (tname EQ 'DCOMPLEX')) THEN BEGIN
        *(*pState).pPhase = ATAN(IMAGINARY(*(*pState).pWavelet), $
            DOUBLE(*(*pState).pWavelet))
        WIDGET_CONTROL, (*pState).wViewPhase, $
            SENSITIVE=1
    ENDIF ELSE BEGIN
        *(*pState).pPhase = 0
        IF WIDGET_INFO((*pState).wViewPhase, /VALID) THEN $
            WIDGET_CONTROL, (*pState).wViewPhase, $
                SENSITIVE=0
    ENDELSE

; update the plot by sending a Zscale event
    WV_PLOT3D_ZSCALE_EVENT, {id:(*pState).wPowerScale, $
        top:Event.top, handler:(*pState).wEnergyBase, $
        index:(*pState).sPowerScale}

    RETURN
END ; wv_plot3d_wavelet_event


;--------------------------------------------------------------------
PRO wv_plot3d_zscale_event, event, $
    NO_DRAW=no_draw

    COMPILE_OPT strictarr, hidden
    ON_ERROR, 2

    WIDGET_CONTROL, /HOURGLASS
    WIDGET_CONTROL, Event.handler, GET_UVALUE=wBase
    WIDGET_CONTROL, wBase, GET_UVALUE=pState
    WIDGET_CONTROL, (*pState).wDraw, GET_VALUE=rWindow
    (*pState).rView->GETPROPERTY,UVALUE=sWps

    CASE Event.id OF
; Energy scaling
    (*pState).wPowerScale: BEGIN
        IF (Event.index LT 99) THEN $  ; special case for wCutoff call
            (*pState).sPowerScale = Event.index
        CASE (*pState).sPowerScale OF
            0: BEGIN
                WIDGET_CONTROL, (*pState).wCutoff, SENSITIVE=0
                z = ABS(*(*pState).pWavelet)^2 ; power
                (*pState).var_zscale = (*pState).varArray
                colorbartitle = 'Power'
                units = (*pState).units
                IF (units NE '') THEN colorbartitle = colorbartitle + ' (' + $
                    units + '!U2!N)'
                END
            1: BEGIN
                WIDGET_CONTROL, (*pState).wCutoff, SENSITIVE=0
                z = ABS(*(*pState).pWavelet)   ; amplitude
                (*pState).var_zscale = SQRT((*pState).varArray)
                colorbartitle = 'Magnitude'
                units = (*pState).units
                IF (units NE '') THEN colorbartitle = colorbartitle + ' (' + $
                    units + ')'
                END
            2: BEGIN
                WIDGET_CONTROL, (*pState).wCutoff, SENSITIVE=1
                z = ABS(*(*pState).pWavelet)^2
                zmean = TOTAL(z)/N_ELEMENTS(z)
                z = TEMPORARY(z)/zmean   ; renormalize by mean
                zNonzero = WHERE(z GT 0.,nNonzero)
                IF (nNonzero EQ 0) THEN BEGIN ; all elements = 0.
                    z = TEMPORARY(z) + 1.0 ; make all elements = 1.
                ENDIF ELSE BEGIN ; restrict minimum to 1./zMax
                    z = MIN(z[zNonzero]) > TEMPORARY(z)
                ENDELSE
                z = 10.0*ALOG10(TEMPORARY(z)) ; decibels
                (*pState).var_zscale = 10.0*ALOG10((*pState).varArray/zmean)
                colorbartitle = 'Power (db)'
                zcutoff = (*pState).sCutoff
                END
            ELSE: BEGIN
                zcutoff = (*pState).sCutoff
                colorbartitle = 'Power (db)'
                END
        ENDCASE
        IF (N_ELEMENTS(z) GT 0) THEN BEGIN
            *(*pState).pGws = TOTAL(z,1)/N_ELEMENTS(z[*,0])
            *(*pState).pZ = TEMPORARY(z)
        ENDIF

        threeD = 1 - (*pState).sSurfaceFlat
; update all objects
        WV_PLOT3D_REDRAW, pState, $
            THREED=threeD, $
            ZCUTOFF=zcutoff, $
            COLORBARTITLE=colorbartitle

; Don't both to continue if /NO_DRAW, presumably within "Save State"
        IF KEYWORD_SET(no_draw) THEN RETURN

; update Zcutoff in case it's been changed by _REDRAW
        IF ((*pState).sPowerScale GE 2) THEN BEGIN
            WIDGET_CONTROL, (*pState).wCutoff, $
                SET_VALUE=zcutoff
            (*pState).sCutoff = zcutoff
        ENDIF
        WV_PLOT3D_SIGNIF_EVENT, $
            {id:(*pState).wSignifLevel, $
            top:wBase, handler:wBase, index:(*pState).sSignifLevel}
        RETURN  ; don't need to redraw since signif event did redraw
        END
; Decibel cutoff
    (*pState).wCutoff: BEGIN
        (*pState).sCutoff = Event.value
        IF ((*pState).sPowerScale EQ 2) THEN $
            WV_PLOT3D_ZSCALE_EVENT, {ID:(*pState).wPowerScale, $
                TOP:Event.top,HANDLER:Event.handler,INDEX:99}
        END
    ELSE: MESSAGE, 'Unknown event.'
    ENDCASE
    RETURN
END ; wv_plot3d_zscale_event


;--------------------------------------------------------------------
PRO wv_plot3d_options_event, event

    COMPILE_OPT strictarr, hidden
    ON_ERROR, 2

    WIDGET_CONTROL, /HOURGLASS
    WIDGET_CONTROL, Event.top, GET_UVALUE=pState
    WIDGET_CONTROL, (*pState).wDraw, GET_VALUE=rWindow
    (*pState).rView->GETPROPERTY,UVALUE=sWps

    CASE Event.id OF
; Line contours
    (*pState).wLineContour: BEGIN
        (*pState).sLineContour = Event.index
        CASE Event.index OF
            0: sWps.rLineContour->SetProperty, HIDE=1 ; contour lines off
            1: BEGIN
                sWps.rLineContour->GetProperty, MAX_VALUE=zmax
                sWps.rLineContour->SetProperty, HIDE=0, $
                    /PLANAR, GEOMZ=zmax, $
                    UVALUE=1 ; top
                END
            2: BEGIN
                sWps.rLineContour->GetProperty, MIN_VALUE=zmin
                sWps.rLineContour->SetProperty, HIDE=0, $
                    /PLANAR, GEOMZ=zmin, $
                    UVALUE=0 ; bottom
                END
            3: BEGIN
                sWps.rLineContour->GetProperty, DATA_VALUES=z
                sWps.rLineContour->SetProperty, HIDE=0, $
                    PLANAR=0, GEOMZ=TEMPORARY(z)
                END
            ELSE: MESSAGE, 'Unknown line contour item.'
        ENDCASE
        END
; Color contours
    (*pState).wColorContour: BEGIN
        (*pState).sColorContour = Event.index
        CASE Event.index OF
            0: sWps.rColorContour->SetProperty, HIDE=1 ; contour lines off
            1: BEGIN
                sWps.rColorContour->GetProperty, MAX_VALUE=zmax
                sWps.rColorContour->SetProperty, HIDE=0, $
                    /PLANAR, GEOMZ=zmax, $
                    UVALUE=1 ; top
                END
            2: BEGIN
                sWps.rColorContour->GetProperty, MIN_VALUE=zmin
                sWps.rColorContour->SetProperty, HIDE=0, $
                    /PLANAR, GEOMZ=zmin, $
                    UVALUE=0 ; bottom
                END
            3: BEGIN
                sWps.rColorContour->GetProperty, DATA_VALUES=z
                sWps.rColorContour->SetProperty, HIDE=0, $
                    PLANAR=0, GEOMZ=TEMPORARY(z)
                END
            ELSE: MESSAGE, 'Unknown color contour item.'
        ENDCASE
        WIDGET_CONTROL, (*pState).wColorContourFillButton, $
            SENSITIVE=(Event.index NE 0)
        END
; Color contour fill
    (*pState).wColorContourFillButton: BEGIN
        (*pState).sColorContourFillButton = Event.select
        sWps.rColorContour->SetProperty, FILL=Event.select
        END
; Surface
    (*pState).wSurfaceStyle: BEGIN
        old_index = (*pState).sSurfaceStyle
        IF (Event.index EQ old_index) THEN RETURN ; no change
        (*pState).sSurfaceStyle = Event.index
        IF (Event.index EQ 0) THEN BEGIN ; no surface
            sWps.rSurface->SetProperty, /HIDE
            WIDGET_CONTROL, (*pState).wSkirtButton, SENSITIVE=0
            WIDGET_CONTROL, (*pState).wSurfaceFlat, SENSITIVE=0
            WIDGET_CONTROL, (*pState).wPaletteButton, SENSITIVE=0
        ENDIF ELSE BEGIN ; surface style
            style = Event.index - 1
            old_style = old_index - 1
            sWps.rSurface->SetProperty, HIDE=0, $
                STYLE=style
            WIDGET_CONTROL, (*pState).wSkirtButton, SENSITIVE=1
            WIDGET_CONTROL, (*pState).wSurfaceFlat, SENSITIVE=1
            WIDGET_CONTROL, (*pState).wPaletteButton, SENSITIVE=1
;           IF (((old_style GE 5) AND (style LE 4)) $
;               OR ((old_style LE 4) AND (style GE 5))) THEN BEGIN ; lego
;               zscale = WIDGET_INFO((*pState).wPowerScale, /DROPLIST_SELECT)
;               IF (zscale EQ 2) THEN $
;                   WIDGET_CONTROL, (*pState).wCutoff, GET_VALUE=zcutoff
;               WV_PLOT3D_REDRAW,(*pState).rView, $
;                   (*pState).pX, (*pState).pY, (*pState).pZ, $
;                   ZCUTOFF=zcutoff
;           ENDIF ; lego
        ENDELSE ; surface style
        END

; Surface skirt
    (*pState).wSkirtButton: BEGIN
        (*pState).sSkirtButton = Event.select
        sWps.rSurface->SetProperty,SHOW_SKIRT=Event.select
        END

; Surface 3D
    (*pState).wSurfaceFlat: BEGIN
        sWps.rLineContour->GetProperty,DATA_VALUES=zvalues,ZRANGE=zrange
        sWps.rZaxis->GetProperty,RANGE=zrange
        offset = 0
        IF (Event.select EQ 1) THEN offset = zrange[0]
        sWps.rSurface->SetProperty, $
            DATAZ=TEMPORARY(zvalues)*(1-Event.select)+offset
        (*pState).sSurfaceFlat = Event.select
        sWps.rDirectionalLight->SetProperty, HIDE=Event.select
        END

; Palette
    (*pState).wPaletteButton: BEGIN
        (*pState).sPaletteButton = Event.select
        CASE (Event.select) OF
            0: sWps.rSurface->SetProperty, $
                PALETTE=sWps.rColorPalette
            1: sWps.rSurface->SetProperty, $
                PALETTE=sWps.rGrayPalette
            ELSE: MESSAGE, 'Unknown palette button selection.'
        ENDCASE
        END

; Two/three dimensional
    (*pState).wView3dButton: BEGIN
        (*pState).sView3dButton = Event.select
        WIDGET_CONTROL,(*(*pState).wMenuID).Undo, SENSITIVE=0  ; can't undo
        CASE (Event.select) OF
            0: BEGIN
                sWps.rGroup->GetProperty, TRANSFORM=transform
                xscale = SQRT(TOTAL(transform[0,0:2]^2,/DOUBLE))
                yscale = SQRT(TOTAL(transform[1,0:2]^2,/DOUBLE))
                transform = IDENTITY(4)
                transform[0,0] = xscale
                transform[1,1] = yscale
                sWps.rGroup->SetProperty, TRANSFORM=transform
                IF OBJ_VALID(sWps.rTsModel) THEN BEGIN
                    sWps.rTsModel->Rotate, [1,0,0], -90, $
                        /PREMULTIPLY ; flatten
                    sWps.rTsModel->Scale, 1, 0.75, 1, $
                        /PREMULTIPLY ; shrink
                    sWps.rGwsModel->Rotate, [1,0,0], -90, $
                        /PREMULTIPLY ; flatten
                    sWps.rGwsModel->Scale, 1, 0.5, 1, $
                        /PREMULTIPLY ; shrink
                ENDIF
                END
            1: BEGIN
                sWps.rGroup->GetProperty, TRANSFORM=transform
                off_diagonal = [transform[0,1],transform[1,0], $
                    transform[0,2],transform[2,0], $
                    transform[1,2],transform[2,1]]
                IF (TOTAL(off_diagonal NE 0.0) EQ 0) THEN BEGIN ; flat->rotated
                    sWps.rGroup->ROTATE, [0,0,1], 25
                    sWps.rGroup->ROTATE, [1,0,0], -30
                ENDIF
                IF OBJ_VALID(sWps.rTsModel) THEN BEGIN
                    sWps.rTsModel->Scale, 1, 1./0.75, 1, $
                        /PREMULTIPLY ; expand
                    sWps.rTsModel->Rotate, [1,0,0], 90, $
                        /PREMULTIPLY   ; bend up
                    sWps.rGwsModel->Scale, 1, 2, 1, $
                        /PREMULTIPLY ; expand
                    sWps.rGwsModel->Rotate, [1,0,0], 90, $
                        /PREMULTIPLY ; bend up
                ENDIF
                END
            ELSE: MESSAGE, 'Unknown 3D button selection.'
        ENDCASE
        END

; View/hide color bar
    (*pState).wViewColorBar: BEGIN
        (*pState).sViewColorBar = Event.select
        sWps.rColorBar->SetProperty, HIDE=1-Event.select
        END

; View/hide time series
    (*pState).wViewData: BEGIN
        (*pState).sViewData = Event.select
        sWps.rTsModel->SetProperty, HIDE=1-Event.select
        END

; View/hide global wavelet
    (*pState).wViewGWS: BEGIN
        (*pState).sViewGWS = Event.select
        sWps.rGwsModel->SetProperty, HIDE=1-Event.select
        END

; View/hide phase lines
    (*pState).wViewPhase: BEGIN
        (*pState).sViewPhase = Event.select
        CASE Event.select OF
        0: sWps.rSurface->SetProperty, $
            TEXTURE_MAP=OBJ_NEW()
        1: sWps.rSurface->SetProperty, $
            TEXTURE_MAP=sWps.rPhaseImage
        ENDCASE
        END

    ELSE: MESSAGE, 'Unknown event.'
    ENDCASE

    rWindow->Draw, sWps.rView
    RETURN
END ; wv_plot3d_options_event


;--------------------------------------------------------------------
PRO wv_plot3d_exportimage_event, Event

    COMPILE_OPT strictarr, hidden
    ON_ERROR, 2

    WIDGET_CONTROL, Event.top, GET_UVALUE=pState
    WIDGET_CONTROL, Event.id, GET_VALUE=menu_name
    menu_name = (STRSPLIT(menu_name,'!!!',ESCAPE='&',/EXTRACT))[0]

; events for menu items
    CASE (menu_name) OF
    'Copy To Clipboard': BEGIN
        suffix = ''
        filename = ''
        END
    'Bitmap Image': BEGIN
        suffix = ''
        END
    'Vector Metafile': BEGIN
        postscript = 0
        suffix = '.emf'
        vector = 1
        END
    'PICT': BEGIN
        postscript = 0
        suffix = '.pict'
        vector = 0
        END
    'Bitmap Postscript': BEGIN
        postscript = 1
        suffix = '.eps'
        vector = 0
        END
    'Vector Postscript': BEGIN
        postscript = 1
        suffix = '.eps'
        vector = 1
        END
    'VRML': BEGIN
        suffix = '.wrl'
        END
    ELSE: MESSAGE, 'Unknown menu item'
    ENDCASE

; pick a filename
    IF (suffix NE '') THEN BEGIN
pick_again:
        filename = DIALOG_PICKFILE(/WRITE, $
            GROUP=Event.top, $
            FILTER='*'+suffix, $
            GET_PATH=file_path, $
            PATH=(*pState).file_path, $
            TITLE='Save as '+menu_name)
        IF (filename EQ '') THEN RETURN
        IF ((FILE_SEARCH(filename))[0] NE '') THEN BEGIN
            result = DIALOG_MESSAGE([filename, $
                'This file already exists. Replace existing file?'], $
                DIALOG_PARENT=Event.top, $
                /QUESTION,TITLE='Save As')
            IF (result EQ 'No') THEN GOTO,pick_again
        ENDIF
; save the file path
        (*pState).file_path = file_path
        suffix_pos = STRPOS(filename,suffix)
        correct_suffix = suffix_pos EQ (STRLEN(filename)-STRLEN(suffix))
        IF ((NOT correct_suffix) AND $
            (!VERSION.OS_FAMILY EQ 'Windows')) THEN $
            filename = filename + suffix
    ENDIF

    WIDGET_CONTROL,/HOURGLASS
    WIDGET_CONTROL, (*pState).wDraw, GET_VALUE=rWindow
    rWindow->GetProperty, $
        COLOR_MODEL=color_model, $
        DIMENSIONS=dimensions, $
        RESOLUTION=resolution, $
        N_COLORS=n_colors

; change background color to white
    (*pState).rView->GetProperty,COLOR=color
    (*pState).rView->SetProperty,COLOR=[255,255,255]

    CASE menu_name OF
    'Bitmap Image': BEGIN
        rImage = rWindow->Read()
        rImage->GetProperty, DATA=image
        result = DIALOG_WRITE_IMAGE(image, $
            DIALOG_PARENT=Event.top, $
            /WARN_EXIST)
        OBJ_DESTROY, rImage
        END
    'VRML': BEGIN
        IF (NOT OBJ_VALID((*pState).rVRML)) THEN BEGIN
            (*pState).rVRML = OBJ_NEW('IDLgrVRML', $
                COLOR_MODEL=color_model, $
                GRAPHICS_TREE=(*pState).rView, $
                N_COLORS=n_colors)
        ENDIF
        (*pState).rVRML->SetProperty, $
            DIMENSIONS=dimensions, $
            FILENAME=filename, $
            RESOLUTION=resolution
        (*pState).rVRML->Draw
        END
    ELSE: BEGIN
        IF (NOT OBJ_VALID((*pState).rClipboard)) THEN BEGIN
            (*pState).rClipboard = OBJ_NEW('IDLgrClipboard', $
                COLOR_MODEL=color_model, $
                GRAPHICS_TREE=(*pState).rView, $
                N_COLORS=n_colors)
        ENDIF
        IF KEYWORD_SET(postscript) THEN BEGIN
            (*pState).rClipboard->GetProperty, $
                SCREEN_DIMENSIONS=screen_dimensions
            resolution = resolution*FLOAT(dimensions)/screen_dimensions
            dimensions = screen_dimensions
        ENDIF
        (*pState).rClipboard->SetProperty, $
            DIMENSIONS=dimensions, $
            RESOLUTION=resolution
        (*pState).rClipboard->Draw, $
            FILE=filename, $
            POSTSCRIPT=postscript, $
            VECTOR=vector
        END
    ENDCASE

; reset the color
    (*pState).rView->SetProperty,COLOR=color

    RETURN
END


;--------------------------------------------------------------------
PRO wv_plot3d_hidebase_event, event

    COMPILE_OPT strictarr, hidden
    ON_ERROR, 2

    WIDGET_CONTROL, Event.top, GET_UVALUE=pState
    wMenuID = *(*pState).wMenuID


; find ID and size for chosen menu item
    CASE (Event.id) OF
    wMenuID.WaveletOptions: BEGIN
        wDoBase = (*pState).wWaveletBase
        siz = (*pState).sizeWaveletBase
        END
    wMenuID.ViewOptions: BEGIN
        wDoBase = (*pState).wViewBase
        siz = (*pState).sizeViewBase
        END
    ENDCASE


; find out if menu item is set or not
    WIDGET_CONTROL, Event.id, $
        GET_VALUE=menu_name
    isSet = STRMID(menu_name,0,1) EQ '*'
    WIDGET_CONTROL, (*pState).wBase, UPDATE=0
    CASE isSet OF
    0: BEGIN   ; set base
        WIDGET_CONTROL, Event.id, $
            SET_VALUE='* ' + STRMID(menu_name,2)
        WIDGET_CONTROL, wDoBase, /MAP, $
            SCR_XSIZE=siz[0], SCR_YSIZE=siz[1]
        END
    1: BEGIN   ; unset base
        WIDGET_CONTROL, Event.id, $
            SET_VALUE='  ' + STRMID(menu_name,2)
        WIDGET_CONTROL, wDoBase, $
            MAP=0, $
            SCR_XSIZE=1, $
            SCR_YSIZE=1
        END
    ENDCASE

; crucial to update the base, otherwise widgets overlap
    WIDGET_CONTROL, (*pState).wBase, /UPDATE

; find new minimum base height and new base size
    geom_toolbar = WIDGET_INFO((*pState).wBaseOptions,/GEOMETRY)
    (*pState).min_base_size[1] = geom_toolbar.ysize > 128

    WIDGET_CONTROL,Event.handler,TLB_GET_SIZE=new_size
    (*pState).base_size = new_size

    RETURN
END


;--------------------------------------------------------------------
PRO wv_plot3d_event, event, $
    DATA=xloadct_cb_event

    COMPILE_OPT strictarr, hidden
    ON_ERROR, 2

    IF (N_ELEMENTS(xloadct_cb_event) GT 0) THEN event = xloadct_cb_event
    WIDGET_CONTROL, Event.handler, GET_UVALUE=pState
    wMenuID = *(*pState).wMenuID

; special events
    CASE TAG_NAMES(event,/STRUCTURE_NAME) OF
        'WIDGET_KILL_REQUEST': event = {id:wMenuID.base,top:Event.top, $
            handler:Event.handler,value:wMenuID.Close}
        'WIDGET_BASE': BEGIN
            WIDGET_CONTROL, /HOURGLASS
            ; new TLB size
            WIDGET_CONTROL,Event.top,TLB_GET_SIZE=new_size
            WIDGET_CONTROL,Event.top,UPDATE=0
            delta = new_size - (*pState).base_size
            geom = WIDGET_INFO((*pState).wDraw,/GEOMETRY)
            min_size = (*pState).min_base_size
            xsize1 = (geom.xsize + delta[0]) > min_size[0]
            ysize1 = (geom.ysize + delta[1]) > min_size[1]
            WIDGET_CONTROL,(*pState).wDraw,XSIZE=xsize1,YSIZE=ysize1
            WIDGET_CONTROL,(*pState).wMessage,SCR_XSIZE=xsize1
            WIDGET_CONTROL,Event.top,/UPDATE
            WIDGET_CONTROL,Event.handler,TLB_GET_SIZE=new_size
            (*pState).base_size = new_size
            IF (xsize1 LT ysize1) THEN BEGIN
                height = 2.*ysize1/xsize1
                viewplane_rect = [-1, -height/2., 2, height]
            ENDIF ELSE BEGIN
                width = 2.*xsize1/ysize1
                viewplane_rect = [-width/2., -1, width, 2]
            ENDELSE
            (*pState).rView->SetProperty, $
                VIEWPLANE_RECT = viewplane_rect
            END
        ELSE:
    ENDCASE

    IF (Event.id NE (*pState).wPDmenu) THEN RETURN

    IF (Event.value NE wMenuID.Print) THEN $
        WIDGET_CONTROL, /HOURGLASS

    WIDGET_CONTROL, (*pState).wDraw, GET_VALUE=rWindow

; events for menu items
    CASE (Event.value) OF
    wMenuID.Print: BEGIN
        IF (NOT OBJ_VALID((*pState).rPrinter)) THEN BEGIN
            rWindow->GetProperty, $
                COLOR_MODEL=color_model, $
                N_COLORS=n_colors
            (*pState).rView->GETPROPERTY,UVALUE=sWps
            (*pState).rPrinter = OBJ_NEW('IDLgrPrinter', $
                COLOR_MODEL=color_model, $
                GRAPHICS_TREE=(*pState).rView, $
                N_COLORS=n_colors, $
                PALETTE=sWps.rColorPalette, $
                UNITS=0)
        ENDIF
        result = DIALOG_PRINTERSETUP((*pState).rPrinter, $
            DIALOG_PARENT=Event.top, $
            TITLE='Print')
        IF (result EQ 0) THEN RETURN
        (*pState).rView->GetProperty,COLOR=color
        (*pState).rView->SetProperty,COLOR=[255,255,255] ; white background
        rDummyView = OBJ_NEW('IDLgrView')
        MESSAGE,/RESET  ; reset old errors
        (*pState).rPrinter->Draw, rDummyView  ; do fake draw to get filename
        IF (!ERROR_STATE.CODE EQ 0) THEN BEGIN
            WIDGET_CONTROL,/HOURGLASS   ; now we can put up the hourglass
            (*pState).rPrinter->GetProperty, $
                DIMENSION=dimensions
            xsize1 = dimensions[0]
            ysize1 = dimensions[1]
            IF (xsize1 LT ysize1) THEN BEGIN
                height = 2.*ysize1/xsize1
                viewplane_rect = [-1, -height/2., 2, height]
            ENDIF ELSE BEGIN
                width = 2.*xsize1/ysize1
                viewplane_rect = [-width/2., -1, width, 2]
            ENDELSE
            (*pState).rView->GetProperty, $
                VIEWPLANE_RECT = save_viewplane_rect
            (*pState).rView->SetProperty, $
                VIEWPLANE_RECT = viewplane_rect
            (*pState).rPrinter->Draw,VECTOR=0  ; and draw the actual image
            (*pState).rPrinter->NewDocument
            (*pState).rView->SetProperty, $
                VIEWPLANE_RECT = save_viewplane_rect
        ENDIF
        OBJ_DESTROY, rDummyView
        (*pState).rView->SetProperty,COLOR=color
        END
    wMenuID.Close: BEGIN ; quit
        WIDGET_CONTROL, Event.top, /DESTROY
        RETURN
        END
    wMenuID.Undo: BEGIN ; undo transform
        WIDGET_CONTROL,wMenuID.Undo,GET_VALUE=menu_name
        undo_flag = (menu_name EQ 'Undo')
        WIDGET_CONTROL,wMenuID.Undo,SET_VALUE=(['Undo','Redo'])[undo_flag]
        (*pState).rView->GETPROPERTY,UVALUE=sWps
        SWps.rGroup->GetProperty, $
            TRANSFORM=current_transform, $
            UVALUE=old_transform
        SWps.rGroup->SetProperty, $
            TRANSFORM=old_transform, $
            UVALUE=current_transform
        rWindow->Draw, sWps.rView
        RETURN
        END
    wMenuID.ColorTable: BEGIN
        (*pState).rView->GETPROPERTY,UVALUE=sWps
        TVLCT,red,green,blue,/GET
        CASE (N_ELEMENTS(xloadct_cb_event) GT 0) OF
            0: BEGIN ; start XLOADCT widget
                *(*pState).pColortable = [[red],[green],[blue]] ; save old
                sWps.rColorPalette->GETPROPERTY, $
                    RED_VALUES=red, GREEN_VALUES=green, BLUE_VALUES=blue
                TVLCT,red,green,blue
                XLOADCT,GROUP=Event.top, $
                    UPDATECALLBACK='wv_plot3d_event', $
                    UPDATECBDATA=event
                END
            1: BEGIN ; change to new color table
                TVLCT,*(*pState).pColortable ; restore old colortable
                sWps.rColorPalette->SETPROPERTY, $
                    RED_VALUES=red, $
                    GREEN_VALUES=green, $
                    BLUE_VALUES=blue
                rWindow->Draw, sWps.rView
                RETURN
                END
        ENDCASE
        END
    wMenuID.Low: BEGIN
        (*pState).WPS_drag_quality = 0
        WIDGET_CONTROL,wMenuID.Low, SENSITIVE=0
        WIDGET_CONTROL,wMenuID.Medium, SENSITIVE=1
        WIDGET_CONTROL,wMenuID.High, SENSITIVE=1
        END
    wMenuID.Medium: BEGIN
        (*pState).WPS_drag_quality = 1
        WIDGET_CONTROL,wMenuID.Low, SENSITIVE=1
        WIDGET_CONTROL,wMenuID.Medium, SENSITIVE=0
        WIDGET_CONTROL,wMenuID.High, SENSITIVE=1
        END
    wMenuID.High: BEGIN
        (*pState).WPS_drag_quality = 2
        WIDGET_CONTROL,wMenuID.Low, SENSITIVE=1
        WIDGET_CONTROL,wMenuID.Medium, SENSITIVE=1
        WIDGET_CONTROL,wMenuID.High, SENSITIVE=0
        END
    wMenuID.HelponWaveletPowerSpectrum: BEGIN ; Display information file
        ONLINE_HELP, 'WAV_PWRSPEC'
        END
    wMenuID.IDLhelp: BEGIN ; Display information file
        ONLINE_HELP
        END
    ELSE: MESSAGE, 'Unknown menu item.'
    ENDCASE
    RETURN
END  ; wv_plot3d_event


;--------------------------------------------------------------------
PRO wv_plot3d_cleanup, wBase

    COMPILE_OPT strictarr, hidden

    WIDGET_CONTROL, wBase, GET_UVALUE=pState

; Clean up heap variables
    FOR i=0,N_TAGS(*pState)-1 DO BEGIN
        tname = SIZE((*pState).(i), /TNAME)
        CASE tname OF
            'POINTER': PTR_FREE, (*pState).(i) ; pointer
            'OBJREF': OBJ_DESTROY, (*pState).(i) ; object
            ELSE:
        ENDCASE
    ENDFOR
    PTR_FREE, pState
END  ; wv_plot3d_cleanup


;--------------------------------------------------------------------
FUNCTION wv_plot3d_wps, $
    inputData, $ ; 2D array
    x, $     ; x coordinates of array
    y, $     ; y coordinates of array
    XTITLE=xtitle,YTITLE=ytitle, $
    XUNITS=xunits,YUNITS=yunits, $
    UNITS=units, $
    TITLE=title, $
    SURFACE_STYLE=surface_style, $ ; graphics mode
    COLUMN=column, $ ; dummy variable, so it can't get set in _extra
    MBAR=mbar, $ ; dummy variable, so it can't get set in _extra
    ROW=row, $ ; dummy variable, so it can't get set in _extra
    _EXTRA=_extra ; this includes keywords such as UVALUE, GROUP_LEADER, etc.

    COMPILE_OPT strictarr

    ON_ERROR, 2

; Check for valid Wavelet license
; Don't bother modifying these lines as WV_DWT and WV_PWT will not work.
    IF (NOT LMGR('idl_wavelet', VERSION='1.0')) THEN BEGIN
        MESSAGE, /INFO, /NONAME, $
            'You do not have a valid IDL Wavelet Toolkit license'
        RETURN,0
    ENDIF

    IF (N_PARAMS() LT 1) THEN MESSAGE, $
        'Incorrect number of arguments'

; Set up the drawing area size
    DEVICE,BYPASS_TRANSLATION=0,DECOMPOSED=0
    DEVICE, GET_SCREEN_SIZE = screenSize
    draw_ysize = (draw_xsize = 0.7 * MIN(screenSize))


; check input parameters for files & data
    tname = SIZE(inputData,/TNAME)
    CASE tname OF
        'UNDEFINED': MESSAGE, $
            'Input must be either a string or an array.'
        'STRING': filename = inputData
        ELSE: array = inputData
    ENDCASE
    import_array = (N_ELEMENTS(array) GT 0)

    IF import_array THEN BEGIN
        oneD = SIZE(array, /N_DIM) EQ 1
        IF (N_ELEMENTS(title) LE 0) THEN title=''

    ; Note: the keywords get checked (and set) in WV_PLOT3D_INIT
        rState = WV_PLOT3D_INIT( array, x, y, $
            TITLE=title, $
            XTITLE=xtitle, $
            YTITLE=ytitle, $
            XUNITS=xunits, $
            YUNITS=yunits, $
            UNITS=units, $
            DRAW_XSIZE=draw_xsize, $
            DRAW_YSIZE=draw_ysize, $
            SURFACE_STYLE=surface_style)

    ; Widget IDs and state
        wState = { $
            min_base_size: [0L, 0L], $
            wBase: 0L, $
            wDraw: 0L, $
            wMessage: 0L, $
            wPDmenu:0L, $
            wMenuID:PTR_NEW(), $
            wBaseOptions: 0L, $
            wWaveletBase:0L, $
                sizeWaveletBase:[0L,0L], $
            wViewBase:0L, $
                sizeViewBase:[0L,0L], $
            wEnergyBase: 0L, $
            wWavelet: 0L, $
                sWaveletFamily: '', $
                sWaveletOrder: 0d, $
            wPowerScale:0L, $
                sPowerScale:0L, $
            wCutoff: 0L, $
                sCutoff: -50L, $
            wLineContour: 0L, $
                sLineContour: 0L, $
            wColorContour: 0L, $
                sColorContour: 0L, $
            wColorContourFillButton: 0L, $
                sColorContourFillButton: 0L, $
            wSurfaceStyle: 0L, $
                sSurfaceStyle: surface_style, $
            wSkirtButton: 0L, $
                sSkirtButton: 0L, $
            wSurfaceFlat: 0L, $
                sSurfaceFlat: 0L, $
            wPaletteButton: 0L, $
                sPaletteButton: 0L, $
            wSignifStyle: 0L, $
                sSignifStyle: 0L, $
            wSignifLevel: 0L, $
                sSignifLevel: 0L, $
            wView3dButton: 0L, $
                sView3dButton: 1L, $
            wViewColorBar: 0L, $
                sViewColorBar: 1L, $
            wViewData: 0L, $
                sViewData: 1L, $
            wViewGWS: 0L, $
                sViewGWS: 1L, $
            wViewPhase: 0L, $
                sViewPhase: 0L $
            }
        pState = PTR_NEW(CREATE_STRUCT(rState, wState))
    ENDIF ELSE BEGIN
        IF ((FILE_SEARCH(filename))[0] EQ '') THEN MESSAGE, $
                'Cannot open the file "'+filename+'"'
        RESTORE, filename
    ENDELSE


; Create the widgets.
    (*pState).wBase = WIDGET_BASE(TITLE='WPS: '+(*pState).title, $
        /COLUMN,                    $
;       TLB_FRAME_ATTR=1,          $
        /TLB_KILL_REQUEST_EVENT, $
        /TLB_SIZE_EVENTS, $
        MAP=0, $
        MBAR=id_barBase, $
        _EXTRA=_extra)
    WIDGET_CONTROL, (*pState).wBase, $
        SET_UVALUE=pState

; Create menu bar items
    formats = [ '0\Bitmap Image' ]
    CASE STRLOWCASE(!VERSION.OS_FAMILY) OF
        'windows': formats = [ $
            formats, '0\Vector Metafile']
        'macos': formats = [ $
            formats, '0\PICT']
        ELSE:
    ENDCASE
    formats = [formats, $
        '0\Bitmap Postscript', $
        '0\Vector Postscript', $
        '2\VRML']


; construct menu item string array
    menu_items = [ $
        '1\&File', $
            '0\&Open State...\wv_plot3d_file_restore_event', $
            '0\&Save State...\wv_plot3d_file_save_event', $
            '5\&Export To...', $
                formats + '\wv_plot3d_exportimage_event', $
            '0\&Print', $
            '6\&Close', $
        '1\&Edit', $
            '0\&Undo', $
            '6\&Copy To Clipboard\wv_plot3d_exportimage_event', $
        '1\&View', $
            '0\&Color Table', $
            '1\&Drag Quality', $
                '0\&Low', $
                '0\&Medium', $
                '2\&High', $
            '4\* Wavelet Options\wv_plot3d_hidebase_event', $
            '2\* View Options\wv_plot3d_hidebase_event', $
        '1\&Help', $
            '0\&Help on Wavelet Power Spectrum', $
            '2\&IDL Help']

    IF (!VERSION.os_family NE 'Windows') THEN BEGIN
        FOR i=0,N_ELEMENTS(menu_items)-1 DO menu_items[i] = $
            STRSPLIT(menu_items[i],'!!!',ESCAPE='&',/EXTRACT)
    ENDIF

    (*pState).wPDmenu = CW_PDMENU(id_barBase,menu_items, $
        IDS=menu_ids, $
        /MBAR, $
        /RETURN_ID)

    wMenuID = {base:(*pState).wPDmenu}
    FOR i=0,N_ELEMENTS(menu_items)-1 DO BEGIN
        menu_name = STRSPLIT(menu_items[i],'\',/EXTRACT)
        IF (menu_name[0] NE '1') THEN BEGIN
            menu_name = menu_name[1]
            menu_name = (STRSPLIT(menu_name,'...',/EXTRACT))[0]  ; remove ...
            menu_name = STRSPLIT(menu_name,'*',ESCAPE='&',/EXTRACT)
            menu_name = STRCOMPRESS(menu_name,/REMOVE_ALL) ; remove spaces
            wMenuID = CREATE_STRUCT(wMenuID,menu_name,menu_ids[i])  ; save ID
        ENDIF
    ENDFOR
    WIDGET_CONTROL,wMenuID.Medium, SENSITIVE=0  ; this is the default
    WIDGET_CONTROL,wMenuID.Undo, SENSITIVE=0
    IF (NOT (*pState).oneD) THEN wMenuID = CREATE_STRUCT(wMenuID, $
        'HideDataSeries',0, $
        'HideGlobalWavelet',0)
    (*pState).wMenuID = PTR_NEW(wMenuID)


; Create left and right bases.
    wBase_row = WIDGET_BASE((*pState).wBase,COLUMN=2)

    (*pState).wDraw = WIDGET_DRAW(wBase_row, $
        /BUTTON_EVENTS, $
        /EXPOSE_EVENTS, $
        /MOTION_EVENTS, $
        EVENT_PRO='wv_plot3d_draw_event', $
        GRAPHICS_LEVEL=2, $
        RETAIN=0, $
        XSIZE=draw_xsize, $
        YSIZE=draw_ysize)


    (*pState).wBaseOptions = WIDGET_BASE(wBase_row,/COLUMN, $
        XPAD=0, YPAD=0)


; Wavelet options base
    (*pState).wWaveletBase = WIDGET_BASE((*pState).wBaseOptions, $
        /COLUMN,/FRAME,SPACE=0,XPAD=1,YPAD=1, $
        EVENT_PRO='wv_plot3d_wavelet_event', $
        UVALUE=(*pState).wBase)
    dummy = WIDGET_LABEL((*pState).wWaveletBase, $
        /ALIGN_LEFT, $
        VALUE='Wavelet Options')
    no_color = (!D.N_COLORS LE 256)


; 2D images can only use discrete wavelets
    need_discrete = ((*pState).oneD EQ 0)
    IF need_discrete THEN extra = {DISCRETE:1}
    IF ((*pState).sWaveletFamily NE '') THEN wave_value = $
        {FAMILY:(*pState).sWaveletFamily, ORDER:(*pState).sWaveletOrder}
    (*pState).wWavelet = WV_CW_WAVELET((*pState).wWaveletBase, $
        NO_COLOR=no_color, $
        VALUE=wave_value, $
        _EXTRA=extra)


; Plot options base
    (*pState).wViewBase = WIDGET_BASE((*pState).wBaseOptions, $
        /COLUMN,FRAME=1,XPAD=1,YPAD=1, $
        EVENT_PRO='wv_plot3d_options_event')
    dummy = WIDGET_LABEL((*pState).wViewBase, $
        VALUE='View Options',/ALIGN_LEFT)


; Font selection
    wFontBase = WIDGET_BASE((*pState).wViewBase, $
        EVENT_PRO='wv_plot3d_font_event')
    (*pState).rView->GetProperty,UVALUE=sWps
    sWps.rFont->GetProperty, NAME=fname, SIZE=fsize
    wFont = CW_FONT_SELECT(wFontBase, $
        VALUE={NAME:fname, SIZE:fsize}, $
        SPACE=0,XPAD=0,YPAD=1)


; General view options
    wViewButtons = WIDGET_BASE((*pState).wViewBase, $
        COLUMN=2, $
        /NONEXCLUSIVE)
    (*pState).wView3dButton = WIDGET_BUTTON(wViewButtons, $
        VALUE='3D')
    WIDGET_CONTROL, (*pState).wView3dButton, $
        SET_BUTTON=(*pState).sView3dButton
    (*pState).wViewColorBar = WIDGET_BUTTON(wViewButtons, $
        VALUE='Color Bar')
    WIDGET_CONTROL, (*pState).wViewColorBar, $
        SET_BUTTON=(*pState).sViewColorBar

    IF (*pState).oneD THEN BEGIN
        (*pState).wViewData = WIDGET_BUTTON(wViewButtons, $
            VALUE='Data Plot')
        WIDGET_CONTROL, (*pState).wViewData, $
            SET_BUTTON=(*pState).sViewData
        (*pState).wViewGWS = WIDGET_BUTTON(wViewButtons, $
            VALUE='Global')
        WIDGET_CONTROL, (*pState).wViewGWS, $
            SET_BUTTON=(*pState).sViewGWS
        wViewButtons2 = WIDGET_BASE((*pState).wViewBase, $
            /COLUMN, $
            /ALIGN_LEFT, $
            /NONEXCLUSIVE)
        (*pState).wViewPhase = WIDGET_BUTTON(wViewButtons2, $
            VALUE='Zero Phase Lines')
        WIDGET_CONTROL, (*pState).wViewPhase, $
            SET_BUTTON=(*pState).sViewPhase, $
            SENSITIVE=0
    ENDIF


; WPS energy scaling
    (*pState).wEnergyBase = WIDGET_BASE((*pState).wViewBase, $
        /COLUMN,FRAME=0,SPACE=0,XPAD=1,YPAD=1, $
        EVENT_PRO='wv_plot3d_zscale_event', $
        UVALUE=(*pState).wBase)

    dummy = WIDGET_LABEL((*pState).wEnergyBase, $
        VALUE='Energy scaling',/ALIGN_LEFT)
    wEnergyBase1 = WIDGET_BASE((*pState).wEnergyBase, $
        /BASE_ALIGN_CENTER, $
        /ROW,SPACE=0,XPAD=0,YPAD=0)
    (*pState).wPowerScale = WIDGET_DROPLIST(wEnergyBase1, $
        VALUE=['Power','Magnitude', $
        'Decibels'])
    WIDGET_CONTROL, (*pState).wPowerScale, $
        SET_DROPLIST_SELECT=(*pState).sPowerScale

; Decibal text field
    (*pState).wCutoff = CW_FIELD(wEnergyBase1, $
        /RETURN_EVENTS, $
        VALUE=(*pState).sCutoff, $
        /INTEGER, $
        XSIZE=4, $
        TITLE=' >')
    dummy = WIDGET_LABEL(wEnergyBase1, $
        VALUE='db')


; Surface options
    wSurfaceBase = WIDGET_BASE((*pState).wViewBase, $
        /BASE_ALIGN_LEFT, $
        COLUMN=1, $
        FRAME=0, $
        SPACE=0,XPAD=1,YPAD=1)
    (*pState).wSurfaceStyle = WIDGET_DROPLIST(wSurfaceBase, $
        TITLE='Surface', $
        VALUE=['Off', $
            'Points', $
            'Mesh', $
            'Shaded', $
            'XZ lines', $
            'YZ lines', $
            'Lego', $
            'Lego fill'])
    WIDGET_CONTROL, (*pState).wSurfaceStyle, $
        SET_DROPLIST_SELECT=(*pState).sSurfaceStyle, $
        SET_UVALUE=(*pState).sSurfaceStyle

    wSurfaceButtons1 = WIDGET_BASE(wSurfaceBase, /NONEXCLUSIVE, /ROW)

    (*pState).wSkirtButton = WIDGET_BUTTON(wSurfaceButtons1, $
        VALUE='Skirt')
    WIDGET_CONTROL, (*pState).wSkirtButton, $
        SENSITIVE=((*pState).sSurfaceStyle GT 0), $
        SET_BUTTON=(*pState).sSkirtButton

    (*pState).wSurfaceFlat = WIDGET_BUTTON(wSurfaceButtons1, $
        VALUE='Flat')
    WIDGET_CONTROL, (*pState).wSurfaceFlat, $
        SENSITIVE=((*pState).sSurfaceStyle GT 0), $
        SET_BUTTON=(*pState).sSurfaceFlat

    (*pState).wPaletteButton = WIDGET_BUTTON(wSurfaceButtons1, $
        VALUE='Gray')
    WIDGET_CONTROL, (*pState).wPaletteButton, $
        SENSITIVE=((*pState).sSurfaceStyle GT 0), $
        SET_BUTTON=(*pState).sPaletteButton


; Line contour droplist
    wLineContourBase = WIDGET_BASE((*pState).wViewBase, $
        ROW=2, FRAME=0, $
        SPACE=0,XPAD=1,YPAD=1)
    (*pState).wLineContour = WIDGET_DROPLIST( $
        wLineContourBase, $
        TITLE='Contour lines', $
        VALUE=['Off', 'Top', 'Bottom', '3D'])
    WIDGET_CONTROL, (*pState).wLineContour, $
        SET_DROPLIST_SELECT=(*pState).sLineContour


; Color contour droplist
    wColorContourBase = WIDGET_BASE(wLineContourBase, $
        /ROW,SPACE=0,XPAD=0,YPAD=0)
    (*pState).wColorContour = $
        WIDGET_DROPLIST(wColorContourBase, $
            TITLE='Color', $
            VALUE=['Off', 'Top', $
            'Bottom', '3D'])
    WIDGET_CONTROL, (*pState).wColorContour, $
        SET_DROPLIST_SELECT=(*pState).sColorContour

    wColorContourBase = WIDGET_BASE(wColorContourBase, $
        /NONEXCLUSIVE, $
        FRAME=0)
    (*pState).wColorContourFillButton = $
        WIDGET_BUTTON(wColorContourBase, $
            SENSITIVE=((*pState).sColorContour GT 0), $
            VALUE='Filled')
    WIDGET_CONTROL, (*pState).wColorContourFillButton, $
        SET_BUTTON=(*pState).sColorContourFillButton



; Significance levels
    wSignifBase = WIDGET_BASE((*pState).wViewBase, $
        /COLUMN, $
        EVENT_PRO='wv_plot3d_signif_event', $
        FRAME=0, $
        SPACE=0, XPAD=1, YPAD=1)
    dummy = WIDGET_LABEL(wSignifBase, $
        /ALIGN_LEFT, $
        VALUE='Significance')
    wSignifRow = WIDGET_BASE(wSignifBase, $
        /ROW, SPACE=0, XPAD=0, YPAD=0)

    (*pState).wSignifStyle = WIDGET_DROPLIST(wSignifRow, $
        VALUE=['Off', $
            'Sheet', $
            'Top contour', $
            'Bottom', $
            '3D'])
    WIDGET_CONTROL, (*pState).wSignifStyle, $
        SET_DROPLIST_SELECT=(*pState).sSignifStyle

    (*pState).wSignifLevel = WIDGET_DROPLIST(wSignifRow, $
        SENSITIVE=((*pState).sSignifStyle GT 0), $
        VALUE=['10%','5%','1%','0.1%'], $
        UVALUE=[0.1,0.05,0.01,0.001])
    WIDGET_CONTROL, (*pState).wSignifLevel, $
        SET_DROPLIST_SELECT=(*pState).sSignifLevel

; Create tips text area.
    id_bottom_row = WIDGET_BASE((*pState).wBase,/ROW)
    (*pState).wMessage = WIDGET_TEXT(id_bottom_row,VALUE='Ready', $
        /ALIGN_LEFT,SCR_XSIZE=draw_xsize)

; Realize the widget hierarchy
;   IF (!VERSION.OS_FAMILY EQ 'Windows') THEN $
;       WIDGET_CONTROL, wBase, MAP=1 ; workaround. RSI report #6140


    WIDGET_CONTROL, (*pState).wBase, /MAP, /REALIZE
    WIDGET_CONTROL, /HOURGLASS

    geom_toolbar = WIDGET_INFO((*pState).wBaseOptions,/GEOMETRY)
    (*pState).min_base_size = [128,geom_toolbar.ysize]

    WIDGET_CONTROL, (*pState).wBase, TLB_GET_SIZE=base_size
    (*pState).base_size = base_size

    geom = WIDGET_INFO((*pState).wWaveletBase, /GEOM)
    (*pState).sizeWaveletBase = [geom.scr_xsize, geom.scr_ysize]
    geom = WIDGET_INFO((*pState).wViewBase, /GEOM)
    (*pState).sizeViewBase = [geom.scr_xsize, geom.scr_ysize]

; Register with XMANAGER, for subsequent user events.
    XMANAGER, 'wv_plot3d_wps', (*pState).wBase, $
        /NO_BLOCK, $
        CLEANUP='wv_plot3d_cleanup', $
        EVENT_HANDLER='wv_plot3d_event'

    RETURN, (*pState).wBase
END

