-- This code is an adaptation of Tozes' lua script for X9D.
-- As the QX7 doesn't allow functions like pixmap and can display images, all the bmp files have been replaced by text and rectangles.
-- This script is made for my model setup. You can change it if it doesn't fit your model setup.

-- function to round values to 2 decimal of precision
function round(num, decimals)
  local mult = 10^(decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

---- Screen setup
-- top left pixel coordinates
local min_x, min_y = 0, 0 
-- bottom right pixel coordinates
local max_x, max_y = 128, 63 
-- set to create a header, the grid will adjust automatically but not its content
local header_height = 0 
-- set the grid left and right coordinates; leave space left and right for batt and rssi
local grid_limit_left, grid_limit_right = 20, 108 
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
local SW_FS = 'sa'
local SW_ARM = 'sf'
local SW_AIR = 'sc'
local SW_FMODE = 'sb'
local SW_BBOX = 'sd'
local SW_BEEPR = 'sa'

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
  local cell = batt/cell_count
  -- Calculate the size of the level
  local total_steps = 30 
  local range = max_batt - min_batt
  local step_size = range/total_steps
  local current_level = math.floor(total_steps - ((cell - min_batt) / step_size))
    --draw graphic battery level
  lcd.drawFilledRectangle(6, 2, 8, 4, SOLID)
  lcd.drawFilledRectangle(3, 5, 14, 32, SOLID)
  lcd.drawFilledRectangle(4, 6, 12, current_level, ERASE)
    
  -- Values
  lcd.drawText(2, 39, round(cell, 2),SMLSIZE)
    
  if batt<10 then
    lcd.drawText(2, 48, round(batt, 2),SMLSIZE)
  else
    lcd.drawText(2, 48, round(batt, 1),SMLSIZE)
  end
  
    
  lcd.drawText(1, 57, "Vbat", INVERS+SMLSIZE)
  -- Calculate and display the battery cell count (3S, 4S)
  if (cell_count > 0) then 
    lcd.drawText(grid_limit_left + 4, min_y + header_height + cell_height * 2 + 3, cell_count .. "S", DBLSIZE)
    lcd.drawText(grid_limit_left + 29, min_y + header_height + cell_height * 2 + 3, max_batt)
    lcd.drawText(grid_limit_left + 29, min_y + header_height + cell_height * 2 + 3 + 9, min_batt)
  end
end

local function drawRSSI()
  local rssi = getValue(DS_RSSI)
  local CLAMPrssi = rssi
  if (rssi<45) then
        CLAMPrssi = 45
    elseif (rssi>90) then
        CLAMPrssi = 90
    end
    
  local total_steps = 30
  local range = max_rssi - min_rssi
  local step_size = range/total_steps
  local current_level = math.floor(total_steps-((CLAMPrssi - min_rssi) / step_size))

    --draw graphic rssi level
  lcd.drawFilledRectangle(111, 4, 14, 32, SOLID)
  lcd.drawFilledRectangle(112, 5, 12, current_level, ERASE)

  -- Display durrent RSSI value
  lcd.drawText(110, 38, round(rssi, 0), DBLSIZE)
  lcd.drawText(109, 57, "rssi", INVERS+SMLSIZE)
end


-- Top Left cell -- Flight mode
local function cell_1()
  local x1 = grid_limit_left + 1
  local y1 = min_y + header_height - 2

  -- FMODE
  local f_mode = "UNKN"
  local fm = getValue(SW_FMODE)
	if fm < -1000 then
		f_mode = "ANGL"
	elseif (-10 < fm and fm < 10) then
		f_mode = "HRZN"
	elseif fm > 1000 then
	    f_mode = "ACRO"
	end
  lcd.drawText(x1 + 4, y1 + 6, f_mode, MIDSIZE)
end

-- Middle left cell -- Switch statuses (enabled, disabled)
local function cell_2()
  local x1 = grid_limit_left + 1
  local y1 = min_y + header_height + cell_height - 1

  local armed = getValue(SW_ARM)  -- arm
  local airmode = getValue(SW_AIR)  -- airmode
  local failsafe = getValue(SW_FS)  -- failsafe
  local bbox = getValue(SW_BBOX)  -- blackbox
  local beepr = getValue(SW_BEEPR)  -- blackbox
  local fm = getValue(SW_FMODE)

  if (armed < 10 and failsafe < 0) then
        lcd.drawText(x1 + 3, y1 + 2, "Arm", SMLSIZE)
  elseif (failsafe < 0) then
        lcd.drawText(x1 + 3, y1 + 2, "Arm", INVERS+SMLSIZE)
  end

  if (airmode < -10 and failsafe < 0) then
        if (fm > -10 and failsafe < 0) then
        lcd.drawText(x1 + 25, y1 + 2, "Air", INVERS+SMLSIZE)
        elseif (failsafe < 0) then
        lcd.drawText(x1 + 25, y1 + 2, "Air", SMLSIZE)
        end
  elseif (failsafe < 0) then
        lcd.drawText(x1 + 25, y1 + 2, "Air", INVERS+SMLSIZE)
  end
  
  if (bbox < -10 and failsafe < 0) then
        lcd.drawText(x1 + 3, y1 + 12, "Bbx", SMLSIZE)
  elseif (failsafe < 0) then
        lcd.drawText(x1 + 3, y1 + 12, "Bbx", INVERS+SMLSIZE)
  end

  if (beepr < 10 and failsafe < 0) then
        lcd.drawText(x1 + 25, y1 + 12, "Bpr", SMLSIZE)
  elseif (failsafe < 0) then
        lcd.drawText(x1 + 25, y1 + 12, "Bpr", INVERS+SMLSIZE)
  end

 if failsafe > -10 then
        lcd.drawFilledRectangle(x1, y1, (grid_limit_right - grid_limit_left) / 2, cell_height, DEFAULT)
        lcd.drawText(x1+2, y1+2, "FailSafe", SMLSIZE+INVERS+BLINK)
        lcd.drawText(x1 + 25, y1 + 12, "Bpr", INVERS+SMLSIZE+BLINK)
 end
end

-- Top Right cell -- Current time
local function cell_4() 
  local x1 = grid_middle + 1
  local y1 = min_y + header_height + 1

  local datenow = getDateTime()
  lcd.drawText(x1 + 4, y1 + 6, datenow.hour .. ":" .. datenow.min .. ":" .. datenow.sec)
end

-- Center right cell -- Timer1
local function cell_5() 
  local x1 = grid_middle + 1
  local y1 = min_y + header_height + cell_height + 1

  lcd.drawText(x1, y1, "T1", INVERS)

  -- Show timer
  timer = model.getTimer(0)
  s = timer.value
  time = string.format("%.2d:%.2d:%.2d", s/(60*60), s/60%60, s%60)
  lcd.drawText(x1 + 4, y1 + 10, time)
end

-- Bottom right cell -- Timer2
local function cell_6() 
  local x1 = grid_middle + 1
  local y1 = min_y + header_height + cell_height * 2 + 1

  lcd.drawText(x1, y1, "T2", INVERS)
  -- Show timer
  timer = model.getTimer(1)
  s = timer.value
  time = string.format("%.2d:%.2d:%.2d", s/(60*60), s/60%60, s%60)
  lcd.drawText(x1 + 4, y1 + 10, time)
end

-- Execute
local function run(event)
  lcd.clear()
  cell_1()
  cell_2()
  cell_4()
  cell_5()
  cell_6()
  drawBatt()
  drawRSSI()
  drawGrid()
end

return{run=run}