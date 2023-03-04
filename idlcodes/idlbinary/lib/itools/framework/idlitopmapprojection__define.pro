; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/framework/idlitopmapprojection__define.pro#1 $
;
; Copyright (c) 2004-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopMapProjection
;
; PURPOSE:
;   This file implements the IDL Tool object that
;   implements the Map Projection action.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopMapProjection::Init
;
;-
;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitopMapProjection::Init
;
; Purpose:
;   The constructor of the IDLitopMapProjection object.
;
; Arguments:
;   None.
;
function IDLitopMapProjection::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitOperation::Init(TYPES=[''], _EXTRA=_extra)) then $
        return, 0

    if (~self->_IDLitMapProjection::Init(_EXTRA=_extra)) then $
        return, 0

    ; Turn this property back on.
    self->SetPropertyAttribute, 'SHOW_EXECUTION_UI', HIDE=0

    return, 1

end


;----------------------------------------------------------------------------
pro IDLitopMapProjection::GetProperty, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    self->IDLitOperation::GetProperty, _EXTRA=_extra
    self->_IDLitMapProjection::GetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
pro IDLitopMapProjection::SetProperty, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    self->IDLitOperation::SetProperty, _EXTRA=_extra
    self->_IDLitMapProjection::SetProperty, _EXTRA=_extra

end


;---------------------------------------------------------------------------
function IDLitopMapProjection::UndoOperation, oCommand

    compile_opt idl2, hidden

    ; Only look for the START_PROJECTION item.
    if (~oCommand->GetItem('START_PROJECTION')) then $
        return, 1

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return, 0

    oCommand->GetProperty, TARGET_IDENTIFIER=idNormDataspace
    oNormDataspace = oTool->GetByIdentifier(idNormDataspace)
    ; If there was nothing in the view when the map projection was added,
    ; then the dataspace might have been destroyed once the Map Grid was
    ; destroyed. In this we're done.
    if (~OBJ_VALID(oNormDataspace)) then $
        return, 1

    oDataspace = oNormDataspace->GetDataSpace(/UNNORMALIZED)
    if (~OBJ_VALID(oDataspace)) then $  ; sanity check
        return, 0

    ; Force the dataspace to undo its projection, using the
    ; old projection properties.
    oDataspace->OnProjectionChange

end


;---------------------------------------------------------------------------
function IDLitopMapProjection::RedoOperation, oCommand

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return, 0

    if (oCommand->GetItem('START_PROJECTION')) then begin

        ; Make sure we have a valid dataspace.
        oCommand->GetProperty, TARGET_IDENTIFIER=idNormDataspace
        oNormDataspace = oTool->GetByIdentifier(idNormDataspace)

        ; The dataspace might have been destroyed during the Undo, if
        ; the Map Grid was the only item in it. In this case we need to
        ; recreate the dataspace.
        if (~OBJ_VALID(oNormDataspace)) then begin
            void = oCommand->GetItem('LAYER', idLayer)
            oLayer = oTool->GetByIdentifier(idLayer)
            oWorld = oLayer->GetWorld()
            oNormDataspace = oWorld->GetCurrentDataSpace()
        endif

        ; We *must* retrieve the Dataspace and the MapProjection to force
        ; them to be created if they don't exist. This is so the SetProperty
        ; operation can successfully redo all the properties on the
        ; dataspace map projection.
        oDataspace = oNormDataspace->GetDataSpace(/UNNORMALIZED)
        oMapProj = oDataspace->_GetMapProjection()

    endif else if (oCommand->GetItem('END_PROJECTION')) then begin

        ; Make sure we have a valid dataspace. This should have been
        ; guaranteed by START_PROJECTION above.
        oCommand->GetProperty, TARGET_IDENTIFIER=idNormDataspace
        oNormDataspace = oTool->GetByIdentifier(idNormDataspace)
        if (~OBJ_VALID(oNormDataspace)) then $  ; sanity check
            return, 0

        oDataspace = oNormDataspace->GetDataSpace(/UNNORMALIZED)

        ; Force the dataspace to redo its projection, using the
        ; new projection properties.
        oDataspace->OnProjectionChange

    endif

    return, 1

