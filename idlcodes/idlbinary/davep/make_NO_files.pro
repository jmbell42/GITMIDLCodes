filelist = file_search('3DALL*')
nfiles = n_elements(filelist)


for ifile = 0, nfiles - 1 do begin

   
   fn = filelist(ifile)
   print, 'Reading file: ',fn
   read_thermosphere_file, fn, nvars, nalts, nlats, nlons, $
                           vars, data, rb, cb, bl_cnt

   alt = reform(data(2,*,*,*)) / 1000.0
   lat = reform(data(1,*,*,*)) / !dtor
   lon = reform(data(0,*,*,*)) / !dtor
   
   l = 7
   year = strmid(fn,l, 2)
   mont = strmid(fn,l+2, 2)
   day  = strmid(fn,l+4, 2)
   hour = strmid(fn, l+7, 2)
   minu = strmid(fn,l+9, 2)
   seco = strmid(fn,l+11, 2)

     
   if year lt 50 then year = tostr(fix(year) + 2000) else year = tostr(fix(year) + 1900)

   filename = 'NO_'+year+mont+day+'_'+hour+minu+seco+'.bin'

   openw,1,filename
   printf,1,'#NO density and vertical velocity at 100km'
   printf,1,'#Longitude(deg)   Latitude(deg)  [NO](1/m^3) [NO]_120 V_NO(m/s)'
   ialt1 = 2
   ialt2 = 12
   for ilon = 2, nlons - 3 do begin
      for ilat = 2, nlats - 3 do begin
         printf,1, lon(ilon,ilat,ialt1),lat(ilon,ilat,ialt1),data(8,ilon,ilat,ialt1),$
                 data(8,ilon,ilat,ialt2),data(23,ilon,ilat,ialt1),format='(5G9.3)'
      endfor
endfor

close,1

endfor

end
