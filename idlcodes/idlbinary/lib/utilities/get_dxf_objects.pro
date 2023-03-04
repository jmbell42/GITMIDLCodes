; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/utilities/get_dxf_objects.pro#1 $
;
; Copyright (c) 2000-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;
;+
; NAME:
;   GET_DXF_OBJECTS
;
; PURPOSE:
;   This function returns an IDLgrModel contaning graphics from a
;   given dxf file.
;
; CATEGORY:
;   Data Access.
;
; CALLING SEQUENCE:
;   Result = GET_DXF_OBJECTS(Filename [, BlockTable [, LayerTable]])
;
; INPUTS:
;   Filename:  String.  The name of a DXF file.
;
; Input keywords:
;    NORMALIZE: ignored, but present for backwards compatibility.
;    ByLayer: set to read files by layer, rather than by block which
;    		is the default.
;
; OUTPUTS:
;   BlockTable: a structure array describing the  blocks.  See below
;        for description.
;   LayerTable: a structure array describing the  layers.
;   Structure tags for BlockTable and LayerTable:
; 	Name : <string> Block/layer name or NULL for *Model_Space block
;       Model: <object> ;IDLgrModel for this block/layer
;       nEntries: <lonarr(21)> number of DXF entities in this block,
;       	indexed by DXF type.
;	ColorName: <string>  Entitiy's color name
;	Color: <bytarr(3)> Entitiy's color RGB
;	ColorIndex: <int> DXF color index
;	Visible: <int> Set if layer is visible
;
; OUTPUT KEYWORD PARAMETERS
;   IGNORED: An array of 21 elements containing the counts of the DXF
;   	entities that were ignored because of unimplemented DXF data
;   	types.
;   ERROR:  Set to 0 on return if successful, 1 if an error occured.
;
; OUTPUTS:
;   This function returns the IDLgrModel for the *Model_Space block,
;   the default block.
;
; EXAMPLE:
;   IDL> filename = filepath('heart.dxf', subdir=['examples', 'data'])
;   IDL> oModel = get_dxf_objects(filename)
;   IDL> xobjview, oModel
;
; Note: GET_DXF_OBJECTS is undocumented.
;
; MODIFICATION HISTORY:
;   Written by: DMS, RSI, July, 2000.
;-
;

;--------------------------------------------------------------------
FUNCTION get_dxf_objects, filename, $ ; IN
                          BlockTable, $ ; OUT
                          LayerTable, $ ; OUT
                          ByLayer= bylayer, $ ;In
                          NORMALIZE=normalize, $ ; IN
                          IGNORED=ignored, $ ; OUT
                          ERROR=error, $ ; OUT
                          DEBUG=debug ; IN


COMPILE_OPT strictarr, hidden   ; since it is undocumented

; debug=1
; if keyword_set(debug) then print,'Debug'
if keyword_set(normalize) then print, 'Normalize not implemented'

catch, NoDXF
if NoDXF ne 0 then begin        ;DXF present?
    catch, /CANCEL
    message,'DXF not supported on this architecture', /CONTINUE
    error=1
    return, 0
endif

oDXF = OBJ_NEW('IDLffDXF')      ; Create a DXF object.
catch, /CANCEL

; Initialize the returned value to a NULL object reference.
nTypes = 0
ignored = -1L
error = 0

BlockTableEntry = { Name : "", $ ;Block name or NULL for *Model_Space block
                    Model: obj_new(), $ ;IDLgrModel for this block
                    nEntries: lonarr(21), $ ;# of DXF entities in this block
                    ColorName: "", $  ;Block's color name
                    Color: bytarr(3),$ ;Block's color RGB
                    ColorIndex: 0, $
                    Visible: 1}

LayerTableEntry = { Name: "",$  ;Layer name
                    Model: obj_new(), $ ;IDLgrModel for this block
                    nEntries: lonarr(21), $ ;# of DXF entities in this block
                    ColorName: "", $
                    Color: bytarr(3), $
                    ColorIndex: 0, $
                    Visible: 0}

CATCH, errStatus
IF (errStatus NE 0) THEN BEGIN
    CATCH, /CANCEL
    error:    error = 1
    IF (OBJ_VALID(oModel)) THEN OBJ_DESTROY, oModel
    if obj_valid(odxf) then obj_destroy, odxf
    RETURN, obj_new()           ;Return null object
ENDIF
                                ; Read in the DXF file contents.
IF oDXF->Read(filename) eq 0 then goto, error
IF KEYWORD_SET(debug) THEN CATCH, /CANCEL

dxfTypes = oDXF->GetContents(COUNT=typeCounts)
nTypes = N_ELEMENTS(typeCounts)
IF nTypes eq 0 then goto, error ;Nothing there
ignored = LONARR(21)            ;Max number of dxf types

oDXF->GetPalette, palRed, palGreen, palBlue ;DXF palette colors
; Create a model object in which to place the geometry.

iBlock = WHERE(dxfTypes EQ 18, nBlocks) ; Get block color indices.
colornames = [' ', 'Red', 'Yellow', 'Green', 'Cyan', 'Blue', 'Magenta', $
              'White', 'Gray', 'LtRed', 'LtYel', 'LtGrn', 'LtCyan', $
              'LtBlue', 'LtMgnta']


