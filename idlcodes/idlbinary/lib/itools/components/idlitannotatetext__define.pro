; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/components/idlitannotatetext__define.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;----------------------------------------------------------------------------
;+
; CLASS_NAME:
;   IDLitAnnotateText
;
; PURPOSE:
;   Abstract class for the manipulator system of the IDL component framework.
;   The class will not be created directly, but defines the basic
;   structure for the manipulator container.
;
; CATEGORY:
;   Components
;
; SUPERCLASSES:
;   IDLitManipulator
;
; SUBCLASSES:
;
;-

;---------------------------------------------------------------------------
; Lifecycle Routines
;---------------------------------------------------------------------------
; IDLitAnnotateText::Init
;
; Purpose:
;  The constructor of the manipulator object.
;
function IDLitAnnotateText::Init, strType, _EXTRA=_extra

    compile_opt idl2, hidden

    ; Init our superclass
    status =self->IDLitManipAnnotation::Init( TRANSIENT_DEFAULT=2,$
                                              NAME='Text Annotation', $
                                              DEFAULT_CURSOR='IBEAM', $
                                              _EXTRA=_extra)
    if(status eq 0)then return,0

    return,1

end


;--------------------------------------------------------------------------
;; IDLitAnnotateText::Cleanup
;;
;; Purpose:
;;   Cleanup method for this object.
;;
;pro IDLitAnnotateText::Cleanup
;    compile_opt idl2, hidden
;    self->IDLitManipAnnotation::Cleanup
;end


;;---------------------------------------------------------------------------
;; IDLitAnnotateText::FinishAnnotate
;;
;; Purpose:
;;   When called, any pending annotation is completed.
;;
pro IDLitAnnotateText::FinishAnnotate
    compile_opt idl2, hidden

    if (~self.inAnnotate) then $
        return

    self.inAnnotate = 0b
    oTool = self->GetTool()
    oWin = oTool->GetCurrentWindow()
    if (OBJ_VALID(oWin)) then begin
        ; Turn keyboard accelerators back on.
        self->DoOnNotify, oWin->GetFullIdentifier(), $
            'IGNOREACCELERATORS', 0
    endif

    if (~obj_valid(self._oText)) then $
        return

    self._oText->GetProperty, STRINGS=text

    if (text ne '') then begin
        self._oText->EndEditing
        self->CommitAnnotation, self._oText
    endif else begin  ; No text, delete
        self._oText->getProperty, _PARENT=oParent
        oParent->remove, self._oText
        obj_destroy, self._oText
        self->CancelAnnotation
    endelse

    self._oText = obj_new()

end


;;---------------------------------------------------------------------------
;; IDLitAnnotateText::OnLoseCurrentManipulator
;;
;; Purpose:
;;   This routine is called by the manipualtor system when this
;;   manipulator is made "not current". If called, this routine will
;;   make sure any pending annotations are completed
;;
pro IDLitAnnotateText::OnLoseCurrentManipulator
    compile_opt  idl2, hidden

    self->FinishAnnotate

    ; Call our superclass.
    self->_IDLitManipulator::OnLoseCurrentManipulator
end


;--------------------------------------------------------------------------
;
; This interface implements the IIDLWindowEventObserver interface
;
;--------------------------------------------------------------------------
; IDLitAnnotateText::OnMouseDown
;
; Purpose:
;   Implements the OnMouseDown method. This method is often used
;   to setup an interactive operation.
;
; Parameters
;      oWin    - Source of the event
;  x   - X coordinate
;  y   - Y coordinate
;  iButton - Mask for which button pressed
;  KeyMods - Keyboard modifiers for button
;  nClicks - Number of clicks

