-- by mor2000

UniversalProcessKitEnvironment = {}
UniversalProcessKitEnvironment.sun=nil
UniversalProcessKitEnvironment.rain=nil
UniversalProcessKitEnvironment.temperature=nil

UniversalProcessKitEnvironment.RAINPOWER_RAIN=70
UniversalProcessKitEnvironment.RAINPOWER_HAIL=100

UniversalProcessKitEnvironment.TEMPERATURE_HOUR_COLDEST=5
UniversalProcessKitEnvironment.TEMPERATURE_HOUR_HOTTEST=17

function UniversalProcessKitEnvironment:minuteChanged()
	printFn('UniversalProcessKitEnvironment:minuteChanged()')
	UniversalProcessKitEnvironment.setSun()
	UniversalProcessKitEnvironment.setRain()
end

function UniversalProcessKitEnvironment:hourChanged()
	printFn('UniversalProcessKitEnvironment:hourChanged()')
	UniversalProcessKitEnvironment.setTemperature()
end

function UniversalProcessKitEnvironment:setSun()
	printFn('UniversalProcessKitEnvironment:setSun()')
	local lightScale=1
	if g_currentMission.environment.currentRain~=nil then
		local rainTime = (g_currentMission.environment.currentDay - g_currentMission.environment.currentRain.startDay) * g_currentMission.environment.dayLength +
			(g_currentMission.environment.dayTime - g_currentMission.environment.currentRain.startDayTime)
		if rainTime < g_currentMission.environment.currentRain.duration then
			if rainTime > g_currentMission.environment.currentRain.duration - g_currentMission.environment.rainFadeDuration then
				lightScale, _, _, _ = g_currentMission.environment.rainFadeCurve:get((g_currentMission.environment.currentRain.duration - rainTime) / 60000)
			else
				lightScale, _, _, _ = g_currentMission.environment.rainFadeCurve:get(rainTime / 60000)
			end
		end
	end
	UniversalProcessKitEnvironment.sun=lightScale*100
	--print('UniversalProcessKitEnvironment.sun='..tostring(UniversalProcessKitEnvironment.sun))
end

function UniversalProcessKitEnvironment:setRain()
	printFn('UniversalProcessKitEnvironment:setRain()')
	if g_currentMission.environment.currentRain~=nil then
		local rainType=g_currentMission.environment.currentRain.rainTypeId
		--print('rainType='..tostring(rainType))
		if rainType==Environment.RAINTYPE_RAIN then
			UniversalProcessKitEnvironment.rain=UniversalProcessKitEnvironment.RAINPOWER_RAIN
		elseif rainType==Environment.RAINTYPE_HAIL then
			UniversalProcessKitEnvironment.rain=UniversalProcessKitEnvironment.RAINPOWER_HAIL
		end
	else
		UniversalProcessKitEnvironment.rain=0
	end
	--print('UniversalProcessKitEnvironment.rain='..tostring(UniversalProcessKitEnvironment.rain))
end

function UniversalProcessKitEnvironment:setTemperature()
	printFn('UniversalProcessKitEnvironment:setTemperature()')
	printInfo('g_currentMission.environment.currentHour='..tostring(g_currentMission.environment.currentHour))
	if g_currentMission.environment.currentHour>UniversalProcessKitEnvironment.TEMPERATURE_HOUR_COLDEST and
		g_currentMission.environment.currentHour<=UniversalProcessKitEnvironment.TEMPERATURE_HOUR_HOTTEST then
		local factor=g_currentMission.environment.currentHour-UniversalProcessKitEnvironment.TEMPERATURE_HOUR_COLDEST-1
		printInfo('factor='..tostring(factor))
		local factor2=mathsin((factor/12)*(mathpi/2))
		printInfo('factor2='..tostring(factor2))
	elseif g_currentMission.environment.currentHour<=UniversalProcessKitEnvironment.TEMPERATURE_HOUR_COLDEST then
		printInfo('night before day')
	elseif g_currentMission.environment.currentHour>UniversalProcessKitEnvironment.TEMPERATURE_HOUR_HOTTEST then
		printInfo('night after day')
		local factor= (g_currentMission.environment.currentHour+UniversalProcessKitEnvironment.TEMPERATURE_HOUR_COLDEST+1)%24
		printInfo('factor='..tostring(factor))
		local factor2=mathcos((factor/12)*(mathpi/2))
		printInfo('factor2='..tostring(factor2))
	end
	--print('g_currentMission.environment.weatherTemperaturesDay[1]='..tostring(g_currentMission.environment.weatherTemperaturesDay[1]))
	--print('g_currentMission.environment.weatherTemperaturesNight[1]='..tostring(g_currentMission.environment.weatherTemperaturesNight[1]))
end

