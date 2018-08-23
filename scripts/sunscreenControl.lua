return {
	on = {
		devices = {
			'Light level front house',
			'Switch sunscreen upstairs'
		}
	},
	data = {
	    buffer = { history = true, maxItems = 20 },
	},
	execute = function(domoticz, device)
		
		local sunscreenUpstairs = domoticz.devices('Sunscreen front upstairs')
	
		if(device.name == 'Switch sunscreen upstairs') then
			if(device.state == 'On') then
				sunscreenUpstairs.switchOn()
			else
				sunscreenUpstairs.switchOff()
			end
		
		end
	
		if(device.name == 'Light level front house') then
			--add new data to running mean
			domoticz.data.buffer.add(device.percentage)
			domoticz.log('Device ' .. device.name .. ' latest value' .. device.percentage , domoticz.LOG_INFO)
			
			local upstairsManualOverride = false
			
			if(domoticz.devices('Switch sunscreen upstairs').lastUpdate.minutesAgo < 45) then
				upstairsManualOverride = true
			end
			
			local maxWindSpeed = domoticz.devices('Wind speed').gust
			local maxWindThreshold = 12.5
			local rainExpected = domoticz.devices('Buienradar Status').state
			
			if(maxWindSpeed > maxWindThreshold) then
				if(sunscreenUpstairs.state == 'On' and upstairsManualOverride == true) then
					domoticz.notify('Opening the sunscreen',
								'Wind speed is ' ..maxWindSpeed.. ' m/s',
								domoticz.PRIORITY_NORMAL)
					sunscreenUpstairs.switchOff()
				end
			end
			
			if(rainExpected == 'On') then
				if(sunscreenUpstairs.state == 'On' and upstairsManualOverride == true) then
					domoticz.notify('Opening the sunscreen',
								'Rain' ..domoticz.devices('Buienradar Display').text,
								domoticz.PRIORITY_NORMAL)
					sunscreenUpstairs.switchOff()
				end
			end
			
			if(domoticz.data.buffer.size == 20 and sunscreenUpstairs.lastUpdate.minutesAgo > 30) then
				local average = domoticz.data.buffer.avg()
				
				if(average > 10500 and  maxWindSpeed < maxWindThreshold and rainExpected == 'Off') then
					local sendMessage = false
					
					if(sunscreenUpstairs.state == 'Off' and upstairsManualOverride == true) then
						sunscreenUpstairs.switchOn()
						sendMessage = true
					end
					
					if(sendMessage == true) then
						domoticz.notify('Closing the sunscreen',
							 'Average for the last 10 minutes was ' ..average ,
							 domoticz.PRIORITY_NORMAL)
					end            
				end
				
				if(average < 6000) then
					local sendMessage = false
					
					if(sunscreenUpstairs.state == 'On' and upstairsManualOverride == true) then
						sunscreenUpstairs.switchOff()
						sendMessage = true
					end
					
					if(sendMessage == true) then
						domoticz.notify('Opening the sunscreen',
							 'Average for the last 10 minutes was ' ..average ,
							 domoticz.PRIORITY_NORMAL)
					end		        
				end
			end
		end
	end
}