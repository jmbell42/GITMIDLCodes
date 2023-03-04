file = file_search('1D*.bin')
nfiles_new = n_elements(file)
if n_elements(file) eq 0 then begin
    print, "No matching files... "
    stop
endif

;if nfiles_new gt 1 then begin
;    filetype = strarr(nfiles_new)
;    for ifile = 0, n_elements(file) -1 do begin
;        l1 = strpos(file(ifile),'/',/reverse_search)+1
;        filetype(ifile) = strmid(file(ifile),l1,5)
;        print, tostr(ifile), '    ',filetype(ifile)
;    endfor
;    if n_elements(ft) eq 0 then ft = 0
;    ft = fix(ask('which filetype: ',tostr(ft)))
;    whichtype = filetype(ft)
;    file = file_search(directories(0)+'/'+whichtype+'*'+f+'*')
;endif
nfiles = nfiles_new
gitm_read_bin, file(0), data,time,nvars,vars,version

nalts = n_elements(data(0,0,0,*))
alts = reform(data(2,0,0,0:nalts-1))/1000.

for ivar = 0, nvars - 1 do print, tostr(ivar),'   ', vars(ivar)
if n_elements(var) eq 0 then var = 3
var = fix(ask('which variable to plot: ',tostr(var)))

if n_elements(ylog) eq 0 then ylog = 'y'
ylog = ask('whether to plot log: ',ylog)

value = fltarr(nfiles,nalts)
for ifile = 0, nfiles - 1 do begin
   fn = file(ifile)
   get_1d_profile,fn,var,coordinates,profile
   value(ifile,*) = profile

endfor
if ylog eq 'y' then value = alog10(value)

ppp = nfiles
space = 0.01
pos_space, ppp, space, sizes,ny = ppp/10
loadct,39



xrange = mm(value)
;xrange = [-1e-4,1e-4]
;for ifile = 0, nfiles - 1 do begin
;   value(ifile,*) = value(ifile,*) + (xrange(1)-xrange(0))/nfiles * ifile
;endfor
setdevice,'plot.ps','p',5,.95
 cl = findgen(nfiles)*(245/float(nfiles))+245/float(nfiles)
;plot,value(0,*),coordinates/1000.0,/nodata,xrange=xrange,ytitle = 'Altitude',$
;     pos = pos,yrange = [90,500],ystyle = 1,xstyle = 1,$
;     xtitle = 'Time evolution of '+vars(var),xtickname = strarr(10)+' '
;
;
;for ifile = 0, nfiles - 1 do begin
;   oplot,value(ifile,*),coordinates/1000.0,thick = 3,color=cl(ifile)
;endfor
posold = [-1,-1,-1,-1]
for ifile = 0, nfiles - 1 do begin
   get_position, ppp, space, sizes, ifile, pos, /rect

   if posold(1) ne pos(1) then begin
      plot,value(0,*),coordinates/1000.0,/nodata,xrange=xrange,ytitle = 'Altitude',$
           pos = pos,yrange = [90,500],ystyle = 1,xstyle = 1,$
           /noerase,xtickname = strarr(10)+' '
   endif else begin
      plot,value(0,*),coordinates/1000.0,/nodata,xrange=xrange,ytickname=strarr(10) + ' ',$
           pos = pos,yrange = [90,500],ystyle = 1,xstyle = 1,$
           /noerase,xtickname = strarr(10)+' '
   endelse
   posold = pos
   oplot,value(ifile,*),coordinates/1000.0,thick = 3,color=cl(ifile)
   oplot,[0,0],[0,1000],linestyle = 2
endfor
xyouts,.01,1.01,'Time evolution of '+vars(var),/norm,charsize=1.3
xyouts, .6,1.01,'Range of values: '+tostrf(xrange(0))+':'+tostrf(xrange(1)),/norm
closedevice

end
