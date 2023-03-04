;----------------------------------------------------------------
; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/wavelet/source/wv_cw_wavelet.pro#1 $
;
; Copyright (c) 1999-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;+
; NAME:
;    WV_CW_WAVELET
;
; PURPOSE:
;
;    This function runs the IDL Wavelet Toolkit compound widget
;    for viewing wavelet functions.
;
; CALLING SEQUENCE:
;
;    Result = WV_CW_WAVELET([Parent]
;        [, TITLE=string] [, UNAME=string]
;        [, UVALUE=variable] [, WAVELETS=string array])
;
; INPUTS:
;
;    Parent: The widget ID of the parent widget.
;      Omit this argument to created a top-level widget.
;
; KEYWORD PARAMETERS:
;
;   TITLE: Set this keyword equal to a scalar string containing the title
;     of the top level base. TITLE is not used if the wavelet widget has
;     a parent widget. If it is not specified, the default title
;     is "Wavelets."
;
;   UNAME: Set this keyword to a string that can be used to identify
;     the widget in your code. You can associate a name with each widget
;     in a specific hierarchy, and then use that name to query the widget
;     hierarchy and get the correct widget ID.
;
;   UVALUE: Set this keyword equal to the user value associated with
;     the widget.
;
;   WAVELETS: A scalar string or vector of strings giving the names of
;     user-defined wavelet functions to be included in WV_CW_WAVELET.
;     The actual function names are constructed by removing all white space
;     from each name and attaching a prefix of WV_FN_.
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
;-
;  Variable name conventions used herein:
;       r==Reference to Object
;       p==pointer
;       w==widget ID
;


;----------------------------------------------------------------
PRO wv_cw_construct_discrete, wave_function, order, wave_fn, scale_fn, n, x, $
    LABEL=label

    label = ['Wavelet','!C!CScaling']

; find coefficients
    waveletInfo = CALL_FUNCTION(wave_function, order, $
        scaling,wavelet)
    n = LONG(waveletInfo.support)
; pad with some zeroes
    scale_fn = [DBLARR(n),SQRT(2d)*scaling,DBLARR(n)]
    wave_fn = [DBLARR(n),SQRT(2d)*wavelet,DBLARR(n)]
    ni = N_ELEMENTS(scale_fn)
    nj = N_ELEMENTS(wave_fn)
    jmax = 8L - FIX(ALOG(n)/ALOG(2))
    indx = LINDGEN(ni*(2L^(jmax-1)))*2L
    jndx = LINDGEN(nj*(2L^(jmax-1)))*2L
; construct the actual wavelet functions
    FOR j=0L,jmax-1 DO BEGIN
        ni = 2L*ni
        nj = 2L*nj
        tmp = scale_fn
        scale_fn = DBLARR(ni)
        scale_fn[indx[0:ni/2-1]] = tmp
        scale_fn = SQRT(2d)*CONVOL(scale_fn,scaling,CENTER=0)
        tmp = wave_fn
        wave_fn = DBLARR(nj)
        wave_fn[jndx[0:nj/2-1]] = tmp
        wave_fn = SQRT(2d)*CONVOL(wave_fn,scaling,CENTER=0)
    ENDFOR
    nx = N_ELEMENTS(scale_fn)
    n0 = MIN(WHERE(scale_fn GT 1E-5))
    x = (FINDGEN(nx)-n0)/(2^(jmax+1))

; This method works, but I can't figure out how to construct the wavelet
;   n = FIX(waveletInfo.support+2)
;   dwt = DBLARR(n)
;   dwt[1] = 1d
;   jmax = 3L - FIX(ALOG(n)/ALOG(2))
;   FOR j=0L,jmax-1 DO BEGIN
;       dwt = [dwt,dwt*0d]
;       dwt = WV_PWT(dwt,scaling,wavelet,0,0,/INVERSE,/DOUBLE)
;   ENDFOR
END


;----------------------------------------------------------------
PRO wv_cw_construct_continuous, wave_function, order, $
    real_wave_fn, cmplx_wave_fn, n, x, $
    LABEL=label

