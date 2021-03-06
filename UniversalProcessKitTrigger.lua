-- by mor2000

--[[ TRIGGER FUNCTIONS BEGIN ]]--

function UniversalProcessKit:addTrigger()
	self:printFn('UniversalProcessKit:addTrigger()')
	
	self.triggerId=self.nodeId
	self:getAllowedVehicles()
	self:fitCollisionMaskToAllowedVehicles()
	
	self.vehicles={}
	self.vehiclesInTrigger=0
	self.vehicleNodesInTrigger={}
	self.players={}
	self.playersInTrigger=0
	self.entitiesInTrigger=0
	
	self.playerInRange=false
	
	-- actions
	
	self:getActionUserAttributes('OnEmpty')
	self:getActionUserAttributes('OnPopulated')
	self:getActionUserAttributes('OnEnter')
	self:getActionUserAttributes('OnLeave')
	

	addTrigger(self.triggerId, "triggerCallback", self)
	table.insert(g_upkTrigger, self)
	--self:triggerUpdate(nil,true)
	--self:triggerUpdate(nil,false)
end

function UniversalProcessKit:removeTrigger()
	self:printFn('UniversalProcessKit:removeTrigger()')
	
	if self.triggerId~=nil and self.triggerId~=0 then
		removeValueFromTable(g_upkTrigger, self)
		removeTrigger(self.triggerId)
		self.triggerId = 0
		self.allowedVehicles=nil
		
		self.vehicles={}
		self.vehiclesInTrigger=0
		self.players={}
		self.playersInTrigger=0
		self.entitiesInTrigger=0
		
		self.playerInRange=false
	end
end

function UniversalProcessKit:getAllowedVehicles()
	self:printFn('UniversalProcessKit:getAllowedVehicles()')
	
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
	
	self.allowWalker = Utils.getNoNil(self.allowWalker, getBoolFromUserAttribute(self.nodeId, "allowWalker", true))
	
	self.allowBales = Utils.getNoNil(self.allowBales, getBoolFromUserAttribute(self.nodeId, "allowBales", false))
	self.allowPallets = Utils.getNoNil(self.allowPallets, getBoolFromUserAttribute(self.nodeId, "allowPallets", false))
	self.allowWood = Utils.getNoNil(self.allowWood, getBoolFromUserAttribute(self.nodeId, "allowWood", false))
	
	for k,v in pairs(self.allowedVehicles) do
		if not v then
			self.allowedVehicles[k]=nil
		end
	end
end

