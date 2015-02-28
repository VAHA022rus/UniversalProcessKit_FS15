-- by mor2000

local UniversalProcessKit_mt = ClassUPK(UniversalProcessKit);
InitObjectClass(UniversalProcessKit, "UniversalProcessKit");

function UniversalProcessKit:onCreate(id)
	print('UniversalProcessKit:onCreate('..tostring(id)..')')
	local upkbase = OnCreateUPK:new(g_server ~= nil, g_client ~= nil)
	if upkbase==false or upkbase~=nil then
		upkbase:load(id)
		g_currentMission:addOnCreateLoadedObject(upkbase)
		upkbase:register(true)
	else
		upkbase:detele()
	end
end;

function UniversalProcessKit:print(string, debug)
	if debug==nil then
		debug=debugMode
	end
	if debug then
		if type(string)=="string" then
			local msg=string
			if self.nodeId~=nil or self.id~=nil then
				msg='[nid='..tostring(self.nodeId)..' oid='..tostring(self.id)..'] '..msg
			end
			if debug then
				msg='DEBUG '..msg
			end
			local signature=tostring(self.i18nNameSpace or '(unnamed)')..': '..tostring(self.name)
			_g.print(' ['..tostring(signature)..'] '..msg)
		end
	end
end;

function UniversalProcessKit:new(nodeId, parent, customMt)
	if nodeId==nil then
		print('Error: UniversalProcessKit:new() called with id=nil')
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
				print('adding capacity of '..tostring(capacity)..' to '..tostring(fillType))
				capacities[fillType]=capacity
			end
		end
	end

	self.capacities = FillLevelBubbleCapacities:new(self.p_capacity, capacities)

	for k,v in pairs(self.capacities) do
		print('capacity of '..tostring(k)..': '..tostring(v))
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
	self:print('fillTypesConversionMatrixStrStr: '..tostring(fillTypesConversionMatrixStrStr))
	local fillTypesConversionMatrixStrArr = gmatch(fillTypesConversionMatrixStrStr..',','(.-),')
	for _,fillTypesConversionMatrixStr in pairs(fillTypesConversionMatrixStrArr) do
		if fillTypesConversionMatrixStr~=nil and fillTypesConversionMatrixStr~="" then
			self:print('dealing with '..tostring(fillTypesConversionMatrixStr))
			self.fillTypesConversionMatrix = self.fillTypesConversionMatrix + FillTypesConversionMatrix:new(UniversalProcessKit.fillTypeNameToInt(gmatch(fillTypesConversionMatrixStr,'%S+')))
		end
	end

	print('self.fillTypesConversionMatrix is '..tostring(self.fillTypesConversionMatrix))
	
	for k,v in pairs(self.fillTypesConversionMatrix) do
		for l,w in pairs(v) do
			print('adding '..tostring(l)..' (incoming) to '..tostring(k)..' (stored) ends up as '..tostring(w))
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
			print('capacity of '..tostring(k)..': '..tostring(v))
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
				self:print('you need to set the modName-UserAttribute to use MapHotspotIcon')
			else
				self.MapHotspotIcon = g_modNameToDirectory[self.i18nNameSpace]..iconStr
				self:print('using \"'..tostring(self.MapHotspotIcon)..'\" as MapHotspotIcon')
			end
		else
			self.MapHotspotIcon = Utils.getFilename(mapHotspotIcons["TipPlace"], getAppBasePath())
		end
	end
	
	self.useMapHotspot = getUserAttribute(nodeId, "showMapHotspot") ~= nil
	
	self:showMapHotspot(getBoolFromUserAttribute(nodeId, "showMapHotspot", false), true)
	
	-- placeable object
	
	if self.type~="base" and self.parent~=nil then
		self.placeable = self.parent.placeable
		self.builtIn = self.parent.builtIn
		self.syncObj = self.parent.syncObj
		self.base = self.parent.base
		self.syncObj:registerObjectToSync(self) -- invokes to call read and writeStream
	end
	
	
	print('loaded module '..tostring(self.name)..' with id '..tostring(nodeId))
	
	print('self.placeable '..tostring(self.placeable))
	print('getBoolFromUserAttribute(nodeId, "adjustToTerrainHeight", false) '..tostring(getBoolFromUserAttribute(nodeId, "adjustToTerrainHeight", false)))
	
	if getBoolFromUserAttribute(nodeId, "adjustToTerrainHeight", false) and self.placeable then
		UniversalProcessKit.adjustToTerrainHeight(nodeId)
	end
	
	UniversalProcessKitListener.registerPostLoadObject(self)
	
	--g_currentMission:addNodeObject(self.nodeId, self)
	
	return self
