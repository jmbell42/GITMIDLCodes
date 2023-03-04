;+
; CLASS:
;   MGH_Command
;
; PURPOSE:
;   This class encapsulates a command (i.e. a statement, procedure or
;   procedure method) and its arguments.
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
;   Mark Hadfield, 2000-07:
;     Written as MGHdgCommand, based on concepts in David Fanning's
;     XWINDOW.
;   Mark Hadfield, 2001-06:
;     Added the ability to execute object methods.
;   Mark Hadfield, 2001-09:
;     Updated to IDL 5.5: keywords now passed to procedures using
;     _STRICT_EXTRA.
;   Mark Hadfield, 2002-09:
;     Increased maximum number of positional parameters to 4.
;-


; MGH_Command::Init
;
function MGH_Command::Init, command, p0, p1, p2, p3, $
     EXECUTE=execute, OBJECT=object, _EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(command) gt 0 then self.command = command

   self.execute = n_elements(execute) gt 0 ? execute : 0

   if self.execute then return, 1

   if n_elements(object) gt 0 then self.object = object

   self.n_params = 0

   if n_elements(p0) gt 0 then begin
      self.n_params = 1
      self.params[0] = ptr_new(p0)
      if n_elements(p1) gt 0 then begin
         self.n_params = 2
         self.params[1] = ptr_new(p1)
         if n_elements(p2) gt 0 then begin
            self.n_params = 3
            self.params[2] = ptr_new(p2)
            if n_elements(p3) gt 0 then begin
               self.n_params = 4
               self.params[3] = ptr_new(p3)
            endif
         endif
      endif
   endif

   if n_elements(extra) gt 0 then self.extra = ptr_new(extra)

   return, 1

end

; MGH_Command::GetProperty
;
pro MGH_Command::GetProperty, $
     ALL=all, COMMAND=command, EXECUTE=execute, KEYWORDS=keywords, N_PARAMS=n_params, $
     OBJECT=object, PARAMS=params

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   command = self.command

   execute = self.execute

   n_params = self.n_params

   object = self.object

   if arg_present(params) then begin
      case self.n_params of
         0:
         1: params = {param1: *self.params[0]}
         2: params = {param1: *self.params[0], param2: *self.params[1]}
         3: params = {param1: *self.params[0], param2: *self.params[1], $
                      param3: *self.params[2]}
      endcase
   endif

   if arg_present(keywords) && ptr_valid(self.extra) then $
        keywords = *self.extra

   if arg_present(all) then $
        all = {command:command, execute:execute, n_params:n_params, object:object}

end


; MGH_Command::Cleanup
;
pro MGH_Command::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   for i=0,self.n_params-1 do ptr_free, self.params[i]

   ptr_free, self.extra

end


; MGH_Command::Execute
;
pro MGH_Command::Execute

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if strlen(self.command) eq 0 then return

   case self.execute of

      0: begin

         case obj_valid(self.object) of

            0: begin
               case self.n_params of
                  0: begin
                     case ptr_valid(self.extra) of
                        0: call_procedure, self.command
                        1: call_procedure, self.command, _STRICT_EXTRA=*self.extra
                     endcase
                  end
                  1: begin
                     case ptr_valid(self.extra) of
                        0: call_procedure, self.command, $
                             *self.params[0]
                        1: call_procedure, self.command, $
                             *self.params[0], _STRICT_EXTRA=*self.extra
                     endcase
                  end
                  2: begin
                     case ptr_valid(self.extra) of
                        0: call_procedure, self.command, $
                             *self.params[0], *self.params[1]
                        1: call_procedure, self.command, $
                             *self.params[0], *self.params[1], _STRICT_EXTRA=*self.extra
                     endcase
                  end
                  3: begin
                     case ptr_valid(self.extra) of
                        0: call_procedure, self.command, $
                             *self.params[0], *self.params[1], $
                             *self.params[2]
                        1: call_procedure, self.command, $
                             *self.params[0], *self.params[1], $
                             *self.params[2], _STRICT_EXTRA=*self.extra
                     endcase
                  end
                  4: begin
                     case ptr_valid(self.extra) of
                        0: call_procedure, self.command, $
                             *self.params[0], *self.params[1], $
                             *self.params[2], *self.params[3]
                        1: call_procedure, self.command, $
                             *self.params[0], *self.params[1], $
                             *self.params[2], *self.params[3], _STRICT_EXTRA=*self.extra
                     endcase
                  end
               endcase
            end

            1: begin
               case self.n_params of
                  0: begin
                     case ptr_valid(self.extra) of
                        0: call_method, self.command, self.object
                        1: call_method, self.command, self.object, $
                             _STRICT_EXTRA=*self.extra
                     endcase
                  end
                  1: begin
                     case ptr_valid(self.extra) of
                        0: call_method, self.command, self.object, $
                             *self.params[0]
                        1: call_method, self.command, self.object, $
                             *self.params[0], _STRICT_EXTRA=*self.extra
                     endcase
                  end
                  2: begin
                     case ptr_valid(self.extra) of
                        0: call_method, self.command, self.object, $
                             *self.params[0], *self.params[1]
                        1: call_method, self.command, self.object, $
                             *self.params[0], *self.params[1], _STRICT_EXTRA=*self.extra
                     endcase
                  end
                  3: begin
                     case ptr_valid(self.extra) of
                        0: call_method, self.command, self.object, $
                             *self.params[0], *self.params[1], $
                             *self.params[2]
                        1: call_method, self.command, self.object, $
                             *self.params[0], *self.params[1], $
                             *self.params[2], _STRICT_EXTRA=*self.extra
                     endcase
                  end
                  4: begin
                     case ptr_valid(self.extra) of
                        0: call_method, self.command, self.object, $
                             *self.params[0], *self.params[1], $
                             *self.params[2], *self.params[2]
                        1: call_method, self.command, self.object, $
                             *self.params[0], *self.params[1], $
                             *self.params[2], *self.params[2], _STRICT_EXTRA=*self.extra
                     endcase
                  end
               endcase
            end

         endcase

      end

      1: ok = execute(self.command)

   endcase

end

; MGH_Command::String
;
function MGH_Command::String

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   result = (self.execute ? 'EXECUTE:' : 'PROCEDURE:') + ' ' + self.command

   if obj_valid(self.object) then $
        result += mgh_obj_string(self.object) + ' '

   for i=0,self.n_params-1 do $
         result += ', ' + self->_ValueToString(*self.params[i])

   if ptr_valid(self.extra) then begin

      extra = *self.extra

      names = tag_names(extra)

      result += ', {'

      for i=0,n_elements(names)-1 do begin
         if i gt 0 then result += ', '
         result += names[i] + ': ' + self->_ValueToString(extra.(i))
      endfor

      result += '}'

   endif

   return, result

end


; MGH_Command::_ValueToString
;
function MGH_Command::_ValueToString, param

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   compile_opt HIDDEN

   n_dims = size(param, /N_DIMENSIONS)

   case n_dims gt 0 of

      0: return, strtrim(param,2)

      1: begin
         dims = size(param, /DIMENSIONS)
         return, size(param, /TNAME) + '[' + strjoin(strtrim(dims,2), ',') + ']'
      end

   endcase

end


pro MGH_Command__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Command, execute: 0B, object: obj_new(), command: '', $
                 n_params: 0L, params: ptrarr(4), extra: ptr_new()}

end


