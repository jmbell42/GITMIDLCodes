;+
; NAME:
;   MGH_NCDF_RESTORE
;
; PURPOSE:
;   This function retrieves data from a netCDF file (or sequence thereof)
;   in the form of an IDL structure
;
; CATEGORY:
;   NetCDF
;
; CALLING SEQUENCE:
;   result = MGH_NCDF_RESTORE(file, variables)
;
; POSITIONAL PARAMETERS:
;   file (input, string, scalar or vector)
;     A list of netCDF file names. This list is passed to the Init
;     routine for the netCDF file object.
;
;   variables (input, string, scalar or vector, optional)
;     A list of variable names. Default is all variables in the file(s).
;
; KEYWORD PARAMETERS:
;   AUTOSCALE (input, switch)
;     Passed to the netCDF object's Retrieve method to determine whether
;     data are automatically scaled.
;
;   COUNT (output, integer)
;     This keyword returns the number of variables for which data have
;     been returned.
;
;   NETCDF_CLASS (input, string, scalar)
;     The class of the netCDF file object to be created. Permissible
;     values are 'MGHncFile', 'MGHncReadFile' and
;     'MGHncSequence'. The default is 'MGHncSequence'.
;
;   POINTER (input, switch)
;     Passed to the netCDF object's Retrieve method to determine whether
;     the output structure includes the data values or pointers to them.
;
;   Other keywords are passed to the netCDF object's Init method via
;   inheritance.
;
; RETURN VALUE:
;   The function returns an anonymous structure, with one tag per
;   variable.
;
; PROCEDURE:
;   An netCDF file object is created, its Retrieve method called and
;   the object then destroyed.
;
;###########################################################################
;
; This software is provided subject to the following conditions:
;
; 1.  NIWA makes no representations or warranties regarding the
;     accuracy of the software, the use to which the software may
;     be put or the results to be obtained from the use of the
;     software.  Accordingly NIWA accepts no liability for any loss
;     or damage (whether direct of indirect) incurred by any person
;     through the use of or reliance on the software.
;
; 2.  NIWA is to be acknowledged as the original author of the
;     software where the software is used or presented in any form.
;
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield, 14 Mar 1994:
;     Written as NCDF_RESTORE.
;   Mark Hadfield, Apr 1997:
;     Rewritten to use the MGHncFile class.
;   Mark Hadfield, May 1998:
;     Extra keywords now passed to MGHncFile.
;   Mark Hadfield, Nov 2000:
;     Renamed MGH_NCDF_RESTORE, updated, moved to public directory,
;     added NETCDF_CLASS keyword & associated functionality.
;   Mark Hadfield, 2001-07:
;     Updated for IDL 5.5.
;   Mark Hadfield, 2005-09:
;     Added POINTER keyword.
;-
function mgh_ncdf_restore, file, variables, $
     AUTOSCALE=autoscale, COUNT=count, NETCDF_CLASS=netcdf_class, POINTER=pointer, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   ;; No argument checking here because it is carried out by the
   ;; netCDF object's Init & Retrieve methods.

   if n_elements(netcdf_class) eq 0 then netcdf_class = 'mghncsequence'

   onc = obj_new(netcdf_class, file, _STRICT_EXTRA=extra)

   result = onc->Retrieve(variables, AUTOSCALE=autoscale, COUNT=count, POINTER=pointer)

   obj_destroy, onc

   return, result

end

