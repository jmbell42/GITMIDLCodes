filelist = file_search('fism*.sav')
display,filelist
if n_elements(ifile) eq 0 then ifile = 0
ifile = fix(ask('which file to plot ',tostr(ifile)))

fname = filelist(ifile)
restore, fname

l1 = strpos(fname,'.sav')-15
sdate = strmid(filelist(ifile),l1,7)
file = 'fism_ascii_'+sdate+'.dat'
openw, 1, file

nwaves = n_elements(fism_wv)

printf, 1, '#START'
for iwave = 0, nwaves -1 do begin
   printf, 1, fism_wv(iwave),fism_av_sp(iwave)
endfor
close,1

end

