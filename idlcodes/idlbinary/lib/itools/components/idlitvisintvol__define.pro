; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/components/idlitvisintvol__define.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;    Unauthorized reproduction prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisIntVol
;
; PURPOSE:
;    The IDLitVisIntVol class implements an Interval Volume visualization
;    object for the iTools system.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;   IDLitVisualization
;
;-

;;----------------------------------------------------------------------------
;; IDLitVisIntVol::Init
;;
;; Purpose:
;;   Initialization routine of the object.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;   NAME   - The name to associated with this item.
;;
;;   Description - Short string that will describe this object.
;;
;;   All other keywords are passed to the super class
function IDLitVisIntVol::Init, $
                         NAME=name, $
                         DESCRIPTION=description, $
                         _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if(not KEYWORD_SET(name))then name ="Interval Volume"
    if(not KEYWORD_SET(description))then description ="An Interval Volume"
    ; Initialize superclass
    if (not self->IDLitVisPolygon::Init(NAME=name, $
                                        TYPE='IDLINTERVAL VOLUME', $
                                        ICON='volume', $
                                        DESCRIPTION=description, $
                                        COLOR=[0b,0b,0b], $
                                        LINESTYLE=6, $
                                        SHADING=1, $
                                        /IMPACTS_RANGE, $
                                        _EXTRA=_extra))then $
        return, 0

    ;; Register Parameters

    ;; These are "INPUT" parameters.  They are used to access the data needed
    ;; needed to compute the isosurface.  They also notify us (via OnDataChangeUpdate)
    ;; when something changes that will cause us to change the isosurface.

    self->RegisterParameter, 'VOLUME', DESCRIPTION='Volume', $
        /INPUT, TYPES='IDLARRAY3D'
    self->RegisterParameter, 'RGB_TABLE', DESCRIPTION='RGB Table', $
        /INPUT, /OPTIONAL, TYPES=['IDLPALETTE','IDLARRAY2D']
    self->RegisterParameter, 'VOLUME_DIMENSIONS', DESCRIPTION='Volume Dimensions', $
        /INPUT, /OPTIONAL, TYPES='IDLVECTOR'
    self->RegisterParameter, 'VOLUME_LOCATION', DESCRIPTION='Volume Location', $
        /INPUT, /OPTIONAL, TYPES='IDLVECTOR'

    ;; These parameters are "OUTPUT" parameters in the sense
    ;; that this object generates the data for these parameters.
    self->SetParameterAttribute, ['VERTICES', 'CONNECTIVITY'], $
        INPUT=0, OUTPUT=1, OPTARGET=0

    self->RegisterParameter, 'POLYGONS', $
        DESCRIPTION='Interval Volume Surface Connectivity List', $
        TYPES='IDLVECTOR'
    self->RegisterParameter, 'TETRAHEDRA', $
        DESCRIPTION='Interval Volume Tetrahedra List', $
        TYPES='IDLVECTOR'
    self->RegisterParameter, 'VERTEX_COLORS', $
        DESCRIPTION='Interval Volume Surface Vertex Color Indices', $
        TYPES='IDLVECTOR'

    ;; Register Properties
    self->RegisterProperty, 'Isovalues', USERDEF='Select isovalues', $
        DESCRIPTION='Interval Volume values.'

    self->RegisterProperty, '_ISOVALUE0', /FLOAT, $
        NAME='Isovalue0', $
        DESCRIPTION='Isovalue0', /HIDE

    self->RegisterProperty, '_ISOVALUE1', /FLOAT, $
        NAME='Isovalue1', $
        DESCRIPTION='Isovalue1', /HIDE

    self->RegisterProperty, 'SOURCE_COLOR', $
        ENUMLIST=['Isovalue selected (Volume color table)', $
                  'User selected (Fill Color Property)'], $
        DESCRIPTION='Method of selecting color for interval volume', $
        NAME='Source color'

    self->SetPropertyAttribute, 'SHADING', HIDE=0

    ;; Hide to avoid showing on style sheet.
    self->SetPropertyAttribute, 'Isovalues', HIDE=1

    ;; Init state
    self._fillColor = [255b,0b,0b]
    self->IDLitVisPolygon::SetProperty, FILL_COLOR=self._fillColor
    self._decimate = 100

    self->Set3D, /ALWAYS
    self->SetDefaultSelectionVisual, OBJ_NEW('IDLitManipVisSelectBox', /HIDE)

    RETURN, 1 ; Success
end


