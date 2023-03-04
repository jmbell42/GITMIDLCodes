;+
; NAME:
;   MGH_FILE_COPY
;
; PURPOSE:
;   This procedure reads the contents of a file & writes them to
;   another file.
;
; CALLING SEQUENCE:
;   MGH_FILE_COPY, InFile, OutFile
;
; POSITIONAL PARAMETERS:
;   infile (input, scalar string)
;     Input file name.
;
;   outfile (input, scalar string)
;     Output file name.
;
; KEYWORD PARAMETERS:
;   BUFSIZE (input, scalar integer)
;     This keyword has an effect only when the TEXT keyword *is not*
;     set. It specifies the size (in bytes) of chunks read &
;     written. Default is 2^16 (64kiB)
;
;   GUNZIP (input, logical)
;     If this keyword is set, read compressed data.
;
;   GZIP (input, logical)
;     If this keyword is set, write compressed data.
;
;   TEXT (input, logical)
;     If this keyword is set, treat the file as a text file,
;     transferring data line-by-line with formatted
;     read/writes. Otherwise, transfer data via a buffer with
;     unformatted read/writes of byte data.
;
;   UNIX (input, logical)
;     This keyword has an effect only when the TEXT keyword *is*
;     set. When UNIX is set, the lines of text are written via
;     unformatted writes terminated with a 10B character. Thus
;     Unix-format files are produced on all platforms.
;
;   YIELD (input, logical)
;     If this keyword is set, yield control regularly throughout the
;     transfer.
;
; SIDE EFFECTS:
;   A new file is created.
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
;   Mark Hadfield, 1997-01:
;     Written.
;   Mark Hadfield, 1999-09:
;     Added GZIP, GUNZIP & TEXT functionality.
;   Mark Hadfield, 2000-08:
;     With the move to version 5.4, removed BINARY keyword in calls
;     to OPENR & OPENW. this should make the procedure portable to
;     non-Windows platforms.
;   Mark Hadfield, 2000-10:
;     Worked around EOF bug in IDL 5.4 beta by changing EOF to
;     MGH_EOF (which see).
;   Mark Hadfield, 2000-11:
;     EOF bug fixed in IDL 5.4 final so MGH_EOF changed back to
;     EOF.
;   Mark Hadfield, 2001-07:
;     Updated for IDL 5.5.
;   Mark Hadfield, 2002-11:
;     Added YIELD keyword--yielding is done via an MGH_Waiter object.
;   Mark Hadfield, 2003-01:
;     Yielding is now turned on by default and is done via a call to
;     widget_event.
;   Mark Hadfield, 2005-02:
;     Fixed bug: binary NOT operator used when the LOGICAL_PREDICATE
;     compile option is in effect.
;-

pro MGH_FILE_COPY, InFile, OutFile, $
     BUFSIZE=bufsize, GUNZIP=gunzip, GZIP=gzip, TEXT=text, $
     UNIX=unix, VERBOSE=verbose, YIELD=yield

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(yield) eq 0 then yield = 1B

   if keyword_set(gunzip) then compress_in = 1B

   if keyword_set(gzip) then compress_out = 1B

   openr, inlun, InFile, /GET_LUN, COMPRESS=compress_in
   openw, outlun, OutFile, /GET_LUN, COMPRESS=compress_out

   if keyword_set(verbose) then begin
      fs = fstat(inlun)
      msg = string(FORMAT='("Copying file ",A," (",F0.3," MiB) to ",A)', $
                   infile, 2.^(-20)*fs.size, outfile)
      message, /INFORM, temporary(msg)
   endif

   case keyword_set(text) of

      1: begin

         while ~ eof(inlun) do begin

            if keyword_set(yield) then void = widget_event(/NOWAIT)

            sline = ''

            readf, inlun, sline
            case keyword_set(unix) of
               0: printf, outlun, sline
               1: writeu, outlun, sline, string(10B)
            endcase

         endwhile

      end

      0: begin

         if n_elements(bufsize) eq 0 then bufsize = 2^16

         buf = bytarr(bufsize)

         catch, err
         if err ne 0 then goto, caught_err_binary

         while ~ eof(inlun) do begin
            if keyword_set(yield) then void = widget_event(/NOWAIT)
            readu, inlun, buf
            writeu, outlun, buf
         endwhile

         caught_err_binary:
         catch, /CANCEL
         if err ne 0 then begin
            case !error_state.name of
               'IDL_M_FILE_EOF' : begin
                  info = fstat(inlun)
                  if info.transfer_count gt 0 then $
                       writeu, outlun, buf[0:info.transfer_count-1]
               end
               else: begin
                  help, /STRUCT, !error_state
                  message, 'Unexpected error'
               end
            endcase
         endif

      end

   endcase

   free_lun, inlun
   free_lun, outlun

end


