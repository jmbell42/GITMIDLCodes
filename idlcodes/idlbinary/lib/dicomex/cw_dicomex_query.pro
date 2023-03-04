; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/dicomex/cw_dicomex_query.pro#1 $
; Copyright (c) 2004-2006, Research Systems, Inc.  All rights reserved.
;   Unauthorized reproduction prohibited.
;+
; NAME:
;   cw_dicomex_query
;
; PURPOSE:
;   This widget a UI front end to an underlying dicomex config object.
;   This UI allows the user to perform dicom queries and dicom retrieves.
;
; CALLING SEQUENCE:
;
;   ID = CW_DICOMEX_QUERY(WID)
;
; INPUTS:
;
;   WID - Widget ID of the parent
;
; KEYWORD PARAMETERS:
;
;   NONE
;
; NOTES:
;
;   query_model
;     0 = patient_root
;     1 = study_root
;     2 = patient_study_only
;
;   query_level
;     0 = patient
;     1 = study
;     2 = series
;     3 = image
;
; MODIFICATION HISTORY:
;   Written by:  LFG, RSI, August 2004
;   Modified by:  AGEH, RSI, December 2004    Tweaked code, added comments.
;
;-

;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_createqueryxmlfile
;;
;; Purpose:
;;   Create Query field XML file for saving build query options
;;
;; Parameters:
;;   FILENAME - Name of file in which to save values
;;
;;   QFPSTATE - Query field state structure
;;
;; Keywords:
;;   NONE
;;
PRO cw_dicomex_createqueryxmlfile, filename
  compile_opt idl2

  oDocument = obj_new('IDLffXMLDOMDocument')

  oElement = oDocument->createElement('Build_Queries')
  oBuild = oDocument->appendChild(oElement)

  oDocument->save, filename=filename, /pretty_print
  obj_destroy, oDocument

END


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_savequery_addtag
;;
;; Purpose:
;;   Add/Replace a tag value in a saved query
;;
;; Parameters:
;;   ODOCUMENT - an IDLffXMLDOMDocument object
;;
;;   OQUERY - a query object that exists in oDocument
;;
;;   TAGNAME - name of tag
;;
;;   TAGVALUE - value of tag
;;
;; Keywords:
;;   NONE
;;
PRO cw_dicomex_savequery_addtag, oDocument, oQuery, tagName, tagValue
  compile_opt idl2

  oNodeList = oQuery->GetElementsByTagName(tagName)
  IF (oNodeList->GetLength() EQ 0) THEN BEGIN
    oElement = oDocument->createElement(tagName)
    oVoid = oQuery->appendChild(oElement)
    oElementText = oDocument->createTextNode(tagValue)
    oVoid = oElement->appendChild(oElementText)
  ENDIF ELSE BEGIN
    oElement = oNodeList->item(0)
    oElementText = oElement->GetFirstChild()
    IF ~obj_valid(oElementText) THEN BEGIN
      oElementText = oDocument->createTextNode(tagValue)
      oVoid = oElement->appendChild(oElementText)
    ENDIF ELSE BEGIN
      oElementText->SetNodeValue, tagValue
    ENDELSE
  ENDELSE

END


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_savequery
;;
;; Purpose:
;;   Save build query options
;;
;; Parameters:
;;   FILENAME - Name of file in which to save values
;;
;;   SAVENAME - Name of query to be saved
;;
;;   QFPSTATE - Query field state structure
;;
;;   QFXVALUES - A structure containing all the information from the
;;               build query dialog
;;
;; Keywords:
;;   NONE
;;
PRO cw_dicomex_savequery, filename, savename, qfpstate, qfxValues
  compile_opt idl2

  path = dicomex_getconfigfilepath()
  dir = file_dirname(path, /mark_directory)
  file = dir+filename

  savename = idl_validname(savename, /convert_all)

  ;; if file does not exist then create one
  IF ~file_test(file) THEN $
    cw_dicomex_createqueryxmlfile, file

  ;; open file
  oDocument = obj_new('IDLffXMLDOMDocument')
  oDocument->Load, FILENAME=file

  ;; get build query element
  oNodeList = oDocument->GetElementsByTagName('Build_Queries')
  oBuild = oNodeList->item(0)

  oQueryList = oBuild->GetElementsByTagName(savename)
  IF (oQueryList->GetLength() EQ 0) THEN BEGIN
    oQuery = oDocument->createElement(savename)
    oVoid = oBuild->appendChild(oQuery)
  ENDIF ELSE BEGIN
    oQuery = oQueryList->item(0)
  ENDELSE

  cw_dicomex_savequery_addtag, oDocument, oQuery, 'QModel', strtrim(qfxValues.qmodel,2)
  cw_dicomex_savequery_addtag, oDocument, oQuery, 'QLevel', strtrim(qfxValues.qlevel,2)
  cw_dicomex_savequery_addtag, oDocument, oQuery, 'Family_Name', qfxValues.family_name
  cw_dicomex_savequery_addtag, oDocument, oQuery, 'Given_Name', qfxValues.given_name
  cw_dicomex_savequery_addtag, oDocument, oQuery, 'Middle_Name', qfxValues.middle_name
  cw_dicomex_savequery_addtag, oDocument, oQuery, 'Prefix', qfxValues.prefix
  cw_dicomex_savequery_addtag, oDocument, oQuery, 'Suffix', qfxValues.suffix
  cw_dicomex_savequery_addtag, oDocument, oQuery, 'Patient_ID', qfxValues.patient_id
  cw_dicomex_savequery_addtag, oDocument, oQuery, 'Study_Date', qfxValues.study_date
  cw_dicomex_savequery_addtag, oDocument, oQuery, 'Study_Time', qfxValues.study_time
  cw_dicomex_savequery_addtag, oDocument, oQuery, 'Accession_Number', qfxValues.accession_number
  cw_dicomex_savequery_addtag, oDocument, oQuery, 'Study_ID', qfxValues.study_id
  cw_dicomex_savequery_addtag, oDocument, oQuery, 'Modality', qfxValues.modality

  ;; save information
  oDocument->Save, FILENAME=file, /PRETTY_PRINT
  obj_destroy, oDocument

END


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_restorequeryxmlfile
;;
;; Purpose:
;;   Restores query values
;;
;; Parameters:
;;   FILENAME - Name of file in which to save values
;;
;;   QUERYNAME - Name of query to restore
;;
;;   QFPSTATE - Query fields state pointer
;;
;; Keywords:
;;   NONE
;;
PRO cw_dicomex_restorequeryxmlfile, filename, queryname, qfpstate
  compile_opt idl2

  qfStruct = cw_dicomex_getquery(filename, queryname)

  ;; model value
  value = qfStruct.qmodel
  (*qfpstate).qfmodel = value
  CASE fix(value) OF
    0 : widget_control, (*qfpstate).wradPatientModel, set_button=1
    1 : widget_control, (*qfpstate).wradStudyModel, set_button=1
    ELSE :
  ENDCASE

  ;; level value
  value = qfStruct.qlevel
  (*qfpstate).qflevel = value
  CASE fix(value) OF
    0 : widget_control, (*qfpstate).wradPatientLvl, set_button=1
    1 : widget_control, (*qfpstate).wradStudyLvl, set_button=1
    2 : widget_control, (*qfpstate).wradSeriesLvl, set_button=1
    ELSE :
  ENDCASE

  ;; family name
  value = qfStruct.family_name
  widget_control, (*qfpstate).wtxtFamily, set_value=value

  ;; given name
  value = qfStruct.given_name
  widget_control, (*qfpstate).wtxtGiven, set_value=value

  ;; middle name
  value = qfStruct.middle_name
  widget_control, (*qfpstate).wtxtMiddle, set_value=value

  ;; prefix
  value = qfStruct.prefix
  widget_control, (*qfpstate).wtxtPrefix, set_value=value

  ;; suffix
  value = qfStruct.suffix
  widget_control, (*qfpstate).wtxtSuffix, set_value=value

  ;; patient id
  value = qfStruct.patient_id
  widget_control, (*qfpstate).wtxtPatientId, set_value=value

  ;; study date
  value = qfStruct.study_date
  widget_control, (*qfpstate).wtxtDate, set_value=value

  ;; study time
  value = qfStruct.study_time
  widget_control, (*qfpstate).wtxtTime, set_value=value

  ;; accession number
  value = qfStruct.accession_number
  widget_control, (*qfpstate).wtxtAccess, set_value=value

  ;; study id
  value = qfStruct.study_id
  widget_control, (*qfpstate).wtxtStudyId, set_value=value

  ;; modality
  value = qfStruct.modality
  widget_control, (*qfpstate).wtxtModality, set_value=value

END


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_getquery
;;
;; Purpose:
;;   Returns build query options for a given named query
;;
;; Parameters:
;;   FILENAME - Name of file in which to save values
;;
;;   QUERYNAME - Name of query to restore
;;
;; Keywords:
;;   NONE
;;
FUNCTION cw_dicomex_getquery, filename, queryname
  compile_opt idl2

  path = dicomex_getconfigfilepath()
  dir = file_dirname(path, /mark_directory)
  file = dir+filename

  queryname = idl_validname(queryname, /convert_all)

  qfStruct = cw_dicomex_CreateQFStruct()

  ;; if file does not exist then bail
  IF ~file_test(file) THEN $
    return, qfStruct

  ;; open file
  oDocument = obj_new('IDLffXMLDOMDocument')
  oDocument->Load, FILENAME=file

  ;; get build query element
  oNodeList = oDocument->GetElementsByTagName('Build_Queries')
  oBuild = oNodeList->item(0)
  IF ~obj_valid(oBuild) THEN return, qfStruct

  oQueryList = oBuild->GetElementsByTagName(queryname)
  oQuery = oQueryList->item(0)
  IF ~obj_valid(oQuery) THEN return, qfStruct

  ;; model value
  oNodeList = oQuery->GetElementsByTagName('QModel')
  oElement = oNodeList->item(0)
  oElementText = oElement->GetFirstChild()
  value = oElementText->GetNodeValue()
  qfStruct.qmodel = value

  ;; level value
  oNodeList = oQuery->GetElementsByTagName('QLevel')
  oElement = oNodeList->item(0)
  oElementText = oElement->GetFirstChild()
  value = oElementText->GetNodeValue()
  qfStruct.qlevel = value

  ;; family name
  oNodeList = oQuery->GetElementsByTagName('Family_Name')
  oElement = oNodeList->item(0)
  oElementText = oElement->GetFirstChild()
  value = obj_valid(oElementText) ? oElementText->GetNodeValue() : ''
  qfStruct.family_name = value

  ;; given name
  oNodeList = oQuery->GetElementsByTagName('Given_Name')
  oElement = oNodeList->item(0)
  oElementText = oElement->GetFirstChild()
  value = obj_valid(oElementText) ? oElementText->GetNodeValue() : ''
  qfStruct.given_name = value

  ;; middle name
  oNodeList = oQuery->GetElementsByTagName('Middle_Name')
  oElement = oNodeList->item(0)
  oElementText = oElement->GetFirstChild()
  value = obj_valid(oElementText) ? oElementText->GetNodeValue() : ''
  qfStruct.middle_name = value

  ;; prefix
  oNodeList = oQuery->GetElementsByTagName('Prefix')
  oElement = oNodeList->item(0)
  oElementText = oElement->GetFirstChild()
  value = obj_valid(oElementText) ? oElementText->GetNodeValue() : ''
  qfStruct.prefix = value

  ;; suffix
  oNodeList = oQuery->GetElementsByTagName('Suffix')
  oElement = oNodeList->item(0)
  oElementText = oElement->GetFirstChild()
  value = obj_valid(oElementText) ? oElementText->GetNodeValue() : ''
  qfStruct.suffix = value

  ;; patient id
  oNodeList = oQuery->GetElementsByTagName('Patient_ID')
  oElement = oNodeList->item(0)
  oElementText = oElement->GetFirstChild()
  value = obj_valid(oElementText) ? oElementText->GetNodeValue() : ''
  qfStruct.patient_id = value

  ;; study date
  oNodeList = oQuery->GetElementsByTagName('Study_Date')
  oElement = oNodeList->item(0)
  oElementText = oElement->GetFirstChild()
  value = obj_valid(oElementText) ? oElementText->GetNodeValue() : ''
  qfStruct.study_date = value

  ;; study time
  oNodeList = oQuery->GetElementsByTagName('Study_Time')
  oElement = oNodeList->item(0)
  oElementText = oElement->GetFirstChild()
  value = obj_valid(oElementText) ? oElementText->GetNodeValue() : ''
  qfStruct.study_time = value

  ;; accession number
  oNodeList = oQuery->GetElementsByTagName('Accession_Number')
  oElement = oNodeList->item(0)
  oElementText = oElement->GetFirstChild()
  value = obj_valid(oElementText) ? oElementText->GetNodeValue() : ''
  qfStruct.accession_number = value

  ;; study id
  oNodeList = oQuery->GetElementsByTagName('Study_ID')
  oElement = oNodeList->item(0)
  oElementText = oElement->GetFirstChild()
  value = obj_valid(oElementText) ? oElementText->GetNodeValue() : ''
  qfStruct.study_id = value

  ;; modality
  oNodeList = oQuery->GetElementsByTagName('Modality')
  oElement = oNodeList->item(0)
  oElementText = oElement->GetFirstChild()
  value = obj_valid(oElementText) ? oElementText->GetNodeValue() : ''
  qfStruct.modality = value

  obj_destroy, oDocument

  return, qfStruct