pro IDLitAnnotateText::OnMouseDown, oWin, x, y, iButton, KeyMods, nClicks

    compile_opt idl2, hidden

    ; To avoid too many draws, disable updates until the end.
    oTool = self->GetTool()
    oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled

    ; Call our superclass.
    self->IDLitManipulator::OnMouseDown, $
        oWin, x, y, iButton, KeyMods, nClicks

    ; If we previously had a valid annotation object, with a valid
    ; cursor line, then we should remove it. This can occur if the user
    ; doesn't hit Return or ESC but just clicks somewhere else.
    ; Note: We return here. If you don't, the text annotation manipulator
    ;       becomes very confused. Related to how annotation is committed.
    if(self.inAnnotate)then begin
        self->FinishAnnotate
        if (~wasDisabled) then $
            oTool->EnableUpdates
        return
    endif

    oItems = oWin->GetSelectedItems()
    dex = where(obj_isa(oItems, "IDLitVisText"), nText)

    if(nText gt 0)then begin

        self._oText = oItems[dex[0]]
        self._oText->Select,0
        self._oText->BeginEditing,oWin ;start edit mode
        self._iInsert = self._oText->WindowPositionToOffset(oWin, x, y)
        self._oText->moveEntryPoint, oWin, self._iInsert

        ; If we are editing a current text item, then we want
        ; to use SetProperty for our Undo/Redo operation.
        self->SetProperty, OPERATION_IDENTIFIER='SET_PROPERTY', $
            PARAMETER_IDENTIFIER='_STRING'

    endif else begin

        ;; Create our new annotation.
        oDesc = oTool->GetAnnotation('Text')
        self._oText = oDesc->GetObjectInstance()

        ;; Add a data object.
        oData = obj_new("IDLitData", type="IDLPOINT", name='Location',/private)
        void=    self._oText->SetData(oData, parameter_name= 'LOCATION',/by_value)

        self._oText->SetProperty, HIDE=1 ;; TODO: FIX this/prevent from flashing
        ;; Add this text to the annotation layer.
        oWin->Add, self._oText, LAYER='ANNOTATION', /NO_UPDATE, /NO_NOTIFY

        ;; Set the text at the down location. This must be done after the
        ;; item is in the scene graph.
        self._oText->SetLocation, x, y, self._normalizedZ, /WINDOW
        self._oText->SetProperty, HIDE=0 ;; can show now.
        self._iInsert=0
        self._oText->BeginEditing,oWin ;start edit mode

        ; We are creating a new text item, so use our standard
        ; annotation operation for Undo/Redo.
        self->SetProperty, OPERATION_IDENTIFIER='ANNOTATION', $
            PARAMETER_IDENTIFIER=''

    endelse


    oTool->RefreshCurrentWindow

    ; Add a helpful message.
    self->StatusMessage, IDLitLangCatQuery('Status:AnnotateText:Text2')

    ; We need to turn off keyboard accelerators on the draw window,
    ; so that keyboard events get routed here rather than intercepted
    ; by the top-level menus.
    self->DoOnNotify, oWin->GetFullIdentifier(), 'IGNOREACCELERATORS', 1

    self.inAnnotate = 1b        ;we are annotating

    iStatus = self->RecordUndoValues()

end

;;--------------------------------------------------------------------------
;; IDLitAnnotateText::OnKeyBoard
;;
;; Purpose:
;;   Implements the OnKeyBoard method.
;;
;; Parameters
;;      oWin        - Event Window Component
;;      IsAlpha     - The the value a character or ASCII value?
;;      Character   - The ASCII character of the key pressed.
;;      KeyValue    - The value of the key pressed.
;;                    1 - BS, 2 - Tab, 3 - Return
;;      X           - The location the keyboard entry began at (last
;;                    mousedown)
;;      Y           - The location the keyboard entry began at (last
;;                    mousedown)
;;      press       - 1 if keypress, 0 if not
;;
;;      release     - 1 if keypress, 0 if not
;;
;;      Keymods     - Set to values of any modifier keys.

