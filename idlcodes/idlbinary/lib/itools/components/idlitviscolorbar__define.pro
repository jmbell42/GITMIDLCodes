; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/components/idlitviscolorbar__define.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;    Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
; Purpose:
;    The IDLitVisColorbar class is the component wrapper for the colorbar.
;
; MODIFICATION HISTORY:
;     Written by:   CT, July 2002.
;


;----------------------------------------------------------------------------
pro IDLitVisColorbar::_RegisterProperties, $
    UPDATE_FROM_VERSION=updateFromVersion

    compile_opt idl2, hidden

    registerAll = ~KEYWORD_SET(updateFromVersion)

    if (registerAll) then begin

        ; Add general properties
        self->RegisterProperty, 'BORDER_ON', /BOOLEAN, $
            DESCRIPTION='Turn on border', $
            NAME='Border'

        self->RegisterProperty, 'Orientation', $
            ENUMLIST=['Horizontal', 'Vertical'], $
            DESCRIPTION='Orientation'

        self->RegisterProperty, 'Location',$
            USERDEF="Location", $
            DESCRIPTION="Location", /HIDE

    endif

    if (registerAll || (updateFromVersion lt 620)) then begin
        ; Previous releases did not hide the DATA_POSITION
        ; (a.k.a., 'Lock to Data Position')property.
        ; Reset back to appropriate value, and hide.
        self._oAxis->SetProperty, DATA_POSITION=0
        self._oAxis->SetPropertyAttribute, 'DATA_POSITION', /HIDE
    endif
end


;----------------------------------------------------------------------------
; Purpose:
;    Initialize this component
;
; Arguments:
;   None.
;
; Keywords:
;   All keywords that can be used for IDLitVisualization
;
; Result:
;    This function method returns 1 on success, or 0 on failure.
;
function IDLitVisColorbar::Init, TOOL=tool, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    success = self->IDLitVisualization::Init( TYPE="IDLCOLORBAR", $
        /MANIPULATOR_TARGET, $
        NAME="Colorbar", $
        ICON='colorbar', $
        IMPACTS_RANGE=0, $   ; should not affect DataSpace range
        DESCRIPTION="A Colorbar Visualization", $
        TOOL=tool, $
        _EXTRA=_extra)

    if (~success) then $
        return, 0

    ; Create Parameter
    self->RegisterParameter, 'PALETTE', $
        DESCRIPTION='Image Data', $
        /INPUT, TYPES=['IDLPALETTE','IDLARRAY2D']

    self->RegisterParameter, 'OPACITY TABLE', $
        DESCRIPTION='Opacity Data', $
        /INPUT, TYPES=['IDLOPACITY_TABLE','IDLVECTOR']

    ; handle data of visContour, visVolume, etc.
    self->RegisterParameter, 'VISUALIZATION DATA', $
        DESCRIPTION='Visualization Data', $
        /INPUT, TYPES=['IDLVECTOR', 'IDLARRAY2D', 'IDLARRAY3D']

    self._oPalette = OBJ_NEW('IDLgrPalette', $
        RED=BINDGEN(256), $
        GREEN=BINDGEN(256), $
        BLUE=BINDGEN(256))

    ; Create Image object and add it to this Visualization.
    self._oImage = OBJ_NEW('IDLgrImage', $
        DATA=BINDGEN(256,2), $
        DIMENSIONS=[1,0.1], $
        PALETTE=self._oPalette)

    self->Add, self._oImage

    self._oAxis = OBJ_NEW('IDLitVisAxis', $
        LOCATION=[0, 0, 0.5], $
        TICKLEN=0.05d, $
        SUBTICKLEN=1.0, $
        /EXACT, $
        TOOL=tool, $
        MANIPULATOR_TARGET=0, $
        /private)

    self->Add, self._oAxis, /AGGREGATE

    self->_RegisterProperties

    ; Set any properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitVisColorbar::SetProperty, _EXTRA=_extra

    RETURN, 1 ; Success
end


