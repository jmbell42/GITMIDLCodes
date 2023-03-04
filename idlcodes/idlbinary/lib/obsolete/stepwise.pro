; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/stepwise.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


  pro writereport,X,Y,V,Enter,direction,RepType,unit
;Writereportprints out 

 printf,unit," "
 printf,unit," "
 printf,unit," "
 printf,unit,RepType," Report"
 printf,unit,direction ,Enter
 printf,unit,""
 regression,X,Y,VarNames=V,Unit=unit
 return
 end


function setnames,vn,N,unit
; if vn is an array with n names , simply return vn,else
; pad out vn with var i.

 NC=Size(vn)

 if(NC(1) NE 0 ) THEN BEGIN        ; 
   VarName=vn
   if(NC(1) LT N) THEN BEGIN
     printf,unit,'stepwise-missing Variable names'
     I=Indgen(N)
     VarName=[VarName,'Var'+STRTRIM(I(NC(1):N-1),2)]
   ENDIF
 ENDIF ELSE VarName='Var'+ STRTrim(INDgen(N),2)

 return,VarName
 END


function mult_cor,A,index,k
return, A(k,k) - A(index,k)*A(k,index)/A(index,index)
end



pro InsertVar,A,index,k

 mult0 = 1.0/A(index,index)
 m1 = A(*,index) # replicate(1.0,k+1)
 m2 = replicate(1.0,k+1)#A(index,*)
 mult1 = m1*m2
 case index of
 0: A(1:*,1:*) = A(1:*,1:*) - mult0*mult1(1:*,1:*) 
 k: A(0:k-1,0:k-1) = A(0:k-1,0:k-1) - mult0*mult1(0:k-1,0:k-1) 
 ELSE:BEGIN
       IN = [lindgen(index),lindgen(k-index) + index+1 ]
       A(IN,0:INDEX-1) =  A(IN,0:INDEX-1) -   $
                          mult0*mult1(IN,0:Index-1)
       A(IN,INDEX+1:*) =  A(IN,INDEX+1:*) -  $
                          mult0*mult1(IN,INDEX+1:*)
      END
 ENDCASE
 A(index,*) = -A(index,*) * mult0
 A(*,index) = A(*,index) * mult0
 A(index,index) = mult0
return
end



pro UpDate, COR, INEQ, N,K
; update correlation matrix by adding variables in  $
; InEQ to equation

for i = 0L,n-1 do insertvar,COR,INEQ(i),k
return
end


function remove_from, A, B,VarNo
; View both A and B as sets and return the set compliment B-A
; elements not returned in same order

Temp = fltarr(VarNo + 1)
Temp(B) = 1
Temp(A) = 0
return, where(Temp eq 1)
END  


function remove1_from, A, B
; View both A and B as sets and return the set compliment B-A
; elements not returned in same order

 A = A(sort(A))
 B = B(sort(B))

 SA = N_Elements(A)
 SB = N_Elements(B)

 if SB EQ 0 THEN return,B                   $
  else if SB EQ 1 THEN if A(0) EQ B(0) THEN return,C                $
                       else return,B
 
i = 0
j = 0

while i LT SA and j LT SB do BEGIN

     if A(i) EQ B(j) THEN BEGIN              ; remove B(j) from B
        if j EQ 0 THEN B = B(1:*)            $
         else if j EQ SB-1 THEN B = B(0:SB-2)         $
              else B = [B(0:j-1), B(j+1:*)]  
        i = i + 1
        SB = SB - 1
     ENDIF ELSE if A(i) GT B(j) THEN j = j+1  $
                else i = i+1
ENDWHILE

return,B
END
  

 



function f_to_exit,C,index,COR,k,n
; f_to_exit returns the index of the variable in C with
; smallest F_to_exit value which is computed via the
; partial correlation coefficient of each variable in
;  C against Y and adjusted for the remaining
; variables in C. If C is empty, inf is returned

 SC = size(C)
 SC = SC(1)

 FMin = 1.0e30
 index=0
 mul = n - SC - 1

 P2 = Cor(k,k)
 if N_Elements(C) EQ 0 THEN return,1.0e30

 for i = 0L,SC-1 DO BEGIN
    P1 = mult_cor(COR,C(i),k) 
    F = (P1-P2)/P1
    F = (F * mul) / (1 - F)    
    if (F LT FMin) THEN BEGIN
        FMin = F
        index = i
    ENDIF
ENDFOR

return, FMIN
END
          



 function f_to_enter, X,index,COR,k,n,SC
; f_to _enter returns the maximum f_to_enter value for the
; Variables in x ,index returns the index of the var with
; max f_to_enter

 SX1 = size(X)
 SX = SX1(1)
 FMax = 0
 mul = n-2-SC
 P1 = COR(k,k)
 for i = 0L, SX-1 DO BEGIN
     P2 = mult_cor(Cor,X(i),k)
     F = (P1-P2)/P1
     if F ge 1 THEN BEGIN
       index = i
       return,1.0e30
     ENDIF

       F = (F * mul) / (1 - F)
       if (F GT FMax) THEN BEGIN
          FMax = F
          Index = i
       ENDIF
      ENDFOR

