;+
; NAME:
;	makemovie
;-
;
;
; still does not check for true color png input/output but since it has
; only been used lately for grid files, this shouldn't matter much. i hope
; 07/16/2008 - this doesn't seem to matter, fixed the program to load the
;            - color table as needed and output the image correctly (maybe)
;            - color table can be changed by running xloadct, or loadct
;            - prior to running makemovie
PRO makemovie_event, event
	widget_control, event.top, get_uvalue=state
	kill=0
	CASE event.id OF
		state.wid_cancel : kill=1
		state.wid_accept : kill=2
		state.wid_pickfile: BEGIN
					filters = ['*.grd;*.gif;*.jpg;*.png']
					files = dialog_pickfile(filter=filters,/multiple_files,/read)
					if files[0] ne '' then begin
					IF n_elements(files) GT 0 THEN BEGIN
						widget_control, state.wid_pickfile, set_uvalue=files
						fname = '<'+strcompress(string(n_elements(files)))+' files selected>'
						widget_control, state.wid_filetext, set_value=fname, /no_copy
					END
					end
				    END	
		state.wid_chkbox1 : BEGIN
					IF event.select eq 0 THEN widget_control, state.wid_box1grav, sensitive=0 ELSE widget_control, state.wid_box1grav, sensitive=1
				    END
		state.wid_chkbox2 : BEGIN
					IF event.select eq 0 THEN BEGIN
						widget_control, state.wid_box2val, sensitive=0
						widget_control, state.wid_box2grav, sensitive=0			
					ENDIF ELSE BEGIN
						widget_control, state.wid_box2val, sensitive=1
						widget_control, state.wid_box2grav, sensitive=1
					ENDELSE
				    END
		state.wid_box2val : BEGIN
					widget_control, state.wid_box2val, get_value=box2val
					widget_control, state.wid_box2val, set_value=box2val
				    END
		state.wid_box1grav : BEGIN
					grav1val = widget_info(state.wid_box1grav, /combobox_gettext)
					grav2val = widget_info(state.wid_box2grav, /combobox_gettext)
					IF grav1val EQ grav2val THEN BEGIN 
						widget_control, state.wid_box2grav, set_combobox_select=abs(event.index-1), /update
						grav2val = widget_info(state.wid_box2grav, /combobox_gettext)
					ENDIF
				      END	
		state.wid_box2grav : BEGIN
					grav1val = widget_info(state.wid_box1grav, /combobox_gettext)
					grav2val = widget_info(state.wid_box2grav, /combobox_gettext)
					IF grav1val EQ grav2val THEN BEGIN 
						widget_control, state.wid_box1grav, set_combobox_select=abs(event.index-1), /update 
						grav1val=widget_info(state.wid_box1grav, /combobox_gettext)
					ENDIF
				      END
		state.wid_zmax : BEGIN
                                 widget_control, state.wid_zmin, get_value=zmin
                                 widget_control, state.wid_zmax, get_value=zmax
                                 if zmin ge zmax then begin
                                        print, 'Z-Max must not be smaller than Z-Min, resetting to defaults'
                                        widget_control, state.wid_zmin, set_value='-10.00'
                                        widget_control, state.wid_zmax, set_value='10.00'
                                 end
				END

		state.wid_zmin : BEGIN
				 widget_control, state.wid_zmin, get_value=zmin
				 widget_control, state.wid_zmax, get_value=zmax
				 if zmin ge zmax then begin
					print, 'Z-Min must not be larger than Z-Max, resetting to defaults'
					widget_control, state.wid_zmin, set_value='-10.00'
					widget_control, state.wid_zmax, set_value='10.00'
				 end
				END
                state.wid_qmax : BEGIN
