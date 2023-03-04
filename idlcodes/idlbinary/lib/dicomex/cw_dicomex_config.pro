; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/dicomex/cw_dicomex_config.pro#1 $
; Copyright (c) 2004-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   cw_dicomex_config
;
; PURPOSE:
;   This widget a UI front end to an underlying dicomex config object.
;   The UI presented allows the user to edit the local user config file
;   or the system config file.
;
;   This compound widget will make a callback when the save btn is pressed
;   if a callback routine has been specified.  The callback allows the
;   parent to update any widgets that use the config file values.
;
; CALLING SEQUENCE:
;
;   ID = CW_DICOMEX_CONFIG(WID [,/SYSTEM_CONFIGURATION] [,CALLBACKROUTINE=name])
;
; INPUTS:
;
;   WID - Widget ID of the parent
;
; KEYWORD PARAMETERS:
;
;   SYSTEM_CONFIGURATION - If set, display the system configuration, otherwise
;                          display the local configuration
;
;   CALLBACKROUTINE - Set to the name of the routine to be called when
;                     the Save button is pressed.
;
; MODIFICATION HISTORY:
;   Written by:  LFG, RSI, October 2004
;   Modified by:  AGEH, RSI, December 2004    Tweaked code, added comments.
;
;-

;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_btnStartService_event
;;
;; Purpose:
;;   Event handler for the Start Service button
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
PRO cw_dicomex_btnStartService_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(ev.top, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  ;; check to see if the Storage SCP Dir needs to be saved before starting
  widget_control, (*pstate).wtxtSScpDir, get_uvalue=dirty
  IF dirty THEN BEGIN
    result = dialog_message(title='Dialog Dicom Network Error', /cancel, $
                            dialog_parent=ev.top, $
                            ['You must save your changes to the Storage SCP Directory', $
                             'before starting the Storage SCP Service.', $
                             '', $
                             'Save Changes and Start Service?'])
    IF (result EQ 'Cancel') THEN $
      return
    ;; save changes
    call_procedure, 'cw_dicomex_btnSave_event', ev
    ;; check to ensure that a proper directory was saved
    widget_control, (*pstate).wtxtSScpDir, get_value = wstrings
    IF ~file_search(wstrings[0], /test_directory) THEN $
      return
  ENDIF

  ;; check to see if a propert Storage SCP Dir exists
  widget_control, (*pstate).wtxtSScpDir, get_value = wstrings
  IF ~file_search(wstrings[0], /test_directory) THEN BEGIN
    void = dialog_message(title='Dialog Dicom Network Error', /error, $
                          dialog_parent=ev.top, $
                          ['An existing Storage SCP Directory must be specified ' + $
                           'before starting the Storage SCP Service'])
    return
  ENDIF

  val =(*pstate).ocfg->StorageScpService('start')
  widget_control, (*pstate).wtxtServiceStatus, set_value = val

  ;; wait a bit then update status
  widget_control, (*pstate).wbtnServiceStatus, timer=3

end

;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_btnStopService_event
;;
;; Purpose:
;;   Event handler for the Stop Service button
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
PRO cw_dicomex_btnStopService_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(ev.top, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  val =(*pstate).ocfg->StorageScpService('stop')
  widget_control, (*pstate).wtxtServiceStatus, set_value = val

  ;; wait a bit then update status
  widget_control, (*pstate).wbtnServiceStatus, timer=3

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_btnServiceStatus_event
;;
;; Purpose:
;;   Event handler for the Update Service Status button
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
PRO cw_dicomex_btnServiceStatus_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(ev.top, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  val =(*pstate).ocfg->StorageScpService('status')
  widget_control, (*pstate).wtxtServiceStatus, set_value = val

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_wbtnSScpDirBrowse_event
;;
;; Purpose:
;;   Event handler for the Storage SCP Dir text
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
PRO cw_dicomex_wbtnSScpDirBrowse_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(ev.top, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  widget_control, (*pstate).wtxtSScpDir, get_value = oldpath

  newpath = dialog_pickfile(title='Pick a directory', path=oldpath, $
                            /directory, DIALOG_PARENT=ev.top)

  if (newpath[0] eq '') then begin
    return
  endif

  widget_control, (*pstate).wtxtSScpDir, set_value = newpath[0], set_uvalue=1

END


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_wtxtGeneric_event
;;
;; Purpose:
;;   Sets the uvalue on the widget_text if it has been edited.
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
PRO cw_dicomex_wtxtGeneric_event, ev
  compile_opt idl2

  ;; just set dirty flag
  IF (ev.type LT 3) THEN $
    widget_control, ev.id, set_uvalue=1

END


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_btnAcceptAny_event
;;
;; Purpose:
;;   Event handler for the Accept Any check box
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
PRO cw_dicomex_btnAcceptAny_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(ev.top, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  (*pstate).bAcceptAny NE= 1

  val = (*pstate).bAcceptAny ? 'yes' : 'no'
  (*pstate).ocfg->setvalue, 'AcceptAny', val

END


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_cbAENEcho_event
;;
;; Purpose:
;;   Event handler for the Echo Application Entity Name combobox
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
PRO cw_dicomex_cbAENEcho_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(ev.top, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  widget_control, ev.id, get_value = wstrings
  val = wstrings[ev.index]

  (*pstate).ocfg->setvalue, 'EchoScuServiceAE', val

END


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_cbAENQR_event
;;
;; Purpose:
;;   Event handler for the Query Retrieve Application Enity Name combobox
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
PRO cw_dicomex_cbAENQR_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(ev.top, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  widget_control, ev.id, get_value = wstrings
  val = wstrings[ev.index]

  (*pstate).ocfg->setvalue, 'QRScuServiceAE', val

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_cbAENSScu_event
;;
;; Purpose:
;;   Event handler for the Storage SCU Application Enity Name combobox
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
PRO cw_dicomex_cbAENSScu_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(ev.top, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  widget_control, ev.id, get_value = wstrings
  val = wstrings[ev.index]

  (*pstate).ocfg->setvalue, 'StorScuServiceAE', val

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_cbAENSScp_event
;;
;; Purpose:
;;   Event handler for the Storage SCP Application Enity Name combobox
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_cbAENSScp_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(ev.top, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  widget_control, ev.id, get_value = wstrings
  val = wstrings[ev.index]

  (*pstate).ocfg->setvalue, 'StorScpServiceAE', val

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_cbEchoNodes_event
;;
;; Purpose:
;;   Event handler for the Remote Nodes combobox
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_cbEchoNodes_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(ev.top, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  widget_control, ev.id, get_value = wstrings
  (*pstate).echo_node = wstrings[ev.index]

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_btnEcho_event
;;
;; Purpose:
;;   Event handler for the Echo button
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_btnEcho_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    widget_control, (*pstate).wbtnEcho, sensitive=1
    return
  endif

  wState = widget_info(ev.top, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  if ((*pstate).echo_node eq '') then $
    message, ' Do not have a node to echo'

  widget_control, (*pstate).wtxtEchoStatus, set_value = 'Echo request sent....'
  widget_control, (*pstate).wtxtEchoStatus, set_value = ' ', /append

  widget_control, (*pstate).wbtnEcho, sensitive=0

  status = (*pstate).ocfg->Echo((*pstate).echo_node, count=cnt)

  widget_control, (*pstate).wbtnEcho, sensitive=1

  for ii = 0, cnt-1 do $
    widget_control, (*pstate).wtxtEchoStatus, set_value = status[ii], /append

  ;; check for success.  Get Query models if the AE is a query scp and
  ;; we are not is system mode
  IF ((strpos(status[0], 'Succeeded') NE -1) && ~(*pstate).sysCfg) THEN BEGIN
    ;; check to see if selected node is a Query SCP
    qrscpaes = (*pstate).ocfg->GetApplicationEntities(count=count, $
                                                      SERVICE_TYPE='Query_SCP')
    wh = where((*pstate).echo_node EQ qrscpaes.APPLENTITYNAME)
    IF (wh[0] NE -1) THEN BEGIN
      ;; query scp for supported modes
      oqr = obj_new('IDLffDicomExQuery')
      oqr->setproperty, query_scp = (*pstate).echo_node
      models = oqr->querymodelssupported(count=cnt)

      widget_control, (*pstate).wtxtEchoStatus, set_value = '', /append
      widget_control, (*pstate).wtxtEchoStatus, $
                      set_value = 'Query models supported by the remote ' + $
                      'Query SCP node:', /append

      if (cnt eq 0) then begin
        widget_control, (*pstate).wtxtEchoStatus, set_value = ' The selected node did ' + $
                        'not returned any supported models.', /append
      endif

      for xx=0, cnt -1 do begin
        case models[xx] of
          0: widget_control, (*pstate).wtxtEchoStatus, $
                             set_value = '  PATIENT_ROOT_QR_FIND', /append
          1: widget_control, (*pstate).wtxtEchoStatus, $
                             set_value = '  PATIENT_ROOT_QR_GET', /append
          2: widget_control, (*pstate).wtxtEchoStatus, $
                             set_value = '  PATIENT_ROOT_QR_MOVE', /append
          3: widget_control, (*pstate).wtxtEchoStatus, $
                             set_value = '  PATIENT_STUDY_ONLY_QR_FIND', /append
          4: widget_control, (*pstate).wtxtEchoStatus, $
                             set_value = '  PATIENT_STUDY_ONLY_QR_GET', /append
          5: widget_control, (*pstate).wtxtEchoStatus, $
                             set_value = '  PATIENT_STUDY_ONLY_QR_MOVE', /append
          6: widget_control, (*pstate).wtxtEchoStatus, $
                             set_value = '  STUDY_ROOT_QR_FIND', /append
          7: widget_control, (*pstate).wtxtEchoStatus, $
                             set_value = '  STUDY_ROOT_QR_GET', /append
          8: widget_control, (*pstate).wtxtEchoStatus, $
                             set_value = '  STUDY_ROOT_QR_MOVE', /append
          else: widget_control, (*pstate).wtxtEchoStatus, $
                                set_value = ' Invalid response from remote Query ' + $
                                'SCP node.', /append
        ENDCASE
      ENDFOR
      obj_destroy, oqr
    ENDIF
  ENDIF

END


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_std_aen_name_check
;;
;; Purpose:
;;   Sensitive settings based on Existing Entries value
;;
;; Parameters:
;;   ID - Widget ID
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_std_aen_name_check, id
  compile_opt idl2
  on_error, 2

  wState = widget_info(id, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  aen = widget_info((*pstate).wcbAENames, /combobox_gettext)

  if (aen eq 'RSI_AE_QUERY_SCU')  || $
    (aen eq 'RSI_AE_STOR_SCU')   || $
    (aen eq 'RSI_AE_STOR_SCP')   || $
    (aen eq 'RSI_AE_ECHO_SCU') then begin
    widget_control, (*pstate).wtxtAEN, editable=0
    widget_control, (*pstate).wcbSLN, sensitive=0
    widget_control, (*pstate).wcbType, sensitive=0
  endif else begin
    widget_control, (*pstate).wtxtAEN, editable=1
    widget_control, (*pstate).wcbSLN, sensitive=1
    widget_control, (*pstate).wcbType, sensitive=1
  endelse

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_txtcbAEEdit_event
;;
;; Purpose:
;;   Event handler for all the properties of an Application Entity
;;
;; Parameters:
;;   EV - A widget event structure
;;
;; Keywords:
;;   NONE
;;
PRO cw_dicomex_txtcbAEEdit_event, ev
  compile_opt idl2

  names = ['WIDGET_TEXT_CH','WIDGET_TEXT_STR','WIDGET_TEXT_DEL','WIDGET_COMBOBOX']

  IF (max(tag_names(ev, /structure_name) EQ names) EQ 1) THEN BEGIN
    wState = widget_info(ev.top, find_by_uname='cfgstatebase')
    widget_control, wState, get_uvalue = pstate
    cw_dicomex_AENew_mode, 1, pstate
  ENDIF

END


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_AENew_mode
;;
;; Purpose:
;;   De/sensitizes all other widgets during the creation of a new
;;   Application Entity
;;
;; Parameters:
;;   ENTER - If set, desensitize the rest of the widget, otherwise
;;           re-sensitize everything.
;;
;;   PSTATE - A pointer to the state structure
;;
;; Keywords:
;;   NONE
;;
PRO cw_dicomex_AENew_mode, enter, pstate
  compile_opt idl2

  IF enter THEN BEGIN
    ;; check to see if we have already switched into edit mode
    widget_control, (*pstate).wbtnAENew, get_uvalue=inEdit
    IF inEdit THEN return

    widget_control, (*pstate).wcbAENames, sensitive=0
    widget_control, (*pstate).wbaseEcho, sensitive=0
    widget_control, (*pstate).wbaseEchoAE, sensitive=0
    widget_control, (*pstate).wbaseQRAE, sensitive=0
    widget_control, (*pstate).wbaseSScpAE, sensitive=0
    widget_control, (*pstate).wbaseSScuAE, sensitive=0
    widget_control, (*pstate).wbaseSSAE, sensitive=0
    widget_control, (*pstate).wbtnSave, sensitive=0
    widget_control, (*pstate).wbtnCancel, sensitive=0
    widget_control, (*pstate).wbtnAENew, set_value='Save', $
                    event_pro='cw_dicomex_btnSave_event', set_uvalue=1
    ;; save current sensitive state of delete button
    widget_control, (*pstate).wbtnAEDelete, $
                    set_uvalue=widget_info((*pstate).wbtnAEDelete, /sensitive)
    widget_control, (*pstate).wbtnAEDelete, set_value='Cancel', $
                    event_pro='cw_dicomex_btnCancel_event', /sensitive
  ENDIF ELSE BEGIN
    widget_control, (*pstate).wcbAENames, sensitive=1
    widget_control, (*pstate).wbaseEcho, sensitive=1
    widget_control, (*pstate).wbaseEchoAE, sensitive=1
    widget_control, (*pstate).wbaseQRAE, sensitive=1
    widget_control, (*pstate).wbaseSScpAE, sensitive=1
    widget_control, (*pstate).wbaseSScuAE, sensitive=1
    widget_control, (*pstate).wbaseSSAE, sensitive=1
    widget_control, (*pstate).wbtnSave, sensitive=1
    widget_control, (*pstate).wbtnCancel, sensitive=1
    widget_control, (*pstate).wbtnAENew, set_value='New', $
                    event_pro='cw_dicomex_btnAENew_event', set_uvalue=0
    ;; retreive sensitive state of delete button
    widget_control, (*pstate).wbtnAEDelete, get_uvalue=sens
    widget_control, (*pstate).wbtnAEDelete, set_value='Delete', $
                    event_pro='cw_dicomex_btnAEDelete_event', sensitive=sens
  ENDELSE

END


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_btnAENew_event
;;
;; Purpose:
;;   Event handler for the New button
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_btnAENew_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(ev.top, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  cw_dicomex_save_ae, ev.top, 1

  widget_control, (*pstate).wtxtAEN,  set_value = ''
  widget_control, (*pstate).wtxtAET,  set_value = ''
  widget_control, (*pstate).wtxtHost, set_value = ''
  widget_control, (*pstate).wtxtPort, set_value = strtrim(string(0),2)
  widget_control, (*pstate).wcbSLN, SET_COMBOBOX_SELECT=0
  widget_control, (*pstate).wcbType, SET_COMBOBOX_SELECT=0

  ;; make the following editable in case they were not
  widget_control, (*pstate).wtxtAEN, editable=1
  widget_control, (*pstate).wcbSLN, sensitive=1
  widget_control, (*pstate).wcbType, sensitive=1

  cw_dicomex_AENew_mode, 1, pstate

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_btnAEDelete_event
;;
;; Purpose:
;;   Event handler for the Delete button
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_btnAEDelete_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    cw_dicomex_reload_aes, ev.top, 0
    cw_dicomex_reload, ev.top
    return
  endif

  result = dialog_message('Confirm Application Entity Delete ', /question, $
                          dialog_parent=ev.top)
  IF (result EQ 'No') THEN return

  wState = widget_info(ev.top, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  aes = (*pstate).ocfg->GetApplicationEntities(count=count)
  if (count eq 1) then begin
    message, ' You can not delete the last application entity.'
  endif

  ;; this is the aen to delete
  aen = widget_info((*pstate).wcbAENames, /combobox_gettext)
  (*pstate).ocfg->removeapplicationentity, aen

  ;; reload the combobox so the deleted item is removed
  cw_dicomex_reload_aes, ev.top, 0
  cw_dicomex_reload, ev.top

  ;; make a callback to the parent so that the parent is told that the
  ;; config file changed...the parent can then tell widgets that use
  ;; config file data to update themselves.
  parentUname = widget_info((*pstate).parent, /uname)
  if (parentUname eq 'dlg_dicomex_net_tab_config') then begin
    widget_control, (*pstate).parent, get_uvalue = topMostWidgetInUI
    IF ((*pstate).callback NE '') THEN $
      call_procedure, (*pstate).callback, topMostWidgetInUI
  endif

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_cbAENames_event
;;
;; Purpose:
;;   Event handler for the Application Entity Name combobox
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_cbAENames_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(ev.top, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  ; remember the selected aen
  widget_control, ev.id, get_value = wstrings
  aen = wstrings[ev.index]

  ; if there is a new aen load it into the combobox
  cw_dicomex_reload_aes, ev.top, 1
  cw_dicomex_reload, ev.top

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_btnSave_event
;;
;; Purpose:
;;   Event handler for the Save button
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_btnSave_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(ev.top, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  widget_control, (*pstate).wtxtSScpDir, get_value = wstrings
  val = wstrings[0]
  system = widget_info((*pstate).wtxtSScpDir, /sensitive)
  IF system THEN BEGIN
    IF ~file_search(val, /test_directory) THEN BEGIN
      void = dialog_message('An existing Storage SCP Directory must be specified', $
                            dialog_parent=ev.top, /error, $
                            title='Dialog Dicom Network Error')
      ;; re-sensitize rest of widget
      cw_dicomex_AENew_mode, 0, pstate
      return
    ENDIF
  ENDIF
  (*pstate).ocfg->setvalue, 'StorScpDir', val

  ; save any ae edits
  cw_dicomex_save_ae, ev.top, 0

  val = widget_info((*pstate).wcbAENEcho, /combobox_gettext)
  (*pstate).ocfg->setvalue, 'EchoScuServiceAE', val

  val = widget_info((*pstate).wcbAENQR, /combobox_gettext)
  (*pstate).ocfg->setvalue, 'QRScuServiceAE', val

  widget_control, (*pstate).wtxtMaxQRRsp, get_value = wstrings
  val = wstrings[0]
  iVal = fix(val)
  (*pstate).ocfg->setvalue, 'MaxQueryResponses', iVal

  val = widget_info((*pstate).wcbAENSScu, /combobox_gettext)
  (*pstate).ocfg->setvalue, 'StorScuServiceAE', val

  ;; the stor scp value set is written to the local cfg file when in
  ;; local cfg mode but these values are not used... only the sys cfg
  ;; file values are used...we warn the user when the ae for the stor scp
  ;; service is not defined
  val = widget_info((*pstate).wcbAENSScp, /combobox_gettext)

  if ((*pstate).sysCfg eq 1) then begin
      (*pstate).ocfg->setvalue, 'StorScpServiceAE', val
  endif else begin
      widget_control, (*pstate).wcbAENames, get_value = aenStrs
      cnt_strs = n_elements(aenStrs)

      valmatch = 0
      for idx=0, cnt_strs-1 do begin
        if (val eq aenStrs[idx])then begin
          valmatch = 1
          break
        endif
      endfor

      widget_control, (*pstate).wtxtAEN, get_value = wstrings

      if (val eq wstrings[0])then begin
          valmatch = 1
      endif

      if (valmatch eq 1) then begin
          (*pstate).ocfg->setvalue, 'StorScpServiceAE', val
      endif else begin
          void = dialog_message('Warning: The Application Entity for the local Storage Scp Service is not defined.', $
                                dialog_parent=ev.top, /Information, $
                                title='Dialog Dicom Network Warning')
      endelse
  endelse

  if ((*pstate).bAcceptAny eq 1) then begin
    val = 'yes'
  endif else begin
    val = 'no'
  endelse
  (*pstate).ocfg->setvalue, 'AcceptAny', val

  widget_control, (*pstate).wtxtFileExt, get_value = wstrings
  val = wstrings[0]
  (*pstate).ocfg->setvalue, 'FileExtension', val

  widget_control, (*pstate).wtxtCtrlPort, get_value = wstrings
  val = wstrings[0]
  iVal = fix(val) > 1
  (*pstate).ocfg->setvalue, 'StorScpCtrlPort', iVal

  ;; repopulate the ae combobox and fields
  cw_dicomex_reload_aes, ev.top, 1
  cw_dicomex_reload, ev.top

  ;; write the config file
  (*pstate).ocfg->commit

  ;; reset text widget dirty flags
  widget_control, (*pstate).wtxtSScpDir, set_uvalue=0
  widget_control, (*pstate).wtxtMaxQRRsp, set_uvalue=0
  widget_control, (*pstate).wtxtCtrlPort, set_uvalue=0
  widget_control, (*pstate).wtxtFileExt, set_uvalue=0

  ;; make a callback to the parent so that the parent is told that the
  ;; config file changed...the parent can then tell widgets that use
  ;; config file data to update themselves.  the uname checked here is
  ;; changeable but it must be the uname of the parent and the uvalue is
  ;; a widget id that is that is the root of the ui or very near the
  ;; root of the ui
  parentUname = widget_info((*pstate).parent, /uname)
  if (parentUname eq 'dlg_dicomex_net_tab_config') then begin
    widget_control, (*pstate).parent, get_uvalue = topMostWidgetInUI
    IF ((*pstate).callback NE '') THEN $
      call_procedure, (*pstate).callback, topMostWidgetInUI
  endif

  ;; re-sensitize rest of widget
  cw_dicomex_AENew_mode, 0, pstate

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_btnCancel_event
;;
;; Purpose:
;;   Event handler for the Cancel button
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_btnCancel_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog

  if (errorStatus ne 0) then begin
    catch,/cancel
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(ev.top, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  ; drop any edits
  obj_destroy, (*pstate).ocfg

  ; reload config object
  if ((*pstate).sysCfg eq 1) then begin
    (*pstate).ocfg = obj_new('IDLffDicomExCfg', /system)
  endif else begin
    (*pstate).ocfg = obj_new('IDLffDicomExCfg')
  endelse

  ; reload the ui widgets
  cw_dicomex_reload_aes, ev.top, 1
  cw_dicomex_reload, ev.top

  ;; re-sensitize rest of widget
  cw_dicomex_AENew_mode, 0, pstate

  ;; reset text widget dirty flags
  widget_control, (*pstate).wtxtSScpDir, set_uvalue=0
  widget_control, (*pstate).wtxtMaxQRRsp, set_uvalue=0
  widget_control, (*pstate).wtxtCtrlPort, set_uvalue=0
  widget_control, (*pstate).wtxtFileExt, set_uvalue=0

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_save_ae
;;
;; Purpose:
;;   Saves an application entity
;;
;; Parameters:
;;   ID - Widget ID
;;
;;   RETURNONBLANK - If set then return without issuing a message if
;;                   the Entity Name is blank
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_save_ae, id, returnOnBlank
  compile_opt idl2
  on_error, 2                   ; return errors to the caller

  wState = widget_info(id, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  ; ------- save appl entity fields: name, aet, host, port, sln, type ----------

  widget_control, (*pstate).wtxtAEN,  get_value = aen
  aen = strtrim(aen,2)
  if (strlen(aen[0]) eq 0) then begin
    if (returnOnBlank eq 1) then return
    message, ' Application Entity Name is not valid. You must fix this ' + $
             'error before you can continue OR press the Cancel button.'
  endif
  if (strlen(aen[0]) gt 30) then begin
    message, ' Application Entity Name is too long. You must fix this ' + $
             'error before you can continue OR press the Cancel button.'
  endif

  widget_control, (*pstate).wtxtAET,  get_value = aet
  aet = strtrim(aet,2)
  if (strlen(aet[0]) eq 0) then begin
    if (returnOnBlank eq 1) then return
    message, ' Application Entity Title is not valid. You must fix this ' + $
             'error before you can continue OR press the Cancel button.'
  endif
  if (strlen(aet[0]) gt 15) then begin
    message, ' Application Entity Title is too long. You must fix this ' + $
             'error before you can continue OR press the Cancel button.'
  endif

  widget_control, (*pstate).wtxtHost,  get_value = host
  host = strtrim(host,2)
  if (strlen(host[0]) eq 0) then begin
    if (returnOnBlank eq 1) then return
    message, ' Application Entity Host is not valid. You must fix this ' + $
             'error before you can continue OR press the Cancel button.'
  endif
  if (strlen(host[0]) gt 30) then begin
    message, ' Application Entity Host is too long. You must fix this ' + $
             'error before you can continue OR press the Cancel button.'
  endif

  widget_control, (*pstate).wtxtPort, get_value = port
  ;; do not allow non numeric values
  port = (stregex(port,'[^0-9 ]') NE -1) ? '' : ulong(port)

  port = strtrim(port,2)
  if (strlen(port[0]) eq 0) then begin
    if (returnOnBlank eq 1) then return
    message, ' Application Entity port is not valid. You must fix this ' + $
             'error before you can continue OR press the Cancel button.'
  endif
  if (strlen(port[0]) gt 5) then begin
    message, ' Application Entity port is too long. You must fix this ' + $
             'error before you can continue OR press the Cancel button.'
  endif

  slnStr = widget_info((*pstate).wcbSLN, /combobox_gettext)

  typeStr = widget_info((*pstate).wcbType, /combobox_gettext)

  (*pstate).ocfg->SetApplicationEntity, aen,  aet, host,  port,  slnStr,   typeStr

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_reload_aes
;;
;; Purpose:
;;   Update the Application Entities fields
;;
;; Parameters:
;;   ID - Widget ID
;;
;;   LASTAEN - If set, reload the previous entity
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_reload_aes, id, lastAEN
  compile_opt idl2
  on_error, 2                   ; return errors to the caller

  wState = widget_info(id, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  if (lastAEN eq 1) then begin
    aen = widget_info((*pstate).wcbAENames, /combobox_gettext)
  endif

  ; ------- load appl entity fields: combo, name, aet, host, port, sln, type ----------

  num = widget_info((*pstate).wcbAENames, /combobox_number)
  if (num ne 0) then begin
    for ii=num, 0, -1 do begin
      widget_control, (*pstate).wcbAENames, combobox_deleteitem = ii
    endfor
  endif

  aes = (*pstate).ocfg->GetApplicationEntities(count=count)
  for xx = 0, count-1 do begin
    widget_control, (*pstate).wcbAENames, $
                    combobox_additem = aes[xx].APPLENTITYNAME
  endfor

  ; make the last aen show up in the combobox
  aematch = -1
  if (lastAEN eq 1) then begin
    widget_control, (*pstate).wcbAENames, get_value = aenStrings
    cnt = n_elements(aenStrings)

    for ii=0, cnt-1 do begin
      if (aen eq aenStrings[ii])then begin
        aematch = ii
        break
      endif
    endfor
  endif

  ;; set match to 0 if we are not restoring the last AEN selected in
  ;; the combobox or a match was not found for the last AEN selected
  ;; in the combobox
  if (lastAEN eq 0) || (aematch eq -1) then begin
    aematch = 0
  endif

  widget_control, (*pstate).wcbAENames, SET_COMBOBOX_SELECT=aematch
  widget_control, (*pstate).wtxtAEN,  set_value = aes[aematch].APPLENTITYNAME
  widget_control, (*pstate).wtxtAET,  set_value = aes[aematch].AET
  widget_control, (*pstate).wtxtHost, set_value = aes[aematch].hostname
  widget_control, (*pstate).wtxtPort, $
                  set_value = strtrim(string(aes[aematch].port),2)

  ; select the correct sln for this ae
  match = -1
  widget_control, (*pstate).wcbSLN, get_value = slnstrs
  cnt = n_elements(slnstrs)

  for ii=0, cnt-1 do begin
    if (aes[aematch].servicelistname eq slnstrs[ii])then begin
      match = ii
      break
    endif
  endfor

  if (match ne -1) then begin
    widget_control, (*pstate).wcbSLN, SET_COMBOBOX_SELECT=match
  endif


  ; select the correct type for this ae
  match = -1
  widget_control, (*pstate).wcbType, get_value = typestrs
  cnt = n_elements(typestrs)

  for ii=0, cnt-1 do begin
    if (aes[aematch].servicetype eq typestrs[ii])then begin
      match = ii
      break
    endif
  endfor

  if (match ne -1) then begin
    widget_control, (*pstate).wcbType, SET_COMBOBOX_SELECT=match
  endif

  ;; desensitize the delete button if the AE is one of the
  ;; undeletables.
  ;; NOTE - This is a currently done by matching the AE Name to
  ;;        "RSI_AE_".  However the titles of the resevered AEs should
  ;;        come from the config object.
  widget_control, (*pstate).wtxtAEN, get_value=AEName
  sens = (strmid(AEName,0,7) NE 'RSI_AE_')
  widget_control, (*pstate).wbtnAEDelete, sensitive=sens, set_uvalue=sens

  cw_dicomex_std_aen_name_check, id

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_reload
;;
;; Purpose:
;;   Update the entire widget
;;
;; Parameters:
;;   ID - Widget ID
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_reload, id
  compile_opt idl2
  on_error, 2                   ; return errors to the caller

  wState = widget_info(id, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  ; ------- load echo nodes combo box ----------

  ;; get current item
  val = widget_info((*pstate).wcbEchoNodes, /combobox_gettext)
  IF ~val THEN val='__CW_DICOMEX_NO_VALUE'

  num = widget_info((*pstate).wcbEchoNodes, /combobox_number)
  if (num ne 0) then begin
    for ii=num, 0, -1 do begin
      widget_control, (*pstate).wcbEchoNodes, combobox_deleteitem = ii
    endfor
  endif

  aes1 = (*pstate).ocfg->GetApplicationEntities(count=qcnt, $
                                                SERVICE_TYPE='Query_SCP')
  for xx = 0, qcnt-1 do begin
    widget_control, (*pstate).wcbEchoNodes, $
                    combobox_additem = aes1[xx].APPLENTITYNAME
  endfor

  aes2 = (*pstate).ocfg->GetApplicationEntities(count=count, $
                                                SERVICE_TYPE='Storage_SCP')
  for xx = 0, count-1 do begin
    widget_control, (*pstate).wcbEchoNodes, $
                    combobox_additem = aes2[xx].APPLENTITYNAME
  endfor

  IF (qcnt GT  0) || (count GT 0) THEN BEGIN
    ;; combine Query and Storage lists
    names = [aes1.APPLENTITYNAME,aes2.APPLENTITYNAME]
    ;; filter out null strings
    names = names[where(names)>0]
    ;; find location of previous value
    wh = where(val EQ names) > 0
    (*pstate).echo_node = names[wh]
    widget_control, (*pstate).wcbEchoNodes, set_combobox_select=wh
  ENDIF

  ;-------- load the echo scu aen --------

  num = widget_info((*pstate).wcbAENEcho, /combobox_number)
  if (num ne 0) then begin
    for ii=num, 0, -1 do begin
      widget_control, (*pstate).wcbAENEcho, combobox_deleteitem = ii
    endfor
  endif

  match = -1
  val = (*pstate).ocfg->getvalue('EchoScuServiceAE')
  aes = (*pstate).ocfg->GetApplicationEntities(count=count, $
                                               SERVICE_TYPE='Echo_SCU')

  for xx = 0, count-1 do begin
    widget_control, (*pstate).wcbAENEcho, $
                    combobox_additem = aes[xx].APPLENTITYNAME
    if (val eq aes[xx].APPLENTITYNAME) then begin
      match = xx
    endif
  endfor

  if (match ne -1) then begin
    widget_control, (*pstate).wcbAENEcho, SET_COMBOBOX_SELECT=match
  endif

  num = widget_info((*pstate).wcbAENEcho, /combobox_number)
  if (num eq 0) then begin
    r = dialog_message('Warning you must define at least one Echo ' + $
                       'Scu Application Entity')
  endif


  ;-------- load the query scu aen --------

  num = widget_info((*pstate).wcbAENQR, /combobox_number)
  if (num ne 0) then begin
    for ii=num, 0, -1 do begin
      widget_control, (*pstate).wcbAENQR, combobox_deleteitem = ii
    endfor
  endif

  match = -1
  val = (*pstate).ocfg->getvalue('QRScuServiceAE')
  aes = (*pstate).ocfg->GetApplicationEntities(count=count, $
                                               SERVICE_TYPE='Query_SCU')

  for xx = 0, count-1 do begin
    widget_control, (*pstate).wcbAENQR, $
                    combobox_additem = aes[xx].APPLENTITYNAME
    if (val eq aes[xx].APPLENTITYNAME) then begin
      match = xx
    endif
  endfor

  if (match ne -1) then begin
    widget_control, (*pstate).wcbAENQR, SET_COMBOBOX_SELECT=match
  endif

  val = (*pstate).ocfg->getvalue('MaxQueryResponses')
  widget_control, (*pstate).wtxtMaxQRRsp, set_value = val


  ;-------- load the stor scu aen --------

  num = widget_info((*pstate).wcbAENSScu, /combobox_number)
  if (num ne 0) then begin
    for ii=num, 0, -1 do begin
      widget_control, (*pstate).wcbAENSScu, combobox_deleteitem = ii
    endfor
  endif

  match = -1
  val = (*pstate).ocfg->getvalue('StorScuServiceAE')
  aes = (*pstate).ocfg->GetApplicationEntities(count=count, $
                                               SERVICE_TYPE='Storage_SCU')

  for xx = 0, count-1 do begin
    widget_control, (*pstate).wcbAENSScu, combobox_additem = aes[xx].APPLENTITYNAME
    if (val eq aes[xx].APPLENTITYNAME) then begin
      match = xx
    endif
  endfor

  if (match ne -1) then begin
    widget_control, (*pstate).wcbAENSScu, SET_COMBOBOX_SELECT=match
  endif


  ;-------- load the stor scp aen --------

  ;; we always load the values from the sys config file even when in
  ;; local user config mode
  if ((*pstate).sysCfg eq 0) then begin
    ocfgsys = obj_new('IDLffDicomExCfg', /system)
  endif else begin
    ocfgsys = (*pstate).ocfg
  endelse

  num = widget_info((*pstate).wcbAENSScp, /combobox_number)
  if (num ne 0) then begin
    for ii=num, 0, -1 do begin
      widget_control, (*pstate).wcbAENSScp, combobox_deleteitem = ii
    endfor
  endif

  match = -1
  val = ocfgsys->getvalue('StorScpServiceAE')
  aes = ocfgsys->GetApplicationEntities(count=count, $
                                        SERVICE_TYPE='Storage_SCP')

  for xx = 0, count-1 do begin
    widget_control, (*pstate).wcbAENSScp, $
                    combobox_additem = aes[xx].APPLENTITYNAME
    if (val eq aes[xx].APPLENTITYNAME) then begin
      match = xx
    endif
  endfor

  if (match ne -1) then begin
    widget_control, (*pstate).wcbAENSScp, SET_COMBOBOX_SELECT=match
  endif

  val = ocfgsys->getvalue('FileExtension')
  widget_control, (*pstate).wtxtFileExt, set_value = val

  val = ocfgsys->getvalue('StorScpDir')
  widget_control, (*pstate).wtxtSScpDir, set_value = val

  val = ocfgsys->getvalue('AcceptAny')
  IF (val EQ 'yes') THEN BEGIN
    (*pstate).bAcceptAny = 1
    widget_control, (*pstate).wbtnAccepAny, /set_button
  ENDIF ELSE BEGIN
    (*pstate).bAcceptAny = 0
    widget_control, (*pstate).wbtnAccepAny, set_button=0
  ENDELSE

  IF ~(!version.os_family EQ 'Windows') THEN BEGIN
    val = ocfgsys->getvalue('StorScpCtrlPort')
    widget_control, (*pstate).wtxtCtrlPort, set_value = val
  ENDIF

  if ((*pstate).sysCfg eq 0) then begin
    obj_destroy, ocfgsys
  endif

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_cfg_set_value
;;
;; Purpose:
;;   Procedure to handle set_value calls.  This method is used when
;;   upper level widgets need to send information to this widget
;;
;; Parameters:
;;   ID - Widget ID
;;
;;   VALUE - Structure containing desired information
;;
;; Keywords:
;;   NONE
;;
PRO cw_dicomex_cfg_set_value, id, value
  compile_opt idl2

  ;; value should be structure
  IF (size(value, /type) NE 8) THEN return

  CASE tag_names(value, /structure_name) OF
    'SAVE' : BEGIN
      IF value.save THEN BEGIN
        ;; get top level widget
        top = id
        WHILE ((parent=widget_info(top, /parent))) DO top=parent
        ;; save changes
        call_procedure, 'cw_dicomex_btnSave_event', {TOP:top, ID:id, HANDLER:id}
      ENDIF
    END
    ELSE :
  ENDCASE

END


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_cfg_get_value
;;
;; Purpose:
;;   Procedure to handle get_value calls.  This method is used when
;;   upper level widgets need to retrieve information from this widget
;;
;; Parameters:
;;   ID - Widget ID
;;
;; Keywords:
;;   NONE
;;
FUNCTION cw_dicomex_cfg_get_value, id
  compile_opt idl2

  wState = widget_info(id, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  ;; is currently in AE edit mode?
  widget_control, (*pstate).wbtnAENew, get_uvalue=inEdit

  ;; get dirty flags for text widgets
  widget_control, (*pstate).wtxtSScpDir, get_uvalue=ScpDirDirty
  widget_control, (*pstate).wtxtMaxQRRsp, get_uvalue=MaxDirty
  widget_control, (*pstate).wtxtCtrlPort, get_uvalue=CtrlDirty
  widget_control, (*pstate).wtxtFileExt, get_uvalue=ExtDirty

  dirty = max([(*pstate).ocfg->isDirty(), inEdit, ScpDirDirty, MaxDirty, $
               CtrlDirty, ExtDirty])

  return, {DicomExConfig, Dirty:dirty}

END


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_cfg_kill_event
;;
;; Purpose:
;;   Event handler for kill request events
;;
;; Parameters:
;;   ID - Widget ID
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_cfg_kill_event, id
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  ; called when the main ui is destroyed we let go of objects and pointers

  widget_control, id, get_uvalue = pstate

  if ptr_valid(pstate) then begin
    obj_destroy, (*pstate).ocfg
    ptr_free, pstate
  endif

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_cfg_realize_notify_event
;;
;; Purpose:
;;   Event handler for realization events
;;
;; Parameters:
;;   ID - Widget ID
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_cfg_realize_notify_event, id
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(id, find_by_uname='cfgstatebase')
  widget_control, wState, get_uvalue = pstate

  ; ------- load appl entity fields: combo, name, aet, host, port, sln, type ----------

  ; we only load the sln and types once
  sln = (*pstate).ocfg->GetServiceLists(count=count)
  for xx = 0, count-1 do begin
    widget_control, (*pstate).wcbSLN, combobox_additem = sln[xx]
  endfor

  types = (*pstate).ocfg->GetServiceTypes(count=count)
  for xx = 0, count-1 do begin
    widget_control, (*pstate).wcbType, combobox_additem = types[xx]
  endfor

  ; before calling reload be sure to load the sln and type comboboxes
  cw_dicomex_reload_aes, id, 0

  cw_dicomex_reload, id

  ;; IF Storage SCP service is running but the SCP Directory is
  ;; invalid then throw up a reminder warning.
  val =(*pstate).ocfg->StorageScpService('status')
  IF (strpos(val[0], 'not') EQ -1) THEN BEGIN
    system = widget_info((*pstate).wtxtSScpDir, /sensitive)
    widget_control, (*pstate).wtxtSScpDir, get_value=val
    IF ~file_search(val[0], /test_directory) THEN BEGIN
      str = ['The Storage SCP Directory has not been set.','']
      IF system THEN BEGIN
        str = [str, $
               'You must specify this directory before the Storage SCP Service', $
               'can store retrieved items. To specify the Storage SCP Directory,', $
               'provide the appropriate value in the Storage SCP Dir field, then', $
               'restart the Storage SCP Service.']
      ENDIF ELSE BEGIN
        str = [str,'You must specify this directory before the Storage SCP Service', $
               'can store retrieved items. To specify the Storage SCP Directory,', $
               'launch the DicomEx_Net utility with the SYSTEM keyword and', $
               'provide the appropriate value, then restart the Storage SCP Service.']
      ENDELSE
      void = dialog_message(str, dialog_parent=(*pstate).parent, $
                            title='Dialog Dicom Network Warning')
    ENDIF
  ENDIF

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_config
;;
;; Parameters:
;;   PARENT - Widget ID
;;
;; Keywords:
;;   SYSTEM_CONFIGURATION - If set display in system configuration
;;                          mode, by default display in local user
;;                          mode
;;
;;   CALLBACKROUTINE - Set to the name of a routine to call when the
;;                     save button is pressed
;;
function cw_dicomex_config, parent, SYSTEM_CONFIGURATION=sysConfig, $
                            CALLBACKROUTINE=callbackRoutine
  compile_opt idl2
  on_error, 2                   ; return errors to caller...in this case we
                                ; return errors to the consumer of this compound widget

  xsize = 410
  lxsize = xsize-20
  boxsize = 0.60
  textsize = 0.40

  sysCfg = keyword_set(sysConfig)
  IF ~keyword_set(callbackRoutine) THEN callbackRoutine=''

  ; this is the base for all the widgets in the stor scu ui
  wBase = widget_base(parent, /Row, $
                      NOTIFY_REALIZE='cw_dicomex_cfg_realize_notify_event', $
                      PRO_SET_VALUE='cw_dicomex_cfg_set_value', $
                      FUNC_GET_VALUE='cw_dicomex_cfg_get_value')

  wBaseState = widget_base(wBase, uname='cfgstatebase', $
                           kill_notify='cw_dicomex_cfg_kill_event')

  wBaseCol1 = widget_base(wBase, /Col, space = 10)

  ; ------- add the AE to frame
  wbaseAE = widget_base(wBaseCol1)
  wLblAE = widget_label(wbaseAE, value=' Application Entities ', xoffset=5)
  winfoLblAE = widget_info(wLblAE, /geometry)
  wbaseFrAE = widget_base(wbaseAE, /frame, yoffset=winfoLblAE.ysize/2, $
                          xsize=xsize, /col, space=2, ypad=10, xpad=1, tab_mode=1)
  wLblAE = widget_label(wbaseAE, value=' Application Entities ', xoffset=5)

  wAEr = widget_base(wbaseFrAE, /row)
  wAEr2 = widget_base(wAEr)
  wlblAENames = widget_label(wAEr2, value='Existing Entities ', $
                             /align_right, xsize=lxsize*textsize)
  wcbAENames = widget_combobox(wAEr, scr_xsize=lxsize*boxsize, $
                               event_pro='cw_dicomex_cbAENames_event')

  wAENr = widget_base(wbaseFrAE, /row)
  wlblAEN = widget_label(wAENr, value='Application Entity Name ', $
                         /align_right, xsize=lxsize*textsize)
  wtxtAEN = widget_text(wAENr, /editable, scr_xsize=lxsize*boxsize, $
                        event_pro='cw_dicomex_txtcbAEEdit_event', /all_events)

  wAETr = widget_base(wbaseFrAE, /row)
  wlblAET = widget_label(wAETr, value='Application Entity Title ', $
                         /align_right, xsize=lxsize*textsize)
  wtxtAET = widget_text(wAETr, /editable, scr_xsize=lxsize*boxsize, $
                        event_pro='cw_dicomex_txtcbAEEdit_event', /all_events)

  wHostr = widget_base(wbaseFrAE, /row)
  wlblHost = widget_label(wHostr, value='Host Name ', $
                          /align_right, xsize=lxsize*textsize)
  wtxtHost = widget_text(wHostr, /editable, scr_xsize=lxsize*boxsize, $
                         event_pro='cw_dicomex_txtcbAEEdit_event', /all_events)

  wPortr = widget_base(wbaseFrAE, /row)
  wlblPort = widget_label(wPortr, value='TCP/IP Port Number ', $
                          /align_right, xsize=lxsize*textsize)
  wtxtPort = widget_text(wPortr, /editable, scr_xsize=lxsize*boxsize, $
                         event_pro='cw_dicomex_txtcbAEEdit_event', /all_events)

  wSLNr = widget_base(wbaseFrAE, /row)
  wlblSLN = widget_label(wSLNr, value='Service List Name ', $
                         /align_right, xsize=lxsize*textsize)
  wcbSLN = widget_combobox(wSLNr, scr_xsize=lxsize*boxsize, $
                           event_pro='cw_dicomex_txtcbAEEdit_event')

  wTyper = widget_base(wbaseFrAE, /row)
  wlblType = widget_label(wTyper, value='Service Type ', $
                          /align_right, xsize=lxsize*textsize)
  wcbType = widget_combobox(wTyper, scr_xsize=lxsize*boxsize, $
                            event_pro='cw_dicomex_txtcbAEEdit_event')

  wAEr = widget_base(wbaseFrAE, /row, xpad=175)
  wbtnAENew = widget_button(wAEr, value='New', xsize = 80, uvalue=0, $
                            event_pro='cw_dicomex_btnAENew_event')
  wbtnAEDelete = widget_button(wAEr, value='Delete', xsize = 80, $
                               event_pro='cw_dicomex_btnAEDelete_event')


  ; -------- add the Echo frame
  wbaseEcho = widget_base(wBaseCol1)
  wLblEcho = widget_label(wbaseEcho, value=' Echo SCU ', xoffset=5)
  winfoLblEcho = widget_info(wLblEcho, /geometry)
  wbaseFrEcho = widget_base(wbaseEcho, /frame, yoffset=winfoLblEcho.ysize/2, $
                            xsize=xsize, /col, space=2, ypad=10, xpad=1)
  wLblEcho = widget_label(wbaseEcho, value=' Echo SCU ', xoffset=5)

  wEchor = widget_base(wbaseFrEcho,/row)
  wlblRn = widget_label(wEchor,value='Remote Nodes ', /align_right, $
                        xsize=lxsize*textsize)
  wcbEchoNodes = widget_combobox(wEchor, scr_xsize=lxsize*boxsize, $
                                 event_pro='cw_dicomex_cbEchoNodes_event')

  wEchoc2 = widget_base(wbaseFrEcho, /column)
  wlblEchoStatus = widget_label(wEchoc2,value=' Status ',/align_left)
  wtxtEchoStatus = widget_text(wEchoc2,scr_xsize=lxsize, ysize=10, /scroll)

  wEcho = widget_base(wbaseFrEcho, /row, xpad=280)
  wbtnEcho = widget_button(wEchoc2, value='Echo', xsize = 80, $
                           event_pro='cw_dicomex_btnEcho_event')

  ; --------- starting next column
  wBaseCol2 = widget_base(wBase, /Col, space=10, xpad=5)
  xsize = 375
  boxsize = 0.525
  textsize = 0.40


  ; --------- add the echo aen frame
  wbaseEchoAE = widget_base(wBaseCol2)
  wLblEchoAE = widget_label(wbaseEchoAE, value=' Echo SCU Application Entity ', xoffset=5)
  winfoLblEchoAE = widget_info(wLblEchoAE, /geometry)
  wbaseFrEchoAE = widget_base(wbaseEchoAE, /frame, yoffset=winfoLblEchoAE.ysize/2, $
                              xsize=xsize, /row, space=2, ypad=10, xpad=1)
  wLblEchoAE = widget_label(wbaseEchoAE, value=' Echo SCU Application Entity ', xoffset=5)

  wEchor = widget_base(wbaseFrEchoAE,/row)
  wlblEcho = widget_label(wEchor,value='Application Entity Name ', $
                          xsize=lxsize*textsize,/align_right)
  wcbAENEcho = widget_combobox(wEchor, scr_xsize=lxsize*boxsize, $
                               event_pro='cw_dicomex_cbAENEcho_event')


  ; --------- add the qr aen frame
  wbaseQRAE = widget_base(wBaseCol2)
  wLblQRAE = widget_label(wbaseQRAE, value=' Query Retrieve SCU Application Entity ', $
                          xoffset=5)
  winfoLblQRAE = widget_info(wLblQRAE, /geometry)
  wbaseFrQRAE = widget_base(wbaseQRAE, /frame, yoffset=winfoLblQRAE.ysize/2, $
                            xsize=xsize, /col, space=2, ypad=10, xpad=1, tab_mode=1)
  wLblQRAE = widget_label(wbaseQRAE, value=' Query Retrieve SCU Application Entity ', $
                          xoffset=5)

  wQRr = widget_base(wbaseFrQRAE,/row)
  wlblQR = widget_label(wQRr,value='Application Entity Name ', $
                        xsize=lxsize*textsize,/align_right)
  wcbAENQR = widget_combobox(wQRr, scr_xsize=lxsize*boxsize, $
                             event_pro='cw_dicomex_cbAENQR_event')
  wRespr = widget_base(wbaseFrQRAE,/row)
  wlblRsp = widget_label(wRespr, value='Max Query Responses ', $
                         xsize=lxsize*textsize,/align_right)
  wtxtMaxQRRsp = widget_text(wRespr,/editable,scr_xsize=lxsize*boxsize, $
                             ysize=1, uvalue=0, /all_events, $
                             event_PRO='cw_dicomex_wtxtGeneric_event')


  ; --------- add the stor scu aen frame
  wbaseSScuAE = widget_base(wBaseCol2)
  wLblSScuAE = widget_label(wbaseSScuAE, value=' Storage SCU Application Entity ', $
                            xoffset=5)
  winfoLblSScuAE = widget_info(wLblSScuAE, /geometry)
  wbaseFrSScuAE = widget_base(wbaseSScuAE, /frame, yoffset=winfoLblSScuAE.ysize/2, $
                              xsize=xsize, /row, space=2, ypad=10, xpad=1)
  wLblSScuAE = widget_label(wbaseSScuAE, value=' Storage SCU Application Entity ', $
                            xoffset=5)

  wSScu = widget_base(wbaseFrSScuAE,/row)
  wlblSScu = widget_label(wSScu,value='Application Entity Name ', $
                          xsize=lxsize*textsize,/align_right)
  wcbAENSScu = widget_combobox(wSScu, scr_xsize=lxsize*boxsize, $
                               event_pro='cw_dicomex_cbAENSScu_event')


  ; --------- add the stor scp frame
  wbaseSScpAE = widget_base(wBaseCol2)
  wLblSScpAE = widget_label(wbaseSScpAE, value=' Storage SCP Application Entity ', $
                            xoffset=5)
  winfoLblSScpAE = widget_info(wLblSScpAE, /geometry)
  wbaseFrSScpAE = widget_base(wbaseSScpAE, /frame, yoffset=winfoLblSScpAE.ysize/2, $
                              xsize=xsize, /col, space=2, ypad=10, xpad=1, tab_mode=1)
  wLblSScpAE = widget_label(wbaseSScpAE, value=' Storage SCP Application Entity ', $
                            xoffset=5)


  wSScpr = widget_base(wbaseFrSScpAE,/row)
  wlblAENSScp = widget_label(wSScpr, value='Application Entity Name ', $
                             xsize=lxsize*textsize, /align_right)
  wcbAENSScp = widget_combobox(wSScpr, scr_xsize=lxsize*boxsize, $
                               event_pro='cw_dicomex_cbAENSScp_event')
  wSScpr = widget_base(wbaseFrSScpAE,/row)
  wlblSScpDir = widget_label(wSScpr, value='Storage SCP Dir ', $
                             xsize=lxsize*textsize, /align_right)
  wtxtSScpDir = widget_text(wSScpr, /editable, scr_xsize=lxsize*boxsize-30, $
                            ysize=1, uvalue=0, /all_events, $
                            event_PRO='cw_dicomex_wtxtGeneric_event')
  wbtnSScpDirBrowse = widget_button(wSScpr, value='...', $
                                    event_pro='cw_dicomex_wbtnSScpDirBrowse_event')
  wSScpr = widget_base(wbaseFrSScpAE, /row, xpad=30, space=10)
  wlblCtrlPort = widget_label(wSScpr, value='Control Port ', /align_right)
  wtxtCtrlPort = widget_text(wSScpr, /editable, xsize=6, ysize=1, uvalue=0, $
                             event_PRO='cw_dicomex_wtxtGeneric_event', /all_events)
  wlblFileExt = widget_label(wSScpr, value='File Extension ', /align_right)
  wtxtFileExt = widget_text(wSScpr, /editable, xsize=6, ysize=1, uvalue=0, $
                            event_PRO='cw_dicomex_wtxtGeneric_event', /all_events)
  wAABase = widget_base(wbaseFrSScpAE, /nonexclusive, /align_center)
  wbtnAccepAny = widget_button(wAABase, value=' Accept Any Application Entity Title', $
                               event_pro='cw_dicomex_btnAcceptAny_event')


  ; --------- add the stor scp service manager frame
  wbaseSSAE = widget_base(wBaseCol2)
  wLblSSAE = widget_label(wbaseSSAE, value=' Storage SCP Service Manager ', xoffset=5)
  winfoLblSSAE = widget_info(wLblSSAE, /geometry)
  wbaseFrSSAE = widget_base(wbaseSSAE, /frame, yoffset=winfoLblSScpAE.ysize/2, $
                            xsize=xsize, /col, space=2, ypad=10, xpad=1)
  wLblSSAE = widget_label(wbaseSSAE, value=' Storage SCP Service Manager ', xoffset=5)

  wSSBasec = widget_base(wbaseFrSSAE, /col)
  wSSBase = widget_base(wSSBasec, /row, xpad=20)
  wbtnStopService = widget_button(wSSBase, value=' Start Service ', $
                                  event_pro='cw_dicomex_btnStartService_event')
  wbtnStartService = widget_button(wSSBase, value=' Stop Service', $
                                   event_pro='cw_dicomex_btnStopService_event')

  wbtnServiceStatus = widget_button(wSSBase, value=' Update Service Status ', $
                                    event_pro='cw_dicomex_btnServiceStatus_event')
  wSSBaser = widget_base(wSSBasec, /row)
  wlblSStatus = widget_label(wSSBaser, value='Service Status ')
  wtxtServiceStatus = widget_text(wSSBaser, scr_xsize=lxsize*.69)


  ;---------- save and cance btns
  wRow = widget_base(wBaseCol2)
  wbtnSave = widget_button(wRow, value='Save', xsize=100, xoffset=175, $
                           yoffset=0, event_pro='cw_dicomex_btnSave_event')
  wbtnCancel = widget_button(wRow, value='Cancel', xsize=100, xoffset=280, $
                             yoffset=0, event_pro='cw_dicomex_btnCancel_event', $
                             accelerator='Escape')


  if (sysCfg eq 0) then begin
    widget_control, wlblAENSScp, sensitive=0
    widget_control, wcbAENSScp,  sensitive=0
    widget_control, wlblFileExt, sensitive=0
    widget_control, wtxtFileExt, sensitive=0
    widget_control, wlblSScpDir, sensitive=0
    widget_control, wtxtSScpDir, sensitive=0
    widget_control, wbtnSScpDirBrowse, sensitive=0
    widget_control, wbtnAccepAny, sensitive=0
    widget_control, wlblCtrlPort, sensitive=0
    widget_control, wtxtCtrlPort, sensitive=0
  endif

  if (sysCfg eq 1) then begin
    widget_control, wlblQR, sensitive=0
    widget_control, wcbAENQR, sensitive=0
    widget_control, wlblRsp, sensitive=0
    widget_control, wtxtMaxQRRsp, sensitive=0
    widget_control, wlblSScu, sensitive=0
    widget_control, wcbAENSScu, sensitive=0
  endif

  ;; desensitize control port if not on UNIX
  IF (!version.os_family EQ 'Windows') THEN BEGIN
    widget_control, wlblCtrlPort, sensitive=0
    widget_control, wtxtCtrlPort, sensitive=0
  ENDIF

  ; create a config object
  if (sysCfg eq 1) then begin
    ocfg = obj_new('IDLffDicomExCfg', /system)
  endif else begin
    ocfg = obj_new('IDLffDicomExCfg')
  endelse

  cfg_state = {parent:parent, ocfg:ocfg, sysCfg:sysCfg, wcbAENames:wcbAENames, $
               wtxtAEN:wtxtAEN, wtxtAET:wtxtAET, wtxtHost:wtxtHost, $
               wtxtPort:wtxtPort, wcbSLN:wcbSLN, wcbType:wcbType, $
               wcbEchoNodes:wcbEchoNodes, echo_node:'', wbtnEcho:wbtnEcho, $
               wtxtEchoStatus:wtxtEchoStatus, wcbAENEcho:wcbAENEcho, $
               wcbAENQR:wcbAENQR, wtxtMaxQRRsp:wtxtMaxQRRsp, $
               wcbAENSScu:wcbAENSScu, wcbAENSScp:wcbAENSScp, $
               wtxtFileExt:wtxtFileExt, wtxtSScpDir:wtxtSScpDir, $
               wbtnAccepAny:wbtnAccepAny, bAcceptAny:0, $
               wtxtCtrlPort:wtxtCtrlPort, wbtnStopService:wbtnStopService, $
               wbtnStartService:wbtnStartService, $
               wbtnServiceStatus:wbtnServiceStatus, $
               wtxtServiceStatus:wtxtServiceStatus, $
               callback:callbackRoutine, $
               wbtnSave:wbtnSave, wbtnCancel:wbtnCancel, $
               wbtnAENew:wbtnAENew, wbtnAEDelete:wbtnAEDelete, $
               wbaseEcho:wbaseEcho, wbaseEchoAE:wbaseEchoAE, $
               wbaseQRAE:wbaseQRAE, wbaseSScpAE:wbaseSScpAE, $
               wbaseSScuAE:wbaseSScuAE, wbaseSSAE:wbaseSSAE $
              }


  ;; passing a ptr is much more efficient
  pstate = ptr_new(cfg_state)

  ;; put the state ptr in the uvalue of the base state widget so all
  ;; events can get the state
  widget_control, wBaseState, set_uvalue=pstate

  return, wBase

end
