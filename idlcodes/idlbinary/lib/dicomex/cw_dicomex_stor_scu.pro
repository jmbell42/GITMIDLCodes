; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/dicomex/cw_dicomex_stor_scu.pro#1 $
; Copyright (c) 2004-2006, Research Systems, Inc.  All rights reserved.
;       Unauthorized reproduction prohibited.
;+
; NAME:
;   cw_dicomex_stor_scu
;
; PURPOSE:
;   This widget a UI front end to an underlying dicomex storage scu object.
;   This UI allows the user to push dicom files to another dicom node.
;
; CALLING SEQUENCE:
;
;   ID = CW_DICOMEX_STOR_SCU(WID)
;
; INPUTS:
;
;   WID - Widget ID of the parent
;
; KEYWORD PARAMETERS:
;
;   NONE
;
; MODIFICATION HISTORY:
;   Written by:  LFG, RSI, October 2004
;   Modified by:  AGEH, RSI, December 2004    Tweaked code, added comments.
;
;-

;;----------------------------------------------------------------------------
;; NAME
;;   IDLffDICOMEx::GetValueDefault
;;
;; Purpose:
;;   Event handler for the close button
;;
;; Parameters:
;;   TAG - Name of tag to query
;;
;;   DEF - default to return if tag not found
;;
;; Keywords:
;;   NONE
;;
function IDLffDICOMEx::GetValueDefault, tag, def
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  if (self->QueryValue(tag) ne 2) then begin
    return, def
  endif else begin
    return, self->GetValue(tag)
  endelse

end

;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_create_file_info_struct
;;
;; Purpose:
;;   Creates array needed to execute sub queries
;;
;; Parameters:
;;   NONE
;;
;; Keywords:
;;   NONE
;;
function cw_dicomex_create_file_info_struct
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  ; an array of these structs that is put into node zero of each level
  ; this array of structs contians info that needed to execute sub queries
  ; this array of structs contains info that allows the the results table to
  ; be filled in when the user clicks on a node in the tree

  xFile = create_struct( name='lfg_struct', $
                         'fn',           '', $
                         'pat_id',           '', $
                         'pat_name',        '', $
                         'study_uid',         '', $
                         'series_uid',          '', $
                         'sop_uid',           '', $
                         'modality',        '', $
                         'study_id',        '', $
                         'study_desc',          '', $
                         'study_date',          '', $
                         'study_time',          '', $
                         'series_num',          '', $
                         'series_desc',       '', $
                         'acc_num',           '', $
                         'inst_num',        '')

  return, xFile

end

;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_fill_in_file_info
;;
;; Purpose:
;;   Sets default values
;;
;; Parameters:
;;   II - index into xFiles
;;
;;   XFILES - array of info structures
;;
;;   OBJ - IDLffDicomEx object to query for values
;;
;;   FILE - Name of file
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_fill_in_file_info, ii, xFiles, obj, file
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  def = strtrim(string(ii),2)   ;  a simplistic default value (should never be used)
  xFiles[ii].fn = file
  xFiles[ii].pat_id = obj->GetValueDefault('0010,0020', def) ;  Patient ID
  xFiles[ii].pat_name = obj->GetValueDefault('0010,0010', def) ;  Patient Name
  xFiles[ii].study_uid = obj->GetValueDefault('0020,000D', def) ;  Study Instance UID
  xFiles[ii].series_uid = obj->GetValueDefault('0020,000E', def) ;  Series Instance UID
  xFiles[ii].sop_uid = obj->GetValueDefault('0008,0018', def) ;  Series Instance UID
  xFiles[ii].modality = obj->GetValueDefault('0008,0060', def) ;  Modality
  xFiles[ii].study_id = obj->GetValueDefault('0020,0010', def) ;  Study Id
  xFiles[ii].study_desc = obj->GetValueDefault('0008,1030', def) ;  Study Description
  xFiles[ii].study_date = obj->GetValueDefault('0008,0020', def) ;  Study Date
  xFiles[ii].study_time = obj->GetValueDefault('0008,0030', def) ;  Study Time
  xFiles[ii].series_num = obj->GetValueDefault('0020,0011', def) ;  Series Num
  xFiles[ii].series_desc = obj->GetValueDefault('0008,103E', def) ;  Series Description
  xFiles[ii].inst_num = obj->GetValueDefault('0020,0013', def) ;  Instance Num
  xFiles[ii].acc_num = obj->GetValueDefault('0008,0050', def) ;  Accession Num

