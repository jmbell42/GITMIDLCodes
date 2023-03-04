; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/framework/idlitsys_createtool.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;  IDLitsys_CreateTool
;
; PURPOSE:
;   Provides a procedurual interface to create IDL tools. This is
;   primarly used for the procedureal interface exposed by the itools
;   system. This routine will also verify that the system is up and running.
;
;   This is an internal routine.
;
; CALLING SEQUENCE:
;     id = IDLitSys_CreateTool(strTool)
;
; PARAMETERS
;   strTool   - The name of the tool to create
;
; KEYWORDS
;   All keywords are passsed to the system objects CreateTool method.
;
;   DISABLE_UPDATES: Set this keyword to disable updates on the
;       newly-created tool. If this keyword is set then the user
;       is responsible for calling EnableUpdates on the tool.
;       This keyword is useful when you want to do a subsequent overplot
;       or use DoAction to call an operation, but do not want to see the
;       intermediate steps.
;       Note: This keyword is ignored if the tool already exists.
;       In this case you should call DisableUpdates on the tool
;       before calling IDLitSys_CreateTool.
;
; RETURN VALUE
;   This routine will return the identifier of the created tool. If no
;   tool was created, then an empty '' string is returned.
;-

;-------------------------------------------------------------------------
; Purpose:
;   Helper routine to empty all visualizations out of a view.
;
pro IDLitSys_CreateTool__EmptyView, oView
    compile_opt idl2, hidden

    ; Sanity check.
    if (~OBJ_VALID(oView)) then $
        return

    oLayer = oView->Get(/ALL, ISA='IDLitgrLayer', COUNT=nLayer)
    for i=0,nLayer-1 do begin

        ; Don't destroy the annotation layer.
        if (~OBJ_VALID(oLayer[i]) || $
            OBJ_ISA(oLayer[i], 'IDLitgrAnnotateLayer')) then $
            continue

        oWorld = oLayer[i]->GetWorld()
        if (~OBJ_VALID(oWorld)) then $
            continue

        ; Retrieve all dataspaces.
        oDataspaces = oWorld->GetDataSpaces(COUNT=ndataspace)

        if (~ndataspace) then $
            continue

        for d=0,ndataspace-1 do begin
            ; Must notify the visualizations before the dataspace is removed
            oVisualizations = oDataSpaces[d]->GetVisualizations( $
                COUNT=count, /FULL_TREE)
            for j=0,count-1 do begin
                ; Send a delete message
                idVis = oVisualizations[j]->GetFullIdentifier()
                oVisualizations[j]->OnNotify, idVis, "DELETE", ''
                oVisualizations[j]->DoOnNotify, idVis, 'DELETE', ''
            endfor
        endfor

        ; We can just destroy the dataspaces since new ones
        ; will be created automatically.
        oLayer[i]->Remove, oDataSpaces
        OBJ_DESTROY, oDataSpaces

    endfor


end


