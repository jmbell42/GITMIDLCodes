getnewdata = 1

filelist_new = file_search('*out.dat')
nfiles_new = n_elements(filelist_new)

if n_elements(nfiles) eq 0 then nfiles = 0

if nfiles eq nfiles_new then begin
    getnewdata = 0 
    getnewdata = fix(ask("get new data: (0/1) ", tostr(getnewdata)))
endif

nfiles = nfiles_new


if getnewdata then begin
itime = intarr(3,nfiles)
rtime = fltarr(nfiles)    
    for ifile = 0, nfiles -1 do begin
        
        fn = filelist_new(ifile)
        read_hydro_file, fn, data, nvars, nlons, nlats, nalts, lats, lons, alts, vars

        if ifile eq 0 then alldata = fltarr(nfiles,nvars,nlons,nlats,nalts)

        alldata(ifile,*,*,*,*) = data
        
        len = 0
        chour = strmid(fn,len,2)
        cmin = strmid(fn,len+2,2)
        csec = strmid(fn,len+3,2)
        itime(*,ifile) = [chour,cmin,csec]
        rtime(ifile) = fix(chour)*60.+fix(cmin)+fix(csec)/60.

    endfor


endif


for ivar = 0, nvars - 1 do print, tostr(ivar), ' ', vars(ivar)

if n_elements(plotvar) eq 0 then plotvar = 3

plotvar = fix(ask("which variable to plot: ", tostr(plotvar)))

for ialt = 0, nalts - 1 do print, tostr(ialt), alts(ialt)
if n_elements(whichalt) eq 0 then whichalt = 0
whichalt = fix(ask("which alt to plot: ",tostr(whichalt)))

x = reform(alldata(*,0,*,*,whichalt))
y = reform(alldata(*,1,*,*,whichalt))

val = reform(alldata(*,plotvar,*,*,whichalt))

maxval = fltarr(nfiles)
minval = fltarr(nfiles)
meanval = fltarr(nfiles)
 
for ifile = 0, nfiles - 1 do begin

    maxval(ifile) = max(val(ifile,*,*),imax)
    minval(ifile) = min(val(ifile,*,*),imin)
    meanval(ifile) = mean(val(ifile,*,*),imean)

    minloc(ifile) = imin
    maxloc(ifile) = imax
    meanloc(ifile) = imean
endfor

setdevice, 'plot.ps', 'p',5,.95
ppp = 4
space = 0.01
pos_space, ppp, space, sizes,ny = ppp

get_position, ppp, space, sizes, 0, pos, /rect
pos(0) = pos(0) + .05

plot,rtime,/nodata,xtitle = 'Time (minutes)', ytitle = vars(plotvar), charsize = 1.2, $
  xrange = mm(rtime),pos = pos,xstyle = 1,/noerase, yrange = mm([maxval,minval])

oplot,rtime,maxval,linestyle = 2, thick = 3
oplot,rtime,meanval,linestyle = 0, thick = 3
oplot,rtime,minval,linestyle = 1, thick = 3


get_position, ppp, space, sizes, 0, pos, /rect
pos(0) = pos(0) + .05

plot,rtime,/nodata,xtitle = 'Time (minutes)', ytitle = vars(plotvar), charsize = 1.2, $
  xrange = mm(rtime),pos = pos,xstyle = 1,/noerase, yrange = mm([maxval,minval])

oplot,rtime,imax
closedevice


end
