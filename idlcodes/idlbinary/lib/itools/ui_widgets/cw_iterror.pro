; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/ui_widgets/cw_iterror.pro#1 $
;
; Purpose:
;   An include file that can be used for error handling in
;   iTool compound widgets. The compound widget code should
;   look like:
;
;       nparams = 3
;       @cw_iterror
;
;   where nparams is the minimum number of arguments that
;   must be supplied to the routine.
;


; Include our customizable error handling.
@idlit_on_error2
@idlit_catch

if (ierr ne 0) then begin
    catch, /cancel
    ; Strip off subroutine prefix so we can add our own.
    msg = !error_state.msg
    pos = STRPOS(msg, ':')
    if (pos ge 0) then $
        msg = STRMID(msg, pos + 2)
    ; This will add our subroutine prefix.
    MESSAGE, msg
endif

; Check arguments. Note that nparams must be defined
; by the including routine.
if (N_PARAMS() lt nparams) then $
  MESSAGE, IDLitLangCatQuery('UI:WrongNumArgs')

if (~OBJ_VALID(oUI)) then $
  MESSAGE, IDLitLangCatQuery('UI:InvalidOUI')

