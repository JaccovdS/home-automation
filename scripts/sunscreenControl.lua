return {
	on = {
		devices = {
			'Light level front house',
			'Switch sunscreen upstairs'
			'Switch sunscreen downstairs'
		}
	},
	data = {
	    buffer = { history = true, maxItems = 20 },
	},
	execute = function(domoticz, device)
		
		local sunscreenUpstairs = domoticz.devices('Sunscreen front upstairs')
		local sunscreenDownstairs = domoticz.devices('Suncreen front downstairs')
	
		if(device.name == 'Switch sunscreen upstairs') then
			if(device.state == 'On') then
				sunscreenUpstairs.switchOn()
			else
				sunscreenUpstairs.switchOff()
			end
		
		end
		
		if(device.name == 'Switch sunscreen downstairs') then
			if(device.state == 'On') then
				sunscreenDownstairs.switchOn()
			else
				sunscreenDownstairs.switchOff()
			end
		
		end
	
		if(device.name == 'Light level front house') then
			--add new data to running mean
			domoticz.data.buffer.add(device.percentage)
			domoticz.log('Device ' .. device.name .. ' latest value' .. device.percentage , domoticz.LOG_INFO)
			
			local upstairsManualOverride = false
			local downstairsManualOverride = false
			
			if(domoticz.devices('Switch sunscreen upstairs').lastUpdate.minutesAgo < 45) then
				upstairsManualOverride = true
			end
			
			if(domoticz.devices('Switch sunscreen downstairs').lastUpdate.minutesAgo < 45) then
				downstairsManualOverride = true
			end
			
			local maxWindSpeed = domoticz.devices('Wind speed').gust
			local maxWindThreshold = 12.5
			local rainExpected = domoticz.devices('Buienradar Status').state
			
			if(maxWindSpeed > maxWindThreshold) then
				local sendMessage = false
				if(sunscreenDownstairs.state == 'On' and downstairsManualOverride == false) then
					sendMessage = true
					sunscreenDownstairs.switchOff()
				end
				
				if(sunscreenUpstairs.state == 'On' and upstairsManualOverride == false) then
					sendMessage = true
					sunscreenUpstairs.switchOff()
				end
				
				if(sendMessage == true) then
					domoticz.notify('Opening the sunscreen',
								'Wind speed is ' ..maxWindSpeed.. ' m/s',
								domoticz.PRIORITY_NORMAL)
				end
			end
			
			if(rainExpected == 'On') then
				local sendMessage = false
				if(sunscreenDownstairs.state == 'On' and downstairsManualOverride == false) then
					sendMessage = true
					sunscreenDownstairs.switchOff()
				end
				
				if(sunscreenUpstairs.state == 'On' and upstairsManualOverride == false) then
					sendMessage = true
					sunscreenUpstairs.switchOff()
				end
				
				if(sendMessage == true) then
					domoticz.notify('Opening the sunscreen',
								'Rain' ..domoticz.devices('Buienradar Display').text,
								domoticz.PRIORITY_NORMAL)
				end
			end
			
			if(domoticz.data.buffer.size == 20 and sunscreenUpstairs.lastUpdate.minutesAgo > 30) then
				local average = domoticz.data.buffer.avg()
				
				if(average > 10500 and  maxWindSpeed < maxWindThreshold and rainExpected == 'Off') then
					local sendMessage = false
					
					if(sunscreenUpstairs.state == 'Off' and upstairsManualOverride == false) then
						sunscreenUpstairs.switchOn()
						sendMessage = true
					end
					
					if(sunscreenDownstairs.state == 'Off' and downstairsManualOverride == false) then
						sunscreenDownstairs.switchOn()
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
					
					if(sunscreenDownstairs.state == 'On' and downstairsManualOverride == false) then
						sunscreenDownstairs.switchOff()
						sendMessage = true
					end
					
					if(sunscreenUpstairs.state == 'On' and upstairsManualOverride == false) then
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