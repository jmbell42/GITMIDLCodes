; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/components/idlitvistext__define.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;    Unauthorized reproduction prohibited.
;
;+
; CLASS_NAME:
;    IDLitVisText
;
; PURPOSE:
;    The IDLitVisText class is the iTools implementation of a text
;    object.
;
; CATEGORY:
;    Components
;
; SUPERCLASSES:
;    IDLitVisualization
;
;-


;----------------------------------------------------------------------------
;+
; METHODNAME:
;    IDLitVisText::Init
;
; PURPOSE:
;    Initialize this component
;
; CALLING SEQUENCE:
;
;    Obj = OBJ_NEW('IDLitVisText')
;
; INPUTS:
;
; KEYWORD PARAMETERS:
;   All keywords that can be used for IDLgrFont
;
; OUTPUTS:
;    This function method returns 1 on success, or 0 on failure.
;
;-
function IDLitVisText::Init,$
                     _REF_EXTRA=_extra

    compile_opt idl2, hidden

    ; Initialize superclass
    if (~self->IDLitVisualization::Init(NAME="Text", $
        /MANIPULATOR_TARGET, $
        TYPE='IDLTEXT', $
        DESCRIPTION="A Text Visualization", $
        ICON='text', $
        IMPACTS_RANGE=0, $
        SELECTION_PAD=10, $ ; pixels
        _EXTRA=_extra))then $
      return, 0

    self._oText = OBJ_NEW("IDLgrText", /REGISTER_PROPERTIES,$
        /ENABLE_FORMATTING, /KERNING, $
        RECOMPUTE_DIMENSIONS=2, $
        VERTICAL_ALIGNMENT=1, /PRIVATE, $
        STRING='', $
        _EXTRA=_extra)


    ; Add in our special manipulator visual.  This allows translation
    ; but doesn't allow scaling.  We don't want to allow scaling because
    ; it causes problems with the font sizing.
    oSelectBox = OBJ_NEW('IDLitManipVisSelect', /HIDE)
    oSelectBox->Add, OBJ_NEW('IDLgrPolyline', COLOR=[0,150,0], $
        DATA=[[-1,-1],[1,-1],[1,1],[-1,1],[-1,-1]])
    self->SetDefaultSelectionVisual, oSelectBox


    self->Add, self._oText, /AGGREGATE, /NO_NOTIFY, /NO_UPDATE

    self._oShadow = obj_new("IDLgrText", /HIDE, /PRIVATE, $
        /ENABLE_FORMATTING, $
        /KERNING, $
        RECOMPUTE_DIMENSIONS=2, $
        VERTICAL_ALIGNMENT=1, $
        _EXTRA=_EXTRA)


    ; Registered our properties.
    self._oText->RegisterProperty, 'TRANSPARENCY', /INTEGER, $
        NAME='Transparency', $
        DESCRIPTION='Text transparency', $
        VALID_RANGE=[0,100,5]


    ; Hide some text properties.
    self->SetPropertyAttribute, ['ALIGNMENT', $
        'ALPHA_CHANNEL', $
        'ENABLE_FORMATTING', $
        'KERNING', $
        'ONGLASS', $
        'RECOMPUTE_DIMENSIONS', $
        'RENDER_METHOD', $
        'PALETTE',$
        'VERTICAL_ALIGNMENT'], /HIDE

    ; Register text properties.
    ; Hide until we have a real string (needed for Styles).
    self->RegisterProperty, '_STRING', /STRING, $
        NAME='Text string', $
        DESCRIPTION='Text string', $
        /HIDE

    self->RegisterProperty, '_HORIZONTAL_ALIGN', $
        ENUMLIST=['Left', 'Center', 'Right'], $
        NAME='Horizontal alignment', $
        DESCRIPTION='Horizontal alignment'

    ; Use the current zoom factor of the tool window as the
    ; initial font zoom factor.  Likewise for the view zoom, and normalization
    ; factor.
    oTool = self->GetTool()
    if (OBJ_VALID(oTool) && OBJ_ISA(oTool, 'IDLitTool')) then begin
        oWin = oTool->GetCurrentWindow()
        if (OBJ_VALID(oWin)) then begin
            oWin->GetProperty, CURRENT_ZOOM=fontZoom
            oView = oWin->GetCurrentView()
            if (OBJ_VALID(oView)) then begin
                oView->GetProperty, CURRENT_ZOOM=viewZoom
                normViewDims = oView->GetViewport(UNITS=3,/VIRTUAL)
                fontNorm = MIN(normViewDims)
            endif
        endif
    endif

    self._oFont = OBJ_NEW('IDLitFont', FONT_ZOOM=fontZoom, VIEW_ZOOM=viewZoom, $
        FONT_NORM=fontNorm)
    self._oText->SetProperty, FONT=self._oFont->GetFont()
    self._oShadow->SetProperty, FONT=self._oFont->GetFont()
    self->Aggregate, self._oFont

    ; Set any properties
    if(n_elements(_extra) gt 0)then $
      self->IDLitVisText::SetProperty, _EXTRA=_extra

    ;; Register our parameter. This is the location of the text
    ;; object!
    self->RegisterParameter, 'LOCATION', DESCRIPTION='Text Location', $
                            /INPUT, TYPES=['IDLPOINT','IDLVECTOR']

    self._oEntry = obj_new("IDLgrPolyline", [0,0], [1,1], $
        color=[160,160,160], /hide,thick=2, /PRIVATE)

    RETURN, 1 ; Success
