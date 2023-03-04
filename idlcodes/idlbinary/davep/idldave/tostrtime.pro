PRO tostrtime,itime,strtime
  
  itime = tostr(itime)
  cyear= itime(0)
  cmon = chopr('0'+itime(1),2)
  cday=chopr('0'+itime(2),2)
  chour=chopr('0'+itime(3),2)
  cmin=chopr('0'+itime(4),2)
  csec=chopr('0'+itime(5),2)

  strtime = cmon+'/'+cday+'/'+cyear+' '+chour+':'+cmin
end
