;+
; NAME:
;   MGH_STR_VANILLA
;
; PURPOSE:
;   Convert arbitrary string to vanilla form, suitable for file name.
;
; CATEGORY:
;   Strings.
;
; CALLING SEQUENCE:
;   result = MGH_STR_VANILLA(instr)
;
; POSITIONAL PARAMETERS:
;   instr (input, string scalar or array)
;     Input string(s).
;
; RETURN VALUE:
;   The function returns a string variable with the same shape as the
;   original, with all unsafe characters replaced with safe ones.
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
;   Mark Hadfield, 2005-02:
;     Written.
;-

function MGH_STR_VANILLA, instr

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(instr) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'instr'

   if size(instr, /TYPE) ne 7 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'instr'

   old = [' ',':','/','\','(',')','&','<','>']
   new = ['_','_','_','_','' ,'' ,'' ,'' ,'' ]

   result = instr

   for i=0,n_elements(old)-1 do $
        result = mgh_str_subst(temporary(result), old[i], new[i])

   return, result

end
