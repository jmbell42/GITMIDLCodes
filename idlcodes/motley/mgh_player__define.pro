;+
; CLASS:
;   MGH_Player
;
; PURPOSE:
;   A window for displaying & managing picture sequences.
;
; CATEGORY:
;       Widgets, Object Graphics.
;
; PROPERTIES:
;   The following properties (ie keywords to the Init, GetProperty &
;   SetProperty methods) are supported:
;
;     CUMULATIVE (Init, Get, Set)
;       The number of frames to superpose on each display. Default is
;       1. If CUMULATIVE is zero or negative then all frames up to the
;       current one are superposed.
;
;     N_FRAMES (Get)
;       The number of frames currently managed by the animator.
;
;     SLAVE (Init, Get, Set)
;       Set this property to specify that the player will be
;       controlled externally.
;
;###########################################################################
;
; This software is provided subject to the following conditions:
;
; 1.  NIWA makes no representations or warranties regarding the
;     accuracy of the software, the use to which the software may
;     be put or the results to be obtained from the use of the
;     software.  Accordingly NIWA accepts no liability for any loss
;     or damage (whether direct of indirect) incurred by any person
;     through the use of or reliance on the software.
;
; 2.  NIWA is to be acknowledged as the original author of the
;     software where the software is used or presented in any form.
;
;###########################################################################
;
; MODIFICATION HISTORY:
;   Mark Hadfield 2001-07.
;     Written.
;   Mark Hadfield 2004-04:
;     Several changes to the code that exports animations to
;     bitmap-oriented animation formats:
;      - Removed facility to save an animation in PPM_SEQUENCE
;        form. Image sequences can be created in other ways,
;      - Added method WriteAnimationToAVIFile to produce AVI movies
;        using the IDL_AVI DLM. See also the new function MGH_AVI_REGISTERED.
;   Mark Hadfield 2005-01:
;     Fixed bug in WriteAnimationToAVIFile: when USE_RANGE property is set and
;     frames are skipped, empty frames are being left in the AVI file.
;   Mark Hadfield 2006-05:
;     - The WriteAnimationToAVIFile method now uses the MGHaviWriteFile class,
;       which provides an interface to Olgeg Kornilov's AVI DLL.
;     - The menu item that supports MPEG output has been deleted, as MPEG
;       output from the IDLgrMPEG object is pretty awful.
;   Mark Hadfield 2007-10:
;     - The WriteAnimationToAVIFile method now forces the output buffer size
;       to be a multiple of 8 (previously 4) to supprt a wider range of codecs.
;-

; MGH_Player::Init
;
function MGH_Player::Init, anim, $
     ANIMATION=animation, CUMULATIVE=cumulative, PLAYBACK=playback, SLAVE=slave, $
     _REF_EXTRA=_extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Process animation arguments

   if n_elements(animation) eq 0 && n_elements(anim) gt 0 then animation = anim

   ;; Properties

   self.cumulative = n_elements(cumulative) gt 0 ? cumulative : 1

   ;; Initialise the widget base

   ok = self->MGH_Window::Init( _STRICT_EXTRA=_extra)

   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_Window'

   ;; Add the animator

   self->NewChild, /OBJECT, 'MGH_Animator', CLIENT=self, $
        /ALIGN_CENTER, PLAYBACK=playback, SLAVE=slave, RESULT=animator
   self.animator = animator

   ;; Load the animation. The graphics window hasn't been
   ;; realised yet, so we just store the info in the class structure.

   if obj_valid(animation) then begin
      self.animation = animation
      self.animation->GetProperty, GRAPHICS_TREE=graphics_tree
      self.graphics_tree = graphics_tree
   endif

   ;; Finalise

   self->Finalize, 'MGH_Player'

   return, 1

end


; MGH_Player::Cleanup
;
pro MGH_Player::Cleanup

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   obj_destroy, self.animation

   obj_destroy, self.animator

   self->MGH_Window::Cleanup

end


; MGH_Player::GetProperty
;
pro MGH_Player::GetProperty, $
     ANIMATION=animation, ANIMATOR=animator, CUMULATIVE=cumulative, N_FRAMES=n_frames, $
     PLAYBACK=playback, POSITION=position, SLAVE=slave, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   animation = self.animation

   animator = self.animator

   cumulative = self.cumulative

   if arg_present(n_frames) then $
        n_frames = obj_valid(self.animation) ? self.animation->N_Frames() : 0

   if obj_valid(self.animator) then $
        self.animator->GetProperty, PLAYBACK=playback, POSITION=position, SLAVE=slave

   self->MGH_Window::GetProperty, _STRICT_EXTRA=extra

END

; MGH_Player::SetProperty
;
pro MGH_Player::SetProperty, $
     ANIMATION=animation, CUMULATIVE=cumulative, PLAYBACK=playback, $
     POSITION=position, SLAVE=slave, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(animation) gt 0 then begin
      self.animation = animation
      case obj_valid(animation) of
         0: graphics_tree = obj_new()
         1: self.animation->GetProperty, GRAPHICS_TREE=graphics_tree
      endcase
      self->MGH_Window::SetProperty, GRAPHICS_TREE=graphics_tree
   endif

   if n_elements(cumulative) gt 0 then $
        self.cumulative = cumulative

   if obj_valid(self.animator) then $
        self.animator->SetProperty, PLAYBACK=playback, POSITION=position, SLAVE=slave

   self->MGH_Window::SetProperty, _STRICT_EXTRA=extra

end