end

;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_btnSendPatFiles_event
;;
;; Purpose:
;;   Event handler for the Send Patient Files button
;;
;; Parameters:
;;   EV - widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_btnSendPatFiles_event, ev
  compile_opt idl2

  catch, errorStatus
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    widget_control, (*pstate).wbtnCancelSPD, sensitive=0
    cw_dicomex_stor_ui_enable, ev
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(ev.top, find_by_uname='storscustatebase')
  widget_control, wState, get_uvalue = pstate

  if ((*pstate).treeNodeSelIdx eq -2) then begin
    widget_control, (*pstate).wtxtStatus, set_value='Select a Patient, Study, ' + $
                    'Series or Image before pressing the send patient files button'
    return
  endif

  ; ensure the stor scp node has been set
  (*pstate).oscu->setproperty, storage_scp = (*pstate).store_scp

  widget_control, (*pstate).wbtnCancelSPD, sensitive=1
  cw_dicomex_stor_ui_disable, ev

  cnt = 1
  name = widget_info((*pstate).treeNodeSel, /uname)
  xFiles = *(*pstate).pxFiles
  xx = (*pstate).treeNodeSelIdx
  filesToSend = ''

  if (name eq 'patient') then begin
    id = xFiles[xx].pat_id
  endif

  if (name eq 'study') then begin
    id = xFiles[xx].study_uid
  endif

  if (name eq 'series') then begin
    id = xFiles[xx].series_uid
  endif

  if (name eq 'image') then begin
    id = xFiles[xx].sop_uid
    filesToSend = [filesToSend, xFiles[xx].fn]
  endif

  numxFiles = n_elements(xFiles)

  if (name ne 'image') then begin
    for ii = 0, numxFiles-1 do begin
      if (name eq 'patient') then begin
        if (xFiles[ii].pat_id eq id) then begin
          filesToSend = [filesToSend, xFiles[ii].fn]
        endif
      endif
      if (name eq 'study') then begin
        if (xFiles[ii].study_uid eq id) then begin
          filesToSend = [filesToSend, xFiles[ii].fn]
        endif
      endif
      if (name eq 'series') then begin
        if (xFiles[ii].series_uid eq id) then begin
          filesToSend = [filesToSend, xFiles[ii].fn]
        endif
      endif
    endfor
  endif

  ; clear the status text widget
  widget_control, (*pstate).wtxtStatus, set_value=''

  numfiletosend = n_elements(filesToSend) - 1
  filesToSend = filesToSend[1:numfiletosend]
  cnt = (*pstate).oscu->send(filesToSend)

  widget_control, (*pstate).wbtnCancelSPD, sensitive=0
  cw_dicomex_stor_ui_enable, ev

end

