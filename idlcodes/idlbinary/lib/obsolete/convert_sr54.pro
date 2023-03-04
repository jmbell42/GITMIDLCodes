; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/convert_sr54.pro#1 $
;
; Copyright (c) 2001-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;       CONVERT_SR54
;
; PURPOSE:
;       Convert IDL Save/Restore files written by IDL 5.4 using 64-bit
;       offsets to the IDL 5.5 (and newer) format that is readable by
;       older non-64-bit capable versions of IDL.
;
;	This routine is intentionally written using a subset of IDL
;	that is accepted by all versions beginning with IDL 5.2. It
;	requires the use of 64-bit integers, which were not available
;	in versions earlier than that.
;
; CATEGORY:
;       Format change impact mitigation.
;
; CALLING SEQUENCE:
;       CONVERT_SR54, ExistingSRFile, NewSRFile
;
; INPUTS:
;       ExistingSRFile - Name of existing Save/Restore file.
;       NewSRFile - Name of new Save/Restore file to be created.
;
; OUTPUTS:
;       None
;
; COMMON BLOCKS:
;       None.
;
; SIDE EFFECTS:
;       The file NewSRFile is created. This file contains the same
;       data as ExistingSRFile, but has its 64-bit offsets encoded
;       using the format supported by IDL 5.5 and newer. Such files
;       are readable by older non-64-bit capable versions of IDL
;       *AS LONG AS THE LENGTH OF THE FILE DOES NOT EXCEED 2.1 GB
;       IN LENGTH*.
;
;        ------------------------------------------------------------
;       | WARNING: Please verify that your converted data is correct |
;       | before destroying the original data file.                  |
;        ------------------------------------------------------------
;
; MODIFICATION HISTORY:
;       5 March 2001, AB
;
; FULL EXPLANATION:
;       With IDL 5.4, RSI released versions of IDL that are 64-bit
;       capable. The original IDL Save/Restore format uses 32-bit
;       offsets. In order to support 64-bit memory access, it was necessary 
;       modify the IDL Save/Restore file format in order to allow the
;       use of 64-bit offsets within the file, while retaining the ability
;       to read old files that use the 32-bit offsets. The method chosen
;       to to do this is as follows:
;
;           - In IDL versions capable of writing large files
;             (!VERSION.FILE_OFFSET_BITS eq 64), SAVE writes a
;             special command at the beginning of the file that switches
;             the format from 32 to 64-bit.
;           - SAVE always starts reading any save file using 32-bit
;             offsets. If it sees the 64-bit offset command, it switches
;             to 64-bit offsets for any commands following that one.
;
;       This scheme is fully backwards compatible, in the sense that any
;       IDL program can read any Save/Restore file created by it, or by
;       any earlier version of IDL. However, files produced by IDL 5.4
;       with the 64-bit offsets are not readable by older versions of IDL.
;
;       After release of IDL 5.4, it became apparent that IDL users
;       commonly transfer Save/Restore data files written by newer
;       IDL versions to sites where they are RESTOREd by older versions
;       of IDL. In other words, new files being input by old programs.
;       In general, it is not reasonable to expect this to work, and it
;       does not fit the usual definition of backwards compatibility.
;       However, RSI strives to avoid breaking such compatibility
;       gratuitously, and in this spirit, we have taken the following
;       steps for IDL 5.5 to minimize these problems:
;
;           1) We have changed the way in which 64-bit offsets are
;              encoded. Save/Restore files written by IDL 5.5 and newer
;              will be readable by any older version of IDL, as long
;              as the data in that file does not exceed 2.1 GB in length.
;
;           2) IDL 5.5 and newer retain the ability to read the 64-bit offset
;              files produced by IDL 5.4.x, so backwards compatibility is
;              ensured.
;
;           3) Save/Restore files written by IDL 5.5 or newer, which
;              contain data longer than 2.1GB in length are not readable
;              by older versions of IDL, but will be readable by IDL 5.5
;              and newer versions of IDL that have !VERSION.MEMORY_BITS equal
;              to 64.
;
;           4) The CONVERT_SR54 procedure can be used to convert Save/Restore
;              files written by IDL 5.4 into the newer IDL 5.5 format. This
;              allows existing data files to become readable by older IDL
;              versions.
;-
;
;

pro convert_sr54_copy, from, to, n

  ;COMPILE_OPT hidden

  ; Big enough to be reasonably efficient, small enough not to be a problem
  bufsize=524288

  ; Step 1: Copy sections of data greater than bufsize in length
  ; in multiple bufsize operations.
  if (n ge bufsize) then begin
    buf = bytarr(bufsize)
    while (n ge bufsize) do begin
      readu, from, buf
      writeu, to, buf
      n = n - bufsize
    endwhile
  endif

  ; Step 2: If anything is left, it is less than bufsize bytes. Handle it
  ; in a single operation.
  if (n gt 0) then begin
    buf = bytarr(n)
    readu, from, buf
    writeu, to, buf
  endif
end



pro convert_sr54, ExistingSRFile, NewSRFile

  ; IMPORTANT WARNING: This routine reveals details of a file format
  ; that is proprietary to Research Systems, Inc, and which is not
  ; publically documented. Research Systems reserves the right to make
  ; changes to this format without notice. You should not make use of
  ; the information revealed here in other code, unless you fully
  ; understand that your code can break at any time without warning.

  on_error, 2		; Return to caller

  openr, iunit, ExistingSRFile, /GET_LUN, /SWAP_IF_LITTLE_ENDIAN
  id=0L
  offset32=0l
  offset64=0ll
  w1 = 0l
  w2 = 0l
  do64=0

  readu, iunit, id
  if (id ne 1397882884) and (id ne 1397882886) then begin
    free_lun, iunit
    message, 'Unable to convert unrecognized savefile format: ' $
	+ ExistingSRFile
  endif

  openw, ounit, NewSRFile, /GET_LUN, /SWAP_IF_LITTLE_ENDIAN
  writeu, ounit, id

  bias = 0LL
  while (not eof(iunit)) do begin
    point_lun, -iunit, curpos		; Where are we right now?
    if (do64) then begin
      readu, iunit, id, offset64, w1, w2
      dlen = offset64 - curpos - 20
      bias = bias + 4
      offset64 = offset64 - bias
      offset32 = long(offset64)
      w1 = long(ishft(offset64, -32))
    endif else begin
      readu, iunit, id, offset32, w1, w2
      dlen = offset32 - curpos - 16
      offset32 = offset32 - long(bias)
    endelse
    if (id eq 17) then begin
      ;print, 'IS 64 BIT FILE'
      do64=1
      bias = bias + 20
      if (dlen gt 0) then begin			; Happens with compression
	tmp = bytarr(dlen)
        readu, iunit, tmp
      endif
    endif else begin
      if (id eq 6) then begin
        offset32 = 0L
        w1 = 0L
      endif
      writeu, ounit, id, offset32, w1, w2	; section header
      if (id eq 6) then goto, done		; Bail, if final section
						; section data
      if (dlen gt 0) then convert_sr54_copy, iunit, ounit, dlen
    endelse
  endwhile

done:
  free_lun, iunit, ounit
end
