; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/xdl.pro#1 $
;
; Copyright (c) 1991-2006, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.
;+
; NAME:
;	XDL
;
; PURPOSE:
;	Provide a graphical user interface to the DOC_LIBRARY user
;	library procedure.  XDL is different from the "?" command under
;	X windows in that every "user library" type routine in the IDL
;	distribution is displayed in a single list.  Also, any ".pro" files
;	in the current directory are scanned for documentation headers and
;	put into the list if they are documented.
;
; CATEGORY:
;	Help, documentation, widgets.
;
; CALLING SEQUENCE:
;	XDL [, Name]
;
; OPTIONAL INPUTS:
;	Name:	A scalar string that contains the name of the initial routine
;		for which help is desired.  This argument should be a scalar
;		string.
; KEYWORDS:
;	GROUP:	The widget ID of the widget that calls XDL.  When
;		this keyword is specified, a death of the caller results in a
;		death of XDL.
;
; OUTPUTS:
;	No explicit outputs.  A widget interface is used to allow reading
;	the help text.
;
; COMMON BLOCKS:
;	XDL_BLOCK - Internal to this module.
;
; RESTRICTIONS:
;	This routine does not support many of the keywords supported
;	by the DOC_LIBRARY procedure.
;
;	This routine uses DOC_LIBRARY to do much of the actual work
;	of finding the documentation text.  The alternative would be
;	to duplicate much of DOC_LIBRARY, which is undesirable.  However,
;	the use of DOC_LIBRARY leads to messages sometimes being sent
;	to the terminal.
;
; MODIFICATION HISTORY:
;	5 January 1991, AB
;       9 January 1992, ACY for Jim Pendleton, NWU; handle invalid library
;	28 April 1992, AB, Modified to only search !PATH for routine names
;		on the first invocation. The names are saved in the XDL_BLOCK
;		common block, so that following invocations start much faster.
;	15 September 1991, ACY, Correct ls command for IRIX
;	20 February 1993 Updated for VMS directory Library W. Landsman
;	27 May 1993, TAC,  Send invalid OS message for Windows and Macintosh
;	25 June 1993, AB, Fixed error in call to DL_VMS, and shortened the
;		list and text widgets slightly to accomodate larger fonts.
;	1 July 1995, AB, Replaced use of XANNOUNCE with WIDGET_MESSAGE and
;		improved status label sizing.
;-




function xdl_list, parent
; Returns a list widget containing the names of all routines in !PATH.
; The array of names are saved in the XDL_BLOCK.
  common XDL_BLOCK, NAMES, N_NAMES, text_w, status_w

  if (n_elements(names) eq 0) then begin
    WIDGET_CONTROL, /HOURGLASS
    path = strcompress(!PATH, /remove_all)
    is_vms = !version.os eq 'vms'
    if (is_vms) then SEP=',' else SEP=':'
    N_NAMES = 0
    while (strlen(path) ne 0) do begin
      cpos = strpos(path, SEP)
      if (cpos eq -1) then begin
        item = path
        path = ''
      endif else begin
        item = strmid(path, 0, cpos)
        path = strmid(path, cpos+1, 32767)
      endelse
      if (is_vms) then begin
        if (strmid(item, 0, 1) eq '@') then begin
	  item = strmid(item, 1, 32767)
          spawn, 'LIBRARY/LIST/TEXT ' + item, tmp
          if (n_elements(tmp) lt 9) then $
             message, "Invalid Text Library", /traceback
          tmp = tmp(8:*)		; Skip the header. 9 is a magic #
        endif else begin
          tmp = FILE_SEARCH(item+'*.PRO')
          for i = 0, n_elements(tmp)-1 do begin		; Strip path and ext
            tmp1 = strmid(tmp(i), strpos( tmp(i), ']')+1, 32767 )
	    tail = STRPOS( tmp1, '.PRO' )
	    tmp(i) = strmid( tmp1, 0 , tail )
	  endfor
        endelse
      endif else begin
        if (!VERSION.OS EQ 'IRIX') then ls_com = '/bin/ls ' $
                                   else ls_com = '/bin/ls -1 '
        spawn, ls_com + item + '/*.pro', tmp
        tmp = strupcase(tmp)
        tail = STRPOS(tmp, '.PRO')
        for i = 0, n_elements(tmp)-1 do begin		; Strip path and ext
	  tmp1 = strmid(tmp(i), 0, tail(i))
	  j = STRPOS(tmp1, '/')
          while (j ne -1) do begin
	    tmp1 = strmid(tmp1, j+1, 32767)
	    j = STRPOS(tmp1, '/')
          endwhile
	  tmp(i) = tmp1
        endfor
      endelse
      if (N_NAMES eq 0) then begin
        names = tmp
      endif else begin
        names = [ names, tmp]
      endelse
      N_NAMES = N_NAMES + 1
    endwhile

    names = names(uniq(names, sort(names)))
  endif

  ; Fudge time. Different list lengths work best for OPEN LOOK and Motif
  version = WIDGET_INFO(/VERSION)
  if (version.style EQ 'OPEN LOOK') then n=22 else n = 30
  return, WIDGET_LIST(parent, value=names, ysize=n)

