; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/iimage.pro#1 $
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   iImage
;
; PURPOSE:
;   Implements the iimage wrapper interface for the tools sytem.
;
; CALLING SEQUENCE:
;   iImage[, Image][,X, Y]
;
; INPUTS:
;    Image   - Either a vector, two-dimensional array, or
;      three-dimensional array representing the sample values to be
;      displayed as an image.
;
;      If Image is a vector:
;        The X and Y arguments must also be present and contain the same
;        number of elements.  In this case, a dialog will be presented that
;        offers the option of gridding the data to a regular grid (the
;        results of which will be displayed as a color-indexed image).
;
;      If Image is a two-dimensional array:
;        If either dimension is 3:
;          Image represents an array of XYZ values (either:
;          [[x0,y0,z0],[x1,y1,z1],.], or [[x0,x1,.],[y0,y1,.],[z0,z1,.]]).
;          In this case, the X and Y arguments, if present, will be ignored.
;          A dialog will be presented that allows the option of gridding the
;          data to a regular grid (the results of which will be displayed as
;          a color-indexed image, using the Z values as the image data
;          values).
;
;        If neither dimension is 3:
;          If X and Y are provided, the sample values are defined as a
;          function of the corresponding (X, Y) locations; otherwise, the
;          sample values are implicitly treated as a function of the array
;          indices of each element of Image.
;
;      If Image is a three-dimensional array:
;        If one of the dimensions is 3:
;          Image is an array (3xMxN, or Mx3xN, or MxNx3) representing the
;          red, green, and blue channels of the RGB image to be displayed.
;
;        If one of the dimensions is 4:
;          Image is an array (4xMxN, or Mx4xN, or MxNx4) representing the
;          red, green, blue, and alpha channels of the RGBA image to be
;          displayed.
;    X       - Either a vector or a two-dimensional array representing the
;      X coordinates of the image grid.
;
;      If the Image argument is a vector:
;        X must be a vector with the same number of elements.
;
;      If the Image argument is a two-dimensional array (for which neither
;      dimension is 3):
;        If X is a vector, each element of X specifies the X coordinates for
;        a column of Image (e.g., X[0] specifies the X coordinate for
;        Image[0, *]).
;        If X is a two-dimensional array, each element of X specifies the
;        X coordinate of the corresponding point in Image (Xij specifies the
;        X coordinate of Imageij).
;
;    Y      - Either a vector or a two-dimensional array representing the
;      Y coordinates of the image grid.
;
;      If the Image argument is a vector:
;        Y must be a vector with the same number of elements.
;
;      If the Image argument is a two-dimensional array:
;        If Y is a vector, each element of Y specifies the Y coordinates for
;        a column of Image (e.g., Y[0] specifies the Y coordinate for
;        Image[*,0]).
;        If Y is a two-dimensional array, each element of Y specifies the Y
;        coordinate of the corresponding point in Image (Yij specifies the
;        Y coordinate of Imageij).
;
; KEYWORD PARAMETERS:
;
;    ALPHA_CHANNEL - Set this keyword to a two-dimensional array
;      representing the alpha channel pixel values for the image to
;      be displayed.  This keyword is ignored if the Image argument is
;      present, and is intended to be used in conjunction with some
;      combination of the RED_CHANNEL, GREEN_CHANNEL, and BLUE_CHANNEL
;      keywords.
;
;    BLUE_CHANNEL - Set this keyword to a two-dimensional array
;      representing the blue channel pixel values for the image to
;      be displayed.  This keyword is ignored if the Image argument is
;      present, and is intended to be used in conjunction with some
;      combination of the ALPHA_CHANNEL, RED_CHANNEL, and GREEN_CHANNEL
;      keywords.
;
;    GREEN_CHANNEL - Set this keyword to a two-dimensional array
;      representing the green channel pixel values for the image to
;      be displayed.  This keyword is ignored if the Image argument is
;      present, and is intended to be used in conjunction with some
;      combination of the ALPHA_CHANNEL, RED_CHANNEL, and BLUE_CHANNEL
;      keywords.
;
;    IDENTIFIER  [out] - The identifier of the created tool.
;
;    IMAGE_LOCATION - Set this keyword to a two-element vector, [x,y],
;      specifying the location of the lower-left corner of the image
;      in data units.  The default is [0,0].
;
;    IMAGE_DIMENSIONS - Set this keyword to a two-element vector,
;      [width,height], specifying the dimensions of the image in
;      data units.  The default is the pixel dimensions of the image.
;
;    RED_CHANNEL - Set this keyword to a two-dimensional array
;      representing the red channel pixel values for the image to be
;      displayed.  This keyword is ignored if the Image argument is
;      present, and is intended to be used in conjunction with some
;      combination of the ALPHA_CHANNEL, GREEN_CHANNEL, and BLUE_CHANNEL
;      keywords.
;
;    RGB_TABLE - Set this keyword to a 3x256 or 256x3 byte array of
;      RGB color values to be used as the color lookup table for the
;      image.  If no color table is supplied, iImage will provide a
;      default linear grayscale color lookup table for indexed images.
;
;    All other keywords are passed to the tool during creation.
;
; MODIFICATION HISTORY:
;   Written by:  CT, RSI, March 2002
;   Modified:
;
;-

