if n_elements(date) eq 0 then date = ''
date = ask('date (yyyy-mm-dd): ',date)
cdate = strmid(date,2,2)+strmid(date,5,2)+strmid(date,8,2)
gitmdir = '/data6/gitm/Runs/'+strmid(date,0,4)+'/'+strmid(date,5,2)+'/'
kpfile = '~/KP/'+strmid(date,0,4)+'.dat'


kp = strarr(8)
ktime = [0,3,6,9,12,15,18,21,24]

done = 0
close,/all
openr,1,kpfile

t = ''
while not done do begin
    readf,1,t
    
    temp = strmid(t,0,6)
    if temp eq cdate then done = 1
endwhile
close,1

for itimes = 0, 7 do begin
    kp_t = strmid(t,itimes*2 + 12,2)
    if fix(kp_t) lt 10 then kp_t='07'
    if strmid(kp_t,1,1) eq 0 then kp(itimes) = strmid(kp_t,0,1)
    if strmid(kp_t,1,1) eq 3 then kp(itimes) = strmid(kp_t,0,1)+'+'
    if strmid(kp_t,1,1) eq 7 then kp(itimes) = tostr(fix(strmid(kp_t,0,1))+1)+'-'

endfor



end

