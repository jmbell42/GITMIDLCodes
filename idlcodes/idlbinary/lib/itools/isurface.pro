; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/isurface.pro#1 $
; Copyright (c) 2003-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   iSurface
;
; PURPOSE:
;   Implements the isurface wrapper interface for the tools sytem.
;
; CALLING SEQUENCE:
;   ISurface
;
; INPUTS:
;   Z[,X,Y] [,...] (see IDLgrSurface)
;
; KEYWORD PARAMETERS:
;   IDENTIFIER  [out] - The identifier of the created tool.
;
;   VERT_COLORS: vector or 2D array of color indices,
;    or a two-dimensional array containing RGB triplets or RGBA values.
;
;   TEXTURE_IMAGE: 2D array (MxN), 3D array (3xMxN, Mx3xN, MxNx3,
;   4xMxN, Mx4xN, MxNx4) RGB with optional alpha channel
;
;   TEXTURE_RED, TEXTURE_GREEN, TEXTURE_BLUE, TEXTURE_ALPHA: 2D arrays
;   (must be of same size and type) specifying, respectively, red
;   channel, green channel, blue channel, and, optionally, the alpha
;   channel of the image to be used as the TEXTURE_IMAGE
;
;   RGB_TABLE: 2D array (3x256) specifying the colors to be used when
;   index color is used
;
;   All other keywords are passed to the tool during creation.
;
; MODIFICATION HISTORY:
;   Written by:  AGEH, RSI, January 2003
;   Modified:
;
;-

;-------------------------------------------------------------------------
PRO ISURFACE, z, x, y,  _EXTRA=_EXTRA, $
              IDENTIFIER=IDENTIFIER, $
              VERT_COLORS=VERT_COLORS, $
              TEXTURE_IMAGE=TEXTURE_IMAGE, $
              TEXTURE_RED=TEXTURE_RED, $
              TEXTURE_GREEN=TEXTURE_GREEN, $
              TEXTURE_BLUE=TEXTURE_BLUE, $
              TEXTURE_ALPHA=TEXTURE_ALPHA, $
              RGB_TABLE=rgbTable

  compile_opt hidden, idl2
