;+
; :Description:
; Converts SPIDR ASCII to an IDL Structure.  "MISSING VALUES" are placed with NaN.
;
; :Author: Rob Redmon
; :Copyright: NGDC, 2010
; 
; :Params:
;     spidr_ascii in, required, type='string array'
;
; :Keywords:
;         
; :Returns: Array of structures.  
;     Structure has the format:
;     {param DESCRIPTION UNITS ORIGIN STATION_CODE STATION_NAME SAMPLING MISSING_VALUE CREATED_ON metalink TIME_8601 TIME VALUE QUALIFIER DESCRIPTOR}
;     0 if no data was found.
;-
function spidr_ascii_to_structure, spidr_ascii

    ; boiler plate
    my_name = 'spidr_ascii_to_structure'
    ngdc_boiler
    

    ;;;;;
    ; ASCII => IDL structure
    ;;;;;
    log_debug, my_name+": Converting "+strtrim( n_elements( spidr_ascii ), 2 )+' lines.'
   
   
    ; SPIDR ASCII file layout:
    ;    
    ;    2006-02-28 22:45 166.40   "U"   "R"
    ;    #>
    ;    #param: foF2.BC840
    ;    #Description: Peak height F2 layer
    ;    #Measure units: km
    ;    #Origin:
    ;    #Station code: BC840
    ;    #Station name: BOULDER
    ;    #Sampling: undef sampling
    ;    #Missing value: 9999.0
    ;    #Metalink: http://spidr.ngdc.noaa.gov/spidr/servlet/GetMetadata?param=iono.BC840
    ;    #>
    ;    #yyyy-MM-dd HH:mm value qualifier description
    ;    2006-02-01 00:00 224.30   "U"   "R"
    ;

    ; Metadata
    param         = spidr_ascii_get_meta( spidr_ascii, '#param:'   )
    created_on    = ( strsplit( spidr_ascii[0], /extract ) )[9]
    description   = spidr_ascii_get_meta( spidr_ascii, '#Description:'   )
    units_given   = spidr_ascii_get_meta( spidr_ascii, '#Measure units:' )
    origin        = spidr_ascii_get_meta( spidr_ascii, '#Origin:'        )
    station_code  = spidr_ascii_get_meta( spidr_ascii, '#Station code:'  )
    station_name  = spidr_ascii_get_meta( spidr_ascii, '#Station name:'  )
    sampling      = spidr_ascii_get_meta( spidr_ascii, '#Sampling:'      )
    missing_value = double( spidr_ascii_get_meta( spidr_ascii, '#Missing value:' ) )
    metalink   = spidr_ascii_get_meta( spidr_ascii, '#Metalink:'   )

    ; Data, Qualifiers, Descriptors
    i_start = 1 + ( where( strmatch( spidr_ascii, '#yyyy-MM-dd*' ) ) )[0]
    n_data = n_elements( spidr_ascii ) - i_start
    if ( n_data eq 0 ) then return, 0
    
    spidr = { $
        ; Information
        param:param, $
        description:description, units:units_given, origin:origin, station_code:station_code, station_name:station_name, sampling:sampling, missing_value:missing_value, created_on:created_on, $
        metalink:metalink, $
        $
        ; Content
        time_8601:  strarr(     n_data ), $
        time:      make_array( n_data, /double, value=!values.d_nan ), $
        value:     make_array( n_data, /double, value=!values.d_nan ), $
        qualifier: strarr(     n_data ), $
        descriptor:strarr(     n_data ) $
    }
    
    for i = long64( 0 ), n_data -1 do begin
        splits = strsplit( spidr_ascii[ i + i_start ], ',', /extract )
        spidr.time_8601[i]  = splits[0]
        spidr.value[i]      = double( splits[1] )
        spidr.qualifier[i]  = ( n_elements( splits ) gt 2 ) ? splits[2] : ''
        spidr.descriptor[i] = ( n_elements( splits ) gt 3 ) ? splits[3] : ''
    
        ; add julian datetime
        t_time_arr = time_8601_to_array( splits[0]+':00' )
        spidr.time[i] = julday( t_time_arr[1], t_time_arr[2], t_time_arr[0], t_time_arr[3], t_time_arr[4], t_time_arr[5] )        
    endfor
    
    ; Set 'Missing Values' to NaN.  Set meta tag 'Missing Value' to NaN
    idx_missing = where( spidr.value eq spidr.missing_value, n_missing )
    if ( n_missing gt 0 ) then begin
        spidr.value[ idx_missing ] = !values.d_nan
    endif
    spidr.missing_value = !values.d_nan

    ; Done
    return, spidr
