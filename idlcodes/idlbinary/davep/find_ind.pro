function find_ind, arr, num,dim

case dim of
    0: ind = where(arr(*,0) eq num)

    1: ind = where(arr(0,*) eq num)
endcase


return, ind

end
