; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/ivolume.pro#1 $
; Copyright (c) 2003-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   iVolume
;
; PURPOSE:
;   Implements the iVolume command line interface for the tools sytem.
;
; CALLING SEQUENCE:
;   iVolume
;
; INPUTS:
;   vol0, vol1, vol2, vol3 - Three-dimensional arrays of volume data.
;   Zero, one, two, or four of these channels must be specified.
;   All of the volume arrays must be of the same dimension.
;   If no volume data is specified, an empty volume visualization
;   is created.
;
; KEYWORD PARAMETERS:
;   RGB_TABLE0, RGB_TABLE1 - [3x256] array of color values.
;   If not specified, linear gray ramps are used in the volume
;   visualization.  If a two-channel volume is specified, the
;   volume visualization will use both color tables; otherwise
;   it uses the first color table.
;
;   OPACITY_TABLE0, OPACITY_TABLE1 - [3x256] array of opacity values.
;   If not specified, linear ramps are used in the volume
;   visualization.  If a two-channel volume is specified, the
;   volume visualization will use both opacity tables; otherwise
;   it uses the first opacity table.
;
;   VOLUME_DIMENSIONS - A three-element vector that specifies the
;   volume dimensions in user data coordinates.
;
;   VOLUME_LOCATION - A three-element vector that specifies the
;   volume location in user data coordinates.
;
;   IDENTIFIER  [out] - The identifier of the created tool.
;
;   Keywords accepted by IDLgrVolume may also be specified.
;
;   In addition, the following keywords are available:
;
;   AUTO_RENDER - Set to 1 to always render the volume.  The default is
;   to not render the volume each time the tool window is drawn.
;
;   RENDER_EXTENTS - 0: Do not draw anything around the volume.
;   1: Draw a wireframe around the volume.  2: Draw a translucent box
;   around the volume.
;
;   RENDER_QUALITY - 1: Low - Renders volume with a stack of 2D texture maps.
;   2: High - Use IDLgrVolume ray-casting rendering.
;
;   SUBVOLUME (or BOUNDS)- Six-element vector [Xmin, Ymin, Zmin, Xmax, Ymax, Zmax]
;   to specify the subvolume to render.
;
;   All other keywords are passed to the tool during creation.
;
; MODIFICATION HISTORY:
;   Written by:  KWS, RSI, February 2003
;   Modified:
;
;-



