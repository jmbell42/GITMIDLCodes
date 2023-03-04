;----------------------------------------------------------------
; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/wavelet/source/wv_cw_datatable.pro#1 $
;
; Copyright (c) 1999-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.

;----------------------------------------------------------------
PRO sWV_data__define, data, WIDTHS=widths, EDITABLE=editable

    COMPILE_OPT strictarr, hidden

; Template for sWv_data structure
    tmp = {sWV_datatable, $
        type:'', $
        title:'', $         ; long name of data variable
        variable:'', $      ; short name of data variable
        units:'', $         ; units for variable
        xname:'', $         ; name of X coordinate
        xunits:'', $        ; units for X coord
        xstart:'0', $       ; starting value for X coord
        dx:'1.0', $         ; sampling rate for X coord
        yname:'', $         ; name of Y coordinate
        yunits:'', $        ; units for Y coord
        ystart:'0', $       ; starting value for Y coord
        dy:'1.0', $         ; sampling rate for Y coord
        xoffset:0L, $       ; starting index of X coord to use
        xcount:0L, $        ; number of X coords to use
        xstride:0L, $       ; X sampling interval to use
        yoffset:0L, $       ; starting index of Y coord to use
        ycount:0L, $        ; number of Y coords to use
        ystride:0L, $       ; Y sampling interval to use
        source:'', $        ; filename or contact info
        notes:'' $          ; miscellaneous notes
        }
    tmp = {sWV_data, $
        INHERITS sWV_datatable, $
        xdata:PTR_NEW(), $  ; pointer to X coordinates (irregular grid)
        ydata:PTR_NEW(), $  ; pointer to Y coordinates (irregular grid)
        data:PTR_NEW(), $   ; pointer to data array
        colors:PTR_NEW(), $ ; pointer to color table for data
        view:0L, $          ; widget ID of data viewer
        modified:'' $       ; last modification time
        }

    editable = BYTARR(N_TAGS(tmp)) + 1b
    editable[[1,2,19]] = 0b

    IF (N_ELEMENTS(data) GT 0) THEN BEGIN
        s = SIZE(data)
        ptr_data = PTR_NEW(TEMPORARY(data))
        data = TEMPORARY(tmp)
        data.data = ptr_data
        data.modified = SYSTIME()
    ENDIF
END


;----------------------------------------------------------------
; Internal function to convert a string into a valid double,
;
function sWV_data_convertstr, strIn

    compile_opt idl2, hidden

    str = STRTRIM(strIn, 2)

    ; If we contain any math operators, use execute,
    ; otherwise just convert to double.
    if (STRMATCH(STRMID(str,1), '*[+\-*/^]*')) then $
        dummy = EXECUTE('result = DOUBLE(' + str + ')') $
    else $
        result = DOUBLE(str)

    return, result

end


;----------------------------------------------------------------
PRO sWv_data_access,data,X,Y, $
    DATA_OUT=data_out, $
    DX=dx,NX=nx,XSTART=xstart, $
    DY=dy,NY=ny,YSTART=ystart, $
    XTITLE=xtitle,YTITLE=ytitle, $
    XUNITS=xunits,YUNITS=yunits, $
    UNITS=units,TITLE=title

    COMPILE_OPT strictarr, hidden

    ON_ERROR, 2

    IF (N_TAGS(data) LT 1) THEN RETURN
    s = SIZE(*data.data)

; X coordinate
    nx = s[1]
    IF PTR_VALID(data.xdata) THEN BEGIN ; irregular grid

        x = *data.xdata
        xstart = x[0]
        nx = N_ELEMENTS(x)
        dx = TOTAL(x[1:nx-1]-x[0:nx-2])/(nx-1) ; average dx

    ENDIF ELSE BEGIN ; regular grid

        dx = sWV_data_convertstr(data.dx)
        if (dx eq 0) then $
            dx = 1
        xstart = sWV_data_convertstr(data.xstart)
        x = dx*DINDGEN(nx) + xstart

    ENDELSE

    data_out = *data.data

; check for count, offset, & stride
    data.xstride = data.xstride > 1
    IF (data.xcount EQ 0) THEN data.xcount = nx