END


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_CreateQFStruct
;;
;; Purpose:
;;   Create Query field structure
;;
;; Parameters:
;;   NONE
;;
;; Keywords:
;;   NONE
;;
function cw_dicomex_CreateQFStruct
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  ;; a struct that contains all the query field values this struct is
  ;; filled in by the query field ui.  when the ok, clear, or apply
  ;; btns are pressed it is then passed to the main query ui

  xQF = create_struct(    'qmodel',           0,  $
                          'qlevel',           0,  $
                          'family_name',       '', $
                          'given_name',          '', $
                          'middle_name',       '', $
                          'prefix',           '', $
                          'suffix',           '', $
                          'patient_id',          '', $
                          'study_instance_uid',     '', $
                          'study_id',        '', $
                          'study_date',          '', $
                          'study_time',          '', $
                          'accession_number',   '', $
                          'series_instance_uid',    '', $
                          'series_number',      '', $
                          'modality',        '', $
                          'sop_instance_uid',   '', $
                          'instance_number',      '' )

  return, xQF

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_qfGetQFValues
;;
;; Purpose:
;;   Assemble all the query field values
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
function cw_dicomex_qfGetQFValues, ev
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  ;; get all the qf values from there corresponding text widgets and
  ;; put them into a struct and pass them to the main query ui

  ;; the qf state has all the needed widget ids
  wState = widget_info(ev.top, find_by_uname='qfstatebase')
  widget_control, wState, get_uvalue = qfpstate

  widget_control, (*qfpstate).wtxtFamily, get_value=fami
  widget_control, (*qfpstate).wtxtGiven, get_value=give
  widget_control, (*qfpstate).wtxtMiddle, get_value=midd
  widget_control, (*qfpstate).wtxtPrefix, get_value=pref
  widget_control, (*qfpstate).wtxtSuffix, get_value=suff
  widget_control, (*qfpstate).wtxtPatientId, get_value=pati
  widget_control, (*qfpstate).wtxtDate, get_value=date
  widget_control, (*qfpstate).wtxtTime, get_value=time
  widget_control, (*qfpstate).wtxtAccess, get_value=acce
  widget_control, (*qfpstate).wtxtStudyId, get_value=stud
  widget_control, (*qfpstate).wtxtModality, get_value=moda

  qfxValues = cw_dicomex_CreateQFStruct()

  qfxValues.qmodel = (*qfpstate).qfmodel
  qfxValues.qlevel = (*qfpstate).qflevel
  qfxValues.family_name = fami
  qfxValues.given_name = give
  qfxValues.middle_name = midd
  qfxValues.prefix = pref
  qfxValues.suffix = suff
  qfxValues.patient_id = pati
  qfxValues.study_instance_uid = ''
  qfxValues.study_id = stud
  qfxValues.study_date = date
  qfxValues.study_time = time
  qfxValues.accession_number = acce
  qfxValues.series_instance_uid = ''
  qfxValues.series_number = ''
  qfxValues.modality = moda
  qfxValues.sop_instance_uid = ''
  qfxValues.instance_number = ''

  return, qfxValues

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_qfFieldState
;;
;; Purpose:
;;   Enable and disable the qf txt widgets based on the currently
;;   selected model and level
;;
;; Parameters:
;;   QFPSTATE - A pointer to the widget's state structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_qfFieldState, qfpstate
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  if (((*qfpstate).qfModel eq 0) && ((*qfpstate).qfLevel eq 0)) then begin
    widget_control, (*qfpstate).wradPatientLvl, sensitive = 1
    widget_control, (*qfpstate).wtxtFamily, sensitive = 1
    widget_control, (*qfpstate).wtxtGiven, sensitive = 1
    widget_control, (*qfpstate).wtxtMiddle, sensitive = 1
    widget_control, (*qfpstate).wtxtPrefix, sensitive = 1
    widget_control, (*qfpstate).wtxtSuffix, sensitive = 1
    widget_control, (*qfpstate).wtxtPatientId, sensitive = 1
    widget_control, (*qfpstate).wtxtDate, sensitive = 0
    widget_control, (*qfpstate).wtxtTime, sensitive = 0
    widget_control, (*qfpstate).wtxtAccess, sensitive = 0
    widget_control, (*qfpstate).wtxtStudyId, sensitive = 0
    widget_control, (*qfpstate).wtxtModality, sensitive = 0
  endif

  if (((*qfpstate).qfModel eq 0) && ((*qfpstate).qfLevel eq 1)) then begin
    widget_control, (*qfpstate).wradPatientLvl, sensitive = 1
    widget_control, (*qfpstate).wtxtFamily, sensitive = 0
    widget_control, (*qfpstate).wtxtGiven, sensitive = 0
    widget_control, (*qfpstate).wtxtMiddle, sensitive = 0
    widget_control, (*qfpstate).wtxtPrefix, sensitive = 0
    widget_control, (*qfpstate).wtxtSuffix, sensitive = 0
    widget_control, (*qfpstate).wtxtPatientId, sensitive = 1
    widget_control, (*qfpstate).wtxtDate, sensitive = 1
    widget_control, (*qfpstate).wtxtTime, sensitive = 1
    widget_control, (*qfpstate).wtxtAccess, sensitive = 1
    widget_control, (*qfpstate).wtxtStudyId, sensitive = 1
    widget_control, (*qfpstate).wtxtModality, sensitive = 0
  endif

  if (((*qfpstate).qfModel eq 0) && ((*qfpstate).qfLevel eq 2)) then begin
    widget_control, (*qfpstate).wradPatientLvl, sensitive = 1
    widget_control, (*qfpstate).wtxtFamily, sensitive = 0
    widget_control, (*qfpstate).wtxtGiven, sensitive = 0
    widget_control, (*qfpstate).wtxtMiddle, sensitive = 0
    widget_control, (*qfpstate).wtxtPrefix, sensitive = 0
    widget_control, (*qfpstate).wtxtSuffix, sensitive = 0
    widget_control, (*qfpstate).wtxtPatientId, sensitive = 1
    widget_control, (*qfpstate).wtxtDate, sensitive = 0
    widget_control, (*qfpstate).wtxtTime, sensitive = 0
    widget_control, (*qfpstate).wtxtAccess, sensitive = 0
    widget_control, (*qfpstate).wtxtStudyId, sensitive = 0
    widget_control, (*qfpstate).wtxtModality, sensitive = 1
  endif

  if (((*qfpstate).qfModel eq 1) && ((*qfpstate).qfLevel eq 1)) then begin
    widget_control, (*qfpstate).wradPatientLvl, sensitive = 0
    widget_control, (*qfpstate).wtxtFamily, sensitive = 1
    widget_control, (*qfpstate).wtxtGiven, sensitive = 1
    widget_control, (*qfpstate).wtxtMiddle, sensitive = 1
    widget_control, (*qfpstate).wtxtPrefix, sensitive = 1
    widget_control, (*qfpstate).wtxtSuffix, sensitive = 1
    widget_control, (*qfpstate).wtxtPatientId, sensitive = 1
    widget_control, (*qfpstate).wtxtDate, sensitive = 1
    widget_control, (*qfpstate).wtxtTime, sensitive = 1
    widget_control, (*qfpstate).wtxtAccess, sensitive = 1
    widget_control, (*qfpstate).wtxtStudyId, sensitive = 1
    widget_control, (*qfpstate).wtxtModality, sensitive = 0
  endif

  if (((*qfpstate).qfModel eq 1) && ((*qfpstate).qfLevel eq 2)) then begin
    widget_control, (*qfpstate).wradPatientLvl, sensitive = 0
    widget_control, (*qfpstate).wtxtFamily, sensitive = 1
    widget_control, (*qfpstate).wtxtGiven, sensitive = 1
    widget_control, (*qfpstate).wtxtMiddle, sensitive = 1
    widget_control, (*qfpstate).wtxtPrefix, sensitive = 1
    widget_control, (*qfpstate).wtxtSuffix, sensitive = 1
    widget_control, (*qfpstate).wtxtPatientId, sensitive = 1
    widget_control, (*qfpstate).wtxtDate, sensitive = 0
    widget_control, (*qfpstate).wtxtTime, sensitive = 0
    widget_control, (*qfpstate).wtxtAccess, sensitive = 0
    widget_control, (*qfpstate).wtxtStudyId, sensitive = 0
    widget_control, (*qfpstate).wtxtModality, sensitive = 1
  endif

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_qfradPatientModel_event
;;
;; Purpose:
;;   Event handler for the patient root radio button
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_qfradPatientModel_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  ; the qf state has all the needed widget ids
  wState = widget_info(ev.top, find_by_uname='qfstatebase')
  widget_control, wState, get_uvalue = qfpstate

  if (ev.select eq 1) then begin
    (*qfpstate).qfModel = 0
    widget_control, (*qfpstate).wradPatientLvl, sensitive = 1
    cw_dicomex_qfFieldState, qfpstate
  endif

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_qfradStudyModel_event
;;
;; Purpose:
;;   Event handler for the study root radio button
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_qfradStudyModel_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', dialog_parent=cwBase, /error)
    return
  endif

  ; the qf state has all the needed widget ids
  wState = widget_info(ev.top, find_by_uname='qfstatebase')
  widget_control, wState, get_uvalue = qfpstate

  if (ev.select eq 1) then begin
    (*qfpstate).qfModel = 1

    if ((*qfpstate).qfLevel eq 0) then begin
      widget_control, (*qfpstate).wradPatientLvl, set_button=0
      widget_control, (*qfpstate).wradStudyLvl, set_button=1
      (*qfpstate).qfLevel = 1
    endif

    widget_control, (*qfpstate).wradPatientLvl, sensitive = 0
    cw_dicomex_qfFieldState, qfpstate
  endif

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_qfradPatientLvl_event
;;
;; Purpose:
;;   Event handler for the patient level radio button
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_qfradPatientLvl_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', dialog_parent=cwBase, /error)
    return
  endif

  ; the qf state has all the needed widget ids
  wState = widget_info(ev.top, find_by_uname='qfstatebase')
  widget_control, wState, get_uvalue = qfpstate

  if (ev.select eq 1) then begin
    (*qfpstate).qfLevel = 0
    cw_dicomex_qfFieldState, qfpstate
  endif

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_qfradStudyLvl_event
;;
;; Purpose:
;;   Event handler for the study level radio button
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_qfradStudyLvl_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  ; the qf state has all the needed widget ids
  wState = widget_info(ev.top, find_by_uname='qfstatebase')
  widget_control, wState, get_uvalue = qfpstate

  if (ev.select eq 1) then begin
    (*qfpstate).qfLevel = 1
    cw_dicomex_qfFieldState, qfpstate
  endif

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_qfradSeriesLvl_event
;;
;; Purpose:
;;   Event handler for the series level radio button
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_qfradSeriesLvl_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  ; the qf state has all the needed widget ids
  wState = widget_info(ev.top, find_by_uname='qfstatebase')
  widget_control, wState, get_uvalue = qfpstate

  if (ev.select eq 1) then begin
    (*qfpstate).qfLevel = 2
    cw_dicomex_qfFieldState, qfpstate
  endif

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_qfbtnClear_event
;;
;; Purpose:
;;   Event handler for the clear button
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_qfbtnClear_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  ; the qf state has all the needed widget ids
  wState = widget_info(ev.top, find_by_uname='qfstatebase')
  widget_control, wState, get_uvalue = qfpstate

  ; clear all the widget text fields
  widget_control, (*qfpstate).wtxtFamily, set_value=''
  widget_control, (*qfpstate).wtxtGiven, set_value=''
  widget_control, (*qfpstate).wtxtMiddle, set_value=''
  widget_control, (*qfpstate).wtxtPrefix, set_value=''
  widget_control, (*qfpstate).wtxtSuffix, set_value=''
  widget_control, (*qfpstate).wtxtPatientId, set_value=''
  widget_control, (*qfpstate).wtxtDate, set_value=''
  widget_control, (*qfpstate).wtxtTime, set_value=''
  widget_control, (*qfpstate).wtxtAccess, set_value=''
  widget_control, (*qfpstate).wtxtStudyId, set_value=''
  widget_control, (*qfpstate).wtxtModality, set_value=''

  xQFValues = cw_dicomex_qfGetQFValues(ev)
  cw_dicomex_SetQFValues, xQFValues, (*qfpstate).wBaseUI

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_qfbtnOk_event
;;
;; Purpose:
;;   Event handler for the OK button
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;  NONE
;;
pro cw_dicomex_qfbtnOk_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  ; the qf state has all the needed widget ids
  wState = widget_info(ev.top, find_by_uname='qfstatebase')
  widget_control, wState, get_uvalue = qfpstate

  ; get the qf's from the text widgets
  xQFValues = cw_dicomex_qfGetQFValues(ev)

  ; give the main ui a copy of the query fields
  cw_dicomex_SetQFValues, xQFValues, (*qfpstate).wBaseUI

  ; hide the qf ui window
  widget_control, (*qfpstate).wqfBase, map = 0

  ;; save the values
  cw_dicomex_savequery, (*qfpstate).queryFile, 'Use current query', qfpstate, xQFValues

end


;;--------------------------------------------------------------------------
;;NAME
;;  cw_dicomex_qfbtnApply_event
;;
;;Purpose:
;;  Event handler for the Apply button
;;
;;Parameters:
;;  EV - Widget event structure
;;
;;Keywords:
;;  NONE
;;
pro cw_dicomex_qfbtnApply_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  ; the qf state has all the needed widget ids
  wState = widget_info(ev.top, find_by_uname='qfstatebase')
  widget_control, wState, get_uvalue = qfpstate

  ; get the qf's from the text widgets
  xQFValues = cw_dicomex_qfGetQFValues(ev)

  ; give the main ui a copy of the query fields
  cw_dicomex_SetQFValues, xQFValues, (*qfpstate).wBaseUI

  ;; save the values
  cw_dicomex_savequery, (*qfpstate).queryFile, 'Use current query', qfpstate, xQFValues

end


;;----------------------------------------------------------------------------
;;NAME
;;  cw_dicomex_qfbtnCancel_event
;;
;;Purpose:
;;  Event handler for the Cancel button
;;
;;Parameters:
;;  EV - Widget event structure
;;
;;Keywords:
;;  NONE
;;
pro cw_dicomex_qfbtnCancel_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  ; the qf state has all the needed widget ids
  wState = widget_info(ev.top, find_by_uname='qfstatebase')
  widget_control, wState, get_uvalue = qfpstate

  ; hide the qf ui window
  widget_control, (*qfpstate).wqfBase, map = 0

  ;; restore the values for next time
  cw_dicomex_restorequeryxmlfile, (*qfpstate).queryFile, 'Use current query', qfpstate
  cw_dicomex_qfFieldState, qfpstate

end


;;----------------------------------------------------------------------------
;;NAME
;;  cw_dicomex_qfbtnHelp_event
;;
;;Purpose:
;;  Event handler for the Help button.  Displays help text in a dialog.
;;
;;Parameters:
;;  EV - Widget event structure
;;
;;Keywords:
;;  NONE
;;
PRO cw_dicomex_qfbtnHelp_event, ev
  compile_opt idl2

  online_help, 'DICOMEX_NET_QUERY'

END


;;----------------------------------------------------------------------------
;;NAME
;;  cw_dicomex_qfui_event
;;
;;Purpose:
;;  Main event handler for the Query Fields UI
;;
;;Parameters:
;;  EV - Widget event structure
;;
;;Keywords:
;;  NONE
;;
pro cw_dicomex_qfui_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  ; just unmap (hide) the qf ui window when killed via the X title bar btn
  if (tag_names(ev, /structure_name) EQ 'WIDGET_KILL_REQUEST') then begin
    widget_control,ev.id,map=0
  endif

end


