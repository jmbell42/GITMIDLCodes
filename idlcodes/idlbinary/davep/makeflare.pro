if n_elements(date) eq 0 then date = ' ' 
date = ask('flare date (mm-dd-yyyy): ',date)

iyear = strmid(date,6,4)
iyearshort = strmid(date,8,2)
imonth = strmid(date, 0,2)
iday = strmid(date,3,2)

goesfile = '~/GOES/'+tostr(iyear)+'/data/*'+tostr(iyearshort)+tostr(imonth)+'.TXT'