; find coefficients
    scale = 64
    n = 512
    waveletInfo = CALL_FUNCTION(wave_function, order, scale, n, $
        WAVELET=wavelet,/SPATIAL)
    real_wave_fn = FLOAT(wavelet)
    IF (SIZE(wavelet,/TNAME) EQ 'COMPLEX') THEN BEGIN
        cmplx_wave_fn = IMAGINARY(wavelet)
        label = ['Real','!C!CImaginary']
    ENDIF
    x = (FINDGEN(n) - (n-1)/2.0)/scale
END


;----------------------------------------------------------------
PRO wv_cw_draw_wavelet, discrete, wDraw, wave_function, order, $
    NO_PARENT=no_parent, NO_COLOR=no_color

    no_parent = KEYWORD_SET(no_parent)
    no_color = KEYWORD_SET(no_color)

    CASE discrete OF
    0: WV_CW_CONSTRUCT_CONTINUOUS, $
            wave_function,order,wavelet1,wavelet2,n,x,LABEL=label
    1: WV_CW_CONSTRUCT_DISCRETE, $
        wave_function,order,wavelet1,wavelet2,n,x,LABEL=label
    ENDCASE

    nx = N_ELEMENTS(x)
    do_wave2 = N_ELEMENTS(wavelet2) GT 0


; Plot scaling & wavelet functions
    ; save defaults
    DEVICE, GET_DECOMPOSED=saveDecomposed
    DEVICE, BYPASS_TRANSLATION=0, DECOMPOSED=0
    pBackground = !P.BACKGROUND
    pColor = !P.COLOR
    ; We do not want to change the current color table. However, we must
    ; choose foreground/background colors that are different.
    ; So convert the current color table to grayscale, and choose the
    ; lightest and darkest values.
    TVLCT,red,green,blue,/GET
    gray = 0.299*red + 0.587*green + 0.114*blue
    void = MAX(gray, lightest, SUBSCRIPT_MIN=darkest)
    !P.BACKGROUND = lightest  ; lightest color
    !P.COLOR = darkest        ; darkest color

    ; find an appropriate yrange, with some padding
    yrange0 = MIN(wavelet1)
    yrange1 = MAX(wavelet1)

    ; only plot the "nonzero" middle of the wavelet
    n = N_ELEMENTS(x)
    n5 = FIX(0.05*n)
    keep = WHERE(ABS(wavelet1) GE 0.01*MAX(ABS(wavelet1)))
    ; add some extra padding on each side
    keep0 = (keep[0] - n5)
    keep1 = (MAX(keep) + n5)
    IF do_wave2 THEN BEGIN
        keep = WHERE(ABS(wavelet2) GE 0.01*MAX(ABS(wavelet2)))
        keep0 = keep0 < (keep[0] - n5)
        keep1 = keep1 > (MAX(keep) + n5)
        yrange0 = yrange0 < MIN(wavelet2)
        yrange1 = yrange1 > MAX(wavelet2)
    ENDIF
    keep0 = keep0 > 0
    keep1 = keep1 < (n-1)

    xrange = [x[keep0],x[keep1]]
    yrange = 1.1*[yrange0,yrange1]

    IF (no_parent) THEN BEGIN ; draw axes
        extra = {xstyle:9, $
            ystyle:9, $
            xmargin:[4,1], $
            ymargin:[2,1], $
            thick:2}
    ENDIF ELSE BEGIN ; don't draw the axes, zero margin
        extra = {xstyle:5, $
            ystyle:5, $
            xmargin:[0,0], $
            ymargin:[0,0], $
            thick:1}
    ENDELSE

    WIDGET_CONTROL, wDraw, GET_VALUE=win_num
    WSET,win_num
    PLOT,x,wavelet1, $
        XRANGE=xrange, $
        YRANGE=yrange, $
        _EXTRA=extra
    IF (no_parent) AND (N_ELEMENTS(label) GT 0) THEN BEGIN
        XYOUTS,!X.CRANGE[1],!Y.CRANGE[1]*0.9,label[0] + ' (solid)', $
            ALIGN=1,/NOCLIP
    ENDIF
    IF do_wave2 THEN BEGIN
        OPLOT,x,wavelet2, $
            THICK=extra.thick, LINESTYLE=2
        IF (no_parent) THEN XYOUTS,!X.CRANGE[1],!Y.CRANGE[1]*0.9, $
            label[1] + ' (dash)', ALIGN=1,/NOCLIP
    ENDIF

    ; Restore defaults.
    !P.BACKGROUND = pBackground
    !P.COLOR = pColor
    DEVICE, DECOMPOSED=saveDecomposed

