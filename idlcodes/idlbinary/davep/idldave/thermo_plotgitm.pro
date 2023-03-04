function tostr,value
  return, strcompress(string(long(value)),/remove_all)
end

function tostrf,value
  return, strcompress(string(float(value)),/remove_all)
end

function chopr, svalue, n
  if strlen(svalue) lt n then n = strlen(svalue)
  return, strmid(svalue, strlen(svalue)-n,n)
end


pro display, vars

  nVars = n_elements(vars)

  if (nVars eq 0) then return

  nchop = floor(alog10(nVars))+1

  for iVar = 0,nVars-1 do $
    print, chopr('0000'+tostr(iVar),nchop),'. ',vars(iVar)

end

function chopr, svalue, n
  if strlen(svalue) lt n then n = strlen(svalue)
  return, strmid(svalue, strlen(svalue)-n,n)
end

function ask, what, orig_ans, set_orig = set_orig

  if n_elements(orig_ans) eq 0 then orig_ans = ''

  nAnswers = n_elements(orig_ans)

  if (nAnswers eq 1) then begin

      answer = ''
      read, 'Enter '+what+' ['+orig_ans+'] : ', answer
      if strlen(answer) eq 0 then answer = orig_ans
      if n_elements(set_orig) gt 0 then orig_ans = answer

  endif else begin

      answer = strarr(nAnswers)

      TempAnswer = ''
      for i = 0, nAnswers-1 do begin
          read, 'Enter '+what+' '+tostr(i)+' ['+orig_ans(i)+'] : ', TempAnswer
          if strlen(TempAnswer) eq 0 then TempAnswer = orig_ans(i)
          Answer(i) = TempAnswer
      endfor

  endelse

  return, answer

  end


PRO c_r_to_a, timearray, timereal

  dayofmon = [31,28,31,30,31,30,31,31,30,31,30,31]

  timearray = intarr(6)

  speryear = double(31536000.0)
  sperday  = double(86400.0)
  sperhour = double(3600.0)
  spermin  = double(60.0)

  numofyears = floor(timereal/speryear)
  if (numofyears+65) mod 4 eq 0 then dayofmon(1) = dayofmon(1) + 1
  numofdays = floor((timereal mod speryear)/sperday)
  numofleap = floor(numofyears / 4)
  numofdays = numofdays - numofleap
  if numofdays lt 0 then begin
    if (numofyears+65) mod 4 eq 0 then dayofmon(1) = dayofmon(1) - 1
    numofyears = numofyears - 1
    numofdays = numofdays + numofleap + 365
    if (numofyears+65) mod 4 eq 0 then dayofmon(1) = dayofmon(1) + 1
    numofleap = floor(numofyears / 4)
    numofdays = numofdays - numofleap
  endif
  numofhours = floor((timereal mod sperday)/sperhour)
  numofmin = floor((timereal mod sperhour)/spermin)
  numofsec = floor(timereal mod spermin)

  numofmon = 0

  while numofdays ge dayofmon(numofmon) do begin

    numofdays = numofdays - dayofmon(numofmon)
    numofmon = numofmon + 1

  endwhile

  timearray(0) = numofyears + 1965
  timearray(1) = numofmon + 1
  timearray(2) = numofdays + 1
  timearray(3) = numofhours
  timearray(4) = numofmin
  timearray(5) = numofsec

  RETURN

END

pro c_a_to_s, timearray, strtime

  mon='JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC' 

  sd = '0'+tostr(timearray(2))
  sd = strmid(sd,strlen(sd)-2,2)
  sm = strmid(mon,(timearray(1)-1)*3,3)
  if timearray(0) lt 1900 then year = timearray(0) 		$
  else year = timearray(0)-1900
  if (year ge 100) then year = year - 100
  sy = chopr('0'+tostr(year),2)
  sh = '0'+tostr(timearray(3))
  sh = strmid(sh,strlen(sh)-2,2)
  si = '0'+tostr(timearray(4))
  si = strmid(si,strlen(si)-2,2)
  ss = '0'+tostr(timearray(5))
  ss = strmid(ss,strlen(ss)-2,2)

  strtime = sd+'-'+sm+'-'+sy+' '+sh+':'+si+':'+ss+'.000'

  RETURN

END

PRO c_a_to_r, timearray, timereal

  dayofmon = [31,28,31,30,31,30,31,31,30,31,30,31]
  if ((timearray(0) mod 4) eq 0) then dayofmon(1) = dayofmon(1) + 1

  timereal = double(0.0)

  if timearray(0) lt 65 then timearray(0) = timearray(0) + 2000
  if timearray(0) gt 1900 then numofyears = timearray(0)-1965 		      $
  else numofyears = timearray(0)-65	
  numofleap = floor(float(numofyears)/4.0)
  numofmonths = timearray(1) - 1
  numofdays = 0

  for i = 0, numofmonths-1 do begin

    numofdays = numofdays + dayofmon(i)

  endfor

  numofdays = numofdays + timearray(2) - 1
  numofhours = timearray(3)
  numofminutes = timearray(4)
  numofseconds = timearray(5)

  timereal = double(numofseconds*1.0) +       $
	     double(numofminutes*60.0) +             $
	     double(numofhours*60.0*60.0) +          $
	     double(numofdays*24.0*60.0*60.0) +      $
	     double(numofleap*24.0*60.0*60.0) +      $
	     double(numofyears*365.0*24.0*60.0*60.0)

  RETURN

END

function mm, array
return, [min(array),max(array)]
end

pro closedevice

  if !d.name eq 'PS' then begin
    device, /close
    set_plot, 'X'
  endif

  return

end

pro setdevice, psfile, orient, psfont, percent, eps=eps, 	$
	       psname_inq = psname_inq

  if n_elements(psfile) eq 0 then begin

    psfile = ''
    if n_elements(psname_inq) gt 0 then begin
      read, 'Enter ps filename : ',psfile
    endif
    if strlen(psfile) eq 0 then psfile = 'idl.ps'

  endif

  if n_elements(percent) eq 0 then percent = 1.0		$
  else if percent gt 1.0 then percent = float(percent)/100.0
  if n_elements(orient) eq 0 then orient = 'landscape'
  if n_elements(psfont) eq 0 then psfont = 28
  if n_elements(eps) eq 0 then eps = 0 else eps = 1
  set_plot, 'ps', /copy, /interpolate

  !p.font = 0

  if (strmid(orient,0,1) eq 'p') or (strmid(orient,0,1) eq 'P') then begin

    changep = percent
    xs = 7.5
    ys = 9.5

    if eps eq 0 then begin

      case (psfont) of

	0  : device, file = psfile, /color, bits=8,	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		xoff = (8.5-xs*changep)/2.0, yoff = (11.0-ys*changep)/2.0,  $
		/Courier 
	1  : device, file = psfile, /color, bits=8,	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		xoff = (8.5-xs*changep)/2.0, yoff = (11.0-ys*changep)/2.0,  $
		/Courier, /Bold 
    	2  : device, file = psfile, /color, bits=8,	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		xoff = (8.5-xs*changep)/2.0, yoff = (11.0-ys*changep)/2.0,  $
		/Courier, /Oblique 
	3  : device, file = psfile, /color, bits=8,	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		xoff = (8.5-xs*changep)/2.0, yoff = (11.0-ys*changep)/2.0,  $
		/Courier, /Bold, /Oblique
       	4  : device, file = psfile, /color, bits=8,	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		xoff = (8.5-xs*changep)/2.0, yoff = (11.0-ys*changep)/2.0,  $
		/Helvetica
      	5  : device, file = psfile, /color, bits=8,	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		xoff = (8.5-xs*changep)/2.0, yoff = (11.0-ys*changep)/2.0,  $
		/Helvetica, /Bold
    	6  : device, file = psfile, /color, bits=8,	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		xoff = (8.5-xs*changep)/2.0, yoff = (11.0-ys*changep)/2.0,  $
		/Helvetica, /Oblique
       	8  : device, file = psfile, /color, bits=8,      	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		xoff = (8.5-xs*changep)/2.0, yoff = (11.0-ys*changep)/2.0,  $
		/Helvetica, /Bold, /Oblique 
    	12 : device, file = psfile, /color, bits=8,	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		xoff = (8.5-xs*changep)/2.0, yoff = (11.0-ys*changep)/2.0,  $
		/Avantgarde, /Book 
     	13 : device, file = psfile, /color, bits=8,	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		xoff = (8.5-xs*changep)/2.0, yoff = (11.0-ys*changep)/2.0,  $
		/Avantgarde, /Book, /Oblique
	 14 : device, file = psfile, /color, bits=8,	$
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		xoff = (8.5-xs*changep)/2.0, yoff = (11.0-ys*changep)/2.0,  $
		/Avantgarde, /Demi 
      	15 : device, file = psfile, /color, bits=8,	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		xoff = (8.5-xs*changep)/2.0, yoff = (11.0-ys*changep)/2.0,  $
		/Avantgarde, /Demi, /Oblique
       	20 : device, file = psfile, /color, bits=8, $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		xoff = (8.5-xs*changep)/2.0, yoff = (11.0-ys*changep)/2.0,  $
		/Schoolbook
   	21 : device, file = psfile, /color, bits=8,$
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		xoff = (8.5-xs*changep)/2.0, yoff = (11.0-ys*changep)/2.0,  $
		/Schoolbook, /Bold
      	22 : device, file = psfile, /color, bits=8,$
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		xoff = (8.5-xs*changep)/2.0, yoff = (11.0-ys*changep)/2.0,  $
		/Schoolbook, /Italic
       	23 : device, file = psfile, /color, bits=8,	$
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		xoff = (8.5-xs*changep)/2.0, yoff = (11.0-ys*changep)/2.0,  $
		/Schoolbook, /Bold, /Italic 
	28 : device, file = psfile, /color, bits=8,	$
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		xoff = (8.5-xs*changep)/2.0, yoff = (11.0-ys*changep)/2.0,  $
		/Times
	29 : device, file = psfile, /color, bits=8,	$
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		xoff = (8.5-xs*changep)/2.0, yoff = (11.0-ys*changep)/2.0,  $
		/Times, /Bold
	 30 : device, file = psfile, /color, bits=8,	$
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		xoff = (8.5-xs*changep)/2.0, yoff = (11.0-ys*changep)/2.0,  $
		/Times, /Italic
	31 : device, file = psfile, /color, bits=8,	$
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		xoff = (8.5-xs*changep)/2.0, yoff = (11.0-ys*changep)/2.0,  $
		/Times, /Bold, /Italic

      endcase

    endif else begin

      case (psfont) of

	0  : device, file = psfile, /color, bits=8,	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		/Courier, /encapsulated 
	1  : device, file = psfile, /color, bits=8,	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		/Courier, /Bold, /encapsulated 
    	2  : device, file = psfile, /color, bits=8,	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		/Courier, /Oblique, /encapsulated 
	3  : device, file = psfile, /color, bits=8,	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		/Courier, /Bold, /Oblique, /encapsulated
       	4  : device, file = psfile, /color, bits=8,	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		/Helvetica, /encapsulated
      	5  : device, file = psfile, /color, bits=8,	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		/Helvetica, /Bold, /encapsulated
    	6  : device, file = psfile, /color, bits=8,	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		/Helvetica, /Oblique, /encapsulated
       	8  : device, file = psfile, /color, bits=8,      	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		/Helvetica, /Bold, /Oblique, /encapsulated 
    	12 : device, file = psfile, /color, bits=8,	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		/Avantgarde, /Book, /encapsulated 
     	13 : device, file = psfile, /color, bits=8,	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		/Avantgarde, /Book, /Oblique, /encapsulated
	 14 : device, file = psfile, /color, bits=8,	$
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		/Avantgarde, /Demi, /encapsulated 
      	15 : device, file = psfile, /color, bits=8,	      $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		/Avantgarde, /Demi, /Oblique, /encapsulated
       	20 : device, file = psfile, /color, bits=8, $
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		/Schoolbook, /encapsulated
   	21 : device, file = psfile, /color, bits=8,$
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		/Schoolbook, /Bold, /encapsulated
      	22 : device, file = psfile, /color, bits=8,$
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		/Schoolbook, /Italic, /encapsulated
       	23 : device, file = psfile, /color, bits=8,	$
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		/Schoolbook, /Bold, /Italic, /encapsulated 
	28 : device, file = psfile, /color, bits=8,	$
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		/Times, /encapsulated
	29 : device, file = psfile, /color, bits=8,	$
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		/Times, /Bold, /encapsulated
	 30 : device, file = psfile, /color, bits=8,	$
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		/Times, /Italic, /encapsulated
	31 : device, file = psfile, /color, bits=8,	$
		/inches, /portrait, xsize = xs*changep, ysize = ys*changep, $
		/Times, /Bold, /Italic, /encapsulated 

      endcase

    endelse

  endif else begin

    xs = 10.0
    ys = 7.0
    change = percent

    if eps eq 0 then begin

      case (psfont) of

	0  : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		yoff=11.0-(11.0-xs*change)/2.0, 		 $
		xoff=(8.5-ys*change)/2.0,			 $
		/inches,					 $
		/Courier 
	1  : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		yoff=11.0-(11.0-xs*change)/2.0, 		 $
		xoff=(8.5-ys*change)/2.0,			 $
		/inches,					 $
		/Courier, /Bold 
    	2  : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		yoff=11.0-(11.0-xs*change)/2.0, 		 $
		xoff=(8.5-ys*change)/2.0,			 $
		/inches,					 $
		/Courier, /Oblique 
	3  : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		yoff=11.0-(11.0-xs*change)/2.0, 		 $
		xoff=(8.5-ys*change)/2.0,			 $
		/inches,					 $
		/Courier, /Bold, /Oblique
       	4  : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		yoff=11.0-(11.0-xs*change)/2.0, 		 $
		xoff=(8.5-ys*change)/2.0,			 $
		/inches,					 $
		/Helvetica
      	5  : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		yoff=11.0-(11.0-xs*change)/2.0, 		 $
		xoff=(8.5-ys*change)/2.0,			 $
		/inches,					 $
		/Helvetica, /Bold
    	6  : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		yoff=11.0-(11.0-xs*change)/2.0, 		 $
		xoff=(8.5-ys*change)/2.0,			 $
		/inches,					 $
		/Helvetica, /Oblique
       	8  : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		yoff=11.0-(11.0-xs*change)/2.0, 		 $
		xoff=(8.5-ys*change)/2.0,			 $
		/inches,					 $
		/Helvetica, /Bold, /Oblique 
    	12 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		yoff=11.0-(11.0-xs*change)/2.0, 		 $
		xoff=(8.5-ys*change)/2.0,			 $
		/inches,					 $
		/Avantgarde, /Book 
     	13 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		yoff=11.0-(11.0-xs*change)/2.0, 		 $
		xoff=(8.5-ys*change)/2.0,			 $
		/inches,					 $
		/Avantgarde, /Book, /Oblique
	14 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		yoff=11.0-(11.0-xs*change)/2.0, 		 $
		xoff=(8.5-ys*change)/2.0,			 $
		/inches,					 $
	 	/Avantgarde, /Demi 
      	15 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		yoff=11.0-(11.0-xs*change)/2.0, 		 $
		xoff=(8.5-ys*change)/2.0,			 $
		/inches,					 $
		/Avantgarde, /Demi, /Oblique
       	20 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		yoff=11.0-(11.0-xs*change)/2.0, 		 $
		xoff=(8.5-ys*change)/2.0,			 $
		/inches,					 $
		/Schoolbook
   	21 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		yoff=11.0-(11.0-xs*change)/2.0, 		 $
		xoff=(8.5-ys*change)/2.0,			 $
		/inches,					 $
		/Schoolbook, /Bold
      	22 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		yoff=11.0-(11.0-xs*change)/2.0, 		 $
		xoff=(8.5-ys*change)/2.0,			 $
		/inches,					 $
		/Schoolbook, /Italic
       	23 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		yoff=11.0-(11.0-xs*change)/2.0, 		 $
		xoff=(8.5-ys*change)/2.0,			 $
		/inches,					 $
		/Schoolbook, /Bold, /Italic 
	28 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		yoff=11.0-(11.0-xs*change)/2.0, 		 $
		xoff=(8.5-ys*change)/2.0,			 $
		/inches,					 $
		/Times
	29 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		yoff=11.0-(11.0-xs*change)/2.0, 		 $
		xoff=(8.5-ys*change)/2.0,			 $
		/inches,					 $
		/Times, /Bold
	30 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		yoff=11.0-(11.0-xs*change)/2.0, 		 $
		xoff=(8.5-ys*change)/2.0,			 $
		/inches,					 $
		/Times, /Italic
	31 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		yoff=11.0-(11.0-xs*change)/2.0, 		 $
		xoff=(8.5-ys*change)/2.0,			 $
		/inches,					 $
		/Times, /Bold, /Italic

      endcase

    endif else begin

      case (psfont) of

	0  : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		/inches,					 $
		/Courier, /encapsulated  
	1  : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		/inches,					 $
		/Courier, /Bold, /encapsulated  
    	2  : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		/inches,					 $
		/Courier, /Oblique, /encapsulated  
	3  : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		/inches,					 $
		/Courier, /Bold, /Oblique, /encapsulated 
       	4  : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		/inches,					 $
		/Helvetica, /encapsulated 
      	5  : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		/inches,					 $
		/Helvetica, /Bold, /encapsulated 
    	6  : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		/inches,					 $
		/Helvetica, /Oblique, /encapsulated 
       	8  : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		/inches,					 $
		/Helvetica, /Bold, /Oblique, /encapsulated  
    	12 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		/inches,					 $
		/Avantgarde, /Book, /encapsulated  
     	13 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		/inches,					 $
		/Avantgarde, /Book, /Oblique, /encapsulated 
	14 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		/inches,					 $
	 	/Avantgarde, /Demi, /encapsulated  
      	15 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		/inches,					 $
		/Avantgarde, /Demi, /Oblique, /encapsulated 
       	20 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		/inches,					 $
		/Schoolbook, /encapsulated 
   	21 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		/inches,					 $
		/Schoolbook, /Bold, /encapsulated 
      	22 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		/inches,					 $
		/Schoolbook, /Italic, /encapsulated 
       	23 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		/inches,					 $
		/Schoolbook, /Bold, /Italic, /encapsulated  
	28 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		/inches,					 $
		/Times, /encapsulated 
	29 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		/inches,					 $
		/Times, /Bold, /encapsulated 
	30 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		/inches,					 $
		/Times, /Italic, /encapsulated 
	31 : device, file = psfile, /color, bits=8, /landscape,  $
		xsize=xs*change, ysize=ys*change,		 $
		/inches,					 $
		/Times, /Bold, /Italic, /encapsulated 

      endcase

    endelse

  endelse

  return

