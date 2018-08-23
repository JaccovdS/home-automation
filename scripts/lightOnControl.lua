return {
	on = {
		devices = {
			'Light level front house'
		}
	},
	data = {
	    buffer = { history = true, maxItems = 10 }
	},
	execute = function(domoticz, device)		
		--add new data to running mean
		domoticz.data.buffer.add(device.percentage)
		
		-- Decide to turn on based on light level 		
		if(domoticz.data.buffer.size == 10) then
		    local average = domoticz.data.buffer.avg()
		    
		    domoticz.log('Device ' .. device.name .. ' average' ..average , domoticz.LOG_INFO)
		    
			local Time = require('Time')
			local now = Time()
			
		    if(average < 140 and now.matchesRule('at 15:00-22:00')) then
		        domoticz.log('Turn on lights' , domoticz.LOG_INFO)
				-- Turn on some lights
				if(domoticz.devices('Light inside cupboard').state == 'Off') then
					domoticz.devices('Light inside cupboard').switchOn()
				end
				
				if(domoticz.devices('Light corner TV').state == 'Off') then
					domoticz.devices('Light corner TV').switchOn()
				end
			
				if(domoticz.devices('Light top cupboard').state == 'Off') then
					domoticz.devices('Light top cupboard').switchOn()
				end
	        end
		end		
	end
}