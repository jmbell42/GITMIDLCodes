; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/set_native_plot.pro#1 $
;
; Copyright (c) 1993-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

PRO SET_NATIVE_PLOT
    ver	= WIDGET_INFO(/version)
    CASE ver.style OF
    	'MS Windows':	SET_PLOT,'WIN'
    	ELSE: 		SET_PLOT,'X'
    ENDCASE
END
