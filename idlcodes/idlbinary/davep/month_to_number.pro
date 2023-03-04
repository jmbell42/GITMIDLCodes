function month_to_number, month
  month = strlowcase(month)
  if strpos(month, 'jan') ge 0 then num = '01'
  if strpos(month, 'feb') ge 0 then num = '02'
  if strpos(month, 'mar') ge 0 then num = '03'
  if strpos(month, 'apr') ge 0 then num = '04'
  if strpos(month, 'may') ge 0 then num = '05'
  if strpos(month, 'jun') ge 0 then num = '06'
  if strpos(month, 'jul') ge 0 then num = '07'
  if strpos(month, 'aug') ge 0 then num = '08'
  if strpos(month, 'sep') ge 0 then num = '09'
  if strpos(month, 'oct') ge 0 then num = '10'
  if strpos(month, 'nov') ge 0 then num = '11'
  if strpos(month, 'dec') ge 0 then num = '12'

return, num

end
