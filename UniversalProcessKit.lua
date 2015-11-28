-- by mor2000

local UniversalProcessKit_mt = ClassUPK(UniversalProcessKit);
InitObjectClass(UniversalProcessKit, "UniversalProcessKit");

function UniversalProcessKit:onCreate(id)
	printFn('UniversalProcessKit:onCreate(',id,')')
	
	local upkbase = OnCreateUPK:new(g_server ~= nil, g_client ~= nil)
	if upkbase==false or upkbase~=nil then
		upkbase:load(id)
		g_currentMission:addOnCreateLoadedObject(upkbase)
		upkbase:register(true)
	else
		upkbase:detele()
	end
end;

function UniversalProcessKit:new(nodeId, parent, customMt)
	printFn('UniversalProcessKit:new(',nodeId,', ',parent,', ',customMt,')')
	
	if nodeId==nil then
		printErr('Error: UniversalProcessKit:new() called with id=nil')
		return false
	end

	--local self = Object:new(g_server ~= nil, g_client ~= nil, customMt or UniversalProcessKit_mt) -- base needs to be object
	--registerObjectClassName(self, "UniversalProcessKit")
	
	local self={}
	
	self.isServer = g_server ~= nil
	self.isClient = g_client ~= nil

	self.rootNode = nodeId
	self.nodeId = nodeId
	self.triggerId = 0
	
	self.parent = parent
	if self.parent == nil then
		self.base = self
	else
		self.base = self.parent.base
	end
	self.kids={}
	self.type=nil

	self.onCreates = {}
	self.onFillLevelChangeFuncs = {}
	
	self.x,self.y,self.z = getTranslation(nodeId)
	self.pos = __c({self.x,self.y,self.z})
	self.wpos = __c({getWorldTranslation(nodeId)})
	self.rot = __c({getRotation(nodeId)})
	self.wrot = __c({getWorldRotation(nodeId)})
	self.scale = __c({getScale(nodeId)})
	
	-- misc
	
	self.name = string.gsub(getName(self.nodeId), "%W", "_")
	self.type = getStringFromUserAttribute(nodeId, "type")
	self.isEnabled = getBoolFromUserAttribute(nodeId, "isEnabled", true)

	-- i18nNameSpace
	
	if self.parent~=nil then
		self.i18nNameSpace = self.parent.i18nNameSpace
		self.i18n = self.parent.i18n
	else
		self.i18n = {}
		self.type = "base"
	end
	
	-- fill types conversion matrix
	
	self.fillTypesConversionMatrix = FillTypesConversionMatrix:new()
	
	-- storageType
	
	self.storageType = UPK_Storage.SEPARATE
	
	local storeArr = getArrayFromUserAttribute(self.nodeId, "store")
	
	if #storeArr==1 then
		if storeArr[1]=="single" then
			self.storageType = UPK_Storage.SINGLE
		elseif storeArr[1]=="fifo" then
			self.storageType = UPK_Storage.FIFO
		elseif storeArr[1]=="filo" then
			self.storageType = UPK_Storage.FILO
		end
	end

	-- capacity/ capacities

	self.p_capacity = getNumberFromUserAttribute(nodeId, "capacity", math.huge)

	local capacities = {}
	if self.storageType==UPK_Storage.SEPARATE or self.storageType==UPK_Storage.SINGLE then
		local capacitiesArr = getArrayFromUserAttribute(nodeId, "capacities")
		for i=1,#capacitiesArr,2 do
			local capacity=tonumber(capacitiesArr[i])
			local fillType=unpack(UniversalProcessKit.fillTypeNameToInt(capacitiesArr[i+1]))
			if capacity~=nil and fillType~=nil then
				printInfo('adding capacity of ',capacity,' to ',fillType)
				capacities[fillType]=capacity
			end
		end
	end

	self.capacities = FillLevelBubbleCapacities:new(self.p_capacity, capacities)

	for k,v in pairs(self.capacities) do
		printAll('capacity of ',k,': ',v)
	end

	-- set metatable

	setmetatable(self, customMt or UniversalProcessKit_mt)

	-- network
	
	self.fillLevelsToSync = {}
	self.nextDirtyFlag = 1
	self.dirtyMask = 0
	self.syncAllDirtyFlag = self:getNextDirtyFlag()
	self.fillLevelDirtyFlag = self:getNextDirtyFlag()
	self.isEnabledDirtyFlag = self:getNextDirtyFlag()
	self.mapHotspotDirtyFlag = self:getNextDirtyFlag()
	
	-- fill level bubbles

	self.p_flbs = {}
	--setmetatable(self.p_flbs,p_flbs_mt)

	if self.storageType == UPK_Storage.SEPARATE then
		for _,v in pairs(UniversalProcessKit.fillTypeNameToInt(storeArr)) do
			self.p_flbs[v] = FillLevelBubble:new()
			self.fillTypesConversionMatrix = self.fillTypesConversionMatrix + FillTypesConversionMatrix:new(v)
		end
	elseif self.storageType==UPK_Storage.SINGLE then
		local flb = FillLevelBubble:new()
		self.p_flbs = {flb}
	elseif self.storageType==UPK_Storage.FIFO then
		local flb = FillLevelBubble:new()
		self.p_flbs = {flb}
		self.p_flbs_fifo_lastkey = 1
		self.p_totalFillLevel = 0
	elseif self.storageType==UPK_Storage.FILO then
		local flb = FillLevelBubble:new()
		self.p_flbs = {flb}
		self.p_totalFillLevel = 0
	end

	

	-- fill types conversion matrix

	local fillTypesConversionMatrixStrStr = getStringFromUserAttribute(nodeId, "convertFillTypes", "")
	self:printInfo('fillTypesConversionMatrixStrStr: ',fillTypesConversionMatrixStrStr)
	local fillTypesConversionMatrixStrArr = gmatch(fillTypesConversionMatrixStrStr..',','(.-),')
	for _,fillTypesConversionMatrixStr in pairs(fillTypesConversionMatrixStrArr) do
		if fillTypesConversionMatrixStr~=nil and fillTypesConversionMatrixStr~="" then
			self:printAll('dealing with ',fillTypesConversionMatrixStr)
			self.fillTypesConversionMatrix = self.fillTypesConversionMatrix + FillTypesConversionMatrix:new(UniversalProcessKit.fillTypeNameToInt(gmatch(fillTypesConversionMatrixStr,'%S+')))
		end
	end

	printAll('self.fillTypesConversionMatrix is '..tostring(self.fillTypesConversionMatrix))
	
	for k,v in pairs(self.fillTypesConversionMatrix) do
		for l,w in pairs(v) do
			printInfo('adding ',l,' (incoming) to ',k,' (stored) ends up as ',w)
		end
	end
	
	if self.storageType==UPK_Storage.SINGLE or self.storageType==UPK_Storage.FIFO or self.storageType==UPK_Storage.FILO then
		local convertFromUnknown_mt = {
			__index = function(t,k)
				rawset(t,k,k)
				return k
			end
		}
		local convertFromUnknown={}
		setmetatable(convertFromUnknown, convertFromUnknown_mt)
		self.fillTypesConversionMatrix[UniversalProcessKit.FILLTYPE_UNKNOWN] = convertFromUnknown
	end
	
	for _,flb in pairs(self.p_flbs) do
		flb.capacities = self.capacities
		for k,v in pairs(flb.capacities) do
			printInfo('capacity of ',k,': ',v)
		end
		flb.fillTypesConversionMatrix = self.fillTypesConversionMatrix
		flb:registerOnFillLevelChangeFunc(self,"p_onFillLevelChange")
	end
	
	-- addNodeObject
	--[[
	if self.addNodeObject and getRigidBodyType(nodeId) ~= "NoRigidBody" then
		g_currentMission:addNodeObject(nodeId, self)
	end
	--]]
	
	-- MapHotspot -- nothing done yet
	
	self.showMapHotSpotIfDisabled = getBoolFromUserAttribute(nodeId, "showMapHotSpotIfDisabled", true)
	--self.blinkingMapHotspot = getBoolFromUserAttribute(nodeId, "blinkingMapHotspot", false)
	
	self.MapHotspotName = getStringFromUserAttribute(nodeId, "MapHotspot")
	local mapHotspotIcons={
		Bank="$dataS2/menu/hud/hud_pda_spot_bank.png",
		FuelStation="$dataS2/menu/hud/hud_pda_spot_fuelStation.png",
		Shop="$dataS2/menu/hud/hud_pda_spot_shop.png",
		Phone="$dataS2/menu/hud/hud_pda_spot_phone.png",
		Eggs="$dataS/menu/hud/hud_pda_spot_eggs.png",
		TipPlace="$dataS2/menu/hud/hud_pda_spot_tipPlace.png",
		TipPlaceGold="$dataS2/menu/hud/hud_pda_spot_tipPlaceGold.png",
		Cows="$dataS2/menu/hud/hud_pda_spot_cows.png",
		Sheep="$dataS2/menu/hud/hud_pda_spot_sheep.png",
		Chickens="$dataS2/menu/hud/hud_pda_spot_chickens.png",
		Billboard="$dataS2/menu/hud/hud_pda_spot_billboard.png"}
	
	if self.MapHotspotName~=nil and mapHotspotIcons[self.MapHotspotName]~=nil then
		self.MapHotspotIcon = Utils.getFilename(mapHotspotIcons[self.MapHotspotName], getAppBasePath())
	else
		local iconStr = getStringFromUserAttribute(nodeId, "MapHotspotIcon")
		if iconStr~=nil then
			if self.i18nNameSpace==nil then
				self:printInfo('you need to set the modName-UserAttribute to use MapHotspotIcon')
			else
				self.MapHotspotIcon = g_modNameToDirectory[self.i18nNameSpace]..iconStr
				self:printInfo('using \"'..tostring(self.MapHotspotIcon)..'\" as MapHotspotIcon')
			end
		else
			self.MapHotspotIcon = Utils.getFilename(mapHotspotIcons["TipPlace"], getAppBasePath())
		end
	end
	
	self.useMapHotspot = getUserAttribute(nodeId, "showMapHotspot") ~= nil
	
	self:showMapHotspot(getBoolFromUserAttribute(nodeId, "showMapHotspot", false), true)
	
	-- actions
	
	self.actions={}
	
	-- placeable object
	
	if self.type~="base" and self.parent~=nil then
		self.placeable = self.parent.placeable
		self.builtIn = self.parent.builtIn
		self.syncObj = self.parent.syncObj
		self.base = self.parent.base
		self.syncObj:registerObjectToSync(self) -- invokes to call read and writeStream
	end
	
	
	printAll('loaded module ',self.name,' with id ',nodeId)
	
	printAll('self.placeable ',self.placeable)
	printAll('getBoolFromUserAttribute(nodeId, "adjustToTerrainHeight", false) ',getBoolFromUserAttribute(nodeId, "adjustToTerrainHeight", false))
	
	if getBoolFromUserAttribute(nodeId, "adjustToTerrainHeight", false) and self.placeable then
		UniversalProcessKit.adjustToTerrainHeight(nodeId)
	end
	
	UniversalProcessKitListener.registerPostLoadObject(self)
	
	--g_currentMission:addNodeObject(self.nodeId, self)
	
	return self
