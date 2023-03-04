rhoc0 = 1
rhoc1 = .1 
rhofac = 0.06
noc = .327
redfac = .06

restore,'rho.sav'
grtime=rtime
gstime=stime
grho = aves2

if n_elements(ftime) eq 0 then ftime = [0,0,0,0,0,0]
ftime = fix(strsplit(ask('flare time: ',strjoin(tostr(ftime),' ')),/extract))

if n_elements(nfiles) eq 0 then nfiles = 0
nfiles = fix(ask('how many flux files: ',tostr(nfiles)))

sdate = tostr(ftime(0))+chopr('0'+tostr(ftime(1)),2)+chopr('0'+tostr(ftime(2)),2)
if n_elements(nfilesold) eq 0 then nfilesold = 0
if n_elements(file) eq 0 or nfiles ne nfilesold then begin
    file = strarr(nfiles)
endif
nfilesold = nfiles
fism = intarr(nfiles)
for ifile = 0,nfiles - 1 do begin
    file(ifile) = ask('flux file '+tostr(ifile)+' (fism to use fism directory): ',file(ifile))
    if strpos(file(ifile),'fism') ge 0 then begin
        file(ifile) = file_search('~/UpperAtmosphere/FISM/binnedfiles/'+tostr(ftime(0))+sdate+'.dat')
        fism(ifile) = 1
    endif
endfor


date = tostr(ftime)
cyear = date(0)
cmonth = date(1)
cday = (date(2))
chour = (date(3))
cmin = (date(4))

;itime = fix([cyear,cmonth,cday,chour,cmin,'0'])
c_a_to_r,ftime,stime

hours = [.5,1,2,4,8,12,16,24];1-6
hours = [.25,.5,.75,1,2,4,6,8,12,24];7-8
hours = [.25,.5,2,6,8,12,16];9

coefs = [.6,.3,.01,.01,1.0,.01,.01,.01] ;1
coefs = [.3,.6,.01,.01,1.0,.01,.01,.01] ;2
coefs = [.2,.5,.5,.01,1.0,.01,.01,.01] ;3
coefs = [.1,.3,.6,.01,1.0,.01,.01,.01] ;4
coefs = [.3,.3,.6,.01,1.0,.01,.01,.01] ;5
coefs = [.01,1,.01,.01,.01,.01,.01,.01] ;6

coefs = [.2,.2,.6,1,.01,.01,.01,.01,.01] ;7
coefs = [.5,.01,.01,.01,.2,.01,1.2,.8,1,.01] ;8
coefs = [.5,.01,.01,.01,.2,.01,1.2,.8,1,.01] ;8
coefs = [.2,.2,1.2,.8,1.2,.6] ;9
coefs = [.2,.01,.2,.8,1.2,1.2] ;9
coefs = [.2,.01,.1,.4,.01,1.2,1.2] ;9
dtime = .25
ntimes = 24/dtime+1
outtime = fltarr(ntimes)

for itime = 0, ntimes -1 do begin
    outtime(itime) = itime*dtime
endfor
;outtime = [0,.25,.5,.75,1,2,4,6,8,10,12,14,16,18,20,22,24]
;ntimes = n_elements(outtime)
nhours = n_elements(hours)

reread = 1
if n_elements(no) ne 0 then begin
    reread = 'n'
    reread = ask('whether to reread: ',reread)
    if strpos(reread,'y') ge 0 then reread = 1 else reread = 0
endif

if reread then begin
    energy = fltarr(nfiles,ntimes,nhours)
    
    for ifile = 0, nfiles - 1 do begin
        print, ' '
        print, 'Looking at file '+file(ifile)
        for itime = 0, ntimes -1 do begin
        rt = stime + outtime(itime)*3600.
        c_r_to_a,ta,rt
        print, 'Working on '+strjoin(tostr(ta),' ')+'...'
        get_energies,en,file(ifile),ta,ftime, hours,fism
        energy(ifile,itime,*) = en

    endfor
endfor
endif
 
no = fltarr(nfiles,ntimes)
rho = fltarr(nfiles,ntimes)

for ifile = 0, nfiles -1 do begin
    for itime = 1, ntimes - 1 do begin
        no(ifile,itime) = noc*total(coefs*energy(ifile,itime,*))
        rho(ifile,itime) = (rho(ifile,itime-1) + $
                            rhofac*(rhoc0*energy(ifile,itime,0) + rhoc1*energy(ifile,itime,1) - $
                                    no(ifile,itime)) - redfac*0.01*rho(ifile,itime-1)/(no(ifile,itime)+0.01)) 

    endfor
endfor
;rho = rho*rhofac

names = strarr(nfiles)
len = strpos(file,'.',/reverse_search,/reverse_offset)
for ifile = 0, nfiles - 1 do begin
    names(ifile) = strmid(file(ifile),0,len(ifile))
endfor


setdevice,'plot.ps','p',5,.95
ppp = 4
space = 0.02
pos_space, ppp, space, sizes, ny = ppp

loadct,39
get_position, ppp, space, sizes, 0, pos, /rect
pos(0) = pos(0) + .1


yrange = mm(no)
plot,outtime,no(0,*),  ytitle = '[NO] enhancement',$
  pos = pos,/nodata,yrange= yrange,/noerase,xtickname=strarr(10)+' '

if nfiles gt 1 then colors = findgen(nfiles)*254/nfiles+254/nfiles else colors = 0
for ifile = 0, nfiles - 1 do begin
    oplot, outtime,no(ifile,*),thick=3,color = colors(ifile)
 endfor



;legend,names,color=colors,linestyle=fltarr(nfiles),box = 0, $
;  pos = [pos(2)-.25,pos(3)-.03],/norm


get_position, ppp, space, sizes, 1, pos, /rect
pos(0) = pos(0) + .1

yrange = mm(rho)
yrange = [0,15]
plot,outtime,rho(0,*),xtitle = 'Hours after the start of the flare ', $
  ytitle = 'Rho enhancement',$
  pos = pos,/nodata,yrange= yrange,/noerase

for ifile = 0, nfiles - 1 do begin
    oplot, outtime,rho(ifile,*),color = colors(ifile), thick = 3
 endfor



oplot,(grtime-stime)/3600.,grho(0,*),thick=3,color=0,linestyle=2


closedevice
  
end
        