IF (nBlocks ge 1) THEN BEGIN
    nBlocks = typeCounts[iBlock[0]]
    BlockTable = replicate(BlockTableEntry, nBlocks)
    sBlockArr = oDXF->GetEntity(18)
    BlockTable.Name  = sBlockArr.name
    defaultBlock = (where(strlen(BlockTable.Name) eq 0, count))[0] > 0
    if count ne 1 then message, /INFO, 'Warning: no *MODEL_SPACE block.'
    for i=0, nblocks-1 do begin
        j = sBlockArr[i].color < 255
        BlockTable[i].Color = [palRed[j], palGreen[j], palBlue[j]]
        BlockTable[i].ColorName = colorNames[j < 14]
        BlockTable[i].ColorIndex = j
        o = obj_new('idlgrmodel')
        BlockTable[i].model = o
;        print, 'Block ', BlockTable[i].name, sBlockarr[i].pt0
;        o->translate, sBlockArr[i].pt0[0], $
;          sBlockArr[i].pt0[1], sBlockArr[i].pt0[2]
;        o->setproperty, NAME = BlockTable[i].name
    endfor
ENDIF else message,'DXF file has no blocks'


iMatchTypes = WHERE(dxfTypes EQ 20, nLayers) ; Get layer information.
if nLayers gt 0 then begin
    iLayer = iMatchTypes[0]
    nLayers = typeCounts[iLayer]
    LayerTable = Replicate(LayerTableEntry, nLayers)
    sLayerArr = oDXF->GetEntity(20)
    LayerTable.name = sLayerArr.name
    LayerTable.Visible = sLayerArr.color ge 0
    layerModel = OBJARR(nLayers)
    for i=0, nLayers-1 do begin
        j = abs(sLayerArr[i].color) ;Neg => layer turned off
        LayerTable[i].color = [palRed[j], palGreen[j], palBlue[j]]
        LayerTable[i].ColorName = colorNames[j < 14]
        LayerTable[i].ColorIndex = j
        layerTable[i].Model = obj_new('IDLgrMODEL')
    endfor
endif else message, 'DXF file has no layers'


layerNames = LayerTable.name
blockNames = BlockTable.name
processTypes = bytarr(21)       ;Types to process
processTypes[[1,2,3,4,5,6,7,8, 9, 10, 11, 14, 18, 19, 20]] = 1

byLayer = keyword_set(bylayer)

;*****************************************************************
FOR index = 0, (byLayer ? nLayers : nBlocks) -1 do begin ;Read each block
    if byLayer then begin
        contents = odxf->getcontents(LAYER=LayerTable[index].name, $
                                     COUNT=concount)
        for i=0, n_elements(concount)-1 do $
          LayerTable[index].nEntries[contents[i]] = concount[i]
        Lcolor = LayerTable[index].color
    endif else begin
        contents = odxf->getcontents(BLOCK=BlockTable[index].name, $
                                     COUNT=concount)
        for i=0, n_elements(concount)-1 do $
          BlockTable[index].nEntries[contents[i]] = concount[i]
        Bcolor = BlockTable[index].color
    endelse

;*****************************************************************
    FOR i=0, n_elements(contents)-1 DO BEGIN ;Each entity type
        currType = contents[i]
        if processTypes[currType] eq 0 then begin ;Process this type?
            ignored[currType] = ignored[currType] + concount[i]
            continue            ;Skip this
        ENDIF
        if currType eq 18 or currType eq 20 then continue ;done blks & layers

;        print, BlockTable[iBlock].name, ':', currType, typeCounts[i]
        if byLayer then $
          s = oDXF->GetEntity(currType, LAYER=LayerTable[index].name) $
        else s = oDXF->GetEntity(currType, BLOCK=BlockTable[index].name)

        FOR j=0L, n_elements(s)-1 do begin ;Process each element
            if byLayer then begin
                iBlock = (where(s[j].block eq blockNames))[0] > 0
                                ;Count population of each layer
                BlockTable[iBlock].nentries[currType] = $
                  BlockTable[iBlock].nentries[currType]  + 1
                bColor = BlockTable[iBlock].color
                iLayer = index
            endif else begin
                iLayer = (where(s[j].layer eq layerNames))[0] > 0
                                ;Count population of each layer
                LayerTable[iLayer].nentries[currType] = $
                  LayerTable[iLayer].nentries[currType]  + 1
                iBlock = index
            endelse
            entColor = s[j].color

            if entColor le 0 then entColor = BlockTable[iBlock].color $
            else if abs(entColor) ge 256 then $
              entColor = LayerTable[iLayer].color $
            else entColor = [palRed[entColor], palGreen[entColor], $
                             palBlue[entColor]]

            SWITCH currType of
                1:              ;Arc
                2:              ;Circle
                3: BEGIN        ;Ellipse