;----------------------------------------------------------------------------
; Purpose:
;    Cleanup this component
;
pro IDLitVisColorbar::Cleanup

    compile_opt idl2, hidden

    OBJ_DESTROY, self._oImage
    OBJ_DESTROY, self._oPalette

    ; Cleanup superclass
    self->IDLitVisualization::Cleanup
end

;----------------------------------------------------------------------------
; IDLitVisColorbar::Restore
;
; Purpose:
;   This procedure method performs any cleanup work required after
;   an object of this class has been restored from a save files to
;   ensure that its state is appropriate for the current revision.
;
pro IDLitVisColorbar::Restore
    compile_opt idl2, hidden

    ; Call superclass restore.
    self->_IDLitVisualization::Restore

    ; Call ::GetProperty on each aggregated graphic object
    ; to force its internal restore process to be called, thereby
    ; ensuring any new properties are registered.
    if (OBJ_VALID(self._oAxis)) then $
        self._oAxis->GetProperty

    ; Register new properties.
    self->IDLitVisColorbar::_RegisterProperties, $
        UPDATE_FROM_VERSION=self.idlitcomponentversion

    ; ---- Required for SAVE files transitioning ----------------------------
    ;      from IDL versions less than 6.2 to 6.2 or above:
    if (self.idlitcomponentversion lt 620) then begin
        ; The border now shares color and line thickness with the axis.
        if (OBJ_VALID(self._oBorder)) then begin
            self._oAxis->GetProperty, COLOR=color, THICK=thick
            self._oBorder->SetProperty, COLOR=color, THICK=thick
        endif
        ; We switched from a texture-mapped polygon to a raw grImage.
        ; Remove our old polygon and add the image directly.
        oOldPoly = self->Get(/ALL, ISA='IDLgrPolygon')
        if OBJ_VALID(oOldPoly) then begin
            self->Remove, oOldPoly
            OBJ_DESTROY, oOldPoly
        endif
        self->Add, self._oImage, POSITION=0
        ; The handling of the image changed, so update our orientation.
        self._oAxis->GetProperty, DIRECTION=currentorientation
        self->SetProperty, ORIENTATION=currentorientation
    endif
end

;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisColorbar::GetProperty
;
; PURPOSE:
;      This procedure method retrieves the
;      value of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisColorbar::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisColorbar::Init followed by the word "Get"
;      can be retrieved using IDLitVisColorbar::GetProperty.  In addition
;      the following keywords are available:
;
;      ALL: Set this keyword to a named variable that will contain
;              an anonymous structure containing the values of all the
;              retrievable properties associated with this object.
;              NOTE: UVALUE is not returned in this struct.
;-
pro IDLitVisColorbar::GetProperty, $
    BORDER_ON=border, $
    LOCATION=location, $
    ORIENTATION=orientation, $
    PARENT=parent, $
    TICKLEN=ticklen, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Handle our properties.
    if ARG_PRESENT(border) then begin
        if (OBJ_VALID(self._oBorder)) then begin
            self._oBorder->GetProperty, HIDE=hide
            border = 1-hide
        endif else border = 0    ; false
    endif

    if ARG_PRESENT(location) then $
        location = self._location

    ; Convert from grAxis tick length to our normalized tick length.
    if ARG_PRESENT(ticklen) then begin
        self._oAxis->GetProperty, TICKLEN=ticklen
        ticklen *= 20
    endif

    ; Get my properties
    self._oImage->GetProperty, _EXTRA=_extra

    ; The ORIENTATION property has the same value as the axis DIRECTION.
    ; All other axis properties are handled by aggregation.
    self._oAxis->GetProperty, DIRECTION=orientation

    ; get superclass properties
    if ((N_ELEMENTS(_extra) gt 0) || ARG_PRESENT(parent)) then $
        self->IDLitVisualization::GetProperty, PARENT=parent, _EXTRA=_extra

end

;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisColorbar::SetProperty
;
; PURPOSE:
;      This procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisColorbar::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisColorbar::Init followed by the word "Set"
;      can be set using IDLitVisColorbar::SetProperty.
;-

