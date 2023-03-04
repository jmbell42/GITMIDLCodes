; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/components/idlitvispolygon__define.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;    Unauthorized reproduction prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisPolygon
;
; PURPOSE:
;    The IDLitVisPolygon class implements a a polygon visualization
;    object for the iTools system.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;   IDLitVisualization
;
;-

;----------------------------------------------------------------------------
; IDLitVisPolygon::Init
;
; Purpose:
;   Initialization routine of the object.
;
; Parameters:
;   None.
;
; Keywords:
;   NAME   - The name to associated with this item.
;
;   Description - Short string that will describe this object.
;
;   All other keywords are passed to th super class
function IDLitVisPolygon::Init, $
                        _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    if (~self->IDLitVisualization::Init( $
        NAME="Polygon", DESCRIPTION="A Polygon", $
        TYPE='IDLPOLYGON', ICON='freeform', $
        IMPACTS_RANGE=0, $
        _EXTRA=_EXTRA))then $
        return, 0


    self._closed = 1b  ; default is to close the polyline
    self._fillBackground = 1b

    ; This will also register our X parameter.
    dummy = self->_IDLitVisVertex::Init(POINTS_NEEDED=3)

    self._oPolygon = obj_new('IDLgrPolygon', $
        COLOR=[255,255,255], $
        /PRIVATE, $
        STYLE=2)
    self->Add, self._oPolygon, /NO_NOTIFY

    self._oLine = OBJ_NEW('IDLgrPolyline', /PRIVATE)
    self->Add, self._oLine, /NO_NOTIFY

    ; Register all properties.
    self->IDLitVisPolygon::_RegisterProperties

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisPolygon::SetProperty, _EXTRA=_extra

    RETURN, 1 ; Success
end


;----------------------------------------------------------------------------
; IDLitVisPolygon::Cleanup
;
; Purpose:
;   Cleanup/destrucutor method for this object.
;
; Parameters:
;   None.
;
; Keywords:
;    None.
pro IDLitVisPolygon::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oTessellate

    ; Cleanup superclass
    self->IDLitVisualization::Cleanup
end