pro IDLitAnnotateText::OnKeyBoard, oWin, $
    IsASCII, Character, KeyValue, X, Y, Press, Release, KeyMods
   ;; pragmas
   compile_opt idl2, hidden

   if (OBJ_VALID(self._oText) eq 0) then return

   if(release)then return

    ; To avoid too many draws, disable updates until the end.
    oTool = self->GetTool()
    oTool->DisableUpdates, PREVIOUSLY_DISABLED=wasDisabled

   self._oText->GetProperty, _STRING=text
   ;; First check for non-Ascii text. Like Arrow keys.
   if(IsASCII eq 0)then begin
       ;; Right now just worry about left and right motion
       if(KeyValue eq 5 and self._iInsert gt 0)then begin ;; left
           while(self->_IsPreviousHershey(self._iInsert, text, Hershey)) do begin
               if(hershey eq "!C" or hershey eq "!!")then begin
                   self._iInsert--;; next char is decremented below
                   break
               endif
               self._iInsert -=2
           endwhile
           self._iInsert--
       endif else if(Keyvalue eq 6 and self._iInsert lt strlen(text))then begin ;; right
           while(self->_IsNextHershey(self._iInsert, text, Hershey)) do begin
               if(hershey eq "!C" or hershey eq "!!")then begin
                   self._iInsert++
                   break
               endif
               self._iInsert +=2
           endwhile
           self._iInsert++
       endif
       self._oText->moveEntryPoint, oWin, self._iInsert
   endif else begin
       switch KeyMods of
           0:
           1:begin
               case Character of
                   13: begin ;; <CR> ;; accept
                       self._oText->SetProperty, _STRING=text
                       self->FinishAnnotate
                   end
                   27: begin  ; <ESC> Abort
                        self._oText->SetProperty, STRINGS=''
                        self->FinishAnnotate
                       end
                   8: begin ;; backspace - delete from prev slot
                       ;; are we at the begining of the string?
                       if(self._iInsert eq 0)then break
                       ;; Skip over any pure Hershey formatting
                       ;; codes. This is needed to preserve
                       ;; formatting when editing between codes.
                       delChar=1
                       while(self->_IsPreviousHershey(self._iInsert, text, Hershey)) do begin
                           if(hershey eq "!C" or hershey eq "!!")then begin
                               delChar=2
                               break
                           endif
                           self._iInsert-=2
                       endwhile
                       self._iInsert -= delChar
                       newText = strmid(text, 0, self._iInsert) + $
                         strmid(text, self._iInsert+delChar)
                   end
                   127: begin   ; delete (remove from next slot
                       ;; are we at the begining of the string?
                       if(self._iInsert eq strlen(text))then break
                       delChar=1
                       while(self->_IsNextHershey(self._iInsert, text, Hershey)) do begin
                           if(hershey eq "!C" or hershey eq "!!")then begin
                               delChar=2
                               break
                           endif
                           self._iInsert+=2
                       endwhile
                       newText =strmid(text,0, self._iInsert) + strmid(text, self._iInsert+delChar)

                   end
                   33: begin ;; Bang (!)
                       newtext = strmid(text,0, self._iInsert) + $
                         "!!"+STRMID(text, self._iInsert)
                       self._iInsert += 2
                   end
                   else: begin  ;just good old text!
                       newtext = strmid(text,0, self._iInsert) + $
                         STRING(Character)+STRMID(text, self._iInsert)
                       self._iInsert++
                   end
               endcase
               break            ;
           end
           2: begin
               case Character of
;                   1:  newtext = '!A'
;                   2:  newtext = '!B'
                   4:  newtext = '!D'  ; <Ctrl>D subscript
                   10: newtext = '!C'
                   14: newtext = '!N'
                   21: newtext = '!U'  ; <Ctrl>U superscript
                   else:newtext=''
               endcase
               if(newtext ne '')then begin
                   mode = (strlen(text) gt self._iInsert ? $
                           self->_GetCurrentHersheyMode(self._iInsert, text) : '')
                   newtext = strmid(text,0, self._iInsert) + $
                     newText + mode +STRMID(text, self._iInsert)
                   self._iInsert += 2
               endif else newtext = text
           end

           else:

       endswitch
       if (N_ELEMENTS(newtext) gt 0) then begin
           ;; Prevent selection visual updates w the /no_update keyword
           self._oText->SetProperty, _STRING=newtext,/no_update
           self._oText->moveEntryPoint, oWin,self._iInsert
       endif
   endelse

;   oWin->Draw, /DRAW_INSTANCE
    oTool->RefreshCurrentWindow

    if (~wasDisabled) then $
        oTool->EnableUpdates

end

;;---------------------------------------------------------------------------
;; IDLitAnnotateText::_GetCurrentHersheyMode
;;
;; Purpose:
;;  Used to determine the current hershey mode for a given point in a
;;  string. This is needed when inserting a new hershey mode, to
;;  preserve formatting for chars. For example the following string:
;;
;;    !Ncow!Upig moo!N
;;
;; Would be the following if a !D was put between "pig" and "moo"
;;
;;    !Ncow!upig!D!U moo!N
;;
;; Parameters:
;;  iPoint - Current insertion ponit in the string
;;
;;  text   - The string
;;
;; Return Value:
;;    The Hershey mode
;;
function IDLitAnnotateText::_GetCurrentHersheyMode, iPoint, text

    compile_opt idl2, hidden

   ;; Basically, the string must be traversed until hitting the given
   ;; point. This required since hershey formatting is forward direction
   ;; dependent
   iChar = strpos(text,"!")
   iHershey=-1
   while(iChar ge 0 and iChar lt  iPoint-2) do begin
       Hershey = strmid(text, iChar,2)
       if(Hershey ne "!!" and Hershey ne "!C")then $
         iHershey = iChar
       iChar = strpos(text, "!", iChar+2)
   endwhile
   if(iHershey eq -1)then $
     Hershey="!N"
   return, Hershey
end
;;---------------------------------------------------------------------------
;; IDLitAnnotateText::_IsPreviousHershey
;;
;; Purpose:
;;  Used to determine if the previous charater is a hershey formatting
;;  code.
;;
;;
function IDLitAnnotateText::_IsPreviousHershey, iPoint, text,  Hershey
   compile_opt hidden, idl2

   ;; If the insertion point is le 1, there can be no hershey chars.
   if(iPoint lt 2)then return, 0

   ;; Basically, the string must be traversed until hitting the given
   ;; point. This required since hershey formatting is forward direction
   ;; dependent
   iChar = strpos(text,"!")
   while(iChar ge 0 and iChar lt  iPoint-2) do $
       iChar = strpos(text, "!", iChar+2)

   if(iChar eq iPoint-2 )then begin
       Hershey = strmid(text, iChar,2)
       return, 1
   endif else Hershey=''
   return, 0
end

;;---------------------------------------------------------------------------
;; IDLitAnnotateText::_IsNextHershey
;;
;; Purpose:
;;  Used to determine if the next charater is a hershey formatting
;;  code. This pretty simpl
;;
;;
function IDLitAnnotateText::_IsNextHershey, iPoint, text,  Hershey

    compile_opt idl2, hidden

   if(strMid(text, iPoint,1) eq '!')then begin
       Hershey=strMid(text, iPoint,2)
       return,1
   endif
   Hershey=''
   return, 0
end
;--------------------------------------------------------------------------
; IDLitAnnotateText__Define::GetCursorType
;
; Purpose:
;   This function method gets the cursor type for the item that was
;   hit during a mouse motion. For this manipulator, we enable IBEAM
;   for everything.
;
; Parameters
;  type: Optional string representing the current type.
;
function IDLitAnnotateText::GetCursorType, typeIn, KeyMods
    compile_opt idl2, hidden
    return, '';; always use the default
end


;---------------------------------------------------------------------------
; IDLitAnnotateText__Define
;
; Purpose:
;   Define the base object for the manipulator container.
;
pro IDLitAnnotateText__Define

    compile_opt idl2, hidden

    ; Just define this bad boy.
    void = {IDLitAnnotateText, $
            inherits IDLitManipAnnotation, $ ; super class
            inAnnotate       : 0b,         $ ; performing an annotation
            _iInsert         : 0,          $ ; Insert point
            _oText           : OBJ_NEW()   $ ; The text
        }

end
