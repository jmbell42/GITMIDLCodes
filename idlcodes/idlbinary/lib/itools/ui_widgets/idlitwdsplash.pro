; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/itools/ui_widgets/idlitwdsplash.pro#1 $
;
; Copyright (c) 2002-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   IDLitWdToolSplash
;
; PURPOSE:
;   Create the IDL UI (widget) splash screen. This can only be run
;   once per session
;
; CALLING SEQUENCE:
;   IDLitWDSplash           - to display
;   IDLitWDSplash_shutdown  - to remove
;
; KEYWORD PARAMETERS:
;   DELAY_TIMER
;   Set to the number of seconds to set the shutdown timer. This is a
;   fallback timer to remove the screen if other methods fail. The
;   default value is 10.
;
; MODIFICATION HISTORY:
;-

;---------------------------------------------------------------------------
; IDLitWdSplash_Event
;
; Purpose:
;   Used as a fallback method for shutting down the splash
;   screen. Basically a timer is fired to trigger shutdown.
;
pro idlitwdsplash_event, ev

    compile_opt idl2, hidden

   ; The only event is a timer event that is used as backup to shutdown
   ; the splash screen
   idlitwdsplash_shutdown
end
;---------------------------------------------------------------------------
; IDLitWdSplash__Update
;
; Purpose:
;   Used to update the progress bar on the splash screen.
;
; Arguments:
;   Percent  - The amount of percent done with the startup
;              process.
pro idlitwdsplash_update, percent

   compile_opt idl2, hidden
   common _IDLitTools$Splash$_, c_iRan, wSplash, oldR, oldG, oldB

    if (~n_elements(wSplash))then $
        return
    if (~widget_info(wSplash,/valid))then $
        return
    strOldDev = !d.name
    set_plot,(!version.os_family eq 'Windows' ? 'WIN' : 'X')
    widget_control, wSplash, get_uvalue=state
    wset, state.idxPix
    p = percent/100.
    x = state.xprog*(percent/100.) < state.xprog-3
    if(!d.n_colors gt 256)then $
     device, decompose=0
    polyfill, [2,2,x,x], [2,state.yprog-4, state.yprog-4,2], $
     color=0,/device
    wset,state.idxDraw
    device, copy=[0, 0, state.xprog, state.yprog, $
           state.xoff, state.yoff, state.idxPix]
    set_plot, strOldDev

end


;---------------------------------------------------------------------------
; IDLitwdSplash_shutdown
;
; Purpose:
;   Called to shutdown the splash screen. If nothing exists, it just
;   returns quietly.

pro idlitwdsplash_shutdown

   compile_opt idl2, hidden
   common _IDLitTools$Splash$_, c_iRan, wSplash, oldR, oldG, oldB

   if(n_elements(wSplash) gt 0)then begin
       if(widget_info(wSplash,/valid))then begin
           strOldDev = !d.name
           set_plot,(!version.os_family eq 'Windows' ? 'WIN' : 'X')
           widget_control, wSplash, get_uvalue=state
           wdelete, state.idxPix
           widget_control, wSplash, /destroy

           tvlct, oldR, oldG, oldB
           if(!d.n_colors gt 256)then $
             device, decompose=state.oldDecompose
           set_plot, strOldDev
       endif
       void = temporary(wSplash)
       void = temporary(oldR)
       void = temporary(oldG)
       void = temporary(oldB)
   endif

end


;---------------------------------------------------------------------------
; IDLitWdSplash
;
; Purpose:
;   Used to display a splash screen on initial startup.
;
; The user must shutdown the splash screen using
; idlitwdSplash_shutdown
;
; Arguments:
;   Filename: Set this optional argument to a string giving the full path
;       to the image file to use for the splash screen.
;       This file must be an 8-bit PNG image.
;       If this argument is not provided then the standard iTools
;       splash screen is used.
;
; Keywords:
;    DELAY_TIMER   - The amount of delete to use. Default is 2 sec.
;
;    DISABLE_SPLASH_SCREEN - If set, the screen isn't shown
;
; Return Value
;   1 - Splash is up
;   0 - no splash
;
function idlitwdsplash, strFilename, $
    DELAY_TIMER=delay_timer, $
    DISABLE_SPLASH_SCREEN=DISABLE_SPLASH, $
    PERCENT=percent

   compile_opt idl2, hidden
   common _IDLitTools$Splash$_, c_iRan, wSplash, oldR, oldG, oldB

   if(n_elements(c_iRan))then begin ; Already ran the splash screen
       if(n_elements(wSplash) gt  0)then begin
           if(widget_info(wSplash, /valid))then begin
                if (N_ELEMENTS(percent) gt 0) then $
                    idlitwdsplash_update, percent
                if (KEYWORD_SET(disable_splash)) then $
                    idlitwdsplash_shutdown
              return, 1
           endif
       end
       return,0
   end
   ; Disable the splash screen?
   if(keyword_set(DISABLE_SPLASH))then begin
       c_iRan =1
       return, 0
   endif
