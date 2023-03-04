; $Id:
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;  IDLittool_systeminit
;
; PURPOSE:
;   Load system related files
;
; CALLING SEQUENCE:
; MODIFICATION HISTORY:
;-
pro IDLitTool_SystemInit

   compile_opt idl2, hidden
   common _IDLitTools$Init$_, c_isInitialized

   if(n_elements(c_isInitialized))then $ ;; Already initalized
     return

@idlit_catch
   if(iErr ne 0)then begin
      catch, cancel=1
      c_isInitialized = 1
      return
  endif

  saveFile = filepath("itools_library.sav", subdir=['lib','itools'])
  if(file_test(saveFile))then begin      
      restore, saveFile
  endif
  status = IDLitwdSplash()
  c_isInitialized=1
end
