; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/ui_widgets/idlituifilesaveas.pro#1 $
; Copyright (c) 2003-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;
; Purpose:
;   This function implements the user interface for file selection
;   for the IDL Tool. The Result is a success flag, either 0 or 1.
;
; Syntax:
;   Result = IDLitUIFileSaveAs(UI, Requester)
;
; Arguments:
;   UI: UI object that is calling this function.
;   Requester: The object reference for the operation requesting this UI.
;
; Keywords:
;   None.
;
; Written by:  CT, RSI, March 2003
; Modified:
;

;-------------------------------------------------------------------------
function IDLitUIFileSaveAs, oUI, oRequester

    compile_opt idl2, hidden

    ; Retrieve widget ID of top-level base.
    oUI->GetProperty, GROUP_LEADER=groupLeader

    ; Retrieve working directory.
    oTool = oUI->GetTool()
    if (OBJ_VALID(oTool)) then begin
        oTool->GetProperty, $
            CHANGE_DIRECTORY=changeDirectory, $
            WORKING_DIRECTORY=workingDirectory
    endif

    oRequester->GetProperty, FILENAME=initialFilename
    filter = oRequester->GetFilterList(COUNT=count)
    if (count eq 0) then $
        return, 0

    ; On Motif, the filters cannot have spaces between them.
    filter[*,0] = STRCOMPRESS(filter[*,0], /REMOVE_ALL)

    if (N_ELEMENTS(filter[*,0]) eq 1) then begin
        pos = STRPOS(filter[*,0], '.')
        if (pos ge 0) then $
            defaultExtension = STRMID(filter[*,0], pos+1, 3)
    endif

    filename = DIALOG_PICKFILE( $
        DEFAULT_EXTENSION=defaultExtension, $
        DIALOG_PARENT=groupLeader, $
        FILE=initialFilename, $
        FILTER=filter, $
        /OVERWRITE_PROMPT, $
        GET_PATH=newDirectory, $
        PATH=workingDirectory, $
        TITLE=IDLitLangCatQuery('UI:UISaveAs:Title'), $
        /WRITE)

    WIDGET_CONTROL, /HOURGLASS

    ; User hit cancel?
    if (filename eq '') then $
        return, 0

    oRequester->SetProperty, FILENAME=filename

    ; Set the new working directory if change_directory is enabled.
    if (OBJ_VALID(oTool) && KEYWORD_SET(changeDirectory)) then $
        oTool->SetProperty, WORKING_DIRECTORY=newDirectory

    return, 1
end