;----------------------------------------------------------------------------
; IDLitVisPolygon::_RegisterProperties
;
; Purpose:
;   Internal routine that will register all properties supported by
;   this object.
;
; Keywords:
;   UPDATE_FROM_VERSION: Set this keyword to a scalar representing the
;     component version from which this object is being updated.  Only
;     properties that need to be registered to update from this version
;     will be registered.  By default, all properties associated with
;     this class are registered.
;
pro IDLitVisPolygon::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin
        ; Register our outline properties.
        self->RegisterProperty, 'COLOR', /COLOR, $
            NAME='Color', $
            DESCRIPTION='Outline color'

        self->RegisterProperty, 'LINESTYLE', /LINESTYLE, $
            NAME='Line style', $
            DESCRIPTION='Outline style'

        self->RegisterProperty, 'THICK', /THICKNESS, $
            NAME='Thickness', $
            DESCRIPTION='Outline thickness'

        ; Register our polygon properties.
        self->RegisterProperty, 'FILL_BACKGROUND', /BOOLEAN, $
            NAME='Fill background', $
            DESCRIPTION='Fill polygon'

        self->RegisterProperty, 'FILL_COLOR', /COLOR, $
            NAME='Fill color', $
            DESCRIPTION='Fill color'

        self->RegisterProperty, 'SHADING', $
            NAME='Shading', $
            ENUMLIST=['Flat','Gouraud'], $
            DESCRIPTION='Shading Method', /HIDE

        self->RegisterProperty, 'TRANSPARENCY', /INTEGER, $
            NAME='Transparency', $
            DESCRIPTION='Transparency of the polygon', $
            VALID_RANGE=[0, 100, 5]

        self->RegisterProperty, 'USE_BOTTOM_COLOR', /BOOLEAN, /HIDE, $
            NAME='Use bottom color', $
            DESCRIPTION='Use the bottom color instead of matching the top'

        self->RegisterProperty, 'BOTTOM', /COLOR, /HIDE, $
            NAME='Bottom color', $
            DESCRIPTION='Bottom color', $
            SENSITIVE=0
    endif

    if (registerAll || (updateFromVersion lt 610)) then begin
        ; Register these properties, but hide them, as not all uses
        ; of this object require these properties.
        self->RegisterProperty, 'AMBIENT', /COLOR, /HIDE, $
            NAME='Ambient Reflective Color', $
            DESCRIPTION='Ambient Reflective Color'

        self->RegisterProperty, 'DIFFUSE', /COLOR, /HIDE, $
            NAME='Diffuse Reflective Color', $
            DESCRIPTION='Diffuse Reflective Color'

        self->RegisterProperty, 'SPECULAR', /COLOR, /HIDE, $
            NAME='Specular Highlight Color', $
            DESCRIPTION='Specular Highlight Color'

        self->RegisterProperty, 'EMISSION', /COLOR, /HIDE, $
            NAME='Emissive Color', $
            DESCRIPTION='Emissive Color'

        self->RegisterProperty, 'SHININESS', /FLOAT, /HIDE, $
            NAME='Shininess', $
            DESCRIPTION='Shininess', $
            VALID_RANGE=[0, 128, 1]
    endif

    if (registerAll) then begin
        ; These need to be registered so Copy/Paste works correctly,
        ; but are hidden from the Property Sheet.
        self->RegisterProperty, 'NO_CLOSE', /BOOLEAN, /HIDE, $
            NAME='No close', $
            DESCRIPTION='Do not close the polyline'
        self->RegisterProperty, 'TESSELLATE', /BOOLEAN, /HIDE, $
            NAME='Tessellate polygon', $
            DESCRIPTION='Tessellate the polygon'
    endif

    if (registerAll || (updateFromVersion lt 610)) then begin
        ; This is registered to provide macro support for polygons
        self->RegisterProperty, '_DATA', NAME='Vertices', USERDEF='', /HIDE
    endif

end


;----------------------------------------------------------------------------
; IDLitVisPolygon::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save file to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisPolygon::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Register new properties.
    self->IDLitVisPolygon::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin
        ; We added a _fillBackground field in IDL61 to keep track of the
        ; filled value, irrespective of whether there was data or not.
        ; The HIDE property was previously used to store the filled value,
        ; but we can't rely on that, since it could be hidden if no data.
        self._oPolygon->GetProperty, HIDE=hide
        self._fillBackground = ~hide
    endif

end

;---------------------------------------------------------------------------
; IDLitVisPolygon::OnDataChangeUpdate
;
; Purpose:
;   This method is called by the framework when the data associated
;   with this object is modified or initially associated.
;
; Parameters:
;   oSubject   - The data object of the parameter that changed. if
;                parmName is "<PARAMETER SET>", this is an
;                IDLitParameterSet object
;
;   parmName   - The name of the parameter that changed.
;
; Keywords:
;   None.
;
pro IDLitVisPolygon::OnDataChangeUpdate, oSubject, parmName

    compile_opt idl2, hidden

    switch STRUPCASE(parmName) of

    '<PARAMETER SET>': ; fall thru
    'VERTICES':  ; fall thru
    'CONNECTIVITY': begin
        self._calcFill = 0b
        self->_UpdateData
        end

    else: ; ignore unknown parameters

    endswitch

end


;----------------------------------------------------------------------------
pro IDLitVisPolygon::OnProjectionChange, sMap

    compile_opt idl2, hidden

    self._calcFill = 0b
    self->_UpdateData, sMap
    self->UpdateSelectionVisual

end


