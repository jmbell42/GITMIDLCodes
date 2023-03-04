; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/skey_ibm.pro#1 $
PRO skey_ibm
;
; Copyright (c) 1994-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:         SKEY_IBM
; PURPOSE:      Under Unix, the number of function keys, their names, and the
;               escape sequences they send to the host computer vary
;               enough between various keyboards that IDL cannot be
;               written to understand all keyboards. Therefore, it provides
;               a very general routine named DEFINE_KEY that allows the
;               user to specify the names and escape sequences. This
;               routine uses DEFINE_KEY to enter the keys for a Sun 
;		keyboard.
;
;               Note: SKEY_IBM is primarily designed to be called by
;               SETUP_KEYS, which attempts to automatically detect the 
;		correct
;               keyboard type in use, and define the keys accordingly.
;               Nonetheless, SKEY_IBM may be called as a standalone
;               routine.
;
; CATEGORY:     Misc.
; CALLING SEQUENCE:
;       SKEY_IBM
; INPUTS:
;       None.
; KEYWORD PARAMETERS:
;       None.
; OUTPUTS:
;       None.
; COMMON BLOCKS:
;       None.
; SIDE EFFECTS:
;
;       The definitions for the function keys have been entered, and
;       can be viewed using HELP,/KEYS .
; MODIFICATION HISTORY:
;       ACY, Oct 1994, skey_ibm created, based on skey_sgi
;-
COMPILE_OPT hidden	; Public entry point is SETUP_KEYS

  ; F1-F5 (escape sequences 11-15)
  FOR i = 1,5 DO begin
    define_key, 'F' + STRTRIM(i,2), $
        ESCAPE = string(27B) + '[' + STRTRIM(i+10,2) + '~'
  ENDFOR

  ; F6-F10 (escape sequences 17-21)
  FOR i = 6,10 DO begin
    define_key, 'F' + STRTRIM(i,2), $
        ESCAPE = string(27B) + '[' + STRTRIM(i+11,2) + '~'
  ENDFOR

  ; F11-F12 (escape sequences 23-24)
  FOR i = 11,12 DO begin
      define_key, 'F' + STRTRIM(i,2), $
          ESCAPE = string(27B) + '[' + STRTRIM(i+12,2) + '~'
  ENDFOR

END     ; ibm keyboard
