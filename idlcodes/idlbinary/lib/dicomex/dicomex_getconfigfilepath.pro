; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/dicomex/dicomex_getconfigfilepath.pro#1 $
; Copyright (c) 2004-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   getDicomexStorScpDir
;
; PURPOSE:
;   Returns the path to the system config or local config file
;
; CALLING SEQUENCE:
;
;   PATH = getDicomexConfigPath
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
;   Written by:  LFG, RSI, January 2005
;   Modified by:
;
;-
function DicomEx_GetConfigFilePath, system=sys
  compile_opt idl2

  catch, errorStatus
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    return, path
  endif

  ; when the system keyword is Not set we will get the local user config file path
  ; when the system keyword is set we will get the system config file path
  sysCfg = keyword_set(sys)

  path = ''

  if (sysCfg eq 0) then begin
      ocfg = obj_new('IDLffDicomExCfg')
  endif else begin
      ocfg = obj_new('IDLffDicomExCfg', /system)
  endelse


  path = ocfg->GetValue('configfile')
  obj_destroy, ocfg

  return, path

end