;;----------------------------------------------------------------------------
;;NAME
;;  cw_dicomex_dlQueries_event
;;
;;Purpose:
;;  Event handler for the Current query droplist
;;
;;Parameters:
;;  EV - Widget event structure
;;
;;Keywords:
;;  NONE
;;
PRO cw_dicomex_dlQueries_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(ev.top, find_by_uname='querystatebase')
  widget_control, wState, get_uvalue = pstate

  ;; Currently swallow events.
  index = widget_info((*pstate).wdlQueries, /droplist_select)
  (*pstate).queryIdx = index

  queryIdx = (*pstate).queryIdx
  queryAEN = (*pstate).queryAEN
  destinationAEN = (*pstate).destinationAEN
  save, queryIdx, queryAEN, destinationAEN, FILENAME=(*pstate).prefsFile



END


;;----------------------------------------------------------------------------
;;NAME
;;  cw_dicomex_btnBuild_event
;;
;;Purpose:
;;  Event handler for the Build Query button.  This creates and
;;  displays the query field ui (qfui)
;;
;;Parameters:
;;  EV - Widget event structure
;;
;;Keywords:
;;  NONE
;;
pro cw_dicomex_btnBuild_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(ev.top, find_by_uname='querystatebase')
  widget_control, wState, get_uvalue = pstate

  idqf = (*pstate).wQFUI
  valid_qfid = widget_info(idqf, /valid_id)
  if (valid_qfid eq 1) then begin
    widget_control, (*pstate).wQFUI, map=1
    return
  endif

  ; constants used to align labels and text edit boxes into lined up columns
  width = 300
  lxsize = width-20
  boxsize = 0.60
  textsize = 0.35

  ; this is the base for all the widgets in the query fields ui
  wqfBase = widget_base(/col, TITLE='Query Fields', group=ev.top, /float, $
                        xoffset=852, yoffset=0, tlb_frame_attr=1)

  wqfStateBase = widget_base(wqfBase, uname='qfstatebase')

  ; base for the model and level frames ------------------------
  wbaseML = widget_base(wqfBase, /row)

  ; add the model frame
  wbaseModel = widget_base(wbaseML)
  wlblModel = widget_label(wbaseModel, value=' Query Model ', xoffset=5)
  winfolblModel = widget_info(wlblModel, /geometry)
  wbaseFrModel = widget_base(wbaseModel, /frame, yoffset=winfolblModel.ysize/2, $
                             xsize=width/2, /col, space=0, ypad=5, xpad=10)
  wlblModel = widget_label(wbaseModel, value=' Query Model ', xoffset=5)

  wbaseRadModel = widget_base(wbaseFrModel, /exclusive)
  wradPatientModel = widget_button(wbaseRadModel, value="Patient Root", $
                                   event_pro='cw_dicomex_qfradPatientModel_event')
  wradStudyModel = widget_button(wbaseRadModel, value="Study Root", $
                                 event_pro='cw_dicomex_qfradStudyModel_event')
  widget_control, wradPatientModel, set_button=1

  ; add the level frame
  wbaseLvl = widget_base(wbaseML)
  wlblLvl = widget_label(wbaseLvl, value=' Query Level ', xoffset=5)
  winfolblLvl = widget_info(wlblLvl, /geometry)
  wbaseFrLvl = widget_base(wbaseLvl, /frame, yoffset=winfolblLvl.ysize/2, $
                           xsize=width/2, /col, space=0, ypad=5, xpad=10)
  wlblLvl = widget_label(wbaseLvl, value=' Query Level ', xoffset=5)

  wbaseRadLvl = widget_base(wbaseFrLvl, /exclusive)
  wradPatientLvl = widget_button(wbaseRadLvl, value="Patient Level", $
                                 event_pro='cw_dicomex_qfradPatientLvl_event')
  wradStudyLvl = widget_button(wbaseRadLvl, value="Study Level", $
                               event_pro='cw_dicomex_qfradStudyLvl_event')
  wradSeriesLvl = widget_button(wbaseRadLvl, value="Series Level", $
                                event_pro='cw_dicomex_qfradSeriesLvl_event')
  widget_control, wradPatientLvl, set_button=1

  ; base for the patient, study, and series frames
  wbasePSS = widget_base(wqfBase, /col)

  ; add the patient frame
  wbasePat = widget_base(wBasePSS)
  wlblPat = widget_label(wbasePat, value=' Patient Fields ', xoffset=5)
  winfolblPat = widget_info(wlblPat, /geometry)
  wbaseFrPat = widget_base(wbasePat, /frame, yoffset=winfolblPat.ysize/2, $
                           xsize=width, /col, space=0, ypad=5, xpad=10, tab_mode=1)
  wlblPat = widget_label(wbasePat, value=' Patient Fields ', xoffset=5)

  wbaseR1 = widget_base(wbaseFrPat, /row)
  wlblFamily = widget_label(wbaseR1, value='Family Name', xsize=lxsize*textsize, $
                            /align_right)
  wtxtFamily = widget_text(wbaseR1, /editable, scr_xsize=lxsize*boxsize, ysize=1)
  wbaseR2 = widget_base(wbaseFrPat, /row)
  wlblGiven = widget_label(wbaseR2, value='Given Name', xsize=lxsize*textsize, /align_right)
  wtxtGiven = widget_text(wbaseR2, /editable, scr_xsize=lxsize*boxsize, ysize=1)
  wbaseR3 = widget_base(wbaseFrPat, /row)
  wlblMiddle = widget_label(wbaseR3, value='Middle Name', xsize=lxsize*textsize, $
                            /align_right)
  wtxtMiddle = widget_text(wbaseR3, /editable, scr_xsize=lxsize*boxsize, ysize=1)
  wbaseR4 = widget_base(wbaseFrPat, /row)
  wlblPrefix = widget_label(wbaseR4, value='Prefix ', xsize=lxsize*textsize, /align_right)
  wtxtPrefix = widget_text(wbaseR4, /editable, scr_xsize=lxsize*boxsize, ysize=1)
  wbaseR5 = widget_base(wbaseFrPat, /row)
  wlblSuffix = widget_label(wbaseR5, value='Suffix ', xsize=lxsize*textsize, /align_right)
  wtxtSuffix = widget_text(wbaseR5, /editable, scr_xsize=lxsize*boxsize, ysize=1)
  wbaseR6 = widget_base(wbaseFrPat, /row)
  wlblPatientId = widget_label(wbaseR6, value='Patient Id', xsize=lxsize*textsize, $
                               /align_right)
  wtxtPatientId = widget_text(wbaseR6, /editable, scr_xsize=lxsize*boxsize, ysize=1)


  ; add the study frame
  wbaseStdy = widget_base(wBasePSS)
  wlblStdy = widget_label(wbaseStdy, value=' Study Fields', xoffset=5)
  winfolblStdy = widget_info(wlblStdy, /geometry)
  wbaseFrStdy = widget_base(wbaseStdy, /frame, yoffset=winfolblStdy.ysize/2, $
                            xsize=width, /col, space=0, ypad=5, xpad=10, tab_mode=1)
  wlblStdy = widget_label(wbaseStdy, value=' Study Fields', xoffset=5)

  wbaseR11 = widget_base(wbaseFrStdy, /row)
  wlblDate = widget_label(wbaseR11, value='Study Date', xsize=lxsize*textsize, $
                          /align_right)
  wtxtDate = widget_text(wbaseR11, /editable, scr_xsize=lxsize*boxsize, ysize=1)

  wbaseR12 = widget_base(wbaseFrStdy, /row)
  wlblTime = widget_label(wbaseR12, value='Study Time', xsize=lxsize*textsize, $
                          /align_right)
  wtxtTime = widget_text(wbaseR12, /editable, scr_xsize=lxsize*boxsize, ysize=1)

  wbaseR13 = widget_base(wbaseFrStdy, /row)
  wlblAccess = widget_label(wbaseR13, value='Accession Number', $
                            xsize=lxsize*textsize, /align_right)
  wtxtAccess = widget_text(wbaseR13, /editable, scr_xsize=lxsize*boxsize, ysize=1)

  wbaseR14 = widget_base(wbaseFrStdy, /row)
  wlblStudyId = widget_label(wbaseR14, value='Study Id', xsize=lxsize*textsize, $
                             /align_right)
  wtxtStudyId = widget_text(wbaseR14, /editable, scr_xsize=lxsize*boxsize, ysize=1)


  ; add the series frame
  wbaseSeri = widget_base(wBasePSS)
  wlblSeri = widget_label(wbaseSeri, value=' Series Fields', xoffset=5)
  winfolblSeri = widget_info(wlblSeri, /geometry)
  wbaseFrSeri = widget_base(wbaseSeri, /frame, yoffset=winfolblSeri.ysize/2, $
                            xsize=width, /col, space=0, ypad=5, xpad=10)
  wlblSeri = widget_label(wbaseSeri, value=' Series Fields', xoffset=5)

  wbaseR21 = widget_base(wbaseFrSeri, /row)
  wlblModality = widget_label(wbaseR21, value='Modality', $
                              xsize=lxsize*textsize, /align_right)
  wtxtModality = widget_text(wbaseR21, /editable, scr_xsize=lxsize*boxsize, ysize=1)

  ; add the buttons
  buttonSize = lxsize/5
  wbaseBtns = widget_base(wBasePSS, /row, /align_center)
  wbtnqfClear = widget_button(wbaseBtns, value=' Clear ', xsize=buttonSize, $
                              event_pro='cw_dicomex_qfbtnClear_event')
  wbtnqfOk = widget_button(wbaseBtns, value=' OK ', xsize=buttonSize, $
                           event_pro='cw_dicomex_qfbtnOk_event')
  wbtnqfCancel = widget_button(wbaseBtns, value=' Cancel ', xsize=buttonSize, $
                               event_pro='cw_dicomex_qfbtnCancel_event')
  wbtnqfApply = widget_button(wbaseBtns, value=' Apply ', xsize=buttonSize, $
                              event_pro='cw_dicomex_qfbtnApply_event')
  wbtnqfHelp = widget_button(wbaseBtns, value=' Help ', xsize=buttonSize, $
                             event_pro='cw_dicomex_qfbtnHelp_event')


  ; make it real --------------------
  widget_control, wqfBase, /real, event_pro='cw_dicomex_qfui_event', /tlb_kill_request_events

  ;; the state gets passed to the  qr obj and the qr obj passes it
  ;; back as call back param
  qfstate = { wqfBase:wqfBase, wtxtFamily:wtxtFamily, wtxtGiven:wtxtGiven, $
              wtxtMiddle:wtxtMiddle, wtxtPrefix:wtxtPrefix, wtxtSuffix:wtxtSuffix, $
              wtxtPatientId:wtxtPatientId, wtxtDate:wtxtDate, wtxtTime:wtxtTime, $
              wtxtAccess:wtxtAccess, wtxtStudyId:wtxtStudyId, $
              wtxtModality:wtxtModality, wradPatientModel:wradPatientModel, $
              wradStudyModel:wradStudyModel, wradPatientLvl:wradPatientLvl, $
              wradStudyLvl:wradStudyLvl, wradSeriesLvl:wradSeriesLvl, $
              wdlQueries:(*pstate).wdlQueries, $
              queryFile: (*pstate).queryFile, qfmodel:0, qflevel:0, wBaseUI:ev.top}

  ; passing a ptr is much more efficient
  qfpstate = ptr_new(qfstate)

  ;; put the state ptr in the uvalue of the base obj so all events can
  ;; get the state
  widget_control, wqfStateBase, set_uvalue=qfpstate

  ;; restore saved values
  cw_dicomex_restorequeryxmlfile, (*pstate).queryFile, 'Use current query', qfpstate
  ; init the text widget states to be enable or disabled
  cw_dicomex_qfFieldState, qfpstate

  ; save the widget id for the qf base in the primary ui state
  (*pstate).wQFUI = wqfBase

  ; make the y size of the model and level boxes the same
  wbaseInfoFrLvl = widget_info(wbaseFrLvl, /geometry)
  widget_control, wbaseFrModel, ysize= wbaseInfoFrLvl.ysize

  ; get the qf's from the text widgets
  xQFValues = cw_dicomex_qfGetQFValues({top:wqfBase})

  ; give the main ui a copy of the query fields
  cw_dicomex_SetQFValues, xQFValues, qfstate.wBaseUI

end

;;*******************************************************************
;;*******************************************************************
;;end the query fields ui
;;*******************************************************************
;;*******************************************************************


;;----------------------------------------------------------------------------
;;NAME
;;  cw_dicomex_SetQFValues
;;
;;Purpose:
;;  called by the query fields UI to pass the query fields to the main UI
;;
;;Parameters:
;;  XQFVALUES - query fields values
;;
;;  ID - Widget ID
;;
;;Keywords:
;;  NONE
;;
pro cw_dicomex_SetQFValues, xQFValues, id
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  wState = widget_info(id, find_by_uname='querystatebase')
  widget_control, wState, get_uvalue = pstate

  (*pstate).xQFValues = xQFValues

end


;;----------------------------------------------------------------------------
;;NAME
;;  cw_dicomex_cbRetrieve_event
;;
;;Purpose:
;;  Event handler for the Destination Node combobox
;;
;;Parameters:
;;  EV - Widget event structure
;;
;;Keywords:
;;  NONE
;;
pro cw_dicomex_cbRetrieve_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  ; pass along the selected retrieve node to the query object

  wState = widget_info(ev.top, find_by_uname='querystatebase')
  widget_control, wState, get_uvalue = pstate

  widget_control, ev.id, get_value = wstrings
  (*pstate).oqr->setproperty, storage_scp=wstrings[ev.index]
  (*pstate).store_scp = wstrings[ev.index]
  (*pstate).destinationAEN = wstrings[ev.index]

  queryIdx = (*pstate).queryIdx
  queryAEN = (*pstate).queryAEN
  destinationAEN = (*pstate).destinationAEN
  save, queryIdx, queryAEN, destinationAEN, FILENAME=(*pstate).prefsFile

end


;;----------------------------------------------------------------------------
;;NAME
;;  cw_dicomex_cbQuery_event
;;
;;Purpose:
;;  Event handler for the Query Node combobox
;;
;;Parameters:
;;  EV - Widget event structure
;;
;;Keywords:
;;  NONE
;;
pro cw_dicomex_cbQuery_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  ; pass along the selected query node to the query object

  wState = widget_info(ev.top, find_by_uname='querystatebase')
  widget_control, wState, get_uvalue = pstate

  widget_control, ev.id, get_value = wstrings
  (*pstate).oqr->setproperty, query_scp=wstrings[ev.index]
  (*pstate).query_scp = wstrings[ev.index]
  (*pstate).queryAEN = wstrings[ev.index]

  queryIdx = (*pstate).queryIdx
  queryAEN = (*pstate).queryAEN
  destinationAEN = (*pstate).destinationAEN
  save, queryIdx, queryAEN, destinationAEN, FILENAME=(*pstate).prefsFile

