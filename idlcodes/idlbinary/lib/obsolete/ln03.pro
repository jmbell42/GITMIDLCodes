; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/ln03.pro#1 $
;
; Copyright (c) 1988-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

Pro LN03, Filename, To_terminal
;+
; NAME:
;	LN03
;
; PURPOSE:
;	Produce plot files suitable for printing by an LN03+ laser printer.
;
; CATEGORY:
;	Graphics.
;
; CALLING SEQUENCE:
;	LN03, Filename		;To start outputting plot codes to a file and
;				;the terminal.
;
;	LN03, Filename, 0	;Same as above, but don't send to terminal.
;
;	LN03			;To close the file.
;
; INPUTS:
;    Filename:	The name of the file to contain the plots.  The default 
;		extension is .LIS.
;
; To_terminal:	An optional parameter, which if present and 0, inhibits
;		sending the plots to the terminal.  Note: The terminal must
;		be a Tektronix compatible terminal.
;
; OUTPUTS:
;	No explicit outputs.
;
; COMMON BLOCKS:
;  LN03_COMMON:	This common block ontains the unit number and name of the 
;		graphics device to restore to when finished.
;
; SIDE EFFECTS:
;	A file is opened and closed.
;
; RESTRICTIONS:
;	Be sure to call LN03 to close the file after all the plots have
;	been produced.  If you don't, the file will not contain the escape
;	sequence to take the printer out of the Tektronix mode when done.
;
;	You can repeat this process as many times as you wish,
;	producing more than one file.
;
;	The plot files produced by IDL must be printed using a
;	special form:
;
;	For VMS, include the following command in your 
;	SYS$MANAGER:SYSTARTUP.COM file:
;
;		$ DEFINE /FORM PLOT 3 /NOWRAP /NOTRUNC /STOCK=DEFAULT
;
;	This command makes the form and assigns it to form number 3.
;	Of course, you can also define a symbol to accomplish
;	the same thing in your LOGIN.COM file:
;
;		$ PLOT :== PRINT /FORM=PLOT /PASSALL
;
;	Then, to print a plot file, enter:
;
;		$ PLOT EXAMPLE
;
;	Real VMS wizards may want to define a device-control library for the 
;	PLOT form to insert the escape sequences at the beginning to put 
;	the LN03+ into the Tektronix mode, and to revert to the normal mode.
;	In this case, you will have to remove the print statements in the LN03 
;	procedure that put these escape sequences in the output file.
;
;	For ULTRIX, we can make no specific recommendations, as the
;	printcap files vary greatly.  We suggest that you copy
;	your printcap entry to a new entry, called for example: "lntek"
;	Be sure that the pl and pw parameters are not set.  Also,
;	disable all output filters.  Use xc#0177777:xs#040 to disable
;	output translations.  Then to print a plot file, enter: 
;		lpr -Plntek file.
;
; PROCEDURE:
;	Opening Call:	Open the file, set the device to that of a TEK 4014 
;			printer, output the correct escape sequence.
;
;	Closing Call:	Restore the previous graphics device and send out the 
;			correct closing escape sequence before closing the 
;			file.
;
; MODIFICATION HISTORY:
;	DMS, March, 1988.
;	SMR, September, 1990.	Updated to work with V2 of IDL and included all
;			       	pertinent documentation in library header.
;-

common ln03_common, unit, restoredevice

if n_elements(unit) eq 0 then unit = 0	;First time?
esc = string(27b)		;Escape character
empty				;Empty graphics buffer.
n = n_params(0)			;# of params
if n lt 2 then to_terminal = 1	;Default = to terminal also

if n eq 0 then begin		;Close the file?
	if unit eq 0 then print,'LN03 - File not open for plots.' $
	else begin
;;;;		erase		;output the page
		printf,unit, esc+'[!p'	;Escape seq for out of tek mode
		device, /close	;Close file
		unit = 0	;Show closed.
		set_plot, restoredevice
	endelse
endif else begin		;Opening file:
	if unit ne 0 then print,'LN03 - File already open for plots.' $
	else begin		;Open it...
		get_lun, unit	;Get a lun
		openw,unit,filename, error = err, $
		      /none 			;Open output, no carr cont
		if(err eq 0) then begin 
			restoredevice = !D.name
			set_plot, 'tek'
			device, TEK4014 = 1	;use the maximum resolution
			printf, unit, esc + '[?38h' ;Into tek mode esc seq
			if (to_terminal eq 0) then device, plot_to = unit $
			else device, plot_to = -unit
		endif else begin
			unit = 0
			message, "Ln03 output file name should be a string"
		endelse
	endelse
endelse

end

