; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/utilities/xdxf.pro#1 $
;
; Copyright (c) 2000-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.

function XDXFGetBounds, oObj, $ ; IN: object to find boundaries of.
                        oParent, $ ;IN: PATH for GetTextDimensions, if needed.
                        oDestDevice, $ ;IN: supplies GetTextDimensions if needed.
                        Range   ;Out: [3,2] coordinates of bounding box coords
compile_opt hidden

if obj_valid(oObj) eq 0 then return, 0
if obj_isa(oObj, 'IDLgrModel') then begin
;
;       Find the boundary of oObj's children.
;
    oChildArr = oObj->Get(/all, count=count)
    gotBox = 0L
    path = [oParent, oObj]
    for ichild=0L, count-1 do $ ;Get each box and accumulate bounding box
      if XDXFGetBounds(oChildArr[ichild], path, oDestDevice, $
                       child_range) then begin
        if gotBox eq 0 then range = child_range $
        else range = [[range[0:2] < child_range[0:2]], $
                      [range[3:5] > child_range[3:5]]]
        gotBox = 1
    endif

    if gotBox then begin             ;Got a box?  Transform it..
        oObj->GetProperty, transform=model_tm ;Transform it and get range
        p1 = fltarr(4,8)
        for i=0, 7 do p1[0,i] = [range[0, i and 1],     $
                                 range[1, (i/2) and 1], $
                                 range[2, (i/4) and 1], $
                                 1.0 ]
        p1 = MATRIX_MULTIPLY(p1, model_tm, /ATRANSPOSE)
        range = [[min(p1[*,0], max=xmax), min(p1[*,1], max=ymax), $
                  min(p1[*,2], max=zmax)], $
                 [xmax, ymax, zmax]]
    endif                       ;if gotBox
    return, gotBox

endif else if obj_isa(oObj, 'IDLgrGraphic') then begin

    if obj_isa(oObj, 'IDLgrLight') then return, 0 ;Don't look at lights

    if obj_isa(oObj, 'IDLgrText') then begin
;
;           GetTexTDimensions is called for this side effect: oObj's
;           xrange, yrange & zrange are updated.
;
        if obj_valid(oDestDevice) and obj_valid(oParent[0]) then $
          void = oDestDevice->GetTextDimensions(oObj, path=[oParent])
    endif

    oObj->GetProperty, xrange=xrange, yrange=yrange, zrange=zrange, $
      xcoord_conv=xcc, ycoord_conv=ycc, zcoord_conv=zcc
;
    xrange = xrange * xcc[1] + xcc[0] ;Scale to normalized coords
    yrange = yrange * ycc[1] + ycc[0]
    zrange = zrange * zcc[1] + zcc[0]
    Range = [[[xrange[0], yrange[0]], zrange[0]], $
             [xrange[1], yrange[1], zrange[1]]]
    return, 1
endif else begin                ;Dunno what it is
    return, 0
endelse
end


FUNCTION xdxf_strippath, filename
COMPILE_OPT hidden

CASE !VERSION.OS_FAMILY OF
    'unix': sep = '/'
    'Windows': sep = '\'
ENDCASE

pos = STRPOS(filename, sep, /REVERSE_SEARCH)
IF ((pos GE 0) AND (pos LT (STRLEN(filename)))) THEN $
  RETURN, STRMID(filename, pos+1) $
ELSE RETURN, filename
END


Function DXFBuildTable, wTop, bTable, lTable, sTable, REBUILD=rebuild

nBlocks = n_elements(bTable)
nLayers = n_elements(lTable)
nRows = nBLocks + nLayers

sTable = Replicate({ typ: 'B', vis: 1b, count: 0L, Color: 'Magenta'}, nRows)
sTable.typ =[REPLICATE('B', nBLocks), REPLICATE('L', nLayers)]
sTable.vis = [btable.visible, ltable.visible]
sTable.Count = long(total([[btable.nentries],[ltable.nentries]], 1))
sTable.Color = [ btable.colorname, ltable.colorname]

if keyword_set(rebuild) eq 0 then begin
    bList = widget_table(wTop, YSIZE = nRows > 6, XSIZE=4, $
                         Y_SCROLL_SIZE = 6, /ROW_MAJOR, $
                         SCR_XSIZE = 0.7 * 4 + 2.25, $
                         COLUMN_LABELS = ['Typ', 'Vis', 'Count', 'Color'], $
                         COLUMN_WIDTHS= [.5,.5,.75,.9], $
                         UNIT=1, /RESIZEABLE_COLUMNS, $
                         ROW_LABELS = [bTable.name, LTable.name], $
                         ALIGNMENT=2, /ALL_EVENTS, VALUE=sTable)
    WIDGET_CONTROL, bList, USE_TABLE_SELECT=[-1,0,-1,nrows-1], $
      COLUMN_WIDTH=1.5, /UNIT
