;+
; Reports the version of the SPIDR IDL Client
;-
function spidr_client_version
    ; do not mess up the format of this next line. don't add or remove white spaces. the build process uses this for versioning.
    version = '2.2.2'   ; <VERSION/>
    return, version
end


;+
; Eventually, this procedure will provide an entry point to the broad suite of functionality.
;-
pro spidr_client

    ; Check for update
    ans = dialog_message( 'Check for a newer version of SPIDR IDL Client?', /question )
    if ( ans eq 'Yes' ) then spidr_client_check_update
    
    ; Test essential functionality
    ans = dialog_message( 'Test Essential Functionality? Takes 1-2 minutes using decent Wifi.', /question )
    if ( ans eq 'Yes' ) then begin
        res = test_spidr_client()
        if ( ~ res ) then t = dialog_message( 'Some tests failed, please contact Rob.Redmon@noaa.gov.' ) $
        else t = dialog_message( 'All tests passed.', /information )
    endif
    
    ; Run cribs
    ans = dialog_message( 'Run Examples (examples/spidr_crib.pro)?', /question )
    if ( ans eq 'Yes' ) then spidr_crib
    
end


;+
; Attempts to determine if a new version exists
;-
pro spidr_client_check_update

    ; Get version from RSS
    rss_url = 'http://sourceforge.net/api/file/index/project-id/177675/mtime/desc/rss'

    oDoc = OBJ_NEW( 'IDLffXMLDOMDocument', FILENAME=rss_url ) 
    tmp = (((oDoc->GetElementsByTagName('title'))->Item(1))->GetFirstChild())->GetNodeValue()
    version_sourceforge = stregex( tmp, '[0-9]\.[0-9]\.[0-9]', /extract )
    obj_destroy, oDoc 
    
    print, "Checking Sourceforge: My version ["+spidr_client_version()+"], Sourceforge version ["+version_sourceforge+"]"    
    if ( version_sourceforge gt spidr_client_version() ) then begin
        t = dialog_message( "Consider upgrading SPIDR IDL Client from ["+spidr_client_version() $
                           +"] to ["+version_sourceforge+"] at http://sourceforge.net/projects/spidr-idl/", /information )
        mg_open_url, 'http://sourceforge.net/projects/spidr-idl/'    
    endif $
    else t = dialog_message( "You are running the newest version ["+spidr_client_version()+"].", /information )
    
end


;+
; Runs test_*.pro
;-
function test_spidr_client

    print, "Testing package..."
    result = 1
    result = result and test_spidr_ascii_to_structure()
    result = result and test_spidr_get_data()
    result = result and test_spidr_get_metadata()
    
    case result of
        1 : print, 'ALL TESTS => SUCCESS'
        0 : print, 'ALL TESTS => 1 or more FAILED'
    endcase
    
    return, result
end
