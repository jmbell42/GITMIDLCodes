; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/framework/idlitmanipviewzoom__define.pro#1 $
;
; Copyright (c) 2001-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitManipViewZoom
;
;-

;----------------------------------------------------------------------------
;+
; METHODNAME:
;       IDLitManipViewZoom::Init
;
; PURPOSE:
;       The IDLitManipViewZoom::Init function method initializes the
;       component object.
;
;       NOTE: Init methods are special lifecycle methods, and as such
;       cannot be called outside the context of object creation.  This
;       means that in most cases, you cannot call the Init method
;       directly.  There is one exception to this rule: If you write
;       your own subclass of this class, you can call the Init method
;       from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;       oManipulator = OBJ_NEW('IDLitManipViewZoom')
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;   Written by:
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitManipViewZoom::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
function IDLitManipViewZoom::Init, $
    _REF_EXTRA=_extra
    ; pragmas
    compile_opt idl2, hidden

    ; Init our superclass
    iStatus = self->IDLitManipulator::Init( $
        VISUAL_TYPE="Select", $
        IDENTIFIER="ManipViewZoom", $
        OPERATION_IDENTIFIER="SET_PROPERTY", $
        PARAMETER_IDENTIFIER="CURRENT_ZOOM", $
        /SKIP_MACROHISTORY, $
        NAME="View Zoom", $
        _EXTRA=_extra)
    if (iStatus eq 0) then $
        return, 0

    self.origZoom = 1.0
    self.radius = 1.0

   ; Register the default cursor for this manipulator.
    self->IDLitManipViewZoom::_DoRegisterCursor

    ; Set properties.
    self->IDLitManipViewZoom::SetProperty, _EXTRA=_extra

    return, 1
end

;--------------------------------------------------------------------------
; IDLitManipViewZoom::Cleanup
;
; Purpose:
;  The destructor of the component.
;
;pro IDLitManipViewZoom::Cleanup
;    ; pragmas
;    compile_opt idl2, hidden
;
;    self->IDLitManipulator::Cleanup
;end


;--------------------------------------------------------------------------
; IDLitManipViewZoom::OnMouseDown
;
; Purpose:
;   Implements the OnMouseDown method. This method is often used
;   to setup an interactive operation.
;
; Parameters
;   oWin    - Source of the event
;   x       - X coordinate
;   y       - Y coordinate
;   iButton - Mask for which button pressed
;   KeyMods - Keyboard modifiers for button
;   nClicks - Number of clicks
pro IDLitManipViewZoom::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks, $
    NO_SELECT=noSelect

    ; pragmas
    compile_opt idl2, hidden

    ; Call superclass.
    self->IDLitManipulator::OnMouseDown, oWin, x, y, iButton, $
        KeyMods, nClicks

    ; Retrieve a reference to the current view (to be zoomed).
    self.oCurrView = oWin->GetCurrentView()
    if (OBJ_VALID(self.oCurrView) eq 0) then $
        return
    self.nSelectionList = 1
    *self.pSelectionList = self.oCurrView

    ; Retrieve the viewport information.
    viewportDims = self.oCurrView->GetViewport(oWin, LOCATION=viewportLoc)

    ; Retrieve the original zoom factor from the current view.
    self.oCurrView->GetProperty, CURRENT_ZOOM=zoom
    self.origZoom = zoom
    self.viewportLoc = ULONG(viewportLoc)

    ; Temporarily disable pixel scale enforcement on the view.
    self.oCurrView->DisablePixelScale

    ; Compute the initial radius.
    self.radius = y - viewportLoc[1]

    ; Record the current values.
    iStatus = self->RecordUndoValues()
end


;--------------------------------------------------------------------------
pro IDLitManipViewZoom::_CaptureMacroHistory, $
    zoom, $
    MOUSE_MOTION=mouseMotion

    compile_opt idl2, hidden

    oTool = self->GetTool()
    oSrvMacro = oTool->GetService('MACROS')
    if obj_valid(oSrvMacro) then begin
        oSrvMacro->GetProperty, $
            RECORDING=recording, $
            MANIPULATOR_STEPS=manipulatorSteps
        skipMacro = 0
        skipHistory = 0
        if recording && manipulatorSteps then begin
            if keyword_set(mouseMotion) then begin
                ; add each individual manipulation to macro
                ; don't add individual manipulation to history
                skipHistory = 1
            endif else skipMacro = 1    ; overall added to history but not macro
        endif else begin
            ; add overall manipulation to both macro and history
            ; skip the individual manipulations
            if keyword_set(mouseMotion) then return
        endelse

        idSrc = "/Registry/MacroTools/Zoom"
        oDesc = oTool->GetByIdentifier(idSrc)
        if obj_valid(oDesc) then begin
            oDesc->SetProperty, $
                ZOOM_PERCENTAGE=zoom*100
            oSrvMacro->GetProperty, CURRENT_NAME=currentName
            oSrvMacro->PasteMacroOperation, oDesc, currentName, $
                SKIP_MACRO=skipMacro, $
                SKIP_HISTORY=skipHistory
        endif
    endif