;-------------------------------------------------------------------------
; NAME:
;   _TestRegularGrid
;
; PURPOSE:
;   Utility routine used to determine if the X and Y samples are
;   monotonically increasing and fall on a regular grid.
;
; INPUTS:
;   X:	A vector or 2D array of X values.
;   Y:  A vector or 2D array of Y values.
;
; OUTPUTS:
;   This function returns a 1 if the X and Y samples represent
;   a valid regular grid, or a 0 otherwise.
;
function _TestRegularGrid, x, y, TOLERANCE=inTolerance
    compile_opt idl2, hidden

    tolerance = (N_ELEMENTS(inTolerance) gt 0) ? inTolerance : 0.01

    ; Check X first.
    nXDims = SIZE(x, /N_DIMENSIONS)
    xDims = SIZE(x, /DIMENSIONS)
    case nXDims of
        1: begin
            nx = xDims[0]

            ; Compute deltas between samples.
            dx = x[1:(nx-1)] - x[0:(nx-2)]

            ; Check if samples are monotonically increasing.
            id = WHERE(dx le 0, nNonMono)
            if (nNonMono gt 0) then $
               return, 0

            ; Check if deltas are equal within tolerance.
            stats = MOMENT(dx, SDEV=sdev)
            if (stats[0] eq 0.0) then $
                return, 0
            if ((sdev / stats[0]) gt tolerance) then $
                return, 0
        end

        2: begin
            ; Start with first row.
            xrow = x[*,0]
            nx = xDims[0]
            ny = xDims[1]

            ; Compute deltas between samples.
            dx = xrow[1:(nx-1)] - xrow[0:(nx-2)]

            ; Check if samples are monotonically increasing.
            id = WHERE(dx le 0, nNonMono)
            if (nNonMono gt 0) then $
               return, 0

            ; Check if deltas are equal within tolerance.
            stats = MOMENT(dx, SDEV=sdev)
            deltaMean = stats[0]
            if (deltaMean eq 0.0) then $
                return, 0
            if ((sdev / deltaMean) gt tolerance) then $
                return, 0

            ; Now check that columns are equal within tolerance.
            dx = x[*,1:(ny-1)] - x[*,0:(ny-2)]
            stats = MOMENT(dx)
            if ((stats[0] / deltaMean) gt tolerance) then $
                return, 0
        end

        else: return, 0
    endcase

    ; Check Y next.
    nYDims = SIZE(y, /N_DIMENSIONS)
    yDims = SIZE(y, /DIMENSIONS)
    case nYDims of
        1: begin
            ny = yDims[0]

            ; Compute deltas between samples.
            dy = y[1:(ny-1)] - y[0:(ny-2)]

            ; Check if samples are monotonically increasing.
            id = WHERE(dy le 0, nNonMono)
            if (nNonMono gt 0) then $
               return, 0

            ; Check if deltas are equal within tolerance.
            stats = MOMENT(dy, SDEV=sdev)
            if (stats[0] eq 0.0) then $
                return, 0
            if ((sdev / stats[0]) gt tolerance) then $
                return, 0
        end

        2: begin
            ; Start with first column.
            ycol = y[0,*]
            nx = yDims[0]
            ny = yDims[1]

            ; Compute deltas between samples.
            dy = ycol[1:(ny-1)] - ycol[0:(ny-2)]

            ; Check if samples are monotonically increasing.
            id = WHERE(dy le 0, nNonMono)
            if (nNonMono gt 0) then $
               return, 0

            ; Check if deltas are equal within tolerance.
            stats = MOMENT(dy, SDEV=sdev)
            deltaMean = stats[0]
            if (deltaMean eq 0.0) then $
                return, 0
            if ((sdev / deltaMean) gt tolerance) then $
                return, 0

            ; Now check that rows are equal within tolerance.
            dy = y[1:(nx-1),*] - y[0:(nx-2),*]
            stats = MOMENT(dy)
            if ((stats[0] / deltaMean) gt tolerance) then $
                return, 0
        end

        else: return, 0
    endcase

    return, 1