; Create the arc object.  We punt on ellipses and treat them  as arcs
                    o = OBJ_NEW('IDLgrArc', COLOR=entColor, POS=s[j].pt0, $
                                ASPECT=s[j].MIN_TO_MAJ_RATIO, $
                                RADIUS = s[j].pt1_offset[0], $
                                START_ANGLE = s[j].START_ANGLE * !radeg, $
                                END_ANGLE = s[j].END_ANGLE * !radeg)
                    break
                ENDSWITCH

                4:              ;line
                5:              ;line3d (obsolete)
                6:              ;Trace
                7:              ;Polyline
                8: BEGIN        ;LWPolyline
; Retrieve all polyline-like entities.  Create corresponding
; IDLgrPolyline objects.
                    o = OBJ_NEW('IDLgrPolyline', COLOR=entColor, $
                                THICK=(s[j].thickness eq 0) ? 1 : s[j].thickness,$
                                POLYLINES=*(s[j].connectivity), $
                                (*(s[j].vertices)))
                                ; Clean up.
                    PTR_FREE, s[j].vertices
                    PTR_FREE, s[j].connectivity
                    PTR_FREE, s[j].vertex_colors
                    break
                ENDSWITCH

                9: BEGIN        ;Face3D
                                ; Retrieve all polygon-like entities.
                    o = OBJ_NEW('IDLgrPolygon', COLOR=entColor, $
                                (*(s[j].vertices)))
                    o->setproperty, POLYGON=*(s[j].connectivity), $
                      shading=1, style=2
                                ; Clean up.
                    PTR_FREE, s[j].vertices
                    PTR_FREE, s[j].connectivity
                    PTR_FREE, s[j].vertex_colors
                    break
                ENDSWITCH

                10: BEGIN       ;Face3D
                    o = OBJ_NEW('IDLgrPolygon', COLOR=entColor, $
                                (*(s[j].vertices)), $
                                POLYGONS=*(s[j].connectivity), $
                                SHADING=0, STYLE=2)
                    if ptr_valid(s[j].vertex_colors) then begin
                        vc = *(s[j].vertex_colors)
                        ec = where(vc eq 0, count)
                        if count gt 0 then vc[ec] = BlockTable[iBlock].colorIndex
                        lc = where(vc eq 256, count)
                        if count gt 0 then vc[lc] = LayerTable[iLayer].colorIndex
                        o->setproperty, VERT_COLORS= $
                          transpose([[palRed[vc]],[palGreen[vc]],[palBlue[vc]]])
                    endif
                    PTR_FREE, s[j].vertices ; Clean up.
                    PTR_FREE, s[j].connectivity
                    PTR_FREE, s[j].vertex_colors
                    break
                ENDSWITCH
                11: BEGIN       ;Solid
                    o = OBJ_NEW('IDLgrPolygon', COLOR=entColor, $
                                (*(s[j].vertices)))
                    PTR_FREE, s[j].vertices ; Clean up.
                    PTR_FREE, s[j].connectivity
                    PTR_FREE, s[j].vertex_colors
                    break
                ENDSWITCH

                14: BEGIN       ;Text
                    just = s[j].justification ;Text justification
                    align = ([0.0, 0.5, 1.0, 0.0, 0.5])[just > 0 < 4]
                    o = OBJ_NEW('IDLgrText', COLOR=entColor, $
                                s[j].text_str, CHAR_DIM=s[j].height * [.8,1.], $
                                LOCATION=just eq 0 ? s[j].pt0 : s[j].direction, $
                                ALIGN=align)
                    break
                ENDSWITCH

                19: BEGIN       ;Insert
                    bName = s[j].instance_block ;Name of block to insert
                    inBlock = where(bName eq blocktable.name, count)
                    if count ne 1 then begin
                        message, 'Block '+bName+ ' can not be found to insert'
                    endif
                    n = s[j].num_row_col[0] * s[j].num_row_col[1] ;# of inserts
                    if n gt 1 then o = obj_new('IDLgrMODEL')
                                ; Repeat num_row_cols....
                    for iy=0, s[j].num_row_col[0]-1 do $
                      for ix=0, s[j].num_row_col[1]-1 do begin
                        o1 = obj_new('IDLgrModel') ;Make a new model
                        o1->add, blocktable[inBlock[0]].model, /ALIAS
                        o1->scale,  s[j].scale[0], s[j].scale[1], s[j].scale[2]
                        if s[j].rotation ne 0 then $
                          o1->rotate, [0,0,1], s[j].rotation * !radeg
                        o1->translate, $
                          s[j].pt0[0]+ix*s[j].distance_between[1],$
                          s[j].pt0[1]+iy*s[j].distance_between[0], $
                          s[j].pt0[2]
                        o1->setproperty, NAME=bName
                        if n gt 1 then o->add, o1 $
                        else o = o1
                    endfor
                ENDSWITCH
            ENDSWITCH
            layerTable[iLayer].Model->add, o, /ALIAS ;Add new object to layer
            blockTable[iBlock].Model->add, o, /ALIAS ;Add to block
        ENDFOR                  ;Each element
    ENDFOR                      ;Each entity type
ENDFOR                          ;Each block

                                ; Clean up the DXF object.
IF (OBJ_VALID(oDXF)) THEN OBJ_DESTROY, oDXF

return, BlockTable[defaultBlock[0]].model
END