;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_sc_tree_node_event
;;
;; Purpose:
;;   Event handler for the tree widget
;;
;; Parameters:
;;   EV - widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_sc_tree_node_event, ev
  compile_opt idl2

  catch, errorStatus
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  ; this is called when the user left clicks a node in the tree

  wState = widget_info(ev.top, find_by_uname='storscustatebase')
  widget_control, wState, get_uvalue = pstate

  ; get the unique name of the node
  name = widget_info(ev.id, /uname)
  widget_control, ev.id, get_uvalue = ii

  ; avoid sub queries on the patient_id root of tree when the tree is empty
  if (name eq 'TRE_PATIENTS') then begin
    widget_control, (*pstate).wtxtPatInfo, set_value = ''
    return
  endif

  xFiles = *(*pstate).pxFiles

  (*pstate).treeNodeSel    = ev.id
  (*pstate).treeNodeSelIdx    = ii

  if (name eq 'patient') then begin
    widget_control, (*pstate).wtxtPatInfo, set_value='Patient Id:'+ xFiles[ii].pat_id
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Patient Name: '+ xFiles[ii].pat_name, /append
  endif

  if (name eq 'study')  then begin
    widget_control, (*pstate).wtxtPatInfo, set_value='Patient Id:' +  xFiles[ii].pat_id
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Patient Name: ' +  xFiles[ii].pat_name, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Study Instance UID: ' +  xFiles[ii].study_uid, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Modality: ' +  xFiles[ii].modality, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Study Id: ' +  xFiles[ii].study_id, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Study Description: ' +  xFiles[ii].study_desc, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Study Date: ' +  xFiles[ii].study_date, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Study Time: ' +  xFiles[ii].study_time, /append
  endif

  if (name eq 'series') then begin
    widget_control, (*pstate).wtxtPatInfo, set_value='Patient Id:' +  xFiles[ii].pat_id
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Patient Name: ' +  xFiles[ii].pat_name, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Study Instance UID: ' +  xFiles[ii].study_uid, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Series Instance UID: ' +  xFiles[ii].series_uid, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Modality: ' +  xFiles[ii].modality, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Study Id: ' +  xFiles[ii].study_id, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Study Description: ' +  xFiles[ii].study_desc, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Study Date: ' +  xFiles[ii].study_date, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Study Time: ' +  xFiles[ii].study_time, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Series Number: ' +  xFiles[ii].series_num, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Series Description: ' +  xFiles[ii].series_desc, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Accession Number: ' +  xFiles[ii].acc_num, /append
  endif

  if (name eq 'image') then begin
    widget_control, (*pstate).wtxtPatInfo, set_value='Patient Id:' +  xFiles[ii].pat_id
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Patient Name: ' +  xFiles[ii].pat_name, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Study Instance UID: ' +  xFiles[ii].study_uid, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Series Instance UID: ' +  xFiles[ii].series_uid, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='SOP Instance UID: ' +  xFiles[ii].sop_uid, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Modality: ' +  xFiles[ii].modality, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Study Id: ' +  xFiles[ii].study_id, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Study Description: ' +  xFiles[ii].study_desc, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Study Date: ' +  xFiles[ii].study_date, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Study Time: ' +  xFiles[ii].study_time, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Series Number: ' +  xFiles[ii].series_num, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Series Description: ' +  xFiles[ii].series_desc, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Instance Number: ' +  xFiles[ii].inst_num, /append
    widget_control, (*pstate).wtxtPatInfo, $
                    set_value='Filename: ' +  xFiles[ii].fn, /append
  ENDIF

end

