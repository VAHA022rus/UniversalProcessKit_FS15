-- by mor2000

PlaceableUPK_mt = Class(PlaceableUPK, Placeable)
InitObjectClass(PlaceableUPK, "PlaceableUPK")

function PlaceableUPK:new(isServer, isClient, customMt)
	local self = Placeable:new(isServer, isClient, customMt or PlaceableUPK_mt)
	registerObjectClassName(self, "PlaceableUPK")
	self.isServer=isServer
	self.isClient=isClient
	return self
end

function PlaceableUPK:load(xmlFilename, x, y, z, rx, ry, rz, moveMode, initRandom)
    if not PlaceableUPK:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, moveMode, initRandom) then
		return false
    end

	if not moveMode and self.nodeId~=nil then
		self.base=UPK_Base:new(self.nodeId,true)
		if self.base~=false then
			self.base:findChildren(self.nodeId)
		else
			return false
		end
	end -- not moveMode

	return true
end

function PlaceableUPK:delete()
	if self.base~=nil and self.base~=false then
		self.base:delete()
	end
	PlaceableUPK:superClass().delete(self)
end

function PlaceableUPK:readStream(streamId, connection)
	PlaceableUPK:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		if self.base~=nil then
			self.base:readStream(streamId, connection)
		end
	end
end

function PlaceableUPK:writeStream(streamId, connection)
	PlaceableUPK:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		if self.base~=nil then
			self.base:writeStream(streamId, connection)
		end
	end
end

function PlaceableUPK:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
	if not PlaceableUPK:superClass().loadFromAttributesAndNodes(self, xmlFile, key, resetVehicles) then
		return false
	end
	
	if self.base~=nil then
		self.base:loadFromAttributesAndNodes(xmlFile, key)
	end
	
	return true
end

function PlaceableUPK:getSaveAttributesAndNodes(nodeIdent)
	local attributes, nodes = PlaceableUPK:superClass().getSaveAttributesAndNodes(self, nodeIdent)

	if self.base~=nil then
		local baseAttributes, baseNodes=self.base:getSaveAttributesAndNodes(nodeIdent)
		attributes=attributes .. baseAttributes
		nodes=nodes .. baseNodes
	end
	
	return attributes, nodes
end