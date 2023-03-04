; $Id: //depot/idl/IDL_63_RELEASE/idldir/lib/obsolete/disp_txt.pro#1 $
;
; Copyright (c) 1992-2006, Research Systems, Inc.  All rights reserved.
;	Unauthorized reproduction prohibited.
;
;+
; NAME:
;	DISP_TXT
;
; PURPOSE:
;	This procedure displays text strings in the current IDL window.
;       The text strings may contain control sequences which define
;       what font, color, and position to use when drawing the text.
;
; CATEGORY:
;	Text Display.
;
; CALLING SEQUENCE:
;       DISP_TXT, Strings, Fonts, Yspace
;
; INPUTS:
;       Strings:    A string or string array containing the text to
;                   display in the current IDL window.   The string(s)
;                   may contain control sequences which specify what
;                   font, color, and position to use when drawing the text.
;                   Control sequences are enclosed in back quotes.
;                   Control sequences consist of one or more commands
;                   separated by commas.   Commands start with one of
;                   the following upper or lower case characters :
;
;                   F  -  Specify a new font to use
;                   C  -  Specify a new color to use
;                   J  -  Specify a new justification (alignment)
;                   X  -  Specify a new absolute X position (in pixels)
;                   Y  -  Specify a new absolute Y position (in pixels)
;                   H  -  Shift horizontally a relative amount (in pixels)
;                   V  -  Shift vertically a relative amount (in pixels)
;
;                   Here is an example of a text string with an imbedded
;                   control sequence to change to font #2, color #255,
;                   justification 0.5 (center), and absolute Y position 100 :
;
;                      ABCDEF`F2,C255,J0.5,Y100`GHIJKL
;
;                   The actual fonts to use are specified by the "Fonts"
;                   parameter (see below).
;
;                   Care must be taken when specifying any justification
;                   other than 0.0 (left justify) or the strings may overlap.
;                   A good rule of thumb is if center justification (0.5) or
;                   right justification (1.0) is desired, then put the
;                   control commands before or after a block of text, but
;                   not in the middle of it.
;
;                   One line of text is output for each non-null element
;                   in "Strings".   If an element in "Strings" is null
;                   or contains only a control seqence, then no new line
;                   is output.   To output a blank line, use a space
;                   character on a line by itself.
;                   Data Type : String or Strarr.
;
;       Fonts:      A string or string array containing the font(s) to
;                   use.   When a command of the form "Fn" is encountered
;                   while processing the text, the nth element of "Fonts"
;                   is passed to the "Device, Font=" command.   Using the
;                   above example, when the "F2" command is processed,
;                   the font is set by automatically issuing the command :
;
;                      Device, Font=Fonts(2)
;
;                   IF the specified font number is less than zero, or
;                   greater than or equal to the number of elements in
;                   "Fonts", then Fonts(0) is used.
;
;                   Fonts may be specified using wildcards, and may have
;                   an optional field that specifies what style of vector
;                   drawn font to use if the specified hardware font does
;                   not exist.   The optional field is separated from the
;                   actual font string by a "|" character.   (The optional
;                   field is always stripped off before passing the string
;                   to the "Device, Font=" command.)   An example of a
;                   "Fonts" array is as follows :
;
;                      *helvetica-bold*--12*|10!5
;                      vector|20!3
;                      *helvetica-bold*--24*
;
;                   This example array specifies the following :
;
;                   0. Use 12 point helvetica bold hardware font for font F0.
;                      If no matching font exists on the current system
;                      then use vector font style #5 (duplex roman), and size
;                      the font so that it is 10 pixels high.   For a list of
;                      the IDL vector drawn fonts, see chapter 12 in the IDL
;                      User's Guide.
;                   1. Since there is no such thing as a hardware font called
;                      "vector", then use a software (vector drawn) font for
;                      font F1.   Draw this font 20 pixels high and use font
;                      style #3 (simplex roman).
;                   2. Use 24 point helvetica bold hardware font for font F2.
;                      If no matching font exists on the current system
;                      then use the most recently specified vector drawn font
;                      (since there is no optional field specified for this
;                      font).
;
;                   On some Unix systems, it is possible to list the available
;                   hardware fonts by using the Unix command "xlsfonts".
;
;                   When running under Windows or MacOS, fonts are specified
;                   in a slightly different manner.   For example, a Helvetica
;                   italic 24-point font could be specified by the font
;                   definition :
;
;                      HELVETICA*ITALIC*24
;
;                   For best results, use a scalable font.
;
;                   See "The Windows Device Driver" in the "IDL For Windows"
;                   document.
;
;                   Data Type : String or Strarr.
;
;       Yspace:     The spacing, in pixels, between the baseline of each
;                   line of text.   IF "Yspace" is negative then the baseline
;                   of each line of text will be Yspace pixels ABOVE the
;                   previous line.   Otherwise, each line is placed Yspace
;                   pixels BELOW the previous line.
;                   Data Type : Int or Long.
;
; KEYWORD PARAMETERS:
;       Xstart:     The X location (in pixels) at which to start drawing
;                   the text.
;                   The default is to start near the left edge of the current
;                   window (unless the default justification is Center or
;                   Right, in which case the default starting X location is
;                   set accordingly).
;                   Data Type : Int or Long.
;       Ystart:     The Y location (in pixels) at which to start drawing
;                   the text.
;                   The default is to start near the top edge of the current
;                   window.   (Unless "Yspace" is negative, in which case the
;                   default is to start near the bottom edge of the current
;                   window).
;                   Data Type : Int or Long.
;       Def_Font:   The font to use when no font has been specified in
;                   "Strings".   "Def_Font" is specified just like the fonts
;                   in "Fonts" (except that no optional field should be used).
;                   If no font is specified in "Strings" and "Def_Font" is
;                   not supplied, then the default is to use the default
;                   hardware font.   If no hardware font is available then
;                   use a vector drawn font as the default.
;                   Data Type : String.
;
;       Def_Size:   The default height (in pixels) of the vector drawn font.
;                   The default is !D.Y_CH_SIZE.
;                   Data Type : Int or Long.
;
;       Def_Style:  The default style (such as !3, !4, etc.) of the vector
;                   drawn font.
;                   The default is '!3' (simplex roman).
;                   Data type : String.
;
;       Def_Color:  The color index to use when no color is specified in
;                   "Strings".
;                   The default is (!D.N_COLORS - 1L).
;                   Data Type : Byte, Int or Long.
;
;       Colors:     Normally, color indices can be specified directly in
;                   "Strings".   If "Colors" is specified, however, then
;                   "Colors" acts as a translation table to modify the
;                   actual color index of the text.   For example, when the
;                   following string is drawn :
;
;                      `C13`ABCDEF
;
;                   It will be drawn in color index 13 if "Colors" is NOT
;                   specified.   If "Colors" IS specified then the string
;                   "ABCDEF" will be drawn in color index Colors(13).
;
;                   If "Colors" is specified, and the color number is
;                   less than zero then Colors(0) is used.   IF the color
;                   number is greater than or equal to the number of
;                   elements in "Colors" then Colors(n-1) is used
;                   (where "n" is the number of elements in "Colors).
;
;       W_Erase:    The color index to erase the window with before drawing
;                   the text.   If "W_Erase" is less than zero then the window
;                   will NOT be erased first.
;                   The default is to NOT erase the window first.
;                   Data Type : Int or Long.
;
; RESTRICTIONS:
;	An IDL window must exist before calling "DISP_TXT" or an error
;       will result.   All text is drawn in Device coordinates and no 3-D
;       transformations have any effect.
;
; EXAMPLE:
;       Display a text screen using "DISP_TXT"
;
;       ; Create some strings.
;         strings = STRARR(4)
;         strings(0) = '0000000000000'
;         strings(1) = '`F1,C200`'
;         strings(2) = 'ABC`X200,V-100`DEF`F0`GHIJKL`C155`abc'
;         strings(3) = '`C255,F1`ABCDEF`F2`GHIJKL'
;
;       ; Specify the fonts.
;         fonts = STRARR(3)
;         fonts(0) = '*helvetica-bold*--24*|20!5'
;         fonts(1) = 'vector|15!6'
;         fonts(2) = '8x13|11!3'
;
;       ; Create a window and display the text.
;         Window, 0
;         DISP_TXT, strings, fonts, 28, Def_Font='12x24'
;
; MODIFICATION HISTORY:
;       Written by:     Daniel Carr. Tue Sep 29 11:52:56 MDT 1992
;       Added support for 'Win32' and 'MacOS'
;                       Daniel Carr. Mon Nov 23 09:44:33 MST 1992
;       Modified Yspace for 'Win32' and 'MacOS'
;                       Daniel Carr. Thu Dec 17 17:02:40 MST 1992
;-

PRO Disp_Txt, strings, fonts, yspace, Xstart=xstart, Ystart=ystart, $
              Def_Font=def_font, Def_Style=def_style, Def_Just=def_just, $
              Def_Size=def_size, Def_Color=def_color, Colors=colors, $
              W_Erase=w_erase

IF (!D.Window LT 0L) THEN BEGIN
   Print, 'No window exists to draw text in'
   STOP
ENDIF

size_strings = Size(strings)
IF (size_strings(size_strings(0)+1) NE 7L) THEN BEGIN
   Print, 'Text array must be of type string'
   STOP
ENDIF
num_strings = N_Elements(strings)

size_fonts = Size(fonts)
IF (size_fonts(size_fonts(0)+1) NE 7L) THEN BEGIN
   Print, 'Fonts array must be of type string'
   STOP
ENDIF
num_fonts = N_Elements(fonts)

text_space = Fix(yspace(0))

default_size = !D.Y_Ch_Size - 1
IF (N_Elements(def_size) GT 0L) THEN default_size = Long(def_size(0))
vector_size = Float(default_size) / ((Float(!D.Y_Ch_Size) + 6.0) / 2.0)

default_font = ''
IF (N_Elements(def_font) GT 0L) THEN default_font = String(def_font(0))

default_style = '!3'
IF (N_Elements(def_style) GT 0L) THEN default_style = String(def_style(0))

default_just = 0.0
IF (N_Elements(def_just) GT 0L) THEN default_just = $
                                     (Float(def_just(0)) > 0.0) < 1.0

default_color = !D.N_Colors - 1L
IF (N_Elements(def_color) GT 0L) THEN default_color = Long(def_color(0))

t_colors = (-1)
IF (N_Elements(colors) GT 0L) THEN t_colors = (Long(colors) > 0) < $
                                              (!D.N_Colors - 1L)
num_colors = N_Elements(t_colors)

erase_col = (-1)
IF (N_Elements(w_erase) GT 0L) THEN erase_col = Long(w_erase(0)) < $
                                                (!D.N_Colors - 1L)

xpos = ((!D.X_Size - (2 * default_size)) * default_just) + default_size
ypos = !D.Y_Size - (text_space + default_size)
IF ((!Version.Os EQ 'Win32') OR (!Version.Os EQ 'MacOS')) THEN BEGIN
   text_space = Fix(4.0 * Float(text_space) / 5.0) > 1
ENDIF
IF (text_space LT 0) THEN ypos = (-text_space)

IF (N_Elements(xstart) GT 0L) THEN xpos = Fix(xstart(0))
IF (N_Elements(ystart) GT 0L) THEN ypos = Fix(ystart(0))

font_type = 0
fontnum = 0
Device, Font=default_font, Get_Fontnum=fontnum

control_delim = '`'
field_delim = ','
option_delim = '|'
style_delim = '!'

IF (erase_col GE 0L) THEN Erase, erase_col

count = 0L
WHILE ((count LT num_strings) AND $
      ((ypos GE 0) AND (ypos LT !D.Y_Size))) DO BEGIN
   string_len = Strlen(strings(count))

   Xyouts, xpos, ypos, default_style, /Device, Font=(-1), Size=vector_size, $
           Color=default_color, T3d=0, Alignment=default_just
   c_xpos = xpos

   new_line = 0B
   cur_pos = 0
   WHILE (cur_pos LE string_len) DO BEGIN
      control_pos_l = Strpos(strings(count), control_delim, cur_pos)
      control_pos_r = Strpos(strings(count), control_delim, (control_pos_l + 1))
      IF (control_pos_r GE cur_pos) THEN $
         draw_string = Strmid(strings(count), cur_pos, $
         (control_pos_l-cur_pos)) $
      ELSE $
         draw_string = Strmid(strings(count), cur_pos, string_len)

      cur_pos = cur_pos + Strlen(draw_string)

      IF (draw_string NE '') THEN BEGIN
         Xyouts, c_xpos, ypos, draw_string, /Device, Font=font_type, $
                 Size=vector_size, Alignment=default_just, $
                 Color=default_color, T3d=0, Width=t_wide
         c_xpos = c_xpos + Fix(t_wide * Float(!D.X_SIZE) * (1.0 - default_just))
         new_line = 1B
      ENDIF

      IF ((control_pos_l GE cur_pos) AND (control_pos_r GE (cur_pos + 1))) $
      THEN BEGIN
         control_string = Strmid(strings(count), (control_pos_l + 1), $
                          (control_pos_r - (control_pos_l + 1)))
         control_len = Strlen(control_string)

         control_pos = 0
         WHILE (control_pos LE control_len) DO BEGIN

            control_string1 = control_string
            field_pos = Strpos(control_string, field_delim, control_pos)
            IF (field_pos GE control_pos) THEN $
               control_string1 = Strmid(control_string, control_pos, $
                                 (field_pos - control_pos)) $
            ELSE $
               control_string1 = Strmid(control_string, $
                                 control_pos, control_len)

            control_len1 = Strlen(control_string1)
            control_pos = control_pos + control_len1

            first_char = Strupcase(Strmid(control_string1, 0, 1))
            CASE first_char OF
                'J': BEGIN
                        just_string = Strmid(control_string1, 1, control_len1)
                        IF (just_string NE '') THEN BEGIN
                           ON_IOERROR, SKIP_JUST
                              temp_just = Float(just_string)
                              default_just = temp_just
                           SKIP_JUST:
                           ON_IOERROR, NULL
                        ENDIF
                     END
                'X': BEGIN
                        x_string = Strmid(control_string1, 1, control_len1)
                        IF (x_string NE '') THEN BEGIN
                           ON_IOERROR, SKIP_X
                              temp_x = Float(x_string)
                              xpos = temp_x
                              c_xpos = temp_x
                           SKIP_X:
                           ON_IOERROR, NULL
                        ENDIF
                     END
                'Y': BEGIN
                        y_string = Strmid(control_string1, 1, control_len1)
                        IF (y_string NE '') THEN BEGIN
                           ON_IOERROR, SKIP_Y
                              temp_y = Float(y_string)
                              ypos = temp_y
                           SKIP_Y:
                           ON_IOERROR, NULL
                        ENDIF
                     END
                'H': BEGIN
                        horiz_string = Strmid(control_string1, 1, control_len1)
                        IF (horiz_string NE '') THEN BEGIN
                           ON_IOERROR, SKIP_HORIZ
                              temp_horiz = Float(horiz_string)
                              c_xpos = c_xpos + temp_horiz
                              xpos = c_xpos
                           SKIP_HORIZ:
                           ON_IOERROR, NULL
                        ENDIF
                     END
                'V': BEGIN
                        vert_string = Strmid(control_string1, 1, control_len1)
                        IF (vert_string NE '') THEN BEGIN
                           ON_IOERROR, SKIP_VERT
                              temp_vert = Float(vert_string)
                              ypos = ypos + temp_vert
                           SKIP_VERT:
                           ON_IOERROR, NULL
                        ENDIF
                     END
                'C': BEGIN
                        color_string = Strmid(control_string1, 1, control_len1)
                        IF (color_string NE '') THEN BEGIN
                           ON_IOERROR, SKIP_COLOR
                              temp_color = Long(color_string)
                              IF (t_colors(0) GE 0L) THEN $
                                 default_color = t_colors((temp_color > 0L) < $
                                                         (num_colors - 1L)) $
                              ELSE $
                                 default_color = (temp_color > 0L) < $
                                                 (!D.N_Colors - 1L)
                           SKIP_COLOR:
                           ON_IOERROR, NULL
                        ENDIF
                     END
                'F': BEGIN
                        font_string = Strmid(control_string1, 1, control_len1)
                        font_index = 0L
                        IF (font_string NE '') THEN BEGIN
                           ON_IOERROR, SKIP_FONT
                              temp_index = Long(font_string) > 0L
                              font_index = temp_index
                           SKIP_FONT:
                           ON_IOERROR, NULL
                           IF (font_index GE num_fonts) THEN font_index = 0L

                           font_string1 = fonts(font_index)
                           font_string2 = ''
                           option_pos = Strpos(fonts(font_index), option_delim)
                           IF (option_pos GE 0) THEN BEGIN
                              font_string1 = Strmid(fonts(font_index), 0, $
                                             option_pos)
                              font_string2 = Strmid(fonts(font_index), $
                                             (option_pos+1), $
                                             Strlen(fonts(font_index)))
                           ENDIF

                           fontnum = 0
                           Device, Font=font_string1, Get_Fontnum=fontnum
                           IF (fontnum GT 0) THEN BEGIN
                              Device, Font=font_string1
                              font_type = 0
                           ENDIF ELSE BEGIN
                              font_type = (-1)
                              IF (font_string2 NE '') THEN BEGIN
                                 style_pos = Strpos(font_string2, style_delim)
                                 y_size_string = Strmid(font_string2, 0, $
                                                        style_pos)
                                 style_string = Strmid(font_string2, $
                                                style_pos, Strlen(font_string2))

                                 IF (y_size_string NE '') THEN BEGIN
                                    ON_IOERROR, SKIP_SIZE
                                       temp_size = Fix(y_size_string)
                                       default_size = temp_size
                                    SKIP_SIZE:
                                    ON_IOERROR, NULL
                                 ENDIF
                                 vector_size = Float(default_size) / $
                                               ((Float(!D.Y_Ch_Size) + 6.0) / $
                                               2.0)

                                 IF (style_string NE '') THEN BEGIN
                                    Xyouts, c_xpos, ypos, style_string, $
                                            /Device, $
                                            Font=font_type, Size=vector_size, $
                                            Color=default_color, T3d=0, $
                                            Width=t_wide, Alignment=default_just
                                    c_xpos = c_xpos + $
                                             Fix(t_wide * Float(!D.X_SIZE) * $
                                             (1.0 - default_just))
                                 ENDIF
                              ENDIF
                              vector_size = Float(default_size) / $
                                            ((Float(!D.Y_Ch_Size) + 6.0) / 2.0)
                           ENDELSE
                        ENDIF
                     END
               ELSE:
            ENDCASE
            control_pos = control_pos + 1
         ENDWHILE

         cur_pos = cur_pos + control_len + 2
      ENDIF ELSE BEGIN
         cur_pos = cur_pos + 1
      ENDELSE

   ENDWHILE

   shift_down = text_space
   IF ((!Version.Os EQ 'Win32') OR (!Version.Os EQ 'MacOS')) THEN $
      shift_down = Fix(4.0 * Float(text_space) / 5.0) > 1

   IF (new_line) THEN ypos = ypos - shift_down

   count = count + 1L
ENDWHILE

Empty

RETURN
END