end


;----------------------------------------------------------------
PRO wv_cw_wavelet_realize, base
    COMPILE_OPT strictarr, hidden
    child = WIDGET_INFO(base, /CHILD)
    WIDGET_CONTROL, child, GET_UVALUE=info
    value = {family:info.wavelets[0]}
    IF (info.initialFamily NE '') THEN $
        value.family = info.initialFamily
    IF (info.initialOrder GT 0) THEN value = $
        CREATE_STRUCT(value, 'ORDER', info.initialOrder)
    WIDGET_CONTROL,base,SET_VALUE=value ;Set value of WV_CW_WAVELET widget
    RETURN
END


;----------------------------------------------------------------
FUNCTION wv_cw_wavelet_getv, id ;Return value of WV_CW_WAVELET widget
    COMPILE_OPT strictarr, hidden
    child = WIDGET_INFO(id,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=info
; anonymous structure {family:'',order:0}
    RETURN,{Family:info.wavelets[info.familyIndex > 0], $
        Order:info.order}
END


;----------------------------------------------------------------
PRO wv_cw_wavelet_setv, id, value ;Set value of WV_CW_WAVELET widget

    COMPILE_OPT strictarr, hidden

    IF (N_TAGS(value) LT 1) THEN BEGIN
        MESSAGE,/INFO,"Value should be a structure {FAMILY:' ',ORDER:0d}"
        RETURN
    ENDIF

; get current WV_CW_WAVELET info
    child = WIDGET_INFO(id,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=info

; check if Family tag exists
    tags = TAG_NAMES(value)
    do_family = (MAX(tags EQ 'FAMILY') EQ 1b)
    new_family = ''
    IF (do_family) THEN new_family = STRUPCASE(value.family)
    valid_families = STRUPCASE(info.wavelets)
    current_family = ''
    IF (info.familyIndex GE 0) THEN $
        current_family = valid_families[info.familyIndex]

; check if Order tag exists
    do_order = (MAX(tags EQ 'ORDER') EQ 1b)

    IF (do_family AND (new_family NE current_family)) THEN BEGIN
        valid = (WHERE(valid_families EQ new_family))[0]
        IF (valid EQ -1) THEN BEGIN
            MESSAGE,/INFO,'Invalid family ' + new_family
            RETURN
        ENDIF
        IF (do_order) THEN BEGIN
            info.order = -value.order ; set this to skip default order
            WIDGET_CONTROL,child,SET_UVALUE=info
        ENDIF
        WIDGET_CONTROL,info.wFamily,SET_DROPLIST_SELECT=valid, $
            SEND_EVENT={id:info.wFamily,top:id,handler:id,index:valid}
        RETURN
    ENDIF

    IF (do_order) THEN BEGIN  ; same Family, but new Order
        wtype = WIDGET_INFO(info.wOrder,/NAME)
        CASE (wtype) OF
            'SLIDER': WIDGET_CONTROL,info.wOrder,SET_VALUE=value.order, $
                SEND_EVENT={id:info.wOrder,top:id,handler:id, $
                value:value.order}
;           'DROPLIST': BEGIN  ; this hasn't been tested!
;               WIDGET_CONTROL,info.wOrder,GET_VALUE=values
;               valid = (WHERE(values EQ value.order))[0]  ; check Order list
;               IF (valid EQ -1) THEN BEGIN
;                   MESSAGE,/INFO,'Invalid order ' + STRING(value.order)
;                   RETURN
;               ENDIF
;               WIDGET_CONTROL,info.wOrder,SET_DROPLIST_SELECT=value.order, $
;                   SEND_EVENT={id:info.wOrder,top:id,handler:id, $
;                   index:value.order}
;               END
            ELSE:  ; label or text widget, don't change
        ENDCASE
    ENDIF
    RETURN
END


;----------------------------------------------------------------
FUNCTION wv_cw_wavelet_info, waveletInfo
    value = ['', $
        (['Continuous','Discrete'])[waveletInfo.discrete], $
        (['Nonorthogonal','Orthogonal'])[waveletInfo.orthogonal]]
    support = 'No'
    IF (waveletInfo.support GT 0) THEN $
        support = STRTRIM(waveletInfo.support,2)
    moments = 'None'
    IF (waveletInfo.moments GT 0) THEN $
        moments = STRTRIM(waveletInfo.moments,2)
    regularity = 'Unknown'
    IF (waveletInfo.regularity NE -1.) THEN $
        regularity = STRING(waveletInfo.regularity,FORMAT='(F8.2)')
    value = [value, $
        (['As','S','Near s'])[waveletInfo.symmetric]+'ymmetric', $
        'Compact support: '+support, $
        'Vanishing moments: '+moments, $
        'Regularity: '+regularity]
    IF (waveletInfo.discrete EQ 0) THEN BEGIN
        efolding = 'Unknown'
        IF (waveletInfo.efolding NE 0) THEN efolding = $
            STRING(waveletInfo.efolding,FORMAT='(G6.3)')
        fourier = 'Unknown'
        IF (waveletInfo.fourier_period GT 0) THEN fourier = $
            STRING(waveletInfo.fourier_period,FORMAT='(G6.3)')
;       time_decorr = 'Unknown'
;       IF (waveletInfo.time_decorr GT 0) THEN time_decorr = $
;           STRING(waveletInfo.time_decorr,FORMAT='(G6.3)')
;       scale_decorr = 'Unknown'
;       IF (waveletInfo.scale_decorr GT 0) THEN scale_decorr = $
;           STRING(waveletInfo.scale_decorr,FORMAT='(G6.3)')
        value = [value, $
            'e-folding time: '+efolding+'s', $
            'Period/scale ratio: '+fourier]
;           'Time decorrelation: '+time_decorr, $
;           'Scale decorrelation: '+scale_decorr]
    ENDIF
    RETURN, ' ' + value
END

;----------------------------------------------------------------
FUNCTION wv_cw_wavelet_event, Event

    COMPILE_OPT strictarr, hidden

;   ON_ERROR, 2
    child = WIDGET_INFO(Event.handler,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=info

    CASE (TAG_NAMES(Event,/STRUCTURE_NAME)) OF
        'WIDGET_KILL_REQUEST': Event.id = info.wClose
        'WIDGET_BASE': BEGIN
            WIDGET_CONTROL, Event.handler, TLB_GET_SIZE=new_size
            dx = new_size[0] - info.base_size[0]
            dy = new_size[1] - info.base_size[1]
            geom = WIDGET_INFO(info.wDraw,/GEOMETRY)
            xsize1 = (geom.xsize + dx) > info.min_size[0]
            ysize1 = (geom.ysize + dy) > info.min_size[1]
            WIDGET_CONTROL,Event.handler,UPDATE=0
            WIDGET_CONTROL,info.wDraw,DRAW_XSIZE=xsize1,DRAW_YSIZE=ysize1
            WIDGET_CONTROL,Event.handler,/UPDATE
            WIDGET_CONTROL,Event.handler,TLB_GET_SIZE=new_size
            info.base_size = new_size
            WIDGET_CONTROL,child,SET_UVALUE=info
        ; re-draw
            Event = {id:info.wOrder, $
                    top:Event.top,handler:Event.handler, $
                    value:info.order}
            info.order = 0
            END
        ELSE:
    ENDCASE

    CASE (Event.id) OF
    info.wFamily: BEGIN
        IF (Event.index EQ info.familyIndex) THEN RETURN, 0 ; family unchanged
        info.familyIndex = Event.index
        info.order = 0
        family = info.wavelets[Event.index]
        wave_function = STRCOMPRESS('wv_fn_'+family,/REMOVE_ALL)
        waveletInfo = CALL_FUNCTION(wave_function)
        WIDGET_CONTROL,Event.handler,UPDATE=0
;       IF (WIDGET_INFO(info.wOrder,/VALID)) THEN $
;           WIDGET_CONTROL,info.wOrder,/DESTROY
;       WIDGET_CONTROL,info.wOrder_name,SET_VALUE=waveletInfo.order_name
        CASE (waveletInfo.order_range[0] NE waveletInfo.order_range[1]) OF
        0: BEGIN ; only 1 order
            value = waveletInfo.order_range[0] ; the only choice
            WIDGET_CONTROL,info.wOrder, $
                SET_SLIDER_MIN=waveletInfo.order_range[0], $
                SET_SLIDER_MAX=waveletInfo.order_range[0]+1
            WIDGET_CONTROL,info.wOrder,SET_VALUE=value,SENSITIVE=0
            WIDGET_CONTROL,info.wOrder_name,SENSITIVE=0
;           info.wOrder = WIDGET_LABEL(info.base_family, $
;               VALUE=waveletInfo.order_name)
            new_event = {id:info.wOrder, $
                top:Event.top,handler:Event.handler, $
                value:waveletInfo.order_range[0]}
            END
        1: BEGIN ; multiple orders
            value = waveletInfo.order_range[2] ; default
            IF (info.order LT 0) THEN value = -info.order ; user choice
;    make sure we are within the valid Order range
            value = waveletInfo.order_range[0] > value < waveletInfo.order_range[1]
            value = FIX(value)
            WIDGET_CONTROL,info.wOrder, $
                SET_SLIDER_MIN=waveletInfo.order_range[0], $
                SET_SLIDER_MAX=waveletInfo.order_range[1]
            WIDGET_CONTROL,info.wOrder,SET_VALUE=value,/SENSITIVE
            WIDGET_CONTROL,info.wOrder_name,/SENSITIVE
            new_event = {id:info.wOrder, $
                top:Event.top,handler:Event.handler, $
                value:value}
            END
        ELSE: BEGIN  ; droplist, this hasn't been tested!
;               info.wOrder = WIDGET_DROPLIST(info.base_family, $
;                   TITLE=' Order: ',VALUE=STRING(waveletInfo.order_range), $
;                   UVALUE=waveletInfo.order_range)
            END
        ENDCASE
        WIDGET_CONTROL,child,SET_UVALUE=info
        WIDGET_CONTROL,Event.handler,/UPDATE
        Event = WV_CW_WAVELET_EVENT(new_event)
        RETURN, Event
        END
    info.wOrder: BEGIN
        family = info.wavelets[info.familyIndex > 0]
        order = Event.value
        IF (order EQ info.order) THEN RETURN,0 ; order is unchanged, get out
        wave_function = STRCOMPRESS('wv_fn_'+family,/REMOVE_ALL)
        waveletInfo = CALL_FUNCTION(wave_function,order, $
            scaling,wavelet)
        info.order = order
        WIDGET_CONTROL,child,SET_UVALUE=info
        WIDGET_CONTROL,info.wOrder_name, $
            SET_VALUE=waveletInfo.order_name+':  '+STRTRIM(order,2)

; if inside another Widget, then don't print info or draw wavelet
        Event = {id:info.base,top:info.parent,handler:info.base, $
            family:info.wavelets[info.familyIndex > 0],order:info.order}

; print out wavelet info to Text widget
        IF WIDGET_INFO(info.wText,/VALID) THEN BEGIN ; wText valid
            value = WV_CW_WAVELET_INFO(waveletInfo)
            WIDGET_CONTROL,info.wText,SET_VALUE=value
        ENDIF ; wText valid

; Construct scaling & wavelet functions
        IF WIDGET_INFO(info.wDraw,/VALID) THEN BEGIN ; wDraw valid
            WV_CW_DRAW_WAVELET, waveletInfo.discrete, info.wDraw, $
                wave_function, order, $
                NO_PARENT=info.no_parent, NO_COLOR=info.no_color
        ENDIF
        END
    info.wClose: BEGIN
        WIDGET_CONTROL,info.base,/DESTROY
        void = CHECK_MATH() ; Silently flush any accumulated math error.
        !EXCEPT = info.math_except
        RETURN,0
        END
    ELSE:
    ENDCASE

    IF (info.no_parent) THEN Event = 0  ; swallow Events
    RETURN, Event  ; return Events up the widget chain
END


;----------------------------------------------------------------
; If WV_CW_WAVELET is a modal widget (i.e. no parent), then,
; because XMANAGER can only issue Events to procedures (not fns),
; we need to have a dummy procedure to pass events on to the
; event-handling function.
PRO wv_cw_wavelet_pass_event, Event
    COMPILE_OPT strictarr, hidden
    dummy = WV_CW_WAVELET_EVENT(Event)
    RETURN
END


;----------------------------------------------------------------
FUNCTION wv_cw_wavelet, $
    parent, $
    DISCRETE=discrete, $
    NO_DRAW_WINDOW=no_draw_window, $
    TITLE=title, $
    WAVELETS=wavelets, $
    VALUE=value, $
    NO_COLOR=no_color, $
    COLUMN=column, $ ; dummy variable so it can't get set in _extra
    MBAR=mbar, $ ; dummy variable so it can't get set in _extra
    ROW=row, $ ; dummy variable so it can't get set in _extra
    _EXTRA=_extra ; this includes keywords such as UVALUE, GROUP_LEADER, etc.

    COMPILE_OPT strictarr

;   ON_ERROR,2 ;return to caller

    COMMON cWvAppletData, $
        wCurrentApplet, $   ; widget ID of currently-active Applet
        WaveletFamilies     ; string array of usable wavelet functions


; find all current wavelet families
    WV_IMPORT_WAVELET,wavelets, $
        RESET=(N_ELEMENTS(WaveletFamilies) EQ 0)

    WaveletInclude = WaveletFamilies
    IF (N_ELEMENTS(discrete) GT 0) THEN BEGIN
        discrete = KEYWORD_SET(discrete)
        WaveletInclude = ''
        FOR i=0,N_ELEMENTS(WaveletFamilies)-1 DO BEGIN
            info = CALL_FUNCTION('WV_FN_'+STRUPCASE(WaveletFamilies[i]))
            IF (info.discrete EQ discrete) THEN $
                WaveletInclude = [WaveletInclude, WaveletFamilies[i]]
        ENDFOR
        IF (N_ELEMENTS(WaveletInclude) LT 2) THEN MESSAGE, $
            'No wavelet functions were found.'
        WaveletInclude = WaveletInclude[1:*]
    ENDIF


; If no parent, then create base
    no_parent = (N_PARAMS() EQ 0)
    tlb_size = [0L,0L]
    IF (no_parent) THEN BEGIN
        IF N_ELEMENTS(title) LE 0 THEN title='Wavelet functions'
        DEVICE, GET_SCREEN_SIZE=screen_size
        xsize1 = 250 < 0.4*screen_size[0]
        ysize1 = 250 < 0.4*screen_size[1]
        xoffset = (screen_size[0]/2 - xsize1) > 0
        yoffset = 10
        base = WIDGET_BASE(TITLE=title, $
            /ROW, $
            /TLB_KILL_REQUEST_EVENT, $
            /TLB_SIZE_EVENTS, $
            XOFFSET=xoffset,YOFFSET=yoffset, $
            _EXTRA=_extra)
        wDraw = WIDGET_DRAW(base, $
            RETAIN=2, $  ; IDL retains backing store
            XSIZE=xsize1,YSIZE=ysize1)
        parent = base
    ENDIF ELSE BEGIN
        IF (N_ELEMENTS(frame) LT 1) THEN frame = 0
        base = WIDGET_BASE(parent,/COLUMN,/BASE_ALIGN_CENTER, $
            EVENT_FUNC='wv_cw_wavelet_event',_EXTRA=_extra)
        wDraw = 0L
        IF NOT KEYWORD_SET(no_draw_window) THEN BEGIN
            wDraw = WIDGET_DRAW(base, $
                RETAIN=2, $  ; IDL retains backing store
                XSIZE=64,YSIZE=64)
        ENDIF
    ENDELSE


    WIDGET_CONTROL, base, $
        FUNC_GET_VALUE='wv_cw_wavelet_getv', $
        PRO_SET_VALUE='wv_cw_wavelet_setv', $
        NOTIFY_REALIZE='wv_cw_wavelet_realize'


; construct wavelet family droplist
    base_right = WIDGET_BASE(base,/COLUMN,/BASE_ALIGN_CENTER, $
        SPACE=1,XPAD=0,YPAD=0)
    base_family = WIDGET_BASE(base_right,/COLUMN, $
        SPACE=0,XPAD=0,YPAD=0)

; Family droplist
    wFamily = WIDGET_DROPLIST(base_family,TITLE=' Family:', $
        VALUE=WaveletInclude)

; Order slider
    geom = WIDGET_INFO(wFamily,/GEOMETRY)
    wOrder = WIDGET_SLIDER(base_family, $
        MINIMUM=0,MAXIMUM=100, $
        /SUPPRESS_VALUE, $
        VALUE=0, $
        DRAG=no_parent, $
        XSIZE=geom.xsize)
    wOrder_name = WIDGET_LABEL(base_family, $
        /ALIGN_LEFT, $
        /DYNAMIC_RESIZE,VALUE=' ')

    wText = 0L
    wClose = 0L
    IF (no_parent) THEN BEGIN
        wText = WIDGET_TEXT(base_right,/WRAP,FRAME=1,XSIZE=28,YSIZE=8)
        wClose = WIDGET_BUTTON(base_right,VALUE='  Close  ')
    ENDIF


; Check if initial VALUE was supplied
    initialFamily = ''
    initialOrder = -1d
    IF (N_TAGS(value) GT 0) THEN BEGIN
        IF (MAX(TAG_NAMES(value) EQ 'FAMILY') EQ 1) THEN $
            initialFamily = value.family
        IF (MAX(TAG_NAMES(value) EQ 'ORDER') EQ 1) THEN $
            initialOrder = value.order
    ENDIF


; save widget information into the base child uvalue
    info = {no_parent:no_parent, $
        parent:parent, $
        base:base, $
        base_size:tlb_size, $
        min_size:[0L,0L], $
        no_color:KEYWORD_SET(no_color), $
        wDraw:wDraw, $
        base_family:base_family, $
        wText:wText, $
        wFamily:wFamily, $
        wOrder:wOrder, $
        wOrder_name:wOrder_name, $
        wClose:wClose, $
        wavelets:WaveletInclude, $
        familyIndex:-1L, $
        order:0d, $
        initialFamily:initialFamily, $
        initialOrder:initialOrder, $
        math_except:!EXCEPT}
    child = WIDGET_INFO(base,/CHILD)
    WIDGET_CONTROL,child,SET_UVALUE=info

    IF (no_parent) THEN BEGIN
        WIDGET_CONTROL,base,/REALIZE, $
            TLB_GET_SIZE=tlb_size
        geom = WIDGET_INFO(base_right,/GEOMETRY)
        info.min_size = [geom.xsize,geom.ysize]
    ENDIF
    info.base_size = tlb_size
    WIDGET_CONTROL,child,SET_UVALUE=info

    void = CHECK_MATH() ; Silently flush any accumulated math error.
    !EXCEPT = 0  ; Silently accumulate any subsequent math errors.

    IF (no_parent) THEN BEGIN ; no parent
        XMANAGER, 'wv_cw_wavelet', base,/NO_BLOCK, $
            EVENT_HANDLER='wv_cw_wavelet_pass_event'
    ENDIF ; no parent


    RETURN,base
END
