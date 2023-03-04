; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/itresolve.pro#1 $
; Copyright (c) 2003-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; Name:
;   ITRESOLVE
;
; Purpose:
;   Resolves all IDL code within the iTools directory, as well
;   as all other necessary IDL code. Useful for constructing save
;   files containing user code that requires the iTools framework.
;
; Arguments:
;   None.
;
; Keywords:
;   PATH: Set this keyword to a string giving the full path to the iTools
;       directory. The default is to use the lib/itools subdirectory
;       within which the ITRESOLVE procedure resides.
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, June 2003
;   Modified:
;


;-------------------------------------------------------------------------
pro itresolve, PATH=pathIn

    compile_opt idl2, hidden

    if (N_ELEMENTS(pathIn) gt 0) then begin
        path = pathIn
    endif else begin
        ; Assume this program is in a subdirectory of iTools.
        path = FILE_DIRNAME((ROUTINE_INFO('itresolve', $
            /SOURCE)).path, /MARK_DIR)
    endelse

    filenames = FILE_SEARCH(path, '*.pro', /FULLY_QUALIFY)

    ; Files which we don't need (or can't) compile.
    excludelist=[ $
        'idlit_catch','idlit_on_error2', $
        'idlitconfig', 'cw_iterror', $   ;  @ includes
        '_idlitcreatesave', $  ; don't include ourself
        ; Can't compile methods by themselves (see classlist below).
        'idlitcomponent___copyproperty', $
        'idlitsystem__registertoolfunctionality',$
        'idlittool__updateavailability']

    ; These are classes which have methods outside of their __define files,
    ; or whose class definitions are in C code.
    classlist = ['idlittool', $
        'idlitsystem', $
        'idlitcomponent', $
        'idlfflangcat', $
        'trackball']

    filenames = FILE_BASENAME(filenames, '.pro')

    for i=0,N_ELEMENTS(excludelist)-1 do $
        filenames = filenames[WHERE(filenames ne excludelist[i])]

    RESOLVE_ROUTINE, filenames, /EITHER, $
        /COMPILE_FULL_FILE, /NO_RECOMPILE

    RESOLVE_ALL, CLASS=classlist, /QUIET

end

