; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/components/idlitvisisosurface__define.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;    Unauthorized reproduction prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisIsosurface
;
; PURPOSE:
;    The IDLitVisIsosurface class implements a a polygon visualization
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
;; IDLitVisIsosurface::Init
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
function IDLitVisIsosurface::Init, $
                        NAME=name, $
                        DESCRIPTION=description, $
                        _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if(not KEYWORD_SET(name))then name ="Isosurface"
    if(not KEYWORD_SET(description))then description ="An Isosurface"

    ;; Initialize superclass
    if (not self->IDLitVisPolygon::Init(NAME=name, $
                                        TYPE='IDLISOSURFACE', $
                                        ICON='volume', $
                                        DESCRIPTION=description, $
                                        LINESTYLE=6, $
                                        SHADING=1, $
                                        /IMPACTS_RANGE, $
                                        _EXTRA=_extra))then $
        return, 0

    ;; Register Parameters

    self->RegisterParameter, 'VOLUME', DESCRIPTION='Volume', $
        /INPUT, TYPES='IDLARRAY3D'
    self->RegisterParameter, 'RGB_TABLE', DESCRIPTION='RGB Table', $
        /INPUT, /OPTIONAL, TYPES=['IDLPALETTE','IDLARRAY2D']
    self->RegisterParameter, 'VOLUME_DIMENSIONS', DESCRIPTION='Volume Dimensions', $
        /INPUT, /OPTIONAL, TYPES='IDLVECTOR'
    self->RegisterParameter, 'VOLUME_LOCATION', DESCRIPTION='Volume Location', $
        /INPUT, /OPTIONAL, TYPES='IDLVECTOR'

    ;; The VERTICES and CONNECTIVITY parameters are "OUTPUT" parameters in the sense
    ;; that this object generates the data for these parameters.
    self->SetParameterAttribute, ['VERTICES', 'CONNECTIVITY'], $
        INPUT=0, OUTPUT=1, OPTARGET=0

    ;; Register Properties
    self->RegisterProperty, 'Isovalue', USERDEF='Select isovalue', $
        DESCRIPTION='Isosurface value.'

    self->RegisterProperty, '_ISOVALUE0', /FLOAT, $
        NAME='Isovalue0', $
        DESCRIPTION='Isovalue0', /HIDE

    self->RegisterProperty, '_ISOVALUE1', /FLOAT, $
        NAME='Isovalue1', $
        DESCRIPTION='Isovalue1', /HIDE

    self->RegisterProperty, 'SOURCE_COLOR', $
        ENUMLIST=['Isovalue selected (Volume color table)', $
                  'User selected (Fill Color Property)'], $
        DESCRIPTION='Method of selecting color for isosurface', $
        NAME='Source color'

    self->SetPropertyAttribute, 'SHADING', HIDE=0

    ;; Hide to avoid showing on style sheet.
    self->SetPropertyAttribute, 'Isovalue', HIDE=1

    ;; Init state
    self._sourceColor = 0
    self._fillColor = [255b,0b,0b]
    self->IDLitVisPolygon::SetProperty, FILL_COLOR=self._fillColor
    self._decimate = 100

    self->Set3D, /ALWAYS
    self->SetDefaultSelectionVisual, OBJ_NEW('IDLitManipVisSelectBox', /HIDE)

    return, 1 ; Success
end


;;----------------------------------------------------------------------------
;; IDLitVisIsosurface::Cleanup
;;
;; Purpose:
;;   Cleanup/destrucutor method for this object.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;    None.
pro IDLitVisIsosurface::Cleanup

    compile_opt idl2, hidden

    obj_destroy,self->GetParameter('VERTICES')
    obj_destroy,self->GetParameter('CONNECTIVITY')

    ; Cleanup superclass
    self->IDLitvispolygon::Cleanup
end

