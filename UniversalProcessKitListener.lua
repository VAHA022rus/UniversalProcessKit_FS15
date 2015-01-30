-- by mor2000

UniversalProcessKitListener = {}
UniversalProcessKitListener.updateables = {}
UniversalProcessKitListener.updateablesDay = {}
UniversalProcessKitListener.updateablesHour = {}
UniversalProcessKitListener.updateablesMinute = {}
UniversalProcessKitListener.updateablesSecond = {}
UniversalProcessKitListener.dtsum = 0
UniversalProcessKitListener.postLoadObjects = {}

print('UniversalProcessKitListener.postLoadObjects is '..tostring(UniversalProcessKitListener.postLoadObjects))



function UniversalProcessKitListener.loadMap(name)
	--cleanup at map loaded
	--[[
	for filltypeName,fillType in pairs(Fillable.fillTypeNameToInt) do
		--UniversalProcessKit.fillTypeNameToInt[k]=v
		UniversalProcessKit.fillTypeIntToName[fillType]=filltypeName
	end
	
	for k,v in pairs(UniversalProcessKit.fillTypeNameToInt) do
		local fillabletype=Fillable.fillTypeNameToInt[k]
		if fillabletype~=nil then
			UniversalProcessKit.fillTypeNameToInt[k]=nil
			--UniversalProcessKit.fillTypeIntToName[v]=nil
		end
	end
	]]--
	
	if g_server ~= nil then
		UniversalProcessKitListener.fillTypesSyncingObject = UPK_FillTypesSyncingObject:new(g_server ~= nil, g_client ~= nil)
		g_server:addObject(UniversalProcessKitListener.fillTypesSyncingObject, UniversalProcessKitListener.fillTypesSyncingObject.id)
		--self.syncTipTriggerObject:load(self)
		UniversalProcessKitListener.fillTypesSyncingObject:register(false)
	end
	
	UniversalProcessKitEnvironment.setSun()
	UniversalProcessKitEnvironment.setRain()
	UniversalProcessKitEnvironment.setTemperature()

	UniversalProcessKitListener.addMinuteChangeListener(UniversalProcessKitEnvironment)
	UniversalProcessKitListener.addHourChangeListener(UniversalProcessKitEnvironment)
	
	g_currentMission.environment:addDayChangeListener(UniversalProcessKitListener)
	g_currentMission.environment:addHourChangeListener(UniversalProcessKitListener)
	g_currentMission.environment:addMinuteChangeListener(UniversalProcessKitListener)

	

end

function UniversalProcessKitListener.deleteMap(name)
	UniversalProcessKitListener.removeMinuteChangeListener(UniversalProcessKitEnvironment)
	UniversalProcessKitListener.removeHourChangeListener(UniversalProcessKitEnvironment)
	
	if g_currentMission.environment~=nil then
		g_currentMission.environment:removeDayChangeListener(UniversalProcessKitListener)
		g_currentMission.environment:removeHourChangeListener(UniversalProcessKitListener)
		g_currentMission.environment:removeMinuteChangeListener(UniversalProcessKitListener)	
	end
end

function UniversalProcessKitListener.addUpdateable(obj)
	UniversalProcessKitListener.updateables[obj]=true
end

function UniversalProcessKitListener.removeUpdateable(obj)
	UniversalProcessKitListener.updateables[obj]=nil
end

function UniversalProcessKitListener:update(dt)
	UniversalProcessKitListener.dtsum = UniversalProcessKitListener.dtsum+dt
	if UniversalProcessKitListener.dtsum >= 1000 then
		UniversalProcessKitListener.dtsum = UniversalProcessKitListener.dtsum-1000
		UniversalProcessKitListener.secondChanged()
	end
	
	-- running post load
	
	for i=1,#UniversalProcessKitListener.postLoadObjects do
		if type(UniversalProcessKitListener.postLoadObjects[i])=="table" and UniversalProcessKitListener.postLoadObjects[i].postLoad~=nil then
			UniversalProcessKitListener.postLoadObjects[i]:postLoad()
		end
		table.remove(UniversalProcessKitListener.postLoadObjects,i)
	end
	
	-- running updates
	
	for obj,v in pairs(UniversalProcessKitListener.updateables) do
		if v then
			obj:update(dt)
		end
	end
end

-- day

function UniversalProcessKitListener.addDayChangeListener(obj)
	UniversalProcessKitListener.updateablesDay[obj]=true
end

function UniversalProcessKitListener.removeDayChangeListener(obj)
	UniversalProcessKitListener.updateablesDay[obj]=nil
end

function UniversalProcessKitListener:dayChanged()
	for obj,v in pairs(UniversalProcessKitListener.updateablesDay) do
		if v then
			obj:dayChanged(dt)
		end
	end
end

-- hour

function UniversalProcessKitListener.addHourChangeListener(obj)
	UniversalProcessKitListener.updateablesHour[obj]=true
end

function UniversalProcessKitListener.removeHourChangeListener(obj)
	UniversalProcessKitListener.updateablesHour[obj]=nil
end

function UniversalProcessKitListener:hourChanged()
	for obj,v in pairs(UniversalProcessKitListener.updateablesHour) do
		if v then
			obj:hourChanged(dt)
		end
	end
end

-- minute

function UniversalProcessKitListener.addMinuteChangeListener(obj)
	UniversalProcessKitListener.updateablesMinute[obj]=true
end

function UniversalProcessKitListener.removeMinuteChangeListener(obj)
	UniversalProcessKitListener.updateablesMinute[obj]=nil
end

function UniversalProcessKitListener:minuteChanged()
	for obj,v in pairs(UniversalProcessKitListener.updateablesMinute) do
		if v then
			obj:minuteChanged(dt)
		end
	end
end

-- second

function UniversalProcessKitListener.addSecondChangeListener(obj)
	UniversalProcessKitListener.updateablesSecond[obj]=true
end

function UniversalProcessKitListener.removeSecondChangeListener(obj)
	UniversalProcessKitListener.updateablesSecond[obj]=nil
end

function UniversalProcessKitListener.secondChanged()
	for obj,v in pairs(UniversalProcessKitListener.updateablesSecond) do
		if v then
			obj:secondChanged(dt)
		end
	end
end

-- post load

function UniversalProcessKitListener.registerPostLoadObject(obj)
	print('UniversalProcessKitListener.postLoadObjects is '..tostring(UniversalProcessKitListener.postLoadObjects))
	table.insert(UniversalProcessKitListener.postLoadObjects,obj)
end

local function emptyFunc() end
UniversalProcessKitListener.mouseEvent=emptyFunc
UniversalProcessKitListener.keyEvent=emptyFunc
UniversalProcessKitListener.draw=emptyFunc

addModEventListener(UniversalProcessKitListener)