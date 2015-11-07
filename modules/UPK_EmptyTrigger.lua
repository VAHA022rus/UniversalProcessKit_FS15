-- by mor2000

--------------------
-- UPK_EmptyTrigger (fills trailers and/or shovels with specific fillType)

local UPK_EmptyTrigger_mt = ClassUPK(UPK_EmptyTrigger,UniversalProcessKit)
InitObjectClass(UPK_EmptyTrigger, "UPK_EmptyTrigger")
UniversalProcessKit.addModule("emptytrigger",UPK_EmptyTrigger)

function UPK_EmptyTrigger:new(nodeId, parent)
	printFn('UPK_EmptyTrigger:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId, parent, UPK_EmptyTrigger_mt)
	registerObjectClassName(self, "UPK_EmptyTrigger")
	
	self.emptyFillTypes = {}
	local emptyFillTypesArr = getArrayFromUserAttribute(nodeId, "emptyFillTypes")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(emptyFillTypesArr)) do
		self:printAll('fillType from emptyFillTypesArr: '..tostring(fillType))
		self.emptyFillTypes[fillType] = true
		self:printAll('self.emptyFillTypes[fillType]: '..tostring(self.emptyFillTypes[fillType]))
	end
	
	-- activateInput
	
	self.useActivateInputBinding = false
	local activateInput = getStringFromUserAttribute(nodeId, "activateInput", "false")
	if activateInput~="false" or self.useFillFillTypes then
		self.activateInputBinding = 'ACTIVATE_OBJECT'
		if activateInput=="false" then
			activateInput = 'ACTIVATE_OBJECT'
		end
		self.useActivateInputBinding = true
		self.startUnloadingText = returnNilIfEmptyString(self.i18n[getStringFromUserAttribute(nodeId, "startUnloadingText")]) or self.i18n['emptyTriggerStartUnloading']
		self.stopUnloadingText = returnNilIfEmptyString(self.i18n[getStringFromUserAttribute(nodeId, "stopUnloadingText")]) or self.i18n['emptyTriggerStopUnloading']
		if activateInput~="true" then
			if not InputBinding[activateInput] then
				self:printErr('unknown input "',activateInput,'" - using "ACTIVATE_OBJECT" for now')
			else
				self.activateInputBinding=activateInput
			end
		end
		self.autoDeactivate = getBoolFromUserAttribute(nodeId, "autoDeactivate", true)
	end
	
	self.isActivated = not self.useActivateInputBinding
	
	
    self.emptyLitersPerSecond = getNumberFromUserAttribute(nodeId, "emptyLitersPerSecond", 1500, 0)

	self:printAll('emptyFillTypes: '..tostring(getStringFromUserAttribute(nodeId, "emptyFillTypes")))

	self.emptyOnlyWholeNumbers = getBoolFromUserAttribute(nodeId, "emptyOnlyWholeNumbers", false)
	self.amountToEmptyOfVehicle = {}
	
	-- revenues
	
	self.revenuePerLiter = getNumberFromUserAttribute(nodeId, "revenuePerLiter", 0)
	self.revenuesPerLiter = {}
		
	local revenuesPerLiterArr = getArrayFromUserAttribute(nodeId, "revenuesPerLiter")
	for i=1,#revenuesPerLiterArr,2 do
		local revenue=tonumber(revenuesPerLiterArr[i])
		local fillType=unpack(UniversalProcessKit.fillTypeNameToInt(revenuesPerLiterArr[i+1]))
		if revenue~=nil and fillType~=nil then
			self.revenuesPerLiter[fillType] = revenue
		end
	end
	
	local revenues_mt = {
		__index=function(t,k)
			return self.revenuePerLiter
		end
	}
	setmetatable(self.revenuesPerLiter,revenues_mt)
	
	self.preferMapDefaultRevenue = getBoolFromUserAttribute(nodeId, "preferMapDefaultRevenue", false)
	self.revenuePerLiterMultiplier = getVectorFromUserAttribute(nodeId, "revenuePerLiterMultiplier", "1 0.5 0.25")
	self.revenuesPerLiterAdjusted = {}
	
	self.statName=getStatNameFromUserAttribute(nodeId)

	self.deleteEmptyPallets = getBoolFromUserAttribute(nodeId, "deleteEmptyPallets", true)

	self.allowedVehicles={}
	self.allowedVehicles[UniversalProcessKit.VEHICLE_TIPPER] = getBoolFromUserAttribute(nodeId, "allowTipper", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SHOVEL] = getBoolFromUserAttribute(nodeId, "allowShovel", true)
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SOWINGMACHINE] = getBoolFromUserAttribute(nodeId, "allowSowingMachine", self.emptyFillTypes[UniversalProcessKit.FILLTYPE_SEEDS] or false)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER] = getBoolFromUserAttribute(nodeId, "allowWaterTrailer", self.emptyFillTypes[UniversalProcessKit.FILLTYPE_WATER] or false)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRAILER] = getBoolFromUserAttribute(nodeId, "allowMilkTrailer", self.emptyFillTypes[UniversalProcessKit.FILLTYPE_MILK] or false)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER] = getBoolFromUserAttribute(nodeId, "allowLiquidManureTrailer", self.emptyFillTypes[UniversalProcessKit.FILLTYPE_LIQUIDMANURE] or false)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SPRAYER] = getBoolFromUserAttribute(nodeId, "allowSprayer", self.emptyFillTypes[UniversalProcessKit.FILLTYPE_FERTILIZER] or false)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MANURESPREADER] = getBoolFromUserAttribute(nodeId, "allowManureSpreader", self.emptyFillTypes[UniversalProcessKit.FILLTYPE_MANURE] or false)
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER] = getBoolFromUserAttribute(nodeId, "allowFuelTrailer", self.emptyFillTypes[UniversalProcessKit.FILLTYPE_FUEL] or false)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] = getBoolFromUserAttribute(nodeId, "allowMotorized", false)
	
	self.allowWalker = getBoolFromUserAttribute(nodeId, "allowWalker", false)
	
	self:addTrigger()
	
	-- actions
	self:getActionUserAttributes('IfEmptying')
	self.isEmptying=nil
	
	self:getActionUserAttributes('IfEmptyingStarted')
	self:getActionUserAttributes('IfEmptyingStopped')
	
	self:getActionUserAttributes('OnPalletDeleted')
	
	self:printFn('UPK_EmptyTrigger:new done')
	
    return self
