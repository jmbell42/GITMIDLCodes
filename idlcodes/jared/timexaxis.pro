;+
; NAME:
;	TimeXAxis
; PURPOSE:
;	Plot horizontal time axis
; CATEGORY:
;	Plotting
; CALLING SEQUENCE:
	PRO TimeXAxis, TR, unit, $
		t0		= T0		, $
		same_T0 = same_T0	, $
		exact	= exact 	, $
		noxtitle= noxtitle	, $
		yrxtitle= yrxtitle	, $
		tick_get= tick_get	, $
		axis_only=axis_only , $
		xaxis	= xaxis		, $
		starttime=starttime , $
		nmajor	= nmajor	, $
		from	= from		, $
		upto	= upto		, $
		trim    = trim		, $
		xminor	= xminor	, $
		xtickn	= xtickn	, $
		xtickv	= xtickv	, $
		xstyle	= xstyle	, $
		ydoy	= ydoy		, $
		_ydoy	= _ydoy 	, $
		_extra	= _extra	;, title=title
; INPUT PARAMETERS:
;	TR		array; type: float or time structure
;				(must have at least two elements)
;				Defines range of times to be plotted
;
;				If TR is a float array then TR is a time relative to the
;				time origin T0 in units of 'unit'.
;
;				If T0 is not specified then TR MUST be an array
;					of time structures (T0 will be set internally using TR)
;
;				Only min(TR) and max(TR) are used.
;	Unit	scalar; type: integer; default: TimeUnit(/days)
;				Determines the units of TR (if TR is a float array)
;				Use function TimeUnit to specify unit
;
;	Graphics keywords to the PLOT command are used using the _extra mechanism.
; OPTIONAL INPUT PARAMETERS:
;	t0=T0	scalar; type: time structure
;				Time origin. MUST be set if TR is specified as a float array
;	/same_T0
;			if set then the time origin from a previous call to TimeXAxis
;			is used. If there is no origin available then the keyword is
;			ignored. If there is an origin available then this keyword
;			overrides the t0 keyword.
;	/exact	forces time axis to cover exactly min(TR) to max(TR)
;	/noxtitle
;			suppress title for time axis
;	title=title 		NOT TRUE
;			title for time axis. If omitted and /noxtitle is not set then
;			the title is time at the start of the time axis is used as title.
;	from, upto
;			if set these keywords determine which time units are used in
;			the axis labels.
;	/axis_only
;			by default, the IDL plot procedure with the /nodata keyword
;			is used to plot the axis. If /axis_only is used then the
;			IDL axis procedure is used.
;	nmajor=nmajor
;			# of major tickmarks on time axis.
;	xstyle=xstyle
;			IDL xstyle keyword, but MUST be an even number
;			(internally 1 is added; keyword /exact controls whether
;			the time axis is exact or not)
;	/ydoy	plot DOY along x-axis instead of Month/Day of Month
;
;	Usually the labels are calculated internally from the specified time array.
;	Override this by explicitly setting the xtickv keyword (and, optional,
;	the xtickn keyword:
;
;	xtickv=xtickv
;	xtickn=xtickv
;
; OPTIONAL OUTPUT PARAMETERS:
;	starttime=starttime
;			scalar; type: string
;				time at beginning of time axis.
;	tick_get=tick_get
;			array; type: float
;				tickmark labels used (i.e. value of keyword xtickv
;				on IDL plot or axis procedures)
; INCLUDE:
	@compile_opt.pro				; On error, return to caller
; COMMON BLOCKS:
	common TimeScale, torigin, trange, tunit, texact
; CALLS:
;	InitVar, IsType, TimeUnit, TimeRound, TimeSet, TimeGet
;	TimeOp, TimeLimits, gridgen
; PROCEDURE:
;	The common block stores the time origin (as a time structure) and the
;	time units used to generate the time axis. These are used by PlotCurve
;	to plot data points if the first argument to PlotCurve is a time
;	structure.
; MODIFICATION HISTORY:
;	MAY-1991, Paul Hick (ARC)
;		Cribbed from the UTPLOT package
;	SEP-1998, Paul Hick (UCSD/CASS)
;		Introduced time structures
;	JAN-2001, Paul Hick (UCSD/CASS)
;		Renamed from TimeAxis to TimeXAxis to avoid conflict in SSW
;	MAY-2007, Paul Hick (UCSD/CASS; pphick@ucsd.edu)
;		Added /ydoy keyword
;-

IF n_elements(TR) LT 2 THEN BEGIN
	CASE IsType(torigin, /defined) OF
	0: message, 'less than two data points in time range'
	1: same_T0 = 1
	ENDCASE
ENDIF

InitVar,  trim, /key
InitVar,  ydoy, /key
InitVar, _ydoy, /key
ymd = (1-ydoy) AND (1-_ydoy)

InitVar, same_T0, /key
same_T0 AND= IsType(torigin, /defined)

CASE same_T0 OF
0: BEGIN

	InitVar, exact, /key

	IF IsType(unit,/undefined) AND IsTime(TR) THEN BEGIN
		XR = TimeLimits(TR, /range)
		DX = TimeOp(/subtract,XR[1],XR[0])
		XR = abs([TimeGet(DX, /diff,/full, TimeUnit(/year  )), 	$
				  TimeGet(DX, /diff,/full, TimeUnit(/day   )),	$
				  TimeGet(DX, /diff,/full, TimeUnit(/hour  )),	$
				  TimeGet(DX, /diff,/full, TimeUnit(/minute)),	$
				  TimeGet(DX, /diff,/full, TimeUnit(/sec   )),	$
				  TimeGet(DX, /diff,/full, TimeUnit(/msec  ))])/100
		XR = (where(long(XR) GT 0))[0]
		IF XR NE -1 THEN unit = XR
	ENDIF

	InitVar, unit, TimeUnit(/days)

	; Determine time origin
	; If T0 is not set, TR must be time structure or TimeGet will fail

	CASE IsType(T0,/defined) OF
	0: TT0 = TimeGet(TR[0], /botime, unit)
	1: IF IsTime(T0) THEN TT0 = T0 ELSE TT0 = TimeSet(T0)
	ENDCASE

	; Save time origin and time units for common block
	; The common block is accessed by PlotCurve

	tunit   = unit
	texact  = exact
	torigin = TT0
	trange  = TR
END
1: BEGIN
	unit  = tunit
	exact = texact
	TT0   = torigin
	InitVar, TR, trange
END
ENDCASE

InitVar, noxtitle , /key
InitVar, axis_only, /key
InitVar, xaxis, 1

FAC = ([1.0d0/365.25d0,1.0d0, 24.0d0, 1440.0d0, 86400.0d0, 86400000.0d0])[unit]
								; Converts time units to days

; If TR is a time structure, convert to units 'Unit' relative to TT0
; If TR is a difference time structure, convert to units of 'Unit'
; Otherwise use TR as is.

CASE 1 OF
IsTime(TR      ): XR = TimeOp(/subtract, TR, TT0, unit)
;IsTime(TR,/diff): XR = TimeGet(/diff, TR, unit)
ELSE			: XR = TR
ENDCASE

; IXR1 and IXR2 are used to flip the time axis if IXR1 gt IXR2

XR = [min(XR,IXR1),max(XR,IXR2)]
IF NOT exact then XR = TimeRound(XR,unit)

TTR = TimeSet(XR, unit)						; Difference time structure
TTR = TimeOp(/add,TT0,TTR)					; Exact begin and end time of axis
DR  = XR[1]-XR[0]							; Range in time units

CASE 1 OF

IsType(xtickv,/undefined): BEGIN			; Calculate tick values

	; List of tickmark intervals: range .001 seconds - 60 days (2 to 6 tick intervals are required)

	IF DR LE 62*FAC THEN BEGIN				; Select from units lt 2 month

		A = [10^findgen(5)*0.001,10^findgen(5)*0.002,10^findgen(5)*0.005,20.0,40.0]
		A = A[sort(A)]						; Seconds
		B = [1,2,4,5,6,10,15,20,30,60]		; Minutes
		C = [1+indgen(6),8,10,12]			; Hours
		D = [1+indgen(6),10,20,30,60]		; Days
											; Allowed intervals between major tick marks in units of input time
		ticku = [A*(FAC/86400.0d0),B*(FAC/1440.0d0),C*(FAC/24.0d0),D*FAC]
		K1 = 0 +n_elements(A)
		K2 = K1+n_elements(B)
		K3 = K2+n_elements(C)

		W = DR/ticku						; # tick marks fitting in DR for all ticku (largest nr first)
		w_ok = (where(2 LE W AND W LT 7))[0]; Smallest spacings; largest # tick marks

		IF w_ok EQ -1 then message, 'Error finding major tick spacing for '+	$
			strcompress(DR,/rem)+'/'+strcompress(FAC,/rem)+' days'

		ticku	= ticku[w_ok]				; Time between major tick marks
		xtickv_	= long(DR/ticku)			; # tick intervals

		TTRe = [TimeGet(TTR[0],/eotime,TimeUnit(/year   ))	, $
				TimeGet(TTR[0],/eotime,TimeUnit(/day    ))	, $
				TimeGet(TTR[0],/eotime,TimeUnit(/hour   ))	, $
				TimeGet(TTR[0],/eotime,TimeUnit(/minute ))	, $
				TimeGet(TTR[0],/eotime,TimeUnit(/second ))	, $
				TimeGet(TTR[0],/eotime,TimeUnit(/msecond))  ]
		TTRb = [TimeGet(TTR[1],/botime,TimeUnit(/year   ))	, $
				TimeGet(TTR[1],/botime,TimeUnit(/day    ))	, $
				TimeGet(TTR[1],/botime,TimeUnit(/hour   ))	, $
				TimeGet(TTR[1],/botime,TimeUnit(/minute ))	, $
				TimeGet(TTR[1],/botime,TimeUnit(/second ))	, $
				TimeGet(TTR[1],/botime,TimeUnit(/msecond))]
		XRs = TimeOp(/subtract,TTRb,TTRe,unit)
		XRs = TimeOp(/subtract,TTRe[(where(XRs GT 0))[0]],TT0,unit)

		xtickv_ = XRs[0]+(-xtickv_+findgen(1+2*xtickv_))*ticku

		;dT0 = TimeGet(TT0,/botime,unit)	; Truncate to beginning of Unit
		;dT0 = TimeOp(/subtract,TT0,dT0,unit)
		;xtickv_ = -dT0+(ceil((dT0+XR[0])/ticku)+(-1+findgen(1+1+xtickv_)))*ticku
											; Times at major ticks

		IF w_ok LT K1 THEN FAC1 = 86400.0d0 ELSE $
		IF w_ok LT K2 THEN FAC1 =  1440.0d0 ELSE $
		IF w_ok LT K3 THEN FAC1 =    24.0d0 ELSE FAC1 = 1.0d0

		ticku1 = ticku*(FAC1/FAC)

		A = [1,2]#[0.0001,0.001,0.01,0.1,1.0,10.0]
		A = reform(A,n_elements(A))			; Seconds
		B = [1,2,5,10]						; Minutes
		C = [1,2,4,6,12]					; Hours
		D = [1,2,5,10]						; Days
		minoru = [A*(FAC1/86400.0d0),B*(FAC1/1440.0d0),C*(FAC1/24.0d0),D*FAC1] ; Possible time intervals between minor ticks
		A = where(ticku1 mod minoru EQ 0)	; which minors divide evenly into major tick intervals
		IF A[0] EQ -1 then message, 'Error finding minor tick spacing for '+	$
			strcompress(ticku1,/rem)+'/'+strcompress(FAC1,/rem)+' days'

		minoru = minoru[A]
		minoru = round(ticku1/minoru)		; Possible #minor intervals
		A = min(abs(minoru-4),I)			; Get as close as possible to 4 sub-intervals
		InitVar, xminor, minoru[I]			; # minor tick intervals

	ENDIF ELSE IF DR LT 1096*FAC THEN BEGIN	; If 2-36 months

		Y = TimeGet(TTR,/year )
		M = TimeGet(TTR,/month)
		 									; # months in range (with safety margin?)
		M = M[0]+indgen((Y[1]-Y[0])*12+M[1]-M[0]+2)	; Monotonous increasing index array for all months
		Y = Y[0]+(M-1)/12					; Years for all months
		M  = 1+((M-1) mod 12)				; All months (drops back to 1 after 12)
											; Time units elapsed since T0

		xtickv_ = TimeOp(/subtract, TimeSet(yr=Y, mon=M, day=1+0*M), TT0)
		xtickv_ = TimeGet(xtickv_,/diff,/full,TimeUnit(/day))*FAC

		ticku = 30*FAC						; Ca. one month between tick marks
		InitVar, xminor, 0

	ENDIF ELSE BEGIN

		IF DR LT  40L*366*FAC THEN	A =   1 ELSE $; Range is 3-40 years
		IF DR LT 400L*366*FAC THEN	A =  10 ELSE $; Range is 40-400 years
									A = 100		  ; More than 400 years

		Y = TimeGet(TTR,TimeUnit(/year))
		Y = (Y[0]/A+indgen((Y[1]-Y[0])/A+2))*A
											; Time units elapsed since T0
		xtickv_ = TimeOp(/subtract, TimeSet(yr=Y, doy=1+0*Y), TT0)
		xtickv_ = TimeGet(xtickv_,/diff,/full,TimeUnit(/day))*FAC

		ticku	= DR
		InitVar, xminor, 0

	ENDELSE

	; Array xtickv_ has all yy/mm/01 within allowed range
	; Make sure ticks are within range by both methods of time selection

	w_ok = where(XR[0] LE xtickv_ AND xtickv_ LE XR[1],A)
	xtickv_ = xtickv_[w_ok]
											; How many possible ticks (A le 6 for first method)
	;DTICKS = fix(A/6.1)+1					; # months/years between ticks
	DTICKS = fix(A/7.1)+1					; # months/years between ticks
	IF xminor EQ 0 THEN xminor = DTICKS		; Set minor tick marks close to months or years

	w_ok = where(xtickv_ EQ 0)
	CASE w_ok[0] EQ -1 OF					; Use only every DTICK month/yr
	0: w_ok = w_ok[0]+gridgen(2*A+1,range=DTICKS*A*[-1,1])
	1: w_ok = DTICKS*indgen(A)
	ENDCASE

	w_ok = w_ok[ where( 0 LE w_ok AND w_ok LT A ) ]
	xtickv_ = xtickv_[w_ok]

	IF IsType(nmajor,/defined) THEN BEGIN
		WHILE n_elements(xtickv_) GT nmajor DO BEGIN
			A = (n_elements(xtickv_)+1)/2
			IF A LE 1 THEN break
			xtickv_ = xtickv_[2*indgen(A)]
		ENDWHILE
	ENDIF

	xtickn_ = TimeOp(/add, TT0, TimeSet(/diff, xtickv_, unit))

END

IsTime(xtickv): BEGIN						; Tick values input as time structures

	IF IsType(xtickn,/defined) THEN xtickn_ = xtickn ELSE xtickn_ = xtickv
	xtickv_ = TimeOp(/subtract, xtickv, TT0, unit)

END

ELSE: BEGIN 								; Tick values input in units of 'unit' relative to TT0

	IF IsType(xtickn,/defined) THEN xtickn_ = xtickn ELSE xtickn_ = TimeOp(/add, xtickv, TT0, unit)
	xtickv_ = xtickv

END

ENDCASE

; At this point xtickv_ is set up in units of 'unit' since TT0 and
; xtickn_ is either a time structure or whatever was specified as input (should be strings)

CASE IsTime(xtickn_) OF

0: BEGIN
	upto = TimeUnit(/year)
	xtickn_ = strtrim(xtickn_,2)
END

1: BEGIN

	; UUUUUUUUUUUUUUUUGLY
	CASE unit OF
	TimeUnit(/years  ): roundt = 15*60
	TimeUnit(/days   ): roundt = 2
	TimeUnit(/hours  ): roundt = 0.100
	TimeUnit(/minutes): roundt = 0.001
	ELSE:
	ENDCASE

	IF IsType(roundt,/defined) THEN xtickn_ = TimeGet(xtickn_, TimeUnit(/sec), roundt=roundt)

	CASE IsType(from, /defined) OF
	0: BEGIN
		from = TimeUnit(/year)								; Start at largest unit (years)
		WHILE from LT TimeUnit(/sec) DO BEGIN 
			from_vals = TimeGet(xtickn_, from)
			IF n_elements(uniq(from_vals)) EQ 1 THEN BEGIN	; All labels have same value for this unit
				from++										; .. so drop the unit
				continue
			ENDIF
			IF trim THEN BEGIN
				n = n_elements(xtickn_)
				from = replicate(from,n)					; Compare with previous label
				n = where((from_vals EQ shift(from_vals,1))[1:*])
				IF n[0] NE -1 THEN from[n+1]++				; If same value for this unit, drop unit
			ENDIF
			break
		ENDWHILE
	END
	1: from >= TimeUnit(/year)
	ENDCASE

	CASE IsType(upto, /defined) OF
	0: BEGIN
		upto = TimeUnit(/msec)
		WHILE upto GT from DO 			$
			IF (where(TimeGet(xtickn_, upto) NE 0))[0] EQ -1 THEN upto -= 1 ELSE break
	END
	1: upto = upto < TimeUnit(/msec) > max(from)
	ENDCASE

	n = n_elements(xtickn_)
	yrs = TimeGet(xtickn_, TimeUnit(/year))
	yrs = yrs[uniq(yrs)]
	IF IsType(yrxtitle,/defined) THEN from >= TimeUnit(/year)+1

	CASE n_elements(from) OF
	1: xtickn_ = TimeGet(xtickn_,ymd=ymd,ydoy=ydoy,_ydoy=_ydoy,from=from,upto=upto)
	n: BEGIN												; Happens if /trim is set
		xtickn__ = strarr(n)
		FOR i=0,n-1 DO xtickn__[i] = TimeGet(xtickn_[i],ymd=ymd,ydoy=ydoy,_ydoy=_ydoy,from=from[i],upto=upto)
		xtickn_ = xtickn__
	END
	ENDCASE

	IF ymd AND upto EQ TimeUnit(/day) AND from EQ 0 THEN BEGIN
		day = strmid(xtickn_[0], strlen(xtickn_[0])-3,3)
		same_day = 1
		FOR i=0,n-1 DO same_day AND= strmid(xtickn_[i], strlen(xtickn_[i])-3,3) EQ day
		IF same_day THEN BEGIN
			FOR i=0,n-1 DO xtickn_[i] = strmid(xtickn_[i],0,strlen(xtickn_[i])-3)
			month = strmid(xtickn_[0], strlen(xtickn_[0])-3,3)
			same_month = 1
			FOR i=0,n-1 DO same_month AND= strmid(xtickn_[i], strlen(xtickn_[i])-3,3) EQ month
			IF same_month THEN FOR i=0,n-1 DO xtickn_[i] = strmid(xtickn_[i],0,strlen(xtickn_[i])-3)
		ENDIF
		FOR i=0,n-1 DO IF xtickn_[i] EQ '' THEN xtickn_[i] = ' '
	ENDIF

	FOR i=n-1,1,-1 DO IF xtickn_[i] EQ xtickn_[i-1] THEN xtickn_[i] = ' ' ELSE xtickn_[i] = strtrim(xtickn_[i],2)

END

ENDCASE

up = TimeUnit(/msec)
WHILE up GT upto DO 	$
	IF (TimeGet(TTR[0], up))[0] EQ 0 THEN up -= 1 ELSE break

starttime = TimeGet(TTR[0],ymd=ymd,ydoy=ydoy,_ydoy=_ydoy,upto=up)
IF NOT noxtitle AND IsType(yrxtitle,/undefined) THEN xtitle = 'start time '+starttime ELSE destroyvar, xtitle

IF IXR1 GT IXR2 THEN XR = reverse(XR)

xstyle_ = 1
IF IsType(xstyle,/defined) THEN xstyle_ += xstyle/2*2

CASE axis_only OF
0: plot, XR,0*XR	,	$
	/nodata 		,	$
	xstyle = xstyle_,	$			; Exact X-axis
	ystyle = 4		,	$			; Suppress Y-axis
	xtitle = xtitle ,	$
	_extra = _extra ,	$
	;title  = title	,	$
	xminor = xminor ,	$
	xtickn = xtickn_,	$
	xtickv = xtickv_,	$
	xticks = n_elements(xtickv_)-1

1: axis, xaxis = xaxis	,	$
	xrange = XR 	,	$
	xstyle = xstyle_,	$			; Exact X-axis
	xtitle = xtitle ,	$
	_extra = _extra ,	$
	xminor = xminor ,	$
	xtickn = xtickn_,	$
	xtickv = xtickv_,	$
	xticks = n_elements(xtickv_)-1

ENDCASE

IF IsType(yrxtitle,/defined) THEN BEGIN
	yrs = [ yrs[0]-1, yrs, yrs[n_elements(yrs)-1]+1 ]
	FOR i=0,n_elements(yrs)-1 DO BEGIN
		x = TimeScale( TimeSet(yr=yrs[i], doy=365.25/2) )
		y = !y.crange[0]-yrxtitle*(!y.crange[1]-!y.crange[0])
		IF !x.crange[0] LT x AND x LT !x.crange[1] THEN xyouts, x, y, strcompress(yrs[i],/rem), align=0.5, _extra=_extra
	ENDFOR
ENDIF

tick_get = xtickv_

RETURN  &  END