end;

function UniversalProcessKit:findChildrenLoopFunc(childId)
	local type = getStringFromUserAttribute(childId, "type")
	self:print('UserAttribute type is '..tostring(type))
	if type~=nil and UniversalProcessKit.ModuleTypes[type]~=nil then
		childName=Utils.getNoNil(getName(childId),"")
		self:print('found module '..childName..' of type '..tostring(type)..' and id '..tostring(childId))
		local module=UniversalProcessKit.ModuleTypes[type]:new(childId,self)
		if module~=nil and module~=false then
			--if debugMode then
			--	module=debugObject(module)
			--end
			table.insert(self.kids,module)
			module:findChildren(childId)
		else
			self:print('couldnt load module of type '..tostring(type)..' and id '..tostring(childId))
			self:findChildren(childId)
		end
	else
		if getBoolFromUserAttribute(childId, "adjustToTerrainHeight", false) and self.placeable then
			UniversalProcessKit.adjustToTerrainHeight(childId)
		end
		self:findChildren(childId)
	end
	return true
end

function UniversalProcessKit:findChildren(id)
	loopThruChildren(id,"findChildrenLoopFunc",self)
end;

function UniversalProcessKit:findChildrenShapesLoopFunc(childId)
	table.insert(self.childrenShapes,childId)
	self:findChildrenShapes(childId)
	return true
end;

function UniversalProcessKit:findChildrenShapes(id)
	loopThruChildren(id,"findChildrenShapesLoopFunc",self)
end;

function UniversalProcessKit:delete()
	print('delete module '..tostring(self.name)..' with id '..tostring(self.id))

	self.isEnabled = false

	self:removeTrigger()
	
	for _,v in pairs(self.kids) do
		v:removeTrigger()
		v:delete()
	end
	
	self.kids={}
	
	UniversalProcessKitListener.removeUpdateable(self)
	UniversalProcessKitListener.removeDayChangeListener(self)
	UniversalProcessKitListener.removeHourChangeListener(self)
	UniversalProcessKitListener.removeMinuteChangeListener(self)
	UniversalProcessKitListener.removeSecondChangeListener(self)

	if self.addNodeObject and self.nodeId ~= 0 then
		g_currentMission:removeNodeObject(self.nodeId)
	end
	
	unregisterObjectClassName(self)
end;


function UniversalProcessKit:update(dt)
	-- do sth with time (ms)
	-- requieres UniversalProcessKitListener.addUpdateable(self)
	-- and UniversalProcessKitListener.removeUpdateable(self)
end;

function UniversalProcessKit:registerOnFillLevelChangeFunc(obj,func)
	print('UniversalProcessKit:registerOnFillLevelChangeFunc('..tostring(obj)..', '..tostring(func)..')')
	if type(obj)=="table" and obj~=self and type(func)=="string" and type(obj[func])=="function" then
		self.onFillLevelChangeFuncs[obj]=func
	end
end

function UniversalProcessKit:unregisterOnFillLevelChangeFunc(obj)
	if type(obj)=="table" then
		self.onFillLevelChangeFuncs[obj]=nil
	end
end

function UniversalProcessKit:p_onFillLevelChange(deltaFillLevel, newFillLevel, fillType) -- do sth with syncing
	self:print('UniversalProcessKit:p_onFillLevelChange('..tostring(deltaFillLevel)..', '..tostring(newFillLevel)..', '..tostring(fillType)..')')
	
	if self.isServer then
		table.insert(self.fillLevelsToSync,{fillLevel=newFillLevel,fillType=fillType})
		self:raiseDirtyFlags(self.fillLevelDirtyFlag)
	end
	
	for obj,func in pairs(self.onFillLevelChangeFuncs) do
		obj[func](obj, deltaFillLevel, newFillLevel, fillType)
	end
	self:onFillLevelChange(deltaFillLevel, newFillLevel, fillType)
end

function UniversalProcessKit:onFillLevelChange(deltaFillLevel, newFillLevel, fillType) -- to be overwritten
	self:print('UniversalProcessKit:onFillLevelChange('..tostring(deltaFillLevel)..', '..tostring(newFillLevel)..', '..tostring(fillType)..')')
end