;;;;;;;;;;
;do not need q-max AND q-min, only one, but if both are present, don't want max < min
;

				 widget_control, state.wid_qmin, get_value=qmin
                                 widget_control, state.wid_qmax, get_value=qmax 
                                 if qmin ne '' and qmin ge qmax then begin
					print, 'Q-Max must not be smaller than Q-Min, resetting to defaults'
					widget_control, state.wid_qmin, set_value=''
                                        widget_control, state.wid_qmax, set_value=''
				 end
                                END                                                                    
                state.wid_qmin : BEGIN
				 widget_control, state.wid_zmin, get_value=qmin
                                 widget_control, state.wid_zmax, get_value=qmax
				 if qmax ne '' and qmin ge qmax then begin
                                        print, 'Z-Min must not be larger than Z-Max, resetting to defaults'
                                        widget_control, state.wid_qmin, set_value=''
					widget_control, state.wid_qmax, set_value=''
                                 end
				END

		ELSE: BEGIN
			kill=0
			END
	ENDCASE
	CASE kill OF
	0: widget_control, event.top, set_uvalue=state
	1: BEGIN
		widget_control, event.top, /destroy
		return
	   END
	2: BEGIN
		widget_control, state.wid_pickfile, get_uvalue=files ; copy filenames
		widget_control, state.wid_zmin, get_value=zmin
		widget_control, state.wid_zmax, get_value=zmax
		timestamp = widget_info(state.wid_chkbox1, /button_set)
		textstamp = widget_info(state.wid_chkbox2, /button_set)
		delete = widget_info(state.wid_chkbox3,/button_set)
		widget_control, state.wid_box2val, get_value=textvalue
		widget_control, state.wid_fps, get_value=fps
		widget_control, state.wid_bitrate, get_value=bitrate
		widget_control, state.wid_qmin, get_value=qmin
		widget_control, state.wid_qmax, get_value=qmax
		widget_control, state.wid_resize, get_value=resize
		widget_control, /hourglass
		setfilespec, textvalue ; see if the value is a filename
		isimage = getfilespec(part='type')

		composite = '/usr/bin/composite'
		convert = 'convert'
		ffmpeg = 'ffmpeg'
		CASE !version.os_family OF
		'unix': BEGIN
		        spawn, 'which '+ffmpeg+' 2> /dev/null', ffmpeg   ; Search for executable
		        ffmpeg = ffmpeg[0]
		        spawn, 'which '+convert+'  2> /dev/null', convert
		        convert = convert[0]
			END
		ELSE  : print, 'convert and ffmpeg unavailable.' 
		ENDCASE

		filesave = dialog_pickfile(/write) ; video file to be written (in AVI format)
		SetFileSpec, filesave
		sdir = GetFileSpec(part='dir') ; path to file
		sname = GetFileSpec(part='name') ; filename excluding extention for image writing
		gravity_ts = widget_info(state.wid_box1grav, /combobox_gettext)
		gravity_txt = widget_info(state.wid_box2grav, /combobox_gettext)

		nfiles = n_elements(files) ; number of files, step through each.
		outfile = strarr(n_elements(files))

		for I=0,nfiles-1 DO BEGIN
			SetFileSpec, files[i]
			file = GetFileSpec()
			name = GetFileSpec(part='name')
			type = GetFileSpec(part='type')
			data = ''
			outfile[i] = sdir+sname+string(i,format='(I4.4)')+'.png'
		
			CASE type OF
			'.png' : BEGIN
				read_png, file, data, r, g, b
				if (n_elements(size(data,/dim)) le 2) then begin
					tvlct, r, g, b
					write_image, outfile[i], 'PNG', data, r, g, b
				end
				if (n_elements(size(data,/dim)) eq 3) then begin
					write_image, outfile[i], 'PNG', data
				end
					
				print, 'RENAMING: '+file+' to '+outfile[i]+' OK'
				 END
			'.grd' : BEGIN
				 status = grd_read(file, data)
				 IF NOT status THEN print, 'Cannot read file: '+file
				 print, '%GRD_READ: '+file+' OK'
				 ; apply z-min z-max scaling
				 data = bytscl(data, min=zmin, max=zmax, /nan)
				 tvlct, r, g, b, /get
				 write_image, outfile[i],'PNG', data, r, g, b
				 print, '%WRITE_IMAGE: '+outfile[i]+' OK'
				 END
			'.jpg' : BEGIN
				 read_jpeg, file, data, ctable, colors=256, /two_pass_quantize
				 print, "%READ_JPG: "+file+" OK"
				 ; read_jpeg should produce it's own errors if file is not found for some reason
				 ; load color table and split into rgb
				 tvlct, ctable
				 tvlct, r, g, b, /get
				 write_image, outfile[i], 'PNG', data, r, g, b
                                 print, '%WRITE_IMAGE: '+outfile[i]+' OK'

				 END
			'.gif' : BEGIN
				 read_gif, file, data, r, g, b
				 print, '%READ_GIF: '+file+' OK'
				 write_image, outfile[i], 'PNG', data, r, g, b
                                 print, '%WRITE_IMAGE: '+outfile[i]+' OK'

				 END
			ENDCASE
		progress = '<'+strcompress(string(i+1))+'/'+strcompress(string(nfiles))+' files processed>'
		widget_control, state.wid_filetext, set_value=progress, /no_copy

		; read file in, now process the written pixmaps by adding the necessary stamps
		cmd = ''
		
		if timestamp eq 1 then begin
				framesplit = strsplit(name, "_", /extract)
				if n_elements(framesplit) EQ 4 then begin
				frame = framesplit[2] +' '+ timeset(year=fix(strcompress(framesplit[1],/rem)),doy=fix(strcompress(framesplit[2], /rem)),hour=fix(strmid(framesplit[3],0,2)), minute=fix(strmid(framesplit[3],2,2)), sec=fix(strmid(framesplit[3],4,2)),/stringt,/ymd,upto=timeunit(/sec))
				; write the timestamp
				cmd = " -box '#0009' -font helvetica -fill white -pointsize 12 -gravity "+gravity_ts+" -annotate +0+0 "+'"'+frame+'" '
				print, gravity_ts, frame
				print, cmd
				end
		end

		if textstamp eq 1 then begin
				if file_search(textvalue) eq '' then begin
				cmd = cmd + " -box '#0009' -font helvetica -fill white -pointsize 12 -gravity "+gravity_txt+" -annotate +0+0 "+'"'+textvalue+'" '
				end
		end

