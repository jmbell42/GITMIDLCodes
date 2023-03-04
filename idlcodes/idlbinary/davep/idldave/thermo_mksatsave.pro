

filelist1 = findfile("????_00?_t*.dat")
filelist2 = findfile("????_01?_t*.dat")
filelist3 = findfile("????_02?_t*.dat")

filelist = [filelist1, filelist2, filelist3]

nfiles = n_elements(filelist)

iCurSat = 0
iFile = 0

nSats = 0
sats    = strarr(100)
nSwaths = intarr(100)
nPts    = intarr(100,100)
nPts(0,0) = 1

sats(0) = strmid(filelist(0),0,4)

for i=1,nFiles-1 do begin
    cFile = filelist(i)
    if (strpos(cFile, sats(nSats)) ne 0) then begin
        nSats = nSats + 1
        sats(nSats) = strmid(filelist(i),0,4)
    endif else begin
        n = fix(strmid(cFile,5,3))
        if (n gt nSwaths(nSats)) then nSwaths(nSats) = n
        nPts(nSats,n-1) = nPts(nSats,n-1) + 1
    endelse
endfor
nSats = nSats + 1

if (nSats gt 1) then begin
    for i=0,nSats-1 do print, tostr(i)+'. '+sats(i)
    if (n_elements(isat) eq 0) then isat = 0
    isat = fix(ask('satellite to plot',tostr(isat)))
endif else isat = 0

nPtsSw = nSwaths(iSat)
nTimes = max(npts(iSat,*))

it = 0

for i=0,nFiles-1 do begin

    cFile = filelist(i)

    if (strpos(cFile, sats(isat)) eq 0) then begin

        read_thermosphere_file, cFile, nvars_t, nalts_t, nlats_t, nlons_t, $
          vars_t, data_t, nBLKlat_t, nBLKlon_t, nBLK_t

        if (it eq 0) then begin
            data = fltarr(nPtsSw, nTimes, nvars_t, nalts_t)
            time = dblarr(nTimes)
        endif

        if (n ne fix(strmid(cFile,5,3))-1) then it = 0
        n = fix(strmid(cFile,5,3))-1

        data(n, it, *, *) = data_t(*,0,0,*)

        if (n eq 0) then begin
            itime = [ $
                      fix(strmid(cfile,10,2)), $
                      fix(strmid(cfile,12,2)), $
                      fix(strmid(cfile,14,2)), $
                      fix(strmid(cfile,17,2)), $
                      fix(strmid(cfile,19,2)), $
                      fix(strmid(cfile,21,2))]
            c_a_to_r, itime, rtime
            time(it) = rtime
        endif

        it = it + 1

    endif

endfor

Vars = vars_t

nSwaths = nSwaths(iSat)
SatFile = sats(iSat)+'.save'

save, data, time, Vars, nSwaths, nPtsSw, file = SatFile, nTimes, nAlts_t

end
