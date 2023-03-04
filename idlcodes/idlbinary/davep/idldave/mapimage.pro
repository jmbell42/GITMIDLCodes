
filelist = findfile("-t *.jpg")
file = filelist(0)

file = ask("jpg file to convert to tecplot",file)

read_jpeg, file, image

nLons = n_elements(image(0,*,0))
nLats = n_elements(image(0,0,*))

lats = findgen(nLats) / (nLats-1) * !pi - !pi/2
lons = findgen(nLons) / (nLons-1) * 2*!pi

openw,1,file+".dat"

printf,1,"TITLE = ""Earth Surface Map"""
printf,1,"VARIABLES = ""X [R]"", ""Y [R]"", ""Z [R]"",""Earth-Red"", ""Earth-Green"", ""Earth-Blue"""
printf,1,"ZONE T=""Earth"", I="+tostr(nLats)+", J="+tostr(nLons)+", K=1, ZONETYPE=Ordered, DATAPACKING=POINT"

for iLon = 0, nLons-1 do for iLat = 0,nLats-1 do begin

  x = cos(lats(iLat))*cos(lons(iLon))
  y = cos(lats(iLat))*sin(lons(iLon))
  z = sin(lats(iLat))

  printf,1,x,y,z, $
    float(image(0,iLon,iLat))/255.0,$
    float(image(1,iLon,iLat))/255.0,$
    float(image(2,iLon,iLat))/255.0

endfor
close,1

end