end

function UPK_EmptyTrigger:delete()
	self:printFn('UPK_EmptyTrigger:delete()')
	UniversalProcessKitListener.removeUpdateable(self)
	if self.useActivateInputBinding then
		UniversalProcessKitListener.unregisterKeyFunction(self.activateInputBinding,self)
	end
	UPK_EmptyTrigger:superClass().delete(self)
end

function UPK_EmptyTrigger:postLoad()
	self:printFn('UPK_EmptyTrigger:postLoad()')
	UPK_EmptyTrigger:superClass().postLoad(self)
	
	UniversalProcessKitListener.addUpdateable(self)
	
	if self.isServer then
		--self:sendEvent(UniversalProcessKitEvent.TYPE_INPUT,1,123.123,-65000.02,"test",nil,1234567890.12345678,1900,-1900.12345678)
	end
end

function UPK_EmptyTrigger:loadExtraNodes(xmlFile, key)
	self:printFn('UPK_EmptyTrigger:loadExtraNodes(',xmlFile,', ',key,')')
	self.isActivated = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isActivated"),not self.useActivateInputBinding)
	return true
end

function UPK_EmptyTrigger:getSaveExtraNodes(nodeIdent)
	self:printFn('UPK_EmptyTrigger:getSaveExtraNodes(',nodeIdent,')')
	local nodes=""
	if isActivated==false then
		nodes=nodes .. ' isActivated="false"'
	end
	return nodes
end

function UPK_EmptyTrigger:eventCallback(eventType,...)
	self:printFn('UPK_EmptyTrigger:eventCallBack(',eventType,'...)')
	if eventType==UniversalProcessKitEvent.TYPE_INPUT then
		self:printAll('UniversalProcessKitEvent.TYPE_INPUT')
		self:printAll(...)
	elseif eventType==UniversalProcessKitEvent.TYPE_FILLTYPESELECTED then
		self:printAll('UniversalProcessKitEvent.TYPE_FILLTYPESELECTED')
		self:printAll(...)
	end
end

function UPK_EmptyTrigger:triggerUpdate(vehicle,isInTrigger)
	self:printFn('UPK_EmptyTrigger:triggerUpdate(',vehicle,', ',isInTrigger,')')
	if self.isEnabled and self.isServer then
		for k,v in pairs(self.allowedVehicles) do
			if v and UniversalProcessKit.isVehicleType(vehicle, k) then
				if isInTrigger then
					self.amountToEmptyOfVehicle[vehicle]=0
					self:printAll('UniversalProcessKitListener.addUpdateable(',self,')')
					UniversalProcessKitListener.addUpdateable(self)
				else
					self.amountToEmptyOfVehicle[vehicle]=nil
				end
			end
		end
		
		if self.allowPallets and vehicle~=nil and vehicle.isPallet and vehicle.setFillLevel~=nil then
			if isInTrigger then
				self.amountToEmptyOfVehicle[vehicle]=0
				UniversalProcessKitListener.addUpdateable(self)
			else
				self.amountToEmptyOfVehicle[vehicle]=nil
			end
		end
		
		if self.entitiesInTrigger==0 then
			self:printAll('UniversalProcessKitListener.removeUpdateable(',self,')')
			UniversalProcessKitListener.removeUpdateable(self)
			if self.isEmptying then
				self:operateAction('IfEmptyingStopped')
				self.isEmptying=false
			end
		end
	end