;;----------------------------------------------------------------------------
;; IDLitVisIntVol::Cleanup
;;
;; Purpose:
;;   Cleanup/destrucutor method for this object.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;    None.
pro IDLitVisIntVol::Cleanup

    compile_opt idl2, hidden

    obj_destroy,self->GetParameter('VERTICES')
    obj_destroy,self->GetParameter('CONNECTIVITY')
    obj_destroy,self->GetParameter('TETRAHEDRA')
    obj_destroy,self->GetParameter('VERTEX_COLORS')

    ; Cleanup superclass
    self->IDLitvisPolygon::Cleanup
end

;;----------------------------------------------------------------------------
;; IDLitVisIntVol::Restore
;;
;; Purpose:
;;   This procedure method performs any cleanup work required after
;;   an object of this class has been restored from a save file to
;;   ensure that its state is appropriate for the current revision.
;;
pro IDLitVisIntVol::Restore

    compile_opt idl2, hidden

    ; Restore superclass.
    self->_IDLitVisualization::Restore

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL 6.0 to 6.1 or above:
    if (self.idlitcomponentversion lt 610) then begin
        ; Fix up the VERTICES parm so it is not an OPTARGET.
        self->SetParameterAttribute, 'VERTICES', OPTARGET=0

        ; Ensure sensitivity of FILL_COLOR is correct.
        self->SetPropertyAttribute, 'FILL_COLOR', SENSITIVE=self._sourceColor
    endif

end

;;----------------------------------------------------------------------------
;; IDLitVisIntVol::_SetColor
;;
;; Purpose:
;;   Set the Interval Volume colors - either a per-vertex color or a solid.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;    None.

pro IDLitVisIntVol::_SetColor

    compile_opt idl2, hidden

    case self._sourceColor of
    0: begin
        ;; The vertex colors are saved as indices into a volume palette.
        oPal = self->GetParameter('RGB_TABLE')
        oVertColors = self->GetParameter('VERTEX_COLORS')
        success1 = 0
        success2 = 0
        if OBJ_VALID(oPal) then begin
            success1 = oPal->GetData(palette)
            if N_ELEMENTS(palette) ne 256*3 then $
                success1 = 0
        endif
        if OBJ_VALID(oVertColors) then begin
            success2 = oVertColors->GetData(vertexColors)
            if N_ELEMENTS(vertexColors) eq 0 then $
                success2 = 0
        endif

        ;; We have vertex colors and a palette.
        ;; Create RGB color vector from palette lookup.
        if success1 gt 0 and success2 gt 0 then begin
            self->IDLitvisPolygon::SetProperty, $
                VERT_COLORS=palette[*, BYTE(vertexColors)]

        ;; We have just vertex colors - use gray palette for lookup
        endif else if success1 eq 0 and success2 gt 0 then begin
            vc = BYTE(TEMPORARY(vertexColors))
            self->IDLitvisPolygon::SetProperty, $
                VERT_COLORS=TRANSPOSE([[vc],[vc],[vc]])

        ;; No vertex colors.
        endif else begin
            self->IDLitVisPolygon::SetProperty, VERT_COLORS=0
        endelse
    end
    1: self->IDLitVisPolygon::SetProperty, VERT_COLORS=0
    endcase
end

;;----------------------------------------------------------------------------
;; IDLitVisIntVol::_ProgressCallback
;;
;; Purpose:
;;   Callback for Isosurface progress bar
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;    None.

function IDLitVisIntVol::_ProgressCallback, percent, USERDATA=oTool

    compile_opt idl2, hidden

    status = oTool->ProgressBar('Computing Interval Volume...', PERCENT=percent, $
        SHUTDOWN=percent ge 100)
    return, status  ; 0 means cancel
end

;;----------------------------------------------------------------------------
;; IDLitVisIntVol::_DecimateCallback
;;
;; Purpose:
;;   Callback for decimation progress bar
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;    None.

function IDLitVisIntVol::_DecimateCallback, percent, USERDATA=oTool

    compile_opt idl2, hidden

    status = oTool->ProgressBar('Decimating Interval Volume Surface...', PERCENT=percent, $
        SHUTDOWN=percent ge 100)
    return, status  ; 0 means cancel
end

;;----------------------------------------------------------------------------
;; IDLitVisIntVol::_GenerateIntervalVolume
;;
;; Purpose:
;;   Generate the interval volume vertex and connectivity data.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;    None.