end;

function UniversalProcessKit:findChildrenLoopFunc(childId,prefixShapeNames)
	self:printFn('UniversalProcessKit:findChildrenLoopFunc(',childId,')')	
	
	-- rename shapes
	if prefixShapeNames==nil then
		prefixShapeNames=""
	end
	local addPrefixShapeNames=getStringFromUserAttribute(childId, "prefixShapeNames","")
	if addPrefixShapeNames~="" then	
		prefixShapeNames=addPrefixShapeNames..prefixShapeNames
	end
	if prefixShapeNames~="" then
		local shapeName=getName(childId)
		printInfo('shape "',shapeName,'" renamed to "',prefixShapeNames..shapeName,'"')
		setName(childId,prefixShapeNames..shapeName)
	end
	
	-- load external i3d
	local loadI3D=getStringFromUserAttribute(childId, "loadI3D")
	self:printAll('loadI3D = ',loadI3D)
	if loadI3D~=nil then
		
		local a,_=string.find(loadI3D,"^[$%w_%/\\%.0-9]+%.i3d$")
		if a==nil then
			printErr('invalid filename "',loadI3D,'"')
		else
			local filename = getLongFilename(loadI3D,self.base.i18nNameSpace)
			printInfo('filename is "'..tostring(filename)..'"')
			local newNode = loadI3DFile(filename)
			if newNode == 0 then
				printErr('couldnt load file "'..tostring(filename)..'"')
			else
				local nrOfChildren=getNumOfChildren(newNode)
				if nrOfChildren==0 then
					printInfo('no shapes loadable out of file "',filename,'"')
				end
				for i=0,getNumOfChildren(newNode)-1 do
					local linkShapeId = getChildAt(newNode, i)
					if linkShapeId~=nil and linkShapeId~=0 then
						link(childId, linkShapeId)
					end
				end
				delete(newNode)
			end
		end
	end
	
	local type = getStringFromUserAttribute(childId, "type")
	self:printInfo('UserAttribute type is '..tostring(type))
	if type~=nil and UniversalProcessKit.ModuleTypes[type]~=nil then
		childName=Utils.getNoNil(getName(childId),"")
		self:printInfo('found module ',childName,' of type ',type,' and id ',childId)
		local module=UniversalProcessKit.ModuleTypes[type]:new(childId,self)
		if module~=nil and module~=false then
			--if debugMode then -- not true/false anymore
			--	module=debugObject(module)
			--end
			table.insert(self.kids,module)
			self:printInfo('shape ',module.name,' is child of ',self.name)
			module:findChildren(childId,prefixShapeNames)
		else
			self:printErr('couldnt load module of type ',type,' and id ',childId)
			self:findChildren(childId,prefixShapeNames)
		end
	else
		if getBoolFromUserAttribute(childId, "adjustToTerrainHeight", false) and self.placeable then
			UniversalProcessKit.adjustToTerrainHeight(childId)
		end
		self:findChildren(childId,prefixShapeNames)
	end
	return true
