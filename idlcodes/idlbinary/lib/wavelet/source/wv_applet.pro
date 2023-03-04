;----------------------------------------------------------------
; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/wavelet/source/wv_applet.pro#2 $
;
; Copyright (c) 1999-2006, Research Systems, Inc.  All rights reserved.
; Unauthorized reproduction prohibited.
;+
; NAME:
;    WV_APPLET
;
; PURPOSE:
;
;    This procedure runs the IDL Wavelet Toolkit graphical user
;    interface.
;
; CATEGORY:
;
;    Toolkits
;
; CALLING SEQUENCE:
;
;    WV_APPLET [, filename]
;      [, ARRAY=array] [, GROUP_LEADER=wGroup]
;      [, NO_SPLASH=no_splash]
;      [, TOOLS=tools] [, WAVELETS=wavelets]
;
; INPUTS:
;
;    Filename: A scalar string giving the name of a Wavelet Toolkit
;      save file to open upon startup. If no filename is specified
;      (and keyword ARRAY is not set) then the example file is opened.
;      If the filename is a null string ("") then the example
;      file is not opened.
;
; KEYWORD PARAMETERS:
;
;    ARRAY: A one- or two-dimensional array to be imported into WV_APPLET.
;      If argument Filename is also given then ARRAY is added to the list
;      of variables.
;
;    GROUP_LEADER: The widget ID of an existing widget that serves as
;      "group leader" for the newly-created widget. When a group leader
;      is killed, for any reason, all widgets in the group are also destroyed.
;
;    NO_SPLASH: If this keyword is set then the splash screen will
;      not be displayed on startup.
;
;    TOOLS: A scalar string or vector of strings giving the names of
;      user-defined functions to be included in the WV_APPLET Tools menu.
;      The actual function names are constructed by removing all white space
;      from each name and attaching a prefix of WV_TOOL_.
;
;    WAVELETS: A scalar string or vector of strings giving the names of
;      user-defined wavelet functions to be included in WV_APPLET. The actual
;      function names are constructed by removing all white space from each
;      name and attaching a prefix of WV_FN_.
;
; OUTPUTS:
;    None
;
; REFERENCE:
;    IDL Wavelet Toolkit Online Manual
;
; MODIFICATION HISTORY:
;    Written by CT, 1999
;    May 2000, CT: Moved data viewer out to WV_CW_DATATABLE,
;        removed RESOLVE_ALL, changed splash to PNG.
;-
;  Variable name conventions used herein:
;       r==Reference to Object
;       p==pointer
;       w==widget ID
;


;*****************************************************************************
; Auxiliary routines start here
;*****************************************************************************




;----------------------------------------------------------------
;  NAME:
;    WV_STRCAPITALIZE
;
;  PURPOSE:
;    This function returns a copy of a string or array of strings
;    with each string converted so the first letter is capitalized
;    and the remaining letters are uncapitalized.
;
;
;  CALLING SEQUENCE:
;    Result = WV_STRCAPITALIZE(string)
;
; INPUTS:
;    string: A string or array of strings.
;
; KEYWORD PARAMETERS:
;    None
;
; OUTPUTS:
;    Result: The capitalized string or array of strings.
;
; MODIFICATION HISTORY:
;    Written by: Chris Torrence, 1999
;
FUNCTION wv_strcapitalize,string_in
    COMPILE_OPT strictarr, hidden
    ON_ERROR,2
    string_out = string_in
    FOR i=0,N_ELEMENTS(string_in)-1 DO BEGIN
        s = string_in[i]
        string_out[i] = STRUPCASE(STRMID(s,0,1)) + $
            STRLOWCASE(STRMID(s,1))
    ENDFOR
    RETURN,string_out
END


;----------------------------------------------------------------
PRO wv_message, topid, value
    COMPILE_OPT strictarr, hidden
    child = WIDGET_INFO(topid,/CHILD)
    IF (value NE '') THEN BEGIN
        WIDGET_CONTROL,child,GET_UVALUE=wv
        id_message = (*wv).id.message
        IF (id_message LT 1) THEN $
            MESSAGE,'*** Unable to find message bar ***' $
        ELSE WIDGET_CONTROL,id_message,SET_VALUE=value
    ENDIF
END


;----------------------------------------------------------------
PRO wv_error_handler, wTop, $
    EXTRA=extra, $ ; additional error message
    INFO=info, $ ; return to user
    NO_BUG=no_bug  ; if set, then this is a user error, not a bug

    COMPILE_OPT strictarr, hidden

    bug = 1b - KEYWORD_SET(no_bug)
    info = [!ERROR_STATE.MSG]
    IF (!ERROR_STATE.SYS_MSG NE '') THEN info = [info,!ERROR_STATE.SYS_MSG]
    info = [info,'']

; add traceback info
    IF (bug) THEN BEGIN
        HELP,/TRACEBACK,OUTPUT=output
        n = N_ELEMENTS(output)
        output = output[(n GT 1):(2 < (n-1))]
        info = [info, output]
    ENDIF

; add extra info
    IF (N_ELEMENTS(extra) GT 0) THEN info = [info, extra]

; add Applet info
    IF (N_ELEMENTS(wTop) GT 0) THEN BEGIN
        IF WIDGET_INFO(wTop,/VALID) THEN BEGIN
            child = WIDGET_INFO(wTop,/CHILD)
            WIDGET_CONTROL,child,GET_UVALUE=wv
            info = [info, $
                (*wv).info.title + ' ' + (*wv).info.version]
            extra = {dialog_parent:wTop}
        ENDIF
    ENDIF

; add IDL !VERSION info
    info = [info, $
        '{'+STRING(!VERSION,FORMAT='(10(A,:," "))') + '}']

; add LM Host ID if present
    dummy = LMGR(LMHOSTID=LmHostID)
    IF (LmHostID NE '0') THEN info = [info,'LmHostID='+LmHostID]

; add feedback info
    email = '<support@ResearchSystems.com>'
    CASE (bug) OF
        0: feedback = 'Please contact '+email+' for more information.'
        1: feedback = ['Please report the above message and the actions', $
            'leading up to the error to '+email]
    ENDCASE

; combine all strings
    info = [info,'',feedback]
    title = (['Error','*** ERROR ***'])[bug]
    info = STRCOMPRESS(info) ; remove all double spaces

; output to Dialog widget and to IDL output log
    PRINT,TRANSPOSE([title,info])
    result = DIALOG_MESSAGE(info,/ERROR, $
            TITLE=title, $
            _EXTRA=extra)
END


