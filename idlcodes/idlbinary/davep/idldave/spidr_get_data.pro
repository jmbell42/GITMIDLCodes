;+
; Function to retrieve SPIDR data for a particular [station,element,time range] as a structure 
; via WebServices
; 
; :Author: Rob Redmon
; :Copyright: NGDC, 2010
; 
; :Requires: IDL 6.4 or newer.
; 
; :History:
;     2006-08 Initial version.  Depended on SOAP/WS, Java, Java Bridge, System Unzip.
;     2009-11 SPIDR's new RESTful services allowed the removal of many dependencies.
;     2010-01 Added wget chunking to reduce instantaneous load on SPIDR.  Added logging. Minor bug fixes.
;
; :Usage:
;     data = spidr_get_data( param, start_time [year, month, day, hour, minute, second], end_time [year, month, day, hour, minute, second] )
; 
; :Params:
;     param: in, required, type='string'
;         element.station or leave .station blank for a global index like Kp. E.g. foF2.BC840, or index_kp.
;     start_time: in, required, type='integer array'
;         Start time, e.g. [2009, 10, 31, 0, 0, 0]  which represents '2009-10-31 00:00:00'.
;     end_time: in, required, type='integer array'
;         End time, e.g.   [2009, 10, 31, 12, 30, 0] which represents '2009-10-31 12:30:00'.
;         
; :Keywords:         
;     SAMPLING: in, type='integer'
;         Sampling or averaging to perform.  Values supported depend on Station and Element in question.
;         0 (or absent) => Native
;         otherwise     => User choice (assumes supported).
;         
;     UNIX_TIME: in, type='boolean'
;         0 (or absent) => default to Julian time
;         1             => seconds since 1970-01-01 00:00:00
;         
;     VERBOSITY: in, type='integer'
;         1: show {fatal}
;         2: show {fatal,error}
;         3: show {fatal,error,warn}
;         4: show {fatal,error,warn,info}
;         5: show all messages
;         unset: use existing debug level as default
;         
;     HELP: in, type='boolean'
;         0: do nothing
;         1: display usage
;         
; :Returns:
;     Structure of data or 0 if no data exists for request.
;
; :Examples:
;     data = spidr_get_data( 'index_f107', [1997,1,1,0,0,0], [1997,12,25,12,30,0] )    
;     data = spidr_get_data( 'foF2.BC840', [2009, 11, 1, 0, 0, 0], [2009, 11, 30, 0, 0, 0] )
;     data = spidr_get_data( 'imf_bx.OMNI', [1996,1,1,0,0,0], [1998,12,31,23,59,59], VERBOSITY=VERBOSITY )
;     
; TODO: add sanity tests: 1) check for repeating times
;-
function spidr_get_data, param, start_time, end_time, SAMPLING=SAMPLING, UNIX_TIME=UNIX_TIME, VERBOSITY=VERBOSITY, HELP=HELP

    ; boiler plate
    my_name = 'spidr_get_data'
    ngdc_boiler, VERBOSITY=VERBOSITY
    VERBOSITY = !LOG.verbosity

        
    ; Help
    if ( keyword_set( HELP ) ) then begin
        print, "  :Usage:"        
        print, "      data = spidr_get_data( param, start_time [year, month, day, hour, minute, second], end_time [year, month, day, hour, minute, second] )"        
        print, "  "
        print, "  :Params:"
        print, "      param: in, required, type='string'"
        print, "          element.station or leave .station blank for a global index like Kp. E.g. foF2.BC840, or index_kp."
        print, "      start_time: in, required, type='integer array'"
        print, "          Start time, e.g. [2009, 10, 31, 0, 0, 0]  which represents '2009-10-31 00:00:00'."
        print, "      end_time: in, required, type='integer array'"
        print, "          End time, e.g.   [2009, 10, 31, 12, 30, 0] which represents '2009-10-31 12:30:00'."
        print, "          "
        print, "  :Keywords:"
        print, "      SAMPLING: in, type='integer'"
        print, "          Sampling or averaging to perform.  Values supported depend on Station and Element in question."
        print, "          0 (or absent) => Native"
        print, "          otherwise     => User choice (assumes supported)."
        print, "          "
        print, "      UNIX_TIME: in, type='boolean'"
        print, "          0 (or absent) => default to Julian time"
        print, "          1             => seconds since 1970-01-01 00:00:00"
        print, "          "
        print, "      VERBOSITY: in, type='integer'"
        print, "          1: show {fatal}"
        print, "          2: show {fatal,error}"
        print, "          3: show {fatal,error,warn}"
        print, ""
        return, 0
    endif
    
    ; Exception handler
    catch, error_status  
    if (error_status ne 0) then begin 
        catch, /CANCEL 
                
        log_fatal, my_name+": Unhandled exception occurred with message: "+!ERROR_STATE.MSG

        ; Destroy the url object 
        obj_destroy, url 

        return, 0
    endif

    ;;;;;
    ; Setup
    ;;;;;

    j_start = julday( start_time[1], start_time[2], start_time[0], start_time[3], start_time[4], start_time[5] )
    j_end   = julday(   end_time[1],   end_time[2],   end_time[0],   end_time[3],   end_time[4],   end_time[5] )

    
    ; sampling
    if ( n_elements( SAMPLING ) eq 0 ) then sampling = 0  ; i.e. native for data type


    ; URL Object
    url = OBJ_NEW('IDLnetUrl')

    ;;;;;
    ; Chunks
    ;;;;;
    CHUNK_SIZE = 30       ; Days
    for j_current=j_start, j_end, CHUNK_SIZE do begin

        ; current chunk window
        t_start = jday_to_time_array( j_current )
        t_end   = jday_to_time_array( j_current + CHUNK_SIZE - 1 < j_end )    ; don't grab past our last needed day, it's wasteful
                
        ;;;;;
        ; Build URL
        ;;;;;
        start_year_s   = string( t_start[0], FORMAT='(I4)'  )
        start_month_s  = string( t_start[1], FORMAT='(I02)' )
        start_day_s    = string( t_start[2], FORMAT='(I02)' )
        start_hour_s   = string( t_start[3], FORMAT='(I02)' )
        start_minute_s = string( t_start[4], FORMAT='(I02)' )
        start_second_s = '00'
    
        end_year_s   = string( t_end[0], FORMAT='(I4)'  )
        end_month_s  = string( t_end[1], FORMAT='(I02)' )
        end_day_s    = string( t_end[2], FORMAT='(I02)' )
        end_hour_s   = string( t_end[3], FORMAT='(I02)' )
        end_minute_s = string( t_end[4], FORMAT='(I02)' )
        end_second_s = '00'
    
        url_scheme = 'http'
        url_host   = 'spidr.ngdc.noaa.gov'
        url_path   = '/spidr/servlet/GetData?format=csv&param='+param+'&sampling='+strtrim(sampling,2)+'&dateFrom='+start_year_s+start_month_s+start_day_s+'&dateTo='+end_year_s+end_month_s+end_day_s
        ; example: URL_PATH = '/spidr/servlet/GetData?format=csv&param=foF2.BC840&sampling=0&dateFrom=20090101&dateTo=20090201
        ;          OR         '/spidr/servlet/GetData?format=csv&param=index_kp&dateFrom=20090101&dateTo=20090201'
        log_debug, my_name+": HTTP/GET: "+url_scheme+'://'+url_host+url_path
        url->SetProperty, VERBOSE=(VERBOSITY eq 5), URL_SCHEME=url_scheme, URL_HOST=url_host, URL_PATH=url_path

        ;;;;;
        ; Get Raw ASCII data
        ;;;;;
        data_raw = url->Get( /STRING_ARRAY )
       
        ; convert Raw ASCII to IDL Structure
        spidr_chunk = spidr_ascii_to_structure( data_raw )
        if ( ~ is_structure( spidr_chunk ) ) then begin
            log_debug, my_name+": Call was invalid, no data returned."
            return, 0
        endif
        
        ; Concatenate the inefficient way
        ; TODO: efficient concatencation, but how?
        if ( j_current eq j_start ) then begin
            spidr_meta = { description:spidr_chunk.description, units:spidr_chunk.units, origin:spidr_chunk.origin, station_code:spidr_chunk.station_code, station_name:spidr_chunk.station_name, sampling:spidr_chunk.sampling, missing_value:spidr_chunk.missing_value, created_on:spidr_chunk.created_on, metalink:spidr_chunk.metalink }
            spidr_data = { time_8601:spidr_chunk.time_8601, time:spidr_chunk.time, value:spidr_chunk.value, qualifier:spidr_chunk.qualifier, descriptor: spidr_chunk.descriptor }
        endif $
        else begin
            spidr_data = { time_8601:[ spidr_data.time_8601, spidr_chunk.time_8601 ], time:[ spidr_data.time, spidr_chunk.time ], value:[ spidr_data.value, spidr_chunk.value ], qualifier:[ spidr_data.qualifier, spidr_chunk.qualifier ], descriptor:[ spidr_data.descriptor, spidr_chunk.descriptor ] }
        endelse
    endfor
    
    ; filter for requested time range (i.e. fractional days)
    idx = where( spidr_data.time ge j_start and spidr_data.time le j_end, n )
    if ( n eq 0 ) then return, 0  ; No data

    ; Meta Info + Data
    spidr = create_struct( {param:param}, spidr_meta, { time_8601:spidr_data.time_8601[idx], time:spidr_data.time[idx], $
                           value:spidr_data.value[idx], qualifier:spidr_data.qualifier[idx], descriptor:spidr_data.descriptor[idx] } )
    
    
    ; Unix Time?
    if ( keyword_set( UNIX_TIME ) ) then spidr.time = jday_to_unix_time( spidr.time )
        

    ; cleanup
    obj_destroy, url

    ; done
    log_info, my_name+': Retrieved '+strtrim(n_elements(spidr.time),2)+' data points.'
    return, spidr