endif else begin                ;Resize existing table
    blist = wTop
    WIDGET_CONTROL, blist, YSIZE = nRows
    WIDGET_CONTROL, blist, ROW_LABELS=[bTable.name, lTable.name], ALIGNMENT=2
    WIDGET_CONTROL, blist, SET_VALUE= sTable ;, USE_TABLE_SELECT=[0,0,nRows-1,3]
endelse

return, blist
end

PRO XDXFUnselect, state
o = state.oSelected
if obj_valid(o) eq 0 then return
ochild = o->get(/ALL, COUNT=nchildren)
for i=0, nchildren-1 do begin
    (*(state.btable))[state.defaultBlock].model->remove, ochild[i]
    obj_destroy, ochild[i]
endfor
obj_destroy, o
state.oSelected = obj_new()
end

PRO XDXFSelect, state, iSelect

entry = iSelect ge state.nBlocks ? $
    (*(state.lTable))[iSelect - state.nBlocks] : (*(state.bTable))[iSelect]
mainBlock = (*(state.btable))[state.defaultBlock].model
if iSelect eq state.defaultBlock then begin
    child = mainBlock
    nchildren = 1
endif else child = mainBlock->get(/ALL, COUNT=nchildren)
oSelected = obj_new('idlgrmodel')
state.oSelected = oSelected

for ic=0L, nchildren-1 do begin ;Search for instances of selected blk
    child[ic]->getproperty, NAME=cname
    if (cname eq entry.name) or (child[ic] eq mainBlock) $
      then begin        ;Where block is inserted
        t0 = systime(1)
        i = XDXFGetBounds(child[ic], child[ic], 0, range)
        t1 = systime(1)-t0

        ;WIDGET_CONTROL, state.wtext, GET_VALUE=v
        ;v[n_elements(v)-1] = i ? string(range[0:5],FORMAT='(6f9.1)') : $
        ;  '<Object is not drawable>'
        ;WIDGET_CONTROL, state.wtext, SET_VALUE=v

        if i eq 0 then break

        verts = fltarr(3,8) ;Bounding volume
        for i=0, 7 do for j=0,2 do $
          verts[j,i] = range[j, (i and 2^j) ne 0]
                        ;Make the bounding box
        selbox = obj_new('idlgrpolyline', verts, color=[0,255,0], $
                         POLYLINES = [5,0,1,3,2,0, 5,4,5,7,6,4, $
                                      2,0,4, 2,1,5, 2,2,6, 2,3,7])
        oSelected->add, selbox, /ALIAS
        mainBlock->add, selbox, /ALIAS ;Show bounding box
    endif               ;Found inserted block
endfor

end

PRO xdxf_display_cleanup1, obj
if obj_valid(obj) eq 0 then return
if obj_isa(obj, 'idlgrcontainer') then begin
    objs = obj->get(/ALL, COUNT=n)
    for i=0L, n-1 do xdxf_display_cleanup1, objs[i]
endif
obj_destroy, obj
end


PRO xdxf_display_cleanup, wID, STATE=state
COMPILE_OPT hidden

onlyg = n_elements(state) ne 0
if onlyg eq 0 then begin
    WIDGET_CONTROL, wID, GET_UVALUE=state
    ptr_free, state.entities
endif

XDXFUnselect, state              ;Clean up any boxes...
bTable = *(state.btable)
for i=0, n_elements(btable)-1 do xdxf_display_cleanup1, bTable[i].model
ptr_free, state.btable

ltable = *(state.ltable)
for i=0, n_elements(ltable)-1 do xdxf_display_cleanup1, ltable[i].model
ptr_free, state.ltable
ptr_free, state.visible

END


FUNCTION SummarizeEntities, Counts, Names
str1 = ''
for i=0, n_elements(counts)-1 do if counts[i] ne 0 then $
  str1 = str1 + (((strlen(str1) ne 0) ? ', ' : '') + $
                 (Names[i] + ' ' + strtrim(counts[i],2)))
return, str1
end


pro XDXF_DISPLAY_EVENT, ev
COMPILE_OPT hidden