pro IDLitVisIntVol::_GenerateIntervalVolume

    compile_opt idl2, hidden

    if not self._isovaluesValid then return

    ;; Get volume data to make interval volume with
    oVol = self->GetParameter('VOLUME')
    if not OBJ_VALID(oVol) then return
    success = oVol->GetData(pVol, /POINTER)
    if success eq 0 then return

    ;; This may take awhile...
    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return

    if self._isovalues[0] ne self._isovalues[1] then begin
        INTERVAL_VOLUME, *pVol, self._isovalues[0], self._isovalues[1], $
            verts, tets, AUXDATA_IN=BYTSCL(*pVol), AUXDATA_OUT=vertexColors, $
            PROGRESS_OBJECT=self, PROGRESS_METHOD="_ProgressCallback", $
            PROGRESS_USERDATA=oTool
        ; Cancelled.
        if (N_ELEMENTS(verts) le 3) then $
            return
        void = oTool->DoUIService("HourGlassCursor", self)
        conn = TETRA_SURFACE(verts, tets)
        if self._decimate ne 100 then begin
            r = MESH_DECIMATE(verts, conn, conn, PERCENT_POLYGONS=self._decimate, $
                PROGRESS_OBJECT=self, $
                PROGRESS_METHOD='_DecimateCallback', $
                PROGRESS_USERDATA=oTool)
            void = oTool->DoUIService("HourGlassCursor", self)
        endif
    endif

    ;; Get the parms so we can update the vertex and connectivity data
    ;; Create the parms if they are not there
    oVerts = self->GetParameter('VERTICES')
    if not OBJ_VALID(oVerts) then begin
        oVerts = OBJ_NEW('IDLitData', TYPE='IDLVERTEX', $
            ICON='segpoly', NAME='Interval Volume Vertices')
        void = self->SetData(oVerts, PARAMETER_NAME='VERTICES', /NO_UPDATE, /BY_VALUE)
    endif
    oConn = self->GetParameter('CONNECTIVITY')
    if not OBJ_VALID(oConn) then begin
        oConn = OBJ_NEW('IDLitData', TYPE='IDLCONNECTIVITY', $
            ICON='segpoly', NAME='Interval Volume Polygon Connectivity')
        void = self->SetData(oConn, PARAMETER_NAME='CONNECTIVITY', /NO_UPDATE, /BY_VALUE)
    endif

    ;; Empty out polygon in case there is no interval volume
    ;; (Need to do it in this order!)
    success = oConn->SetData([-1])
    success = oVerts->SetData(FLTARR(3,3))

    ;; Make sure that we have enough verts to keep the polygon happy
    if N_ELEMENTS(verts) lt 9 then begin
        verts = FLTARR(3,3)
    endif

    ;; Prepare vertex data
    ;; - scale by dimensions
    oDimensions = self->GetParameter('VOLUME_DIMENSIONS')
    if OBJ_VALID(oDimensions) then begin
        success = oDimensions->GetData(dimensions)
        dimensions = FLOAT(dimensions)
        volDims = SIZE(*pVol, /DIMENSIONS)
        verts[0,*] *= dimensions[0] / volDims[0]
        verts[1,*] *= dimensions[1] / volDims[1]
        verts[2,*] *= dimensions[2] / volDims[2]
    endif

    ;; - translate by volume location
    oLocation = self->GetParameter('VOLUME_LOCATION')
    if OBJ_VALID(oLocation) then begin
        success = oLocation->GetData(location)
        verts[0,*] += location[0]
        verts[1,*] += location[1]
        verts[2,*] += location[2]
    endif

    ;; Update Output Parameters
    oTets = self->GetParameter('TETRAHEDRA')
    if not OBJ_VALID(oTets) then begin
        oTets = OBJ_NEW('IDLitDataIDLVector', $
            NAME="Interval Volume Tetrahedra List")
        void = self->SetData(oTets, $
            PARAMETER_NAME='TETRAHEDRA', /NO_UPDATE, /BY_VALUE)
    endif
    oVertexColors = self->GetParameter('VERTEX_COLORS')
    if not OBJ_VALID(oVertexColors) then begin
        oVertexColors = OBJ_NEW('IDLitDataIDLVector', $
            NAME="Interval Volume Vertex Color Indices")
        void = self->SetData(oVertexColors, $
            PARAMETER_NAME='VERTEX_COLORS', /NO_UPDATE, /BY_VALUE)
    endif
    success = oVerts->SetData(verts)
    success = oConn->SetData(conn)
    success = oTets->SetData(tets)
    success = oVertexColors->SetData(vertexColors)

    ;; Move the Interval Volume before the Volume Visualization.
    ;; This improves the mixed display of Volumes (with ZBUFFER on) and
    ;; solid geometry.
    oDataSpace = self->GetDataSpace()
    if OBJ_VALID(oDataSpace) then begin
        oAllList = oDataSpace->Get(/ALL)
        volPosition = WHERE(OBJ_ISA(oAllList, 'IDLITVISVOLUME'))
        isoPosition = WHERE(oAllList eq self)
        if volPosition[0] lt isoPosition[0] then $
            oDataSpace->Move, isoPosition[0], volPosition[0]
    endif

    ;; Turn off OPTARGET on the vertices because we don't have
    ;; any operations that work on vertex lists.
    self->SetParameterAttribute, 'VERTICES', OPTARGET=0