end

pro plotdumb

  plot, [0,1], 			$
	xstyle = 5,		$
	ystyle = 5,		$
	pos = [0,0,1,1],	$
	/nodata

  return

end

function mklower, string

  temp = byte(string)

  loc = where((temp ge 65) and (temp le 90), count)

  if count ne 0 then temp(loc) = temp(loc)+32

  return, string(temp)

end

pro makect, color

  common colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr

  ; Get number of colors
  n=!d.table_size
  if n lt 10 or n gt 256 then n=256

  r = fltarr(n)
  g = fltarr(n)
  b = fltarr(n)

  if not keyword_set(color) then begin
    print,'grey  - black to white to black'
    print,'red   - white to red'
    print,'wyr   - white to red'
    print,'blue  - white to blue'
    print,'rwb   - red white blue'
    print,'bwr   - blue white red'
    print,'bw    - black white'
    print,'wb    - white black'
    print,'mid   - blue green white yellow red'

    color = ''
    read,'Enter color table from list above : ', color

  endif

  color = mklower(color)

  ; Set read, green, blue to values normalized to the 0.0 -- 1.0 range.

  case color of
      
      'grey' : begin
          half=n/2.
          r(0:half-1) = findgen(half)/(half-1)
          g(0:half-1) = findgen(half)/(half-1)
          b(0:half-1) = findgen(half)/(half-1)
          
          r(half:n-1) = 1 - findgen(half)/(half-1)
          g(half:n-1) = 1 - findgen(half)/(half-1)
          b(half:n-1) = 1 - findgen(half)/(half-1)
      end

    'red' : begin
              r(*) = 1.
              g(*) = 1. - findgen(n)/(n-1)
              b(*) = 1. - findgen(n)/(n-1)
            end

    'wb' : begin
              r(*) = 1. - findgen(n)/(n-1)
              g(*) = 1. - findgen(n)/(n-1)
              b(*) = 1. - findgen(n)/(n-1)
            end

    'bw' : begin
              r(*) = 0. + findgen(n)/(n-1)
              g(*) = 0. + findgen(n)/(n-1)
              b(*) = 0. + findgen(n)/(n-1)
            end

    'blue' : begin
               r(*) = 1. - findgen(n)/(n-1)
               b(*) = 1.
               g(*) = 1. - findgen(n)/(n-1)
             end

    'rwb' : begin
              half=n/2
              r(0:half-1) = 1.
              g(0:half-1) = findgen(half)/(half-1)
              b(0:half-1) = findgen(half)/(half-1)

              r(half:n-1) = 1. - findgen(n-half)/(n-half-1)
              g(half:n-1) = 1. - findgen(n-half)/(n-half-1)
              b(half:n-1) = 1.
            end

    'wyr' : begin
              half=n/2
              r(0:half-1) = 1.
              g(0:half-1) = 1.
              b(0:half-1) = 1. - findgen(half)/(half-1)

              r(half:n-1) = 1.
              g(half:n-1) = 1. - findgen(n-half)/(n-half-1)
              b(half:n-1) = 0.
            end

    'bwr' : begin
              half=n/2
              b(0:half-1) = 1.
              g(0:half-1) = findgen(half)/(half-1)
              r(0:half-1) = findgen(half)/(half-1)

              b(half:n-1) = 1. - findgen(n-half)/(n-half-1)
              g(half:n-1) = 1. - findgen(n-half)/(n-half-1)
              r(half:n-1) = 1.
            end

    'mid' : begin
              r(0:n/3-1)     = 0.0
              r(n/3:n/2-1)   = findgen(n/2-n/3)/(n/2-n/3-1)
              r(n/2:n-1)     = 1.0

              b(0:n/2-1)      = 1.
              b(n/2:2*n/3-1)  = 1. - findgen(2*n/3-n/2)/(2*n/3-n/2-1)
              b(2*n/3-1:n-1)  = 0.

              g(0:n/3-1)      = findgen(n/3)/(n/3-1)
              g(n/3:2*n/3-1)  = 1.
              g(2*n/3:n-1)    = 1. - findgen(n-2*n/3)/(n-2*n/3-1)

	      r(n/2) = 1.0
	      g(n/2) = 1.0
	      b(n/2) = 1.0

            end

    'bgr' : begin

        if (n gt 255) then n = 255

        r = fltarr(n)
        g = fltarr(n)
        b = fltarr(n)

        r(*) = 0.0
        b(*) = 0.0
        g(*) = 0.0
        ff = findgen(n/3)/(n/3)

        n13 = 1*n/3
        n23 = 2*n/3

        r(  0:n13-1)   = 0.0
        r(n13:n23-1)   = ff
        r(n23:n  -1)   = 1.0

        g(  0:n13-1)   = ff
        g(n13:n23-1)   = 1.0
        g(n23:n  -1)   = 1.0-ff

        b(  0:n13-1)   = 1.0
        b(n13:n23-1)   = 1.0-ff
        b(n23:n  -1)   = 0.0

    end

    'all' : begin

        if (n gt 255) then n = 255

        r = fltarr(n)
        g = fltarr(n)
        b = fltarr(n)

        r(*) = 0.0
        b(*) = 0.0
        g(*) = 0.0
        ff = findgen(n/5)/(n/5)

        n25 = 2*n/5
        n35 = 3*n/5
        n45 = 4*n/5

        ; bottom 1/5 Blue to Green
        b(0:n/5-1) = 1.0 - ff
        g(0:n/5-1) = ff

        ; Next 1/5 Green to Cyan
        b(n/5:n25-1) = ff
        g(n/5:n25-1) = 1.0

        ; Next 1/5 Cyan to white
        b(n25:n35-1) = 1.0
        g(n25:n35-1) = 1.0
        r(n25:n35-1) = ff

        ; Next 1/5 White to Yellow
        b(n35:n45-1) = 1.0 - ff
        g(n35:n45-1) = 1.0
        r(n35:n45-1) = 1.0

        ; Next 1/5 Yellow to Red
        g(n45:n-1) = 1.0 - ff
        r(n45:n-1) = 1.0

    end

    else : begin
             print, "Unknown value for color=",color
             r(*) = findgen(n)
             g(*) = findgen(n)
             b(*) = findgen(n)
           end

  endcase

  r(0) = 0.0
  g(0) = 0.0
  b(0) = 0.0

  r(n-1) = 1.0
  g(n-1) = 1.0
  b(n-1) = 1.0

  r=255*r
  g=255*g
  b=255*b

  r_orig = r
  g_orig = g
  b_orig = b
  r_curr = r_orig
  g_curr = g_orig
  b_curr = b_orig
  tvlct,r,g,b

end

