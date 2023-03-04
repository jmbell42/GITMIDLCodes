;;; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/components/idlitvislegend__define.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;    Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
; Purpose:
;    The IDLitVisLegend class is the component wrapper for the legend.
;
; Modification history:
;     Written by:   AY, Jan 2003.
;


;----------------------------------------------------------------------------
pro IDLitVisLegend::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin
        ; Add general properties
        self->RegisterProperty, 'LEGEND_LOCATION', $
            ENUMLIST=['User Specified', 'Top Left', 'Top Center', 'Top Right', $
                        'Bottom Left', 'Bottom Center', 'Bottom Right' ], $
            DESCRIPTION='Automatically Position Legend', $
            NAME='Location'

        self->RegisterProperty, 'ORIENTATION', $
            ENUMLIST=['Column', 'Row'], $
            DESCRIPTION='Orientation', $
            NAME='Layout'

        self->RegisterProperty, 'SAMPLE_WIDTH', /FLOAT, $
            DESCRIPTION='Legend sample width', $
            NAME='Sample width', $
            VALID_RANGE=[0, 0.5d, .01d]

        self->RegisterProperty, 'HORIZONTAL_SPACING', /FLOAT, $
            DESCRIPTION='Legend horizontal spacing', $
            NAME='Horizontal spacing', $
            VALID_RANGE=[0, 0.25d, .01d]

        self->RegisterProperty, 'VERTICAL_SPACING', /FLOAT, $
            DESCRIPTION='Legend vertical spacing', $
            NAME='Vertical spacing', $
            VALID_RANGE=[0, 0.25d, .01d]

        self->RegisterProperty, 'TEXT_COLOR', /COLOR, $
            DESCRIPTION='Item Text Color', $
            NAME='Text color'

        self->RegisterProperty, 'FONT_INDEX', $
            ENUMLIST=['Helvetica', 'Courier', 'Times', 'Symbol', 'Hershey'], $
            NAME='Text font'
        self->RegisterProperty, 'FONT_STYLE', $
            ENUMLIST=['Normal', 'Bold', 'Italic', 'Bold Italic'], $
            NAME='Text style'
        self->RegisterProperty, 'FONT_SIZE', /INTEGER, $
            NAME='Text font size', $
            VALID_RANGE=[1,1000]

        self._oPolygon->SetPropertyAttribute, $
            ['BOTTOM', 'USE_BOTTOM_COLOR'], /HIDE

    endif

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisLegend::Init
;
; PURPOSE:
;    Initialize this component
;
; CALLING SEQUENCE:
;
;    Obj = OBJ_NEW('IDLitVisLegend'[, Z[, X, Y]])
;
; INPUTS:
;   Z: (see IDLgrImage)
;   X:
;   Y:
;
; KEYWORD PARAMETERS:
;   All keywords that can be used for IDLgrImage
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 on failure.
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
; EXAMPLE:
;   Create just like an IDLgrImage.
;
;
;
;-
function IDLitVisLegend::Init, $
                       NAME=NAME, $
                       DESCRIPTION=DESCRIPTION, $
                       _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~keyword_set(name)) then $
        name ="Legend"
    if (~keyword_set(DESCRIPTION)) then $
        DESCRIPTION ="A Legend Visualization"

    ; Initialize superclass
    success = self->IDLitVisualization::Init( $
        /REGISTER_PROPERTIES, $
        NAME=NAME, $
        TYPE="IDLLEGEND", $
        ICON='legend', $
        IMPACTS_RANGE=0, $   ; should not affect DataSpace range
        DESCRIPTION=DESCRIPTION, $
        /MANIPULATOR_TARGET, $
        SELECTION_PAD=10, $ ; pixels. allows easier de-selection
        _EXTRA=_extra)

    if (~success) then $
        return, 0

    ; Add in our special manipulator visual.  This allows translation
    ; but doesn't allow scaling.  We don't want to allow scaling because
    ; it causes problems with the autoposition feature.  Translation is
    ; enabled, however.  For the user's interactive translation to "stick"
    ; they need to disable autoposition.
    self->SetDefaultSelectionVisual, $
        OBJ_NEW('IDLitManipVisSelectBox', /HIDE, COLOR=[0,150,0])

    self._oPolygon = OBJ_NEW('IDLitVisPolygon', $
                             SELECT_TARGET=0, $
                             /IMPACTS_RANGE, $
                             /private)
    self->IDLitVisualization::Add, self._oPolygon, /AGGREGATE

    self->Set3D, 0, /ALWAYS

    self->IDLitVisLegend::_RegisterProperties

    ;; Register the parameters we are using for data
    self->RegisterParameter, 'VISUALIZATIONS', DESCRIPTION='Visualizations ', $
                            /INPUT, TYPES='VISUALIZATION',/optarget
    ; Set any properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisLegend::SetProperty, _EXTRA=_extra

    self._sampleWidth = 0.15d
    self._horizSpacing = 0.02d
    self._vertSpacing = 0.02d
    self._orientation = 0       ;vertical
    self._location = 3      ;top right
    self._textColor = PTR_NEW([0L,0,0])
    self._fontSize = 10

    RETURN, 1 ; Success
