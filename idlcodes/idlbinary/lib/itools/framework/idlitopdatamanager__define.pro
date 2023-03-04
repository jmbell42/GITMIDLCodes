; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/framework/idlitopdatamanager__define.pro#1 $
;
; Copyright (c) 2000-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopDataManager
;
; PURPOSE:
;   Simple operation used to launch the data manager browser
;
; CATEGORY:
;   IDL Tools
;
;;---------------------------------------------------------------------------
;; IDLitOPDatamanager::DoAction
;;
;; Purpose:
;;   when called by the system, this will initiate the data manager
;;   browser UI service
;;
;; Parameters:
;;   oTool   - The tool for the system
;;
;-------------------------------------------------------------------------
function IDLitopDataManager::DoAction, oTool
  ;; Pragmas
  compile_opt idl2, hidden

@idlit_catch
  if(iErr ne 0)then begin
    catch, /cancel
    return, obj_new()
  endif

  ;; pretty simple.
  void=oTool->DoUIService('/DataManagerBrowser', self)

  return, 0

end

;;-------------------------------------------------------------------------
;; IDLitopDataManager__define
;;
;; Purpose:
;;    When called, it defines the object for the system.
;;
pro IDLitopDataManager__define
  compile_opt idl2, hidden

  struc = {IDLitopDataManager,           $ ;; pretty simple
           inherits IDLitOperation}


END
