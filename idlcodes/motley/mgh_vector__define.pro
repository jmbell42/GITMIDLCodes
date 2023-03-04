;+
; CLASS NAME:
;   MGH_Vector
;
; PURPOSE:
;   This class implements a random-access container for heterogeneous
;   data. It is implemented using an array of pointers.
;
; PROPERTIES:
;   COUNT (Get):
;     The number of items currently stored in the vector.
;
;   SIZE (Init, Get, Set):
;     The capacity of the vector, i.e. the size of the pointer array
;     used to keep track of the items. The size can be changed via the
;     SetProperty method. If it is increased then the array is padded
;     with blank pointers; if it is reduced then any items beyond the
;     new size are deleted and their pointers freed.
;
; METHODS:
;   In addition to the usual suspects (Init, Cleanup, GetProperty,
;   SetProperty):
;
;     Add (Procedure):
;       This method adds a single item at the end of the vector and
;       increments the COUNT property. If this would exceed the
;       capacity of the vector, then the SIZE is increased; the
;       increase is always done in reasonably large chunks to avoid
;       performance degradation.
;
;     Count (Function):
;       This method takes no arguments and returns the COUNT property.
;
;     Get (Function):
;       This method retrieves a single item from a position specified
;       by the POSITION keyword. The default is POSITION=0. The item
;       is not removed from the vector. (There is no way of removing
;       items other than by reducing the SIZE).
;
;     Put (Procedure):
;       This method puts a new value into a position specified by the
;       POSITION keyword (default is POSITION=0). There must already
;       be a value stored at this location.
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
;   Mark Hadfield, 1999-10:
;       Written.
;   Mark Hadfield, 2000-11:
;       Added the Array method, which returns an array holding the
;       data.
;-

function MGH_Vector::Init, SIZE=size

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(size) eq 0 then size = 1000

   self.values = ptr_new(ptrarr(size))

   self.size = size

   return, 1

end

pro MGH_Vector::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ptr_valid(self.values) then $
        values = *self.values

   ptr_free, self.values

   for i=0,n_elements(values)-1 do $
        ptr_free, values[i]

end

pro MGH_Vector::GetProperty, COUNT=count, SIZE=size

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   count = self.count

   size = self.size

end

pro MGH_Vector::SetProperty, SIZE=size

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(size) gt 0 then begin

      delta = size - self.size

      case fix(delta gt 0) - fix(delta lt 0) of

         -1: begin
            values = *self.values
            ptr_free, self.values
            ptr_free, values[size:self.size-1]
            self.values = ptr_new(values[0:size-1])
            self.size = size
            self.count = self.count < self.size
         end

         0:

         1: begin
            values = *self.values
            ptr_free, self.values
            self.values = ptr_new([values, ptrarr(delta)])
            self.size = size
         end

      endcase

   endif

end

pro MGH_Vector::Add, value

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE
   
   if n_elements(value) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'value'

   if self.count ge self.size then $
        self->SetProperty, SIZE=(round(1.5*self.size) > (self.size+1000))

   (*self.values)[self.count] = ptr_new(value)

   self.count ++

end

; MGH_Vector::Array
;
;   Return an array holding a copy of the data. Default is to return
;   an array of pointers. If the VALUES keyword is set then return an
;   array of values--the data type is set by the first value and an
;   error will occur if any other value cannot be coerced into this
;   data type.

function MGH_Vector::Array, VALUES=values

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.count eq 0 then $
        message, 'The vector is empty'

   case keyword_set(values) of

      0: begin
         result = ptrarr(self.count)
         for i=0,self.count-1 do $
              result[i] = ptr_new(self->Get(POSITION=i))
      end

      1: begin
         result = replicate(self->Get(), self.count)
         for i=1,self.count-1 do $
              result[i] = self->Get(POSITION=i)
      end

   endcase

   return, result

end

function MGH_Vector::Count

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   return, self.count

end

function MGH_Vector::Get, POSITION=position

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.count le 0 then $
        message, 'The vector is empty'

   if n_elements(position) eq 0 then position = 0

   if position gt self.count-1 then $
        message, 'Position exceeds number of items'

   return, *(*self.values)[position]

end

pro MGH_Vector::Put, value, POSITION=position

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.count le 0 then $
        message, 'The vector is empty'

   if n_elements(position) eq 0 then position = 0

   if position gt self.count-1 then $
        message, 'Position exceeds number of items'

   ptr_free, (*self.values)[position]

   (*self.values)[position] = ptr_new(value)

end

function MGH_Vector::Values

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if self.count le 0 then $
        message, 'The vector is empty'

   return, (*self.values)[0:self.count-1]

end

pro MGH_Vector__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Vector, values: ptr_new(), count: 0L, size: 0L}

end