end
;;---------------------------------------------------------------------------
;; IDLitVisText::BeginEditing
;;
;; Purpose:
;;    Called to put this string in text edit mode. This must be
;;    followed by a called to EndEditing
;;
;; Parameters:
;;    oWin   - The Window the editing is being performed on.
;;
pro IDLitVisText::BeginEditing, oWin

   compile_opt idl2, hidden

   self->Add, self._oEntry, /NO_NOTIFY, /NO_UPDATE
   self->Add, self._oShadow, /NO_NOTIFY, /NO_UPDATE

   ;; Align the shadow with the actual text
   self._oText->GetProperty, location=loc, alignment=align
   self._oShadow->SetProperty, location=loc, alignment=align

   ;; figure out the vertical size of the shadow cursor
   self._oShadow->SetProperty, strings='|'
   dims = oWin->GetTextDimensions(self._oShadow, descent=descent)
   loc[1] -= descent[0]
   self._y = dims[1]

   ;; get size of current text and position graphical cursor at end of the text
   dims=oWin->GetTextDimensions(self._oText)
   x=loc[0] + dims[0] * (1-align)
   self._oEntry->SetProperty, hide=0, thick=2, data=[[x,loc[1]-.01], [x,loc[1]-self._y]]

end
;;---------------------------------------------------------------------------
;; IDLitVisText::MoveEntryPoint
;;
;; Purpose:
;;   This routine is used to move the text entry point when editing
;;
;; Parameters:
;;  oWin - The window the editing is being performed on.
;;
;;  locChar - The string index of the location character