;----------------------------------------------------------------------------
; sMap: Contains the map structure. Will be automatically
;   retrieved if not supplied.
;
function IDLitVisPolygon::_TessellateShapes, data, connectivity, shapes, $
    MAP_STRUCTURE=sMap, $
    POLYGONS=polygons

    compile_opt idl2, hidden

    oTool = self->GetTool()
    if (OBJ_VALID(oTool)) then $
        void = oTool->DoUIService("HourGlassCursor", self)

    nShape = N_ELEMENTS(shapes)
    hasMap = N_TAGS(sMap) gt 0

    offset = 0

    for i=0,nShape-1 do begin

        ; Pull out the individual shape and its vertices.
        polyshape1 = (i lt nShape-1) ? $
            connectivity[shapes[i]:shapes[i+1]-1] : $
            connectivity[shapes[i]:*]
        idx = 0
        nvert = 0
        while (idx lt N_ELEMENTS(polyshape1)) do begin
            n1 = polyshape1[idx]
            if (n1 eq -1) then $
                break
            if (n1 eq 0) then $
                continue
            ; Concat the individual shape parts and create a new
            ; connectivity array for the tessellator to use.
            datasub = data[*, polyshape1[idx+1:idx+n1]]
            polysub = [n1, LINDGEN(n1)+nvert]
            vert1 = (idx gt 0) ? [[vert1], [datasub]] : datasub
            polygons1 = (idx gt 0) ? [polygons1, polysub] : polysub
            idx += n1 + 1
            nvert += n1
        endwhile

        if (N_ELEMENTS(vert1) le 1) then $
                continue

        if (hasMap) then begin
            vert1 = MAP_PROJ_FORWARD(vert1[0:1,*], $
                MAP=sMap, $
                CONNECTIVITY=polygons1, $
                POLYGONS=polygons1)
            ; See if polygon is off the map.
            if (N_ELEMENTS(vert1) le 1) then $
                continue
        endif

        ; Tessellate
        self._oTessellate->AddPolygon, TEMPORARY(vert1), $
            POLYGON=TEMPORARY(polygons1)
        success = self._oTessellate->Tessellate(vert1, polygons1)
        self._oTessellate->Reset
        if (~success) then $
            continue
        ; Offset this connectivity by the total # of verts.
        ; This assumes the connectivity is sets of triangles.
        polygons1[1:*:4] += offset
        polygons1[2:*:4] += offset
        polygons1[3:*:4] += offset
        offset += N_ELEMENTS(vert1)/N_ELEMENTS(vert1[*,0])

        ; Append the vertices and connectivity for this shape.
        if (N_ELEMENTS(vert) gt 0) then begin
            vert = [[TEMPORARY(vert)], [TEMPORARY(vert1)]]
            polygons = [TEMPORARY(polygons), TEMPORARY(polygons1)]
        endif else begin
            vert = TEMPORARY(vert1)
            polygons = TEMPORARY(polygons1)
        endelse

    endfor

    return, (N_ELEMENTS(vert) gt 0) ? vert : 0
end