end


;----------------------------------------------------------------------------
; Purpose:
;    Cleanup this component
;
pro IDLitVisLegend::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oPolygon

    oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
    for i=0, nItems-1 do begin
        OBJ_DESTROY, oItems[i]
    endfor
    PTR_FREE, self._textColor

    ; Cleanup superclass
    self->IDLitVisualization::Cleanup
end


;----------------------------------------------------------------------------
; IDLitVisLegend::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisLegend::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Call ::Restore on each aggregated ItVis object
    ; to ensure any new properties are registered.  Also
    ; call its UpdateComponentVersion method so that this
    ; will not be attempted later
    if (OBJ_VALID(self._oPolygon)) then begin
        self._oPolygon->Restore
        self._oPolygon->UpdateComponentVersion
    endif

    ; Register new properties.
    self->IDLitVisLegend::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

end


;----------------------------------------------------------------------------
PRO IDLitVisLegend::RecomputeLayout

    compile_opt idl2, hidden

    oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)

    ; if last item deleted, preserve size of legend and
    ; simply return.
    ; consider destroying whole legend here, but at present
    ; this cannot be supported with undo/redo.
    if ~nItems then $
        return

    xBorderMax = self._horizSpacing ; in case no items in legend
    yBorderMax = self._vertSpacing

    xOffset = self._horizSpacing
    yOffset = self._vertSpacing

    haveItem = 0b

    for i=nItems-1,0,-1 do begin
        oItems[i]->GetProperty, ITEM_RANGE=itemRange, HIDE=hide

        ; Don't include hidden items in calculations
        if (hide) then $
            continue

        curWidth = itemRange[0]
        curHeight = itemRange[1]

        oItems[i]->Reset
        ; Push the legend items a little closer to the viewer.
        ; This helps vector output sort the primitives correctly.
        oItems[i]->Translate, xOffset, yOffset, 0.01

        ; layout is: space,sampleWidth,space,text,space
        ; item is responsible for sampleWidth, middle space and text positioning
        ; legend is responsible for leading and trailing horizontal spacing as well as
        ; vertical spacing.
        xBorderMax = xBorderMax > (xOffset + curWidth + self._horizSpacing)
        yBorderMax = yBorderMax > (yOffset + curHeight + self._vertSpacing)

        if (self._orientation) then $  ;horizontal orientation, yOffset fixed
            xOffset += 2*self._horizSpacing + curWidth $
        else $   ; vertical orientation, xOffset fixed
            yOffset += curHeight + self._vertSpacing

        haveItem = 1b
    endfor

    ; Bail if all hidden, so we don't end up with a tiny little box.
    if (~haveItem) then $
        return

    xmin=0
    xmax = xBorderMax
    ymin=0
    ymax = yBorderMax
    self._oPolygon->SetProperty, $
        DATA=[[xmin,ymin], [xmax,ymin], [xmax,ymax], [xmin,ymax], [xmin,ymin]]

    ; range of annotation space is [-1,1] in both x,y, plus some additional margin
    ; space in x.  leave some space so manipulater handles show up
    ;
    ; Add the Z so that values are in the annotation layer and
    ; not clipped by the Viz.
    ;
    ; location=0 means don't reposition - maintain position specified by
    ;                                     user
    z_layer=0.99

    if (self._location gt 0) then begin
        self->IDLgrModel::GetProperty, transform=transform

        case self._location of
        1: tr = [ $                 ; top left
            -0.95 - transform[3,0], $
            0.95 - ymax - transform[3,1]]
        2: tr = [ $                 ; top center
            -xmax/2 - transform[3,0], $
            0.95 - ymax - transform[3,1]]
        3: tr = [ $                 ; top right
            0.95 - xmax - transform[3,0], $
            0.95 - ymax - transform[3,1]]
        4: tr = [ $                 ; bottom left
            -0.95 - transform[3,0], $
            -0.95 - transform[3,1]]
        5: tr = [ $                 ; bottom center
            -xmax/2 - transform[3,0], $
            -0.95 - transform[3,1]]
        6: tr = [ $                 ; bottom right
            0.95 - xmax - transform[3,0], $
            -0.95 - transform[3,1]]
        endcase

        self->Translate, tr[0], tr[1], z_layer-transform[3,2], $
            /PREMULTIPLY, /IGNORE

    endif

    self->UpdateSelectionVisual

