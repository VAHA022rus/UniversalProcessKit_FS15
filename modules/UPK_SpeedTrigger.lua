-- by mor2000

--------------------
-- SpeedTrigger

local UPK_SpeedTrigger_mt = ClassUPK(UPK_SpeedTrigger,UniversalProcessKit)
InitObjectClass(UPK_SpeedTrigger, "UPK_SpeedTrigger")
UniversalProcessKit.addModule("speedtrigger",UPK_SpeedTrigger)

function UPK_SpeedTrigger:new(nodeId, parent)
	printFn('UPK_SpeedTrigger:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId, parent, UPK_SpeedTrigger_mt)
	registerObjectClassName(self, "UPK_SpeedTrigger")
	
	self.isPopulated=false
	self.speedLimitWhenEntered={}

	-- speed limit
	
	self.speedLimit = getNumberFromUserAttribute(nodeId, "speedLimit", 120, 1, 999)
	self.speedLimitPercentageFactor = getNumberFromUserAttribute(nodeId, "speedLimitPercentage", 100, 1, 100)/100
	self.speedLimitChoiceMax = getStringFromUserAttribute(nodeId, "speedLimitChoice", "min")=="max"
	
	self.speedLimitToleranceFactor = getNumberFromUserAttribute(nodeId, "speedLimitTolerance", 0, 0, 100)/100
	
	self:printInfo('ST self.speedLimitPercentage = ',self.speedLimitPercentage)
	self:printInfo('ST self.speedLimit = ',self.speedLimit)
	
	-- actions
	
	self:getActionUserAttributes('IfAboveSpeedLimit')
	self:getActionUserAttributes('IfBelowSpeedLimit')
	
	self:getActionUserAttributes('OnPopulated')
	self:getActionUserAttributes('OnEmpty')
	self:getActionUserAttributes('OnPopulated')
	self:getActionUserAttributes('OnEnter')
	self:getActionUserAttributes('OnLeave')

	-- trigger
	
	self.allowedVehicles={}
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] = getBoolFromUserAttribute(nodeId, "allowMotorized", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_COMBINE] = getBoolFromUserAttribute(nodeId, "allowCombine", true)
	
	self:addTrigger()
	
	self.allowWalker=false
	
	self:printFn('UPK_SpeedTrigger:new done')
	
	return self
end

function UPK_SpeedTrigger:postLoad()
	self:printFn('UPK_SpeedTrigger:postLoad()')
	
	if self.isServer then -- server, single game
		self:setIsPopulated(self.vehiclesInTrigger>0) -- from savegame, ignore players
	else -- client joning
		self:setIsPopulated(self.entitiesInTrigger>0)
	end
	
	UPK_SpeedTrigger:superClass().postLoad(self)
	
	-- no players allowed
end

function UPK_SpeedTrigger:triggerUpdate(vehicle,isInTrigger)
	self:printFn('UPK_SpeedTrigger:triggerUpdate(',vehicle,', ',isInTrigger,')')
	if self.isEnabled and self.isClient then
		if vehicle~=nil and UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_DRIVABLE) and UniversalProcessKit.isVehicleType(vehicle,UniversalProcessKit.VEHICLE_MOTORIZED) then
			if isInTrigger then
				self:operateAction('OnEnter')
				
				local lastSpeed=vehicle.lastSpeed*3600
				self:printInfo('ST vehicle.lastSpeed = ',lastSpeed)
				self:printInfo('ST vehicle.speedLimit = ',vehicle.motor.speedLimit)
				
				local maximumForwardSpeed = vehicle.motor:getMaximumForwardSpeed()*3.6
				self:printInfo('ST vehicle.motor:getMaximumForwardSpeed() = ',maximumForwardSpeed)
				self.speedLimitWhenEntered[vehicle.rootNode] = maximumForwardSpeed
				
				self:printInfo('ST vehicle.cruiseControl = ',vehicle.cruiseControl)
				if vehicle.cruiseControl~=nil then
					self:printInfo('ST vehicle.cruiseControl.isActive = ',vehicle.cruiseControl.isActive)
					self:printInfo('ST vehicle.cruiseControl.speed = ',vehicle.cruiseControl.speed)
					self:printInfo('ST vehicle.cruiseControl.maxSpeed = ',vehicle.cruiseControl.maxSpeed)
					self:printInfo('ST vehicle.cruiseControl.state == Drivable.CRUISECONTROL_STATE_ACTIVE = ',vehicle.cruiseControl.state == Drivable.CRUISECONTROL_STATE_ACTIVE)	
				end
				
				UniversalProcessKitListener.addUpdateable(self)
			else
				if vehicle.cruiseControl~=nil then
					if self.speedLimitWhenEntered[vehicle.rootNode]~=nil then
						vehicle.motor:setSpeedLimit(self.speedLimitWhenEntered[vehicle.rootNode])
						self.speedLimitWhenEntered[vehicle.rootNode] = nil
					else
						vehicle:setCruiseControlMaxSpeed(vehicle.cruiseControl.maxSpeed)
					end
				end
					
				self:operateAction('OnLeave')
			end
		end
		self:printAll('self.entitiesInTrigger=',self.entitiesInTrigger,' self.isPopulated=',self.isPopulated)
		if self.entitiesInTrigger>0 and not self.isPopulated then
			self:setIsPopulated(true)
		elseif self.entitiesInTrigger==0 and self.isPopulated then
			self:setIsPopulated(false)
		end
		
		if self.entitiesInTrigger==0 then
			self:printAll('UniversalProcessKitListener.removeUpdateable(',self,')')
			UniversalProcessKitListener.removeUpdateable(self)
		end
	end
end

function UPK_SpeedTrigger:update(dt)
	self:printAll('UPK_SpeedTrigger:update(',dt,')')
	if self.isServer and self.isEnabled then
		for _,vehicle in pairs(self.vehicles) do
			local speedLimit = self.speedLimit
			local maximumForwardSpeed = vehicle.motor:getMaximumForwardSpeed()*3.6
			if self.speedLimitChoiceMax then
				speedLimit = mathmax(self.speedLimit, maximumForwardSpeed*self.speedLimitPercentageFactor)
			else
				speedLimit = mathmin(self.speedLimit, maximumForwardSpeed*self.speedLimitPercentageFactor)
			end
			self:printInfo('vehicle:getSpeedLimit(true) ',vehicle:getSpeedLimit(true))
			self:printInfo('speedLimit ',speedLimit)
			vehicle.motor:setSpeedLimit(speedLimit)
			self:printInfo('vehicle:getSpeedLimit(true) ',vehicle:getSpeedLimit(true))
			
			local lastSpeed=vehicle.lastSpeed*3600
			self:printInfo('speedLimit ',speedLimit,' lastSpeed ',lastSpeed)
			if lastSpeed > speedLimit*(1+self.speedLimitToleranceFactor) then
				local modifier=(lastSpeed-speedLimit)/1000*dt
				self:printInfo('speedLimit-lastSpeed ',modifier)
				self:operateAction('IfAboveSpeedLimit',modifier)
			elseif lastSpeed < speedLimit*(1-self.speedLimitToleranceFactor) then
				local modifier=(speedLimit-lastSpeed)/1000*dt
				self:printInfo('lastSpeed-speedLimit ',modifier)
				self:operateAction('IfBelowSpeedLimit',modifier)
			end
		end
	end
end

function UPK_SpeedTrigger:setIsPopulated(isPopulated)
	self:printFn('UPK_SpeedTrigger:setIsPopulated(',isPopulated,')')
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
