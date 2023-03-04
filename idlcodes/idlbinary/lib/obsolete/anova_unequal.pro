; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/anova_unequal.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


 pro printout,TName,BName,IName,SST,SSB,SSI,SSE,R,C,N,FT,FB,FI,unit

if N_Elements( TName) EQ 0 THEN TName='Treatment'
if N_Elements( BName) EQ 0 THEN BName='Block'
if N_Elements( IName) EQ 0 THEN IName ='Interaction'
printf,unit, format='
printf,unit,'          Source        SUM OF SQUARES    DF     MEAN SQUARE       F       p'
      printf,unit,'*******************************************************************************'

MSSE = SSE/(N-R*C)
DFE = N-R*C

MT = SST/(C-1) 
FT = MT/MSSE
printf,unit,         $
     Format='(A14,7X,G15.7,3X,I5,3X,G11.4,1X,G11.4,3X,G11.4)',$
TName,SST,C-1,MT,FT, 1-F_Test1(FT,C-1,DFE)

MT = SSB/(R-1) 
FB = MT/MSSE
printf,unit,        $
    Format='(A14,7X,G15.7,3X,I5,3X,G11.4,1X,G11.4,3X,G11.4)', $
             BName,SSB,R-1,MT,FB, 1-F_Test1(FB,R-1,DFE)

MT = SSI/((C-1)*(R-1))
FI = MT/MSSE
printf,unit,         $
Format='(A14,7X,G15.7,3X,I5,3X,G11.4,1X,G11.4,3X,G11.4)',  $
       IName,SSI,(C-1)*(R-1),MT,FI, 1-F_Test1(FI,(C-1)*(R-1),DFE)
 
printf,unit,         $
      Format='(A14,7X,G15.7,3X,I5,3X,G11.4)', 'Error',SSe,DFe,MSSe

RETURN
END


function mult_matrix ,X,Y,R,C
; Return the product of X with the design matrix
; specified by Y, Y(i,j) = the number of observations
; in cell (i,j). R and C are number of rows and columns

Here = 0
First = X(0)
X = X(1:*)
Result = [0]
skip = INDGEN(R-1)
for i = 0L,R-1 DO  BEGIN

   for j = 0L, C-1 DO  BEGIN
      
        if j EQ C-1 THEN tot = -Total(X(R-1:C+R-3))      $
         else tot = X(j+R-1)

       if i EQ R-1 THEN tot = tot - Total(X(0:R-2))          $
          else tot = tot +  X(i) 
       if j EQ C-1 and i ne R-1 THEN tot= tot -      $
                      total(X(R+C-2 + i*(C-1): R+C-3+(i+1)*   $
                           (C-1)))
       if i EQ R-1 and j ne  c-1 THEN tot = tot -             $
                                Total(X(R+C-2 +j + skip*(C-1)))    
       if(i EQ R-1 and j EQ C-1) THEN tot = tot +             $
                                             Total(X(R+C-2:R*C-2))
       if i NE r-1 and j NE C-1 THEN tot = tot + X(i*(C-1)+j+R+C-2)
       
       RESUlT = [RESULT, Replicate(tot,Y(i,j))]  
   ENDFOR
 ENDFOR
X = [First,X]
RETURN,Result(1:*) + First
END


Function Fit, G, R, C

; Compute B such that X*B = G, where X is the design matrix
; for an experiment with R rows, C columns and one observation
; per cell