;;----------------------------------------------------------------------------
;; IDLitVisIsosurface::Restore
;;
;; Purpose:
;;   This procedure method performs any cleanup work required after
;;   an object of this class has been restored from a save file to
;;   ensure that its state is appropriate for the current revision.
;;
pro IDLitVisIsosurface::Restore

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

        ; If isovalue was marked as valid, double check that volume data
        ; is available.  If not, then the isovalue is not valid.
        if (self._isovalueValid) then begin
            if (self._volMin eq self._volMax) then $
                self._isovalueValid = 0
        endif
    endif
end

;;----------------------------------------------------------------------------
;; IDLitVisIsosurface::_SetColor
;;
;; Purpose:
;;   Set the isosurface color.
;;   If the source of the color comes from the isosurface, convert the
;;   isovalue into a color index into the volume color table.
;;   Otherwise, use the last set FILL_COLOR value.
;;   In either case, set the color into the superclass.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;    None.

pro IDLitVisIsosurface::_SetColor

    compile_opt idl2, hidden

    case self._sourceColor of
    0: begin
        ;; Compute color index if we have vol data
        if (self._volMax - self._volMin) ne 0 then begin
            ;; Convert the iso value to a color table index
            index = (self._isovalue - self._volMin) / (self._volMax - self._volMin)
            index = (ROUND(index * 255) > 0) < 255
            ;; Lookup color in color table
            oPal = self->GetParameter('RGB_TABLE')
            success = 0
            if OBJ_VALID(oPal) then $
                success = oPal->GetData(colortable)
            if success then begin
                color = REFORM(BYTE(colortable[*, index]))
            endif else begin
                color = [index, index, index]
            endelse
        endif
        ;; Fallback
        if N_ELEMENTS(color) eq 0 then $
            color = [128b,128b,128b]
        self->IDLitVisPolygon::SetProperty, FILL_COLOR=color
    end
    1: begin
        self->IDLitVisPolygon::SetProperty, FILL_COLOR=self._fillColor
    end
    endcase

end

;;----------------------------------------------------------------------------
;; IDLitVisIsosurface::_ProgressCallback
;;
;; Purpose:
;;   Callback for Isosurface progress bar
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;    None.
function IDLitVisIsosurface::_ProgressCallback, percent, USERDATA=oTool

    compile_opt idl2, hidden

    status = oTool->ProgressBar('Computing Isosurface...', PERCENT=percent, $
        SHUTDOWN=percent ge 100)
    return, status  ; 0 means cancel
end

;;----------------------------------------------------------------------------
;; IDLitVisIsosurface::_DecimateCallback
;;
;; Purpose:
;;   Callback for decimation progress bar
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;    None.
function IDLitVisIsosurface::_DecimateCallback, percent, USERDATA=oTool

    compile_opt idl2, hidden

    status = oTool->ProgressBar('Decimating Isosurface...', PERCENT=percent, $
        SHUTDOWN=percent ge 100)
    return, status  ; 0 means cancel
end

;;----------------------------------------------------------------------------
;; IDLitVisIsosurface::_GenerateIsosurface
;;
;; Purpose:
;;   Generate the isosurface vertex and connectivity data.
;;
;; Parameters:
;;   None.
;;
;; Keywords:
;;    None.

