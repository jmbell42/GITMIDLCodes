if n_elements(d) eq 0 then d = ''
d = ask('directory: ',d)

directories = file_search(d)
print, directories

ndirs = n_elements(directories)
base = intarr(ndirs)

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
    file = file_search(directories(0)+'/1DTHM'+'*'+f+'*')
endif

gitm_read_bin, file, data,time,nvars,vars,version

nalts = n_elements(data(0,0,0,*))
value = fltarr(3,nalts,ndirs)
alts = reform(data(2,0,0,2:nalts-3))/1000.

;for ivar = 0, nvars - 1 do print, tostr(ivar),'   ', vars(ivar)
;if n_elements(var) eq 0 then var = 3
;var = fix(ask('variable to plot: ',tostr(var)))

setdevice, 'plot.ps','p',5,.95
loadct,39
ppp=2
space = 0.01
pos_space, ppp, space, sizes, ny = ppp

xtitle = 'Conduction'
ytitle = 'Altitude (m)'

for idir = 0, ndirs - 1 do begin
   if nfiles_new eq 1 then file = file_search(directories(idir)+'/*'+f+'*') else $
     file = file_search(directories(idir)+'/1DTHM'+'*'+f+'*')

    print,directories(idir)
    get_1d_profile,file,5,coordinates,profile
    value(0,*,idir) = profile
    get_1d_profile,file,6,coordinates,profile
    value(1,*,idir) = profile
    get_1d_profile,file,7,coordinates,profile
    value(2,*,idir) = -1 * profile
    get_1d_profile,file,4,coordinates,profile
    ctotal = profile

endfor

xrange = [min(value(*,2:nalts-3,*))-.1*min(value(*,2:nalts-3,*)),max(value(*,2:nalts-3,*))+.1*max(value(*,2:nalts-3,*))]

root = strmid(directories(0),0,flen)

get_position, ppp, space, sizes, 0, pos, /rect
pos(3) = pos(3) - .05
plot,fltarr(nalts-4),alts,/nodata,xrange = xrange,background=0,$
  ytitle = ytitle,yrange = [100,600],pos=pos,/noerase

linestyle = findgen(ndirs)
for idir = 0, ndirs - 1 do begin
    oplot,value(0,2:nalts-3,idir),coordinates(2:nalts-3)/1000.,color=50,linestyle = linestyle(idir),$
      thick=3
    oplot,value(1,2:nalts-3,idir),coordinates(2:nalts-3)/1000.,color=140,linestyle = linestyle(idir),$
      thick=3
    oplot,value(2,2:nalts-3,idir),coordinates(2:nalts-3)/1000.,color=230,linestyle = linestyle(idir),$
      thick=3

    oplot,ctotal(2:nalts-3),coordinates(2:nalts-3)/1000.,color=20,linestyle = 2,$
      thick=3
endfor
legend,vars(5:7),box = 0,colors=[50,140,230],pos=[pos(0)+.05,pos(3)-.05],/norm,$
  linestyle = [0,0,0],thick=3

get_position, ppp, space, sizes, 1, pos, /rect
pos(3) = pos(3) - .05
xrange = [-0.01,0.01]
plot,fltarr(nalts-4),alts,/nodata,xrange = xrange,background=0,xtitle=xtitle,$
  ytitle = ytitle,yrange = [100,140],pos=pos,/noerase

linestyle = findgen(ndirs)
for idir = 0, ndirs - 1 do begin
     oplot,value(0,2:nalts-3,idir),coordinates(2:nalts-3)/1000.,color=50,linestyle = linestyle(idir),$
      thick=3
    oplot,value(1,2:nalts-3,idir),coordinates(2:nalts-3)/1000.,color=140,linestyle = linestyle(idir),$
      thick=3
    oplot,value(2,2:nalts-3,idir),coordinates(2:nalts-3)/1000.,color=230,linestyle = linestyle(idir),$
      thick=3
 oplot,ctotal(2:nalts-3),coordinates(2:nalts-3)/1000.,color=20,linestyle = 2,$
      thick=3
endfor
legend,vars(5:7),box = 0,colors=[50,140,230],pos=[pos(0)+.05,pos(3)-.05],/norm,$
  linestyle = [0,0,0],thick=3

    closedevice


;close,93
;openw,93,'gitm1ddata.txt'
;
;printf, 93, vars(2:*),format='(36A16)'
;printf,93,' '
; 
;for ialt = 2, nalts - 3 do begin
;   printf,93,tostrf(data(2:*,0,0,ialt)), format='(36G12.5)'
;endfor
;
;close,93

end
