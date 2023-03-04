;+
; FUNCTION:
;   MGH_IS_CALLBACK
;
; PURPOSE:
;   This function determines whether a variable represents a widget
;   callback, in the sense used elsewhere in my widget code. The
;   function has been created and given its name to allow clearer
;   event-handling code.
;
; CALLING SEQUENCE:
;   Result = mgh_is_callback(value)
;
; POSITIONAL PARAMETERS:
;   var (input)
;     The variable to be examined.
;
; RETURN VALUE:
;   This function returns 1 if the variable is a single-element
;   MGH_WIDGET_CALLBACK structure, otherwise 0.
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
;   Mark Hadfield, Jun 2001:
;       Written.
;-
function MGH_IS_CALLBACK, value

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(value) eq 1 then begin
      if size(value, /TYPE) eq 8 then begin
         if tag_names(value, /STRUCTURE_NAME) eq 'MGH_WIDGET_CALLBACK' then begin
            return, 1B
         endif
      endif
   endif

   return, 0B

end


