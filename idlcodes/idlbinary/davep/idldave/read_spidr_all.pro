filename = 'spidr*.txt'
filename = filename(0)
close,1
openr,1, filename

t = ' '
while not eof(1) do begin
   readf,1,t
   if strpos(t,'#') ge 0 then begin
      notdone = 1
      while notdone do begin
         close, 2
         readf,1,t
         if strpos(t,'Element') ge 0 then begin
            temp = strsplit(t,/extract)
            type = strjoin(temp(1:*))
         endif
         
         if strpos(t,'Station name') ge 0 then begin
            temp = strsplit(t,/extract)
            station = temp(2)
            if strpos(station,'/')ge 0 then begin
               l = strpos(station,'/')
               station = strjoin(strmid(station,0,l-1),'-'+strmid(station,l+1))
            endif
            code = strmid(temp(n_elements(temp)-1),1,5)

            stationfile = code+'.xml'
            close,5
            openr,5,stationfile
            done = 0
            while not done do begin
               readf, 5, t
               t = strtrim(t,2)
               if strpos(t,'<westbc>') ge 0 then begin
                  longitude = strmid(t,8,4)
                  if float(longitude) lt 0 then longitude = tostrf(360 + float(longitude))

                  readf,5,t
                  readf,5,t
                  t = strtrim(t,2)
                  latitude = strmid(t,9,4)
                  done = 1

               endif
            endwhile
            close,5
         endif
         
         if strpos(t,'Missing value') ge 0 then begin
            temp = strsplit(t,/extract)
            missing = temp(2)
         endif
         
         if strpos(t,'yyyy-MM-dd') ge 0 then begin
            readf,1,t
            if strpos(t,'#') lt 0 then begin
               notdone = 0
               
               file = 'iono_'+station+'_'+type+'.dat'
               openw,2,file
               printf,2,'Element: '+type
               printf,2,'Station name: '+station
               printf,2,'Coordinates: '+longitude+' E.Lon '+Latitude + ' N.Lat'
               printf,2,'Missing Value: '+missing
               printf,2,'#yyyy-MM-dd HH:mm value qualifier description'
               printf,2,'#START'
            endif
         endif
      endwhile

   endif
   printf,2,t
endwhile
   
close,2
close,1
   
end

   