end

;-------------------------------------------------------------------------
; NAME:
;   _SetPalette
;
; PURPOSE:
;   Utility routine used to add a parameter that corresponds to the
;   RGB values of a palette to the given parameter set.
;
; INPUTS:
;   oParmSet:   A reference to the parameter set object to which the
;     palette is to be added.
;   rgb:    The parameter that corresponds to the RGB values of
;     the palette.
;
; KEYWORDS:
;   DEFAULT: Set this keyword to a non-zero value to indicate that
;     a default grayscale ramp should be constructed.  If this keyword
;     is present, the rgb argument is optional and will be ignored.
;
pro _SetPalette, oParmSet, rgb, DEFAULT=default

    compile_opt idl2, hidden

    if (KEYWORD_SET(default)) then begin
        ; Create default grayscale ramp.
        ramp = BINDGEN(256)

        oPalette = OBJ_NEW('IDLitDataIDLPalette', $
            TRANSPOSE([[ramp],[ramp],[ramp]]), $
            NAME='Palette')

        oParmSet->Add, oPalette, PARAMETER_NAME='PALETTE'
        return
    endif

    nDims = SIZE(rgb, /N_DIMENSIONS)
    if (nDims eq 2) then begin
        dims = SIZE(rgb, /DIMENSIONS)
        if ((dims[0] eq 3) and $
            (dims[1] eq 256)) then begin
            ; [[r0,g0,b0],[r1,g1,b1], ....]
            oPalette = OBJ_NEW('IDLitDataIDLPalette', $
                rgb, $
                NAME='Palette')
         endif else if ((dims[0] eq 256) and $
                        (dims[1] eq 3)) then begin
            ; [[r0,r1,r2,...],[g0,g1,g2,...],[b0,b1,b2,...]]
            oPalette = OBJ_NEW('IDLitDataIDLPalette', $
                TRANSPOSE(rgb), $
                NAME='Palette')
         endif else $
             MESSAGE, 'A palette must be 3x256 or 256x3.'

         oParmSet->Add, oPalette, PARAMETER_NAME='PALETTE'
    endif else $
         MESSAGE, 'A palette must be 3x256 or 256x3.'
end