@idlit_on_error2.pro
@idlit_catch.pro
  IF (iErr NE 0) THEN BEGIN
    catch, /cancel
    if (N_ELEMENTS(oParmSet) gt 0) then OBJ_DESTROY, oParmSet
    MESSAGE, /REISSUE_LAST
    return
  ENDIF

  oSrvLangCat = (_IDLitSys_GetSystem())->GetService('LANGCAT')

  IF n_params() eq 0 THEN BEGIN
    ;; Just call the tool creation and return
    IDENTIFIER = IDLitSys_CreateTool("Surface Tool", $
                                     VISUALIZATION_TYPE="SURFACE", $
                                     TITLE='IDL iSurface',_EXTRA=_EXTRA)
    return
  ENDIF ELSE BEGIN
    IF (n_elements(z) EQ 0) THEN $
      Message, oSrvLangCat->Query('Message:iSurface:Zundefined')

    ;; create parameter set for holding data
    oParmSet = OBJ_NEW('IDLitParameterSet', $
                       NAME='Surface parameters', $
                       ICON='surface',$
                       DESCRIPTION='Surface parameters')

    CASE SIZE(z, /N_DIMENSIONS) OF

      1: BEGIN
        ;; if Z is a vector then X and Y are required
        nx = N_ELEMENTS(x)
        ny = N_ELEMENTS(y)
        nz = N_ELEMENTS(z)
        IF ((nx EQ ny) && (ny EQ nz)) THEN BEGIN
          ;; Do not give parameter names when adding,
          ;; since these need to be gridded, and are not
          ;; valid surface parameters.
          oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', $
                                 NAME='VERT X', $
                                 REFORM(x, nz))
          oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', $
                                 NAME='VERT Y', $
                                 REFORM(y, nz))
          oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', $
                                 NAME='VERT Z', $
                                 REFORM(z, nz))
          ;; Fire up the unknown data wizard after starting the tool.
          unknownData = 1
        ENDIF ELSE BEGIN
          Message, oSrvLangCat->Query('Message:iSurface:VectorNElements')
        ENDELSE

      END

      2: BEGIN
        oDataZ = OBJ_NEW('IDLitDataIDLArray2D', Z, $
                         NAME='Z')
        oParmSet->add, oDataZ, PARAMETER_NAME= "Z"

        IF (((nx=N_ELEMENTS(X)) NE 0) OR ((ny=N_ELEMENTS(Y))) NE 0) THEN BEGIN

          validXY = 0b
          zDims = size(z, /dimensions)
          xDims = size(x, /dimensions)
          yDims = size(x, /dimensions)

          ;; if both X and Y exist as vectors, add them to the data set
          IF nx EQ zDims[0] && ny EQ zDims[1] THEN BEGIN
            oDataX = obj_new('idlitDataIDLVector',  X, NAME='X')
            oParmSet->add, oDataX, PARAMETER_NAME  ="X"
            oDataY = obj_new('idlitDataIDLVector', Y, NAME='Y')
            oParmSet->add, oDataY, PARAMETER_NAME= "Y"
            validXY = 1b
          ENDIF

          ;; if both X and Y exist as 2D arrays, add them to the data set
          IF array_equal(zDims,xDims) && array_equal(zDims,yDims) THEN BEGIN
            oDataX = obj_new('IDLitDataIDLArray2D',  X, NAME='X')
            oParmSet->add, oDataX, PARAMETER_NAME  ="X"
            oDataY = obj_new('IDLitDataIDLArray2D', Y, NAME='Y')
            oParmSet->add, oDataY, PARAMETER_NAME= "Y"
            validXY = 1b
          ENDIF

          IF ~validXY THEN BEGIN
            Message, $
              oSrvLangCat->Query('Message:iSurface:XY_ELMTS_NE_Z_COLROW')
          ENDIF

        ENDIF

      END

      ELSE : MESSAGE, 'First argument has invalid dimensions'

    ENDCASE

  ENDELSE

  ;; Check for vertex colors. If set, add that to the data container.
  IF keyword_set(VERT_COLORS) THEN BEGIN
    vFlag = 0
    ndim = size(VERT_COLORS, /n_dimensions)
    dims = size(VERT_COLORS, /dimensions)
    zdim = size(z, /DIMENSIONS)
    IF (ndim EQ 1 || $
      (ndim EQ 2 && dims[0] eq zdim[0] && dims[1] eq zdim[1])) then BEGIN
      oVert = obj_new('idlitDataIDLVector', $
                      reform(VERT_COLORS,n_elements(VERT_COLORS)), $
                      NAME='VERTEX COLORS')
      vFlag = 1
    endif else begin
        ; Handle either RGB or RGBA.
        IF (ndim EQ 2 && $
          (dims[0] EQ 3 || dims[0] eq 4)) THEN BEGIN
          oVert = obj_new('idlitDataIDLArray2D',VERT_COLORS, $
                          NAME='VERTEX COLORS')
          vFlag = 1
        endif
    endelse
    IF vFlag THEN BEGIN
      oParmSet->add, oVert,PARAMETER_NAME="VERTEX COLORS"
    ENDIF ELSE BEGIN
      Message, oSrvLangCat->Query('Message:iSurface:BadVertColors')
    ENDELSE
  ENDIF

  ;; Check for texture map image. If set, add that to the data container.
  IF keyword_set(TEXTURE_IMAGE) && $
    (where(size(TEXTURE_IMAGE,/type) EQ [0l,6,7,8,9,10,11]) EQ -1) THEN BEGIN

    ;; if TEXTURE_IMAGE is 2D, use it directly
    IF (size(TEXTURE_IMAGE,/n_dimensions))[0] EQ 2 THEN BEGIN
      oTextMap = obj_new('idlitDataIDLArray2D', TEXTURE_IMAGE, $
                         NAME='TEXTURE')
      oParmSet->add, oTextMap,PARAMETER_NAME="TEXTURE"
    ENDIF

    ;; if TEXTURE_IMAGE is 3D move channel dimension to the first position
    IF (size(TEXTURE_IMAGE,/n_dimensions))[0] EQ 3 THEN BEGIN
      sz = size(TEXTURE_IMAGE,/dimensions)
      IF (((wh=where(sz EQ 3, complement=comp)))[0] NE -1) || $
        (((wh=where(sz EQ 4, complement=comp)))[0] NE -1) THEN BEGIN
        imageTemp = byte(transpose(TEXTURE_IMAGE,[wh,comp]))
        oTextMap = obj_new('idlitDataIDLArray3D', imageTemp, $
                           NAME='TEXTURE')
        oParmSet->add, oTextMap,PARAMETER_NAME="TEXTURE"
      ENDIF
    ENDIF

    IF ~obj_valid(oTextMap) THEN $
      Message, oSrvLangCat->Query('Message:iSurface:BadTextureImage')

  ENDIF

  ;; Check to see if texture map was passed in as 3 or 4 separate 2D
  ;; arrays.  TEXTURE_RED, TEXTURE_GREEN, and TEXTURE_BLUE must all
  ;; be 2D arrays of the same size and type and TEXTURE_IMAGE must
  ;; not be set.
  IF keyword_set(TEXTURE_RED) && keyword_set(TEXTURE_GREEN) && $
    keyword_set(TEXTURE_BLUE) && ~keyword_set(TEXTURE_IMAGE) && $
    (size(reform(TEXTURE_RED),/n_dimensions) EQ 2) && $
    (size(reform(TEXTURE_GREEN),/n_dimensions) EQ 2) && $
    (size(reform(TEXTURE_BLUE),/n_dimensions) EQ 2) && $
    ( ((textmap_x=(size(reform(TEXTURE_RED),/dimensions))[0])) EQ $
      (size(reform(TEXTURE_GREEN),/dimensions))[0] ) && $
    ( textmap_x EQ (size(reform(TEXTURE_BLUE),/dimensions))[0] ) && $
    ( ((textmap_y=(size(reform(TEXTURE_RED),/dimensions))[1])) EQ $
      (size(reform(TEXTURE_GREEN),/dimensions))[1] ) && $
    ( textmap_y EQ (size(reform(TEXTURE_BLUE),/dimensions))[1] ) && $
    ( ((textmap_type=(size(reform(TEXTURE_RED),/type))[0])) EQ $
      (size(reform(TEXTURE_GREEN),/type))[0] ) && $
    ( textmap_type EQ (size(reform(TEXTURE_BLUE),/type))[0] ) && $
    ( where(textmap_type EQ [0l,6,7,8,9,10,11]) EQ -1 ) THEN BEGIN
    ;; TEXTURE_ALPHA, if set, must match TEXTURE_* in size and type
    IF keyword_set(TEXTURE_ALPHA) && $
      (size(reform(TEXTURE_ALPHA),/n_dimensions) EQ 2) && $
      ( textmap_x EQ (size(reform(TEXTURE_ALPHA),/dimensions))[0]) && $
      ( textmap_y EQ (size(reform(TEXTURE_ALPHA),/dimensions))[1]) && $
      ( textmap_type EQ (size(reform(TEXTURE_ALPHA),/type))[0]) $
      THEN BEGIN
      textData = make_array(4,textmap_x,textmap_y,type=textmap_type)
      textData[0,*,*] = TEXTURE_RED
      textData[1,*,*] = TEXTURE_GREEN
      textData[2,*,*] = TEXTURE_BLUE
      textData[3,*,*] = TEXTURE_ALPHA
    ENDIF ELSE BEGIN
      textData = make_array(3,textmap_x,textmap_y,type=textmap_type)
      textData[0,*,*] = TEXTURE_RED
      textData[1,*,*] = TEXTURE_GREEN
      textData[2,*,*] = TEXTURE_BLUE
    ENDELSE
    oTextMap = obj_new('idlitDataIDLArray3d', textData, $
                       NAME='TEXTURE')
    oParmSet->add, oTextMap, PARAMETER_NAME= "TEXTURE"
  ENDIF

  ;; Check for color table. If set, add that to the data container.
  IF (SIZE(rgbTable, /N_DIMENSIONS) EQ 2) THEN BEGIN
    dim = SIZE(rgbTable, /DIMENSIONS)
    ;; Handle either 3xM or Mx3, but convert to 3xM to store.
    is3xM = dim[0] EQ 3
    IF ((is3xM || (dim[1] EQ 3)) && (max(dim) LE 256)) THEN BEGIN
      tableEntries = is3xM ? rgbTable : TRANSPOSE(rgbTable)
      ramp = BINDGEN(256)
      palette = TRANSPOSE([[ramp],[ramp],[ramp]])
      palette[*,0:n_elements(tableEntries[0,*]) -1] = tableEntries
      oPalette = OBJ_NEW('IDLitDataIDLPalette', $
                         palette, NAME='Palette')
      oParmSet->Add, oPalette, PARAMETER_NAME="PALETTE"
    ENDIF ELSE $
      MESSAGE, oSrvLangCat->Query('Message:iSurface:BadDimsRGB_Table')
  ENDIF

  ;; Set the autodelete mode
  IF (obj_valid(oParmSet)) THEN $
    oParmSet->setAutoDeleteMode, 1

  ;; Send the data to the system for tool creation
  IDENTIFIER = IDLitSys_CreateTool("Surface Tool", $
                                   VISUALIZATION_TYPE="SURFACE", $
                                   INITIAL_DATA=oParmSet, $
                                   UNKNOWN_DATA=unknownData, $
                                   TITLE='IDL iSurface',_EXTRA=_EXTRA)

END
