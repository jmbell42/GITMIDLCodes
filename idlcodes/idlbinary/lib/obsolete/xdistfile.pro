; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/xdistfile.pro#1 $
;
; Copyright (c) 1994-2006, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.

PRO XDistfile, FILENAME, SUBDIRECTORY, _EXTRA=extra
;+
; NAME: 
;	XDISTFILE
;
; PURPOSE:
;	Displays ASCII text files from the IDL distribution. 
;	This file used to handle IDL routines in VMS text libraries, 
;	but is now a very thin wrapper to XDISPLAYFILE.
;
; CATEGORY:
;	Widgets.
;
; CALLING SEQUENCE:
;	XDISTFILE, Filename, Subdirectory
;
; INPUTS:
;     Filename:	A scalar string that contains the filename of the file
;		to display NOT INCLUDING the '.pro' extension or any
;		path information.
;     Subdirectory: Subdirectory information in the style of the
;		FILEPATH user library routine.
;
; KEYWORD PARAMETERS:
;	Any keywords allowed by XDISPLAYFILE are also allowed.
;
; OUTPUTS:
;	No explicit outputs.  A file viewing widget is created.
;
; SIDE EFFECTS:
;	Triggers the XMANAGER if it is not already in use.
;
; RESTRICTIONS:
;	None.
;
; PROCEDURE:
;	This is a thin wrapper over the XDISPLAYFILE routine.
;
; MODIFICATION HISTORY:
;	1 June 1994, AB
;	30 June, 2001, SM
;-

  XDISPLAYFILE, FILEPATH(filename + '.pro', SUBDIRECTORY=SUBDIRECTORY), $
			 _extra=extra

END
