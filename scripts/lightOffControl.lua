return {
   on = {
      timer = {
         'at 22:30 on sun, mon, tue, wed, thu',
         'at 23:59 on fri, sat'
      }
   },
   execute = function(domoticz, timer)

	-- Turn off some lights
	domoticz.devices('Light top cupboard').switchOff()
		
	domoticz.devices('Light corner TV').switchOff()
		
	domoticz.devices('Light inside cupboard').switchOff()
	
      --Turn off all lights no matter what
	domoticz.groups('All lights').switchOff()
	  
   end
}