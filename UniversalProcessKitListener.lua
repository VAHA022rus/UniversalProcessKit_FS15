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

function UniversalProcessKitListener.loadMap(name)
	printFn('UniversalProcessKitListener.loadMap('..tostring(name)..')')
	
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
	
	
	-- new store categories
	
	local maxStoreCategoryOrderId=0
	for _, category in pairs(StoreItemsUtil.storeCategories) do
		if category.orderId ~= nil and category.orderId > maxStoreCategoryOrderId then
			maxStoreCategoryOrderId = category.orderId
		end
	end
	
	local storePicturesPath = upkModDirectory .. 'storePictures/'
	
	--print('storePicturesPath = '..tostring(storePicturesPath))
	
	local storageCategoryFruit = {}
	storageCategoryFruit['image'] = storePicturesPath .. 'store.dds'
	storageCategoryFruit['title'] = g_i18n:getText('storeCategory_fruit')
	storageCategoryFruit['name'] = 'upk_fruit'
	storageCategoryFruit['orderId'] = maxStoreCategoryOrderId + 1
	
	local storageCategoryAnimals = {}
	storageCategoryAnimals['image'] = storePicturesPath .. 'store.dds'
	storageCategoryAnimals['title'] = g_i18n:getText('storeCategory_animals')
	storageCategoryAnimals['name'] = 'upk_animals'
	storageCategoryAnimals['orderId'] = maxStoreCategoryOrderId + 2
	
	local storageCategoryStorage = {}
	storageCategoryStorage['image'] = storePicturesPath .. 'store.dds'
	storageCategoryStorage['title'] = g_i18n:getText('storeCategory_storage')
	storageCategoryStorage['name'] = 'upk_storage'
	storageCategoryStorage['orderId'] = maxStoreCategoryOrderId + 3
	
	local storageCategoryBuildings = {}
	storageCategoryBuildings['image'] = storePicturesPath .. 'store.dds'
	storageCategoryBuildings['title'] = g_i18n:getText('storeCategory_buildings')
	storageCategoryBuildings['name'] = 'upk_buildings'
	storageCategoryBuildings['orderId'] = maxStoreCategoryOrderId + 4
	
	local storageCategorySellingPoints = {}
	storageCategorySellingPoints['image'] = storePicturesPath .. 'store.dds'
	storageCategorySellingPoints['title'] = g_i18n:getText('storeCategory_sellingPoints')
	storageCategorySellingPoints['name'] = 'upk_sellingPoints'
	storageCategorySellingPoints['orderId'] = maxStoreCategoryOrderId + 5
	
	local storageCategoryFactories = {}
	storageCategoryFactories['image'] = storePicturesPath .. 'store.dds'
	storageCategoryFactories['title'] = g_i18n:getText('storeCategory_factories')
	storageCategoryFactories['name'] = 'upk_factories'
	storageCategoryFactories['orderId'] = maxStoreCategoryOrderId + 6
	
	local storageCategoryExamples = {}
	storageCategoryExamples['image'] = storePicturesPath .. 'store.dds'
	storageCategoryExamples['title'] = g_i18n:getText('storeCategory_examples')
	storageCategoryExamples['name'] = 'upk_examples'
	storageCategoryExamples['orderId'] = maxStoreCategoryOrderId + 7
	
	StoreItemsUtil.storeCategories["upk_fruit"] = storageCategoryFruit
	StoreItemsUtil.storeCategories["upk_animals"] = storageCategoryAnimals
	StoreItemsUtil.storeCategories["upk_storage"] = storageCategoryStorage
	StoreItemsUtil.storeCategories["upk_buildings"] = storageCategoryBuildings
	StoreItemsUtil.storeCategories["upk_sellingPoints"] = storageCategorySellingPoints
	StoreItemsUtil.storeCategories["upk_factories"] = storageCategoryFactories
	StoreItemsUtil.storeCategories["upk_examples"] = storageCategoryExamples
	
	
	
	
	
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
	printFn('UniversalProcessKitListener.deleteMap('..tostring(name)..')')
	
	UniversalProcessKitListener.removeMinuteChangeListener(UniversalProcessKitEnvironment)
	UniversalProcessKitListener.removeHourChangeListener(UniversalProcessKitEnvironment)
	
	if g_currentMission.environment~=nil then
		g_currentMission.environment:removeDayChangeListener(UniversalProcessKitListener)
		g_currentMission.environment:removeHourChangeListener(UniversalProcessKitListener)
		g_currentMission.environment:removeMinuteChangeListener(UniversalProcessKitListener)	
	end
end

function UniversalProcessKitListener.addUpdateable(obj)
	printFn('UniversalProcessKitListener.addUpdateable('..tostring(obj)..')')
	if not UniversalProcessKitListener.updateables[obj] then
		table.insert(UniversalProcessKitListener.updateablesOrder,obj)
		UniversalProcessKitListener.updateables[obj]=true
	end
end

function UniversalProcessKitListener.removeUpdateable(obj)
	printFn('UniversalProcessKitListener.removeUpdateable('..tostring(obj)..')')
	if UniversalProcessKitListener.updateables[obj] then
		removeValueFromTable(UniversalProcessKitListener.updateablesOrder,obj)
		UniversalProcessKitListener.updateables[obj]=nil
	end
end

function UniversalProcessKitListener:update(dt)
	printAll('UniversalProcessKitListener:update('..tostring(dt)..')')
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
	printFn('UniversalProcessKitListener.addDayChangeListener('..tostring(obj)..')')
	if not UniversalProcessKitListener.updateablesDay[obj] then
		table.insert(UniversalProcessKitListener.updateablesDayOrder,obj)
		UniversalProcessKitListener.updateablesDay[obj]=true
	end