end


;---------------------------------------------------------------------------
function IDLitopMapProjection::DoAction, oTool

    compile_opt idl2, hidden

    self->IDLitOperation::GetProperty, SHOW_EXECUTION_UI=showUI

    ; Retrieve our dataspace on which to set the projection.
    oWindow = oTool->GetCurrentWindow()
    if (~OBJ_VALID(oWindow)) then $
        return, OBJ_NEW()
    oView = oWindow->GetCurrentView()
    oLayer = oView->GetCurrentLayer()
    oWorld = oLayer->GetWorld()
    oDataspaceRoot = oWorld->_GetDataSpaceRoot()
    oDS = oDataspaceRoot->Get(/ALL, ISA='IDLitVisIDataSpace', COUNT=count)
    hasDataspace = count gt 0

    ; If we have a dataspace, retrieve it. If we don't, then
    ; don't retrieve it until later. That way, if the user hits Cancel
    ; on the dialog we don't create an empty dataspace.
    if (hasDataspace) then begin
        oNormDataspace = oWorld->GetCurrentDataSpace()
        oDataspace = oNormDataspace->GetDataSpace(/UNNORMALIZED)
        ; Do we currently have a valid map projection?
        hadMapProjection = N_TAGS(oDataspace->GetProjection()) gt 0
    endif else begin
        hadMapProjection = 0
    endelse


    if (showUI) then begin

        ; If we have a dataspace with a map projection, then assume
        ; that we want to copy its properties onto ourself.
        if (hadMapProjection) then begin

            ; Copy all properties from dataspace map projection to ourself.
            oMapProj = oDataspace->_GetMapProjection()
            props = oMapProj->QueryProperty()

            oMapProj->GetProperty, PROJECTION=projection
            self->GetProperty, PROJECTION=currentProjection
            if (projection ne currentProjection) then $
                self->SetProperty, PROJECTION=projection

            ; Start copying after PROJECTION property.
            props = props[(WHERE(props eq 'PROJECTION'))[0] + 1 : *]

            for i=0,N_ELEMENTS(props)-1 do begin
                oMapProj->GetPropertyAttribute, props[i], $
                    HIDE=hide, SENSITIVE=sensitive
                if (hide || ~sensitive) then $
                    continue
                if (~oMapProj->GetPropertyByIdentifier(props[i], value)) then $
                    continue
                self->SetPropertyByIdentifier, props[i], value
            endfor
        endif else begin

            ; Reset our map projection, so we start from a clean slate.
            self->SetProperty, PROJECTION=0

        endelse

        ; Make a temporary command set for the map proj properties,
        ; to determine if any actually change.
        oTmpCmd = self->RecordInitialProperties(self)

        ; If user hits cancel, return a null object.
        if (~oTool->DoUIService('MapProjection', self)) then begin
            return, OBJ_NEW()
        endif

        ; See if any of the map proj properties change.
        self->RecordFinalProperties, oTmpCmd, /SKIP_MACROHISTORY
        noChange = oTmpCmd->Count() eq 0

        ; We don't need to keep this command set, since any changes
        ; will have already been transacted by the Property Sheet.
        OBJ_DESTROY, oTmpCmd

        ; User hit OK but no changes were actually made.
        if (noChange) then begin

            ; If our dataspace had a map projection, then we know that
            ; nothing changed, so we can bail early.
            if (hasDataspace && hadMapProjection) then $
                return, OBJ_NEW()

            ; If we didn't have a dataspace or our dataspace didn't
            ; have a map projection, and the user selected 'No projection',
            ; then we can return.
            self->GetProperty, PROJECTION=projection
            if (projection eq 0) then $
                return, OBJ_NEW()

            ; At this point we either don't have a dataspace,
            ; or we have one without a map projection.
            ; Even though no changes were made to the dialog,
            ; we want to apply the operation's projection to the dataspace.
            ; So keep going.
        endif

    endif

    ; If we didn't have a dataspace before, create it now.
    if (~hasDataspace) then begin
        oNormDataspace = oWorld->GetCurrentDataSpace()
        oDataspace = oNormDataspace->GetDataSpace(/UNNORMALIZED)
    endif

    idNormDataspace = oNormDataspace->GetFullIdentifier()
    myID = self->GetFullIdentifier()

    ; Create an empty command object. Add a START_PROJECTION item
    ; so we know when to update the projection on an Undo.
    oCmd = OBJ_NEW('IDLitCommand', $
        OPERATION_IDENTIFIER=myID, $
        TARGET_IDENTIFIER=idNormDataspace)
    void = oCmd->AddItem('START_PROJECTION', 1)
    void = oCmd->AddItem('LAYER', oLayer->GetFullIdentifier())


    oMapProj = oDataspace->_GetMapProjection()

    ; Copy all properties from ourself to the dataspace map projection.
    props = self->QueryProperty()

    self->GetProperty, PROJECTION=projection
    oMapProj->GetProperty, PROJECTION=currentProjection
    if (projection ne currentProjection) then $
        _extra = {PROJECTION: projection}

    ; Start copying after PROJECTION property.
    props = props[(WHERE(props eq 'PROJECTION'))[0] + 1 : *]

    for i=0,N_ELEMENTS(props)-1 do begin
        self->GetPropertyAttribute, props[i], $
            HIDE=hide, SENSITIVE=sensitive
        if (hide || ~sensitive) then $
            continue
        if (~self->GetPropertyByIdentifier(props[i], value)) then $
            continue
        _extra = (N_ELEMENTS(_extra) gt 0) ? $
            CREATE_STRUCT(_extra, props[i], value) : $
            CREATE_STRUCT(props[i], value)
    endfor

    oProperty = oTool->GetService("SET_PROPERTY")
    ; Use DoSetProperty so these changes to the dataspace are undoable.
    oExtraCmd = oProperty->DoSetPropertyWith_Extra(oMapProj, $
        _EXTRA=_extra)
    if (~OBJ_VALID(oExtraCmd)) then begin
        OBJ_DESTROY, oCmd
        return, OBJ_NEW()
    endif

    oCmd = [oCmd, oExtraCmd]


    ; This is just a "flag" to tell the dataspace to call OnMapProjection.
    oRedoCmd = OBJ_NEW('IDLitCommand', $
        OPERATION_IDENTIFIER=myID, $
        TARGET_IDENTIFIER=idNormDataspace)
    void = oRedoCmd->AddItem('END_PROJECTION', 1)
    oCmd = [oCmd, oRedoCmd]


    oTool->DisableUpdates, PREVIOUSLY_DISABLE=wasDisabled

    oTool->_UpdateToolByType, 'IDLMAP'

    ; In case any of the Range properties get changed, record their
    ; initial values so we can Undo the changes.
    oPropCmd = self->RecordInitialProperties(oNormDataspace)

    oDataspace->OnProjectionChange

    if (OBJ_VALID(oPropCmd)) then begin
        self->RecordFinalProperties, oPropCmd
        oCmd = [oCmd, oPropCmd]
    endif

    ; Automatically insert map grid if we didn't have a map
    ; projection before, and if we don't already have a map grid.
    void = oDataspace->Get(/ALL, ISA='IDLitVisMapGrid', COUNT=ngrid)
    if (~hadMapProjection && ~ngrid) then begin
        oDesc = oTool->GetByIdentifier('OPERATIONS/INSERT/MAP/GRID')
        if (OBJ_VALID(oDesc)) then begin
            oGridOp = oDesc->GetObjectInstance()
            oGridCmd = oGridOp->DoAction(oTool)
            if (OBJ_VALID(oGridCmd[0])) then $
                oCmd = [oCmd, oGridCmd]
        endif
    endif

    if (~wasDisabled) then $
        oTool->EnableUpdates

    oCmd[N_ELEMENTS(oCmd)-1]->SetProperty, NAME='Map Projection'

    return, oCmd

end


;-------------------------------------------------------------------------
pro IDLitopMapProjection__define

    compile_opt idl2, hidden
    struc = {IDLitopMapProjection, $
        inherits IDLitOperation, $
        inherits _IDLitMapProjection $
        }

end

