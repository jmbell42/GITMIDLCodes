;----------------------------------------------------------------
; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/wavelet/source/wv_plot_multires.pro#1 $
;
; Copyright (c) 1999-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;+
; NAME:
;    WV_PLOT_MULTIRES
;
; PURPOSE:
;
;    This function runs the IDL Wavelet Toolkit multiresolution
;    analysis widget.
;
; CALLING SEQUENCE:
;
;    Result = WV_PLOT_MULTIRES( Array [, X] [, Y]
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
;       location of points along the first dimension of Array.
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
;      The default is "MRes:".
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
;-
;  Variable name conventions used herein:
;       r==Reference to Object
;       p==pointer
;       w==widget ID
;

PRO wv_plot_multires_wavelet_Event, Event, $
    PRINTER=printer

    COMPILE_OPT strictarr, hidden

; error handling
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        MESSAGE,/INFO,!ERROR_STATE.MSG
        RETURN
    ENDIF

    WIDGET_CONTROL, Event.handler, GET_UVALUE=pState
    printer = KEYWORD_SET(printer)
    IF (NOT printer) THEN BEGIN
        WIDGET_CONTROL, /HOURGLASS
        DEVICE,BYPASS_TRANSLATION=0,DECOMPOSED=0
        WIDGET_CONTROL,(*pState).wDraw,GET_VALUE=win_num
        WSET,win_num
    ENDIF

    wave_function = STRCOMPRESS('wv_fn_'+Event.family,/REMOVE_ALL)
    winfo = CALL_FUNCTION(wave_function,Event.order, $
            scaling,wavelet,ioff,joff)
    data = *(*pState).pData
    siz = SIZE(data)
    oneD = (siz[0] EQ 1)
    dim = 2L^(LONG(ALOG(siz[1:2])/ALOG(2)+0.99999))
    nx = dim[0]
    ny = dim[1]
    IF (siz[0] EQ 1) THEN data_in = DBLARR(nx) $
        ELSE data_in = DBLARR(nx,ny)
    n = N_ELEMENTS(data)
    meann = TOTAL(data)/n
    mx = MAX(data,MIN=mn)
    IF (mx EQ mn) THEN mx = mn + 1
    data_in[0,0] = data - meann
    dwt = WV_DWT(data_in,scaling,wavelet,ioff,joff,/DOUBLE)
    pBackground = !P.BACKGROUND
    pColor = !P.COLOR
    xomargin = !X.OMARGIN  ; save default
    yomargin = !Y.OMARGIN
    if (not printer) then begin
        TVLCT,r,g,b,/GET
        LOADCT, 0, /SILENT
        nRed = N_ELEMENTS(r)
        !P.BACKGROUND = nRed-1  ; lightest color
        !P.COLOR = 0         ; darkest color
    endif

    IF (oneD) THEN BEGIN ; time series
        power2 = LONG(ALOG(DOUBLE(nx))/ALOG(2d))
        multi_res = dwt[0:n-1]
        smooth1 = data_in
        rough1 = FLTARR(n)
        !P.MULTI = [0,3,power2+1]
        ERASE
        !P.MULTI[0] = !P.MULTI[1]*!P.MULTI[2] - 1
        !X.OMARGIN = [4,3]
        !Y.OMARGIN = [0,0]
        extra = { $
            NOCLIP:1, $
            XMINOR:2, $
            XMARGIN:[1,1], $
            XTITLE:(*pState).xtitle, $
            YMINOR:1, $
            YMARGIN:[1,0], $
            YSTYLE:1, $
            YTICKS:2, $
            CHARSIZE:2}
        blanks = REPLICATE(' ',29)
        x = *(*pstate).pX
        yrange = ((mx-meann) > (meann-mn))*[-1.25,1.25]

        PLOT,x,data_in, $
            XSTYLE=9, $
            YRANGE=yrange, $
            XMARGIN=extra.xmargin,YMARGIN=extra.ymargin+[-2,2], $
            XTITLE=(*pState).xtitle,YTITLE=(*pState).ytitle, $
            XMINOR=extra.xminor,YMINOR=extra.yminor, $
            YTICKS=extra.yticks,CHARSIZE=2
        !P.MULTI[0] = !P.MULTI[0] - 4
        t_detail = 'Details (band pass)'
        t_smooth = 'Smooth (low pass)'
        t_rough = 'Rough (high pass)'

        WIDGET_CONTROL, /HOURGLASS

        nn = nx/2
        XYOUTS,0.03,0.5,'Scale',/NORMAL, $
            CHARSIZE=1.25,ALIGNMENT=0.5,ORIENTATION=90

        WHILE (nn GE 2) DO BEGIN ; compute multires

            dwt1 = DBLARR(nx)
            dwt1[nn:2*nn-1] = dwt[nn:2*nn-1]
            detail1 = WV_DWT(dwt1,scaling,wavelet,ioff,joff,/DOUBLE,/INVERSE)
            detail1 = detail1[0:n-1]
            multi_res = [[TEMPORARY(multi_res)],[detail1]]
            smooth1 = smooth1 - detail1
            rough1 = rough1 + detail1
            PLOT,x,smooth1, $
                TITLE=t_smooth, $
                XSTYLE=5, $
                YRANGE=yrange, $
                YTICKNAME=blanks, $
                _EXTRA=extra
            XYOUTS,!X.CRANGE[0],0,'!A'+STRTRIM(nx/nn,2)+'!B!N', $
                ALIGN=0.5, $
                CHARSIZE=1.25, $
                ORIENTATION=90
            PLOT,x,detail1, $
                TITLE=t_detail, $
                XSTYLE=5, $
                YRANGE=yrange, $
                YTICKNAME=blanks, $
                _EXTRA=extra
            PLOT,x,rough1, $
                TITLE=t_rough, $
                XSTYLE=5, $
                YRANGE=yrange, $
                YTICKNAME=blanks, $
                _EXTRA=extra
            t_detail = ''
            t_smooth = ''
            t_rough = ''
            nn = nn/2
        ENDWHILE
    ENDIF ELSE BEGIN ; 2D
        LOADCT, 0, /SILENT
        dwt1 = dwt
        xsize1 = (*pState).xsize1
        ysize1 = (*pState).ysize1
        offset = (*pState).offset
        pad = 0;(*pState).pad
        ni = FIX(ALOG(nx)/ALOG(2))
        nj = FIX(ALOG(ny)/ALOG(2))
        smooth_old = data
        nloop = ni < nj
        plots_per_page = nloop-1
        IF ((plots_per_page GE 8) AND printer) THEN plots_per_page=6
        !P.MULTI = [0,3,plots_per_page]
        !X.OMARGIN = [6,0]
        !Y.OMARGIN = [0,4]
        extra_plot = {CHARSIZE:2, $
            NODATA:1, $
            XSTYLE:5, $
            YSTYLE:5, $
            XMARGIN:[0,1], $
            YMARGIN:[1,0]}

; loop thru scales
        FOR i=1,nloop-1 DO BEGIN ; 2D scale loop
            indx = 2L^(ni-i)
            jndx = 2L^(nj-i)
            dwt1[indx:*,*] = 0
            dwt1[*,jndx:*] = 0
            smooth1 = WV_DWT(dwt1,scaling,wavelet,ioff,joff,/DOUBLE,/INVERSE)
            smooth1 = smooth1[0:siz[1]-1,0:siz[2]-1]
            rough1 = data - smooth1
            detail1 = smooth_old - smooth1
            smooth_old = smooth1
;           smooth1 = BYTSCL( $
;               CONGRID(TEMPORARY(smooth1),xsize1,ysize1), $
;               TOP=255-bottom)+bottom
;           detail1 = BYTSCL( $
;               CONGRID(TEMPORARY(detail1),xsize1,ysize1), $
;               TOP=255-bottom)+bottom
;           rough1 = BYTSCL( $
;               CONGRID(TEMPORARY(rough1),xsize1,ysize1), $
;               TOP=255-bottom)+bottom
            smooth1 = BYTSCL(TEMPORARY(smooth1))
            detail1 = BYTSCL(TEMPORARY(detail1))
            rough1 = BYTSCL(TEMPORARY(rough1))

            t_detail = ''
            t_smooth = ''
            t_rough = ''
            IF (!P.MULTI[0] EQ 0) THEN BEGIN
                t_smooth = 'Smooth!C(low pass)'
                t_detail = 'Details!C(band pass)'
                t_rough = 'Rough!C(high pass)'
            ENDIF

; Smooth image
            PLOT,[0,1],_EXTRA=extra_plot,TITLE=t_smooth
            position = CONVERT_COORD(0.5,0.5,/DATA,/TO_DEVICE)
            plot_size = CONVERT_COORD(1,1,/DATA,/TO_DEVICE) - $
                CONVERT_COORD(0,0,/DATA,/TO_DEVICE)
            IF (printer) THEN BEGIN
                position = position/[!D.X_PX_CM,!D.Y_PX_CM]
                plot_size = plot_size/[!D.X_PX_CM,!D.Y_PX_CM]
                plot_size = MIN(plot_size[0:1])
                extra = {CENTIMETERS:1,XSIZE:plot_size,YSIZE:plot_size}
            ENDIF ELSE BEGIN
                plot_size = MIN(plot_size[0:1])
                smooth1 = CONGRID(TEMPORARY(smooth1),plot_size,plot_size)
            ENDELSE
            position = position - plot_size/2
            TV,smooth1,position[0],position[1],ORDER=0,_EXTRA=extra

; Scale label
            XYOUTS,0,0.5,'!A'+STRTRIM(2L^i,2), $
                ALIGN=0.5, $
                CHARSIZE=1, $
                ORIENTATION=90

; Detail image
            PLOT,[0,1],_EXTRA=extra_plot,TITLE=t_detail
            position = CONVERT_COORD(0.5,0.5,/DATA,/TO_DEVICE)
            IF (printer) THEN BEGIN
                position = position/[!D.X_PX_CM,!D.Y_PX_CM]
            ENDIF ELSE BEGIN
                detail1 = CONGRID(TEMPORARY(detail1),plot_size,plot_size)
            ENDELSE
            position = position - plot_size/2
            TV,detail1,position[0],position[1],ORDER=0,_EXTRA=extra

; Rough image
            PLOT,[0,1],_EXTRA=extra_plot,TITLE=t_rough
            position = CONVERT_COORD(0.5,0.5,/DATA,/TO_DEVICE)
            IF (printer) THEN BEGIN
                position = position/[!D.X_PX_CM,!D.Y_PX_CM]
            ENDIF ELSE BEGIN
                rough1 = CONGRID(TEMPORARY(rough1),plot_size,plot_size)
            ENDELSE
            position = position - plot_size/2
            TV,rough1,position[0],position[1],ORDER=0,_EXTRA=extra

            IF (i EQ 1) THEN BEGIN
                WIDGET_CONTROL, /HOURGLASS
                XYOUTS,0,0.5, $
                    '!CScale', $
                    ALIGN=0.5, $
                    CHARSIZE=1, $
                    /NORMAL, $
                    ORIENTATION=90
            ENDIF
        ENDFOR ; 2D scale loop
    ENDELSE ; 2D

; restore all plot defaults
    !P.MULTI = 0
    !X.OMARGIN = xomargin
    !Y.OMARGIN = yomargin
    !P.BACKGROUND = pBackground
    !P.COLOR = pColor

END ; wv_plot_multires_wavelet_Event


;--------------------------------------------------------------------
FUNCTION wv_page_setup_landscape_event, Event

    COMPILE_OPT strictarr, hidden

    IF (Event.value EQ 0) THEN RETURN, Event  ; Encapsulated
    wForm = WIDGET_INFO(Event.top,/CHILD)
    WIDGET_CONTROL,wForm,GET_VALUE=setup
    new_size = {width:setup.height, $
        height:setup.width, $
        left_margin:setup.bottom_margin, $
        bottom_margin:setup.left_margin}
    WIDGET_CONTROL,wForm,SET_VALUE=new_size
    RETURN,Event
END


;--------------------------------------------------------------------
FUNCTION wv_page_setup_measure_event, Event

    COMPILE_OPT strictarr, hidden

    IF (Event.select EQ 0) THEN BEGIN
        WIDGET_CONTROL,Event.top,SET_UVALUE=Event.value
        RETURN,0
    ENDIF
    WIDGET_CONTROL,Event.top,GET_UVALUE=old_measure
    IF (old_measure EQ Event.value) THEN RETURN,0
    wForm = WIDGET_INFO(Event.top,/CHILD)
    WIDGET_CONTROL,wForm,GET_VALUE=setup
    factor = ([1./2.54,2.54])[Event.value]
    new_size = { $
        width:setup.width*factor, $
        height:setup.height*factor, $
        left_margin:setup.left_margin*factor, $
        bottom_margin:setup.bottom_margin*factor}
    WIDGET_CONTROL,wForm,SET_VALUE=new_size
    RETURN,Event
END


;--------------------------------------------------------------------
FUNCTION wv_page_setup, setup

    COMPILE_OPT strictarr, hidden

    IF (N_ELEMENTS(setup) LT 1) THEN BEGIN
        setup = {measure:0, $
            encapsulated:0, $
            landscape:0, $
            width:6.5, $
            left_margin:1.0, $
            height:9.0, $
            bottom_margin:1.0, $
            ok:0, $
            cancel:0}
        RETURN,setup
    ENDIF
    desc = [ $
        '0,BUTTON,Regular|Encapsulated,EXCLUSIVE' + $
            ',TAG=encapsulated,ROW,LABEL_LEFT=Postscript:' + $
            ',SET_VALUE='+STRING(setup.encapsulated), $
        '0,BUTTON,Portrait|Landscape,EXCLUSIVE' + $
            ',TAG=landscape,ROW,LABEL_LEFT=Orientation:' + $
            ',SET_VALUE='+STRING(setup.landscape)+ $
            ',EVENT=wv_page_setup_landscape_event', $
        '1,BASE,,ROW', $
            '1,BASE,,ROW', $
                '2,LABEL, ,', $
            '1,BASE,,ROW', $
                '2,LABEL, ,', $
            '1,BASE,,ROW', $
                '2,LABEL, ,', $
            '1,BASE,,COLUMN', $
                '0,LABEL,Dimensions,LEFT', $
                '1,BASE,,COLUMN,FRAME', $
                    '3,BASE,,COLUMN', $
                        '0,LABEL,Width,LEFT', $
                        '0,FLOAT,'+STRING(setup.width)+',TAG=width', $
                        '0,LABEL, ,', $
                        '0,LABEL,Height,LEFT', $
                        '2,FLOAT,'+STRING(setup.height)+',TAG=height', $
                '0,LABEL, ,', $
                '2,BUTTON,OK,QUIT,TAG=ok', $
            '1,BASE,,ROW', $
                '2,LABEL, ,', $
            '1,BASE,,COLUMN', $
                '0,LABEL,Margins,LEFT', $
                '1,BASE,,COLUMN,FRAME', $
                    '3,BASE,,COLUMN', $
                        '0,LABEL,Left,LEFT', $
                        '0,FLOAT,'+STRING(setup.left_margin) + $
                            ',TAG=left_margin', $
                        '0,LABEL, ,', $
                        '0,LABEL,Bottom,LEFT', $
                        '2,FLOAT,'+STRING(setup.bottom_margin) + $
                            ',TAG=bottom_margin', $
                '0,LABEL, ,', $
                '2,BUTTON,Cancel,QUIT,TAG=cancel', $
            '1,BASE,,COLUMN', $
                '0,LABEL, ,', $
                '2,BUTTON,inch|cm' + $
                    ',EXCLUSIVE,SET_VALUE='+STRING(setup.measure) + $
                    ',LABEL_TOP= ,TAG=measure' + $
                    ',EVENT=wv_page_setup_measure_event' $
            ]
    setup_new = CW_FORM(desc, $
        /COLUMN, $
        TITLE='Page Setup')
    IF (setup_new.ok NE 1) THEN RETURN,setup
    RETURN,setup_new
END


;--------------------------------------------------------------------
PRO wv_plot_multires_Event, Event

    COMPILE_OPT strictarr, hidden

; error handling
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        MESSAGE,/INFO,!ERROR_STATE.MSG
        RETURN
    ENDIF

    WIDGET_CONTROL, Event.handler, GET_UVALUE=pState

    CASE (TAG_NAMES(Event,/STRUCTURE_NAME)) OF
        'WIDGET_KILL_REQUEST': BEGIN
            Event = {id:(*pState).wPDmenu, top:Event.top, $
                handler:Event.handler, value:(*pState).wMenuID.Close}
            END
        'WIDGET_BASE': BEGIN
            WIDGET_CONTROL, Event.handler, TLB_GET_SIZE=new_size
            dx = new_size[0] - (*pState).tlb_size[0]
            dy = new_size[1] - (*pState).tlb_size[1]
            geom = WIDGET_INFO((*pState).wDraw,/GEOMETRY)
            xsize1 = (geom.xsize + dx) > (*pState).min_size[0]
            ysize1 = (geom.ysize + dy) > (*pState).min_size[1]
            WIDGET_CONTROL,Event.handler,UPDATE=0
            WIDGET_CONTROL,(*pState).wDraw,XSIZE=xsize1,YSIZE=ysize1
            WIDGET_CONTROL,Event.handler,/UPDATE
            WIDGET_CONTROL,Event.handler,TLB_GET_SIZE=new_size
            (*pState).tlb_size = new_size
            RETURN
            END
        ELSE:
    ENDCASE

    CASE Event.id OF
        (*pState).wWavelet: BEGIN
            WV_PLOT_MULTIRES_WAVELET_EVENT, Event
            RETURN
            END
        ELSE:
    ENDCASE

    IF (Event.id NE (*pState).wPDmenu) THEN RETURN

; add wavelet function to Event structure
    WIDGET_CONTROL, (*pState).wWavelet, GET_VALUE=wavelet_fn
    Event = CREATE_STRUCT(Event, wavelet_fn)

; Events for menu items
    menuID = (*pState).wMenuID
    CASE (Event.value) OF
    menuID.ExportPostscript: BEGIN
        setup = *(*pState).pSetup
        suffix = (['.ps','.eps'])[setup.encapsulated]
pick_again:
        filename = DIALOG_PICKFILE(/WRITE, $
            GROUP=Event.top, $
            FILTER='*'+suffix, $
            GET_PATH=file_path, $
            PATH=(*pState).file_path, $
            TITLE='Export Postscript')
        IF (filename EQ '') THEN RETURN
        IF ((FILE_SEARCH(filename))[0] NE '') THEN BEGIN
            result = DIALOG_MESSAGE([filename, $
                'This file already exists. Replace existing file?'], $
                DIALOG_PARENT=Event.top, $
                /QUESTION,TITLE='Save Postscript As')
            IF (result EQ 'No') THEN GOTO,pick_again
        ENDIF
        WIDGET_CONTROL, /HOURGLASS
        suffix_pos = STRPOS(filename,suffix)
        correct_suffix = suffix_pos EQ (STRLEN(filename)-STRLEN(suffix))
        IF ((NOT correct_suffix) AND $
            (!VERSION.OS_FAMILY EQ 'Windows')) THEN $
            filename = filename + suffix
        old_device = !D.NAME
        SET_PLOT,'ps'
        landscape = setup.landscape
        IF (setup.encapsulated) THEN landscape = 0
        xoffset = setup.left_margin
        yoffset = setup.bottom_margin
        IF (landscape) THEN BEGIN ; switch X & Y margins
            ymax = 11 ; inches
            IF (setup.measure) THEN ymax = ymax*2.54 ; cm/inch
            xoffset = setup.bottom_margin
            yoffset = ymax - setup.left_margin
        ENDIF
        DEVICE,FILE=filename, $
            ENCAPSULATED=setup.encapsulated, $
            LANDSCAPE=landscape, $
            INCHES=(setup.measure NE 1), $
            XSIZE=setup.width, $
            XOFFSET=xoffset, $
            YSIZE=setup.height, $
            YOFFSET=yoffset
        WV_PLOT_MULTIRES_WAVELET_EVENT, Event, /PRINTER
        DEVICE,/CLOSE
        SET_PLOT,old_device
        (*pState).file_path = file_path
        END
    menuID.PageSetup: BEGIN
        setup = WV_PAGE_SETUP(*(*pState).pSetup)
        IF (setup.ok) THEN *(*pState).pSetup = setup
        END
    menuID.PrinterSetup: BEGIN
        result = DIALOG_PRINTERSETUP(DIALOG_PARENT=Event.top, $
            TITLE='Print')
        END
    menuID.Print: BEGIN
        old_device = !D.NAME
        SET_PLOT,'printer'
        setup = *(*pState).pSetup
        landscape = setup.landscape
        xoffset = setup.left_margin
        yoffset = setup.bottom_margin
        IF (landscape) THEN BEGIN ; switch X & Y margins
            ymax = 11 ; inches
            IF (setup.measure) THEN ymax = ymax*2.54 ; cm/inch
            xoffset = setup.bottom_margin
            yoffset = ymax - setup.left_margin
        ENDIF
        DEVICE,LANDSCAPE=landscape, $
            INCHES=(setup.measure NE 1), $
            XSIZE=setup.width, $
            XOFFSET=xoffset, $
            YSIZE=setup.height, $
            YOFFSET=yoffset
        WV_PLOT_MULTIRES_WAVELET_EVENT, Event, /PRINTER
        DEVICE,/CLOSE_DOCUMENT
        SET_PLOT,old_device
        END
    menuID.Close: BEGIN ; quit
        WIDGET_CONTROL, Event.top, /DESTROY
        RETURN
        END
    ENDCASE
    RETURN
END  ; wv_plot_multires_Event


;--------------------------------------------------------------------
PRO wv_plot_multires_cleanup, id_base

    COMPILE_OPT strictarr, hidden

; error handling
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        MESSAGE,/INFO,!ERROR_STATE.MSG
        RETURN
    ENDIF

    WIDGET_CONTROL, id_base, GET_UVALUE=pState

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
END   ; of Cleanup


;----------------------------------------------------------------
FUNCTION wv_plot_multires, $
    array, $ ; vector or array
    x, $     ; x coordinates of *pData
    y, $     ; y coordinates of *pData
    XTITLE=xtitle,YTITLE=ytitle, $
    XUNITS=xunits,YUNITS=yunits, $
    UNITS=units, $
    TITLE=title, $
    COLORTABLE=colortable, $
    XOFFSET=xoffset, YOFFSET=yoffset, $
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

    siz = SIZE(array)
    oneD = siz[0] EQ 1
    nx = siz[1]
    IF (oneD) THEN ny=1 ELSE ny=siz[2]
    IF (N_ELEMENTS(x) LT 1) THEN x = LINDGEN(nx)
    IF (N_ELEMENTS(y) LT 1) THEN y = LINDGEN(ny)
    IF (N_ELEMENTS(xtitle) LE 0) THEN xtitle = 'X'
    IF (N_ELEMENTS(ytitle) LE 0) THEN ytitle = 'Y'
    IF (N_ELEMENTS(xunits) LE 0) THEN xunits = ''
    IF (N_ELEMENTS(yunits) LE 0) THEN yunits = ''
    IF (N_ELEMENTS(units) LE 0) THEN units = ''
    IF (N_ELEMENTS(plot_type) LE 0) THEN plot_type = 7
    IF (N_ELEMENTS(title) LE 0) THEN title=''
    IF (N_ELEMENTS(colortable) LE 0) THEN colortable = BINDGEN(256,3)

; Set up the drawing area size
    DEVICE, GET_SCREEN_SIZE=screen_size
    xsize = 0.5*screen_size[0]
    ysize = 0.75*screen_size[1]
    IF (N_ELEMENTS(xoffset) LT 1) THEN xoffset = 0.25*screen_size[0]
    IF (N_ELEMENTS(yoffset) LT 1) THEN yoffset = 20

    wBase = WIDGET_BASE( $
        /COLUMN, $
        MBAR=wMenubar, $
        TITLE='MRes: '+title, $
        XOFFSET=xoffset,YOFFSET=yoffset, $
        /TLB_KILL_REQUEST_EVENTS, $
        /TLB_SIZE_EVENTS, $
        _EXTRA=_extra)

    wRow = WIDGET_BASE(wBase,/ROW)
    wCol = WIDGET_BASE(wRow,/COLUMN,/BASE_ALIGN_CENTER)

; find next higher power-of-two for array size
    dim = 2L^(LONG(ALOG([nx,ny])/ALOG(2)+0.99999))
    nx = dim[0]
    ny = dim[1]
    ni = FIX(ALOG(nx)/ALOG(2))
    nj = FIX(ALOG(ny)/ALOG(2))

    IF (oneD) THEN BEGIN
        xsize1 = 0
        ysize1 = 0
        pad = 0
        offset = 0
        dy = ysize/9.
        y_scroll_size = ysize
        ysize = ysize + dy*((ni-8) > 0)
        wDraw = WIDGET_DRAW(wCol, $
            RETAIN=2, $
            /SCROLL, $
            XSIZE=xsize, $
            X_SCROLL_SIZE=xsize+20, $
            YSIZE=ysize, $
            Y_SCROLL_SIZE=y_scroll_size)
    ENDIF ELSE BEGIN
        xsize1 = 128L
        ysize1 = LONG(xsize1*(FLOAT(ny)/nx)) < 128L
;       ysize1 = ny < xsize1
        pad = 5
        offset = 40
        draw_xsize = (xsize1+pad)*3 + pad + offset
        draw_ysize = (ysize1+pad)*((ni<nj) - 1) + pad + offset
        wDraw = WIDGET_DRAW(wCol, $
            RETAIN=2, $
            /SCROLL, $
            XSIZE=draw_xsize,YSIZE=draw_ysize, $
            X_SCROLL_SIZE=(draw_xsize+20)<xsize, $
            Y_SCROLL_SIZE=(draw_ysize+20)<ysize)
    ENDELSE

; menu items
    menu_list = [ $
        '1\File', $
            '0\Page Setup', $
            '0\Export Postscript', $
            '0\Printer Setup', $
            '0\Print', $
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

    wBase_options = WIDGET_BASE(wRow,/COLUMN)

; Wavelet options base
    dummy = WIDGET_LABEL(wBase_options,VALUE='Wavelet options',/ALIGN_LEFT)
    wWavelet = WV_CW_WAVELET(wBase_options,/FRAME,/DISCRETE)

    pState = PTR_NEW({ $
        wBase:wBase, $
        wCol:wCol, $
        wDraw:wDraw, $
        wWavelet:wWavelet, $
        wPDmenu:wPDmenu, $
        wMenuID:wMenuID, $
        file_path:'', $
        tlb_size:[0L,0L], $
        min_size:[128L,128L], $
        xsize1:xsize1, $
        ysize1:ysize1, $
        offset:offset, $
        pad:pad, $
        pSetup:PTR_NEW(WV_PAGE_SETUP()), $
        pX: PTR_NEW(x), $
        pY: PTR_NEW(y), $
        pData: PTR_NEW(array), $
        pColortable: PTR_NEW(colortable), $
        xtitle:xtitle, $
        xunits:xunits, $
        ytitle:ytitle, $
        yunits:yunits, $
        title:title, $
        units:units $
        })

; Register with the XMANAGER, FOR subsequent user Events.
    WIDGET_CONTROL,wBase,SET_UVALUE=pState,/REALIZE, $
        TLB_GET_SIZE=tlb_size
    (*pState).tlb_size = tlb_size

    XMANAGER, 'wv_plot_multires', wBase, $
        /NO_BLOCK, $
        CLEANUP='wv_plot_multires_cleanup'

;IF (LMGR(/DEMO)) THEN $
;   WIDGET_CONTROL, wVRMLButton, SENSITIVE=0

    RETURN, wBase
END