end

function UniversalProcessKit:findChildren(id,prefixShapeNames)
	self:printFn('UniversalProcessKit:findChildren(',id,')')
	local name=getName(id)
	local a,b=string.find(name,"[%w_%.%/]+")
	if name=="" or a==nil or string.sub(name,a,b)~=name then
		self:printInfo('name of shape "',name,'" (nodeId "',id,'") is not valid')
	else
		if self.base.shapeNamesToNodeIds[name]~=nil then
			self:printInfo('name of shape "',name,'" already used')
		else
			self.base.shapeNamesToNodeIds[name]=id
			
			local audioSample=AudioSample.new(id,self.syncObj) -- test if node is an audio sample
			if audioSample~=false then
				self:printInfo('audio sample found')
				self.base.playableShapes[name]=audioSample
			end
			
			local animTrack=AnimationTrack.new(id,self.syncObj) -- test if node is an animation
			if animTrack~=false then
				self:printInfo('audio sample found')
				self.base.playableShapes[name]=animTrack
			end
		end
	end
	loopThruChildren(id,"findChildrenLoopFunc",self,prefixShapeNames)
end;

function UniversalProcessKit:findChildrenShapesLoopFunc(childId)
	self:printFn('UniversalProcessKit:findChildrenShapesLoopFunc(',childId,')')
	table.insert(self.childrenShapes,childId)
	self:findChildrenShapes(childId)
	return true