pro pos_space, nb, space, sizes, nx = nx, ny = ny

  sizes = {bs:0.0, nbx:0, nby:0, xoff:0.0, yoff:0.0, xf:0.0, yf:0.0}

  xsi = float(!d.x_size)
  ysi = float(!d.y_size)

  xs = xsi - 5.0*space*xsi
  ys = ysi - 5.0*space*ysi

  if nb eq 1 then begin

    sizes.nbx = 1
    sizes.nby = 1
    sizes.bs = 1.0 - space

    if xs gt ys then begin

       sizes.yf = 1.0
       sizes.xf = ys/xs

    endif else begin

       sizes.xf = 1.0
       sizes.yf = xs/ys

     endelse

  endif else begin

    if (n_elements(nx) gt 0) then begin
      sizes.nbx = nx(0)
      if n_elements(ny) eq 0 then sizes.nby = nb/nx(0) else sizes.nby = ny(0)
    endif else begin
      if (n_elements(ny) gt 0) then begin
        sizes.nby = ny(0)
        sizes.nbx = nb/ny(0)
      endif else begin
        if xs gt ys then begin
          sizes.nbx = round(sqrt(nb))
          sizes.nby = fix(nb/sizes.nbx)
        endif else begin
          sizes.nby = round(sqrt(nb))
          sizes.nbx = fix(nb/sizes.nby)
        endelse
      endelse
    endelse

    if xs gt ys then begin

      if (sizes.nbx*sizes.nby lt nb) then 				$
	if (sizes.nbx le sizes.nby) then sizes.nbx = sizes.nbx + 1	$
	else sizes.nby = sizes.nby + 1					$
      else								$
	if (sizes.nbx lt sizes.nby) and					$
	   (n_elements(nx) eq 0) and					$
	   (n_elements(ny) eq 0) then begin
	  temp = sizes.nby
	  sizes.nby = sizes.nbx
	  sizes.nbx = temp
	endif

      sizes.yf = 1.0
      sizes.xf = ys/xs
      sizes.bs = ((1.0-space*(sizes.nbx-1))/sizes.nbx )/sizes.xf
      if sizes.nby*sizes.bs+space*(sizes.nby-1) gt 1.0 then 		$
	sizes.bs = (1.0- space*(sizes.nby-1))/sizes.nby 

    endif else begin

      if (sizes.nbx*sizes.nby lt nb) then				$
	if (sizes.nby le sizes.nbx) then sizes.nby = sizes.nby + 1	$
	else sizes.nbx = sizes.nbx + 1					$
      else								$
	if (sizes.nby lt sizes.nbx) and					$
	   (n_elements(nx) eq 0) and					$
	   (n_elements(ny) eq 0) then begin
	  temp = sizes.nby
	  sizes.nby = sizes.nbx
	  sizes.nbx = temp
	endif

      sizes.xf = 1.0
      sizes.yf = xs/ys
      sizes.bs = ((1.0 - space*(sizes.nby-1))/sizes.nby)/sizes.yf
      if sizes.nbx*sizes.bs+space*(sizes.nbx-1) gt 1.0 then 		$
	sizes.bs = (1.0 - space*(sizes.nbx-1))/sizes.nbx

    endelse

  endelse

  sizes.xoff = (1.0 - sizes.xf*(sizes.bs*sizes.nbx + space*(sizes.nbx-1)))/2.0
  sizes.yoff = (1.0 - sizes.yf*(sizes.bs*sizes.nby + space*(sizes.nby-1)))/2.0

  RETURN

END


pro thermo_plotvectors,vars,k,data, lat,lon, utrot, alt, nlats,nlons, nalts, $
                cf,vi_cnt,vn_cnt,step, polar, maxran, plane, npolar

  ;Calculate the factor
  count = 0
  vieast_index = 0
  vneast_index = 0
  if (vi_cnt eq 1) then begin
      count = n_elements(vars)
      test = "V!Di!N(east)"
;      test = "E (east)"
      for i=0,count-1 do begin
          var=strcompress(vars[i],/remove_all)
          tes = strcompress(test,/remove_all)
          result= STRCMP( var, tes, 8)
          if (result eq 1) then vieast_index = i
      endfor
  endif
  if (vn_cnt eq 1) then begin
      count = n_elements(vars)
      test = "V!Dn!N(east)"
      for i=0,count-1 do begin
          var=strcompress(vars[i],/remove_all)
          tes = strcompress(test,/remove_all)
          result= STRCMP( var, tes,8 )
          if (result eq 1) then vneast_index = i
      endfor
  endif

  factors = [1.0, 5.0, 10.0, 20.0, 25.0, $
             50.0, 75.0, 100.0, 150.0, 200.0]

  if (vi_cnt eq 1) then vindex = vieast_index  $
  else vindex = vneast_index

  if (cf lt 0) then begin
    dist = max(abs(data(vindex,*,*,k))) - factors*10.0
    cf = 1
    mindist = dist(cf-1)
    for i=1,n_elements(factors)-1 do begin
        if (dist(i) gt 0 and dist(i) lt mindist) then begin
            cf = i+1
            mindist = dist(i)
        endif
    endfor
  endif

  factor = factors(cf-1)

  if (plane eq 1) then begin

      for i =0,nlats-1,step do begin

          if (npolar) then la = lat(0,i,k) else la = -lat(0,i,k)

          if (90-la lt maxran) then begin

              for j =0,nlons-1,step do begin
                  lo = lon(j,i,k) + utrot

                  ux = data(vindex,j,i,k)/factor
                  if (polar) then $
                    uy = data((vindex+1),j,i,k)/factor*lat(0,i,k)/abs(lat(0,i,k)) $
                  else $
                    uy = data((vindex+1),j,i,k)/factor

                  if (polar) then begin
                      x = (90.0 - la) * cos(lo*!pi/180.0 - !pi/2.0)
                      y = (90.0 - la) * sin(lo*!pi/180.0 - !pi/2.0)

                      ulo = ux
                      ula = uy
                      
                      ux = - ula * cos(lo*!pi/180.0 - !pi/2.0)  $
                        - ulo * sin(lo*!pi/180.0 - !pi/2.0)
                      uy = - ula * sin(lo*!pi/180.0 - !pi/2.0) $
                        + ulo * cos(lo*!pi/180.0 - !pi/2.0)

                  endif else begin
                      x = lo
                      y = la
                  endelse

                  ;ux is the eastward welocity (neutral or ion)
                  ;uy is the northard velocity (neutral or ion)
;                  oplot,[x],[y],psym = 4, color = 0
                  oplot,[x,x+ux],[y,y+uy], color = 0, thick = 2.0

                  u = sqrt(ux^2+uy^2)
                  if (u gt 0) then begin
                      t = asin(uy/u)
                      if (ux lt 0) then t = !pi-t
                      t1 = t+!pi/12
                      t2 = t-!pi/12
                      ux1 = 0.6 * u * cos(t1)
                      uy1 = 0.6 * u * sin(t1)
                      ux2 = 0.6 * u * cos(t2)
                      uy2 = 0.6 * u * sin(t2)
                      oplot,[x+ux, x+ux1],[y+uy,y+uy1], color = 0, thick = 2.0
                      oplot,[x+ux, x+ux2],[y+uy,y+uy2], color = 0, thick = 2.0
                  endif

              endfor

          endif

      endfor

      if (polar) then begin

          x  =  maxran
          y  =  maxran
          uy = -10.0
          ux =   0.0

          plots,[x,x+ux],[y,y+uy]
          
          u = sqrt(ux^2+uy^2)
          t = asin(uy/u)
          if (ux lt 0) then t = !pi-t
          t1 = t+!pi/12
          t2 = t-!pi/12
          ux1 = 0.6 * u * cos(t1)
          uy1 = 0.6 * u * sin(t1)
          ux2 = 0.6 * u * cos(t2)
          uy2 = 0.6 * u * sin(t2)
          plots,[x+ux, x+ux1],[y+uy,y+uy1], color = 0, thick = 2.0
          plots,[x+ux, x+ux2],[y+uy,y+uy2], color = 0, thick = 2.0

          str = string(factor*10.0, format = '(f6.1)') + ' m/s'
          xyouts, x-1.0, y+uy/2.0, str, alignment = 1.0

      endif else begin

          x  =  360.0
          y  =   95.0
          uy =    0.0
          ux =  -10.0

          plots,[x,x+ux],[y,y+uy]

          u = sqrt(ux^2+uy^2)
          t = asin(uy/u)
          if (ux lt 0) then t = !pi-t
          t1 = t+!pi/12
          t2 = t-!pi/12
          ux1 = 0.6 * u * cos(t1)
          uy1 = 0.6 * u * sin(t1)
          ux2 = 0.6 * u * cos(t2)
          uy2 = 0.6 * u * sin(t2)

          plots,[x+ux, x+ux1],[y+uy,y+uy1], color = 0, thick = 2.0
          plots,[x+ux, x+ux2],[y+uy,y+uy2], color = 0, thick = 2.0

          str = string(factor*10.0, format = '(f6.1)') + ' m/s'
          xyouts, x, y+5.0, str, alignment = 1.0

      endelse

  endif

  if (plane eq 2) then begin

      for i =0,nlons-1,step do begin

          lo = lon(i,0,k)

          for j =0,nalts-1,step*2 do begin
              al = alt(i,k,j)

              ux = data(vindex,i,k,j)/factor
              uy = data((vindex+2),i,k,j)/factor

              x = lo
              y = al

              ;ux is the eastward welocity (neutral or ion)
              ;uy is the northward velocity (neutral or ion)
              oplot,[x],[y],psym = 4, color = 0
              oplot,[x,x+ux],[y,y+uy], color = 0, thick = 2.0

          endfor

      endfor

      x  =  360.0
      y  =  max(alt)*1.01
      uy =    0.0
      ux =  -10.0

      plots,[x],[y],psym = 4
      plots,[x,x+ux],[y,y+uy]

      str = string(factor*10.0, format = '(f6.1)') + ' m/s'
      xyouts, x, y+5.0, str, alignment = 1.0

  endif

  if (plane eq 3) then begin

      for i =0,nlats-1,step do begin

          la = lat(k,i,0)

          for j =0,nalts-1,step*2 do begin
              al = alt(k,i,j)

              ux = data(vindex+1,k,i,j)/factor
              uy = data((vindex+2),k,i,j)/factor

              x = la
              y = al

              ;ux is the eastward welocity (neutral or ion)
              ;uy is the northward velocity (neutral or ion)
              oplot,[x],[y],psym = 4, color = 0
              oplot,[x,x+ux],[y,y+uy], color = 0, thick = 2.0

          endfor

      endfor

      x  =   90.0
      y  =  max(alt)*1.01
      uy =    0.0
      ux =  -10.0

      plots,[x],[y],psym = 4
      plots,[x,x+ux],[y,y+uy]

      str = string(factor*10.0, format = '(f6.1)') + ' m/s'
      xyouts, x, y+5.0, str, alignment = 1.0

  endif

end


pro plotmlt, maxran, white = white, black = black, 		$
      no00 = no00, no06 = no06, no12 = no12, no18 = no18,	$
      longs = longs, dash = dash

  if n_elements(white) gt 0 then color = 255
  if n_elements(black) gt 0 then color = 0
  if n_elements(color) eq 0 then begin
    if !d.name eq 'PS' then color = 0 else color = 255
  endif

  if n_elements(no00) eq 0 then no00 = 0
  if n_elements(no06) eq 0 then no06 = 0
  if n_elements(no12) eq 0 then no12 = 0
  if n_elements(no18) eq 0 then no18 = 0

  if n_elements(dash) eq 0 then dash = 1 else dash = 2

  if n_elements(longs) eq 0 then begin
    p00 = '00'
    p06 = '06'
    p12 = '12'
    p18 = '18'
  endif else begin
    p00 = '00'
    p06 = '90'
    p12 = '180'
    p18 = '270'
  endelse

  t = findgen(182.0)*2.0*!pi/180.0
  xp = cos(t)
  yp = sin(t)

  plots, maxran*xp, maxran*yp, color = color
  for i=10,maxran, 10 do					$
    oplot, float(i)*xp, float(i)*yp,linestyle=dash, color = color

  oplot, [-maxran,maxran],[0.0,0.0], linestyle =dash, color = color
  oplot, [0.0,0.0], [-maxran,maxran], linestyle = dash, color = color

  xs  = float(!d.x_size)
  ys  = float(!d.y_size)
  pos = float(!p.clip(0:3))
  pos([0,2]) = pos([0,2])/xs
  pos([1,3]) = pos([1,3])/ys

  mid_x = (pos(2) + pos(0))/2.0
  mid_y = (pos(3) + pos(1))/2.0

  ch = 0.8

  y_ch = ch*float(!d.y_ch_size)/ys
  x_ch = ch*float(!d.x_ch_size)/xs

  if no00 eq 0 then 							$
    xyouts, mid_x, pos(1) - y_ch*1.1, p00, alignment=0.5, 		$
      charsize=ch, /norm

  if no06 eq 0 then 							$
    xyouts, pos(2)+x_ch*0.15, mid_y - y_ch/2.0, p06, 			$
      charsize=ch, /norm

  if no12 eq 0 then 							$
    xyouts, mid_x, pos(3) + y_ch*0.15, p12, alignment=0.5, 		$
      charsize=ch, /norm

  if no18 eq 0 then 							$
    xyouts, pos(0)-x_ch*0.15, mid_y - y_ch/2.0, p18, 			$
      charsize=ch, /norm, alignment = 1.0

  return

end

