; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/chi_sqr1.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


function chi_sqr1,X,DF
;+
;
; NAME:
;	CHI_SQR1
;
; PURPOSE: 
;	CHI_SQR1 returns the probabilty of observing X or something smaller
;	from a chi square distribution with DF degrees of freedom.
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;	PROB = CHI_SQR1(X,DF)
;
; INPUTS:
;	X:	the cut off point
;	DF:	the degrees of freedom
;-

on_error,2 	; return to caller

if X le 0 THEN return,0 ELSE BEGIN
  gres = rsi_gammai(DF/2.0,x/2.0)
  if gres NE -1 then return, gres else return,-1
  END
end

