;; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/ui_widgets/idlitwdcommandlineimport.pro#1 $
;;
;; Copyright (c) 2003-2006, Research Systems, Inc.  All rights reserved.
;;       Unauthorized reproduction prohibited.
;;
;; Purpose:
;;   This file implements the logic that allows a user to select an
;;   item from the command line and import that value into IDL. It
;;   uses a tree view metaphore to allow the user to drill down in
;;   variables.

;;-------------------------------------------------------------------------
;; IDLitwdCommandLineImport_EVENT
;;
;; Purpose:
;;   Event handler for the command line browser.
;;
;; Parameter:
;;   sEvent  - The widget event.
;;
PRO  IDLitwdCommandLineImport_EVENT, sEvent
  compile_opt idl2, hidden

@idlit_catch
  if(iErr ne 0)then begin
      catch, /cancel
      return
  end
  widget_control, sEvent.top, get_uvalue=pState
  message = widget_info(sEvent.id, /uname)

  case message of
      ;; Tree Event? If so, update display values
      'TREE': begin
          oItem = (*pState).oRoot->GetByIdentifier(sEvent.identifier)
          oItem->getProperty, desc=desc, shape=shape, $
            type_name=type_name, TYPE_CODE=tcode, data_types=dTypes
          ;; no containers or objects
          sensitive = ~(obj_isa(oItem, "IDLitContainer") or (tcode eq 11))
          widget_control, (*pState).wOK, $
            sensitive=sensitive
          widget_control, (*pState).wName, set_value=desc
          widget_control, (*pState).wType, set_value=type_name
          widget_control, (*pState).wValue, set_value=shape
          widget_control, (*pState).wData, $
            set_value=(~sensitive ? '':desc)
          widget_control, (*pState).wDataType, set_value=dTypes
      end
      'OK':begin ;; Import Button selected

          ;; What was selected?
          widget_control, (*pState).wTree, get_value=idSel
          if(idSel eq '')then return
          widget_control, (*pState).wData, get_value=dName
          iType = widget_info((*pState).wDataType, /droplist_select)
          oItem = (*pState).oRoot->GetByIdentifier(idSel)
          oTool = (*pState).oUI->GetTool()
          oCL = oTool->GetService("COMMAND_LINE")
          if(obj_valid(oCL))then begin
            oItem->getproperty, data_type=dType
            dType = dType[iType]
            iStatus = oCL->ImportToDMByDescriptor((*pState).oRoot,  $
                                                  oItem, name=dName, $
                                                  DATA_TYPE=dType)
            if(iStatus eq 0)then begin
              void = dialog_message(IDLitLangCatQuery('UI:wdCLImport:Error'), $
                       title=IDLitLangCatQuery('UI:wdCLImport:ErrorTitle'), $
                       /ERROR, dialog_parent=sEvent.top)
            endif
          endif
          widget_control, sEvent.top, /destroy
      end
      'CANCEL':widget_control, sEvent.top, /destroy;; just kill the beast
    else:
  endcase
end

;;-------------------------------------------------------------------------
;; IDLitwdCommandLineImport
;;
;; Purpose:
;;   This widget routine will present the user with the  contents of
;;   the commandline and allow them to import the values to the data
;;   manager. The command line is displayed as a tree view, allowing
;;   the user to drill down structs and pointers.
;;
;;   This widget is modal
;;
;; Parameters:
;;    oUI   - The uI object
;;
;;    GROUP_LEADER - The widgets group leader
;;
;;    XSIZE   - The xsize of this widget
;;
;;    YSIZE   - The ysize of this widget
;;
;;    All other keywords are passed to the widget system