function UniversalProcessKit:getFillLevelBubbleShellFromFillType(fillType)
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
	--self:print('UniversalProcessKit:getFillLevel('..tostring(fillType)..')')
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
	--self:print('UniversalProcessKit:getCapacity('..tostring(fillType)..')')
	if self.storageType==UPK_Storage.SEPARATE and fillType~=nil then
		local newFillType=self.fillTypesConversionMatrix[Fillable.FILLTYPE_UNKNOWN][fillType] or fillType
		local flb=self.p_flbs[newFillType]
		if flb~=nil then
			return self.capacities[newFillType]
		else
			if self.parent~=nil then
				return self.parent:getCapacity(fillType)
			end
		end
	end
	return self.capacity
end

function UniversalProcessKit:getFillType() -- for single, fifo and filo
	if self.storageType==UPK_Storage.SEPARATE then
		if self.parent~=nil then
			return self.parent:getFillType()
		end
	end
	return self.fillType
end

function UniversalProcessKit:resetFillLevelIfNeeded()
end

function UniversalProcessKit:allowFillType(fillType, allowEmptying) -- also check for capacity
	self:print('UniversalProcessKit:allowFillType('..tostring(fillType)..')')
	if fillType~=nil then
		local newFillType=self.fillTypesConversionMatrix[UniversalProcessKit.FILLTYPE_UNKNOWN][fillType] or fillType
		if UniversalProcessKit.isSpecialFillType(newFillType) then
			return true
		elseif self.storageType==UPK_Storage.SEPARATE then
			self:print('self.storageType==UPK_Storage.SEPARATE')
			local flb=self.p_flbs[newFillType]
			if flb~=nil then
				return flb.fillLevel < flb.capacity
			else
				if self.parent~=nil then
					return self.parent:allowFillType(fillType, allowEmptying)
				end
			end
		elseif self.storageType==UPK_Storage.SINGLE then
			self:print('self.storageType==UPK_Storage.SINGLE')
			local myFillType=self.fillType
			self:print('myFillType = '..tostring(myFillType))
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
	self:print('UniversalProcessKit:addFillLevel('..tostring(deltaFillLevel)..', '..tostring(fillType)..')')
	if fillType~=nil then
		fillType=self.fillTypesConversionMatrix[Fillable.FILLTYPE_UNKNOWN][fillType] or fillType
	end
	return self + {deltaFillLevel, fillType}
end

function UniversalProcessKit:addFillLevels(fillLevelsArr)
	for fillType, deltaFillLevel in pairs(fillLevelsArr) do
		if type(deltaFillLevel)=="number" and type(fillType)=="number" then
			self:addFillLevel(deltaFillLevel,fillType)
		end
	end
end

function UniversalProcessKit:getUniqueFillType()
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
	self:print('UniversalProcessKit:showMapHotspot('..tostring(on)..', '..tostring(alreadySent)..')')
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
		self:print('widthHeightRatio = '..tostring(widthHeightRatio))
		self:print('g_currentMission.ingameMap.mapWidth = '..tostring(g_currentMission.ingameMap.mapWidth))
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
	self:print('UniversalProcessKit:setEnable('..tostring(isEnabled)..')')
	
	if type(self.entities) == "table" and self.entitiesInTrigger>0 then
		for _, vehicle in pairs(self.entities) do
			print('setting vehicle '..tostring(vehicle)..' in trigger to '..tostring(isEnabled))
			self:triggerUpdate(vehicle,isEnabled)
		end
		if self.playerInRange == true then
			self:triggerUpdate(nil,isEnabled)
		end
	end
	
	if isEnabled~=nil then
		self.isEnabled=isEnabled
		if not alreadySent then
			--self:raiseDirtyFlags(self.isEnabledDirtyFlag)
		end
	end
	if self.useMapHotspot then
		if self.isEnabled or self.showMapHotSpotIfDisabled then
			self:print('self.isEnabled or self.showMapHotSpotIfDisabled')
			self:showMapHotspot(true,true)
		else
			self:print('not (self.isEnabled or self.showMapHotSpotIfDisabled)')
			self:showMapHotspot(false,true)
		end
	end
	self:setEnableChildren(isEnabled,alreadySent)
end;

function UniversalProcessKit:setEnableChildren(isEnabled,alreadySent)
	self:print('UniversalProcessKit:setEnableChildren('..tostring(isEnabled)..')')
	for _,kid in pairs(self.kids) do
		kid:setEnable(isEnabled,alreadySent)
	end
end;