end

;--------------------------------------------------------------------------
; IDLitManipViewZoom::OnMouseUp
;
; Purpose:
;   Implements the OnMouseUp method. This method is often used to
;   complete an interactive operation.
;
; Parameters
;   oWin    - Source of the event
;   x       - X coordinate
;   y       - Y coordinate
;   iButton - Mask for which button released
;
pro IDLitManipViewZoom::OnMouseUp, oWin, x, y, iButton
    ; pragmas
    compile_opt idl2, hidden

    if (OBJ_VALID(self.oCurrView) eq 0) then begin
        ; Call superclass.
        self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton

        return
    endif

    ; Re-enable pixel scale enforcement on the view.
    self.oCurrView->EnablePixelScale

    ; Determine if zoom factor ever changed.
    self.oCurrView->GetProperty, CURRENT_ZOOM=zoom
    noChange = (self.origZoom eq zoom)

    ; Commit this transaction
    oTool = self->GetTool()
    self->GetProperty, OPERATION_IDENTIFIER=idOp
    oOp = oTool->GetByIdentifier('/SERVICES/'+idOp)
    oOp->SetProperty, CURRENT_ZOOM=zoom

    iStatus = self->CommitUndoValues(UNCOMMIT=noChange)

    self->_CaptureMacroHistory, zoom

    if (~noChange) then begin
        ; This manipulation may cause a change in availability
        ; (particularly for operations and manipulators that
        ; are available only if the view zoom factor is a
        ; certain value.)
        oTool->UpdateAvailability
    endif

    ; Call superclass.
    self->IDLitManipulator::OnMouseUp, oWin, x, y, iButton

end


;--------------------------------------------------------------------------
; IDLitManipViewZoom::OnMouseMotion
;
; Purpose:
;   Implements the OnMouseMotion method.
;
; Parameters
;  oWin    - Event Window Component
;  x   - X coordinate
;  y   - Y coordinate
;  KeyMods - Keyboard modifiers for button

pro IDLitManipViewZoom::OnMouseMotion, oWin, x, y, KeyMods
    ; pragmas
    compile_opt idl2, hidden

    if ((~OBJ_VALID(self.oCurrView)) || $
        (self.ButtonPress eq 0)) then begin
        ; Simply pass control to superclass.
        self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods
        return
    endif

    ; Compute the new radius.
    newRadius = (y - self.viewportLoc[1]) > 1

    ; Compute the new zoom factor (using the ratio of the radii
    ; as a scale factor for the original zoom factor).
    scaleFactor = newRadius / self.radius
    newZoom = self.origZoom*scaleFactor

    ; Restrict to one-hundredths, > 1%, < some large %.
    newZoom = (1 > LONG(newZoom*100) < 999999)/100d

    ; Apply the new zoom factor.
    self.oCurrView->SetCurrentZoom, newZoom

    probeStr = IDLitLangCatQuery('Status:Framework:ViewZoomManip') + $
        STRTRIM(ULONG((newZoom*100)+0.5),2)+'%'
    self->ProbeStatusMessage, probeStr

    self->_CaptureMacroHistory, newZoom, $
        /MOUSE_MOTION

    ; Call our superclass.
    self->IDLitManipulator::OnMouseMotion, oWin, x, y, KeyMods
end


;;--------------------------------------------------------------------------
;; IDLitManipViewZoom::_DoRegisterCursor
;;
;; Purpose:
;;   Register the cursor used with this manipulator with the system
;;   and set it as the default.
;;
pro IDLitManipViewZoom::_DoRegisterCursor

    compile_opt idl2, hidden

    strArray = [ $
        '     .....      ', $
        '    .#####.     ', $
        '   .#.....#.    ', $
        '  .#.     .#.   ', $
        ' .#.       .#.  ', $
        ' .#.       .#.  ', $
        ' .#.   $   .#.  ', $
        ' .#.       .#.  ', $
        ' .#.       .#.  ', $
        '  .#.     .##.  ', $
        '   .#.....####. ', $
        '    .######..##.', $
        '     .... .#..#.', $
        '           .##. ', $
        '            ..  ', $
        '                ']

    self->RegisterCursor, strArray, 'Zoom', /DEFAULT

end


;---------------------------------------------------------------------------
; IDLitManipViewZoom::Define
;
; Purpose:
;   Define the object structure for the manipulator
;

pro IDLitManipViewZoom__Define
    ; pragmas
    compile_opt idl2, hidden

    void = {IDLitManipViewZoom,        $
            inherits IDLitManipulator, $ ; Superclass
            oCurrView: OBJ_NEW(),      $ ; Reference to view to be zoomed
            viewportLoc: ULONARR(2),   $ ; Location of viewport
            origZoom: 0.0,             $ ; original zoom factor
            radius: 0.0                $ ; "radius" of zoom
    }
end