end


;----------------------------------------------------------------------------
function IDLitVisIntVol::EditUserDefProperty, oTool, identifier

    compile_opt idl2, hidden

    case identifier of

    'ISOVALUES': begin
        success = oTool->DoUIService('IntervalVolume', self)
        if success then begin
            if self._isovalues[0] eq self._isovalues[1] then begin
                self->ErrorMessage, $
                  IDLitLangCatQuery('Error:IsoSurface:IsoValueEqual'), severity=2
                return, 0
            endif
            return, 1
        endif
        return, 0
    end
    else:
    endcase

    ; Call our superclass.
    return, self->IDLitVisualization::EditUserDefProperty(oTool, identifier)

end

;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisIntVol::GetProperty
;
; PURPOSE:
;      This procedure method retrieves the
;      value of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisIntVol::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisIntVol::Init followed by the word "Get"
;      can be retrieved using IDLitVisIntVol::GetProperty.  In addition
;      the following keywords are available:
;
;      ALL: Set this keyword to a named variable that will contain
;              an anonymous structure containing the values of all the
;              retrievable properties associated with this object.
;              NOTE: UVALUE is not returned in this struct.
;-
pro IDLitVisIntVol::GetProperty, $
                                   _ISOVALUE0=isovalue0, $
                                   _ISOVALUE1=isovalue1, $
                                   USE_ISOVALUES=useIsovalues, $
                                   FILL_COLOR=fillColor, $
                                   SOURCE_COLOR=sourceColor, $
                                   DATA_OBJECTS=oData, $
                                   PALETTE_OBJECTS=oPalette, $
                                   DECIMATE=decimate, $
                                  _DATA=_data, $
                                  _REF_EXTRA=_extra

  compile_opt idl2, hidden

    ;; Handle our properties.

    if (ARG_PRESENT(isovalue0)) then $
        isovalue0 = self._isovalues[0]

    if (ARG_PRESENT(isovalue1)) then $
        isovalue1 = self._isovalues[1]

    if (ARG_PRESENT(useIsovalues)) then $
        useIsovalues = 1

    if (ARG_PRESENT(fillColor)) then $
        fillColor = self._fillColor

    if (ARG_PRESENT(sourceColor)) then $
        sourceColor = self._sourceColor

    if (ARG_PRESENT(oData)) then $
        oData = self->GetParameter('VOLUME')

    if (ARG_PRESENT(oPalette)) then $
        oPalette = self->GetParameter('RGB_TABLE')

    if (ARG_PRESENT(decimate)) then $
        decimate = self._decimate

    ;; This keeps undo/redo from saving/restoring the vertex data.
    if (ARG_PRESENT(_data)) then $
        _data = 0

    ;; get superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisPolygon::GetProperty, _EXTRA=_extra

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisIntVol::SetProperty
;
; PURPOSE:
;      This procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisIntVol::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisIntVol::Init followed by the word "Set"
;      can be set using IDLitVisIntVol::SetProperty.
;-
pro IDLitVisIntVol::SetProperty, $
                                   _ISOVALUE0=isovalue0, $
                                   _ISOVALUE1=isovalue1, $
                                   DECIMATE=decimate, $
                                   FILL_COLOR=fillColor, $
                                   SOURCE_COLOR=sourceColor, $
                                  _REF_EXTRA=_extra

    compile_opt idl2, hidden

    refresh = 0b
    oTool = self->GetTool()
    if (obj_isa(oTool, "IDLitSystem")) then $
       oTool = oTool->_GetCurrentTool()

    ;; Handle our properties.

    ;; Do before isovalues
    if (N_ELEMENTS(decimate) eq 1) then begin
        self._decimate = 1 > decimate < 100
    endif


    ;; It is unfortunate that we have to have two separate
    ;; properties for the isovalues (because of macro recording).
    ;; The rest of the system ensures that these two properties
    ;; will always be set together, but possibly in different calls
    ;; to SetProperty and in either order.
    ;; So, to prevent the generation of an intermediate intvol
    ;; between the setting of the two properties, we wait until
    ;; they are both set.
    if (N_ELEMENTS(isovalue0) gt 0) then begin
        self._isovalues[0] = isovalue0
        self._isovaluesValid = 0
        self._isoVal0Set = 1
    endif

    if (N_ELEMENTS(isovalue1) gt 0) then begin
        self._isovalues[1] = isovalue1
        self._isovaluesValid = 0
        self._isoVal1Set = 1
    endif

    if (self._isoVal0Set and self._isoVal1Set) then begin
        self._isovaluesValid = self._isovalues[0] NE self._isovalues[1]
        self._isoVal0Set = 0
        self._isoVal1Set = 0
        if OBJ_VALID(oTool) then $
            oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled
        self->_GenerateIntervalVolume
        self->_SetColor
        if (OBJ_VALID(oTool) && ~previouslyDisabled) then $
            oTool->EnableUpdates
    endif

    if (N_ELEMENTS(fillColor) gt 0) then begin
        self._fillColor = fillColor
        self->IDLitVisPolygon::SetProperty, FILL_COLOR=self._fillColor
        refresh = 1
    endif

    if (N_ELEMENTS(sourceColor) gt 0) then begin
        self._sourceColor = sourceColor
        self->_SetColor
        self->SetPropertyAttribute, 'FILL_COLOR', SENSITIVE=sourceColor
        refresh = 1
    endif

    ;; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisPolygon::SetProperty, _EXTRA=_extra

    if refresh && OBJ_VALID(oTool) then $
        oTool->RefreshCurrentWindow
