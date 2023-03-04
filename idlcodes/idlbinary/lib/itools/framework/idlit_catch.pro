;; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/framework/idlit_catch.pro#2 $
;;
;; Purpose:
;;   An include file that can be used to turn on/off all
;;   catches in the iTools system. To use this setting,
;;   a catch statement in code would look like:
;;     @idlit_catch
;;        if(iErr ne 0)then ...
;;
;; Use:
;;   To control the catch settings, just uncomment, comment the
;;   below lines.
;;
;; Include file to turn on and off catch throughout the system.

;; Uncomment to turn on catch, comment to turn off
   catch, iErr

;; Uncomment to turn off catch, comment to turn on
;   iErr = 0