pro IDLitVisText::MoveEntryPoint, oWin, locChar

    compile_opt idl2, hidden

    self._oText->GetProperty, STRINGS=text, LOCATION=loc, ALIGNMENT=align

    ;; Figure out the width of the string up to the entry point
    xText = STRMID(text, 0, locChar)
    ;; if there was a preceeding !C, start the string after it
    iEnd = STRPOS(xtext, "!C", STRLEN(xText), /REVERSE_SEARCH)
    if iEnd gt -1 then $
        xText = STRMID(xText, iEnd+2)
    ;; "Render" the shadow string to get its width
    self._oShadow->SetProperty, STRINGS=xText
    dims = oWin->GetTextDimensions(self._oShadow, DESCENT=descent)
    shadowWidth = dims[0]

    ;; Now compute the width of the entire string.
    ;; Take into account any !C that will shorten the string
    left = STRPOS(text, "!C", locChar, /REVERSE_SEARCH)
    ;; Left is the start of the string or just after the first !C
    ;; encountered to the left of the entry point.
    if left eq -1 then $
        left = 0 $
    else $
        left +=2
    ;; Right is the end of the string or just before the first !C
    ;; encountered to the right of the entry point
    right = STRPOS(text, "!C", locChar)
    if right eq -1 then $
        right = STRLEN(text)-1 $
    else $
        right -=1
    xText = STRMID(text, left, right-left+1)
    ;; "Render" the string to get its width
    self._oShadow->SetProperty, STRINGS=xText
    dims = oWin->GetTextDimensions(self._oShadow)
    ;; x coord is the alignment-adjusted start of the string
    ;; plus the shadow width
    x = loc[0] - dims[0] * align + shadowWidth

    ;; Now our y offset
    yText = STRMID(text, 0, locChar)
    if STRMID(yText, 1,2, /REVERSE_OFFSET) eq "!C" or locChar eq 0 then $
        ytext = ytext+'|'
    self._oShadow->SetProperty, STRINGS=ytext
    dims = oWin->GetTextDimensions(self._oShadow, DESCENT=descent)
    loc[1] -= (dims[1] + descent[0])
    self._oEntry->SetProperty, data=[[x,loc[1]-.01], [x,loc[1]+self._y]]
end
;;---------------------------------------------------------------------------
;; IDLitVisText::WindowPositionToOffset
;;
;; Purpose:
;;   Determine an insert point from a given window x, y location. This
;;   is done by walking the string and finding the position in the
;;   string that is the closest to the given xy location.
;;
;;   Since text size is determined by calling GetTextDimensions, the
;;   longer a string is the more time this routine will take. While
;;   this algorithm will try and jump into a possible locatoin in the
;;   string, it still will slow down with large strings.
;;
;; Parameters:
;;   oWin   - the associated Window
;;
;;   x      - X coord (Window)
;;
;;   y      - Y Coord (Window)
;;
;; Return Value:
;;   The offset in the string that is the closest to the given
;;   location.

