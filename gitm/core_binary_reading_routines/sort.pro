
PRO sort, array, order, arraymd

  n = n_elements(array) - 1

  sorted = fltarr(n+1)
  order = intarr(n+1)

  for i=0,n do begin

    find = where(array lt array(i), count)

    sorted(count) = array(i)
    order(i) = count

  endfor

  array = sorted

  if n_elements(arraymd) gt 0 then begin

    arraymd(0) = array(0)

    npts = 0

    for i=1,n do begin

      loc = where(arraymd eq array(i), count)

      if count eq 0 then begin

	npts = npts + 1
	arraymd(npts) = array(i)

      endif

    endfor

    arraymd = arraymd(0:npts)

  endif    

END