end;

function UniversalProcessKit:findChildrenShapes(id)
	self:printFn('UniversalProcessKit:findChildrenShapes(',id,')')
	loopThruChildren(id,"findChildrenShapesLoopFunc",self)
end;

function UniversalProcessKit:delete()
	printFn('delete module ',self.name,' with nodeid ',self.nodeId)

	self.isEnabled = false

	if self.triggerId~=nil then
		self:removeTrigger()
		-- clear player in trigger
	end
	
	for i=1,#self.kids do
		self.kids[i]:removeTrigger()
		self.kids[i]:delete()
	end
	
	self.kids={}
	
	UniversalProcessKitListener.removeUpdateable(self)
	UniversalProcessKitListener.removeDayChangeListener(self)
	UniversalProcessKitListener.removeHourChangeListener(self)
	UniversalProcessKitListener.removeMinuteChangeListener(self)
	UniversalProcessKitListener.removeSecondChangeListener(self)
	
	if self.registeredOnFillLevelChangeFuncs~=nil then
		for _,obj in pairs(self.registeredOnFillLevelChangeFuncs) do
			obj:unregisterOnFillLevelChangeFunc(self)
		end
	end

	if self.addNodeObject and self.nodeId ~= 0 then
		g_currentMission:removeNodeObject(self.nodeId)
	end
	
	unregisterObjectClassName(self)
end;

function UniversalProcessKit:update(dt)
	self:printFn('UniversalProcessKit:update(',dt,')')
	-- do sth with time (ms)
	-- requieres UniversalProcessKitListener.addUpdateable(self)
	-- and UniversalProcessKitListener.removeUpdateable(self)
end;

function UniversalProcessKit:registerOnFillLevelChangeFunc(obj,func)
	self:printFn('UniversalProcessKit:registerOnFillLevelChangeFunc(',obj,', ',func,')')
	if obj.registeredOnFillLevelChangeFuncs==nil then
		obj.registeredOnFillLevelChangeFuncs={}
	end
	if type(obj)=="table" and obj~=self and type(func)=="string" and type(obj[func])=="function" then
		--self:printInfo('registered object successfully')
		table.insert(obj.registeredOnFillLevelChangeFuncs,self)
		self.onFillLevelChangeFuncs[obj]=func
	end
end