end


;+
; Test primary functionality
; TODO: point these tests at a dummy database that is guranteed NOT to change
;-
function test_spidr_get_data

    print, "TESTING: spidr_get_data"
    
    ; Iono
    name = 'Iono'
    spidr = spidr_get_data( 'foF2.BC840', [2008, 11, 1, 0, 0, 0], [2008, 11, 30, 0, 0, 0], VERBOSITY=5 )
    if ( stddev( spidr.value, /nan ) gt 1.347 $
      or mean(   spidr.value, /nan ) gt 4.2  $
      or ( total( spidr.time ) - 6176242580.104D ) gt 0.0002 ) then begin
        print, '    '+name+' => FAILED or database changed'
        return, 0
    endif
    print, '    '+name+' => SUCCESS'

    ; GOES
    name = 'GOES 11'
    spidr = spidr_get_data( 'xs.goes11', [2008,1,1,0,0,0], [2008,12,31,23,59,59], /UNIX_TIME, verbosity=5 ) 
    if ( abs( stddev( spidr.value, /nan ) - 3.8982075e-09 ) gt 1e-17  $
      or abs( mean(   spidr.value, /nan ) - 5.2125760e-09 ) gt 1e-15  $
      or total( spidr.time ) ne 640330816060800 ) then begin
        print, '    '+name+' => FAILED or database changed'
        return, 0
    endif
    print, '    '+name+' => SUCCESS'

    return, 1

end


;+
; Test
;-

; Test essential functionality
print, "TEST => ", ( test_spidr_get_data() eq 1 ) ? "SUCCESS" : "FAIL"

end