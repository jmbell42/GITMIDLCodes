;+
; NAME:
;   MGH_NCDF_FILL
;
; PURPOSE:
;   For a given netCDF variable type, this function returns the default fill
;   value, as specified in netcdf.h
;
; CALLING SEQUENCE:
;   result = mgh_ncdf_fill(type)
;
; POSITIONAL PARAMETERS:
;   type (input, string scalar)
;     A netCDF data type, as in the datatype field of the output ncdf_varinq.
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
;   Mark Hadfield, 2008-11:
;     Written.
;-
function mgh_ncdf_fill, type

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if size(type, /N_ELEMENTS) eq 0 then type = 'FLOAT'

   if size(type, /TYPE) ne 7 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'type'

   if size(type, /N_ELEMENTS) gt 1 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'type'

   case strupcase(type) of
      'BYTE'  : result = byte(-127)
      'CHAR'  : result = ''
      'SHORT' : result = -32767S
      'LONG'  : result = -2147483647L
      'FLOAT' : result = 9.9692099683868690E+36
      'DOUBLE': result = 9.9692099683868690D+36
   endcase

   return, result

end

