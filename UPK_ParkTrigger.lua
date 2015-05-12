-- by mor2000

--------------------
-- ParkTrigger


local UPK_ParkTrigger_mt = ClassUPK(UPK_ParkTrigger,UniversalProcessKit)
InitObjectClass(UPK_ParkTrigger, "UPK_ParkTrigger")
UniversalProcessKit.addModule("parktrigger",UPK_ParkTrigger)

function UPK_ParkTrigger:new(nodeId, parent)
	local self = UniversalProcessKit:new(nodeId, parent, UPK_ParkTrigger_mt)
	registerObjectClassName(self, "UPK_ParkTrigger")
	
	self.allowedVehicles={}
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] = getBoolFromUserAttribute(nodeId, "allowMotorized", true)
	
	self.allowWalker = false
	
	self:addTrigger()
	
	self:print('loaded ParkTrigger successfully')
	
	return self
end

function UPK_ParkTrigger:triggerUpdate(vehicle,isInTrigger)
	self:print('UPK_ParkTrigger:triggerUpdate('..tostring(vehicle)..', '..tostring(isInTrigger)..')')
	if self.isEnabled and vehicle~=nil then
		if isInTrigger then
			vehicle.nonTabbable = true
		elseif not SpecializationUtil.hasSpecialization(NonTabbable, vehicle.specializations) then
			vehicle.nonTabbable = nil
		end
	end
end