; MGH_Player::About
;
pro MGH_Player::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Window::About, lun

   printf, lun, FORMAT='(%"%s: my animation is %s")', $
           mgh_obj_string(self), mgh_obj_string(self.animation, /SHOW_NAME)


end

; MGH_Player::AssembleFrame
;
pro MGH_Player::AssembleFrame, position

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; This method can assume that position will always be a
   ;; defined, scalar integer >= 0.

   self.animation->GetProperty, MULTIPLE=multiple

   case multiple of
      0: frame = position
      1: begin
         p0 = (position-self.cumulative+1) > 0
         p1 = position
         frame = p0 + lindgen(p1-p0+1)
      end
   endcase

   self.animation->AssembleFrame, frame

end

; MGH_Player::BuildMenuBar
;
; Purpose:
;   Add menus, sub-menus & menu items to the menu bar

pro MGH_Player::BuildMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ widget_info(self.menu_bar, /VALID_ID) then return

   if widget_info(self.menu_bar, /CHILD) gt 0 then $
        message, 'The menu bar already has children'

   ;; Create a pulldown menu object with top-level items.

   obar = obj_new('MGH_GUI_PDmenu', BASE=self.menu_bar, /MBAR, $
                  ['File','Edit','Tools','Window','Help'])

   ;; Populate menus in turn...

   ;; ...File menu

   case self.changeable of
      0: begin
         obar->NewItem, PARENT='File', $
              ['Save...','Export Animation','Export Frame', $
               'Print Frame','Slave','Close'], $
              MENU=[0,1,1,1,0,0], SEPARATOR=[0,1,0,1,1,1], $
              CHECKED_MENU=[0,0,0,0,1,0], $
              ACCELERATOR=['Ctrl+S','','','','','Ctrl+F4']
      end
      1: begin
         obar->NewItem, PARENT='File', $
              ['Open...','Save...','Clear','Export Animation', $
               'Export Frame','Print Frame','Slave','Close'], $
              MENU=[0,0,0,1,1,1,0,0], SEPARATOR=[0,0,0,1,0,1,1,1], $
              CHECKED_MENU=[0,0,0,0,0,0,1,0], $
              ACCELERATOR=['Ctrl+O','Ctrl+S','','','','','','Ctrl+F4']
      end
   endcase

   case file_test(mgh_avi_dll()) of
      1B: fmts = ['AVI...','FLC...','MJ2...','TIFF...','ZIP...']
      0B: fmts = ['FLC...','MJ2...','TIFF...','ZIP...']
   endcase
   obar->NewItem, PARENT='File.Export Animation', temporary(fmts)

   case strcmp(!version.os_family, 'Windows', /FOLD_CASE) of
      1B: fmts = ['EPS...','PNG...','PNG (h-r)...','JPEG...','PPM...','VRML..','WMF...']
      0B: fmts = ['EPS...','PNG...','PNG (h-r)...','JPEG...','PPM...','VRML..']
   endcase
   obar->NewItem, PARENT='File.Export Frame', temporary(fmts)

   obar->NewItem, PARENT='File.Print Frame', ['Bitmap...','Vector...']

   ;; ...Edit menu

   obar->NewItem, PARENT='Edit', MENU=[1,0,1], SEPARATOR=[0,1,1], $
        ['Undo','Inspect Frame','Copy Frame']

   obar->NewItem, PARENT='Edit.Undo', ['Previous','All'], ACCELERATOR=['Ctrl+Z','']

   obar->NewItem, PARENT='Edit.Copy Frame', ['Bitmap','Vector']

   ;; ...Tools menu

   case strcmp(!version.os_family, 'Windows', /FOLD_CASE) of
      0: begin
         obar->NewItem, PARENT='Tools', SEPARATOR=[0,1,1,0], $
              ['Time Animation','Export Data...','Set Cumulative...']
      end
      1: begin
         obar->NewItem, PARENT='Tools', SEPARATOR=[0,1,1,1,0], $
              ['Time Animation','Clipboard Viewer','Export Data...', $
               'Set Cumulative...']
      end
   endcase

   ;; ...Window menu

   obar->NewItem, PARENT='Window', ['Update','Toolbars'], MENU=[0,1], $
        ACCELERATOR=['F5','']

   obar->NewItem, PARENT='Window.Toolbars', /CHECKED_MENU, $
        ['Status Bar','Slider Bar','Play Bar','Delay Bar','Range Bar']

   ;; ...Help menu

   obar->NewItem, PARENT='Help', ['About']

end


; MGH_Player::Display
;
pro MGH_Player::Display, position

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; This method can assume that position will always be a
   ;; defined scalar integer, but may be negative--this will
   ;; occur if the number of frames is 0.

   if position ge 0 then begin

      self->AssembleFrame, position

      self->Draw

      self.animator->GetProperty, SLAVE=slave

      if slave then begin
         self.animator->SetProperty, POSITION=position
         self.animator->UpdateSliderBar
      endif

   end

end

