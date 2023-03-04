; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/icontour.pro#1 $
; Copyright (c) 2003-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   iContour
;
; PURPOSE:
;   Implements the icontour wrapper interface for the tools sytem.
;
; CALLING SEQUENCE:
;   IContour
;
; INPUTS:
;   Z[,X,Y] [,...] (see IDLgrContour)
;
; KEYWORD PARAMETERS:
;   IDENTIFIER  [out] - The identifier of the created tool.
;
;   RGB_TABLE
;   Set this keyword to either a 3x256 or 256x3 array containing
;   color values to use for vertex colors.
;
;   RGB_INDICES
;   Set this keyword to a vector of indices into the color table
;   to select colors to use for vertex colors.  If the number of
;   colors selected is less than the number of vertices, the
;   colors are repeated cyclically.
;
;   All other keywords are passed to the tool during creation.
;
; MODIFICATION HISTORY:
;   Written by:  Alan, RSI, January 2003
;   Modified:
;
;-



;-------------------------------------------------------------------------
pro icontour, z, x, y, $
    RGB_TABLE=rgbTable, $
    RGB_INDICES=rgbIndices, $
    IDENTIFIER=IDENTIFIER, $
    _EXTRA=_EXTRA

    compile_opt hidden, idl2
@idlit_on_error2.pro
@idlit_catch.pro

    if(iErr ne 0)then begin
        catch, /cancel
        if (N_ELEMENTS(oParmSet) gt 0) then OBJ_DESTROY, oParmSet
        MESSAGE, /REISSUE_LAST
        return
    endif

    IF (n_params() GT 0 || $
       N_ELEMENTS(rgbTable) gt 0 || $
       N_ELEMENTS(rgbIndices) gt 0) THEN BEGIN
        oParmSet = OBJ_NEW('IDLitParameterSet', $
            NAME='Contour parameters', $
            ICON='contour', $
            DESCRIPTION='Contour parameters')

        if(n_elements(z) eq 0) then $
            Message, "Parameter Z is an undefined variable."

        case SIZE(z, /N_DIMENSIONS) of

        1: begin
            nx = N_ELEMENTS(x)
            ny = N_ELEMENTS(y)
            nz = N_ELEMENTS(z)
            if ((nx eq ny) && (ny eq nz)) then BEGIN
                oDataX = OBJ_NEW('IDLitDataIDLVector', $
                                     NAME='VERT X', $
                                     REFORM(x, nz))
                oDataY = OBJ_NEW('IDLitDataIDLVector', $
                                     NAME='VERT Y', $
                                     REFORM(y, nz))
                oDataZ = OBJ_NEW('IDLitDataIDLVector', $
                                     NAME='VERT Z', $
                                     REFORM(z, nz))
                ; Do not give parameter names when adding,
                ; since these need to be gridded, and are not
                ; valid contour parameters.
                oParmSet->Add, oDataX
                oParmSet->Add, oDataY
                oParmSet->Add, oDataZ
                ; Fire up the unknown data wizard after starting the tool.
                unknownData = 1
            endif else begin
                MESSAGE, 'Arguments have invalid dimensions'
            endelse
        end

        2: begin
            oDataZ = OBJ_NEW('IDLitDataIDLArray2d', Z, $
                                NAME='Z')
            oParmSet->add, oDataZ, PARAMETER_NAME="Z"

            IF (((nx=N_ELEMENTS(X)) NE 0) OR ((ny=N_ELEMENTS(Y))) NE 0) THEN BEGIN
                validXY = 0b
                zDims = size(z, /dimensions)
                xDims = size(x, /dimensions)
                yDims = size(y, /dimensions)

                ; if X and Y cover the x and y dimensions, resp. of Z
                ; add them to the data set
                if ((nx eq zDims[0]) && (ny eq zDims[1])) then BEGIN
                    oDataX = obj_new('idlitDataIDLVector', X, NAME='X')
                    oDataY = obj_new('idlitDataIDLVector', Y, NAME='Y')
                    oParmSet->add, oDataX, PARAMETER_NAME="X"
                    oParmSet->add, oDataY, PARAMETER_NAME="Y"
                    validXY = 1b
                endif

                ; if both X and Y exist as 2D arrays of the same dim
                ; as z add them to the data set
                IF array_equal(zDims,xDims) && array_equal(zDims,yDims) THEN BEGIN
                  oDataX = obj_new('IDLitDataIDLArray2D',  X, NAME='X')
                  oDataY = obj_new('IDLitDataIDLArray2D', Y, NAME='Y')
                  oParmSet->add, oDataX, PARAMETER_NAME="X"
                  oParmSet->add, oDataY, PARAMETER_NAME="Y"
                  validXY = 1b
                ENDIF

                IF ~validXY THEN BEGIN
                  MESSAGE, 'X or Y argument has invalid dimensions'
                ENDIF
            endif
        end

        else: MESSAGE, 'First argument has invalid dimensions'

        ENDCASE

        ; Check for color table. If set, add that to the data container.
        if (SIZE(rgbTable, /N_DIMENSIONS) EQ 2) then begin
            dim = SIZE(rgbTable, /DIMENSIONS)
            ; Handle either 3x256 or 256x3, but convert to 3x256 to store.
            is3x256 = ARRAY_EQUAL(dim, [3, 256])
            if (is3x256 || ARRAY_EQUAL(dim, [256, 3])) then begin
                oPalette = OBJ_NEW('IDLitDataIDLPalette', $
                    is3x256 ? rgbTable : TRANSPOSE(rgbTable), NAME='Palette')
                oParmSet->Add, oPalette, PARAMETER_NAME="PALETTE"
            endif else $
                MESSAGE, "Incorrect dimensions for RGB_TABLE."
       endif

        ;; Check for color table indices. If set, add that to the data container.
        if (SIZE(rgbIndices,/n_dimensions))[0] EQ 1 then begin
          oColorIndices = OBJ_NEW('IDLitDataIDLVector', rgbIndices, $
                          NAME='RGB Indices', TYPE='IDLVECTOR', icon='layer')
          oParmSet->add, oColorIndices, PARAMETER_NAME="RGB_INDICES"
        endif

    ENDIF

    ;; Set the autodelete mode on the parameter set.
    if (OBJ_VALID(oParmSet)) then $
      oParmSet->SetAutoDeleteMode, 1


    ;; Send the data to the system for tool creation
    IDENTIFIER = IDLitSys_CreateTool("Contour Tool", $
                                     VISUALIZATION_TYPE="CONTOUR", $
                                     UNKNOWN_DATA=unknownData, $
                                     INITIAL_DATA=oParmSet, $
                                     TITLE='IDL iContour',_EXTRA=_EXTRA)

end