end

function UPK_EmptyTrigger:update(dt)
	self:printAll('UPK_EmptyTrigger:update(',dt,')')
	
	if not self.isServer then
		return
	end
	
	if not self.isActivated and (self.isFilling==nil or self.isFilling) then
		self:operateAction('IfEmptyingStopped')
		self.isEmptying=false
	end
	
	if self.useActivateInputBinding and not self.isActivated then
		UniversalProcessKitListener.removeUpdateable(self)
	end
	
	if self.isEnabled and self.isActivated then
		local isEmptying=false
		local removedTotally=0
		for _,vehicle in pairs(self.vehicles) do
			local deltaFillLevel = - (self.emptyLitersPerSecond * 0.001 * dt)
			for vehicleType, isAllowed in pairs(self.allowedVehicles) do
				if isAllowed and UniversalProcessKit.isVehicleType(vehicle, vehicleType) then
					local removed = 0
					if (vehicleType==UniversalProcessKit.VEHICLE_TIPPER or
						 vehicleType==UniversalProcessKit.VEHICLE_SHOVEL or
						 vehicleType==UniversalProcessKit.VEHICLE_SOWINGMACHINE or
						 vehicleType==UniversalProcessKit.VEHICLE_WATERTRAILER or
						 vehicleType==UniversalProcessKit.VEHICLE_MANURESPREADER or
						 vehicleType==UniversalProcessKit.VEHICLE_MILKTRAILER or
						 vehicleType==UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER or
						 vehicleType==UniversalProcessKit.VEHICLE_SPRAYER or
						 vehicleType==UniversalProcessKit.VEHICLE_FUELTRAILER) then
						removed = self:emptyFillable(vehicle, deltaFillLevel)
					elseif vehicleType==UniversalProcessKit.VEHICLE_MOTORIZED then
						removed = self:emptyMotorized(vehicle, deltaFillLevel)
					end
					removedTotally=removedTotally+removed
				end
			end
			if self.allowPallets and vehicle.isPallet and vehicle.setFillLevel~=nil then
				removed = self:emptyPallet(vehicle, deltaFillLevel)
				removedTotally=removedTotally+removed
			end
		end
		self:printAll('removedTotally ',removedTotally)
		if (not self.isEmptying or not isEmptying) and round(removedTotally,8)>0 then
			isEmptying=true
		end
		self:printAll('isEmptying ',isEmptying)
		if isEmptying then
			if not self.isEmptying then
				self:operateAction('IfEmptyingStarted')
				self.isEmptying=true
			end
			self:operateAction('IfEmptying',removedTotally)
		else
			if self.isEmptying then
				self:operateAction('IfEmptyingStopped')
				self.isEmptying=false
			end
			if self.isActivated and self.useActivateInputBinding and self.autoDeactivate then
				self.isActivated=false
				UniversalProcessKitListener.updateKeyFunctionDisplayText(self.activateInputBinding,self,self.startUnloadingText)
			end
		end
	end
end

UPK_EmptyTrigger.getRevenuePerLiter = UPK_TipTrigger.getRevenuePerLiter

