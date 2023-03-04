;+
; NAME:
;   MGH_DT_UNITS
;
; PURPOSE:
;   This function parses "units" descriptors for date-time data, see
;
;     http://my.unidata.ucar.edu/content/software/udunits/man.php?udunits+3
;
; CATEGORY:
;   Date-time.
;
; CALLING SEQUENCE:
;   Result = MGH_DT_UNITS(ustring)
;
; RETURN VALUE:
;   The function returns a structure containing tags "scale" and "offset"
;   that can be used to convert data-time data into a Julian Date.
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
;   Mark Hadfield, 2004-10:
;     Written.
;-

function MGH_DT_UNITS, ustring

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if size(ustring, /N_ELEMENTS) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'ustring'

   if size(ustring, /N_ELEMENTS) gt 1 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumelem', 'ustring'

   if size(ustring, /TYPE) ne 7 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrongtype', 'ustring'

   result = {scale: 0.D, offset: 0.D}

   ;; Split the string into components

   p = strpos(ustring, 'since')

   case p ge 0 of

      0B: s0 = ustring

      1B: begin
         s0 = strmid(ustring, 0, p+1)
         s1 = strmid(ustring, p+5)
      end

   endcase

   ;; Handle the units component

   case 1B of
      strmatch(s0, 'day*', /FOLD_CASE): begin
         result.scale = 1
      end
      strmatch(s0, 'hour*', /FOLD_CASE): begin
         result.scale = 1/24.D
      end
      strmatch(s0, 'second*', /FOLD_CASE): begin
         result.scale = 1/(24.D*3600.D)
      end
      else: begin
         result.scale = 1
      end
   endcase

   ;; Handle the base-date component. Special handling for year zero.

   if n_elements(s1) gt 0 then begin
      dts = mgh_dt_parse(strtrim(s1, 2))
      case dts.year of
         0: begin
            dts.year = 1
            result.offset = mgh_dt_julday(dts) - mgh_dt_julday(YEAR=dts.year)
         end
         else: begin
            result.offset = mgh_dt_julday(dts)
         end
      endcase
   endif

   return, result

end
