-- by mor2000

UniversalProcessKit=_g.UniversalProcessKit
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
	
	self.name = getName(self.nodeId)
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
	
	self.appearsOnPDA = getBoolFromUserAttribute(nodeId, "appearsOnPDA", false)
	self.MapHotspotName = getStringFromUserAttribute(nodeId, "MapHotspot")
	local mapHotspotIcons={
		Bank="$dataS2/missions/hud_pda_spot_bank.png",
		Shop="$dataS2/missions/hud_pda_spot_shop.png",
		Phone="$dataS2/missions/hud_pda_spot_phone.png",
		Eggs="$dataS/missions/hud_pda_spot_eggs.png",
		TipPlace="$dataS2/missions/hud_pda_spot_tipPlace.png",
		Cows="$dataS2/missions/hud_pda_spot_cows.png",
		Sheep="$dataS2/missions/hud_pda_spot_sheep.png",
		Chickens="$dataS2/missions/hud_pda_spot_chickens.png"}
	
	if self.MapHotspotName~=nil then
		if mapHotspotIcons[self.MapHotspotName]~=nil then
			self.MapHotspotIcon = Utils.getFilename(mapHotspotIcons[self.MapHotspotName], getAppBasePath())
		else
			local iconStr = getStringFromUserAttribute(nodeId, "MapHotspotIcon")
			if iconStr~=nil then
				if self.i18nNameSpace==nil then
					self:print('you need to set the i18nNameSpace to use MapHotspotIcon')
				else
					self.MapHotspotIcon = g_modNameToDirectory[self.i18nNameSpace]..iconStr
					--self:print('using \"'..tostring(self.MapHotspotIcon)..'\" as MapHotspotIcon')
				end
			end
		end
	end

	if self.MapHotspotName~=nil then
		self:showMapHotspot(self.appearsOnPDA)
	end
	
	-- placeable object
	
	if self.type~="base" and self.parent~=nil then
		self.placeable=self.parent.placeable
	end
	
	-- loading kids (according to known types of modules)
	-- kids are loading their kids and so on..
	
	print('loaded module '..tostring(self.name)..' with id '..tostring(nodeId))
	
	if getBoolFromUserAttribute(nodeId, "adjustToTerrainHeight", false) then
		UniversalProcessKit.adjustToTerrainHeight(nodeId)
	end
	
	UniversalProcessKitListener.registerPostLoadObject(self)
	
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
			if debugMode then
				module=debugObject(module)
			end
			table.insert(self.kids,module)
			module:findChildren(childId)
		else
			self:print('couldnt load module of type '..tostring(type)..' and id '..tostring(childId))
			self:findChildren(childId)
		end
	else
		if getBoolFromUserAttribute(childId, "adjustToTerrainHeight", false) then
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
	if self.storageType==UPK_Storage.SEPARATE and fillType~=nil then
		local newFillType=self.fillTypesConversionMatrix[Fillable.FILLTYPE_UNKNOWN][fillType] or fillType
		local flb=self.p_flbs[newFillType]
		if flb~=nil then
			return flb.fillLevel
		else
			if self.parent~=nil then
				return self.parent:getFillLevel(fillType)
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

function UniversalProcessKit:getFillType()
	return self.fillType
end

function UniversalProcessKit:resetFillLevelIfNeeded()
end

function UniversalProcessKit:allowFillType(fillType, allowEmptying) -- also check for capacity
	if fillType~=nil then
		newFillType=self.fillTypesConversionMatrix[Fillable.FILLTYPE_UNKNOWN][fillType] or fillType
		if UniversalProcessKit.isSpecialFillType(newFillType) then
			return true
		elseif self.storageType==UPK_Storage.SEPARATE then
			local flb=self.p_flbs[newFillType]
			if flb~=nil then
				return flb.fillLevel < flb.capacity
			else
				if self.parent~=nil then
					return self.parent:allowFillType(fillType, allowEmptying)
				end
			end
		elseif self.storageType==UPK_Storage.SINGLE or self.storageType==UPK_Storage.FIFO or self.storageType==UPK_Storage.FILO then
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
	return self + {deltaFillLevel, fillType}
