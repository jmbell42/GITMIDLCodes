; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/maketree.pro#1 $
;
;  Copyright (c) 1993-2006, Research Systems Inc.  All rights
;  reserved. Unauthorized reproduction prohibited.

pro Adjust, sim, imin, N
for i = N-1,2*N do  $
  if Sim(i) ge Sim(imin(i)) - 1 THEN   $
     Sim(imin(i)) = Sim(i) + 2
return
end

 pro PutV,X,V
    
 if V(0) EQ -1 THEN V=[X]      $
    ELSE V = [X,V]
 RETURN
 END         ;PutV

 pro RemoveV,V

 if (N_Elements(V) GT 1) THEN V = V(1:*)         $
 ELSE V=-1

 RETURN
 END
   
 Pro maketree,pos,Imin,Sim,unit,CaseName=CasName, Width = LS
;+
; NAME: 
;	MAKETREE
;
; PURPOSE:
;	MakeTree constructs a tree representation of the nested clusters
;	created by the join procedure. 
;
; CATEGORY:
;	Statistics.
;
; CALLING SEQUENCE:
;	MAKETREE, Pos, Imin, Sim [, Unit]
;
; INPUT:
;	Pos(i):	The position of the ith case as a leaf in the tree to be 
;		constructed.
;
;      Imin(i):	The smallest cluster to strictly contain the case or object i.
;
;      Sim (i):	A measure of similarity among the objects in cluster i.
;
; OPTIONAL INPUT PARAMETERS:
;	Unit:	The file unit for output.  Default is to the screen.
;
; KEYWORDS:
;	WIDTH:	User-supplied tree width in characters.  The default is 60.
;		MAKETREE tries to fit the tree into the specified width.
;
;     CASENAME:	User-supplied vector of case names to be used in the output.
;         
;
; PROCEDURE:
;	We scan the cases in the order they appear in the tree.
;	A list V is maintained of strictly increasing clusters to be
;	used to determine which cluster should appear in the gap 
;	between case i and case i+1.  Each cluster in V contains at
;	least one case that has been scanned. 
;-

 if(N_elements(unit) EQ 0) THEN unit =-1 
   

 N=N_Elements(pos)         ; N= # of cases
 M= 2*N-2                  ; M = Last cluster
 NC=size(CasName)

mx=max(Sim)
Sim(M+1) = mx; assign length to final branch from
                         ; largest cluster
 

 if N_Elements(LS) EQ 0 THEN LS = 60 
 if (NC(0) NE 0 ) THEN BEGIN   
                             ;check and, maybe, fix case names
   CaseName=CasName
   if (NC(1) LT N) THEN BEGIN
     printf,unit,'kmeans-missing Case names'
     I=Indgen(N)
     CaseName=[CaseName,'Case'+STRTRIM(I(NC(1):N-1),2.)]
   ENDIF
 ENDIF ELSE CaseName= 'Case'+STRTRim(INDgen(N),2)
 

 Visited=Intarr(M+1)   ; Visited(i)=0,if cluster i is not in V
                       ;           =1, if in list and has one
                       ;                branch
                       ;           =-1,if in list but no
                       ;                 branches
                    


P=INtarr(N)
P(Pos)=INDGEN(N)         ; P(i)= ith case in tree
;Sim(0) = Sim(2*N)
If(N_ELEMENTS(unit) EQ 0) THEN unit = -1

;if N_ELEMENTS(RL) EQ 0 THEN BEGIN
  mn = min(Sim)
  Sim1=Fix((Sim-mn) *((LS-3)/(mx-mn)))+1
; ENDIF ELSE BEGIN
;  sim1 = sim
;  Sim1(sort(sim)) = (INDGEN(2*N) + LS -2*N)>1
 ;ENDELSE

 Adjust, Sim1, Imin, N-1        ;add length to branches where needed
                         ;because of closeness.
Sim1(0) = Sim1(2*N-2) + 2

 Gap=INTarr(N)           ; Gap(i)= Cluster # between i and i+1



 for i = 1l,N-1 DO BEGIN    ; Make Gap
     Here=Imin(P(i-1)) 
                     ; Here = smallest cluster containing P(i)

     if (i EQ 1 ) THEN BEGIN  ;Try to put first 3 smallest
                              ;clusters containing i on V
        V=[HERE,IMIN(HERE)]
        Visited(HERE)=1
        Visited(Imin(HERE))=1
        Gap(1)=IMin(HERE)              ;second smallest in gap
        if(i LT N-1) THEN BEGIN
           V=[V,IMin(IMin(HERE))]
           Visited(Imin(Imin(here)))=-1
                
        ENDIf
    ENDIF ELSE BEGIN




          CASE Visited(HERE) OF




          1:BEGIN                ;smallest containing cluster 
                                        ; has first branch


            ;V=V(1:*)            ;remove it from list 
            RemoveV,V
            Gap(i)= V(0)         ;make sur parent has a
                                 ; branch before closing