;   data.xcount = data.xcount < ((nx-data.xoffset)/data.xstride)
    nx = data.xcount < ((nx-data.xoffset)/data.xstride)
    x_index = LINDGEN(nx)*data.xstride + data.xoffset
    x = x[x_index]
    data_out = data_out[x_index,*]

; construct title & unit strings
    xunits = data.xunits
    xtitle = data.xname
    IF (STRTRIM(xunits,2) NE '') THEN xtitle = xtitle + $
        ' (' + xunits + ')'
    yunits = data.units
    ytitle = data.variable
    IF (STRTRIM(yunits,2) NE '') THEN ytitle = ytitle + $
        ' (' + yunits + ')'
    units = data.units
    title = data.title
;   IF (STRTRIM(units,2) NE '') THEN title = title + $
;       ' (' + units + ')'

    ny = s[2]*(s[0] GE 2)
    IF (ny EQ 0) THEN RETURN ; if 1D vector rather than 2D array

;*** Two dimensional datasets

    yunits = data.yunits
    ytitle = data.yname
    IF (STRTRIM(yunits,2) NE '') THEN ytitle = ytitle + $
        ' (' + yunits + ')'

; Y coordinate
    IF PTR_VALID(data.ydata) THEN BEGIN ; irregular grid

        y = *data.ydata
        ystart = y[0]
        ny = N_ELEMENTS(y)
        dy = TOTAL(y[1:ny-1]-y[0:ny-2])/(ny-1) ; average dy

    ENDIF ELSE BEGIN ; regular grid

        dy = sWV_data_convertstr(data.dy)
        ystart = sWV_data_convertstr(data.ystart)
        if (dy eq 0) then $
            dy = 1
        y = dy*DINDGEN(ny) + ystart

    ENDELSE

; check for count, offset, & stride
    data.ystride = data.ystride > 1
    IF (data.ycount EQ 0) THEN data.ycount = ny
;   data.ycount = data.ycount < ((ny-data.yoffset)/data.ystride)
    ny = data.ycount < ((ny-data.yoffset)/data.ystride)
    y_index = LINDGEN(ny)*data.ystride + data.yoffset
    y = y[y_index]
    data_out = data_out[*,y_index]

    RETURN
END


;----------------------------------------------------------------
;  NAME:
;    WV_VAR_FORMAT
;
;  PURPOSE:
;    This function returns a "nice" string Format code
;    appropriate to the magnitude and type of an input number.
;
;  CALLING SEQUENCE:
;    Result = WV_VAR_FORMAT(X)
;
; INPUTS:
;    X: A scalar number
;
; KEYWORD PARAMETERS:
;    None
;
; OUTPUTS:
;    Result: A "nice" format code for X that can be
;            used with a PRINT statement.
;
; MODIFICATION HISTORY:
;    Written by: Chris Torrence, 1999
;
FUNCTION wv_var_format,x
    COMPILE_OPT strictarr, hidden
    CASE (1) OF
        (x GE 10000): code = 'G12.5'
        (x GE 1000): code = 'G11.4'
        ELSE: code = 'G10.3'
    ENDCASE
    cmplx = '"(",'+code+',",",'+code+',")"'
    formats = ['A','I3','I7','I12',code,code, $
            cmplx,'A','A',cmplx,'A','A', $
            'I7','I12','I22','I22']
    type = SIZE(x)
    type = type[type[0]+1]
    RETURN,formats[type]
END


;----------------------------------------------------------------
;  NAME:
;    WV_HELP_VAR_TYPE
;
;  PURPOSE:
;    This function returns a string of type and array size.
;
;  CALLING SEQUENCE:
;    Result = WV_HELP_VAR_TYPE(siz)
;
; INPUTS:
;    siz: A vector equal to the output of the SIZE function
;
; KEYWORD PARAMETERS:
;    None
;
; OUTPUTS:
;    Result: a string equal to the type name and the array size.
;
; EXAMPLE:
;    IDL> siz = SIZE(FINDGEN(10,20))
;    IDL> Result = WV_HELP_VAR_TYPE(siz)
;    IDL> PRINT, Result
;      FLOAT[10,20]
;
; MODIFICATION HISTORY:
;    Written by: Chris Torrence, 1999
;
FUNCTION wv_help_var_type,variable
    COMPILE_OPT strictarr, hidden

    tname = SIZE(variable,/TNAME)
    nDim = SIZE(variable,/N_DIMENSION)
    dims = SIZE(variable,/DIMENSIONS)
    CASE nDim OF
    0: name = tname
    ELSE: name = tname + '[' + STRING(dims,FORMAT='(255(I0,:,","))') + ']'
    ENDCASE
    RETURN,name