pro IDLitVisColorbar::SetProperty,  $
    BORDER_ON=border, $
    COLOR=color, $
    DIRECTION=swallow, $  ; interferes with orientation
    LOCATION=location, $
    ORIENTATION=orientation, $
    TEXTPOS=textpos, $
    THICK=thick, $
    TICKLEN=ticklen, $
    TRANSFORM=transform, $
    BYTESCALE_RANGE=range, $
    _EXTRA=_extra

    compile_opt idl2, hidden


    modifiedprops = ''

    ; Set my properties.
    if (N_ELEMENTS(border) eq 1) then begin
        if (~OBJ_VALID(self._oBorder)) then begin
            self._oAxis->GetProperty, COLOR=axisColor, THICK=axisThick, $
                DIRECTION=currentorientation
            data = [[0,0,0.5], [1,0,0.5], [1,0.1d,0.5], [0,0.1d,0.5]]
            if (currentorientation) then $
                data[[0,1],*] = data[[1,0],*]
            self._oBorder = OBJ_NEW('IDLgrPolyline', $
                DATA=data, POLYLINE=[5,0,1,2,3,0], $
                COLOR=axisColor, THICK=axisThick, /private)
            self->Add, self._oBorder
        endif
        self._oBorder->SetProperty, HIDE=1-KEYWORD_SET(border)
    endif

    if ((N_ELEMENTS(color) gt 0) || $
        (N_ELEMENTS(thick) gt 0)) then begin
        if (OBJ_VALID(self._oBorder)) then $
            self._oBorder->SetProperty, COLOR=color, THICK=thick
        self._oAxis->SetProperty, COLOR=color, THICK=thick
    endif

    if (N_ELEMENTS(location) eq 3) then begin
        self->Reset
        self->Translate, location[0], location[1], location[2], /PREMULTIPLY
        self._location = location
    endif

    ; Convert from our normalized tick length to grAxis tick length.
    if (N_ELEMENTS(ticklen) gt 0) then $
        self._oAxis->SetProperty, TICKLEN=ticklen/20d


    self._oPalette->SetProperty, _EXTRA=_extra
    self._oImage->SetProperty, _EXTRA=_extra

    ; Note: All axis properties are handled by aggregation.


    ; If the text position was flipped, then we also need to shift
    ; the axis.
    if (N_ELEMENTS(textpos) eq 1) then begin
        self._oAxis->SetProperty, $
            LOCATION=textpos ? [0.1d, 0.1d, 0.5] : [0, 0, 0.5]
    endif


    ; Flip the orientation.
    if (N_ELEMENTS(orientation) eq 1) then begin

        ; Flip columns if necessary.
        data = [[0,0,0.5], [1,0,0.5], [1,0.1d,0.5], [0,0.1d,0.5]]
        if (orientation) then $
            data[[0,1],*] = data[[1,0],*]
        if (OBJ_VALID(self._oBorder)) then $
            self._oBorder->SetProperty, DATA=data

        self._oAxis->SetProperty, $
            DIRECTION=orientation

        self._oImage->GetProperty, DATA=imagedata
        dims = SIZE(imagedata, /DIM)
        ; Flip data if necessary.
        if ((dims[0] gt dims[1] && orientation eq 1) || $
            (dims[0] lt dims[1] && orientation eq 0)) then begin
            imagedata = TRANSPOSE(imagedata)
        endif
        self._oImage->SetProperty, DATA=imagedata, $
            DIMENSIONS=orientation ? [0.1,1] : [1,0.1]

        IF array_equal(self._coord_conv,[0d,0]) THEN $
          self._coord_conv=[0d,1]
        CASE orientation OF
          0 : self._oAxis->SetProperty, $
            XCOORD_CONV=self._coord_conv,YCOORD_CONV=[0,1]
          1 : self._oAxis->SetProperty, $
            XCOORD_CONV=[0,1],YCOORD_CONV=self._coord_conv
        ENDCASE

        self->UpdateSelectionVisual

    endif

    IF (n_elements(range) EQ 2) THEN BEGIN
      self._oAxis->GetProperty, RANGE=axisRange, $
        DIRECTION=currentorientation
      byteRange = (range-axisRange[0])/(axisRange[1]-axisRange[0])*255
      data = currentorientation ? BINDGEN(2,256) : BINDGEN(256,2)
      self._oImage->SetProperty, $
        DATA=BYTSCL(data,MIN=byteRange[0],MAX=byteRange[1])
    ENDIF

    ; Set superclass properties
    self->IDLitVisualization::SetProperty, $
        TEXTPOS=textpos, $
        _EXTRA=_extra


    ; We must send this directly to the grModel without going thru the
    ; property aggregation system.
    if (N_ELEMENTS(transform) gt 0) then $
        self->IDLgrModel::SetProperty, TRANSFORM=transform