;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_btnSelDir_event
;;
;; Purpose:
;;   Event handler for the Select Directory button
;;
;; Parameters:
;;   EV - widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_btnSelDir_event, ev
  compile_opt idl2, logical_predicate

  catch, errorStatus
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(ev.top, find_by_uname='storscustatebase')
  widget_control, wState, get_uvalue = pstate

  if ((*pstate).stor_scp_cnt eq 0) then begin
    widget_control, (*pstate).wtxtStatus, set_value = 'You will need to configure ' + $
                    'at least one Storage SCP node before you can do a send.'
    return
  endif

  ; clear the status text widget
  widget_control, (*pstate).wtxtStatus, set_value=''

  ; clear the status text widget
  widget_control, (*pstate).wtxtPatInfo, set_value=''

  if ((*pstate).sendPatDir ne '') then begin
    path = (*pstate).sendPatDir
  endif else begin
    path=!dir
  endelse

  newpath = dialog_pickfile(title='Pick a directory', path=path, /directory, $
                            DIALOG_PARENT=ev.top)

  if (newpath[0] eq '') then begin
    return
  endif

  files = file_search(newpath[0]+'*', /TEST_REGULAR)
  num_files = n_elements(files)

  if (num_files eq 0) then begin
    return
  endif

  (*pstate).sendPatDir = newpath[0]

  ;  Get the current size of the widget
  geo = WIDGET_INFO((*pstate).wtrePatients, /GEOMETRY)

  ;  Empty the tree
  WIDGET_CONTROL, (*pstate).wtrePatients, /DESTROY
  (*pstate).wtrePatients = WIDGET_TREE((*pstate).wtree, UNAME='TRE_PATIENTS', $
                                       value='Patient Ids', /FOLDER, /EXPANDED, $
                                       event_pro='cw_dicomex_sc_tree_node_event')

  ;  This takes a few seconds
  WIDGET_CONTROL, /HOURGLASS

  xFile = cw_dicomex_create_file_info_struct()

  if (num_files GT 0) then begin
    xFiles = replicate(xFile, num_files)
  endif

  ; make sure we do not use an old tree selection
  (*pstate).treeNodeSel   = 0
  (*pstate).treeNodeSelIdx    = -2

  numCatches = 0
  numDicomFiles = 0

  ;  Scan each file keeping only those that are dicom files.
  ;;  we have a dedicated error handling for errors issued by the
  ;;  idlffdicomex obj when it encounters a bad file
  for  ii = 0, num_files-1 do begin
    catch, err
    if err then begin
      catch, /CANCEL
      numCatches++
      print, !error_state.msg   ;  not a DICOM file
    endif else begin
      obj = obj_new('IDLffDicomEx', files[ii], /NO_PIXEL_DATA) ;  is it a DICOM file?
      cw_dicomex_fill_in_file_info, numDicomFiles, xFiles, obj, files[ii]
      numDicomFiles++
      obj_destroy, obj
    endelse
  endfor

  ; put the normal catch handler with a return back in place
  catch, errorStatus
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', dialog_parent=cwBase, /error)
    return
  endif

  ;  If no DICOM files then exit
  if (numDicomFiles eq 0) then begin
    return
  endif

  ;  Sort the DICOM files found by patient, study, series and image.
  attr = strarr(4, numDicomFiles)
  for i = 0, numDicomFiles-1 do begin
    attr[0,i] = xFiles[i].pat_id
    attr[1,i] = xFiles[i].study_uid
    attr[2,i] = xFiles[i].series_uid
    attr[3,i] = attr[0,i]+attr[1,i]+attr[2,i]
  endfor

  order = sort(attr[3,*])       ; sort by "UID"
  attr = attr[*,order]

  widget_control, (*pstate).wtree, update=0

  ;  Build the tree
  ;  on solaris the tree must be visible when adding nodes...very strange...
  pat = ''
  sty = ''
  ser = ''
  for i = 0, numDicomFiles-1 do begin
    if (pat ne attr[0,i]) then begin
      pat = attr[0,i]
      wPat = WIDGET_TREE((*pstate).wtrePatients, VALUE=pat, /FOLDER, $
                         uname='patient', UVALUE=i, $
                         event_pro='cw_dicomex_sc_tree_node_event')
    endif
    if (sty ne attr[1,i]) then begin
      sty = attr[1,i]
      wStudy = WIDGET_TREE(wPat, VALUE='Study', /FOLDER, uname='study', $
                           UVALUE=i, event_pro='cw_dicomex_sc_tree_node_event')
    endif
    if (ser ne attr[2,i]) then begin
      ser = attr[2,i]
      wSeries = WIDGET_TREE(wStudy, VALUE='Series', /FOLDER, uname='series', $
                            UVALUE=i, event_pro='cw_dicomex_sc_tree_node_event')
    endif
    wImage = WIDGET_TREE(wSeries, VALUE='Image', uname='image', UVALUE=i, $
                         event_pro='cw_dicomex_sc_tree_node_event')
  endfor

  widget_control, (*pstate).wtree, update=1

  ; reorder the xFiles struct to match the order of the attr array
  ; shrink the xFiles struct to match the actual number of dicom files
  order_cnt = n_elements(order)
  xFiles = xFiles[order]
  xFiles = xFiles[0:order_cnt-1]

  if ptr_valid((*pstate).pxFiles) then begin
    ptr_free, (*pstate).pxFiles
  endif

  (*pstate).pxFiles = ptr_new(xFiles, /NO_COPY)

end

;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_stor_ui_enable
;;
;; Purpose:
;;   Routine to desensitize the buttons
;;
;; Parameters:
;;   EV - widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_stor_ui_disable, ev
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  wState = widget_info(ev.top, find_by_uname='storscustatebase')
  widget_control, wState, get_uvalue = pstate

  ; disable the btns
  widget_control, (*pstate).wcbSendTo, sensitive=0
  widget_control, (*pstate).wbtnSelDirSPD, sensitive=0
  widget_control, (*pstate).wbtnSendSPD, sensitive=0
  widget_control, (*pstate).wbtnSendFiles, sensitive=0

end

;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_stor_ui_enable
;;
;; Purpose:
;;   Routine to sensitize the buttons
;;
;; Parameters:
;;   EV - widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_stor_ui_enable, ev
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  wState = widget_info(ev.top, find_by_uname='storscustatebase')
  widget_control, wState, get_uvalue = pstate

  ; enable the btns
  widget_control, (*pstate).wcbSendTo, sensitive=1
  widget_control, (*pstate).wbtnSelDirSPD, sensitive=1
  widget_control, (*pstate).wbtnSendSPD, sensitive=1
  widget_control, (*pstate).wbtnSendFiles, sensitive=1

end