pro get_position, nb, space, sizes, pos_num, pos, rect = rect,		$
		  xmargin = xmargin, ymargin = ymargin

  xipos = fix(pos_num) mod sizes.nbx
  yipos = fix(pos_num)/sizes.nbx

  yf2 = sizes.yf
  yf = sizes.yf*(1.0-space)
  xf2 = sizes.xf
  xf = sizes.xf*(1.0-space)

  if n_elements(rect) gt 0 then begin

    if n_elements(xmargin) gt 0 then xmar = xmargin(0) 			$
    else xmar = space/2.0

    if n_elements(ymargin) gt 0 then ymar = ymargin(0) 			$
    else ymar = space/2.0

    xtotal = 1.0 - (space*float(sizes.nbx-1) + xmar + xf2*space/2.0)
    xbs = xtotal/(float(sizes.nbx)*xf)

    xoff = xmar - xf2*space/2.0

    ytotal = 1.0 - (space*float(sizes.nby-1) + ymar + yf2*space/2.0)
    ybs = ytotal/(float(sizes.nby)*yf)

    yoff = 0.0

  endif else begin

    xbs  = sizes.bs
    xoff = sizes.xoff
    ybs  = sizes.bs
    yoff = sizes.yoff

  endelse

  xpos0 = float(xipos) * (xbs+space)*xf + xoff + xf2*space/2.0
  xpos1 = float(xipos) * (xbs+space)*xf + xoff + xf2*space/2.0 + xbs*xf

  ypos0 = (1.0-yf2*space/2) - (yipos * (ybs+space)*yf + ybs*yf) - yoff
  ypos1 = (1.0-yf2*space/2) - (yipos * (ybs+space)*yf) - yoff

  pos= [xpos0,ypos0,xpos1,ypos1]

  RETURN

END


pro gitm_read_bin, file, data, time, nVars, Vars, version

  filelist = file_search(file)

  nFiles = n_elements(filelist)

  if (nFiles gt 1) then Time = dblarr(nFiles) else Time = 0.0D

  for iFile = 0, nFiles-1 do begin

      filein = filelist(iFile)

      close, 1
      openr, 1, filein, /f77

      version = 0.0D

      nLons = 0L
      nLats = 0L
      nAlts = 0L
      nVars = 0L

      readu, 1, version
      readu, 1, nLons, nLats, nAlts
      readu, 1, nVars

      Vars = strarr(nVars)
      line = bytarr(40)
      for iVars = 0, nVars-1 do begin
          readu, 1, line
          Vars(iVars) = strcompress(string(line),/remove)
      endfor

      lTime = lonarr(7)
      readu, 1, lTime

      iTime = fix(lTime(0:5))
      c_a_to_r, itime, rtime
      Time(iFile) = rTime + lTime(6)/1000.0

      if (nFiles eq 1) then begin
          Data = dblarr(nVars, nLons, nLats, nAlts)
      endif else begin
          if (iFile eq 0) then $
            Data = dblarr(nFiles, nLons, nLats, nAlts, nVars)
      endelse

      tmp = dblarr(nLons, nLats, nAlts)
      for i=0,nVars-1 do begin
          readu,1,tmp
          data(i,*,*,*) = tmp
      endfor
          
      close, 1

  endfor

end

pro read_thermosphere_file, filelist, nvars, nalts, nlats, nlons, $
                            vars, data, nBLKlat, nBLKlon, nBLK, $
                            iTime, Version

  if (n_elements(nBLKlat) eq 0) then nBLKlat = 0
  if (n_elements(nBLKlon) eq 0) then nBLKlon = 0
  if (n_elements(nBLK)    eq 0) then nBLK    = 0

  filelist = file_search(filelist)

  Version = -1.0

  if (strpos(filelist(0), "save") gt 0) then begin
      restore, filelist(0)
      nBLK = 1
      if (n_elements(iTime) eq 0) then begin
          p = strpos(filelist(0),".save")-1
          while (strpos(strmid(filelist(0),p,1),'.') eq -1) do p = p-1
          iYear   = fix(strmid(filelist(0),p-13,2))
          iMonth  = fix(strmid(filelist(0),p-11,2))
          iDay    = fix(strmid(filelist(0),p-9,2))
          iHour   = fix(strmid(filelist(0),p-6,2))
          iMinute = fix(strmid(filelist(0),p-4,2))
          iSecond = fix(strmid(filelist(0),p-2,2))
          iTime = [iYear, iMonth, iDay, iHour, iMinute, iSecond]
      endif
      return
  endif else begin
      if (strpos(filelist(0), "bin") gt 0) then begin
          gitm_read_bin, filelist, data, time, nVars, Vars, version
          s = size(data)
          if (s(0) eq 4) then begin
              nLons = s(2)
              nLats = s(3)
              nAlts = s(4)
          endif
          if (s(0) eq 3) then begin
              nLons = s(2)
              nLats = s(3)
              nAlts = 1
          endif
          nBLK = 1
          c_r_to_a, itime, time(0)
          return
      endif
  endelse

  f = filelist(0)

  if (strpos(filelist(0),"b0") eq 0) then begin
      all = findfile('b0*'+strmid(filelist(0),6,18)+'*')
  endif else begin
      all = filelist(0)
  endelse

  nfiles = n_elements(all)

  if (nBLKlat eq 0 and nBLKlon eq 0) then begin

    if (nfiles eq 1) then begin
      nBLKlon = 1
      nBLKlat = 1
    endif

 endif

 if (nBLKlat*nBLKlon eq 0) then begin

     file = all(0)
     print, "Determining Block Information from : ",file
     openr,1,file

      done = 0
      line = ''
      while not done do begin
          readf,1,line
          if strpos(line,'BLOCKS') gt -1 then begin
              nBLKlat = 0L
              nBLKlon = 0L
              nBLKalt = 0L
              readf,1, nBLKalt 
              readf,1, nBLKlat
              readf,1, nBLKlon
              done = 1
          endif

          if (eof(1)) then done = 1

      endwhile

      close,1

      if (nBLKlat*nBLKlon eq 0) then begin
          nBLK = 0
          print, "Could not determine block structure!!!"
          stop
      endif
 endif
  if (nBLKlat*nBLKlon gt nfiles) then begin
    nBLK = 0
    mess = 'There are not enough files to fill the blocks! Blocks:'+ $
           string(nBLKlat*nBLKlon)+'  files:'+string(nfiles)
    print, mess
    stop
  endif else begin
    nBLK = 1
    for n=0,nBLKlat*nBLKlon-1 do begin
      file = all(n)
      print, "reading file : ",file
      openr,1,file
      done = 0
      line = ''
      while not done do begin
          readf,1,line
          if strpos(line,'NUMERICAL') gt -1 then begin
              nvars = 0L
              nlines = 0L
              readf,1, nvars
              readf,1, nalts
              readf,1, nlats
              readf,1, nlons
          endif
          if strpos(line,'BLOCKS') gt -1 then begin
              nBLKlat = 0L
              nBLKlon = 0L
              nBLKalt = 0L
              readf,1, nBLKalt 
              readf,1, nBLKlat
              readf,1, nBLKlon
          endif
          if strpos(line,'TIME') gt -1 then begin
              iYear   = 0
              iMonth  = 0
              iDay    = 0
              iHour   = 0
              iMinute = 0
              iSecond = 0
              readf,1, iYear
              readf,1, iMonth
              readf,1, iDay
              readf,1, iHour
              readf,1, iMinute
              readf,1, iSecond
              iTime = [iYear, iMonth, iDay, iHour, iMinute, iSecond]
          endif
          if strpos(line,'VERSION') gt -1 then begin
              readf,1,Version
          endif
          if strpos(line,'VARIABLE') gt -1 then begin
              if n_elements(nvars) eq 0 then begin
                  print, 'File is in the wrong order, NUMERICAL VALUES must come'
                  print, 'before VARIABLE LIST'
                  stop
              endif else begin
                  vars = strarr(nvars)
                  for i=0,nvars-1 do begin
                      readf,1,format="(I7,a)",j,line
                      vars(i) = line
                  endfor
              endelse
              ;Store the value of vars into the pointer. 
          endif
          if strpos(line,'BEGIN') gt -1 then done = 1
      endwhile
      if (n eq 0) then begin
          nlo = (nlons-4) * nBLKlon + 4
          nla = (nlats-4) * nBLKlat + 4
          data = fltarr(nvars, nlo, nla, nalts)
          tmp = fltarr(nvars)
          format = '('+tostr(nvars)+'E11.3)'
      endif
      
      if (n_elements(iTime) eq 0) then begin
          p = strlen(filelist(0))-1
          while (strpos(strmid(filelist(0),p,1),'.') eq -1) do p = p-1
          iYear   = fix(strmid(filelist(0),p-13,2))
          iMonth  = fix(strmid(filelist(0),p-11,2))
          iDay    = fix(strmid(filelist(0),p-9,2))
          iHour   = fix(strmid(filelist(0),p-6,2))
          iMinute = fix(strmid(filelist(0),p-4,2))
          iSecond = fix(strmid(filelist(0),p-2,2))
          iTime = [iYear, iMonth, iDay, iHour, iMinute, iSecond]
      endif

      line = ''

      for k = 0, nalts-1 do begin
          for j = 0, nlats-1 do begin
              for i = 0, nlons-1 do begin
                  readf,1,tmp, format=format
                  ii = (n mod nBLKlon)*(nlons-4) + i
		  jj = (n / nBLKlon)*(nlats-4) + j
                  if (i ge 2 and i le nlons-3 and $
                      j ge 2 and j le nlats-3) then $
                    data(*,ii,jj,k) = tmp
                  if (jj lt 2) then data(*,ii,jj,k) = tmp
                  if (ii lt 2) then data(*,ii,jj,k) = tmp
                  if (jj gt nla-3) then data(*,ii,jj,k) = tmp
                  if (ii gt nlo-3) then data(*,ii,jj,k) = tmp
              endfor
          endfor	
      endfor
      close,1
    endfor
    nlons = nlo
    nlats = nla

endelse
end

function gettok,st,char, exact=exact

  On_error,2                           ;Return to caller
  compile_opt idl2

   if N_params() LT 2 then begin
       print,'Syntax - token = gettok( st, char, [ /EXACT ] )'
       return,-1
   endif

; if char is a blank treat tabs as blanks

 if not keyword_set(exact) then begin
    st = strtrim(st,1)              ;Remove leading blanks and tabs
    if char EQ ' ' then begin 
       tab = string(9b)                 
       if max(strpos(st,tab)) GE 0 then st = repchr(st,tab,' ')
    endif
  endif
  token = st

; find character in string

  pos = strpos(st,char)
  test = pos EQ -1
  bad = where(test, Nbad, Complement = good, Ncomplement=Ngood)
  if Nbad GT 0 then st[bad] = ''
 
; extract token
 if Ngood GT 0 then begin
    stg = st[good]
    pos = reform( pos[good], 1, Ngood )
    token[good] = strmid(stg,0,pos)
    st[good] = strmid(stg,pos+1)
 endif

;  Return the result.

 return,token
 end

function date_conv,date,type

compile_opt idl2
; data declaration
;
days = [0,31,28,31,30,31,30,31,31,30,31,30,31]
months = ['   ','JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT',$
        'NOV','DEC']
;
; set default type if not supplied
;
if N_params() lt 2 then type = 'REAL'
;
; Determine type of input supplied
;
s = size(date) & ndim = s[0] & datatype = s[ndim+1]
if ndim gt 0 then begin                 ;vector?
        if ndim gt 1 then goto,notvalid
        if (s[1] ne 5) and (s[1] ne 3) then goto,notvalid
        if (s[1] eq 5) then form = 2 else form = 4
   end else begin                       ;scalar input
        if datatype eq 0 then goto,notvalid
        if datatype eq 7 then form = 3 $        ;string
                         else form = 1  ;numeric scalar
end
;
;      -----------------------------------
;
;*** convert input to year,day,hour,minute,second
;
;      -----------------------------------
case form of

        1: begin                                        ;real scalar
                idate = long(date)
                year = long(idate/1000)
;
; if year is only 2 digits, assume 1900
;
                if year lt 100 then begin
                   message,/WARN, $
                     'Warning: Year specified is only 2 digits, assuming 19xx'
                   year=1900+year
                   idate=1900000+idate
                   date=1900000.+date
                end
;
                day = idate - year*1000
                fdate = date-idate
                fdate = fdate*24.
                hour = fix(fdate)
                fdate = (fdate-hour)*60.0
                minute = fix(fdate)
                sec = float((fdate-minute)*60.0)
           end

        2: begin                                        ;vector
                year = fix(date[0])
;
; if year is only 2 digits, assume 1900
;
                if year lt 100 then begin
                   message,/WARN, $
                    'Warning: Year specified is only 2 digits, assuming 19xx'
                   year=1900+year
                end
;
                day = fix(date[1])
                hour = fix(date[2])
                minute = fix(date[3])
                sec = float(date[4])
           end

        3: begin                                        ;string
                temp = date
