; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/components/idlitopinsertmapshape__define.pro#1 $
;
; Copyright (c) 2004-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitopInsertMapShape
;
; PURPOSE:
;   This operation creates a map grid visualization.
;
; CATEGORY:
;   IDL Tools
;
; SUPERCLASSES:
;
; SUBCLASSES:
;
; CREATION:
;   See IDLitopInsertMapShape::Init
;
;-

;-------------------------------------------------------------------------
function IDLitopInsertMapShape::Init, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (~self->IDLitOperation::Init(TYPES=[""], $
        _EXTRA=_extra)) then $
        return, 0

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitopInsertMapShape::SetProperty, _EXTRA=_extra

    return, 1

end


;---------------------------------------------------------------------------
pro IDLitopInsertMapShape::GetProperty, $
    COMBINE_ALL=combineAll, $
    SHAPEFILE=shapefile, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (ARG_PRESENT(combineAll)) then $
        combineAll = self._combineAll

    if (ARG_PRESENT(shapefile)) then $
        shapefile = self._shapefile

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::GetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
pro IDLitopInsertMapShape::SetProperty, $
    COMBINE_ALL=combineAll, $
    SHAPEFILE=shapefile, $
    _REF_EXTRA=_extra

    compile_opt idl2, hidden

    if (N_ELEMENTS(combineAll) eq 1) then $
        self._combineAll = combineAll

    if (N_ELEMENTS(shapefile) eq 1) then $
        self._shapefile = shapefile

    if (N_ELEMENTS(_extra) gt 0) then $
        self->IDLitOperation::SetProperty, _EXTRA=_extra
end


;---------------------------------------------------------------------------
function IDLitopInsertMapShape::DoAction, oTool

    compile_opt idl2, hidden

    oReadFile = oTool->GetService("READ_FILE")
    if (~OBJ_VALID(oReadFile)) then $
        return, OBJ_NEW()

    if (~self._shapefile) then begin
        ; By default, key off our identifier to get the shapefile name.
        ; This avoids having to create a separate subclass for the
        ; most common cases in the iMap tool.
        self->IDLitComponent::GetProperty, IDENTIFIER=id

        case (id) of
        'CONTINENTS': begin
            self._combineAll = 1b
            shapefile = 'continents'
            end
        'COUNTRIESLOW': shapefile = 'country'
        'COUNTRIESHIGH': shapefile = 'cntry02'
        'RIVERS': shapefile = 'rivers'
        'LAKES': shapefile = 'lakes'
        'CITIES': shapefile = 'cities'
        'STATES': shapefile = 'states'
        'PROVINCES': shapefile = 'canadaprovince'
        else: shapefile = ''
        endcase

        if (shapefile ne '') then begin
            shapefile += '.shp'
            self._shapefile = FILEPATH(shapefile, $
                SUBDIR=['resource', 'maps', 'shape'])
        endif
    endif

    filename = self._shapefile

    if (~FILE_TEST(filename, /READ)) then begin
        self->ErrorMessage, $
            [IDLitLangCatQuery('Error:Framework:CannotOpenFile') + filename], $
            TITLE=IDLitLangCatQuery('Error:MapCont:Title'), severity=2
        return, OBJ_NEW()
    endif

    idReader = oReadFile->FindMatchingReader(filename, _ERRORMSG=errorMsg)
    if (idReader eq '') then begin
        self->ErrorMessage, errorMsg, $
            TITLE=IDLitLangCatQuery('Error:MapCont:Title'), severity=2
        return, OBJ_NEW()
    endif

    oReaderDesc = oTool->GetByIdentifier(idReader)
    if (~OBJ_VALID(oReaderDesc)) then $
        return, OBJ_NEW()
    oReader = oReaderDesc->GetObjectInstance()

    ; Cache the old filename and properties.
    oldFilename = oReader->GetFilename()
    oReader->GetProperty, COMBINE_ALL=combineAll

    ; Set our new filename.
    oReader->SetFilename, filename
    oReader->SetProperty, COMBINE_ALL=self._combineAll

    success = oReader->GetData(oData)

    ; Set our previous values.
    oReader->SetFilename, oldFilename
    oReader->SetProperty, COMBINE_ALL=combineAll
    oReaderDesc->ReturnObjectInstance, oReader

    if (~success) then $
        return, OBJ_NEW()


    self->IDLitComponent::GetProperty, NAME=myname

    ; If we have only 1 data object, change its name to match ours.
    if (self._combineAll) then $
        oData[0]->SetProperty, NAME=myname, DESCRIPTION=filename

    oData[0]->GetProperty, TYPE=type

    case (type) of
    'IDLSHAPEPOLYGON': visualization = 'Shape Polygon'
    'IDLSHAPEPOLYLINE': visualization = 'Shape Polyline'
    'IDLSHAPEPOINT': visualization = 'Shape Point'
    else: visualization = ''
    endcase


    oCreate = oTool->GetService("CREATE_VISUALIZATION")
    if (~OBJ_VALID(oCreate)) then $
        return, OBJ_NEW()


    oTool->DisableUpdates, PREVIOUSLY_DISABLED=previouslyDisabled

    oTool->AddByIdentifier, "/Data Manager", oData


    if (visualization ne '') then begin

        ; Call _Create so we don't have to worry about type matching.
        oVisDesc = oTool->GetVisualization(visualization)
        ndata = N_ELEMENTS(oData)
        if (ndata gt 1) then $
            oVisDesc = REPLICATE(oVisDesc, ndata)

        oVisCmd = oCreate->_Create(oVisDesc, oData, $
            FOLDER_NAME=myname)

    endif else begin

        ; Let the service figure out what type of vis to create.
        oVisCmd = oCreate->CreateVisualization(oData, $
            FOLDER_NAME=myname)

    endelse

    if (~OBJ_VALID(oVisCmd[0])) then $
        goto, skipover

    ; Make a prettier undo/redo name.
    oVisCmd[0]->SetProperty, NAME='Insert Map ' + myname


skipover:

    if (~previouslyDisabled) then $
        oTool->EnableUpdates

    return, oVisCmd

end


;-------------------------------------------------------------------------
pro IDLitopInsertMapShape__define

    compile_opt idl2, hidden
    struc = {IDLitopInsertMapShape, $
        inherits IDLitOperation, $
        _combineAll: 0b, $
        _shapefile: ''}

end