end


;----------------------------------------------------------------------------
; IIDLDataObserver Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; IDLitVisColorbar::OnDataDisconnect
;
; Purpose:
;   This is called by the framework when a data item has disconnected
;   from a parameter on the surface.
;
; Parameters:
;   ParmName   - The name of the parameter that was disconnected.
;
;
;-
PRO IDLitVisColorbar::OnDataDisconnect, ParmName
   compile_opt hidden, idl2

   ; Just check the name and perform the desired action
   switch ParmName of
       'PALETTE':
       'OPACITY TABLE':
       'VISUALIZATION DATA': self->SetProperty, HIDE=1
       else:
   endswitch
end


;----------------------------------------------------------------------------
; METHODNAME:
;    IDLitVisColorbar::OnDataChangeUpdate
;
; PURPOSE:
;    This procedure method is called by a Subject via a Notifier when
;    its data has changed.  This method obtains the data from the subject
;    and updates the IDLgrImage object.
;
; CALLING SEQUENCE:
;
;    Obj->[IDLitVisColorbar::]OnDataChangeUpdate, oSubject, ParmName
;
; INPUTS:
;    oSubject: The Subject object in the Subject-Observer relationship.
;    This object (the image) is the observer, so it uses the
;    IIDLDataSource interface to get the data from the subject.
;    Then, it puts the data in the IDLgrImage object.
;
pro IDLitVisColorbar::OnDataChangeUpdate, oSubject, parmName
  compile_opt idl2, hidden

  case STRUPCASE(parmName) OF
    '<PARAMETER SET>': begin
      parmNames = ['PALETTE', 'OPACITY TABLE', 'VISUALIZATION DATA']
      for i=0, N_ELEMENTS(parmNames)-1 do begin
        oData = oSubject->GetByName(parmNames[i], count=nCount)
        if ncount ne 0 then begin
                                ; vector to code below
          self->OnDataChangeUpdate,oData,parmNames[i]
        endif
      endfor
    END
    'PALETTE': begin
      success = oSubject->GetData(palette)
      if (N_ELEMENTS(palette) gt 0) then begin
        self._oPalette->SetProperty, $
          RED=palette[0,*], $
          GREEN=palette[1,*], $
          BLUE=palette[2,*]
        self._oImage->SetProperty, PALETTE=self._oPalette
        self->SetProperty, HIDE=0
      endif
    END
    'OPACITY TABLE': begin
      success = oSubject->GetData(palette)
      if (N_ELEMENTS(palette) gt 0) then begin
        self._oPalette->SetProperty, $
          RED=palette, $
          GREEN=palette, $
          BLUE=palette
        self._oImage->SetProperty, PALETTE=self._oPalette
        self->SetProperty, HIDE=0
      endif
    END
    'VISUALIZATION DATA': begin
      success = oSubject->GetData(visData)
      if (N_ELEMENTS(visData) gt 0) then begin
        ; For byte data, to match iImage behavior, set range to 0-255.
        if (SIZE(visData[0], /TYPE) eq 1) then begin
            dataMin = 0b
            dataMax = 255b
        endif else begin
            dataMin = MIN(visData, MAX=dataMax, /NAN)
        endelse
        ;; if the range is small, regardless of data type,
        ;; reduce the number of tick marks so that the labels
        ;; do not overlap
        IF (dataMax-dataMin) LE 0.01 THEN BEGIN
          self._oAxis->SetProperty, MAJOR=3
        ENDIF
        ;; reduce the number of ticks for small integral data
        ;; ranges
        if ((size(visData, /TYPE) le 3) && $
            ((dataMax - dataMin) le 10)) then BEGIN
          self._oAxis->SetProperty, MAJOR=2
        ENDIF

        ;; scale the value to the data range
        ;; incoming Value parameter is in the range [0,1]
        SWITCH size(visData, /TYPE) OF
          1:
          2:
          3: BEGIN
            format='(I)'
            BREAK
          END
          ELSE: BEGIN
            pwr = fix(alog10(dataMax-dataMin))
            CASE 1 OF
              pwr GT 4 : format='(E0.2)'
              pwr GT 0 : format='(I0)'
              pwr GT -3 : format='(F0.'+strtrim(abs(pwr)+2,2)+')'
              ELSE : format='(E0.2)'
            ENDCASE
          ENDELSE
        ENDSWITCH

        range = DOUBLE(dataMax-dataMin)
        self._coord_conv = [-dataMin/range,1.0/range]
        IF array_equal(self._coord_conv,[0d,0]) THEN self._coord_conv=[0d,1]

        self._oAxis->SetProperty, $
          TICK_DEFINEDFORMAT=0, $
          RANGE=[dataMin,dataMax], $
          TICKFORMAT=format
        self._oAxis->GetProperty,DIRECTION=orientation
        CASE orientation OF
          0 : self._oAxis->SetProperty, $
            XCOORD_CONV=self._coord_conv,YCOORD_CONV=[0,1]
          1 : self._oAxis->SetProperty, $
            XCOORD_CONV=[0,1],YCOORD_CONV=self._coord_conv
        ENDCASE
        self->SetProperty, HIDE=0
      ENDIF
    END

    else:                       ; ignore unknown parameters
  ENDCASE