;
; check for old type of date, DD-MMM-YYYY
;
                if strpos(temp,'-') le 2 then begin
                  day_of_month = fix(gettok(temp,'-'))
                  month_name = gettok(temp,'-')
                  year = fix(gettok(temp,' '))
                  hour = fix(gettok(temp,':'))
                  minute = fix(gettok(temp,':'))
                  sec = float(strtrim(strmid(temp,0,5)))
;
; determine month number from month name
;
                  month_name = strupcase(month_name)
                  for mon = 1,12 do begin
                        if month_name eq months[mon] then goto,found
                  end
                  message,'Invalid month name specified'
                  
;
; check for new type of date, ISO: YYYY-MM-DD
;
                end else if strpos(temp,'-') eq 4 then begin
                  year = fix(gettok(temp,'-'))
                  month_name = gettok(temp,'-')
                  mon=month_name
                  day_of_month=gettok(temp,' ')
                  if strlen(temp) eq 0 then begin
                        dtmp=gettok(day_of_month,'T')
                        temp=day_of_month
                        day_of_month=dtmp
                  end
                  day_of_month=fix(day_of_month)
                  hour = fix(gettok(temp,':'))
                  minute = fix(gettok(temp,':'))
                  sec = float(strtrim(strmid(temp,0,5)))
                end else goto, notvalid
              found:
;
; if year is only 2 digits, assume 1900
;
                if year lt 100 then begin
                   message,/WARN, $' 
                     'Warning: Year specified is only 2 digits, assuming 19xx'
                   year=1900+year
                end
;
;
;            convert to day of year from month/day_of_month
;
;            correction for leap years
;
;               if (fix(year) mod 4) eq 0 then days(2) = 29     ;add one to february
                lpyr = ((year mod 4) eq 0) and ((year mod 100) ne 0) $
                        or ((year mod 400) eq 0)
                if lpyr eq 1 then days[2] = 29 ; if leap year, add day to Feb.
;
;
;            compute day of year
;
                  day = fix(total(days[0:mon-1])+day_of_month)
           end

        4 : begin                       ;spacecraft time
                SC = DOUBLE(date)
                SC = SC + (SC LT 0.0)*65536.    ;Get rid of neg. numbers 
;
;            Determine total number of secs since midnight, JAN. 1, 1979
;
                SECS = SC[2]/64 + SC[1]*1024 + SC[0]*1024*65536.
                SECS = SECS/8192.0D0            ;Convert from spacecraft units 
;
;            Determine number of years 
;
                MINS = SECS/60.
                HOURS = MINS/60.
                TOTDAYS = HOURS/24.
                YEARS = TOTDAYS/365.
                YEARS = FIX(YEARS)
;
;            Compute number of leap years past 
;
                LEAPYEARS = (YEARS+2)/4
;
;           Compute day of year 
;
                DAY = FIX(TOTDAYS-YEARS*365.-LEAPYEARS)
;
;           Correct for case of being right at end of leapyear
;
                IF DAY LT 0 THEN BEGIN
                  DAY = DAY+366
                  LEAPYEARS = LEAPYEARS-1
                  YEARS = YEARS-1
                END
;
;            COMPUTE HOUR OF DAY
;
                TOTDAYS = YEARS*365.+DAY+LEAPYEARS
                HOUR = FIX(HOURS - 24*TOTDAYS)
                TOTHOURS = TOTDAYS*24+HOUR
;
;            COMPUTE MINUTE
;
                MINUTE = FIX(MINS-TOTHOURS*60)
                TOTMIN = TOTHOURS*60+MINUTE
;
;            COMPUTE SEC
;
                SEC = SECS-TOTMIN*60
;
;            COMPUTE ACTUAL YEAR
;
                YEAR = YEARS+79
;
; if year is only 2 digits, assume 1900
;
                if year lt 100 then begin
                   message, /CON, $ 
                     'Warning: Year specified is only 2 digits, assuming 19xx'
                   year=1900+year
                end
;
;
;            START DAY AT ONE AND NOT ZERO
;
                DAY=DAY+1
           END
ENDCASE
;
;            correction for leap years
;
        if form ne 3 then begin         ;Was it already done?
           lpyr = ((year mod 4) eq 0) and ((year mod 100) ne 0) $
                or ((year mod 400) eq 0)
           if lpyr eq 1 then days[2] = 29 ; if leap year, add day to Feb.
        end
;
;            check for valid day
;
        if (day lt 1) or (day gt total(days)) then $
            message,'ERROR -- There are only ' + strtrim(fix(total(days)),2) + $
	         ' days  in year '+strtrim(year,2)

;
;            find month which day occurs
;
        day_of_month = day
        month_num = 1
        while day_of_month gt days[month_num] do begin
               day_of_month = day_of_month - days[month_num]
               month_num = month_num+1
        end
;           ---------------------------------------
;
;   *****       Now convert to output format
;
;           ---------------------------------------
;
; is type a string
;
s = size(type)
if (s[0] ne 0) or (s[1] ne 7) then $
        message,'ERROR - Output type specification must be a string'
;
case strmid(strupcase(type),0,1) of

        'V' : begin                             ;vector output
                out = fltarr(5)
                out[0] = year
                out[1] = day
                out[2] = hour
                out[3] = minute
                out[4] = sec
             end
 
        'R' : begin                             ;floating point scalar
;               if year gt 1900 then year = year-1900
                out = sec/24.0d0/60./60. + minute/24.0d0/60. + hour/24.0d0 $
                        +  day + year*1000d0
              end

        'S' : begin                             ;string output 

                month_name = months[month_num]
;
;            encode into ascii_date
;
                out = string(day_of_month,'(i2)') +'-'+ month_name +'-' + $
                        string(year,'(i4)') + ' '+ $
                        string(hour,'(i2.2)') +':'+ $
                        strmid(string(minute+100,'(i3)'),1,2) + ':'+ $
                        strmid(string(sec+100,'(f6.2)'),1,5)
           end
        'F' : begin
               xsec = strmid(string(sec+100,'(f6.2)'),1,5)
               if xsec EQ '60.00' then begin
                     minute = minute+1
                     xsec = '00.00'
                endif
                xminute =   string(minute,'(i2.2)')
                if xminute EQ '60' then begin
                       hour = hour+1
                       xminute = '00'                  
                endif          
                out = string(year,'(i4)')+'-'+string(month_num,'(I2.2)')+'-'+ $
                        string(day_of_month,'(i2.2)')+'T' + $
                        string(hour,'(i2.2)') +  ':' +xminute + ':'+ xsec
                        
              end
        else: begin                     ;invalid type specified
                print,'DATE_CONV-- Invalid output type specified'
                print,' It must be ''REAL'', ''STRING'', or ''VECTOR'''
                return,-1
              end
endcase
return,out
;
; invalid input date error section
;
notvalid:
message,'Invalid input date specified',/CON
return, -1
end

pro zsun,date,time,lat,lon,zenith,azimuth,solfac,sunrise=sunrise, $
           sunset=sunset,local=local,latsun=latsun,lonsun=lonsun

today = DATE_CONV(date , 'V')

day = today(1)


if n_params() eq 0 then begin
  xhelp,'zensun'
  return
endif  

nday=[  1.0,   6.0,  11.0,  16.0,  21.0,  26.0,  31.0,  36.0,  41.0,  46.0,$
       51.0,  56.0,  61.0,  66.0,  71.0,  76.0,  81.0,  86.0,  91.0,  96.0,$
      101.0, 106.0, 111.0, 116.0, 121.0, 126.0, 131.0, 136.0, 141.0, 146.0,$
      151.0, 156.0, 161.0, 166.0, 171.0, 176.0, 181.0, 186.0, 191.0, 196.0,$
      201.0, 206.0, 211.0, 216.0, 221.0, 226.0, 231.0, 236.0, 241.0, 246.0,$
      251.0, 256.0, 261.0, 266.0, 271.0, 276.0, 281.0, 286.0, 291.0, 296.0,$
      301.0, 306.0, 311.0, 316.0, 321.0, 326.0, 331.0, 336.0, 341.0, 346.0,$
      351.0, 356.0, 361.0, 366.0]

eqt=[ -3.23, -5.49, -7.60, -9.48,-11.09,-12.39,-13.34,-13.95,-14.23,-14.19,$
     -13.85,-13.22,-12.35,-11.26,-10.01, -8.64, -7.18, -5.67, -4.16, -2.69,$
      -1.29, -0.02,  1.10,  2.05,  2.80,  3.33,  3.63,  3.68,  3.49,  3.09,$
       2.48,  1.71,  0.79, -0.24, -1.33, -2.41, -3.45, -4.39, -5.20, -5.84,$
      -6.28, -6.49, -6.44, -6.15, -5.60, -4.82, -3.81, -2.60, -1.19,  0.36,$
       2.03,  3.76,  5.54,  7.31,  9.04, 10.69, 12.20, 13.53, 14.65, 15.52,$
      16.12, 16.41, 16.36, 15.95, 15.19, 14.09, 12.67, 10.93,  8.93,  6.70,$
       4.32,  1.86, -0.62, -3.23]

dec=[-23.06,-22.57,-21.91,-21.06,-20.05,-18.88,-17.57,-16.13,-14.57,-12.91,$
     -11.16, -9.34, -7.46, -5.54, -3.59, -1.62,  0.36,  2.33,  4.28,  6.19,$
       8.06,  9.88, 11.62, 13.29, 14.87, 16.34, 17.70, 18.94, 20.04, 21.00,$
      21.81, 22.47, 22.95, 23.28, 23.43, 23.40, 23.21, 22.85, 22.32, 21.63,$
      20.79, 19.80, 18.67, 17.42, 16.05, 14.57, 13.00, 11.33,  9.60,  7.80,$
       5.95,  4.06,  2.13,  0.19, -1.75, -3.69, -5.62, -7.51, -9.36,-11.16,$
     -12.88,-14.53,-16.07,-17.50,-18.81,-19.98,-20.99,-21.85,-22.52,-23.02,$
     -23.33,-23.44,-23.35,-23.06]

;
; compute the subsolar coordinates
;

tt=((fix(day)+time/24.-1.) mod 365.25) +1.  ;; fractional day number
                                            ;; with 12am 1jan = 1.

if n_elements(tt) gt 1 then begin
  eqtime=tt-tt                              ;; this used to be day-day, caused 
  decang=eqtime                             ;; error in eqtime &amp; decang when a
  ii=sort(tt)                               ;; single integer day was input
  eqtime(ii)=spline(nday,eqt,tt(ii))/60.    
  decang(ii)=spline(nday,dec,tt(ii))
endif else begin
  eqtime=spline(nday,eqt,tt)/60.
  decang=spline(nday,dec,tt)
endelse  
latsun=decang

if keyword_set(local) then begin
  lonorm=((lon + 360 + 180 ) mod 360 ) - 180.
  tzone=fix((lonorm+7.5)/15)
  index = where(lonorm lt 0, cnt)
  if (cnt gt 0) then tzone(index) = fix((lonorm(index)-7.5)/15)
  ut=(time-tzone+24.) mod 24.                  ; universal time
  noon=tzone+12.-lonorm/15.                    ; local time of noon
endif else begin
  ut=time
  noon=12.-lon/15.                             ; universal time of noon
endelse

lonsun=-15.*(ut-12.+eqtime)

; compute the solar zenith, azimuth and flux multiplier

t0=(90.-lat)*!dtor                            ; colatitude of point
t1=(90.-latsun)*!dtor                         ; colatitude of sun

p0=lon*!dtor                                  ; longitude of point
p1=lonsun*!dtor                               ; longitude of sun

zz=cos(t0)*cos(t1)+sin(t0)*sin(t1)*cos(p1-p0) ; up          \
xx=sin(t1)*sin(p1-p0)                         ; east-west    &gt; rotated coor
yy=sin(t0)*cos(t1)-cos(t0)*sin(t1)*cos(p1-p0) ; north-south /

azimuth=atan(xx,yy)/!dtor                     ; solar azimuth 
zenith=acos(zz)/!dtor                         ; solar zenith

rsun=1.-0.01673*cos(.9856*(tt-2.)*!dtor)      ; earth-sun distance in AU
solfac=zz/rsun^2                              ; flux multiplier

if n_elements(time) eq 1 then begin
    angsun=6.96e10/(1.5e13*rsun) ; solar disk half-angle
                                ;angsun=0.  
    arg=-(sin(angsun)+cos(t0)*cos(t1))/(sin(t0)*sin(t1))
    sunrise = arg - arg 
    sunset  = arg - arg + 24.
    index = where(abs(arg) le 1, cnt)
    if (cnt gt 0) then begin
        dtime=acos(arg(index))/(!dtor*15)
        sunrise(index)=noon-dtime-eqtime(index)
        sunset(index)=noon+dtime-eqtime(index)
    endif
endif
return
end

;*****************************************************************************
 
pro plotct, ncolors, pos, maxmin, title, right=right, 		$
	color = color, reverse = reverse
 
