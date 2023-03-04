;----------------------------------------------------------------
; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/wavelet/source/wv_denoise.pro#1 $
;
; Copyright (c) 2000-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;+
; NAME:
;    WV_DENOISE
;
; PURPOSE:
;
;    This function uses the wavelet transform to filter (or de-noise)
;    a one or two-dimensional array.
;
; CALLING SEQUENCE:
;
;    Result = WV_DENOISE( Array [, Family, Order])
;
; INPUTS:
;
;   Array: A one- or two-dimensional array of data to be analyzed.
;
;      Note - If the dimensions of Array are not powers of two,
;           then the Array will be embedded within a larger zero-filled array
;           whose dimensions are powers of two. In this case the Result
;           will have the same dimensions as the larger array.
;
;   Family: A string specifying the name of the wavelet function
;            to use. WV_DENOISE will construct the actual function name
;            by removing all white space and attaching a prefix of 'WV_FN_'.
;           Note: This must be a discrete wavelet, such as COIFLET,
;               DAUBECHIES, HAAR, or SYMLET.
;
;   Order: A scalar specifying the order number for the wavelet.
;
;      Note - If you pass in DENOISE_STATE, then Family and Order
;          may be omitted. In this case the values from DENOISE_STATE
;          are used.
;
; KEYWORDS:
;
;   COEFFICIENTS: Set this keyword to a scalar specifying the number of
;           wavelet coefficients to retain in the filtered wavelet transform.
;           This keyword is ignored if keyword PERCENT is present.
;
;   CUTOFF: Set this keyword to a named variable that will contain the
;           actual cutoff value of wavelet power that was used for the
;           threshold.
;
;   DENOISE_STATE: This is both an input and an output keyword.
;           If this keyword is set to a named variable, then upon return,
;           DENOISE_STATE will contain the following structure:
;
;            Tag          Type        Definition
;            FAMILY        String     Name of wavelet function
;            ORDER         Double     Order number for the wavelet
;            DWT           FLT/DBLARR Discrete wavelet transform of Array
;            WPS           FLT/DBLARR Wavelet power spectrum = |DWT|^2
;            SORTED        FLT/DBLARR Percent-normalized WPS, sorted
;            CUMULATIVE    FLT/DBLARR Cumulative sum of SORTED
;            COEFFICIENTS  LONG       Number of coefficients retained
;            PERCENT       Double     Percent of coefficients retained
;
;            Upon input, if DENOISE_STATE is set to a structure with the
;            above form, then the DWT, WPS, SORTED, and CUMULATIVE variables
;            are not recomputed. This is useful if you want to make multiple
;            calls to WV_DENOISE using the same Array.
;
;        Note - No error checking is made on the input values. The values
;            should not be modified between calls to DENOISE_STATE.
;
;   DOUBLE: Set this keyword to force the computation to be done using
;           double-precision arithmetic.
;
;   DWT_FILTERED: Set this keyword to a named variable in which the
;           the filtered discrete wavelet transform will be returned.
;
;   PERCENT: Set this keyword to a scalar specifying the percentage of
;           cumulative wavelet power to retain.
;
;        Note - If neither COEFFICIENTS nor PERCENT is present then all
;             of the coefficients are retained (i.e. no filtering is done).
;
;   THRESHOLD: Set this keyword to a scalar specifying the type of threshold.
;            Possible values are:
;               0 = hard threshold (this is the default)
;               1 = soft threshold
;
;   WPS_FILTERED: Set this keyword to a named variable in which the
;           filtered wavelet power spectrum will be returned.
;
; OUTPUTS:
;
;    Result: A vector or array containing the filtered version of Array.
;
; REFERENCE:
;    IDL Wavelet Toolkit Online Manual
;
; MODIFICATION HISTORY:
;    Written by CT, August 2000.
;    CT, May 2001: Fixed default if COEFFICIENTS or PERCENT not supplied.
;    CT, Nov 2004: Add error message if incorrect wavelet supplied.
;
;-


; WV_DENOISE_DWT
;   Helper function.
;   Find discrete wavelet transform and construct denoise_state.
FUNCTION wv_denoise_dwt, data, mean_data, $
    family, order, $
    scaling, wavelet, ioff, joff

    COMPILE_OPT hidden, strictarr
    ON_ERROR, 2

; Convert dimensions to powers of two.
    siz = SIZE(data)
    dim = 2L^(LONG(ALOG(siz[1:2])/ALOG(2)+0.99999))
    CASE siz[0] OF
        1: data_in = DBLARR(dim[0])
        2: data_in = DBLARR(dim[0],dim[1])
        ELSE: MESSAGE, 'Array must have either 1 or 2 dimensions.'
    ENDCASE
    ; remove mean so it doesn't swamp the DWT
    data_in[0,0] = (mean_data NE 0.) ? $
        data - mean_data : data
    dwt = WV_DWT(data_in,scaling,wavelet,ioff,joff, $
        DOUBLE=double)

; Find power and sort
    n = N_ELEMENTS(dwt)
    wps = ABS(dwt)^2
    power = TOTAL(wps)
    rev_sort = REVERSE(SORT(wps))
    sorted = (power EQ 0) ? DBLARR(n) : $
        100.*wps[rev_sort]/power

; Cumulative power
    cumulative = TOTAL(sorted, /CUMULATIVE)
    cumulative[n-1] = 100.0  ; avoid roundoff error for last point

    denoise_state = {family: family, $
        order: order, $
        dwt: TEMPORARY(dwt), $
        wps: TEMPORARY(wps), $
        sorted: TEMPORARY(sorted), $
        cumulative: TEMPORARY(cumulative), $
        coefficients:0L, $
        percent:0d}
    RETURN, denoise_state
