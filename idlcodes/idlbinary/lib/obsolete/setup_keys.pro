; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/setup_keys.pro#1 $
;
; Copyright (c) 1989-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

;+
; NAME:
;	SETUP_KEYS
;
; PURPOSE:
;	Set up function keys for use with IDL.
;
;	Under Unix, the number of function keys, their names, and the
;	escape sequences they send to the host computer vary
;	enough between various keyboards that IDL cannot be
;	written to understand all keyboards.  Therefore, it provides
;	a very general routine named DEFINE_KEY that allows the
;	user to specify the names and escape sequences of function keys.
;
;	SETUP_KEYS uses user input (via keywords), the TERM environment
;	variable and the type of machine the current IDL is running on
;	to determine what kind of keyboard you are using, and then uses
;	DEFINE_KEY to enter the proper definitions for the function keys.
;
;	The need for SETUP_KEYS has diminished in recent years because
;	most Unix terminal emulators have adopted the ANSI standard for
;	function keys, as represented by VT100 terminals and their many
;	derivatives, as well as xterm and the newer CDE based dtterm.
;	The current version of IDL already knows the function keys of such
;	terminals, so SETUP_KEYS is not required. However, SETUP_KEYS is
;	still needed to define keys on non-ANSI terminals such as the
;	Sun shelltool, SGI iris-ansi terminal emulator, or IBM's aixterm.
;
; CATEGORY:
;	Misc.
;
; CALLING SEQUENCE:
;	SETUP_KEYS
;
; INPUTS:
;	None.
;
; KEYWORD PARAMETERS:
;	NOTE:  If no keyword is specified, SETUP_KEYS uses the TERM
;	environment variable and !VERSION to make an educated guess of
;	the keyboard being used. This guess is not foolproof, but is
;	usually correct).
;
;	ANSI:
;	VT200:	Establish function key definitions for a DEC VT200. The
;		VT200 is a superset of the ANSI standard and can be used
;		for ANSI based terminal emulators such as xterm.
;
;
;     EIGHTBIT:	When establishing VT200 function key definitions,
;		use the 8-bit versions of the escape codes instead
;		of the default 7-bit.
;	HP9000:	Establish function key definitions for an HP 9000 series
;		300 keyboard.  Although the HP 9000 series 300 supports both
;		xterm and hpterm windows, IDL supports only user-definable
;		key definitions in xterm windows - hpterm windows use
;		non-standard escape sequences which IDL does not attempt
;		to handle.
;
;	IBM	Establish function key definitions for an IBM keyboard.
;
;	MIPS:	Establish function key definitions for a Mips RS series
;		keyboard.
;
;	SGI:	Establish function key definitions for SGI keyboards.
;
;	SUN:	Establish function key definitions for a Sun shelltool
;		terminal emulator, as well as some definitions for the
;		obsolete Sun3 keyboard.
;
;
;  APP_KEYPAD:	Will define escape sequences for the group of keys
;		in the numeric keypad, enabling these keys to be programmed
;		within IDL.
;
;  NUM_KEYPAD:	Will disable programmability of the numeric keypad.
;
; OUTPUTS:
;	None.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	The definitions for the function keys are entered.  The new keys
;	can be viewed using the command HELP, /KEYS.
;
; MODIFICATION HISTORY:
;	AB, 26 April 1989
;	TJA, July 1990.	Added key definitions for HP 9000 series 300, as
;			well as Mips RS series; also rearranged code into 
;			separate files.
;
;	SMR, April, 1991.  Added key definitions for SGI and PSTERM
;	AB, 22 November 1994, Added key definitions for IBM.
;	AB, 5 March 1997, Update for the current state of keyboards, which
;		increasingly emulate ANSI behavior. This simplifies things.
;		Added the ANSI keyword. Removed the PSTERM keyword because
;		Sun's psterm program no longer exists. Added code that uses
;		the TERM environment variable to better diagnose the keyboard.
;		General cleanup.
;-

PRO setup_keys, ANSI=ANSI, HP9000 = HP9000, IBM = IBM, MIPS = MIPS, $
	SGI = SGI, SUN = SUN, VT200 = VT200, _EXTRA=EXTRA

ON_ERROR,2                              ;Return to caller if an error occurs

; The GUI based front ends don't use this mechanism. Quietly return instead
; of throwing an error so that people who use both can call this from
; their startup files.
if ((FSTAT(0)).isagui ne 0) then return

; VMS has a tty based interface available, but the keys are fixed.
IF (!VERSION.OS EQ 'vms') THEN $
  MESSAGE, 'VMS key names are "pre-set" by the Screen Management Utility.'


; Decide what kind of keyboard were defining. The rules used to pick this
; are:
;	1) If the user indicates the keyboard using a keyword, use that.
;	2) If the TERM environment variable is a type we understand, use
;	   that. This allows us to work with terminal emulators displaying
;	   across a network.
;	3) If !VERSION.OS indicates a keyboard that is a unique special case
;	   that we understand, use that. This is better than a blind guess.
;	4) If all else fails, assume it is an ANSI keyboard.
term = GETENV('TERM')
os = !version.os
case  1 of
  KEYWORD_SET(ANSI)	: cmd = 'SKEY_DEC'
  KEYWORD_SET(HP9000)	: cmd = 'SKEY_HP'
  KEYWORD_SET(IBM)	: cmd = 'SKEY_IBM'
  KEYWORD_SET(MIPS)	: cmd = 'SKEY_MIPS'
  KEYWORD_SET(SUN) 	: cmd = 'SKEY_SUN'
  KEYWORD_SET(VT200)	: cmd = 'SKEY_DEC'
  KEYWORD_SET(SGI)	: cmd = 'SKEY_SGI'

  (term eq 'xterm') or (term eq 'dtterm') : cmd = 'SKEY_DEC'
  (term eq 'iris-ansi') : cmd = 'SKEY_SGI'
  (term eq 'aixterm')	: cmd = 'SKEY_IBM'
  (term eq 'hpterm')	: cmd = 'SKEY_HP'

  (os eq 'sunos')	: cmd = 'SKEY_SUN'
  (os eq 'hp-ux')	: cmd = 'SKEY_HP'
  (os eq 'IRIX')	: cmd = 'SKEY_SGI'
  (os eq 'AIX')		: cmd = 'SKEY_IBM'

  else			: cmd = 'SKEY_DEC'
ENDCASE

; Call the appropriate sub-module to do the work
if (n_elements(extra) eq 0) THEN BEGIN
  CALL_PROCEDURE, cmd
endif else begin
  CALL_PROCEDURE, cmd, _extra=extra
ENDELSE

END
