; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/ui_widgets/idlitwdabout.pro#1 $
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   IDLitwdAbout
;
; PURPOSE:
;   This function implements the About box
;
; CALLING SEQUENCE:
;    IDLitwdAbout, wLeader
;
; INPUTS:
;     wLeader - Group leader for this modal widget
;
; OUTPUTS
;    None, but this is modal
; RETURN VALUE
;
; KEYWORD PARAMETERS:
;    Standard Widget keywords.
;
; MODIFICATION HISTORY:
;   KDB July 02
;   Modified:
;
;-


;;-------------------------------------------------------------------------
;; IDLitwdAbout__event
;;
;; Purpose:
;;    Event handler for this interface
;;
;;
pro IDLitwdAbout_event, event

    compile_opt idl2, hidden

    ;; Error trapping
@idlit_catch
    if(iErr ne 0)then begin
        catch, /cancel
        if(n_elements(state) gt 0)then $
          Widget_Control, event.top, set_uvalue=state,/no_copy
        return
    end
    Widget_control, event.id, get_uvalue=uval
    if(n_elements(uval) gt 0)then begin
        if(uval eq 'close')then  $
          widget_control, event.top, /destroy
    endif
end

;;-------------------------------------------------------------------------
;; See file header for API
;;
function  IDLitwdAbout,  oUI, oRequest
   compile_opt idl2, hidden

@idlitconfig

   strAbout= $
     [IDLitLangCatQuery('UI:wdAbout:Line01'), $
      IDLitLangCatQuery('UI:wdAbout:Line02'), $
      IDLitLangCatQuery('UI:wdAbout:Line03')+ITOOLS_STRING_VERSION, $
      IDLitLangCatQuery('UI:wdAbout:Line04')+!version.release, $
      IDLitLangCatQuery('UI:wdAbout:Line05'), $
      IDLitLangCatQuery('UI:wdAbout:Line06'), $
      IDLitLangCatQuery('UI:wdAbout:Line07'), $
      IDLitLangCatQuery('UI:wdAbout:Line08'), $
      IDLitLangCatQuery('UI:wdAbout:Line09'), $
      IDLitLangCatQuery('UI:wdAbout:Line10'), $
      IDLitLangCatQuery('UI:wdAbout:Line11'), $
      IDLitLangCatQuery('UI:wdAbout:Line12'), $
      IDLitLangCatQuery('UI:wdAbout:Line13')]

    oUI->GetProperty, group_leader=wLeader
   ;; Keyword Validation
    title = (N_ELEMENTS(titleIn) gt 0) ? titleIn[0] : $
      IDLitLangCatQuery('UI:wdAbout:Title')

   if(WIDGET_INFO(wLeader, /valid) eq 0)then $
     Message, IDLitLangCatQuery('UI:wdAbout:BadLeader')

   ;; Okay, create our modal TLB
   wTLB = Widget_Base( /MODAL, GROUP_LEADER=wLeader, $
                       TLB_FRAME_ATTR=1, $
                       /BASE_ALIGN_RIGHT, $
                       /COLUMN, $
                       SPACE=2, $
                       TITLE=title,  $
                       _EXTRA=_extra)

   ;; Now our one base
   wBase = Widget_Base(wTLB, /row )

   ;; Get the image
   bHaveImg = IDLitGetResource("itools_about", img)
   if(bHaveImg)then begin
       szImage = size(img)
       wDraw = widget_draw(wBase, xsize=szImage[1], ysize=szImage[2], retain=2)
   endif
   bBase = widget_base(wBase,/column)
    ; Cannot guarantee the existence of fonts on Motif, but can on Windoze
   if (!version.os_family eq 'Windows') then $
     font = 'Helvetica*24'
   void = widget_label(bBase, /align_left, value=strAbout[0], font=font)
   for i=1, n_elements(strAbout)-1 do $
       void = widget_label(bBase, /align_left, value=strAbout[i])


   ;; Add a Close button.
   wBBase = Widget_base(wTLB, /align_center,/row,  space=3)
   wOK = Widget_Button(wBBase, VALUE=IDLitLangCatQuery('UI:wdAbout:OK'), $
                       UVALUE="close")

   widget_control, wTLB, cancel_button=wOK

   widget_control, wTLB, /REALIZE

   if(bHaveImg)then begin
       Widget_Control, wDraw, get_value=idxDraw
       wset,idxDraw
       device,decompose=1
       tv,img, true=3

   endif
   ;; Call xmanager, which will block until the dialog is closed


   xmanager, 'IDLitwdAbout', wTLB

   return, 1
end