end


;----------------------------------------------------------------------------
pro IDLitVisLegend::Add, oTargets, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    self->IDLitVisualization::Add, oTargets, _EXTRA=_extra

    ; If we add a legend item, recompute the layout.
    if (OBJ_ISA(oTargets[0], 'IDLitVisLegendPlotItem') || $
        OBJ_ISA(oTargets[0], 'IDLitVisLegendSurfaceItem') || $
        OBJ_ISA(oTargets[0], 'IDLitVisLegendContourItem')) then $
        self->RecomputeLayout
end


;----------------------------------------------------------------------------
pro IDLitVisLegend::Remove, oTargets, _EXTRA=_extra

    compile_opt idl2, hidden

    if (N_PARAMS() eq 0) then $
        self->IDLitVisualization::Remove, _EXTRA=_extra $
    else $
        self->IDLitVisualization::Remove, oTargets, _EXTRA=_extra

    ; If we remove a legend item, recompute the layout.
    if (N_ELEMENTS(oTargets) && $
        (OBJ_ISA(oTargets[0], 'IDLitVisLegendPlotItem') || $
        OBJ_ISA(oTargets[0], 'IDLitVisLegendSurfaceItem') || $
        OBJ_ISA(oTargets[0], 'IDLitVisLegendContourItem'))) then $
        self->RecomputeLayout
end


