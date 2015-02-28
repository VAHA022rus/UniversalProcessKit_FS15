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
	self.entityDistances={}
	self.entitiesInTrigger=0
	self.playerInRange=false
	self.playersInRange={}
	self.playerInRangeNetworkNode = false
	self.triggerTracker = UniversalProcessKitTriggerTracker:new(self)

	addTrigger(self.triggerId, "triggerCallback", self)
	table.insert(g_upkTrigger, self)
	self:triggerUpdate(nil,true)
	self:triggerUpdate(nil,false)
end

function UniversalProcessKit:removeTrigger()
	if self.triggerId~=nil and self.triggerId~=0 then
		self.triggerTracker:delete()
		removeValueFromTable(g_upkTrigger, self)
		removeTrigger(self.triggerId)
		self.triggerId = 0
		self.allowedVehicles=nil
		self.entities={}
		self.entitiesInTrigger=0
		self.playerInRange=false
		self.playersInRange={}
	end
end

function UniversalProcessKit:getAllowedVehicles()
	if self.allowedVehicles==nil then
		self.allowedVehicles={}
		self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED]=true
		self.allowedVehicles[UniversalProcessKit.VEHICLE_FILLABLE]=true
		self.allowedVehicles[UniversalProcessKit.VEHICLE_COMBINE]=true
		self.allowedVehicles[UniversalProcessKit.VEHICLE_MIXERWAGONTRAILER]=true
		self.allowedVehicles[UniversalProcessKit.VEHICLE_ATTACHMENT] = true
	end
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] = getBoolFromUserAttribute(self.nodeId, "allowMotorized", self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED])
	self.allowedVehicles[UniversalProcessKit.VEHICLE_COMBINE] = getBoolFromUserAttribute(self.nodeId, "allowCombine", self.allowedVehicles[UniversalProcessKit.VEHICLE_COMBINE])
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FILLABLE] = getBoolFromUserAttribute(self.nodeId, "allowFillable", self.allowedVehicles[UniversalProcessKit.VEHICLE_FILLABLE])
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_ATTACHMENT] = getBoolFromUserAttribute(self.nodeId, "allowAttachment", self.allowedVehicles[UniversalProcessKit.VEHICLE_ATTACHMENT])
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_TIPPER] = getBoolFromUserAttribute(self.nodeId, "allowTipper", self.allowedVehicles[UniversalProcessKit.VEHICLE_TIPPER])
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SHOVEL] = getBoolFromUserAttribute(self.nodeId, "allowShovel", self.allowedVehicles[UniversalProcessKit.VEHICLE_SHOVEL])
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER] = getBoolFromUserAttribute(self.nodeId, "allowWaterTrailer", self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER])
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER] = getBoolFromUserAttribute(self.nodeId, "allowFuelTrailer", self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER])
	self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER] = getBoolFromUserAttribute(self.nodeId, "allowLiquidManureTrailer", self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER])
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRAILER] = getBoolFromUserAttribute(self.nodeId, "allowMilkTrailer", self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRAILER])
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SOWINGMACHINE] = getBoolFromUserAttribute(self.nodeId, "allowSowingMachine", self.allowedVehicles[UniversalProcessKit.VEHICLE_SOWINGMACHINE])
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SPRAYER] = getBoolFromUserAttribute(self.nodeId, "allowSprayer", self.allowedVehicles[UniversalProcessKit.VEHICLE_SPRAYER])
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MANURESPREADER] = getBoolFromUserAttribute(self.nodeId, "allowManureSpreader", self.allowedVehicles[UniversalProcessKit.VEHICLE_MANURESPREADER])
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FORAGEWAGON] = getBoolFromUserAttribute(self.nodeId, "allowForageWagon", self.allowedVehicles[UniversalProcessKit.VEHICLE_FORAGEWAGON])
	self.allowedVehicles[UniversalProcessKit.VEHICLE_BALER] = getBoolFromUserAttribute(self.nodeId, "allowBaler", self.allowedVehicles[UniversalProcessKit.VEHICLE_BALER])
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_TRAFFICVEHICLE] = getBoolFromUserAttribute(self.nodeId, "allowTrafficVehicle", self.allowedVehicles[UniversalProcessKit.VEHICLE_TRAFFICVEHICLE])
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRUCK] = getBoolFromUserAttribute(self.nodeId, "allowMilktruck", self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRUCK])
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MIXERWAGONPICKUP] = getBoolFromUserAttribute(self.nodeId, "allowMixerWagonPickup", self.allowedVehicles[UniversalProcessKit.VEHICLE_MIXERWAGONPICKUP])
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MIXERWAGONTRAILER] = getBoolFromUserAttribute(self.nodeId, "allowMixerWagonTrailer", self.allowedVehicles[UniversalProcessKit.VEHICLE_MIXERWAGONTRAILER])
	
	self.allowVehicle = self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_COMBINE]

	self.allowAttachment = self.allowedVehicles[UniversalProcessKit.VEHICLE_ATTACHMENT]
	
	self.allowSomeTrailer = (self.allowedVehicles[UniversalProcessKit.VEHICLE_FILLABLE] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_TIPPER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRAILER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_SOWINGMACHINE] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_SPRAYER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_FORAGEWAGON] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_MIXERWAGONTRAILER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_BALER])
	
	self.allowShovel = self.allowedVehicles[UniversalProcessKit.VEHICLE_SHOVEL] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_MIXERWAGONPICKUP]

	self.allowWalker = Utils.getNoNil(self.allowWalker, getBoolFromUserAttribute(self.nodeId, "allowWalker", true))
	
	self.allowBales = Utils.getNoNil(self.allowBales, getBoolFromUserAttribute(self.nodeId, "allowBales", false))
	self.allowPallets = Utils.getNoNil(self.allowPallets, getBoolFromUserAttribute(self.nodeId, "allowPallets", false))
	self.allowWood = Utils.getNoNil(self.allowWood, getBoolFromUserAttribute(self.nodeId, "allowWood", false))
	
	self.allowSomeDynamicObject = (self.allowBales or self.allowPallets)
	
	for k,v in pairs(self.allowedVehicles) do
		if not v then
			self.allowedVehicles[k]=nil
		end
	end
