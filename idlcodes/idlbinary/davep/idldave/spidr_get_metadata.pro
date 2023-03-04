;+
; ALPHA: subject to change, especially the output schema.
; Function to retrieve SPIDR Meta Data for a particular [station,element] via WebServices
; 
; :Author: Rob Redmon
; :Copyright: NGDC, 2010
; 
; :Requires: IDLNetURL (IDL 6.4 or newer)
; 
; :History:
;     2010-02 Initial version.
;
; :Usage:
; 
; :Params:
;         
; :Keywords:
;     AS_STRING: in, type='boolean'
;         0 or absent: do nothing
;         1: return XML array
;         
;     PRINT_SCREEN: in, type='boolean'
;         0 or absent: do nothing
;         1: print XML to screen
;
;     VERBOSITY: in, type='integer'
;         1: show {fatal}
;         2: show {fatal,error}
;         3: show {fatal,error,warn}
;         4: show {fatal,error,warn,info}
;         5: show all messages
;         unset: use existing debug level as default 
;         
; :Returns:
;
; :Examples:
;-
function spidr_get_metadata, param, AS_STRING=AS_STRING, DISPLAY_CONSOLE=DISPLAY_CONSOLE, DISPLAY_POPUP=DISPLAY_POPUP, VERBOSITY=VERBOSITY, HELP=HELP

    ; boiler plate
    my_name = 'spidr_get_metadata'
    ngdc_boiler, VERBOSITY=VERBOSITY
    VERBOSITY = !LOG.verbosity

        
    ; Help
    if ( keyword_set( HELP ) ) then begin
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


    ; Setup
    url = OBJ_NEW('IDLnetUrl')

    ; HTTP/Get
    url_scheme = 'http'
    url_host   = 'spidr.ngdc.noaa.gov'
    url_path   = '/spidr/servlet/GetMetadata?param='+param
    ; example: 'http://spidr.ngdc.noaa.gov/spidr/servlet/GetMetadata?param=iono.BC840'
    log_debug, my_name+": HTTP/GET: "+url_scheme+'://'+url_host+url_path
    url->SetProperty, VERBOSE=(VERBOSITY eq 5), URL_SCHEME=url_scheme, URL_HOST=url_host, URL_PATH=url_path

    fgdc_xml = url->Get( /STRING_ARRAY )
    obj_destroy, url

    ; Print to screen?
    if ( keyword_set( DISPLAY_CONSOLE ) ) then begin
        for i = 0, n_elements( fgdc_xml ) - 1 do begin
            print, fgdc_xml[i]
        endfor
    endif
    ; Popup?
    if ( keyword_set( DISPLAY_POPUP ) ) then begin
        xdisplayfile, text=fgdc_xml, title=url_scheme+'://'+url_host+url_path, width=100
    endif    
    
    
    ; Return XML?
    if ( keyword_set( AS_STRING ) ) then begin
        return, fgdc_xml
    endif

    ; Return Structure
    ; XML => Structure
    fgdc = fgdc_to_simple_struct( strjoin( fgdc_xml, '' ) )
    fgdc.metalink = url_scheme+'://'+url_host+url_path

    
    return, fgdc
end