END


;----------------------------------------------------------------
PRO wv_dataset_free, datasets
    COMPILE_OPT strictarr, hidden
    IF (N_TAGS(datasets) NE 0) THEN BEGIN
        FOR d=0,N_ELEMENTS(datasets)-1 DO BEGIN
            dataset1 = datasets[d]
            PTR_FREE,dataset1.xdata, $
                dataset1.ydata, $
                dataset1.data, $
                dataset1.colors
        ENDFOR
    ENDIF
    RETURN
END ; wv_dataset_free


;----------------------------------------------------------------
PRO wv_datatable_set, wDatatable, datasets, $
    MODIFIED=modified, $
    TITLE=title, $
    COLUMN_MAJOR=column_major

    COMPILE_OPT strictarr, hidden

    n = N_ELEMENTS(datasets)
    modified = KEYWORD_SET(modified)

; construct row labels from variable names
    row_labels = ['(no data)'] ; this is only if no datasets
    IF (N_TAGS(datasets[0]) GT 0) THEN BEGIN
        row_labels = [STRTRIM(LINDGEN(n)+1,2) + '. ' + $
            STRMID(datasets.variable,0,10)]
        FOR i=0,n-1 DO BEGIN
            datasets[i].type = WV_HELP_VAR_TYPE(*datasets[i].data)
        ENDFOR
    ENDIF

    if (N_TAGS(datasets[0]) gt 0) then begin
        datasetvalue = REPLICATE({sWV_datatable}, n)
        STRUCT_ASSIGN, datasets, datasetvalue
    endif else $
        datasetvalue = datasets

; set the Table value and row labels
    CASE KEYWORD_SET(column_major) OF
    0: BEGIN
        WIDGET_CONTROL,wDatatable, $
            SET_VALUE=datasetvalue, $
            ROW_LABELS=row_labels, $
            TABLE_YSIZE=(n>1)
        END
    1: BEGIN
        widths = WIDGET_INFO(wDatatable, /COLUMN_WIDTHS)
        nw = N_ELEMENTS(widths)
        if (n gt nw) then $
            widths = [widths, REPLICATE(widths[0], n - nw)]
        WIDGET_CONTROL,wDatatable, $
            SET_VALUE=datasetvalue, $
            COLUMN_LABELS=row_labels, $
            TABLE_XSIZE= (n>1), $
            COLUMN_WIDTHS=widths
        END
    ENDCASE

    WIDGET_CONTROL,wDatatable, $
        GET_UVALUE=uvalue, /NO_COPY

    uvalue = { $
        MODIFIED: KEYWORD_SET(modified), $
        TLB_TITLE: uvalue.tlb_title, $
        DATASETS:datasets}

    uvalue.modified = KEYWORD_SET(modified)

;   new title?
    if (N_ELEMENTS(title) gt 0) then $
        uvalue.tlb_title = title

    title = uvalue.tlb_title
    IF uvalue.modified THEN title = title + ' (modified)'

    WIDGET_CONTROL,wDatatable, $
        SET_UVALUE=uvalue, /NO_COPY, $
        TLB_SET_TITLE=title

    RETURN
END ; wv_datatable_set

;----------------------------------------------------------------
PRO wv_data_moveup, Event

    COMPILE_OPT strictarr, hidden
