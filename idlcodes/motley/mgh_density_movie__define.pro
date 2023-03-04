;+
; CLASS NAME:
;   MGH_Density_Movie
;
; PURPOSE:
;   This class displays a 3-D numeric array as a sequence of colour
;   density plots in a window with axes and a colour scale. The class
;   inherits from MGH_Player.
;
; OBJECT CREATION SEQUENCE
;   mgh_new, 'MGH_Density_Movie', values
;
; INPUTS:
;   values (input, numeric 3D array
;     Data to be plotted
;
; KEYWORDS:
;   SLICE_DIMENSION
;     The (one-based) dimension of the array to be animated.
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
;   Mark Hadfield, 1999-05:
;     Written as MGHgrDensityMovie.
;   Mark Hadfield, 2000-08:
;     Renamed.
;   Mark Hadfield, 2000-12:
;     Miscellaneous enhancements. DIMENSION now zero-based.
;   Mark Hadfield, 2001-06:
;     Now based on MGH_Player.
;   Mark Hadfield, 2001-10:
;     - Upgraded keyword inheritance to IDL 5.5.
;     - Added GRAPH_CLASS keyword.
;   Mark Hadfield, 2002-11:
;     - Upgraded to IDL 5.6.
;   Mark Hadfield, 2003-07:
;     - Upgraded to IDL 6.0.
;     - SLICE_DIMENSION now one-based.
;-

; MGH_Density_Movie::Init

function MGH_Density_Movie::Init, values, datax, datay, $
     BAR_VISIBLE=bar_visible, DATA_VALUES=data_values, $
     BYTE_RANGE=byte_range, DATA_RANGE=data_range, $
     EXAMPLE=example, $
     GRAPH_CLASS=graph_class, GRAPH_PROPERTIES=graph_properties, $
     IMPLEMENTATION=implementation, PALETTE_PROPERTIES=palette_properties, $
     SLICE_DIMENSION=slice_dimension, $
     SLICE_RANGE=slice_range, SLICE_STRIDE=slice_stride, $
     STYLE=style, TITLE=title, $
     XAXIS_PROPERTIES=xaxis_properties, $
     YAXIS_PROPERTIES=yaxis_properties, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; The data

   if keyword_set(example) then $
        data_values = transpose(mgh_flow(), [1,2,0])

   if n_elements(data_values) eq 0 && n_elements(values) gt 0 then $
        data_values = values

   ;; Keyword defaults

   if n_elements(bar_visible) eq 0 then bar_visible = 1

   if n_elements(graph_class) eq 0 then graph_class = 'MGHgrGraph2D'

   if n_elements(style) eq 0 then style = 1

   self.implementation = $
        n_elements(implementation) gt 0 ? implementation : 0

   if n_elements(data_range) eq 0 then begin
      data_range = mgh_minmax(data_values, /NAN)
      if data_range[0] eq data_range[1] then data_range += [-1,1]
   endif

   n_dim = size(data_values, /N_DIMENSIONS)
   dim = size(data_values, /DIMENSIONS)

   if n_dim eq 2 then begin
      n_dim = 3
      dim = [dim, 1]
   endif

   if n_dim ne 3 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'data_values'

   if n_elements(slice_dimension) eq 0 then slice_dimension = 3
   if n_elements(slice_stride) eq 0 then slice_stride = 1

   case slice_dimension of
      1: begin
         numx = dim[1]
         numy = dim[2]
         nums = dim[0]
      end
      2: begin
         numx = dim[0]
         numy = dim[2]
         nums = dim[1]
      end
      3: begin
         numx = dim[0]
         numy = dim[1]
         nums = dim[2]
      end
   endcase

   if n_elements(slice_range) eq 0 then slice_range = [0,nums-1]

   ;; Set up X and Y position arrays

   case style of
      0: begin
         if n_elements(datax) eq 0 then datax = -0.5+findgen(numx+1)
         if n_elements(datay) eq 0 then datay = -0.5+findgen(numy+1)
      end
      1: begin
         if n_elements(datax) eq 0 then datax = findgen(numx)
         if n_elements(datay) eq 0 then datay = findgen(numy)
      end
   endcase

   ;; Create the base graph

   xmargin = keyword_set(bar_visible) ? [0.375,0.400] : [0.375,0.15]

   ograph = obj_new(graph_class, NAME='3D array animation', XMaRGIN=xmargin, $
                    _STRICT_EXTRA=graph_properties)

   ograph->NewFont, SIZE=10
   ograph->NewFont, SIZE=9

   ograph->NewAxis, 0, NAME='X axis', RANGE=mgh_minmax(datax), /EXACT, /EXTEND, $
        _STRICT_EXTRA=xaxis_properties
   ograph->NewAxis, 1, NAME='Y axis', RANGE=mgh_minmax(datay), /EXACT, /EXTEND, $
        _STRICT_EXTRA=yaxis_properties

   ograph->NewPalette, mgh_get_ct('Rainbow', /SYSTEM), RESULT=palette, $
        _STRICT_EXTRA=palette_properties

   ograph->NewColorBar, FONT=ograph->GetFont(POS=1), $
        DATA_RANGE=data_range, BYTE_RANGE=byte_range, HIDE=1-bar_visible, $
        PALETTE=palette, RESULT=obar
   self.bar = obar

   case self.implementation of
      0: begin
         ;; An implementation based on the MGHgrColorSurface class (the default)
         ograph->NewAtom, 'MGHgrDensityPlane', PLANE_CLASS='MGHgrColorSurface', $
              DATAX=datax, DATAY=datay, DATA_VALUES=fltarr(numx,numy), $
              NAME='Density plane', STYLE=style, /STORE_DATA, COLORSCALE=self.bar, RESULT=oplane
      end
      1: begin
         ;; As 0, but based on the MGHgrColorPolygon class
         ograph->NewAtom, 'MGHgrDensityPlane', PLANE_CLASS='MGHgrColorPolygon', $
              DATAX=datax, DATAY=datay, DATA_VALUES=fltarr(numx,numy), $
              NAME='Density plane', STYLE=style, /STORE_DATA, COLORSCALE=self.bar, RESULT=oplane
      end
      2: begin
         ;; An implementation in which data are regridded on an
         ;; IDLgrImage overlaid as a texture map on a rectangular IDLgrPolygon
         ograph->NewAtom, 'MGHgrDensityRect', $
              DATAX=datax, DATAY=datay, DATA_VALUES=fltarr(numx,numy), $
              NAME='Density plane', STYLE=style, /STORE_DATA, COLORSCALE=self.bar, RESULT=oplane
      end
      3: begin
         ;; An implementation in which data are regridded on an
         ;; naked IDLgrImage.
         ograph->NewAtom, 'MGHgrDensityRect2', $
              DATAX=datax, DATAY=datay, DATA_VALUES=fltarr(numx,numy), $
              NAME='Density plane', STYLE=style, /STORE_DATA, COLORSCALE=self.bar, RESULT=oplane
      end
      4: begin
         ;; An implementation using an IDLgrImage. It ignores non-uniform
         ;; grid spacing.
         location = [min(datax),min(datay)]
         dimensions = [max(datax),max(datay)] - location
         ograph->NewAtom, 'MGHgrDensityImage', STYLE=style, $
              DATA_VALUES=fltarr(numx,numy), LOCATION=location, DIMENSIONS=dimensions, $
              COLORSCALE=self.bar, RESULT=oplane
      end
   endcase
   self.plane = oplane

   ograph->NewTitle, '', RESULT=otitle

   ;; Create an MGH_Datamation object and load the frames into it

   oanimation = obj_new('MGHgrDatamation', GRAPHICS_TREE=ograph)

   oframe = objarr(2)

   for s=slice_range[0],slice_range[1],slice_stride do begin

      case slice_dimension of
         1: fdata = reform(data_values[s,*,*])
         2: fdata = reform(data_values[*,s,*])
         3: fdata = reform(data_values[*,*,s])
      endcase

      oframe[0] = obj_new('MGH_Command', OBJECT=self.plane, 'SetProperty', $
                          DATA_VALUES=fdata)

      if n_elements(title) gt 0 then $
           oframe[1] = obj_new('MGH_Command', OBJECT=otitle, 'SetProperty', $
                               STRINGS=title[s < n_elements(title)])

      oanimation->AddFrame , oframe

   endfor

   ;; Set up the player and return

   ok = self->MGH_Player::Init(ANIMATION=oanimation, CHANGEABLE=0, $
                               _STRICT_EXTRA=extra)

   if ~ ok then message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_Player'

   self->Finalize, 'MGH_Density_Movie'

   return, 1

end

; MGH_Density_Movie::GetProperty
;
pro MGH_Density_Movie::GetProperty, $
     BYTE_RANGE=byte_range, DATA_RANGE=data_range, PALETTE=palette, $
     PLANE=plane, STYLE=style, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   plane = self.plane

   self.plane->GetProperty, $
        BYTE_RANGE=byte_range, DATA_RANGE=data_range, PALETTE=palette, STYLE=style

   self->MGH_Player::GetProperty, _STRICT_EXTRA=extra

END

; MGH_Density_Movie::SetProperty
;
pro MGH_Density_Movie::SetProperty, $
     BYTE_RANGE=byte_range, DATA_RANGE=data_range, PALETTE=palette, $
     STYLE=style, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self.plane->SetProperty, $
        BYTE_RANGE=byte_range, DATA_RANGE=data_range, PALETTE=palette, STYLE=style

   if obj_valid(self.bar) then begin
      self.bar->SetProperty, $
           BYTE_RANGE=byte_range, DATA_RANGE=data_range, PALETTE=palette
   endif

   self->MGH_Player::SetProperty, _STRICT_EXTRA=extra

END

; MGH_Density_Movie::About
;
pro MGH_Density_Movie::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Player::About, lun

   self->GetProperty, PALETTE=palette, PLANE=plane

   if obj_valid(plane) then $
        printf, lun, self, ': the density-plane is ', mgh_obj_string(plane, /SHOW_NAME)

   if obj_valid(palette) then $
        printf, lun, self, ': the palette is ', mgh_obj_string(palette, /SHOW_NAME)

end

; MGH_Density_Movie::BuildMenuBar
;
; Purpose:
;   Add menus, sub-menus & menu items to the menu bar

pro MGH_Density_Movie::BuildMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Player::BuildMenuBar

   obar = mgh_widget_self(self.menu_bar)

   obar->NewItem, PARENT='Tools', SEPARATOR=[1,0,0,1], MENU=[1,0,0,0], $
        ['Data Range','Edit Palette...', $
         'View Colour Scale...','View Data Values...']

   obar->NewItem, PARENT='Tools.Data Range', ['Set...','Fit this Frame']

end


; MGH_Density_Movie::EventMenuBar
;
function MGH_Density_Movie::EventMenuBar, event

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   case event.value of

      'TOOLS.DATA RANGE.SET': begin
         mgh_new, 'MGH_GUI_SetArray', CAPTION='Range', CLIENT=self, $
                  /FLOATING, GROUP_LEADER=self.base, IMMEDIATE=0, $
                  N_ELEMENTS=2, PROPERTY_NAME='DATA_RANGE'
         return, 0
      end

      'TOOLS.DATA RANGE.FIT THIS FRAME': begin
         self->GetProperty, POSITION=position
         oframe = self.animation->GetFrame(POSITION=position)
         oframe[0]->GetProperty, KEYWORDS=keywords
         data_range = mgh_minmax(keywords.data_values, /NAN)
         if data_range[0] eq data_range[1] then data_range += [-1,1]
         self->SetProperty, DATA_RANGE=data_range
         self->Update
         return, 0
      end

      'TOOLS.EDIT PALETTE': begin
         self->GetProperty, PALETTE=palette
         mgh_new, 'MGH_GUI_Palette_Editor', palette, CLIENT=self, $
                  /FLOATING, GROUP_LEADER=self.base, /IMMEDIATE
         return, 0
      end

      'TOOLS.SET STYLE': begin
         mgh_new, 'MGH_GUI_SetList', CAPTION='Style', CLIENT=self, $
                  /FLOATING, GROUP_LEADER=self.base, IMMEDIATE=0, $
                  ITEM_STRING=['Block','Interpolated'], $
                  PROPERTY_NAME='STYLE'
         return, 0
      end

      'TOOLS.VIEW COLOUR SCALE': begin
         mgh_new, 'MGH_GUI_ColorScale', CLIENT=self, /FLOATING, GROUP_LEADER=self.base
         return, 0
      end

      'TOOLS.VIEW DATA VALUES': begin
         self->GetProperty, POSITION=position
         oframe = self.animation->GetFrame(POSITION=position)
         oframe[0]->GetProperty, KEYWORDS=keywords
         data_dims = size(keywords.data_values, /DIMENSIONS)
         xvaredit, keywords.data_values, GROUP=self.base, $
                   X_SCROLL_SIZE=(data_dims[0] < 12), $
                   Y_SCROLL_SIZE=(data_dims[1] < 30)
         return, 0
      end

      else: return, self->MGH_Player::EventMenubar(event)

   endcase

end

; MGH_Density_Movie::PickReport
;
pro MGH_Density_Movie::PickReport, pos, LUN=lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(lun) eq 0 then lun = -1

   if n_elements(pos) ne 2 then $
        message, 'Parameter POS must be a 2-element vector'

   self->GetProperty, GRAPHICS_TREE=ograph

   if ~ obj_valid(ograph) then begin
      printf, lun, FORMAT='(%"%s: no graphics tree")', mgh_obj_string(self)
      return
   endif

   printf, lun, FORMAT='(%"%s: graphics tree %s")', $
           mgh_obj_string(self), mgh_obj_string(ograph, /SHOW_NAME)

   atoms = self->Select(ograph, pos)
   valid = where(obj_valid(atoms), n_atoms)

   if n_atoms eq 0 then begin
      printf, lun, FORMAT='(%"%s: no atoms selected")', mgh_obj_string(self)
      return
   endif

   atoms = atoms[valid]

   for j=0,n_atoms-1 do begin
      atom = atoms[j]
      status = self->PickData(ograph, atom, pos, data)
      case (atom eq self.plane) of
         0: begin
            printf, lun, FORMAT='(%"%s: atom %s, success: %d, value: %f %f %f")', $
                    mgh_obj_string(self), mgh_obj_string(atom,/SHOW_NAME), $
                    status, double(data)
         end
         1: begin
            ;; If the selected atom is the density plane, report the
            ;; data value at the selected location.

            self->GetProperty, ANIMATION=animation, POSITION=position

            oframe = animation->GetFrame(POSITION=position)
            oframe[0]->GetProperty, KEYWORDS=keywords

            data_values = keywords.data_values

            ;; Locate the selection point in the index space of the
            ;; density planes' pixel vertices.  If style is 0, allow
            ;; for offset of data locations (pixel centres) and use
            ;; nearest-neighbour interpolation

            case self.implementation of
               4: begin
                  self.plane->GetProperty, $
                       LOCATION=location, DIMENSIONS=dimensions, STYLE=style
                  dimv = size(data_values, /DIMENSIONS)
                  datax = mgh_range(location[0], location[0]+dimensions[0], $
                                    N_ELEMENTS=dimv[0])
                  datay = mgh_range(location[1], location[1]+dimensions[1], $
                                    N_ELEMENTS=dimv[1])
               end
               else: $
                  self.plane->GetProperty, DATAX=datax, DATAY=datay, STYLE=style
            endcase
            xy2d = size(datax, /N_DIMENSIONS) eq 2
            case xy2d of
               0: begin
                  loc = [mgh_locate(datax, XOUT=data[0]), $
                         mgh_locate(datay, XOUT=data[1])]
               end
               1: begin
                  loc = mgh_locate2a(datax, datay, $
                                     XOUT=data[0], YOUT=data[1], $
                                     MISSING=-1)
               end
            endcase
            if style eq 0 then loc = round(loc-0.5)

            ;; Interpolate & report
            value = mgh_interpolate(data_values, loc[0], loc[1], GRID=(~ xy2d), $
                                    MISSING=!values.f_nan)
            printf, lun, FORMAT='(%"%s: atom %s, success: %d, value: %f %f %f")', $
                    mgh_obj_string(self), mgh_obj_string(atom,/SHOW_NAME), $
                    status, double(data)
            printf, lun, FORMAT='(%"%s: atom %s, index: %f %f, value: %f")', $
                    mgh_obj_string(self), mgh_obj_string(atom,/SHOW_NAME), $
                    loc[0],loc[1],value
         end
      endcase
   endfor

end

; MGH_Density_Movie__Define

pro MGH_Density_Movie__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Density_Movie, inherits MGH_Player, $
                 bar: obj_new(), plane: obj_new(), implementation: 0S}

end