function UniversalProcessKit:unregisterOnFillLevelChangeFunc(obj)
	self:printFn('UniversalProcessKit:unregisterOnFillLevelChangeFunc(',obj,')')
	if type(obj)=="table" then
		self.onFillLevelChangeFuncs[obj]=nil
	end
end

function UniversalProcessKit:p_onFillLevelChange(deltaFillLevel, newFillLevel, fillType) -- do sth with syncing
	self:printFn('UniversalProcessKit:p_onFillLevelChange(',deltaFillLevel,', ',newFillLevel,', ',fillType,')')
	
	if self.isServer then
		local hasFillTypeToSync = false
		for _,v in pairs(self.fillLevelsToSync) do
			if v.fillType==fillType then
				v.fillLevel=newFillLevel
				hasFillTypeToSync = true
				break
			end
		end
		if not hasFillTypeToSync then
			table.insert(self.fillLevelsToSync,{fillLevel=newFillLevel,fillType=fillType})
		end
		self:raiseDirtyFlags(self.fillLevelDirtyFlag)
	end
	
	for obj,func in pairs(self.onFillLevelChangeFuncs) do
		obj[func](obj, deltaFillLevel, newFillLevel, fillType)
	end
	self:onFillLevelChange(deltaFillLevel, newFillLevel, fillType)
end

function UniversalProcessKit:onFillLevelChange(deltaFillLevel, newFillLevel, fillType) -- to be overwritten
	self:printFn('UniversalProcessKit:onFillLevelChange(',deltaFillLevel,', ',newFillLevel,', ',fillType,')')
end

function UniversalProcessKit:getFillLevelBubbleShellFromFillType(fillType)
	self:printFn('UniversalProcessKit:getFillLevelBubbleShellFromFillType(',fillType,')')
	if self.storageType==UPK_Storage.SEPARATE and fillType~=nil then
		local newFillType=self.fillTypesConversionMatrix[Fillable.FILLTYPE_UNKNOWN][fillType] or fillType
		local flb=self.p_flbs[newFillType]
		if flb~=nil then
			return self
		else
			if self.parent~=nil then
				return self.parent:getFillLevelBubbleShellFromFillType(fillType)
			end
		end
	elseif self.storageType==UPK_Storage.SINGLE or self.storageType==UPK_Storage.FIFO or self.storageType==UPK_Storage.FILO then
		return self
	end 
	return nil
end

function UniversalProcessKit:getFillLevel(fillType)
	self:printFn('UniversalProcessKit:getFillLevel(',fillType,')')
	if fillType~=nil then
		if UniversalProcessKit.isSpecialFillType(fillType) then
			return UniversalProcessKitEnvironment.flbs[fillType].fillLevel
		end
		
		if self.storageType==UPK_Storage.SEPARATE then
			local newFillType=self.fillTypesConversionMatrix[Fillable.FILLTYPE_UNKNOWN][fillType] or fillType
			local flb=self.p_flbs[newFillType]
			if flb~=nil then
				return flb.fillLevel
			else
				if self.parent~=nil then
					return self.parent:getFillLevel(fillType)
				end
			end
		elseif self.storageType==UPK_Storage.SINGLE or self.storageType==UPK_Storage.FIFO or self.storageType==UPK_Storage.FILO then
			--self:print('self.p_flbs[1].fillType: '..tostring(self.p_flbs[1].fillType))
			if self.p_flbs[1].fillType==fillType then
				return self.p_flbs[1].fillLevel
			else
				return 0
			end
		end
	end
		
	return self.fillLevel
end

function UniversalProcessKit:getCapacity(fillType)
	self:printFn('UniversalProcessKit:getCapacity(',fillType,')')
	if self.storageType==UPK_Storage.SEPARATE and fillType~=nil then
		local newFillType=self.fillTypesConversionMatrix[Fillable.FILLTYPE_UNKNOWN][fillType] or fillType
		local flb=self.p_flbs[newFillType]
		if flb~=nil then
			return self.capacities[newFillType]
		else
			if self.parent~=nil then
				return self.parent:getCapacity(newFillType)
			end
		end
	end
	return self.capacity
end

function UniversalProcessKit:getFillType() -- for single, fifo and filo
	self:printFn('UniversalProcessKit:getFillType()')
	if self.storageType==UPK_Storage.SEPARATE then
		if self.parent~=nil then
			return self.parent:getFillType()
		end
		return Fillable.FILLTYPE_UNKNOWN
	end
	return self.fillType
end

function UniversalProcessKit:resetFillLevelIfNeeded()
	self:printFn('UniversalProcessKit:resetFillLevelIfNeeded()')
end

