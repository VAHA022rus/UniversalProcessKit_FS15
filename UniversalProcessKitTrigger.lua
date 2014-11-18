-- by mor2000

--[[ TRIGGER FUNCTIONS BEGIN ]]--

-- use this function to handle trigger events (in your own class)
-- otherwise use self.entitiesInTrigger and self.entities in update()
function UniversalProcessKit:triggerUpdate(vehicle,isInTrigger)
end

function UniversalProcessKit:addTrigger()
	self.triggerId=self.nodeId
	self:getAllowedVehicles()
	self:fitCollisionMaskToAllowedVehicles()
	self.entities={}
	self.entitiesInTrigger=0
	self.playerInRange=false

	addTrigger(self.triggerId, "triggerCallback", self)
	self:triggerUpdate(nil,nil)
end

function UniversalProcessKit:removeTrigger()
	if self.triggerId~=nil and self.triggerId~=0 then
		removeTrigger(self.triggerId)
		self.triggerId = 0
		self.allowedVehicles={}
		self.entities={}
		self.entitiesInTrigger=0
		self.playerInRange=false
	end
end

function UniversalProcessKit:getAllowedVehicles()
	if self.allowedVehicles==nil then
		self.allowedVehicles={}
	end
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] = getBoolFromUserAttribute(self.nodeId, "allowMotorized", self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED])
	self.allowedVehicles[UniversalProcessKit.VEHICLE_COMBINE] = getBoolFromUserAttribute(self.nodeId, "allowCombine", self.allowedVehicles[UniversalProcessKit.VEHICLE_COMBINE])
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FILLABLE] = getBoolFromUserAttribute(self.nodeId, "allowFillable", self.allowedVehicles[UniversalProcessKit.VEHICLE_FILLABLE])
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_TIPPER] = getBoolFromUserAttribute(self.nodeId, "allowTipper", self.allowedVehicles[UniversalProcessKit.VEHICLE_TIPPER])
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SHOVEL] = getBoolFromUserAttribute(self.nodeId, "allowShovel", self.allowedVehicles[UniversalProcessKit.VEHICLE_SHOVEL])

	self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER] = getBoolFromUserAttribute(self.nodeId, "allowWaterTrailer", self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER])
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER] = getBoolFromUserAttribute(self.nodeId, "allowFuelTrailer", self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER])
	self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER] = getBoolFromUserAttribute(self.nodeId, "allowLiquidManureTrailer", self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER])
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRAILER] = getBoolFromUserAttribute(self.nodeId, "allowMilkTrailer", self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRAILER])
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SOWINGMACHINE] = getBoolFromUserAttribute(self.nodeId, "allowSowingMachine", self.allowedVehicles[UniversalProcessKit.VEHICLE_SOWINGMACHINE])
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SPRAYER] = getBoolFromUserAttribute(self.nodeId, "allowSprayer", self.allowedVehicles[UniversalProcessKit.VEHICLE_SPRAYER])
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FORAGEWAGON] = getBoolFromUserAttribute(self.nodeId, "allowForageWagon", self.allowedVehicles[UniversalProcessKit.VEHICLE_FORAGEWAGON])
	self.allowedVehicles[UniversalProcessKit.VEHICLE_BALER] = getBoolFromUserAttribute(self.nodeId, "allowBaler", self.allowedVehicles[UniversalProcessKit.VEHICLE_BALER])
	
	self.allowWalker = getBoolFromUserAttribute(self.nodeId, "allowWalker", self.allowWalker)
end

function UniversalProcessKit:fitCollisionMaskToAllowedVehicles()
	-- taking care of correct collisionMask
	-- http://gdn.giants-software.com/thread.php?categoryId=16&threadId=677
	-- player = 2^20 = 1048576
	-- tractors = 2^21 = 2097152
	-- combines = 2^22 = 4194304
	-- fillables = 2^23 = 8388608
	-- all = 15728640

	local trigger_player = 1048576
	local trigger_tractor = 2097152
	local trigger_combine = 4194304
	local trigger_fillable = 8388608

	local collisionMask_old = getCollisionMask(self.triggerId)
	local collisionMask_new = collisionMask_old
	if self.allowWalker and bitAND(collisionMask_new,trigger_player)==0 then
		self:print('Warning: allowWalker is set to true but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new + trigger_player
	end
	if self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] and bitAND(collisionMask_new,trigger_tractor)==0 then
		self:print('Warning: allowMotorized is set to true but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new + trigger_tractor
	end
	if self.allowedVehicles[UniversalProcessKit.VEHICLE_COMBINE] and bitAND(collisionMask_new,trigger_combine)==0 then
		self:print('Warning: allowCombine is set to true but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new + trigger_combine
	end
	if (self.allowedVehicles[UniversalProcessKit.VEHICLE_FILLABLE] or -- check every fillable type
		self.allowedVehicles[UniversalProcessKit.VEHICLE_TIPPER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_SHOVEL] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRAILER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_SOWINGMACHINE] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_SPRAYER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_FORAGEWAGON] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_BALER]) and bitAND(collisionMask_new,trigger_fillable)==0 then
		self:print('Warning: some kind of allowFillable is set to true but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new + trigger_fillable
	end
	if collisionMask_new ~= collisionMask_old then
		self:print('Notice: set collisionMask according to allowed vehicles to '..tostring(collisionMask_new)..' (you may want to fix that)')
		setCollisionMask(self.triggerId,collisionMask_new)
	end
end

function UniversalProcessKit:triggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if self.isEnabled then
		local vehicle=g_currentMission.objectToTrailer[otherShapeId] or g_currentMission.nodeToVehicle[otherShapeId]
		if vehicle~=nil then
			for k,v in pairs(UniversalProcessKit.getVehicleTypes(vehicle)) do
				if v and self.allowedVehicles[k] then
					if onEnter then
						self:triggerOnEnter(vehicle)
					else
						self:triggerOnLeave(vehicle)
					end
					break
				end
			end
		end
		if self.allowWalker and g_currentMission.player ~= nil and otherActorId == g_currentMission.player.rootNode then
			if onEnter then
				self:triggerOnEnter(nil, true)
			else
				self:triggerOnLeave(nil, true)
			end
		end
	end
end

function UniversalProcessKit:triggerOnEnter(vehicle, player)
	if vehicle~=nil then
		local networkId=networkGetObjectId(vehicle)
		if networkId~=nil and networkId~=0 then
			self.entities[networkId]=vehicle
		end
	end
	self.entitiesInTrigger=length(self.entities)
	if player==true then
		self.playerInRange = true
		self.entitiesInTrigger=self.entitiesInTrigger+1
	end
	self:triggerUpdate(vehicle,true)
end;

function UniversalProcessKit:triggerOnLeave(vehicle, player)
	if vehicle~=nil then
		local networkId=networkGetObjectId(vehicle)
		if networkId~=nil and networkId~=0 then
			self.entities[networkId]=nil
		end
	end
	self.entitiesInTrigger=length(self.entities)
	if player==true then
		self.playerInRange = false
	end
	self:triggerUpdate(vehicle,false)
end;

function UniversalProcessKit:getShowInfo()
	if self.playerInRange then
		return g_currentMission.controlPlayer or false
	else
		for k,v in pairs(self.entities) do
			if v:getIsActiveForInput() then
				return true
			end
		end
	end
	return false
end

--[[ TRIGGER FUNCTIONS END ]]--