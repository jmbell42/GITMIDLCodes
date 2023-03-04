; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/ivector.pro#1 $
;
; Copyright (c) 2005-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   iMap
;
; PURPOSE:
;   Implements the iVector wrapper interface for the tools sytem.
;
; CALLING SEQUENCE:
;   iVector[, U, V][, X, Y]
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, Oct 2005
;   Modified:
;
;-


;-------------------------------------------------------------------------
pro iVector, parm1, parm2, parm3, parm4, $
    RGB_TABLE=rgbTable, $
    STREAMLINES=streamlines, $
    VECTOR_COLORS=vectorColors, $
    _REF_EXTRA=_extra

    compile_opt hidden, idl2

@idlit_on_error2.pro
@idlit_catch.pro
    if(iErr ne 0)then begin
        catch, /cancel
        if (N_ELEMENTS(oParmSet) gt 0) then OBJ_DESTROY, oParmSet
        MESSAGE, /REISSUE_LAST
        return
    endif

    n = N_PARAMS()

    if (n gt 0) then begin

        if (n ne 2 && n ne 4) then $
            MESSAGE, 'Incorrect number of arguments.'
        ndim = SIZE(parm1, /N_DIMENSIONS)
        if (ndim ne 1 && ndim ne 2) then $
            MESSAGE, 'Arguments U and V must be vectors or 2D arrays.'
        dim = SIZE(parm1, /DIMENSIONS)
        if (~ARRAY_EQUAL(dim, SIZE(parm2, /DIMENSIONS))) then $
            MESSAGE, 'Arguments U and V must have matching dimensions.'
        if (ndim eq 1 && n ne 4) then $
            MESSAGE, 'For U and V vector inputs, X and Y must be supplied.'

        oParmSet = OBJ_NEW('IDLitParameterSet', NAME='Vector parameters', $
            ICON='fitwindow', DESCRIPTION='Vector parameters')

        class = ndim eq 2 ? 'IDLitDataIDLArray2d' : 'IDLitDataIDLVector'
        oData1 = OBJ_NEW(class, parm1, NAME='U component')
        oData2 = OBJ_NEW(class, parm2, NAME='V component')
        oParmSet->Add, oData1, PARAMETER_NAME='U component'
        oParmSet->Add, oData2, PARAMETER_NAME='V component'

        if (n eq 4) then begin

            if (SIZE(parm3, /N_DIMENSIONS) ne 1) then $
                MESSAGE, 'Argument X must be a vector'
            if (N_ELEMENTS(parm3) ne dim[0]) then $
                MESSAGE, 'Incorrect number of elements for X.'

            if (SIZE(parm4, /N_DIMENSIONS) ne 1) then $
                MESSAGE, 'Argument Y must be a vector'
            if ((ndim eq 2 && N_ELEMENTS(parm4) ne dim[1]) || $
                (ndim eq 1 && N_ELEMENTS(parm4) ne dim[0])) then $
                MESSAGE, 'Incorrect number of elements for Y.'

            oData3 = OBJ_NEW('IDLitDataIDLVector', parm3, NAME='X')
            oData4 = OBJ_NEW('IDLitDataIDLVector', parm4, NAME='Y')
            oParmSet->Add, oData3, PARAMETER_NAME='X'
            oParmSet->Add, oData4, PARAMETER_NAME='Y'
        endif

    endif

    ; Check for color table. If set, add that to the data container.
    if (N_ELEMENTS(rgbTable) gt 0) then begin
        dim = SIZE(rgbTable, /DIMENSIONS)
        ; Handle either 3x256 or 256x3, but convert to 3x256 to store.
        is3x256 = ARRAY_EQUAL(dim, [3, 256])
        if ((N_ELEMENTS(dim) ne 2) || $
            (~is3x256 && ~ARRAY_EQUAL(dim, [256, 3]))) then begin
            MESSAGE, "Incorrect dimensions for RGB_TABLE."
        endif
        if (~OBJ_VALID(oParmSet)) then begin
            oParmSet = OBJ_NEW('IDLitParameterSet', NAME='Vector parameters', $
                ICON='fitwindow', DESCRIPTION='Vector parameters')
        endif
        oPalette = OBJ_NEW('IDLitDataIDLPalette', $
            is3x256 ? rgbTable : TRANSPOSE(rgbTable), NAME='Palette')
        oParmSet->Add, oPalette, PARAMETER_NAME="PALETTE"
    endif


    ; Check for vertex colors. If set, add that to the data container.
    nColors = N_ELEMENTS(vectorColors)
    if (nColors gt 0) then begin
        ndim = SIZE(vectorColors, /N_DIMENSIONS)
        vdim = SIZE(vectorColors, /DIMENSIONS)
        if (ndim gt 2) then $
            MESSAGE, 'VECTOR_COLORS must be a one or two-dimensional array.'
        if (N_ELEMENTS(parm1) gt 0) then begin
            ; See if we have an array of RGB or RGBA values.
            if (ndim eq 2 && (vdim[0] eq 3 || vdim[0] eq 4)) then $
                nColors = vdim[1]
            if (nColors ne N_ELEMENTS(parm1)) then $
                MESSAGE, 'Number of elements in VECTOR_COLORS does not match inputs.'
        endif
        if (~OBJ_VALID(oParmSet)) then begin
            oParmSet = OBJ_NEW('IDLitParameterSet', NAME='Vector parameters', $
                ICON='fitwindow', DESCRIPTION='Vector parameters')
        endif
        oVert = OBJ_NEW((ndim eq 1) ? $
            'idlitDataIDLVector' : 'idlitDataIDLArray2D', vectorColors, $
            NAME='VECTOR COLORS')
        oParmSet->Add, oVert, PARAMETER_NAME="VECTOR COLORS"
    endif

    ; Set the autodelete mode on the parameter set.
    if (OBJ_VALID(oParmSet)) then $
        oParmSet->SetAutoDeleteMode, 1

    visType = KEYWORD_SET(streamlines) ? "STREAMLINE" : "VECTOR"

    ; Send the data to the system for tool creation
    identifier = IDLitSys_CreateTool("Vector Tool", $
        VISUALIZATION_TYPE=visType, $
        INITIAL_DATA=oParmSet, $
        TITLE='IDL iVector',_EXTRA=_EXTRA)

end



