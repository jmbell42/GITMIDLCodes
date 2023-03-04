
close,/all
if (n_elements(year) eq 0) then year = '2002'
year = ask('year',year)

if (n_elements(bmonth) eq 0) then bmonth = '10'
bmonth = string(fix(ask('start month',bmonth)), format='(I02)')

if (n_elements(bday) eq 0) then bday = '29'
bday = string(fix(ask('start day',bday)), format='(I02)')


btime = jday(fix(year),fix(bmonth),fix(bday))
etime = btime
byear = fix(year)



;;;;;;;;;

;    btime = 152.                    ;; insert start time (DOY)
;    etime = 181.                    ;; insert end time (DOY)
;    byear = 2002                    ;; insert start time (YEAR)
namef ='guvi'+year+bmonth+bday+'.dat' ;;name of out but file
  
;;;;;;;;;

    guvi_list = file_search('/csem1/GUVI/ALL_GUVI_DATA/*.sav', count= gcount) 
    i = 0
    found = 0
    while not found do begin
        
          len = strpos(guvi_list(i),'.sav',/reverse_offset,/reverse_search)-11
          ys = fix(strmid(guvi_list(i),len+3,2))+2000
          ds = fix(strmid(guvi_list(i),len,3))
          ye = fix(strmid(guvi_list(i),len+9,2))+2000
          de = fix(strmid(guvi_list(i),len+6,3))
          dateStart = [ys,ds,0,0,0]
          dateEnd = [ye,de,0,0,0]
          tempd = date_conv(dateStart,'F')
          monstart = fix(strmid(tempd,5,2))
          daystart = fix(strmid(tempd,8,2))
          tempd = date_conv(dateEnd,'F')
          monend = fix(strmid(tempd,5,2))
          dayend = fix(strmid(tempd,8,2))
          
          itimes = [ys,monstart,daystart,0,0,0]
          itimee = [ys,monend,dayend,0,0,0]
          filet = [byear,bmonth,bday,0,0,0]
          c_a_to_r,itimes,rts
          c_a_to_r,itimee,rte
          c_a_to_r,filet,rtw

          if rtw ge rts and rtw lt rte then begin
              found = 1
              ifile = i
          endif

          i = i + 1
      endwhile

       restore, guvi_list(ifile)
       
       gyear_add =reform(bs.yy)
       glon_add = reform(bs.glon)
       glat_add = reform(bs.glat)
       gnmf2_add = reform(bs.nmf2)
       ghmf2_add = reform(bs.hmf2)
       gtec_add = reform(bs.tec) 
       gdoy_add = reform(bs.doy)
       gtime_add = reform(bs.time)
       gorbit_add = reform(bs.orbit)


	  
          gyear  = gyear_add
          glon   = glon_add 
          glat   = glat_add 
          gnmf2  = gnmf2_add 
          ghmf2  = ghmf2_add
          gtec   = gtec_add 
          gdoy   = gdoy_add
          gtime  = gtime_add
          gorbit = gorbit_add
          
   

    index= where( gdoy le etime AND gdoy ge btime AND gyear eq byear  , count)

     gyear  = gyear(index)	
     glon   = glon(index)
     glat   = glat(index)
     gnmf2  = gnmf2(index)/.000001
     ghmf2  = ghmf2(index)
     gtec   = gtec(index)
     gdoy   = gdoy(index)
     gtime  = gtime(index)
     gorbit = gorbit(index)    

     
     itime=fltarr(6,count)



;;;;;;; Write data to file for GITM SATELLITE FILE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;;;;;;;;;
 limit = 0
 limit=n_elements(gdoy)       
       
        openw, 10,namef

        namef= strcompress(namef)
;        printf,10, filename
        printf,10,'#START'
        ;printf,10, format='(3x,A,11x,A, 9x, A, 10x,A, 10x,A,10x,A,6x,A,8x,A, 10x,A,8x,A)','YYYY','MM','DA', $
         ;          'HR','MI','SE' , 'MS','LON', 'LAT', 'ALT'

        da=0 

        for j=0L, limit-1  DO BEGIN
              
        
                CALDAT,JULDAY(1,gdoy(j),year),mon,da
 
                itime= [year,mon,da,0,0,0]
                c_a_to_r, itime, basetime
       
                realtime = basetime + gtime(j)/1000.
                c_r_to_a, itime, realtime
               


;               printf,10, format='(2(4I),3(2I),9(4F20.4))',year,mon, da, hr, min, sec, 0.00,( orb_lon(j)), $
;                           orb_lat(j), 300.0 
                printf,10, format='((I4), 6(I5),3(F10.4))',itime, 0.00,( glon(j)), $
                           glat(j), 300.0
         
         
        endfor

        close,10




end 
