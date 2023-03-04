; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/kmeans.pro#1 $
;
;  Copyright (c) 1991-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.



Function kmeans_normal1, Data,R,C

;kmeans_normal1 returns the matrix obtained by normalizing the columns
; of Data.  R= # of rows, C= # of columns.

Y= Data-Data#Replicate(1./R,R) #Replicate(1.,R)
std =sqrt(Y^2 # Replicate(1./(R-1),R))
D1=Fltarr(c,c)
for i=0l,C-1 do              $
 if std(i) NE 0 then D1(i,i)=1./std(i) else d1(i,i)=0

return, D1#Y
end     ;kmeans_normal1
 




 Pro StatComp,D,V,N,Mx,Mn,STD,SS

 ; compute summary statistics,min,max,standard deviation for
 ; all variables in a cluster whose cases are listed in V. 
 ; Statistics stored  in the 1-dim  arrays, Mx=Max,Mn=Min,
 ; STD=standard deviation,SS=sum  of squares. D=Data,  see
 ; procedure kmeans.

 R=Size(D)               
 N=R(1)                    ; N = # of variables
 R1=R(0)               
 R=R(2)                    ; R = # of cases


 Y= D-V#Replicate(1.,R)    ; Compute sum of squares and
                           ; standard deviation
 if(R1 GT 1) THEN SS= Y^2#Replicate(1.,R) ELSE SS=Y^2

 if(R1 GT 1) THEN  STD=SQRT(Y^2#Replicate(1./(R-1),R))     $
  ELSE STD=FLtArr(N)

 Mx=Fltarr(N)
 MN=Mx

 for i=0l,N-1 DO BEGIN      ; compute max and min
     MN(i)=min(D(i,*))
     Mx(i)=max(D(i,*))
 ENDFOR
 RETURN
 END
  




 
Pro VAnova,Data,Cluster,VarNames,SS,unit,N,CN,R,SizeB,B1,SW1

;Compute and print out 1-way  analysis of variance for each
;variable. Interpret clusters as treatments. N=# of variables,
; CN= #of clusters, R=of cases, SizeB(i)= size of ith cluster.


Common KBlock,B                  ;B(i,j)= ith variable mean
                                 ; for cluster j. 

printf,unit,Format='(/,/,/)'
printf,unit,"                    Overall Variable Statistics"
printf,unit,"*******************************************************************"

  printf,unit,                 $
Format='("Variable",6x,"Within SS",4X,"DF",4x,"Between SS",4X,"DF",5X,"FRatio")'

SW1=Fltarr(N)
MS= Replicate(1.,N)#SizeB       ;compute between sum of squares
TT= B*MS#Replicate(1.,CN)       
TT= TT*TT/Total(SizeB)
B1= B^2 * MS#Replicate(1.,CN)-TT  ; B1(i) = between SS for ith 
                                  ;variable 
DFB=CN-1                          ; compute between degrees of freedom 
DFW=R-DFB-1                  ; compute within degrees of freedom
if DFB EQ 0 THEN DFB= 1.e-10
if DFW EQ 0 THEN DFW = 1.e-10

for i=0l,N-1 DO BEGIN
    SSB=B1(i) 
    SW= Total(SS(i,*))            ; within SS
    SW1(i)=SW
  printf,unit,Format='(A8,4X,G11.4,3X,I3,3X,G11.4,3X,I3,1X,G11.4)',VarNames(i),SW,DFW,SSB,DFB,SSB*(DFW)/(SW*DFB)
ENDFOR

 RETURN
END                 ;Procedure Vanova
    
    
 



 Pro OutPut1, Clus,Data,CaseNam,VarNam,unit,SD1,SB1,SW1
 ; Output mean,min,max and standard deviation for each
 ; variable for each cluster.Also, output overall analysis
 ; of variance.
 
 Common KBlock,B 
        ;B(i,j) = value of ith variable in jth cluster

 SB=Size(B)
 K= SB(2)                ; final # of clusters
 N= SB(1)                ; number of variables
 SD=Size(Data)
 CN=SD(2)                ; number of cases
 SD1=Fltarr(N,K)
 NC=Size(CaseNam)

 if(NC(1) NE 0 ) THEN BEGIN 
                 ;check and, maybe, fix case names
     CaseName=CaseNam
     if(NC(1) LT CN) THEN BEGIN
     printf,unit,'kmeans-missing Case names'
     I=Indgen(CN)
     CaseName=[CaseName,'Case'+STRTRIM(I(NC(1):CN-1),2.)]
   ENDIF
 ENDIF ELSE CaseName= 'Case'+STRTRim(INDgen(CN),2)

 NC=Size(VarNam)

 if(NC(1) NE 0 ) THEN BEGIN
          ;likewise, for variable names
   VarName=VarNam
   if(NC(1) LT N) THEN BEGIN
     printf,unit,'kmeans-missing Variable names'
     I=Indgen(N)
     VarName=[VarName,'Var'+STRTRIM(I(NC(1):N-1)),2]
   ENDIF
 ENDIF ELSE VarName='Var'+ STRTrim(INDgen(N),2)


   
 SSW=Fltarr(N,K)
                        ;SSW(i)= sum of squares for cluster i
 SizeB= FltArr(K)          ;SizeB(i) = # of cases in cluster i

 for i = 0l,K-1 DO BEGIN    ;print out cases and statistics for
                           ;each cluster
 V=B(*,i)    
                 ;V= vector of mean var values for ith cluster
 printf,unit,Format='(/,/,/)'

 printf,unit,Format='(20X,"Cluster:",I12)',i

printf,unit,'********************************************************************************'


 printf,unit,                       $
Format='(/,6X,"Case",5X,"Distance",3X,"|",5X,"Var",8X,"Min",8X,"Max",7X,"Mean",8X,"STD",/,/)'

CL=where(Clus EQ i,count)    
                           ;Cl= list of cases in ith cluster
if count ne 0 THEN BEGIN
 SizeB(i)=count  
 M=count> N
 D1=Data(*,CL)                ;D1 is Data restricted to the
                              ;cases in cluster i.

 StatComp,D1,V,N,mx, mn,STD,SS        ; compute var stats 
 SSW(*,i)=SS          
                      ;compute within sum of squares for anova
 SD1(*,i)=STD

 for j=0l,M-1 DO BEGIN                 

     if(J LE count-1) THEN BEGIN   ;print Cases and distances
       Dist= Data(*,CL(J))-V
       printf,unit,                $
Format='(A10,2X,G11.4,3X,A1,$)',   $
CaseName(CL(j)),SQRT(Total(Dist*Dist)),"|"
     ENDIF ELSE printf,unit,Format='(26X,"|",$)'



   if(J LE N-1) THEN BEGIN
                  ; print variables and their stats

printf,unit,Format='(2X,A6,G11.4,G11.4,G11.4,G11.4)',    $
                   VarName(j),mn(j),mx(j),V(j),STD(j)
   ENDIF ELSE printf,unit," "
 ENDFOR
ENDIF
ENDFor

 VAnova,Data,Clus,VarName,SSW,unit,N,K,CN,SizeB,SB1,SW1
                                             ; output anova
 
RETURN
END        ; OutPut1
     
 



  
Pro KMeans1, Data,Clus,iter,K

; Data is a (C,R) dimensioned array of R cases and C
; variables.Clus must be a one-dimensional array of size
; R and with each element between 0 and K-1. K is the number
; of clusters and iter the maximum #of times to relocate case
; in clusters to minimize error. On exit, CLUS represents
; the final clusters of the partition. Clus(i)=cluster
; containing casei.



Common KBlock,B 
 On_Error,2  

 SD=Size(Data)
 if SD(0) eq 1 then R = 1 else R=SD(2)                          ; R= # of cases
 C=SD(1)                          ; N= # of variables
 
 B=Fltarr(C,K)                    
 D=Fltarr(K,R)
 INCLUS=FLtarr(R,k)
 L=Fltarr(K)                      ;L(i)= size of ith cluster
 

 for i=0l,k-1 DO BEGIN
    X=( CLUS EQ i)
    L(i)= Total(x)
    if(L(i) NE 0) THEN X=X/L(i)
    INCLUS(*,i)=X
  END

 B= Data#INCLUS
            ;B(N,L)= mean of the Nth variable in cluster L
     
 CD=Fltarr(R) 


 X=Data-B(*,Clus)
 e = Total(X*X)

 for j=1l,iter DO BEGIN         ; reiteratively, relocate
                               ; cases in clusters
                               ; to reduce error
    GotOne=0
    for i= 0l,R-1 DO BEGIN      ; run thru cases
         Min=1.e30
         NK=-1
         D1= Data(*,i)-B(*,Clus(i))      ; 
     if(L(CLUS(i)) GT 1)               $
     THEN D1= L(CLUS(I))*Total(D1*D1)/(L(Clus(i))-1)    $
     else D1=0
               ;D1=~Distance from i to its cluster Clus(i) 
         for n= 0l,k-1 DO BEGIN
             if(n NE CLUS(i)) THEN BEGIN
                D2= Data(*,i)-B(*,n)  
                                
                D2= L(n)*Total(D2*D2)/(L(n)+1) 
                       ;D2=~Distance from case i to cluster n

                if (D2-D1 LT Min) THEN BEGIN
                        ;D1-D2= error change if object i is
                        ; relocated into cluster n
                    Min=D2-D1
                    NK=n
                    ENDIF
              ENDIF
           ENDFOR

          if(Min LT 0) THEN BEGIN
                  ;relocate to cluster NK if it reduces error
        
            B(*,CLus(i))=   $
           (B(*,Clus(i))*L(CLus(i))-Data(*,i))/(L(Clus(i))-1)
                        ;update cluster means after relocation
            B(*,NK)=(B(*,NK)*L(NK)+Data(*,i))/(L(NK)+1)
            L(CLUS(I))=L(CLUS(I))-1      ; update cluster size
            CLUS(I)=NK
            L(NK)=L(NK)+1
            e=e+Min                      ; update error
            GotOne=1
          ENDIF
  
     ENDFOR

   if(Not GotOne ) THEN RETURN     ;quit with final Partition if
                                 ;cant relocate to reduce error  
    ENDFOR



RETURN
END
             
            
             
     
  



Pro kmeans,Data1,CLuster,VarName = VarName,CaseName = CaseName,$
          Iter=IT,Number=n,Norm=Nr,Missing=M, List_Name=LN,$
          ClustMeans=CM,ClustSTD=CS,SSBetween=SB,SSWithin=SW,NoPrint=NP


;+
;
; NAME:
;	KMEANS
;
; PURPOSE:
;	To split the cases in Data into n (default=2) groups that have 
;	minimum in  group variation relative to between group variation.
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE: 
;	KMEANS, Data, Cluster, VarName, CaseName
;
; INPUTS: 
;       Data =  a (C,R) dimensioned array where R is
;		the number of cases to be partitioned and C is the number 
;		of variables.
;
; KEYWORDS:
;	Number = the number of clusters in final
;                  partition. The default is 2
;	Iter =   the number of iterations used to assign
;                  cases to clusters. The default is 50.
;	Norm =   flag, if set, to signal whether to
;                  normalize the variable values in Data.
;                  Values normalized only if Norm=1. 
;
;	Missing = missing data value. If undefined,
;                   assume no missing data
;
;	List_Name= name of output file. Default is to
;                    the screen.
;	ClustMeans=array of cluster means. If defined on
;                    entry, CM(i,j) = mean of ith variable
;                     in j th cluster on exit
;	ClustSTD = array of cluster standard deviations.
;                    If defined on entry, CS(i,j) =
;                     standard deviation of ith variable
;                    in jth cluster on exit
;	SSBetween = array of sum of squares  between
;                    clusters. If defined on entry,
;                    SSB(i)= sum of squares for ith
;                    variable.
;	SSWithin = array of sum of squares within clusters.
;                   SSW is the  analogue for SSB
;	VarName= one dimensional array of C variable names
;	CaseName= one dimensional array of R case names
;
; OUTPUT:
;	Summary statistics for each variable for each cluster, overall
;	analysis of variance for each variable.
;
; OPTIONAL OUTPUT PARAMETERS: 
;	Cluster	a one dimensional array. Cluster(i) = the cluster containing
;	case i in the final partition
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
;	Adapted from algorithm in Clustering Algorithms by Hartigan, 
;	Wiley Series in Probablity and Mathematical Statistics, Chapt.4.
;	Function kmeans1 implements a function that given a partition P
;	returns a partition P' in the same neighborhood with reduced in group
;	error.
;
;	Function is called repeatedly until it finds a fixed point or local
;	minimum. Kmeans1 recomputes cluster means after each reassignment.
;           
;	Procedure Kmeans successively finds partitions with the starting 
;	partition for K the final partition for K-1 with the case farthest
;	from its cluster mean split off to form a new cluster.
;-

;on_error,2
 Common KBlock,B
 
 SD=Size(Data1)


 if(N_ELements(LN) EQ 0)THEN  Unit = -1  $
  else openw,unit,/Get,LN
 if(SD(0) NE 2) THEN BEGIN
   printf,unit,  $
   " kmeans- Data must be a two dimensional array."
   goto,Done1
 ENDIF

 Data = Data1 
   
 if (N_Elements(M) EQ 1) THEN BEGIN          
       Data=ListWise(Data,M)
       if N_elements(Data) le 1 THEN $
       if(Data EQ -1) THEN BEGIN
         printf,unit,   $
     "kmeans- halted since all cases have missing data."
         goto,DONE1
       ENDIF
       SD = size(Data)
 ENDIF

 
  
 C=Sd(1)
 if SD(0) eq 1 then R = 1 else R=SD(2)


 if( N_Elements(N) EQ 1) then if(n GT R) THEN BEGIN
   printf,unit, $
 "kmeans- Partition number must not be greater than number of cases"
    goto,DONE1
 ENDIF else PN=n else PN= 2

 if(N_Elements(IT) NE 0) THEN Iter= IT else Iter =50

 if(N_Elements(nr) NE 0) THEN  if ( nr EQ 1) THEN BEGIN
        D=Data
        Data= kmeans_normal1(Data,R,C)  
  ENDIF





  Cluster = Fltarr(R)    ; Clus(i)= cluster containing case i
                         ; initially all cases in same cluster
  Temp=Replicate(1.,C)

  for i=0l,PN-1 DO BEGIN   
                  ; successively, construct cluster partitions
      kmeans1,data,cluster,iter,i+1
      max2=0
      ind1 = -1
      for j=0l,i do begin
                    ;Find case farthest from cluster mean 
          Ind= where(cluster EQ j,count)
          if(count NE 0) THEN BEGIN
             A=Data(*,IND)-B(*,j)#Replicate(1.,count)
             if count eq 1 THEN BEGIN
                here = 0
                max1 = Total(Temp *A^2)
             ENDIF ELSE BEGIN
               max1= max(Temp # (A*A),here)
               here=Ind(here)
            ENDELSE
             if(max1 GT max2) THEN BEGIN
               ind1=here
               max2=max1
             ENDIF
            
          ENDIF
      ENDFOR
 
    if(i NE PN-1 and ind1 ne -1) THEN Cluster(ind1)= i+1

  ENDFOR

 if (N_Elements(NP) EQ 0) THEN                          $
   OutPut1,cluster,Data,CaseName,VarName,unit,SD1,SB1,SW1

 if(N_Elements(CS) NE 0) THEN CS=SD1   
 if(N_Elements(SB) NE 0) THEN SB=SB1   
 if(N_Elements(SW) NE 0) THEN SW=SW1   
 if(N_Elements(CM) NE 0)  THEN CM=B

DONE1:
 if( unit NE -1) Then Free_Lun ,unit    
 RETURN
 END                        ; kmeans
