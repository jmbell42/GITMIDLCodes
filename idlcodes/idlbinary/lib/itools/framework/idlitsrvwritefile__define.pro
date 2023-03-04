; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/framework/idlitsrvwritefile__define.pro#1 $
;
; Copyright (c) 2003-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDL Tool service for file writing.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the IDLitsrvWriteFile object.
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords to superclass.
;
function IDLitsrvWriteFile::Init, _EXTRA=_SUPER

    compile_opt idl2, hidden

    if(self->_IDLitsrvReadWrite::Init(_EXTRA=_SUPER) eq 0)then $
      return, 0

    return, 1
end


;-------------------------------------------------------------------------
; Purpose:
;   The destructor of the IDLitsrvWriteFile object.
;
; Arguments:
;   None.
;
;pro IDLitsrvWriteFile::Cleanup
;    compile_opt idl2, hidden
;    self->_IDLitsrvReadWrite::Cleanup
;end

;---------------------------------------------------------------------------
;; IDLitsrvWriteFile::_FindWritersByType
;;
;; Purpose:
;;   Retrieve a list of writers using their type
;;
;; Parameters:
;;  Type  - the type(s) to match
;;
;;  oDesc - The descriptor list
;;
;;  count  - The number of returned items.
function IDLitsrvWriteFile::_FindWritersByType, types, oDesc, count=count
   compile_opt hidden, idl2

   count=0

   nt = N_ELEMENTS(types)

   ; just loop and do a type match check
   for i=0, n_elements(oDesc)-1 do begin
        oDesc[i]->GetProperty, TYPE=objType
        ; Always allow a null type.
        if (objType[0] ne '') then begin
            for j=0,nt-1 do begin
                ; Found a match. Stop looking.
                if (MAX(STRCMP(objType, types[j], /FOLD_CASE)) eq 1) then $
                    break
            endfor
            ; Didn't find a match?
            if (j eq nt) then $
                continue
        endif

        ; Add to list
        oWriters = (count eq 0 ? oDesc[i] : [oWriters, oDesc[i]])
        count++

   endfor

   return, count gt 0 ? oWriters : obj_new()

end


;;---------------------------------------------------------------------------
;; IDLitsrvWriteFile::GetWritersByType
;;
;; Purpose:
;;   Return the ids of writers given a specific type.
;;
;; Parameters:
;;   type - The type to check against
;;
;; Keywords:
;;   count  - the number of ids returned.
;;
;; Return Value:
;;   identifiers fo writes that match the given type.
;;
function IDLitsrvWriteFile::GetWritersByType, type, count=count
   compile_opt hidden, idl2
   oTool = self->GetTool()

   oDesc = oTool->GetFileWriter(count=count,/all)
   if(count eq 0)then $
     return, ''
   oDesc = self->_FindWritersByType(type, oDesc, count=count)
   if(count eq 0)then $
     return, ''

   idRet = strarr(count)
   for i=0, count-1 do $
     idRet[i] = oDesc[i]->GetFullIdentifier()

   return, idRet
end

;;---------------------------------------------------------------------------
;; IDLitsrvWriteFile::_GetDescriptors
;;
;; Purpose:
;;    Return the list of descriptors to the  callee for the specified
;;    writers. This is used by the super-class to peform various
;;    actions.
;;
;; parameters:
;;    None.
;;
;; Keywords:
;;   COUNT  - Return the number of items returned.
;;
;;   SYSTEM - Include the system file formats.
;;
function IDLitsrvWriteFile::_GetDescriptors, system=system, count=count
   compile_opt hidden, idl2

   ;; Get all the writers
   oTool = self->GetTool()
   oDesc = oTool->GetFileWriter( count=count, /all)
   iMatch =-1
   if(~keyword_set(system))then begin
       ;; we need to take out the system writer
       for i=0, count-1 do begin
           oWriter = oDesc[i]->GetObjectInstance()
           tmpExt = oWriter->GetFileExtensions(count=nEXT)
           oDesc[i]->ReturnObjectInstance, oWriter
           if(strcmp(tmpExt[0], "isv", /fold_case) eq 1)then begin
               iMatch = i
               break
           endif
       endfor
       if(iMatch gt -1)then begin
           dex = where(indgen(count) ne iMatch, count)
           if(count gt 0)then $
             oDesc = oDesc[dex] $
           else oDesc = obj_new()
       endif
   endif
   return, oDesc
