PRO calcsza, date,time,lat,lon,zenith

t0=(90.-lat)*!dtor                            ; colatitude of point
t1=(90.-latsun)*!dtor                         ; colatitude of sun

p0=lon*!dtor                                  ; longitude of point
p1=lonsun*!dtor                               ; longitude of sun

zz=cos(t0)*cos(t1)+sin(t0)*sin(t1)*cos(p1-p0) ; up          \
xx=sin(t1)*sin(p1-p0)                         ; east-west    > rotated coor
yy=sin(t0)*cos(t1)-cos(t0)*sin(t1)*cos(p1-p0) ; north-south /

azimuth=atan(xx,yy)/!dtor                     ; solar azimuth 
zenith=acos(zz)/!dtor     

end
