; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/time_test.pro#1 $
;
; Copyright (c) 1986-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.

;	Time test procedure.. Print values of commonly used timings.
pro time_test_timer, name	;Print timing information, name = descriptive
;	string for message.

COMPILE_OPT hidden, strictarr
common timer_common, time, lunno, total_time, geom_time, ntest, demomode

t = systime(1)		;Get current time.
ntest = ntest + 1
tt = t - time
total_time = total_time + tt
geom_time = geom_time + alog(tt > (machar()).xmin)

IF (demomode) THEN print, ntest, float(tt), ' ', name $
ELSE printf, lunno, ntest, float(tt), ' ',name

time = systime(1)	;Starting time for next test
end

pro time_test_init,file	;Initialize timer, file = optional param
;	containing name of file to write info to
COMPILE_OPT hidden, strictarr
common timer_common, time, lunno, total_time, geom_time, ntest, demomode

on_error,2              ;Return to caller if an error occurs

total_time = 0.
geom_time = 0.
ntest = 0

quiet=!quiet
!quiet=1
demomode=LMGR(/DEMO)
!quiet=quiet

if (n_params(0) ge 1) AND (NOT demomode) then begin
	get_lun, lunno	;Get a lun
	openw,lunno,file
  end else lunno = -1	;Set to stdout
time = systime(1)
return
end



pro time_compare, files, outfile, THRESHOLD = threshold
;Compare results of two time tests...
; Files = array of file names containing output of each test
; Outfile = filename for output. If omitted, only output to log window.
; THRESHOLD = comparison threshold, values outside the range of 1.0
; 	plus or minus threshold are flagged.  Default = 0.15 = 15%.
; A report is printed..
;
; For example:  TIME_COMPARE, FILE_SEARCH('time*.dat'), 'junk.lis'
;
COMPILE_OPT hidden, strictarr

if n_elements(threshold) le 0 then threshold = 0.15

nf = n_elements(files)		;# of files

nmax = 100			;Max number of tests.
t = fltarr(nf, nmax)
names = strarr(nmax)

for j=0, nf-1 do begin		;Read each file
    openr, lun, /get, files[j]
    b = ''
    m = 0			;Test index
    while not eof(lun) do begin
	readf, lun, b
;Ignore lines containing "Total Time" and the | character.
        if strpos(b, '|') ge 0 then $
            print, files[j], b, format="(a10, ': ', a)" $
        else if (strpos(b, 'Total Time') lt 0) then begin
	    a1 = strcompress(b)
	    k = strpos(a1, ' ', 1)
	    t[j,m] = float(strmid(a1, k+1, 100))
	    k = strpos(a1, ' ', k+1)
	    label = strmid(a1, k+1, 100)
	    if j eq 0 then names[m] = label $
	    else if label ne names[m] then $
		print,'Tests are inconsistent: ', names[m], label
	    m = m + 1
	    endif
    endwhile
    free_lun, lun
endfor

nr = m+1			;New # of rows
t = t[*,0:nr]			;Truncate
names = names[0:nr]
t[0,m] = total(t,2)		;Column sums
names[m] = 'Total Time'
;		Geometric mean
for i=0, nf-1 do t[i,nr] = exp(total(alog(t[i,0:m-1])) / m)
names[nr] = 'Geometric mean'

luns = -1
if n_elements(outfile) gt 0 then begin
    openw, i, /get, outfile
    luns = [luns, i]
    endif
fmt = '(f8.2,'+strcompress(nf)+'i8, 3x,a)'

slen = 80 - 12 - 8*nf > 10

for file = 0, n_elements(luns)-1 do begin
  printf, luns[file]
  printf, luns[file] , ['Time',strmid(files, 0, 7)], format='(10A8)'

  for j=0,nr do begin
     fast = min(t[*,j])
     tt = round(t[*,j] / fast * 100.)
     s = string(fast, tt, strmid(names[j],0,slen-1), format=fmt)
     for k=0, nf-1 do begin
	p  = 8+(k+1)*8		;Char pos
	if t[k,j] gt (1.0+threshold) * fast then strput, s, '*', p
	if t[k,j] eq fast then strput, s, '^', p
	endfor
     printf, luns[file], s
    endfor
  printf, luns[file], ' '
  printf, luns[file], '^ = fastest.'
  printf, luns[file], '* = Slower by '+strtrim(fix(threshold*100),2) + $
		'% or more.'
  printf, luns[file], systime(0)
  endfor		;File
if n_elements(outfile) gt 0 then free_lun, luns[1]
end





pro time_test_reset,dummy	;Reset timer, used to ignore set up times...
; No-op this procedure to include setup times mainly comprise
; the time required to allocate arrays and to set them to
; a given value.

COMPILE_OPT hidden, strictarr
common timer_common, time, lunno, total_time, geom_time, ntest, demomode

time = systime(1)
return
end