;----------------------------------------------------------------------------
; sMap: Optional argument giving the map structure. Will be automatically
;   retrieved if not supplied.
;
pro IDLitVisPolygon::_UpdateData, sMap

    compile_opt idl2, hidden

    oVert = self->GetParameter('VERTICES')
    if (~OBJ_VALID(oVert) || ~oVert->GetData(data)) then $
        goto, skip
    if (N_ELEMENTS(data) le 1 || SIZE(data, /N_DIMENSIONS) ne 2) then $
        goto, skip

    oConn = self->GetParameter('CONNECTIVITY')
    if (OBJ_VALID(oConn)) then $
        void = oConn->GetData(connectivity)

    dims = SIZE(data, /DIMENSIONS)

    ; Set our visualization to 2D or 3D
    if (dims[0] eq 3) then begin
        minn = MIN(data[2,*], MAX=maxx)
        diff = (minn eq 0) ? ABS(maxx) : (maxx-minn)/(ABS(maxx)>ABS(minn))
        is3D = diff gt 1d-6
    endif else begin
        is3D = 0b
    endelse
    if (is3D ne self->Is3D()) then $
        self->Set3D, is3D

    ; See if we also have a map projection.
    hasMap = ~is3D
    if (hasMap) then begin
        if (~N_ELEMENTS(sMap)) then $
            sMap = self->GetProjection()
        hasMap = N_TAGS(sMap) gt 0
        ; If we have data values out of the normal lonlat range, then
        ; assume these are not coordinates in degrees.
        if (hasMap) then begin
            minn = MIN(data, DIMENSION=2, MAX=maxx)
            if (minn[0] lt -360 || maxx[0] gt 720 || $
                minn[1] lt -90 || maxx[1] gt 90) then hasMap = 0
        endif
    endif


    ; Map transform the polyline data if necessary.
    if (hasMap) then begin
        linedata = MAP_PROJ_FORWARD(data[0:1,*], $
            MAP=sMap, $
            CONNECTIVITY=connectivity, $
            POLYLINES=polylines)
    endif else begin
        linedata = data
        if (N_ELEMENTS(connectivity) gt 0) then $
            polylines = connectivity
    endelse


    if (~self._fillBackground) then $
        goto, skip


    useTessellator = OBJ_VALID(self._oTessellate)

    if (useTessellator && N_ELEMENTS(connectivity) gt 0) then begin
        ; The SHAPES parameter is a vector, each element of which
        ; is the starting index within the CONNECTIVITY of the
        ; next shape. This allows multiple shapes to be stored
        ; within a single parameter set, but still have the
        ; IDLitVisPolygon tessellate them separately.
        oShape = self->GetParameter('SHAPES')
        if (~OBJ_VALID(oShape) || ~oShape->GetData(shapes)) then $
            shapes = 0
    endif


    if (N_ELEMENTS(shapes) gt 1) then begin

        vert = self->_TessellateShapes(data, connectivity, shapes, $
            MAP_STRUCTURE=hasMap ? sMap : 0, $
            POLYGONS=polygons)

    endif else begin   ; no tessellation or only 1 shape

        if (hasMap) then begin
            data = MAP_PROJ_FORWARD(data[0:1,*], $
                MAP=sMap, $
                CONNECTIVITY=connectivity, $
                POLYGONS=connectivity)
        endif

        ; Do we need to tessellate?
        if (useTessellator && N_ELEMENTS(data) gt 1) then begin
            ; The Z values may be all identical, but nonzero.
            ; In this case, save the Z value, so the tessellator
            ; doesn't mess it up.
            dim0 = (SIZE(data, /DIMENSIONS))[0]
            if (~is3D && dim0 eq 3) then $
                zvalue = data[2,0]
            self._oTessellate->AddPolygon, data, POLYGON=connectivity
            if (~self._oTessellate->Tessellate(vert, polygons)) then begin
                vert = TEMPORARY(data)
                if (N_ELEMENTS(connectivity) gt 0) then $
                    polygons = TEMPORARY(connectivity)
            endif
            self._oTessellate->Reset
            ; Restore the Z value if necessary. This prevents the
            ; tessellator from tweaking the Z values.
            if (~is3D && dim0 eq 3) then $
                vert[2,*] = zvalue
        endif else begin
            vert = TEMPORARY(data)
            if (N_ELEMENTS(connectivity) gt 0) then $
                polygons = TEMPORARY(connectivity)
        endelse

    endelse


