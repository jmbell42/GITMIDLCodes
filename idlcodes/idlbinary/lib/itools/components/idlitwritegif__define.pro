; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/components/idlitwritegif__define.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
; Purpose:
;   This file implements the IDLitWriteGIF class.
;

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; Purpose:
;   The constructor of the object.
;
; Arguments:
;   None.
;
; Keywords:
;   All superclass keywords.
;
FUNCTION IDLitWriteGIF::Init, $
  _EXTRA=_extra

  compile_opt idl2, hidden

  ;; Init superclass
  ;; The only properties that can be set at INIT time can be set
  ;; in the superclass Init method.
  if (~self->IDLitWriter::Init('gif', $
                               TYPES=["IDLIMAGE", "IDLIMAGEPIXELS", "IDLARRAY2D"], $
                               NAME='Graphics Interchange Format', $
                               DESCRIPTION="Graphics Interchange Format (gif)", $
                               _EXTRA=_extra)) then $
    return, 0

  ;; Initialize ourself
  IF (N_ELEMENTS(_extra) GT 0) THEN $
    self->IDLitWriteGIF::SetProperty, _EXTRA=_extra

  return, 1

END


;---------------------------------------------------------------------------
; Purpose:
;   Procedure for writing data out to the file.
;
; Arguments:
;   ImageData: An object reference to the data to be written.
;
; Keywords:
;   None.
;
FUNCTION IDLitWriteGIF::SetData, oImageData
  compile_opt idl2, hidden

  IF (~self->IDLitWriter::_GetImageData(oImageData, $
                                        image, red, green, blue, $
                                        HAS_PALETTE=hasPalette)) THEN $
    return, 0

  strFilename = self->GetFilename()

  ;; account for possible true color images
  IF (size(image,/n_dimensions) EQ 3) THEN BEGIN
    oImageData->GetProperty, INTERLEAVE=interleave
    image = color_quan(image,interleave+1,red,green,blue)
    hasPalette = 1
  ENDIF

  IF hasPalette THEN $
    WRITE_GIF, strFilename, image, red, green, blue $
  ELSE $
    WRITE_GIF, strFilename, image
  
  return, 1

END


;---------------------------------------------------------------------------
; Definition
;---------------------------------------------------------------------------
; Purpose:
;   Class definition.
;
PRO IDLitWriteGIF__Define
  compile_opt idl2, hidden

  void = {IDLitWriteGIF, $
          inherits IDLitWriter $
         }

END
