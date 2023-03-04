d = '.'
directories = '.'

if n_elements(f) eq 0 then f =''
f = ask('date and time to plot (dd_hhmm): ',f)
flen = strlen(d)
if strpos(d,'*') ne -1 then flen = flen - 1

file = file_search(directories(0)+'/*'+f+'*')
nfiles_new = n_elements(file)
if n_elements(file) eq 0 then begin
    print, "No matching files... "
    stop
endif

if nfiles_new gt 1 then begin
    filetype = strarr(nfiles_new)
    for ifile = 0, n_elements(file) -1 do begin
        l1 = strpos(file(ifile),'/',/reverse_search)+1
        filetype(ifile) = strmid(file(ifile),l1,5)
        print, tostr(ifile), '    ',filetype(ifile)
    endfor
    if n_elements(ft) eq 0 then ft = 0
    ft = fix(ask('which filetype: ',tostr(ft)))
    whichtype = filetype(ft)
    file = file_search(directories(0)+'/'+whichtype+'*'+f+'*')
endif

gitm_read_bin, file, data,time,nvars,vars,version

nalts = n_elements(data(0,0,0,*))
alts = reform(data(2,0,0,0:nalts-1))/1000.

svars = where(strpos(vars,'Source') ge 0)
lvars = where(strpos(vars,'Loss') ge 0)

nsvars = n_elements(svars)
nlvars = n_elements(lvars)

svalue = fltarr(nsvars,nalts)
lvalue = fltarr(nlvars,nalts)

 if nfiles_new eq 1 then file = file_search(directories+'/*'+f+'*') else $
    file = file_search(directories+'/'+whichtype+'*'+f+'*')
 for ivar = 0, nsvars - 1 do begin
    
    get_1d_profile,file,svars(ivar),coordinates,profile
    svalue(ivar,*) = profile
    
 endfor
 
 for ivar = 0, nlvars - 1 do begin
          
    get_1d_profile,file,lvars(ivar),coordinates,profile
    lvalue(ivar,*) = profile
    
 endfor
 
setdevice, 'plot.ps','p',5,.95
loadct,39
ppp=4
space = 0.08
pos_space, ppp, space, sizes

if n_elements(dolog) eq 0 then dolog = 'n'
dolog = ask('whether to plot log: ',dolog)
if dolog eq 'y' then begin
   svalue = alog10(svalue)
   lvalue = alog10(lvalue)
endif

if n_elements(mini) eq 0 then mini = 0.0
if n_elements(maxi) eq 0 then maxi = 0.0
mini = float(ask('minimum value to plot (0 for auto): ', tostrf(mini)))
maxi = float(ask('maximum value to plot (0 for auto): ', tostrf(maxi)))

if mini eq 0 then mins = min(svalue(*,2:nalts-3))-.1*min(svalue(*,2:nalts-3))
if maxi eq 0 then maxs = max(svalue(*,2:nalts-3))+.1*max(svalue(*,2:nalts-3))
if mini eq 0 then minl = min(svalue(*,2:nalts-3))-.1*min(svalue(*,2:nalts-3))
if maxi eq 0 then maxl = max(svalue(*,2:nalts-3))+.1*max(svalue(*,2:nalts-3))

if mini eq 0 then begin
   mini = min([mins,minl])
endif
if maxi eq 0 then begin
   maxi = max([maxs,maxl])
endif

xrange = [mini,maxi]

yrange = mm(alts(2:nalts-3))
yrange = [80,150]
;-------------------------
get_position, ppp, space, sizes, 0, pos, /rect

plot,fltarr(nalts),alts,/nodata,xrange = xrange,background=0,$
  ytitle = ytitle,yrange = yrange,pos=pos,/noerase,xtickname=strarr(10)+' ',xtitle='Sources',$
     ystyle=  1


  cl = findgen(nsvars)*(245/(nsvars))+245/(nsvars)

  for ivar = 0, nsvars - 1 do begin
     oplot,svalue(ivar,*),coordinates/1000.,color=cl(ivar),thick=3
  endfor

legend,vars(svars),box = 0,colors=cl,pos=[pos(2)+.05,pos(3)],/norm,$
       linestyle = 0,thick=3


;----------------------------
get_position, ppp, space, sizes, 2, pos, /rect

plot,fltarr(nalts),alts,/nodata,xrange = xrange,background=0,$
  ytitle = ytitle,yrange = yrange,pos=pos,/noerase,xtitle='Losses',$
     ystyle=  1


  cl = findgen(nlvars)*(245/(nlvars))+245/(nlvars)

  for ivar = 0, nlvars - 1 do begin
     oplot,lvalue(ivar,*),coordinates/1000.,color=cl(ivar),thick=3
  endfor

legend,vars(lvars),box = 0,colors=cl,pos=[pos(2)+.05,pos(3)-.05],/norm,$
       linestyle = 0,thick=3

closedevice


end