if Visited(Gap(i)) and N_elements(V) GT 1 THEN BEGIN
                         ; To assure closure of large cluster
               Gap(i) =V(1)
               Off = V(0)
               V=V(1:*)
             ENDIF else OFF=-1



            Case Visited(Gap(i)) OF

            1:BEGIN
               GI=IMIN(Gap(i))

                    if(Visited(GI) EQ -1) THEN Gap(i)=GI  $
                    ELSE RemoveV,V 

                   if(i LE N-2) THEN BEGIN
                    GI=IMIN(Gap(i))

                   if (Visited(GI) EQ 0) THEN BEGIN
                    if Visited(Gap(i)) EQ -1 THEN BEGIN
                      if(N_Elements(V) GE 3) THEN      $
                            V=[V(0:1),GI,V(2:*)]    $
                      ELSE IF V(0) NE -1 THEN V=[V,GI]    $
                           ELSE V= [GI]
                    ENDIF ELSE if N_Elements(V) EQ 0      $
                                THEN V=[GI] ELSE V=[GI,V]
                    Visited(GI)=-1
                  ENDIF
               ENDIF
             END

            ELSE :  BEGIN
                    
                    if(i LE N-2) THEN BEGIN
                      GI=IMIN(Gap(i))
                      if (Visited(GI) EQ 0) THEN BEGIN
                       if N_Elements(V) EQ 1 THEN     $
                         V=[V(0),GI] ELSE V=[V(0),GI,V(1:*)]
                       Visited(GI)=-1
                      ENDIF
                    ENDIF
                   END

        ENDCASE

        Visited(Gap(i))=1
        if Off NE -1 THEN PutV,OFF,V            
        END                            ;Case Visited(Here)=1


          ELSE:BEGIN 
               Gap(i)=IMIN(HERE)
               if Gap(i) eq Gap(i-1) THEN BEGIN
                 Gap(i) = IMIN (Gap(i))
               endif
           
              Visited(Here)=1

              if Visited(Gap(i)) EQ 1 and N_elements(V) GT 1 $
               THEN  V=V(1:*)
              if(i LE N-2) THEN BEGIN
                 GI=IMIN(Gap(i))
                 if (Visited(GI) EQ 0) THEN BEGIN
                    if V(0) EQ -1 THEN  V=[GI] ELSE V=[GI,V] 
                            Visited(GI)=-1
                  ENDIF
              ENDIF

             if Visited(Gap(i)) EQ 0 THEN PutV,Gap(i),V
             Visited(Gap(i))=1
             PutV,Here,V
             END
      ENDCASE
    ENDELSE
 ENDFOR



             
  Visited(*)=0
  Visited(0)=1
  Wid = max(Sim1)
  Str=Bytarr(10 + wid)
printf,unit,Format='(40X,"Similarity")
;printf,unit,'          1___________________________________________________________________0'
ST1 = bytarr(wid)
ST1(0:wid-1) = BYTE("_")
printf,unit,'         '+'1' + string(ST1) + '0'

  for i=1l,n DO BEGIN
      printf,unit,Format='(A10,$)',CaseName(P(i-1))
      Here=Imin(P(i-1))
      S1=fix(Sim1(Here))
      Str(0:S1)=Byte("-")
      S=String(Str)
      printf,unit,S
      Str(0:S1)=Byte(" ")

     if(i NE n) THEN BEGIN

      if(Visited(Here) EQ 0)THEN BEGIN
        Str(S1)=Byte("|")
        Visited(Here)=1
      ENDIF ELSE Str(S1)=Byte(" ")
        S=String(str)  

       ;printf,unit,'          ',S

          
      S2=fix(Sim1(Gap(i)))

       m=max(Str,gapStart)
      if( gapStart+1 LE S2) THEN         $
        Str(gapStart+1:S2)=Byte( "-")    $
      else Str(S2:S2) = Byte( "-")
      S=String(Str)

      printf,unit,'          ',S
                                    
     if ( gapStart+1 LE S2) THEN   $
       Str(gapstart+1:S2)=Byte( " ")      $
     else Str(S2:S2) = Byte(" ")

     if (Visited(Gap(i)) EQ 0) THEN BEGIN
       Str(S2)=Byte("|")
       Visited(Gap(i))=1
     ENDIF ELSE Str(S2)=Byte(" ")
      S=String(str)


      ;printf,unit,'          ',S
                            
    ENDIF
 ENDFOR




  RETURN
  END