end

;----------------------------------------------------------------------------
;; IDLitVisIntVol::OnDataDisconnect
;;
;; Purpose:
;;   This is called by the framework when a data item has disconnected
;;   from a parameter on the surface.
;;
;; Parameters:
;;   ParmName   - The name of the parameter that was disconnected.
;;
pro IDLitVisIntVol::OnDataDisconnect, ParmName

    compile_opt hidden, idl2

    switch STRUPCASE(parmname) of
    'VOLUME': begin
        self->SetPropertyAttribute, 'ISOVALUES', SENSITIVE=0
        self->DoOnNotify, self->GetFullIdentifier(), 'SETPROPERTY', ''
    end
    endswitch
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisIntVol::OnDataChangeUpdate
;
; PURPOSE:
;    This procedure method is called by a Subject via a Notifier when
;    its data has changed.  This method obtains the data from the subject
;    and updates the object.
;
; CALLING SEQUENCE:
;
;    Obj->[IDLitVisIntVol::]OnDataChangeUpdate, oSubject
;
; INPUTS:
;    oSubject: The Subject object in the Subject-Observer relationship.
;    This object (the surface) is the observer, so it uses the
;    IIDLDataSource interface to get the data from the subject.
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

; EXAMPLE:
;
;-
pro IDLitVisIntVol::OnDataChangeUpdate, oSubject, parmName

    compile_opt idl2, hidden

    switch STRUPCASE(parmName) OF
    '<PARAMETER SET>': begin
        ;; Skip RGB_TABLE because that work is handled by VOLUME
        parmNames = ['VOLUME', $
                     'VERTICES', 'CONNECTIVITY', 'TETRAHEDRA', 'VERTEX_COLORS']
        for i=0, N_ELEMENTS(parmNames)-1 do begin
            oData = oSubject->GetByName(parmNames[i], count=nCount)
            if ncount ne 0 then begin
                ;; vector to code below
                self->OnDataChangeUpdate,oData,parmNames[i]
            endif
        endfor
        break
    end

    'VOLUME':
    'VOLUME_DIMENSIONS':
    'VOLUME_LOCATION': begin
        self->_GenerateIntervalVolume
        ;; Fall through
    end

    'RGB_TABLE': begin
        self->_SetColor
        break
    end

    'TETRAHEDRA': break

    'VERTEX_COLORS': begin
        self->_SetColor
    end
    else: $
        self->IDLitVisPolygon::OnDataChangeUpdate, oSubject, parmName
    endswitch

    ;; Unhide so it shows on property sheet.
    self->SetPropertyAttribute, 'Isovalues', HIDE=0

end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisIntVol__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisIntVol object.
;
;-
pro IDLitVisIntVol__Define

    compile_opt idl2, hidden

    struct = { IDLitVisIntVol,           $
               inherits IDLitVisPolygon,     $
               _oData: OBJ_NEW(),            $
               _isovalues: DBLARR(2),        $
               _isovaluesValid: 0b,          $
               _isoVal0Set: 0b,              $
               _isoVal1Set: 0b,              $
               _fillColor: BYTARR(3),        $
               _sourceColor: 0,              $
               _decimate: 0b                 $
             }
end