skip:

    if (N_ELEMENTS(vert) gt 1) then begin

        self._calcFill = 1b

        ; If the data is being set, then the connectivity list
        ; needs to be either provided or to be reset, otherwise
        ; we might get an invalid connectivity list error.
        self._oPolygon->SetProperty, DATA=vert, $
            HIDE=~self._fillBackground, $
            POLYGONS=(N_ELEMENTS(polygons) gt 0) ? polygons : 0

    endif else begin

        ; Hide our polygon if data is a scalar.
        ; Also reset the data & connectivity so GetXYZRange doesn't
        ; return the old data range.
        self._oPolygon->SetProperty, /HIDE, DATA=FLTARR(2,3), POLYGONS=0

    endelse

    if (N_ELEMENTS(linedata) gt 1) then begin
        ; If necessary, attach the last point of the line to the first.
        if (self._closed && $
            ~ARRAY_EQUAL(linedata[*,0], linedata[*,dims[1]-1])) then begin
            linedata = [[linedata], [linedata[*,0]]]
        endif

        ; If the data is being set, then the connectivity list
        ; needs to be either provided or to be reset, otherwise
        ; we might get an invalid connectivity list error.
        self._oLine->SetProperty, HIDE=0, $
            DATA=linedata, $
            POLYLINES=(N_ELEMENTS(polylines) gt 0) ? polylines : 0

    endif else begin

        ; Hide our polyline if data is a scalar.
        ; Also reset the data & connectivity so GetXYZRange doesn't
        ; return the old data range.
        self._oLine->SetProperty, /HIDE, DATA=[0,0], POLYLINES=0

    endelse

end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;   IDLitVisPolygon::OnWorldDimensionChange
;
; PURPOSE:
;   This procedure method handles notification that the dimensionality
;   of the parent world has changed.
;
; CALLING SEQUENCE:
;   Obj->[IDLitVisPolygon::]OnWorldDimensionChange, Subject, is3D
;
; INPUTS:
;   Subject: A reference to the object sending notification of the
;            dimensionality change.
;   is3D: new 3D setting of Subject.
;-
PRO IDLitVisPolygon::OnWorldDimensionChange, oSubject, is3D
  compile_opt idl2, hidden

  is3D = 0b

  self._oPolygon->GetProperty, DATA=data

  ;; Ignore check if oSubject is IDLitgrWorld
  if (obj_isa(oSubject,'_IDLitVisualization') && $
      n_elements(data) GT 1 && size(data,/n_dimensions) EQ 2) then BEGIN
    ;; If data has a Z component then check to see if it is 3D.
    dims = SIZE(data, /DIMENSIONS)
    if (dims[0] eq 3) then begin
      minn = MIN(data[2,*], MAX=maxx)
      is3D = minn ne maxx
    ENDIF
    ;; If either polygon data or dataspace is 3D then mark self as 3D
    ;; so that lighting will look right.
    is3d OR= oSubject->is3D()

    if (is3D ne self->Is3D()) then $
        self->Set3D, is3D
  ENDIF

  ;: Call superclass
  self->_IDLitVisualization::OnWorldDimensionChange, oSubject, is3D

END

;----------------------------------------------------------------------------
; PURPOSE:
;   This function method retrieves the LonLat range of
;   contained visualizations. Override the _Visualization method
;   so we can retrieve the correct range.
;
function IDLitVisPolygon::GetLonLatRange, lonRange, latRange, $
    MAP_STRUCTURE=sMap

    compile_opt idl2, hidden

    oVert = self->GetParameter('VERTICES')
    if (~OBJ_VALID(oVert) || ~oVert->GetData(pData, /POINTER)) then $
        return, 0
    if (N_ELEMENTS(*pData) le 1 || SIZE(*pData, /N_DIMENSIONS) ne 2) then $
        return, 0

    ; Just assume that if we have vertex data, and it is within lon/lat
    ; limits, that it is indeed longitude/latitude data. This method should
    ; only be called from classes such as the MapGrid anyway.
    minn = MIN(*pData, DIMENSION=2, MAX=maxx)
    if (minn[0] lt -360 || maxx[0] gt 720 || $
        minn[1] lt -90 || maxx[1] gt 90) then $
        return, 0

    lonRange = [minn[0], maxx[0]]
    latRange = [minn[1], maxx[1]]

    return, 1

end


