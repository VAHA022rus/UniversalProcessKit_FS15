-- by mor2000

OnCreateUPK_mt = Class(OnCreateUPK, Object)
InitObjectClass(OnCreateUPK, "OnCreateUPK")

function OnCreateUPK:new(isServer, isClient)
	local self = Object:new(isServer, isClient, OnCreateUPK_mt)
	registerObjectClassName(self, "OnCreateUPK")
	self.isServer=isServer
	self.isClient=isClient
	self.builtIn=true
	return self
end

function OnCreateUPK:load(id)
	print('OnCreateUPK:load('..tostring(id)..')')
	
	if id==nil then
		return false
	end
	
	self.nodeId=id
	
	self.base=UPK_Base:new(self.nodeId,true)
	if self.base~=false then
		self.base:findChildren(self.nodeId)
	end
	
	g_currentMission:addNodeObject(self.nodeId, self);
	g_currentMission:addOnCreateLoadedObjectToSave(self);
	
	return true
end

function OnCreateUPK:delete()
	if self.base~=nil then
		self.base:delete()
	end
	OnCreateUPK:superClass().delete(self)
end

function OnCreateUPK:readStream(streamId, connection)
	OnCreateUPK:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		if self.base~=nil then
			self.base:readStream(streamId, connection)
		end
	end
end

function OnCreateUPK:writeStream(streamId, connection)
	OnCreateUPK:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		if self.base~=nil then
			self.base:writeStream(streamId, connection)
		end
	end
end

function OnCreateUPK:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
	print('OnCreateUPK:loadFromAttributesAndNodes()')
	if self.base~=nil then
		self.base:loadFromAttributesAndNodes(xmlFile, key)
	end
	
	return true
end

function OnCreateUPK:getSaveAttributesAndNodes(nodeIdent)
	print('OnCreateUPK:getSaveAttributesAndNodes('..tostring(nodeIdent)..')')
	local attributes=""
	local nodes=""
	
	if self.base~=nil then
		local baseAttributes, baseNodes=self.base:getSaveAttributesAndNodes(nodeIdent)
		attributes=attributes .. baseAttributes
		nodes=nodes .. baseNodes
	end
	
	return attributes, nodes
end