files_new = file_search('1D*')
nfiles_new = n_elements(files_new)

nfiletypes = 0
filetypes = strarr(10)
filetold = ' '
for ifile = 0, nfiles_new - 1 do begin
    temp = strmid(files_new(ifile),0,5)
    if temp ne filetold then begin
        filetypes(nfiletypes) = temp
        nfiletypes = nfiletypes + 1
        filetold = temp
    endif
endfor

filetypes = filetypes(0:nfiletypes-1)
display,filetypes
if n_elements(ft) eq 0 then ft = 0
ft = fix(ask('which filetype: ',tostr(ft)))
whichtype = filetypes(ft)

files = file_search(whichtype+'*')
nfiles = n_elements(files)
if n_elements(nfilesold) eq 0 then nfilesold = 0
if n_elements(whichtypeold) eq 0 then whichtypeold = -1

;if nfiles eq nfilesold and whichtype eq whichtypeold then begin
;    reread = 'n'
;    reread = ask('whether to reread data: ',reread)
;    if strpos(reread,'y') ge 0 then reread = 1 else reread = 0
;endif else begin
;    reread = 1
;endelse

nfilesold = nfiles
whichtypeold = whichtype

gitm_read_bin, files(0), data,time,nvars,vars,version

nalts = n_elements(data(0,0,0,*))
value = fltarr(nalts,nfiles)
alts = reform(data(2,0,0,*))/1000.

for ivar = 0, nvars - 1 do print, tostr(ivar),'   ', vars(ivar)
if n_elements(var) eq 0 then var = 3
var = fix(ask('variable to plot: ',tostr(var)))

value = fltarr(nalts,nfiles)
itime = intarr(6,nfiles)
for ifile = 0, nfiles - 1 do begin
    fn = files(ifile)
    get_1d_profile,fn,var,coordinates,profile
    
    itime(*,ifile) = get_gitm_time(fn)
    value(*,ifile) = profile
endfor

c_a_to_r,itime(*,0),stime
c_a_to_r,itime(*,nfiles-1),etime
time_axis, stime, etime,btr,etr, xtickname, xtitle2, xtickv, xminor, xtickn

setdevice, 'plot.ps','p',5,.95
loadct,39
ppp=2
space = 0.01
pos_space, ppp, space, sizes, ny = ppp

xtitle = vars(var)
ytitle = 'Altitude (m)'
xrange = mm(value)
;xrange = [-50,50]
colors = indgen(nfiles)*254/float(nfiles)+245/(nfiles)

get_position, ppp, space, sizes, 0, pos, /rect
pos(1) = pos(1) + .1
pos(0) = pos(0) + .02
pos(2) = pos(2) - .02
for ifile = 0, nfiles - 1 do begin
    
    plot,fltarr(nalts-4),alts(2:nalts-3),/nodata,xrange = xrange,background=0,$
  ytitle = ytitle,yrange = [100,600],pos=pos,/noerase,xtickname=strarr(10)+' ',charsize=1.2

    oplot,value(2:nalts-3,ifile),alts(2:nalts-3),color = colors(ifile)
endfor
        
get_position, ppp, space, sizes, 1, pos, /rect
pos(1) = pos(1) + .2
pos(3) = pos(3) + .1
pos(0) = pos(0) + .02
pos(2) = pos(2) - .02
for ifile = 0, nfiles - 1 do begin
    
    plot,fltarr(nalts-4),alts(2:nalts-3),/nodata,xrange = xrange,background=0,$
  ytitle = ytitle,yrange = [100,200],pos=pos,/noerase,xtitle=vars(var),charsize=1.2

    oplot,value(2:nalts-3,ifile),alts(2:nalts-3),color = colors(ifile)
endfor

pos(3) = pos(1) - .06
pos(1) = .005


display,alts(2:nalts-3)
if n_elements(ialt) eq 0 then ialt = 0
ialt = fix(ask('which altitude for line plot: ',tostr(ialt)))
plot, [0,etime-stime],/nodata,xtickname = xtickname,xtickv = xtickv, xticks = xtickn, $
  xminor = xminor, xtitle = xtitle2, ytitle = vars(var),charsize=1.2,pos = pos,/noerase,$
  xrange = [0,etime-stime],yrange = mm(value(ialt+2,*))
for ifile = 0, nfiles - 1 do begin
    c_a_to_r,itime(*,ifile),rt
    plots,rt-stime,value(ialt+2,ifile),color = colors(ifile),thick = 3, psym = sym(1)
endfor

closedevice

end
     