;-------------------------------------------------------------------------
; NAME:
;   _CreateImageFromChannels
;
; PURPOSE:
;   Utility routine used to create a parameter set consisting of a
;   single RGB or RGBA image using the given channel data.
;
; KEYWORDS:
;   RED_CHANNEL: Set this keyword to two-dimensional vector representing
;      the red channel of the image.
;   GREEN_CHANNEL: Set this keyword to two-dimensional vector representing
;      the green channel of the image.
;   BLUE_CHANNEL: Set this keyword to two-dimensional vector representing
;      the blue channel of the image.
;   ALPHA_CHANNEL: Set this keyword to two-dimensional vector representing
;      the alpha channel of the image.
;   DIMENSIONS: Set this keyword to a named variable that upon return
;      will contain the dimensions of a single channel of the resulting
;      image.
;
; OUTPUTS:
;   This function returns an IDLitDataIDLImagePixels object if able to
;   successfully generate an RGB or RGBA image from the provided channels,
;   or a NULL object reference otherwise.
;
function _CreateImageFromChannels, $
    RED_CHANNEL=redChannel, $
    GREEN_CHANNEL=greenChannel, $
    BLUE_CHANNEL=blueChannel, $
    ALPHA_CHANNEL=alphaChannel, $
    DIMENSIONS=dimensions, $
    ORDER=order, $
    _EXTRA=_extra

    compile_opt idl2, hidden

    haveRed = N_ELEMENTS(redChannel) ne 0
    haveGreen = N_ELEMENTS(greenChannel) ne 0
    haveBlue = N_ELEMENTS(blueChannel) ne 0
    haveAlpha = N_ELEMENTS(alphaChannel) ne 0
    maxType = 0

    ; If no channels were provided, no image can be created.
    if ((haveRed + haveGreen + haveBlue + haveAlpha) eq 0) then begin
        if (ARG_PRESENT(dimensions)) then $
            dimensions = [0,0]
        return, OBJ_NEW()
    endif

    if (haveRed) then begin
        nDims = SIZE(redChannel, /N_DIMENSIONS)
        if (nDims ne 2) then $
            MESSAGE, 'RED_CHANNEL must have two dimensions.'

        redDims = SIZE(redChannel, /DIMENSIONS)
        maxType = SIZE(redChannel, /TYPE)

        imgDims = (haveAlpha ? [4, redDims] : [3, redDims])
    endif

    if (haveGreen) then begin
        nDims = SIZE(greenChannel, /N_DIMENSIONS)
        if (nDims ne 2) then $
            MESSAGE, 'GREEN_CHANNEL must have two dimensions.'

        greenDims = SIZE(greenChannel, /DIMENSIONS)
        maxType = maxType > SIZE(greenChannel, /TYPE)
        if (haveRed) then begin
            if (~ARRAY_EQUAL(redDims, greenDims)) then begin
                MESSAGE, 'Dimensions of channel images must match.', $
                    /CONTINUE
                return, OBJ_NEW()
            endif
        endif else $
            imgDims = (haveAlpha ? [4, greenDims] : [3, greenDims])
    endif

    if (haveBlue) then begin
        nDims = SIZE(blueChannel, /N_DIMENSIONS)
        if (nDims ne 2) then $
            MESSAGE, 'BLUE_CHANNEL must have two dimensions.'

        blueDims = SIZE(blueChannel, /DIMENSIONS)
        maxType = maxType > SIZE(blueChannel, /TYPE)
        if (haveRed) then begin
            if (~ARRAY_EQUAL(redDims, blueDims)) then begin
                MESSAGE, 'Dimensions of channel images must match.', $
                    /CONTINUE
                return, OBJ_NEW()
            endif
        endif else if (haveGreen) then begin
            if (~ARRAY_EQUAL(greenDims, blueDims)) then $
                MESSAGE, 'Dimensions of channel images must match.'
        endif else $
            imgDims = (haveAlpha ? [4, blueDims] : [3, blueDims])
    endif

    if (haveAlpha) then begin
        nDims = SIZE(alphaChannel, /N_DIMENSIONS)
        if (nDims ne 2) then $
            MESSAGE, 'ALPHA_CHANNEL must have two dimensions.'

        alphaDims = SIZE(alphaChannel, /DIMENSIONS)
        maxType = maxType > SIZE(alphaChannel, /TYPE)
        if (haveRed) then begin
            if (~ARRAY_EQUAL(redDims, alphaDims)) then $
                MESSAGE, 'Dimensions of channel images must match.'
        endif else if (haveGreen) then begin
            if (~ARRAY_EQUAL(greenDims, alphaDims)) then $
                MESSAGE, 'Dimensions of channel images must match.'
        endif else if (haveBlue) then begin
            if (~ARRAY_EQUAL(blueDims, alphaDims)) then $
                MESSAGE, 'Dimensions of channel images must match.'
        endif else $
            imgDims = [4, alphaDims]
    endif

    if (ARG_PRESENT(dimensions)) then $
        dimensions = imgDims[1:2]

    imgData = MAKE_ARRAY(imgDims, TYPE=maxType)

    if (haveRed) then $
        imgData[0,*,*] = redChannel

    if (haveGreen) then $
        imgData[1,*,*] = greenChannel

    if (haveBlue) then $
        imgData[2,*,*] = blueChannel

    if (haveAlpha) then $
        imgData[3,*,*] = alphaChannel

    oImageData = OBJ_NEW('IDLitDataIDLImagePixels', $
        imgData, $
        NAME='Image Planes', $
        IDENTIFIER='ImagePixels', $
        ORDER=order, $
        _EXTRA=_extra)

    return, oImageData
