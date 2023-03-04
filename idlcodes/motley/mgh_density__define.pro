;+
; CLASS NAME:
;   MGH_Density
;
; PURPOSE:
;   This class displays a 2-D numeric array as a colour density plot
;   in a window, with axes and a colour scale. The colour scale can be
;   edited interactively. The performance of an MGH_DENSITY object
;   depends on the implementation of the density plot (keyword
;   IMPLEMENTATION).
;
; OBJECT CREATION CALLING SEQUENCE
;   mgh_new, 'MGH_Density', values[, x, y]
;
; POSITIONAL PARAMETERS:
;   values
;     A 2D array of numeric data to be plotted
;
;   x
;     Position in the x direction of the columns of data
;
;   y
;     Position in the y direction of the rows of data

;
; PROPERTIES:
;   BYTE_RANGE (Init,Get)
;     The range of byte values to which the data range is to be mapped.
;
;   DATA_RANGE (Init,Get,Set)
;     The range of data values to be mapped onto the indexed color
;     range for the density plane and the colour bar. Data values
;     outside the range are mapped to the nearest end of the range. If
;     not specified, DATA_RANGE is calculated when the density plane
;     is created,
;
;   STYLE (Init):
;     The style of the plane. Values are 0 (each data point represented
;     by a cell of uniform colour) and 1 (colours interpolated between
;     data points). Default is 0. Note that the value of this property
;     determines the dimensions that X & Y arrays (if any) must have.
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
;   Mark Hadfield, May 1999:
;       Written as MGHgrDensityPlot.
;   Mark Hadfield, May 1999:
;       Renamed MGH_Density.
;-

; ***** MGH_Density class *****

function MGH_Density::Init, values, X, Y, $
     BYTE_RANGE=byte_range, $
     CONTOUR_PROPERTIES=contour_properties, $
     DATA_RANGE=data_range, DATA_VALUES=data_values, $
     EXAMPLE=example, $
     GRAPH_PROPERTIES=graph_properties, $
     IMPLEMENTATION=implementation, $
     PALETTE_PROPERTIES=palette_properties, $
     PRESERVE_ASPECT=preserve_aspect, $
     SHOW_CONTOUR=show_contour, STYLE=style, TITLE=title, $
     XAXIS_PROPERTIES=xaxis_properties, $
     YAXIS_PROPERTIES=yaxis_properties, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   ;; Defaults

   if n_elements(style) eq 0 then style = 0

   if n_elements(show_contour) eq 0 then show_contour = 0

   self.implementation = n_elements(implementation) gt 0 ? implementation : 0B

   ;; Sort out data values

   if keyword_set(example) then data_values = mgh_dist(41)

   if n_elements(data_values) eq 0 && n_elements(values) gt 0 then $
        data_values = values

   if n_elements(data_values) eq 0 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_undefvar', 'data_values'

   if size(data_values, /N_DIMENSIONS) ne 2 then $
        message, BLOCK='mgh_mblk_motley', NAME='mgh_m_wrgnumdim', 'data_values'

   dims = size(data_values, /DIMENSIONS)

   ;; Sort out data positions

   if n_elements(x) eq 0 then x = findgen(dims[0])
   if n_elements(y) eq 0 then y = findgen(dims[1])

   vertx = mgh_stagger(x, DELTA=(style eq 0))
   verty = mgh_stagger(y, DELTA=(style eq 0))

   ;; Other defaults

   case keyword_set(preserve_aspect) of
      0: aspect = 1.0
      1: aspect = float(dims[1]+(style eq 0))/float(dims[0]+(style eq 0))
   endcase

   if n_elements(data_range) eq 0 then begin
      data_range = mgh_minmax(data_values, /NAN)
      if data_range[0] eq data_range[1] then data_range += [-1,1]
   endif

   ;; Create the figure.

   ograph = obj_new('MGHgrGraph2D', ASPECT=aspect, NAME='Density plot', $
                    XMARGIN=[0.25,0.4], _STRICT_EXTRA=graph_properties)

   ograph->GetProperty, DELTAZ=deltaz

   ograph->NewMask, RESULT=omask
   self.mask = omask

   ograph->NewFont, SIZE=10
   ograph->NewFont, SIZE=9

   ograph->NewAxis, 0, $
        RANGE=mgh_minmax(vertx), /EXACT, /EXTEND, _STRICT_EXTRA=xaxis_properties
   ograph->NewAxis, 1, $
        RANGE=mgh_minmax(verty), /EXACT, /EXTEND, _STRICT_EXTRA=yaxis_properties

   ograph->NewBackground

   ograph->NewTitle, title

   ograph->NewPalette, mgh_get_ct('Rainbow', /SYSTEM), RESULT=palette, $
        _STRICT_EXTRA=palette_properties

   ograph->NewAtom, 'IDLgrContour', RESULT=ocont, $
        GEOMZ=-deltaz, /PLANAR, DATA=data_values, GEOMX=x, GEOMY=y, $
        HIDE=(~ show_contour), COLOR=mgh_color('white'), $
        _STRICT_EXTRA=contour_properties
   self.contour = ocont

   ocont->GetProperty, C_VALUE=contour_values

   ograph->NewColorBar, $
        DATA_RANGE=data_range, PALETTE=palette, $
        SHOW_CONTOUR=show_contour, $
        CONTOUR_PROPERTIES=contour_properties, CONTOUR_VALUES=contour_values, $
        _STRICT_EXTRA=colorbar_properties, RESULT=obar
   self.bar = obar

   case self.implementation of
      0: begin
         ;; An implementation based on the MGHgrColorSurface class (the default)
         ograph->NewAtom, 'MGHgrDensityPlane', NAME='Density plane', $
              PLANE_CLASS='MGHgrColorSurface', STYLE=style, $
              DATA_VALUES=data_values, DATAX=vertx, DATAY=verty, $
              /STORE_DATA, DEPTH_OFFSET=1, ZVALUE=-5*deltaz, $
              COLORSCALE=obar, RESULT=oplane
      end
      1: begin
         ;; As 0, but based on the MGHgrColorPolygon class
         ograph->NewAtom, 'MGHgrDensityPlane', NAME='Data', $
              PLANE_CLASS='MGHgrColorPolygon', STYLE=style, $
              DATA_VALUES=data_values, DATAX=vertx, DATAY=verty, $
              /STORE_DATA, DEPTH_OFFSET=1, ZVALUE=-5*deltaz, $
              COLORSCALE=obar, RESULT=oplane
      end
      2: begin
         ;; An implementation in which data are regridded on an
         ;; IDLgrImage overlaid as a texture map on a rectangular IDLgrPolygon
         ograph->NewAtom, 'MGHgrDensityRect', NAME='Data', STYLE=style, $
              DATA_VALUES=data_values, DATAX=vertx, DATAY=verty, $
              DEPTH_OFFSET=1, ZVALUE=-5*deltaz, COLORSCALE=obar, RESULT=oplane
      end
      3: begin
         ;; An implementation in which data are regridded on an
         ;; naked IDLgrImage.
         ograph->NewAtom, 'MGHgrDensityRect2', NAME='Data', STYLE=style, $
              DATA_VALUES=data_values, DATAX=vertx, DATAY=verty, $
              COLORSCALE=obar, RESULT=oplane
      end
      4: begin
         ;; An implementation using an IDLgrImage. It ignores non-uniform
         ;; grid spacing.
         iloc = [min(vertx),min(verty)]
         idim = [max(vertx),max(verty)] - iloc
         ograph->NewAtom, 'MGHgrDensityImage', NAME='Data', STYLE=style, $
              DATA_VALUES=data_values, LOCATION=iloc, DIMENSIONS=idim, $
              COLORSCALE=obar, /STORE_DATA, RESULT=oplane
      end
   endcase
   self.plane = oplane


   ok = self->MGH_Window::Init(ograph, _STRICT_EXTRA=extra)

   if ~ ok then $
        message, BLOCK='MGH_MBLK_MOTLEY', NAME='MGH_M_INITFAIL', 'MGH_Window'

   self->Finalize, 'MGH_Density'

   return, 1