; MGH_Player::EventMenuBar
;
function MGH_Player::EventMenuBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.value of

      'FILE.OPEN': begin
         filename = dialog_pickfile(/READ, FILTER='*.idl_animation')
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            self->GetProperty, ANIMATION=animation
            obj_destroy, animation
            self->SetProperty, ANIMATION=mgh_var_restore(filename, /RELAX)
            self->Update
         endif
         return, 0
      end

      'FILE.SAVE': begin
         self->GetProperty, ANIMATION=animation, GRAPHICS_TREE=graphics_tree
         case obj_valid(graphics_tree) of
            0B: name = ''
            1B: graphics_tree->GetProperty, NAME=name
         endcase
         default_file = strlen(name) gt 0 ? name+'.idl_animation' : ''
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*.idl_animation')
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            animation->Save, filename
         endif
         return, 0
      end

      'FILE.CLEAR': begin
         self->GetProperty, ANIMATION=animation
         obj_destroy, animation
         self->SetProperty, ANIMATION=obj_new()
         self->Update
         return, 0
      end

      'FILE.EXPORT ANIMATION.AVI': begin
         self->GetProperty, GRAPHICS_TREE=graphics_tree
         if obj_valid(graphics_tree) then begin
            graphics_tree->GetProperty, NAME=name
            ext = '.avi'
            case strlen(name) gt 0 of
               0: default_file = ''
               else: default_file = mgh_str_vanilla(name)+ext
            endcase
            filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
            if strlen(filename) gt 0 then begin
               if !mgh_prefs.sticky then begin
                  dir = file_dirname(filename)
                  if strlen(dir) gt 0 then begin
                     cd, CURRENT=old_dir
                     if dir ne old_dir then begin
                        message, /INFORM, 'Changing to directory '+dir
                        cd, dir
                     endif
                  endif
               endif
               self->WriteAnimationToAVIFile, filename
            endif
         endif
         return, 0
      end

      'FILE.EXPORT ANIMATION.FLC': begin
         self->GetProperty, GRAPHICS_TREE=graphics_tree
         if obj_valid(graphics_tree) then begin
            graphics_tree->GetProperty, NAME=name
            ext = '.flc'
            case strlen(name) gt 0 of
               0: default_file = ''
               else: default_file = mgh_str_vanilla(name)+ext
            endcase
            filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
            if strlen(filename) gt 0 then begin
               widget_control, HOURGLASS=1
               if !mgh_prefs.sticky then begin
                  dir = file_dirname(filename)
                  if strlen(dir) gt 0 then begin
                     cd, CURRENT=old_dir
                     if dir ne old_dir then begin
                        print, FORMAT='(%"%s: changing to directory %s)")', $
                               mgh_obj_string(self), dir
                        cd, dir
                     endif
                  endif
               endif
               self->WriteAnimationToMovieFile, filename, TYPE='FLC'
            endif
         endif
         return, 0
      end

      'FILE.EXPORT ANIMATION.MJ2': begin
         self->GetProperty, GRAPHICS_TREE=graphics_tree
         if obj_valid(graphics_tree) then begin
            graphics_tree->GetProperty, NAME=name
            ext = '.mj2'
            case strlen(name) gt 0 of
               0: default_file = ''
               else: default_file = mgh_str_vanilla(name)+ext
            endcase
            filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
            if strlen(filename) gt 0 then begin
               widget_control, HOURGLASS=1
               if !mgh_prefs.sticky then begin
                  dir = file_dirname(filename)
                  if strlen(dir) gt 0 then begin
                     cd, CURRENT=old_dir
                     if dir ne old_dir then begin
                        print, FORMAT='(%"%s: changing to directory %s)")', $
                               mgh_obj_string(self), dir
                        cd, dir
                     endif
                  endif
               endif
               self->WriteAnimationToMJ2000File, filename
            endif
         endif
         return, 0
      end

      'FILE.EXPORT ANIMATION.MJ2 (LOSSLESS)': begin
         self->GetProperty, GRAPHICS_TREE=graphics_tree
         if obj_valid(graphics_tree) then begin
            graphics_tree->GetProperty, NAME=name
            ext = '.mj2'
            case strlen(name) gt 0 of
               0: default_file = ''
               else: default_file = mgh_str_vanilla(name)+ext
            endcase
            filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
            if strlen(filename) gt 0 then begin
               widget_control, HOURGLASS=1
               if !mgh_prefs.sticky then begin
                  dir = file_dirname(filename)
                  if strlen(dir) gt 0 then begin
                     cd, CURRENT=old_dir
                     if dir ne old_dir then begin
                        print, FORMAT='(%"%s: changing to directory %s)")', $
                               mgh_obj_string(self), dir
                        cd, dir
                     endif
                  endif
               endif
               self->WriteAnimationToMJ2000File, filename, /LOSSLESS
            endif
         endif
         return, 0
      end

      'FILE.EXPORT ANIMATION.MPEG': begin
         self->GetProperty, GRAPHICS_TREE=graphics_tree
         if obj_valid(graphics_tree) then begin
            graphics_tree->GetProperty, NAME=name
            ext = '.mpg'
            case strlen(name) gt 0 of
               0: default_file = ''
               else: default_file = mgh_str_vanilla(name)+ext
            endcase
            filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
            if strlen(filename) gt 0 then begin
               widget_control, HOURGLASS=1
               if !mgh_prefs.sticky then begin
                  dir = file_dirname(filename)
                  if strlen(dir) gt 0 then begin
                     cd, CURRENT=old_dir
                     if dir ne old_dir then begin
                        print, FORMAT='(%"%s: changing to directory %s)")', $
                               mgh_obj_string(self), dir
                        cd, dir
                     endif
                  endif
               endif
               self->WriteAnimationToMPEGFile, filename
            endif
         endif
         return, 0
      end

      'FILE.EXPORT ANIMATION.PDF': begin
         self->GetProperty, GRAPHICS_TREE=graphics_tree
         if obj_valid(graphics_tree) then begin
            graphics_tree->GetProperty, NAME=name
            ext = '.pdf'
            case strlen(name) gt 0 of
               0: default_file = ''
               else: default_file = mgh_str_vanilla(name)+ext
            endcase
            filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
            if strlen(filename) gt 0 then begin
               widget_control, HOURGLASS=1
               if !mgh_prefs.sticky then begin
                  dir = file_dirname(filename)
                  if strlen(dir) gt 0 then begin
                     cd, CURRENT=old_dir
                     if dir ne old_dir then begin
                        print, FORMAT='(%"%s: changing to directory %s)")', $
                               mgh_obj_string(self), dir
                        cd, dir
                     endif
                  endif
               endif
               self->WriteAnimationToMovieFile, filename, TYPE='PDF'
            endif
         endif
         return, 0
      end

      'FILE.EXPORT ANIMATION.TIFF': begin
         self->GetProperty, GRAPHICS_TREE=graphics_tree
         if obj_valid(graphics_tree) then begin
            graphics_tree->GetProperty, NAME=name
            ext = '.tif'
            case strlen(name) gt 0 of
               0: default_file = ''
               else: default_file = mgh_str_vanilla(name)+ext
            endcase
            filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
            if strlen(filename) gt 0 then begin
               widget_control, HOURGLASS=1
               if !mgh_prefs.sticky then begin
                  dir = file_dirname(filename)
                  if strlen(dir) gt 0 then begin
                     cd, CURRENT=old_dir
                     if dir ne old_dir then begin
                        print, FORMAT='(%"%s: changing to directory %s)")', $
                               mgh_obj_string(self), dir
                        cd, dir
                     endif
                  endif
               endif
               self->WriteAnimationToMovieFile, filename, TYPE='TIFF'
            endif
         endif
         return, 0
      end

      'FILE.EXPORT ANIMATION.ZIP': begin
         self->GetProperty, GRAPHICS_TREE=graphics_tree
         if obj_valid(graphics_tree) then begin
            graphics_tree->GetProperty, NAME=name
            ext = '.zip'
            case strlen(name) gt 0 of
               0: default_file = ''
               else: default_file = mgh_str_vanilla(name)+ext
            endcase
            filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
            if strlen(filename) gt 0 then begin
               widget_control, HOURGLASS=1
               if !mgh_prefs.sticky then begin
                  dir = file_dirname(filename)
                  if strlen(dir) gt 0 then begin
                     cd, CURRENT=old_dir
                     if dir ne old_dir then begin
                        print, FORMAT='(%"%s: changing to directory %s)")', $
                               mgh_obj_string(self), dir
                        cd, dir
                     endif
                  endif
               endif
               self->WriteAnimationToMovieFile, filename, TYPE='ZIP'
            endif
         endif
         return, 0
      end

      'FILE.EXPORT FRAME.EPS': begin
         self->GetProperty, GRAPHICS_TREE=graphics_tree
         graphics_tree->GetProperty, NAME=name
         ext = '.eps'
         case strlen(name) gt 0 of
            0: default_file = ''
            else: default_file = mgh_str_vanilla(name)+ext
         endcase
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            if !mgh_prefs.sticky then begin
               dir = file_dirname(filename)
               if strlen(dir) gt 0 then begin
                  cd, CURRENT=old_dir
                  if dir ne old_dir then begin
                     print, FORMAT='(%"%s: changing to directory %s)")', $
                            mgh_obj_string(self), dir
                     cd, dir
                  endif
               endif
            endif
            self->WritePictureToGraphicsFile, filename, /POSTSCRIPT, /VECTOR
         endif
      end

      'FILE.EXPORT FRAME.WMF': begin
         ;; This option provides for output in system-native vector
         ;; format.  It is applicable only on Windows and Macintosh
         ;; platforms and has been implemented & tested only for
         ;; Windows.
         self->GetProperty, GRAPHICS_TREE=graphics_tree
         graphics_tree->GetProperty, NAME=name
         ext = '.wmf'
         case strlen(name) gt 0 of
            0: default_file = ''
            else: default_file = mgh_str_vanilla(name)+ext
         endcase
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            if !mgh_prefs.sticky then begin
               dir = file_dirname(filename)
               if strlen(dir) gt 0 then begin
                  cd, CURRENT=old_dir
                  if dir ne old_dir then begin
                     print, FORMAT='(%"%s: changing to directory %s)")', $
                            mgh_obj_string(self), dir
                     cd, dir
                  endif
               endif
            endif
            self->WritePictureToGraphicsFile, filename, /VECTOR
         endif
      end

      'FILE.EXPORT FRAME.JPEG': begin
         self->GetProperty, GRAPHICS_TREE=graphics_tree
         graphics_tree->GetProperty, NAME=name
         ext = '.jpg'
         case strlen(name) gt 0 of
            0: default_file = ''
            else: default_file = mgh_str_vanilla(name)+ext
         endcase
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            if !mgh_prefs.sticky then begin
               dir = file_dirname(filename)
               if strlen(dir) gt 0 then begin
                  cd, CURRENT=old_dir
                  if dir ne old_dir then begin
                     print, FORMAT='(%"%s: changing to directory %s)")', $
                            mgh_obj_string(self), dir
                     cd, dir
                  endif
               endif
            endif
            self->WritePictureToImageFile, /JPEG, filename
         endif
      end

      'FILE.EXPORT FRAME.PNG': begin
         self->GetProperty, GRAPHICS_TREE=graphics_tree
         graphics_tree->GetProperty, NAME=name
         ext = '.png'
         case strlen(name) gt 0 of
            0: default_file = ''
            else: default_file = mgh_str_vanilla(name)+ext
         endcase
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            if !mgh_prefs.sticky then begin
               dir = file_dirname(filename)
               if strlen(dir) gt 0 then begin
                  cd, CURRENT=old_dir
                  if dir ne old_dir then begin
                     message, /INFORM, 'Changing to directory '+dir
                     cd, dir
                  endif
               endif
            endif
            self->WritePictureToImageFile, /PNG, filename
         endif
      end

      'FILE.EXPORT FRAME.PNG (H-R)': begin
         self->GetProperty, GRAPHICS_TREE=graphics_tree
         graphics_tree->GetProperty, NAME=name
         ext = '.png'
         case strlen(name) gt 0 of
            0: default_file = ''
            else: default_file = mgh_str_vanilla(name+' (high-res)')+ext
         endcase
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            if !mgh_prefs.sticky then begin
               dir = file_dirname(filename)
               if strlen(dir) gt 0 then begin
                  cd, CURRENT=old_dir
                  if dir ne old_dir then begin
                     print, FORMAT='(%"%s: changing to directory %s)")', $
                            mgh_obj_string(self), dir
                     cd, dir
                  endif
               endif
            endif
            self->WritePictureToImageFile, /PNG, filename, RESOLUTION=0.005
         endif
      end

      'FILE.EXPORT FRAME.PPM': begin
         self->GetProperty, GRAPHICS_TREE=graphics_tree
         graphics_tree->GetProperty, NAME=name
         ext = '.ppm'
         case strlen(name) gt 0 of
            0: default_file = ''
            else: default_file = mgh_str_vanilla(name)+ext
         endcase
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            if !mgh_prefs.sticky then begin
               dir = file_dirname(filename)
               if strlen(dir) gt 0 then begin
                  cd, CURRENT=old_dir
                  if dir ne old_dir then begin
                     print, FORMAT='(%"%s: changing to directory %s)")', $
                            mgh_obj_string(self), dir
                     cd, dir
                  endif
               endif
            endif
            self->WritePictureToImageFile, /PPM, filename
         endif
      end

      'FILE.EXPORT FRAME.VRML': begin
         self->GetProperty, GRAPHICS_TREE=graphics_tree
         graphics_tree->GetProperty, NAME=name
         ext = '.wrl'
         case strlen(name) gt 0 of
            0: default_file = ''
            else: default_file = mgh_str_vanilla(name)+ext
         endcase
         filename = dialog_pickfile(/WRITE, FILE=default_file, FILTER='*'+ext)
         if strlen(filename) gt 0 then begin
            widget_control, HOURGLASS=1
            if !mgh_prefs.sticky then begin
               dir = file_dirname(filename)
               if strlen(dir) gt 0 then begin
                  cd, CURRENT=old_dir
                  if dir ne old_dir then begin
                     print, FORMAT='(%"%s: changing to directory %s)")', $
                            mgh_obj_string(self), dir
                     cd, dir
                  endif
               endif
            endif
            self->WritePictureToVRML, filename
         endif
      end

      'FILE.PRINT FRAME.BITMAP': begin
         if mgh_printer(/SETUP) then begin
            widget_control, HOURGLASS=1
            self->WritePictureToPrinter, /BANNER, PRINTER=mgh_printer()
         endif
         return, 0
      end

      'FILE.PRINT FRAME.VECTOR': begin
         if mgh_printer(/SETUP) then begin
            widget_control, HOURGLASS=1
            self->WritePictureToPrinter, /BANNER, PRINTER=mgh_printer(), /VECTOR
         endif
         return, 0
      end

      'FILE.SLAVE': begin
         self->GetProperty, SLAVE=slave
         self->SetProperty, SLAVE=(~ slave)
         self->Update
         return, 0
      end

      'EDIT.UNDO.PREVIOUS': begin
         self->Undo
         return, 0
      end

      'EDIT.UNDO.ALL': begin
         self->Undo, /ALL
         return, 0
      end

      'EDIT.INSPECT FRAME': begin
         picture = self->ExportFrame()
         case obj_valid(picture) of
            0: begin
               message, /INFORM, 'Method ExportFrame produced an invalid object'
            end
            1: begin
               self->GetProperty, MOUSE_ACTION=mouse_action
               mgh_new, 'MGH_Window', picture, VISIBLE=0, $
                        MOUSE_ACTION=mouse_action, RESULT=owin
               owin->Align, RELATIVE=self
               owin->SetProperty, /VISIBLE
            end
         endcase
         return, 0
      end

      'EDIT.COPY FRAME.BITMAP': begin
         widget_control, HOURGLASS=1
         self->WritePictureToClipboard
      end

      'EDIT.COPY FRAME.VECTOR': begin
         widget_control, HOURGLASS=1
         self->WritePictureToClipboard, /VECTOR, RESOLUTION=[0.015,0.015]
      end

      'FILE.CLOSE': begin
         self->Kill
         return,1
      end

      'TOOLS.CLIPBOARD VIEWER': begin
         spawn, /NOSHELL, /NOWAIT, 'clipbrd.exe'
         return, 0
      end

      'TOOLS.TIME ANIMATION': begin
         self.animator->TimeFrames
      end

      'TOOLS.EXPORT DATA': begin
         self->ExportData, values, labels
         ogui = obj_new('MGH_GUI_Export', values, labels, /BLOCK, $
                        /FLOATING, GROUP_LEADER=self.base)
         ogui->Manage
         obj_destroy, ogui
         return, 0
      end

      'TOOLS.SET CUMULATIVE': begin
         mgh_new, 'MGH_GUI_SetArray', CAPTION='Cumulative', CLIENT=self, $
                  /FLOATING, GROUP_LEADER=self.base, /IMMEDIATE, /INTEGER, $
                  N_ELEMENTS=1, PROPERTY_NAME='CUMULATIVE'
         return, 0
      end

      'WINDOW.UPDATE': begin
         self->Update
         return, 0
      end

      'WINDOW.TOOLBARS.STATUS BAR': begin
         self->BuildStatusBar
         self->UpdateStatusBar
         self->UpdateStatusContext
         self->UpdateMenuBar
         return, 0
      end

      'WINDOW.TOOLBARS.SLIDER BAR': begin
         self.animator->BuildSliderBar
         self.animator->UpdateSliderBar
         self.animator->UpdateSliderContext
         self->UpdateMenuBar
         return, 0
      end

      'WINDOW.TOOLBARS.PLAY BAR': begin
         self.animator->BuildPlayBar
         self.animator->UpdatePlayBar
         self.animator->UpdatePlayContext
         self->UpdateMenuBar
         return, 0
      end

      'WINDOW.TOOLBARS.DELAY BAR': begin
         self.animator->BuildDelayBar
         self.animator->UpdateDelayBar
         self.animator->UpdateDelayContext
         self->UpdateMenuBar
         return, 0
      end

      'WINDOW.TOOLBARS.RANGE BAR': begin
         self.animator->BuildRangeBar
         self.animator->UpdateRangeBar
         self.animator->UpdateRangeContext
         self->UpdateMenuBar
         return, 0
      end

      'HELP.ABOUT': begin
         self->About
         return, 0
      end

      else: return, self->EventUnexpected(event)

   endcase

