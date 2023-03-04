; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/components/idlitopinsertlegend__define.pro#1 $
;
; Copyright (c) 2000-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the insert legend operation.
;
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the object.
;
; Arguments:
;   None.
;
function IDLitopInsertLegend::Init, _REF_EXTRA=_extra
    compile_opt idl2, hidden
    ; don't init by type.  allow creation of legend if no items are
    ; selected.  filter by vis type below
    return, self->IDLitOperation::Init( $
        TYPES=['DATASPACE_2D','DATASPACE_3D', $
            'DATASPACE_ROOT_2D','DATASPACE_ROOT_3D', $
            'PLOT','PLOT3D','SURFACE','CONTOUR'], $
            _EXTRA=_extra)
end


;---------------------------------------------------------------------------
; Purpose:
;   Perform the action.
;
; Arguments:
;   None.
;
function IDLitopInsertLegend::DoAction, oTool

    compile_opt idl2, hidden

    ; Retrieve the current selected item(s).
    oTargets = oTool->GetSelectedItems(count=nTarg)

    if( (nTarg eq  0) or $
    ((nTarg eq 1) AND $
         (OBJ_ISA(oTargets[0], 'IDLitVisIDataSpace')))) then begin
        oWindow = oTool->GetCurrentWindow()
        if (~OBJ_VALID(oWindow)) then $
          return, OBJ_NEW()
        oView = oWindow->GetCurrentView()
        oLayer = oView->GetCurrentLayer()
        oWorld = oLayer->GetWorld()
        oDataSpace = oWorld->GetCurrentDataSpace()
        oTargets = oDataSpace->GetVisualizations(COUNT=count, /FULL_TREE)
        if (count eq 0) then begin
            self->ErrorMessage, $
              [IDLitLangCatQuery('Error:InsertLegend:CannotFind')], $
                severity=0, $
              TITLE=IDLitLangCatQuery('Error:InsertLegend:Title')
            return, OBJ_NEW()
        endif
    endif

    ; filter to acceptable visualizations
    for i=0, N_ELEMENTS(oTargets)-1 do begin
        if ((OBJ_ISA(oTargets[i], 'IDLitVisPlot')) || $
            (OBJ_ISA(oTargets[i], 'IDLitVisPlot3D')) || $
            (OBJ_ISA(oTargets[i], 'IDLitVisContour')) || $
            (OBJ_ISA(oTargets[i], 'IDLitVisSurface'))) then begin
                if (N_ELEMENTS(oVisTargets) gt 0) then begin
                    oVisTargets = [oVisTargets, oTargets[i]]
                endif else begin
                    oVisTargets = [oTargets[i]]
                endelse
        endif
    endfor
    if (N_ELEMENTS(oVisTargets) eq 0) then begin
        self->ErrorMessage, $
          [IDLitLangCatQuery('Error:InsertLegend:NotSelected')], $
            severity=0, $
          TITLE=IDLitLangCatQuery('Error:InsertLegend:Title')
        return, OBJ_NEW()
    endif

    oData = obj_new("IDLitData", type='Visualization', name="Legend Data",/private)
    ;; NOTE: By adding this to the data manager, this data object will
    ;; leak! (it's hidden though). TODO: Make sure this is fixed
    oTool->AddByIdentifier, "/Data Manager", oData
    status = oData->SetData(oVisTargets)

    oCreate = oTool->GetService("CREATE_VISUALIZATION")
    if(not obj_valid(oCreate))then $
      return, obj_new();
    ;; Create the color bar!
    return, oCreate->CreateVisualization( oData, "LEGEND", $
                                          LAYER='ANNOTATION', $
                                          /MANIPULATOR_TARGET)
end


;-------------------------------------------------------------------------
pro IDLitopInsertLegend__define

    compile_opt idl2, hidden
    struc = {IDLitopInsertLegend, $
        inherits IDLitOperation $
        }

end