;+
;   Parses an FGDC record for basic content and returns a nested structure.  
;   This function does NOT attempt to reproduce the rather awkward looking
;   FGDC schema, in favor of simple is better.
;-
function fgdc_to_simple_struct, fgdc_xml
    
    ; boiler plate
    my_name = 'spidr_get_metadata'
    ngdc_boiler, VERBOSITY=VERBOSITY
    VERBOSITY = !LOG.verbosity
    
    ; setup
    fgdc = { title:'', abstract:'', metalink:'', contact:{organization:'', name:'', voice:'', email:'', address:'', city:'', state:'', postal:'', country:''}, $
             start_date:'', end_date:'', location:{north:!values.d_nan, south:!values.d_nan, east:!values.d_nan, west:!values.d_nan} }

    ; Exception handler
    catch, error_status  
    if (error_status ne 0) then begin 
        catch, /CANCEL 
                
        log_error, my_name+": Unhandled exception occurred with message: "+!ERROR_STATE.MSG+", Returning a partial FGDC structure."

        ; Destroy the url object 
        if ( n_elements( oDoc ) ) then obj_destroy, oDoc

        return, fgdc
    endif


    oDoc = OBJ_NEW('IDLffXMLDOMDocument')
    oDoc->Load, STRING=fgdc_xml
    
    ; Citation
    o_citeinfo = (oDoc->GetElementsByTagName('citeinfo'))->Item(0)
    fgdc.title = (((o_citeinfo->GetElementsByTagName('title'))->Item(0))->GetFirstChild())->GetNodeValue()
    
    ; Abstract
    fgdc.abstract = (((oDoc->GetElementsByTagName('abstract'))->Item(0))->GetFirstChild())->GetNodeValue()
    
    ; Time
    fgdc.start_date = (((oDoc->GetElementsByTagName('begdate'))->Item(0))->GetFirstChild())->GetNodeValue()
    fgdc.end_date   = (((oDoc->GetElementsByTagName('enddate'))->Item(0))->GetFirstChild())->GetNodeValue()

    ; Lat / Lon
    fgdc.location.north = (((oDoc->GetElementsByTagName('northbc'))->Item(0))->GetFirstChild())->GetNodeValue()
    fgdc.location.south = (((oDoc->GetElementsByTagName('southbc'))->Item(0))->GetFirstChild())->GetNodeValue()
    fgdc.location.east  = (((oDoc->GetElementsByTagName('eastbc'))->Item(0))->GetFirstChild())->GetNodeValue()
    fgdc.location.west  = (((oDoc->GetElementsByTagName('westbc'))->Item(0))->GetFirstChild())->GetNodeValue()
    
    ; Point of Contact
    o_ptcontac = (oDoc->GetElementsByTagName('ptcontac'))->Item(0)
    fgdc.contact.name  = (((o_ptcontac->GetElementsByTagName('cntper'))->Item(0))->GetFirstChild())->GetNodeValue()
    fgdc.contact.email = (((o_ptcontac->GetElementsByTagName('cntemail'))->Item(0))->GetFirstChild())->GetNodeValue()
    fgdc.contact.organization = (((o_ptcontac->GetElementsByTagName('cntorg'))->Item(0))->GetFirstChild())->GetNodeValue()
    fgdc.contact.address = (((o_ptcontac->GetElementsByTagName('address'))->Item(0))->GetFirstChild())->GetNodeValue()
    fgdc.contact.city    = (((o_ptcontac->GetElementsByTagName('city'))->Item(0))->GetFirstChild())->GetNodeValue()
    fgdc.contact.state   = (((o_ptcontac->GetElementsByTagName('state'))->Item(0))->GetFirstChild())->GetNodeValue()
    fgdc.contact.postal  = (((o_ptcontac->GetElementsByTagName('postal'))->Item(0))->GetFirstChild())->GetNodeValue()
    fgdc.contact.country = (((o_ptcontac->GetElementsByTagName('country'))->Item(0))->GetFirstChild())->GetNodeValue()
    fgdc.contact.voice   = (((o_ptcontac->GetElementsByTagName('cntvoice'))->Item(0))->GetFirstChild())->GetNodeValue()

   
    ; cleanup
    OBJ_DESTROY, oDoc
   
    return, fgdc
   
end


;+
; Test primary functionality
;-
function test_spidr_get_metadata

    print, "TESTING: spidr_get_metadata"

    fgdc = spidr_get_metadata( 'iono.BC840' )

    if ( fgdc.contact.name ne "Rob Redmon" ) then begin
        print, '     => FAILED or xml changed'
        return, 0
    endif

    print, '     => SUCCESS'
    
    return, 1

end




;+
; Test
;-

; Test essential functionality
print, "TEST => ", ( test_spidr_get_metadata() eq 1 ) ? "SUCCESS" : "FAIL"


end