end

; MGH_Density::GetProperty
;
PRO MGH_Density::GetProperty, $
     BAR=bar, BYTE_RANGE=byte_range, DATA_RANGE=data_range, DATA_VALUES=data_values, $
     PALETTE=palette, PLANE=plane, STYLE=style, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Window::GetProperty, _STRICT_EXTRA=extra

   self.plane->GetProperty, STYLE=style

   bar = self.bar

   plane = self.plane

   if obj_valid(self.bar) then begin
      self.bar->GetProperty, $
           BYTE_RANGE=byte_range, DATA_RANGE=data_range, PALETTE=palette
   endif

   if arg_present(data_values) then begin
      self.plane->GetProperty, DATA_VALUES=data_values
   endif

END

; MGH_Density::SetProperty
;
pro MGH_Density::SetProperty, $
     BYTE_RANGE=byte_range, DATA_RANGE=data_range, DATA_VALUES=data_values, $
     PALETTE=palette, STYLE=style, _REF_EXTRA=extra

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if obj_valid(self.plane) then begin
      self.plane->SetProperty, BYTE_RANGE=byte_range, DATA_RANGE=data_range, $
           DATA_VALUES=data_values, PALETTE=palette, STYLE=style
   endif

   if obj_valid(self.bar) then begin
      self.bar->SetProperty, BYTE_RANGE=byte_range, DATA_RANGE=data_range, $
           PALETTE=palette
   endif

   self->MGH_Window::SetProperty, _STRICT_EXTRA=extra

END

