; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/msg_cat_compile.pro#1 $
;
; Copyright (c) 1998-2006, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.
;
;+
; NAME:
;	MSG_CAT_COMPILE
;
; PURPOSE:
;	This procedure creates an IDL language catalog file from an input file.
;
; CATEGORY:
;	Internationalization
;
; CALLING SEQUENCE:
;	MSG_CAT_COMPILE, input[, output]
;
; INPUTS:
;	input - The language source file.
;
; OUTPUTS:
;	output - The IDL language catalog file. (optional)
;
; EXAMPLE:
;   MSG_CAT_COMPILE,'idl_envi_usa_eng.src','idl_envi_usa_eng.cat'
;
; MODIFICATION HISTORY
;	Written by:	Scott Lasica,  11/11/98
;-

PRO MSG_CAT_COMPILE, source, outfile, VERBOSE=verbose, MBCS=mbcs, $
	LOCALE_ALIAS = locale_alias

	on_error, 2

	;; Adding this in case there's an error deleting the temp files
	cd,current=currDir

	;;Open two temp files that will be used in processing
    OPENW, IDX_FILE, filepath('lang_cat.idx', /TMP), /GET_LUN, /DELETE
    OPENW, TXT_FILE, filepath('lang_cat.txt', /TMP), /GET_LUN, /DELETE

	;;Set current position in the file
	TXT_POS = 0L
	idx_offset = 0L
	if (!version.os_family eq 'Windows') then platform_cr = 2 else $
		platform_cr = 1
	magic_number = "IDL_I18N_Language_Catalog_"

	;;Get some filenames, either a source file or a listing of the source
	;;code files in the supplied directory.
	OPENR, IN_FILE, source, /GET_LUN
	point_lun, in_File, 0

	if (KEYWORD_SET(verbose)) then print,'Reading file...'

	num_keys = 0L
	;; First pass, just see how many lines there are
	while(not EOF(IN_FILE))do begin
		tmp = ''
		READF, IN_FILE, TMP
		if (tmp ne '') then $
			num_keys = num_keys + 1
	endwhile

	;; This is for our internal file format version number & locale
	num_keys = num_keys + 2

	;; This is because the IDL array concatination is SLOW
	keys = strarr(num_keys)
	theStrings = strarr(num_keys)

	app_found = 0
	point_lun, IN_FILE, 0
	i=2
	while(not EOF(IN_FILE))do begin
		tmp = ''
		READF, IN_FILE, TMP
		;; Here we need worry about having double quotes in the string itself
		if (tmp ne '' ) then begin
			embed_check = STRTOK(tmp, '""', /EXTRACT, /REGEX)
			if (N_ELEMENTS(embed_check) eq 1) then begin
				;; Use double quotes to delimit
				key_str = STRTOK(tmp, '"',/EXTRACT)
				if (N_ELEMENTS(key_str) ne 1) then begin
					keys[i] = STRTRIM(key_str[0], 2)
					theStrings[i] = key_str[1]
				endif
			endif else begin
				startString = STRPOS(tmp,'"')
				endString = STRPOS(tmp,'"', /REVERSE_SEARCH)
				keys[i] = STRTRIM(STRMID(tmp,0,startString),2)
				theStrings[i] = STRMID(tmp,startString+1,(endString-startString)-1)
			endelse
			if (keys[i] eq 'APPLICATION') then app_found = i
		i = i + 1
		endif
	endwhile

	if (app_found eq 0) then begin
		message,'ERROR:  Key APPLICATION must be included in input file.'
		free_lun,txt_file, idx_file, in_file
		return
	endif

	keys[0] = 'IDL_I18N_VERSION'
	theStrings[0] = '1.0'
	keys[1] = 'LOCALE'
	theStrings[1] = LOCALE_GET()
	if (N_ELEMENTS(locale_alias) eq 1) then begin
		if (SIZE(locale_alias,/TYPE) eq 7) then $
			theStrings[1] = theStrings[1] + ';'+locale_alias
	endif

	if (KEYWORD_SET(verbose)) then print,'Writing temporary files...'
	;;Begin a while loop that tests for EOF.
	for i=0,num_keys-1 do begin
		TMP_POS = TXT_POS
		out_idx = STRING(keys[i], ' ', TMP_POS, FORMAT='(A,A,I0)')
		out_txt = theStrings[i]
		printf, idx_file, out_idx
		printf, txt_file, out_txt
		idx_offset = idx_offset + (strlen(out_idx) > 1) + platform_cr
		TXT_POS = TXT_POS + (STRLEN(out_txt) > 1) + platform_cr
	endfor

	FREE_LUN, IN_FILE

	POINT_LUN, IDX_FILE, 0
	POINT_LUN, TXT_FILE, 0

	;;Now to build the final file
	if (N_ELEMENTS(outfile) eq 0) then begin
		outfile = 'idl_'+STRCOMPRESS(LOCALE_GET(),/REMOVE_ALL)+'.cat'
	endif
	OPENW, final_file, outfile, /STREAM ,/GET_LUN

	;; NOTE: carriage returns are 2 bytes!!!!
	idx_offset = idx_offset + strlen(STRTRIM(STRING(num_keys),2))+platform_cr +$
		strlen(magic_number+theStrings[app_found])+platform_cr +$
		strlen(theStrings[1])+platform_cr
	idx_offset = idx_offset + strlen(STRTRIM(STRING(idx_offset),2))+platform_cr

	if (KEYWORD_SET(verbose)) then print,'Writing output file...'
	;; First write the "magic number"
	printf, final_file, magic_number+theStrings[app_found]
	printf, final_file, theStrings[1]

	;; This tells us how many keys are in the file
	printf, final_file, STRTRIM(STRING(num_keys),2)
	printf, final_file, STRTRIM(STRING(idx_offset),2)

    WHILE(not EOF(IDX_FILE)) DO BEGIN
		READF, IDX_FILE, TMP
		PRINTF, FINAL_FILE, TMP
    ENDWHILE

	if (idx_file ne -1) then $
		close, idx_file
	FREE_LUN, IDX_FILE

	TMP = ''

	;;Now the text file
	WHILE(not EOF(TXT_FILE)) DO BEGIN
		READF, TXT_FILE, TMP
		PRINTF, FINAL_FILE, TMP
	ENDWHILE

	close, txt_file
	close, final_file

	FREE_LUN, TXT_FILE, FINAL_FILE

	cd,currDir
END