;-------------------------------------------------------------------------
FUNCTION IDLitSys_CreateTool, strTool, $
    BACKGROUND_COLOR=backgroundColor, $
    DISABLE_UPDATES=disableUpdates, $
    INITIAL_DATA=initial_data, $
    MACRO_NAMES=macroNames, $
    MAP_PROJECTION=mapProjection, $
    OVERPLOT=overplotIn, $
    TOOLNAME=toolname, $
    USER_INTERFACE=userInterface, $
    VIEW_GRID=viewGrid, $
    VIEW_NEXT=viewNext, $
    VIEW_NUMBER=viewNumber, $
    VIEW_TITLE=viewTitle, $
    _EXTRA=_EXTRA

   compile_opt idl2, hidden

   ;; Get the System tool
   oSystem = _IDLitSys_GetSystem()
   if(not obj_valid(oSystem))then $
       Message, "SYSTEM ERROR: The iTools system cannot initialize"

    ; Check if a valid overplot situation was provided
    idTool = ''
    overplot = (N_ELEMENTS(overplotIn) eq 1) ? overplotIn[0] : 0
    if (overplot || $
        N_ELEMENTS(viewNext) || $
        N_ELEMENTS(viewNumber)) then begin
        idTool = (SIZE(overplot, /TYPE) eq 7) ? $
            overplot : oSystem->GetCurrentTool()
    endif

    ; CT, RSI: "Special" code for STYLE_NAME keyword.
    ; There is a keyword conflict with the Surface visualization
    ; STYLE keyword. To handle this we don't specify STYLE_NAME
    ; in the function header above. Instead we look for it in
    ; the _EXTRA structure. It is okay that STYLE_NAME is passed
    ; on via _EXTRA because it doesn't match a registered property
    ; on any visualization, so it will be quietly ignored later.
    if (N_TAGS(_extra) gt 0) then begin
        tname = TAG_NAMES(_extra)
        istyle = (WHERE(tname eq 'STYLE_NAME'))[0]
        if (istyle ge 0) then begin
            styleName = _extra.(istyle)
        endif else begin
            ; Be nice and look for the STYLE_NAME keyword abbreviated
            ; as just STYLE.
            ; Because of keyword conflict with the surface STYLE property,
            ; make sure our STYLE property is a string.
            ; If it isn't, assume it is our surface style property.
            istyle = (WHERE(tname eq 'STYLE'))[0]
            if (istyle ge 0 && SIZE(_extra.(istyle), /TYPE) eq 7) then $
                styleName = _extra.(istyle)
        endelse
    endif

    ; If style name, make sure we have that style.
    if (N_ELEMENTS(styleName) gt 0) then begin
        oStyleService = oSystem->GetService('STYLES')
        if (~OBJ_VALID(oStyleService)) then $
            MESSAGE, 'Style service has not been registered.'
        if (~OBJ_VALID(oStyleService->GetByName(styleName[0]))) then $
            MESSAGE, 'Style "' + styleName[0] + '" does not exist.'
    endif

    ; If MACRO_NAMES, make sure each macro exists.
    if (N_ELEMENTS(macroNames) gt 0) then begin
        oSrvMacro = oSystem->GetService('MACROS')
        if (~OBJ_VALID(oSrvMacro)) then $
            MESSAGE, 'Macro service has not been registered.'
        for i=0, n_elements(macroNames)-1 do begin
            if (~OBJ_VALID(oSrvMacro->GetMacroByName(macroNames[i]))) then $
                MESSAGE, 'Macro "' + macroNames[i] + '" does not exist.'
        endfor
    endif

   if (idTool) then begin

        if (overplot && ~N_ELEMENTS(initial_data) ) then $
            Message, "ERROR: Data required for overplotting"

        oTool = oSystem->GetByIdentifier(idTool)
        oTool->DisableUpdates, PREVIOUSLY_DISABLE=wasDisabled
        reEnableUpdates = ~wasDisabled

        ; Handle my special view keywords.
        if (N_ELEMENTS(viewNext) || N_ELEMENTS(viewNumber)) then begin

            if OBJ_VALID(oTool) then begin
                oWin = oTool->GetCurrentWindow()

                if (OBJ_VALID(oWin)) then begin

                    ; Set my view keywords.
                    oWin->SetProperty, VIEW_NEXT=viewNext, $
                        VIEW_NUMBER=viewNumber

                    if (~overplot) then begin
                        IDLitSys_CreateTool__EmptyView, $
                            oWin->GetCurrentView()
                        ; Need to force a refresh if nothing changed.
                        oTool->RefreshCurrentWindow
                    endif

                endif  ; oWin
           endif  ; oTool

       endif  ; view keywords

       if (N_ELEMENTS(initial_data)) then BEGIN
         ;; Include MAP_PROJECTION so if we are creating an image, we pass
         ;; on the properties to the image's projection.
         oCmd = oSystem->CreateVisualization(idTool, initial_data, $
                                             MAP_PROJECTION=mapProjection, $
                                             _extra=_extra)
       ENDIF

       IF (n_elements(oCmd) && obj_valid(oCmd[0])) THEN BEGIN
         oTool->_AddCommand, oCmd
         oCmd[n_elements(oCmd)-1]->GetProperty, NAME=cmdName
       ENDIF

   endif else begin

        ; Ignore the overplot setting since we didn't have a tool.
        overplot = 0

        toolname = (N_ELEMENTS(toolname) eq 1) ? toolname : strTool
        ; Include MAP_PROJECTION so if we are creating an image, we pass
        ; on the properties to the image's projection.
        oTool = oSystem->CreateTool(toolname, $
            INITIAL_DATA=initial_data, $
            /DISABLE_UPDATES, $
            MAP_PROJECTION=mapProjection, $
            VIEW_GRID=viewGrid, $
            USER_INTERFACE=userInterface, $
            _EXTRA=_extra)

        ; Make sure to re-enable updates, unless the user has forced
        ; them to remain off.
        reEnableUpdates = ~KEYWORD_SET(disableUpdates)

   endelse

   if (~OBJ_VALID(oTool)) then $
     return, ''

   ;; add view title text annotation
   IF keyword_set(viewTitle) THEN BEGIN
     oManip = oTool->GetCurrentManipulator()
     oDesc = oTool->GetAnnotation('Text')
     oText = oDesc->GetObjectInstance()
     oText->SetProperty, $
       _STRING=viewTitle[0], $
       _HORIZONTAL_ALIGN=1, $
       LOCATIONS=[0,0.9,0.99], NAME='View Title'
     oTool->Add, oText, LAYER='ANNOTATION LAYER'
     IF obj_isa(oManip, 'IDLitManipViewPan') THEN $
       oTool->ActivateManipulator, 'VIEWPAN'

     IF overplot THEN BEGIN
       ;; record transaction
       oOperation = oTool->GetService('ANNOTATION') ;
       oCmd = obj_new("IDLitCommandSet", $
                      OPERATION_IDENTIFIER= $
                      oOperation->getFullIdentifier())
       iStatus = oOperation->RecordFinalValues( oCmd, oText, "")
       oCmd->SetProperty, $
         NAME=((n_elements(cmdName) GT 0) ? cmdName : "Text Annotation")
       oTool->_AddCommand, oCmd
     ENDIF
   ENDIF

   if n_elements(backgroundColor) gt 0 then begin
     oWin = oTool->GetCurrentWindow()
     if (OBJ_VALID(oWin)) then begin
       oView = oWin->GetCurrentView()
       if obj_valid(oView) then begin
         oLayerVisualization = oView->GetCurrentLayer()
         if OBJ_VALID(oLayerVisualization) then BEGIN
           IF overplot THEN BEGIN
             oProperty = oTool->GetService("SET_PROPERTY")
             oCmd = oProperty->DoAction(oTool, oLayerVisualization->GetFullIdentifier(), $
                                        'COLOR', backgroundColor)
             oCmd->SetProperty,NAME=cmdName
             oTool->_AddCommand, oCmd
           ENDIF ELSE BEGIN
             oLayerVisualization->SetProperty, COLOR=backgroundColor
           ENDELSE
         ENDIF
       endif
     endif
   endif

   ; See if we have any map projection properties.
   ; The user must specify the MAP_PROJECTION keyword for the
   ; other keywords to take effect. If OVERPLOT then ignore.
   if (N_ELEMENTS(mapProjection) && ~overplot) then begin
        ; Fire up the Map Proj operation to actually change the value.
        ; This is a bit weird, but we pass in the keywords directly
        ; to DoAction. This is because the Map Projection operation needs
        ; to be very careful how it does its Undo/Redo command set,
        ; and it's easier to let the operation handle the details.
        oMapDesc = oTool->GetByIdentifier('Operations/Operations/Map Projection')
        if (OBJ_VALID(oMapDesc)) then begin
            oOp = oMapDesc->GetObjectInstance()
            oOp->GetProperty, SHOW_EXECUTION_UI=showUI
            ; Set all the map projection properties on our operation,
            ; then fire it up.
            oOp->SetProperty, SHOW_EXECUTION_UI=0, $
                MAP_PROJECTION=mapProjection, _EXTRA=_extra
            oCmd = oOp->DoAction(oTool)
            ; no undo
            obj_destroy, oCmd
            if (showUI) then $
                oOp->SetProperty, SHOW_EXECUTION_UI=showUI
        endif
    endif

    if (N_ELEMENTS(styleName)) then begin
        oDesc = oTool->GetByIdentifier('/Registry/Operations/Apply Style')
        oStyleOp = oDesc->GetObjectInstance()
        oStyleOp->GetProperty, SHOW_EXECUTION_UI=showUI
        oStyleOp->SetProperty, SHOW_EXECUTION_UI=0, $
            STYLE_NAME=styleName[0], $
            APPLY=overplot ? 1 : (idTool ? 2 : 3), $
            UPDATE_CURRENT=~overplot
        void = oStyleOp->DoAction(oTool, /NO_TRANSACT)
        if (showUI) then $
            oStyleOp->SetProperty, /SHOW_EXECUTION_UI
    endif

    ; Re-enable tool updates. This will cause a refresh.
    if (reEnableUpdates) then begin
        oTool->EnableUpdates
        ; Process the initial iTool expose event.
        void = WIDGET_EVENT(/NOWAIT)
    endif

   if n_elements(macroNames) gt 0 then begin
        oDesc = oTool->GetByIdentifier('/Registry/MacroTools/Run Macro')
        oOpRunMacro = oDesc->GetObjectInstance()
        oOpRunMacro->GetProperty, $
            SHOW_EXECUTION_UI=showUIOrig, $
            MACRO_NAME=macroNameOrig
        ; Hide macro controls if using an IDLgrBuffer user interface.
        hideControls = N_ELEMENTS(userInterface) eq 1 && $
            STRCMP(userInterface, 'NONE', /FOLD)
        for i=0, n_elements(macroNames)-1 do begin
            oOpRunMacro->SetProperty, $
                SHOW_EXECUTION_UI=0, $
                MACRO_NAME=macroNames[i]
            oCmd = oOpRunMacro->DoAction(oTool, HIDE_CONTROLS=hideControls)
            ; no undo
            obj_destroy, oCmd
        endfor
        ; restore original values on the singleton
        oOpRunMacro->SetProperty, $
            SHOW_EXECUTION_UI=showUIOrig, $
            MACRO_NAME=macroNameOrig
   endif

   if (MAX(OBJ_VALID(oCmd)) gt 0) then $
        oTool->CommitActions

   return, idTool ? idTool : oTool->GetFullIdentifier()
end
