files = file_search('*.bin')
display,files
if n_elements(pfile) eq 0 then pfile = 0
pfile = fix(ask('which file to plot: ',tostr(pfile)))


gitm_read_bin, files(pfile), data,time,nvars,vars,version
c_r_to_a, itimearr,time
cta = [strmid(tostr(itimearr(0)),2,2),chopr('0'+tostr(itimearr(1)),2),chopr('0'+tostr(itimearr(2)),2),$
       chopr('0'+tostr(itimearr(3)),2),chopr('0'+tostr(itimearr(4)),2),chopr('0'+tostr(itimearr(5)),2)]
ctime = cta(0)+cta(1)+cta(2)+'_'+cta(3)+cta(4)+cta(5)
nalts = n_elements(data(0,0,0,*))
alts = reform(data(2,0,0,2:nalts-3))/1000.

if strpos(files(pfile),'ALL') ne 0 then begin
   allfile = file_search('*ALL_t'+ctime+'.bin')
   if allfile ne -1 then begin
      if n_elements(plott) eq 0 then plott = 'n'
      plott = ask('*all file found.  Plot temperature? ',plott)
   endif
endif else begin
   plott = 'n'
endelse


display,vars
if n_elements(pvar) eq 0 then pvar = 0
pvar = fix(ask('which variable to plot: ',tostr(pvar)))

get_1d_profile,files(pfile),pvar,coordinates,profile
coordinates = coordinates / 1000.

setdevice,'plot.ps','p',5,.95
pos = [.05,.05,.45,.55]
xtitle=vars(pvar)
ytitle='Altitude'
plot,profile,coordinates,xtitle=xtitle,ytitle=ytitle,pos=pos,yrange = mm(coordinates),ystyle=1,/noerase,$
        thick=3,charsize=1.2


if plott eq 'y' then begin
   get_1d_profile,allfile,15,tcoordinates,tprofile
   tcoordinates = tcoordinates / 1000.
   pos = [.5,.05,.95,.55]
   xtitle='Temperature'
   ytitle=''
   plot,tprofile,tcoordinates,xtitle=xtitle,ytitle=ytitle,pos=pos,yrange = mm(coordinates),ystyle=1,/noerase,$
        thick=3,charsize=1.2,ytickname=strarr(10)+' '
endif

closedevice
end