function UPK_EmptyTrigger:emptyFillable(fillable, deltaFillLevel) -- tippers, shovels etc
	self:printFn('UPK_EmptyTrigger:emptyFillable(',fillable,', ',deltaFillLevel,')')
	
	if self.isServer and self.isEnabled then
		local fillType = nil
		for k,v in pairs(self.emptyFillTypes) do
			if v and fillable:allowFillType(k, false) then
				fillType = k
				break
			end
		end
		if fillType~=nil then
			local fillLevel = self:getFillLevel(fillType)
			local capacity = self:getCapacity(fillType)
			local fillableFillLevel = fillable:getFillLevel(fillType)
			if fillableFillLevel>0 and capacity-fillLevel>0 then
				deltaFillLevel=-mathmin(-deltaFillLevel, fillableFillLevel, capacity-fillLevel)
				
				if self.emptyOnlyWholeNumbers then
					self.amountToEmptyOfVehicle[fillable] = (self.amountToEmptyOfVehicle[fillable] or 0) - deltaFillLevel
					deltaFillLevel = -mathfloor(self.amountToEmptyOfVehicle[fillable])
					self.amountToEmptyOfVehicle[fillable] = self.amountToEmptyOfVehicle[fillable] + deltaFillLevel
				end
			
				if deltaFillLevel==0 then
					return 0
				end
				
				fillable:setFillLevel(fillableFillLevel + deltaFillLevel, fillType)
				local added = self:addFillLevel(-deltaFillLevel, fillType)
				
				local revenuePerLiter = self:getRevenuePerLiter(fillType)
				if added~=0 and revenuePerLiter~=0 then
					local revenue = added * revenuePerLiter
					g_currentMission:addSharedMoney(revenue, self.statName)
				end
				return added
			end
		end
	end
	return 0
end

function UPK_EmptyTrigger:emptyMotorized(motorized, deltaFillLevel) -- motorized
	self:printFn('UPK_EmptyTrigger:emptyMotorized(',motorized,', ',deltaFillLevel,')')
	if self.isServer and self.isEnabled and self.emptyFillTypes[UniversalProcessKit.FILLTYPE_FUEL] then
		local fillType = UniversalProcessKit.FILLTYPE_FUEL
		local fillLevel = self:getFillLevel(fillType)
		local capacity = self:getCapacity(fillType)
		local motorizedFillLevel = motorized.fuelFillLevel
		if motorizedFillLevel>0 and capacity-fillLevel>0 then
			deltaFillLevel=-mathmin(-deltaFillLevel, motorizedFillLevel, capacity-fillLevel)
			
			if self.emptyOnlyWholeNumbers then
				self.amountToEmptyOfVehicle[fillable] = (self.amountToEmptyOfVehicle[fillable] or 0) - deltaFillLevel
				deltaFillLevel = -mathfloor(self.amountToEmptyOfVehicle[fillable])
				self.amountToEmptyOfVehicle[fillable] = self.amountToEmptyOfVehicle[fillable] + deltaFillLevel
			end
		
			if deltaFillLevel==0 then
				return 0
			end
			
			motorized:setFuelFillLevel(motorizedFillLevel + deltaFillLevel)
			local added = self:addFillLevel(-deltaFillLevel, fillType)
			if added~=0 and self.revenuesPerLiter[fillType]~=0 then
				local revenue = added * self.revenuesPerLiter[fillType]
				g_currentMission:addSharedMoney(revenue, self.statName)
			end
			return added
		end
	end
	return 0
end

function UPK_EmptyTrigger:emptyPallet(fillable, deltaFillLevel) -- pallet
	self:printFn('UPK_EmptyTrigger:emptyPallet(',fillable,', ',deltaFillLevel,')')
	if self.isServer and self.isEnabled then
		local fillType = fillable:getFillType()
		if not self.emptyFillTypes[fillType] then
			return 0
		end
		if fillType~=nil then
			local fillLevel = self:getFillLevel(fillType)
			local capacity = self:getCapacity(fillType)
			local fillableFillLevel = fillable:getFillLevel()
			self:printAll('fillableFillLevel ',fillableFillLevel)
			if fillableFillLevel>0 and capacity-fillLevel>0 then
				deltaFillLevel=-mathmin(-deltaFillLevel, fillableFillLevel, capacity-fillLevel)
				
				if self.emptyOnlyWholeNumbers then
					self.amountToEmptyOfVehicle[fillable] = (self.amountToEmptyOfVehicle[fillable] or 0) - deltaFillLevel
					deltaFillLevel = -mathfloor(self.amountToEmptyOfVehicle[fillable])
					self.amountToEmptyOfVehicle[fillable] = self.amountToEmptyOfVehicle[fillable] + deltaFillLevel
				end
			
				if deltaFillLevel==0 then
					return 0
				end
				
				fillable:setFillLevel(fillableFillLevel + deltaFillLevel, fillType)
				local added = self:addFillLevel(-deltaFillLevel, fillType)
				
				local revenuePerLiter = self:getRevenuePerLiter(fillType)
				if added~=0 and revenuePerLiter~=0 then
					local revenue = added * revenuePerLiter
					g_currentMission:addSharedMoney(revenue, self.statName)
				end
				return added
			elseif fillableFillLevel==0 and self.deleteEmptyPallets then
				self:triggerOnLeave(fillable)
				fillable:delete()
				self:operateAction('OnPalletDeleted')
			end
		end
	end
	return 0
end

