function d_in_m, year,month

case month of
    1: days = 31
    2: begin
        ly = isleapyear(year)
        if ly eq 1 then days = 29 else days = 28
    end
    3: days = 31
    4: days = 30
    5: days = 31
    6: days = 30
    7: days = 31
    8: days = 31
    9: days = 30
    10: days = 31
    11: days = 30
    12: days = 31
endcase

return, days
end

function IsLeapYear, year
if fix(year) mod 4 eq 0 then return, 1
end

 