;----------------------------------------------------------------
FUNCTION wv_information, tool_file_in

    COMPILE_OPT strictarr, hidden

    CD,CURRENT=current   ; current working directory (doesn't change dir)
    suffix = 'sav'    ; file suffix
    tool_file = STRUPCASE(tool_file_in)
    tool_path = (ROUTINE_INFO(tool_file,/SOURCE)).path
    pathPos = STRPOS(STRUPCASE(tool_path),'SOURCE')
    IF (pathPos LT 0) THEN MESSAGE,'Unable to find SOURCE directory.'
    tool_path = STRMID(tool_path,0,pathPos-1)
    CASE STRUPCASE(!VERSION.OS_FAMILY) OF
        'UNIX': separator = '/'
        'WINDOWS': separator = '\'
        'MACOS': separator = ':'
        'VMS' : separator = ']'
    ENDCASE
    tool_path = tool_path + separator
    example_path = FILEPATH('',ROOT_DIR=tool_path,SUBDIR=['data'])
    example_file = 'wv_sample.sav'

    RETURN,{title:'IDL Wavelet Toolkit', $
        abbrev:'Wavelet', $    ; abbreviation
        suffix:suffix, $
        $
        version:'6.3', $   ;** VERSION **
        $
        copyright:[ $
            'Copyright 1999-2006, Research Systems, Inc.', $
            'All rights reserved.', $
            'Unauthorized reproduction prohibited.'], $
        tool_file:tool_file, $
        tool_path:tool_path, $
        path:current, $
        file_name:'Untitled.'+suffix, $
        file_path:current, $
        example_path: example_path, $
        example_file: example_file, $
        view_win:LONARR(5), $ ; [Xsize,Ysize,Xoffset,Yoffset,show_data_flag]
        dataset:0L, $
        column_major:1}
END


;----------------------------------------------------------------
; This function returns the default preferences for WV_APPLET
;    Result = WV_DEFAULT_PREFS(dummy)
;    Dummy: This is a dummy (undefined) variable just so IDL
;           doesn't get confused by the empty parentheses.
FUNCTION wv_default_prefs,dummy

    COMPILE_OPT strictarr, hidden

    CD,CURRENT=current
    general = { $
        keep_path:1, $
        confirm_exit:1, $
        save_compress:0}
    general_str = [ $
        'Remember current directory', $
        'Confirm exit', $
        'Compress save files']

    RETURN,{ $
        path:current, $
        general:general, $
        general_str:general_str, $
        oneDstrideFactor:16384L, $
        twoDstrideFactor:256L $
        }
END ; wv_default_prefs


;----------------------------------------------------------------
; adapted from function FILENAME_PATH_SEP in CW_FILESEL.PRO
FUNCTION wv_filename_path_separate, fullName, PATH=path

    COMPILE_OPT strictarr, hidden

    filename = ''
    path = ''

    CASE STRUPCASE(!VERSION.OS_FAMILY) OF
        'UNIX': separator = '/'
        'WINDOWS': separator = '\'
        'MACOS': separator = ':'
        'VMS' : separator = ']'
    ENDCASE
    delimit = STRPOS(fullName, separator, /REVERSE_SEARCH)

    IF (delimit GT -1) THEN BEGIN
        filename = STRMID(fullName, delimit+1)
        path = STRMID(fullName, 0, delimit+1)
    ENDIF ELSE BEGIN
        filename = fullName
        path=''
    ENDELSE

    RETURN, filename
END


;----------------------------------------------------------------
FUNCTION wv_choose_file, wBase, $
    FILE_NAME=file_name, $
    FILE_PATH=file_path, $
    SUFFIX=suffix, $
    TYPE=type

    COMPILE_OPT strictarr, hidden

    child = WIDGET_INFO(wBase,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=wv

; choose either default path or current path
    CASE (*wv).prefs.general.keep_path OF
        0: file_path_in = (*wv).prefs.path
        1: file_path_in = (*wv).info.path
    ENDCASE

; if SUFFIX then construct filter
    filter = ''
    IF (N_ELEMENTS(suffix) EQ 1) THEN filter = '*.' + suffix
    IF (N_ELEMENTS(type) LT 1) THEN type = ''
; pick a file
    file = DIALOG_PICKFILE(GROUP=wBase, $
        FILTER=filter, $
        /READ,/MUST_EXIST,PATH=file_path_in, $
        TITLE='Select ' + type + ' File', $
        GET_PATH=file_path)
    IF (file EQ '') THEN BEGIN
        WV_MESSAGE,wBase,'Cancelled import data.'
        RETURN,''
    ENDIF

    WIDGET_CONTROL,/HOURGLASS
    WV_MESSAGE,wBase,'Importing '+file

; find the file suffix
    file_dot_split = STRSPLIT(file,'.',/EXTRACT)
    n = N_ELEMENTS(file_dot_split)
    suffix = ''
    IF (n GT 1) THEN suffix = STRMID(file_dot_split[n-1],0,3)
    suffix = STRLOWCASE(suffix)

; find the filename (without the filepath)
    file_name = WV_FILENAME_PATH_SEPARATE(file,PATH=file_path)
    file_name = file_name[N_ELEMENTS(file_name)-1]

    RETURN,file
END ; wv_choose_file


;----------------------------------------------------------------
FUNCTION wv_save_changes, wBase
    COMPILE_OPT strictarr, hidden
    child = WIDGET_INFO(wBase,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=wv
;** check if all files saved
    WIDGET_CONTROL,(*wv).id.datatable,GET_UVALUE=uvalue
    success = 1 ; assume success

    IF (uvalue.modified) THEN BEGIN

        file_output = ['Save changes to','"'+(*wv).info.file_name+'"?']
        doSave = DIALOG_MESSAGE(file_output, $
            /CANCEL, $
            DIALOG_PARENT=wBase, $
            /QUESTION, $
            TITLE='Save Changes')

        CASE doSave OF
            'Yes': WV_FILE_SAVE, $
                    {WIDGET_BUTTON,id:(*wv).id.menu.file_save, $
                    TOP:wBase,HANDLER:wBase,SELECT:1}, $
                    SUCCESS=success
            'Cancel': success = 0 ; failure
            ELSE: ; do nothing
        ENDCASE

    ENDIF
    RETURN, success
END





;----------------------------------------------------------------
PRO wv_import_data, dataset_in, $
    PARENT=wBase, $
    FILE_PATH=file_path, $
    MESSAGE_OUT=message_out

    COMPILE_OPT strictarr

; Catch errors
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        WV_ERROR_HANDLER,wBase,NO_BUG=no_bug
        RETURN
    ENDIF

    COMMON cWvAppletData, $
        wCurrentApplet, $   ; widget ID of currently-active Applet
        WaveletFamilies     ; string array of usable wavelet functions

; find parent widget
    IF (N_ELEMENTS(wCurrentApplet) LT 1) THEN wCurrentApplet = 0L
    IF (N_ELEMENTS(wBase) LT 1) THEN wBase = wCurrentApplet[0]
    IF (NOT WIDGET_INFO(wBase,/VALID)) THEN BEGIN
        no_bug = 1
        MESSAGE,/INFO,'IDL Wavelet Toolkit is not currently running.'
        RETURN
    ENDIF

; retrieve widget state
    child = WIDGET_INFO(wBase,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=wv

    IF (N_ELEMENTS(file_path) GT 0) THEN (*wv).info.path = file_path

    IF (N_ELEMENTS(dataset_in) EQ 0) THEN BEGIN
        no_bug = 1
        MESSAGE,/NONAME,'Please input a data array or structure.'
        RETURN
    ENDIF

    WIDGET_CONTROL,/HOURGLASS

    IF (N_TAGS(dataset_in) EQ 0) THEN BEGIN ; make a data structure
        HELP,dataset_in,OUTPUT=message_out
        message_out = message_out[0]
        data_in = {data:PTR_NEW(dataset_in), $
            source:'Imported', $
            variable:'Data', $
            modified:SYSTIME()}
    ENDIF ELSE data_in = dataset_in ; just make a copy

; fix up all tags
    data = {sWv_data}   ; new variable structure
    STRUCT_ASSIGN,data_in,data,/NOZERO  ; copy all of the good tags
    siz = SIZE(*data.data)
    CASE (siz[0]) OF
        1: data.xstride = LONG((siz[1]-1)/(*wv).prefs.oneDstrideFactor) + 1L
        2: BEGIN
            data.xstride = LONG((siz[1]-1)/(*wv).prefs.twoDstrideFactor) + 1L
            data.ystride = LONG((siz[2]-1)/(*wv).prefs.twoDstrideFactor) + 1L
            END
        ELSE: BEGIN
            no_bug = 1
            MESSAGE,'Array must be a vector or 2D array'
            END
    ENDCASE
    no_bug = 1
    SWV_DATA_ACCESS,data         ; fix up remaining tags
    no_bug = 0

; store the new variable
    WIDGET_CONTROL,(*wv).id.datatable,GET_UVALUE=uvalue
    datasets = uvalue.datasets
    IF (N_TAGS(datasets) NE 0) THEN data = $
        [TEMPORARY(datasets),TEMPORARY(data)]
    WV_DATATABLE_SET, (*wv).id.datatable, data, /MODIFIED, $
        COLUMN_MAJOR=(*wv).info.column_major

; change table selection to be new variable
    n = N_ELEMENTS(data)
    set_table_select = [0,n-1,0,n-1]
    IF (*wv).info.column_major THEN set_table_select = [n-1,0,n-1,0]
    WIDGET_CONTROL,(*wv).id.datatable, SET_TABLE_SELECT=set_table_select

; if column_major, change width of new column to equal first column width
    IF ((n GT 1) AND ((*wv).info.column_major)) THEN BEGIN
        column_widths = WIDGET_INFO((*wv).id.datatable,/COLUMN_WIDTHS)
        WIDGET_CONTROL,(*wv).id.datatable, $
            COLUMN_WIDTHS=[column_widths[0:n-2],column_widths[0]]
    ENDIF

; Output the variable info
    IF (N_ELEMENTS(message_out) EQ 1) THEN WV_MESSAGE,wBase,message_out
    RETURN
END ; wv_import_data


;*****************************************************************************
; Event handling routines start here
;*****************************************************************************


;----------------------------------------------------------------
PRO wv_file_new, Event

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
    WIDGET_CONTROL,child, GET_UVALUE=wv
  user_tools = (*wv).info.tools
    IF (user_tools[0] NE '') THEN tools = user_tools

    WV_APPLET, $
        '', $  ; don't load sample file
        /NO_SPLASH, $
        TOOLS=tools
    RETURN
END


;----------------------------------------------------------------
PRO wv_file_open, Event, $
    FILE_IN=file_in, $
    EXAMPLE=example

    COMPILE_OPT strictarr, hidden

    ioerror = 0
; Catch errors
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        WV_ERROR_HANDLER,Event.top,NO_BUG=ioerror
        RETURN
    ENDIF

    child = WIDGET_INFO(Event.top,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=wv

;** check if old dataset saved
    result = WV_SAVE_CHANGES(Event.top)
    IF (result EQ 0) THEN BEGIN
        WV_MESSAGE,Event.top,'Cancelled open.'
        RETURN
    ENDIF

; retrieve the old file path
    suffix = '.' + (*wv).info.suffix
; choose either default path or current path
    CASE (*wv).prefs.general.keep_path OF
        0: file_path = (*wv).prefs.path
        1: file_path = (*wv).info.path
    ENDCASE
    title = 'Open dataset'

    done_once = 0

again: ; choose a file name
    file_name = '';suffix
    filter = suffix
;   IF (!VERSION.OS_FAMILY EQ 'Windows') THEN filter=suffix ELSE filter='.*'

    IF (N_ELEMENTS(file_in) LT 1) THEN BEGIN
        file = DIALOG_PICKFILE(GROUP=Event.top, $
            FILE=file_name, $
            FILTER='*'+filter, $
            GET_PATH=file_path, $
            /MUST_EXIST, $
            PATH=file_path, $
            TITLE=title)
    ENDIF ELSE BEGIN
        file = TEMPORARY(file_in)
    ENDELSE

    WIDGET_CONTROL,/HOURGLASS

    IF (file EQ '') THEN BEGIN
        WV_MESSAGE,Event.top,'Cancelled open.'
        RETURN
    ENDIF

; check to make sure FILE exists
    exists = FILE_SEARCH(file)
    IF (exists[0] EQ '') THEN BEGIN
        result = DIALOG_MESSAGE(["Cannot find file", $
            "'" + file + "'"], $
            DIALOG_PARENT=Event.top,TITLE=title)
        done_once = done_once + 1
        IF (done_once LE 1) THEN GOTO,again  ; try again
        RETURN
    ENDIF

    ioerror = 1   ; catch IOerrors

; read the file
    RESTORE,file,/RELAXED_STRUCTURE_ASSIGNMENT

    IF (N_TAGS(wv_info) LT 1) THEN MESSAGE, $
        file+' is not a valid Wavelet Toolkit save file.'
    ioerror = 0
    WIDGET_CONTROL,/HOURGLASS

; restore saved preferences
    new_wv_prefs = (*wv).prefs
    STRUCT_ASSIGN, wv_prefs, new_wv_prefs, /NOZERO
    (*wv).prefs = new_wv_prefs

; strip out the file name
    file_name = WV_FILENAME_PATH_SEPARATE(file,PATH=file_path)
; keep the new file paths & name
    (*wv).info.path = file_path
    (*wv).info.file_name = file_name
    (*wv).info.file_path = file_path

; restore datasets
    WIDGET_CONTROL,(*wv).id.datatable,GET_UVALUE=uvalue
    old_datasets = uvalue.datasets
    WV_DATASET_FREE, old_datasets
    WV_DATATABLE_SET, (*wv).id.datatable, datasets, $
        COLUMN_MAJOR=(*wv).info.column_major, $
        MODIFIED=0, $
        TITLE=(*wv).info.abbrev+': '+file_name
    IF ((N_TAGS(wv_state) GT 0) AND (NOT KEYWORD_SET(example))) THEN BEGIN
        WIDGET_CONTROL,(*wv).id.datatable, $
            COLUMN_WIDTHS=wv_state.column_widths, $
            TLB_SET_XOFFSET=wv_state.base_offset[0] > 0, $
            TLB_SET_YOFFSET=wv_state.base_offset[1] > 0
        x = wv_state.base_size[0]
        y = wv_state.base_size[1]
        xOld = (*wv).info.base_size[0]
        yOld = (*wv).info.base_size[1]
        IF ((x NE xOld) OR (y NE yOld)) THEN BEGIN
            WV_APPLET_EVENT, {WIDGET_BASE, $
                ID:Event.top, $
                TOP:Event.top, $
                HANDLER:Event.handler, $
                X:x, $
                Y:y}
        ENDIF
    ENDIF

    WV_MESSAGE,Event.top,'Opened dataset '+file

    RETURN
END ; wv_file_open


;----------------------------------------------------------------
; This Event procedure saves a WV_APPLET session.
;
;    WV_FILE_SAVE, Event [, File_name, File_path]
;
;    Event: A widget event of the form,
;        {WIDGET_BUTTON, ID:0L, TOP:0L, HANDLER:0L, SELECT:0}
;
;    File_name: If input, this is the file name to save to.
;    File_path: If input, this is the directory in which to save.
;
;   If WV_FILE_SAVE is called by an event handler then File_name
;   and File_path are not input and are instead retrieved
;   from (*wv).info. File_name, File_path are only
;   used when WV_FILE_SAVE is called "manually" by WV_FILE_SAVEAS.
;
;   If the file name is "untitled" then an event is sent to
;   WV_FILE_SAVEAS to get a legitimate file name.
;
PRO wv_file_save, Event, file_name, file_path, $
    FORCE=force, $  ; if set, then overwrite even if "sample" file
    SUCCESS=success

    COMPILE_OPT strictarr, hidden

    success = 0 ; assume "failure" unless we make it to bottom

    ioerror = 0
; Catch errors
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        WV_ERROR_HANDLER,Event.top,NO_BUG=ioerror
        RETURN
    ENDIF

    child = WIDGET_INFO(Event.top,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=wv

    IF (N_ELEMENTS(file_name) LT 1) THEN file_name = (*wv).info.file_name
    IF (N_ELEMENTS(file_path) LT 1) THEN file_path = (*wv).info.file_path

; if "untitled" then "Save As" needs to be called
    untitled = (STRPOS(STRLOWCASE(file_name),'untitled') GE 0) OR $
        (STRPOS(STRLOWCASE(file_name),(*wv).info.example_file) GE 0)
    IF (untitled AND (NOT KEYWORD_SET(force))) THEN BEGIN
        WV_FILE_SAVEAS,{id:(*wv).id.menu.file_saveas, $
            TOP:Event.top,HANDLER:Event.top}, SUCCESS=success
        RETURN  ; "Save As" will call WV_FILE_SAVE again, so return
    ENDIF

; construct the temporary info to be saved
    WIDGET_CONTROL,/HOURGLASS
    file = file_path + file_name
    WIDGET_CONTROL,(*wv).id.datatable,GET_UVALUE=uvalue, $
        TLB_GET_OFFSET=base_offset, $
        TLB_GET_SIZE=base_size
    datasets = uvalue.datasets
    wv_info = (*wv).info
    wv_prefs = (*wv).prefs
    column_widths = WIDGET_INFO((*wv).id.datatable,/COLUMN_WIDTHS)
    wv_state = { $
        base_size:base_size, $
        base_offset:base_offset, $
        column_widths:column_widths}

; use SAVE to save the dataset
    ioerror = 1 ; set flag for input/output errors
    SAVE,FILE=file, $
        wv_info, $
        wv_prefs, $
        wv_state, $
        datasets, $
        COMPRESS=(*wv).prefs.general.save_compress
    ioerror = 0 ; reset flag
    success = 1

; remember the current directory & filename
    (*wv).info.path = file_path
    (*wv).info.file_name = file_name
    (*wv).info.file_path = file_path
    title = (*wv).info.abbrev+': '+file_name

; reset to unmodified
    WIDGET_CONTROL,(*wv).id.datatable, $
        GET_UVALUE=uvalue, /NO_COPY
    uvalue.modified = 0
    uvalue.tlb_title = title
    WIDGET_CONTROL,(*wv).id.datatable, $
        SET_UVALUE=uvalue, /NO_COPY, $
        TLB_SET_TITLE=uvalue.tlb_title

    WV_MESSAGE,Event.top,'Saved '+file

    RETURN
END ; wv_file_save


;----------------------------------------------------------------
; This Event procedure lets the user choose a new file name,
;   and then saves the WV_APPLET session.
;
;   After choosing a file name, WV_FILE_SAVEAS calls WV_FILE_SAVE
;   manually, sending the variables File_name, File_path.
;
;   SUCCESS = 1 if user chose a file and pressed "Ok"
;           = 0 if user pressed "Cancel"
;
PRO wv_file_saveas, Event, $
    SUCCESS=success

    COMPILE_OPT strictarr, hidden

    success = 0 ; assume "Cancel" unless we make it to bottom

; Catch errors
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        WV_ERROR_HANDLER,Event.top
        RETURN
    ENDIF

    child = WIDGET_INFO(Event.top,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=wv

; retrieve the old file name & path
    file_name = (*wv).info.file_name
    suffix = '.' + (*wv).info.suffix
    file_path = (*wv).info.file_path

again: ; choose a file name (can't be 'untitled')
    untitled = (STRPOS(STRLOWCASE(file_name),'untitled') GE 0) OR $
        (STRPOS(STRLOWCASE(file_name),(*wv).info.example_file) GE 0)
    IF (untitled) THEN file_name = '';suffix
    filter = suffix
;   IF (!VERSION.OS_FAMILY EQ 'Windows') THEN filter=suffix ELSE filter='.*'

    file = DIALOG_PICKFILE(GROUP=Event.top, $
        FILE=file_name, $
        FILTER='*'+filter, $
        GET_PATH=file_path, $
        PATH=file_path, $
        TITLE='Save As', $
        /WRITE)

    IF (file EQ '') THEN BEGIN
        WV_MESSAGE,Event.top,'Cancelled save.'
        RETURN
    ENDIF

; check if file already exists
    exists = FILE_SEARCH(file)
    IF (exists[0] NE '') THEN BEGIN
        result = DIALOG_MESSAGE([file, $
                'This file already exists. Replace existing file?'], $
            /QUESTION,DIALOG_PARENT=Event.top,TITLE='Save As')
        IF (result EQ 'No') THEN GOTO,again  ; try again
    ENDIF

; strip out the file name, and add suffix if Windows architecture
    file_name = STRMID(file,STRLEN(file_path),255)
    chosen_suffix = STRMID(file_name,(STRLEN(file_name)>0) - 4,4)
    IF ((chosen_suffix NE suffix) AND $
        (!VERSION.OS_FAMILY EQ 'Windows')) THEN $
        file_name = file_name + suffix

; Call WV_FILE_SAVE manually with a fake event.
    WV_FILE_SAVE,{WIDGET_BUTTON,id:(*wv).id.menu.file_save, $
        TOP:Event.top,HANDLER:Event.top,SELECT:1}, $
        file_name,file_path, $
        /FORCE, $
        SUCCESS=success

    RETURN
END ; wv_file_saveas



;----------------------------------------------------------------
PRO wv_file_import_ascii, Event

    COMPILE_OPT strictarr, hidden

; Catch errors
    ioerror = 0
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        IF (ioerror) THEN extra=['Please check the file and try again.','']
        WV_ERROR_HANDLER,Event.top, $
            NO_BUG=ioerror,EXTRA=extra
        RETURN
    ENDIF

    child = WIDGET_INFO(Event.top,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=wv

    file = WV_CHOOSE_FILE(Event.top, $
        FILE_PATH=filepath_out, $
        FILE_NAME=file_name, $
        SUFFIX=suffix, $
        TYPE='ASCII')

    IF (file EQ '') THEN RETURN

    ioerror = 1
    IF (N_TAGS(template) EQ 0) THEN template = $
        ASCII_TEMPLATE(file, GROUP=parent, CANCEL=cancelled)
    ioerror = 0
    IF (cancelled) THEN BEGIN
        WV_MESSAGE,Event.top,'Cancelled import data.'
        RETURN
    ENDIF

    ioerror = 1
    data_in = READ_ASCII(file,TEMPLATE=template)
    ioerror = 0

    WIDGET_CONTROL,/HOURGLASS
    modified = SYSTIME()

; Set dataset name equal to the filename minus the suffix
    ln = STRLEN(file_name)
    ls = STRLEN(suffix)
    name = file_name
    actual_suffix = STRLOWCASE(STRMID(name,ln-ls,ls))
    IF (actual_suffix EQ suffix) THEN name = STRMID(name,0,ln-ls-1)

; These are tentative, depending on the characteristics of the first
; field, i.e., is it the time?
    start = 0
    ; assume no time variable
    xname = ''
    time = LINDGEN(N_ELEMENTS(data_in.(0)))
    fields = TAG_NAMES(data_in)
    nFields = N_ELEMENTS(fields)


; Check to see if first field is "time" variable.
; If so, then it should increase monotonically
    IF (nFields GT 1) THEN BEGIN
        data0_sort = SORT(data_in.(0))
        monotonic = MIN(data0_sort EQ time) EQ 1
        IF (STRUPCASE(fields[0]) EQ 'TIME') OR monotonic THEN BEGIN
            time = data_in.(0)   ; new time variable
            xname = fields[0]    ; new time name
            start = 1
        ENDIF
    ENDIF

    xstart = STRTRIM(time[0],2)
    dx = STRTRIM(time[1]-time[0],2)
    nx = N_ELEMENTS(time)

    FOR index = start, nFields-1 DO BEGIN
        data = data_in.(start)
        variable = fields[start]

    ; construct a temporary structure
        dataStore = { $
            title:WV_STRCAPITALIZE(name), $
            variable:variable, $
            units:'', $
            xname:xname, $
            xunits:'', $
            xstart:xstart, $
            dx:dx, $
            source:file, $
            modified:modified, $
            nx:nx, $
            data:PTR_NEW(data)}

        WV_IMPORT_DATA, dataStore, $
            PARENT=Event.top, $
            FILE_PATH=file_path, $
            MESSAGE_OUT=variable
    ENDFOR
    RETURN
END ; wv_file_import_ascii


;----------------------------------------------------------------
PRO wv_file_import_binary, Event

    COMPILE_OPT strictarr, hidden

; Catch errors
    ioerror = 0
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        IF (ioerror) THEN extra=['Please check the file and try again.','']
        WV_ERROR_HANDLER,Event.top, $
            NO_BUG=ioerror,EXTRA=extra
        RETURN
    ENDIF

    child = WIDGET_INFO(Event.top,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=wv

    file = WV_CHOOSE_FILE(Event.top, $
        FILE_PATH=filepath_out, $
        FILE_NAME=file_name, $
        SUFFIX=suffix, $
        TYPE='Binary')

    IF (file EQ '') THEN RETURN

    ioerror = 1
    IF (N_TAGS(template) EQ 0) THEN template = BINARY_TEMPLATE(file, $
        GROUP=parent,CANCEL=cancelled)
    ioerror = 0
    IF (cancelled) THEN BEGIN
        WV_MESSAGE,Event.top,'Cancelled import data.'
        RETURN
    ENDIF

    WIDGET_CONTROL,/HOURGLASS

    ioerror = 1
    data_read = READ_BINARY(file,TEMPLATE=template)

    IF (template.fieldcount LT 1) THEN MESSAGE,/NONAME, $
        "'" + file_name + "' does not have any data.'

; dataset title
    title = template.templatename
    IF (title EQ '') THEN BEGIN ; Set dataset name equal to filename minus suffix
        ln = STRLEN(file_name)
        ls = STRLEN(suffix)
        title = file_name
        actual_suffix = STRLOWCASE(STRMID(title,ln-ls,ls))
        IF (actual_suffix EQ suffix) THEN title = STRMID(title,0,ln-ls-1)
        title = WV_STRCAPITALIZE(title)
    ENDIF

; construct a temporary structure
    data_in = { $
        title:title, $
        variable:'', $
        xstart:'0', $
        dx:'1', $
        ystart:'0', $
        dy:'1', $
        source:file, $
        modified:SYSTIME(), $
        data:PTR_NEW()}

    FOR i=0,template.fieldcount - 1 DO BEGIN
        data_in.variable = (template.names)[i]
        data_in.data = PTR_NEW(data_read.(i))
        valid = ((template.numdims)[i] GE 1) AND ((template.numdims)[i] LE 2)
        IF (valid) THEN WV_IMPORT_DATA, data_in, $
            PARENT=Event.top, $
            FILE_PATH=file_path
    ENDFOR

    RETURN
END ; wv_file_import_binary


;----------------------------------------------------------------
PRO wv_file_import_image, Event

    COMPILE_OPT strictarr, hidden

; Catch errors
    ioerror = 0
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        IF (ioerror) THEN extra=['Please check the file and try again.','']
        WV_ERROR_HANDLER,Event.top, $
            NO_BUG=ioerror,EXTRA=extra
        RETURN
    ENDIF

    child = WIDGET_INFO(Event.top,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=wv

; choose either default path or current path
    CASE (*wv).prefs.general.keep_path OF
        0: file_path = (*wv).prefs.path
        1: file_path = (*wv).info.path
    ENDCASE

; read in the image, along with red,green,blue palette, query, etc.
    ioerror = 1
    result = DIALOG_READ_IMAGE( $
        DIALOG_PARENT=Event.top, $
        IMAGE=data, $
        PATH=file_path, $
        FILE=file, $
        QUERY=query, $
        RED=red, $
        GREEN=green, $
        BLUE=blue)

    IF (result LE 0) THEN BEGIN
        WV_MESSAGE,Event.top,'Cancelled import data.'
        RETURN
    ENDIF
    ioerror = 0

    WIDGET_CONTROL,/HOURGLASS

; Set dataset name equal to the filename minus the suffix
    file_name = WV_FILENAME_PATH_SEPARATE(file,PATH=file_path)
    suffix = STRLOWCASE(query.type)
    CASE (suffix) OF
        'jpeg': suffix = 'jpg'
        'tiff': suffix = 'tif'
        'dicom': suffix = 'dcm'
        ELSE:
    ENDCASE
    ln = STRLEN(file_name)
    ls = STRLEN(suffix)
    name = STRLOWCASE(file_name)
    suffix_pos = STRPOS(name,'.'+suffix)
    IF (suffix_pos GT 0) THEN name=STRMID(name,0,suffix_pos)

; Save the output from HELP to display later
    ioerror = 1
    HELP,data,OUTPUT=help_output
    ioerror = 0
    n_dims = (SIZE(data))[0]

; handle DICOM color tables
    IF ((suffix EQ 'dcm') AND (N_ELEMENTS(red) GT 0)) THEN BEGIN
        IF (MAX(red) GT 255) THEN BEGIN
                red = red/256
                green = green/256
                blue = blue/256
        ENDIF
    ENDIF

; convert true-color (24-bit) images
    do_loop = 0
    IF (n_dims EQ 3) THEN BEGIN
        label0 = '0,LABEL,' + "'" + file_name + "'" + $
                ' appears to be a 24-bit image.,LEFT'
        label1 = '0,LABEL,Please choose a conversion method:,LEFT'
        select0 = 'Grayscale (intensity 0...255)'
        select1 = '|Quantize to 256 colors'
        select2 = '|Separate into 3 images (red\, green\, blue)'
        description = [ $
            label0, $
            label1, $
            '0,BUTTON,' + select0 + select1 + select2 + $
                ',EXCLUSIVE,TAG=method,SET_VALUE=0', $
            '1,BASE, ,ROW', $
            '1,BASE, ,COLUMN', $
            '2,BUTTON,Okay,Quit,TAG=okay', $
            '3,BASE, ,COLUMN', $
            '2,BUTTON,Cancel,Quit']
        method = CW_FORM(description, $
            /COLUMN, $
            GROUP_LEADER=Event.top, $
            TITLE='Color Quantize')
        IF (NOT method.okay) THEN BEGIN
            WV_MESSAGE,Event.top,'Cancelled import data.'
            RETURN
        ENDIF
        CASE method.method OF
            0: data = REFORM( $
                0.299*data[0,*,*] + $
                0.587*data[1,*,*] + $
                0.114*data[2,*,*])
            1: data = COLOR_QUAN(data[0:2,*,*],1,red,green,blue, $
                COLORS=256)
            2: BEGIN
                do_loop = 1
                data3 = TEMPORARY(data)
                END
        ENDCASE
    ENDIF

; construct a temporary structure
    data_in = { $
        title:WV_STRCAPITALIZE(name), $
        variable:name, $
        units:'', $
        xname:'X', $
        xunits:'', $
        xstart:'0', $
        dx:'1', $
        yname:'Y', $
        yunits:'', $
        ystart:'0', $
        dy:'1', $
        source:file, $
        modified:SYSTIME(), $
        data:PTR_NEW(), $
        colors:PTR_NEW()}

    FOR i=0,2*do_loop DO BEGIN  ; loop if necessary
        IF (do_loop) THEN BEGIN
            data = REFORM(data3[i,*,*]) ; pick out channel
            red = BYTARR(256)
            green = BYTARR(256)
            blue = BYTARR(256)
            data_in.variable = (['Red','Green','Blue'])[i]
            CASE (i) OF
                0: red = BINDGEN(256)
                1: green = BINDGEN(256)
                2: blue = BINDGEN(256)
            ENDCASE
        ENDIF

; construct color palette
        IF (N_ELEMENTS(red) GT 1) THEN BEGIN
            colors = PTR_NEW([[red],[green],[blue]])
        ENDIF ELSE colors = PTR_NEW()

        data_in.data = PTR_NEW(TEMPORARY(data))
        data_in.colors = colors

        WV_IMPORT_DATA, data_in, $
            PARENT=Event.top, $
            FILE_PATH=file_path, $
            MESSAGE_OUT=help_output[0]
    ENDFOR
    RETURN
END ; wv_file_import_image


;----------------------------------------------------------------
PRO wv_file_import_wav, Event

    COMPILE_OPT strictarr, hidden

; Catch errors
    ioerror = 0
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        IF (ioerror) THEN extra=['Please check the file and try again.','']
        WV_ERROR_HANDLER,Event.top, $
            NO_BUG=ioerror,EXTRA=extra
        RETURN
    ENDIF

    child = WIDGET_INFO(Event.top,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=wv

    ioerror = 1
    suffix = 'wav'
    file = WV_CHOOSE_FILE(Event.top, $
        FILE_PATH=filepath_out, $
        FILE_NAME=file_name, $
        SUFFIX=suffix, $
        TYPE='WAV')

    IF (file EQ '') THEN RETURN

    result = QUERY_WAV(file,query)

    IF (result EQ 0) THEN MESSAGE,/NONAME, $
        "'" + file_name + "' does not appear to be a WAV file."

    wav_data_in = READ_WAV(file,rate)
    IF (query.channels EQ 1) THEN wav_data_in = TRANSPOSE(wav_data_in)
    ioerror = 0

    WIDGET_CONTROL,/HOURGLASS

; Set dataset name equal to the filename minus the suffix
    ln = STRLEN(file_name)
    ls = STRLEN(suffix)
    name = file_name
    actual_suffix = STRLOWCASE(STRMID(name,ln-ls,ls))
    IF (actual_suffix EQ suffix) THEN name = STRMID(name,0,ln-ls-1)

; construct a temporary structure
    n = N_ELEMENTS(wav_data_in[0,*])
    data_in = { $
        title:WV_STRCAPITALIZE(name), $
        variable:'', $
        units:'', $
        xname:'Time', $
        xunits:'sec', $
        xstart:'0', $
        dx:'1d0/'+STRTRIM(query.samples_per_sec,2), $
        source:file, $
        modified:SYSTIME(), $
        nx:n, $
        data:PTR_NEW()}

; loop through all channels
    FOR i=0,query.channels-1 DO BEGIN
        data = REFORM(wav_data_in[i,*])
        data_in.variable = 'Channel' + STRTRIM(i+1,2)
        data_in.data = PTR_NEW(data)
        help_output = data_in.variable
        WV_IMPORT_DATA, data_in, $
            PARENT=Event.top, $
            FILE_PATH=file_path, $
            MESSAGE_OUT=help_output[0]
    ENDFOR

    RETURN
END ; wv_file_import_wav


;----------------------------------------------------------------
; This Event function is selected by the Preferences "Browse"
;   button. It lets the user change the default directory.
FUNCTION wv_change_default_dir_event, Event

    COMPILE_OPT strictarr, hidden

; Catch errors
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        WV_ERROR_HANDLER,top
        RETURN,0
    ENDIF

; first get the Widget ID of the CW_FORM
    id_pref_base = Event.top
    WIDGET_CONTROL, id_pref_base, GET_UVALUE=id
    top = id.top

; now get the preference structure from CW_FORM
    WIDGET_CONTROL,id.prefs,GET_VALUE=new_prefs

; choose a new directory
    file_path = new_prefs.path
    file = DIALOG_PICKFILE(GROUP=Event.ID, $
        /DIRECTORY,/MUST_EXIST,PATH=file_path, $
        TITLE='Select default directory', $
        GET_PATH=newfile_path)
; save to CW_FORM structure
    IF (file NE '') THEN BEGIN
        WIDGET_CONTROL, id.prefs, SET_VALUE={path:newfile_path}
; this line is a kludge because CW_FORM does a STRCOMPRESS so we need to redo
        WIDGET_CONTROL, id.directory, SET_VALUE=newfile_path
    ENDIF

; re-sensitize the "Browse" button, otherwise for some reason
; it is invisible until the mouse is moved
;   WIDGET_CONTROL,Event.id,SENSITIVE=1

    RETURN,0 ; end event handling
END


;----------------------------------------------------------------
; This Event procedure processes events from the
;   Preferences dialog.
PRO wv_file_preferences_event, Event

    COMPILE_OPT strictarr, hidden

; Catch errors
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        WV_ERROR_HANDLER,top
        RETURN
    ENDIF

; retrieve the widget ID's of the Preferences form
    WIDGET_CONTROL, Event.top, GET_UVALUE=id
    top = id.top

    IF (TAG_NAMES(Event,/STRUCTURE_NAME) EQ $
        'WIDGET_KILL_REQUEST') THEN Event.id = id.cancel

    CASE (Event.id) OF
        id.prefs: ; just accept the change silently
        id.okay: BEGIN ; save changes
            WIDGET_CONTROL,id.prefs,GET_VALUE=sCwform, $
                GET_UVALUE=sGeneralPrefs
            general_flags = sCwform.general
            FOR i=0,N_ELEMENTS(general_flags)-1 DO $
                sGeneralPrefs.(i) = general_flags[i]
            child = WIDGET_INFO(id.top,/CHILD)
            WIDGET_CONTROL,child,GET_UVALUE=wv
            (*wv).prefs.general = sGeneralPrefs
            (*wv).prefs.path = sCwform.path
            (*wv).prefs.oneDstrideFactor = sCwform.oneDstrideFactor > 2
            (*wv).prefs.twoDstrideFactor = sCwform.twoDstrideFactor > 2
            title = (*wv).info.abbrev+': '+(*wv).info.file_name+' (modified)'
            WIDGET_CONTROL,(*wv).id.datatable, $
                GET_UVALUE=uvalue, /NO_COPY
            uvalue.modified = 1     ; set "modified" flag
            WIDGET_CONTROL,(*wv).id.datatable, $
                SET_UVALUE=uvalue, /NO_COPY, $
                TLB_SET_TITLE=title ; add "modified" to title
            WV_MESSAGE,id.top,'Preferences changed'
            WIDGET_CONTROL, Event.top,/DESTROY
            END
        id.cancel: BEGIN ; don't save changes
            WV_MESSAGE,id.top,'Preferences unchanged'
            WIDGET_CONTROL, Event.top,/DESTROY
            END
        id.defaults: BEGIN ; default preferences
            WIDGET_CONTROL,id.prefs, GET_VALUE=sCwform
            default_prefs = WV_DEFAULT_PREFS(1)
            FOR i=0,N_ELEMENTS(sCwform.general)-1 DO $
                sCwform.general[i]=default_prefs.general.(i)
            sCwform = {general:sCwform.general, $
                oneDstrideFactor:STRTRIM(default_prefs.oneDstrideFactor,2), $
                twoDstrideFactor:STRTRIM(default_prefs.twoDstrideFactor,2)}
;           sCwform.oneDstrideFactor = STRING(default_prefs.oneDstrideFactor)
;           sCwform.twoDstrideFactor = STRING(default_prefs.twoDstrideFactor)
            WIDGET_CONTROL, id.prefs, SET_VALUE=sCwform
            END
        ELSE: MESSAGE,'unknown event id'
    ENDCASE
    RETURN
END


;----------------------------------------------------------------
; This Event procedure creates the WV_APPLET Preferences dialog.
PRO wv_file_preferences, Event

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

; since \ is the escape char for CW_FORM, for Windows directories
; we need to "escape" the \ by replacing all \ with \\
    file_path = STRJOIN( $
        STRSPLIT((*wv).prefs.path,'\',/EXTRACT,/PRESERVE_NULL), $
        '\\')

; add separator bars | between button names
    general_str = (*wv).prefs.general_str
    general_prefs = STRING(general_str,FORMAT='(255(A,:,"|"))')
    oneDfactor = STRTRIM((*wv).prefs.oneDstrideFactor,2)
    twoDfactor = STRTRIM((*wv).prefs.twoDstrideFactor,2)

; string array for CW_FORM
    prefs_in = [ $
        '0,LABEL,General,LEFT' $
        ,'1,BASE, ,COLUMN,FRAME' $
        ,'1,BASE, ,ROW' $
        ,'0,TEXT,' + file_path + ' ,TAG=path,WIDTH=30,' + $
            'LABEL_LEFT=Default directory: ' $
        ,'2,BUTTON,Browse,EVENT=wv_change_default_dir_event,TAG=dummy' $
        ,'0,BUTTON,' + general_prefs + ',TAG=general,LABEL_LEFT= ' $
        ,'0,LABEL,Stride factor used when importing data:,LEFT' $
        ,'1,BASE, ,ROW' $
        ,'0,INTEGER,' + oneDfactor + $
            ',LABEL_LEFT=    Vectors: ,TAG=oneDstrideFactor' $
        ,'0,INTEGER,' + twoDfactor + $
            ',LABEL_LEFT=    Arrays: ,TAG=twoDstrideFactor' $
        ]
    id_pref_base = WIDGET_BASE(GROUP_LEADER=Event.top,/MODAL, $
        TITLE='Preferences',/COLUMN, $
        /TLB_KILL_REQUEST_EVENT,TLB_FRAME_ATTR=1)
    id_prefs = CW_FORM(id_pref_base,prefs_in,/COLUMN,IDS=ids)

; change general flags to actual values
    sGeneral = (*wv).prefs.general
    ntags = N_TAGS(sGeneral)
    general_flags = INTARR(ntags)
    FOR i=0,ntags-1 DO general_flags[i] = sGeneral.(i)
    WIDGET_CONTROL,id_prefs,SET_VALUE={GENERAL:general_flags}, $
        SET_UVALUE=sGeneral

; add buttons
    but_base = WIDGET_BASE(id_pref_base,/ALIGN_CENTER,/ROW,/GRID)
    id_defaults = WIDGET_BUTTON(but_base,VALUE='Defaults')
    dummy = WIDGET_LABEL(but_base,VALUE='')
    id_okay   = WIDGET_BUTTON(but_base,VALUE='  OK  ')
    dummy = WIDGET_LABEL(but_base,VALUE='')
    id_cancel = WIDGET_BUTTON(but_base,VALUE='Cancel')

; save widget ID's in UVALUE
    id = {top:Event.top, $
        prefs:id_prefs, $
        directory:ids[3], $
        okay:id_okay, $
        cancel:id_cancel, $
        defaults:id_defaults}
    WIDGET_CONTROL,id_pref_base, $
        DEFAULT_BUTTON=id_okay,CANCEL_BUTTON=id_cancel, $
        EVENT_PRO='wv_file_preferences_event', $
        SET_UVALUE=id,/REALIZE
;   XMANAGER,'wv_file_preferences',id_pref_base;, $;NO_BLOCK=0, $
;       GROUP_LEADER=Event.top
END


;----------------------------------------------------------------
; This Event procedure handles the File->Exit menu item
;   that exits from WV_APPLET.
PRO wv_file_exit, Event

    COMPILE_OPT strictarr, hidden

; Catch errors
;    CATCH,error_status
;    IF (error_status NE 0) THEN BEGIN
;        CATCH,/CANCEL
;        WV_ERROR_HANDLER,Event.top
;        WIDGET_CONTROL,Event.top,/DESTROY
;        RETURN
;    ENDIF

    COMMON cWvAppletData, $
        wCurrentApplet, $   ; widget ID of currently-active Applet
        WaveletFamilies     ; string array of usable wavelet functions

    child = WIDGET_INFO(Event.top,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=wv
    info = (*wv).info
    prefs = (*wv).prefs

; if set in preferences, confirm the exit
    n_active = N_ELEMENTS(wCurrentApplet)
    IF ((prefs.general.confirm_exit) AND (n_active  EQ 1)) THEN BEGIN
        result = DIALOG_MESSAGE(' Exit '+info.title+'? ', $
            DIALOG_PARENT=Event.top,/CANCEL,TITLE='Exit')
        IF (result NE 'OK') THEN RETURN
    ENDIF

;** check if all files saved
    result = WV_SAVE_CHANGES(Event.top)
    IF (result EQ 0) THEN BEGIN
        WV_MESSAGE,Event.top,'Cancelled save.'
        RETURN
    ENDIF

; remove from list of current
    IF (n_active EQ 1) THEN BEGIN
        dummy = TEMPORARY(wCurrentApplet)
        void = CHECK_MATH() ; Silently flush accumulated math errors
        TVLCT,info.color_table
        !P.FONT = info.pfont
    ENDIF ELSE BEGIN
        wCurrentApplet = wCurrentApplet[WHERE(wCurrentApplet NE Event.top)]
    ENDELSE

; destroy heap variables & free up memory
    WIDGET_CONTROL,(*wv).id.datatable,GET_UVALUE=uvalue
    datasets = uvalue.datasets
    WV_DATASET_FREE, datasets
    PTR_FREE, wv

    WIDGET_CONTROL,Event.top,/DESTROY
END ; wv_file_exit


;----------------------------------------------------------------
PRO wv_view_wavelets, Event

    COMPILE_OPT strictarr, hidden
; Catch errors
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        WV_ERROR_HANDLER,Event.top
        RETURN
    ENDIF

    WV_MESSAGE,Event.top,'Starting wavelet viewer'
    WIDGET_CONTROL,/HOURGLASS

    id = WV_CW_WAVELET(GROUP_LEADER=Event.top)
    RETURN
END ; wv_view_wavelets


;----------------------------------------------------------------
PRO wv_plot_data, Event

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

    WIDGET_CONTROL,(*wv).id.draw1,GET_VALUE=draw1
    geom = WIDGET_INFO((*wv).id.draw1,/GEOMETRY)
    WSET,draw1
    !P.MULTI = 0

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

    SWV_DATA_ACCESS,data,x,y, $
        NX=nx,NY=ny, $
        XTITLE=xtitle,YTITLE=ytitle, $
        XUNITS=xunits,YUNITS=yunits, $
        UNITS=units,TITLE=title

    IF (ny LT 1) THEN BEGIN ; time series
        PLOT,x,*data.data, $
            XTITLE=xtitle,YTITLE=title,TITLE=data.title,SYMSIZE=0.5
        RETURN
    ENDIF ; time series

    ERASE
    IF (N_ELEMENTS(*data.colors) GT 0) THEN BEGIN
        TVLCT,r,g,b,/GET
        TVLCT,*data.colors
    ENDIF
    TV,*data.data,(geom.xsize-nx)/2,(geom.ysize-ny)/2, ORDER=0
    IF (N_ELEMENTS(*data.colors) GT 0) THEN TVLCT,r,g,b
;   CONTOUR,*data.data,x,y, $
;       XTITLE=xtitle,YTITLE=ytitle,TITLE=data.title

    RETURN
END ; wv_plot_data


;----------------------------------------------------------------
PRO wv_p3d_wps_event, Event

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

    SWV_DATA_ACCESS,data,X,Y, $
        DATA_OUT=data_out, $
        DX=dx,NX=nx,XSTART=xstart, $
        DY=dy,NY=ny,YSTART=ystart, $
        XTITLE=xtitle,YTITLE=ytitle, $
        XUNITS=xunits,YUNITS=yunits, $
        UNITS=units,TITLE=title

    id = WV_PLOT3D_WPS(data_out,x,y, $
        XTITLE=xtitle,XUNITS=xunits, $
        YTITLE=ytitle,YUNITS=yunits, $
        UNITS=units,TITLE=title, $
        GROUP=Event.top)

    RETURN
END ; wv_p3d_wps_event


;----------------------------------------------------------------
PRO wv_plot_multiresolution, Event

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
    IF PTR_VALID(data.colors) THEN colortable = *data.colors

    SWV_DATA_ACCESS,data,X,Y, $
        DATA_OUT=data_out, $
        DX=dx,NX=nx,XSTART=xstart, $
        DY=dy,NY=ny,YSTART=ystart, $
        XTITLE=xtitle,YTITLE=ytitle, $
        XUNITS=xunits,YUNITS=yunits, $
        UNITS=units,TITLE=title

    id = WV_PLOT_MULTIRES(data_out,x,y, $
        XTITLE=xtitle,XUNITS=xunits, $
        YTITLE=ytitle,YUNITS=yunits, $
        UNITS=units,TITLE=title, $
        COLORTABLE=colortable, $
        GROUP=Event.top)

    RETURN
END ; wv_plot_multiresolution


;----------------------------------------------------------------
PRO wv_tool_event, Event

    COMPILE_OPT strictarr, hidden

; Catch errors
    ioerror = 0
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        CASE (ioerror) OF
            0: WV_ERROR_HANDLER,Event.top
            1: dummy = DIALOG_MESSAGE(!ERROR_STATE.MSG, $
                /ERROR, $
                DIALOG_PARENT=Event.top, $
                TITLE='Tool Error')
        ENDCASE
        RETURN
    ENDIF

; Retrieve state info
    WIDGET_CONTROL,/HOURGLASS
    child = WIDGET_INFO(Event.top,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=wv
    WIDGET_CONTROL,Event.id,GET_VALUE=tool_name
    WIDGET_CONTROL,(*wv).id.datatable,GET_UVALUE=uvalue
    datasets = uvalue.datasets
    IF (N_TAGS(datasets) EQ 0) THEN RETURN  ; no datasets
    n = N_ELEMENTS(datasets)

; Find list of selected datasets
    selected = WIDGET_INFO((*wv).id.datatable,/TABLE_SELECT)
    col_major = (*wv).info.column_major
    bottom = 3 - col_major
    top = 1 - col_major
    selected = INDGEN(selected[bottom]-selected[top]+1) + selected[top]
    if (selected[0] eq -1) or (selected[0] ge n) then begin
        WV_MESSAGE,Event.top,'*** Please select a dataset ***'
        RETURN
    ENDIF
    dataset = datasets[selected[0]]

    tool_name = STRCOMPRESS('WV_TOOL_' + tool_name,/REMOVE_ALL)
    ioerror = 1
    RESOLVE_ROUTINE, tool_name, /IS_FUNCTION, /NO_RECOMPILE
    parameters = ROUTINE_INFO(tool_name,/PARAMETERS,/FUNCTIONS)

    SWV_DATA_ACCESS,dataset,x,y, $
        DATA_OUT=array, $
        XTITLE=xtitle,YTITLE=ytitle, $
        XUNITS=xunits,YUNITS=yunits, $
        UNITS=units,TITLE=title

    extra={GROUP_LEADER:Event.top, $
        XTITLE:xtitle, $
        YTITLE:ytitle, $
        XUNITS:xunits, $
        YUNITS:yunits, $
        UNITS:units, $
        TITLE:title}

; if no arguments, then error message & return
    IF (parameters.num_args EQ 0) THEN MESSAGE, $
        tool_name + " does not accept any arguments."

    IF (parameters.num_kw_args GT 0) THEN BEGIN  ; use keywords
        CASE (parameters.num_args) OF
            1: wTool = CALL_FUNCTION(tool_name,array,_EXTRA=extra)
            2: wTool = CALL_FUNCTION(tool_name,array,x,_EXTRA=extra)
            3: wTool = CALL_FUNCTION(tool_name,array,x,y,_EXTRA=extra)
        ENDCASE
    ENDIF ELSE BEGIN  ; don't use any keywords
        CASE (parameters.num_args) OF
            1: wTool = CALL_FUNCTION(tool_name,array)
            2: wTool = CALL_FUNCTION(tool_name,array,x)
            3: wTool = CALL_FUNCTION(tool_name,array,x,y)
        ENDCASE
    ENDELSE

    RETURN
END ; wv_tool_event


;----------------------------------------------------------------
PRO wv_help_idlhelp, Event
    COMPILE_OPT strictarr, hidden
; Catch errors
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        WV_ERROR_HANDLER,Event.top
        RETURN
    ENDIF

    ONLINE_HELP
    RETURN
END ; wv_help_idlhelp


;----------------------------------------------------------------
PRO wv_help_help, Event

    COMPILE_OPT strictarr, hidden
; Catch errors
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        WV_ERROR_HANDLER,Event.top
        RETURN
    ENDIF

    ONLINE_HELP, 'Introduction_to_the_IDL_Wavelet_Toolkit'

END ; wv_help_help


;----------------------------------------------------------------
PRO wv_help_readme, Event

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
    file = FILEPATH('README*', $
        ROOT_DIR=(*wv).info.tool_path)
    file = (FILE_SEARCH(file))[0]
    XDISPLAYFILE,file, $
        DONE_BUTTON='Close', $
        GROUP=Event.top, $
        TITLE=(*wv).info.abbrev+' Readme'
    RETURN
END ; wv_help_readme


;----------------------------------------------------------------
PRO wv_help_release, Event

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
    file = FILEPATH('rel*', $
        ROOT_DIR=(*wv).info.tool_path)
    file = (FILE_SEARCH(file))[0]
    XDISPLAYFILE,file, $
        DONE_BUTTON='Close', $
        GROUP=Event.top, $
        TITLE=(*wv).info.abbrev+' Release Notes'
    RETURN
END ; wv_help_release


;----------------------------------------------------------------
PRO wv_help_about, Event

    COMPILE_OPT strictarr, hidden
; Catch errors
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        WV_ERROR_HANDLER,Event.top
        RETURN
    ENDIF

    child = WIDGET_INFO(Event.top,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=wv
    title = (*wv).info.title + ' Version ' + (*wv).info.version
    version = !VERSION.RELEASE + ' [' + !VERSION.OS + ']'
    about = [title,'', $
        'IDL Version '+version,'', $
        (*wv).info.copyright]
    result = DIALOG_MESSAGE(about,DIALOG_PARENT=Event.top, $
        TITLE='About '+(*wv).info.title,/INFORMATION)
    RETURN
END ; wv_help_about


;----------------------------------------------------------------
PRO wv_applet_event, Event

    COMPILE_OPT strictarr, hidden

    COMMON cWvAppletData, $
        wCurrentApplet, $   ; widget ID of currently-active Applet
        WaveletFamilies     ; string array of usable wavelet functions

; Catch errors
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        WV_ERROR_HANDLER,Event.top
        RETURN
    ENDIF

    child = WIDGET_INFO(Event.top,/CHILD)
    WIDGET_CONTROL,child,GET_UVALUE=wv

    CASE (TAG_NAMES(Event,/STRUCTURE_NAME)) OF
        'WIDGET_KBRD_FOCUS': BEGIN
            oldID = wCurrentApplet[0]
            position = WHERE(wCurrentApplet EQ Event.top)
            wCurrentApplet[0] = Event.top
            wCurrentApplet[position] = oldID
            RETURN
            END
        'WIDGET_KILL_REQUEST': BEGIN
            id_exit = (*wv).id.menu.File_Exit
            WIDGET_CONTROL,id_exit,SEND_EVENT={id:id_exit, $
                top:Event.top,handler:Event.top}
            RETURN
            END
        'WIDGET_BASE': BEGIN
            IF (*wv).info.no_resize_event THEN BEGIN
                (*wv).info.no_resize_event = 0
                RETURN
            ENDIF
            WIDGET_CONTROL,Event.id,UPDATE=0
            ; new TLB size
            WIDGET_CONTROL, Event.top, TLB_GET_SIZE=new_base_size
            change_size = new_base_size - (*wv).info.base_size
            wDatatable = (*wv).id.datatable
            geom = WIDGET_INFO(wDatatable,/GEOMETRY)
            old_xsize = geom.scr_xsize
            old_ysize = geom.scr_ysize
            old_size = [old_xsize,old_ysize]
            new_size = (old_size + change_size) > (*wv).info.min_base_size
            WIDGET_CONTROL,(*wv).id.message,SCR_XSIZE=new_size[0]
            WIDGET_CONTROL,wDatatable,SCR_XSIZE=new_size[0],SCR_YSIZE=new_size[1]
            WIDGET_CONTROL,Event.id,/UPDATE
            WIDGET_CONTROL,Event.top,TLB_GET_SIZE=new_base_size
            (*wv).info.base_size = new_base_size
            WV_MESSAGE,Event.top,'Ready'
            RETURN
            END
        ELSE:
    ENDCASE

;   CASE (Event.id) OF
;       (*wv).id.choosedata: BEGIN
;           (*wv).info.dataset = Event.index
;           WV_MESSAGE,Event.top,''
;           END
;       ELSE: 'unknown event'
;   ENDCASE
    RETURN
END ; wv_applet_event


;*****************************************************************************
; Main routine starts here
;*****************************************************************************


;----------------------------------------------------------------
PRO wv_applet, inputData, $  ; optional string for input file
    ARRAY=array, $          ; vector or array input data
    GROUP_LEADER=wGroup, $  ; widget ID
    NO_SPLASH=no_splash, $  ; if set then no splash
    TOOLS=tools, $          ; string array of user-defined tool names
    WAVELETS=wavelets       ; string array of user-defined wavelets

    COMPILE_OPT strictarr   ; array indexing must use [ ] not ( )

    COMMON cWvAppletData, $
        wCurrentApplet, $   ; widget ID of currently-active Applet
        WaveletFamilies     ; string array of usable wavelet functions

    ON_ERROR, 2   ; return to caller if error occurs

    info = WV_INFORMATION('wv_applet') ; Get WV_APPLET info

; Attempt to change the device if necessary
    widgets = 2L^16  ; bit flag for "device supports widgets"
    IF ((!D.FLAGS AND widgets) NE widgets) THEN BEGIN
        CASE (!VERSION.OS_FAMILY) OF
            'Windows': name = 'Win'  ; device name
            'MacOS':   name = 'Mac'  ; device name
            ELSE:      name = 'X'    ; device name
        ENDCASE
        PRINT,' Changing device from "' + !D.NAME + '" to "' + name + '"...'
        SET_PLOT, name
    ENDIF

; If still no good, then exit
    IF ((!D.FLAGS AND widgets) NE widgets) THEN MESSAGE, $
        '  The current graphics device does not support widgets.'

; Catch other errors, we can use WV_ERROR_HANDLER since widgets supported
    CATCH,/CANCEL
    CATCH,error_status
    IF (error_status NE 0) THEN BEGIN
        CATCH,/CANCEL
        WV_ERROR_HANDLER, $
            EXTRA=info.title + ' ' + info.version, $
            INFO=info,NO_BUG=no_bug
        IF (N_ELEMENTS(wBase) EQ 1) THEN $
            IF WIDGET_INFO(wBase,/VALID) THEN WIDGET_CONTROL,wBase,/DESTROY
        RETURN
    ENDIF

    DEVICE, $
        BYPASS_TRANSLATION=0, $  ; use color translation tables (X only)
        DECOMPOSED=0  ; use pseudocolor (8-bit) only

;Get current color table. It will be restored when exiting.
    TVLCT, r, g, b, /GET
    color_table = [[r],[g],[b]]

; add more information to "info" structure
    info = CREATE_STRUCT(info, $
        'pfont',!P.FONT, $ ; save this for exit
        'color_table',color_table)


    DEVICE, GET_SCREEN_SIZE=screen_size
    screenXsize = LONG(0.6*screen_size[0])
    screenYsize = LONG(0.4*screen_size[1])

; Start of main widget code...
    title = info.abbrev + ': ' + info.file_name
    wBase = WIDGET_BASE( $
        GROUP_LEADER=wGroup, $
        /KBRD_FOCUS_EVENTS, $
        MAP=0, $
        MBAR=id_menubar, $
        TITLE=title, $
        /TLB_KILL_REQUEST_EVENT, $
        /TLB_SIZE_EVENTS)
    WIDGET_CONTROL,/HOURGLASS


; store widget ID in common variable
    nApp = N_ELEMENTS(wCurrentApplet)
    IF (nApp GT 0) THEN old_applet = wCurrentApplet
    wCurrentApplet = wBase
    FOR i=0,nApp-1 DO BEGIN
        IF WIDGET_INFO(old_applet[i],/VALID) THEN BEGIN
            wCurrentApplet = [wCurrentApplet,old_applet[i]]
            IF (i EQ 0) THEN BEGIN
                WIDGET_CONTROL,old_applet[0], $
                    TLB_GET_OFFSET=tlb_get_offset
                xoffset = tlb_get_offset[0] + 20
                yoffset = tlb_get_offset[1] + 20
            ENDIF
        ENDIF
    ENDFOR


; startup splash screen, if desired
    no_splash = KEYWORD_SET(no_splash)
    IF (NOT no_splash) THEN BEGIN
        splash_file = FILEPATH('splash.png', $
            ROOT_DIR=info.tool_path,SUBDIR=['bitmaps'])
        splash_image = READ_PNG(splash_file,red,green,blue)
        splash_size = (SIZE(splash_image))[1:2]
        splash = WIDGET_BASE(FRAME=0, $
            /FLOATING, $
            GROUP_LEADER=wBase, $
            /MODAL, $
;           SCR_XSIZE=1,YSIZE=1, $
            TITLE=info.title, $
            TLB_FRAME_ATTR=31)
        splash_draw = WIDGET_DRAW(splash, $
            FRAME=0, $
            RETAIN=2, $
            XSIZE=splash_size[0],YSIZE=splash_size[1])
        WIDGET_CONTROL,splash_draw, $
            TLB_SET_XOFFSET=((screen_size[0]-splash_size[0])/2) > 0, $
            TLB_SET_YOFFSET=((screen_size[1]-splash_size[1])/2) > 0
        WIDGET_CONTROL,splash,/REALIZE
;       WIDGET_CONTROL,wBase,UPDATE=0
        WIDGET_CONTROL,splash_draw,GET_VALUE=win_num
        TVLCT,red,green,blue
        WSET,win_num
        time_splash = SYSTIME(1)
        TV,splash_image, ORDER=0 ; draw the splash image
    ENDIF
;   WIDGET_CONTROL,wBase,UPDATE=0


; Check for valid Wavelet license
; Don't bother modifying these lines as WV_DWT and WV_PWT will not work.
    IF (NOT LMGR('idl_wavelet', VERSION='1.0')) THEN BEGIN
        no_bug = 1L
        MESSAGE, /NONAME, $
            'You do not have a valid IDL Wavelet Toolkit license.'
    ENDIF


; set X & Y offset
    IF (N_ELEMENTS(xoffset) LT 1) THEN $
    xoffset=((screen_size[0]-screenXsize)/3) > 0
    IF (N_ELEMENTS(yoffset) LT 1) THEN $
    yoffset=((screen_size[1]-screenYsize)/4) > 0
    WIDGET_CONTROL,wBase, $
        TLB_SET_XOFFSET=xoffset, $
        TLB_SET_YOFFSET=yoffset

; insert User Tool functions
    all_tools = ['Denoise']
;       'Global spectrum', $
;       'Anisotropy', $
;       'Ridge extraction', $
;       'Edge detection', $
;       'Wavelet packets', $
;       'Wavelet coherency', $
    n_user = N_ELEMENTS(tools)
    n_built_in = N_ELEMENTS(all_tools)
    n_tools = n_built_in + n_user
    flags = INTARR(n_tools)    ; menu flags for CW_PDMENU
    IF (n_user GE 1) THEN BEGIN
        all_tools = [all_tools,tools]
        flags[n_built_in] = 4  ; add separator line before User tools
    ENDIF ELSE tools = ''
    flags[n_tools-1] = flags[n_tools-1] + 2  ; end of Tool menu items

; construct Tool array items for menu list
    tool_array = STRARR(3,n_tools)
    tool_array[0,*] = STRTRIM(flags,2) + '\' + all_tools + '\wv_Tool_Event'

; string array for menu items
; each item has:  ['CW_PDMENU string', 'Tooltip help', 'bitmap.bmp']
    menu_list = [ $
        ['1\&File','',''], $
            ['0\&New Applet\wv_File_New', $
                'New Applet','new_wv.bmp'], $
            ['4\&Open Dataset...\wv_File_Open', $
                'Open Dataset','open_wv.bmp'], $
            ['0\&Save\wv_File_Save', $
                'Save Dataset','save_wv.bmp'], $
            ['0\Save &As...\wv_File_SaveAs','',''], $
            ['5\&Import...','',''], $
                ['0\&ASCII File\wv_File_Import_ASCII', $
                    'Import ASCII File','imp_asc.bmp'], $
                ['0\&Binary File\wv_File_Import_Binary', $
                    'Import Binary File','imp_bin.bmp'], $
                ['0\&Image File\wv_File_Import_Image', $
                    'Import Image File','imp_img.bmp'], $
                ['2\&WAV Audio File\wv_File_Import_WAV', $
                    'Import WAV File','imp_wav.bmp'], $
            ['4\&Preferences...\wv_File_Preferences','',''], $
            ['6\E&xit\wv_File_Exit','',''], $
        ['1\&Edit','',''], $
            ['0\Move Variable &Left\wv_data_moveup', $
                'Move Variable Left','moveup.bmp'], $
            ['0\Move Variable &Right\wv_data_movedown', $
                'Move Variable Right','movedown.bmp'], $
            ['0\&View Data Values\wv_data_view', $
                'View Data Values','viewdata.bmp'], $
            ['2\&Delete Variable\wv_data_delete', $
                'Delete Selected Variable','del_data.bmp'], $
        ['1\&Visualize','',''], $
            ['0\Wavelet &Functions\wv_View_Wavelets', $
                'View Wavelet Functions','viewwvlt.bmp'], $
            ['0\Wavelet &Power Spectrum\wv_P3d_WPS_event', $
                '3D Wavelet Power Spectrum','plot_3d.bmp'], $
            ['2\&Multiresolution Analysis\wv_Plot_Multiresolution', $
                'Multiresolution Analysis','multires.bmp'], $
        ['1\&Tools','',''], $
            [tool_array], $
        ['1\&Help','',''], $
            ['0\&IDL Help\wv_Help_IDLHelp','',''], $
            ['0\'+info.title+' &Help\wv_Help_Help', $
                'Help','help_wv.bmp'], $
            ['4\'+info.abbrev+' &Readme\wv_Help_Readme','',''], $
            ['0\'+info.abbrev+' Release &Notes\wv_Help_Release','',''], $
            ['6\&About '+info.title+'...\wv_Help_About','',''] ]

    menu_items = REFORM(menu_list[0,*])
    menu_tooltips = REFORM(menu_list[1,*])
    menu_bitmaps = REFORM(menu_list[2,*])

; if not Windows, then remove '&' menu shortcuts
    IF (STRLOWCASE(!VERSION.OS_FAMILY) NE 'windows') THEN BEGIN
        FOR i=0,N_ELEMENTS(menu_items)-1 DO menu_items[i] = $
            STRSPLIT(menu_items[i],'***',ESCAPE='&',/EXTRACT)
    ENDIF



    FloatMotif = (WIDGET_INFO()).style EQ 'Motif'


; construct pulldown menu
    pdmenu = CW_PDMENU(id_menubar,menu_items,/MBAR,/HELP,IDS=menu_ids)

    wBaseCol = WIDGET_BASE(wBase, /COLUMN, SPACE=3)
    id_row = WIDGET_BASE(wBaseCol, /ROW, $
        /BASE_ALIGN_CENTER, $
        FRAME=1-FloatMotif, $
        SPACE=1)
; save ID's of menu as:   id.menu.File_Save
; also create buttons & save ID's as:   id.button.File_save
    menu = {base:pdmenu}
    button = {base:id_row}

    FOR i=0,N_ELEMENTS(menu_items)-1 DO BEGIN
        menu_split = STRSPLIT(menu_items[i],'\',/EXTRACT)
        menu_name = ''
        IF (N_ELEMENTS(menu_split) GE 3) THEN menu_name=menu_split[2]
        IF ((menu_name NE '') AND (menu_name NE 'wv_Tool_Event')) THEN BEGIN
            menu_name1 = STRMID(menu_name,3,255)   ; strip off 'wv_'
            menu = CREATE_STRUCT(menu,menu_name1,menu_ids[i])  ; save ID
        ENDIF
        IF (menu_bitmaps[i] NE '') THEN BEGIN
            IF ((menu_name EQ 'wv_File_Import_ASCII') OR $
                (menu_name EQ 'wv_View_Wavelets') OR $
                (menu_name EQ 'wv_data_moveup') OR $
                (menu_name EQ 'wv_Help_Help')) THEN BEGIN
                dummy = WIDGET_BASE(id_row,XSIZE=10)  ; add extra space
            ENDIF
            base=WIDGET_BASE(id_row,/ROW, $
                EVENT_PRO=menu_name, $
                FRAME=0,SPACE=0,XPAD=0,YPAD=0)
            button_file = FILEPATH(menu_bitmaps[i], $
                ROOT_DIR=info.tool_path,SUBDIR=['bitmaps'])
            butt = WIDGET_BUTTON(base,/BITMAP,VALUE=button_file, $
                /ALIGN_CENTER, $
                TOOLTIP=menu_tooltips[i])
            button = CREATE_STRUCT(button,menu_name1,butt)
        ENDIF
    ENDFOR

; map the base to find the minimum widget size for the tool bar
;   WIDGET_CONTROL,wBase,/MAP
    geom_toolbar = WIDGET_INFO(id_row,/GEOMETRY)
    min_base_size = [geom_toolbar.xsize,geom_toolbar.ysize]
    min_base_size = min_base_size > [128,64]  ; Macintosh minimum scroll size

; Set up default preferences, datasets, and wavelets
    default_prefs = WV_DEFAULT_PREFS(1)
    WV_IMPORT_WAVELET,wavelets, $
        RESET=(N_ELEMENTS(WaveletFamilies) EQ 0)

    wDatatable = WV_CW_DATATABLE(wBaseCol, $
        COLUMN_MAJOR=info.column_major)


; message bar widget
    id_message = WIDGET_TEXT(wBaseCol,  $
        VALUE='Ready',/ALIGN_LEFT)

;*** save widget ID's into a structure
    id = { $
        base:wBase, $
        view_dataset:0L, $ ; used for View window if open
        message:id_message, $
        datatable:wDatatable, $
        menu:menu, $
        button:button, $
        wavelet:0L $
        }

; Set up graphics & system variables
    !P.FONT = 1
    !P.CHARSIZE = 1
    !P.MULTI = 0
; the following device line cannot be executed without the splash screen,
; otherwise it throws up a graphics window.
    IF (NOT no_splash) THEN $
        DEVICE, FONT='Helvetica', /TT_FONT, SET_CHARACTER_SIZE=[10,12]

;*** REALIZE the top base
    WIDGET_CONTROL,wBase, /MAP, /REALIZE
;   WIDGET_CONTROL,wBase,/UPDATE
    IF (N_ELEMENTS(splash) EQ 1) THEN $
        IF WIDGET_INFO(splash,/VALID) THEN WIDGET_CONTROL,splash,/SHOW

; fix the table column widths
    column_widths = WIDGET_INFO(wDatatable,/COLUMN_WIDTHS)
    width = column_widths[0]
    CASE (info.column_major) OF
    0: BEGIN
        column_widths[*] = 0.75*width
        column_widths[[0,1,2,num_columns-2,num_columns-1]] = $
            [1.25,2,1.25,3,3]*width
        END
    1: column_widths = 2*width
    ENDCASE
    WIDGET_CONTROL,wDatatable,COLUMN_WIDTHS=column_widths

; fix the table size so Y scroll bar isn't cut in half (this is a kludge)
    geom = WIDGET_INFO(wDatatable,/GEOMETRY)
;   WIDGET_CONTROL,wDatatable, $
;       SCR_XSIZE=geom.scr_xsize, $
;       SCR_YSIZE=geom.scr_ysize
    WIDGET_CONTROL,id_message,SCR_XSIZE=geom.scr_xsize
    WIDGET_CONTROL,wBase,TLB_GET_SIZE=tlb_size

; add more information to "info" structure
    info = CREATE_STRUCT(info, $
        'no_resize_event',(!VERSION.os_family EQ 'Windows'), $
        'min_base_size',min_base_size, $
        'base_size',tlb_size, $
        'tools',tools)

    wv = PTR_NEW({ $
        id:id, $
        info:info, $
        prefs:default_prefs})

; save the WV variable into the base child uvalue
    child = WIDGET_INFO(id.base,/CHILD)
    WIDGET_CONTROL,child,SET_UVALUE=wv

; check input parameters for files & data
    tname = SIZE(inputData,/TNAME)
    CASE tname OF
        'UNDEFINED': ; do nothing
        'STRING': filename = inputData
        ELSE: array = inputData
    ENDCASE
    import_array = (N_ELEMENTS(array) GT 0)

; set filename to "example" if no filename or input array
    example = 0
    IF ((N_ELEMENTS(filename) EQ 0) AND (NOT import_array)) THEN BEGIN
        filename = FILEPATH(info.example_file,ROOT=info.example_path)
        example = 1
    ENDIF
    IF (N_ELEMENTS(filename) EQ 0) THEN filename = ''

; open starting save file, if desired
    WIDGET_CONTROL,(*wv).id.datatable,SET_VALUE=[' ']
    IF (filename NE '') THEN BEGIN  ; open file
        WV_FILE_OPEN,{id:(*wv).id.menu.File_Open,top:wBase,handler:wBase}, $
            FILE=filename,EXAMPLE=example
    ENDIF

; if desired, add input array to datasets
    IF (import_array) THEN WV_IMPORT_DATA,TEMPORARY(array),PARENT=wBase

; make sure splash is up for at least 1.5 seconds, then destroy
    IF (N_ELEMENTS(splash) EQ 1) THEN BEGIN
        time_wait = 1.5 - (SYSTIME(1)-time_splash)
        IF (time_wait GT 0) THEN WAIT,time_wait > 0
        IF WIDGET_INFO(splash,/VALID) THEN WIDGET_CONTROL,splash,/DESTROY
        TVLCT, color_table
    ENDIF
    XMANAGER, 'wv_applet',wBase,NO_BLOCK=1

END ; wv_applet

