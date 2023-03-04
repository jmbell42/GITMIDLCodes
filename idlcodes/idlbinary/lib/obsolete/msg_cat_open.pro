; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/msg_cat_open.pro#1 $
;
; Copyright (c) 1998-2006, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.
;
;+
; NAME:
;	MSG_CAT_OPEN
;
; PURPOSE:
;	This function will return a current catalog if it exists, or create a new one.
;
; CATEGORY:
;	Internationalization
;
; CALLING SEQUENCE:
;	Result = MSG_CAT_OPEN(application)
;
; INPUTS:
;	application - A scalar string representing the name of the desired application's
;      catalog file.
;
; KEYWORD PARAMETERS:
;	DEFAULT_FILENAME - Set this keyword to a scalar string containing the full path
;      and filename of the catalog file to open if the initial request was not found.
;
;	FILENAME - Set this keyword to a scalar string containing the full path and filename
;      of the catalog file to open.  If this keyword is set, application, path and locale
;      are ignored.
;
;	FOUND - Set this keyword to a named variable that will contain 1 if a catalog file
;      was found, 0 otherwise.
;
;	LOCALE - Set this keyword to the desired locale (string) for the catalog file.  If not
;      set, the current OS locale is used.
;
;	PATH - Set this keyword to a scalar string containing the path to search for language
;      catalog files.  The default is the current directory.
;
;	SUB_QUERY - Set this keyword equal to the value of the SUB_QUERY to search against.
;	   If a match is found, it is used to further sub-set the possible return catalog
;      choices.
;
; OUTPUTS:
;	Returns an object reference to an IDLffLanguageCat.
;
; EXAMPLE:
;	catalog = MSG_CAT_OPEN('ENVI_3.1', SUB_QUERY='Open dialog', FOUND=found)
;
; MODIFICATION HISTORY
;	Written by:	Scott Lasica,  11/20/98
;-

FUNCTION MSG_CAT_OPEN, application, FILENAME=filename, LOCALE=locale, PATH=path, $
	SUB_QUERY = sub_query, DEFAULT_FILENAME = defFilename, FOUND=found

	common I18N_CATALOG_COMMON, oCats, refCnt

	on_error, 2

	oCat = OBJ_NEW()
	if (N_ELEMENTS(refCnt) eq 0) then refCnt = 0
	if (N_ELEMENTS(defFilename) eq 0) then defFilename=''
	found = 1

	;; Check to see if it's cached
	if (N_ELEMENTS(oCats) gt 0) then begin
		for i=0,N_ELEMENTS(oCats)-1 do begin
			if (OBJ_VALID(oCats[i])) then begin
				if (N_ELEMENTS(filename) gt 0) then begin
					if (oCats[i]->GetFilename() eq filename) then begin
						oCat = oCats[i]
						goto, skip_out
					endif
				endif else begin
					if (oCats[i]->Query('APPLICATION') eq application) then begin
						if (N_ELEMENTS(sub_query) gt 0) then begin
							if (oCats[i]->Query('SUB_QUERY') ne sub_query) then $
								goto, skip
						endif

						if (N_ELEMENTS(locale) gt 0) then begin
							if (oCats[i]->Query('LOCALE') eq locale) then begin
								oCat = oCats[i]
								goto, skip_out
							endif
						endif else begin
							if (oCats[i]->Query('LOCALE') eq LOCALE_GET()) then begin
								oCat = oCats[i]
								goto, skip_out
							endif
						endelse
					endif
				endelse
			endif
			skip:
		endfor
	endif
skip_out:

	if (not OBJ_VALID(oCat)) then begin
		oCat = OBJ_NEW('IDLffLanguageCat')
		if (N_ELEMENTS(oCats) gt 0) then $
			oCats = [oCats, oCat] $
		else $
			oCats = oCat
		if(not oCat->SetCatalog(application, FILENAME=filename, LOCALE=locale, $
			PATH=path)) then begin
			if (not oCat->SetCatalog(FILENAME=defFilename)) then begin
				found = 0
				return, oCat
			endif
		endif
	endif

	refCnt = n_elements(oCats)
	return, oCat
END
