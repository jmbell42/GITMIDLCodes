if n_elements(reread) eq 0 then reread  = 'y'
if n_elements(nfiles) gt 0 then begin
    reread = ask('whether to re-find files: ',reread)
endif

if reread eq 'y' then begin
    files = file_search('e*.bin')
    nfiles = n_elements(files)
endif

dir = 'esr'

for ifile = 0L, nfiles - 1 do begin
    fn = files(ifile)
    l = strpos(fn,'_t') + 2
    year = fix(strmid(fn,l,2)) + 2000
    mon = fix(strmid(fn,l+2,2))
    day = fix(strmid(fn,l+4,2))

    jd = jday(year,mon,day)

    season = season(jd)
    case season of 
        'Winter': season = 'win'
        'Summer': season = 'sum'
        'Fall'  : season = 'fal'
        'Spring': season = 'spr'
    endcase

    cmd = 'cp '+ fn +' ~/ifs1/IPY/'+dir+'/'+ season+'/'
    print, cmd
    spawn,cmd

endfor


end