end

function UniversalProcessKitListener.removeDayChangeListener(obj)
	printFn('UniversalProcessKitListener.removeDayChangeListener('..tostring(obj)..')')
	if UniversalProcessKitListener.updateablesDay[obj] then
		removeValueFromTable(UniversalProcessKitListener.updateablesDayOrder,obj)
		UniversalProcessKitListener.updateablesDay[obj]=nil
	end
end

function UniversalProcessKitListener:dayChanged()
	printFn('UniversalProcessKitListener:dayChanged()')
	for i=1,#UniversalProcessKitListener.updateablesDayOrder do
		local obj=UniversalProcessKitListener.updateablesDayOrder[i]
		if UniversalProcessKitListener.updateablesDay[obj] then
			obj:dayChanged()
		end
	end
end

-- hour

function UniversalProcessKitListener.addHourChangeListener(obj)
	printFn('UniversalProcessKitListener.addHourChangeListener('..tostring(obj)..')')
	if not UniversalProcessKitListener.updateablesHour[obj] then
		table.insert(UniversalProcessKitListener.updateablesHourOrder,obj)
		UniversalProcessKitListener.updateablesHour[obj]=true
	end
end

function UniversalProcessKitListener.removeHourChangeListener(obj)
	printFn('UniversalProcessKitListener.removeHourChangeListener('..tostring(obj)..')')
	if UniversalProcessKitListener.updateablesHour[obj] then
		removeValueFromTable(UniversalProcessKitListener.updateablesHourOrder,obj)
		UniversalProcessKitListener.updateablesHour[obj]=nil
	end
end

function UniversalProcessKitListener:hourChanged()
	printFn('UniversalProcessKitListener:hourChanged()')
	for i=1,#UniversalProcessKitListener.updateablesHourOrder do
		local obj=UniversalProcessKitListener.updateablesHourOrder[i]
		if UniversalProcessKitListener.updateablesHour[obj] then
			obj:hourChanged()
		end
	end
end

-- minute

function UniversalProcessKitListener.addMinuteChangeListener(obj)
	printFn('UniversalProcessKitListener.addMinuteChangeListener('..tostring(obj)..')')
	if not UniversalProcessKitListener.updateablesMinute[obj] then
		table.insert(UniversalProcessKitListener.updateablesMinuteOrder,obj)
		UniversalProcessKitListener.updateablesMinute[obj]=true
	end
end

function UniversalProcessKitListener.removeMinuteChangeListener(obj)
	printFn('UniversalProcessKitListener.removeMinuteChangeListener('..tostring(obj)..')')
	if UniversalProcessKitListener.updateablesMinute[obj] then
		removeValueFromTable(UniversalProcessKitListener.updateablesMinuteOrder,obj)
		UniversalProcessKitListener.updateablesMinute[obj]=nil
	end
end

function UniversalProcessKitListener:minuteChanged()
	printFn('UniversalProcessKitListener:minuteChanged()')
	for i=1,#UniversalProcessKitListener.updateablesMinuteOrder do
		local obj=UniversalProcessKitListener.updateablesMinuteOrder[i]
		if UniversalProcessKitListener.updateablesMinute[obj] then
			obj:minuteChanged()
		end
	end
end

-- second

function UniversalProcessKitListener.addSecondChangeListener(obj)
	printFn('UniversalProcessKitListener.addSecondChangeListener('..tostring(obj)..')')
	if not UniversalProcessKitListener.updateablesSecond[obj] then
		table.insert(UniversalProcessKitListener.updateablesSecondOrder,obj)
		UniversalProcessKitListener.updateablesSecond[obj]=true
	end
end

function UniversalProcessKitListener.removeSecondChangeListener(obj)
	printFn('UniversalProcessKitListener.removeSecondChangeListener('..tostring(obj)..')')
	if UniversalProcessKitListener.updateablesSecond[obj] then
		removeValueFromTable(UniversalProcessKitListener.updateablesSecondOrder,obj)
		UniversalProcessKitListener.updateablesSecond[obj]=nil
	end
end

function UniversalProcessKitListener.secondChanged()
	printFn('UniversalProcessKitListener:secondChanged()')
	for i=1,#UniversalProcessKitListener.updateablesSecondOrder do
		local obj=UniversalProcessKitListener.updateablesSecondOrder[i]
		if UniversalProcessKitListener.updateablesSecond[obj] then
			obj:secondChanged()
		end
	end
end

-- post load

function UniversalProcessKitListener.registerPostLoadObject(obj)
	printFn('UniversalProcessKitListener.registerPostLoadObject('..tostring(obj)..')')
	table.insert(UniversalProcessKitListener.postLoadObjects,obj)
end

function UniversalProcessKitListener.keyEvent(self,unicode,sym,modifier,isDown)
	printAll('UniversalProcessKitListener.keyEvent('..tostring(unicode)..','..tostring(sym)..','..tostring(modifier)..','..tostring(isDown)..')')
	-- player spawner

	if InputBinding.isPressed(InputBinding.UPK_PLAYERTELEPORT) then
		printAll("Teleport pressed")
		UPK_PlayerSpawner.togglePlayerSpawner(1)
	elseif InputBinding.isPressed(InputBinding.UPK_PLAYERTELEPORT_BACK) then
		printAll("Teleport back pressed")
		UPK_PlayerSpawner.togglePlayerSpawner(-1)
	end
end

UniversalProcessKitListener.mouseEvent=emptyFunc
UniversalProcessKitListener.draw=emptyFunc

addModEventListener(UniversalProcessKitListener)