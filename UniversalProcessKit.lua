-- by mor2000

UniversalProcessKit=_g.UniversalProcessKit
local UniversalProcessKit_mt = ClassUPK(UniversalProcessKit);
InitObjectClass(UniversalProcessKit, "UniversalProcessKit");

function UniversalProcessKit:onCreate(id)
	local object = UPK_Base:new(id, false, true)
	if object==false or object~=nil then
		object.builtIn=true
		g_currentMission:addOnCreateLoadedObject(object)
		object:register(true)
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
			local signature=self.className or "unknown"
			_g.print(' ['..tostring(signature)..'] '..msg)
		end
	end
end;

function UniversalProcessKit:new(nodeId, parent, customMt)
	if nodeId==nil then
		print('Error: UniversalProcessKit:new() called with id=nil')
		return false
	end

	local self = Object:new(g_server ~= nil, g_client ~= nil, customMt or UniversalProcessKit_mt) -- base needs to be object
	--local self={}
	--setmetatable(self, customMt or UniversalProcessKit_mt)
	registerObjectClassName(self, "UniversalProcessKit")

	self.rootNode = nodeId
	self.nodeId = nodeId
	self.triggerId = 0
	
	self.parent= parent
	self.kids={}
	self.type=nil

	self.onCreates = {}
	
	self.x,self.y,self.z = getTranslation(nodeId)
	self.pos = __c({self.x,self.y,self.z})
	self.wpos = __c({getWorldTranslation(nodeId)})
	self.rot = __c({getRotation(nodeId)})
	self.wrot = __c({getWorldRotation(nodeId)})
	self.scale = __c({getScale(nodeId)})
	
	-- enable processing of stuff
	
	self.name = getName(self.nodeId)
	self.type = getStringFromUserAttribute(nodeId, "type")
	self.isEnabled = getBoolFromUserAttribute(nodeId, "isEnabled", true)

	-- storage and capacity/ capacities
	
	self.capacity = getNumberFromUserAttribute(nodeId, "capacity", math.huge)
	
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
	
	if self.storageType==UPK_Storage.SEPARATE and #storeArr==0 and self.parent~=nil then
		self.storageController = self.parent.storageController
	else
		self.storageController = UniversalProcessKitStorageController:new(self.storageType, self.capacity, self)
		if self.storageType==UPK_Storage.SEPARATE then
			for i=1,#storeArr do
				local fillType = UniversalProcessKit.fillTypeNameToInt[storeArr[i]]
				self.storageController:createStorageBit(fillType)
			end
		end
	end

	if self.storageType==UPK_Storage.SEPARATE or self.storageType==UPK_Storage.SINGLE then
		local capacities = {}
		local capacitiesArr = getArrayFromUserAttribute(nodeId, "capacities")
		for i=1,#capacitiesArr,2 do
			local capacity=tonumber(capacitiesArr[i])
			local fillType=unpack(UniversalProcessKit.fillTypeNameToInt(capacitiesArr[i+1]))
			if capacity~=nil and fillType~=nil then
				capacities[fillType]=capacity
			end
		end
		for fillType, capacity in pairs(capacities) do
			self.storageController:setStorageBitCapacity(fillType, capacity)
		end
	end
	
	self.initialFillLevels = {}
	local initialFillLevelsArr = getArrayFromUserAttribute(nodeId, "initialFillLevels")
	for i=1,#initialFillLevelsArr,2 do
		local fillLevel=tonumber(initialFillLevelsArr[i])
		local fillType=UniversalProcessKit.fillTypeNameToInt[initialFillLevelsArr[i+1]]
		self:print('want to initially add '..tostring(fillLevel)..' to '..tostring(fillType))
		if fillLevel~=nil and fillType~=nil then
			self.initialFillLevels[fillType] = self:addFillLevel(fillLevel, fillType) -- gets removed when save is loaded
		end
	end
		
	if debugMode then
		self.storageController=debugObject(self.storageController)
	end
	
	-- addNodeObject
	--[[
	if self.addNodeObject and getRigidBodyType(nodeId) ~= "NoRigidBody" then
		g_currentMission:addNodeObject(nodeId, self)
	end
	--]]
	
	-- MapHotspot
	
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
	
	print('loading module '..tostring(self.name)..' with id '..tostring(nodeId))
	
	if getBoolFromUserAttribute(nodeId, "adjustToTerrainHeight", false) then
		UniversalProcessKit.adjustToTerrainHeight(nodeId)
	end
	
	self:findChildren(nodeId)
	
	self.displayTrigger=nil
	
	return self
end;

