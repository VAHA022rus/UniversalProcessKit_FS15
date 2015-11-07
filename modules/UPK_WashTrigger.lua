-- by mor2000

--------------------
-- EntityTrigger (enables modules if vehicle or walker is present)


local UPK_WashTrigger_mt = ClassUPK(UPK_WashTrigger,UniversalProcessKit)
InitObjectClass(UPK_WashTrigger, "UPK_WashTrigger")
UniversalProcessKit.addModule("washtrigger",UPK_WashTrigger)

function UPK_WashTrigger:new(nodeId, parent)
	printFn('UPK_WashTrigger:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId, parent, UPK_WashTrigger_mt)
	registerObjectClassName(self, "UPK_WashTrigger")
	
	self.washPerSecond = getNumberFromUserAttribute(nodeId, "washPerSecond", 0.05)
	self.dirtThreshold = getNumberFromUserAttribute(nodeId, "dirtThreshold", 0.05, 0, 1)
	
	self.pricePerSecond = getNumberFromUserAttribute(nodeId, "pricePerSecond", 0)
	self.pricePerSecondMultiplier = getVectorFromUserAttribute(nodeId, "pricePerSecondMultiplier", "1 1 1")
	
	-- statName
	
	self.statName=getStatNameFromUserAttribute(nodeId)
	
	-- if washing
	
	self.enableChildrenIfWashing = getBoolFromUserAttribute(nodeId, "enableChildrenIfWashing", false)
	self.disableChildrenIfWashing = getBoolFromUserAttribute(nodeId, "disableChildrenIfWashing", false)
	
	if self.enableChildrenIfWashing then
		self.disableChildrenIfWashing = false
	end
	
	-- if not washing
	
	self.enableChildrenIfNotWashing = getBoolFromUserAttribute(nodeId, "enableChildrenIfNotWashing", false)
	self.disableChildrenIfNotWashing = getBoolFromUserAttribute(nodeId, "disableChildrenIfNotWashing", false)
	
	if self.enableChildrenIfNotWashing then
		self.disableChildrenIfNotWashing = false
	end
	
	self.allowedVehicles={}
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] = getBoolFromUserAttribute(nodeId, "allowMotorized", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_COMBINE] = getBoolFromUserAttribute(nodeId, "allowCombine", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_TIPPER] = getBoolFromUserAttribute(nodeId, "allowTipper", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SHOVEL] = getBoolFromUserAttribute(nodeId, "allowShovel", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FILLABLE] = getBoolFromUserAttribute(nodeId, "allowShovel", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_ATTACHMENT] = getBoolFromUserAttribute(nodeId, "allowAttachment", true)
	
	self.allowWalker = getBoolFromUserAttribute(nodeId, "allowWalker", false)
	
	self:addTrigger()
	
	self:printFn('UPK_WashTrigger:new done')
	
	return self
end

function UPK_WashTrigger:postLoad()
	self:printFn('UPK_WashTrigger:postLoad()')
	UPK_WashTrigger:superClass().postLoad(self)
	self:triggerUpdate(false,false)
	self:update(30)
end

function UPK_WashTrigger:triggerUpdate(vehicle,isInTrigger)
	self:printFn('UPK_WashTrigger:triggerUpdate(',vehicle,', ',isInTrigger,')')
	if self.isEnabled and self.washPerSecond~=0 then
		for k,v in pairs(self.allowedVehicles) do
			if v and UniversalProcessKit.isVehicleType(vehicle, k) then
				if isInTrigger then
					--self.amountToFillOfVehicle[vehicle]=0
					--self:print('UniversalProcessKitListener.addUpdateable('..tostring(self)..')')
					UniversalProcessKitListener.addUpdateable(self)
				else
					--self.amountToFillOfVehicle[vehicle]=nil
				end
			end
		end
	end
end

function UPK_WashTrigger:update(dt)
	self:printAll('UPK_WashTrigger:update(',dt,')')
	
	if self.entitiesInTrigger==0 then
		if self.isServer then
			if self.enableChildrenIfNotWashing then
				self:enableChildren(true)
			elseif self.disableChildrenIfNotWashing then
				self:enableChildren(false)
			end
		end
		UniversalProcessKitListener.removeUpdateable(self)
		return
	end
	
	if self.isEnabled and self.washPerSecond~=0 then
		local dirtToRemove = self.washPerSecond/1000 * dt
		local dirtRemoved = 0
		
		for _,vehicle in pairs(self.vehicles) do
			if vehicle.dirtAmount~=nil and vehicle.setDirtAmount~=nil then
				if self.washPerSecond>0 and vehicle.dirtAmount>self.dirtThreshold then
					--self:print('dirt Amount: '..tostring(vehicle.dirtAmount))
					local dirtRemovedVehicle = mathmin(vehicle.dirtAmount, dirtToRemove)
					dirtRemoved = mathmax(dirtRemoved, dirtRemovedVehicle)
					vehicle:setDirtAmount(vehicle.dirtAmount - dirtRemovedVehicle)
				elseif self.washPerSecond<0 and vehicle.dirtAmount<self.dirtThreshold then
					local dirtAddedVehicle = mathmin(self.dirtThreshold-vehicle.dirtAmount,-dirtToRemove)
					dirtRemoved = mathmax(dirtRemoved, dirtAddedVehicle)
				 	vehicle:setDirtAmount(vehicle.dirtAmount + dirtAddedVehicle)
				end
			end
		end
		
		if round(dirtRemoved,8)==0 then
			if self.isServer then
				if self.enableChildrenIfNotWashing then
					self:enableChildren(true)
				elseif self.disableChildrenIfNotWashing then
					self:enableChildren(false)
				end
			end
		else
			if self.isServer then
				if self.pricePerSecond>0 then
					local difficulty = g_currentMission.missionStats.difficulty
					local pricePerSecondAdjustment = self.pricePerSecondMultiplier[difficulty]
					local price = (self.pricePerSecond/1000 * dt) * pricePerSecondAdjustment
					g_currentMission:addSharedMoney(-price, self.statName)
				end
				
				if self.enableChildrenIfWashing then
					self:enableChildren(true)
				elseif self.disableChildrenIfWashing then
					self:enableChildren(false)
				end
			end
		end
	end
end
