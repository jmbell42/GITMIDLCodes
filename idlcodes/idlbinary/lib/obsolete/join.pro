; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/join.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.



 Function join_EuclidRule, Case1, RCases
; Dist returns the vector of Euclidean Distances from Case 
; to the other cases in the array RCase

 SC=Size(RCases)
 C=SC(1)
 if(SC(0) GT 1) THEN  R=SC(2) ELSE R=1
 M1= Case1#(Fltarr(R)+1)
 M2=Fltarr(C)+1
 M1=M1-RCases
 if(R EQ 1) THEN  Return,SQRT(Total(M1*M1)) $
  else Return, transpose (SQRT(M2#(M1*M1)))
 END

Function join_Distance1,Case1,RCases,N
; Determine appropriate rule for computing distances between
; cases and return the vector of distances between
; RCases and Case1.

SC=Size(RCases)
S=SC(1)
if(SC(0) GE 2) THEN R=SC(2) else R=1

Case N of
    "%":BEGIN
       X=Case1#replicate(1.,R) - RCases
       A=where(X NE 0,count)
       if(count NE 0) THEN X(A)=1
       if(SC(0) GT 1) THEN return,       $
         transpose(replicate(1.,S)#X*1/S)    $
       ELSE return,Total(X)*1/S
       END
    
    "COR":BEGIN
          V= [Correlate(Case1,RCases(*,0))]
          for i=1,R-1 DO V=[V,Correlate(Case1,RCases(*,i))]
          return,1-V
          END
    ELSE: return,join_EuclidRule(Case1,RCases)
ENDCASE
END


   
       
 

Function join_normal1, Data,R,C
;Normal returns Data normalized by columns
Y= Data-Data#Replicate(1./R,R) #Replicate(1.,R)
std =sqrt(Y^2 # Replicate(1./(R-1),R))
D1=Fltarr(c,c)
for i=0,C-1 do     $
  if std(i) NE 0 then    $
     D1(i,i)=1./std(i) else d1(i,i)=0
return, D1#Y
end


Function join_FindRow,I,R
; D is a symmetric matrix stored linearly. join_FindRow
; reconstructs the ith row. R is the total number of rows.

Common JBlock,D,INDEX
  case I of 

  R-1:Begin               ;RETURN,(R-1)*(R-2)/2:(R+1)*(R-2)/2)
      X=LINDGEN((R+1)*(R-2)/2 +1)
      Return,X((R-1)*(R-2)/2:(R+1)*(R-2)/2)
      END

  0: BEGIN
     T=LIndgen(R-1)
     RETURN,(1+T)*T/2
     END   

  ELSE: BEGIN
        A1=I*(I-1)/2
        A2=(I+1)*(I+2)/2 -1
        T=LIndGen(R-I-1)
        T=(T+1)*T/2
        RETURN,[A1+LIndgen(I),A2 + I*LIndgen(R-I-1 )+T]
        END
 ENDCASE
 END
 


 Pro join_MinDist,R,DMin,IMin,I	
 ; join_MinDist computes the minimum distance from case I to any
 ; other case  using the symmetric distance matrix D. This
 ; distance and the corresponding row number are returned
 ; in DMin and
 ; IMIN respectively.

 Common JBLock,D,INDEX

 DMin(I)=min(D(join_FindRow(INDEX(I),R)))
 if(!C LE INDEX(I)-1) THEN IMIN(I)=INDEX(!C) else  $
    IMIn(I)=INDEX(!C+1)
 RETURN
 END

 

 Pro join_SetVal,V,I,R  

 Common JBlock,D,INDEX
 
 D(join_FindRow(INDEX(I),R))=v
 RETURN
 END

 
  FUNCTION join_AmalDist,I1,J1,R,pos,Am,cl,here
  ;join_AmalDist computes the distances from the cluster formed
  ; from I and J to the other cases and clusters as the
  ; minimum distance between members

  Common JBlock,D,INDEX

   I = INDEX(I1)
   J = INDEX(J1)
   X1=Fltarr(R)
   Y1=Fltarr(R)

   
  here = join_FindRow(I,R)
  X=D(here)

  case I of

  R-1:X1=[X,1.e30]
  0: X1=[1.e30,X]
  ELSE:X1=[X(0:I-1),1.e30,X(I:R-2)]
  ENDCASE
 
  Y=D(join_FindRow(J,R))

  case J  of
   R-1:Y1=[Y,1.e30]
   0:  Y1=[1.e30,y]
   ELSE:Y1=[Y(0:J-1),1.e30,Y(J:R-2)]
  ENDCASE        

    Ind=Where(Y1 EQ 1.e30)
    Y1(Where(X1 EQ 1.e30))= 1.e30
    X1(Ind)=1.e30

  INDEX(cl) = I
  INDEX(I) = cl
  
  case Am of
  "MAX" : V=X1>Y1
  "MEAN": V=(pos(I)*X1+pos(J)*Y1)/(pos(I)+pos(J))
   ELse : V=X1<Y1
 ENDCASE

 case I of
  0: Return, V(1:*)
  R-1: Return,V(0:R-2)
  ELSE: Return,[V(0:I-1),V(I+1:*)]
 ENDCASE

 END





 Pro Join, DataArray,pos,Imin,Sim,CaseName = CaseName,       $
           List_Name=LN,Norm=NR,Missing=M, Pair=pr,          $
           Distance=Dx, Amal=AM, NoPrint =NP, Width = LS

 Common JBlock, D,Index
 
;+
; NAME:
;	JOIN
;
; PURPOSE:
;	To partition the cases represented by the rows in DataArray into
;	nested clusters. 
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE: 
;	JOIN, DataArray, pos, Imin, Sim
;
; INPUTS: 
;    DataArray:	a (C,R) dimensioned array where R is the
;		number of cases to be partitioned and C
;		is the number of variables.
;
; KEYWORDS
;     CASENAME:	one dimensional array of R case names.
;
;	NORM:	Flag to signal whether to normalize the
;		variable values in Data. Values normalized only if Norm=1. 
;
;      MISSING:	Missing data value. If undefined, assume no missing data
;
;     DISTANCE:	Rule for computing case distances.
;		Options are:
;		1. "%": Distance = percent of variable values that disagree
;				   between two cases. 
;		2. "EUCLID":	This is the default.
;		3. "COR":	Distance between i and    
;                               j = 1-rij, where rij= the correlation 
;				between i and j.
;		4. "OWN":  DataArray= a symmetric a
;			   distance array supplied by the user.  This array
;			   should be a 1-dim array of the elements in the
;			   distance array that are below the main diagonal.
;
;	AMAL:	Rule for computing cluster distances. Options are:
;		1. "MIN": distance = distance between closest members.
;		2. "MAX": distance = distance between farthest members.
;		3.  "MEAN" : distance = average of distances between members.
;                              
;      NOPRINT:	A flag, if set, to suppress output to the screen.             
;
;	WIDTH:	User supplied tree width in characters.  The default is 60.
;
; OUTPUT:
;	The tree of hierarchical clusters is printed to the screen.  
;     
; OPTIONAL OUTPUT PARAMETERS: 
;	Pos:	One-dimensional array of cases in the in the tree of 
;		hierarchical clusters. Pos(i) = position of case i in tree.
;
;	Imin:	One-dimensional array specifying nesting of clusters. 
;		Imin(i) = smallest cluster properly containing cluster or
;		case i.
;              
;	Sim:	One-dimensional array of minimum distances.
;		Sim(i) = the distance between the two clusters joined to
;		form cluster i. 
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
;	Adapted from algorithm in Clustering Algorithms by
;	Hartigan, Wiley Series in Probablity and Mathematical
;	Statistics, Chapt.4. Function  kmeans1 implements a
;	function that given a partition P returns a
;	partition P' in the same neighborhood with reduced
;	in group error. Function is called repeatedly until 
;	it finds a fixed point or local minimum. Kmeans1
;	recomputes cluster means after each reassignment.
;	Procedure Kmeans successively finds partitions
;	with the starting partition for K the final partition
;	for K-1 with the case farthest from its cluster mean
;	split off to form a new cluster.
;-

 On_Error,2
 SD=Size(DataArray)

 if (N_ELements(LN) EQ 0) THEN unit = -1  $
 else openw,unit,/Get,LN

 if (SD(0) NE 2) THEN BEGIN
   printf,unit, "Join- Data Matrix must be 2-dimensional"
   goto,quit0
 ENDIF

 Data = DataArray

 if (N_ELEMENTS(M) NE 0) THEN  BEGIN
     Data = listwise(Data, M)
     SD = size(Data)
     if N_ELEMENTS(Data) le 1 or SD(0) eq 1 THEN BEGIN
        printf,unit,"join- Halting, too many missing data values."
        goto,quit0
     ENDIF
  Endif
 
 C= SD(1)
 R=SD(2)
 Inf= 1.e+30 

 if N_ELEMENTS(NR) NE 0 THEN              $
   Data=join_normal1(Data,R,C)               ;normalize data

 if(N_Elements(Dx) EQ 0) THEN  Dx="EUCLID"  ;if not specified,
                                            ; euclidean
                                            ;distance computed
 if(N_Elements(Am) EQ 0) THEN  Am ="MIN"   
 					;default amalgamation
                                            ;  policy
    

 if(Dx EQ 'OWN') THEN D=Data else Begin 
                              ;user specifies distances 
                                         ;between cases

  V=join_Distance1(Data(*,1),Data(*,0),Dx)
           ;Distance between first two cases print,"V=",V

  D=[V]			        ;initialize symmetric Distance
                                ;matrix D
                                ;Note that D is 1-dimensional

 for i=2l,R-1 DO BEGIN                ;Construct the rest of D
  V=join_Distance1(Data(*,i),Data(*,0:I-1),Dx )
  D=[D,V]
 ENDFOR
ENDELSE              

Index = Findgen(2*R)                  ;initialize indices
           
Sim=Fltarr(2*R)                ;measure of closeness of cases
                                            ;in clusters
DMin=Fltarr(2*R)                            ;
;DDMin=DMIN
IMin=Intarr(2*R)                           
                                           
 
for I=0l,R-1 DO BEGin
 join_MinDist,R,DMin,IMin,I           ;Compute min distance between
 ENDFOR                          ; cases and store distance in
                                ;DMIN(i) and nearest case to i
                                ; in IMIN(I)

RN=R
Pos=[Intarr(RN) +1,Intarr(RN-1)]	

 for i= RN,2*RN-2 DO BEGIN           ; Amalgamate clusters
  DM=Min(DMin(0:R-1),MI)	     ; Find closest clusters
  Sim(I)=DM
  MJ=IMin(MI)                              

  DMin(MI)= inf & IMin(MI)= I & DMin(MJ)=inf & IMin(MJ)=I
                                     ; and combine


  V= join_AmalDist(MI,MJ,RN,pos,Am,i,here)             

  D(here) = V
  R=R+1
if (i NE (2*RN-2)) THEN BEGIN  
  join_MinDist,RN,DMin,IMin,I
  Pos(i)   = Pos(MJ)+Pos(MI)
  Ind=where((DMin(0:R-1) GT  V) AND  $
        (DMIN(0:R-1) NE inf) ,count)
		 ;Compare distance to new cluster with min  
                             ; and update    
   if(count NE 0) THEN BEGIN
    DMin(Ind) = V(Ind)		
    IMin(Ind) = I
   ENDIF



   join_SetVal,inf,MJ,RN 

   for J= 0l,R-1 DO BEGIN       ;Recompute min distance where
                               ;IMin = one of the amalgamated
                                          ;clusters	
    if(IMin(j) EQ MJ) OR ( IMin(j) EQ MI) THEN BEGIN
      if(DMin(j) NE inf) THEN  join_MinDist,RN,DMin,IMin,J          
    ENDIF
  ENDFOR
ENDIF
 ENDFOR                              ; Amalgamation completed


  Pos=[Intarr(RN) +1,Intarr(RN-1)]	
 for i=0l,2*RN-3 DO Pos(IMIN(I))=Pos(IMIN(I))+Pos(I)
                  ;Pos(I)= # of objects in Ith cluster



 

 for i=0l,2*RN-3 DO  BEGIN     ;Pos(i) = position of i in tree
              
  j=2*RN-i-3
  temp=Pos(j)
  Pos(j)= Pos(IMin(j))
  Pos(IMin(j))=Pos(IMin(j))-temp
 ENDFOR
 pos=pos(0:RN-1)-1
 if( N_Elements(NP) EQ 0) THEN maketree,pos,imin,SIM,unit, $
                                CaseName=CaseName,Width = LS
 
 quit0:
 if(unit NE -1) THEN Free_Lun,unit
 RETURN
 END