end

; MGH_Player::ExportData
;
pro MGH_Player::ExportData, values, labels

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   self->MGH_Window::ExportData, values, labels

   self->GetProperty, ANIMATION=animation

   labels = [labels, 'Animation']
   values = [values, ptr_new(animation)]

end

; MGH_Player::ExportFrame
;
function MGH_Player::ExportFrame, NAME=name

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   if ~ obj_valid(self.animation) then return, -1

   self->GetProperty, GRAPHICS_TREE=graphics_tree

   self.animator->GetProperty, POSITION=position

   if n_elements(name) eq 0 then begin
      graphics_tree->Getproperty, NAME=name
      name = name + ' frame ' + strtrim(position,2)
   endif

   self->AssembleFrame, position

   result = mgh_obj_clone(graphics_tree)

   result->SetProperty, NAME=name

   return, result

end

; MGH_Player::Resize
;
pro MGH_Player::Resize, x, y

   compile_opt DEFINT32
   compile_opt STRICTARR

   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->GetProperty, GEOMETRY=geom_base

   if obj_valid(self.animator) then begin
      self.animator->GetProperty, GEOMETRY=geom_animator
      y = y - geom_animator.scr_ysize - geom_base.space
   endif

   self->MGH_Window::Resize, x, y

end

; MGH_Player::Update
;
pro MGH_Player::Update

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Window::Update

   self.animator->Update