function UniversalProcessKit:allowFillType(fillType, allowEmptying) -- also check for capacity
	self:printFn('UniversalProcessKit:allowFillType(',fillType,', ',allowEmptying,')')
	-- return isAllowed, allowFilltype, capacityNotReached
	if fillType~=nil then
		local newFillType=self.fillTypesConversionMatrix[UniversalProcessKit.FILLTYPE_UNKNOWN][fillType] or fillType
		if UniversalProcessKit.isSpecialFillType(newFillType) then
			return true
		elseif self.storageType==UPK_Storage.SEPARATE then
			local flbs = self:getFillLevelBubbleShellFromFillType(newFillType)
			local fillLevel = flbs:getFillLevel(newFillType)
			local capacity = flbs:getCapacity(newFillType)
			return fillLevel < capacity
		elseif self.storageType==UPK_Storage.SINGLE then
			local myFillType=self.fillType
			newFillType=self.fillTypesConversionMatrix[myFillType][fillType]
			if myFillType==newFillType then
				return self.fillLevel < self.capacity
			elseif myFillType==UniversalProcessKit.FILLTYPE_UNKNOWN then
				return true
			end
		elseif self.storageType==UPK_Storage.FIFO or self.storageType==UPK_Storage.FILO then
			return self.fillLevel < self.capacity
		end
	end
	return false
end

function UniversalProcessKit:setFillLevel(newFillLevel, fillType, force)
	self:printFn('UniversalProcessKit:setFillLevel(',newFillLevel,', ',fillType,', ',force,')')
	if fillType~=nil then
		newFillType=self.fillTypesConversionMatrix[Fillable.FILLTYPE_UNKNOWN][fillType] or fillType
		if UniversalProcessKit.isSpecialFillType(newFillType) then -- should not happen
			self:addFillLevel(newFillLevel, newFillType)
		else
			local oldFillLevel = self:getFillLevel(newFillType)
			self:addFillLevel(newFillLevel-oldFillLevel, newFillType)
		end
	end
end

function UniversalProcessKit:addFillLevel(deltaFillLevel, fillType)
	self:printFn('UniversalProcessKit:addFillLevel(',deltaFillLevel,', ',fillType,')')
	if fillType~=nil then
		fillType=self.fillTypesConversionMatrix[Fillable.FILLTYPE_UNKNOWN][fillType] or fillType
	end
	return self + {deltaFillLevel, fillType}
end;

function UniversalProcessKit:addFillLevels(fillLevelsArr)
	self:printFn('UniversalProcessKit:addFillLevels(',fillLevelsArr,')')
	for fillType, deltaFillLevel in pairs(fillLevelsArr) do
		if type(deltaFillLevel)=="number" and type(fillType)=="number" then
			self:addFillLevel(deltaFillLevel,fillType)
		end
	end
end

function UniversalProcessKit:getUniqueFillType()
	self:printFn('UniversalProcessKit:getUniqueFillType()')
	local currentFillType=Fillable.FILLTYPE_UNKNOWN
	for _,v in pairs(self:getAcceptedFillTypes()) do
		fillLevel=self.fillLevels[v]
		if fillLevel~=nil and fillLevel>0 then
			return v
		end
	end
	return currentFillType
end;

function UniversalProcessKit:getAcceptedFillTypes()
	self:printFn('UniversalProcessKit:getAcceptedFillTypes()')
	local r={}
	for k,v in pairs(UniversalProcessKit.fillTypeIntToName) do
		if self.acceptedFillTypes[k] then
			table.insert(r,k)
		end
	end
	return r
end;

-- show or hide an icon on the mini map
function UniversalProcessKit:showMapHotspot(on,alreadySent)
	self:printFn('UniversalProcessKit:showMapHotspot(',on,', ',alreadySent,')')
	self.appearsOnMap=on
	if on==true and self.mapHotspot == nil then
		
		--[[
		if not g_currentMission.ingameMap.upk_tested then
			for k,v in pairs(g_currentMission.ingameMap) do
				self:print('g_currentMission.ingameMap.'..tostring(k)..' = '..tostring(v))
			end
			g_currentMission.ingameMap.upk_tested=true
		end
		]]--
		
		local widthHeightRatio = g_currentMission.syncBackgroundOverlay.height
		self:printInfo('widthHeightRatio = ',widthHeightRatio)
		self:printInfo('g_currentMission.ingameMap.mapWidth = ',g_currentMission.ingameMap.mapWidth)
		local iconSize = 0.015625 --g_currentMission.ingameMap.mapWidth / 10
		local x,_,z = unpack(self.wpos)
		self.mapHotspot = g_currentMission.ingameMap:createMapHotspot(nil, self.MapHotspotIcon, x, z, iconSize, iconSize * widthHeightRatio, false, false, false, 0, true)
	end
	if on==false and type(self.mapHotspot)=="table" and self.mapHotspot.delete~=nil then
		g_currentMission.ingameMap:deleteMapHotspot(self.mapHotspot)
		self.mapHotspot=nil
	end
	if not alreadySent then
		--self:raiseDirtyFlags(self.maphotspotDirtyFlag)
	end
