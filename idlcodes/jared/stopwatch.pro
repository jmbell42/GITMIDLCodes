;+
; NAME:
;	stopwatch
; PURPOSE:
; CATEGORY:
;	Totally unnecessary
; CALLING SEQUENCE:
	PRO stopwatch, set=set, start=start, stop=stop
; INCLUDE:
	@compile_opt.pro		; On error, return to caller
; CALLS:
;	IsType, InitVar, TimeGet, TimeSystem, TimeUnit, TimeOp
; COMMON:
	common	stopwatch_start_time, save_start
; MODIFICATION HISTORY:
;	JUL-2003, Paul Hick (UCSD/CASS)
;-
InitVar, set, /key

CASE set OF
1: BEGIN
	CASE IsType(start, /defined) OF
	0: save_start = TimeSystem(/silent)
	1: save_start = start
	ENDCASe

	message,/info, 'started at '+TimeGet(save_start, /ymd)
END
0: BEGIN
	IF IsType(start,/undefined) THEN BEGIN
    		IF IsType(save_start,/undefined) THEN stopwatch, /set
    		start = save_start
	ENDIF

    	IF IsType(stop,/undefined) THEN stop = TimeSystem(/silent)

	print, 'Start : '+TimeGet(start, /ymd)
	print, 'Stop  : '+TimeGet(stop , /ymd)
	print, 'Diff  : '+TimeOp(/subtract,stop,start,TimeUnit(/sec))+' seconds'
	
END
ENDCASE

RETURN  &  END