end

;-------------------------------------------------------------------------
pro iimage, parm1, parm2, parm3, parm4, $
    IMAGE_LOCATION=imageLocation, $
    IMAGE_DIMENSIONS=imageDimensions, $
    RED_CHANNEL=redChannel, $
    GREEN_CHANNEL=greenChannel, $
    BLUE_CHANNEL=blueChannel, $
    ALPHA_CHANNEL=alphaChannel, $
    RGB_TABLE=rgbTable, $
    IDENTIFIER=IDENTIFIER, $
    ORDER=order, $
    PALETTE=palette, $
    _EXTRA=_extra

    compile_opt hidden, idl2

@idlit_on_error2.pro
@idlit_catch.pro
    if (iErr ne 0) then begin
        CATCH, /CANCEL
	if (N_ELEMENTS(oParmSet)) then $
            OBJ_DESTROY, oParmSet
        MESSAGE, /REISSUE_LAST
        return
    endif

    bHaveImage = 0b
    bHaveUnknown = 0b
    bIndexed = 1b

    ; Capture the parameters within a parameter set.
    nParams = N_PARAMS()

    case nParams of
        0: begin
;-- NO DATA: --------------------------------------------------------------
            ; No data.
        end

        1: begin ; Single parameter.
            ; Check for undefined variable.
            if (N_ELEMENTS(parm1) eq 0) then $
                MESSAGE, 'First argument is an undefined variable.'

            nDims1 = SIZE(parm1, /N_DIMENSIONS)
            case nDims1 of
                2: begin ; First parameter is a 2D array.
                    dims1 = SIZE(parm1, /DIMENSIONS)
                    iDim = WHERE(dims1 eq 3, nDimIs3)
                    if (nDimIs3 gt 0) then begin
;-- SCATTERED DATA: -------------------------------------------------------
;     parm1: 3xN - [[x,y,z],[x,y,z],...], or
;            Nx3 - [[x,x,...],[y,y,...],[z,z,....]]

                        oParmSet = OBJ_NEW('IDLitParameterSet', $
                            NAME='Image parameters', $
                            DESCRIPTION='Image parameters', $
                            ICON='demo')

                        ; Do not give parameter names when adding,
                        ; since these need to be gridded, and are not
                        ; valid image parameters.
                        oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', $
                            ((iDim eq 0) ? $
                                REFORM(parm1[0,*]) : $
                                REFORM(parm1[*,0])), $
                            NAME='X')

                        oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', $
                            ((iDim eq 0) ? $
                                REFORM(parm1[1,*]) : $
                                REFORM(parm1[*,1])), $
                            NAME='Y')

                        oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', $
                            ((iDim eq 0) ? $
                                REFORM(parm1[2,*]) : $
                                REFORM(parm1[*,2])), $
                            NAME='Z')

                        bHaveUnknown = 1
                    endif else begin
;-- INDEXED IMAGE : -------------------------------------------------------
;     parm1: MxN
                        oParmSet = OBJ_NEW('IDLitParameterSet', $
                            NAME='Image parameters', $
                            DESCRIPTION='Image parameters', $
                            ICON='demo')

                        oParmSet->Add, OBJ_NEW('IDLitDataIDLImagePixels', $
                            parm1, $
                            NAME='Image Planes', $
                            IDENTIFIER='ImagePixels', $
                            ORDER=order, $
                            _EXTRA=_extra), PARAMETER_NAME='IMAGEPIXELS'

                        bHaveImage = 1b
                        imgDims = SIZE(parm1, /DIMENSIONS)
                    endelse
                end

                3: begin ; First parameter is a 3D array.
                    dims1 = SIZE(parm1, /DIMENSIONS)
                    if ((dims1[0] eq 3) or $
                        (dims1[1] eq 3) or $
                        (dims1[2] eq 3) or $
                        (dims1[0] eq 4) or $
                        (dims1[1] eq 4) or $
                        (dims1[2] eq 4)) then begin