pro IDLitVisIsosurface::_GenerateIsosurface

    compile_opt idl2, hidden

    if not self._isovalueValid then return

    ;; Get volume data to make isosurface with
    oVol = self->GetParameter('VOLUME')
    if not OBJ_VALID(oVol) then return
    success = oVol->GetData(pVol, /POINTER)
    if success eq 0 then return

    ;; This may take awhile...
    oTool = self->GetTool()
    if (~OBJ_VALID(oTool)) then $
        return

    ISOSURFACE, *pVol, self._isovalue, verts, conn, $
        PROGRESS_OBJECT=self, $
        PROGRESS_METHOD='_ProgressCallback', $
        PROGRESS_USERDATA=oTool

    ; Cancelled.
    if (N_ELEMENTS(verts) le 3) then $
        return

    if self._decimate ne 100 then begin
        r = MESH_DECIMATE(verts, conn, conn, $
            PERCENT_POLYGONS=self._decimate, $
            PROGRESS_OBJECT=self, $
            PROGRESS_METHOD='_DecimateCallback', $
            PROGRESS_USERDATA=oTool)
    endif
    void = oTool->DoUIService("HourGlassCursor", self)

    ;; Get the parms so we can update the vertex and connectivity data
    ;; Create the parms if they are not there yet.
    oVerts = self->GetParameter('VERTICES')
    if not OBJ_VALID(oVerts) then begin
        oVerts = OBJ_NEW('IDLitData', TYPE='IDLVERTEX', $
            ICON='segpoly', NAME="Isosurface Vertices")
        void = self->SetData(oVerts, $
            PARAMETER_NAME='VERTICES', /NO_UPDATE, /BY_VALUE)
    endif
    oConn = self->GetParameter('CONNECTIVITY')
    if not OBJ_VALID(oConn) then begin
        oConn = OBJ_NEW('IDLitData', TYPE='IDLCONNECTIVITY', $
            ICON='segpoly', NAME="Isosurface Polygon Connectivity")
        void = self->SetData(oConn, $
            PARAMETER_NAME='CONNECTIVITY', /NO_UPDATE, /BY_VALUE)
    endif

    ;; Empty out polygon in case there is no isosurface
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

    ;; Update Parameters
    success = oVerts->SetData(verts)
    success = oConn->SetData(conn)

    ;; Move the Isosurface before the Volume Visualization.
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
    ;; any operations work on vertex lists.
    self->SetParameterAttribute, 'VERTICES', OPTARGET=0
end


;----------------------------------------------------------------------------
function IDLitVisIsosurface::EditUserDefProperty, oTool, identifier

    compile_opt idl2, hidden

    case identifier of

    'ISOVALUE': begin
        success = oTool->DoUIService('ISOSURFACE', self)
        if success then return, 1
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
;      IDLitVisIsosurface::GetProperty
;
; PURPOSE:
;      This procedure method retrieves the
;      value of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisIsosurface::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisIsosurface::Init followed by the word "Get"
;      can be retrieved using IDLitVisIsosurface::GetProperty.  In addition
;      the following keywords are available:
;
;      ALL: Set this keyword to a named variable that will contain
;              an anonymous structure containing the values of all the
;              retrievable properties associated with this object.
;              NOTE: UVALUE is not returned in this struct.
;-
pro IDLitVisIsosurface::GetProperty, $
                                   _ISOVALUE0=isovalue0, $
                                   _ISOVALUE1=isovalue1, $
                                   USE_ISOVALUES=useIsovalue, $
                                   SOURCE_COLOR=sourceColor, $
                                   FILL_COLOR=fillColor, $
                                   DATA_OBJECTS=oData, $
                                   PALETTE_OBJECTS=oPalette, $
                                   DECIMATE=decimate, $
                                  _DATA=_data, $
                                  _REF_EXTRA=_extra

  compile_opt idl2, hidden

    ;; Handle our properties.

    if (ARG_PRESENT(isovalue0)) then $
        isovalue0 = self._isovalue

    ; Return a defined but arbitrary value in case caller asks for it.
    if (ARG_PRESENT(isovalue1)) then $
        isovalue1 = 0

    if (ARG_PRESENT(useIsovalue)) then $
        useIsovalue = 1

    if (ARG_PRESENT(sourceColor)) then $
        sourceColor = self._sourceColor

    if (ARG_PRESENT(fillColor)) then $
        fillColor = self._fillColor

    if (ARG_PRESENT(oData)) then begin
        oData = self->GetParameter('VOLUME')
    endif

    if (ARG_PRESENT(oPalette)) then begin
        oPalette = self->GetParameter('RGB_TABLE')
    endif

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
;      IDLitVisIsosurface::SetProperty
;
; PURPOSE:
;      This procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisIsosurface::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisIsosurface::Init followed by the word "Set"
;      can be set using IDLitVisIsosurface::SetProperty.
;-
pro IDLitVisIsosurface::SetProperty, $
                                   _ISOVALUE0=isovalue0, $
                                   _ISOVALUE1=isovalue1, $
                                   SOURCE_COLOR=sourceColor, $
                                   FILL_COLOR=fillColor, $
                                   SELECTED_DATASET=selectedDataset, $
                                   DECIMATE=decimate, $
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

    if (N_ELEMENTS(isovalue0) gt 0) then begin
        self._isovalue = isovalue0[0]
        ;; Don't claim isovalue is valid until we have some volume data.
        if self._volMin ne self._volMax then $
            self._isovalueValid = 1
        if (OBJ_VALID(oTool)) then $
            oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled
        self->_GenerateIsoSurface
        self->_SetColor
        if (OBJ_VALID(oTool) && ~previouslyDisabled) then $
            oTool->EnableUpdates
    endif

    ;; Ignore isovalue 1

    if (N_ELEMENTS(sourceColor) gt 0) then begin
        self._sourceColor = sourceColor
        self->_SetColor
        self->SetPropertyAttribute, 'FILL_COLOR', SENSITIVE=sourceColor
        refresh = 1
    endif

    if (N_ELEMENTS(fillColor) gt 0) then begin
        self._fillColor = fillColor
        self->_SetColor
        refresh = 1
    endif

    ;; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisPolygon::SetProperty, _EXTRA=_extra

    if refresh && OBJ_VALID(oTool) then $
        oTool->RefreshCurrentWindow
