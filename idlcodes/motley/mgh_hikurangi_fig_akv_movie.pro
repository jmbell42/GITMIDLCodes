pro mgh_hikurangi_fig_akv_movie, sim, $
     DATA_RANGE=data_range, DESCRIPTOR=descriptor, $
     DEPTH=depth, LEVEL=level, MODEL=model, PATTERN=pattern, $
     TYPE=type

   compile_opt DEFINT32
   compile_opt STRICTARR
   compile_opt STRICTARRSUBS
   compile_opt LOGICAL_PREDICATE

   if n_elements(sim) eq 0 then sim = ['run08','b']

   if n_elements(data_range) eq 0 then data_range = [0,0.4]

   if n_elements(depth) eq 0 then depth = 20.

   if n_elements(type) eq 0 then type = 'average'

   if n_elements(descriptor) eq 0 then descriptor = type

   name = [sim,'akv',string(depth, FORMAT='(I0," m")')]

   table = mgh_make_ct([0,20,60,120,255], $
                       mgh_color(['blue','green','red','yellow','(127,0,50)']))

   ohis = mgh_roms_file('work/hikurangi/'+strjoin(sim, '/'), $
                        PATTERN=pattern, TYPE=type)

   mgh_new, 'mgh_roms_movie_hslice', ohis, 'AKv', STYLE=0, $
            DATA_rANgE=data_range, DEPTH=depth, $
            PALETTE_PROPERTIES={table: table}, $
            GRAPH_PROPERTIES={name: strjoin(name, ' ')}


end