function UniversalProcessKit:fitCollisionMaskToAllowedVehicles()
	self:printFn('UniversalProcessKit:fitCollisionMaskToAllowedVehicles()')
	
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
	local trigger_dynamic_objects = 16777216 -- bales, pallets, logs
	local trigger_attachment = 8192 -- cultivators, tedders, ...
	local trigger_trafficVehicle = 33554432 -- doesnt seem to work right

	local collisionMask_old = getCollisionMask(self.triggerId)
	local collisionMask_new = collisionMask_old
	
	-- add colision mask bits if necessary
	
	if self.allowWalker and bitAND(collisionMask_new,trigger_player)==0 then
		self:printInfo('Warning: allowWalker is set to true but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new + trigger_player
	end
	if self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] and bitAND(collisionMask_new,trigger_tractor)==0 then
		self:printInfo('Warning: allowMotorized is set to true but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new + trigger_tractor
	end
	if self.allowedVehicles[UniversalProcessKit.VEHICLE_COMBINE] and bitAND(collisionMask_new,trigger_combine)==0 then
		self:printInfo('Warning: allowCombine is set to true but collisionMask was not fitting (fixed)')
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
		self:printInfo('Warning: allowFillable is set to true but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new + trigger_fillable
	end
	if self.allowedVehicles[UniversalProcessKit.VEHICLE_ATTACHMENT] and bitAND(collisionMask_new,trigger_attachment)==0 then
		self:printInfo('Warning: allowAttachment is set to true but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new + trigger_attachment
	end
	if (self.allowedVehicles[UniversalProcessKit.VEHICLE_TRAFFICVEHICLE] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRUCK]) and bitAND(collisionMask_new,trigger_trafficVehicle)==0 then
		self:printInfo('Warning: allowTrafficVehicle is set to true but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new + trigger_trafficVehicle
	end
	if (self.allowBales or self.allowPallets or self.allowWood) and bitAND(collisionMask_new,trigger_dynamic_objects)==0 then
		self:printInfo('Warning: allowBales, allowPallets or allowWood is set to true but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new + trigger_dynamic_objects
	end
	
	-- substract colision mask bits if necessary
	
	if not self.allowWalker and bitAND(collisionMask_new,trigger_player)==1 then
		self:printInfo('Warning: allowWalker is set to false but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new - trigger_player
	end
	if not self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] and bitAND(collisionMask_new,trigger_tractor)==1 then
		self:printInfo('Warning: allowMotorized is set to false but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new - trigger_tractor
	end
	if not self.allowedVehicles[UniversalProcessKit.VEHICLE_COMBINE] and bitAND(collisionMask_new,trigger_combine)==1 then
		self:printInfo('Warning: allowCombine is set to false but collisionMask was not fitting (fixed)')
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
		self:printInfo('Warning: allowFillable is set to false but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new - trigger_fillable
	end
	if not self.allowedVehicles[UniversalProcessKit.VEHICLE_ATTACHMENT] and bitAND(collisionMask_new,trigger_attachment)==1 then
		self:printInfo('Warning: allowAttachment is set to false but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new - trigger_attachment
	end
	if not (self.allowedVehicles[UniversalProcessKit.VEHICLE_TRAFFICVEHICLE] or
		self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRUCK]) and bitAND(collisionMask_new,trigger_trafficVehicle)==1 then
		self:printInfo('Warning: allowTrafficVehicle is set to false but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new - trigger_trafficVehicle
	end
	if not (self.allowBales or self.allowPallets or self.allowWood) and bitAND(collisionMask_new,trigger_dynamic_objects)==1 then
		self:printInfo('Warning: allowBales, allowPallets and allowWood is set to false but collisionMask was not fitting (fixed)')
		collisionMask_new = collisionMask_new - trigger_dynamic_objects
	end
	
	-- result
	
	if collisionMask_new ~= collisionMask_old then
		self:printInfo('Warning: set collisionMask according to allowed vehicles to ',collisionMask_new,' (you may want to fix that)')
		setCollisionMask(self.triggerId,collisionMask_new)
	end
end

function UniversalProcessKit:triggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	self:printFn('UniversalProcessKit:triggerCallback(',triggerId,', ',otherActorId,', ',onEnter,', ',onLeave,', ',onStay,', ',otherShapeId,')')
	if self.isEnabled then
		local vehicle=g_currentMission.objectToTrailer[otherShapeId] or
						g_currentMission.nodeToVehicle[otherShapeId] or
						g_currentMission.objectToTrailer[otherActorId] or
						g_currentMission.nodeToVehicle[otherActorId] or
						g_currentMission.nodeObjects[otherShapeId] or
						g_currentMission.nodeObjects[otherActorId]
		self:printAll('=======')
		self:printAll('g_currentMission.objectToTrailer[otherShapeId] ',g_currentMission.objectToTrailer[otherShapeId])
		self:printAll('g_currentMission.nodeToVehicle[otherShapeId] ',g_currentMission.nodeToVehicle[otherShapeId])
		self:printAll('g_currentMission.objectToTrailer[otherActorId] ',g_currentMission.objectToTrailer[otherActorId])
		self:printAll('g_currentMission.nodeToVehicle[otherActorId] ',g_currentMission.nodeToVehicle[otherActorId])
		self:printAll('vehicle is ',vehicle)
		
		if vehicle~=nil then
			
			if self.vehicleNodesInTrigger[vehicle]==nil then
				self.vehicleNodesInTrigger[vehicle]={}
			end
			if not isInTable(self.vehicleNodesInTrigger[vehicle],otherShapeId) then
				table.insert(self.vehicleNodesInTrigger[vehicle],otherShapeId)
			end
			
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
					self:printAll('thingy is a pallet 1')
					if onEnter then
						if length(self.vehicleNodesInTrigger[vehicle])==1 then
							self:vehicleEntered(vehicle)
						end
					elseif onLeave then
						removeValueFromTable(self.vehicleNodesInTrigger[vehicle],otherShapeId)
						if length(self.vehicleNodesInTrigger[vehicle])==0 then
							self.vehicleNodesInTrigger[vehicle]=nil
							self:vehicleLeft(vehicle)
						end
					end
				end
			end
			
			if self.allowBales then
				if vehicle:isa(Bale) then
					vehicle.isBale = true
					if onEnter then
						if length(self.vehicleNodesInTrigger[vehicle])==1 then
							self:vehicleEntered(vehicle)
						end
					elseif onLeave then
						removeValueFromTable(self.vehicleNodesInTrigger[vehicle],otherShapeId)
						if length(self.vehicleNodesInTrigger[vehicle])==0 then
							self.vehicleNodesInTrigger[vehicle]=nil
							self:vehicleLeft(vehicle)
						end
					end
				end
			end

			for k,v in pairs(UniversalProcessKit.getVehicleTypes(vehicle)) do
				if v and self.allowedVehicles[k] then
					if onEnter then
						if vehicle.upkTrigger == nil then
							vehicle.upkTrigger={}
						end
						table.insert(vehicle.upkTrigger,self)
						if length(self.vehicleNodesInTrigger[vehicle])==1 then
							self:vehicleEntered(vehicle)
						end
					elseif onLeave then
						removeValueFromTable(vehicle.upkTrigger,self)
						removeValueFromTable(self.vehicleNodesInTrigger[vehicle],otherShapeId)
						if length(self.vehicleNodesInTrigger[vehicle])==0 then
							self.vehicleNodesInTrigger[vehicle]=nil
							self:vehicleLeft(vehicle)
						end
					end
					break
				end
			end
		end
		if self.allowWood then
			local splitType = SplitUtil.splitTypes[getSplitType(otherActorId)]
			self:printAll('splitType is ',splitType)
			if splitType~=nil and splitType.woodChipsPerLiter>0 then
				if onEnter then
					self:vehicleEntered(otherActorId,true)
				elseif onLeave then
					self:vehicleLeft(otherActorId,false)
				end
			end
		end
		if self.allowWalker and g_currentMission.player ~= nil and otherActorId == g_currentMission.player.rootNode then
			if onEnter then
				self:playerEntered(UniversalProcessKitListener.clientId, true)
			elseif onLeave then
				self:playerLeft(UniversalProcessKitListener.clientId, true)
			end
		end
	end
end

function UniversalProcessKit:vehicleEntered(vehicle, player, alreadySent)
	self:printFn('UniversalProcessKit:vehicleEntered(',vehicle,', ',player,', ',alreadySent,')')
	if vehicle~=nil then
		if isInTable(self.vehicles, vehicle) then
			return
		end
		local typeV=type(vehicle)
		if typeV=="table" then
			local networkId=networkGetObjectId(vehicle)
			if networkId~=nil and networkId~=0 then
				self.vehicles[networkId]=vehicle
			end
		elseif typeV=="number" then
			self.vehicles[-vehicle]=true -- workaround for non-objects
		end
	end
	
	self.vehiclesInTrigger = length(self.vehicles)
	self:p_triggerUpdate(vehicle,true)
end;

function UniversalProcessKit:vehicleLeft(vehicle, player, alreadySent)
	self:printFn('UniversalProcessKit:vehicleLeft(',vehicle,', ',player,', ',alreadySent,')')
	if vehicle~=nil then
		local typeV=type(vehicle)
		if typeV=="table" then
			local networkId=networkGetObjectId(vehicle)
			if networkId~=nil and networkId~=0 then
				self.vehicles[networkId]=nil
			end
			removeValueFromTable(self.vehicles,vehicle)
		elseif typeV=="number" then
			self.vehicles[-vehicle]=nil -- workaround for non-objects
		end
	end
	
	self.vehiclesInTrigger = length(self.vehicles)
	self:p_triggerUpdate(vehicle,false)
end;

function UniversalProcessKit:playerEntered(player,alreadySent)
	self:printFn('UniversalProcessKit:playerEntered(',player,', ',alreadySent,')')
	if player~=nil then
		if isInTable(self.players, player) then
			return
		end
		if player==UniversalProcessKitListener.clientId then
			self.playerInRange = true
		end
		self.players[player] = true
		if not alreadySent then
			self:sendEvent(UniversalProcessKitEvent.TYPE_PLAYERINTRIGGER,player,true)
		end
	end
	
	self.playersInTrigger = length(self.players)
	self:p_triggerUpdate(nil,true)
end

function UniversalProcessKit:playerLeft(player,alreadySent)
	self:printFn('UniversalProcessKit:playerLeft(',player,', ',alreadySent,')')
	if player~=nil then
		if player==UniversalProcessKitListener.clientId then
			self.playerInRange = false
		end
		self.players[player] = nil
		if not alreadySent then
			self:sendEvent(UniversalProcessKitEvent.TYPE_PLAYERINTRIGGER,player,false)
		end
	end
	
	self.playersInTrigger = length(self.players)
	self:p_triggerUpdate(nil,false)
end

function UniversalProcessKit:p_triggerUpdate(vehicle,isInTrigger)
	self:printFn('UniversalProcessKit:p_triggerUpdate(',vehicle,', ',isInTrigger,')')
	self.entitiesInTrigger = self.vehiclesInTrigger + self.playersInTrigger
	
	if self.isEnabled then
		if isInTrigger then
			self:operateAction('OnEnter')
		else
			self:operateAction('OnLeave')
		end
	end
	
	self:printInfo('self.vehiclesInTrigger ',self.vehiclesInTrigger)
	self:printInfo('self.playersInTrigger ',self.playersInTrigger)
	self:printInfo('self.entitiesInTrigger ',self.entitiesInTrigger)
	self:printInfo('self.isPopulated ',self.isPopulated)
	
	if self.entitiesInTrigger>0 and not self.isPopulated then
		self:setIsPopulated(true)
	elseif self.entitiesInTrigger==0 and self.isPopulated then
		self:setIsPopulated(false)
	end

	if self.triggerUpdate~=nil then
		-- use this function to handle trigger events (in your own class)
		-- otherwise use self.vehiclesInTrigger and self.vehicles in update()
		self:triggerUpdate(vehicle,isInTrigger)
	end
end

function UniversalProcessKit:setIsPopulated(isPopulated)
	self:printFn('UniversalProcessKit:setIsPopulated(',isPopulated,')')
	if isPopulated~=self.isPopulated then
		if isPopulated==false then
			self.isPopulated=false
			self:operateAction('OnEmpty')
		elseif isPopulated==true then
			self.isPopulated=true
			self:operateAction('OnPopulated')
		end
	end
end

function UniversalProcessKit:getShowInfo()
	self:printFn('UniversalProcessKit:getShowInfo()')
	if self.playerInRange then
		return g_currentMission.controlPlayer or false
	else
		for k,v in pairs(self.vehicles) do
			if v.isEntered or v:getIsActiveForInput(true) then
				return true
			end
		end
	end
	return false
end

function UniversalProcessKit:onVehicleDeleted(vehicle)
	self:printFn('UniversalProcessKit:onVehicleDeleted()')
end

--[[ TRIGGER FUNCTIONS END ]]--