function IDLitVisText::WindowPositionToOffset, oWin, x, y
    compile_opt hidden, idl2

    ;; First, validate the point is in the text range
    self->WindowToVis, x, y, x1, y1
    x1 = x1[0]
    y1 = y1[0]
    self._oText->GetProperty, strings=text, location=loc, alignment=align
    locOrig=loc
    textdims = oWin->GetTextDimensions(self._oText,descent=descent)
    iLen = strLen(Text)
    left = loc[0] - textdims[0] * align
    right = loc[0] + textdims[0] * (1-align)
    if(x1 lt left or x1 gt right)then $
      return, iLen
    loc[1] -= (textdims[1] + descent[0])
    if(y1 lt loc[1] or y1 gt loc[1]+textdims[1])then $
      return, iLen
    ;;
    ;; Okay, we are in range. First start walking the string and
    ;; finding the Y offset. This search is done using the following
    ;; logic:
    ;;   - A guess using the average y height is used.
    ;;   - A loop is used to skip initial rows based on the guess.
    ;;   - Lines are skipped based on !C. If no !C is present, the
    ;;     last line is used.
    ;;    - When the rough guess is reached, the string is
    ;;      rendered up to the next row to verify we are on the
    ;;      correct row. When a match is found, the Y search loop
    ;;      exits.
    ;;
    ;; Guess on which row to start in.
    iRow = floor( (y1 - LocOrig[1])/(-self._y))
    iCurr=0
    iPos =0
    while(iPos lt iLen)do begin
        iTmp = strpos(text, "!C", iPos)
        if(iTmp eq -1)then break; Last string.
        iCurr++ ;; increment our row count
        if(iCurr ge iRow)then begin ;; refine our search
            self._oShadow->SetProperty, STRINGS=strmid(text, 0, iTmp)
            dims = oWin->GetTextDimensions(self._oShadow, descent=descent)
            yloc = locOrig[1]- (dims[1] + descent[0])
            if(y1 gt yLoc)then break ;; In the correct row!
        endif
        iPos = iTmp+ 2 ;; Move to the end of the line
    endwhile

    iYPos = iPos
    ;; Now we have the Y offset, the x offset must be determined.
    ;; The trick here is to get a rough skinny charater size and
    ;; use it to skip in the x direction as needed. The key is to
    ;; minimize the calls to GetTextDimensions(). Tied in with
    ;; row jumpging, this should keep this routine within a decent
    ;; performance for large strings

    ;; Get our cut off point
    iCLoc = strpos(text, "!C", iPos)
    if(iCLoc eq -1)then iCLoc = strlen(text)
    iCurr=iPos
    ;; Get a rough string size
    self._oShadow->SetProperty, STRINGS="|"
    dims = oWin->GetTextDimensions(self._oShadow)
    delta2 = dims[0]
    ;; Recompute the left end of the string if not left-aligned.
    if align ne 0 then begin
        self._oShadow->SetProperty, STRINGS=strmid(text, iCurr, iCLoc-iCurr)
        dims = oWin->GetTextDimensions(self._oShadow)
        left = loc[0] - dims[0] * align
    endif
    while(iPos le iCLoc)do begin
        ;; Get the current string (start of line to current) and render
        self._oShadow->SetProperty, STRINGS=strmid(text, iCurr, iPos-iCurr)
        dims = oWin->GetTextDimensions(self._oShadow)
        ;; Have we hit the position?
        if(x1 lt dims[0] + left)then $ ;we are there
          return, iPos-1
        ;; Can we skip down the line?
        if(x1 - dims[0] - left gt delta2 )then begin
            ;; Skip based on the delta and our char size
            iSkip = floor((x1 - dims[0] - left)/delta2)
            for i=0, iSkip-1 do $
              iPos = iPos + (strmid(text, iPos, 2) eq "!" ? 2 : 1)
        endif  else $
          iPos = iPos + (strmid(text, iPos, 2) eq "!" ? 2 : 1)
    endwhile
    return, iCLoc-1 ;; we are at the end of line, set our location
end
;;---------------------------------------------------------------------------
;; IDLitVisText::EndEditing
;;
;; Purpose:
;;    Called to end the editing session in the text editor. This will
;;    hide the entry point and the shadow text string.
;;
pro IDLitVisText::EndEditing
    compile_opt hidden, idl2

   self._oEntry->SetProperty,/hide
   self->Remove, self._oEntry

   self._oShadow->SetProperty,/hide
   self->Remove, self._oShadow
end
;;----------------------------------------------------------------------------
;; IDLitVisText::Cleanup
;;
;; Purpose:
;;    Cleanup method for the text object.
;;
pro IDLitVisText::Cleanup
    compile_opt idl2, hidden

    OBJ_DESTROY, self._oFont
    obj_destroy, self._oShadow
    obj_destroy, self._oEntry

    ; Cleanup superclass
    self->IDLitVisualization::Cleanup
end

