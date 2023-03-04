; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/dicomex/dicomex_net.pro#1 $
; Copyright (c) 1993-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;
; **********************************************************************
;
; Description:
;   This pro code presents the dicomex network dialog.
;   Invocation:
;
;       Dicomex_Net
;          This invocation operates against the users local config file
;
;      Dicomex_Net, /sys
;          This invocation operates against the system config file
;          The system config is used by the storage scp service.
;
;   This dialog presents 3 existing compound widgets in a tab format.
;   This dialog is just a simple container for displaying the
;   following widgets:
;      cw_dicomex_config
;      cw_dicomex_query
;      cw_dicomex_stor_scu
;
; MODIFICATION HISTORY:
;   LFG, RSI, October. 2004  Original version.
;   AGEH, RSI, December, 2004   Tweaked it a bit.  No real functional changes.

;;----------------------------------------------------------------------------
;; NAME
;;   dicomex_net_btnClose_event
;;
;; Purpose:
;;   Event handler for the close button
;;
;; Parameters:
;;   EV - widget event structure
;;
;; Keywords:
;;   NONE
;;
PRO dicomex_net_btnClose_event, ev
  compile_opt idl2, hidden
  on_error, 2

  wTab = widget_info(ev.top, find_by_uname='dlg_dicomex_net_tab_config')
  IF (wTab NE 0) THEN BEGIN
    childID = widget_info(wTab, /child)
    widget_control, childID, get_value=val
    IF ~val.dirty THEN BEGIN
      ;; make the ui go away
      widget_control, ev.top, /destroy
      return
    ENDIF ELSE BEGIN
      result = dialog_message(title='IDL Dicom Network Error', /cancel, $
                              /question, dialog_parent=ev.top, $
                              ['Configuration parameters have changed.', $
                               'Would you like to save them?'])
      IF (result EQ 'Cancel') THEN return
      IF (result EQ 'Yes') THEN BEGIN
        widget_control, childID, set_value={SAVE, save:1}
      ENDIF
    ENDELSE
  ENDIF

  ;; make the ui go away
  widget_control, ev.top, /destroy

END

;;----------------------------------------------------------------------------
;; NAME
;;   dicomex_net_btnHelp_event
;;
;; Purpose:
;;   Event handler for the help button.  Displays the contents of a
;;   help file using XDisplayFile.
;;
;; Parameters:
;;   EV - widget event structure
;;
;; Keywords:
;;   NONE
;;
PRO dicomex_net_btnHelp_event, ev
  compile_opt idl2, hidden
  on_error, 2

  wTab = widget_info(ev.top, /child)
  tNum = widget_info(wTab, /tab_current)
  system = widget_info(wTab, /tab_number) EQ 1
  helpFile = 'DICOMEX_NET_'

  CASE tNum OF
    0 : helpFile += system ? 'SYSTEM' : 'LOCAL'
    1 : helpFile += 'QUERY'
    2 : helpFile += 'STORESCU'
    ELSE :
  ENDCASE

  IF (helpFile NE 'DICOMEX_NET_') THEN $
    online_help, helpFile

END

;;----------------------------------------------------------------------------
;; NAME
;;   dicomex_net_on_save_callback
;;
;; Purpose:
;;   this callback method is called by the compound config widget when
;;   the save btn is pressed AND this routine was specified as the
;;   callback routine
;;
;; Parameters:
;;   ID - widget id
;;
;; Keywords:
;;   NONE
;;
PRO dicomex_net_on_save_callback, id
  compile_opt idl2, hidden

  ;; the config file was updated so refresh the query and stor scu
  ;; widgets.
  ;; Call set_value on each widget sending a structure named "Refresh"
  ;; containing a single field, "refresh".  If the value of refresh is
  ;; anything other than 1 then a refresh will occur.


  ;; if the tab is displayed then refresh the child widget inside the tab
  wTab = widget_info(id, find_by_uname='wTab_qrui')
  IF (wTab NE 0) THEN BEGIN
    childID = widget_info(wTab, /child)
    widget_control, childID, set_value={REFRESH, refresh:1}
  ENDIF

  ; if the tab is displayed then refresh the child widget inside the tab
  wTab = widget_info(id, find_by_uname='wTab_scui')
  IF (wTab NE 0) THEN BEGIN
    childID = widget_info(wTab, /child)
    widget_control, childID, set_value={REFRESH, refresh:1}
  ENDIF