end

;-------------------------------------------------------------------------
; IDLitsrvWriteFile::GetFilterListByType
;
; Purpose:
;  Return an array of the file extensions that support
;  the given data type
;
; Result:
;   String array of extensions
;
; Arguments:
;   Type  - the data type to match
;
; Keywords:
;   COUNT   - The number of extensions returned.
;
function IDLitsrvWriteFile::GetFilterListByType, type, COUNT=COUNT

    compile_opt idl2, hidden

    oTool = self->GetTool()

    oWriterDesc = oTool->GetFileWriter( count=nWriters, /all)
    oWriterDesc = self->_FindWritersByType(type, oWriterDesc, count=nWriters)

    if(nWriters gt 0)then $
        self->BuildExtensions, oWriterDesc, sExten, sFilter, sID

    sFilter[*,1] += ' (' + sFilter[*,0] + ')'

    count = N_ELEMENTS(sFilter)/2

    return, sFilter
end


;---------------------------------------------------------------------------
; Purpose:
;  Given a filename, will return the identifier of writers capable of
;  handling the given file.
;
;  First this system searches file extensions. If that fails, query
;  routines are used.
;
; Arguments:
;   strFile   - The filename to test
;
; Keywords:
;   None.
;
function IDLitsrvWriteFile::FindMatchingWriter, strFile

    compile_opt idl2, hidden

    filename = strtrim(strFile,2)
    if (filename eq '') then $
        return, '' ; invalid

    ; Check extensions
    iDot = STRPOS(filename, '.', /REVERSE_SEARCH)
    if (iDot gt 0) then begin
        oDesc = self->_GetDescriptors(/SYSTEM, COUNT=count)
        if (count gt 0) then begin
            self->BuildExtensions, oDesc, fileExt, sFilterList, sIDs
            count = N_ELEMENTS(fileExt)
        endif
        if (count gt 0) then begin
            fileSuffix = STRUPCASE(STRMID(filename, iDot + 1))
            dex = where(fileSuffix eq strupcase(fileExt), nMatch)
            return, (nMatch gt 0 ? sIDs[dex[0]] : '')
        endif
    endif

    return, ''

end


;---------------------------------------------------------------------------
; Purpose:
;  Write the output to the given file.
;
; Arguments:
;   strFile: The filename to write
;
;   oData: The data to write.
;
function IDLitsrvWriteFile::WriteFile, strFile, oItem, $
    SCALE_FACTOR=scaleFactor, $
    WRITER=idWriter

    compile_opt idl2, hidden