;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_cbSendTo_event
;;
;; Purpose:
;;   Event handler for Destination Node widget
;;
;; Parameters:
;;   EV - widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_cbSendTo_event, ev
  compile_opt idl2

  catch, errorStatus
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', dialog_parent=cwBase, /error)
    return
  endif

  ; combo box event...pass along the selected send node to the scu object

  wState = widget_info(ev.top, find_by_uname='storscustatebase')
  widget_control, wState, get_uvalue = pstate

  widget_control, ev.id, get_value = wstrings
  (*pstate).oscu->setproperty, storage_scp=wstrings[ev.index]
  (*pstate).store_scp = wstrings[ev.index]
  (*pstate).destinationAEN = wstrings[ev.index]

  sendPatDir = (*pstate).sendPatDir
  sendFilesDir = (*pstate).sendFilesDir
  destinationAEN = (*pstate).destinationAEN

  save, sendPatDir, sendFilesDir, destinationAEN, FILENAME=(*pstate).prefsFile

end

;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_btnSendFiles_event
;;
;; Purpose:
;;   Event handler for the Send Files button
;;
;; Parameters:
;;   EV - widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_btnSendFiles_event, ev
  compile_opt idl2

  catch, errorStatus
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    cw_dicomex_stor_ui_enable, ev
    widget_control, (*pstate).wbtnCancelSF, sensitive=0
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(ev.top, find_by_uname='storscustatebase')
  widget_control, wState, get_uvalue = pstate

  if ((*pstate).stor_scp_cnt eq 0) then begin
    widget_control, (*pstate).wtxtStatus, set_value = 'You will need to configure ' + $
                    'at least one Storage SCP node before you can do a send.'
    return
  endif

  ; clear the status text widget
  widget_control, (*pstate).wtxtStatus, set_value=''

  ; ensure
  (*pstate).oscu->setproperty, storage_scp = (*pstate).store_scp

  widget_control, (*pstate).wbtnCancelSF, sensitive=1
  cw_dicomex_stor_ui_disable, ev

  if ((*pstate).sendFilesDir ne '') then begin
    path=file_dirname((*pstate).sendFilesDir)
  endif else begin
    path=!dir
  endelse

  files = dialog_pickfile(title='Pick file(s) to send', path=path, $
                          /multiple_files, DIALOG_PARENT=ev.top)

  if (files[0] eq '') then begin
    widget_control, (*pstate).wbtnCancelSF, sensitive=0
    cw_dicomex_stor_ui_enable, ev
    return
  endif

  (*pstate).sendfilesdir = files[0]

  cnt = (*pstate).oscu->send(files)

  widget_control, (*pstate).wbtnCancelSF, sensitive=0
  cw_dicomex_stor_ui_enable, ev

end

;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_scui_callback
;;
;; Purpose:
;;   Callback routine for the Storage SCU object
;;
;; Parameters:
;;   STATUS - flag
;;
;;   DATA - Information
;;
;; Keywords:
;;   NONE
;;
function cw_dicomex_scui_callback, status, data
  compile_opt idl2

  catch, errorStatus
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', dialog_parent=cwBase, /error)
    return, 1
  endif

  ; this method needs to be kept as short as possible since it is being called:
  ; - as a callback from the stor scu object that is sending files

  ; add the text sent form the sscu obj in the status parameter to the list box
  widget_control, (*data).wtxtStatus, set_value = status, /append

  ; make the last line written visible
  lastchar = widget_info((*data).wtxtStatus, /text_number)
  xypos = widget_info((*data).wtxtStatus, TEXT_OFFSET_TO_XY=lastchar-1)

  if (xypos[1] GT (*data).txtLines) then begin
    widget_control, (*data).wtxtStatus,    set_text_top_line = xypos[1] - (*data).txtLines
  endif

  ; check to see if the user pressed the cancel button
  weQ = widget_event((*data).wbtnCancelSPD, /nowait)
  weR = widget_event((*data).wbtnCancelSF, /nowait)

  if (weQ.id EQ (*data).wbtnCancelSPD) then begin
    return, 0
  endif

  if (weR.id EQ (*data).wbtnCancelSF) then begin
    return, 0
  endif

  return, 1

end

;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_scui_kill_event
;;
;; Purpose:
;;   Called when the main UI is destroyed
;;
;; Parameters:
;;   ID - widget ID
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_scui_kill_event, id
  compile_opt idl2

  catch, errorStatus
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    return
  endif

  ; we let go of objects and pointers

  widget_control, id, get_uvalue = pstate

  if ptr_valid(pstate) then begin
    obj_destroy, (*pstate).ocfg
    obj_destroy, (*pstate).oscu

    sendPatDir = (*pstate).sendPatDir
    sendFilesDir = (*pstate).sendFilesDir
    destinationAEN = (*pstate).destinationAEN

    save, sendPatDir, sendFilesDir, destinationAEN, FILENAME=(*pstate).prefsFile


    if ptr_valid((*pstate).pxFiles) then begin
      ptr_free, (*pstate).pxFiles
    endif

    ptr_free, pstate
  endif