END

;;-----------------------------------------------------------------------------
;; IDLitVisColorbar::OnNotify
;;
;; Purpose:
;;    Updates the colourbar if the data or bytescaling has changed
;;
;; Parameters:
;;   STRITEM - The id of the target vis
;;
;;   STRMSG - The notification message
;;
;;   STRUSER - Not used
;;
;; Keywords:
;;   NONE
;;
PRO IDLitVisColorbar::OnNotify, strItem, StrMsg, strUser
  compile_opt idl2, hidden

  CASE StrMsg OF

    "IMAGECHANGED" : BEGIN
      oTool = self->GetTool()
      IF obj_valid(oTool) THEN $
        oVis = oTool->GetByIdentifier(strItem)
      IF obj_valid(oVis) && obj_isa(oVis,'IDLitVisImage') THEN BEGIN
        oImagePixels = oVis->GetParameter('IMAGEPIXELS')
        IF obj_valid(oImagePixels) THEN $
          self->OnDataChangeUpdate,oImagePixels,'VISUALIZATION DATA'
        oVis->GetProperty,BYTESCALE_MIN=bMin,BYTESCALE_MAX=bMax
        self->SetProperty,BYTESCALE_RANGE=[bMin,bMax]
      ENDIF
    END

    ELSE :

  ENDCASE

END

;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisColorbar__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisColorbar object.
;
;-
pro IDLitVisColorbar__Define

    compile_opt idl2, hidden

    struct = { IDLitVisColorbar,           $
        inherits IDLitVisualization, $
        _oImage: OBJ_NEW(),          $
        _oPalette: OBJ_NEW(),        $
        _oAxis: OBJ_NEW(),           $
        _oBorder: OBJ_NEW(),         $
        _location: DBLARR(3),        $
        _coord_conv: DBLARR(2)       $
    }
end