@idlit_catch
   if(iErr ne 0)then begin
       catch, cancel=1
       c_iRan = 1
       return,0
   endif
   ; Constants
   xprog=150  ; xsize of progress bar
   yprog=10   ; ysize of progress bar
   yoffset=15 ; Offset from the botom of the image

   ; Get the image. This is a special image for the splash screen. It
   ; has the following attributes:
   ;     - Minimum colors (about 130)
   ;     - first color is the progress bar color
   ;     - 2nd color is the boarder
   ;     - 3rd in the background color
   ; Make sure the image is there:
   if (~N_ELEMENTS(strFilename)) then begin
    strFilename = filepath("itools_splash.png", $
        subdir=['resource','bitmaps'])
   endif
   bExists = file_test(strFilename, /READ)
   if(bExists eq 0)then begin ; the file isn't there, return
       c_iRan=1
       return, 0
   endif
   img = read_png(strFilename, r,g,b)

    ; Be sure to quantize our colors down to 128, and leave room
    ; for the bottom three for the progress bar.
    img = COLOR_QUAN(r[img], g[img], b[img], r, g, b, COLOR=125) + 3b
    r = [0b,0b,255b,r]
    g = [220b,0b,255b,g]
    b = [0b,0b,255b,b]

   szImage = size(img)
   strOldDev = !d.name
   set_plot,(!version.os_family eq 'Windows' ? 'WIN' : 'X')
   device, get_screen_size=szScreen
   wSplash = widget_base(tlb_frame_attr=31, map=0, $
                         xoffset=(szScreen[0]-szImage[1]-3)/2, $
                         yoffset=(szScreen[1]-szImage[2]-3)/2)
   wDraw = widget_draw(wSplash, xsize=szImage[1], ysize=szImage[2], $
                         retain=2, /button_events)

   widget_control, wSplash, /realize
   widget_control, wDraw, get_value=idxDraw
   device, get_decompose=oldDecompose
   if(!d.n_colors gt 256)then $
       device, decompose=0

   tvlct,oldR, oldG, oldB, /get
   tvlct, r,g,b

   oldDex = !d.window
   wset, idxDraw
   widget_control, map=1, wSplash
   tv, img,order=0

   ; Begin a progress bar work

   window, /free, /pix, xsize=xprog, ysize=yprog
   idxPix = !d.window
   wset, idxPix
   xoff = szImage[1]-xprog - 20;(szImage[1]-xprog)/2
   erase, 2
   plots, [0,0, xprog-1, xprog-1,0], [0,yprog-1,yprog-1, 0,0], $
       /device, color=1, thick=2

   wset,idxDraw
   device, copy=[0, 0, xprog, yprog, xoff, yoffset, idxPix]

   ; Put in a version while the splash screen splashes
@idlitconfig.pro
   xyouts, szImage[1]/2, 6, IDLitLangCatQuery('UI:wdSplash:Version') $
           +ITOOLS_STRING_VERSION, $
           alignment=.5,/device, font=-1,color=2, charsize=.65
   c_iRan=1
   if(!d.n_colors gt 256)then begin
       device, decompose=oldDecompose
   endif

   set_plot, strOldDev
   widget_control, wSplash, timer=(keyword_set(delay_timer) ? delay_timer : 2)
   widget_control, wSplash, set_uvalue = $
              { idxDraw:idxDraw, idxPix:idxPix, oldDecompose:oldDecompose, $
                 xoff:xoff, yoff:yoffset, xprog:xprog, yprog:yprog,inc:0}

    XMANAGER, 'idlitwdsplash', wSplash, /JUST_REG, /NO_BLOCK

   return, 1
end