end







pro xdl_update, name
; Update the display by running DOC_LIBRARY on NAME and updating
; the text widget to reflect the results. The status widget is
; used to keep the user informed of progress.

  common XDL_BLOCK, NAMES, N_NAMES, text_w, status_w

  WIDGET_CONTROL, status_w, set_value='Status: Please Wait', /HOURGLASS

  name = strlowcase(name)
  is_vms = !version.os eq 'vms

  if (is_vms) then begin
    ON_ERROR, 3
    OFILE='userlib.doc'
    DL_VMS, NAME, /FILE, /NOFILEMSG
  endif else begin
    OFILE='/tmp/idl_xdl.tmp'
    DL_UNIX, NAME, print='cat > /tmp/idl_xdl.tmp'
  endelse

  openr, unit, OFILE, /get_lun, /stream, /delete, err=err
  if (err eq 0) then begin
    tmp = fstat(unit)
    text = bytarr(tmp.size)
    readu, unit, text
    free_lun, unit
  endif else begin
    text = 'Unable to locate routine: ' + strupcase(name)
  endelse

  WIDGET_CONTROL, text_w, set_value = string(text)
  WIDGET_CONTROL, status_w, set_value='Status: Ready'

end







pro xdl_event, ev

  common XDL_BLOCK, NAMES, N_NAMES, text_w, status_w

  case (tag_names(ev, /STRUCTURE_NAME)) of
  "WIDGET_BUTTON": WIDGET_CONTROL, /DESTROY, ev.top
  "WIDGET_LIST": begin
	XDL_UPDATE, NAMES(ev.index)
	end
  endcase


end







pro XDL, name, group=group

  common XDL_BLOCK, NAMES, N_NAMES, text_w, status_w

  on_error, 1		; On error, return to main level

  if (!version.os EQ 'Win32') then message, $
        'ERROR - XDL not supported under IDL for Windows'

  if (!version.os EQ 'MacOS') then message, $
        'ERROR - XDL not supported under IDL for Macintosh'
	
  REQ_PRESENT = N_ELEMENTS(NAME) ne 0
  if (REQ_PRESENT) then begin
    temp = size(NAME)
    if (temp(0) NE 0) then message, 'Argument must be scalar.'
    if (temp(1) NE 7) then message, 'Argument must be of type string.'
    if (STRLEN(STRCOMPRESS(NAME, /REMOVE_ALL)) eq 0) then REQ_PRESENT = 0
  endif

  if (!D.FLAGS and 65536) NE 65536 then message, $
        'ERROR - Current Device ' + !D.NAME + ' does not support widgets'
  new_instance = not xregistered('XDL')
  if (new_instance) then begin
    base = WIDGET_BASE(title='XDL', /ROW)
    do_announce = (WIDGET_INFO(/ACTIVE) eq 0) and (n_elements(names) eq 0)
    if (do_announce) then $
	junk = WIDGET_MESSAGE('Searching !PATH for routine names. This will take a few moments...')
    cntl1 = WIDGET_BASE(base, /FRAME, /COLUMN, space=30)
      pb_quit = WIDGET_BUTTON(value='Quit', cntl1)
      status_w = WIDGET_LABEL(cntl1, value='Status: Please Wait', /frame)
      geo = WIDGET_INFO(status_w, /GEOMETRY)
      WIDGET_CONTROL, status_w, set_value='Status: Ready', $
	              SCR_XSIZE=geo.scr_xsize
      junk = WIDGET_BASE(cntl1, /frame, /COLUMN)
        l = WIDGET_LABEL(junk, value='Library Routines')
        list = xdl_list(junk)
    text_w = WIDGET_TEXT(base, /SCROLL, xsize = 80, ysize=40)

    WIDGET_CONTROL, base, /REALIZE
  endif

  if (REQ_PRESENT) then xdl_update, name

  if (new_instance) then $
	XMANAGER, 'XDL', base, event_handler='XDL_EVENT', group=group
end

