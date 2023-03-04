; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/components/idlitopfittoview__define.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;
;---------------------------------------------------------------------------
; Class Name:
;   IDLitopFitToView
;
; Purpose:
;   This class implements an operation that fits the selected
;   item to its view by appropriately setting the view zoom
;   factor.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------

;---------------------------------------------------------------------------
; Name:
;   IDLitopFitToView::Init
;
; Purpose:
;   This function method initializes the object.
;
; Keywords:
;   This method accepts all keywords supported by the ::Init method
;   of this object's superclass.
;
function IDLitopFitToView::Init, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    if (self->IDLitOperation::Init(NAME="Fit To View", $
        DESCRIPTION='Fit selection to the view', $
        _EXTRA=_extra) eq 0) then $
        return, 0

    return, 1
end

;---------------------------------------------------------------------------
; Name:
;   IDLitopFitToView::Cleanup
;
; Purpose:
;   This procedure method performs all cleanup on the object.
;
;pro IDLitopFitToView::Cleanup
;
;    compile_opt idl2, hidden
;
;    ; Cleanup superclass.
;    self->IDLitOperation::Cleanup
;end

;---------------------------------------------------------------------------
; Property Interface
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; Name:
;   IDLitopFitToView::GetProperty
;
; Purpose:
;   This procedure method retrieves the value of a property or group of
;   properties.
;
; Keywords:
;   This method accepts all keywords supported by the ::GetProperty
;   method of this object's superclass.  Furthermore, any keyword to 
;   IDLitopFitToView::Init followed by the word "Get" can be retrieved
;   using this method.
;
;pro IDLitopFitToView::GetProperty, $
;    _REF_EXTRA=_extra
;
;    compile_opt idl2, hidden
;
;    ; Call superclass.
;    if (N_ELEMENTS(_extra) gt 0) then $
;        self->IDLitOperation::GetProperty, _EXTRA=_extra
;end

;---------------------------------------------------------------------------
; Name:
;   IDLitopFitToView::SetProperty
;
; Purpose:
;   This procedure method sets the value of a property or group of
;   properties.
;
; Keywords:
;   This method accepts all keywords supported by the ::SetProperty
;   method of this object's superclass.  Furthermore, any keyword to 
;   IDLitopFitToView::Init followed by the word "Set" can be set
;   using this method.
;
;pro IDLitopFitToView::SetProperty, $
;    _REF_EXTRA=_extra
;
;    compile_opt idl2, hidden
;
;    ; Call superclass.
;    if (N_ELEMENTS(_extra) gt 0) then $
;        self->IDLitOperation::SetProperty, _EXTRA=_extra
;end

;---------------------------------------------------------------------------
; Pixel Scale Interface
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; Name:
;   IDLitopFitToView::_Targets
;
; Purpose:
;   This internal function method retrieves the list of targets
;   for this operation.
;
; Return Value:
;   This method returns a vector of object references to
;   the targets found for this operation.
;
; Arguments:
;   oTool:	A reference to the tool object in which this
;     operation is being performed.
;
; Keywords:
;   COUNT:	Set this keyword to a named variable that upon
;     return will contain the number of returned targets.
;
function IDLitopFitToView::_Targets, oTool, COUNT=count

    compile_opt idl2, hidden

    count = 0

    if (OBJ_VALID(oTool) eq 0) then $
        return, OBJ_NEW()

    ; Retrieve the currently selected item(s) in the tool.
    oSelVis = oTool->GetSelectedItems(COUNT=nSel)
    if (nSel eq 0) then $
      return, OBJ_NEW()
    if (OBJ_VALID(oSelVis[0]) eq 0) then $
        return, OBJ_NEW()

    count = nSel

    return, oSelVis
end

;---------------------------------------------------------------------------
; Operation Interface
;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
; Name:
;   IDLitopFitToView::DoAction
;
; Purpose:
;   This function method performs the primary action associated with
;   this operation, namely to fit the targets to the viewport.
;
; Return Value:
;   This function returns a reference to the command set object
;   corresponding to the act of performing this operation.
;
; Arguments:
;   oTool:	A reference to the tool object in which this operation
;     is to be performed.
;
function IDLitopFitToView::DoAction, oTool

    compile_opt idl2, hidden

    self->_SetTool, oTool

    ; Retrieve the targets from among the selected items.
    oManipTargets = self->IDLitopFitToView::_Targets(oTool, COUNT=count)
    if (count eq 0) then $
        return, OBJ_NEW()

    ; Walk up to the view.
    oManipTargets[0]->GetProperty, PARENT=oParent
    while (~OBJ_ISA(oParent, 'IDLitgrView')) do begin
        if (~OBJ_VALID(oParent)) then $
            break
        oChild = oParent
        oChild->GetProperty, PARENT=oParent
    endwhile
    if (~OBJ_VALID(oParent)) then $
        return, OBJ_NEW()
    oView = oParent

    ; Retrieve our SetSubView service.
    oSetSubViewOp = oTool->GetService('SET_SUBVIEW')
    if (not OBJ_VALID(oSetSubViewOp)) then $
        return, OBJ_NEW()

    ; Create command set.
    oCmdSet = OBJ_NEW('IDLitCommandSet', $
        NAME='Fit to View', $
        OPERATION_IDENTIFIER=oSetSubViewOp->GetFullIdentifier())

    ; Record initial values for undo.
    iStatus = oSetSubViewOp->RecordInitialValues(oCmdSet, $
        oView, 'CURRENT_ZOOM')
    if (~iStatus) then begin
        OBJ_DESTROY, oCmdSet
        return, OBJ_NEW()
    endif

    oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled

    oView->ZoomToFit, oManipTargets

    ; Since this operation changes view zooming, the current manipulator
    ; visuals for the tool may need to be reconfigured for the new zoom
    ; factor.
    oManip = oTool->GetCurrentManipulator()
    oWin = oTool->GetCurrentWindow()
    if (OBJ_VALID(oWin)) then $
      oManip->ResizeSelectionVisuals, oWin

    if (~wasDisabled) then $
       oTool->EnableUpdates

    ; Record final values for redo.
    iStatus = oSetSubViewOp->RecordFinalValues( oCmdSet, $
        oView, 'CURRENT_ZOOM')
    if (~iStatus) then begin
        OBJ_DESTROY, oCmdSet
        return, OBJ_NEW()
    endif

    return, oCmdSet
end

;-------------------------------------------------------------------------
; Object Definition
;-------------------------------------------------------------------------
;-------------------------------------------------------------------------
; IDLitopFitToView__Define
;
; Purpose:
;   Define the object structure for the IDLitopFitToView class.
;
pro IDLitopFitToView__define

    compile_opt idl2, hidden

    struc = {IDLitopFitToView,    $
        inherits IDLitOperation   $
    }

end

