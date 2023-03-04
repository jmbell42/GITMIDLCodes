nfiles = 100
openw,1,'getpdsdata.sh'
for ifile = 0, nfiles -1 do begin
   num = chopr('0'+tostr(ifile),2)
   printf,1,'wget  "http://pds-atmospheres.nmsu.edu/PDS/data/mgsa_0002/data/profile/p07xx/P07'+num+'.TAB"'
endfor
close,1


end