end

;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_storscu_set_value
;;
;; Purpose:
;;   Routine to handle information from outside the widget, e.g.,
;;   refresh requests.
;;
;; Parameters:
;;   ID - Widget ID
;;
;;   VALUE - value set by the widget_control call
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_storscu_set_value, id, value
  compile_opt idl2

  catch, errorStatus
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', dialog_parent=cwBase, /error)
    return
  endif

  ;; value should be structure
  IF (size(value, /type) NE 8) THEN return

  CASE tag_names(value,/structure_name) OF
    'REFRESH' : BEGIN

      ;; return if refresh is not set
      IF (value.refresh EQ 0) THEN return

      wState = widget_info(id, find_by_uname='storscustatebase')

      ;; if wState is 0 then tab did not get created
      if (wState eq 0) then begin
        return
      endif

      widget_control, wState, get_uvalue = pstate

      obj_destroy,  (*pstate).ocfg
      obj_destroy,  (*pstate).oscu

      ;; re-create a config object so it reloads the config
      (*pstate).ocfg = obj_new('IDLffDicomExCfg')

      ;; re-create a sscu obj so it reloads the config
      (*pstate).oscu = obj_new('IDLffDicomExStorScu')

      ;; empty out the combo
      num = widget_info((*pstate).wcbSendTo, /combobox_number)
      if (num ne 0) then begin
        for ii=num, 0, -1 do begin
          widget_control, (*pstate).wcbSendTo, combobox_deleteitem = ii
        endfor
      endif

      ;; load the remote node drop down -----------------
      storscpaes = (*pstate).ocfg->GetApplicationEntities(count=count, $
                                                          SERVICE_TYPE='Storage_SCP')
      for xx = 0, count-1 do begin
        widget_control, (*pstate).wcbSendTo, $
                        combobox_additem=storscpaes[xx].APPLENTITYNAME
      endfor

      ;; set state var to be used in retrieve event
      (*pstate).stor_scp_cnt = count
      (*pstate).store_scp = ''
      if (count GT 0) then begin
        (*pstate).store_scp = storscpaes[0].APPLENTITYNAME
      endif

      ;; give the state ptr to the sscu obj
      (*pstate).oscu->SetProperty, callback_data = pstate
      (*pstate).oscu->setproperty, CALLBACK_FUNCTION='cw_dicomex_scui_callback'

      if ((*pstate).stor_scp_cnt eq 0) then $
        widget_control, (*pstate).wtxtStatus, set_value = 'You will need to configure ' + $
                        'at least one Storage SCP node before you can do a send.', /append

    END
    ELSE :
  ENDCASE

end

;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_scui_realize_notify_event
;;
;; Purpose:
;;   Realization routine
;;
;; Parameters:
;;   ID - Widget ID
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_scui_realize_notify_event, id
  compile_opt idl2

  catch, errorStatus
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(id, find_by_uname='storscustatebase')
  widget_control, wState, get_uvalue = pstate

  ; load the remote node drop down -----------------
  ; also see if the see saved destAEN is in the current app entity list if it is then restore it
  foundDestAENIdx = -1
  storscpaes = (*pstate).ocfg->GetApplicationEntities(count=count, SERVICE_TYPE='Storage_SCP')
  for xx = 0, count-1 do begin
    widget_control, (*pstate).wcbSendTo, combobox_additem = storscpaes[xx].APPLENTITYNAME
    if ((*pstate).destinationAEN eq storscpaes[xx].APPLENTITYNAME) then begin
       foundDestAENIdx = xx
    endif
  endfor

  ; set state var to be used in retrieve event
  (*pstate).stor_scp_cnt = count
  (*pstate).store_scp = ''

  if (foundDestAENIdx ne -1) then begin
    (*pstate).store_scp = storscpaes[foundDestAENIdx].APPLENTITYNAME
    widget_control, (*pstate).wcbSendTo, SET_COMBOBOX_SELECT=foundDestAENIdx
  endif else begin
    if (count GT 0) then begin
      (*pstate).store_scp = storscpaes[0].APPLENTITYNAME
    endif
  endelse

  ; get the number of visible lines in the status text window
  winfowtxtStatus = widget_info((*pstate).wtxtStatus,/geometry)
  (*pstate).txtLines = winfowtxtStatus.ysize - 2

  ; cancel is only enabled when a q or r is underway
  widget_control, (*pstate).wbtnCancelSPD, sensitive=0
  widget_control, (*pstate).wbtnCancelSF, sensitive=0

  ; give the state ptr to the sscu obj
  (*pstate).oscu->SetProperty, callback_data = pstate
  (*pstate).oscu->setproperty, CALLBACK_FUNCTION='cw_dicomex_scui_callback'

  if ((*pstate).stor_scp_cnt eq 0) then $
    widget_control, (*pstate).wtxtStatus, set_value = 'You will need to configure ' + $
                    'at least one Storage SCP node before you can do a send.', /append