; MGH_Density::About
;
;   Print information about the window and its contents
;
pro MGH_Density::About, lun

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Window::About, lun

   self->GetProperty, PALETTE=palette

   if obj_valid(self.plane) then begin
      printf, lun, FORMAT='(%"%s: my density plane is %s")', $
              mgh_obj_string(self), mgh_obj_string(self.plane, /SHOW_NAME)
   endif

   if obj_valid(self.bar) then begin
      printf, lun, FORMAT='(%"%s: my colour bar is %s")', $
              mgh_obj_string(self), mgh_obj_string(self.bar, /SHOW_NAME)
   endif

   if obj_valid(palette) then begin
      printf, lun, FORMAT='(%"%s: my palette is %s")', $
              mgh_obj_string(self), mgh_obj_string(palette, /SHOW_NAME)
   endif


end

; MGH_Density::BuildMenuBar
;
; Purpose:
;   Add menus, sub-menus & menu items to the menu bar

pro MGH_Density::BuildMenuBar

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Window::BuildMenuBar

   obar = mgh_widget_self(self.menu_bar)

   if obj_valid(obar) then begin

      obar->NewItem, PARENT='Tools', SEPARATOR=[1,0,0,0,1,0,0], MENU=[1,0,0,0,0,0,0], $
           ['Data Range','Edit Palette...', $
            'View Colour Scale...','Edit Data Values...','Graph Properties...', $
            'Plane Properties...','Mask Properties...']

      obar->NewItem, PARENT='Tools.Data Range', ['Set...','Fit Data']

   endif

end

; MGH_Density::EventMenuBar
;
function MGH_Density::EventMenuBar, event

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

      'TOOLS.DATA RANGE.FIT DATA': begin
         self.plane->GetProperty, DATA_VALUES=data_values
         data_range = mgh_minmax(data_values, /NAN)
         if min(finite(data_range)) gt 0 then begin
            if data_range[0] eq data_range[1] then data_range += [-1,1]
            self->SetProperty, DATA_RANGE=data_range
            self->Update
         endif
         return, 0
      end

      'TOOLS.EDIT PALETTE': begin
         self->GetProperty, PALETTE=palette
         mgh_new, 'MGH_GUI_Palette_Editor', palette, CLIENT=self, /FLOATING, $
                  GROUP_LEADER=self.base, /IMMEDIATE
         return, 0
      end

      'TOOLS.VIEW COLOUR SCALE': begin
         mgh_new, 'MGH_GUI_ColorScale', CLIENT=self, /FLOATING, $
                  GROUP_LEADER=self.base
         return, 0
      end

      'TOOLS.EDIT DATA VALUES': begin
         self.plane->GetProperty, DATA_VALUES=data_values
         data_dims = size(data_values, /DIMENSIONS)
         xvaredit, data_values, GROUP=self.base, $
                   X_SCROLL_SIZE=(data_dims[0] < 12), $
                   Y_SCROLL_SIZE=(data_dims[1] < 30)
         self.plane->SetProperty, DATA_VALUES=data_values
         self->Update
         return, 0
      end

      'TOOLS.GRAPH PROPERTIES': begin
         self->GetProperty, GRAPHICS_TREE=ograph
         mgh_new, 'MGH_GUI_PropertySheet', /FLOATING, GROUP_LEADER=self.base, $
              CLIENT=ograph, SPECTATOR=self
         return, 0
      end

      'TOOLS.PLANE PROPERTIES': begin
         mgh_new, 'MGH_GUI_PropertySheet', /FLOATING, GROUP_LEADER=self.base, $
              CLIENT=self.plane, SPECTATOR=self
         return, 0
      end

      'TOOLS.MASK PROPERTIES': begin
         mgh_new, 'MGH_GUI_PropertySheet', /FLOATING, GROUP_LEADER=self.base, $
              CLIENT=self.mask, SPECTATOR=self
         return, 0
      end

      else: return, self->MGH_Window::EventMenubar(event)

   endcase

end


; MGH_Density::ExportData
;
pro MGH_Density::ExportData, values, labels

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   self->MGH_Window::ExportData, values, labels

   self.plane->GetProperty, DATA_VALUES=data_values
   if n_elements(data_values) gt 0 then begin
      labels = [labels,'Data Values']
      values = [values,ptr_new(data_values)]
   endif

   if self.implementation ne 4 then begin
      self.plane->GetProperty, DATAX=datax, DATAY=datay
      if n_elements(datax)*n_elements(datay) gt 0 then begin
         labels = [labels,'Vertex X','Vertex Y']
         values = [values,ptr_new(datax),ptr_new(datay)]
      endif

   endif

end

; MGH_Density::PickReport
;
pro MGH_Density::PickReport, pos, LUN=lun

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

            self.plane->GetProperty, DATA_VALUES=data_values

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

; MGH_Density__Define

pro MGH_Density__Define

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   struct_hide, {MGH_Density, inherits MGH_Window, implementation: 0B, $
                 mask: obj_new(), plane: obj_new(), contour: obj_new(), $
                 bar: obj_new()}

end