function UniversalProcessKit:findChildrenLoopFunc(childId)
	local type = getStringFromUserAttribute(childId, "type")
	self:print('UserAttribute type is '..tostring(type))
	if type~=nil and UniversalProcessKit.ModuleTypes[type]~=nil then
		childName=Utils.getNoNil(getName(childId),"")
		self:print('found module '..childName..' of type '..tostring(type)..' and id '..tostring(childId))
		local module=UniversalProcessKit.ModuleTypes[type]:new(childId,self)
		if module~=nil then
			if debugMode then
				module=debugObject(module)
			end
			table.insert(self.kids,module)
		else
			self:print('couldnt load module of type '..tostring(type)..' and id '..tostring(childId))
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



function UniversalProcessKit:getFillType()
	return self.storageController:getFillType()
end;

function UniversalProcessKit:getFillLevel(fillType)
	return self.storageController:getFillLevel(fillType)
end;

function UniversalProcessKit:setFillLevel(newFillLevel, fillType)
	self:print('UniversalProcessKit:setFillLevel('..tostring(fillLevel)..', '..tostring(fillType)..')')
	local oldFillLevel = self.storageController:getFillLevel(fillType)
	self.storageController:addFillLevel(newFillLevel - oldFillLevel, fillType)
	return 0
end;

function UniversalProcessKit:addFillLevel(deltaFillLevel, fillType)
	self:print('UniversalProcessKit:addFillLevel('..tostring(deltaFillLevel)..', '..tostring(fillType)..')')
	return self.storageController:addFillLevel(deltaFillLevel, fillType)
end;

function UniversalProcessKit:getStorageBitCapacity(fillType)
	return self.storageController:getStorageBitCapacity(fillType)
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
	if self.isEnabled~=isEnabled then
		self.isEnabled=isEnabled
		if alreadySent==nil or not alreadySent then
			--self:raiseDirtyFlags(self.enabledDirtyFlag)
		end
	end
	self:setEnableChildren(isEnabled,alreadySent)
end;

function UniversalProcessKit:setEnableChildren(isEnabled,alreadySent)
	for _,v in pairs(self.kids) do
		v:setEnable(isEnabled,alreadySent)
	end
end;

function UniversalProcessKit:loadFromAttributesAndNodes(xmlFile, key)
	self:print('calling UniversalProcessKit:loadFromAttributesAndNodes for id '..tostring(self.nodeId))
	key=key.."."..self.name
	
	for fillType, fillLevel in pairs(self.initialFillLevels) do
		self:addFillLevel(-fillLevel, fillType)
	end
	
	--local fillType=getXMLFloat(xmlFile, key .. "#fillType")
	--if fillType~=nil then
	--	self:setFillType(unpack(UniversalProcessKit.fillTypeNameToInt(fillType)))
	--end
	
	--[[
	if getXMLFloat(xmlFile, key .. "#isEnabled")=="false" then
		self:setEnable(false)
	end
	if getXMLFloat(xmlFile, key .. "#showMapHotspot")=="false" then
		self:showMapHotspot(false)
	end
	
	for k,v in pairs(UniversalProcessKit.fillTypeIntToName) do
		local fillLevel = getXMLFloat(xmlFile, key .. "#" .. tostring(v))
		if fillLevel~=nil then
			self:setFillLevel(fillLevel,k,true)
		end
	end

	for k,v in pairs(self.kids) do
		v:loadFromAttributesAndNodes(xmlFile, key)
	end

	--]]
	
	return self:loadExtraNodes(xmlFile, key)
end;

function UniversalProcessKit:getSaveAttributesAndNodes(nodeIdent)
	self:print('calling UniversalProcessKit:getSaveAttributesAndNodes for id '..tostring(self.nodeId))
	local attributes=""
	local nodes=""
	
	--[[
	
	local nodes = "\t<"..tostring(self.name)

	--nodes=nodes.." fillType=\""..tostring(UniversalProcessKit.fillTypeIntToName[self.fillType]).."\""
	if not self.isEnabled then
		nodes=nodes.." isEnabled=\"false\""
	end
	if self.mapHotspot~=nil then
		nodes=nodes.." showMapHotspot=\"true\""
	end
	
	local extraNodes=""
	for k,v in pairs(UniversalProcessKit.fillTypeIntToName) do
		local fillLevel=rawget(self.fillLevels,k)
		if fillLevel~=nil and fillLevel>=0.001 then
			extraNodes = extraNodes .. " " .. tostring(v) .. "=\"" .. tostring(mathfloor(fillLevel*1000+0.5)/1000) .. "\""
		end
	end

	extraNodes=extraNodes..self:getSaveExtraNodes(nodeIdent)
	
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
			nodes = nodes .. extraNodes .. " />\n"
		end
	else
		nodes = nodes .. extraNodes ..">\n" .. string.gsub(nodesKids,"\n","\n\t") .. "\n\t</"..tostring(self.name)..">"
	end
	
	--]]
	
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

