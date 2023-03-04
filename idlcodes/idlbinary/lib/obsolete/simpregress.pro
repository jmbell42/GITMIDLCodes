; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/simpregress.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.


function simpregress,X,Y,W,YFit,A0,sigma,FTest,R,RMul,Chisqr
Sx = N_Elements(X)

if N_Elements(W) EQ 0 THEN BEGIN
  W = Replicate(1.0,Sx)     
  NoWeight=1
ENDIF ELSE NoWeight = 0



Sum = Total(W)
Sumx =Total(W*X)
Sumy = Total(W*Y)
SumX2 = Total(W*X*X)
SumXY = Total(W*X*Y)
SumY2 = Total(W*Y*Y)

Del = Sum*SumX2 - Sumx^2
A0 = (sumx2*sumy - sumx*sumxy)/del
B =  ( sumxy * sum - sumx*sumy)/del

if NoWeight EQ 1 THEN   $
   Var = (sumy2 + A0*A0 *Sum + B*B*SumX2 - 2.*(A0*sumy + B*sumxy - A0*B*sumx))  $
         /(Sx-2)                $
ELSE Var = 1.0


sigma = sqrt(Var*Sum/Del)
RMul = (sum * sumxy - sumx * sumy)/sqrt(Del*(sum*sumy2 - sumY^2))
R = RMul

YFit = b * X + a0
Resid = Y - YFit
chisqr = Total(W*Resid^2)

return,b
END

