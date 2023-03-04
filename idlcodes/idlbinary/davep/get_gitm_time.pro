FUNCTION get_gitm_time, filename

len = strpos(filename,'_t',/reverse_search) + 2
year = 2000+fix(strmid(filename,len,2))
mon = fix(strmid(filename,len+2,2))
day = fix(strmid(filename,len+4,2))
hour = fix(strmid(filename,len+7,2))
min = fix(strmid(filename,len+9,2))
sec = fix(strmid(filename,len+11,2))

return, [year,mon,day,hour,min,sec]

end