pro time_test_dummy,dummy
COMPILE_OPT hidden, strictarr
return
end


pro graphics_times2_internal, filename
; Time common graphics operations in the same manner as time_test  (REVISED)

COMPILE_OPT hidden, strictarr
common timer_common, time, lunno, total_time, geom_time, ntest, demomode

on_error,2                      ;Return to caller if an error occurs
if (!d.x_size ne 640) or (!d.y_size ne 512) then $
	window, xs=640, ys=512	;Use the same size window for fairness.
if n_params() gt 0 then time_test_init,filename else time_test_init

; Print header
IF (demomode) THEN BEGIN
    PRINT,'|GRAPHICS_TIMES2 performance for IDL ',!VERSION.RELEASE,' (demo):'
    PRINT,'|       OS_FAMILY=',!VERSION.OS_FAMILY, $
          ', OS=',!VERSION.OS,', ARCH=',!VERSION.ARCH, ' '
    PRINT ,'|	', systime(0)
ENDIF ELSE BEGIN
    PRINTF,lunno,'|GRAPHICS_TIMES2 performance for IDL ',!VERSION.RELEASE, ':'
    PRINTF,lunno,'|       OS_FAMILY=',!VERSION.OS_FAMILY, $
                 ', OS=',!VERSION.OS,', ARCH=',!VERSION.ARCH, ' '
    PRINTF,lunno,'|	', systime(0)
ENDELSE

for i=1,10 do begin
	plot,[0,1]+i
	empty
	endfor
time_test_timer,'Simple plot, 10 times'

n = 1000
x = randomu(seed, n) * (2 * !pi)
y = fix((sin(x)+1) * (0.5 * !d.y_vsize))
x = fix((cos(x)+1) * (0.5 * !d.x_vsize))
for i=1,20 do begin
	erase
	empty
	plots,x,y,/dev
	empty
	endfor
time_test_timer,strtrim(n,2) + ' vectors x 100'

n = 50
plot,[-1,1],[-1,1]

for i=3,n do begin
	x = findgen(i) * ( 2 * !pi / i)
	erase
	polyfill,sin(x),cos(x)
	for j=1,i do begin
	    xx = randomu(seed, 3)
	    yy = randomu(seed, 3)
	    polyfill, xx, yy, /norm, color = !d.table_size/2
	    endfor
	empty
	endfor
time_test_timer,'Polygon filling'