end

function UniversalProcessKit:fitCollisionMaskToAllowedVehicles()
	-- taking care of correct collisionMask
	-- http://gdn.giants-software.com/thread.php?categoryId=16&threadId=677
	-- player = 2^20 = 1048576
	-- tractors = 2^21 = 2097152
	-- combines = 2^22 = 4194304
	-- fillables = 2^23 = 8388608
	-- sum is 15728640
	-- dynamic_objects = 2^24 = 16777216  bales, pallets, trees
	-- trafficVehicles = 2^25 = 33554432 
	-- cutters = 2^26 = 67108864 whats that?

	

	local trigger_player = 1048576
	local trigger_tractor = 2097152
	local trigger_combine = 4194304
	local trigger_fillable = 8388608
	local trigger_dynamic_objects = 16777216 -- bales, pallets
	local trigger_attachment = 8192 -- cultivators, tedders, ...
	local trigger_trafficVehicle = 33554432 -- doesnt seem to work right

	local collisionMask_old = getCollisionMask(self.triggerId)
	local collisionMask_new = collisionMask_old
	
	-- add colision mask bits if necessary
	
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
		self.allowedVehicles[UniversalProcessKit.VEHICLE_MIXERWAGONTRAILER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_MIXERWAGONPICKUP] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_BALER]) and bitAND(collisionMask_new,trigger_fillable)==0 then
		self:print('Warning: allowFillable is set to true but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new + trigger_fillable
	end
	if self.allowedVehicles[UniversalProcessKit.VEHICLE_ATTACHMENT] and bitAND(collisionMask_new,trigger_attachment)==0 then
		self:print('Warning: allowAttachment is set to true but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new + trigger_attachment
	end
	if (self.allowedVehicles[UniversalProcessKit.VEHICLE_TRAFFICVEHICLE] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRUCK]) and bitAND(collisionMask_new,trigger_trafficVehicle)==0 then
		self:print('Warning: allowTrafficVehicle is set to true but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new + trigger_trafficVehicle
	end
	if (self.allowBales or self.allowPallets or self.allowWood) and bitAND(collisionMask_new,trigger_dynamic_objects)==0 then
		self:print('Warning: allowBales or allowPallets or allowWood is set to true but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new + trigger_dynamic_objects
	end
	
	-- substract colision mask bits if necessary
	
	if not self.allowWalker and bitAND(collisionMask_new,trigger_player)==1 then
		self:print('Warning: allowWalker is set to false but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new - trigger_player
	end
	if not self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] and bitAND(collisionMask_new,trigger_tractor)==1 then
		self:print('Warning: allowMotorized is set to false but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new - trigger_tractor
	end
	if not self.allowedVehicles[UniversalProcessKit.VEHICLE_COMBINE] and bitAND(collisionMask_new,trigger_combine)==1 then
		self:print('Warning: allowCombine is set to false but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new - trigger_combine
	end
	if (not (self.allowedVehicles[UniversalProcessKit.VEHICLE_FILLABLE] or -- check every fillable type
		self.allowedVehicles[UniversalProcessKit.VEHICLE_TIPPER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_SHOVEL] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRAILER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_SOWINGMACHINE] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_SPRAYER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_FORAGEWAGON] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_MIXERWAGONTRAILER] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_MIXERWAGONPICKUP] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_BALER]) and bitAND(collisionMask_new,trigger_fillable)==1) then
		self:print('Warning: allowFillable is set to false but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new - trigger_fillable
	end
	if not self.allowedVehicles[UniversalProcessKit.VEHICLE_ATTACHMENT] and bitAND(collisionMask_new,trigger_attachment)==1 then
		self:print('Warning: allowAttachment is set to false but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new - trigger_attachment
	end
	if not (self.allowedVehicles[UniversalProcessKit.VEHICLE_TRAFFICVEHICLE] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRUCK]) and bitAND(collisionMask_new,trigger_trafficVehicle)==1 then
		self:print('Warning: allowTrafficVehicle is set to false but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new - trigger_trafficVehicle
	end
	if not (self.allowBales or self.allowPallets or self.allowWood) and bitAND(collisionMask_new,trigger_dynamic_objects)==1 then
		self:print('Warning: allowBales and allowPallets or allowWood is set to false but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new - trigger_dynamic_objects
	end
	
	-- result
	
	if collisionMask_new ~= collisionMask_old then
		self:print('Warning: set collisionMask according to allowed vehicles to '..tostring(collisionMask_new)..' (you may want to fix that)')
		setCollisionMask(self.triggerId,collisionMask_new)
	end
end

function UniversalProcessKit:triggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	self:print('=======')
	self:print('otherShapeId: '..tostring(otherShapeId)..', otherActorId: '..tostring(otherActorId))
	
	local vehicle
	
	self:print('onEnter '..tostring(onEnter))
	self:print('onLeave '..tostring(onLeave))
	-- self:print('onStay '..tostring(onStay))
	
	if self.allowVehicle or self.allowAttachment or self.allowSomeTrailer or self.allowShovel then
		if self.allowVehicle then
			vehicle = g_currentMission.nodeToVehicle[otherActorId]
			self:print('vehicle found? '..tostring(vehicle))
		elseif self.allowAttachment then
			vehicle = g_currentMission.nodeObjects[otherActorId]
			self:print('attachment found? '..tostring(vehicle))
		elseif self.allowSomeTrailer then
			vehicle = g_currentMission.objectToTrailer[otherShapeId]
			self:print('trailer found? '..tostring(vehicle))
		elseif self.allowShovel then
			vehicle = g_currentMission.nodeToVehicle[otherActorId]
			self:print('shovel found? '..tostring(vehicle))
		end
		if vehicle~=nil then
			if vehicle.upkShapesInTrigger == nil then
				vehicle.upkShapesInTrigger = {}
			end
			if vehicle.upkShapesInTrigger[self] == nil then
				vehicle.upkShapesInTrigger[self] = {}
			end
			for k,v in pairs(UniversalProcessKit.getVehicleTypes(vehicle)) do
				if v and self.allowedVehicles[k] then
					if onEnter then
						vehicle.upkShapesInTrigger[self][otherShapeId]=true
					else
						vehicle.upkShapesInTrigger[self][otherShapeId]=nil
					end
					
					local shapesInTrigger = length(vehicle.upkShapesInTrigger[self])
					self:print('shapes of '..tostring(vehicle)..' in trigger: '..tostring(shapesInTrigger))
					
					if onEnter and shapesInTrigger>0 then
						if vehicle.upkTrigger == nil then
							vehicle.upkTrigger={}
						end
						if not isInTable(vehicle.upkTrigger,self) then
							table.insert(vehicle.upkTrigger,self)
						end
						self:print('vehicle entered: '..tostring(vehicle))
						self:triggerOnEnter(vehicle)
					elseif shapesInTrigger==0 then
						removeValueFromTable(vehicle.upkTrigger,self)
						self:print('vehicle left: '..tostring(vehicle))
						self:triggerOnLeave(vehicle)
					end
				end
			end
		end
	end
	
	if self.allowSomeDynamicObject then
		vehicle = g_currentMission.nodeObjects[otherShapeId] or
					g_currentMission.nodeObjects[otherActorId]
		self:print('pallet/bale found? '..tostring(vehicle))
		
		if vehicle~=nil then
			if self.allowPallets then
				if vehicle.isPallet==nil then
					local shapeId = otherActorId or otherShapeId
					if shapeId~=nil then
						vehicle.isPallet = getUserAttribute(shapeId, "isPallet")
					end
					if vehicle.isPallet==nil then
						vehicle.isPallet = vehicle:isa(FillablePallet)
					end
				end
				if vehicle.isPallet then
					self:print('thingy is a pallet 1')
					if onEnter then
						self:triggerOnEnter(vehicle)
					elseif onLeave then
						self:triggerOnLeave(vehicle)
					end
				end
			end
		
			if self.allowBales then
				if vehicle:isa(Bale) then
					if onEnter then
						self:triggerOnEnter(vehicle)
					elseif onLeave then
						self:triggerOnLeave(vehicle)
					end
				end
			end
		end
	end
	
	if self.allowWood then
		vehicle = g_currentMission.nodeObjects[otherShapeId] or
					g_currentMission.nodeObjects[otherActorId]
		self:print('wood found? '..tostring(vehicle))
		
		if vehicle~=nil then
			local splitType = SplitUtil.splitTypes[getSplitType(otherActorId)]
			if splitType ~= nil then
				self:print('splitType '..tostring(splitType))
			end
		end
	end

	if self.allowWalker and g_currentMission.player ~= nil and otherActorId == g_currentMission.player.rootNode then
		if onEnter then
			self.playerInRangeNetworkNode = true
			self:triggerOnEnter(nil, true)
		elseif onLeave then
			self.playerInRangeNetworkNode = false
			self:triggerOnLeave(nil, true)
		end
	end
end

function UniversalProcessKit:triggerOnEnter(vehicle, player, alreadySent)
	self:print('UniversalProcessKit:triggerOnEnter('..tostring(vehicle)..', '..tostring(player)..', '..tostring(alreadySent))
	if vehicle~=nil then
		if not isInTable(self.entities, vehicle) then
			local networkId=networkGetObjectId(vehicle)
			if networkId~=nil and networkId~=0 then
				self.entities[networkId]=vehicle
			end
		end
	end
	self.entitiesInTrigger=length(self.entities)
	if player==true and not self.playerInRange then
		self.playerInRange = true
		self.entitiesInTrigger=self.entitiesInTrigger+1
		if not alreadySent then
			self:print('UniversalProcessKitTriggerPlayerEvent.sendEvent(self, true, alreadySent)')
			UniversalProcessKitTriggerPlayerEvent.sendEvent(self, true, alreadySent)
		end
	end
	if self.entitiesInTrigger>0 then
		UniversalProcessKitListener.addUpdateable(self.triggerTracker)
	end
	if self.isEnabled then
		self:triggerUpdate(vehicle,true)
	end
end;

function UniversalProcessKit:triggerOnLeave(vehicle, player, alreadySent)
	self:print('UniversalProcessKit:triggerOnLeave('..tostring(vehicle)..', '..tostring(player)..', '..tostring(alreadySent))

	if vehicle~=nil then
		--print('isInTable(self.entities, vehicle) is '..tostring(isInTable(self.entities, vehicle)))
		local valrem = removeValueFromTable(self.entities,vehicle)
		--print('removing vehicle at '..tostring(valrem))
		self.entityDistances[vehicle]=nil
		--print('isInTable(self.entities, vehicle) is '..tostring(isInTable(self.entities, vehicle)))
		vehicle.upkShapesInTrigger[self]={}
	end
	self.entitiesInTrigger=length(self.entities)
	if player==true and self.playerInRange then
		self.playerInRange = false
		if not alreadySent then
			self:print('UniversalProcessKitTriggerPlayerEvent.sendEvent(self, false, alreadySent)')
			UniversalProcessKitTriggerPlayerEvent.sendEvent(self, false, alreadySent)
		end
	end
	if self.playerInRange then
		self.entitiesInTrigger = self.entitiesInTrigger + 1
	end
	if self.entitiesInTrigger<=0 then
		UniversalProcessKitListener.removeUpdateable(self.triggerTracker)
	end
	if self.isEnabled then
		self:triggerUpdate(vehicle,false)
	end
end;

function UniversalProcessKit:getShowInfo()
	if self.playerInRangeNetworkNode then
		return g_currentMission.controlPlayer or false
	else
		for k,v in pairs(self.entities) do
			if v.isEntered or v:getIsActiveForInput(false) then
				return true
			end
		end
	end
	return false
end

function UniversalProcessKit:onVehicleDeleted(vehicle)
end

-- UniversalProcessKitTriggerTracker

UniversalProcessKitTriggerTracker = {}
UniversalProcessKitTriggerTracker_mt = { __index=UniversalProcessKitTriggerTracker }

function UniversalProcessKitTriggerTracker:new(upkmodule)
	local self = {}
	setmetatable(self,UniversalProcessKitTriggerTracker_mt)
	self.upkmodule = upkmodule
	return self
end

function UniversalProcessKitTriggerTracker:update(dt)
	if type(self.upkmodule.entities) == "table" and self.upkmodule.entitiesInTrigger>0 then
		local wx, wy, wz = getWorldTranslation(self.upkmodule.nodeId)
		for _, vehicle in pairs(self.upkmodule.entities) do
			if vehicle.components[1]~=nil then
				local node = vehicle.rootNode --components[1].node
				local vehicle_test = g_currentMission.nodeToVehicle[node] or
								g_currentMission.objectToTrailer[node] or
								g_currentMission.nodeObjects[node]
				if vehicle_test~=nil then
					local vx, vy, vz = getWorldTranslation(node)
					if vx~=nil and vy~=nil and vz~=nil then
						local distance=Utils.vector3Length(wx-vx,wy-vy,wz-vz)
						if self.upkmodule.entityDistances[vehicle]~=nil then
							if mathabs(self.upkmodule.entityDistances[vehicle] - distance) > 5 then
								print('vehicle got too far away')
								self.upkmodule:triggerOnLeave(vehicle)
							end
						end
						self.upkmodule.entityDistances[vehicle] = distance
					end
				else
					print('vehicle doesnt exists anymore')
					self.upkmodule:triggerOnLeave(vehicle)
				end
			end
		end
		if self.upkmodule.playerInRangeNetworkNode == true and not g_currentMission.controlPlayer then
			print('player doesnt exists anymore')
			self.upkmodule.playerInRangeNetworkNode = false
			self.upkmodule.playerDistance = nil
			self.upkmodule:triggerOnLeave(nil,true)
		elseif self.upkmodule.playerInRangeNetworkNode == true then
			local vx, vy, vz = getWorldTranslation(g_currentMission.player.rootNode)
			local distance=Utils.vector3Length(wx-vx,wy-vy,wz-vz)
			if self.upkmodule.playerDistance~=nil then
				if mathabs(self.upkmodule.playerDistance - distance) > 5 then
					print('player got too far away')
					self.upkmodule.playerInRangeNetworkNode = false
					self.upkmodule.playerDistance = nil
					self.upkmodule:triggerOnLeave(nil, true)
				end
			end
			self.upkmodule.playerDistance = distance
		end
	end
end

function UniversalProcessKitTriggerTracker:delete()
	UniversalProcessKitListener.removeUpdateable(self)
end

-- UniversalProcessKitTriggerPlayerEvent

UniversalProcessKitTriggerPlayerEvent = {}
UniversalProcessKitTriggerPlayerEvent_mt = Class(UniversalProcessKitTriggerPlayerEvent, Event);
InitEventClass(UniversalProcessKitTriggerPlayerEvent, "UniversalProcessKitTriggerPlayerEvent");

function UniversalProcessKitTriggerPlayerEvent:emptyNew()
    local self = Event:new(UniversalProcessKitTriggerPlayerEvent_mt)
    return self
end

function UniversalProcessKitTriggerPlayerEvent:new(upkmodule, isPlayerInside)
	local self = UniversalProcessKitTriggerPlayerEvent:emptyNew()
	self.upkmodule = upkmodule
	self.isPlayerInside = isPlayerInside
	return self
end

function UniversalProcessKitTriggerPlayerEvent:writeStream(streamId, connection)
	local syncObj = self.upkmodule.syncObj
	local syncObjId = networkGetObjectId(syncObj)
	print('syncObjId: '..tostring(syncObjId))
	streamWriteInt32(streamId, syncObjId)
	local syncId = self.upkmodule.syncId
	print('syncId: '..tostring(syncId))
	streamWriteInt32(streamId, syncId)
	print('isPlayerInside: '..tostring(self.isPlayerInside))
	streamWriteBool(streamId, self.isPlayerInside)
end

function UniversalProcessKitTriggerPlayerEvent:readStream(streamId, connection)
	local syncObjId = streamReadInt32(streamId)
	print('syncObjId: '..tostring(syncObjId))
	local syncObj = networkGetObject(syncObjId)
	local syncId = streamReadInt32(streamId)
	print('syncId: '..tostring(syncId))
	self.upkmodule=syncObj:getObjectToSync(syncId)
	print('upkmodule: '..tostring(self.upkmodule))
	self.isPlayerInside = streamReadBool(streamId)
	print('isPlayerInside: '..tostring(self.isPlayerInside))
	self:run(connection, streamId)
end;

function UniversalProcessKitTriggerPlayerEvent:run(connection, streamId)
	if not connection:getIsServer() then -- if server: send after receiving
		print('running as server')
		
		print('self.isPlayerInside is '..tostring(self.isPlayerInside))
		
		if streamId ~= nil then
			print('running step a')
			print('streamId is '..tostring(streamId))
			if self.isPlayerInside then
				self.upkmodule.playersInRange[streamId] = true
			else
				self.upkmodule.playersInRange[streamId] = nil
			end
		
			local serverIsPlayerInside = false
			for k,v in pairs(self.upkmodule.playersInRange) do
				if v then
					print('serverIsPlayerInside true for streamId '..tostring(k))
					serverIsPlayerInside = true
					break
				end
			end
			self.isPlayerInside = serverIsPlayerInside or self.upkmodule.playerInRangeNetworkNode
			print('self.isPlayerInside is '..tostring(self.isPlayerInside))
		end
		
		if self.isPlayerInside then
			self.upkmodule:triggerOnEnter(nil, true, true)
		else
			self.upkmodule:triggerOnLeave(nil, true, true)
		end
		
		g_server:broadcastEvent(self, false, connection)

	else
		print('running step a')
		if self.upkmodule ~= nil then
			print('running step b')
			
			print('self.isPlayerInside is '..tostring(self.isPlayerInside))
			
			if self.isPlayerInside then
				self.upkmodule:triggerOnEnter(nil, true, true)
			else
				self.upkmodule:triggerOnLeave(nil, true, true)
			end
		end
	end
end

function UniversalProcessKitTriggerPlayerEvent.sendEvent(upkmodule, isPlayerInside, alreadySent)
	print('UniversalProcessKitTriggerPlayerEvent.sendEvent('..tostring(upkmodule)..', '..tostring(isPlayerInside)..', '..tostring(alreadySent)..')')
	print('calling event with alreadySent = '..tostring(alreadySent))
	if not alreadySent then
		if g_server ~= nil then
			print('broadcasting isPlayerInside = '..tostring(isPlayerInside))
			g_server:broadcastEvent(UniversalProcessKitTriggerPlayerEvent:new(upkmodule, isPlayerInside))
		else
			print('sending to server isPlayerInside = '..tostring(isPlayerInside))
			g_client:getServerConnection():sendEvent(UniversalProcessKitTriggerPlayerEvent:new(upkmodule, isPlayerInside))
		end
	end
end

--[[ TRIGGER FUNCTIONS END ]]--