end


;;----------------------------------------------------------------------------
;;NAME
;;  cw_dicomex_query_ui_disable
;;
;;Purpose:
;;  Desensitize some of the buttons/comboboxes
;;
;;Parameters:
;;  EV - Widget event structure
;;
;;Keywords:
;;  NONE
;;
pro cw_dicomex_query_ui_disable, ev
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  wState = widget_info(ev.top, find_by_uname='querystatebase')
  widget_control, wState, get_uvalue = pstate

  ; disable the btns
  widget_control, (*pstate).wbtnBldQuery, sensitive=0
  widget_control, (*pstate).wbtnQuery, sensitive=0
  widget_control, (*pstate).wbtnRetrieve, sensitive=0
  widget_control, (*pstate).wcbQuery, sensitive=0
  widget_control, (*pstate).wcbRetrieve, sensitive=0

end


;;----------------------------------------------------------------------------
;;NAME
;;  cw_dicomex_query_ui_enable
;;
;;Purpose:
;;  Sensitize some of the buttons/comboboxes
;;
;;Parameters:
;;  EV - Widget event structure
;;
;;Keywords:
;;  NONE
;;
pro cw_dicomex_query_ui_enable, ev
  compile_opt idl2
  on_error, 2                   ; return errors to caller


  wState = widget_info(ev.top, find_by_uname='querystatebase')
  widget_control, wState, get_uvalue = pstate

  ; enable the btns
  widget_control, (*pstate).wbtnBldQuery, sensitive=1
  widget_control, (*pstate).wbtnQuery, sensitive=1
  widget_control, (*pstate).wbtnRetrieve, sensitive=1
  widget_control, (*pstate).wcbQuery, sensitive=1
  widget_control, (*pstate).wcbRetrieve, sensitive=1

end


