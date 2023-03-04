; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/idldsskiplist__define.pro#1 $
;
; Copyright (c) 1998-2006, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.
;+
; CLASS_NAME:
;	IDLdsSkipList
;
; PURPOSE:
;	An IDLdsSkipList object provides fast lookup for a sorted list.
;
; CATEGORY:
;	Data Structures
;
; SUPERCLASSES:
;       This class has no superclasses.
;
; SUBCLASSES:
;       This class has no subclasses.
;
; CREATION:
;       See IDLdsSkipList::Init
;
; METHODS:
;       Intrinsic Methods
;       This class has the following methods:
;
;       IDLdsSkipList::Cleanup
;       IDLdsSkipList::Find
;       IDLdsSkipList::Init
;       IDLdsSkipList::Insert
;       IDLdsSkipList::MakeEmpty
;       IDLdsSkipList::Remove
;		IDLdsSkipList::Size
;
; MODIFICATION HISTORY:
; 	Written by:	Scott J. Lasica, 11/16/98
;-

;+
; =============================================================
;
; METHODNAME:
;       IDLdsSkipList::Init
;
; PURPOSE:
;       The IDLdsSkipList::Init function method initializes the
;       skip list object.
;
;       NOTE: Init methods are special lifecycle methods, and as such
;       cannot be called outside the context of object creation.  This
;       means that in most cases, you cannot call the Init method
;       directly.  There is one exception to this rule: If you write
;       your own subclass of this class, you can call the Init method
;       from within the Init method of the subclass.
;
; CALLING SEQUENCE:
;       oList = OBJ_NEW('IDLdsSkipList', keys, values)
;
;       or
;
;       Result = oList->[IDLdsSkipList::]Init(keys, values)
;
; INPUTS:
;		keys - The array of keys to initialize the list with.
;
;		values - The array of values to initialize the list with.
;
;		NOTE: keys and values must have the same number of elements.
;
; OUTPUTS:
;       1: successful, 0: unsuccessful.
;
; MODIFICATION HISTORY:
; 	Written by:	Scott J. Lasica, 11/16/98
;-

FUNCTION IDLdsSkipList::Init, keys, values
	if (N_ELEMENTS(keys) gt 0) then begin
		;; Bail if not the same length of inputs
		if (N_ELEMENTS(keys) ne N_ELEMENTS(values)) then return,0

		;; Sort the inputs
		sort_order = SORT(keys)
		keys = keys[sort_order]
	 	values = values[sort_order]

		self.num_nodes = N_ELEMENTS(keys)
		self.keys = PTR_NEW(keys)
		self.values = PTR_NEW(values)
	endif else begin
		self.num_nodes = 0L
	endelse

	return, 1
END

;+
; =============================================================
;
; METHODNAME:
;       IDLdsSkipList::Cleanup
;
; PURPOSE:
;       The IDLdsSkipList::Cleanup procedure method preforms all cleanup
;       on the object.
;
;       NOTE: Cleanup methods are special lifecycle methods, and as such
;       cannot be called outside the context of object destruction.  This
;       means that in most cases, you cannot call the Cleanup method
;       directly.  There is one exception to this rule: If you write
;       your own subclass of this class, you can call the Cleanup method
;       from within the Cleanup method of the subclass.
;
; CALLING SEQUENCE:
;       OBJ_DESTROY, oList
;
;       or
;
;       oList->[IDLdsSkipList::]Cleanup
;
; INPUTS:
;       There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;       There are no keywords for this method.
;
; MODIFICATION HISTORY:
; 	Written by:	Scott J. Lasica, 11/16/98
;-

PRO IDLdsSkipList::Cleanup
	PTR_FREE, self.keys, self.values
END

;+
; =============================================================
;
; METHODNAME:
;       IDLdsSkipList::Find
;
; PURPOSE:
;       The IDLdsSkipList::Find function method is used to return the value for the
;			given key.  If not found, this function returns -1, else 1.
;
; CALLING SEQUENCE:
;       Result = oList->[IDLdsSkipList::]Find( key, value )
;
; INPUTS:
;       key - The scalar key for lookup against the value.
;
; OUTPUTS:
; 		value - The value for the given key.
;
; EXAMPLE:
;       if (oList->Find('myKey', value)) then ...
;
; MODIFICATION HISTORY:
; 	Written by:	Scott J. Lasica, 11/16/98
;-

