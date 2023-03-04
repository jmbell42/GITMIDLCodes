;+
; NAME:
;   MGH_STRUCT_PRINT
;
; PURPOSE:
;   This procedure prints structure tag names and values.
;
; CALLING SEQUENCE:
;   MGH_STRUCT_PRINT, struct
;
; POSITIONAL PARAMETERS:
;   struct (input, structure)
;     The structure to be printed
;
; KEYWORD PARAMETERS:
;   UNIT (input, integer)
;     Logical unit number to which output is to be printed. Default is -1.
;
;###########################################################################
;
; This software is provided subject to the following conditions:
;
; 1.  NIWA makes no representations or warranties regarding the 
;     accuracy of the software, the use to which the software may 
;     be put or the results to be obtained from the use of the 
;     software.  Accordingly NIWA accepts no liability for any loss 
;     or damage (whether direct of indirect) incurred by any person 
;     through the use of or reliance on the software.
;
; 2.  NIWA is to be acknowledged as the original author of the 
;     software where the software is used or presented in any form.
;
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 2002-06:
;     Written.
;-

pro mgh_struct_print, struct, UNIT=unit

   compile_opt DEFINT32
   compile_opt STRICTARR

   if size(struct, /TYPE) ne 8 then message, 'Argument is not a structure'

   if n_elements(unit) eq 0 then unit = -1

   tags = tag_names(struct)

   for i=0,n_elements(tags)-1 do $
        printf, unit,'  ',strlowcase(tags[i]),': ', struct.(i)

end