;;----------------------------------------------------------------------------
;;NAME
;;  cw_dicomex_table_results_event
;;
;;Purpose:
;;  Event handler for the Results table widget
;;
;;Parameters:
;;  EV - Widget event structure
;;
;;Keywords:
;;  NONE
;;
pro cw_dicomex_table_results_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    if (haveNames eq 1) then begin
      widget_control, ev.id, set_uvalue = names, /no_copy
    endif
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  ; left click on a row in the results table and its corresponding
  ; node in the tree is high lighted

  haveNames = 0

  ; is this a cell select event
  if (ev.type eq 4) then begin
    wState = widget_info(ev.top, find_by_uname='querystatebase')
    widget_control, wState, get_uvalue = pstate


    ; get the table's uvalue... an array of strings
    widget_control, ev.id, get_uvalue = names, /no_copy
    haveNames = 1

    ; determine which row was selected
    sel = widget_info(ev.id, /table_select)

    ; this is a work around for a bug in the table widget
    if (sel[1] eq -1 && sel[3] eq -1) then begin
      sel[1] = 0
      sel[3] = 0
    endif

    if (sel[1] eq sel[3]) then begin

    ; get the unique tree node uname store in the tables uvalue
      name = names[sel[1]]
      if (name ne '') then begin

        ; get the widget id for this unique name
        ; we start the search in the tree widget
        wid = widget_info((*pstate).wtreResults, find_by_uname=name)
        if (wid ne 0) then begin

          ; select and highlight the tree node
          widget_control, wid, /set_tree_select
          widget_control, wid, /set_tree_visible


            ; get the unique name of the node
		  name = widget_info(wid, /uname)

		  ;; split the unique name into it two parts the first part of the
		  ;; node name is a unique numberthe second part of the node name is
		  ;; the index of the node (the index is zero based from starting from
		  ;; the first node at it's level)
		  split = strsplit(name, ' ', /extract)

		  ; nn is the node level index
		  nn = fix(split[1])

		  ; store the selected node widget id and index
		  ; the index is the zero based from the first node at this level
		  (*pstate).treeNodeSel    = wid
		  (*pstate).treeNodeSelIdx    = nn

        endif
      endif
    endif
    ; restore the array of strings
    widget_control, ev.id, set_uvalue = names, /no_copy
  endif

end


;;----------------------------------------------------------------------------
;;NAME
;;  cw_dicomex_load_table
;;
;;Purpose:
;;  Fills in the results table using the array of structs held by
;;  node zero at each level of the tree the column names are updated
;;  based on the node selected
;;
;;Parameters:
;;  WTABLE - Widget ID of the table
;;
;;  CNT - Number of rows
;;
;;  MODEL - NOT USED
;;
;;  LEVEL - Patient level
;;
;;  XRESULTS - Pointer to results
;;
;;Keywords:
;;  NONE
;;
pro cw_dicomex_load_table, wTable, cnt, model, level, xResults
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  numrows = cnt
  if (numrows lt 12) then begin
    numrows = 12
  endif

  widget_control, wTable, ysize = numrows

  ; show patient level data...all the patients are listed
  if (level eq 0) then begin

    xRow  = create_struct( 'patient_id', '', $,
                           'family_name', '', $
                           'given_name', '', $
                           'middle_name', '', $
                           'prefix', '', $
                           'suffix', '')

    xRows = replicate(xRow, numrows)

    for xx = 0, cnt-1 do begin
      xRows[xx].patient_id = xResults[xx].patient_id
      xRows[xx].family_name = xResults[xx].family_name
      xRows[xx].given_name = xResults[xx].given_name
      xRows[xx].middle_name = xResults[xx].middle_name
      xRows[xx].prefix = xResults[xx].prefix
      xRows[xx].suffix = xResults[xx].suffix
    endfor

    if (cnt gt 0) then begin

      colnames = ['Patient Id', 'Family', 'Given', 'Middle', 'Prefix', 'Suffix']
      widget_control, wTable, column_labels = colnames

      colwidths = [200, 100, 100, 50, 50, 50]
      widget_control, wTable, column_widths = colwidths

      widget_control, wTable, set_value = xRows
    endif

  endif


  ; show study level data...all the studies for a patient are listed
  if (level eq 1) then begin

    xRow  = create_struct( 'study_instance_uid', '', $,
                           'study_id', '', $
                           'study_date', '', $
                           'study_time', '', $
                           'accession_number', '')

    xRows = replicate(xRow, numrows)

    for xx = 0, cnt-1 do begin
      xRows[xx].study_instance_uid = xResults[xx].study_instance_uid
      xRows[xx].study_id = xResults[xx].study_id
      xRows[xx].study_date = xResults[xx].study_date
      xRows[xx].study_time = xResults[xx].study_time
      xRows[xx].accession_number = xResults[xx].accession_number
    endfor

    if (cnt gt 0) then begin

      colnames = ['Study Instance UID', 'Study Id', 'Study Date', 'Study Time', 'Accession #']
      widget_control, wTable, column_labels = colnames

      colwidths = [200, 100, 100, 100, 100]
      widget_control, wTable, column_widths = colwidths

      widget_control, wTable, set_value = xRows
    endif
  endif

  ; show series level data...all the series for a study are listed
  if (level eq 2) then begin

    xRow  = create_struct( 'series_instance_uid', '', $,
                           'series_number', '', $
                           'modality', '')

    xRows = replicate(xRow, numrows)

    for xx = 0, cnt-1 do begin
      xRows[xx].series_instance_uid = xResults[xx].series_instance_uid
      xRows[xx].series_number = xResults[xx].series_number
      xRows[xx].modality = xResults[xx].modality
    endfor

    if (cnt gt 0) then begin

      colnames = ['Series Instance UID', 'Series Number', 'Modality']
      widget_control, wTable, column_labels = colnames

      colwidths = [300, 200, 50]
      widget_control, wTable, column_widths = colwidths

      widget_control, wTable, set_value = xRows
    endif
  endif

  ; show image level data...all the images for a series are listed
  if (level eq 3) then begin

    xRow  = create_struct( 'sop_instance_uid', '', $,
                           'instance_number', '')

    xRows = replicate(xRow, numrows)

    for xx = 0, cnt-1 do begin
      xRows[xx].sop_instance_uid = xResults[xx].sop_instance_uid
      xRows[xx].instance_number = xResults[xx].instance_number
    endfor

    if (cnt gt 0) then begin

      colnames = ['SOP Instance UID', 'Image Number']
      widget_control, wTable, column_labels = colnames

      colwidths = [300, 200]
      widget_control, wTable, column_widths = colwidths

      widget_control, wTable, set_value = xRows
    endif
  endif

  ; create an array of strings
  ; one string for each row representing the corresponding tree node
  names = strarr(numrows)
  for xx = 0, cnt-1 do begin
    names[xx] = xResults[xx].name
  endfor

  ;; the uvalue of the table is given an array of strings containing
  ;; the unique name of the corresponding items in the tree...this
  ;; allows a table row click to high light a tree node
  widget_control, wTable, set_uvalue = names

  ; make the first row in table visble...does not seem to be needed
  ;;widget_control, wTable, set_table_view = [0,0]

  ;; this line of code will move the selection in the table to the
  ;; match the selection in the tree but has the side effect of moving
  ;; the table row selected to the top of the view port
  ;; widget_control, (*pstate).wtblResults,
  ;; SET_TABLE_SELECT=[0,nn,0,nn]

  ;; this line of code has the side effect of setting the first row to
  ;; negative one in the table so the table event must code around
  ;; this issue
  widget_control, wTable, SET_TABLE_SELECT=[-1,-1,-1,-1]

end


;;----------------------------------------------------------------------------
;;NAME
;;  cw_dicomex_create_node_struct
;;
;;Purpose:
;;  Creates the structure used to store information about nodes in
;;  the tree widget
;;
;;Parameters:
;;  NONE
;;
;;Keywords:
;;  NONE
;;
function cw_dicomex_create_node_struct
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  ;; an array of these structs that is put into node zero of each
  ;; level this array of structs contians info that needed to execute
  ;; sub queries this array of structs contains info that allows the
  ;; the results tableto be filled in when the user clicks on a node
  ;; in the tree

  xResult = create_struct('name', '', $
                          'cnt', 0,  $
                          'qmodel', 0,  $
                          'qlevel', 0,  $
                          'nlevel', 0,  $
                          'loaded', 0,  $
                          'patient_name', '', $
                          'family_name', '', $
                          'given_name', '', $
                          'middle_name', '', $
                          'prefix', '', $
                          'suffix', '', $
                          'patient_id', '', $
                          'study_instance_uid', '', $
                          'study_id', '', $
                          'study_date', '', $
                          'study_time', '', $
                          'accession_number', '', $
                          'series_instance_uid', '', $
                          'series_number', '', $
                          'modality', '', $
                          'sop_instance_uid', '', $
                          'instance_number', '')

  return, xResult

end


;;----------------------------------------------------------------------------
;;NAME
;;  cw_dicomex_qr_tree_node_event
;;
;;Purpose:
;;  Event handler for the tree widget
;;
;;Parameters:
;;  EV - Widget event structure
;;
;;Keywords:
;;  NONE
;;
pro cw_dicomex_qr_tree_node_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  ; this is called when the user left clicks a node in the tree

  ;; if the node is not loaded yet then a sub query is done and the
  ;; results of the sub query are added to the tree and the results
  ;; table is filled in with the items for the current level

  ;; if the node is loaded then a sub query is not done and the
  ;; results table is filled in with the items for the current level

  wState = widget_info(ev.top, find_by_uname='querystatebase')
  widget_control, wState, get_uvalue = pstate

  ; get the unique name of the node
  name = widget_info(ev.id, /uname)

  ; avoid sub queries on the patient_id root of tree when the tree is empty
  if (name eq 'TRE_RESULTS') then begin
    return
  endif

  ;; split the unique name into it two parts the first part of the
  ;; node name is a unique numberthe second part of the node name is
  ;; the index of the node (the index is zero based from starting from
  ;; the first node at it's level)
  split = strsplit(name, ' ', /extract)

  ; nn is the node level index
  nn = fix(split[1])

  ; when the tree is populated do not do sub queries on the root ('Patient Id's node)
  root = 0
  if (split[0] eq '0') then begin
    root = 1
    (*pstate).treeNodeSelIdx = -1
    return
  endif

  ;; get the array of structs describing the nodes at this level node
  ;; zero at this level holds the array of structs all other nodes at
  ;; this level point back to node zero
  if (nn ne 0) then begin
    widget_control, ev.id, get_uvalue = node_0_id, /no_copy
    widget_control, node_0_id, get_uvalue = xNode, /no_copy
  endif else begin
    widget_control, ev.id, get_uvalue = xNode, /no_copy
  endelse

  ; store the selected node widget id and index
  ; the index is the zero based from the first node at this level
  (*pstate).treeNodeSel    = ev.id
  (*pstate).treeNodeSelIdx    = nn

  ; a select event not on the root node
  if ((ev.type EQ 0) && (root ne 1)) then begin

    ; if the node is not load then do a sub query
    if (xNode[nn].loaded eq 0) then begin

      (*pstate).oqr->clearproperties

      ; study level sub query
      if (xNode[nn].nLevel eq 0) then begin
        isImage = 0
        (*pstate).oqr->setproperty, patient_id = xNode[nn].patient_id
      endif

      ; series level sub query
      if (xNode[nn].nLevel eq 1) then begin
        isImage = 0
        (*pstate).oqr->setproperty, patient_id = xNode[nn].patient_id
        (*pstate).oqr->setproperty, study_instance_uid = xNode[nn].study_instance_uid
      endif

      ; image level sub query
      if (xNode[nn].nLevel eq 2) then begin
        isImage = 1
        (*pstate).oqr->setproperty, patient_id = xNode[nn].patient_id
        (*pstate).oqr->setproperty, study_instance_uid = xNode[nn].study_instance_uid
        (*pstate).oqr->setproperty, series_instance_uid = xNode[nn].series_instance_uid
      endif

      (*pstate).oqr->setproperty, query_level = xNode[nn].nlevel+1
      (*pstate).oqr->setproperty, query_model = (*pstate).modelOnQuery
      (*pstate).oqr->setproperty, query_scp = (*pstate).query_scp
      (*pstate).oqr->setproperty, CALLBACK_FUNCTION='cw_dicomex_qr_callback'

      widget_control, (*pstate).wtxtStatus, set_value=''

      cw_dicomex_query_ui_disable, ev
      widget_control, (*pstate).wbtnCancelQ, sensitive=1

      ; run the query will not return until the query is finished, canceled or errors out
      vQRes = (*pstate).oqr->query(count=cnt)

      cw_dicomex_query_ui_enable, ev
      widget_control, (*pstate).wbtnCancelQ, sensitive=0

      ; this node is now loaded
      xNode[nn].loaded = 1

      xResult = cw_dicomex_create_node_struct()

      if (cnt GT 0) then begin
        xResults = replicate(xResult, cnt)
      endif

      ; display the result for this node
      for xx = 0, cnt-1 do begin

        (*pstate).uniqueValue = (*pstate).uniqueValue +1
        name = strtrim(string((*pstate).uniqueValue),2) + ' ' + strtrim(string(xx),2)
        xResults[xx].name = name ; each tree node has a uniqie uname to support find by uname
        xResults[xx].cnt = cnt
        xResults[xx].qmodel = (*pstate).xQFValues.qModel
        xResults[xx].qlevel = (*pstate).xQFValues.qlevel
        xResults[xx].nlevel = xNode[nn].nlevel+1
        xResults[xx].loaded = isImage
        xResults[xx].patient_name = vQRes[xx].patient_name
        xResults[xx].family_name = vQRes[xx].family_name
        xResults[xx].given_name = vQRes[xx].given_name
        xResults[xx].middle_name = vQRes[xx].middle_name
        xResults[xx].prefix = vQRes[xx].prefix
        xResults[xx].suffix = vQRes[xx].suffix
        xResults[xx].patient_id = vQRes[xx].patient_id
        xResults[xx].study_instance_uid = vQRes[xx].study_instance_uid
        xResults[xx].study_id = vQRes[xx].study_id
        xResults[xx].study_date = vQRes[xx].study_date
        xResults[xx].study_time = vQRes[xx].study_time
        xResults[xx].accession_number = vQRes[xx].accession_number
        xResults[xx].series_instance_uid = vQRes[xx].series_instance_uid
        xResults[xx].series_number = vQRes[xx].series_number
        xResults[xx].modality = vQRes[xx].modality
        xResults[xx].sop_instance_uid = vQRes[xx].sop_instance_uid
        xResults[xx].instance_number = vQRes[xx].instance_number

      endfor

      ; add the return sub query results as nodes to the tree
      ; nodes are added to the ev.id node
      for xx = 0, cnt-1 do begin

        ; results contain studies for a patient
        if (xResults[xx].nlevel eq 1) then begin
          if (xx eq 0) then begin
            vNode0 = widget_tree(ev.id, value=vQRes[xx].study_instance_uid, $
                                 uvalue=xResults, uname = xResults[xx].name, $
                                 /folder, event_pro='cw_dicomex_qr_tree_node_event')
          endif else begin
            vNode = widget_tree(ev.id, value=vQRes[xx].study_instance_uid, $
                                uvalue=vNode0, uname = xResults[xx].name, $
                                /folder, event_pro='cw_dicomex_qr_tree_node_event')
          endelse
        endif

        ; results contain series for a study
        if (xResults[xx].nlevel eq 2) then begin
          if (xx eq 0) then begin
            vNode0 = widget_tree(ev.id, value=vQRes[xx].series_instance_uid, $
                                 uvalue=xResults, uname = xResults[xx].name, $
                                 /folder, event_pro='cw_dicomex_qr_tree_node_event')
          endif else begin
            vNode = widget_tree(ev.id, value=vQRes[xx].series_instance_uid, $
                                uvalue=vNode0, uname = xResults[xx].name, $
                                /folder, event_pro='cw_dicomex_qr_tree_node_event')
          endelse
        endif

        ; the results conatain images for a series
        if (xResults[xx].nlevel eq 3) then begin
          if (xx eq 0) then begin
            vNode0 = widget_tree(ev.id, value=vQRes[xx].sop_instance_uid, $
                                 uvalue=xResults, uname = xResults[xx].name, $
                                 event_pro='cw_dicomex_qr_tree_node_event')
          endif else begin
            vNode = widget_tree(ev.id, value=vQRes[xx].sop_instance_uid, $
                                uvalue=vNode0, uname = xResults[xx].name, $
                                event_pro='cw_dicomex_qr_tree_node_event')
          endelse
        endif

      endfor
    endif
  endif

  ; when pushing into a loaded node update the results table with the info for this level
  cw_dicomex_load_table, (*pstate).wtblResults, xNode[0].cnt, xNode[0].qmodel, $
                         xNode[0].nlevel, xNode

  ; restore the array of structs or reference to the array of structs
  if (nn ne 0) then begin
    widget_control, node_0_id, set_uvalue = xNode, /no_copy
    widget_control, ev.id, set_uvalue = node_0_id, /no_copy
  endif else begin
    widget_control, ev.id, set_uvalue = xNode, /no_copy
  endelse

end


;;----------------------------------------------------------------------------
;;NAME
;;  cw_dicomex_SetQueryProperties
;;
;;Purpose:
;;  Sets the properties on the query object
;;
;;Parameters:
;;  PSTATE - Pointer to the state structure
;;
;;Keywords:
;;  NONE
;;
pro cw_dicomex_SetQueryProperties, pstate
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  ;; if droplist is set to all patients then clear fields
  index = widget_info((*pstate).wdlQueries, /droplist_select)
  IF ~index THEN BEGIN
    (*pstate).oqr->setproperty, query_level = 0
    (*pstate).oqr->setproperty, query_model = 0
    (*pstate).oqr->setproperty, family_name = ''
    (*pstate).oqr->setproperty, given_name = ''
    (*pstate).oqr->setproperty, middle_name = ''
    (*pstate).oqr->setproperty, prefix = ''
    (*pstate).oqr->setproperty, suffix = ''
    (*pstate).oqr->setproperty, patient_id = ''
    (*pstate).oqr->setproperty, study_instance_uid = ''
    (*pstate).oqr->setproperty, study_id = ''
    (*pstate).oqr->setproperty, study_date = ''
    (*pstate).oqr->setproperty, study_time = ''
    (*pstate).oqr->setproperty, accession_number = ''
    (*pstate).oqr->setproperty, series_instance_uid = ''
    (*pstate).oqr->setproperty, series_number = ''
    (*pstate).oqr->setproperty, modality = ''
    (*pstate).oqr->setproperty, sop_instance_uid = ''
    (*pstate).oqr->setproperty, instance_number = ''
    return
  ENDIF

  ;; get name of query to be loaded
  widget_control, (*pstate).wdlQueries, get_value=str
  queryName = str[index]
  ;; if Use current query and Query Fields widget exists then use the
  ;; latest results from that
  IF ((queryName EQ 'Use current query') && $
      widget_info((*pstate).wQFUI, /valid_id)) THEN BEGIN
    (*pstate).oqr->setproperty, query_level = (*pstate).xQFValues.qlevel
    (*pstate).oqr->setproperty, query_model = (*pstate).xQFValues.qModel
    (*pstate).oqr->setproperty, family_name = (*pstate).xQFValues.family_name
    (*pstate).oqr->setproperty, given_name = (*pstate).xQFValues.given_name
    (*pstate).oqr->setproperty, middle_name = (*pstate).xQFValues.middle_name
    (*pstate).oqr->setproperty, prefix = (*pstate).xQFValues.prefix
    (*pstate).oqr->setproperty, suffix = (*pstate).xQFValues.suffix
    (*pstate).oqr->setproperty, patient_id = (*pstate).xQFValues.patient_id
    (*pstate).oqr->setproperty, study_instance_uid = (*pstate).xQFValues.study_instance_uid
    (*pstate).oqr->setproperty, study_id = (*pstate).xQFValues.study_id
    (*pstate).oqr->setproperty, study_date = (*pstate).xQFValues.study_date
    (*pstate).oqr->setproperty, study_time = (*pstate).xQFValues.study_time
    (*pstate).oqr->setproperty, accession_number = (*pstate).xQFValues.accession_number
    (*pstate).oqr->setproperty, series_instance_uid = (*pstate).xQFValues.series_instance_uid
    (*pstate).oqr->setproperty, series_number = (*pstate).xQFValues.series_number
    (*pstate).oqr->setproperty, modality = (*pstate).xQFValues.modality
    (*pstate).oqr->setproperty, sop_instance_uid = (*pstate).xQFValues.sop_instance_uid
    (*pstate).oqr->setproperty, instance_number = (*pstate).xQFValues.instance_number
    return
  ENDIF

  ;; read current query from the XML file
  xQFValues = cw_dicomex_getquery((*pstate).queryfile, queryName)
  (*pstate).oqr->setproperty, query_level = fix(xQFValues.qlevel)
  (*pstate).oqr->setproperty, query_model = fix(xQFValues.qModel)
  (*pstate).oqr->setproperty, family_name = xQFValues.family_name
  (*pstate).oqr->setproperty, given_name = xQFValues.given_name
  (*pstate).oqr->setproperty, middle_name = xQFValues.middle_name
  (*pstate).oqr->setproperty, prefix = xQFValues.prefix
  (*pstate).oqr->setproperty, suffix = xQFValues.suffix
  (*pstate).oqr->setproperty, patient_id = xQFValues.patient_id
  (*pstate).oqr->setproperty, study_instance_uid = xQFValues.study_instance_uid
  (*pstate).oqr->setproperty, study_id = xQFValues.study_id
  (*pstate).oqr->setproperty, study_date = xQFValues.study_date
  (*pstate).oqr->setproperty, study_time = xQFValues.study_time
  (*pstate).oqr->setproperty, accession_number = xQFValues.accession_number
  (*pstate).oqr->setproperty, series_instance_uid = xQFValues.series_instance_uid
  (*pstate).oqr->setproperty, series_number = xQFValues.series_number
  (*pstate).oqr->setproperty, modality = xQFValues.modality
  (*pstate).oqr->setproperty, sop_instance_uid = xQFValues.sop_instance_uid
  (*pstate).oqr->setproperty, instance_number = xQFValues.instance_number

  return

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_alreadyExistsSeries
;;
;; Purpose:
;;   Returns true if the series already exists
;;
;; Parameters:
;;   SERIESUID - ID of the series
;;
;;   XRESULTS - Pointer to structure containing information about all
;;              the nodes in the tree
;;
;;   CNT - Number of items in the tree
;;
;; Keywords:
;;   NONE
;;
function cw_dicomex_alreadyExistsSeries, seriesUid, xResults, cnt
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  for xx = 0, cnt-1 do begin
    if (seriesUid eq xResults[xx].series_instance_uid) then return, 1
  endfor

  return, 0

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_alreadyExistsStudy
;;
;; Purpose:
;;   Returns true if the study already exists
;;
;; Parameters:
;;   STUDYUID - ID of the study
;;
;;   XRESULTS - Pointer to structure containing information about all
;;              the nodes in the tree
;;
;;   CNT - Number of items in the tree
;;
;; Keywords:
;;   NONE
;;
function cw_dicomex_alreadyExistsStudy, studyUid, xResults, cnt
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  for xx = 0, cnt-1 do begin
    if (studyUid eq xResults[xx].study_instance_uid) then return, 1
  endfor

  return, 0

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_alreadyExistsPatient
;;
;; Purpose:
;;   Returns true if the patient already exists
;;
;; Parameters:
;;   PATID - ID of the patient
;;
;;   XRESULTS - Pointer to structure containing information about all
;;              the nodes in the tree
;;
;;   CNT - Number of items in the tree
;;
;; Keywords:
;;   NONE
;;
function cw_dicomex_alreadyExistsPatient, patId, xResults, cnt
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  for xx = 0, cnt-1 do begin
    if (patId eq xResults[xx].patient_id) then return, 1
  endfor

  return, 0

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_createPatStruct
;;
;; Purpose:
;;   Create an array of structs containing all the unique patients in
;;   the result set study level query
;;
;; Parameters:
;;   VQRES - Pointer to query results
;;
;;   RESCNT - Number of results
;;
;;   PSTATE - Pointer to state structure
;;
;;   PATCNT - Number of patients
;;
;; Keywords:
;;   NONE
;;
function cw_dicomex_createPatStruct, vQres, resCnt, pstate, patCnt
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  ;; create an array of structs containing all the unique patients in
  ;; the result set study level query: the result set contains an
  ;; entry for each study returned series level query: the result set
  ;; contains an entry for each series returned

  xResult = cw_dicomex_create_node_struct()
  xResultsPat = replicate(xResult, resCnt)

  patCnt = 0

  for xx = 0, resCnt-1 do begin

    if (cw_dicomex_alreadyExistsPatient(vQres[xx].patient_id, $
                                        xResultsPat, patCnt) eq 1) then $
      continue

    (*pstate).uniqueValue = (*pstate).uniqueValue +1
    name = strtrim(string((*pstate).uniqueValue),2) + ' ' + strtrim(string(patCnt),2)
    xResultsPat[patCnt].name = name ;each tree node has a unique uname to support find by uname
    xResultsPat[patCnt].qmodel = 0
    xResultsPat[patCnt].qlevel = 0
    xResultsPat[patCnt].nlevel = 0
    xResultsPat[patCnt].loaded = 1
    xResultsPat[patCnt].patient_name = vQRes[xx].patient_name
    xResultsPat[patCnt].family_name = vQRes[xx].family_name
    xResultsPat[patCnt].given_name = vQRes[xx].given_name
    xResultsPat[patCnt].middle_name = vQRes[xx].middle_name
    xResultsPat[patCnt].prefix = vQRes[xx].prefix
    xResultsPat[patCnt].suffix = vQRes[xx].suffix
    xResultsPat[patCnt].patient_id = vQRes[xx].patient_id
    xResultsPat[patCnt].study_instance_uid = vQRes[xx].study_instance_uid
    xResultsPat[patCnt].study_id = vQRes[xx].study_id
    xResultsPat[patCnt].study_date = vQRes[xx].study_date
    xResultsPat[patCnt].study_time = vQRes[xx].study_time
    xResultsPat[patCnt].accession_number = vQRes[xx].accession_number
    xResultsPat[patCnt].series_instance_uid = vQRes[xx].series_instance_uid
    xResultsPat[patCnt].series_number = vQRes[xx].series_number
    xResultsPat[patCnt].modality = vQRes[xx].modality
    xResultsPat[patCnt].sop_instance_uid = vQRes[xx].sop_instance_uid
    xResultsPat[patCnt].instance_number = vQRes[xx].instance_number
    patCnt++

  endfor

  ; shrink the returned results to match the number of patients found
  xResultsPat = xResultsPat[0:patCnt-1]

  ; fix the count element so it matches the number of unique patients
  xResultsPat[*].cnt = patCnt

  return, xResultsPat

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_createStudyStruct
;;
;; Purpose:
;;   Create an array of structs containing all the unique studies for
;;   a given patient study level query
;;
;; Parameters:
;;   VQRES - Pointer to query results
;;
;;   RESCNT - Number of results
;;
;;   PATID - Patient ID
;;
;;   PSTATE - Pointer to state structure
;;
;;   STUDYCNT - Number of studies
;;
;;   LOADED - Whether or not the node has been loaded
;;
;; Keywords:
;;   NONE
;;
function cw_dicomex_createStudyStruct, vQres, resCnt, patId, pstate, studyCnt, loaded
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  ;; create an array of structs containing all the unique studies for
  ;; a given patient study level query: the result set contains an
  ;; entry for each study returned series level query: the result set
  ;; contains an entry for each series returned

  ; loop thru result set and find the patient of interest
  ; once we find the patient add all of it's studies to the study results

  studyCnt = 0
  xResult = cw_dicomex_create_node_struct()
  xResultsStud = replicate(xResult, resCnt)

  for xx = 0, resCnt-1 do begin

    ; loop thru all the results looking for a particular patient
    if (patId ne vQres[xx].patient_id) then begin
      continue
    endif

    ; a study can have more than one series
    if (cw_dicomex_alreadyExistsStudy(vQres[xx].study_instance_uid, $
                                      xResultsStud, studyCnt) eq 1) then $
      continue

    (*pstate).uniqueValue = (*pstate).uniqueValue +1
    name = strtrim(string((*pstate).uniqueValue),2) + ' ' + strtrim(string(studyCnt),2)
    xResultsStud[studyCnt].name = name ;each node has a unique uname to support find by uname
    xResultsStud[studyCnt].qmodel = 0
    xResultsStud[studyCnt].qlevel = 0
    xResultsStud[studyCnt].nlevel = 1
    xResultsStud[studyCnt].loaded = loaded
    xResultsStud[studyCnt].patient_name = vQRes[xx].patient_name
    xResultsStud[studyCnt].family_name = vQRes[xx].family_name
    xResultsStud[studyCnt].given_name = vQRes[xx].given_name
    xResultsStud[studyCnt].middle_name = vQRes[xx].middle_name
    xResultsStud[studyCnt].prefix = vQRes[xx].prefix
    xResultsStud[studyCnt].suffix = vQRes[xx].suffix
    xResultsStud[studyCnt].patient_id = vQRes[xx].patient_id
    xResultsStud[studyCnt].study_instance_uid = vQRes[xx].study_instance_uid
    xResultsStud[studyCnt].study_id = vQRes[xx].study_id
    xResultsStud[studyCnt].study_date = vQRes[xx].study_date
    xResultsStud[studyCnt].study_time = vQRes[xx].study_time
    xResultsStud[studyCnt].accession_number = vQRes[xx].accession_number
    xResultsStud[studyCnt].series_instance_uid = vQRes[xx].series_instance_uid
    xResultsStud[studyCnt].series_number = vQRes[xx].series_number
    xResultsStud[studyCnt].modality = vQRes[xx].modality
    xResultsStud[studyCnt].sop_instance_uid = vQRes[xx].sop_instance_uid
    xResultsStud[studyCnt].instance_number = vQRes[xx].instance_number
    studyCnt = studyCnt + 1

  endfor

  ; shrink the returned struc to the number of studies found
  xResultsStud = xResultsStud[0:studyCnt-1]

  ; fix the cnt element in each struct
  xResultsStud[*].cnt = studyCnt

  return, xResultsStud

end


;;----------------------------------------------------------------------------
;; NAME
;;   X
;;
;; Purpose:
;;   Create a structure containg all the series for the given patient and
;;   study series level query
;;
;; Parameters:
;;   VQRES - Pointer to query results
;;
;;   RESCNT - Number of results
;;
;;   PATID - Patient ID
;;
;;   STUDYUID - ID of the study
;;
;;   PSTATE - Pointer to state structure
;;
;;   SERCNT - Number of series
;;
;; Keywords:
;;   NONE
;;
function cw_dicomex_createSeriesStruct, vQres, resCnt, patId, studyUid, pstate, serCnt
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  ; create a struct containg all the series for the given patient and study
  ; series level query: the result set contains one entry for each series

  ; loop thru result set and find the patient of interest
  ; loop thru patient and find the study of interest
  ; add all series from the study to return struct

  serCnt = 0
  xResult = cw_dicomex_create_node_struct()
  xResultsSer = replicate(xResult, resCnt)

  for xx = 0, resCnt-1 do begin

    ; loop thru all the results looking for a particular patient
    if (patId ne vQres[xx].patient_id) then $
      continue

    ; loop thru all the results looking for a particular study uid
    if (studyUid ne vQres[xx].study_instance_uid) then $
      continue

    if (patId EQ 'Formal') then begin
      hoser = 1
    endif

    ; a series can have more than one image
    if (cw_dicomex_alreadyExistsSeries(vQres[xx].series_instance_uid, $
                                       xResultsSer, serCnt) eq 1) then $
      continue

    (*pstate).uniqueValue = (*pstate).uniqueValue +1
    name = strtrim(string((*pstate).uniqueValue),2) + ' ' + strtrim(string(serCnt),2)
    xResultsSer[serCnt].name = name ;each tree node has a unique uname to support find by uname
    xResultsSer[serCnt].cnt = resCnt
    xResultsSer[serCnt].qmodel = 0
    xResultsSer[serCnt].qlevel = 0
    xResultsSer[serCnt].nlevel = 2
    xResultsSer[serCnt].loaded = 0
    xResultsSer[serCnt].patient_name = vQRes[xx].patient_name
    xResultsSer[serCnt].family_name = vQRes[xx].family_name
    xResultsSer[serCnt].given_name = vQRes[xx].given_name
    xResultsSer[serCnt].middle_name = vQRes[xx].middle_name
    xResultsSer[serCnt].prefix = vQRes[xx].prefix
    xResultsSer[serCnt].suffix = vQRes[xx].suffix
    xResultsSer[serCnt].patient_id = vQRes[xx].patient_id
    xResultsSer[serCnt].study_instance_uid = vQRes[xx].study_instance_uid
    xResultsSer[serCnt].study_id = vQRes[xx].study_id
    xResultsSer[serCnt].study_date = vQRes[xx].study_date
    xResultsSer[serCnt].study_time = vQRes[xx].study_time
    xResultsSer[serCnt].accession_number = vQRes[xx].accession_number
    xResultsSer[serCnt].series_instance_uid = vQRes[xx].series_instance_uid
    xResultsSer[serCnt].series_number = vQRes[xx].series_number
    xResultsSer[serCnt].modality = vQRes[xx].modality
    xResultsSer[serCnt].sop_instance_uid = vQRes[xx].sop_instance_uid
    xResultsSer[serCnt].instance_number = vQRes[xx].instance_number
    serCnt = serCnt + 1

  endfor

  xResultsSer = xResultsSer[0:serCnt-1]
  xResultsSer[*].cnt = serCnt

  return, xResultsSer

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_loadPatPat
;;
;; Purpose:
;;   Create an array of structs containing an entry for each patient
;;
;; Parameters:
;;   VQRES - Pointer to query results
;;
;;   WTRERESULTS - Widget ID of top node of the tree
;;
;;   CNT - Count
;;
;;   PSTATE - Pointer to state structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_loadPatPat, vQres, wtreResults, cnt, pstate
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  ; used in all patient level queries (patient root/patient level)
  ; create an array of structs containing an entry for each patient
  ; on the first patient node contains the array of structs
  ; all other patient nodes hold a reference to the first patient node

  ; patient level query: the result set contains one entry for each patient

  xResult = cw_dicomex_create_node_struct()

  if (cnt GT 0) then begin
    xResults = replicate(xResult, cnt)
  endif

  for xx = 0, cnt-1 do begin

    (*pstate).uniqueValue = (*pstate).uniqueValue +1
    name = strtrim(string((*pstate).uniqueValue),2) + ' ' + strtrim(string(xx),2)
    xResults[xx].name = name ; each tree node has a unique uname to support find by uname
    xResults[xx].cnt = cnt
    xResults[xx].qmodel = 0
    xResults[xx].qlevel = 0
    xResults[xx].nlevel = 0
    xResults[xx].loaded = 0
    xResults[xx].patient_name = vQRes[xx].patient_name
    xResults[xx].family_name = vQRes[xx].family_name
    xResults[xx].given_name = vQRes[xx].given_name
    xResults[xx].middle_name = vQRes[xx].middle_name
    xResults[xx].prefix = vQRes[xx].prefix
    xResults[xx].suffix = vQRes[xx].suffix
    xResults[xx].patient_id = vQRes[xx].patient_id
    xResults[xx].study_instance_uid = vQRes[xx].study_instance_uid
    xResults[xx].study_id = vQRes[xx].study_id
    xResults[xx].study_date = vQRes[xx].study_date
    xResults[xx].study_time = vQRes[xx].study_time
    xResults[xx].accession_number = vQRes[xx].accession_number
    xResults[xx].series_instance_uid = vQRes[xx].series_instance_uid
    xResults[xx].series_number = vQRes[xx].series_number
    xResults[xx].modality = vQRes[xx].modality
    xResults[xx].sop_instance_uid = vQRes[xx].sop_instance_uid
    xResults[xx].instance_number = vQRes[xx].instance_number
  endfor

  ; patient root / patient level
  for xx = 0, cnt-1 do begin

    if (xx eq 0) then begin
      vNode0 = widget_tree(wtreResults, value=vQRes[xx].patient_id, $
                           uvalue=xResults, uname = xResults[xx].name, $
                           /folder, event_pro='cw_dicomex_qr_tree_node_event')
    endif else begin
      vNode = widget_tree(wtreResults, value=vQRes[xx].patient_id, $
                          uvalue=vNode0, uname = xResults[xx].name, $
                          /folder, event_pro='cw_dicomex_qr_tree_node_event')
    endelse

  endfor

  ; load the very top node of the tree so when it is clicked on it shows the root query
  widget_control, wtreResults, set_uvalue = xResults
  widget_control, wtreResults, set_uname = '0 0'

  cw_dicomex_load_table, (*pstate).wtblResults, cnt, 0, 0, xResults

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_loadPatStud
;;
;; Purpose:
;;   Builds an array of structs for each node and adds the node to the tree
;;
;; Parameters:
;;   VQRES - Pointer to query results
;;
;;   WTRERESULTS - Widget ID of top node of the tree
;;
;;   RESCNT - Number of results
;;
;;   PSTATE - Pointer to state structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_loadPatStud, vQres, wtreResults, resCnt, pstate
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  ; used in all study level queries (patient root/study level, study root/study level)

  ; builds an array of structs for each node and adds the node to the tree
  ; only the first node (0) in each level contains the array of structs
  ; all the other nodes for a level hold a reference back to it's first node (0)

  patCnt = 0
  xResultsPat = cw_dicomex_createPatStruct(vQres, resCnt, pstate, patCnt)

  for patIx = 0, patCnt-1 do begin

    ; add a patient
    if (patIx eq 0) then begin
      vNodePat0  = widget_tree(wtreResults, value=xResultsPat[patIx].patient_id, $
                               uvalue=xResultsPat, uname = xResultsPat[patIx].name, $
                               /folder, event_pro='cw_dicomex_qr_tree_node_event')
      vNodePat = vNodePat0
    endif else begin
      vNodePat  = widget_tree(wtreResults, value=xResultsPat[patIx].patient_id, $
                              uvalue=vNodePat0, uname = xResultsPat[patIx].name, $
                              /folder, event_pro='cw_dicomex_qr_tree_node_event')
    endelse

    ; add the studies for this patient
    studyCnt = 0
    xResultsStud = cw_dicomex_createStudyStruct(vQres, resCnt, $
                                                xResultsPat[patIx].patient_id, $
                                                pstate, studyCnt, 0)
    for stdyIx = 0, studyCnt-1 do begin
      if (stdyIx eq 0) then begin
        vNodeStud0 = widget_tree(vNodePat, $
                                 value=xResultsStud[stdyIx].study_instance_uid, $
                                 uvalue=xResultsStud, uname=xResultsStud[stdyIx].name, $
                                 /folder, event_pro='cw_dicomex_qr_tree_node_event')
      endif else begin
        vNode = widget_tree(vNodePat, value=xResultsStud[stdyIx].study_instance_uid, $
                            uvalue=vNodeStud0, uname=xResultsStud[stdyIx].name, $
                            /folder, event_pro='cw_dicomex_qr_tree_node_event')
      endelse
    endfor

  endfor

  ; load the very top node of the tree so when it is clicked on it shows the root query
  widget_control, wtreResults, set_uvalue = xResultsPat

  cw_dicomex_load_table, (*pstate).wtblResults, patCnt, 0, 0, xResultsPat
  widget_control, wtreResults, set_uname = '0 0'

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_loadPatStudSer
;;
;; Purpose:
;;   Builds an array of structures for each node
;;
;; Parameters:
;;   VQRES - Pointer to query results
;;
;;   WTRERESULTS - Widget ID of top node of the tree
;;
;;   RESCNT - Number of results
;;
;;   PSTATE - Pointer to state structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_loadPatStudSer, vQres, wtreResults, resCnt, pstate
  compile_opt idl2
  on_error, 2                   ; return errors to caller


  ; used in all series level queries (patient root/series level, study root/series level)

  ; builds an array of structs for each node and adds the node to the tree
  ; only the first node (0) in each level contains the array of structs
  ; all the other nodes for a level hold a reference back to it's first node (0)

  patCnt = 0
  xResultsPat = cw_dicomex_createPatStruct(vQres, resCnt, pstate, patCnt)

  for patIx = 0, patCnt-1 do begin

    ; add a patient
    if (patIx eq 0) then begin
      vNodePat0  = widget_tree(wtreResults, value=xResultsPat[patIx].patient_id, $
                               uvalue=xResultsPat, uname=xResultsPat[patIx].name, $
                               /folder, event_pro='cw_dicomex_qr_tree_node_event')
      vNodePat = vNodePat0
    endif else begin
      vNodePat  = widget_tree(wtreResults, value=xResultsPat[patIx].patient_id, $
                              uvalue=vNodePat0, uname=xResultsPat[patIx].name, $
                              /folder, event_pro='cw_dicomex_qr_tree_node_event')
    endelse

    ; add the studies for this patient

    studyCnt = 0
    xResultsStud = cw_dicomex_createStudyStruct(vQres, resCnt, $
                                                xResultsPat[patIx].patient_id, $
                                                pstate, studyCnt, 1)

    for stdyIx = 0, studyCnt-1 do begin

      if (stdyIx eq 0) then begin
        vNodeStud0 = widget_tree(vNodePat, $
                                 value=xResultsStud[stdyIx].study_instance_uid, $
                                 uvalue=xResultsStud, uname=xResultsStud[stdyIx].name, $
                                 /folder, event_pro='cw_dicomex_qr_tree_node_event')
        vNodeStud = vNodeStud0
      endif else begin
        vNodeStud = widget_tree(vNodePat, $
                                value=xResultsStud[stdyIx].study_instance_uid, $
                                uvalue=vNodeStud0, uname=xResultsStud[stdyIx].name, $
                                /folder, event_pro='cw_dicomex_qr_tree_node_event')
      endelse

      ; add the series for this study
      serCnt = 0
      xResultsSer = cw_dicomex_createSeriesStruct(vQres, resCnt, $
                                                  xResultsPat[patIx].patient_id, $
                                                  xResultsStud[stdyIx].study_instance_uid, $
                                                  pstate, serCnt)

      for serIx = 0, serCnt-1 do begin

        if (serIx eq 0) then begin
          vNodeSer0 = widget_tree(vNodeStud, $
                                  value=xResultsSer[serIx].series_instance_uid, $
                                  uvalue=xResultsSer, uname=xResultsSer[serIx].name, $
                                  /folder, event_pro='cw_dicomex_qr_tree_node_event')
        endif else begin
          vNode = widget_tree(vNodeStud, $
                              value=xResultsSer[serIx].series_instance_uid, $
                              uvalue=vNodeSer0, uname=xResultsSer[serIx].name, $
                              /folder, event_pro='cw_dicomex_qr_tree_node_event')
        endelse
      endfor

    endfor
  endfor

  ; load the very top node of the tree so when it is clicked on it shows the root query
  widget_control, wtreResults, set_uvalue = xResultsPat
  widget_control, wtreResults, set_uname = '0 0'

  cw_dicomex_load_table, (*pstate).wtblResults, patCnt, 0, 0, xResultsPat

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_btnQuery_event
;;
;; Purpose:
;;   Event handler for the Query button
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_btnQuery_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    cw_dicomex_query_ui_enable, ev
    widget_control, (*pstate).wbtnCancelQ, sensitive=0
    return
  endif

  wState = widget_info(ev.top, find_by_uname='querystatebase')
  widget_control, wState, get_uvalue = pstate

  if ((*pstate).query_scp_cnt eq 0) then begin
    widget_control, (*pstate).wtxtStatus, set_value = 'You will need to configure ' + $
                    'at least one Query SCP node before you can do a query.'
    return
  endif

  ; disable the btns
  cw_dicomex_query_ui_disable, ev

  widget_control, (*pstate).wbtnCancelQ, sensitive=1

  ; clear the status text widget
  widget_control, (*pstate).wtxtStatus, set_value=''

  (*pstate).oqr->clearproperties

  ; set the node we are going to query on the query object
  (*pstate).oqr->setproperty, query_scp = (*pstate).query_scp

  ; use the query fields to set the query field properties on the query object
  cw_dicomex_SetQueryProperties, pstate

  (*pstate).oqr->setproperty, CALLBACK_FUNCTION='cw_dicomex_qr_callback'

  ; before a retrieve can occur the user must select a tree node after each query
  (*pstate).treeNodeSelIdx = -1

  ;; run the query, this call will not return until the query is
  ;; finished, canceled or errors out
  vQRes = (*pstate).oqr->query(count=cnt)

  ; re-enable the btns
  cw_dicomex_query_ui_enable, ev
  widget_control, (*pstate).wbtnCancelQ, sensitive=0

  ;; clear the tree by destroying it and recreating it...ensures the
  ;; memory used is released on the start of a new query
  widget_control, (*pstate).wtreResults, /destroy
  wtreResults = widget_tree((*pstate).wtree,  UNAME = 'TRE_RESULTS', $
                            value='Patient Ids', /FOLDER, /EXPANDED, $
                            event_pro='cw_dicomex_qr_tree_node_event')

  ; store the new tree base
  (*pstate).wtreResults = wtreResults

  ; clear the results table widget
  as = strarr(12)
  widget_control, (*pstate).wtblResults, set_value = as

  ; if the query returned zero results just return
  if (cnt eq 0) then $
    return

  (*pstate).oqr->GetProperty, query_model=qModel, query_level=qLevel
  (*pstate).modelOnQuery = qModel

  ; patient root / patient level
  if ((qModel eq 0) && (qLevel eq 0)) then begin
    cw_dicomex_loadPatPat, vQres, wtreResults, cnt, pstate
  endif

  ; patient root / study level
  if ((qModel eq 0) && (qLevel eq 1)) then begin
    cw_dicomex_loadPatStud, vQres, wtreResults, cnt, pstate
  endif

  ; patient root / series level
  if (qModel eq 0) && (qLevel eq 2) then begin
    cw_dicomex_loadPatStudSer, vQres, wtreResults, cnt, pstate
  endif

  ; study root / study level
  if ((qModel eq 1) && (qLevel eq 1)) then begin
    cw_dicomex_loadPatStud, vQres, wtreResults, cnt, pstate
  endif

  ; study root / series level
  if (qModel eq 1) && (qLevel eq 2) then begin
    cw_dicomex_loadPatStudSer, vQres, wtreResults, cnt, pstate
  endif

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_btnRetrieve_event
;;
;; Purpose:
;;   Event handler for the Retrieve button
;;
;; Parameters:
;;   EV - Widget event structure
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_btnRetrieve_event, ev
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    cw_dicomex_query_ui_enable, ev
    widget_control, (*pstate).wbtnCancelR, sensitive=0

    ; restore the array of structs or reference to the array of structs
    if (idx ne 0) then begin
      widget_control, node_0_id, set_uvalue = xNode, /no_copy
      widget_control, (*pstate).treeNodeSel, set_uvalue = node_0_id, /no_copy
    endif else begin
      widget_control, (*pstate).treeNodeSel, set_uvalue = xNode, /no_copy
    endelse

    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  wState = widget_info(ev.top, find_by_uname='querystatebase')
  widget_control, wState, get_uvalue = pstate


  if ((*pstate).stor_scp_cnt eq 0) then begin
    widget_control, (*pstate).wtxtStatus, set_value = 'You will need to configure ' + $
                    'at least one Storage SCP node before you can do a retrieve.'
    return
  endif

  if ((*pstate).treeNodeSelIdx eq -2) then begin
    widget_control, (*pstate).wtxtStatus, set_value = 'You must do a query before ' + $
                    'you can do a retrieve.'
    return
  endif

  if ((*pstate).treeNodeSelIdx eq -1) then begin
    widget_control, (*pstate).wtxtStatus, set_value = 'You must select a node before ' + $
                    'you can do a retrieve.'
    return
  endif

  cw_dicomex_query_ui_disable, ev
  widget_control, (*pstate).wbtnCancelR, sensitive=1

  ; clear the status text widget
  widget_control, (*pstate).wtxtStatus, set_value=''

  ; set the query and retrieve nodes in the query object
  (*pstate).oqr->setproperty, query_scp = (*pstate).query_scp
  (*pstate).oqr->setproperty, storage_scp = (*pstate).store_scp

  ; this callback function is called while the retrieve is under way
  (*pstate).oqr->setproperty, CALLBACK_FUNCTION='cw_dicomex_qr_callback'

  ; this is the selected node for which the retrieve will be executed
  idx = (*pstate).treeNodeSelIdx

  ; get the array of structs describing the nodes at this level
  ; node zero at this level holds the array of structs
  ; all other nodes at this level point back to node zero
  if (idx ne 0) then begin
    widget_control, (*pstate).treeNodeSel, get_uvalue = node_0_id, /no_copy
    widget_control, node_0_id, get_uvalue = xNode, /no_copy
  endif else begin
    widget_control, (*pstate).treeNodeSel, get_uvalue = xNode, /no_copy
  endelse

  ;; run the retrieve, this call will not return until the retrieve is
  ;; finished, canceled or errors out

  qModel = (*pstate).modelOnQuery

  ; patient level retrieve...get all the images for the selected patient
  if (xNode[idx].nlevel EQ 0) then begin
    if (qModel ne 0) then begin
      widget_control, (*pstate).wtxtStatus, set_value=' Can not retrieve at the ' + $
                      'patient level when the query model is study root...select a ' + $
                      'study or series or image.', /append
    endif else begin
      (*pstate).oqr->setproperty, query_level = 0
      (*pstate).oqr->setproperty, query_model = qModel
      status = (*pstate).oqr->retrieve(patient_id=xNode[idx].patient_id)
    endelse
  endif

  ; study level retrieve...get all the images in the selected study
  if (xNode[idx].nlevel EQ 1) then begin
    (*pstate).oqr->setproperty, query_level = 1
    (*pstate).oqr->setproperty, query_model = qModel
    status = (*pstate).oqr->retrieve(pat=xNode[idx].patient_id, $
                                     study=xNode[idx].study_instance_uid)
  endif

  ; series level retrieve...get all the images in the seleced series
  if (xNode[idx].nlevel EQ 2) then begin
    (*pstate).oqr->setproperty, query_level=2
    (*pstate).oqr->setproperty, query_model=qModel
    status = (*pstate).oqr->retrieve(pat=xNode[idx].patient_id, $
                                     study=xNode[idx].study_instance_uid, $
                                     series=xNode[idx].series_instance_uid)
  endif

  ; image level retrieve...get the selected image
  if (xNode[idx].nlevel EQ 3) then begin
    (*pstate).oqr->setproperty, query_level=3
    (*pstate).oqr->setproperty, query_model=qModel
    status = (*pstate).oqr->retrieve(pat=xNode[idx].patient_id, $
                                     study=xNode[idx].study_instance_uid, $
                                     series=xNode[idx].series_instance_uid, $
                                     sop=xNode[idx].sop_instance_uid)
  endif

  ; re-enable the btns
  cw_dicomex_query_ui_enable, ev
  widget_control, (*pstate).wbtnCancelR, sensitive=0

  ; restore the array of structs or reference to the array of structs
  if (idx ne 0) then begin
    widget_control, node_0_id, set_uvalue = xNode, /no_copy
    widget_control, (*pstate).treeNodeSel, set_uvalue = node_0_id, /no_copy
  endif else begin
    widget_control, (*pstate).treeNodeSel, set_uvalue = xNode, /no_copy
  endelse

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_qr_callback
;;
;; Purpose:
;;   Callback for the query retrieve object
;;
;; Parameters:
;;   STATUS - Status of object
;;
;;   DATA - Any auxiliary data
;;
;; Keywords:
;;   NONE
;;
function cw_dicomex_qr_callback, status, data
  compile_opt idl2
  on_error, 2                   ; return errors to caller

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    cw_dicomex_query_ui_enable, ev
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return, 1
  endif

  ; this method needs to be kept as short as possible since it is being called:
  ; - as a callback from the query retrieve object that is waiting/collecting
  ;   the query matches from the remote query scp node
  ; - as a callback from the query retrieve object that is waiting for
  ;   a retrieve to finish

  ; add the text sent form the qr obj in the status parameter to the list box
  widget_control, (*data).wtxtStatus, set_value = status, /append

  ; make the last line written visible
  lastchar = widget_info((*data).wtxtStatus, /text_number)
  xypos = widget_info((*data).wtxtStatus, TEXT_OFFSET_TO_XY=lastchar-1)

  if (xypos[1] GT (*data).txtLines) then begin
    widget_control, (*data).wtxtStatus, set_text_top_line=xypos[1] - (*data).txtLines
  endif

  ; check to see if the user pressed the cancel button
  weQ = widget_event((*data).wbtnCancelQ, /nowait)
  weR = widget_event((*data).wbtnCancelR, /nowait)

  if (weQ.id EQ (*data).wbtnCancelQ) then begin
    return, 0
  endif

  if (weR.id EQ (*data).wbtnCancelR) then begin
    return, 0
  endif

  return, 1

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_qrui_kill_event
;;
;; Purpose:
;;   Event handler for kill requests
;;
;; Parameters:
;;   ID - Widget ID
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_qrui_kill_event, id
  compile_opt idl2
  catch, errorStatus            ; catch all errors and display an error dialog

  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    return
  endif

  ; called when the main ui is destroyed we let go of objects and pointers

  widget_control, id, get_uvalue = pstate

  if ptr_valid(pstate) then begin
    IF ((*pState).wQFUI NE 0) THEN BEGIN
      wbase = widget_info((*pstate).wQFUI,/child)
      widget_control, wbase, get_uvalue=pqf
      IF ptr_valid(pqf) THEN $
        ptr_free, pqf

      queryIdx = (*pstate).queryIdx
      queryAEN = (*pstate).queryAEN
      destinationAEN = (*pstate).destinationAEN
      save, queryIdx, queryAEN, destinationAEN, FILENAME=(*pstate).prefsFile

    ENDIF
    obj_destroy, (*pstate).ocfg
    obj_destroy, (*pstate).oqr
    ptr_free, pstate
  endif

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_query_set_value
;;
;; Purpose:
;;   Procedure to handle set_value calls.  This method is used when
;;   upper level widgets need to send information to this widget
;;
;; Parameters:
;;   ID - Widget ID
;;
;;   VALUE - Structure containing desired information
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_query_set_value, id, value
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  ;; value should be structure
  IF (size(value, /type) NE 8) THEN return

  CASE tag_names(value,/structure_name) OF
    'REFRESH' : BEGIN

      ;; return if refresh is not set
      IF (value.refresh EQ 0) THEN return

      ;; this procedure can be called by the parent of this compound
      ;; widget when the config file is updated

      wState = widget_info(id, find_by_uname='querystatebase')

      ;; if wState is 0 then tab did not get created
      if (wState eq 0) then $
        return

      widget_control, wState, get_uvalue = pstate

      obj_destroy, (*pstate).ocfg
      obj_destroy, (*pstate).oqr

      ;; recreate a config object so that it re-reads the config
      (*pstate).ocfg = obj_new('IDLffDicomExCfg')

      ;; recreate a qr obj so that it re-reads the config ---------
      (*pstate).oqr = obj_new('IDLffDicomExQuery')

      ;; empty out the combo
      num = widget_info((*pstate).wcbQuery, /combobox_number)
      if (num ne 0) then begin
        for ii=num, 0, -1 do begin
          widget_control, (*pstate).wcbQuery, combobox_deleteitem = ii
        endfor
      endif

      ;; load the remote node drop down -----------------
      qrscpaes = (*pstate).ocfg->GetApplicationEntities(count=count, $
                                                        SERVICE_TYPE='Query_SCP')
      for xx = 0, count-1 do begin
        widget_control, (*pstate).wcbQuery, combobox_additem=qrscpaes[xx].APPLENTITYNAME
      endfor

      ;; set state var to be used in query btn event
      (*pstate).query_scp_cnt = count
      (*pstate).query_scp = ''
      if (count GT 0) then begin
        (*pstate).query_scp    = qrscpaes[0].APPLENTITYNAME
      endif

      ;; empty out the combo
      num = widget_info((*pstate).wcbRetrieve, /combobox_number)
      if (num ne 0) then begin
        for ii=num, 0, -1 do begin
          widget_control, (*pstate).wcbRetrieve, combobox_deleteitem = ii
        endfor
      endif

      ;; load the remote node drop down ---------------------
      storscpaes = (*pstate).ocfg->GetApplicationEntities(count=count, $
                                                          SERVICE_TYPE='Storage_SCP')
      for xx = 0, count-1 do begin
        widget_control, (*pstate).wcbRetrieve, $
                        combobox_additem=storscpaes[xx].APPLENTITYNAME
      endfor

      ;; set state var to be used in retrieve event
      (*pstate).stor_scp_cnt = count
      (*pstate).store_scp = ''
      if (count GT 0) then begin
        (*pstate).store_scp = storscpaes[0].APPLENTITYNAME
      endif

      ;; give the state ptr to the qr obj
      (*pstate).oqr->SetProperty, callback_data = pstate

      if ((*pstate).query_scp_cnt eq 0) then $
        widget_control, (*pstate).wtxtStatus, set_value = 'You will need to configure ' + $
                        'at least one Query SCP Node before you can do a query.', /append

      if ((*pstate).stor_scp_cnt eq 0) then $
        widget_control, (*pstate).wtxtStatus, set_value = 'You will need to configure ' + $
                        'at least one Storage SCP node before you can do a retrieve.', $
                        /append

    END
    ELSE :
  ENDCASE

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_qr_realize_notify_event
;;
;; Purpose:
;;   Event handler for the realization notifications
;;
;; Parameters:
;;   ID - Widget ID
;;
;; Keywords:
;;   NONE
;;
pro cw_dicomex_qr_realize_notify_event, id
  compile_opt idl2

  catch, errorStatus            ; catch all errors and display an error dialog
  if (errorStatus ne 0) then begin
    catch,/cancel
    print, !error_state.msg
    r = dialog_message(!error_state.msg, $
                       title='Dialog Dicom Network Error', $
                       dialog_parent=cwBase, /error)
    return
  endif

  ; called when the main ui is destroyed
  ; we let go of objects and pointers

  wState = widget_info(id, find_by_uname='querystatebase')
  widget_control, wState, get_uvalue = pstate

  ; load the remote node drop down -----------------
  ; also see if the saved queryAEN is in the current app entity list if it is then restore it
  foundQueryAENIdx = -1
  qrscpaes = (*pstate).ocfg->GetApplicationEntities(count=count, SERVICE_TYPE='Query_SCP')
  for xx = 0, count-1 do begin
    widget_control, (*pstate).wcbQuery, combobox_additem = qrscpaes[xx].APPLENTITYNAME
    if ((*pstate).queryAEN eq qrscpaes[xx].APPLENTITYNAME) then begin
       foundQueryAENIdx = xx
    endif
  endfor

  ; set state var to be used in query btn event
  (*pstate).query_scp_cnt = count
  (*pstate).query_scp = ''

  if (foundQueryAENIdx ne -1) then begin
    (*pstate).query_scp = qrscpaes[foundQueryAENIdx].APPLENTITYNAME
    widget_control, (*pstate).wcbQuery, SET_COMBOBOX_SELECT=foundQueryAENIdx
  endif else begin
    if (count GT 0) then begin
      (*pstate).query_scp    = qrscpaes[0].APPLENTITYNAME
    endif
  endelse


  ; load the remote node drop down ---------------------
  ; also see if the saved destAEN is in the current app entity list if it is restore it
  foundDestAENIdx = -1
  storscpaes = (*pstate).ocfg->GetApplicationEntities(count=count, SERVICE_TYPE='Storage_SCP')
  for xx = 0, count-1 do begin
    widget_control, (*pstate).wcbRetrieve, combobox_additem=storscpaes[xx].APPLENTITYNAME
     if ((*pstate).destinationAEN eq storscpaes[xx].APPLENTITYNAME) then begin
         foundDestAENIdx = xx
     endif
  endfor

  ; set state var to be used in retrieve event
  (*pstate).stor_scp_cnt = count
  (*pstate).store_scp = ''

  if (foundDestAENIdx ne -1) then begin
    (*pstate).store_scp = storscpaes[foundDestAENIdx].APPLENTITYNAME
    widget_control, (*pstate).wcbRetrieve, SET_COMBOBOX_SELECT=foundDestAENIdx
  endif else begin
    if (count GT 0) then begin
      (*pstate).store_scp = storscpaes[0].APPLENTITYNAME
    endif
  endelse


  ; two possible values for the queries drop list 'All Patients'=0 'Use current query'=1
  one=1
  if ((*pstate).queryIdx eq 1) then begin
    widget_control, (*pstate).wdlQueries, SET_DROPLIST_SELECT=one
  endif

  ;; init the uvalue in the table to an array of null strings equal to
  ;; the number of rows in table
  winfotblResults = widget_info((*pstate).wtblResults,/geometry)
  tblRows = winfotblResults.ysize
  names = strarr(tblRows)
  widget_control, (*pstate).wtblResults, set_uvalue = names

  ; get the number of visible lines in the status text window
  winfowtxtStatus = widget_info((*pstate).wtxtStatus,/geometry)
  (*pstate).txtLines = winfowtxtStatus.ysize - 2

  ; cancel is only enabled when a q or r is underway
  widget_control, (*pstate).wbtnCancelQ, sensitive=0
  widget_control, (*pstate).wbtnCancelR, sensitive=0

  ; give the state ptr to the qr obj
  (*pstate).oqr->SetProperty, callback_data = pstate

  if ((*pstate).query_scp_cnt eq 0) then $
    widget_control, (*pstate).wtxtStatus, set_value = 'You will need to configure ' + $
                    'at least one Query SCP Node before you can do a query.', /append

  if ((*pstate).stor_scp_cnt eq 0) then $
    widget_control, (*pstate).wtxtStatus, set_value = 'You will need to configure ' + $
                    'at least one Storage SCP node before you can do a retrieve.', /append

  ; make sure nothing is selected in the results table
  widget_control, (*pstate).wtblResults, SET_TABLE_SELECT=[-1,-1,-1,-1]

end


;;----------------------------------------------------------------------------
;; NAME
;;   cw_dicomex_query
;;
;; Parameters:
;;   PARENT - Widget ID
;;
;; Keywords:
;;   NONE
;;
function cw_dicomex_query, parent
  compile_opt idl2
  on_error, 2

  ; this is the main procedure for the query ui compound widget
  ; it builds the query ui and displays it.
  ; this is ui front end to an underlying dicomex query object

  ; it creates a dicomex cfg obj that lives for the life of the ui
  ; the cfg obj is used to get the ae names that are used to populate the combo boxes
  ; it creates a dicomex query obj that lives for the life of the ui
  ; the query obj does the actaul query work

  ; this is the base for all the widgets in the query/retrieve ui widget

  wBase = widget_base(parent, /COLUMN, PRO_SET_VALUE='cw_dicomex_query_set_value', $
                      NOTIFY_REALIZE='cw_dicomex_qr_realize_notify_event', space=5)
  wBaseState = widget_base(wBase, uname='querystatebase', $
                           kill_notify='cw_dicomex_qrui_kill_event')

  ; add the query frame ------------------------
  wbaseQuery = widget_base(wBase)
  wLblQuery = widget_label(wbaseQuery, value=' Query ', xoffset=5)
  winfoLblQuery = widget_info(wLblQuery, /geometry)
  wbaseFrQuery = widget_base(wbaseQuery, /frame, yoffset=winfoLblQuery.ysize/2, $
                             /row, space=10, ypad=10, xpad=10)
  wLblQuery = widget_label(wbaseQuery, value=' Query ', xoffset=5)

  ; add the remote node down down
  wlblRemote = widget_label(wbaseFrQuery, value = 'Query Node', xsize = 95)
  wcbQuery = widget_combobox(wbaseFrQuery, xsize=185, event_pro='cw_dicomex_cbQuery_event')

  ; add the 3 query btns to query frame
  wbtnQuery = widget_button(wbaseFrQuery, xsize=100, value='Query', $
                            UNAME='BTN_QUERY', event_pro='cw_dicomex_btnQuery_event')
  wdlQueries = widget_droplist(wbaseFrQuery, xsize=150, $
                               value=['All patients','Use current query'], $
                               event_PRO='cw_dicomex_dlQueries_event')
  wbtnCancelQ = widget_button(wbaseFrQuery, xsize=100, value='Cancel', UNAME='BTN_CANCELQ')
  wbtnBldQuery = widget_button(wbaseFrQuery, xsize=100, value='Build Query', $
                               UNAME='BTN_BUILD', event_pro='cw_dicomex_btnBuild_event')

  ; add the retrieve frame --------------------------
  wbaseRetrieve = widget_base(wBase)
  wLblRetrieve = widget_label(wbaseRetrieve, value=' Retrieve ', xoffset=5)
  winfoLblRetrieve = widget_info(wLblRetrieve, /geometry)
  wbaseFrRetrieve = widget_base(wbaseRetrieve, /frame, $
                                yoffset=winfoLblRetrieve.ysize/2, /row, space=10, $
                                ypad=10, xpad=10)
  wLblRetrieve = widget_label(wbaseRetrieve, value=' Retrieve ', xoffset=5)

  ; add the retrieve node drop down
  wlblRetrieve = widget_label(wbaseFrRetrieve, value='Destination Node', xsize= 95)
  wcbRetrieve = widget_combobox(wbaseFrRetrieve, xsize=185, $
                                event_pro='cw_dicomex_cbRetrieve_event')
  wbtnRetrieve = widget_button(wbaseFrRetrieve, value='Retrieve', $
                               UNAME='BTN_RETRIEVE', xsize=100, $
                               event_pro='cw_dicomex_btnRetrieve_event')
  wbtnCancelR = widget_button(wbaseFrRetrieve, xsize=100, value='Cancel', UNAME='BTN_CANCELR')

  ;;add the results frame -----------------------------
  wbaseResult = widget_base(wBase)
  wLblResult = widget_label(wbaseResult, value=' Results ', xoffset=5)
  winfoLblResult = widget_info(wLblResult, /geometry)
  wbaseFrResult = widget_base(wbaseResult, /frame, $
                              yoffset=winfoLblResult.ysize/2, /row, space=20, ypad=10, xpad=10)
  wLblResult = widget_label(wbaseResult, value=' Results ', xoffset=5)
  wtree = widget_tree(wbaseFrResult, ysize=260)
  wtreResults = widget_tree(wtree, UNAME='TRE_RESULTS', value='Patient Ids', $
                            /FOLDER, /EXPANDED, event_pro='cw_dicomex_qr_tree_node_event')
  vColNames = ['Patient Id', 'Family', 'Given', 'Middle', 'Prefix', 'Suffix']
  vColWidths = [200, 100, 100, 50, 50, 50]
  wtblResults = widget_table(wbaseFrResult, UNAME='TBL_RESULTS', xsize=6, $
                             ysize=12, /resizeable_columns, $
                             event_pro='cw_dicomex_table_results_event', $
                             /row_major, /no_row_headers, column_labels=vColNames, $
                             column_widths=vColWidths, /scroll, /all_events)
  winfoFrResult = widget_info(wbaseFrResult, /geometry)

  ;;add the status frame -------------------------------
  wbaseStatus = widget_base(wBase)
  wlblStatus = widget_label(wbaseStatus, value=' Status ', xoffset=5)
  winfolblStatus = widget_info(wlblStatus, /geometry)
  wbaseFrStatus = widget_base(wbaseStatus, /frame, yoffset=winfolblStatus.ysize/2, $
                              /row, space=20, ypad=10, xpad=10)
  wlblStatus = widget_label(wbaseStatus, value=' Status ', xoffset=5)
  wtxtStatus = widget_text(wbaseFrStatus, value='', /scroll, UNAME='TXT_STATUS', $
                           ysize=9, scr_xsize=winfoFrResult.xsize-30)

  widget_control, wbaseFrQuery, xsize=winfoFrResult.xsize
  widget_control, wbaseFrRetrieve, xsize=winfoFrResult.xsize
  widget_control, wbaseFrStatus, xsize=winfoFrResult.xsize

  ; create a config object
  ocfg = obj_new('IDLffDicomExCfg')

  ; create a qr obj ---------
  oqr = obj_new('IDLffDicomExQuery')

  ; these state vars are set in the notify_realize event
  query_scp_cnt = 0
  query_scp = ''
  stor_scp_cnt = 0
  store_scp = ''
  txtLines = 0

  ; starting values
  treeNodeSel = 0
  treeNodeSelIdx = -2

  xQFValues = cw_dicomex_CreateQFStruct()

  ;; set query save file name
  queryfile = 'dicomexquery.xml'


  ; read the save file with the saved combo box values
  queryAEN = ''
  destinationAEN = ''
  queryIdx = 0

  AuthorDirname = 'RSI'
  AuthorDesc = 'Research Systems, Inc.'
  AppDirname = 'Dicomex_Network_Services'
  AppDesc = 'DicomEx Network Services UI'
  AppReadmeText = ['Author: rsi', 'DicomEx Storage SCU UI properties']
  AppReadmeVersion = 1
  dir = APP_USER_DIR(AuthorDirname, AuthorDesc, AppDirname, AppDesc, AppReadmeText, AppReadmeVersion)
  prefsFile = filepath(ROOT_DIR=dir, 'query_ui_prefs.sav')
  if (file_test(prefsFile, /REGULAR)) then begin
    restore, prefsFile
  endif

  ; the state gets passed to the  qr obj and the qr obj passes it back as call back param
  state = {ocfg:ocfg, oqr:oqr, wbaseFrResult:wbaseFrResult, wtree:wtree, $
           wtreResults:wtreResults, wtblResults:wtblResults, wtxtStatus:wtxtStatus, $
           wbtnCancelQ:wbtnCancelQ, wbtnCancelR:wbtnCancelR, wbtnBldQuery:wbtnBldQuery, $
           wbtnQuery:wbtnQuery, wdlQueries: wdlQueries, wbtnRetrieve:wbtnRetrieve, $
           wcbQuery:wcbQuery, queryAEN:queryAEN, destinationAEN:destinationAEN, $
           wcbRetrieve:wcbRetrieve, wBase:wBase, txtLines:txtLines, prefsFile:prefsFile, $
           query_scp:query_scp, query_scp_cnt:query_scp_cnt, store_scp:store_scp, $
           stor_scp_cnt:stor_scp_cnt, treeNodeSel:treeNodeSel, queryIdx:queryIdx, $
           treeNodeSelIdx:treeNodeSelIdx, uniqueValue:100, wQFUI:0, $
           xQFValues:xQFValues, queryFile:queryfile, modelOnQuery:0}

  ; passing a ptr is much more efficient
  pstate = ptr_new(state)

  ; put the state ptr in the uvalue of the base obj so all events can get the state
;;;widget_control, wBase, set_uvalue=pstate
  widget_control, wBaseState, set_uvalue=pstate

  return, wBase

end