end;



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

-- show or hide an icon on the pda map
function UniversalProcessKit:showMapHotspot(on,alreadySent)
	self.appearsOnPDA=on
	if on==true and self.mapHotspot == nil then
		local iconSize = g_currentMission.missionPDA.pdaMapWidth / 15
		local x,_,z = unpack(self.wpos)
		self.mapHotspot = g_currentMission.missionPDA:createMapHotspot(self.MapHotspotName, self.MapHotspotIcon, x, z, iconSize, iconSize * 4 / 3, false, false, false, 0, true)
	end
	if on==false and type(self.mapHotspot)=="table" and self.mapHotspot.delete~=nil then
		g_currentMission.missionPDA:deleteMapHotspot(self.mapHotspot)
		self.mapHotspot=nil
	end
	if not alreadySent then
		--self:raiseDirtyFlags(self.maphotspotDirtyFlag)
	end
end;

function UniversalProcessKit:setEnable(isEnabled,alreadySent)
	self:print('setEnable('..tostring(isEnabled)..')')
	if self.isEnabled~=isEnabled then
		self.isEnabled=isEnabled
		if alreadySent==nil or not alreadySent then
			--self:raiseDirtyFlags(self.enabledDirtyFlag)
		end
	end
	self:setEnableChildren(isEnabled,alreadySent)
end;

function UniversalProcessKit:setEnableChildren(isEnabled,alreadySent)
	self:print('setEnableChildren('..tostring(isEnabled)..')')
	for _,kid in pairs(self.kids) do
		kid:setEnable(isEnabled,alreadySent)
	end
end;

function UniversalProcessKit:postLoad()
	self:print('UniversalProcessKit:postLoad()')
	-- initial fill levels
	if self.base.timesSaved==0 then
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
	
	if getXMLFloat(xmlFile, key .. "#isEnabled")=="false" then
		self:setEnable(false)
	end
	
	for k,v in pairs(self.kids) do
		v:loadFromAttributesAndNodes(xmlFile, key)
	end
	
	return self:loadExtraNodes(xmlFile, key)
end;

function UniversalProcessKit:getSaveAttributesAndNodes(nodeIdent)
	self:print('calling UniversalProcessKit:getSaveAttributesAndNodes for id '..tostring(self.nodeId))
	local attributes=""
		
	local nodes = "<"..tostring(self.name)
	
	if not self.isEnabled then
		nodes=nodes.." isEnabled=\"false\""
	end
	
	local fillLevels = ""
	if self.storageType==UPK_Storage.SEPARATE then
		for _,flb in pairs(self.p_flbs) do
			local fillType = UniversalProcessKit.fillTypeIntToName[flb.fillType]
			local fillLevel = flb.fillLevel
			if fillLevels~="" then
				fillLevels = fillLevels .. ' '
			end
			fillLevels = fillLevels .. tostring(round(fillLevel,4)) .. ' ' .. tostring(fillType)
		end
	elseif self.storageType==UPK_Storage.SINGLE or self.storageType==UPK_Storage.FIFO or self.storageType==UPK_Storage.FILO then
		for i=1,#self.p_flbs do
			local flb = self.p_flbs[i]
			local fillType = UniversalProcessKit.fillTypeIntToName[flb.fillType]
			local fillLevel = flb.fillLevel
			if fillLevels~="" then
				fillLevels = fillLevels .. ' '
			end
			fillLevels = fillLevels .. tostring(round(fillLevel,4)) .. ' ' .. tostring(fillType)
		end
	end
	
	self:print('fillLevels: '..tostring(fillLevels))
	
	local extraNodes=""
	
	if fillLevels~="" then
		extraNodes = " fillLevels=\"" .. tostring(fillLevels) .. "\""
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