end

; MGH_Player::UpdateMenuBar
;
pro MGH_Player::UpdateMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   obar = mgh_widget_self(self.menu_bar)

   if obj_valid(obar) then begin

      self->GetProperty, $
           GRAPHICS_TREE=graphics_tree, N_FRAMES=n_frames, $
           EXPAND_STATUS_BAR=expand_status_bar, UNDO_COUNT=undo_count

      self.animator->GetProperty, $
           SLAVE=slave, $
           EXPAND_DELAY_BAR=expand_delay_bar, $
           EXPAND_PLAY_BAR=expand_play_bar, $
           EXPAND_RANGE_BAR=expand_range_bar, $
           EXPAND_SLIDER_BAR=expand_slider_bar

      valid = obj_valid(graphics_tree)

      multiple = 0B
      saveable = 0B
      if valid then $
           self.animation->GetProperty, MULTIPLE=multiple, SAVEABLE=saveable

      ;; Set menu state

      obar->SetItem, 'File.Save', SENSITIVE=saveable
      obar->SetItem, 'File.Clear', SENSITIVE=valid
      obar->SetItem, 'File.Export Animation', SENSITIVE=valid and (n_frames gt 0)
      obar->SetItem, 'File.Export Frame', SENSITIVE=valid and (n_frames gt 0)
      obar->SetItem, 'File.Print Frame', SENSITIVE=valid and (n_frames gt 0)
      obar->SetItem, 'File.Slave', SET_BUTTON=slave

      obar->SetItem, 'Edit.Undo', SENSITIVE=(undo_count gt 0)
      obar->SetItem, 'Edit.Inspect Frame', SENSITIVE=(n_frames gt 0)
      obar->SetItem, 'Edit.Copy Frame', SENSITIVE=(n_frames gt 0)

      obar->SetItem, 'Tools.Time Animation', SENSITIVE=(n_frames gt 1)
      obar->SetItem, 'Tools.Set Cumulative', SENSITIVE=multiple

      obar->SetItem, 'Window.Toolbars.Status Bar', $
           SET_BUTTON=expand_status_bar
      obar->SetItem, 'Window.Toolbars.Slider Bar', $
           SENSITIVE=(~ slave), SET_BUTTON=expand_slider_bar
      obar->SetItem, 'Window.Toolbars.Play Bar', $
           SENSITIVE=(~ slave), SET_BUTTON=expand_play_bar
      obar->SetItem, 'Window.Toolbars.Delay Bar', $
           SENSITIVE=(~ slave), SET_BUTTON=expand_delay_bar
      obar->SetItem, 'Window.Toolbars.Range Bar', $
           SENSITIVE=(~ slave), SET_BUTTON=expand_range_bar

   endif

