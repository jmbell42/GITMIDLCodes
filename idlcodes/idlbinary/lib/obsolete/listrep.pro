; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/listrep.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


 pro ListRep,X,RowNum,Rows,here
; ListRep repairs a matrix that has had data thrown away in Listwise

  SX = size(X)
 SX1 = SX(1)

 
 count = N_Elements(RowNum)
 SX2 = SX(2)+count

 X1 = Fltarr( SX1,SX2)
 X1(*,here) =X
 X1(*,RowNum) = Rows
 X =X1

  return
 end
   