end

;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_stor_scu
;;
;; Parameters:
;;   PARENT - Widget ID
;;
;; Keywords:
;;   NONE
;;
function cw_dicomex_stor_scu, parent
  compile_opt idl2
  on_error, 2

  ; this is the base for all the widgets in the stor scu ui
  wBase = widget_base(parent, /COLUMN, PRO_SET_VALUE='cw_dicomex_storscu_set_value', $
                      NOTIFY_REALIZE='cw_dicomex_scui_realize_notify_event', space=5)

  wBaseState = widget_base(wBase, uname='storscustatebase', $
                           kill_notify='cw_dicomex_scui_kill_event')

  ; ------- add the send to frame
  wbaseSCP = widget_base(wBase)
  wLblSCP = widget_label(wbaseSCP, value=' Send ', xoffset=5)
  winfoLblSCP = widget_info(wLblSCP, /geometry)
  wbaseFrSCP = widget_base(wbaseSCP, /frame, yoffset=winfoLblSCP.ysize/2, $
                           /row, space=20, ypad=10, xpad=10)
  wLblSCP = widget_label(wbaseSCP, value=' Send ', xoffset=5)

  ; add the send to drop down
  wlblSendTo = widget_label(wbaseFrSCP, value = 'Destination Node', xsize = 95)
  wcbSendTo = widget_combobox(wbaseFrSCP, xsize=185, $
                              event_pro = 'cw_dicomex_cbSendTo_event')

  ; -------- add the send patient data frame
  wbaseSPD = widget_base(wBase)
  wLblSPD = widget_label(wbaseSPD, value=' Send Patient Data ', xoffset=5)
  winfoLblSPD = widget_info(wLblSPD, /geometry)
  wbaseFrSPD = widget_base(wbaseSPD, /frame, yoffset=winfoLblSPD.ysize/2, /row, $
                           space=20, ypad=10, xpad=10)
  wLblSPD = widget_label(wbaseSPD, value=' Send Patient Data ', xoffset=5)

  ; add some bases to the send patient data frame
  wbaseFrSPDc = widget_base(wbaseFrSPD, /col)
  wbaseFrSPDr = widget_base(wbaseFrSPDc, /row)
  wbaseFrSPDrc = widget_base(wbaseFrSPDc, /row, space=20)

  ; add the pat tree to the send patient data frame
  wtree = widget_tree(wbaseFrSPDr, ysize=220, xsize=200)
  wtrePatients = widget_tree(wtree,  UNAME='TRE_PATIENTS', value='Patient Ids', $
                             /FOLDER, /EXPANDED, event_pro='cw_dicomex_sc_tree_node_event')

  ; add the patient info list to the send patient data frame
  wtxtPatInfo = widget_text(wbaseFrSPDr, value='', /scroll, UNAME='TXT_PATINFO', xsize=91)

  ; add 2 btns to send patient data frame
  wbtnSelDirSPD = widget_button(wbaseFrSPDrc, xsize=150, value='Select Directory', $
                                UNAME='BTN_SEL_DIR', $
                                event_pro='cw_dicomex_btnSelDir_event')
  wbtnSendSPD = widget_button(wbaseFrSPDrc, xsize=150, value='Send Patient Files', $
                              UNAME='BTN_SEND_PAT_FILES', $
                              event_pro='cw_dicomex_btnSendPatFiles_event')
  wbtnCancelSPD = widget_button(wbaseFrSPDrc, xsize=150, value='Cancel', $
                                UNAME='BTN_CANCELSPD')
  winfoFrSPD = widget_info(wbaseFrSPD, /geometry)

  ; --------- add the send files frame
  wbaseSF = widget_base(wBase)
  wLblSF = widget_label(wbaseSF, value=' Send File(s)', xoffset=5)
  winfoLblSF = widget_info(wLblSF, /geometry)
  wbaseFrSF = widget_base(wbaseSF, /frame, yoffset=winfoLblSF.ysize/2, /row, $
                          space=20, ypad=10, xpad=15)
  wLblSF = widget_label(wbaseSF, value=' Send File(s)', xoffset=5)

  ; add the 2 btns to the send files frame
  wbtnSendFiles = widget_button(wbaseFrSF, xsize=150, value='Browse/Send Files', $
                                UNAME='BTN_SEND_FILES', $
                                event_pro='cw_dicomex_btnSendFiles_event')
  wbtnCancelSF = widget_button(wbaseFrSF, xsize=150, value='Cancel', UNAME='BTN_CANCELSF')

  ;;add the status frame -------------------------------
  wbaseStatus  = widget_base(wBase)
  wlblStatus = widget_label(wbaseStatus, value=' Status ', xoffset=5)
  winfolblStatus = widget_info(wlblStatus, /geometry)
  wbaseFrStatus = widget_base(wbaseStatus, /frame, yoffset=winfolblStatus.ysize/2, $
                              /row, space=20, ypad=10, xpad=10)
  wlblStatus = widget_label(wbaseStatus, value=' Status ', xoffset=5)
  wtxtStatus = widget_text(wbaseFrStatus, value='', /scroll, UNAME='TXT_STATUS', $
                           ysize=9, scr_xsize=winfoFrSPD.xsize-30)

  widget_control, wbaseFrSCP, xsize=winfoFrSPD.xsize
  widget_control, wbaseFrSF, xsize=winfoFrSPD.xsize
  widget_control, wbaseFrStatus, xsize=winfoFrSPD.xsize

  ; create a config object
  ocfg = obj_new('IDLffDicomExCfg')

  ; create a sscu obj ---------
  oscu = obj_new('IDLffDicomExStorScu')

  ; these values are set in the notify_realize event
  stor_scp_cnt = 0
  store_scp = ''
  txtLines = 0

  ; starting values
  treeNodeSel = 0
  treeNodeSelIdx = -2

  sendFilesDir = ''
  sendPatDir = ''
  destinationAEN = ''

  AuthorDirname = 'RSI'
  AuthorDesc = 'Research Systems, Inc.'
  AppDirname = 'Dicomex_Network_Services'
  AppDesc = 'DicomEx Network Services UI'
  AppReadmeText = ['Author: rsi', 'DicomEx Storage SCU UI properties']
  AppReadmeVersion = 1
  dir = APP_USER_DIR(AuthorDirname, AuthorDesc, AppDirname, AppDesc, AppReadmeText, $
                     AppReadmeVersion)
  prefsFile = filepath(ROOT_DIR=dir, 'stor_scu_ui_prefs.sav')
  if (file_test(prefsFile, /REGULAR)) then begin
    restore, prefsFile
  endif

  ;; the state gets passed to the  sccu obj and the sscu obj passes it
  ;; back as call back param
  scui_state = {ocfg:ocfg, oscu:oscu,  wtree:wtree, wtrePatients:wtrePatients, $
                wtxtPatInfo:wtxtPatInfo, wtxtStatus:wtxtStatus, wcbSendTo:wcbSendTo, $
                wbtnSelDirSPD:wbtnSelDirSPD, wbtnSendSPD:wbtnSendSPD, $
                wbtnCancelSPD:wbtnCancelSPD, wbtnSendFiles:wbtnSendFiles, $
                wbtnCancelSF:wbtnCancelSF,  wBase:wBase, txtLines:txtLines, $
                store_scp:store_scp, stor_scp_cnt:stor_scp_cnt, $
                sendFilesDir:sendFilesDir, destinationAEN:destinationAEN, $
                sendPatDir:sendPatDir, treeNodeSel:treeNodeSel, $
                treeNodeSelIdx:treeNodeSelIdx, uniqueValue:100, prefsFile:prefsFile, $
                pxFiles:ptr_new()}

  ; passing a ptr is much more efficient
  pstate = ptr_new(scui_state)

  ;; put the state ptr in the uvalue of the base state widget so all
  ;; events can get the state
  widget_control, wBaseState, set_uvalue=pstate

  return, wBase

end
