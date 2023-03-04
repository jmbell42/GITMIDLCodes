;^CFG COPYRIGHT UM

pro read_idl_file, filename, npict, nxreg, xreglimits, transform, $
                   nfile, physics, ndim, gencoord, it, time,      $
                   nx, x, xreg, nw, w, wreg, wnames, variables,symmtri

;===========================================================================
;    Read the npict-th picture from an ascii or binary ini or out file 
;
;    Usage: 
;
; .r getpict
;
;    "getpict" will prompt you for "filename(s)" and "npict"
;    unless they are already set. Previous settings can be erased by 
;
; .r defaults
;
;    or modified explicitly, e.g.:
;
; filename='data/example.ini'
; npict=1
;
;    The "x" and "w" arrays and the header info will be read from the file. 
;
;    If a file is read with generalized coordinates, "gencoord=1" is set,
;    and the original data is transformed according to the "transform"
;    string variable into "xreg" and "wreg".
;
;    The same npict-th snapshot can be read from 2 or 3 files by e.g. setting
;
; filename='data/file1.ini data/file2.out'
;
;    In this case the data is read into x0,w0 and x1,w1 for the two files,
;    and possibly transformeed into wreg0,wreg1.
;
;    To plot a variable, type e.g.:
;
; surface,w(*,*,2)
;
;    or 
;
; .r plotfunc
;
;===========================================================================

  nfile=0

  if (n_elements(filename) eq 0) then filename = ''
  if (filename eq '') then begin
    filelist = findfile('*.out')
    if (n_elements(filelist) gt 0) then $
      filename = filelist(n_elements(filelist)-1)
    filename = ask('filename',filename)
  endif

  str2arr,filename,filenames,nfile
  if nfile gt 3 then begin
     print,'Error in GetPict: cannot handle more than 3 files.'
     retall
  endif
  gettype,filenames,filetypes,npictinfiles
  print,'filetype(s)   =','',filetypes
  print,'npictinfile(s)=',npictinfiles
  if (n_elements(npict) eq 0) then npict = -1
  if (npict eq -1) then npict = max(npictinfiles)


  physics=''
  str2arr,physics,physicss,nfile
  physics=''
  for ifile=0,nfile-1 do begin

     phys=physicss(ifile)

     ; Read data from file

     openfile,10,filenames(ifile),filetypes(ifile)

     getpict,10,filetypes(ifile),npict,x,w,headline,phys,it,time,$
            gencoord,ndim,neqpar,nw,nx,eqpar,variables,error

     if (nxreg(0) lt 0.0) then begin

       dxmin = 1000.0
       i = 0L
       for i=0L,nx(0)-2 do $
         if x(i+1,0,0)-x(i,0,0) gt 0 and x(i+1,0,0)-x(i,0,0) lt dxmin then $
           dxmin = x(i+1,0,0)-x(i,0,0)
       nxreg=abs(nxreg)/dxmin+1

     endif

     if (strlen(phys) lt 1) then phys = ask('physics (eg. mhd12)','')
     physicss(ifile)=phys
     physics=physics + phys + ' '

     if nfile gt 1 then begin
       case ifile of
       0: begin
            w0=w
            x0=x
          end
       1: begin
            w1=w
            x1=x
          end
       2: begin
            w2=w
            x2=x
          end
       endcase
       print,'Read x',ifile,' and w',ifile,FORMAT='(a,i1,a,i1)'
     endif else print,'Read x and w'

     readtransform,ndim,nx,gencoord,transform,nxreg,xreglimits,wregpad,$
		physics,nvector,vectors,grid,0

     if (gencoord and (transform eq 'polar' or transform eq 'regular')) or $
        (not gencoord and transform eq 'unpolar') then begin
        if nfile eq 1 then $
             print,'...transform to xreg and wreg' $
        else print,'...transform to xreg and wreg',ifile,FORMAT='(a,i1)'
        case transform of
           'regular':regulargrid,x_old,nxreg_old,xreglimits_old,$
                     x,xreg,nxreg,xreglimits,w,wreg,nw,wregpad,triangles,symmtri
           'polar'  :begin
                       polargrid,nvector,vectors,x,w,xreg,wreg
                       variables(0:1)=['r','phi']
                     end
  	   'unpolar':begin
                       unpolargrid,nvector,vectors,x,w,xreg,wreg
                       variables(0:1)=['x','y']
                     end
           else     :print,'Unknown value for transform:',transform
        endcase

        if nfile gt 1 then case ifile of
           0: wreg0=wreg
           1: wreg1=wreg
           2: wreg2=wreg
        endcase
     endif
  endfor
  close,10

  ; Produce a wnames from the last file
  wnames=variables(ndim:ndim+nw-1)

end