;******************************************************************************

    ; this is to make Gabor's stuff work....

    if (n_elements(ncolors) eq 4) then begin
      maxmin = pos
      pos = ncolors
      ncolors = 255
      right = 1
    endif

    xrange=!x.range & yrange=!y.range & !x.range=0 & !y.range=0

    if n_elements(right) eq 0 then right = 0 else right = right

    if n_elements(maxmin) lt 2 then maxmin2 = [0,maxmin] else maxmin2 = maxmin

    if n_elements(color) eq 0 then color_in = -1 else color_in = color

    if n_elements(reverse) eq 0 then reverse = 0 else reverse = 1

    if not right then begin
      if color_in eq -1 then 					$
        plot, maxmin2, /noerase, pos = pos, 			$
	  xstyle=5,ystyle=1, /nodata, ytitle = title,charsize=0.9	$
      else							$
        plot, maxmin2, /noerase, pos = pos, 			$
	  xstyle=5,ystyle=1, /nodata, ytitle = title, color = color_in,charsize=0.9
    endif else begin
      plot, maxmin2, /noerase, pos = pos, 			$
	xstyle=5,ystyle=5, /nodata,charsize=0.9
      if color_in eq -1 then					$
        axis, 1, ystyle=1, /nodata, ytitle = title, yax=1, 	$
              charsize=0.9					$
      else							$
        axis, 1, ystyle=1, /nodata, ytitle = title, yax=1, 	$
              charsize=0.9, color = color_in
    endelse

    plot, [0,9], [0,ncolors], /noerase, pos = pos, xstyle=5,ystyle=5, /nodata
    x = [0.0,0.0,1.0,1.0,0.0]
    y = [0.0,1.0,1.0,0.0,0.0]


    maxi = max(maxmin)
    mini = min(maxmin)
    levels = findgen(29)/28.0*(maxi-mini) + mini
    clevels = (ncolors-1)*findgen(29)/28.0 + 1

    array = findgen(10,ncolors-1)
    for i=0,9 do array(i,*) = findgen(ncolors-1)/(ncolors-2)*(maxi-mini) + mini

    contour, array, /noerase, /cell_fill, xstyle = 5, ystyle = 5, $
	levels = levels, c_colors = clevels, pos=pos

;    index = indgen(ncolors)
;    if reverse then index = (ncolors-1) - index
;    for i=0,ncolors-1 do                                      $
;      polyfill, x, float(index(i))+y, color = i

    if color_in eq -1 then begin
      plots, [0.0,1.0], [0.0,0.0]
      plots, [0.0,1.0], [ncolors-1,ncolors-1]
      plot, maxmin2, /noerase, pos = pos, 			$
	xstyle=5,ystyle=1, /nodata, 				$
	ytickname = strarr(10) + ' ', yticklen = 0.25
    endif else begin
      plots, [0.0,9.0], [0.0,0.0], color = color_in
      plots, [0.0,9.0], [ncolors-1,ncolors-1], color = color_in
      plot, maxmin2, /noerase, pos = pos, 			$
	xstyle=5,ystyle=1, /nodata, 				$
	ytickname = strarr(10) + ' ', yticklen = 0.25, color = color_in
    endelse
 
    !x.range=xrange & !y.range=yrange

  return
 
end


pro thermo_plotbatch,cursor_x,cursor_y,strx,stry,step,nvars,sel,nfiles, $
                cnt1,cnt2,cnt3,ghostcells,no,yeslog,  	  $
                nolog,nalts,nlats,nlons,yeswrite_cnt,$
                polar,npolar,MinLat,showgridyes,	  $
                plotvectoryes,vi_cnt,vn_cnt,cf,	  $
                cursor_cnt,data,alt,lat,lon,	  $
                xrange,yrange,selset,smini,smaxi,	  $
                filename,vars, psfile, mars, colortable, itime,ortho,plat,plon


if (n_elements(colortable) eq 0) then colortable = 'mid'
if (strlen(colortable) eq 0) then colortable = 'mid'

if (n_elements(logplot) eq 0) then logplot = yeslog

if (min(data(sel,*,*,*)) lt 0.0) then begin
  logplot = 0
  yeslog = 0
  nolog = 1
endif

;if (n_elements(iTime) eq 0) then begin

    if (strpos(filename,"save") gt 0) then begin

        fn = findfile(filename)
        if (strlen(fn(0)) eq 0) then begin
            print, "Bad filename : ", filename
            stop
        endif else filename = fn(0)
        
        l1 = strpos(filename,'.save')
        fn2 = strmid(filename,0,l1)
        len = strlen(fn2)
        l2 = l1-1
        while (strpos(strmid(fn2,l2,len),'.') eq -1) do l2 = l2 - 1
        l = l2 - 13
        year = fix(strmid(filename,l, 2))
        mont = fix(strmid(filename,l+2, 2))
        day  = fix(strmid(filename,l+4, 2))
        hour = float(strmid(filename, l+7, 2))
        minu = float(strmid(filename,l+9, 2))
        seco = float(strmid(filename,l+11, 2))
    endif else begin
        if (strpos(filename,"bin") gt 0) then begin
            l1 = strpos(filename,'.bin')
            fn2 = strmid(filename,0,l1)
            len = strlen(fn2)
            l2 = l1-1
            l = l1 - 13
            year = fix(strmid(filename,l, 2))
            mont = fix(strmid(filename,l+2, 2))
            day  = fix(strmid(filename,l+4, 2))
            hour = float(strmid(filename, l+7, 2))
            minu = float(strmid(filename,l+9, 2))
            seco = float(strmid(filename,l+11, 2))
        endif else begin
            year = fix(strmid(filename,07, 2))
            mont = fix(strmid(filename,09, 2))
            day  = fix(strmid(filename,11, 2))
            hour = float(strmid(filename,14, 2))
            minu = float(strmid(filename,16, 2))
            seco = float(strmid(filename,18, 2))
        endelse
    endelse

    itime = [year,mont,day,fix(hour),fix(minu),fix(seco)]

;endif

c_a_to_s, itime, stime

ut = itime(3) + itime(4)/60.0 + itime(5)/3600.0
if (polar) then utrot = ut * 15.0 else utrot = 0.0

if (cnt1 eq 0 and polar) then polar = 0

;Get Subsolar point
zdate = tostr(year(0)+2000)+'-'+chopr('0'+tostr(mont(0)),2)+'-'+chopr('0'+tostr(day(0)),2)
ztime = fix(hour)+fix(minu)/60.+fix(seco)/3600.
zlat = 0
zlon = 0
;stop
zsun,zdate,ztime,zlat,zlon,zenith,azimuth,solfac,latsun=latsun,lonsun=lonsun
;

;According to the button user selected, get the values for plotting
if cnt1 eq 1 then begin
    if (polar) then MinLat = MinLat else MinLat = -1000.0
    if not (polar) then mr = 1090
    if (polar) then begin
        mr = 90.0 - abs(MinLat)
    endif
;    if (polar) and not (npolar) then begin
;        mr = 90.0 + MinLat
;    endif
    
    nLons = n_elements(lon(*,0,0))

    if (polar) then begin
        if (npolar) then begin
            loc = where(lat(0,*,0) ge abs(MinLat) and abs(lat(0,*,0)) lt 90.0)
        endif else begin
            loc = where(lat(0,*,0) le -abs(MinLat) and abs(lat(0,*,0)) lt 90.0)
        endelse
    endif else begin
        loc = where(lat(0,*,0) ge -200 and abs(lat(0,*,0)) lt 200.0)
    endelse

    if (polar) then begin
        datatoplot=reform(data(sel,2:nLons-2,loc,selset))
        datatoplot(nLons-4,*) = datatoplot(0,*)
    endif else datatoplot=reform(data(sel,*,loc,selset))
    maxi=max(datatoplot)
    mini=min(datatoplot)
    
    if (polar) then begin

        if (npolar) then begin
            x = reform( (90.0 - lat(2:nLons-2,loc,selset)) * $
                        cos((lon(2:nLons-2,loc,selset)+utrot)*!pi/180.0 - !pi/2.0))
            y = reform( (90.0 - lat(2:nLons-2,loc,selset)) * $
                        sin((lon(2:nLons-2,loc,selset)+utrot)*!pi/180.0 - !pi/2.0))
        endif else begin
            x = reform( (90.0 + lat(2:nLons-2,loc,selset)) * $
                        cos((lon(2:nLons-2,loc,selset)+utrot)*!pi/180.0 - !pi/2.0))
            y = reform( (90.0 + lat(2:nLons-2,loc,selset)) * $
                        sin((lon(2:nLons-2,loc,selset)+utrot)*!pi/180.0 - !pi/2.0))
        endelse

        xrange = [-mr,mr]
        yrange = [-mr,mr]
        xtitle=' '
        ytitle=' '

    endif else begin
        if ortho then begin
            x=reform(lon(*,loc,selset))
            y=reform(lat(*,loc,selset))
           
           
            datatoplot = datatoplot(1:nLons-2,1:nLats-2)
            
            y = y(1:nLons-2,1:nLats-2)
            x = x(1:nLons-2,1:nLats-2)
            nLons  = nLons-2
            nLats  = nLats-2
            
            datatoplot(0,*)       = (datatoplot(1,*)+datatoplot(nLons-2,*))/2.0
            datatoplot(nLons-1,*) = (datatoplot(1,*)+datatoplot(nLons-2,*))/2.0
            datatoplot(*,0)       = mean(datatoplot(*,1))
            datatoplot(*,nLats-1) = mean(datatoplot(*,nLats-2))
            
            x(0)       = 0.0
            x(nLons-1,*) = 360.0
            y(*,0) = -90.0
            y(*,nLats-1) =  90.0

;        save, newrat, newlon, newlat
            if ghostcells eq 0 then begin
                xrange=[0,360]
                yrange=[-90,90]
            endif
            xtitle='Longitude (deg)'
            ytitle='Latitude (deg)'
        endif else begin
            x=reform(lon(*,loc,selset))
            y=reform(lat(*,loc,selset))
            if ghostcells eq 1 then begin
                xrange=mm(lon)
                yrange=mm(lat)
            endif
            if ghostcells eq 0 then begin
                xrange=[0,360]
                yrange=[-90,90]
            endif
            xtitle='Longitude (deg)'
            ytitle='Latitude (deg)'
        endelse
    endelse
    ygrids = n_elements(loc)
    xgrids = nlons
    location = string(alt(0,0,selset),format='(f5.1)')+' km Altitude'
endif

if cnt2 eq 1 then begin
    datatoplot=reform(data(sel,*,selset,*))
    maxi=max(datatoplot)
    mini=min(datatoplot)
    x=reform(lon(*,selset,*))
    y=reform(alt(*,selset,*))
    location = string(lat(0,selset,0),format='(f5.1)')+' deg Latitude'
    xtitle='Longitude (deg)'
    ytitle='Altitude (km)'
    if ghostcells eq 1 then begin
        xrange=mm(lon)
        yrange=mm(alt)
    endif
    if ghostcells eq 0 then begin
        backup_xrange=mm(lon)
        backup_yrange=mm(alt)
        default_xrange=[0,360]
        default_yrange=mm(alt)
;If out of range then use 'mm' to set xrange and yrange values.
;Else use default values.
        if (backup_xrange[0] lt default_xrange[0]) $
          and (backup_xrange[1] gt default_xrange[1]) then begin
            xrange=mm(lon)
            yrange=mm(alt)
        endif else begin
            xrange=[0,360]
            yrange=mm(alt)
        endelse
    endif

xrange = [0,360]

    ygrids=nalts
    xgrids=nlons
endif

if cnt3 eq 1 then begin
    datatoplot=reform(data(sel,selset,*,*))
    maxi=max(datatoplot)
    mini=min(datatoplot)
    x=reform(lat(selset,*,*))
    y=reform(alt(selset,*,*))
    location = string(lon(selset,0,0),format='(f5.1)')+' deg Longitude'
    xtitle='Latitude (deg)'
    ytitle='Altitude (km)'
    if ghostcells eq 1 then begin
        xrange=mm(lat)
        yrange=mm(alt)
    endif
    if ghostcells eq 0 then begin
        backup_xrange=mm(lat)
        backup_yrange=mm(alt)
        default_xrange=[-90,90]
        default_yrange=mm(alt)
;If out of range then use 'mm' to set xrange and yrange values.
;Else use default values.
        if (backup_xrange[0] lt default_xrange[0]) $
          and (backup_xrange[1] gt default_xrange[1]) then begin
            xrange=mm(lat)
            yrange=mm(alt)
        endif else begin
            xrange=[-90,90]
            yrange=mm(alt)
        endelse
    endif
    ygrids=nalts
    xgrids=nlats

xrange = [-90,90]

endif

  ;Calculate the xld, yld according to the cursor position user set.
  ;Calculate and get the array will be plotted.  

xld = x(*,0)
yld = y(0,*)
dist_x=abs(xld-cursor_x)
dist_y=abs(yld-cursor_y)
locx=where(dist_x eq min(dist_x))
locy=where(dist_y eq min(dist_y))
datald=reform(data(sel,*,locx,locy))

