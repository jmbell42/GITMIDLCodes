FUNCTION next_day,month,day

case month of
    1: ndays = 31
    2: ndays = 28
    3: ndays = 31
    4: ndays = 30
    5: ndays = 31
    6: ndays = 30
    7: ndays = 31
    8: ndays = 31
    9: ndays = 30
    10: ndays = 31
    11: ndays = 30
    12: ndays = 31
endcase

if day eq ndays then nextday = 1
if day lt ndays then nextday = day + 1
if day gt ndays then nextday = -1

return, nextday
end
