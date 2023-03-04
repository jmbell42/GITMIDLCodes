PRO get_1d_profile, filename, variable,coordinates, profile
gitm_read_bin, filename, data,time,nVars,Vars,version

s = size(data)
if (s(0) eq 4) then begin
    nLons = s(2)
    nLats = s(3)
    nAlts = s(4)
endif
if (s(0) eq 3) then begin
    nLons = s(2)
    nLats = s(3)
    nAlts = 1
endif
nBLK = 1
c_r_to_a, itime, time(0)

profile = reform(data(variable,0,0,*))
coordinates = reform(data(2,0,0,*))

end