function IDLdsSkipList::Find, key, value
	comp_idx = long(self.num_nodes/2L)
	prev_idx = -1L
	div_val = comp_idx
	stuck_test = intarr(5)
	stuckidx = 0

	;; We sub-divide the list by 1/2 each iteration through
	while((*self.keys)[comp_idx] ne key) do begin
		prev_idx = comp_idx
		if ((*self.keys)[comp_idx] gt key) then begin
			div_val = div_val/2L + div_val mod 2L
			comp_idx = comp_idx - div_val
			;; Clamp it down to make sure we don't get a negative
			if (comp_idx lt 0) then comp_idx = 0
		endif else begin
			div_val = div_val/2L + div_val mod 2L
			comp_idx = comp_idx + div_val
		endelse
		if (abs(prev_idx-comp_idx) eq 1) then begin
			stuck_test[stuckidx] = 1
			stuckidx = stuckidx + 1
		endif else stuckidx=0
		;; We have split it as much as we can, so test and do the right thing
		if ((prev_idx eq comp_idx) or (total(stuck_test) eq 5)) then begin
			if ((*self.keys)[comp_idx] gt key) then begin
				if ((*self.keys)[(comp_idx-1) > 0] eq key) then begin
					value = (*self.values)[(comp_idx-1) > 0]
					return, 1
				endif
			endif else begin
				if ((*self.keys)[(comp_idx+1) < (self.num_nodes-1)] eq key) then begin
					value = (*self.values)[(comp_idx+1) < (self.num_nodes-1)]
					return, 1
				endif
			endelse
			;; Not in the list
			return, 0
		endif
		;; Another hack to make this work.  All of this will go away when we get a real binary
		;; search tree in IDL
		if (comp_idx ge N_ELEMENTS(*self.keys)) then comp_idx = N_ELEMENTS(*self.keys)-1
	endwhile

	;; Found it, lucky me
	value = (*self.values)[comp_idx]
	return, 1
END

;+
; =============================================================
;
; METHODNAME:
;       IDLdsSkipList::Insert
;
; PURPOSE:
;       The IDLdsSkipList::Insert function method is used to insert a key/value
;      		pair into the list.  It will be inserted in sorted order.  This function
;           will return 1 if successful and -1 if not.
;
; CALLING SEQUENCE:
;       Result = oList->[IDLdsSkipList::]Insert( key, value )
;
; INPUTS:
;       key - The scalar key for insertion.
;
; 		value - The value for the given key.
;
; EXAMPLE:
;       if (oList->Insert('myKey', value)) then ...
;
; MODIFICATION HISTORY:
; 	Written by:	Scott J. Lasica, 11/16/98
;-

function IDLdsSkipList::Insert, key, value
	;; Not implemented for now
	return, 0
END

;+
; =============================================================
;
; METHODNAME:
;       IDLdsSkipList::Size
;
; PURPOSE:
;       The IDLdsSkipList::Size function method returns the number of elements
;			in the list.
;
; CALLING SEQUENCE:
;       Result = oList->[IDLdsSkipList::]Size()
;
; EXAMPLE:
;       num_keys = oList->Size()
;
; MODIFICATION HISTORY:
; 	Written by:	Scott J. Lasica, 11/16/98
;-

function IDLdsSkipList::Size
	return, self.num_nodes
END

;+
; =============================================================
;
; METHODNAME:
;       IDLdsSkipList::MakeEmpty
;
; PURPOSE:
;       The IDLdsSkipList::MakeEmpty procedure method empties the list.
;
; CALLING SEQUENCE:
;       oList->[IDLdsSkipList::]MakeEmpty
;
; EXAMPLE:
;       oList->MakeEmpty
;
; MODIFICATION HISTORY:
; 	Written by:	Scott J. Lasica, 11/16/98
;-

pro IDLdsSkipList::MakeEmpty
	PTR_FREE, self.keys, self.values
	self.num_nodes = 0L
END

;+
; =============================================================
;
; METHODNAME:
;       IDLdsSkipList::Remove
;
; PURPOSE:
;       The IDLdsSkipList::Remove function method removes the key/value
; 			pair from the list if found.
;
; CALLING SEQUENCE:
;       Result = oList->[IDLdsSkipList::]Remove( key )
;
; INPUTS:
;       key - The scalar key for lookup against the value.
;
; EXAMPLE:
;       if (oList->Remove('myKey')) then ...
;
; MODIFICATION HISTORY:
; 	Written by:	Scott J. Lasica, 11/16/98
;-

function IDLdsSkipList::Remove, key
	;; Not implemented
	return, 0
END

;+
;----------------------------------------------------------------------------
; IDLdsSkipList__Define
;
; Purpose:
;  Defines the object structure for an IDLdsSkipList object.
;
; MODIFICATION HISTORY:
; 	Written by:	Scott J. Lasica, 11/16/98
;-

PRO IDLdsSkipList__Define

    COMPILE_OPT hidden

    struct = {  IDLdsSkipList, $
    			num_nodes: 0L, $
    			keys: PTR_NEW(), $
    			values: PTR_NEW(), $
                IDLdsSkipListVersion: 1 $
             }
END







