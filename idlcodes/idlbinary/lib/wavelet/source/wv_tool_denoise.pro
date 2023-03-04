;----------------------------------------------------------------
; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/wavelet/source/wv_tool_denoise.pro#1 $
;
; Copyright (c) 2000-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;+
; NAME:
;    WV_TOOL_DENOISE
;
; PURPOSE:
;
;    This function runs the IDL Wavelet Toolkit denoise
;    widget.
;
; CALLING SEQUENCE:
;
;    Result = WV_TOOL_DENOISE( Array [, X] [, Y]
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
;      The default is "Denoise:".
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
;    CT, August 2000: Moved denoise algorithm out to WV_DENOISE.
;-
;  Variable name conventions used herein:
;       r==Reference to Object
;       p==pointer
;       w==widget ID
;


;----------------------------------------------------------------
PRO wv_tool_denoise_message, topid, value
    COMPILE_OPT strictarr, hidden
; error handling
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        MESSAGE,/INFO,!ERROR_STATE.MSG
        RETURN
    ENDIF
    IF (value NE '') THEN BEGIN
        WIDGET_CONTROL,topid,GET_UVALUE=pState
        wMessage = (*pState).wMessage
        IF (wMessage LT 1) THEN $
            MESSAGE,'*** Unable to find message bar ***' $
        ELSE WIDGET_CONTROL,wMessage,SET_VALUE=value
    ENDIF
END ; wv_tool_denoise_message


;----------------------------------------------------------------
PRO wv_tool_denoise_plot,top_id,event_id

    COMPILE_OPT strictarr, hidden

; error handling
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        MESSAGE,/INFO,!ERROR_STATE.MSG
        RETURN
    ENDIF

    WIDGET_CONTROL,top_id,GET_UVALUE=pState

    WIDGET_CONTROL,(*pState).wWavelet,GET_VALUE=wavelet


; Find threshold
    CASE event_id OF
    (*pState).wCum_slider: BEGIN ; cumulative power cutoff
        WIDGET_CONTROL,(*pState).wCum_slider, $
            GET_VALUE=percent,GET_UVALUE=old_percent_keep
        round_up = percent GT old_percent_keep
        IF (percent EQ old_percent_keep) THEN RETURN
        END
    ELSE: BEGIN ; coefficient cutoff
        WIDGET_CONTROL,(*pState).wCoefficients, $
            GET_VALUE=coeff, GET_UVALUE=old_coeff
        IF (event_id EQ (*pState).wCoefficients) THEN $
            IF (coeff EQ old_coeff) THEN RETURN
        IF (coeff EQ -1) THEN coeff = 2L^31-1  ; startup flag
        END
    ENDCASE


    WIDGET_CONTROL,(*pState).wThreshold,GET_VALUE=threshold


    str = 'WV_DENOISE( Array'
    str = [str, '"' + wavelet.family + '", ' + $
        STRTRIM(FIX(wavelet.order),2)]
    IF (N_ELEMENTS(coeff) GT 0) THEN str = [str, $
        'COEFFICIENTS=' + STRTRIM(coeff,2)]
    str = [str, 'DWT_FILT=dwt_filt']
    IF (N_ELEMENTS(percent) GT 0) THEN str = [str, $
        'PERCENT=' + STRTRIM(percent,2)]
    str = [str, 'THRESHOLD=' + STRTRIM(FIX(threshold),2)]
    str = '  ' + str + ', $'
    str = ['Function Call:', $
        'Result =', $
        str, $
        '  WPS_FILT=wps_filt)']
    functionCall = str


    denoiseState = *(*pState).pDenoiseState
    data = *(*pState).pData
    data_filt = WV_DENOISE(data, wavelet.family, wavelet.order, $
        COEFF=coeff, $
        CUTOFF=cutoff, $
        DENOISE_STATE=denoiseState, $
        DWT_FILTERED=dwt_filt, $
        PERCENT=percent, $
        THRESHOLD=threshold, $
        WPS_FILTERED=wps_filt)
    *(*pState).pDenoiseState = TEMPORARY(denoiseState)

    coeff = (*(*pState).pDenoiseState).coefficients
    percent = (*(*pState).pDenoiseState).percent

;   slider_value = 100
    slider_value = FIX(percent + 1E-5)

    WIDGET_CONTROL,(*pState).wCum_slider, $
        SET_VALUE=slider_value,SET_UVALUE=slider_value
    WIDGET_CONTROL,(*pState).wCoefficients, $
        SET_VALUE=coeff, SET_UVALUE=coeff


; Construct plot labels
    x = *(*pState).pXdata
    y = *(*pState).pYdata
    nx = N_ELEMENTS(x)
    ny = N_ELEMENTS(y)
    n = N_ELEMENTS(dwt_filt)

    data_filt = data_filt[0:nx-1,0:(ny-1)>0]
    *(*pState).pDataFilt = data_filt
    *(*pState).pDwtFilt = TEMPORARY(dwt_filt)

; output results to text widget
    threshold_str = STRING(cutoff,FORMAT='(G10.3)')
    percent_total = STRING(100.*coeff/n,FORMAT='(G10.3,"%")')
    n_tot = nx*(ny > 1)  ; ny>1 is for time series since then ny=0
    mean_diff = TOTAL(data - data_filt)/n_tot
    sq_diff = TOTAL((data - data_filt)^2)/n_tot
    rms_diff = SQRT((sq_diff - mean_diff^2) > 0.)
    IF ((*pState).variance EQ 0.) THEN BEGIN
        percent_diff = '---'
    ENDIF ELSE BEGIN
        percent_diff = 100.*rms_diff/SQRT((*pState).variance)
        percent_diff = STRING(percent_diff,FORMAT='(G10.3,"%")')
    ENDELSE
    rms_diff = STRING(rms_diff,FORMAT='(G10.3)')
    results = ' '+['Threshold: '+STRTRIM(threshold_str,2), $
        '% of coeffs: '+STRTRIM(percent_total,2), $
        'rms difference: '+STRTRIM(rms_diff,2), $
        '% difference: '+STRTRIM(percent_diff,2)]
    results = [results,'',functionCall]
    WIDGET_CONTROL,(*pState).wText_results,SET_VALUE=results

; setup color tables
    pBackground = !P.BACKGROUND
    pColor = !P.COLOR
    TVLCT,r,g,b,/GET
    LOADCT, 0, /SILENT
    nRed = N_ELEMENTS(r)
    !P.BACKGROUND = nRed-1  ; lightest color
    !P.COLOR = 0         ; darkest color

;   IF PTR_VALID(sData.colors) THEN $
;       IF (N_ELEMENTS(*sData.colors) GT 0) THEN TVLCT,*sData.colors
    old_font = !P.FONT
    !P.FONT = 1
    old_charsize = !P.CHARSIZE
    !P.CHARSIZE = 1
    extra = { $
        NOCLIP:1, $
        XSTYLE:9, $
        XMINOR:2, $
        XMARGIN:[6,2], $
        XTITLE:(*pState).xtitle, $
        YMARGIN:[4,1], $
        YSTYLE:10, $
        YMINOR:1, $
        YTICKS:2, $
        YTITLE:(*pState).ytitle}

; Time series or image
    WIDGET_CONTROL, (*pState).wDraw_data, GET_UVALUE=redraw
    IF (ny LE 1) THEN BEGIN ; time series
        minn = MIN(data, MAX=maxx)
        yrange = [minn, maxx]
        IF redraw THEN BEGIN
            WSET,(*pState).window_data
            PLOT,x,data, $
                YRANGE=yrange, $
                _EXTRA=extra
        ENDIF
        WSET,(*pState).window_filt
        PLOT,x,data_filt, $
            YRANGE=yrange, $
            YSTYLE=9, $
            _EXTRA=extra
    ENDIF ELSE BEGIN ; 2D image
        geom = WIDGET_INFO((*pState).wDraw_data,/GEOMETRY)
        fac = 1.0
        win_xsize = fac*geom.xsize
        win_ysize = fac*geom.ysize
        data_shrunk = data
        xsize = nx
        ysize = ny
        type = (SIZE(data))[3]  ; variable type
; because we are only using the b&w color table, we can't
; use byte values for a byte array; must still BYTSCL them
; if we add in color table selection, then we can put this back...
;       IF (type EQ 1) THEN BEGIN  ; byte array
;           data_filt = BYTE(0 > TEMPORARY(data_filt) < 255)
;       ENDIF ELSE BEGIN  ; other type
            IF redraw THEN $
                data_shrunk = BYTSCL(data_shrunk, TOP=254) + 1b
            data_filt = BYTSCL(data_filt, TOP=254) + 1b
;       ENDELSE
        IF ((win_xsize NE nx) OR (win_ysize NE ny)) THEN BEGIN
            xratio = win_xsize/nx
            yratio = win_ysize/ny
            ratio = xratio < yratio
            xsize = nx*ratio
            ysize = ny*ratio
            IF redraw THEN $
                data_shrunk = CONGRID(TEMPORARY(data_shrunk),xsize,ysize)
            data_filt = CONGRID(TEMPORARY(data_filt),xsize,ysize)
        ENDIF
        xoffset = (win_xsize - xsize)/2
        yoffset = (win_ysize - ysize)/2
        IF redraw THEN BEGIN
            WSET,(*pState).window_data
            TV,data_shrunk,xoffset,yoffset, ORDER=0
        ENDIF
        WSET,(*pState).window_filt
        TV,data_filt,xoffset,yoffset, ORDER=0
    ENDELSE ; 2D image
    WIDGET_CONTROL, (*pState).wDraw_data, $
        SET_UVALUE=0  ; don't redraw next time

; Energy histogram
    wt_sort = (*(*pState).pDenoiseState).sorted
    wt_cumulative = (*(*pState).pDenoiseState).cumulative
    WSET,(*pState).window_energy
    x1 = LINDGEN(n)+1
    !P.MULTI = 0
    PLOT,[1,x1+0.5],[wt_sort[0],wt_sort], $
        XRANGE=[1,n], $
        PSYM=10, $
        /NOCLIP, $
        XTYPE=1,YTYPE=0, $
        XSTYLE=9,YSTYLE=9, $
        YRANGE=[0,wt_sort[0]], $
        XMARGIN=[6,6],YMARGIN=extra.ymargin, $
        YMINOR=2, $
        XTITLE='Coefficient',YTITLE='Power (%)'
    IF (coeff GT 0) THEN BEGIN
        PLOTS,x1[coeff-1],0,LINES=2
        PLOTS,x1[coeff-1],wt_sort[coeff-1], $
            /CONTINUE,PSYM=-4,LINES=2
    ENDIF
    AXIS,/YAXIS,/SAVE, $
        YTHICK=2, $
        YMINOR=2, $
        YRANGE=[0,100], $
        YTITLE='Cumulative power (%)'
    OPLOT,[1,x1+0.5],[wt_cumulative[0],wt_cumulative], $
        THICK=2, $
        /NOCLIP, $
        PSYM=10
    IF (coeff GT 0) THEN BEGIN
        PLOTS,x1[[coeff-1,coeff-1,n-1]],wt_cumulative[coeff-1]*[0,1,1],LINES=2
    ENDIF

; Wavelet power spectrum
    WSET,(*pState).window_wps
;   ERASE
    geom = WIDGET_INFO((*pState).wDraw_wps,/GEOMETRY)
    fac = 1.0
    win_xsize = fac*geom.xsize
    win_ysize = fac*geom.ysize
    xoff = (1.0 - fac)/2.0*geom.xsize
    yoff = (1.0 - fac)/2.0*geom.ysize
    IF (ny LE 1) THEN BEGIN ; time series
        wps_filt[0:1] = SQRT(TOTAL(wps_filt[0:1]^2)/2.)  ; 1st 2 coeffs are the mean
        power2 = FIX(ALOG(n)/ALOG(2))
        ny = power2
        nx = 2L^(power2-1)
        wps_out = FLTARR(nx,ny)
        FOR j=0,power2-1 DO BEGIN
            index = 2L^j + LINDGEN(nx)/(2L^(power2-j-1))
            wps_out[0,j] = wps_filt[index]
        ENDFOR
        dx = x[1] - x[0]
        PLOT,[0,1], $
            /NODATA, $
            XSTYLE=9,YSTYLE=9, $
            XRANGE=[x[0],MAX(x)+dx], $
            YRANGE=[power2+1,1], $
            XMARGIN=extra.xmargin, $
            YMARGIN=extra.ymargin, $
            XMINOR=extra.xminor, $
            XTICKLEN=-0.02, $
            YTICKLEN=-0.02, $
            XTITLE=extra.xtitle, $
            YTITLE='Scale (power of 2)'
        px = !X.WINDOW*geom.xsize
        py = !Y.WINDOW*geom.ysize
        xsize = px[1] - px[0]
        ysize = py[1] - py[0]
        xoffset = px[0] + 1
        yoffset = py[0] + 1
    ENDIF ELSE BEGIN ; 2D
        s = SIZE(wps_filt)
        xsize = s[1]
        ysize = s[2]
        IF ((win_xsize NE xsize) OR (win_ysize NE ysize)) THEN BEGIN
            xratio = win_xsize/xsize
            yratio = win_ysize/ysize
            ratio = xratio < yratio
            xsize = xsize*ratio
            ysize = ysize*ratio
        ENDIF
        xoffset = (win_xsize - xsize)/2
        yoffset = (win_ysize - ysize)/2
        wps_out = TEMPORARY(wps_filt)
    ENDELSE
;   not_zero = (wps_out GT 0d)
;   wps_out = ALOG(TEMPORARY(wps_out))
;   minn = MIN(wps_out,MAX=maxx)
;   minn = minn > (maxx-10)
;   CASE (threshold) OF
;       0: BEGIN ; hard threshold, scale from 55b-->255b
;           wps_tv = BYTSCL(TEMPORARY(wps_out),MIN=minn,TOP=200) + 55b
;           wps_tv = TEMPORARY(wps_tv)*TEMPORARY(not_zero)
;           END
;       1: BEGIN ; soft threshold, scale from 0b-->255b
;           wps_tv = BYTSCL(TEMPORARY(wps_out),MIN=minn)
;           END
;   ENDCASE
    zeroes = WHERE(wps_out LE 0d,n_zero)
    maxx = MAX((*(*pState).pDenoiseState).wps)
    minn = (1E-10)*maxx
    wps_out = ALOG10(TEMPORARY(wps_out) > minn)
    wps_tv = BYTSCL(TEMPORARY(wps_out), $
        MIN=ALOG10(minn),MAX=ALOG10(maxx), $
        TOP=223) + 32b
    IF (n_zero GT 0) THEN wps_tv[zeroes] = !P.COLOR
;   minn = MIN(wps_big[WHERE(FLOAT(wps_big) GT 0.)])
;   wps_big = BYTSCL(ALOG(TEMPORARY(wps_big) > minn))
    TV,CONGRID(wps_tv,xsize,ysize),xoffset,yoffset, ORDER=0

;   TVLCT,r,g,b

    !P.COLOR = pColor
    !P.BACKGROUND = pBackground
    !P.FONT = old_font
    !P.CHARSIZE = old_charsize
    RETURN
END ; wv_tool_denoise_plot


;----------------------------------------------------------------
PRO wv_tool_denoise_event, Event

    COMPILE_OPT strictarr, hidden

; error handling
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        MESSAGE,/INFO,!ERROR_STATE.MSG
        RETURN
    ENDIF

    WIDGET_CONTROL,Event.handler,GET_UVALUE=pState
    WIDGET_CONTROL,/HOURGLASS

    CASE (TAG_NAMES(Event,/STRUCTURE_NAME)) OF
        'WIDGET_KILL_REQUEST': BEGIN
            Event = {id:(*pState).wPDmenu, top:Event.top, $
                handler:Event.handler, value:(*pState).wMenuID.Close}
            END
        'WIDGET_BASE': BEGIN
            WIDGET_CONTROL, Event.handler, TLB_GET_SIZE=new_size
            min_xsize = ((*pState).min_base_size)[0]
            new_size = new_size > (*pState).min_base_size
            dx = new_size[0] - (*pState).base_size[0]
            dy = new_size[1] - (*pState).base_size[1]
            geom_data = WIDGET_INFO((*pState).wDraw_data,/GEOMETRY)
            geom_filt = WIDGET_INFO((*pState).wDraw_filt,/GEOMETRY)
            geom_wps = WIDGET_INFO((*pState).wDraw_wps,/GEOMETRY)
            geom_energy = WIDGET_INFO((*pState).wDraw_energy,/GEOMETRY)
            xsize1 = geom_data.xsize
            ysize1 = geom_data.ysize
            xsize2 = geom_energy.xsize
            ysize2 = geom_wps.ysize
            dx1 = FIX(dx*(*pState).xratio)
            dy1 = FIX(dy*(*pState).yratio)
            xsize1 = (xsize1 + dx1) > min_xsize
            ysize1 = (ysize1 + dy1) > 75
            xsize2 = (xsize2 + (dx-dx1)) > min_xsize
            ysize2 = (ysize2 + (dy-dy1)) > 75
            WIDGET_CONTROL,Event.handler,UPDATE=0
            WIDGET_CONTROL,(*pState).wMessage, $
                SCR_XSIZE=xsize1+xsize2
            WIDGET_CONTROL,(*pState).wDraw_data, $
                DRAW_XSIZE=xsize1,DRAW_YSIZE=ysize1, $
                SET_UVALUE=1  ; redraw
            WIDGET_CONTROL,(*pState).wDraw_filt, $
                DRAW_XSIZE=xsize2,DRAW_YSIZE=ysize1
            WIDGET_CONTROL,(*pState).wDraw_wps, $
                DRAW_XSIZE=xsize1,DRAW_YSIZE=ysize2
            WIDGET_CONTROL,(*pState).wDraw_energy, $
                DRAW_XSIZE=xsize2,DRAW_YSIZE=ysize2
            WSET,(*pState).window_data
            ERASE
            WSET,(*pState).window_filt
            ERASE
            WSET,(*pState).window_wps
            ERASE
            WSET,(*pState).window_energy
            ERASE
            WIDGET_CONTROL,Event.handler,UPDATE=1
            WIDGET_CONTROL,Event.handler,TLB_GET_SIZE=new_size
            (*pState).base_size = new_size
            WV_TOOL_DENOISE_MESSAGE,Event.handler,'Ready'
            WV_TOOL_DENOISE_PLOT, Event.handler, Event.id
            RETURN
            END
        ELSE:
    ENDCASE

    CASE (Event.id) OF
    (*pState).wWavelet: BEGIN ; changed wavelet function or order
        WIDGET_CONTROL,(*pState).wWavelet,GET_VALUE=wavelet
        WV_TOOL_DENOISE_MESSAGE,Event.handler,wavelet.family
        *(*pState).pDenoiseState = 0
        WV_TOOL_DENOISE_PLOT, Event.handler, Event.id
        RETURN
        END
    (*pState).wThreshold: BEGIN
        IF (NOT Event.select) THEN RETURN
        WIDGET_CONTROL,(*pState).wCum_slider, $
            GET_VALUE=percent
        IF (percent EQ 100) THEN RETURN
        WV_TOOL_DENOISE_PLOT, Event.handler, Event.id
        RETURN
        END
    (*pState).wCum_slider: WV_TOOL_DENOISE_PLOT, Event.handler, Event.id
    (*pState).wCoefficients: WV_TOOL_DENOISE_PLOT, Event.handler, Event.id
    (*pState).wPDmenu: BEGIN ; Events for menu items
        menuID = (*pState).wMenuID
        CASE (Event.value) OF
        menuID.OpenState: BEGIN
            suffix = '.sav'
            filename = DIALOG_PICKFILE(/READ, $
                GET_PATH=file_path, $
                GROUP=Event.top, $
                FILTER='*'+suffix, $
                PATH=(*pState).file_path, $
                TITLE='Open Denoise State')
            IF (filename EQ '') THEN RETURN
            WIDGET_CONTROL, /HOURGLASS
            RESTORE, filename
            WIDGET_CONTROL, (*pState).wDraw_data, SET_UVALUE=1  ; redraw
            *(*pState).pData = wv_denoise_state.data
            *(*pState).pXdata = wv_denoise_state.Xdata
            *(*pState).pYdata = wv_denoise_state.Ydata
            tmp = *pState  ; (can't pass a pointer)
            STRUCT_ASSIGN, wv_denoise_state, tmp, /NOZERO
            *pState = TEMPORARY(tmp)
            (*pState).file_path = file_path
            WIDGET_CONTROL,(*pState).wThreshold, $
                SET_VALUE=wv_denoise_state.soft_threshold
            WIDGET_CONTROL,(*pState).wCoefficients, $
                SET_VALUE=wv_denoise_state.coefficients
            WIDGET_CONTROL,(*pState).wWavelet, $
                GET_VALUE=wavelet
            same_family = (wavelet.family EQ wv_denoise_state.family)
            same_order = (wavelet.order EQ wv_denoise_state.order)
            IF (same_family AND same_order) THEN BEGIN ; manually force change
                WV_TOOL_DENOISE_EVENT, {id:(*pState).wWavelet, $
                    top:Event.top, handler:Event.handler}
            ENDIF ELSE BEGIN ; let widget event make the change
                WIDGET_CONTROL,(*pState).wWavelet, $
                    SET_VALUE={family:wv_denoise_state.family, $
                    order:wv_denoise_state.order}
            ENDELSE
            END
        menuID.SaveState: BEGIN
            suffix = '.sav'
pick_again:
            filename = DIALOG_PICKFILE(/WRITE, $
                GROUP=Event.top, $
                GET_PATH=file_path, $
                PATH=(*pState).file_path, $
                FILTER='*'+suffix, $
                TITLE='Save Denoise State')
            IF (filename EQ '') THEN RETURN
            IF ((FILE_SEARCH(filename))[0] NE '') THEN BEGIN
                result = DIALOG_MESSAGE([filename, $
                    'This file already exists. Replace existing file?'], $
                    DIALOG_PARENT=Event.top, $
                    /QUESTION,TITLE='Save As')
                IF (result EQ 'No') THEN GOTO,pick_again
            ENDIF
            WIDGET_CONTROL, /HOURGLASS
            suffix_pos = STRPOS(filename,suffix)
            correct_suffix = suffix_pos EQ (STRLEN(filename)-STRLEN(suffix))
            IF ((NOT correct_suffix) AND $
                (!VERSION.OS_FAMILY EQ 'Windows')) THEN $
                filename = filename + suffix
            WIDGET_CONTROL,(*pState).wThreshold,GET_VALUE=soft_threshold
            WIDGET_CONTROL,(*pState).wWavelet,GET_VALUE=wavelet
            WIDGET_CONTROL,(*pState).wCoefficients,GET_VALUE=coefficients
            wv_denoise_state = {created:SYSTIME(), $
                file_path:file_path, $
                family:wavelet.family, $
                order:wavelet.order, $
                coefficients:coefficients, $
                soft_threshold:soft_threshold, $
                Xdata: *(*pState).pXdata, $
                Ydata: *(*pState).pYdata, $
                mean: (*pState).mean, $
                variance: (*pState).variance, $
                xtitle:(*pState).xtitle, $
                xunits:(*pState).xunits, $
                ytitle:(*pState).ytitle, $
                yunits:(*pState).yunits, $
                title:(*pState).title, $
                units:(*pState).units, $
                data:*(*pState).pData, $
                data_filtered:*(*pState).pDataFilt, $
                dwt_filtered:*(*pState).pDwtFilt}
            SAVE, FILE=filename, wv_denoise_state, /COMPRESS
            (*pState).file_path = file_path
            END
        menuID.Close: BEGIN
            WIDGET_CONTROL, Event.top, /DESTROY
            RETURN
            END
        ENDCASE ; menu items
        END ; wPDmenu
    ELSE: ; unknown event
    ENDCASE ; all events

    RETURN
END ; wv_tool_denoise_event


;--------------------------------------------------------------------
PRO wv_tool_denoise_cleanup, wBase

    COMPILE_OPT strictarr, hidden

; error handling
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        MESSAGE,/INFO,!ERROR_STATE.MSG
        RETURN
    ENDIF

    WIDGET_CONTROL,wBase,GET_UVALUE=pState

; Clean up heap variables
    FOR i=0,N_TAGS(*pState)-1 DO BEGIN
        siz = SIZE((*pState).(i))
        type = siz[siz[0]+1]
        CASE type OF
            10: PTR_FREE, (*pState).(i) ; pointer
            11: OBJ_DESTROY, (*pState).(i) ; object
            ELSE:
        ENDCASE
    ENDFOR
    PTR_FREE, pState
END   ; wv_tool_denoise_cleanup


;----------------------------------------------------------------
FUNCTION wv_tool_denoise, $
    array, $ ; 2D array
    x, $     ; x coordinates of array
    y, $     ; y coordinates of array
    TITLE=title, $
    UNITS=units, $
    XTITLE=xtitle, $
    XUNITS=xunits, $
    YTITLE=ytitle, $
    YUNITS=yunits, $
    XOFFSET=xoffset, $
    YOFFSET=yoffset, $
    NO_COPY=no_copy, $ ; dummy variable, so we can force it set
    COLUMN=column, $ ; dummy variable, so it can't get set in _extra
    MBAR=mbar, $ ; dummy variable, so it can't get set in _extra
    ROW=row, $ ; dummy variable, so it can't get set in _extra
    _EXTRA=_extra ; this includes keywords such as UVALUE, GROUP_LEADER, etc.


    COMPILE_OPT strictarr

; Check for valid Wavelet license
; Don't bother modifying these lines as WV_DWT and WV_PWT will not work.
    IF (NOT LMGR('idl_wavelet', VERSION='1.0')) THEN BEGIN
        MESSAGE, /INFO, /NONAME, $
            'You do not seem to have a valid IDL Wavelet Toolkit license'
        MESSAGE, /INFO, /NONAME, /NOPREFIX, $
            '  Exiting...'
        RETURN,0
    ENDIF

; error handling
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        MESSAGE,/INFO,!ERROR_STATE.MSG
        RETURN,0
    ENDIF

; make sure we have some data
    siz = SIZE(array)
    IF ((siz[0] LT 1) OR (siz[0] GT 2)) THEN MESSAGE,'must input data vector or array'

; set up graphics
    DEVICE,BYPASS_TRANSLATION=0,DECOMPOSED=0
    DEVICE, GET_SCREEN_SIZE=screen_size
    xsize1 = 256 < 0.3*screen_size[0]
    ysize1 = 256 < 0.4*screen_size[1]
    xsize2 = 256 < 0.3*screen_size[0]
    ysize2 = 256 < 0.4*screen_size[1]

; construct other keywords, if necessary
    IF (N_ELEMENTS(x) LT 1) THEN x = LINDGEN(siz[1])
    IF (N_ELEMENTS(y) LT 1) THEN BEGIN
        IF (siz[0] EQ 1) THEN y=0 ELSE y=LINDGEN(siz[2])
    ENDIF
    IF (N_ELEMENTS(xtitle) LE 0) THEN xtitle = 'X'
    IF (N_ELEMENTS(ytitle) LE 0) THEN ytitle = 'Y'
    IF (N_ELEMENTS(xunits) LE 0) THEN xunits = ''
    IF (N_ELEMENTS(yunits) LE 0) THEN yunits = ''
    IF (N_ELEMENTS(units) LE 0) THEN units = ''
    IF (N_ELEMENTS(title) LT 1) THEN title = ''
    title1 = 'Denoise: ' + title
    IF (N_ELEMENTS(xoffset) LT 1) THEN xoffset = $
        (screen_size[0] - (xsize1 + xsize2 + 250)) > 0
    IF (N_ELEMENTS(yoffset) LT 1) THEN yoffset = 20


    wBase = WIDGET_BASE( $
        /COLUMN, $
        MBAR=wMenubar, $
        SPACE=0, $
        TITLE=title1, $
        /TLB_KILL_REQUEST_EVENTS, $
        /TLB_SIZE_EVENTS, $
        XOFFSET=xoffset,YOFFSET=yoffset, $
        _EXTRA=_extra)

    menu_list = [ $
        '1\File', $
            '0\Open State...', $
            '0\Save State...', $
            '6\Close']

    wPDmenu = CW_PDMENU(wMenubar,menu_list, $
        IDS=menu_ids, $
        /MBAR, $
        /RETURN_ID)

    wMenuID = {base:wPDmenu}
    FOR i=0,N_ELEMENTS(menu_list)-1 DO BEGIN
        menu_name = STRSPLIT(menu_list[i],'\',/EXTRACT)
        IF (menu_name[0] NE '1') THEN BEGIN
            menu_name = menu_name[1]
            menu_name = (STRSPLIT(menu_name,'...',/EXTRACT))[0]  ; remove ...
            menu_name = STRCOMPRESS(menu_name,/REMOVE_ALL) ; remove spaces
            wMenuID = CREATE_STRUCT(wMenuID,menu_name,menu_ids[i])  ; save ID
        ENDIF
    ENDFOR

    wBase1 = WIDGET_BASE(wBase,/ROW)

; draw widgets
    wBase_draw = WIDGET_BASE(wBase1,COLUMN=2)
    dummy = WIDGET_LABEL(wBase_draw,VALUE='Original data')
    wDraw_data = WIDGET_DRAW(wBase_draw, $
        RETAIN=2, $
        UVALUE=1, $  ; redraw
        XSIZE=xsize1,YSIZE=ysize1)
    wWps_label = WIDGET_LABEL(wBase_draw,VALUE='Wavelet coeffs (black=0)')
    wDraw_wps = WIDGET_DRAW(wBase_draw, $
        RETAIN=2, $
        XSIZE=xsize1,YSIZE=ysize2)
    dummy = WIDGET_LABEL(wBase_draw,VALUE='Filtered data')
    wDraw_filt = WIDGET_DRAW(wBase_draw, $
        RETAIN=2, $
        XSIZE=xsize2,YSIZE=ysize1)
    dummy = WIDGET_LABEL(wBase_draw,VALUE='Coefficient power')
    wDraw_energy = WIDGET_DRAW(wBase_draw, $
        RETAIN=2, $
        XSIZE=xsize2,YSIZE=ysize2)

    wBase_message = WIDGET_BASE(wBase,/ROW)
    wMessage = WIDGET_TEXT(wBase_message,  $
        SCR_XSIZE=xsize1+xsize2,VALUE='Ready',/ALIGN_LEFT)

    wBase_options = WIDGET_BASE(wBase1,/COLUMN)

; Wavelet options base
    dummy = WIDGET_LABEL(wBase_options,VALUE='Wavelet options',/ALIGN_LEFT)
    wWavelet = WV_CW_WAVELET(wBase_options,/FRAME,/DISCRETE)

; Denoise options base
    blank_line = WIDGET_LABEL(wBase_options,VALUE=' ')
    dummy = WIDGET_LABEL(wBase_options,VALUE='Denoise options',/ALIGN_LEFT)
    wBase_denoise = WIDGET_BASE(wBase_options,/COLUMN,/FRAME)

; Cumulative power slider
    WIDGET_CONTROL,WIDGET_INFO(wWavelet,/CHILD),GET_UVALUE=WvCwState
    geom = WIDGET_INFO(WvCwState.wOrder,/GEOMETRY)
    wCum_slider = WIDGET_SLIDER(wBase_denoise, $
        MINIMUM=1,MAXIMUM=100,VALUE=100, $
        UVALUE=100, $
        TITLE='Cumulative power (%)', $
        XSIZE=geom.xsize)

; Power coeff field
    wCoefficients = CW_FIELD(wBase_denoise, $
        /LONG, $
        /RETURN_EVENTS, $
        TITLE='# coeffs ', $
        VALUE=-1L, $
        UVALUE=0L, $
        XSIZE=10)

; Threshold buttons
    wThreshold = CW_BGROUP(wBase_denoise,['Hard','Soft']+' threshold', $
        /EXCLUSIVE,BUTTON_UVALUE=['Hard','Soft'],LABEL_LEFT='  ')

; Wavelet options base
    blank_line = WIDGET_LABEL(wBase_options,VALUE=' ')
    dummy = WIDGET_LABEL(wBase_options,VALUE='Results',/ALIGN_LEFT)
    wText_results = WIDGET_TEXT(wBase_options, $
        /FRAME, $
        /SCROLL, $
        XSIZE=23, $
        YSIZE=6)

; Realize everything & get Draw window sizes
    WIDGET_CONTROL,wBase,/REALIZE, $
        TLB_GET_SIZE=tlb_size
    WIDGET_CONTROL,wDraw_data,GET_VALUE=window_data
    WIDGET_CONTROL,wDraw_filt,GET_VALUE=window_filt
    WIDGET_CONTROL,wDraw_wps,GET_VALUE=window_wps
    WIDGET_CONTROL,wDraw_energy,GET_VALUE=window_energy

; find the minimum widget size for the options bar
    geom_min = WIDGET_INFO(wWps_label,/GEOMETRY)
    min_xsize = geom_min.scr_xsize
    geom_min = WIDGET_INFO(wBase_options,/GEOMETRY)
    min_ysize = geom_min.ysize

    WIDGET_CONTROL,wThreshold,SET_VALUE=0

; add information to "info" structure
    meanArray = TOTAL(array)/N_ELEMENTS(array)
    varArray = VARIANCE(array)

    pState = PTR_NEW({ $
        wBase:wBase, $
        wPDmenu:wPDmenu, $
        wMenuID:wMenuID, $
        wMessage:wMessage, $
        wDraw_data:wDraw_data, $
        wDraw_filt:wDraw_filt, $
        wDraw_wps:wDraw_wps, $
        wDraw_energy:wDraw_energy, $
        wWavelet:wWavelet, $
        wCum_slider:wCum_slider, $
        wCoefficients:wCoefficients, $
        wThreshold:wThreshold, $
        wText_results:wText_results, $
        file_path:'', $
        window_data:window_data, $
        window_filt:window_filt, $
        window_wps:window_wps, $
        window_energy:window_energy, $
        min_base_size:[min_xsize,min_ysize]+50, $
        base_size:tlb_size, $
        xratio:FLOAT(xsize1)/(xsize1+xsize2), $
        yratio:FLOAT(ysize1)/(ysize1+ysize2), $
        pXdata: PTR_NEW(x), $
        pYdata: PTR_NEW(y), $
        pData: PTR_NEW(array), $
        mean: meanArray, $
        variance: varArray, $
        xtitle:xtitle, $
        xunits:xunits, $
        ytitle:ytitle, $
        yunits:yunits, $
        title:title, $
        units:units, $
        pDataFilt:PTR_NEW(/ALLOCATE_HEAP), $
        pDwtFilt:PTR_NEW(/ALLOCATE_HEAP), $
        pDwt:PTR_NEW(/ALLOCATE_HEAP), $
        pWps:PTR_NEW(/ALLOCATE_HEAP), $
        pWt_sort:PTR_NEW(/ALLOCATE_HEAP), $
        pWt_cumulative:PTR_NEW(/ALLOCATE_HEAP), $
        pDenoiseState:PTR_NEW(/ALLOCATE_HEAP) $
        })

; save the WV variable into the base uvalue
    WIDGET_CONTROL,wBase,SET_UVALUE=pState

    XMANAGER, 'wv_tool_denoise',wBase, $
        /NO_BLOCK, $
        CLEANUP='wv_tool_denoise_cleanup'

    RETURN, wBase

END

