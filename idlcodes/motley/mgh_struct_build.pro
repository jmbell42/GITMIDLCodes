;+
; NAME:
;   MGH_STRUCT_BUILD
;
; PURPOSE:
;   This function builds an anonymous structure, given a list of tag names
;   and a list of pointers to data values.
;
; CALLING SEQUENCE:
;   result = MGH_STRUCT_BUILD(tags, values, POINTER=pointer)
;
; POSITIONAL PARAMETERS:
;   tags (input, string array)
;     List of tag names
;
;   values (input, pointer array)
;     A list of values wrapped in pointers. Must have the same number
;     of elements as the tags array.
;
; KEYWORD PARAMETERS:
;   POINTER (input, switch)
;     Determines whether the output structure includes the data values
;     or pointers to them.
;
; PROCEDURE:
;   A command to create the structure is constructed and processed by
;   EXECUTE. To avoid "Program code area full" failures a limit is
;   placed on the number of tags created at one time; if this limit is
;   exceeded the structure is built up in a series of steps.
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
;   Mark Hadfield, 2000-11:
;     Written.
;   Mark Hadfield, 2005-09:
;     Added POINTER keyword.
;-

function mgh_struct_build, tags, values, POINTER=pointer

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Specify the maximum number of tags to be concatenated at one
   ;; time.  On my system (x86 Win32 Windows 5.4 Sep 25 2000) n_max
   ;; can be as large as 306.  Performance will be affected if n_max
   ;; is made too small but above 200 or so it makes little
   ;; difference.

   n_max = 200

   n_tags = n_elements(tags)

   if n_tags eq 0 then $
        message, 'Number of tags is zero'

   if n_elements(values) ne n_tags then $
        message, 'Number of values does not match number of tags'

   n0 = 0

   while n0 lt n_tags do begin

      n1 = (n0 + n_max - 1) < (n_tags - 1)

      cmd = n_elements(result) eq 0 ? 'result={' : 'result=create_struct(result,{'

      m = 0B
      for i=n0,n1 do begin
         if ~ mgh_str_isidentifier(tags[i]) then continue
         if ~ ptr_valid(values[i]) then message, 'Invalid pointer'
         if m then cmd += ','
         cmd += tags[i]+':'
         if ~ keyword_set(pointer) then cmd += '*'
         cmd += 'values['+strtrim(i,2)+']'
         m = 1B
      endfor

      cmd = n_elements(result) eq 0 ? cmd+'}' : cmd+'})'

      if ~ execute(cmd) then message, 'Command failed'

      n0 = n1 + 1

   endwhile

   return, result

end