; Output: oLegendItems
;----------------------------------------------------------------------------
PRO IDLitVisLegend::AddToLegend, oTargets, oNewLegendItems

    compile_opt idl2, hidden

    self->IDLgrModel::SetProperty, /HIDE

    nItems = n_elements(oTargets)

    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return

    supportedVis = 0
    for i=0, nItems-1 do begin
        if (~OBJ_VALID(oTargets[i])) then $
            continue

        if ((OBJ_ISA(oTargets[i], 'IDLitVisPlot')) || $
            (OBJ_ISA(oTargets[i], 'IDLitVisPlot3D')))  then begin
            oItem = OBJ_NEW('IDLitVisLegendPlotItem', $
                            ITEM=oTargets[i], $
                            SAMPLE_WIDTH=self._sampleWidth, $
                            HORIZONTAL_SPACING=self._horizSpacing, $
                            TOOL=oTool)
            supportedVis = 1
        endif
        if (OBJ_ISA(oTargets[i], 'IDLitVisSurface')) then begin
            oItem = OBJ_NEW('IDLitVisLegendSurfaceItem', $
                            ITEM=oTargets[i], $
                            SAMPLE_WIDTH=self._sampleWidth, $
                            HORIZONTAL_SPACING=self._horizSpacing, $
                            TOOL=oTool)
            supportedVis = 1
        endif
        if (OBJ_ISA(oTargets[i], 'IDLitVisContour')) then begin
            oItem = OBJ_NEW('IDLitVisLegendContourItem', $
                            ITEM=oTargets[i], $
                            SAMPLE_WIDTH=self._sampleWidth, $
                            HORIZONTAL_SPACING=self._horizSpacing, $
                            VERTICAL_SPACING=self._vertSpacing, $
                            TOOL=oTool)
            supportedVis = 1
        endif

        if supportedVis then begin
            oItem->_SetTool, oTool

            ; Add to our superclass to avoid recomputing the layout.
            self->IDLitVisualization::Add, oItem

            oData = obj_new("IDLitData", type='Visualization', $
                name="Legend Item Data",/private)
            ;; NOTE: By adding this to the data manager, this data object will
            ;; leak! (it's hidden though). TODO: Make sure this is fixed
            oTool->AddByIdentifier, "/Data Manager", oData
            status = oData->SetData(oTargets[i])
            status = oItem->SetData(oData, PARAMETER_NAME="VISUALIZATION")

            oNewLegendItems = n_elements(oNewLegendItems) gt 0 ? $
                [oNewLegendItems, oItem] : oItem

            self->AddOnNotifyObserver, $
                self->GetFullIdentifier(), $
                oTargets[i]->GetFullIdentifier()
        endif

    endfor


    ; Note: The SetData call to the legend item will result in
    ; a recomputation of dimensions, so no need to do so again here.

    ; For efficiency, pass directly to/from IDLgrModel.
    self->IDLgrModel::SetProperty, HIDE=0

end


;----------------------------------------------------------------------------
PRO IDLitVisLegend::Translate, tx, ty, tz, IGNORE=ignore, _EXTRA=_extra

    compile_opt idl2, hidden

    ; user has moved legend, switch location property to "user specified"
    ; to prevent auto-positioning.  If ignoe is set then translate was
    ; called from recomputeLayout - maintain current position
    if (N_ELEMENTS(ignore) eq 0) then begin
        self->IDLitVisLegend::SetProperty, LEGEND_LOCATION=0
    endif

    ; Cleanup superclass
    self->IDLitVisualization::Translate, tx, ty, tz, _EXTRA=_extra

end


;----------------------------------------------------------------------------
; Override the Move to allow keeping the items in front of polygon and
; behind the selection visual.
;
; Recompute the layout so that when "Move to front" or "Move forward"
; is chosen items move up in the legend.  If "Move to back" or "Move
; backward" is chosen items move down in the legend.
; To do this we need to reverse the order of items within the container.
;
PRO IDLitVisLegend::Move, Source, Destination, NO_NOTIFY=NO_NOTIFY

    compile_opt idl2, hidden

    oItems = self->Get(/ALL, COUNT=nItems)

    ; Reverse the position within the container, since we want the
    ; first item to appear at the top.
    Destination = (nItems - 1) - Destination

    ; skip past the IDLitVisPolygon (legend background),
    ; but before the IDLitManipVisSelect in last position.
    Destination = 1 > Destination < (nItems - 2)

    self->_IDLitVisualization::Move, Source, Destination

    self->RecomputeLayout

end


;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisLegend::GetProperty
;
; PURPOSE:
;      This procedure method retrieves the
;      value of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisLegend::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisLegend::Init followed by the word "Get"
;      can be retrieved using IDLitVisLegend::GetProperty.  In addition
;      the following keywords are available:
;
;      ALL: Set this keyword to a named variable that will contain
;              an anonymous structure containing the values of all the
;              retrievable properties associated with this object.
;              NOTE: UVALUE is not returned in this struct.
;-
pro IDLitVisLegend::GetProperty, $
    LEGEND_LOCATION=location, $
    TEXT_COLOR=textColor, $
    FONT_INDEX=fontIndex, $
    FONT_SIZE=fontSize, $
    FONT_STYLE=fontStyle, $
    SAMPLE_WIDTH=sampleWidth, $
    HORIZONTAL_SPACING=horizSpacing, $
    VERTICAL_SPACING=vertSpacing, $
    ORIENTATION=orientation, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Get my properties
    if (ARG_PRESENT(textColor)) then begin
        oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
        if (nItems gt 0) then begin
            ; this textColor may not be applied to any objects
            ; or it may be applied to some but overridden by some
            ; lower level objects.  return the cached color value
            ; instead of retrieving it from an object
            textColor = *self._textColor
        endif else begin
            textColor = [0b,0b,0b]
        endelse
    endif

    if ARG_PRESENT(fontIndex) then begin
        fontIndex = self._fontIndex
    endif

    if ARG_PRESENT(fontSize) then begin
        fontSize = self._fontSize
    endif

    if ARG_PRESENT(fontStyle) then begin
        fontStyle = self._fontStyle
    endif

    if ARG_PRESENT(sampleWidth) then begin
        sampleWidth = self._sampleWidth
    endif

    if ARG_PRESENT(horizSpacing) then begin
        horizSpacing = self._horizSpacing
    endif

    if ARG_PRESENT(vertSpacing) then begin
        vertSpacing = self._vertSpacing
    endif

    if ARG_PRESENT(orientation) then begin
        orientation = self._orientation
    endif

    if ARG_PRESENT(location) then begin
        location = self._location
    endif


    ; get superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::GetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisLegend::SetProperty
;
; PURPOSE:
;      This procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisLegend::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisLegend::Init followed by the word "Set"
;      can be set using IDLitVisLegend::SetProperty.
;-

pro IDLitVisLegend::SetProperty,  $
    LEGEND_LOCATION=location, $
    TEXT_COLOR=textColor, $
    FONT_INDEX=fontIndex, $
    FONT_SIZE=fontSize, $
    FONT_STYLE=fontStyle, $
    SAMPLE_WIDTH=sampleWidth, $
    HORIZONTAL_SPACING=horizSpacing, $
    VERTICAL_SPACING=vertSpacing, $
    ORIENTATION=orientation, $
    TEXTPOS=textpos, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    bRecompLayout = 0b
    modifiedprops = ''

    if (N_ELEMENTS(textColor) gt 0) then begin
        ; cache textColor even if it does not get applied to any objects
        *self._textColor = textColor
        oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
        for i=0, nItems-1 do begin
            ; ask the item to change its own text color
            oItems[i]->SetProperty, TEXT_COLOR=textColor
        endfor
    endif

    if (N_ELEMENTS(fontIndex) gt 0) then begin
        self._fontIndex = fontIndex
        oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
        for i=0, nItems-1 do begin
            oItems[i]->SetProperty, FONT_INDEX=fontIndex
        endfor
        bRecompLayout = 1b
    endif

    if (N_ELEMENTS(fontStyle) gt 0) then begin
        self._fontStyle = fontStyle
        oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
        for i=0, nItems-1 do begin
            oItems[i]->SetProperty, FONT_STYLE=fontStyle
        endfor
        bRecompLayout = 1b
    endif

    if (N_ELEMENTS(fontSize) gt 0) then begin
        self._fontSize = fontSize
        oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
        for i=0, nItems-1 do begin
            oItems[i]->SetProperty, FONT_SIZE=fontSize
        endfor
        bRecompLayout = 1b
    endif

    if (N_ELEMENTS(sampleWidth) gt 0) then begin
        self._sampleWidth = sampleWidth
        oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
        for i=0, nItems-1 do begin
            if (~OBJ_VALID(oItems[i])) then break
            oItems[i]->SetProperty, SAMPLE_WIDTH=sampleWidth
        endfor
        bRecompLayout = 1b
    endif

    if (N_ELEMENTS(horizSpacing) gt 0) then begin
        self._horizSpacing = horizSpacing
        oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
        for i=0, nItems-1 do begin
            oItems[i]->SetProperty, HORIZONTAL_SPACING=horizSpacing
        endfor
        bRecompLayout = 1b
    endif

    if (N_ELEMENTS(vertSpacing) gt 0) then begin
        ; some but not all items need to be updated for vertical spacing
        self._vertSpacing = vertSpacing
        oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
        for i=0, nItems-1 do begin
            oItems[i]->SetProperty, VERTICAL_SPACING=vertSpacing
        endfor
        bRecompLayout = 1b
    endif

    ; Flip the orientation.
    if (N_ELEMENTS(orientation) eq 1) then begin
        if (orientation ne self._orientation) then begin
            self._orientation = orientation
            bRecompLayout = 1b
        endif
    endif

    if (N_ELEMENTS(location) gt 0) then begin
        if (location ne self._location) then begin
            self._location = location
            ; change to the new position if necessary
            if (location gt 0) then begin
                bRecompLayout = 1b
            endif
        endif
    endif

    ; Set superclass properties.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::SetProperty, _EXTRA=_extra

    if (bRecompLayout) then $
        self->RecomputeLayout

end


;----------------------------------------------------------------------------
function IDLitVisLegend::GetHitVisualization, oSubHitList

    compile_opt idl2, hidden

    oReturn=OBJ_NEW()
    if (N_ELEMENTS(oSubHitList) ge 2) then begin
        if (OBJ_ISA(oSubHitList[0], 'IDLitVisLegendPlotItem') && $
                OBJ_ISA(oSubHitList[1], 'IDLgrPolyline') || $
            (OBJ_ISA(oSubHitList[0], 'IDLitVisLegendContourItem') && $
                OBJ_ISA(oSubHitList[1], 'IDLgrContour')) || $
            (OBJ_ISA(oSubHitList[0], 'IDLitVisLegendSurfaceItem') && $
                OBJ_ISA(oSubHitList[1], 'IDLgrSurface'))) then begin
            oVis = oSubHitList[0]->GetVis()
            return, oVis
        endif
    endif

    return, self->_IDLitVisualization::GetHitVisualization(oSubHitList)

end


;----------------------------------------------------------------------------
; IIDLDataObserver Interface
;----------------------------------------------------------------------------
pro IDLitVisLegend::OnNotify, strItem, StrMsg, strUser

    compile_opt idl2, hidden

    case StrMsg of

        "DELETE": begin
            oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
            for i=0, nItems-1 do begin
                if (~OBJ_ISA(oItems[i], 'IDLitVisLegendItem')) then continue
                oVis = oItems[i]->GetVis()
                oItems[i]->IDLitComponent::GetProperty, $
                    IDENTIFIER=identifier
                self->RemoveOnNotifyObserver, $
                    strItem + '/' + identifier, $
                    oVis->GetFullIdentifier()
            endfor
            end

        "UNDELETE": begin
            oTool = self->GetTool()
            oItem = oTool->GetByIdentifier(strItem)
            self->AddToLegend, oItem

            end

        else:

    endcase

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisLegend::OnDataChange
;
; PURPOSE:
;    This procedure method is called by a Subject via a Notifier when
;    its data has changed.  This method obtains the data from the subject
;    and updates the IDLgrImage object.
;
; CALLING SEQUENCE:
;
;    Obj->[IDLitVisLegend::]OnDataChange, oSubject
;
; INPUTS:
;    oSubject: The Subject object in the Subject-Observer relationship.
;    This object (the image) is the observer, so it uses the
;    IIDLDataSource interface to get the data from the subject.
;    Then, it puts the data in the IDLgrImage object.
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;
; SIDE EFFECTS:
;
; RESTRICTIONS:
;
; PROCEDURE:
;
; EXAMPLE:
;
;-

pro IDLitVisLegend::OnDataChangeUpdate, oSubject, parmName

    compile_opt idl2, hidden



    case STRUPCASE(parmName) OF
        'VISUALIZATIONS': begin
            success = oSubject->GetData(oVis)
            if(success eq 1)then begin
                self->AddToLegend, oVis
                oSubject->RemoveDataObserver, self

            endif


            end
        else: ; ignore unknown parameters
    endcase

end

;---------------------------------------------------------------------------
; IDLitVisLegend::OnViewZoom
;
; Purpose:
;   This procedure method handles notification that the view zoom factor
;   has changed
;
; Arguments:
;   oSubject: A reference to the object sending notification of the
;     view zoom factor change.
;
;   oDestination: A reference to the destination in which the view
;     appears.
;
;   viewZoom: The new zoom factor for the view.
;
pro IDLitVisLegend::OnViewZoom, oSubject, oDestination, viewZoom

    compile_opt idl2, hidden

    oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
    if (~nItems) then $
        return

    for i=0,nItems-1 do begin
        ; Check if view zoom factor has changed.  If so, update the font.
        oItems[i]->GetProperty, VIEW_ZOOM=fontViewZoom

        if (fontViewZoom ne viewZoom) then $
            oItems[i]->SetProperty, VIEW_ZOOM=viewZoom

        oItems[i]->RecomputeLayout
    endfor
end

;---------------------------------------------------------------------------
; IDLitVisLegend::OnViewportChange
;
; Purpose:
;   This procedure method handles notification that the viewport has
;   changed.
;
; Arguments:
;   oSubject: A reference to the object sending notification of the
;     viewport change.
;
;   oDestination: A reference to the destination in which the view
;     appears.
;
;   viewportDims: A 2-element vector, [w,h], representing the new
;     width and height of the viewport (in pixels).
;
;   normViewDims: A 2-element vector, [w,h], representing the new 
;     width and height of the visibile view (normalized relative to 
;     the virtual canvas).
;
pro IDLitVisLegend::OnViewportChange, oSubject, oDestination, $
    viewportDims, normViewDims

    compile_opt idl2, hidden

    oItems = self->Get(/ALL, /SKIP_PRIVATE, COUNT=nItems)
    if (~nItems) then $
        return

    if (OBJ_VALID(oDestination)) then $
        oDestination->GetProperty, CURRENT_ZOOM=zoomFactor $
    else $
        zoomFactor = 1.0

    normFactor = MIN(normViewDims)

    for i=0,nItems-1 do begin
        oItems[i]->GetProperty, FONT_ZOOM=fontZoom, FONT_NORM=fontNorm

        if ((fontZoom ne zoomFactor) || $
            (fontNorm ne normFactor)) then $
            oItems[i]->SetProperty, FONT_ZOOM=zoomFactor, FONT_NORM=normFactor

        ; If zoom factor was not the source of the change, then recompute 
        ; layout.
        if (fontZoom eq zoomFactor) then $
            oItems[i]->RecomputeLayout
    endfor
end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisLegend__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisLegend object.
;
;-
pro IDLitVisLegend__Define

    compile_opt idl2, hidden

    struct = { IDLitVisLegend,           $
        inherits IDLitVisualization, $
        _oPolygon: OBJ_NEW(),        $
        _textColor: PTR_NEW(), $
        _location: 0L,        $
        _orientation: 0L,        $
        _sampleWidth:0.0d, $
        _fontIndex: 0L, $
        _fontStyle: 0L, $
        _fontSize: 0L, $
        _horizSpacing:0.0d, $
        _vertSpacing:0.0d $
    }
end