if n_elements(smini) eq 0 then smini = '0.0'
if n_elements(smaxi) eq 0 then smaxi = '0.0'

if (float(smini) ne 0 or float(smaxi) ne 0) then begin
    mini = float(smini)
    maxi = float(smaxi)
    mini = mini(0)
    maxi = maxi(0)
endif else begin
    mini = mini(0)
    maxi = maxi(0)
    r = (maxi-mini)*0.05
    mini = mini - r
    maxi = maxi + r
    if (logplot) then begin
        if (maxi gt 0.0) then maxi = alog10(maxi)
        if (mini gt 0.0) then mini = alog10(mini)
        if (maxi-mini gt 8) then begin
            mini = maxi-8
            print, "Limiting minimum..."
        endif
    endif 
endelse

if mini eq maxi then maxi=mini*1.01+1.0
levels = findgen(31)/30.0*(maxi-mini) + mini
loc = where(datatoplot lt levels(1), count)
if (count gt 0) then datatoplot(loc) = levels(1)

 ; Check if user wants to write the result to a file
 ;If user wanted then setdevice. 

if yeswrite_cnt eq 1 then begin

    if (strlen(psfile) eq 0) then psfile = filename+'.ps'
    setdevice,psfile,'l',4,0.95

endif

plotdumb

if not ortho then variable = strcompress(vars(sel),/remove) $
  else variable = vars(sel)

;  makect,'wyr'

 makect,'mid'
;makect, colortable
;loadct, 0
clevels = findgen(31)/30 * 253.0 + 1.0

if (polar) then begin
    xstyle = 5 
    ystyle = 5 
endif else begin
    xstyle = 1
    ystyle = 1
endelse

if (not polar and cnt1) then ppp = 2 else ppp = 1

space = 0.075
pos_space, ppp, space, sizes, ny = 1
get_position, ppp, space, sizes, 0, pos

if (not polar) then begin
    if (cnt1) then begin
        r = pos(2) - pos(0)
        pos(2) = pos(0) + r*2.0
    endif else begin
        get_position, ppp, space, sizes, 0, pos, /rect
        pos(1) = pos(1) + space
        pos(3) = pos(3) - space*2.0
        pos(0) = pos(0) + space*1.0
        pos(2) = pos(2) - space*1.0
    endelse
endif

;If user DOES NOT do the Ghost Cells Contour. 
if ghostcells eq 0 then begin

    ;If user DO NOT do plot log. 

    if (logplot) then begin
        loc = where(datatoplot lt max(datatoplot)*1e-8,count)
        if (count gt 0) then datatoplot(loc) = max(datatoplot)*1e-8
        datatoplot = alog10(datatoplot)
    endif

    if (cnt1) then begin 
;ppp = 1    
;    pos(0) = .45
;print, pos

        if (not polar and not ortho) then begin
            locx = where(x(*,0) ge   0.0 and x(*,0) le 360.0,nx)
            locy = where(y(0,*) ge -90.0 and y(0,*) le  90.0,ny)
            d2 = fltarr(nx,ny)
            x2 = fltarr(nx,ny)
            y2 = fltarr(nx,ny)
            for i=nx/2, nx-1 do begin
                d2(i-nx/2,0:ny-1)  = datatoplot(locx(i),locy)
                x2(i-nx/2,0:ny-1)  = x(locx(i),locy)
                y2(i-nx/2,0:ny-1)  = y(locx(i),locy)
                d2(i,0:ny-1)  = datatoplot(locx(i-nx/2),locy)
                x2(i,0:ny-1)  = x(locx(i-nx/2),locy)
                y2(i,0:ny-1)  = y(locx(i-nx/2),locy)
            endfor
        endif else begin
            d2 = datatoplot
            x2 = x
            y2 = y
            ny = n_elements(y2(0,*))
            nx = n_elements(x2(0,*))
        endelse


        if (not polar) then begin
            if ortho ne 1 then begin
                !p.position = pos
                map_set, title=variable+' at '+location+' at '+$
                  strmid(stime,0,15)+' UT',/cont

            endif else begin
                pos = [.05,.05,.72,.95]
                !p.position = pos
                map_set, title=' ',plat,plon,/ortho,/noborder
            endelse
        endif else begin

            ;-------------------------------------
            ; polar plot
            ;-------------------------------------

            plot, [-mr, mr], [-mr, mr], pos=pos, $
              xstyle=5, ystyle=5,/nodata,/noerase, $
              title=variable+' at '+location+' '+stime

        endelse


    endif else begin

        d2 = datatoplot
        x2 = x
        y2 = y

        plot, mm(x2), mm(y2), /nodata, xstyle = 1, ystyle=1,$
          /noerase, pos = pos, $
          title=variable+' at '+location+' '+stime, $
          xrange=xrange,yrange=yrange

    endelse

;    endif else begin 

;    endelse

    if (cnt1) then begin
plotsubsolar = 0
plotlines = 0
linelevels = findgen(9) * 26.0/8.0 - 13.0
linestyle = intarr(9)
linestyle(0:4) = 1
linestyle(5:8) = 0

plotsyms = 0
plotbox = 0
nsyms = 1
symlats = 22.5
symlons = 292.5

;nsyms = 6
;symlats = [22.5,27.5,37.5,32.5,27.5,32.5]
;symlons = [282.5,302.5,327.5,287.5,322.5,337.5]

        loc = where(d2 gt max(levels(n_elements(levels)-2)),count)
        if (count gt 0) then d2(loc) = max(levels(n_elements(levels)-2))

        contour,d2, x2, y2,POS=pos,$
          levels=levels,xstyle=xstyle,ystyle=ystyle,$
          xrange=xrange,yrange=yrange,$
          c_colors=clevels,$
          xtitle=xtitle,ytitle=ytitle,/cell_fill,/over

        if plotsubsolar then begin
            plots,lonsun,latsun,psym=sym(1),symsize = 3,/data,thick=4,color=254
            plots,lonsun+180,latsun,psym=sym(2),symsize = 3,/data,thick=4,color=50
        endif
        
        if plotbox then begin
          ;  plots,225,0,/data
          ;  plots,225,45,/data,/continue,linestyle=2
          ;  plots,45,45,/data,/continue,linestyle=2
          ;  plots,45,0,/data,/continue,linestyle=2
          ;  plots,225,0,/data
          ;  plots,45,0,/data,/continue,linestyle=2
            plots,270,0,/data
            plots,270,45,/data,/continue,linestyle=2
            plots,315,45,/data,/continue,linestyle=2
            plots,315,0,/data,/continue,linestyle=2
            plots,270,0,/data,/continue,linestyle=2
        endif
        
        if plotsyms then begin
            loadct, 39
            for isym = 0, nsyms - 1 do begin
                plots,symlons(isym),symlats(isym),psym=sym(2),symsize=2,/data,color = 254
            endfor
            makect,'mid'
        endif

        if plotlines then begin
            contour,d2,x2,y2, pos = pos, $
              xstyle=xstyle,ystyle=ystyle,$
              xrange=xrange,yrange=yrange,$
              /noerase, levels = linelevels, /follow, $
              c_linestyle = linestyle,/over
        endif
        
        if ortho then begin
            year = '0'+tostr(itime(0))
            year = strmid(year,strlen(year)-2,2)
            mont = '0'+tostr(itime(1))
            mont = strmid(mont,strlen(mont)-2,2)
            day = '0'+tostr(itime(2))
            day = strmid(day,strlen(day)-2,2)
            hour = '0'+tostr(itime(3))
            hour = strmid(hour,strlen(hour)-2,2)
            min = '0'+tostr(itime(4))
            min = strmid(min,strlen(min)-2,2)

            string = mont+'/'+ $
              day + '/' + $
              year+ ' ' + $
               hour+ ':' + min
            xyouts,.62,.9,string,/norm
            endif
    endif else begin
        contour,d2, x2, y2,POS=pos,$
          levels=levels,xstyle=xstyle,ystyle=ystyle,$
          xrange=xrange,yrange=yrange,$
          c_colors=clevels,$
          xtitle=xtitle,ytitle=ytitle,/cell_fill,/noerase

    endelse

    if (not polar and cnt1 and not mars) then map_continents, color = 0
      if (cnt1 and not polar and mars) then begin
        file = '/remotehome/ridley/idl/extras/marsflat.jpg'
        read_jpeg, file, image
        contour, image(2,*,*), levels = [150], pos = pos, /noerase, $
          xstyle =5, ystyle=5, color = 0, thick=1.5
        plot, [-180,180],[-90,90],xstyle=1,ystyle=1,/noerase,/nodata,pos=pos, $
          xtitle = 'Longitude', ytitle = 'Latitude'
    endif

    if (polar) then plotmlt, mr, /no06, /no12
    if not (polar) then mr = 1090

;    if (cnt1 eq 1) then begin

;    endif
    
    ;Draw grid.
    if (showgridyes eq 1) then begin
        for i=0,ygrids-1 do begin
            oplot,x(*,i),y(*,i)
        endfor
        for j=0,xgrids-1 do begin
            oplot,x(j,*),y(j,*)
        endfor
    endif
    ;If user set cursor position to plot, then do plot of datald.
    ;Else clean up the cursor text fields on the interface. 

    if cursor_cnt eq 1 then begin
        if cnt1 eq 1 then begin
            plot,datald,alt(0,0,*),xtitle='datald',ytitle='Alt. (deg)'
        endif
        if cnt2 eq 1 then begin
            plot,datald,lat(0,*,0),ystyle=1,xtitle='datald',ytitle='Lat. (deg)'
        endif
        if cnt3 eq 1 then begin
            plot,datald,lon(*,0,0),xtitle='datald',ytitle='Long. (deg)'
        endif
    endif else begin	
        txt=''
        ;widget_control,(*ptr).curx_txt,set_value=txt
        ;widget_control,(*ptr).cury_txt,set_value=txt
    endelse
endif


                                ;If user DOES the Ghost Cells Contour.
if ghostcells eq 1 then begin
    x1=min(lon)
    x2=max(lon)
    y1=min(lat)
    y2=min(lat)
                                ;If user does not want to do the Plot Log.
    if nolog eq 1 then begin
        maxi=max(datatoplot)
        mini=min(datatoplot)
        if mini eq maxi then maxi=mini+1
        levels = findgen(31)/30.0*(maxi-mini) + mini

        contour,datatoplot(*,*),x(*,*),y(*,*),POS=pos,$
          levels=levels,xstyle=1,ystyle=1,$
          xrange=xrange,yrange=yrange,$
          title='Contour Plot Thermosphere',c_colors=clevels,$
          xtitle=xtitle,ytitle=ytitle,/cell_fill,/NOERASE
        
;        if cnt1 eq 1 then begin	
;            if (plotvectoryes eq 1) then begin
;                thermo_plotvectors,vars,selset,data,lat,lon,nlats,nlons,cf,vi_cnt,vn_cnt,step,$
;                  polar, mr								
;            endif
;        endif
        
                                ;Draw grid.
        if (showgridyes eq 1) then begin
            for i=0,ygrids-1 do begin
                oplot,mm(x),[y(0,i),y(0,i)]
            endfor
            for j=0,xgrids-1 do begin
                oplot,[x(j,0),x(j,0)],mm(y)
            endfor
        endif

                                ;If user set cursor position to plot, then do plot of datald.
                                ;Else clean up the cursor text fields on the inteRrface. 
        if cursor_cnt eq 1 then begin
            if cnt1 eq 1 then begin
                plot,datald,alt,xtitle='datald',ytitle='Alt. (deg)'
            endif
            if cnt2 eq 1 then begin
                plot,datald,lat,xtitle='datald',ytitle='Lat. (deg)'
            endif
            if cnt3 eq 1 then begin
                plot,datald,lon,xtitle='datald',ytitle='Long. (deg)'
            endif
        endif else begin	
            txt=''
                                ;widget_control,(*ptr).curx_txt,set_value=txt
                                ;widget_control,(*ptr).cury_txt,set_value=txt
        endelse
    endif                       ;End of if nolog eq 1

                                ;If user does want to do the Plot Log. 
    if yeslog eq 1 then begin
        nzsubs=where(datatoplot gt 0, cnt)
        datatoplot(nzsubs)=datatoplot(nzsubs)
        datatoplot=ALOG10(datatoplot)
        maxi=max(datatoplot)
        mini=min(datatoplot)
        if mini eq maxi then maxi=mini+1
        levels = findgen(31)/30.0*(maxi-mini) + mini	
        
        contour,datatoplot(*,*),x(*,*),y(*,*),POS=pos,$
          levels=levels,xstyle=1,ystyle=1,$
          xrange=xrange,yrange=yrange,$
          title='Contour Plot Thermosphere',c_colors=clevels,$
          xtitle=xtitle,ytitle=ytitle,/cell_fill,/NOERASE