WIDGET_CONTROL, ev.top, GET_UVALUE=state, /NO_COPY
iSelect = -1
case ev.id of
    state.blist: begin          ;Cell select event??
        if (ev.type ne 4) then break
        if (ev.sel_top lt 0) then break ;Deselect
        widget_control, ev.top, /HOUR
        if ev.sel_top lt state.nentries then begin
            iSelect = ev.SEL_TOP
            if iSelect ne state.iSelect then begin
                if state.do_block_outlines then begin
                    WIDGET_CONTROL, ev.top, /HOUR
                    XDXFUnselect, state
                    XDXFSelect, state, iSelect
                    if widget_info(state.vtlb, /valid_id) then begin
                        xobjview, REFRESH=state.vtlb
                    end else begin
                        xobjview, state.o, tlb=tlb ,group=wtop, $
                            background=[0,0,0]
                        state.vtlb = tlb
                    end
                    state.outline_is_current = 1B
                endif else begin
                    state.outline_is_current = 0B
                endelse
            endif
        endif
        if ev.sel_left eq 1 and ev.sel_right eq 1 then begin ;Toggle visibility?
            state.iSelect = ev.sel_top
            hide = 2
            all = 0
            goto, do_visibility
        endif
    endcase
    state.wFileButton: BEGIN
        WIDGET_CONTROL, ev.top, /HOURGLASS
        filename = DIALOG_PICKFILE(FILTER='*.dxf', GROUP=ev.top, $
                                   /MUST_EXIST, PATH=state.path, $
                                   GET_PATH=path, $
                                   TITLE='Select DXF File to Read')
        IF STRLEN(filename) eq 0 THEN break
        o=get_dxf_objects(filename, bTable, lTable, IGNOR=ignored, ERROR=error)
        IF (error NE 0) THEN BEGIN
            response = DIALOG_MESSAGE(!ERROR_STATE.MSG, DIALOG_PARENT=ev.top)
            break
        endif

        state.iSelect = -1      ;Nothing selected
        if WIDGET_INFO(state.vtlb, /VALID) Then $
          WIDGET_CONTROL, state.vtlb, /DESTROY
        XDXFUnselect, state      ;Clean up selection object
        xdxf_display_cleanup, 0, STATE=state ;Clean up tables
        entities = *(State.entities)

        if total(ignored) gt 0 then begin
            str = 'Ignored: ' + SummarizeEntities(ignored, Entities)
        endif else str = ''

                                ;Report # of entities read.
        state.nBlocks = n_elements(btable)
        state.nEntries = n_elements(btable) + n_elements(lTable)
        sums = long(total(reform(bTable.nentries, 21, state.nBLocks),2))
        str1 = SummarizeEntities(sums, Entities)
        openr, lun, filename, /GET_LUN ;Get the size of the file
        fsize = (fstat(lun)).size
        free_lun, lun
        str2 = 'File size: '+strtrim(round(fsize/1.0e3), 2) + 'kb'

        Widget_Control, state.wText, SET_VALUE=[str, 'Read: ' + str1, str2]
        xobjview, o, TLB=tlb, GROUP=state.wtop, BACKGROUND=[0,0,0], $
          TITLE=XDXF_STRIPPATH(filename)
        DefBlk = where(strlen(bTable.name) eq 0, count) ;Substitute def blk name
        state.defaultBlock = DefBlk[0]
        if count eq 1 then bTable[DefBlk[0]].name = '*Model_Space'
        dummy = DXFBuildTable(state.blist, bTable, lTable, sTable, /REBUILD)
        state.path = path
        state.vtlb = tlb
        state.visible = ptr_new(byte([bTable.visible, lTable.visible]))
        state.btable = PTR_NEW(btable,/NO_COPY)
        state.ltable = PTR_NEW(ltable,/NO_COPY)
        state.o = o
    endcase                     ;File button

    state.wQuitButton: BEGIN
        WIDGET_CONTROL, ev.top, SET_UVALUE=state, /NO_COPY
        WIDGET_CONTROL, ev.top, /DESTROY
        return
    endcase

;    state.wByLayer[0] : BEGIN   ;Set read by layer
;        state.bylayer = 1
;        set_by_layer: WIDGET_CONTROL, state.wByLayer[0], sens=1-state.byLayer
;        WIDGET_CONTROL, state.wByLayer[1], sens=state.byLayer
;    ENDCASE
;    state.wByLayer[1] : BEGIN   ;Set read by block
;        state.bylayer = 0
;        goto, set_by_layer
;    ENDCASE