; if imagemagick decides the depth on its own, it causes ffmpeg to choke
; more often than not.

		if resize ne '' then cmd = cmd + ' -depth 8 -resize '+strcompress(string(resize))+'% '
		if cmd ne '' then begin
			cmd = convert + ' ' + cmd + outfile[i] +' '+outfile[i] ; complete command
			print, '%IMAGEMAGICK CONVERT ' + cmd
			spawn, cmd
			cmd = ''
		end
;;;;;
;composite seems to be mangling the image headers preventing ffmpeg from functioning??
;;;;;
;revisited 07/16/2008 - seems to work now. likely to do with the color depth
;of the composited image in relation to the input image
;
		if isimage ne '' and file_search(textvalue) ne '' then begin
		; this should come last since it requires composite
			cmd = composite + ' -gravity '+gravity_txt+' '+textvalue+' '+outfile[i]+' '+outfile[i]
			print, '%IMAGEMAGICK COMPOSITE ' + cmd
			spawn, cmd
			cmd = ''
		end	
		endfor

		; now make the movie of the completed images

		cmd = ' -r '+strcompress(string(fps),/rem)+' -b '+strcompress(string(bitrate),/rem)+' -i '+sdir+sname+'%04d.png '
		if qmin ne '' then cmd = cmd + ' -qmin '+strcompress(string(qmin))
		if qmax ne '' and qmax gt qmin then cmd = cmd + ' -qmax '+strcompress(string(qmax))
		cmd = cmd + ' -vcodec msmpeg4v2 -y '+filesave
		cmd = ffmpeg + cmd
		spawn, cmd
		cmd = ''
		print, '%MAKEMOV: '+filesave+' written.'
		if (delete) then begin 
			print, '%MAKEMOV: cleaning files :'+sdir+sname+'*.png'
			file_delete, outfile
		endif else print, '%MAKEMOV: files remain :'+sdir+sname+'*.png'
		widget_control, event.top, /destroy
		return
	   END
	ENDCASE
RETURN & END

PRO makemovie
@compile_opt.pro  