;----------------------------------------------------------------------------
; Purpose:
;   This routine implements the Getproperty method for this
;   visualization class.
;
pro IDLitVisPolygon::GetProperty, $
    FILL_COLOR=backgroundColor, $
    BOTTOM=bottom, $
    COLOR=lineColor, $
    LINESTYLE=lineStyle, $
    THICK=lineThick, $
    FILL_BACKGROUND=fillBackground, $
    TRANSPARENCY=transparency, $
    NO_CLOSE=noClose, $   ; don't close the polyline
    POLYLINES=polylines, $
    TESSELLATE=tessellate, $
    USE_BOTTOM_COLOR=useBottomColor, $
    _DATA=_data, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Handle our properties.
    if (ARG_PRESENT(bottom) || ARG_PRESENT(useBottomColor)) then begin
        self._oPolygon->GetProperty, BOTTOM=bottom
        useBottomColor = 1 - ARRAY_EQUAL(bottom, -1)
    endif

    if (ARG_PRESENT(backgroundColor)) then $
        self._oPolygon->GetProperty, COLOR=backgroundColor

    if (ARG_PRESENT(lineColor)) then $
        self._oLine->GetProperty, COLOR=lineColor

    if (ARG_PRESENT(lineStyle)) then $
        self._oLine->GetProperty, LINESTYLE=lineStyle

    if (ARG_PRESENT(lineThick)) then $
        self._oLine->GetProperty, THICK=lineThick

    if (ARG_PRESENT(polylines)) then $
        self._oLine->GetProperty, POLYLINES=polylines

    if (ARG_PRESENT(transparency)) then begin
        self._oPolygon->GetProperty, ALPHA_CHANNEL=alpha
        transparency = 0 > FIX(100 - alpha*100) < 100
    endif

    if (ARG_PRESENT(fillBackground)) then $
        fillBackground = self._fillBackground

    if (ARG_PRESENT(noClose)) then $
        noClose = ~self._closed

    if (ARG_PRESENT(tessellate)) then $
        tessellate = OBJ_VALID(self._oTessellate)

    if (ARG_PRESENT(_data)) then begin
        ; Retrieve data values. This is for use by the undo/redo command.
        oDataObj = self->GetParameter('VERTICES')
        if (OBJ_VALID(oDataObj)) then $
            success = oDataObj->GetData(_data)
    endif

    ; Pass on to superclass.
    if (N_ELEMENTS(_extra) gt 0) then begin
        ; My polygon isn't aggregated, so I need to get props directly.
        self._oPolygon->GetProperty, _EXTRA=_extra
        self->IDLitVisualization::GetProperty, _EXTRA=_extra
    endif

end


