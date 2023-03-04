;----------------------------------------------------------------
; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/wavelet/source/wv_import_wavelet.pro#1 $
;
; Copyright (c) 1999-2006, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.
;+
; NAME:
;    WV_IMPORT_WAVELET
;
; PURPOSE:
;
;    The WV_IMPORT_WAVELET procedure allows the user to add wavelet
;    functions to the IDL Wavelet Toolkit.
;
; CALLING SEQUENCE:
;
;    WV_IMPORT_WAVELET [, Wavelet] [, /RESET]
;
; INPUTS:
;
;    Wavelets: A scalar string or vector of strings giving the names of
;      user-defined wavelet functions to be included in WV_APPLET. The actual
;      function names are constructed by removing all white space from each
;      name and attaching a prefix of WV_FN_.
;
; KEYWORD PARAMETERS:
;
;    RESET: If set, then erase all user-defined wavelets and initialize
;      with only the built-in wavelet functions. If Wavelet is also specified
;      then the new wavelets will be appended onto the built-in wavelets.
;
; OUTPUTS:
;    None
;
; REFERENCE:
;    IDL Wavelet Toolkit Online Manual
;
; MODIFICATION HISTORY:
;    Written by CT, 1999
;-
;  Variable name conventions used herein:
;       r==Reference to Object
;		p==pointer
;       w==widget ID

PRO wv_import_wavelet, wavelets, $
	RESET=reset

	COMPILE_OPT strictarr

	COMMON cWvAppletData, $
		wCurrentApplet, $
		WaveletFamilies

; reset if desired
	IF KEYWORD_SET(reset) THEN BEGIN
		WaveletFamilies = ['Daubechies','Haar','Coiflet','Symlet', $
			'Morlet','Paul','Gaussian']
	ENDIF

; check size of wavelets & WaveletFamilies
	IF (N_ELEMENTS(wavelets) EQ 0) THEN RETURN
	IF (N_ELEMENTS(WaveletFamilies) EQ 0) THEN $
		WaveletFamilies = TEMPORARY(wavelets)

; loop thru wavelets, throw out duplicates
	FOR i=0,N_ELEMENTS(wavelets)-1 DO BEGIN
		exists = WHERE(STRUPCASE(WaveletFamilies) EQ STRUPCASE(wavelets[i]))
		IF (exists[0] EQ -1) THEN WaveletFamilies = $
			[WaveletFamilies, wavelets[i]]
	ENDFOR

	RETURN
END