M = total(G)/(R*C)
CF = Fltarr(R*C)
CF(0) = M
CF(1:R) = transpose((Replicate(1.0/C,C) # G) - M)
CF(R:R+C-1) = G # Replicate(1.0/R, R) - M
CF(R+C-1:*) = G(0:C-2,0:R-2) - replicate(1.0,C-1)#CF(1:R-1) - $
CF(R:R+C-2)#replicate(1.0,R-1) - M
return, CF
END

function RSI_INV, G, R, C
; same as Fix but assume no interactions
CF    = fltarr(R+C-1)
CF(0) = Total(G)/(R*C)
Row = Replicate(1.0,C) # G
CF(1)     =  Total(Row(0) - Row)/(R*C)

if R gt 2 THEN CF(2:R-1 ) = CF(1) - (Row(0) - Row(1:R-2))/C
Col =G #  Replicate(1.0,R)
CF(R)     = Total(Col(0) - Col)/(R*C)
if C gt 2 THEN $
 CF(R+1:*) = CF(R) - (Col(0)-COl(1:C-2))/R 

return,CF
END

function FitI,G,R,C
; regression fit to anova model with observations in G,
; no interactions and only 1 observation per cell.
A = RSI_INV(G, R, C)
CF = fltarr(R*C)
CF(0:R+C-2) = A
Y = fltarr(R,C) + 1
CF = Mult_Matrix(CF,Y,R,C)
return,CF
END
 

pro ComputeSSE, B ,YY,Y, R, C, I, SSE,BB
;ComputeSSE implements the generalized gradient algorithm
;in 'Nonorthogonal Analysis of Variance Using a Generalized
;Conjugate-Gradient Algorithm in Journ. Amer. Statistical
;Association, 1982, vol. 7.

BB   = FLTARR(R*C)             ;INITIALIZE
G   = YY*Y
SSE = Total(YY*G)
RR    = FLTARR(R*C)
eps  = 1.0
d    = 0.0
d1  = 1.0
NUM = 0
P = R * C
while d1 GT 1e-8 DO BEGIN
 NUM = NUM + 1
 Z = FitI(G,R,C)
 d1  = Total(Z*Z)      
 eps = ABS(d1 - d)
 if(NUM GT 1) THEN c1 = d1/d ELSE c1 = 0
 d = d1
 RR = Z + c1*RR
 Z =  Y * RR
 tt = Total(RR*Z)
 if tt ne 0 THEN $
   a = d/Total(RR*Z) $
 else message, $
  "Data causes division by zero. "
 
 BB = BB + a*RR
 SSE = SSE - a*d
 G = G - a * Z
ENDWHILE
BB = RSI_INV(reform(BB,c,r),r,c)
return
END

pro Make_Matrix,X,Y,R,C
; take anova data and make regression matrix X. Y(i,j) = number of observations
; in the ith,jth cell.


X = fltarr(R*C,Total(Y))
Here = 0
X(0,*) = 1
skip = INDGEN(R-1)
for i = 0L,R-1 DO  BEGIN

   for j = 0L, C-1 DO  BEGIN

        TEMP = fltarr(R*C-1)    
        if j EQ C-1 THEN temp(R-1:C+R-3) = -1 else temp(j+R-1) = 1
       if i EQ R-1 THEN temp(0:R-2) = -1 else temp (i) = 1
       if j EQ C-1 and i ne R-1 THEN          $
                    temp(R+C-2 + i*(C-1): R+C-3+(i+1)*   $
                                                    (C-1)) = -1 
       if i EQ R-1 and j ne  c-1 THEN      $
                          temp(R+C-2 +j + skip*(C-1))=-1    
       if(i EQ R-1 and j EQ C-1) THEN temp(R+C-2:R*C-2) =1
       if i NE r-1 and j NE C-1 THEN temp(i*(C-1)+j+R+C-2) =1
       
       X(1:*,HERE:HERE+Y(i,j)-1) = temp # Replicate(1.0,Y(i,j))  
       HERE = HERE + Y(i,j) 
   ENDFOR
 ENDFOR
RETURN
END







pro make_matrix1,T,Y,R,C
;Compute X#transpose(X) directly

T = Fltarr(R*C,R*C)

LastRow = Total(Y(R-1,*))
LastCol = Total(Y(*,C-1))
T(0,0) =  Total(Y)            ;Multiply by column 0---all 1's
for i = 1L, R*C-1 DO BEGIN
 if (i LE R-1) THEN T(0,i) = Total(Y(i-1,*)) - LastROW    $
 ELSE if (i LE R+C-2) THEN T(0,i) = Total( Y(*,i-R)) - LastCOL $
 ELSE BEGIN
  i1 = (i- R - C + 1)  
  a  = i1 MOD (C-1)
  b  = i1/(C-1)
  T(0,i) = Y(b,a) - Y(R-1,a) - Y(b,C-1) + Y(R-1,C-1)
 ENDELSE
T(i,0) = T(0,i)
ENDFOR



;*************************************************************
;                  MULTIPLY BY BLOCKS

for i = 1L,R-1 DO  BEGIN

 for j= i,R-1 DO BEGIN        ;Block * BLOCK********
  If (i EQ j) THEN T(i,i) = Total(Y(i-1,*)) + LastROW  $
  ELSE T(i,j) = LastROW
  T(j,i) = T(i,j)
 ENDFOR

 for j = R,R+C-2 Do  BEGIN    ;Block * TREATMENT***********
  T(i,j) = Y(i-1,j-R)- Y(R-1,j-R) -Y(i-1,C-1) + Y(R-1,C-1)
  T(j,i) = T(i,j)
 ENDFOR

 for j = R+C-1,R*C-1 Do BEGIN    ;Block * Interaction******
  j1 = (j - R - C +1)
  a  = j1 MOD (C-1)
  b  = j1/(C-1)
  if (b EQ i-1) THEN T(i,j) = Y(b,a) + Y(R-1,a) -   $
                             Y(b,C-1) - Y(R-1,C-1)      $
  ELSE T(i,j) = Y(R-1,a) - Y(R-1,C-1)
  T(j,i) = T(i,j)
 ENDFOR

ENDFOR

;**************************************************************
;        MULTIPLY BY BLOCKS

for i = R,R+C-2 Do BEGIN           ;TREATMENT * TREATMENT ***************
    i1 = i - R
 for j = R,R+C-2 Do BEGIN
  j1 = j - R
  if (i EQ j) THEN T(i,j) = Total(Y(*,i1)) + LastCOL  $
  ELSE T(i,j) = LastCOL
  T(j,i) = T(i,j)    
 ENDFOR

 for j = R+C-1,R*C-1 Do BEGIN      ;BlOCK*INTERACTION
  j1 = (j - R - C +1)
  a = j1 MOD (C-1)
  b = j1/(C-1) 
  if ( a EQ i1) THEN T(i,j) = Y(b,a) - Y(R-1,a) + Y(b,C-1)   $
                             - Y(R-1,C-1)                   $
  ELSE T(i,j) = Y(b,C-1) - Y(R-1, C-1)
  T(j,i) = T(i,j)
 ENDFOR
ENDFOR

;**************************************************************
;              MULTIPLY BY INTERACTION

for i = R + C -1, R*C -1 DO BEGIN
 i1 = (i - R - C + 1)
  a1 = i1 MOD (C-1)
  b1 = i1/(C-1)
 for j = i, R*C-1 DO BEGIN
  j1 = (j - R - C + 1)
  a = j1 MOD (C-1)
  b = j1/(C-1)
 if (i EQ j) THEN T(i,j) = Y(b,a) + Y(R-1,a) + Y(b,C-1) +  $
                           Y(R-1,C-1)                      $
 ELSE if ( a EQ a1) THEN T(i,j) = Y(R-1,a) + Y(R-1,C-1)    $
 ELSE if ( b EQ b1) THEN T(i,j) = Y(b,C-1) + Y(R-1,C-1)    $
 ELSE T(i,j) = Y(R-1,C-1)
 T(j,i) = T(i,j)
 ENDFOR
ENDFOR
  
    
RETURN
END 


function mult,B,Y,R,C,I
; Return the product of X with Transpose( design matrix
; specified by Y, Y(i,j) = the number of observations
; in cell (i,j)). R and C are number of rows and columns
Tot = Total(Y)
Tot1 = Total(Y(R-1,*))
LastRow = Total(B(Tot-Tot1 : *))
B1 = [Total(B)]
Next = -1 

for i = 0L, R-2 DO BEGIN
 Last = Next + 1
 Next = Next + Total(Y(i,*))
 Temp = Total( B(Last:Next)) - LastRow
 B1 = [B1,Temp]
ENDFOR

Tot = 0
TotUp = Fltarr(R,C)
for i = 0L,R-1 DO       $
 for j = 0L,C-1 DO BEGIN
  TotUp(i,j) = Tot
  Tot = Tot + Y(i,j)
 ENDFOR


TEMP1 = [0]
for j = 0L,C-1 DO BEGIN
 Temp =0
 for i = 0L, R-1 DO                    $
  TEMP = TEMP + Total(B(TotUP(i,j):TotUp(i,j) + Y(i,j) - 1))
 if ( j NE C-1) THEN                  $
  TEMP1 = [TEMP1,TEMP]                
ENDFOR

TEMP1 = TEMP1(1:*)
TEMP1 = TEMP1 - TEmp
B1 = [B1,TEMP1]

for i = 0L,R-2 DO                     $
 for j = 0L, C-2 DO BEGIN
  TEMP = Total(B(TotUP(i,j): TotUp(i,j) + Y(i,j) -1))
  TEMP = TEMP - Total(B(TotUp(R-1,j):TotUp(R-1,j) +  Y(R-1,j)-1))
  TEMP = TEMP - Total(B(TotUP(i,C-1):TotUp(i,C-1) + Y(i,C-1)-1))
  TEMP = TEMP + Total(B(TotUp(R-1, C-1): TotUp(R-1,C-1) +      $
              Y(R-1,C-1)-1))
  B1 = [B1, TEMP]
 ENDFOR
          


Return,B1
END
          




pro anova_unequal, Data1,FT_Test,FB_Test,FI_Test, TName = TN, $
                  BName = BN, IName = IN,Missing = M,    $
                  ListName = LN, No_Printout =NP
;+
;
; NAME:
;	ANOVA_UNEQUAL
;
; PURPOSE:
;	Perform two way analysis of variance with interactions and unequal
;	cell sizes - that is, not every treatment / block combination
;	has the same number of iterations.
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;	ANOVA_UNEQUAL, Data, FT_Test, FB_Test, FI_Test
;
; INPUTS: 
;	Data:	Array of experimental data, dimensioned (Treatment#, I, B),
;		where I is the number of repetitions in each cell.
;
; OUTPUT:
;	Anova table displaying  Sum of Squares, Mean Squares, and F Ratio 
;	for sources of variation.
;
; OPTIONAL OUTPUT PARAMETERS: 
;      FC_Test:	value of F for treatment or column variation.
;
;      FB_Test:	value of F for row or block variation.
;
;      FI_Test:	value of F for column variation.
;
; KEYWORDS:
;      MISSING:	missing data value.  If undefined, assume no missing data. If 
;		unequal sample sizes, set M to place holding value.
;
;    LIST_NAME:	name of output file. Default is to the screen.
;
;	TNAME:	name to be used in the output for treatment type.
;
;	BNAME:	name to be used in the output for block type.
;
;	INAME:	name to be used in the output for interaction type
; 
;  NO_PRINTOUT:	flag , when set,  to suppress printing
;                       of output
; RESTRICTIONS:
;	Each treatment/block combination must have at least 1 observation.
;
; SIDE EFFECTS:
;	None.
;
; PROCEDURE:
;	Overparameterized least squares procedure with sum to zero 
;	restrictions.
;- 

On_Error,2


if N_Elements(LN) NE 0 THEN openw,unit,/get,LN else unit = -1
if N_elements(data1) eq 0 THEN BEGIN
   printf,unit,"anova_unequal- Data array is empty"
   return
ENDIF

SD = size(Data1)
R  = SD(3)
C  = SD(1)
IN  = SD(2)

if SD(0) ne 3 THEN BEGIN
   printf,unit, "anova_unequal- Data array must be 3 dimensional."
   return
ENDIF

DATA =DATA1
B = [0]
Y = Fltarr(R,C) + R
YY = Y

for i = 0L,R-1 DO         $
 for j = 0L,C-1 do BEGIN
  if( N_Elements(M)) THEN BEGIN
   here = where(Data(j,*,i) NE M, count)
   Y(i,j) = count

   if count EQ 0 THEN BEGIN
    printf,unit,'anova_unbalanced - stop,empty cell'
    goto, done
   ENDIF

   here = transpose(Data(j,here,i))
   B = [B,here]
   YY(i,j) = Total(here)
   ENDIF ELSE BEGIN
    here = transpose(Data(j,*,i))
    B = [B,here]
    Y(i,j) = IN
    YY(i,j) = Total(here)
   ENDELSE
 ENDFOR 

if N_Elements(M) EQ 0 THEN  $
   printf,unit,'anova_unequal, there is no missing data'

YY = YY * 1.0/Y
B = B(1:*)

BB = fit(transpose(YY),R,C)
SSE = Total((B-mult_matrix(BB,Y,R,C))^2)

W =   1.0/Y # replicate(1.0,C)
W = 1.0/(W/(C^2))
YYY =   YY # replicate(1.0/C,C)
WA = Total(w*YYY)/total(w)
SSB = Total(w*(YYY-WA)^2)

W =    replicate(1.0,R) # (1.0/Y)
W = 1.0/(W/(R^2))
YYY = replicate(1.0/R,R) # YY
WA = Total(w*YYY)/total(w)
SST = Total(w*(YYY-WA)^2)

ComputeSSE, B ,transpose(YY),transpose(Y), R, C, I, SSI,BB

if( N_Elements(NP) EQ 0) THEN     $
printout, TName, BName, IName, SST,SSB,SSI,SSE,R,C, Total(Y),  $
 FT_Test,FB_Test,FI_Test,unit

DONE:
if (unit NE -1) THEN Free_Lun,unit

return
END

