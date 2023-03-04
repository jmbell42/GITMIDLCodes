; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/framework/idlitopfilesave__define.pro#1 $
;
; Copyright (c) 2003-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the generic IDL Tool object that
;   implements the actions performed when a file is saved.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the object.
;
; Arguments:
;   None.
;
; Keywords:
;   All superclass keywords.
;
function IDLitopFileSave::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Default is to not show the File Selection dialog,
    ; so set SHOW_EXECUTION_UI to zero.
    if(self->IDLitOperation::Init(SHOW_EXECUTION_UI=0, $
        _EXTRA=_extra) eq 0)then $
      return, 0

    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    self->RegisterProperty, 'FILENAME', /STRING, $
        NAME='Filename', $
        Description='Name of the saved file'

    self._fileName = 'untitled'

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitopFileSave::SetProperty, _EXTRA=_extra

    return, 1
end


;-------------------------------------------------------------------------
; Purpose:
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to ::Init followed by the word Get.
;
pro IDLitopFileSave::GetProperty, $
    FILENAME=fileName, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(fileName)) then $
        fileName = self._fileName

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end


;-------------------------------------------------------------------------
; Purpose:
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to ::Init followed by the word Set.
;
pro IDLitopFileSave::SetProperty, $
    FILENAME=fileName, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(fileName) gt 0 ) then $
        self._fileName = fileName

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
; IDLitopFileSave::_Save
;
; Purpose:
;   Used to save the iTool state.
;
; Parameters:
;   oTool   - The tool we are operating in.
;
; Return Value
;   Success (1), Failure (0), or Cancel (-1).
;
function IDLitopFileSave::_Save, oTool

    compile_opt idl2, hidden

    if (LMGR(/DEMO)) then begin
        self->ErrorMessage, $
            [IDLitLangCatQuery('Error:Framework:SaveDisabledDemo')], severity=2
        return, 0
    endif

    ; Do we have our File Writer service?
    oWriteFile = oTool->GetService("WRITE_FILE")
    if(not obj_valid(oWriteFile))then begin
        self->ErrorMessage, $
            [IDLitLangCatQuery('Error:Framework:CannotAccessWriterService')], $
            title=IDLitLangCatQuery('Error:InternalError:Title'), severity=2
        return, 0
    endif

    self->IDLitOperation::GetProperty, SHOW_EXECUTION_UI=showUI

    badName = (self._filename eq '') || $
        STRCMP(self._filename, 'untitled', 8, /FOLD_CASE)

    ; If we don't have a valid name, see if the Tool does.
    if (badName) then begin
        oTool->GetProperty, TOOL_FILENAME=filename
        self._filename = filename
    endif

    badName = (self._filename eq '') || $
        STRCMP(self._filename, 'untitled', 8, /FOLD_CASE)

    if (showUI || badName) then begin

        ; Ask the UI service to present the file selection dialog to the user.
        ; The caller sets my filename property before returning.
        ; This should also call my GetFilterList().
        success = oTool->DoUIService('FileSaveAs', self)

        if (success eq 0) then $
            return, -1  ; cancel

    endif

    ; check our filename cache
    if (self._fileName eq '') then $
        return, -1  ; cancel

    ; oTool is the tool to save.
    status = oWriteFile->WriteFile(self._fileName, oTool)

    if (status ne 1) then begin
        self->ErrorMessage, /USE_LAST_ERROR, $
          title=IDLitLangCatQuery('Error:InternalError:Title'), severity=2, $
          [IDLitLangCatQuery('Error:Framework:FileWriteError'), $
          self._fileName]
        return, 0
    endif

    ; Change my tool filename.
    oTool->SetProperty, TOOL_FILENAME=self._fileName

    return, 1 ; success

end


;---------------------------------------------------------------------------
; IDLitopFileSave::DoAction
;
; Purpose:
;   Used to save the iTool state.
;
; Parameters:
;   oTool   - The tool we are operating in.
;
; Return Value
;   Null object (not undoable).
;
; Keywords:
;   SUCCESS (1), Failure (0), or Cancel (-1).
;
function IDLitopFileSave::DoAction, oTool, SUCCESS=success

    compile_opt idl2, hidden

    success = self->_Save(oTool)

    if (success eq 1) then begin
        ; Be sure our File/Save and File/SaveAs are in sync.
        oDesc = oTool->GetByIdentifier('Operations/File/SaveAs')
        if (OBJ_VALID(oDesc)) then $
            oDesc->SetProperty, FILENAME=self._filename
    endif

    return, OBJ_NEW()  ; not undoable

end


;---------------------------------------------------------------------------
; Purpose:
;   Basically for the UI service to provide a callback to this
;   object.
;
function IDLitopFileSave::GetFilterList, COUNT=COUNT

   compile_opt idl2, hidden

   oTool = self->GetTool()
   oWriteFile = oTool->GetService("WRITE_FILE")
   if(not obj_valid(oWriteFile))then begin
       count = 0
       return,''
   endif

   return, oWriteFile->GetFilterListByType('IDLISV', COUNT=count)

end


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; Purpose:
;   Class definition.
;
pro IDLitopFileSave__define

    compile_opt idl2, hidden

    struc = {IDLitopFileSave, $
        inherits IDLitOperation, $
        _fileName: ''  $
        }

end