;----------------------------------------------------------------------------
; IIDLProperty Interface
;----------------------------------------------------------------------------
;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisText::GetProperty
;
; PURPOSE:
;      This procedure method retrieves the
;      value of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisText::]GetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisText::Init followed by the word "Get"
;      can be retrieved using IDLitVisText::GetProperty.
;
;-
pro IDLitVisText::GetProperty, $
             _HORIZONTAL_ALIGN=_horizAlign, $
             ALIGNMENT=horizAlign, $
             _STRING=_string, $
             STRINGS=strings, $
             FONT=font, $
             TRANSPARENCY=transparency, $
             _REF_EXTRA=_extra
   compile_opt idl2, hidden

    ; Get text
    self._oText->GetProperty,  ALIGNMENT=horizAlign, $
        ALPHA_CHANNEL=alphaChannel, $
         STRINGS=strings, $
         FONT=font

    if ARG_PRESENT(transparency) then $
        transparency = (1 - alphaChannel)*100

    ; Convert from 0, 0.5, 1 to 0, 1, 2
    if ARG_PRESENT(_horizAlign) then $
        _horizAlign = FIX(horizAlign*2)

    ; Extract the first string only.
    ; Watch out for undefined STRINGS property.
    if ARG_PRESENT(_string) then $
        _string = (SIZE(strings, /TYPE) eq 7) ? strings[0] : ''

    if (N_ELEMENTS(_extra) gt 0) then $
        self->_IDLitVisualization::GetProperty, _EXTRA=_EXTRA
end


;----------------------------------------------------------------------------
;+
; METHODNAME:
;      IDLitVisText::SetProperty
;
; PURPOSE:
;      This procedure method sets the value
;      of a property or group of properties.
;
; CALLING SEQUENCE:
;      Obj->[IDLitVisText::]SetProperty
;
; INPUTS:
;      There are no inputs for this method.
;
; KEYWORD PARAMETERS:
;      Any keyword to IDLitVisText::Init followed by the word "Set"
;      can be set using IDLitVisText::SetProperty.
;-

