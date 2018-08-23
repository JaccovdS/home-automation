-- BuienRadar Module
--
-- curl in os required!!
-- create dummy text device from dummy hardware 'Buien Radar'
-- create dummy rain sensor from dummy hardware 'BuienRadarMeter'
-- create dummy switch from dummy hardware for triggering screens etc based on rain
-- add as time based lua script
-- set your longitude & latitude below!

-- 2017-12-27 working version
-- 2017-12-28 trying to get the rain device working .. missing documentation ..
-- 2017-12-30 isolated the bug, i was overwriting the updatedevice .. should be ok now
-- 2018-03-28 updated buienradar url
-- 2018-04-02 added follow redirect for curl & fixed typo as tipped by gizmocuz 

commandArray = {}

local myBuienRadarDevice='Buienradar Display'
local myBuienRadarMeter='Buienradar Meter'
local myBuienRadarFlg='Buienradar Status'

-- longitude latitude
local lat='51.82'
local lon='4.64'

time = os.date("*t")
if ((time.min % 5)==0)  then 
    
    print('BuienRadar module')

    function os.capture(cmd, rep)   -- execute command to get site
        -- rep is nr of repeats if result is empty
        r = rep or 1
        local s = ""
        while ( s == "" and r > 0) do
            r = r-1
            local f = assert(io.popen(cmd, 'r'))
            s = assert(f:read('*a'))
            f:close()
        end
        if ( rep - r > 1 ) then
            print("os.capture needed more than 1 call: " .. rep-r)
        end
      return s
    end
 
    --  get data from buienradar
    local command = "curl --max-time 5 -L -s 'http://gpsgadget.buienradar.nl/data/raintext?lat=" .. lat .. "&lon=" .. lon .. "'"
    -- print("command: " .. command)
    local tmp = os.capture(command, 3)
 
    -- print('buienRadar data:\n' .. tmp)
    
    if ( tmp == "" ) then
        print("buienRadar: Empty result from curl command")
    else
        -- analyse data 

        -- to mm/h 10^((waarde-109)/32)        
        function tomm(r)
            return 10^((r-109)/32)
        end
        
        -- to string formatted
        function tos(r, c)
            c = c or 1
            return string.format("%." .. c .. "f", r)
        end

        local c=0
        local rainNow=0
        local rainNowAvg = 0
        local rainSoon = 0
        local rainTime = ""
        local rainMax = 0
        for k,v in tmp:gmatch('(.-)|(.-)\r?\n') do
            -- k is rain value, v is time
            kn = tonumber(k)
            if c<=1 then
                if rainNow < kn then
                    rainNow = kn
                end
                if kn > 0 then
                    rainNowAvg = rainNowAvg + tomm(kn)/2
                end
            end
            if c<=3 and rainSoon < kn then 
                rainSoon = kn
            end
            if rainTime == "" and kn > 0 then
                rainTime = v
            end
            if kn > rainMax then
                rainMax = kn
            end
            c = c+1
        end
        
        -- if c = 0 no data found!
        if ( c == 0 ) then
            print("buienRadar: Unparsable result from curl command")
        else
        
            if rainNow>0 then
                tmp = "now; " .. tos(tomm(rainNow)) .. "mm/h"
                if rainMax > rainNow then
                    tmp = tmp .. " upto " .. tos(tomm(rainMax)) .. "mm/h"
                end
            elseif rainSoon>0 then
                tmp = "soon in 15mins; " .. tos(tomm(rainSoon)) .. "mm/h"
                if rainMax > rainSoon then
                    tmp = tmp .. " upto " .. tos(tomm(rainMax)) .. "mm/h"
                end
            elseif rainTime ~= "" then
                tmp = "expected @ " .. rainTime .. "; upto " .. tos(tomm(rainMax)) .. "mm/h"
            else tmp = "No rain"
            end
    
            -- calculate totalrainfall using rainNowAvg as average of 2 next reports
            -- print("buienRadarMeterOld: " .. otherdevices_svalues[myBuienRadarMeter])
            local rainTot = tonumber(otherdevices_svalues[myBuienRadarMeter]:match("[^;]+;([^;]+)")) + rainNowAvg/12 -- /12 to acount for 5min measurements ?? ..
            -- print("buienRadarDebug: rainNow=" .. tos(tomm(rainNow)) .. " rainNowAvg=" .. tos(rainNowAvg) .. " rainSoon=" .. 
            --      tos(tomm(rainSoon)) .. " rainTot=" .. tos(rainTot,2) .. " rainTime=" .. rainTime .. " rainMax=" .. tos(tomm(rainMax)))
            local cmd = otherdevices_idx[myBuienRadarMeter] .. "|0|" .. tos(tomm(rainNow)*100,0) .. ";" .. tos(rainTot,2)
            -- print("buienRadar: " .. cmd)
            table.insert(commandArray, { ['UpdateDevice'] = cmd } ) -- table.insert needed to avoid overwriting with next updatedevice
            
            -- write to text device
            if otherdevices[myBuienRadarDevice] ~= tmp then
                table.insert(commandArray, { ['UpdateDevice'] = otherdevices_idx[myBuienRadarDevice] .. '|0|' .. tmp })
                
                -- trigger based when rainNow or rainSoon (more than 1 mm rain)
                if ( rainNow>109 or rainSoon>109 ) then
                    if otherdevices[myBuienRadarFlg] == "Off" then
                        commandArray[myBuienRadarFlg] = "On"
                    end
                elseif otherdevices[myBuienRadarFlg] == "On" then
                    commandArray[myBuienRadarFlg] = "Off"
                end
            end
        end -- unparsable
    end -- empty result
end

return commandArray