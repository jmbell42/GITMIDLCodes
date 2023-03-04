; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/svdfunct.pro#1 $

function svdfunct,X,M
;
;       Default function for SVDFIT
;
;       Accepts scalar X and M, returns
;       the basis functions for a polynomial series.
;
        XX=X[0]                 ; ensure scalar XX
	sz=reverse(size(XX))    ; use size to get the type
        IF sz[n_elements(sz)-2] EQ 5 THEN $
		basis=DBLARR(M) else basis=FLTARR(M)
;
;       Calculate and return the basis functions
;
        basis[0]=1.0
        FOR i=1,M-1 DO basis[i]=basis[i-1]*XX
	return,basis
end