end

; MGH_Player::WriteAnimationToAVIFile
;
pro MGH_Player::WriteAnimationToAVIFile, file, $
     DISPLAY=display, RESOLUTION=resolution, RANGE=range, STRIDE=stride

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if ~ file_test(mgh_avi_dll()) then $
        message, 'AVI DLL is not available'

   if n_elements(display) eq 0 then display = 1B

   self.animation->GetProperty, $
        GRAPHICS_TREE=graphics_tree, N_FRAMES=n_frames

   self.animator->GetPlayBack, $
        RANGE=play_range, USE_RANGE=play_use_range

   case play_use_range of
      0: begin
         if n_elements(range) eq 0 then range = [0,n_frames-1]
         if n_elements(stride) eq 0 then stride = 1
      end
      1: begin
         if n_elements(range) eq 0 then range = play_range[0:1]
         if n_elements(stride) eq 0 then stride = play_range[2]
      end
   endcase

   self.window->GetProperty, UNITS=units, DIMENSIONS=dimensions

   if n_elements(resolution) eq 0 then begin
      self->GetProperty, BITMAP_RESOLUTION=resolution
      if ~ finite(resolution) then $
           self.window->GetProperty, RESOLUTION=resolution
   endif

   buff = mgh_new_buffer('IDLgrBuffer', UNITS=units, $
                         DIMENSIONS=dimensions, MULTIPLE=8, RESOLUTION=resolution)

   n_written = 1 + (range[1]-range[0])/stride

   for pos=range[0],range[1],stride do begin

      self->AssembleFrame, pos

      if display then self.window->Draw, graphics_tree

      buff->Draw, graphics_tree
      buff->GetProperty, IMAGE_DATA=snapshot

      if pos eq range[0] then begin

         ;; Determine dimensions of image data. The snapshot has been
         ;; produced from a true-colour buffer, so we know it is
         ;; dimensioned [3,m,n]

         dim = (size(snapshot, /DIMENSIONS))[1:2]

         fmt ='(%"Writing %d frames of %d x %d to AVI file %s")'
         message, /INFORM, string(n_written, dim, file, FORMAT=fmt)

         ;; Get default AVI option from !mgh_prefs system variable

         defsysv, '!mgh_prefs', EXISTS=has_mgh_prefs
         if has_mgh_prefs then begin
            if mgh_struct_has_tag(!mgh_prefs, 'avi_options') then $
                 avi_options = !mgh_prefs.avi_options
         endif

         avi = obj_new('MGHaviWriteFile', file, dim, /TRUE_COLOR, $
                       _STRICT_EXTRA=avi_options)

      endif

      avi->Put, snapshot

   endfor

   obj_destroy, [avi,buff]

   self->Update

   fmt ='(%"Finished saving AVI file %s")'
   message, /INFORM, string(file, FORMAT=fmt)