;-- RGB IMAGE: ------------------------------------------------------------
;     parm1: 3xMxN, Mx3xN, or MxNx3, or
;            4xMxN, Mx4xN, or MxNx4, or
                        oParmSet = OBJ_NEW('IDLitParameterSet', $
                            NAME='Image parameters', $
                            DESCRIPTION='Image parameters', $
                            ICON='demo')

                        oParmSet->Add, OBJ_NEW('IDLitDataIDLImagePixels', $
                            parm1, $
                            NAME='Image Planes', $
                            IDENTIFIER='ImagePixels', $
                            ORDER=order, $
                            _EXTRA=_extra), PARAMETER_NAME='IMAGEPIXELS'

                        bHaveImage = 1b
                        bIndexed = 0b
                        ; Keep track of primary image dimensions.
                        if (dims1[0] eq 3) then $
                            imgDims = dims1[1:2] $
                        else if (dims1[1] eq 3) then $
                            imgDims = [dims1[0],dims1[2]] $
                        else if (dims1[2] eq 3) then $
                            imgDims = dims1[0:1] $
                        else if (dims1[0] eq 4) then $
                            imgDims = dims1[1:2] $
                        else if (dims1[1] eq 4) then $
                            imgDims = [dims1[0],dims1[2]] $
                        else if (dims1[2] eq 4) then $
                            imgDims = dims1[0:1]

                    endif else $
                        MESSAGE, 'First argument has invalid dimensions'
                end
                else: MESSAGE, 'First argument has invalid dimensions'
            endcase
        end

        3: begin ; Three parameters.
            ; Check for undefined variables.
            if (N_ELEMENTS(parm1) eq 0) then $
                MESSAGE, 'First argument is an undefined variable.'
            if (N_ELEMENTS(parm2) eq 0) then $
                MESSAGE, 'Second argument is an undefined variable.'
            if (N_ELEMENTS(parm3) eq 0) then $
                MESSAGE, 'Third argument is an undefined variable.'

            nDims1 = SIZE(parm1, /N_DIMENSIONS)
            case nDims1 of
                1: begin ; First parameter is a vector.

;-- SCATTERED DATA: ------------------------------------------------------
;     parm1: [z0,z1,z2,...]
;     parm2: [x0,x1,x2,...]
;     parm3: [y0,y1,y2,...]
                    nZ = N_ELEMENTS(parm1)
                    nX = N_ELEMENTS(parm2)
                    nY = N_ELEMENTS(parm3)
                    if ((nX eq nZ) and (nY eq nZ)) then begin
                        oParmSet = OBJ_NEW('IDLitParameterSet', $
                            NAME='Image parameters', $
                            DESCRIPTION='Image parameters', $
                            ICON='demo')

                        oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', $
                            REFORM(parm2, nZ), $
                            NAME='X')

                        oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', $
                            REFORM(parm3, nZ), $
                            NAME='Y')

                        oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', $
                            REFORM(parm1, nZ), $
                            NAME='Z')

                        bHaveUnknown = 1

                    endif else begin
                        MESSAGE, $
                            'Number of elements per argument must match.'
                    endelse
                end
                2: begin ; First parameter is a 2D array.
