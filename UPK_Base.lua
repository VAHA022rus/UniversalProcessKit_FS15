-- by mor2000

--------------------
-- Base (root of every building, has no parent, main storage in simple buildings)


local UPK_Base_mt = ClassUPK(UPK_Base,UniversalProcessKit)
InitObjectClass(UPK_Base, "UPK_Base")
UniversalProcessKit.addModule("base",UPK_Base)

function UPK_Base:new(nodeId, placeable, builtIn, syncObj)
	printFn('UPK_Base:new(',nodeId,', ',placeable,', ',builtIn,', ',syncObj,')')
	
	local self = UniversalProcessKit:new(nodeId, nil, UPK_Base_mt)
	registerObjectClassName(self, "UPK_Base")
	
	self.placeable = placeable or false
	self.builtIn = builtIn or false
	self.syncObj = syncObj
	self.base = self
	self.syncObj:registerObjectToSync(self) -- invokes to call read and writeStream
	
	if self.builtIn then
		g_currentMission:addOnCreateLoadedObjectToSave(self)
	end
	
	self.timesSaved = 0
	
	local upk=ModsUtil.modNameToMod["AAA_UniversalProcessKit"]
	if upk==nil then
		printErr('ERROR (YOUR FAULT): DO NOT RENAME THE UniversalProcessKit MOD FILE - NOTHING WILL WORK - it has to be "AAA_UniversalProcessKit"')
		return false
	end
	
	local UPKversion = getUserAttribute(nodeId, "UPKversion")
	if UPKversion~=nil then
		local reqversion={}
		for _,v in pairs(gmatch(UPKversion,"[0-9]+")) do
			table.insert(reqversion,tonumber(v))
		end;
		local upk_version={}
		for _,v in pairs(gmatch(upk.version,"[0-9]+")) do
			table.insert(upk_version,tonumber(v))
		end;
		for k,v in pairs(upk_version) do
			if v>(reqversion[k] or 0) then
				break
			elseif v<(reqversion[k] or 0) then
				printErr('Error: the required upk version of this mod (',UPKversion,') doesnt fit your upk mod (',upk.version,')')
				return false
			end
		end
	end
	
	-- i18nNameSpace
	
	self.i18nNameSpace = getStringFromUserAttribute(nodeId, "modname")
	local i18n_mt = {
		__index = function(t,key)
			if key=="" then
				return ""
			end
			local text=""
			if type(key)=="string" then
				if self.i18nNameSpace~=nil and
					(_g or {})[self.i18nNameSpace]~=nil and
					_g[self.i18nNameSpace].g_i18n~=nil and
					_g[self.i18nNameSpace].g_i18n:hasText(key) then
					text=_g[self.i18nNameSpace].g_i18n:getText(key)
				elseif g_i18n:hasText(key) then
					text=g_i18n:getText(key)
				end
				rawset(self.i18n,key,text)
				--print('asked i18n for \"'..tostring(key)..'\" returning \"'..tostring(text)..'\"')
			end
			return text
		end
	}
	setmetatable(self.i18n, i18n_mt)
	
	self.shapeNamesToNodeIds={}
	
	self:printInfo('UPK_Base:new done')
	
	return self
end

function UPK_Base:delete()
	self:printFn('UPK_Base:delete()')
	if self.builtIn then
		g_currentMission:removeOnCreateLoadedObjectToSave(self)
		if self.nodeId ~= 0 then
	        g_currentMission:removeNodeObject(self.nodeId)
	    end
	end
	UPK_Base:superClass().delete(self)
end

function UPK_Base:loadFromAttributesAndNodes(xmlFile, key)
	self:printFn('UPK_Base:loadFromAttributesAndNodes(',xmlFile,', ',key,')')
	
	self.timesSaved = getXMLInt(xmlFile, key .. "#timesSaved") or 0
	
	self:printAll('times saved: '..tostring(self.timesSaved))
	
	return UPK_Base:superClass().loadFromAttributesAndNodes(self, xmlFile, key)
end;

function UPK_Base:getSaveAttributesAndNodes(nodeIdent)
	self:printFn('UPK_Base:getSaveAttributesAndNodes(',nodeIdent,')')
	local attributes, nodes = UPK_Base:superClass().getSaveAttributesAndNodes(self,nodeIdent)
	
	if nodes~="" then
		nodes = "\t\t" .. nodes
	end
	
	local timesSaved = ' timesSaved=\"' .. ((self.timesSaved or 0)+1) .. '\"'

	if attributes~="" then
		attributes = timesSaved .. ' ' .. attributes
	else
		attributes = timesSaved
	end

	return attributes, nodes
end;

-- shapes

function UPK_Base:setVisibility(name,show) -- show and hide
	self:printFn('UPK_Base:setVisibility(',name,',',show,')')
	
	if type(name)=="table" then
		for _,shapeName in pairs(name) do
			self:setVisibility(shapeName,show)
		end
		return
	end
	
	if name==nil or name=="" then
		return false
	end
	
	local shapeId=self.shapeNamesToNodeIds[name]
	if shapeId==nil or shapeId==0 or type(shapeId)~="number" then
		self:printErr('name of shape "'..tostring(name)..'" unknown and/or not valid')
		return false
	end
	
	setVisibility(shapeId,show)
end