end


; MGH_Player::WriteAnimationToMovieFile
;
pro MGH_Player::WriteAnimationToMovieFile, file, $
     DISPLAY=display, RESOLUTION=resolution, RANGE=range, STRIDE=stride, TYPE=type

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE


   if n_elements(type) eq 0 then type = 'FLC'

   type = strupcase(type)

   if n_elements(display) eq 0 then display = 1

   self.animation->GetProperty, $
        GRAPHICS_TREE=graphics_tree, N_FRAMES=n_frames

   self.animator->GetPlayBack, $
        RANGE=play_range, USE_RANGE=play_use_range

   case play_use_range of
      0: begin
         if n_elements(range) eq 0 then range = [0,n_frames-1]
         if n_elements(stride) eq 0 then stride = 1
      end
      1: begin
         if n_elements(range) eq 0 then range = play_range[0:1]
         if n_elements(stride) eq 0 then stride = play_range[2]
      end
   endcase

   self.window->GetProperty, UNITS=units, DIMENSIONS=dimensions

   if n_elements(resolution) eq 0 then begin
      self->GetProperty, BITMAP_RESOLUTION=resolution
      if ~ finite(resolution) then $
           self.window->GetProperty, RESOLUTION=resolution
   endif

   buff = mgh_new_buffer('IDLgrBuffer', UNITS=units, $
                         DIMENSIONS=dimensions, MULTIPLE=4, RESOLUTION=resolution)

   n_written = 1 + (range[1]-range[0])/stride

   for pos=range[0],range[1],stride do begin

      self->AssembleFrame, pos

      if display then self.window->Draw, graphics_tree

      buff->Draw, graphics_tree
      buff->GetProperty, IMAGE_DATA=snapshot

      if pos eq range[0] then begin

         dim = size(snapshot, /DIMENSIONS)

         fmt ='(%"Writing %d frames of %d x %d to %s file %s")'
         message, /INFORM, string(n_written, dim[1:2], type, file, FORMAT=fmt)

         omovie = obj_new( 'MGHgrMovieFile', FILE=File, FORMAT=type)

      endif

      omovie->Put, reverse(snapshot,3)

   endfor

   obj_destroy, buff

   self->Update

   fmt ='(%"Saving %s file %s")'
   message, /INFORM, string(type, file, FORMAT=fmt)

   omovie->Save

   fmt ='(%"Finished saving %s file %s")'
   message, /INFORM, string(type, file, FORMAT=fmt)

   obj_destroy, omovie

end