function IDLitwdCommandLineImport, oUI, $
                                   GROUP_LEADER=GROUP_LEADER, $
                                   TITLE=TITLE, $
                                   XSIZE=XSIZE, $
                                   YSIZE=YSIZE, $
                                   _EXTRA=_extra

   compile_opt idl2, hidden

   ;; check defaults
   if(not keyword_set(TITLE))then $
     title=IDLitLangCatQuery('UI:wdCLImport:Title')

   if(not keyword_set(XSIZE))then $
     XSIZE =450

   if(not keyword_set(YSIZE))then $
     YSIZE =400

   ;; Get the needed variable information from the command line
   ;; service in the tool. This will return a component hierarchy of
   ;; the cl contents.
   oTool = oUI->GetTool()
   oCL = oTool->GetService("COMMAND_LINE")
   if(obj_valid(oCL))then begin
       oRoot = oCL->GetCLVariableDescriptors()
       nVars=1
   endif else begin
       oRoot=obj_new()
       nVars=0
   end

   ;; Build our widget. This is modal
   wTLB = Widget_Base(/column, /floating, $
                      GROUP_LEADER=GROUP_LEADER, $
                      /modal, $
                      title=title, $
                      _extra=_extra)

   ;; Now for the tree display of the command line.
   wBCL = widget_base(wTLB, /ROW, space=8)
   wTree = cw_itComponentTree(wBCL, oUI, oRoot, $
                              /NO_CONTEXT, $
                              ysize = ysize *.7, $
                              xsize = xsize*.6, $
                              uname="TREE")

    ;; Selected item display area.
    wBDisplay = widget_base(wBCL, /column, space=6)
    ;; Name
    wBase = Widget_Base(wBDisplay,/column)
    wTmp = Widget_Label(wBase, $
                        value=IDLitLangCatQuery('UI:wdCLImport:VarName'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wName = Widget_Label(wTmp, value=' ', $
                         scr_xsize=xsize*.4,/align_left)
    ;; Type
    wBase = Widget_Base(wBDisplay,/column)
    wTmp = Widget_Label(wBase, value=IDLitLangCatQuery('UI:wdCLImport:Type'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wType = Widget_Label(wTmp, value=' ', $
                         scr_xsize=xsize*.4,/align_left)

    ;; Value
    wBase = Widget_Base(wBDisplay,/column)
    wTmp = Widget_Label(wBase, $
                        value=IDLitLangCatQuery('UI:wdCLImport:Value'), $
                        /align_left)
    wTmp = Widget_base(wBase,/row, xpad=10, space=5)
    wValue = Widget_Label(wTmp, value=' ', $
                         scr_xsize=xsize*.4,/align_left)

    wBase = Widget_Base(wBDisplay,/column)
    wTmp = Widget_Label(wBase, $
                        value=IDLitLangCatQuery('UI:wdCLImport:DataName'), $
                        /align_left)
    wBImport = Widget_base(wBase,/row, xpad=10, space=5)
    wData = Widget_Text(wBImport, xsize=20, /editable, uname="DATANAME")

    wBase = Widget_Base(wBDisplay,/column)
    wTmp = Widget_Label(wBase, $
                        value=IDLitLangCatQuery('UI:wdCLImport:ImType'), $
                        /align_left)
    wBImport = Widget_base(wBase,/row, xpad=10, space=5)
    wDataType = Widget_DropList(wBImport, /dynamic)

    ;; Now the bottom, button
    wButtons = Widget_Base(wTLB, /align_right, /row, space=5)

    wOK = Widget_Button(wButtons, VALUE=IDLitLangCatQuery('UI:OK'), $
                        uname='OK', sensitive=0)
    wCancel = Widget_Button(wButtons, VALUE=IDLitLangCatQuery('UI:Cancel'), $
                            uname='CANCEL')
    geomCan = widget_info(wCancel, /geometry)
    widget_control, wOK, scr_xsize=geomCan.scr_xsize, $
                         scr_ysize=geomCan.scr_ysize

    ;; our state.
    state = { wName          : wName,       $
              wType          : wType,       $
              wValue         : wValue,      $
              wTree          : wTree,       $
              wOK            : wOK,         $
              wData          : wData,       $
              oUI            : oUI,         $
              wDataType      : wDataType,   $
              oRoot          : oRoot}

    ;; Place state in a pointer and note that we set the cancel  button.
    pState = ptr_new(state, /no_copy)
    widget_control, wTLB, set_uvalue=pState, /realize, cancel_button=wCancel

    xmanager, 'IDLitwdCommandLineImport', wTLB, NO_BLOCK=0

    ;; We are back

    ;; Return the CL objects to the command line service for
    ;; destruction
   if(obj_valid(oCL))then $
       oCL->ReturnCLDescriptors, (*pState).oRoot

    ptr_free, pState

    return, 1

end

