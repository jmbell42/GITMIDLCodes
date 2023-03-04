if n_elements(dir) eq 0 then dir = '.'
dir = ask('which directory to save: ',dir)

filelist_new = file_search(dir+'/3D*')
if strpos(filelist_new(0),'ALL') ge 0 then isall = 1 else isall = 0

nfiles_new = n_elements(filelist_new)
if n_elements(nfiles) eq 0 then nfiles = 0
ift = 0
type = ' '
filetype = strarr(nfiles_new)
for ifile = 0, nfiles_new - 1 do begin
   l1 = strpos(filelist_new(ifile),'/',/reverse_search)+1
   type = strmid(filelist_new(ifile),l1,5)

   if ifile eq 0 then filetype(0) = type
   if type eq '3DUSR' then stop
   if filetype(ift) ne type then begin
      ift = ift + 1
      filetype(ift) = type
   endif
endfor

filetype = filetype(0:ift)
display, filetype
if n_elements(ft) eq 0 then ft = 0
ft = fix(ask('which filetype: ',tostr(ft)))
whichtype = filetype(ft)
filelist_new = file_search(dir+'/'+whichtype+'*.bin')
nfiles_new = n_elements(filelist_new)
;print, filelist_new
filelist=filelist_new
read_thermosphere_file, filelist(0), nvars, nalts, nlats, nlons, $
  vars, datat, rb, cb, bl_cnt
nalts = n_elements(datat(0,0,0,*))

alt = reform(datat(2,0,0,*))/1000.0
lat = reform(datat(1,2:nlons-3,2:nlats-3,0))/!dtor

display, alt
if n_elements(palt) eq 0 then palt = 0
palt = fix(ask('which altitude to save: ',tostr(palt)))
if n_elements(altold) eq 0 then altold = 0

reread = 1
if palt ne altold then begin

    if nfiles_new eq nfiles then begin
        reread = 'n'
        reread = ask('whether to reread files: ',reread)
        if strpos(reread,'y') ge 0 then reread = 1 else reread = 0
    endif

endif

altold = palt

nfiles = nfiles_new
allother = fltarr(nfiles,3,nlons,nlats)
rtime = dblarr(nfiles)

if reread then begin
    
    for ifile = 0,nfiles - 1 do begin
        itime = get_gitm_time(filelist(ifile))
        c_a_to_r, itime, rt
        rtime(ifile) = rt
    endfor
    
    thermo_getall,filelist,palt,data,nmf2,hmf2,on2,sza
    
    iglb = 0
    iday = 1
    init = 2
    ihlt = 3
    iavg = 0
    imin = 1
    imax = 2
    
    alldata = data
    if isall then begin
        allother(*,0,*,*) = nmf2
        allother(*,1,*,*) = hmf2
        allother(*,2,*,*) = on2        
    endif
endif

len = strpos(dir,'/')
if strpos(dir,'.') eq 0 then filename = 'idl.sav' else $
  filename = strmid(dir,0,len)+'THM.sav'
;len = strpos(dir,'3DALL')+5
;filename = strmid(dir,len)+'.sav'
save, alldata,allother,rtime,palt,sza, filename=filename

end

