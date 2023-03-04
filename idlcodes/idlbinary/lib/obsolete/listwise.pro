; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/listwise.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


 Function ListWise,Data,MV,RowNum, Rows,here
 
 ;ListWise returns an array identical to Data modulo the rows containing
 ; the missing data value, MV. Data must be a 2D array. Here is a list of
 ; excluded rows. Rows is an array of excluded rows.

 SD=Size(Data)
 C=SD(1)
 R= SD(2)


 here=[0]
 RowNum = [0]
 Row = [0]
 for i=0,R-1 DO BEGIN
     V=Where(Data(*,i) EQ MV,count)
     if( count EQ 0) THEN  here=[here,i] else BEGIN
       RowNum = [RowNUM,i]
       Row   = [Row,Data(*,i)]
     ENDELSE
 ENDFOR
 if n_elements(here) le 1 THEN  return, -1 
 here = here(1:*) 
 if (N_Elements(Row)) eq 1 then $ ;no missing values 
   return, Data
 RowNum = RowNum(1:*)
 Rows   = Fltarr(C,N_Elements(RowNum))
 Row    = Row(1:*)
 Rows(0:*,0:*)  = row 
 return,Data(*,here)
 END