state = {STATE_QSTAMP, $
	 wid_chkbox1:	0L, $       ;state of first checkbox (timestmap)
	 wid_filetext:	0L, $ 	    ;state of file selection
	 wid_box1grav:	0L, $	    ;gravity value for timestmap (which corner it is in)
	 wid_chkbox2:   0L, $	    ;state of second checkbox (text/image)
	 wid_chkbox3:	0L, $	    ;state of 'delete' checkbox
	 wid_box2grav:	0L, $	    ;gravity value for second checkbox
	 wid_box2val:	0L, $	    ;value of text in text/image textbox, if value is a file (.gif) use image
	 wid_pickfile:	0L, $	    ;files
	 wid_fps:	0L, $	    ;frames per second
	 wid_bitrate:	0L, $	    ;bitrate of video
	 wid_qmin:	0L, $	    ;quantization per frame minimum (only set if stuff is really jpeged
	 wid_qmax:	0L, $	    ;"                      maximum "
	 wid_resize:	0L, $	    ;percentage to resize input image
	 wid_zmin:	0L, $	    ;intensity minimum value (default -10) \_ only used if input file is grid
	 wid_zmax:	0L, $	    ;intensity maximum value (default 10)  /
	 wid_accept:	0L, $	    ;
	 wid_cancel:	0L }
	; values for the dropdown list specifying which corner to put tags
	checkboxval = ['northwest', 'northeast', 'southwest', 'southeast']
	; stamp is obsolete, remove it
;	stamp = chk_time ; if valid times detected, time widget is activated
	; widgets
	wid_chk = widget_base(title='Select Frame Options', /column)
	base_widgets = widget_base(wid_chk, /row)
	state.wid_pickfile = widget_button(base_widgets, value="Pick Files", uvalue='pick')
	state.wid_filetext = widget_text(base_widgets, value="<no files selected>",xsize=25)
	state.wid_zmin = cw_field(base_widgets, title='Z-Min', value='-10.00', xsize=5, /floating, /all_events)
	state.wid_zmax = cw_field(base_widgets, title='Z-Max', value='10.00', xsize=5, /floating, /all_events)

	base_options = widget_base(wid_chk, /row)
	base_values = widget_base(base_options, /column,/nonexclusive)
        state.wid_chkbox1 = widget_button(base_values, value="Timestamp",uvalue='timestamp')
	state.wid_chkbox2 = widget_button(base_values, value="String", uvalue='stringstamp')
	base_input = widget_base(base_options, /column, /align_bottom)
	state.wid_box2val = widget_text(base_input, /editable, value="UCSD/CASS", uvalue='boxval')

	base_grav = widget_base(base_options, /column)
	state.wid_box1grav = widget_combobox(base_grav, value=checkboxval)
	widget_control, state.wid_chkbox2, set_button=1 ; checked by default
	state.wid_box2grav = widget_combobox(base_grav, value=checkboxval)
	widget_control, state.wid_box2grav, set_combobox_select=2

	base_vidopts = widget_base(wid_chk, /row)
	base_del = widget_base(base_vidopts,/column,/nonexclusive)
	state.wid_chkbox3 = widget_button(base_del, value="Delete",uvalue='delete')
	state.wid_fps = cw_field(base_vidopts, title='FPS', value=10, xsize=2, /integer)
	state.wid_bitrate = cw_field(base_vidopts, title='Bitrate', value=1500, xsize=5, /integer)
	state.wid_qmin = cw_field(base_vidopts, title='Q-Min', value='', xsize=2, /integer, /all_events)
	state.wid_qmax = cw_field(base_vidopts, title='Q-Max', value='', xsize=2, /integer, /all_events)
	state.wid_resize = cw_field(base_vidopts, title='Resize Percent', value='', xsize=3, /integer)
	

	base_save = widget_base(wid_chk, /row)
        state.wid_accept = widget_button(base_save, uvalue='save', value='Save')
        state.wid_cancel = widget_button(base_save, uvalue='cancel', value='Cancel')

	; make the widgets real
	widget_control, wid_chk, set_uvalue=state, /no_copy
        widget_control, wid_chk, /realize
	xmanager, 'makemovie', wid_chk, event_handler='makemovie_event', /no_block
END
