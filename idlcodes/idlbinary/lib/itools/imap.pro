; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/imap.pro#1 $
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   iMap
;
; PURPOSE:
;   Implements the iMap wrapper interface for the tools sytem.
;
; CALLING SEQUENCE:
;   iMap[, Image][, X, Y]
;   or
;   iMap[, Z] [, X, Y], /CONTOUR
;
; INPUTS:
;   See iImage for a description of the Image, X, Y arguments.
;   If /CONTOUR is set see iContour for a description of
;       the Z, X, Y arguments.
;
; KEYWORD PARAMETERS:
;   CONTOUR: Set this keyword to create a Contour visualization from
;       the supplied data. By default, an Image visualization is created.
;
;   See iImage  and iContour for list of available keywords.
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Feb 2004
;   Modified:
;
;-


;-------------------------------------------------------------------------
pro iMap, parm1, parm2, parm3, parm4, $
    CONTOUR=doContour, $
    _REF_EXTRA=_extra

    compile_opt hidden, idl2

@idlit_on_error2.pro

    title = 'IDL iMap'
    toolname = 'Map Tool'

    if KEYWORD_SET(doContour) then begin

        case N_PARAMS() of
        0: iContour, $
            TITLE=title, TOOLNAME=toolname, _EXTRA=_extra
        1: iContour, parm1, $
            TITLE=title, TOOLNAME=toolname, _EXTRA=_extra
        2: iContour, parm1, parm2, $
            TITLE=title, TOOLNAME=toolname, _EXTRA=_extra
        3: iContour, parm1, parm2, parm3, $
            TITLE=title, TOOLNAME=toolname, _EXTRA=_extra
        endcase

    endif else begin

        case N_PARAMS() of
        0: iImage, $
            TITLE=title, TOOLNAME=toolname, _EXTRA=_extra
        1: iImage, parm1, $
            TITLE=title, TOOLNAME=toolname, _EXTRA=_extra
        2: iImage, parm1, parm2, $
            TITLE=title, TOOLNAME=toolname, _EXTRA=_extra
        3: iImage, parm1, parm2, parm3, $
            TITLE=title, TOOLNAME=toolname, _EXTRA=_extra
        4: iImage, parm1, parm2, parm3, parm4, $
            TITLE=title, TOOLNAME=toolname, _EXTRA=_extra
        endcase

    endelse

end