;-- INDEXED IMAGE + XY: ------------------------------------------------------
;     parm1: MxN (indexed image)
;     parm2: MxN (X), or M (X)
;     parm3: MxN (Y), or N (Y)
                    imgDims = SIZE(parm1, /DIMENSIONS)

                    ; Check dimensions of second parameter.  Ensure it
                    ; corresponds to the dimensions of the first parameter.
                    nXDims = SIZE(parm2, /N_DIMENSIONS)
                    if ((nXDims lt 1) or (nXDims gt 2)) then $
                        MESSAGE, 'X must be a vector or 2D array.'
                    xDims = SIZE(parm2, /DIMENSIONS)
                    if (xdims[0] ne imgDims[0]) then $
                        MESSAGE, 'Dimensions of X do not correspond to Image'
                    if (nXDims eq 2) then begin
                        if (xdims[1] ne imgDims[1]) then $
                            MESSAGE, $
                               'Dimensions of X do not correspond to Image'
                    endif

                    ; Check dimensions of second parameter.  Ensure it
                    ; corresponds to the dimensions of the first parameter.
                    nYDims = SIZE(parm3, /N_DIMENSIONS)
                    if ((nYDims lt 1) or (nYDims gt 2)) then $
                        MESSAGE, 'Y must be a vector or 2D array.'
                    yDims = SIZE(parm3, /DIMENSIONS)
                    if (nYDims eq 1) then begin
                        if (ydims[0] ne imgDims[1]) then $
                            MESSAGE, $
                               'Dimensions of Y do not correspond to Image'
                    endif else begin
                        if (ydims[0] ne imgDims[0]) then $
                            MESSAGE, $
                               'Dimensions of Y do not correspond to Image'
                        if (ydims[1] ne imgDims[1]) then $
                            MESSAGE, $
                               'Dimensions of Y do not correspond to Image'
                    endelse

                    ; Test whether the XY values fall on a regular grid.
                    isRegular = _TestRegularGrid(parm2, parm3)

                    oParmSet = OBJ_NEW('IDLitParameterSet', $
                        NAME='Image parameters', $
                        DESCRIPTION='Image parameters', $
                        ICON='demo')

                    if (isRegular) then begin
                        oParmSet->Add, $
                            OBJ_NEW('IDLitDataIDLImagePixels', $
                                parm1, $
                                NAME='Image Planes', $
                                IDENTIFIER='ImagePixels', $
                                ORDER=order, $
                                _EXTRA=_extra), $
                            PARAMETER_NAME='IMAGEPIXELS'

                        if (nXDims eq 2) then begin
                            oParmSet->Add, $
                              OBJ_NEW('IDLitDataIDLArray2D', $
                                  parm2, NAME='X'), $
                              PARAMETER_NAME='X'
                        endif else begin
                            oParmSet->Add, $
                              OBJ_NEW('IDLitDataIDLVector', $
                                  parm2, NAME='X'), $
                              PARAMETER_NAME='X'
                        endelse

                        if (nYDims eq 2) then begin
                            oParmSet->Add, $
                              OBJ_NEW('IDLitDataIDLArray2D', $
                                  parm3, NAME='Y'), $
                              PARAMETER_NAME='Y'
                        endif else begin
                            oParmSet->Add, $
                              OBJ_NEW('IDLitDataIDLVector', $
                                  parm3, NAME='Y'), $
                              PARAMETER_NAME='Y'
                        endelse

                        bHaveImage = 1b
                    endif else begin
                        ; The data needs to be gridded.
                        ;
                        ; Do not give parameter names when adding,
                        ; since these are not valid image parameters.


                        if (nXDims eq 1) then begin
                            oParmSet->Add, $
                                OBJ_NEW('IDLitDataIDLVector', $
                                    parm2, $
                                    NAME='X')
                        endif else begin
                             oParmSet->Add, $
                                 OBJ_NEW('IDLitDataIDLVector', $
                                    REFORM(parm2, N_ELEMENTS(parm2)), $
                                    NAME='X')
                        endelse

                        if (nYDims eq 1) then begin
                             oParmSet->Add, $
                                 OBJ_NEW('IDLitDataIDLVector', $
                                    parm3, $
                                    NAME='Y')
                        endif else begin
                             oParmSet->Add, $
                                 OBJ_NEW('IDLitDataIDLVector', $
                                    REFORM(parm3, N_ELEMENTS(parm3)), $
                                    NAME='Y')
                        endelse

                        dims1 = SIZE(parm1, /DIMENSIONS)

                        ; If the first dim of Z matches X and the second
                        ; dim matches Y, then assume an irregular grid.
                        if (nXDims eq 1 && nYDims eq 1 && $
                            dims1[0] eq N_ELEMENTS(parm2) && $
                            dims1[1] eq N_ELEMENTS(parm3)) then begin
                            ; Do not give parameter names when adding,
                            ; since these are not valid image parameters.
                            oParmSet->Add, OBJ_NEW('IDLitDataIDLArray2D', $
                                parm1, NAME='Z')
                        endif else begin
                            oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', $
                                REFORM(parm1, N_ELEMENTS(parm1)), NAME='Z')
                        endelse

                        bHaveUnknown = 1
                    endelse
                end
                else: MESSAGE, 'Invalid number of dimensions: first argument'
            endcase
        end

        else: MESSAGE, 'Incorrect number of arguments'

    endcase

   ;; Check for keyword settings.

   ;; RED_CHANNEL, GREEN_CHANNEL, BLUE_CHANNEL, and/or ALPHA_CHANNEL.
   if (~(bHaveImage or bHaveUnknown)) then begin
       oImageData = _CreateImageFromChannels( $
           RED_CHANNEL=redChannel, $
           GREEN_CHANNEL=greenChannel, $
           BLUE_CHANNEL=blueChannel, $
           ALPHA_CHANNEL=alphaChannel, $
           DIMENSIONS=imgDims, $
           ORDER=order, $
           _EXTRA=_extra)

       if (OBJ_VALID(oImageData)) then begin
           oParmSet = OBJ_NEW('IDLitParameterSet', $
               NAME='Image parameters', $
               DESCRIPTION='Image parameters', $
               ICON='demo')

           oParmSet->Add, oImageData, PARAMETER_NAME='IMAGEPIXELS'

           bHaveImage = 1b
           bIndexed = 0
       endif
   endif

   ; IMAGE_LOCATION and IMAGE_DIMENSIONS.
   if ((N_ELEMENTS(imageLocation) eq 2) or $
       (N_ELEMENTS(imageDimensions) eq 2)) then begin

       if (bHaveImage) then begin
           ; Note: imgDims should have been set above.

           if (N_ELEMENTS(imageLocation) eq 2) then begin
               xmin = imageLocation[0]
               ymin = imageLocation[1]
           endif else begin
               xmin = 0
               ymin = 0
           endelse

           if (N_ELEMENTS(imageDimensions) eq 2) then begin
               xmax = xmin + imageDimensions[0]
               ymax = ymin + imageDimensions[1]
               delta = DOUBLE(imageDimensions) / DOUBLE(imgDims)
           endif else begin
               xmax = xmin + imgDims[0]
               ymax = ymin + imgDims[1]
               delta  = [1.0,1.0]
           endelse

           x = DINDGEN(imgDims[0])*delta[0] + xmin
           y = DINDGEN(imgDims[1])*delta[1] + ymin

           if (OBJ_VALID(oParmSet) ne 0) then begin
               oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', $
                   x, NAME='X'), PARAMETER_NAME='X'

               oParmSet->Add, OBJ_NEW('IDLitDataIDLVector', $
                   y, NAME='Y'), PARAMETER_NAME='Y'
           endif
       endif
   endif

   ; RGB_TABLE.
   ; Note: palettes only apply for indexed images.
   if ((bHaveImage and bIndexed) or bHaveUnknown) then begin
       if (N_ELEMENTS(rgbTable) ne 0) then $
           _SetPalette, oParmSet, rgbTable $
       else if (N_ELEMENTS(palette) ne 0) then begin
           ; If an IDLgrPalette was provided, then grab the red, green,
           ; and blue values, and pass them on to the palette data for
           ; this image.
           ; NOTE: the palette object itself will not be utilized
           ; directly.  Any changes made later to the palette object
           ; will not be reflected in the iImage tool.
           if (OBJ_VALID(palette) && $
               OBJ_ISA(palette,'IDLgrPalette')) then begin
               palette->GetProperty, RED_VALUES=rVal, GREEN_VALUES=gVal, $
                   BLUE_VALUES=bVal
               _SetPalette, oParmSet, TRANSPOSE([[rVal],[gVal],[bVal]])
           endif
       endif
   endif

   ;; Send the data to the system for tool creation
   if (bHaveUnknown) then $
       unknownData = 1

   ;; Set the autodelete mode on the parameter set
   if(obj_valid(oParmSet))then $
     oParmSet->SetAutoDeleteMode, 1

   IDENTIFIER = IDLitSys_CreateTool("Image Tool", $
                                    TITLE='IDL iImage', $
                                    VISUALIZATION_TYPE="IMAGE", $
                                    UNKNOWN_DATA=unknownData, $
                                    INITIAL_DATA=oParmSet, $
                                    _EXTRA=_EXTRA)
end


