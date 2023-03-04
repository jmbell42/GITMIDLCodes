; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/idatamanager.pro#1 $
; Copyright (c) 2003-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   iDataManager
;
; PURPOSE:
;   Launches the DataManager
;
; CALLING SEQUENCE:
;   iDataManager
;
; INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; MODIFICATION HISTORY:
;   Written by:  AGEH, RSI, November 2003
;
;-

;-------------------------------------------------------------------------
PRO IDATAMANAGER

    compile_opt idl2, hidden

    oSystem = _IDLitSys_GetSystem()
    void = oSystem->DoUIService('/DataManagerBrowser',oSystem)

END
