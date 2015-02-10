-- by mor2000

UniversalProcessKitListener = {}
UniversalProcessKitListener.updateables = {}
UniversalProcessKitListener.updateablesDay = {}
UniversalProcessKitListener.updateablesHour = {}
UniversalProcessKitListener.updateablesMinute = {}
UniversalProcessKitListener.updateablesSecond = {}
UniversalProcessKitListener.updateablesOrder = {}
UniversalProcessKitListener.updateablesDayOrder = {}
UniversalProcessKitListener.updateablesHourOrder = {}
UniversalProcessKitListener.updateablesMinuteOrder = {}
UniversalProcessKitListener.updateablesSecondOrder = {}
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
	if not UniversalProcessKitListener.updateables[obj] then
		table.insert(UniversalProcessKitListener.updateablesOrder,obj)
		UniversalProcessKitListener.updateables[obj]=true
	end
end

function UniversalProcessKitListener.removeUpdateable(obj)
	if UniversalProcessKitListener.updateables[obj] then
		removeValueFromTable(UniversalProcessKitListener.updateablesOrder,obj)
		UniversalProcessKitListener.updateables[obj]=nil
	end
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
	
	for i=1,#UniversalProcessKitListener.updateablesOrder do
		local obj=UniversalProcessKitListener.updateablesOrder[i]
		if UniversalProcessKitListener.updateables[obj] then
			obj:update(dt)
		end
	end
end

-- day

function UniversalProcessKitListener.addDayChangeListener(obj)
	if not UniversalProcessKitListener.updateablesDay[obj] then
		table.insert(UniversalProcessKitListener.updateablesDayOrder,obj)
		UniversalProcessKitListener.updateablesDay[obj]=true
	end
end

function UniversalProcessKitListener.removeDayChangeListener(obj)
	if UniversalProcessKitListener.updateablesDay[obj] then
		removeValueFromTable(UniversalProcessKitListener.updateablesDayOrder,obj)
		UniversalProcessKitListener.updateablesDay[obj]=nil
	end
end

function UniversalProcessKitListener:dayChanged()
	for i=1,#UniversalProcessKitListener.updateablesDayOrder do
		local obj=UniversalProcessKitListener.updateablesDayOrder[i]
		if UniversalProcessKitListener.updateablesDay[obj] then
			obj:dayChanged()
		end
	end
end

-- hour

function UniversalProcessKitListener.addHourChangeListener(obj)
	if not UniversalProcessKitListener.updateablesHour[obj] then
		table.insert(UniversalProcessKitListener.updateablesHourOrder,obj)
		UniversalProcessKitListener.updateablesHour[obj]=true
	end
end

function UniversalProcessKitListener.removeHourChangeListener(obj)
	if UniversalProcessKitListener.updateablesHour[obj] then
		removeValueFromTable(UniversalProcessKitListener.updateablesHourOrder,obj)
		UniversalProcessKitListener.updateablesHour[obj]=nil
	end
end

function UniversalProcessKitListener:hourChanged()
	for i=1,#UniversalProcessKitListener.updateablesHourOrder do
		local obj=UniversalProcessKitListener.updateablesHourOrder[i]
		if UniversalProcessKitListener.updateablesHour[obj] then
			obj:hourChanged()
		end
	end
end

-- minute

function UniversalProcessKitListener.addMinuteChangeListener(obj)
	if not UniversalProcessKitListener.updateablesMinute[obj] then
		table.insert(UniversalProcessKitListener.updateablesMinuteOrder,obj)
		UniversalProcessKitListener.updateablesMinute[obj]=true
	end
end

function UniversalProcessKitListener.removeMinuteChangeListener(obj)
	if UniversalProcessKitListener.updateablesMinute[obj] then
		removeValueFromTable(UniversalProcessKitListener.updateablesMinuteOrder,obj)
		UniversalProcessKitListener.updateablesMinute[obj]=nil
	end
end

function UniversalProcessKitListener:minuteChanged()
	for i=1,#UniversalProcessKitListener.updateablesMinuteOrder do
		local obj=UniversalProcessKitListener.updateablesMinuteOrder[i]
		if UniversalProcessKitListener.updateablesMinute[obj] then
			obj:minuteChanged()
		end
	end
end

-- second

function UniversalProcessKitListener.addSecondChangeListener(obj)
	if not UniversalProcessKitListener.updateablesSecond[obj] then
		table.insert(UniversalProcessKitListener.updateablesSecondOrder,obj)
		UniversalProcessKitListener.updateablesSecond[obj]=true
	end
end

function UniversalProcessKitListener.removeSecondChangeListener(obj)
	if UniversalProcessKitListener.updateablesSecond[obj] then
		removeValueFromTable(UniversalProcessKitListener.updateablesSecondOrder,obj)
		UniversalProcessKitListener.updateablesSecond[obj]=nil
	end
end

function UniversalProcessKitListener.secondChanged()
	for i=1,#UniversalProcessKitListener.updateablesSecondOrder do
		local obj=UniversalProcessKitListener.updateablesSecondOrder[i]
		if UniversalProcessKitListener.updateablesSecond[obj] then
			obj:secondChanged()
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