return,FMax
END

  

      
 pro stepwise,X1,Y1,InEQ,alpha,alphar,VarNames=VN, $
                  Report=RP, List_Name =LN,Missing=M
;+
; NAME:
;	STEPWISE
;
; PURPOSE:
;	To select the locally best set of independent variables to be used
;	in a regression analysis to predict Y.
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;	STEPWISE, X, Y [,InEQ, Alpha, Alphar]
;
; INPUT:
;	X:	A 2-dimensional array of observed variable values. 
;		X(i,j) = the value of the ith variable in the jth observation.
;
;	Y:	A column vector of observed dependent variable values. 
;		X and Y must have the same number of rows.
;
; OPTIONAL INPUTS:
;	InEq:	Vector of indices of equations to be forced into the equation.
;
;	Alpha:	Significance level for including a variable.  The default 
;		is 0.05.
;
;	Alphar:	Significance level for removing a variable from the 
;		regression equation. The default is equal to Alpha.
;
; KEYWORDS:   
;     VARNAMES:	A vector of names for the independent variables to be used in
;		the output.
;         
;	REPORT:	A flag to print out regression statistics as each a variable 
;		enters or leaves the equation.
;
;    LIST_NAME:	A string that contains the name of output file.  Default is 
;		to the screen.
;
;      MISSING:	Value of missing data.  If this keyword is not set, assume no
;		missing data.  Listwise handling of missing data.    
;
; OUTPUT:
;	Regression statistics for the final equation.
;
; OPTIONAL OUTPUT PARAMETERS:
;	InEq:	Vector of indices of variables in final equation.
;
; RESTRICTIONS:
;	None.
;
; COMMON BLOCKS:
;	None.
;
; SIDE EFFECTS:
;	None. 
; 
; PROCEDURE:                     
;	Adapted from an algorithm from Statistical Analysis, a Computer
;	Oriented Approach, by A.A. Afifi and S.P. Azen.  The procedure 
;	successively picks the best predictor of the dependent variable Y 
;	given the variables already entered (via a statistic based on the
;	partial correlation coefficient).  Variables may be removed from the
;	equation if their significance falls below a given level. 
;-         

 On_Error,2    


 if ( N_Elements(LN) NE 0 ) THEN openw,unit,/get,LN    $
 else unit = -1 

 if N_ELEMENTS(X1) eq 0 THEN BEGIN
   printf,unit,"stepwise-- Data array is empty"
   goto,done0
 ENDIF

 X = X1
 SX = size(X)
 S1 = SX(1)
 S2 = SX(2)
 SY = size (Y1)




 
 if (SY(0) LT 2) THEN         BEGIN
  Y = transpose(Y1)
  SY = size(Y)
 ENDIF ELSE Y = Y1
   

 if  SY(0) NE 2 OR SX(0) NE 2 OR S2 NE SY(2) THEN   BEGIN
    printf,unit," stepwise - incompatible arrays"
    goto, DONE0
 ENDIF

 if N_Elements(M) THEN BEGIN
   X = listwise([x,y],M,rownum,rows,here)  ; Remove cases with 
                                           ; missing data.
                                           ; Remove and save
                                           ; corresponding
                                           ; values from y
   X = X(0:S1-1,*)
   if N_elements(X) le 1 THEN BEGIN 
      printf,unit,'stepwise---too many missing data values,'
      printf,unit,'           need more observations'
      Goto, DONE0
   ENDIF
                
   yval = Y(rownum) 
   Y = Y(0,here)                          
   SX = size(X)
   S2 = SX(2)
   SY = size (Y)
 ENDIF

 COR = Correl_Matrix([X,Y])
 D = Determ(COR)

 if ( abs(D) lt 1.0e-7) THEN BEGIN
    printf,unit, "Determinat of correlation matrix is", D
    printf,unit, " Hit control C to terminate computations" 
 endif

 
 
 outnum = S1-1



 if ( N_Elements(RP) NE 0) THEN RP =1 else RP =0

 Vars = setnames(VN,S1,unit)               ;Set up variable names
                                          ; for output.

 if ( N_Elements(alpha) EQ 0) THEN alpha =.05
 if ( N_Elements(alphar) EQ 0) THEN alphar = alpha   

 NotinEQ = INDGEN( S1)                    ; Initially, no   
                                          ; variables in    
                                          ; regression eq.


 NF = N_Elements(InEq)                  ; Get number of
                                        ; variables to 
                                        ; force into equation
 innum = NF + 1
 if ( NF EQ S1) THEN goto,done       ; If all vars are forced,
                                     ; exit

 if NF NE 0  THEN BEGIN               ; Are there variables to
                                      ; force  into eq$