;        if cnt1 eq 1 then begin 
;            if (plotvectoryes eq 1) then begin
;                utrot = 180.0
;                thermo_plotvectors,vars,selset,data,lat,lon,nlats,nlons,cf,vi_cnt,vn_cnt,step,$
;                  polar, mr
;            endif
;        endif
        
                                ;Draw grid.
        if (showgridyes eq 1) then begin
            for i=0,ygrids-1 do begin
                oplot,mm(x),[y(0,i),y(0,i)]
            endfor
            for j=0,xgrids-1 do begin
                oplot,[x(j,0),x(j,0)],mm(y)
            endfor
        endif
        
                                ;If user set cursor position to plot, then do plot of datald.
                                ;Else clean up the cursor text fields on the interface. 
        if cursor_cnt eq 1 then begin
            if cnt1 eq 1 then begin
                plot,datald,alt,xtitle='datald',ytitle='Alt. (deg)'
            endif
            if cnt2 eq 1 then begin
                plot,datald,lat,xtitle='datald',ytitle='Lat. (deg)'
            endif
            if cnt3 eq 1 then begin
                plot,datald,lon,xtitle='datald',ytitle='Long. (deg)'
            endif
        endif else begin	
            txt=''
                                ;widget_control,(*ptr).curx_txt,set_value=txt
                                ;widget_control,(*ptr).cury_txt,set_value=txt
        endelse
    endif                       ;End of if yeslog eq 1
endif                           ;End of if yes eq 1


if (cnt1) then plane = 1
if (cnt2) then plane = 2
if (cnt3) then plane = 3

if (plotvectoryes eq 1) then begin
    if (not polar) then $
      plot,xrange,yrange, /nodata,xstyle=5,ystyle=5,/noerase, pos = pos
    utrot = 0.0

    if (plane eq 1 and not ghostcells and not polar) then begin
        lon = lon + 180.0
        loc = where(lon gt 360.0,count)
        if (count gt 0) then lon(loc) = lon(loc) - 360.0
    endif
    thermo_plotvectors,vars,selset,data,lat, $
      lon, utrot, alt, $
      nlats,nlons,nalts, cf,vi_cnt,vn_cnt,step, polar, mr, plane, npolar
endif 

;stfr = 90.0-67.0
;stft = 309.0 + utrot
;
;cirr = 2.0
;cirt = findgen(17)*2*!pi/16
;cirx = cirr*cos(cirt)
;ciry = cirr*sin(cirt)
;stfx = stfr*cos(stft*!pi/180.0-!pi/2) + cirx
;stfy = stfr*sin(stft*!pi/180.0-!pi/2) + ciry
;polyfill, stfx, stfy, color = 0


                                ;Draw color bar.

;	   pos = [0.82,0.05,0.87,0.96]
pos(0) = pos(2)+0.025
pos(2) = pos(0)+0.03
maxmin = mm(levels)

if ortho then begin
    pos(1) = pos(1) + .1
    pos(3) = pos(3) - .1
endif 

title = variable
plotct,254,pos,maxmin,title,/right,color=color

maxi=max(datatoplot)
mini=min(datatoplot)

r = (maxmin(1) - maxmin(0)) * 0.03

if (mini gt maxmin(0)-r) then begin
    plots, [0,1], [mini, mini], thick = 3
    plots, [0,0.5], [mini, mini-r], thick = 3
    plots, [0,0.5], [mini, mini+r], thick = 3
    if (abs(mini) lt 10000.0 and abs(mini) gt 0.01) then begin
        smin = strcompress(string(mini, format = '(f10.2)'), /remove)
    endif else begin
        smin = strcompress(string(mini, format = '(e12.3)'), /remove)
    endelse
    xyouts, -0.1, mini, smin, align = 0.5, charsize = 0.75, orient = 90
endif

if (maxi lt maxmin(1)+r) then begin

    plots, [0,1], [maxi, maxi], thick = 3
    plots, [0,0.5], [maxi, maxi-r], thick = 3
    plots, [0,0.5], [maxi, maxi+r], thick = 3
    if (abs(maxi) lt 10000.0 and abs(maxi) gt 0.01) then begin
        smax = strcompress(string(maxi, format = '(f10.2)'), /remove)
    endif else begin
        smax = strcompress(string(maxi, format = '(e12.3)'), /remove)
    endelse
    xyouts, -0.1, maxi, smax, align = 0.5, charsize = 0.75, orient = 90
endif

;If user write the result to a file, then closedevice right now. 
;;if yeswrite_cnt eq 1 then begin
;;closedevice
;;mes=widget_message('Done with writing into file!')
;;endif
smini = mini
smaxi = maxi

closedevice

end



filelist_new = file_search('3DALL*.bin')

display, filelist_new
if n_elements(whichfile) eq 0 then whichfile = -1
whichfile = fix(ask('which file to plot (-1 for all): ',tostr(whichfile)))

if whichfile ge 0 then filelist = file_search(filelist_new(whichfile)) else filelist = filelist_new
nfiles = n_elements(filelist)

for iFile = 0, nFiles-1 do begin
    
    filename = filelist(iFile)
    
    print, 'Reading file ',filename
    
    read_thermosphere_file, filename, nvars, nalts, nlats, nlons, $
      vars, data, rb, cb, bl_cnt
    
    alt = reform(data(2,*,*,*)) / 1000.0
    lat = reform(data(1,*,*,*)) / !dtor
    lon = reform(data(0,*,*,*)) / !dtor
    
    if (strpos(filename,"save") gt 0) then begin
        
        fn = findfile(filename)
        if (strlen(fn(0)) eq 0) then begin
            print, "Bad filename : ", filename
            stop
        endif else filename = fn(0)
        
        l1 = strpos(filename,'.save')
        fn2 = strmid(filename,0,l1)
        len = strlen(fn2)
        l2 = l1-1
        while (strpos(strmid(fn2,l2,len),'.') eq -1) do l2 = l2 - 1
        l = l2 - 13
        year = fix(strmid(filename,l, 2))
        mont = fix(strmid(filename,l+2, 2))
        day  = fix(strmid(filename,l+4, 2))
        hour = float(strmid(filename, l+7, 2))
        minu = float(strmid(filename,l+9, 2))
        seco = float(strmid(filename,l+11, 2))
    endif else begin
        year = fix(strmid(filename,07, 2))
        mont = fix(strmid(filename,09, 2))
        day  = fix(strmid(filename,11, 2))
        hour = float(strmid(filename,14, 2))
        minu = float(strmid(filename,16, 2))
        seco = float(strmid(filename,18, 2))
    endelse
    
    if year lt 50 then iyear = year + 2000 else iyear = year + 1900
    stryear = strtrim(string(iyear),2)
    strmth = strtrim(string(mont),2)
    strday = strtrim(string(day),2)
    uttime = hour+minu/60.+seco/60./60.
    
    strdate = stryear+'-'+strmth+'-'+strday
    strdate = strdate(0)
    
    if (iFile eq 0) then begin
        
        if n_elements(sel) eq 0 then sel = 3
        for i=0,nvars-1 do print, tostr(i)+'. '+vars(i)
        sel = fix(ask('which var to plot',tostr(sel)))
        
        plotlog = ask('whether you want log or not (y/n)','n')
        if (strpos(plotlog,'y') eq 0) then plotlog = 1 else plotlog = 0
        
        if n_elements(psfile) eq 0 then psfile = 'plot_0000.ps'
        psfile = ask('ps file name',psfile)
        
        print, '1. Constant Altitude Plot'
        print, '2. Constant Longitude Plot'
        print, '3. Constant Latitude Plot'
        slice = fix(ask('type of plot to make','1'))
        
        cnt1 = 0
        cnt2 = 0
        cnt3 = 0
        
        
        
;cnt1 is a lat/lon plot
        if (slice eq 1) then cnt1 = 1
            
;cnt1 is a lat/alt plot
            if (slice eq 2) then cnt3 = 1
            
;cnt1 is a lon/alt plot
            if (slice eq 3) then cnt2 = 1
            
        if (slice eq 1) then begin
            for i=0,nalts-1 do print, tostr(i)+'. '+string(alt(2,2,i))
            if n_elements(selset) eq 0 then selset = 0
            selset = fix(ask('which altitude to plot',tostr(selset)))
        endif

        if (slice eq 2) then begin
            for i=0,nlons-1 do print, tostr(i)+'. '+string(lon(i,2,2))
            if n_elements(selset) eq 0 then selset = 0
            selset = fix(ask('which longitude to plot',tostr(selset)))
        endif

        if (slice eq 3) then begin
            for i=0,nlats-1 do print, tostr(i)+'. '+string(lat(2,i,2))
             if n_elements(selset) eq 0 then selset = 0
            selset = fix(ask('which latitude to plot',tostr(selset)))
        endif

        if n_elements(smini) eq 0 then smini = 0.0
        if n_elements(smaxi) eq 0 then smaxi = 0.0
        smini = ask('minimum (0.0 for automatic)',tostrf(smini))
        smaxi = ask('maximum (0.0 for automatic)',tostrf(smaxi))

        if n_elements(pv) eq 0 then pv = 'n'
        plotvector = ask('whether you want vectors or not (y/n)',pv)
        pv = plotvector
        if strpos(plotvector,'y') eq 0 then plotvector=1 else plotvector = 0

        if (plotvector) then begin
            print,'-1  : automatic selection'
            factors = [1.0, 5.0, 10.0, 20.0, 25.0, $
                       50.0, 75.0, 100.0, 150.0, 200.0]
            nfacs = n_elements(factors)
            for i=0,nfacs-1 do print, tostr(i)+'. '+string(factors(i)*10.0)
            if n_elements(vector_factor) eq 0 then vector_factor = -1
            vector_factor = fix(ask('velocity factor',tostr(vector_factor)))
        endif else vector_factor = 0

; cursor position variables, which don't matter at this point
        cursor_x = 0.0
        cursor_y = 0.0
        strx = '0.0'
        stry = '0.0'

; yes is whether ghostcells are plotted or not:
        yes = 0
        no  = 1

; yeslog is whether variable should be logged or not:
        if (plotlog) then begin 
            yeslog = 1
            nolog  = 0
        endif else begin
            yeslog = 0
            nolog = 1
        endelse

; yeswrite_cnt is whether we have to output to a ps file or not.
        yeswrite_cnt = 1

; polar is variable to say whether we have polar plots or not
       if slice eq 1 then begin
           polar = 0
           ortho = 0
           if n_elements(polar_n) eq 0 then polar_n = 0
           polar_n = fix(ask("if rectangular, polar, or ortho (0,1,2): ",tostr(polar_n)))
           
           polar = polar_n
           if polar eq 2 then begin
               polar = 0
               ortho = 1
            
               if n_elements(tlat) eq 0 then tlat = 0
               if n_elements(tlon) eq 0 then tlon = 0
               tlat = float(ask('ortho center latitude (0.0 for subsolar): ',$
                                tostrf(tlat)))
               tlon = float(ask('ortho center longitude (0.0 for subsolar): ',$
                                tostrf(tlon)))
            
           endif 
       endif

       if ortho eq 1 then begin
           if tlat eq 0.0 and tlon eq 0.0 then begin
           
           zsun,strdate,uttime ,0,0,zenith,azimuth,solfac,$
             lonsun=lonsun,latsun=latsun
        
           if lonsun lt 0.0 then lonsun = 360.0 - abs(lonsun)
           
           plat = latsun
           plon = lonsun

           print, 'Coordinates: ',tostrf(lonsun) ,' Long. ',tostrf(latsun),' Lat.'
       endif else begin
           
           plat = tlat
           plon = tlon

       endelse
   endif

; npolar is whether we are doing the northern or southern hemisphere
       npolar = 1

; MinLat is for polar plots:
        MinLat = 40.0

; showgridyes says whether to plot the grid or not.
        showgridyes = 0

;plotvectoryes says whether to plot vectors or not
        plotvectoryes = plotvector

; number of points to skip when plotting vectors:
        step = 2

; vi_cnt is whether to plot vectors of Vi
        vi_cnt = 1

; vn_cnt is whether to plot vectors of Vn

        vn_cnt = 0

        cursor_cnt = 0

        xrange = [0.0,0.0]

        yrange = [0.0,0.0]

    endif

    if (nFiles gt 1) then begin
        p = strpos(psfile,'.ps')
        if (p gt -1) then psfile = strmid(psfile,0,p-5)
        psfile_final = psfile+'_'+chopr('000'+tostr(iFile),4)+'.ps'
    endif else begin
        psfile_final = psfile
    endelse
    psfile = psfile_final
    smini_final = smini
    smaxi_final = smaxi

    thermo_plotbatch,cursor_x,cursor_y,strx,stry,step,nvars,sel,nfiles,	$
      cnt1,cnt2,cnt3,yes,no,yeslog,  	  $
      1-yeslog,nalts,nlats,nlons,yeswrite_cnt,$
      polar,npolar,MinLat,showgridyes,	  $
      plotvectoryes,vi_cnt,vn_cnt,vector_factor,	  $
      cursor_cnt,data,alt,lat,lon,	  $
      xrange,yrange,selset,smini_final,smaxi_final,	  $
      filename,vars, psfile_final, 0, 'all',itime,ortho,plat,plon

endfor


end
