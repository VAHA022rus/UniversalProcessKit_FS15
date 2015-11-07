-- by mor2000

UniversalProcessKitEnvironment = {}
UniversalProcessKitEnvironment.sun=nil
UniversalProcessKitEnvironment.rain=nil
UniversalProcessKitEnvironment.temperature=nil

UniversalProcessKitEnvironment.RAINPOWER_RAIN = 70
UniversalProcessKitEnvironment.RAINPOWER_HAIL = 100
UniversalProcessKitEnvironment.RAINPOWER_FOG = 10
UniversalProcessKitEnvironment.RAINPOWER_CLOUDY = 0

UniversalProcessKitEnvironment.SUNPOWER_DAY = 100
UniversalProcessKitEnvironment.SUNPOWER_NIGHT = 20
UniversalProcessKitEnvironment.SUNPOWER_NIGHTRAIN = 10

UniversalProcessKitEnvironment.TEMPERATURE_HOUR_COLDEST = 5
UniversalProcessKitEnvironment.TEMPERATURE_HOUR_HOTTEST = 17

function UniversalProcessKitEnvironment:minuteChanged()
	printFn('UniversalProcessKitEnvironment:minuteChanged()')
	UniversalProcessKitEnvironment.setSunAndRain()
end

function UniversalProcessKitEnvironment:hourChanged()
	printFn('UniversalProcessKitEnvironment:hourChanged()')
	UniversalProcessKitEnvironment.setTemperature()
end

function UniversalProcessKitEnvironment:setWeekday()
	printFn('UniversalProcessKitEnvironment:setWeekday()')
	UniversalProcessKitEnvironment.weekday=(g_currentMission.environment.currentDay-1)%7 -- 0-6
	--printInfo('currentDay= ',g_currentMission.environment.currentDay,' day=',day,' weekday=',UniversalProcessKitEnvironment.weekday)
end

function UniversalProcessKitEnvironment:setSunAndRain()
	printFn('UniversalProcessKitEnvironment:setSun()')
	
	local rain = UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_RAIN]
	local sun = UniversalProcessKitEnvironment.flbs[UniversalProcessKit.FILLTYPE_SUN]
	-- rain
	local blendFactor = 1 -- 1 to 0.55
	if g_currentMission.environment.currentRain~=nil then
		local rainTime = (g_currentMission.environment.currentDay - g_currentMission.environment.currentRain.startDay) * g_currentMission.environment.dayLength +
			(g_currentMission.environment.dayTime - g_currentMission.environment.currentRain.startDayTime)
		if rainTime < g_currentMission.environment.currentRain.duration then
			if rainTime > g_currentMission.environment.currentRain.duration - g_currentMission.environment.rainFadeDuration then
				blendFactor, _, _, _ = g_currentMission.environment.rainFadeCurve:get((g_currentMission.environment.currentRain.duration - rainTime) / 60000)
			else
				blendFactor, _, _, _ = g_currentMission.environment.rainFadeCurve:get(rainTime / 60000)
			end
			printInfo('blendFactor = ',blendFactor)
			if blendFactor<=0.55 then
				local rainType=g_currentMission.environment.currentRain.rainTypeId
				if rainType==Environment.RAINTYPE_RAIN then
					rain.fillLevel = UniversalProcessKitEnvironment.RAINPOWER_RAIN
				elseif rainType==Environment.RAINTYPE_HAIL then
					rain.fillLevel = UniversalProcessKitEnvironment.RAINPOWER_HAIL
				elseif rainType==Environment.RAINTYPE_FOG then
					rain.fillLevel = UniversalProcessKitEnvironment.RAINPOWER_FOG
				elseif rainType==Environment.RAINTYPE_CLOUDY then
					rain.fillLevel = UniversalProcessKitEnvironment.RAINPOWER_CLOUDY
				end
			else
				rain.fillLevel=0
			end
			--printInfo('rainIntensity = ',rainIntensity)
		end
	else
		rain.fillLevel=0
	end
	
	printAll('rain.fillLevel = ',rain.fillLevel)
	
	-- sun
	
	-- plain 100
	-- cloudy 80
	-- fog 70
	-- rain 65
	-- hail 50
	-- night + plain 20
	-- night + rain 10
	if g_currentMission.environment.isSunOn then
		local base = UniversalProcessKitEnvironment.SUNPOWER_DAY
		local dayMinutes = g_currentMission.environment.dayTime/60000
		local nightStart = g_currentMission.environment.nightStart
		local nightEnd = g_currentMission.environment.nightEnd
		local sunriseTime=60
		local sunsetTime=180
		if g_currentMission.environment.currentRain~=nil then
			local factor = (1-blendFactor)/0.45
			local rainFactor = 0
			if rainType==Environment.RAINTYPE_RAIN then
				rainFactor = 35*factor
			elseif rainType==Environment.RAINTYPE_HAIL then
				rainFactor = 50*factor
			elseif Environment.RAINTYPE_FOG then
				rainFactor = 30*factor
			elseif Environment.RAINTYPE_CLOUDY then
				rainFactor = 20*factor
			end
			
			if dayMinutes>(nightStart-sunsetTime) and dayMinutes<nightStart then
				base=UniversalProcessKitEnvironment.SUNPOWER_NIGHTRAIN+(UniversalProcessKitEnvironment.SUNPOWER_DAY-UniversalProcessKitEnvironment.SUNPOWER_NIGHTRAIN)*(nightStart-dayMinutes)/sunsetTime
			elseif dayMinutes>nightEnd and dayMinutes<(nightEnd+sunriseTime) then
				base=UniversalProcessKitEnvironment.SUNPOWER_NIGHTRAIN+(UniversalProcessKitEnvironment.SUNPOWER_DAY-UniversalProcessKitEnvironment.SUNPOWER_NIGHTRAIN)*(dayMinutes-nightEnd)/sunriseTime
			end
			sun.fillLevel = base-rainFactor
		else
			if dayMinutes>(nightStart-sunsetTime) and dayMinutes<nightStart then
				base=UniversalProcessKitEnvironment.SUNPOWER_NIGHT+(UniversalProcessKitEnvironment.SUNPOWER_DAY-UniversalProcessKitEnvironment.SUNPOWER_NIGHT)*(nightStart-dayMinutes)/sunsetTime
			elseif dayMinutes>nightEnd and dayMinutes<(nightEnd+sunriseTime) then
				base=UniversalProcessKitEnvironment.SUNPOWER_NIGHT+(UniversalProcessKitEnvironment.SUNPOWER_DAY-UniversalProcessKitEnvironment.SUNPOWER_NIGHT)*(dayMinutes-nightEnd)/sunriseTime
			end
			sun.fillLevel = base
		end
	else
		if g_currentMission.environment.currentRain~=nil then
			sun.fillLevel = UniversalProcessKitEnvironment.SUNPOWER_NIGHTRAIN
		else
			sun.fillLevel = UniversalProcessKitEnvironment.SUNPOWER_NIGHT
		end
	end

	printAll('sun.fillLevel = ',sun.fillLevel)
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