function UniversalProcessKit:postLoad()
	self:print('UniversalProcessKit:postLoad()')
	-- initial fill levels
	if self.isServer and self.base.timesSaved==0 then
		local initialFillLevelsArr = getArrayFromUserAttribute(self.nodeId, "initialFillLevels")
		for i=1,#initialFillLevelsArr,2 do
			local fillLevel=tonumber(initialFillLevelsArr[i])
			local fillType=unpack(UniversalProcessKit.fillTypeNameToInt(initialFillLevelsArr[i+1]))
			self:print('want to initially add '..tostring(fillLevel)..' to '..tostring(fillType))
			if fillLevel~=nil and fillType~=nil then
				self:addFillLevel(fillLevel, fillType)
			end
		end
	end
end;

function UniversalProcessKit:loadFromAttributesAndNodes(xmlFile, key)
	self:print('calling UniversalProcessKit:loadFromAttributesAndNodes for id '..tostring(self.nodeId))
	key=key.."."..self.name

	local fillLevelsStr = getXMLString(xmlFile, key .. "#fillLevels")
	self:print('read save fillLevels '..tostring(fillLevelsStr))
	local fillLevelsArr = gmatch(fillLevelsStr, "%S+")
	for i=1,#fillLevelsArr,2 do
		local fillLevel=tonumber(fillLevelsArr[i])
		local fillType=unpack(UniversalProcessKit.fillTypeNameToInt(fillLevelsArr[i+1]))
		self:print('want to add saved '..tostring(fillLevel)..' to '..tostring(fillType))
		if fillLevel~=nil and fillType~=nil then
			self:addFillLevel(fillLevel, fillType) -- should be good for fifo and filo
		end
	end
	
	local isEnabled = getXMLBool(xmlFile, key .. "#isEnabled")
	self:print('read from save file: isEnabled = '..tostring(isEnabled)..' ('..type(isEnabled)..')')
	self:setEnable(Utils.getNoNil(getXMLBool(xmlFile, key .. "#isEnabled"), true), true)
	
	local appearsOnMap = getXMLBool(xmlFile, key .. "#showMapHotspot")
	self:print('read from save file: showMapHotspot = '..tostring(appearsOnMap)..' ('..type(appearsOnMap)..')')
	self:showMapHotspot(Utils.getNoNil(appearsOnMap, getBoolFromUserAttribute(self.nodeId, "showMapHotspot", false)), true)

	self:loadExtraNodes(xmlFile, key)
	
	for k,v in pairs(self.kids) do
		v:loadFromAttributesAndNodes(xmlFile, key)
	end
	
	return true
end;

function UniversalProcessKit:getSaveAttributesAndNodes(nodeIdent)
	self:print('calling UniversalProcessKit:getSaveAttributesAndNodes for id '..tostring(self.nodeId))
	local attributes=""
		
	local nodes = "<"..tostring(self.name)
	
	local extraNodes=""
	
	if not self.isEnabled then
		extraNodes=extraNodes.." isEnabled=\"false\""
	end
	
	local standardAppearsOnMap = getBoolFromUserAttribute(self.nodeId, "showMapHotspot", false)
	if self.appearsOnMap~=standardAppearsOnMap then
		self:print('save to file: showMapHotspot = '..tostring(self.appearsOnMap))
		extraNodes=extraNodes.." showMapHotspot=\""..tostring(self.appearsOnMap).."\""
	end
	
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
	
	self:print('fillLevels: '..tostring(fillLevels))
	
	if fillLevels~="" then
		extraNodes = extraNodes.." fillLevels=\"" .. tostring(fillLevels) .. "\""
	end
	
	local extraNodesF = self:getSaveExtraNodes(nodeIdent)
	
	if extraNodesF ~= "" then
		extraNodes = extraNodes .. ' ' .. extraNodesF
	end
	
	local nodesKids=""
	for k,v in pairs(self.kids) do
		local attributesKid, nodesKid = v:getSaveAttributesAndNodes(nodeIdent)
		attributes = attributes .. attributesKid
		if nodesKid~="" then
			nodesKids = nodesKids .. nodesKid
		end
	end
	
	if nodesKids=="" then
		if extraNodes=="" then
			nodes=""
		else
			nodes = nodes .. extraNodes .. " />"
		end
	else
		nodes = nodes .. extraNodes ..">\n" .. "\t" .. nodesKids .. "\n" .. "</"..tostring(self.name)..">"
	end
	
	self:print('nodes: '..tostring(nodes))
	
	return attributes, nodes
end;

-- use this function to load your extra Nodes (YourClass:loadExtraNodes)
function UniversalProcessKit:loadExtraNodes(xmlFile, key)
	return true
end;

-- use this function to save your own values (YourClass:getSaveExtraNodes)
function UniversalProcessKit:getSaveExtraNodes(nodeIdent)
	return ""
end;