end;

function UniversalProcessKit:setEnable(isEnabled,alreadySent)
	self:printFn('UniversalProcessKit:setEnable(',isEnabled,', ',alreadySent,')')
	if isEnabled~=nil then
		self.isEnabled=isEnabled
		if not alreadySent then
			--self:raiseDirtyFlags(self.isEnabledDirtyFlag)
		end
	end
	if self.useMapHotspot then
		if self.isEnabled or self.showMapHotSpotIfDisabled then
			self:printAll('self.isEnabled or self.showMapHotSpotIfDisabled')
			self:showMapHotspot(true,true)
		else
			self:printAll('not (self.isEnabled or self.showMapHotSpotIfDisabled)')
			self:showMapHotspot(false,true)
		end
	end
	self:setEnableChildren(isEnabled,alreadySent)
end;

function UniversalProcessKit:setEnableChildren(isEnabled,alreadySent)
	self:printFn('UniversalProcessKit:setEnableChildren(',isEnabled,', ',alreadySent,')')
	local mink,maxk=getMinMaxKeys(self.kids)
	self:printInfo('mink=',mink,' maxk=',maxk)
	if mink~=nil then
		for i=mink,maxk do
			self.kids[i]:setEnable(isEnabled,alreadySent)
		end
	end
end;

function UniversalProcessKit:postLoad()
	self:printFn('UniversalProcessKit:postLoad()')
	-- initial fill levels
	if self.isServer and self.base.timesSaved==0 then
		local initialFillLevelsArr = getArrayFromUserAttribute(self.nodeId, "initialFillLevels")
		for i=1,#initialFillLevelsArr,2 do
			local fillLevel=tonumber(initialFillLevelsArr[i])
			local fillType=unpack(UniversalProcessKit.fillTypeNameToInt(initialFillLevelsArr[i+1]))
			self:printAll('want to initially add ',fillLevel,' to ',fillType)
			if fillLevel~=nil and fillType~=nil then
				self:addFillLevel(fillLevel, fillType)
			end
		end
	end
	
	if self.triggerId~=nil and self.triggerId~=0 then
		if self.isServer then -- server, single game
			self:setIsPopulated(self.vehiclesInTrigger>0) -- from savegame, ignore players
		else -- client joning
			self:setIsPopulated(self.entitiesInTrigger>0)
		end
	end
	
	-- loading done (for actions)
	self.isLoaded=true
	
	if self.triggerId~=nil and self.triggerId~=0 then
		-- isLoaded true
		if self.isServer and self.playersInTrigger>0 then -- catch up on player left at end of game
			for i=1,self.playersInTrigger do
				self:operateAction('OnLeave')
			end
			self.playersInTrigger=0
		end
	end
end;

function UniversalProcessKit:loadFromAttributesAndNodes(xmlFile, key)
	self:printFn('UniversalProcessKit:loadFromAttributesAndNodes(',xmlFile,', ',key,')')
	key=key.."."..self.name

	local fillLevelsStr = getXMLString(xmlFile, key .. "#fillLevels")
	self:printInfo('read save fillLevels ',fillLevelsStr)
	local fillLevelsArr = gmatch(fillLevelsStr, "%S+")
	for i=1,#fillLevelsArr,2 do
		local fillLevel=tonumber(fillLevelsArr[i])
		local fillType=unpack(UniversalProcessKit.fillTypeNameToInt(fillLevelsArr[i+1]))
		self:printInfo('want to add saved ',fillLevel,' to ',fillType)
		if fillLevel~=nil and fillType~=nil then
			self:addFillLevel(fillLevel, fillType) -- should be good for fifo and filo
		end
	end
	
	local isEnabled = getXMLBool(xmlFile, key .. "#isEnabled")
	self:printInfo('read from save file: isEnabled = ',isEnabled,' (',type(isEnabled),')')
	self:setEnable(Utils.getNoNil(getXMLBool(xmlFile, key .. "#isEnabled"), true), true)
	
	local appearsOnMap = getXMLBool(xmlFile, key .. "#showMapHotspot")
	self:printInfo('read from save file: showMapHotspot = ',appearsOnMap,' (',type(appearsOnMap),')')
	self:showMapHotspot(Utils.getNoNil(getXMLBool(xmlFile, key .. "#showMapHotspot"), getBoolFromUserAttribute(self.nodeId, "showMapHotspot", false)), true)
	
	-- trigger
	if self.triggerId~=nil and self.triggerId~=0 then
		self.vehiclesInTrigger = getXMLInt(xmlFile, key .. "#vehiclesInTrigger") or 0
		self.playersInTrigger = getXMLInt(xmlFile, key .. "#playersInTrigger") or 0
	end

	self:loadExtraNodes(xmlFile, key)
	
	for i=1,#self.kids do
		self.kids[i]:loadFromAttributesAndNodes(xmlFile, key)
	end
	
	return true