; Catch errors
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        WV_ERROR_HANDLER,Event.top
        RETURN
    ENDIF

    WIDGET_CONTROL,/HOURGLASS
    child = WIDGET_INFO(Event.top,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=wv

    WIDGET_CONTROL,(*wv).id.datatable, GET_UVALUE=uvalue
    datasets = uvalue.datasets
    IF (N_TAGS(datasets) EQ 0) THEN RETURN  ; no datasets
    n = N_ELEMENTS(datasets)

; find selected dataset
    selected = WIDGET_INFO((*wv).id.datatable,/TABLE_SELECT)
    col_major = (*wv).info.column_major
    select_top = selected[1-col_major]    ; top of currently selected cells
    IF (select_top EQ 0) THEN RETURN  ; dataset is already at the top

    ; Verify that the selection is less than # of datasets.
    if (select_top eq -1) or (select_top ge n) then begin
        WV_MESSAGE,Event.top,'*** Please select a dataset ***'
        RETURN
    ENDIF

; move it up
    datasets[[select_top-1,select_top]] = datasets[[select_top,select_top-1]]
    table_view = WIDGET_INFO((*wv).id.datatable,/TABLE_VIEW)
    WV_DATATABLE_SET, (*wv).id.datatable, datasets, /MODIFIED, $
        COLUMN_MAJOR=(*wv).info.column_major
    set_table_select = [selected[0],select_top-1,selected[2],select_top-1]
    IF col_major THEN BEGIN
        set_table_select = $
            [select_top-1,selected[1],select_top-1,selected[3]]
    ENDIF
    WIDGET_CONTROL,(*wv).id.datatable, $
        SET_TABLE_SELECT=set_table_select

    RETURN
END ; wv_data_moveup


;----------------------------------------------------------------
PRO wv_data_movedown, Event

    COMPILE_OPT strictarr, hidden
; Catch errors
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        WV_ERROR_HANDLER,Event.top
        RETURN
    ENDIF

    WIDGET_CONTROL,/HOURGLASS
    child = WIDGET_INFO(Event.top,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=wv

    WIDGET_CONTROL,(*wv).id.datatable,GET_UVALUE=uvalue
    datasets = uvalue.datasets
    IF (N_TAGS(datasets) EQ 0) THEN RETURN  ; no datasets
    n = N_ELEMENTS(datasets)

; find selected dataset
    selected = WIDGET_INFO((*wv).id.datatable,/TABLE_SELECT)
    col_major = (*wv).info.column_major
    select_bottom = selected[3-col_major]  ; bottom of currently selected cells

    ; Verify that the selection is less than # of datasets.
    if (select_bottom eq -1) or (select_bottom ge n) then begin
        WV_MESSAGE,Event.top,'*** Please select a dataset ***'
        RETURN
    ENDIF

; move it down
    IF (select_bottom EQ n-1) THEN RETURN  ; dataset is already at the bottom
    datasets[[select_bottom,select_bottom+1]] = $
        datasets[[select_bottom+1,select_bottom]]
    table_view = WIDGET_INFO((*wv).id.datatable,/TABLE_VIEW)
    WV_DATATABLE_SET, (*wv).id.datatable, datasets, /MODIFIED, $
        COLUMN_MAJOR=(*wv).info.column_major
    set_table_select = [selected[0],select_bottom+1, $
        selected[2],select_bottom+1]
    IF col_major THEN BEGIN
        set_table_select = $
            [select_bottom+1,selected[1],select_bottom+1,selected[3]]
    ENDIF
    WIDGET_CONTROL,(*wv).id.datatable, $
        SET_TABLE_SELECT=set_table_select

    RETURN
END ; wv_data_movedown


;----------------------------------------------------------------
FUNCTION wv_view_table, wBase, data, $
    TITLE=title

    COMPILE_OPT strictarr, hidden

    IF (N_ELEMENTS(title) LT 1) THEN title=''

    SWV_DATA_ACCESS,data,xdata,ydata, $
        DATA_OUT=value, $
        NX=nx,NY=ny

    xcutoff = 1000
    ycutoff = 1000
    IF ((nx GT xcutoff) OR (ny GT ycutoff)) THEN title=title+' [truncated]'
    WIDGET_CONTROL, wBase, TLB_SET_TITLE=title
    nx = nx < xcutoff
    ny = ny < ycutoff
    xdata = xdata[0:nx-1]
    value = value[0:nx-1,*]

; either row labels (1D) or column labels (2D)
    labels = [STRTRIM(STRING(xdata,FORMAT='(G12.6)'),2)]

    oneD = (ny LE 1)
    IF (oneD) THEN BEGIN
        x_scroll_size = 1L
        y_scroll_size = nx < 20
        row_labels = TEMPORARY(labels)
        column_labels = [data.variable]
        value = TRANSPOSE(TEMPORARY(value))
    ENDIF ELSE BEGIN
        value = value[*,0:ny-1]
        x_scroll_size = nx < 7
        y_scroll_size = ny < 20
        column_labels = TEMPORARY(labels)
        ydata = ydata[0:ny-1]
        row_labels = [STRTRIM(STRING(ydata,FORMAT='(G12.6)'),2)]
    ENDELSE

    format = WV_VAR_FORMAT(MAX(ABS(value)))
    format = '(' + format + (['',',TR1'])[oneD] + ')'
    width1 = ([2,4])[oneD] + $
        STRLEN(STRTRIM(STRING(MIN(value),FORMAT=format),1))
    width2 = MAX(STRLEN(column_labels))
    width = (width1 > width2)*!D.X_CH_SIZE

    id_table = WIDGET_BASE(wBase,/ALIGN_CENTER,/BASE_ALIGN_CENTER)
    id_table1 = WIDGET_TABLE(id_table, $
        /RESIZEABLE_COLUMNS, $
        VALUE=value, $
        FORMAT=format, $
        /SCROLL, $
        X_SCROLL_SIZE=x_scroll_size, $
        Y_SCROLL_SIZE=y_scroll_size, $
        ALIGNMENT=2, $
        COLUMN_WIDTH=width, $
        COLUMN_LABELS=column_labels, $
        ROW_LABELS=row_labels)
    WIDGET_CONTROL,id_table,SET_UVALUE=id_table1
    RETURN,id_table
END ; wv_view_table


;----------------------------------------------------------------
PRO wv_data_view_event, Event

    COMPILE_OPT strictarr, hidden
; Catch errors
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        WV_ERROR_HANDLER,Event.top
        RETURN
    ENDIF

    WIDGET_CONTROL,Event.top,GET_UVALUE=id
    CASE (Event.id) OF
        id.okay: WIDGET_CONTROL,Event.top,/DESTROY
        ELSE:
    ENDCASE
    RETURN
END ; wv_data_view_event


;----------------------------------------------------------------
PRO wv_data_view, Event,id_view_base

    COMPILE_OPT strictarr, hidden
; Catch errors
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        WV_ERROR_HANDLER,Event.top
        RETURN
    ENDIF

    WIDGET_CONTROL,/HOURGLASS
    child = WIDGET_INFO(Event.top,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=wv

    WIDGET_CONTROL,(*wv).id.datatable,GET_UVALUE=uvalue
    datasets = uvalue.datasets
    IF (N_TAGS(datasets) EQ 0) THEN RETURN  ; no datasets
    n = N_ELEMENTS(datasets)

    selected = WIDGET_INFO((*wv).id.datatable,/TABLE_SELECT)
    col_major = (*wv).info.column_major
    selected = selected[1-col_major]  ; top of currently selected cells

    ; Verify that the selection is less than # of datasets.
    if (selected eq -1) or (selected ge n) then begin
        WV_MESSAGE,Event.top,'*** Please select a dataset ***'
        RETURN
    ENDIF

    data = datasets[selected]

    old_id = data.view
    IF (WIDGET_INFO(old_id,/VALID)) THEN BEGIN
        WIDGET_CONTROL,old_id,/SHOW,ICONIFY=0
        RETURN
    ENDIF

    id_view_base = WIDGET_BASE(GROUP_LEADER=Event.top, $
        /COLUMN, $
        SPACE=5,XPAD=5,YPAD=5,TLB_FRAME_ATTR=1)
    id_view_table = WV_VIEW_TABLE(id_view_base,data, $
        TITLE=data.variable)
    but_base = WIDGET_BASE(id_view_base, $
        /ALIGN_CENTER,/ROW)
    id_okay   = WIDGET_BUTTON(but_base,VALUE=' Close ')

    id = {top:Event.top, $
        view_base:id_view_base, $
        dataset_base:id_view_table, $
        okay:id_okay}

    WIDGET_CONTROL,id_view_base,/REALIZE,SET_UVALUE=id
    datasets[selected].view = id_view_base  ; save the Widget id
    uvalue.datasets = datasets
    WIDGET_CONTROL,(*wv).id.datatable,SET_UVALUE=uvalue, /NO_COPY

    XMANAGER,'wv_data_view',id_view_base,NO_BLOCK=1, $
        GROUP_LEADER=Event.top

END ; wv_data_view


;----------------------------------------------------------------
PRO wv_data_delete, Event

    COMPILE_OPT strictarr, hidden
; Catch errors
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        WV_ERROR_HANDLER,Event.top
        RETURN
    ENDIF

; find selected dataset(s)
    child = WIDGET_INFO(Event.top,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=wv
    selected = WIDGET_INFO((*wv).id.datatable,/TABLE_SELECT)
    col_major = (*wv).info.column_major
    top = selected[1-col_major]    ; top of selected cells
    bottom = selected[3-col_major] ; bottom of selected cells

    ; Verify that the selection is less than # of datasets.
    WIDGET_CONTROL,(*wv).id.datatable,GET_UVALUE=uvalue
    datasets = uvalue.datasets
    IF (N_TAGS(datasets) EQ 0) THEN RETURN  ; no datasets
    n = N_ELEMENTS(datasets)

    if (top eq -1) or (bottom ge n) then begin
        WV_MESSAGE,Event.top,'*** Please select a dataset ***'
        RETURN
    ENDIF

; dialog to confirm delete
    delete_str = 'Delete dataset'
    deletes = ' ' + datasets[top].variable
    IF (top NE bottom) THEN BEGIN
        delete_str = 'Delete datasets'
        FOR i=top+1,bottom DO deletes = deletes + ', ' + datasets[i].variable
    ENDIF
    result = DIALOG_MESSAGE(' ' + delete_str + deletes + '? ', $
        DIALOG_PARENT=Event.top,/CANCEL,TITLE=delete_str)
    IF (result NE 'OK') THEN BEGIN ; cancelled
        WV_MESSAGE,Event.top,delete_str + ' cancelled'
        RETURN
    ENDIF

; now delete the actual datasets
    WV_DATASET_FREE, datasets[top:bottom]
    IF ((top EQ 0) AND (bottom EQ n-1)) THEN BEGIN ; keep nothing
        datasets = [' ']  ; null
    ENDIF ELSE BEGIN
        IF (bottom EQ n-1) THEN BEGIN   ; only keep above top
            datasets = datasets[0:top-1]
        ENDIF ELSE BEGIN  ; keep below bottom
            IF (top EQ 0) THEN BEGIN    ; only keep below bottom
                datasets = datasets[bottom+1:*]
            ENDIF ELSE BEGIN  ; keep both above top & below bottom
                datasets = [datasets[0:top-1],datasets[bottom+1:*]]
            ENDELSE
        ENDELSE
    ENDELSE

; redo the data table and output delete message
    WV_DATATABLE_SET, (*wv).id.datatable, datasets, /MODIFIED, $
        COLUMN_MAJOR=(*wv).info.column_major
    WV_MESSAGE,Event.top,delete_str + deletes
    RETURN
END ; wv_data_delete


;----------------------------------------------------------------
FUNCTION wv_datatable_event, Event

    COMPILE_OPT strictarr, hidden
; Catch errors
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        WV_ERROR_HANDLER,Event.top
        RETURN,0
    ENDIF

    child = WIDGET_INFO(Event.top,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=wv
    WIDGET_CONTROL,Event.id,GET_UVALUE=editable

    type = TAG_NAMES(Event,/STRUCTURE_NAME)
    CASE (type) OF
    'WIDGET_TABLE_CH': BEGIN ; Event.ch,Event.offset,Event.x,Event.y
        WIDGET_CONTROL,Event.id, $
            GET_VALUE=datasets, $
            GET_UVALUE=uvalue
        IF (N_TAGS(datasets) EQ 0) THEN BEGIN  ; no datasets
            WIDGET_CONTROL,(*wv).id.datatable, SET_VALUE = [' ']  ; null
            RETURN,0
        ENDIF
        ; Copy from Table structure to actual internal structure.
        newdatasets = uvalue.datasets
        STRUCT_ASSIGN, datasets, newdatasets, /NOZERO
        uvalue.datasets = newdatasets
        datasets = uvalue.datasets
        title = (*wv).info.abbrev+': '+(*wv).info.file_name
        position = Event.x
        IF ((*wv).info.column_major) THEN position=Event.y
        CASE (position) OF
            0: WV_DATATABLE_SET,Event.id,datasets, $ ; can't modify first column
                COLUMN_MAJOR=(*wv).info.column_major
            2: WV_DATATABLE_SET,Event.id,datasets, /MODIFIED, $
                COLUMN_MAJOR=(*wv).info.column_major
            ELSE: IF NOT uvalue.modified THEN BEGIN
                uvalue.modified = 1
                WIDGET_CONTROL,Event.id, $
                    TLB_SET_TITLE=uvalue.tlb_title + ' (modified)'
                ENDIF
        ENDCASE
        WIDGET_CONTROL, Event.id, $
            SET_TABLE_SELECT=[Event.x, Event.y, Event.x, Event.y]
        WIDGET_CONTROL,Event.id, SET_UVALUE=uvalue, /NO_COPY
        END
    'WIDGET_TABLE_STR': ;type,Event.str,Event.offset,Event.x,Event.y
    'WIDGET_TABLE_DEL': ;type,Event.offset,Event.length,Event.x,Event.y
    'WIDGET_TABLE_TEXT_SEL': ;type,Event.offset,Event.length,Event.x,Event.y
    'WIDGET_TABLE_CELL_SEL': ;type,Event.sel_left, Event.sel_top, Event.sel_right, Event.sel_bottom
    'WIDGET_TABLE_ROW_HEIGHT': ;type ;do nothing
    'WIDGET_TABLE_COL_WIDTH': ;type ;do nothing?
    'WIDGET_TABLE_INVALID_ENTRY': ;type,Event.str,Event.x,Event.y
    ELSE:
    ENDCASE
    RETURN,0
END ; wv_datatable_event


;----------------------------------------------------------------
FUNCTION wv_cw_datatable, parent, XSIZE=xsize, $
    COLUMN_MAJOR=column_major

    COMPILE_OPT strictarr

    column_major = KEYWORD_SET(column_major)

; create the dataset table
    id_datarow = WIDGET_BASE(parent,/ROW,FRAME=0,SPACE=5)

    sWV_data__define
    datasets = [{sWv_datatable}]
    column_labels = WV_STRCAPITALIZE(TAG_NAMES(datasets[0]))
    row_labels = STRARR(1)
    row_labels = ['(no data)',' ']
    IF (column_major) THEN BEGIN
        IF (N_ELEMENTS(xsize) LT 1) THEN xsize=6
        extra = {COLUMN_MAJOR:1, $
            ROW_LABELS:column_labels, $
            COLUMN_LABELS:row_labels, $
            XSIZE:xsize, $
            Y_SCROLL_SIZE:N_ELEMENTS(column_labels) + 3}
    ENDIF ELSE BEGIN
        IF (N_ELEMENTS(xsize) LT 1) THEN xsize=400
        extra = {ROW_MAJOR:1, $
            COLUMN_LABELS:column_labels, $
            ROW_LABELS:row_labels, $
            SCR_XSIZE:xsize-50, $
            YSIZE:6}
    ENDELSE

    wDatatable = WIDGET_TABLE(id_datarow, $
        ALIGNMENT=0, $
        ALL_EVENTS=0, $
        EDITABLE=1, $
        EVENT_FUNC='wv_datatable_event', $
;        FORMAT='(A)', $
        /RESIZEABLE_COLUMNS, $
        /SCROLL, $
        UVALUE={MODIFIED:0,TLB_TITLE:'',DATASETS:0}, $
        VALUE=datasets, $
        _EXTRA=extra)
    RETURN, wDatatable
END

