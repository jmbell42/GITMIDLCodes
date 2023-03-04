;$Id: //depot/idl/IDL_63_RELEASE/idldir/lib/utilities/xvolume.pro#1 $
;
;  Copyright (c) 1997-2006, Research Systems, Inc. All rights reserved.
;       Unauthorized reproduction prohibited.
;
pro xvolume_cleanup, wID
compile_opt hidden

widget_control, wID, get_uvalue=pState

if (*pState).group_leader_is_fabricated then begin
    if widget_info(*(*pState).pGroupLeader, /valid_id) then begin
        widget_control, *(*pState).pGroupLeader, /destroy
        endif
    endif

if ptr_valid((*pState).pBlocked) then begin
;
;   Remove volume so that it is not destroyed now.
;
    (*pState).oView->Remove, (*pState).oVol
    end

obj_destroy, (*pState).oObjViewWid
obj_destroy, (*pState).oView
ptr_free, (*pState).pGroupLeader
ptr_free, pState
end
;--------------------------------------------------------------------
pro xvolume_event, event
compile_opt hidden
;
;Handle resize events.
;
if tag_names(event, /structure_name) eq 'WIDGET_BASE' then begin
    widget_control, event.top, get_uvalue=pState
    widget_control, /hourglass
    pad = 4 ; Estimate.
    xsize = event.x - pad
    ysize = event.y - pad
    (*pState).oObjViewWid->SetProperty, xsize=xsize, ysize=ysize
    endif
end
;--------------------------------------------------------------------
pro xvolume, $
    vol, $
    block=block, $
    modal=modal, $
    group=group_leader, $
    replace=replace, $  ; IN: (opt) If set, replace vol in existing XVOLUME.
    renderer=renderer, $; IN: (opt) 0==OpenGL (default), 1==IDL software.
    xsize=xsize, $      ; IN: (opt) pixel size of draw window.
    ysize=ysize, $      ; IN: (opt) pixel size of draw window.
    scale=scale, $      ; IN: (opt) 1-value or 3-value [x,y,z] size factor.
    interpolate=interpolate, $ ; IN: (opt) If set, affect volume's appearance.
    test=test, $        ; IN: (opt) If set, do not require vol argument.
    debug=debug         ; IN: (opt) Set this keyword to see the actual
                        ;             line at which an error (if any) occurs.

compile_opt idl2
on_error, keyword_set(debug) ? 0 : 2

if n_elements(vol) eq 0 and arg_present(vol) and keyword_set(test) eq 0 $
then $
    message, 'Volume argument is undefined.'

if n_elements(vol) eq 0 and keyword_set(test) eq 0 then $
    message, 'requires one argument.'

if keyword_set(replace) then begin
    if xregistered('xVolume') eq 0 then $
        message, 'There is no valid XVOLUME for REPLACE.'
    tlb = LookupManagedWidget('xVolume')
    widget_control, tlb, get_uvalue=pState
    oView = (*pState).oView
    oView->GetProperty, volume=oVol
    oView->Remove, oVol
    oVol->GetProperty, rgb_table0=rgb_table0, opacity_table0=opacity_table0, hide=hide
    obj_destroy, oVol
    oVol = obj_new('IDLgrVolume', $
        keyword_set(test) ? $
            congrid(bytscl(randomu((seed=0), 4, 4, 4)), 40, 40, 20) $
            : vol, $
        /zbuff, $
        interpolate=interpolate, $
        hints=2, $
        /zero_opacity_skip, $
        /no_copy, $
        opacity_table0=opacity_table0, $
        rgb_table0=rgb_table0, hide=hide $
        )
    end $
else begin
    oVol = obj_new('IDLgrVolume', $
        keyword_set(test) ? $
            congrid(bytscl(randomu((seed=0), 4, 4, 4)), 40, 40, 20) $
            : vol, $
        /zbuff, $
        interpolate=interpolate, $
        hints=2, $
        /no_copy, $
        /zero_opacity_skip $
        )
    end

