;; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/dicomex/dicomex_net_startup.pro#1 $
;; Copyright (c) 2005-2006, Research Systems, Inc.  All rights reserved.
;;   Unauthorized reproduction prohibited.
;;+
;; NAME:
;;   dicomex_net_startup
;;
;; PURPOSE:
;;   This displays a dialog asking the user to choose in which mode to
;;   start the dicomex_net routine.
;;
;; CALLING SEQUENCE:
;;   dicomex_net_startup
;;
;; INPUTS:
;;   NONE
;;
;; KEYWORD PARAMETERS:
;;   NONE
;;
;; MODIFICATION HISTORY:
;;   Written by:  AGEH, RSI, January 2005
;;
;;-

;;----------------------------------------------------------------------------
;; NAME
;;   dicomex_net_startup_event
;;
;; Purpose:
;;   Event handler.  Calls appropriate dicomex_net then kills self
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
PRO dicomex_net_startup_event, ev
  compile_opt idl2, hidden

  ;; get uname of button
  name = widget_info(ev.id, /uname)

  ;; invoke proper routine
  CASE name OF
    'local' : BEGIN
      ;; destory this widget
      widget_control, ev.top, /destroy
      dicomex_net
    END
    'system' : BEGIN
      ;; destory this widget
      widget_control, ev.top, /destroy
      dicomex_net, /system
    END
    'help' : BEGIN
      ;; display help text
      title = 'IDL Dicom Network Utility Startup Help'
      str = ['You can start the IDL Dicom Network Services Utility in either', $
             'Local mode or System mode.', $
             ' ', $
             '* Start the utility in System mode to define an Application', $
             '  Entity for a local Storage SCP service.', $
             ' ', $
             '* Start the utility in Local mode to perform queries, retrieve', $
             '  files, or store files.', $
             ' ', $
             'You can define Application Entities other than the local', $
             'Storage SCP service in either Local or System mode.']

      xdisplayfile, '', /modal, title=title, text=str, $
                    height=n_elements(str)+1, width=max(strlen(str))
      ;; restore focus to button
      widget_control, ev.id, /input_focus
    END
    'cancel' : BEGIN
      ;; destroy this widget
      widget_control, ev.top, /destroy
    END
    ELSE :
  ENDCASE

END


;;----------------------------------------------------------------------------
;; NAME
;;   dicomex_net_startup
;;
;; Purpose:
;;   Main routine.  Builds widget.
;;
PRO dicomex_net_startup
  compile_opt idl2, hidden

  ;; get screen size so widget can be displayed near screen center
  sz = get_screen_size()

  tlb = widget_base(/column, tlb_frame_attr=1, space=10, xpad=10, ypad=10, $
                    xoffset=sz[0]*0.45, yoffset=sz[1]*0.35, $
                    title='IDL Dicom Network Utility Startup')
  ;; base for text
  textBase = widget_base(tlb, /align_center, /column)
  ;; text to be displayed
  txt = ['Do you want to start the IDL Dicom Network Services', $
         'Utility in Local mode or System mode?']
  ;; add text to widget
  FOR i=0,n_elements(txt)-1 DO $
    wTxt = widget_label(textBase, value=txt[i])

  ;; base for buttons
  buttonBase = widget_base(tlb, /align_center, /row, /grid, $
                           space=5, /tab_mode)
  wLocal = widget_button(buttonBase, value='  Local  ', uname='local')
  wSystem = widget_button(buttonBase, value='  System  ', uname='system')
  wCancel = widget_button(buttonBase, value='  Cancel  ', uname='cancel')
  wHelp = widget_button(buttonBase, value='  Help  ', uname='help')

  widget_control, tlb, /realize
  ;; set initial focus to local button
  widget_control, wLocal, /input_focus

  xmanager, 'dicomex_net_startup', tlb

END
