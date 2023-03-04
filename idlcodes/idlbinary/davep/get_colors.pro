function get_colors,n

colors = findgen(n)*(254/(n))+254/(n)

return, colors


end
