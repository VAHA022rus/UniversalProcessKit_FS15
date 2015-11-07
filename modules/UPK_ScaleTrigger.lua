-- by mor2000

--------------------
-- ScaleTrigger

local UPK_ScaleTrigger_mt = ClassUPK(UPK_ScaleTrigger,UniversalProcessKit)
InitObjectClass(UPK_ScaleTrigger, "UPK_ScaleTrigger")
UniversalProcessKit.addModule("scaletrigger",UPK_ScaleTrigger)

function UPK_ScaleTrigger:new(nodeId, parent)
	printFn('UPK_ScaleTrigger:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId, parent, UPK_ScaleTrigger_mt)
	registerObjectClassName(self, "UPK_ScaleTrigger")
	
	-- actions
	
	self:getActionUserAttributes('OnScale')
	self:getActionUserAttributes('IfAboveMassLimit')
	self:getActionUserAttributes('IfBelowMassLimit')
	
	local fillTypeMass = UniversalProcessKit.fillTypeNameToInt['mass']
	self.actions['OnScale']['add']=__c({[fillTypeMass]=1})
	
	-- trigger
	
	self.allowedVehicles={}
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] = getBoolFromUserAttribute(nodeId, "allowMotorized", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_COMBINE] = getBoolFromUserAttribute(nodeId, "allowCombine", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_TIPPER] = getBoolFromUserAttribute(nodeId, "allowTipper", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SHOVEL] = getBoolFromUserAttribute(nodeId, "allowShovel", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_ATTACHMENT] = getBoolFromUserAttribute(nodeId, "allowAttachment", true)
	
	self.allowBales = Utils.getNoNil(self.allowBales, getBoolFromUserAttribute(self.nodeId, "allowBales", true))
	self.allowPallets = Utils.getNoNil(self.allowPallets, getBoolFromUserAttribute(self.nodeId, "allowPallets", true))
	self.allowWood = Utils.getNoNil(self.allowWood, getBoolFromUserAttribute(self.nodeId, "allowWood", true))
	
	self:addTrigger()
	
	self.allowWalker=true
	
	self:printFn('UPK_ScaleTrigger:new done')
	
	return self
end

function UPK_ScaleTrigger:triggerUpdate(vehicle,isInTrigger)
	self:printFn('UPK_ScaleTrigger:triggerUpdate(',vehicle,', ',isInTrigger,')')
	if self.isEnabled and self.isClient then
		if vehicle~=nil then
			local i3dNode = 0
			local mass = 0
			local typeV = type(vehicle)
			if typeV=="table" then
				if vehicle.rootNode~=nil then
					i3dNode = vehicle.rootNode
				else
					i3dNode = vehicle.nodeId
				end
			elseif typeV=="number" then
				i3dNode = vehicle
			end
			if i3dNode~=0 and entityExists(i3dNode) then
				mass = getMass(i3dNode)
			end
			self:printInfo('mass of vehicle is ',mass)
			-- not finished
		end
	end
end