end

;----------------------------------------------------------------------------
;; IDLitVisIsosurface::OnDataDisconnect
;;
;; Purpose:
;;   This is called by the framework when a data item has disconnected
;;   from a parameter on the surface.
;;
;; Parameters:
;;   ParmName   - The name of the parameter that was disconnected.
;;
pro IDLitVisIsosurface::OnDataDisconnect, ParmName

    compile_opt hidden, idl2

    switch STRUPCASE(parmname) of
    'VOLUME': begin
        self->SetPropertyAttribute, 'ISOVALUE', SENSITIVE=0
        self->DoOnNotify, self->GetFullIdentifier(), 'SETPROPERTY', ''
    end
    endswitch
end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisIsosurface::OnDataChangeUpdate
;
; PURPOSE:
;    This procedure method is called by a Subject via a Notifier when
;    its data has changed.  This method obtains the data from the subject
;    and updates the object.
;
; CALLING SEQUENCE:
;
;    Obj->[IDLitVisIsosurface::]OnDataChangeUpdate, oSubject
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
pro IDLitVisIsosurface::OnDataChangeUpdate, oSubject, parmName

    compile_opt idl2, hidden

    case STRUPCASE(parmName) OF
    '<PARAMETER SET>': begin
        ;; Skip RGB_TABLE because that work is handled by VOLUME
        parmNames = ['VOLUME', $
                     'VERTICES', 'CONNECTIVITY']
        for i=0, N_ELEMENTS(parmNames)-1 do begin
            oData = oSubject->GetByName(parmNames[i], count=nCount)
            if ncount ne 0 then begin
                ;; vector to code below
                self->OnDataChangeUpdate, oData, parmNames[i]
            endif
        endfor
    end

    'VOLUME': begin
        self->_GenerateIsoSurface
        success = oSubject->GetData(pVol, /POINTER)
        if success then begin
            volMin = MIN(*pVol, MAX=volMax)
            self._volMin = volMin
            self._volMax = volMax
        endif
        self->_SetColor
    end

    'RGB_TABLE': begin
        self->_SetColor
    end

    else: $
        self->IDLitVisPolygon::OnDataChangeUpdate, oSubject, parmName
    endcase

    ;; Unhide so it shows on property sheet.
    self->SetPropertyAttribute, 'Isovalue', HIDE=0
end

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisIsosurface__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisIsosurface object.
;
;-
pro IDLitVisIsosurface__Define

    compile_opt idl2, hidden

    struct = { IDLitVisIsosurface,           $
               inherits IDLitVisPolygon,     $
               _oData: OBJ_NEW(),            $
               _isovalue: 0.0d,              $
               _isovalueValid: 0b,           $
               _volMin: 0.0d,                $
               _volMax: 0.0d,                $
               _sourceColor: 0,              $
               _fillColor: BYTARR(3),        $
               _decimate: 0b                 $
             }
end
