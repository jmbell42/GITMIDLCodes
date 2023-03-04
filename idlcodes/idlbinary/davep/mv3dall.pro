filelist = file_search('3DALL*')
nfiles = n_elements(filelist)

tail = '00.bin'
for ifile = 0, nfiles -1  do begin
    base = strmid(filelist(ifile),0,18)
    spawn, 'cp ' + filelist(ifile)+ ' new/'+base+tail
endfor


end