end


;+
; Handy function to extract meta tags from SPIDR ASCII format
; 
; :Keywords:
;     exists: out, type='integer'
;     boolean 0 => false, 1 => true
;     
; :Params:
;     spidr_ascii: in, required, type='string array'
;     tag: in, required, type='string'
;         e.g. '#Element:'
;         
; :Returns:
;     string value of tag, or empty string '' if no tag exists.
;-
function spidr_ascii_get_meta, spidr_ascii, tag, exists=exists

    ; error handler
    catch, error_status
    if error_status ne 0 then begin
        catch, /CANCEL
        exists = 0
        return, ''
    endif

    splits = strsplit( spidr_ascii[ where( strmatch( spidr_ascii, tag+' *' ) eq 1 ) ], ': ', /extract, /regex )
    element = ( n_elements( splits ) ge 2 ) ? strjoin( splits[1:n_elements(splits)-1], ': ' ) : ''
    return, element
end


;+
; Tests essential functionality
; 
; :Returns: 0 => FAILURE, 1 => SUCCESS
;-
function test_spidr_ascii_to_structure
    spidr_ascii     = strarr( 20 )
    spidr_ascii[ 0] = '#Spidr data output file in CSV format created at 2009-11-25 21:21'
    spidr_ascii[ 1] = '#GMT time is used'
    spidr_ascii[ 2] = '#'
    spidr_ascii[ 3] = '#'
    spidr_ascii[ 4] = '#--------------------------------------------------'
    spidr_ascii[ 5] = '#>'
    spidr_ascii[ 6] = '#param: index_f107
    spidr_ascii[ 7] = '#Description: Adjusted daily solar radio flux'
    spidr_ascii[ 8] = '#Measure units: W/m^2/Hz'
    spidr_ascii[ 9] = '#Origin: '
    spidr_ascii[10] = '#'
    spidr_ascii[11] = '#'
    spidr_ascii[12] = '#Sampling: 1 day'
    spidr_ascii[13] = '#Missing value: 1.0E33'
    spidr_ascii[14] = '#Metalink: http://spidr.ngdc.noaa.gov/spidr/servlet/GetMetadata?param=index_f107'
    spidr_ascii[15] = '#>'
    spidr_ascii[16] = '#yyyy-MM-dd HH:mm value qualifier description'
    spidr_ascii[17] = '1997-01-01 00:00,70.0,,'
    spidr_ascii[18] = '1997-01-02 00:00,69.7,,'
    spidr_ascii[19] = '1997-01-03 00:00,1.0E33,,'
    
    ; convert
    spidr = spidr_ascii_to_structure( spidr_ascii )
    
    ; test
    if ( total( spidr.value, /NAN ) ne ( 70.D + 69.7D ) ) then return, 0
    if ( total( spidr.time ) ne total( julday( 1, [1,2,3], 1997, 0, 0, 0 ) ) ) then return, 0
    if ( finite( spidr.missing_value ) ) then return, 0
    
    return, 1
end


; Test essential functionality
print, "TEST => ", ( test_spidr_ascii_to_structure() eq 1 ) ? "SUCCESS" : "FAIL"

end