n = 512
a = findgen(n) * (8 * !pi / n)
c = bytscl(sin(a) # cos(a), top = !d.table_size-1)
d = not c
erase
time_test_reset
for i=1,5 do begin
	tv,c
	empty
	tv,d
	empty
	endfor
time_test_timer,'Display 512 x 512 image, 10 times'
;for i=1,10 do begin
;	c = 0
;	c = tvrd(0,0,512,512)
;	endfor
;time_test_timer,'Read back 512 by 512 image, 10 times'

IF (demomode) THEN $
  print, float(total_time),'=Total Time, ', $
	exp(geom_time / ntest), '=Geometric mean,',ntest,' tests.' $
ELSE printf, lunno, float(total_time),'=Total Time, ', $
	exp(geom_time / ntest), '=Geometric mean,',ntest,' tests.'

if lunno gt 0 then free_lun,lunno
wdelete
end



pro graphics_times3_internal, filename
; Time common graphics operations in the same manner as time_test  (REVISED)

COMPILE_OPT hidden, strictarr
common timer_common, time, lunno, total_time, geom_time, ntest, demomode

on_error,2                      ;Return to caller if an error occurs
if (!d.x_size ne 640) or (!d.y_size ne 512) then $
	window, xs=640, ys=512	;Use the same size window for fairness.
if n_params() gt 0 then time_test_init,filename else time_test_init
a = dist(2)                     ;So we don't get "COMPILED DIST message"

; Print header
IF (demomode) THEN BEGIN
    PRINT,'|GRAPHICS_TIMES3 performance for IDL ',!VERSION.RELEASE,' (demo):'
    PRINT,'|       OS_FAMILY=',!VERSION.OS_FAMILY, $
          ', OS=',!VERSION.OS,', ARCH=',!VERSION.ARCH, ' '
    PRINT,'|	', systime(0)
ENDIF ELSE BEGIN
    PRINTF,lunno,'|GRAPHICS_TIMES3 performance for IDL ',!VERSION.RELEASE, ':'
    PRINTF,lunno,'|       OS_FAMILY=',!VERSION.OS_FAMILY, $
                 ', OS=',!VERSION.OS,', ARCH=',!VERSION.ARCH
    PRINTF,lunno,'|	', systime(0)
ENDELSE

for i=1,30 do begin
	plot,sin(findgen(100)/(2+i))
	empty
	endfor
time_test_timer,'Simple plot, 30 times'

n = 1000
x = randomu(seed, n) * (2 * !pi)
y = fix((sin(x)+1) * (0.5 * !d.y_vsize))
x = fix((cos(x)+1) * (0.5 * !d.x_vsize))
for i=1,20 do begin
	erase
	empty
	plots,x,y,/dev
	empty
	endfor
time_test_timer,strtrim(n,2) + ' vectors x 100'

n = 50
plot,[-1,1],[-1,1]

for i=3,n do begin
	x = findgen(i) * ( 2 * !pi / i)
	erase
	polyfill,sin(x),cos(x)
	for j=1,i do begin
	    xx = randomu(seed, 3)
	    yy = randomu(seed, 3)
	    polyfill, xx, yy, /norm, color = !d.table_size/2
	    endfor
	empty
	endfor
time_test_timer,'Polygon filling'

n = 512
a = findgen(n) * (8 * !pi / n)
c = bytscl(sin(a) # cos(a), top = !d.table_size-1)
d = not c
erase
time_test_reset
for i=1,5 do begin
	tv,c
	empty
	tv,d
	empty
	endfor
time_test_timer,'Display 512 x 512 image, 10 times'

for i=1,2 do surface, dist(128)
time_test_timer,'Surface 128x128, 2 times'

for i=1,2 do shade_surf, dist(128)
time_test_timer,'Shaded surface 128x128, 2 times'


erase
nrep = 500
for i=0L, nrep do begin
    siz  = randomn(seed) + 1 > .4
    str = string(byte(randomu(seed, randomu(seed)*20 > 3)*100 + 34))
    xyouts, randomu(seed), randomu(seed), str, charsize=siz, /NORM
    endfor
time_test_timer, 'Hershey strings X'+strtrim(nrep,2)

erase

nrep = 1000
for i=0L, nrep do begin
    str = string(byte(randomu(seed, randomu(seed)*20 > 3)*100 + 34))
    xyouts, randomu(seed), randomu(seed), str, /NORM, FONT=0
    endfor
time_test_timer, 'Hardware font strings X'+strtrim(nrep,2)


IF (demomode) THEN $
  print, float(total_time),'=Total Time, ', $
	exp(geom_time / ntest), '=Geometric mean,',ntest,' tests.' $
ELSE printf, lunno, float(total_time),'=Total Time, ', $
	exp(geom_time / ntest), '=Geometric mean,',ntest,' tests.'

if lunno gt 0 then free_lun,lunno
wdelete
end

pro time_test2_internal, filename, NOFILEIO=nofileio	;Time_test revised....

; Why??  This routine is similar to time_test, but with longer and
; larger tests to obtain more accurate comparisons with ever faster
; machines.

; As machines have become faster over the years, the time required for
; some of the individual tests became small in comparison the the
; resolution of the system clock, making the results inaccurate.  This
; test is based on the original time_test, but with the interations and
; data size adjusted to yield times on the order of 5 seconds/test.

; In a few years, this is written in 1996, the tests will probably
; have to be again adjusted.

COMPILE_OPT hidden, strictarr
common timer_common, time, lunno, total_time, geom_time, ntest, demomode

on_error,2                      ;Return to caller if an error occurs

nofileio = KEYWORD_SET(nofileio)

if n_params() gt 0 then time_test_init,filename else time_test_init

; Print header
IF (demomode) THEN BEGIN
    PRINT,'|TIME_TEST2 performance for IDL ',!VERSION.RELEASE,' (demo):'
    PRINT,'|       OS_FAMILY=',!VERSION.OS_FAMILY, $
          ', OS=',!VERSION.OS,', ARCH=',!VERSION.ARCH
    PRINT,'|	', systime(0)
ENDIF ELSE BEGIN
    PRINTF,lunno,'|TIME_TEST2 performance for IDL ',!VERSION.RELEASE, ':'
    PRINTF,lunno,'|       OS_FAMILY=',!VERSION.OS_FAMILY, $
                 ', OS=',!VERSION.OS,', ARCH=',!VERSION.ARCH
    PRINTF,lunno,'|	', systime(0)
ENDELSE

;	Empty for loop
nrep = 2000000
for i=1L, nrep do begin & end

time_test_timer,'Empty For loop,' + string(nrep)+ ' times'

for i=1L,100000 do time_test_dummy, i
time_test_timer,'Call empty procedure (1 param) 100,000 times'

;	Add 100000 scalar ints:...
for i=0L,99999 do a=i+1
time_test_timer,'Add 100,000 integer scalars and store'

;	Scalar arithmetic loop:
for i=0L,25000 do begin
	a = i + i -2
	b = a / 2 + 1
	if b ne i then print,'You screwed up',i,a,b
	endfor
time_test_timer,'25,000 scalar loops each of 5 ops, 2 =, 1 if)'

a=replicate(2b,512,512)
time_test_reset
for i=1,10 do b=a*2b
time_test_timer,'Mult 512 by 512 byte by constant and store, 10 times'
for i=1,100 do c = shift(b,10,10)
time_test_timer,'Shift 512 by 512 byte and store, 100 times'
for i=1,50 do b=a+3b
time_test_timer,'Add constant to 512 x 512 byte array and store, 50 times'
for i=1,30 do b=a+b
time_test_timer,'Add two 512 by 512 byte images and store, 30 times'

a = float(a)
time_test_reset
for i=1,30 do b=a*2b
time_test_timer,'Mult 512 by 512 floating by constant and store, 30 times'
for i=1,30 do c = shift(b,10,10)
time_test_timer,'Add constant to 512 x 512 floating and store, 40 times'
for i=1,40 do b=a+b
time_test_timer,'Add two 512 by 512 floating images and store, 30 times'

time_test_reset
for i=1,10 do a=randomu(qqq, 150, 150)	;Random number matrix
time_test_timer, 'Generate 225000 random numbers'

time_test_reset
b = invert(a)
time_test_timer,'Invert a 150 by 150 random matrix'

time_test_reset
ludc, a, index
time_test_timer, 'LU Decomposition of a 150 by 150 random matrix'

a=bindgen(256,256) & b=a
time_test_reset
for i=0,255 do for j=0,255 do b[j,i]=a[i,j]
time_test_timer,'Transpose 256 x 256 byte, FOR loops'
for j=1,10 do for i=0,255 do begin
	b[0,i] = transpose(a[i,*])
	end
time_test_timer,'Transpose 256 x 256 byte, row and column ops x 10'
for i=1,10 do b=transpose(a)
time_test_timer,'Transpose 256 x 256 byte, TRANSPOSE function x 10'

a=findgen(100000)+1
c=a
b = a
time_test_reset
for i=0L,n_elements(a)-1 do b[i] = alog(a[i])
time_test_timer,'Log of 100,000 numbers, FOR loop'
b = alog(a)
time_test_timer,'Log of 100,000 numbers, vector ops'

n = 2L^17
a = findgen(n)
time_test_reset
b = fft(a,1)
b = fft(b,-1)
time_test_timer,string(n) + ' point forward plus inverse FFT'

a=bytarr(512,512)
a[200:250,200:250]=10b
time_test_reset
for i=1,10 do b=smooth(a,5)
time_test_timer,'Smooth 512 by 512 byte array, 5x5 boxcar, 10 times'

a=float(a)
time_test_reset
for i=1,2 do b=smooth(a,5)
time_test_timer,'Smooth 512 by 512 floating array, 5x5 boxcar, 2 times'

a=bindgen(512,512)
aa =assoc(1,a)
time_test_reset
nrecs = 20

IF ((NOT demomode) AND (NOT nofileio)) THEN BEGIN
    openw, 1, FILEPATH('test.dat', /TMP), 512, $
    	initial = 512L*nrecs ;Must be changed for vax
    FOR i=0, nrecs-1 DO aa[i] = a
    FOR i=0, nrecs-1 DO a=aa[i]
    time_test_timer, 'Write and read 512 by 512 byte array x '+strtrim(nrecs, 2)
    close, 1
END ELSE BEGIN
    IF (nofileio) AND (NOT demomode) THEN $
          PRINT,'                      Skipped read/write test' $
    ELSE $
          PRINT,'                      Skipped read/write test in demo mode'
ENDELSE

IF (demomode) THEN $
  print, float(total_time),'=Total Time, ', $
	exp(geom_time / ntest), '=Geometric mean,',ntest,' tests.' $
ELSE printf, lunno, float(total_time),'=Total Time, ', $
	exp(geom_time / ntest), '=Geometric mean,',ntest,' tests.'

;  Remove the data file
IF ((NOT demomode) AND (NOT nofileio)) THEN BEGIN
    openw, 2, FILEPATH('test.dat', /TMP), /DELETE
    close, 2
ENDIF
if lunno gt 0 then free_lun,lunno
end

pro time_test3_internal, filename, NOFILEIO=nofileio, FACT=fact
                                ;Time_test revised....again...

; Why??  This routine is similar to time_test and time_test2, but with
; longer and larger tests to obtain more accurate comparisons with
; ever faster machines.

COMPILE_OPT hidden, strictarr
common timer_common, time, lunno, total_time, geom_time, ntest, demomode

on_error,2                      ;Return to caller if an error occurs

nofileio = KEYWORD_SET(nofileio)

if n_params() gt 0 then time_test_init,filename else time_test_init

; Print header
IF (demomode) THEN BEGIN
    PRINT,'|TIME_TEST3 performance for IDL ',!VERSION.RELEASE,' (demo):'
    PRINT,'|       OS_FAMILY=',!VERSION.OS_FAMILY, $
          ', OS=',!VERSION.OS,', ARCH=',!VERSION.ARCH
    PRINT,'|	', systime(0)
ENDIF ELSE BEGIN
    PRINTF,lunno,'|TIME_TEST3 performance for IDL ',!VERSION.RELEASE, ':'
    PRINTF,lunno,'|       OS_FAMILY=',!VERSION.OS_FAMILY, $
                 ', OS=',!VERSION.OS,', ARCH=',!VERSION.ARCH
    PRINTF,lunno,'|	', systime(0)
ENDELSE

if n_elements(fact) eq 0 then fact = 1.0 ;Global scale factor for all tests....

;	Empty for loop
nrep = long(2000000 * fact)
for i=1L, nrep do begin & end

time_test_timer,'Empty For loop, ' + strtrim(nrep,2)+ ' times'

nrep = long(100000 * fact)
for i=1L, nrep do time_test_dummy, i
time_test_timer,'Call empty procedure (1 param) '+strtrim(nrep,2)+ ' times'

;	Add 200000 scalar ints:...
nrep = long(200000 * fact)
for i=1L, nrep do a=i+1
time_test_timer,'Add '+strtrim(nrep,2)+' integer scalars and store'

;	Scalar arithmetic loop:
nrep = long(fact * 50000)
for i=1L, nrep do begin
	a = i + i -2
	b = a / 2 + 1
	if b ne i then print,'You screwed up',i,a,b
	endfor
time_test_timer, strtrim(nrep,2) + ' scalar loops each of 5 ops, 2 =, 1 if)'

a=replicate(2b,512,512)
time_test_reset
nrep = long(30L*fact)
for i=1,nrep do b=a*2b
time_test_timer,'Mult 512 by 512 byte by constant and store, '+strtrim(nrep,2)+' times'
nrep = long(300L*fact)
for i=1,nrep do c = shift(b,10,10)
time_test_timer,'Shift 512 by 512 byte and store, '+strtrim(nrep,2)+' times'

nrep = long(100L*fact)
for i=1,nrep do b=a+3b
time_test_timer,'Add constant to 512x512 byte array, '+strtrim(nrep,2)+' times'

nrep = long(80L*fact)
for i=1, nrep do b=a+b
time_test_timer,'Add two 512 by 512 byte arrays and store, '+strtrim(nrep,2)+' times'

a = randomu(seed, 512,512)
time_test_reset
nrep = long(30L*fact)
for i=1, nrep do b=a*2b
time_test_timer,'Mult 512 by 512 floating by constant, '+strtrim(nrep,2)+' times'

nrep = long(60L*fact)
for i=1,nrep do c = shift(b,10,10)
time_test_timer,'Shift 512 x 512 array, '+strtrim(nrep,2)+' times'

nrep = long(40L*fact)
for i=1, nrep do b=a+b
time_test_timer,'Add two 512 by 512 floating images, '+strtrim(nrep,2)+' times'

time_test_reset
nrep = long(10L*fact)
for i=1, nrep do a=randomu(qqq, 100000L)	;Random number matrix
time_test_timer, 'Generate '+strtrim(100000L*nrep,2)+' random numbers'

siz = long(sqrt(fact) * 192)
a = randomu(seed, siz, siz)
time_test_reset
b = invert(a)
time_test_timer,'Invert a '+strtrim(siz,2)+'^2 random matrix'

time_test_reset
ludc, a, index
time_test_timer, 'LU Decomposition of a '+strtrim(siz,2)+'^2 random matrix'

siz = long(384 * sqrt(fact))
a=bindgen(siz,siz) & b=a
time_test_reset
for i=0,(siz-1) do for j=0,(siz-1) do b[j,i]=a[i,j]
time_test_timer,'Transpose '+strtrim(siz,2)+'^2 byte, FOR loops'
for j=1,10 do for i=0,(siz-1) do begin
	b[0,i] = transpose(a[i,*])
	end
time_test_timer,'Transpose '+strtrim(siz,2)+'^2 byte, row and column ops x 10'
for i=1,100 do b=transpose(a)
time_test_timer,'Transpose '+strtrim(siz,2)+'^2 byte, TRANSPOSE function x 100'

siz = long(100000L*fact)
a=findgen(siz)+1
c=a
b = a
time_test_reset
for i=0L, n_elements(a)-1 do b[i] = alog(a[i])
time_test_timer,'Log of '+strtrim(siz,2)+' numbers, FOR loop'
for i=1,10 do b = alog(a)
time_test_timer,'Log of '+strtrim(siz,2)+' numbers, vector ops 10 times'

n = 2L^long(17*fact)
a = findgen(n)
time_test_reset
b = fft(a,1)
b = fft(b,-1)
time_test_timer,strtrim(n,2) + ' point forward plus inverse FFT'

nrep = long(10L*fact)
a=bytarr(512,512)
a[200:250,200:250]=10b
time_test_reset
for i=1,nrep do b=smooth(a,5)
time_test_timer,'Smooth 512 by 512 byte array, 5x5 boxcar, '+strtrim(nrep,2)+' times'

nrep = long(5L*fact)
a=float(a)
time_test_reset
for i=1,nrep do b=smooth(a,5)
time_test_timer,'Smooth 512 by 512 floating array, 5x5 boxcar, '+strtrim(nrep,2)+' times'

a=bindgen(512,512)
aa =assoc(1,a)
time_test_reset
nrep = long(40L*fact)


IF ((NOT demomode) AND (NOT nofileio)) THEN BEGIN
    openw, 1, FILEPATH('test.dat', /TMP), 512, $
    	initial = 512L*nrep ;Must be changed for vax
    FOR i=0, nrep-1 DO aa[i] = a
    FOR i=0, nrep-1 DO a=aa[i]
    time_test_timer, 'Write and read 512 by 512 byte array x '+strtrim(nrep, 2)
    close, 1
END ELSE BEGIN
    IF (nofileio) AND (NOT demomode) THEN $
          PRINT,'                      Skipped read/write test' $
    ELSE $
          PRINT,'                      Skipped read/write test in demo mode'
ENDELSE

IF (demomode) THEN $
  print, float(total_time),'=Total Time, ', $
	exp(geom_time / ntest), '=Geometric mean,',ntest,' tests.' $
ELSE printf, lunno, float(total_time),'=Total Time, ', $
	exp(geom_time / ntest), '=Geometric mean,',ntest,' tests.'

;  Remove the data file
IF ((NOT demomode) AND (NOT nofileio)) THEN BEGIN
    openw, 2, FILEPATH('test.dat', /TMP), /DELETE
    close, 2
ENDIF
if lunno gt 0 then free_lun,lunno
end


pro graphics_times_internal, filename
; Time common graphics operations in the same manner as time_test

COMPILE_OPT hidden, strictarr
common timer_common, time, lunno, total_time, geom_time, ntest, demomode

on_error,2                      ;Return to caller if an error occurs
if (!d.x_size ne 640) or (!d.y_size ne 512) then $
	window, xs=640, ys=512	;Use the same size window for fairness.
if n_params() gt 0 then time_test_init,filename else time_test_init

; Print header
IF (demomode) THEN BEGIN
    PRINT,'|GRAPHICS_TIMES performance for IDL ',!VERSION.RELEASE,' (demo):'
    PRINT,'|       OS_FAMILY=',!VERSION.OS_FAMILY, $
          ', OS=',!VERSION.OS,', ARCH=',!VERSION.ARCH
    PRINT,'|	', systime(0)
ENDIF ELSE BEGIN
    PRINTF,lunno,'|GRAPHICS_TIMES performance for IDL ',!VERSION.RELEASE, ':'
    PRINTF,lunno,'|       OS_FAMILY=',!VERSION.OS_FAMILY, $
                 ', OS=',!VERSION.OS,', ARCH=',!VERSION.ARCH
    PRINTF,lunno,'|	', systime(0)
ENDELSE

for i=1,10 do begin
	plot,[0,1]+i
	empty
	endfor
time_test_timer,'Simple plot, 10 times'

n = 1000
x = randomu(seed, n) * (2 * !pi)
y = fix((sin(x)+1) * (0.5 * !d.y_vsize))
x = fix((cos(x)+1) * (0.5 * !d.x_vsize))
for i=1,5 do begin
	erase
	empty
	plots,x,y,/dev
	empty
	endfor
time_test_timer,'vectors'

n = 24
plot,[-1,1],[-1,1]

for i=3,n do begin
	x = findgen(i) * ( 2 * !pi / i)
	erase
	polyfill,sin(x),cos(x)
	empty
	endfor
time_test_timer,'Polygon filling'

n = 512
a = findgen(n) * (8 * !pi / n)
c = bytscl(sin(a) # cos(a), top = !d.table_size-1)
d = not c
erase
time_test_reset
for i=1,5 do begin
	tv,c
	empty
	tv,d
	empty
	endfor
time_test_timer,'Display 512 x 512 image, 10 times'
;for i=1,10 do begin
;	c = 0
;	c = tvrd(0,0,512,512)
;	endfor
;time_test_timer,'Read back 512 by 512 image, 10 times'

IF (demomode) THEN $
  print, float(total_time),'=Total Time, ', $
	exp(geom_time / ntest), '=Geometric mean,',ntest,' tests.' $
ELSE printf, lunno, float(total_time),'=Total Time, ', $
	exp(geom_time / ntest), '=Geometric mean,',ntest,' tests.'

if lunno gt 0 then free_lun,lunno
wdelete
end



pro time_test, filename, NOFILEIO=nofileio	;Run some time tests.
; filename = name of listing file or null for terminal output.
; nofileio = The presence of this keyword means that no file I/O should be
;            done in the test.  Results from demo mode may be compared to
;            those from full IDL.
;
;+
; NAME:
;	TIME_TEST
;
; PURPOSE:
;	General purpose IDL benchmark program that performs
;	approximately 20 common operations and prints the time
;	required.
;
; CATEGORY:
;	Miscellaneous.
;
; CALLING SEQUENCE:
;	TIME_TEST [, Filename]
;
; OPTIONAL INPUTS:
;    Filename:	The string containing the name of output file for the
;		results of the time test.
;
; KEYWORD PARAMETERS:
;	NoFileIO = Optional keyword when set disables file Input/Output
;	operations.  Results from tests run in demo mode may be compared to
;	those run in full mode with this keyword set.
;
; OUTPUTS:
;	No explicit outputs.  Results of the test are printed to the screen
;	or to a file.
;
; OPTIONAL OUTPUT PARAMETERS:
;	None.
;
; COMMON BLOCKS:
;	TIMER_COMMON
;
; SIDE EFFECTS:
;	Many operations are performed.  Files are written, etc.
;
; RESTRICTIONS:
;	Could be more complete, and could segregate integer, floating
;	point and file system IO times into separate figures.
;
; PROCEDURE:
;	Straightforward.
;	See also the procedure GRAPHICS_TEST, in this file, which
;	times a few of the common graphics operations.
;
;	We make no claim that these times are a fair or accurate
;	measure of computer performance.  In particular, different
;	versions of IDL were used.
;
;	Graphics performance varies greatly, depending largely on the
;	window system, or lack of thereof.
;
;	Typical times obtained to date include:
; 	 (where	Comp.     = computational tests
; 		Graphics  = graphics tests
;		Geo. Avg. = geometric average)
;
; Machine / OS / Memory            Comp.   Geo. Avg.   Graphics Geo. Avg.
;
; MicroVAX II, VMS 5.1, 16MB        637     14.4        39.9    6.57
; MicroVAX II, Ultrix 3.0, 16MB     616     13.9        58.1    8.27
; Sun 3/110, SunOS 4.0, 12MB        391      8.19       32.0    7.81
; Sun 3/80, 12MB, 24 bit color      282      6.03       89.3   21.7
; PC 386 25MHz, 80387, MSDOS, 4MB   276      6.9        29.5    5.94
; Mips R2030, RISC/os 4.1, 8MB      246      3.67       14.6    2.62
; VAXStation 3100, VMS 5.1, 16MB    235      5.13       24.3    3.71
; HP 9000, Model 375, ?? ??         163      4.14       20.8    3.37
; DecStation 3100, UWS 2.1, 16MB    150      4.00       17.6    3.23
; 486 33mhz Clone, MS Windows, 8MB   70      1.81       12.9    3.00
; Sun 4/65, SunOS 4.1, 16MB          66      1.81        7.0    1.64
; Silicon Graphics 4D/25, ??         51      1.38       19.4    2.44
; Sun 4/50 IPX, 16MB                 40      1.03        7.7    0.80
; IBM 6000 Model 325 24MB            40      0.87        5.8    1.21
; HP 9000 / 720 48 MB                20      0.52        5.0    0.70
; SGI Indigo XS4000, 32MB            20      0.46        2.1    0.44
; SGI Indigo2, 150Mhz, 32MB          16      0.32        2.4    0.51
; DEC Alpha 3000/500, 224MB          13      0.30        2.3    0.43
;
;
; MODIFICATION HISTORY:
;	DMS, 1986.
;
;	DMS, Revised July 1990,  Increased the size of arrays and the number
;		of repetitions to make most of the tests take longer.
;		This is to eliminate the effect of clock granularity
;		and to acknowledge that machines are becoming faster.
;		Many of the tests were made longer by a factor of 10.
;
;	MWR, Jan 1995,  Modified to run in demo mode.  All routines except
;		TIME_COMPARE now run in demo mode.  Added platform and
;		version information.  Added NoFileIO keyword.
;-
COMPILE_OPT idl2

common timer_common, time, lunno, total_time, geom_time, ntest, demomode

on_error,2                      ;Return to caller if an error occurs

if n_elements(time) eq 0 then begin
   print, 'TIME_TEST is obsolete.'
   print, 'Use the newer, more accurate, TIME_TEST2, contained in this file.'
   endif

do_floating = 1	;Do floating point array tests

nofileio = KEYWORD_SET(nofileio)

if n_params() gt 0 then time_test_init,filename else time_test_init

; Print header
IF (demomode) THEN BEGIN
    PRINT,'|TIME_TEST performance for IDL ',!VERSION.RELEASE,' (demo):'
    PRINT,'|       OS_FAMILY=',!VERSION.OS_FAMILY, $
          ', OS=',!VERSION.OS,', ARCH=',!VERSION.ARCH
ENDIF ELSE BEGIN
    PRINTF,lunno,'|TIME_TEST performance for IDL ',!VERSION.RELEASE, ':'
    PRINTF,lunno,'|       OS_FAMILY=',!VERSION.OS_FAMILY, $
                 ', OS=',!VERSION.OS,', ARCH=',!VERSION.ARCH
ENDELSE

;	Empty for loop
for i=0L, 999999l do begin & end

time_test_timer,'Empty For loop, 1 million times'

for i=1L,100000 do time_test_dummy, i
time_test_timer,'Call empty procedure (1 param) 100,000 times'

;	Add 100000 scalar ints:...
for i=0L,99999 do a=i+1
time_test_timer,'Add 100,000 integer scalars and store'

;	Scalar arithmetic loop:
for i=0L,25000 do begin
	a = i + i -2
	b = a / 2 + 1
	if b ne i then print,'You screwed up',i,a,b
	endfor
time_test_timer,'25,000 scalar loops each of 5 ops, 2 =, 1 if)'

a=replicate(2b,512,512)
time_test_reset
for i=1,10 do b=a*2b
time_test_timer,'Mult 512 by 512 byte by constant and store, 10 times'
for i=1,10 do c = shift(b,10,10)
time_test_timer,'Shift 512 by 512 byte and store, 10 times'
for i=1,10 do b=a+3b
time_test_timer,'Add constant to 512 x 512 byte array and store, 10 times'
for i=1,10 do b=a+b
time_test_timer,'Add two 512 by 512 byte images and store, 10 times'

if do_floating then begin
	a = float(a)
	time_test_reset
	for i=1,10 do b=a*2b
	time_test_timer,'Mult 512 by 512 floating by constant and store, 10 times'
	for i=1,10 do c = shift(b,10,10)
	time_test_timer,'Add constant to 512 x 512 floating and store, 10 times'
	for i=1,10 do b=a+b
	time_test_timer,'Add two 512 by 512 floating images and store, 10 times'
	endif


a=randomu(qqq,100,100)	;Random number matrix
time_test_reset
b = invert(a)
time_test_timer,'Invert a 100 by 100 random matrix'

a=bindgen(256,256) & b=a
time_test_reset
for i=0,255 do for j=0,255 do b[j,i]=a[i,j]
time_test_timer,'Transpose 256 x 256 byte, FOR loops'
for i=0,255 do begin
	b[0,i] = transpose(a[i,*])
	end
time_test_timer,'Transpose 256 x 256 byte, row and column ops'
b=transpose(a)
time_test_timer,'Transpose 256 x 256 byte, transpose function'

a=findgen(100000)+1
c=a
b = a
time_test_reset
for i=0L,n_elements(a)-1 do b[i] = alog(a[i])
time_test_timer,'Log of 100,000 numbers, FOR loop'
b = alog(a)
time_test_timer,'Log of 100,000 numbers, vector ops'

for i=0L,n_elements(a)-1 do c[i]=a[i]+b[i]
time_test_timer,'Add two 100000 element floating vectors, FOR loop'

c=a+b
time_test_timer,'Add two 100000 element floating vectors, vector op'

a = findgen(65536L)
time_test_reset
b=fft(a,1)
time_test_timer,'65536 point real to complex FFT'

a=bytarr(512,512)
a[200:250,200:250]=10b
time_test_reset
b=smooth(a,5)
time_test_timer,'Smooth 512 by 512 byte array, 5x5 boxcar'

a=float(a)
time_test_reset
b=smooth(a,5)
time_test_timer,'Smooth 512 by 512 floating array, 5x5 boxcar'

IF ((NOT demomode) AND (NOT nofileio)) THEN BEGIN
    a=bindgen(512, 512)
    aa =assoc(1, a)
    time_test_reset
    openw, 1, FILEPATH('test.dat', /TMP), 512, $
    	initial = 5120 ;Must be changed for vax
    FOR i=1, 10 DO aa[0] = a
    FOR i=1, 10 DO a=aa[0]
    time_test_timer, 'Write and read 10 512 by 512 byte arrays'
    close, 1
END ELSE BEGIN
    IF (nofileio) AND (NOT demomode) THEN $
          PRINT,'                      Skipped read/write test' $
    ELSE $
          PRINT,'                      Skipped read/write test in demo mode'
ENDELSE

IF (demomode) THEN $
  print, float(total_time),'=Total Time, ', $
	exp(geom_time / ntest), '=Geometric mean,',ntest,' tests.' $
ELSE printf, lunno, float(total_time),'=Total Time, ', $
	exp(geom_time / ntest), '=Geometric mean,',ntest,' tests.'

;  Remove the data file
IF ((NOT demomode) AND (NOT nofileio)) THEN BEGIN
    openw, 2, FILEPATH('test.dat', /TMP), /DELETE
    close, 2
ENDIF
IF lunno GT 0 THEN free_lun, lunno
end