;*****************************************************************
    state.wViewBlock: begin
        state.do_block_outlines = ev.select
        if state.do_block_outlines $
            and state.iSelect ge 0 $
            and not state.outline_is_current $
        then begin
            XDXFUnselect, state
            XDXFSelect, state, state.iSelect
        endif
        if obj_valid(state.oSelected) then begin
            oBoxes = state.oSelected->Get(/ALL)
            for i=0,n_elements(oBoxes)-1 do begin
                if obj_valid(oBoxes[i]) then begin
                    oBoxes[i]->SetProperty, hide=ev.select eq 0
                endif
            endfor
        endif

        if widget_info(state.vtlb, /valid_id) then begin
            xobjview, REFRESH=state.vtlb
        end else begin
            xobjview, state.o, tlb=tlb ,group=wtop, $
                background=[0,0,0]
            state.vtlb = tlb
        end

    endcase

    state.wHideAll: Begin
        hide = 1
        all = 1
        goto, do_visibility
    endcase
    state.wHide: Begin
        hide = 1
        all = 0
        goto, do_visibility
    endcase

    state.wShowAll: Begin
        hide = 0
        all = 1
        goto, do_visibility
    endcase
    state.wShow: Begin
        hide = 0
        all = 0
do_visibility:
        WIDGET_CONTROL, ev.top, /HOURGLASS
        iSelect = state.iSelect
        if (all eq 0) and (iSelect lt 0 or iSelect ge state.nEntries) then break
        for j = all ? 0 : iSelect, $
          all ? n_elements(*(state.visible))-1 : iSelect do begin
            if j eq state.defaultBlock then continue ;Don't mess with #1
            entry = j ge state.nBlocks ? $
              (*(state.lTable))[j - state.nBlocks] : (*(state.bTable))[j]
            hide1 = hide eq 2 ? (*(state.visible))[j] : hide ;New hide value
            if (*(state.visible))[j] eq (1-hide1) then continue
            entry.model->setproperty, hide=hide1
            WIDGET_CONTROL, state.blist, USE_TABLE_SELECT=[1,j,1,j], $
              SET_VALUE=1-hide1
            if j ge state.nBlocks then begin ;Must hit children for layers
                for i=0L, entry.model->count()-1 do begin
                    o = entry.model->get(POSITION=i)
                    o->setproperty, HIDE=hide1
                endfor
            endif               ;layers
            (*(state.visible))[j] = 1-hide1
        endfor

        if widget_info(state.vtlb, /valid_id) then begin
            xobjview, REFRESH=state.vtlb
        end else begin
            xobjview, state.o, tlb=tlb ,group=wtop, $
                background=[0,0,0]
            state.vtlb = tlb
        end
        if iSelect ge 0 then goto, refresh_text
    endcase
endcase

if iSelect ne state.iSelect then begin ;New selection
refresh_text:
    if iSelect lt 0 or iSelect ge state.nEntries then goto, done
    entry = iSelect ge state.nBlocks ? $
      (*(state.lTable))[iSelect - state.nBlocks] : (*(state.bTable))[iSelect]
    str1 = ''
    sums = entry.nentries
    for i=0, n_elements(sums)-1 do if sums[i] ne 0 then $
      str1 = str1 + (((strlen(str1) ne 0) ? ', ' : '') + $
                     (*(state.Entities))[i] + ' ' + strtrim(sums[i],2))
    WIDGET_CONTROL, state.wText, SET_VALUE= $
      [entry.name + ((*(state.visible))[iSelect] ? '<Visible>' : '<Hidden>')+ $
       '<'+ entry.ColorName+'>', str1]
    state.Iselect = iSelect
endif

done: WIDGET_CONTROL, ev.top, SET_UVALUE=state, /NO_COPY
end



;*****************************************************************
PRO xdxf, filename, $           ; IN (opt)
          GROUP=group_leader, $ ; IN (opt)
          MODAL=modal, $        ; IN (opt)
          TEST= test, $         ; IN (to read heart example file)
          BLOCK=block, $
          _EXTRA=extra

;*****************************************************************

; Names of IDL DXF entity types:
Entities = ['Entities', 'Arc', 'Circle', 'Ellipse', 'Line', 'Line3D', 'Trace', $
            'Polyline', 'LWPolyline', 'Polygon', 'Face3D', 'Solid', 'Ray', $
            'XLine', 'Text', 'MText', 'Point', 'Spline', 'Block', $
            'Insert', 'Layer']

; filter = '/rsi/src/dxf/example_files/*.dxf'    ;For testing
filter = '*.dxf'
path = ''
IF N_ELEMENTS(filename) EQ 0 THEN BEGIN ;Get file path info
    IF keyword_set(test) then $
      filename = FILEPATH('heart.dxf',SUBDIR=['examples','data']) $
    else filename = DIALOG_PICKFILE(FILTER=filter, /MUST_EXIST, $
                                    GET_PATH=path, $
                                    TITLE='Select DXF File to Read')
endif

IF filename EQ '' THEN RETURN