; MGH_Player::WriteAnimationToMJ2000File
;
pro MGH_Player::WriteAnimationToMJ2000File, file, $
     DISPLAY=display, LOSSLESS=lossless, RESOLUTION=resolution, $
     RANGE=range, STRIDE=stride

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(display) eq 0 then display = 1B

   self.animation->GetProperty, $
        GRAPHICS_TREE=graphics_tree, N_FRAMES=n_frames

   self.animator->GetPlayBack, $
        RANGE=play_range, USE_RANGE=play_use_range

   case play_use_range of
      0: begin
         if n_elements(range) eq 0 then range = [0,n_frames-1]
         if n_elements(stride) eq 0 then stride = 1
      end
      1: begin
         if n_elements(range) eq 0 then range = play_range[0:1]
         if n_elements(stride) eq 0 then stride = play_range[2]
      end
   endcase

   self.window->GetProperty, UNITS=units, DIMENSIONS=dimensions

   if n_elements(resolution) eq 0 then begin
      self->GetProperty, BITMAP_RESOLUTION=resolution
      if ~ finite(resolution) then $
           self.window->GetProperty, RESOLUTION=resolution
   endif

   buff = mgh_new_buffer('IDLgrBuffer', UNITS=units, $
                         DIMENSIONS=dimensions, MULTIPLE=4, RESOLUTION=resolution)

   n_written = 1 + (range[1]-range[0])/stride

   for pos=range[0],range[1],stride do begin

      self->AssembleFrame, pos

      if display then self.window->Draw, graphics_tree

      buff->Draw, graphics_tree
      buff->GetProperty, IMAGE_DATA=snapshot

;     snapshot = reverse(snapshot, 3, /OVERWRITE)

      if pos eq range[0] then begin

         dim =(size(snapshot, /DIMENSIONS))[1:2]

         fmt ='(%"Writing %d frames of %d x %d to Motion JPEG2000 file %s")'
         message, /INFORM, string(n_written, dim, file, FORMAT=fmt)

         ;; The BIT_RATE parameter specifies the compression ratio in
         ;; bits per pixel per component. The FRAME_PERIOD specifies
         ;; the frame duration in ticks, where the duration of a tick
         ;; is specified by the TIMESCALE property and has a default
         ;; of 1/30000 s. The REVERSIBLE keyword specifies lossless
         ;; compression.

         case keyword_set(lossless) of
            0: omovie = obj_new('IDLffMJPEG2000', file, /WRITE, FRAME_PERIOD=2000, $
                                N_LAYERS=2, BIT_RATE=[0.05,0.5])
            1: omovie = obj_new('IDLffMJPEG2000', file, /WRITE, FRAME_PERIOD=2000, $
                                /REVERSIBLE)
         endcase
      endif

      ok = omovie->SetData(snapshot)

      if ~ok then message, 'File writing failed'

   endfor

   obj_destroy, buff

   self->Update

   fmt ='(%"Saving Motion JPEG2000 file %s")'
   message, /INFORM, string(file, FORMAT=fmt)

   ok = omovie->Commit(10000)

   case ok of
      0: fmt ='(%"Motion JPEG2000 file %s failed")'
      1: fmt ='(%"Motion JPEG2000 file %s saved successfully")'
      2: fmt ='(%"Motion JPEG2000 file %s warning: may be incomplete")'
   endcase
   message, INFORM=(ok gt 0), string(file, FORMAT=fmt)

   obj_destroy, omovie

end

; MGH_Player::WriteAnimationToMPEGFile
;
pro MGH_Player::WriteAnimationToMPEGFile, file, $
     DISPLAY=display, RESOLUTION=resolution, RANGE=range, STRIDE=stride

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(display) eq 0 then display = 1B

   self.animation->GetProperty, $
        GRAPHICS_TREE=graphics_tree, N_FRAMES=n_frames

   self.animator->GetPlayBack, $
        RANGE=play_range, USE_RANGE=play_use_range

   case play_use_range of
      0: begin
         if n_elements(range) eq 0 then range = [0,n_frames-1]
         if n_elements(stride) eq 0 then stride = 1
      end
      1: begin
         if n_elements(range) eq 0 then range = play_range[0:1]
         if n_elements(stride) eq 0 then stride = play_range[2]
      end
   endcase

   self.window->GetProperty, UNITS=units, DIMENSIONS=dimensions

   if n_elements(resolution) eq 0 then begin
      self->GetProperty, BITMAP_RESOLUTION=resolution
      if ~ finite(resolution) then $
           self.window->GetProperty, RESOLUTION=resolution
   endif

   buff = mgh_new_buffer('IDLgrBuffer', UNITS=units, $
                         DIMENSIONS=dimensions, MULTIPLE=4, RESOLUTION=resolution)

   n_written = 1 + (range[1]-range[0])/stride

   for pos=range[0],range[1],stride do begin

      self->AssembleFrame, pos

      if display then self.window->Draw, graphics_tree

      buff->Draw, graphics_tree
      buff->GetProperty, IMAGE_DATA=snapshot

      snapshot = reverse(snapshot, 3, /OVERWRITE)

      if pos eq range[0] then begin

         dim = size(snapshot, /DIMENSIONS)
         dim = 2*(dim[1:2]/2)

         print, self, ': Writing '+strtrim(n_written,2)+' frames of '+ $
                strtrim(dim[0],2)+' x '+strtrim(dim[1],2)+' to MPEG file '+file

         omovie = obj_new('IDLgrMPEG', FILENAME=file, QUALITY=100, FORMAT=0)

      endif

      omovie->Put, snapshot[*,0:dim[0]-1,0:dim[1]-1]

   endfor

   obj_destroy, buff

   self->Update

   print, self, ': Saving MPEG file '+file+'...'

   omovie->Save

   print, self, ': Finished saving MPEG file '+file

   obj_destroy, omovie

end



pro MGH_Player__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Player, inherits MGH_Window, animator: obj_new(), $
                 animation: obj_new(), cumulative: 0}

end