if not obj_valid(oVol) then $
    message, 'Unable to create volume object.'

catch, error_status
if error_status ne 0 then begin
    catch, /cancel
    if arg_present(vol) and not keyword_set(test) then begin
        oVol->GetProperty, data0=vol
        end
    obj_destroy, oVol
    message, !error_state.msg + ' ' + !error_state.sys_msg
    end
if keyword_set(debug) then $
    catch, /cancel

if not keyword_set(replace) then begin
    oView = obj_new('IDLexVolview')

    if not obj_valid(oView) then $
        message, 'Unable to create IDLexVolview object.'

    catch, error_status
    if error_status ne 0 then begin
        catch, /cancel
        if arg_present(vol) and not keyword_set(test) then begin
            oVol->GetProperty, data0=vol
            end
        obj_destroy, oVol
        obj_destroy, oView
        if keyword_set(group_leader_is_fabricated) then begin
            widget_control, group_leader, /destroy
            end
        if obj_valid(oObjViewWid) then begin
            obj_destroy, oObjViewWid
            end
        message, !error_state.msg + ' ' + !error_state.sys_msg
        end
    if keyword_set(debug) then $
        catch, /cancel

    oView->SetProperty, interpolate_slices=interpolate
    end

oView->Add, oVol

if not keyword_set(replace) then begin
    if n_elements(group_leader) ne 0 then begin
        if not widget_info(group_leader, /valid_id) then begin
            message, 'Specified Group Leader is not valid.', /noname
            endif
        endif $
    else begin
        if keyword_set(modal) then begin
;
;           Modal widgets require a group leader.  A group leader was not
;           specified, so fabricate an invisible one.
;
            group_leader = widget_base(map=0)
            group_leader_is_fabricated = 1b
            endif
        endelse
;
;   Create widgets.
;
    if keyword_set(modal) then begin
        tlb = widget_base( $
            /column, $
            /tlb_size_events, $
            /modal, $
            group_leader=group_leader, $
            title='Xvolume' $
            )
        end $
    else begin
        tlb = widget_base( $
            mbar=mbar, $
            /tlb_size_events, $
            group_leader=group_leader, $
            title='Xvolume' $
            )
        end
    oObjViewWid = obj_new('IDLexVolviewWid', $
        tlb, $
        oView, $
        renderer=renderer, $
        draw_xsize=xsize, $
        draw_ysize=ysize, $
        scale=scale, $
        menu_parent=mbar, $
        /use_instancing, $
        /debug $
        )
    if not obj_valid(oObjViewWid) then $
        message, 'Failed to create IDLexVolviewWid object.'

    pBlocked = ptr_new(/allocate_heap)
    widget_control, tlb, /realiz, set_uvalue=ptr_new({ $
        oObjViewWid: oObjViewWid, $
        oView: oView, $
        oVol: oVol, $
        pBlocked: pBlocked, $
        pGroupLeader: ptr_new(group_leader), $
        group_leader_is_fabricated: keyword_set(group_leader_is_fabricated) $
        })
    oObjViewWid->SetProperty, drag_quality=0
    xmanager, $
        "xVolume", $
        tlb, $
        no_block=keyword_set(block) eq 0, $
        cleanup='xVolume_cleanup'
    ptr_free, pBlocked ; our call to xmanager has returned.

    if keyword_set(group_leader_is_fabricated) then begin
;
;       Leave GROUP_LEADER parameter like we found it: undefined.
;
        ptr_free, ptr_new(group_leader, /no_copy)
        endif

    end $
else begin
    (*pState).oObjViewWid->SetSliderRanges
    (*pState).oObjViewWid->Draw
    end

done_viewing = obj_valid(oView) eq 0
;
;Leave vol argument unchanged.
;
if arg_present(vol) and not keyword_set(test) then begin
    oVol->GetProperty, data0=vol, no_copy=done_viewing
    end
;
if done_viewing then begin
    obj_destroy, oVol
    end

end

