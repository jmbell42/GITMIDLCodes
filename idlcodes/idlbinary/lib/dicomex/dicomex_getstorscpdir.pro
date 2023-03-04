; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/dicomex/dicomex_getstorscpdir.pro#1 $
; Copyright (c) 2004-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   getDicomexStorScpDir
;
; PURPOSE:
;   Returns the directory StorScpDir used by the IDLffDicomExCfg object
;
; CALLING SEQUENCE:
;
;   PATH = GETDICOMEXSTORSCPDIR
;
; INPUTS:
;
;   NONE
;
; KEYWORD PARAMETERS:
;
;   NONE
;
; MODIFICATION HISTORY:
;   Written by:  LFG, RSI, October 2004
;   Modified by:
;
;-
function Dicomex_GetStorScpDir
  compile_opt idl2

  catch, errorStatus
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    return, path
  endif

  path = ''
  ocfg = obj_new('IDLffDicomExCfg', /system)
  path = ocfg->GetValue('StorScpDir')

  obj_destroy, ocfg
  return, path

end