@idlit_catch
    if(iErr ne 0)then begin
        catch, /cancel
        self->SignalError, $
          [IDLitLangCatQuery('Error:Framework:ErrorWritingFile'), !error_state.msg], severity=2
        return, 0
    endif

    ; Have we been provided a writer? If not, find a match.
    if(not keyword_set(idWriter))then $
        idWriter = self->FindMatchingWriter(strFile)

    if(strtrim(idWriter,2) eq '')then begin
        self->SignalError, $
            [IDLitLangCatQuery('Error:Framework:FileFormatUnknown'), $
            IDLitLangCatQuery('Error:Framework:FileWriteError'),strFile], $
            severity=2

        return, 0
    endif

    ; Create an instance of our writer
    oTool = self->GetTool()
    oDesc = oTool->GetByIdentifier(idWriter)
    oWriter = oDesc->GetObjectInstance()
    ;; It appears that most of the IDL file writers will fail if the
    ;; filename doesnt have an extenstion. So if this file name
    ;; doesnt have an extension, add one
    strTmp = strFile
    if(strpos(strFile, ".") eq -1)then begin
        strext = oWriter->GetFileExtensions(count=count)
        if(count gt 0)then $
          strTmp = strFile +"."+strExt[0]
    endif
    oWriter->SetFilename, strTmp
    oWriter->SetProperty, SCALE_FACTOR=scaleFactor

    void = oTool->DoUIService("HourGlassCursor", self)

    oData = oItem

    switch (1) of

    ; For VisImage retrieve the image data and palette from the grImage,
    ; so you get what is visually displayed, not the raw data.
    OBJ_ISA(oItem, 'IDLitVisImage'): begin
        oItem->GetProperty, _DATA=image, VISUALIZATION_PALETTE=palette

        ndim = SIZE(image, /N_DIMENSIONS)
        if (ndim eq 0) then $
            return, 0 ; failure

        dims = SIZE(image, /DIMENSIONS)
        hasPalette = ((ndim eq 2) || (ndim eq 3 && dims[0] le 2)) && $
            (N_ELEMENTS(palette) ge 3)
        oData = hasPalette ? $
            OBJ_NEW('IDLitDataIDLImage', image, palette, /NO_COPY) : $
            OBJ_NEW('IDLitDataIDLImagePixels', image, /NO_COPY)
        break
        end

    OBJ_ISA(oItem, "_IDLitgrDest"):  ; fall thru
    OBJ_ISA(oItem, "IDLitgrView"): begin
        oWriter->GetProperty, TYPES=types
        ; If our writer accepts IDLDEST, then no need to convert.
        if (MAX(STRCMP(types, 'IDLDEST', /FOLD_CASE)) eq 1) then $
            break

        ; Our writer presumably wants an IDLIMAGE.
        ; Get the system raster service.
        oRaster = oTool->GetService("RASTER_BUFFER")
        if (~obj_valid(oRaster))then begin
            self->SignalError, $
                IDLitLangCatQuery('Error:Framework:CannotAccessBuffer'), $
                severity=2
            return, 0
        endif
        ;; Set the buffer dims
        oItem->GetProperty, DIMENSIONS=dims
        oRaster->SetProperty, SCALE_FACTOR=scaleFactor, $
            XOFFSET=0, YOFFSET=0, DIMENSIONS=dims

        ;; Do the draw
        oWin = oTool->GetCurrentWindow()
        if (~OBJ_VALID(oWin)) then $
            return, 0
        status = oRaster->DoWindowCopy(oWin, $
            OBJ_ISA(oItem, "_IDLitgrDest") ? oItem->GetScene() : oItem)
        if (status eq 0) then $
            return, 0

        success = oRaster->GetData(image)

        ; Reset the IDLgrBuffer dimensions, to conserve memory.
        oDev = oRaster->GetDevice()
        oDev->SetProperty, DIMENSIONS=[2,2]

        if (~success) then begin
            self->SignalError, $
                IDLitLangCatQuery('Error:Framework:CannotAccessRaster'), severity=2
            return, 0
        endif

        oData = OBJ_NEW('IDLitDataIDLImage', image, /NO_COPY)
        break
        end

    else: ; should have the correct type

    endswitch

    ; Actually write the data to the file
    ; Returns 1 for success, 0 for error, -1 for cancel.
    success = oWriter->SetData(oData)

    if (oData ne oItem) then $
        OBJ_DESTROY, oData

    ; Return the instance - we are done with it
    oDesc->ReturnObjectInstance, oWriter

    return, success
end

;-------------------------------------------------------------------------
pro IDLitsrvWriteFile__define

    compile_opt idl2, hidden

    struc = {IDLitsrvWriteFile,           $
             inherits _IDLitsrvReadWrite}

end