NotInEq = remove_from( InEq, NotInEq,S1)  ;If so,remove them 
                                          ;from NotIneq list.
   outnum = outnum - NF
Update,COR,INEQ,NF,S1             ; Update correlation matrix
 ENDIF


 if NF NE 0 THEN C = X(InEq,*)

if (innum gt 1) THEN      $
 F = f_to_enter(NotInEQ,index,COR,S1,S2,innum-1)  $
                                  ;Index specifies first .
ELSE BEGIN
  F = max(abs(COR(S1,0:S1-1)),index)
  if F ne 1 THEN F = F^2*(S2-innum-1)/(1-F^2) else F = 1.0e30
END

 F = 1 - f_test1(F,1,S2-2)              
                                  ;Compute significance of F.

                                         

 if ( F LT alpha) THEN BEGIN
   Update,COR,NotInEq(index),1,S1
   if (NF  NE 0) THEN BEGIN  ; if significant,
       InEq =  [InEq,NotInEq(index)]                 
   ENDIF else           $
         InEq = [NotInEq(index)]
 ENDIF else if (NF NE 0) THEN goto, DONE  $
            else  BEGIN
                 printf,unit,                                $
 "stepwise- no variable significant, mean best predictor of y"
      goto, DONE0;
           ENDELSE 


 if RP NE 0 THEN writereport,X(InEq,*),Y,Vars(InEq)    $
            ,Vars(NotInEq(index)),     $
                "Entering Variable: ","Step", unit  

 if (outnum EQ 0) THEN goto,DONE           ;All vars in eq?
 

 if ( Index EQ 0) THEN NotInEq = NotInEQ(1:*)     $
                                          ; remove from list 
   else if (Index EQ outnum) THEN NotInEq =     $
                               NotInEq(0:outnum-1) $
     ELSE NotInEq = [NotInEq(0:index-1),NotInEq(index+1:*)]
 

 

 while ( innum NE S2-2 ) DO BEGIN 
      F = f_to_enter(NotInEq,index,COR,S1,S2,     $
                     N_Elements(InEq))      
                                    ; Get next var to enter
      F = 1 - f_test1(F,1,S2-2-innum)
 
     if ( F LT alpha) THEN BEGIN
       INEQ = [Ineq,NotInEq(index)]   ; put in eq
       Update,COR,NotInEQ(index),1,S1
      ENDIF else goto, DONE  

     if RP NE 0 THEN writereport,X(InEq,*),Y,Vars(InEq)   $
       ,Vars(NotInEq(index)),"Entering Variable: ","Step",unit


     innum = innum +1
     outnum = outnum -1 

                          
     if outnum EQ 0 THEN goto,done

     if ( Index EQ 0) THEN NotInEq = NotInEQ(1:*)     $
                     ; Remove it from list.

     else if (Index EQ outnum) THEN NotInEq =  $
                              NotInEq(0:outnum-1) $
              ELSE NotInEq = [NotInEq(0:index-1),  $
                              NotInEq(index+1:*)]
      
     F = f_to_exit(InEq(NF:*),index,COR,S1,S2)        
                        ;Are other vars still significant?

     WHILE ( 1-f_test1(F,1,S2-innum-1) GT alphar) DO BEGIN

        if NF NE 0 THEN temp = InEq(0:NF-1)  
                       ; if not, remove
                                        ;them from eq
        innum = innum-1
        outnum = outnum +1
        Varout = InEq(NF + Index)
        NotInEq = [NotInEQ,VarOut]
        Update,COR,varout,1,S1   
        if (Index EQ 0) THEN InEq = InEq(NF+1:*) $
          else if (Index EQ innum -1) THEN InEq = $
                                    InEq(NF:innum-2) $
        else InEq = [InEq(NF:NF+index-1),InEq(NF+index+1:*)]
        if NF NE 0 THEN InEQ = [temp,InEq]

        if RP NE 0 THEN writereport,X(InEq,*),Y,Vars(InEq), $
          Vars( VarOut),"Exiting Variable: ","Step", unit
             F = f_to_exit(InEq(NF:*),index,COR,S1,S2)
     ENDWHILE
ENDWHILE

     
DONE:

writereport,X(InEq,*),Y,Vars(InEq),"*******","*****",  $
                                     "Final",unit
printf,unit," "
printf,unit," "
printf,unit,"Variables in Equation: ",Vars(InEq)
DONE0: ;if N_Elements(M) THEN BEGIN                    ;replace cases with missing data
;   listrep,x,rownum,rows,here
;   Y = Fltarr(1,N_Elements(rownum) + sizea)
;   Y(here) = Y
;   Y(rownum) = yval
; ENDIF 
if (unit NE -1) THEN Free_Lun,unit
Return
END