END

;;----------------------------------------------------------------------------
;; NAME
;;   dicomex_net_event
;;
;; Purpose:
;;   Swallow all but the kill events
;;
;; Parameters:
;;   EV - widget event structure
;;
;; Keywords:
;;   NONE
;;
PRO dicomex_net_event, ev
  compile_opt idl2, hidden

  ;; fake a button close event
  IF TAG_NAMES(ev, /STRUCTURE_NAME) EQ 'WIDGET_KILL_REQUEST' THEN $
    dicomex_net_btnClose_event, ev

END

;;----------------------------------------------------------------------------
;; NAME
;;   dicomex_net
;;
;; Parameters:
;;   NONE
;;
;; Keywords:
;;   SYSTEM - if set, use the system config file instead of the local
;;            user config file
;;
pro dicomex_net, system=sys
  compile_opt idl2
  on_error, 2

  ; this pro code is really just a container for the 3 compound widgets that
  ; make up the functionality of the dicomex dialog

  ; when the system keyword is Not set we will use the local user config file
  ; when the system keyword is set we will use the system config
  sysCfg = keyword_set(sys)

  ; the errors caught in the compound widget's main init routine bubble up to this level.
  ; if there is an error it is displayed and this dialog exits

  catch, errorStatus
  if (errorStatus ne 0) then begin
    catch,/cancel
    r = dialog_message(!error_state.msg, $
                       title='IDL Dialog Dicom Network Services Error', $
                       dialog_parent=cwBase, /error)
    return
  ENDIF

  titlecfg = ' (' + (sysCfg ? 'System' : 'Local') + ' Configuration)'

  ; root level widget for this ui
  cwBase = widget_base(/column, TITLE='IDL Dicom Network Services'+titlecfg, $
                       uname='dlg_dicomex_net', tlb_frame_attr=1, $
                       /tlb_kill_request_events)
  wTab = widget_tab(cwBase)

  ; create the config tab
  ;; note the parent of the compound config widget has it uname and
  ;; uvalue set so that it will make a callback when the save config
  ;; file btn is pressed...this callback is optional
  wTab1 = widget_base(wTab, title='    Configuration     ',/row, $
                      uname='dlg_dicomex_net_tab_config', uvalue=cwBase)
  cfg = cw_dicomex_config(wTab1, SYSTEM_CONFIGURATION=sysCfg, $
                          CALLBACKROUTINE='dicomex_net_on_save_callback')

  ; we do not show the query and stor scu tab when editing the system config
  if (sysCfg eq 0) then begin
    ; create the query retrieve tab
    wTab2 = widget_base(wTab, title='  Query Retrieve SCU  ',/row, $
                        uname='wTab_qrui')
    qrui = cw_dicomex_query(wTab2)

    ; create the storage scu tab
    wTab3 = widget_base(wTab, title='     Storage SCU      ',/row, $
                        uname='wTab_scui')
    scui = cw_dicomex_stor_scu(wTab3)
  endif

  ; add the close button to the tab container
  wRow = widget_base(cwBase, /row, /align_right, space=5)
  wbtnHelp = widget_button(wRow, value='Help', xsize=100, $
                            event_pro = 'dicomex_net_btnHelp_event')
  wbtnClose = widget_button(wRow, value='Close', xsize = 100, $
                            event_pro = 'dicomex_net_btnClose_event')

  ; draw the ui
  widget_control, cwBase, /real

  ;; The XMANAGER procedure provides the main event loop and
  ;; management for widgets created using IDL.  Calling XMANAGER
  ;; "registers" a widget program with the XMANAGER event handler,
  ;; XMANAGER takes control of event processing until all widgets have
  ;; been destroyed.

  ;; NO BLOCK needs to be set 0 in order for the build query events to
  ;; fire
  XMANAGER,'dicomex_net', cwBase, GROUP=group, NO_BLOCK=0

END
