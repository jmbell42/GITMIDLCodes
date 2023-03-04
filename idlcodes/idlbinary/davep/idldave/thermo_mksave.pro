
filelist = findfile("*.bin")

nfiles = n_elements(filelist)

for ifile = 0, nfiles - 1 do begin

    nBLKlat = 0
    nBLKlon = 0
    nBLK = 0

    file = filelist(ifile)
    read_thermosphere_file, file, nvars, nalts, nlats, nlons,vars,data, $
      nBLKlat, nBLKlon, nBLK, iTime, Version

    ofile = strmid(file,6,strlen(file)-6)+".save"
    print, ofile
    save, file=ofile, nvars, nalts, nlats, nlons, vars, data, iTime, Version

endfor

end