;----------------------------------------------------------------------------
; Purpose:
;    Implements the SetPoperty Method for this polygon object.
;
pro IDLitVisPolygon::SetProperty, $
    FILL_COLOR=backgroundColor, $
    DATA=data, $
    COLOR=lineColor, $
    LINESTYLE=lineStyle, $
    NO_CLOSE=noClose, $   ; don't close the polyline
    THICK=lineThick, $
    FILL_BACKGROUND=fillBackground, $
    TRANSPARENCY=transparency, $
    LINEDATA=linedata, $
    POLYGONS=polygons, $
    POLYLINES=polylines, $
    TESSELLATE=tessellate, $
    USE_BOTTOM_COLOR=useBottomColor, $
    _DATA=_data, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Handle our properties.
    if (N_ELEMENTS(useBottomColor)) then begin
        ; Either set our bottom color to white (turning it on),
        ; or reset it to -1 (turning it off).
        self._oPolygon->SetProperty, $
            BOTTOM=KEYWORD_SET(useBottomColor) ? [255,255,255] : -1
        self->SetPropertyAttribute, 'BOTTOM', $
            SENSITIVE=KEYWORD_SET(useBottomColor)
    endif

     ; Don't close the polyline
    if (N_ELEMENTS(noClose)) then $
        self._closed = ~KEYWORD_SET(noClose)

    if (N_ELEMENTS(backgroundColor) gt 0) then $
        self._oPolygon->SetProperty, COLOR=backgroundColor

    if (N_ELEMENTS(lineColor) gt 0) then $
        self._oLine->SetProperty, COLOR=lineColor

    if (N_ELEMENTS(lineStyle)) then $
        self._oLine->SetProperty, LINESTYLE=lineStyle

    if (N_ELEMENTS(lineThick)) then $
        self._oLine->SetProperty, THICK=lineThick

    if (N_ELEMENTS(fillBackground)) then begin
        self._fillBackground = KEYWORD_SET(fillBackground)
        self->SetPropertyAttribute, ['FILL_COLOR', 'TRANSPARENCY'], $
            SENSITIVE=self._fillBackground
        ; Has the fill data already been calculated?
        if (self._calcFill) then begin
            self._oPolygon->SetProperty, HIDE=~self._fillBackground
        endif else begin
            self->_UpdateData
        endelse
    endif

    if (N_ELEMENTS(transparency)) then begin
        self._oPolygon->SetProperty, $
            ALPHA_CHANNEL=0 > ((100.-transparency)/100) < 1
    endif


    ; Tessellate property.
    if (N_ELEMENTS(tessellate)) then begin
        if KEYWORD_SET(tessellate) then begin
            ; Turn on tessellation by creating our object
            ; (if it hasn't already been created).
            if (~OBJ_VALID(self._oTessellate)) then $
                self._oTessellate = OBJ_NEW('IDLgrTessellator')
        endif else begin
            ; Turn off tessellation by destroying our object
            OBJ_DESTROY, self._oTessellate
        endelse
        self._calcFill = 0b
        self->_UpdateData
    endif


    ; My polygon isn't aggregated, so I need to set props directly.
    if (N_ELEMENTS(_extra) gt 0) then $
        self._oPolygon->SetProperty, _EXTRA=_extra


    if (N_ELEMENTS(_data) gt 0) then begin
        ; Set data values. This is for use by the undo/redo command and macros.
        oDataObj = self->GetParameter('VERTICES')
        if (~OBJ_VALID(oDataObj)) then begin
            oDataObj = OBJ_NEW("IDLitData", _data, NAME='Vertices', $
                TYPE='IDLVERTEX', ICON='segpoly', /PRIVATE)
            void = self->SetData(oDataObj, $
                PARAMETER_NAME= 'VERTICES', /BY_VALUE)
        endif else begin
            success = oDataObj->SetData(_data, /NO_COPY)
        endelse
    endif

    ; Manually set our data.
    if (N_ELEMENTS(data) gt 0) then begin
        self._oLine->SetProperty, DATA=data, HIDE=N_ELEMENTS(data) le 1
        if (OBJ_VALID(self._oTessellate) && N_ELEMENTS(data) gt 1) then begin
            self._oTessellate->AddPolygon, data
            void = self._oTessellate->Tessellate(data, polygons)
            self._oTessellate->Reset
        endif
        self._oPolygon->SetProperty, DATA=data, POLYGONS=polygons, $
            HIDE=(N_ELEMENTS(data) le 1) || ~self._fillBackground
        ; If we are manually setting our data, then assume we don't
        ; want to ever go thru _UpdateData.
        self._calcFill = 1b
    endif

    ; Pass on to superclass.
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisualization::SetProperty, _EXTRA=_extra

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisPolygon__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisPolygon object.
;
;-
pro IDLitVisPolygon__Define

    compile_opt idl2, hidden

    struct = { IDLitVisPolygon,           $
               inherits IDLitVisualization, $
               inherits _IDLitVisVertex, $
               _oPolygon: OBJ_NEW(),$
               _oLine: OBJ_NEW(), $
               _oTessellate: OBJ_NEW(), $
               _closed: 0b, $
               _fillBackground: 0b, $
               _calcFill: 0b $
             }
end
