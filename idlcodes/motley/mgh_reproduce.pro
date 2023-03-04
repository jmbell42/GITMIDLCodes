;+
; NAME:
;   MGH_REPRODUCE
;
; PURPOSE:
;   Replicate by example: replicates a scalar value into an array
;   (or scalar) with size & dimensions copied from a template
;   array. Useful for generating structure arrays in procedures.
;
; CATEGORY:
;   Array manipulation. Structures.
;
; CALLING SEQUENCE:
;   Result = MGH_REPRODUCE(value, template)
;
; POSITIONAL PARAMETERS:
;   value (input, any type and size)
;     Data to be replicated. Dimensions are ignored and only the first
;     element is used.
;
;   template (input, any type and size)
;     Supplies dimensions.
;
; RETURN VALUE:
;   This function returns a variable with the same type as Value and the
;   same organisation as Template.
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
;   Mark Hadfield, Oct 1993:
;     Written, based on ideas in one of Bill Thompson's procedures.
;   Mark Hadfield, Jun 1995:
;     Modified to treat one-element template arrays correctly.
;   Mark Hadfield, 2003-08:
;     Simplified this routine substantially using newer IDL type inquiry and
;     creation functions.
;-

function MGH_REPRODUCE, value, template

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(value) eq 0 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'value'

   if n_elements(template) eq 0 then $
      message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'template'

   case size(template, /N_DIMENSIONS) gt 0 of
      0B: return, value[0]
      1B: return, make_array(VALUE=value[0], DIMENSION=size(template, /DIMENSIONS))
   endcase

end
