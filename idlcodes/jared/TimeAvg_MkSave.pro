; Small code to set colors for plotting below ------------------>

device, decomposed = 0
bottom = 0

; fixes all plots to specifications later on

!x.style =1 

; Load graphics colors:----------------->

red = [   0, 255,   0, 255,   0, 255,   0, 255,$ 
          0, 255, 255, 112, 219, 127,   0, 255]
grn = [   0,   0, 255, 255, 255,   0,   0, 255,$ 
          0, 187, 127, 219, 112, 127, 163, 171]
blu = [   0, 255, 255,   0,   0,   0, 255, 255,$ 
        115,   0, 127, 147, 219, 127, 255, 127]

tvlct, red, grn, blu, bottom

; Set color names :----------------->
names = [ 'Black', 'Magenta', 'Cyan', 'Yellow', $
          'Green', 'Red', 'Blue', 'White',      $
          'Navy', 'Gold', 'Pink', 'Aquamarine', $
           'Orchid', 'Gray', 'Sky', 'Beige']

; END COLOR SETUP


GetNewData = 1
fpi = 0

filelist_new = findfile("*.bin")
nfiles_new = n_elements(filelist_new)
if (nfiles_new eq 1) then begin
    filelist_new = findfile("????_*.dat")
    nfiles_new = n_elements(filelist_new)
endif

if n_elements(nfiles) gt 0 then begin
    if (nfiles_new eq nfiles) then default = 'n' else default='y'
    GetNewData = mklower(strmid(ask('whether to reread data',default),0,1))
    if (GetNewData eq 'n') then GetNewData = 0 else GetNewData = 1
endif

if (GetNewData) then begin

    thermo_readsat, filelist_new, data, time, nTimes, Vars, nAlts, nSats, Files
    nFiles = n_elements(filelist_new)

endif


; Now Time-Average the Profiles

; First, remove the first array index (spurious)
  newdata = reform(data)

; Next, Time Average the Data

  TimeAveData = total(newdata, 1)/nfiles
  Alts = reform(TimeAveData[2,*])/1000.0

  TimeAveData = TimeAveData
  Alts = reform(TimeAveData[2,*])/1000.0

  nGcs = 2  ; the Number of Ghost Cells (Top and Bottom) 

  savefile = 'TimeAvg.save'

  save, filename = savefile, TimeAveData, Alts
end
