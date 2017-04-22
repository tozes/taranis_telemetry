-- function to round values to 2 decimal of precision
function round(num, decimals)
  local mult = 10^(decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

---- Screen setup
-- top left pixel coordinates
local min_x, min_y = 0, 0 
-- bottom right pixel coordinates
local max_x, max_y = 211, 63 
-- set to create a header, the grid will adjust automatically but not its content
local header_height = 0 
-- set the grid left and right coordinates; leave space left and right for batt and rssi
local grid_limit_left, grid_limit_right = 33, 180 
-- calculated grid dimensions
local grid_width = round((max_x - (max_x - grid_limit_right) - grid_limit_left), 0)
local grid_height = round(max_y - min_y - header_height)
local grid_middle = round((grid_width / 2) + grid_limit_left, 0)
local cell_height = round(grid_height / 3, 0)

-- Batt
local max_batt = 4.2
local min_batt = 3.3

-- RSSI
local max_rssi = 90
local min_rssi = 45

-- SWITCHES
local SW_FS = 'sf'
local SW_ARM = 'sd'
local SW_FMODE = 'sc'
local SW_BBOX = 'sa'
local SW_BEEPR = 'se'

-- Data Sources
local DS_VFAS = 'VFAS'
local DS_CELL = 'A4'
local DS_CELL_MIN = 'A4-'
local DS_RSSI = 'RSSI'
local DS_RSSI_MIN = 'RSSI-'


local function drawGrid(lines, cols)
  -- Grid limiter lines
  ---- Table Limits
  lcd.drawLine(grid_limit_left, min_y, grid_limit_right, min_y, SOLID, FORCE)
  lcd.drawLine(grid_limit_left, min_y, grid_limit_left, max_y, SOLID, FORCE)
  lcd.drawLine(grid_limit_right, min_y, grid_limit_right, max_y, SOLID, FORCE)
  lcd.drawLine(grid_limit_left, max_y, grid_limit_right, max_y, SOLID, FORCE)
  ---- Header
  lcd.drawLine(grid_limit_left, min_y + header_height, grid_limit_right, min_y + header_height, SOLID, FORCE)
  ---- Grid
  ------ Top
  lcd.drawLine(grid_middle, min_y + header_height, grid_middle, max_y, SOLID, FORCE)
  ------ Hrznt Line 1
  lcd.drawLine(grid_limit_left, cell_height + header_height - 2, grid_limit_right, cell_height + header_height -2, SOLID, FORCE)
  lcd.drawLine(grid_limit_left, cell_height * 2 + header_height - 1, grid_limit_right, cell_height * 2 + header_height - 1, SOLID, FORCE)
end

-- Draw the battery indicator
local function drawBatt()
  local batt = getValue(DS_VFAS)
  local cell = getValue(DS_CELL)
  local cell_count = math.floor(batt/cell)
  -- Picture
  lcd.drawPixmap(2, 2, "/SCRIPTS/BMP/batt.bmp")
  -- Calculate the size of the level rectangle and draw it
  local total_steps = 30 
  local range = max_batt - min_batt
  local step_size = range/total_steps
  local current_level = math.floor(total_steps - ((cell - min_batt) / step_size))
  lcd.drawFilledRectangle(3, 10 + current_level, 26, 30 - current_level, SOLID)
  -- Values
  lcd.drawText(1, 45, round(cell, 4), DBLSIZE)
  -- Calculate and display the battery cell count (3S, 4S)
  if (cell_count > 0) then 
    lcd.drawText(grid_limit_left + 2, min_y + header_height + cell_height * 2 + 3, cell_count .. "S", DBLSIZE)
  end
end

local function drawRSSI()
  local rssi = getValue(DS_RSSI)
  local total_steps = 10
  local range = max_rssi - min_rssi
  local step_size = range/total_steps
  local current_level = math.floor((rssi - min_rssi) / step_size)

  if current_level > 9 then file = "10"
  elseif current_level == 9 then file = "09"
  elseif current_level == 8 then file = "08"
  elseif current_level == 7 then file = "07"
  elseif current_level == 6 then file = "06"
  elseif current_level == 5 then file = "05"
  elseif current_level == 4 then file = "04"
  elseif current_level == 3 then file = "03"
  elseif current_level == 2 then file = "02"
  elseif current_level == 1 then file = "01"
  else file = "00"
  end
  -- Draw the corresponding picture
  lcd.drawPixmap(grid_limit_right+2, 2, "/SCRIPTS/BMP/RSSI" .. file .. ".bmp")
  -- Display durrent RSSI value
  lcd.drawText(190, 45, round(rssi, 4), DBLSIZE)
end


-- Top Left cell -- Flight mode
local function cell_1()
  local x1 = grid_limit_left + 1
  local y1 = min_y + header_height - 2
  
  -- Picture
  lcd.drawPixmap(x1 + 1, y1 + 4, "/SCRIPTS/BMP/fmode.bmp")

  -- FMODE
  local f_mode = "UNKN"
  local fm = getValue(SW_FMODE)
	if fm < -1000 then
		f_mode = "ACRO"
	elseif (-10 < fm and fm < 10) then
		f_mode = "HRZN"
	elseif fm > 1000 then
	    f_mode = "ANGL"
	end
  lcd.drawText(x1 + 26, y1 + 4, f_mode, DBLSIZE)
end

-- Middle left cell -- Switch statuses (enabled, disabled)
local function cell_2()
  local x1 = grid_limit_left + 1
  local y1 = min_y + header_height + cell_height - 1

  local armed = getValue(SW_ARM)  -- arm / airmode
  local failsafe = getValue(SW_FS)  -- failsafe
  local bbox = getValue(SW_BBOX)  -- blackbox
  local beepr = getValue(SW_BEEPR)  -- blackbox

  if (armed < 10 and failsafe < 0) then
    lcd.drawPixmap(x1 + 4, y1 + 1, "/SCRIPTS/BMP/armed.bmp")
  elseif (failsafe < 0) then
    lcd.drawPixmap(x1 + 4, y1 + 1, "/SCRIPTS/BMP/armed_no.bmp")
  end

  if (armed < -10 and failsafe < 0) then
    lcd.drawPixmap(x1 + 40, y1 + 1, "/SCRIPTS/BMP/airmd.bmp")
  elseif (failsafe < 0) then
    lcd.drawPixmap(x1 + 40, y1 + 1, "/SCRIPTS/BMP/airmd_no.bmp")
  end
  
  if (bbox < -10 and failsafe < 0) then
    lcd.drawPixmap(x1 + 4, y1 + 11, "/SCRIPTS/BMP/blkbox.bmp")
  elseif (failsafe < 0) then
    lcd.drawPixmap(x1 + 4, y1 + 11, "/SCRIPTS/BMP/blkbox_no.bmp")
  end

  if (beepr < -10 and failsafe < 0) then
    lcd.drawPixmap(x1 + 40, y1 + 11, "/SCRIPTS/BMP/beepr.bmp")
  elseif (failsafe < 0) then
    lcd.drawPixmap(x1 + 40, y1 + 11, "/SCRIPTS/BMP/beepr_no.bmp")
  end

  if failsafe > 0 then
    lcd.drawFilledRectangle(x1 + 1, y1 + 1, (grid_limit_right - grid_limit_left) / 2 - 2, cell_height -2, DEFAULT)
    lcd.drawPixmap(x1 + 12, y1 + 6, "/SCRIPTS/BMP/failsafe.bmp")
  end
end

-- Bottom Left cell -- Cell cound and RSSI- and Cell Vmin
local function cell_3()
  local x1 = grid_limit_left + 1
  local y1 = min_y + header_height + cell_height * 2

  local rssi_min = getValue(DS_RSSI_MIN)
  local cell_min = getValue(DS_CELL_MIN)

  lcd.drawPixmap(x1 + 22, y1 + 1, "/SCRIPTS/BMP/rssi_min.bmp")
  lcd.drawText(x1 + 53, y1 + 3, rssi_min .. "dB", SMLSIZE)

  lcd.drawPixmap(x1 + 22, y1 + 11, "/SCRIPTS/BMP/cell_min.bmp")
  lcd.drawText(x1 + 53, y1 + 12, cell_min, SMLSIZE)
end

-- Top Right cell -- Current time
local function cell_4() 
  local x1 = grid_middle + 1
  local y1 = min_y + header_height + 1

  local datenow = getDateTime()
  lcd.drawText(x1 + 3, y1 + 2, datenow.hour .. ":" .. datenow.min .. ":" .. datenow.sec, DBLSIZE)
end

-- Center right cell -- Timer1
local function cell_5() 
  local x1 = grid_middle + 1
  local y1 = min_y + header_height + cell_height + 1

  -- Picture
  lcd.drawPixmap(x1 + 1, y1, "/SCRIPTS/BMP/t1.bmp")

  -- Show timer
  timer = model.getTimer(0)
  s = timer.value
  time = string.format("%.2d:%.2d:%.2d", s/(60*60), s/60%60, s%60)
  lcd.drawText(x1 + 20, y1 + 2, time, MIDSIZE)
end

-- Bottom right cell -- Timer2
local function cell_6() 
  local x1 = grid_middle + 1
  local y1 = min_y + header_height + cell_height * 2 + 1

  -- Picture
  lcd.drawPixmap(x1 + 2, y1 + 1, "/SCRIPTS/BMP/t2.bmp")

  -- Show timer
  timer = model.getTimer(1)
  s = timer.value
  time = string.format("%.2d:%.2d:%.2d", s/(60*60), s/60%60, s%60)
  lcd.drawText(x1 + 20, y1 + 3, time, MIDSIZE)
end

-- Execute
local function run(event)
  lcd.clear()
  cell_1()
  cell_2()
  cell_3()
  cell_4()
  cell_5()
  cell_6()
  drawBatt()
  drawRSSI()
  drawGrid()
end

return{run=run}