;-------------------------------------------------------------------------
pro iVolume, vol0, vol1, vol2, vol3, $
             RGB_TABLE0=rgb_table0, $
             RGB_TABLE1=rgb_table1, $
             OPACITY_TABLE0=opacity_table0, $
             OPACITY_TABLE1=opacity_table1, $
             VOLUME_DIMENSIONS=volumeDimensions, $
             VOLUME_LOCATION=volumeLocation, $
             IDENTIFIER=identifier, $ ; return to caller
             _EXTRA=_EXTRA

    compile_opt hidden, idl2
    @idlit_on_error2.pro
    @idlit_catch.pro

    if(iErr ne 0)then begin
        catch, /cancel
        if (OBJ_VALID(oParmSet)) then $
            OBJ_DESTROY, oParmSet
        MESSAGE, /REISSUE_LAST
        return
    endif

    if N_PARAMS() gt 0 and N_ELEMENTS(vol0) eq 0 then $
        Message, "Parameter vol0 is an undefined variable."

    ;; Prepare data parameters for invoking the volume tool.
    oParmSet = OBJ_NEW('IDLitParameterSet', $
        NAME='Volume Data Container', $
        ICON='volume', $
        DESCRIPTION='Volume Data Container created by iVolume')

    ;; Check vol args for existence and consistency
    if (N_ELEMENTS(vol0) eq 0 && N_ELEMENTS(vol1) eq 0 && $
        N_ELEMENTS(vol2) eq 0 && N_ELEMENTS(vol3) eq 0) $
        || $
       (N_ELEMENTS(vol0) gt 1 && N_ELEMENTS(vol1) eq 0 && $
        N_ELEMENTS(vol2) eq 0 && N_ELEMENTS(vol3) eq 0 && $
        SIZE(vol0, /N_DIMENSIONS) eq 3 ) $
        || $
       (N_ELEMENTS(vol0) gt 1 && N_ELEMENTS(vol1) gt 1 && $
        N_ELEMENTS(vol2) eq 0 && N_ELEMENTS(vol3) eq 0 && $
        ARRAY_EQUAL(SIZE(vol0,/DIMENSIONS), SIZE(vol1,/DIMENSIONS)) && $
        SIZE(vol0, /N_DIMENSIONS) eq 3 ) $
        || $
       (N_ELEMENTS(vol0) gt 1 && N_ELEMENTS(vol1) gt 1 && $
        N_ELEMENTS(vol2) gt 1 && N_ELEMENTS(vol3) gt 1 && $
        ARRAY_EQUAL(SIZE(vol0,/DIMENSIONS), SIZE(vol1,/DIMENSIONS)) && $
        ARRAY_EQUAL(SIZE(vol0,/DIMENSIONS), SIZE(vol2,/DIMENSIONS)) && $
        ARRAY_EQUAL(SIZE(vol0,/DIMENSIONS), SIZE(vol3,/DIMENSIONS)) && $
        SIZE(vol0, /N_DIMENSIONS) eq 3 ) $
        then begin
            if N_ELEMENTS(vol0) gt 0 then begin
            oDataVol = OBJ_NEW('IDLitDataIDLArray3D', vol0, $
                               NAME='Volume0')
            oParmSet->add, oDataVol, PARAMETER_NAME="Volume0"
            endif
            if N_ELEMENTS(vol1) gt 0 then begin
                oDataVol = OBJ_NEW('IDLitDataIDLArray3D', vol1, $
                                   NAME='Volume1')
                oParmSet->add, oDataVol, PARAMETER_NAME="Volume1"
            endif
            if N_ELEMENTS(vol2) gt 0 && N_ELEMENTS(vol3) gt 0 then begin
                oDataVol = OBJ_NEW('IDLitDataIDLArray3D', vol2, $
                                   NAME='Volume2')
                oParmSet->add, oDataVol, PARAMETER_NAME="Volume2"
                oDataVol = OBJ_NEW('IDLitDataIDLArray3D', vol3, $
                                   NAME='Volume3')
                oParmSet->add, oDataVol, PARAMETER_NAME="Volume3"
            endif
    endif else begin
        MESSAGE, "Volume data arrays are invalid or inconsistent."
    endelse

    ;; Check for color tables. If set, add to the parm set.
    ;; IDLgrVolume expects 256x3, but people are often used to 3x256.
    ;; The IDLPALETTE data type is 3x256, so convert it to that format.
    if (SIZE(rgb_table0,/N_DIMENSIONS))[0] EQ 2 && $
        ( ((SIZE(rgb_table0,/DIMENSIONS))[0] EQ 3 && $
           (SIZE(rgb_table0,/DIMENSIONS))[1] EQ 256) || $
          ((SIZE(rgb_table0,/DIMENSIONS))[0] EQ 256 && $
           (SIZE(rgb_table0,/DIMENSIONS))[1] EQ 3) ) THEN BEGIN
        if (SIZE(rgb_table0,/DIMENSIONS))[1] EQ 3 then $
            rgb_table0 = TRANSPOSE(rgb_table0)
        oColorTable = OBJ_NEW('IDLitDataIDLPalette', rgb_table0, NAME='RGB Table 0')
        oParmSet->add, oColorTable, PARAMETER_NAME="RGB_TABLE0"
    endif else if N_ELEMENTS(rgb_table0) gt 0 then begin
        MESSAGE, "Invalid Color table (RGB_TABLE0)"
    endif

    if (SIZE(rgb_table1,/N_DIMENSIONS))[0] EQ 2 && $
        ( ((SIZE(rgb_table1,/DIMENSIONS))[0] EQ 3 && $
           (SIZE(rgb_table1,/DIMENSIONS))[1] EQ 256) || $
          ((SIZE(rgb_table1,/DIMENSIONS))[0] EQ 256 && $
           (SIZE(rgb_table1,/DIMENSIONS))[1] EQ 3) ) THEN BEGIN
        if (SIZE(rgb_table1,/DIMENSIONS))[1] EQ 3 then $
            rgb_table1 = TRANSPOSE(rgb_table1)
        oColorTable = OBJ_NEW('IDLitDataIDLPalette', rgb_table1, NAME='RGB Table 1')
        oParmSet->add, oColorTable, PARAMETER_NAME="RGB_TABLE1"
    endif else if N_ELEMENTS(rgb_table1) gt 0 then begin
        MESSAGE, "Invalid Color table (RGB_TABLE1)"
    endif

    ;; Check for opacity tables. If set, add to the parm set.
    if (SIZE(opacity_table0,/N_DIMENSIONS))[0] EQ 1 && $
        (SIZE(opacity_table0,/DIMENSIONS))[0] EQ 256 then begin
      oOpacityTable = OBJ_NEW('IDLitData', opacity_table0, $
                      NAME='Opacity Table 0', TYPE='IDLOPACITY_TABLE', ICON='layer')
      oParmSet->add, oOpacityTable, PARAMETER_NAME="OPACITY_TABLE0"
    endif else if N_ELEMENTS(opacity_table0) gt 0 then begin
        MESSAGE, "Invalid Opacity table (OPACITY_TABLE0)"
    endif

    if (SIZE(opacity_table1,/N_DIMENSIONS))[0] EQ 1 && $
        (SIZE(opacity_table1,/DIMENSIONS))[0] EQ 256 then begin
      oOpacityTable = OBJ_NEW('IDLitData', opacity_table1, $
                      NAME='Opacity Table 1', TYPE='IDLOPACITY_TABLE', ICON='layer')
      oParmSet->add, oOpacityTable, PARAMETER_NAME="OPACITY_TABLE1"
    endif else if N_ELEMENTS(opacity_table1) gt 0 then begin
        MESSAGE, "Invalid Opacity table (OPACITY_TABLE1)"
    endif

    if N_ELEMENTS(volumeDimensions) eq 3 then begin
        oParm = OBJ_NEW('IDLitDataIDLVector', volumeDimensions, $
                        NAME='VOLUME_DIMENSIONS', TYPE='IDLVector')
      oParmSet->add, oParm, PARAMETER_NAME="VOLUME_DIMENSIONS"
    endif else if N_ELEMENTS(volumeDimensions) gt 0 then begin
        MESSAGE, "Invalid VOLUME_DIMENSIONS"
    endif

    if N_ELEMENTS(volumeLocation) eq 3 then begin
        oParm = OBJ_NEW('IDLitDataIDLVector', volumeLocation, $
                        NAME='VOLUME_LOCATION', TYPE='IDLVector')
      oParmSet->add, oParm, PARAMETER_NAME="VOLUME_LOCATION"
    endif else if N_ELEMENTS(volumeLocation) gt 0 then begin
        MESSAGE, "Invalid VOLUME_LOCATION"
    endif

    ;; Start the Tool
    if oParmSet->Count() eq 0 then begin
        OBJ_DESTROY, oParmSet
        identifier = IDLitSys_CreateTool("Volume Tool", $
                                         VISUALIZATION_TYPE="VOLUME", $
                                         TITLE='IDL iVolume',$
                                         _EXTRA=_EXTRA)
    endif else begin
       oParmSet->SetAutoDeleteMode, 1b ;; set to autodelete
       identifier = IDLitSys_CreateTool("Volume Tool", $
                                        VISUALIZATION_TYPE="VOLUME", $
                                        INITIAL_DATA=oParmSet, $
                                        TITLE='IDL iVolume',$
                                        _EXTRA=_EXTRA)
   endelse

end