o = GET_DXF_OBJECTS(filename, bTable, lTable, IGNOR=ignored, ERROR=error)

if error ne 0 then return
defBlk = where(strlen(bTable.name) eq 0, count) ;Substitute default block name
if count eq 1 then bTable[defBlk[0]].name = '*Model_Space' $
else message,'No default block'

openr, lun, filename, /GET_LUN  ;Get the size of the file
fsize = (fstat(lun)).size
free_lun, lun

if KEYWORD_SET(modal) then $
  MESSAGE, 'Modal keyword now implies /BLOCK', /INFO

wTop = WIDGET_BASE(/COLUMN, TITLE='XDXF Information', $
                   GROUP_LEADER=group_leader, MBAR=wMenuBar, $
                   map=0)

wFileMenu = WIDGET_BUTTON(wMenuBar, VALUE='File', /MENU)
wFileButton = WIDGET_BUTTON(wFileMenu, VALUE='Open...', UVALUE='OPEN')
wQuitButton = WIDGET_BUTTON(wFileMenu, VALUE='Quit', UVALUE='QUIT')

blist = DXFBuildTable(wTop, bTable, Ltable, sTable) ;Make the entity table

wButtons = WIDGET_BASE(wTop, /ROW)
wButtonBase = WIDGET_BASE(wButtons, /ROW, XPAD=0)
wHide = WIDGET_BUTTON(wButtonBase, VALUE='Hide', /NO_RELEASE)
wShow = WIDGET_BUTTON(wButtonBase, VALUE='Show', /NO_RELEASE)
wHideAll = WIDGET_BUTTON(wButtonBase, VALUE='Hide All', /NO_RELEASE)
wShowAll = WIDGET_BUTTON(wButtonBase, VALUE='Show All', /NO_RELEASE)
void = WIDGET_LABEL(wButtons, VALUE='  ')
wBase = WIDGET_BASE(wButtons, /NONEXCLUSIVE, /COLUMN)
wViewBlock = WIDGET_BUTTON(wBase, VALUE='View Block Outline')

wText = WIDGET_TEXT(wTop, xsize=40, ysize=5, /WRAP)

if total(ignored) gt 0 then begin
    str = 'Ignored: ' + SummarizeEntities(ignored, Entities)
endif else str = ''

                                ;Report # of entities read and file size
nBlocks = n_elements(bTable)
sums = long(total(reform(bTable.nentries, 21, nBlocks),2)) ;Entity count
str1 = 'Read: ' + SummarizeEntities(sums, Entities)
str2 = 'File size: '+strtrim(round(fsize/1.0e3), 2) + 'kb'
Widget_Control, wText, SET_VALUE=[str, str1, str2]

widget_control, wTop, /realize
xobjview, o, TLB=tlb, GROUP= wtop, $
  TITLE=XDXF_STRIPPATH(filename), BACKGROUND = [0,0,0], _EXTRA=extra

wTop_geom = WIDGET_INFO(wTop, /GEOMETRY)
tlb_geom = WIDGET_INFO(tlb, /GEOMETRY)
DEVICE, GET_SCREEN_SIZE=screen_size

x = tlb_geom.scr_xsize[0] + tlb_geom.xoffset
x = x < (screen_size[0] - wTop_geom.scr_xsize)
x = x > 0

WIDGET_CONTROL, wTop, TLB_SET_XOFFSET=x
WIDGET_CONTROL, wTop, MAP=1

state = { wTop: wTop, $
          nBlocks : nBlocks, $
          nEntries: nBlocks + n_elements(lTable), $
          visible: ptr_new(byte([bTable.visible, lTable.visible])), $
          bTable: ptr_new(bTable, /NO_COPY), $
          lTable: ptr_new(lTable, /NO_COPY), $
          entities: ptr_new(entities, /NO_COPY), $
          bList: bList, $
          wText: wText, $
          wShow: wShow, $
          wHide: wHide, $
          wShowAll: wShowAll, $
          wHideAll: wHideAll, $
          wViewBlock: wViewBlock, $
          wFileButton: wFileButton, $
          wQuitButton: wQuitButton, $
          path: path, $
          iSelect: -1L, $
          oSelected : obj_new(), $
          vtlb: tlb, $
          o: o, $
          defaultBlock: defBlk[0], $
          filename: filename, $
          do_block_outlines: 0B, $
          outline_is_current: 0B $
        }

WIDGET_CONTROL, wTop, SET_UVALUE=state

xmanager, 'xdxf_display', wtop, $
  NO_BLOCK=(KEYWORD_SET(block) or KEYWORD_SET(modal)) EQ 0, $
  CLEANUP='xdxf_display_cleanup'
end