pro IDLitVisText::SetProperty,  $
                _HORIZONTAL_ALIGN=_horizAlign, $
                ALIGNMENT=swallow1, $
                _STRING=_string, $
                STRINGS=swallow2, $
                FONT_OBJECT=fontObject, $
                FONT_INDEX=fontIndex, $
                FONT_SIZE=fontSize, $
                FONT_STYLE=fontStyle, $
                NO_UPDATE=NO_UPDATE, $ ;; for interactive editing
                FILL_BACKGROUND=fillBackground, $
                TRANSPARENCY=transparency, $
                _REF_EXTRA=_extra

    compile_opt idl2, hidden


    updateSelVisual = 0b

    if N_ELEMENTS(transparency) then $
        alphaChannel = (100 - transparency)/100d

    ; For horizontal alignment, change the horizontal location
    ; so that the text doesn't move.
    if N_ELEMENTS(_horizAlign) then begin
        _horizAlign = 0 > FIX(_horizAlign) < 2   ; 0, 1, or 2
        self._oText->GetProperty, ALIGNMENT=oldAlign, $
            LOCATION=location
        oldAlign = 0 > FIX(oldAlign*2) < 2   ; 0, 1, or 2
        if (oldAlign ne _horizAlign) then begin
            textDims = self->_GetTextDimensions()
            case _horizAlign of
                0: offset = (oldAlign eq 2) ? -textDims[0] : -textDims[0]/2
                1: offset = (oldAlign eq 0) ? textDims[0]/2 : -textDims[0]/2
                2: offset = (oldAlign eq 0) ? textDims[0] : textDims[0]/2
                else:
            endcase
            location[0] += offset
            ; Don't forget to convert from enumerated to floats.
            self._oText->SetProperty, ALIGNMENT=_horizAlign/2.0, $
                LOCATION=location
        endif
        updateSelVisual = 1b
    endif


    if (N_ELEMENTS(_string) gt 0) then $
        strings = _string

    if (N_ELEMENTS(fillBackground)) then begin
        self._oText->SetPropertyAttribute, 'FILL_COLOR', $
            SENSITIVE=KEYWORD_SET(fillBackground)
    endif

    ; Show once we have a real string (needed for Styles).
    if (N_ELEMENTS(strings) gt 0) then $
        self->SetPropertyAttribute, '_STRING', HIDE=0

    self._oText->SetProperty, $
      FILL_BACKGROUND=fillBackground, $
      STRINGS=strings, $
      FONT=fontObject, ALPHA_CHANNEL=alphaChannel

    ; Handle the font properties directly so we can set our
    ; updateSelVisual flag as well.
    if (N_ELEMENTS(fontIndex) || N_ELEMENTS(fontSize) || $
        N_ELEMENTS(fontStyle)) then begin
        self._oFont->SetProperty, $
            FONT_INDEX=fontIndex, $
            FONT_SIZE=fontSize, $
            FONT_STYLE=fontStyle
        updateSelVisual = 1b
    endif

    ; Set superclass properties
    if (N_ELEMENTS(_extra) gt 0) then $
        self->_IDLitVisualization::SetProperty, _EXTRA=_extra

    ;; To get the correct selection visual size, the text dimenions
    ;; must be recalculated. To do this the only real method at this
    ;; point in the system is to get the window and call
    ;; GetTextDimensions. This is what this code does.
    ;;
    ;; Note: This must occur after the call to the super calls b/c
    ;;       the font is aggregated.
    ;;
    ;; Note: The NO_UPDATE keyword allows interactive editing to
    ;;       disable the calculation (for performance
    ;; We also make sure that we are part of a Window/View.
    if ((~KEYWORD_SET(NO_UPDATE)) && $
        self->_GetWindowandViewG(oWin, oViewG) && $
        (updateSelVisual || N_ELEMENTS(strings))) then begin
        self->UpdateSelectionVisual
    endif

end
;;---------------------------------------------------------------------------
;; IDLitVisText::OnDataChangeUpdate
;;
;; Purpose:
;;  This routine is called when the data associated with this text is
;;  changed or initially associated this visualization
;;
;; Parameters:
;;   oSubject   - The data object of the parameter that changed. if
;;                parmName is "<PARAMETER SET>", this is an
;;                IDLitParameterSet object
;;
;;   parmName   - The name of the parameter that changed.
;;
;; Keywords:
;;   None.
;;

pro IDLitVisText::OnDataChangeUpdate, oSubject, parmName

    compile_opt idl2, hidden

    SWITCH STRUPCASE(parmName) OF
    '<PARAMETER SET>': begin ;; just the the vertices and fall through
            oSubject = oSubject->GetByName('LOCATION', count=count)
            if(count eq  0)then $
               break;
            ;; fall through
        end
    'LOCATION': BEGIN
            success = oSubject->GetData(Vertex)
            if(success)then $
              self._oText->SetProperty, LOCATION=temporary(vertex)
            BREAK
        END
    ELSE:
    ENDSWITCH

end

;---------------------------------------------------------------------------
; IDLitVisText::OnViewZoom
;
;
; Purpose:
;   This procedure method handles notification that the view's
;   zoom factor has changed.
;
; Arguments:
;   oSubject: A reference to the object sending notification of the
;     view zoom.
;
;   oDestination: A reference to the destination in which the view
;     appears.
;
;   newZoomFactor: A scalar representing the new zoom factor.
;
pro IDLitVisText::OnViewZoom, oSubject, oDestination, newZoomFactor

    compile_opt idl2, hidden

    ; Check if view zoom factor has changed.  If so, update the font.
    self._oFont->GetProperty, VIEW_ZOOM=fontViewZoom

    if (fontViewZoom ne newZoomFactor) then $
        self._oFont->SetProperty, VIEW_ZOOM=newZoomFactor

    self->UpdateSelectionVisual

    ; Allow superclass to notify all children.
    self->_IDLitVisualization::OnViewZoom, oSubject, oDestination, $
        newZoomFactor
end

;---------------------------------------------------------------------------
; IDLitVisText::OnViewportChange
;
; Purpose:
;   This procedure method handles notification that the viewport
;   has changed.
;
; Arguments:
;   oSubject: A reference to the object sending notification of the
;     viewport change.
;
;   oDestination: A reference to the destination in which the view
;     appears.
;
;   viewportDims: A 2-element vector, [w,h], representing the new
;     width and height of the viewport (in pixels).
;
;   normViewDims: A 2-element vector, [w,h], representing the new
;     width and height of the visibile view (normalized relative to
;     the virtual canvas).
;
pro IDLitVisText::OnViewportChange, oSubject, oDestination, $
    viewportDims, normViewDims

    compile_opt idl2, hidden

    ; Check if destination zoom factor or normalized viewport has changed.
    ; If so, update the corresponding font properties.
    self._oFont->GetProperty, FONT_ZOOM=fontZoom, FONT_NORM=fontNorm
    if (OBJ_VALID(oDestination)) then $
        oDestination->GetProperty, CURRENT_ZOOM=zoomFactor $
    else $
        zoomFactor = 1.0

    normFactor = MIN(normViewDims)

    if ((fontZoom ne zoomFactor) || $
        (fontNorm ne normFactor)) then $
        self._oFont->SetProperty, FONT_ZOOM=zoomFactor, FONT_NORM=normFactor

     self->UpdateSelectionVisual

    ; Allow superclass to notify all children.
    self->_IDLitVisualization::OnViewportChange, oSubject, oDestination, $
        viewportDims, normViewDims
end

;;
;;---------------------------------------------------------------------------
;; IDLitVisText::SetLocation
;;
;; Purpose:
;;    Used to set the location of the given text on the screen.
;;
;; Parameters:
;;   x   - X location
;;   y   - Y location
;;   z   - Z location
;;
;; Keywords:
;;  WINDOW    - If set, the provided values are in Window coordinates
;;              and need to be  converted into visualization coords.

pro IDLitVisText::SetLocation, x, y, z, WINDOW=WINDOW
  compile_opt hidden, idl2

  if(keyword_set(WINDOW))then $
    self->_IDLitVisualization::WindowToVis, [x, y, z], Pt $
  else $
    Pt=[x,y,z]

  oDataObj = self->GetParameter("LOCATION")
  if(obj_valid(oDataObj))then $
    iStatus = oDataObj->SetData(Pt)

end


;----------------------------------------------------------------------------
function IDLitVisText::_GetTextDimensions, _REF_EXTRA=_extra

    compile_opt idl2, hidden

    oTool=self->GetTool()

    ; Just make sure we have a parent, and then assume we are in the
    ; current tool hierarchy.
    self->GetProperty, PARENT=oParent

    if (obj_valid(oParent) && OBJ_VALID(oTool)) then begin
        oWin = oTool->GetCurrentWindow()
        if (OBJ_VALID(oWin)) then begin
            return, oWin->GetTextDimensions(self._oText, _EXTRA=_extra)
        endif
    endif

    return, [0, 0, 0]

end


;;----------------------------------------------------------------------------
;; IDLitVisText::UpdateSelectionVisual
;;
;; Purpose:
;;   This routine overrides the method in _IDLItVisualization so that
;;   the text dimensions can be calculated before the selection visual
;;   is updated. This is a non-optimal solution, but because of the
;;   implementation of text in the IDLgrText system, a
;;   GetTextDimensions() call must be made on the Window before the
;;   text size is know. If this isn't done, the selection visual will
;;   be incorrect.

pro IDLitVisText::UpdateSelectionVisual

    compile_opt idl2, hidden

    void = self->_GetTextDimensions()

    ; Call our superclass.
    self->_IDLitVisualization::UpdateSelectionVisual

end


;----------------------------------------------------------------------------
; Object Definition
;----------------------------------------------------------------------------

;----------------------------------------------------------------------------
;+
; IDLitVisText__Define
;
; PURPOSE:
;    Defines the object structure for an IDLitVisText object.
;
;-
pro IDLitVisText__Define

    compile_opt idl2, hidden

    struct = { IDLitVisText,           $
               inherits IDLitVisualization, $
               _oText: obj_new(), $
               _oShadow : obj_new(), $
               _oEntry : obj_new(), $
               _y:0.0, $
               _oFont: OBJ_NEW() $
    }
end
