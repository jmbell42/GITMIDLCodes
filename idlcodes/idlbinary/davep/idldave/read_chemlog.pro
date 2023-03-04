nspecies = 4
iNO = 0
iN_4S = 1
iN_2D = 2
iO2P = 3
cspecies = strarr(nspecies)
cspecies(0) = 'NO'
cspecies(1) = 'N(4S)'
cspecies(2) = 'N(2D)'
cspecies(3) = 'O2P'
close,5
openr, 5,'log'
start = 0
ended = 0
temp = ' '
nreacsmax = 20
production = strarr(nspecies,nreacsmax)
loss = strarr(nspecies,nreacsmax)
prates = fltarr(nspecies,nreacsmax)
lrates = fltarr(nspecies,nreacsmax)
ireacp = intarr(nspecies)
ireacl = intarr(nspecies)
while not start do begin
    readf, 5, temp
    if strpos(temp,'Final') ge 0 then start = 1
endwhile
readf,5,temp

while not ended do begin
    readf,5,temp
    if strpos(temp,'neutralsourcestotal') ge 0 then ended = 1

    arr = strsplit(temp,/extract)
    narrs = n_elements(arr)

    if narrs gt 3 then begin
    case arr(1) of
        cspecies(0) : begin
            case arr(0) of
                'S' : begin
                    production(0,ireacp(0)) = strjoin(arr(0:narrs-2),' ')
                    prates(0,ireacp(0)) = arr(narrs-1)
                    ireacp(0) = ireacp(0) + 1
                end 
                'L' : begin
                    loss(0,ireacl(0)) = strjoin(arr(0:narrs-2),' ')
                    lrates(0,ireacl(0)) = arr(narrs-1)
                    ireacl(0) = ireacl(0) + 1
                end 
            endcase
        end 
        cspecies(1) : begin
            case arr(0) of
                'S' : begin
                    production(1,ireacp(1)) = strjoin(arr(0:narrs-2),' ')
                    prates(1,ireacp(1)) = arr(narrs-1)
                    ireacp(1) = ireacp(1) + 1
                end 
                'L' : begin
                    loss(1,ireacl(1)) = strjoin(arr(0:narrs-2),' ')
                    lrates(1,ireacl(1)) = arr(narrs-1)
                    ireacl(1) = ireacl(1) + 1
                end 
            endcase
        end 
        cspecies(2) : begin
            case arr(0) of
                'S' : begin
                    production(2,ireacp(2)) = strjoin(arr(0:narrs-2),' ')
                    prates(2,ireacp(2)) = arr(narrs-1)
                    ireacp(2) = ireacp(2) + 1
                end 
                'L' : begin
                    loss(2,ireacl(2)) = strjoin(arr(0:narrs-2),' ')
                    lrates(2,ireacl(2)) = arr(narrs-1)
                    ireacl(2) = ireacl(2) + 1
                end 
            endcase
        end 
        cspecies(3) : begin
            case arr(0) of
                'S' : begin
                    production(3,ireacp(3)) = strjoin(arr(0:narrs-2),' ')
                    prates(3,ireacp(3)) = arr(narrs-1)
                    ireacp(3) = ireacp(3) + 1
                end 
                'L' : begin
                    loss(3,ireacl(3)) = strjoin(arr(0:narrs-2),' ')
                    lrates(3,ireacl(3)) = arr(narrs-1)
                    ireacl(3) = ireacl(3) + 1
                end
            endcase
        end
    endcase
endif

endwhile

for ispecies = 0, nspecies - 1 do begin
   print, ' '
    print, 'Species ',cspecies(ispecies)
    print, ' Production: '
    print, ' '
    for irate = 0, ireacp(ispecies) - 1 do begin
        print, production(ispecies,irate), ' ',tostrf(prates(ispecies,irate))
    endfor
    print, ' Loss: '
    print, ' '
    for irate = 0, ireacL(ispecies) - 1 do begin
        print, Loss(ispecies,irate), ' ',tostrf(lrates(ispecies,irate))
    endfor
    print, ' '
endfor
close,5
end