end;

function UniversalProcessKit:getSaveAttributesAndNodes(nodeIdent)
	self:printFn('UniversalProcessKit:getSaveAttributesAndNodes(',nodeIdent,')')
	local attributes=""
		
	local nodes = "<"..tostring(self.name)
	
	local extraNodes=""
	
	if not self.isEnabled then
		extraNodes=extraNodes.." isEnabled=\"false\""
	end
	
	extraNodes=extraNodes.." showMapHotspot=\""..tostring(self.appearsOnMap).."\""
	
	local fillLevels = ""
	if self.storageType==UPK_Storage.SEPARATE then
		for _,flb in pairs(self.p_flbs) do
			local fillType = UniversalProcessKit.fillTypeIntToName[flb.fillType]
			local fillLevel = flb.fillLevel
			if fillType~="unknown" then
				if fillLevels~="" then
					fillLevels = fillLevels .. ' '
				end
				fillLevels = fillLevels .. tostring(round(fillLevel,4)) .. ' ' .. tostring(fillType)
			end
		end
	elseif self.storageType==UPK_Storage.SINGLE or self.storageType==UPK_Storage.FIFO or self.storageType==UPK_Storage.FILO then
		for i=1,#self.p_flbs do
			local flb = self.p_flbs[i]
			local fillType = UniversalProcessKit.fillTypeIntToName[flb.fillType]
			local fillLevel = flb.fillLevel
			if fillType~="unknown" then
				if fillLevels~="" then
					fillLevels = fillLevels .. ' '
				end
				fillLevels = fillLevels .. tostring(round(fillLevel,6)) .. ' ' .. tostring(fillType)
			end
		end
	end
	
	if fillLevels~="" then
		extraNodes = extraNodes.." fillLevels=\"" .. tostring(fillLevels) .. "\""
	end
	
	-- trigger
	if self.triggerId~=nil and self.triggerId~=0 then
		extraNodes = extraNodes.." vehiclesInTrigger=\"" .. tostring(self.vehiclesInTrigger) .. "\""
		extraNodes = extraNodes.." playersInTrigger=\"" .. tostring(self.playersInTrigger) .. "\""
	end
	
	local extraNodesF = self:getSaveExtraNodes(nodeIdent)
	
	if extraNodesF ~= "" then
		extraNodes = extraNodes .. ' ' .. extraNodesF
	end
	
	local nodesKids=""
	
	for i=1,#self.kids do
		local attributesKid, nodesKid = self.kids[i]:getSaveAttributesAndNodes(nodeIdent)
		attributes = attributes .. attributesKid
		if nodesKid~="" then
			if nodesKids=="" then
				nodesKids = nodesKid
			else
				nodesKids = nodesKids .. "\n" .. nodesKid
			end
		end
	end
	
	if nodesKids=="" then
		if extraNodes=="" then
			nodes=""
		else
			nodes = nodes .. extraNodes .. " />"
		end
	else
		nodesKids = string.gsub(nodesKids,"\n","\n\t")
		nodes = nodes .. extraNodes ..">\n\t" .. nodesKids .. "\n" .. "</"..tostring(self.name)..">"
	end
	
	return attributes, nodes
end;

-- use this function to load your extra Nodes (YourClass:loadExtraNodes)
function UniversalProcessKit:loadExtraNodes(xmlFile, key)
	self:printFn('UniversalProcessKit:loadExtraNodes(',xmlFile,', ',key,')')
	return true
end;

-- use this function to save your own values (YourClass:getSaveExtraNodes)
function UniversalProcessKit:getSaveExtraNodes(nodeIdent)
	self:printFn('UniversalProcessKit:getSaveExtraNodes(',nodeIdent,')')
	return ""
end;