END


;------------------------------------------------------------------------
FUNCTION wv_denoise, data, familyIn, orderIn, $
    COEFFICIENTS=coeffIn, $
    CUTOFF=cutoff, $
    DENOISE_STATE=denoise_state, $
    DOUBLE=doubleIn, $
    DWT_FILTERED=dwt_filt, $
    PERCENT=percentIn, $
    THRESHOLD=threshold, $
    WPS_FILTERED=wps_filt

    COMPILE_OPT strictarr

    ON_ERROR, 2

    nParam = N_PARAMS()
    IF ((nParam NE 1) AND (nParam NE 3)) THEN $
        MESSAGE, 'Incorrect number of arguments.'


; Keyword DOUBLE
    double = (N_ELEMENTS(doubleIn) GT 0) ? $
        KEYWORD_SET(doubleIn) : $
        SIZE(data,/TNAME) EQ 'DOUBLE'


; Make local copies
    IF (nParam EQ 3) THEN BEGIN
        family = familyIn
        order = DOUBLE(orderIn)
    ENDIF


; Check if DENOISE_STATE was passed in
    redo_state = (N_TAGS(denoise_state) LT 1)
    IF redo_state AND (nParam NE 3) THEN $
        MESSAGE, 'Incorrect number of arguments.'


; Use previous Family and Order if not provided
    IF NOT redo_state AND (nParam EQ 1) THEN BEGIN
        family = denoise_state.family
        order = denoise_state.order
    ENDIF
; Note that no error checking is done if a new Family or Order
; are given. This could result in different wavelet function being
; used for reconstruction. Note that this might be useful...


; Get scaling & wavelet functions (discrete wavelets only)
    wave_function = STRUPCASE(STRCOMPRESS('wv_fn_'+family,/REMOVE_ALL))
    catch, err
    if (err ne 0) then begin
        CATCH, /CANCEL
        MESSAGE, 'Error calling ' + !ERROR_STATE.msg + $
            ' (Note: WV_DENOISE may only be used with discrete wavelets)'
        return, 0
    endif
    winfo = CALL_FUNCTION(wave_function,order+0, $
        scaling,wavelet,ioff,joff)

    mean_data = MEAN(data)


    IF redo_state THEN BEGIN
        denoise_state = WV_DENOISE_DWT(data, mean_data, $
            family, order, $
            scaling, wavelet, ioff, joff)
    ENDIF
    n = N_ELEMENTS(denoise_state.dwt)


; In case no filtering occurs, define the defaults
    IF ARG_PRESENT(dwt_filt) THEN $
        dwt_filt = denoise_state.dwt
    IF ARG_PRESENT(wps_filt) THEN $
        wps_filt = denoise_state.wps
    cutoff = double ? 0d : 0.0


; Keywords PERCENT and COEFFICIENTS
    coeff = n   ; default is to retain all coefficients
    if (N_ELEMENTS(percentIn) ge 1) then begin
        percent = 0 > percentIn[0] < 100
        coeff = 1 + (WHERE(denoise_state.cumulative GE percent))[0]
        IF (coeff EQ 0) THEN coeff = n
        IF ((percent LT denoise_state.percent) AND $
            (coeff EQ denoise_state.coefficients)) THEN $
            coeff = coeff - 1
    endif else if (N_ELEMENTS(coeffIn) ge 1) then begin
        coeff = coeffIn[0]
    endif


; Find the actual percent corresponding to that coefficients
    coeff = 1 > coeff < n   ; restrict to allowed range
    percent = denoise_state.cumulative[coeff-1]
    denoise_state.coefficients = coeff
    denoise_state.percent = percent


; Are we keeping all coefficients?
    IF (coeff EQ n) THEN BEGIN
        RETURN, data
    ENDIF


; Keyword THRESHOLD
    IF (N_ELEMENTS(threshold) LT 1) THEN $
        threshold = 0  ; default is 'hard'


; Find power if it hasn't been calculated above
    IF (N_ELEMENTS(power) LT 1) THEN $
        power = TOTAL(denoise_state.wps)


; Find actual cutoff in data 'units'
    offset = (threshold EQ 1) ? 1 : 0   ; keep 1 extra for 'soft'
    cutoff = (denoise_state.sorted)[coeff-1+offset]
    cutoff = cutoff*power/100.


; Apply the threshold to the WPS and DWT
    CASE (threshold) OF
    0: BEGIN ; hard threshold
        mask = denoise_state.wps GE cutoff   ; 0 or 1
        dwt_filt = mask*denoise_state.dwt
        IF ARG_PRESENT(wps_filt) THEN $
            wps_filt = mask*denoise_state.wps
        END
    1: BEGIN ; soft threshold
        ; remember the signs
        sgn = (denoise_state.dwt GT 0)*2 - 1
        dwt_filt = sgn*((ABS(denoise_state.dwt) - SQRT(cutoff)) > 0)
        IF ARG_PRESENT(wps_filt) THEN $
            wps_filt = (denoise_state.wps - cutoff) > 0
        END
    ENDCASE


; Inverse transform to find filtered data/image
    data_filt = WV_DWT(dwt_filt,scaling,wavelet,ioff,joff, $
        DOUBLE=double,/INVERSE)
    IF (mean_data NE 0.) THEN $  ; add mean back in
        data_filt = TEMPORARY(data_filt) + mean_data

    RETURN, data_filt

END

