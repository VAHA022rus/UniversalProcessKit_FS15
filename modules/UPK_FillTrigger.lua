-- by mor2000

--------------------
-- UPK_FillTrigger (fills trailers and/or shovels with specific fillType)

local UPK_FillTrigger_mt = ClassUPK(UPK_FillTrigger,UniversalProcessKit)
InitObjectClass(UPK_FillTrigger, "UPK_FillTrigger")
UniversalProcessKit.addModule("filltrigger",UPK_FillTrigger)

function UPK_FillTrigger:new(nodeId, parent)
	printFn('UPK_FillTrigger:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId, parent, UPK_FillTrigger_mt)
	registerObjectClassName(self, "UPK_FillTrigger")
	
	self.fillFillType=nil
	local fillFillTypeStr = getStringFromUserAttribute(nodeId, "fillType")
	if fillFillTypeStr~=nil then
		self.fillFillType = UniversalProcessKit.fillTypeNameToInt[fillFillTypeStr]
		if self.fillFillType==nil then
			printInfo('unknown fillType "',fillFillTypeStr,'"')
		end
	end
	
	self.fillFillTypes={}
	self.useFillFillTypes=false
	local fillTypesArr = getArrayFromUserAttribute(nodeId, "fillTypes", false)
	if fillTypesArr~=false then
		local fillTypesArrLen = length(fillTypesArr)
		for i=1,fillTypesArrLen do
			local fillType = UniversalProcessKit.fillTypeNameToInt[fillTypesArr[i]]
			if fillType~=nil then
				table.insert(self.fillFillTypes,fillType)
				self.useFillFillTypes=true
			else
				printInfo('unknown fillType "',fillTypesArr[i],'"')
			end
		end
	end
	
	if self.useFillFillTypes and length(self.fillFillTypes)==1 then
		printInfo('just 1 filltype found in "fillTypes"')
		self.fillFillType=self.fillFillTypes[1]
		self.useFillFillTypes=false
		self.fillFillTypes={}
	end
	
	self:printInfo('self.useFillFillTypes: ',self.useFillFillTypes)
	
	if self.fillFillType~=nil and self.useFillFillTypes then
		printInfo('use either "fillType" or "fillTypes" - merging both for now')
		table.insert(self.fillFillTypes,self.fillFillType,1)
		self.fillFillType=nil
	end

	self.useActivateInputBinding = false
	local activateInput = getStringFromUserAttribute(nodeId, "activateInput", "false")
	if activateInput~="false" or self.useFillFillTypes then
		self.activateInputBinding = 'ACTIVATE_OBJECT'
		if activateInput=="false" then
			activateInput = 'ACTIVATE_OBJECT'
		end
		self.useActivateInputBinding = true
		self.startFillingText = returnNilIfEmptyString(self.i18n[getStringFromUserAttribute(nodeId, "startFillingText")]) or self.i18n['siloStartFilling']
		self.stopFillingText = returnNilIfEmptyString(self.i18n[getStringFromUserAttribute(nodeId, "stopFillingText")]) or self.i18n['siloStopFilling']
		if activateInput~="true" then
			local isInputSet=false
			for k,v in pairs(InputBinding.actions) do
				if v.name==activateInput then
					isInputSet=true
					break
				end
			end
			if isInputSet==false then
				self:printErr('unknown input "',isInputSet,'" - using "ACTIVATE_OBJECT" for now')
			else
				self.activateInputBinding=activateInput
			end
		end
		self.autoDeactivate = getBoolFromUserAttribute(nodeId, "autoDeactivate", true)
		-- stationName
		local stationName = self.name
		if self.i18nNameSpace~=nil then
			stationName = ModsUtil['modNameToMod'][self.i18nNameSpace].title
		end
		self.stationName = returnNilIfEmptyString(self.i18n[getStringFromUserAttribute(nodeId, "stationName")]) or stationName
	end
	
	self.isActivated = not self.useActivateInputBinding
	
    self.fillLitersPerSecond = getNumberFromUserAttribute(nodeId, "fillLitersPerSecond", 1500, 0)
	self.createFillType = getBoolFromUserAttribute(nodeId, "createFillType", false)
    self.pricePerLiter = getNumberFromUserAttribute(nodeId, "pricePerLiter", 0)
	
	self.preferMapDefaultPrice = getBoolFromUserAttribute(nodeId, "preferMapDefaultPrice", false)
	self.pricePerLiterMultiplier = getVectorFromUserAttribute(nodeId, "pricePerLiterMultiplier", "1 1 1")
	self.pricesPerLiter = {}
	
	self.fillOnlyWholeNumbers = getBoolFromUserAttribute(nodeId, "fillOnlyWholeNumbers", false)
	self.amountToFillOfVehicle = {}
	
	-- statName
	
	self.statName=getStatNameFromUserAttribute(nodeId)

	-- spawn pallets
	
	local palletType = getStringFromUserAttribute(nodeId, "spawnPalletType")
	self:printAll('spawnPalletType '..tostring(palletType))
	local palletTypes = {}
	palletTypes["woolPallet"] = "$data/maps/models/objects/pallets/woolPallet.i3d"
	local palletFilename=getStringFromUserAttribute(nodeId, "spawnPalletFilename")

	local filename = ""
	
	if palletType~=nil then
		filename=palletTypes[palletType]
	elseif palletFilename~=nil then
		filename=palletFilename
	end
	
	if filename~="" then
		local a,_=string.find(filename,"^[$%w_%/\\%.0-9]+%.i3d$")
		if a==nil then
			self:printErr('invalid pallet filename "'..tostring(filename)..'"')
		else
			self.palletFilename = getLongFilename(filename,self.base.i18nNameSpace)
			self:printInfo('ready to spawn "',self.palletFilename,'"')
		end
	end
	
	self.palletSpawnDelay = getNumberFromUserAttribute(nodeId, "palletSpawnDelay", 1, 0.1)*1000
	self.palletSpawnPosition = getVectorFromUserAttribute(nodeId, "palletSpawnPosition", "0 0 0")
	self.palletSpawnRotation = getVectorFromUserAttribute(nodeId, "palletSpawnRotation", "0 0 0")

	-- auto allow...

	local fillTypes = {}
	if self.useFillFillTypes==false then
		table.insert(fillTypes,self.fillFillType or self:getFillType())
	else
		fillTypes=self.fillFillTypes
	end
	
	self.allowedVehicles={}
	self.allowedVehicles[UniversalProcessKit.VEHICLE_TIPPER] = getBoolFromUserAttribute(nodeId, "allowTipper", true)
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SHOVEL] = getBoolFromUserAttribute(nodeId, "allowShovel", true)
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SOWINGMACHINE] = getBoolFromUserAttribute(nodeId, "allowSowingMachine", isInTable(fillTypes,Fillable.FILLTYPE_SEEDS))
	self.allowedVehicles[UniversalProcessKit.VEHICLE_WATERTRAILER] = getBoolFromUserAttribute(nodeId, "allowWaterTrailer", isInTable(fillTypes,UniversalProcessKit.FILLTYPE_WATER))
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MILKTRAILER] = getBoolFromUserAttribute(nodeId, "allowMilkTrailer", isInTable(fillTypes,UniversalProcessKit.FILLTYPE_MILK))
	self.allowedVehicles[UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER] = getBoolFromUserAttribute(nodeId, "allowLiquidManureTrailer", isInTable(fillTypes,UniversalProcessKit.FILLTYPE_LIQUIDMANURE))
	self.allowedVehicles[UniversalProcessKit.VEHICLE_SPRAYER] = getBoolFromUserAttribute(nodeId, "allowSprayer", isInTable(fillTypes,UniversalProcessKit.FILLTYPE_FERTILIZER))
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MANURESPREADER] = getBoolFromUserAttribute(nodeId, "allowManureSpreader", isInTable(fillTypes,UniversalProcessKit.FILLTYPE_MANURE))
	
	self.allowedVehicles[UniversalProcessKit.VEHICLE_FUELTRAILER] = getBoolFromUserAttribute(nodeId, "allowFuelTrailer", isInTable(fillTypes,UniversalProcessKit.FILLTYPE_FUEL))
	self.allowedVehicles[UniversalProcessKit.VEHICLE_MOTORIZED] = getBoolFromUserAttribute(nodeId, "allowMotorized", false)
	
	self.allowPallets = getBoolFromUserAttribute(nodeId, "allowPallets", self.palletFilename~=nil)

	self.allowWalker = getBoolFromUserAttribute(nodeId, "allowWalker", false)
	
	self:addTrigger()
	
	self.dtsum=0
	
	-- actions
	self:getActionUserAttributes('IfFilling')
	self.isFilling=nil
	
	self:getActionUserAttributes('IfFillingStarted')
	self:getActionUserAttributes('IfFillingStopped')
	
	self:getActionUserAttributes('OnPalletSpawned')
	
	self:printFn('UPK_FillTrigger:new done')
	
    return self
end

function UPK_FillTrigger:delete()
	self:printFn('UPK_FillTrigger:delete()')
	UniversalProcessKitListener.removeUpdateable(self)
	if self.useActivateInputBinding then
		UniversalProcessKitListener.unregisterKeyFunction(self.activateInputBinding,self)
	end
	UPK_FillTrigger:superClass().delete(self)
end

function UPK_FillTrigger:postLoad()
	self:printFn('UPK_FillTrigger:postLoad()')
	UPK_FillTrigger:superClass().postLoad(self)
	self:triggerUpdate(false,false)
	UniversalProcessKitListener.addUpdateable(self)
	
	if self.isServer then
		self:sendEvent(UniversalProcessKitEvent.TYPE_INPUT,1,123.123,-65000.02,"test",nil,1234567890.12345678,1900,-1900.12345678)
	end
end

function UPK_FillTrigger:eventCallback(eventType,...)
	self:printFn('UPK_FillTrigger:eventCallBack(',eventType,'...)')
	if eventType==UniversalProcessKitEvent.TYPE_INPUT then
		self:printAll('UniversalProcessKitEvent.TYPE_INPUT')
		self:printAll(...)
	elseif eventType==UniversalProcessKitEvent.TYPE_FILLTYPESELECTED then
		self:printAll('UniversalProcessKitEvent.TYPE_FILLTYPESELECTED')
		self:printAll(...)
	end
end

function UPK_FillTrigger:writeStream(streamId, connection)
	self:printFn('UPK_FillTrigger:writeStream(',streamId,', ',connection,')')
	UPK_FillTrigger:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		self:printInfo('write to stream self.isActivated = ',self.isActivated)
		streamWriteBool(streamId,self.isActivated)
		self:printInfo('write to stream self.isActive = ',self.fillFillType)
		streamWriteIntN(streamId,self.fillFillType,17)
	end
end;

function UPK_FillTrigger:readStream(streamId, connection)
	self:printFn('UPK_FillTrigger:readStream(',streamId,', ',connection,')')
	UPK_FillTrigger:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		self.isActivated = streamReadBool(streamId)
		self:printInfo('read from stream self.isActivated = ',self.isActivated)
		self.fillFillType = streamReadIntN(streamId, 17)
		self:printInfo('read from stream self.fillFillType = ',self.fillFillType)
	end
end;

function UPK_FillTrigger:loadExtraNodes(xmlFile, key)
	self:printFn('UPK_FillTrigger:loadExtraNodes(',xmlFile,', ',key,')')
	self.isActivated = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isActivated"),not self.useActivateInputBinding)
	if self.useFillFillTypes then
		local selectedFillType = getXMLString(xmlFile, key .. "#selectedFillType")
		if selectedFillType~=nil then
			local fillType=UniversalProcessKit.fillTypeNameToInt[selectedFillType]
			if fillType~=nil then
				self.fillFillType=fillType
			end
		end
	end
	return true
end

function UPK_FillTrigger:getSaveExtraNodes(nodeIdent)
	self:printFn('UPK_FillTrigger:getSaveExtraNodes(',nodeIdent,')')
	local nodes=""
	if isActivated==false then
		nodes=nodes .. ' isActivated="false"'
	end
	if self.useFillFillTypes and self.fillFillType~=nil then
		nodes=nodes .. ' selectedFillType="'..UniversalProcessKit.fillTypeIntToName[self.fillFillType]..'"'
	end
	return nodes
end

function UPK_FillTrigger:triggerUpdate(vehicle,isInTrigger)
	self:printFn('UPK_FillTrigger:triggerUpdate(',vehicle,', ',isInTrigger,')')
	if true then
		for k,v in pairs(self.allowedVehicles) do
			if v and UniversalProcessKit.isVehicleType(vehicle, k) then
				if isInTrigger then
					self.amountToFillOfVehicle[vehicle]=0
					--self:print('UniversalProcessKitListener.addUpdateable('..tostring(self)..')')
					UniversalProcessKitListener.addUpdateable(self)
					if self.useActivateInputBinding then
						UniversalProcessKitListener.registerKeyFunction(self.activateInputBinding,self,'inputCallback',self.startFillingText)
					end
				else
					self.amountToFillOfVehicle[vehicle]=nil
				end
			end
		end
		
		if self.allowPallets and type(vehicle)=="table" and vehicle.isPallet and vehicle.setFillLevel~=nil then
			if isInTrigger then
				self.amountToFillOfVehicle[vehicle]=0
				--self:print('UniversalProcessKitListener.addUpdateable('..tostring(self)..')')
				UniversalProcessKitListener.addUpdateable(self)
			else
				self.amountToFillOfVehicle[vehicle]=nil
			end
		end
		
		if self.entitiesInTrigger==0 then
			if self.useActivateInputBinding then
				UniversalProcessKitListener.unregisterKeyFunction(self.activateInputBinding,self)
			end
		end
	end
end

function UPK_FillTrigger:update(dt)
	self:printAll('UPK_FillTrigger:update(',dt,')')
	
	if not self.isServer then
		return
	end
	
	if not self.isActivated and (self.isFilling==nil or self.isFilling) then
		self:operateAction('IfFillingStopped')
		self.isFilling=false
	end

	if self.useActivateInputBinding and not self.isActivated then
		UniversalProcessKitListener.removeUpdateable(self)
	end
	
	--self:printInfo('self.isEnabled ',self.isEnabled,' self.isActivated ',self.isActivated)
	if self.isEnabled and self.isActivated then
		local isFilling=false
		local addedTotally=0
		if self.entitiesInTrigger==0 then
			if self.palletFilename==nil then
				UniversalProcessKitListener.removeUpdateable(self)
				if self.useActivateInputBinding then
					UniversalProcessKitListener.unregisterKeyFunction(self.activateInputBinding,self)
				end
				if self.isFilling==nil or self.isFilling then
					self:operateAction('IfFillingStopped')
					self.isFilling=false
				end
				return
			else
				self.dtsum=self.dtsum+dt
				if self.dtsum>self.palletSpawnDelay then
					self.dtsum=0
					local x, y, z = unpack(__c({getWorldTranslation(self.nodeId)}) + self.palletSpawnPosition)
					local y_terrain = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z) + 0.2
					y = mathmax(y, y_terrain)
					local rx, ry, rz = unpack((__c({getWorldRotation(self.nodeId)}) + self.palletSpawnRotation) * (2*math.pi))
			
					local pallet = FillablePallet:new(self.isServer, self.isClient)
					if pallet:load(self.palletFilename, x, y, z, rx, ry, rz) then
						self:printAll('spawning pallet in ',x,', ',y,', ',z)
						pallet:register()
						pallet.fillType = self.fillFillType or self:getFillType() or UniversalProcessKit.FILLTYPE_UNKNOWN
						self:operateAction('OnPalletSpawned')
						if self.isFilling==nil or self.isFilling then
							self:operateAction('IfFillingStopped')
							self.isFilling=false
						end
					else
						self:printErr('couldnt load ',self.palletFilename)
					end
				end
			end
		else
			for _,trailer in pairs(self.entities) do
				--self:print('vehicle is '..tostring(trailer.upk_vehicleType))
				local deltaFillLevel = floor(self.fillLitersPerSecond * 0.001 * dt,8)
				for k,v in pairs(self.allowedVehicles) do
					--self:print('checking for '..tostring(k)..': '..tostring(v))
					if v and UniversalProcessKit.isVehicleType(trailer, k) then
						--self:print('vehicle allowed')
						local added = 0
						if k==UniversalProcessKit.VEHICLE_MIXERWAGONPICKUP then
							added = self:fillMixerWagonPickup(trailer, deltaFillLevel)
						elseif k==UniversalProcessKit.VEHICLE_MIXERWAGONTRAILER then
							added = self:fillMixerWagonTrailer(trailer, deltaFillLevel)
						elseif ((k==UniversalProcessKit.VEHICLE_TIPPER and not UniversalProcessKit.isVehicleType(trailer, UniversalProcessKit.VEHICLE_MIXERWAGONTRAILER)) or
							 (k==UniversalProcessKit.VEHICLE_SHOVEL and not UniversalProcessKit.isVehicleType(trailer, UniversalProcessKit.VEHICLE_MIXERWAGONPICKUP)) or
							 k==UniversalProcessKit.VEHICLE_SOWINGMACHINE or
							 k==UniversalProcessKit.VEHICLE_WATERTRAILER or
							 k==UniversalProcessKit.VEHICLE_MANURESPREADER or
							 k==UniversalProcessKit.VEHICLE_MILKTRAILER or
							 k==UniversalProcessKit.VEHICLE_LIQUIDMANURETRAILER or
							 k==UniversalProcessKit.VEHICLE_SPRAYER or
							 k==UniversalProcessKit.VEHICLE_FUELTRAILER) then
							added = self:fillTrailer(trailer, deltaFillLevel)
						elseif k==UniversalProcessKit.VEHICLE_MOTORIZED then
							added = self:fillMotorized(trailer, deltaFillLevel)
						end
						addedTotally=addedTotally+added
					end
				end
				if self.allowPallets and trailer.isPallet and trailer.setFillLevel~=nil then
					added = self:fillPallet(trailer, deltaFillLevel)
					addedTotally=addedTotally+added
				end
			end
			if (not self.isFilling or not isFilling) and round(addedTotally,8)>0 then
				isFilling=true
			end
		end
		if isFilling then
			if not self.isFilling then
				self:operateAction('IfFillingStarted',addedTotally)
				self.isFilling=true
			end
			self:operateAction('IfFilling',addedTotally)
		else
			if self.isFilling then
				self:operateAction('IfFillingStopped',addedTotally)
				self.isFilling=false
			end
			self:printInfo('self.useActivateInputBinding: ',self.useActivateInputBinding,' - self.autoDeactivate: ',self.autoDeactivate)
			if self.isActivated and self.useActivateInputBinding and self.autoDeactivate then
				self.isActivated=false
				UniversalProcessKitListener.unregisterKeyFunction(self.activateInputBinding,self)
				UniversalProcessKitListener.registerKeyFunction(self.activateInputBinding,self,'inputCallback',self.startFillingText)
			end
		end
	end
end

function UPK_FillTrigger:getFillLevel(fillType)
	self:printFn('UPK_FillTrigger:getFillLevel(',fillType,')')
	return UPK_FillTrigger:superClass().getFillLevel(self, fillType or self.fillFillType or self:getFillType()) or 0
end

function UPK_FillTrigger:getPricePerLiter(fillType)
	self:printFn('UPK_FillTrigger:getPricePerLiter(',fillType,')')
	fillType = fillType or self.fillFillType
	if self.pricesPerLiter[fillType]~=nil then
		return self.pricesPerLiter[fillType]
	end
	local pricePerLiter = self.pricePerLiter
	if self.preferMapDefaultPrice then
		pricePerLiter = Fillable.fillTypeIndexToDesc[fillType].pricePerLiter or pricePerLiter
	end
	local difficulty = g_currentMission.missionStats.difficulty
	local pricePerLiterAdjustment = self.pricePerLiterMultiplier[difficulty]
	if pricePerLiterAdjustment~=nil then
		pricePerLiter = pricePerLiter * pricePerLiterAdjustment
	end
	self.pricesPerLiter[fillType] = pricePerLiter
	return pricePerLiter
end

function UPK_FillTrigger:inputCallback(inputName)
	self:printFn('UPK_FillTrigger:inputCallback(',inputName,')')
	if self.activateInputBinding==inputName then
		UniversalProcessKitListener.unregisterKeyFunction(self.activateInputBinding,self)
		if self.useFillFillTypes and not self.isActivated then
			-- show dialog
			upkMultiSiloDialog:setModule(self)
			upkMultiSiloDialog:setTitle(self.stationName)
			upkMultiSiloDialog:setFillTypes(self.fillFillTypes)
			upkMultiSiloDialog:setSelectedFillType(self.fillFillType)
			upkMultiSiloDialog:setSelectionCallback(self.onFillTypeSelection, self)
			upkMultiSiloDialog:setCancelCallback(self.onFillTypeSelectionCancel, self)
			g_gui:showGui("UpkMultiSiloDialog")
		else
			self.isActivated=not self.isActivated
			local text=nil
			if self.isActivated then
				text=self.stopFillingText
			else
				text=self.startFillingText
			end
			UniversalProcessKitListener.registerKeyFunction(self.activateInputBinding,self,'inputCallback',text)
		end
	end
end

function UPK_FillTrigger:onFillTypeSelection(selectedFillType)
	self:printFn('UPK_FillTrigger:onSelectCallback(',selectedFillType,')')
	self.fillFillType=selectedFillType
	self.isActivated=true
	UniversalProcessKitListener.registerKeyFunction(self.activateInputBinding,self,'inputCallback',self.stopFillingText)
	-- event
	self:sendEvent(UniversalProcessKitEvent.TYPE_FILLTYPESELECTED,self.fillFillType)
	UniversalProcessKitListener.addUpdateable(self)
end

function UPK_FillTrigger:onFillTypeSelectionCancel()
	self:printFn('UPK_FillTrigger:onSelectCallbackCancel()')
	self.fillFillType=nil
	self.isActivated=false
	UniversalProcessKitListener.registerKeyFunction(self.activateInputBinding,self,'inputCallback',self.startFillingText)
end

function UPK_FillTrigger:fillTrailer(trailer, deltaFillLevel) -- tippers, shovels etc
	self:printFn('UPK_FillTrigger:fillTrailer(',trailer,', ',deltaFillLevel,')')
	if self.isServer and self.isEnabled then
		local fillFillType = self.fillFillType or self:getFillType() -- for single, fifo and filo
		self:printAll('fillFillType '..tostring(fillFillType))
		if fillFillType~=UniversalProcessKit.FILLTYPE_UNKNOWN then
			
			if self.fillOnlyWholeNumbers then
				self.amountToFillOfVehicle[trailer] = (self.amountToFillOfVehicle[trailer] or 0) - deltaFillLevel
				deltaFillLevel = -mathfloor(self.amountToFillOfVehicle[trailer])
				self.amountToFillOfVehicle[trailer] = self.amountToFillOfVehicle[trailer] + deltaFillLevel
			end
			
			if deltaFillLevel==0 then
				return 0
			end
			
			local trailerFillLevel = trailer:getFillLevel(trailer.currentFillType)
			local fillLevel = self:getFillLevel(fillFillType)
			--self:print('fillLevel '..tostring(fillLevel))
			--self:print('trailer:allowFillType(fillFillType, false) '..tostring(trailer:allowFillType(fillFillType, false)))
			if (fillLevel>0 or self.createFillType) and
				(fillFillType==trailer.currentFillType or trailer.currentFillType==UniversalProcessKit.FILLTYPE_UNKNOWN or
					(fillFillType~=trailer.currentFillType and trailerFillLevel<0.0001)) and
				trailer:allowFillType(fillFillType, false) and
				trailerFillLevel<trailer.capacity then
				
				trailer:resetFillLevelIfNeeded(fillFillType)
				trailerFillLevel = trailer:getFillLevel(fillFillType)
				if not self.createFillType then
					deltaFillLevel=math.min(deltaFillLevel, fillLevel)
				end
				trailer:setFillLevel(round(trailerFillLevel + deltaFillLevel,8), fillFillType)
				deltaFillLevel = trailer:getFillLevel(fillFillType) - trailerFillLevel
				if deltaFillLevel~=0 then
					if not self.createFillType then
						deltaFillLevel=-self:addFillLevel(-deltaFillLevel,fillFillType)
					end
					local pricePerLiter = self:getPricePerLiter(fillFillType)
					if pricePerLiter~=0 then
						local price = deltaFillLevel * pricePerLiter
						g_currentMission:addSharedMoney(-price, self.statName)
					end
					return deltaFillLevel
				end
			end
		end
	end
	return 0
end

function UPK_FillTrigger:fillMotorized(trailer, deltaFillLevel) -- motorized
	self:printFn('UPK_FillTrigger:fillMotorized(',trailer,', ',deltaFillLevel,')')
	if self.isServer and self.isEnabled then
		local fillFillType = self.fillFillType or self:getFillType() -- for single, fifo and filo
		self:printAll('fillFillType ',fillFillType)
		if fillFillType==UniversalProcessKit.FILLTYPE_FUEL then
			
			if self.fillOnlyWholeNumbers then
				self.amountToFillOfVehicle[trailer] = (self.amountToFillOfVehicle[trailer] or 0) - deltaFillLevel
				deltaFillLevel = -mathfloor(self.amountToFillOfVehicle[trailer])
				self.amountToFillOfVehicle[trailer] = self.amountToFillOfVehicle[trailer] + deltaFillLevel
			end
			
			if deltaFillLevel==0 then
				return 0
			end
			
			local trailerFillLevel = trailer.fuelFillLevel
			self:printAll('trailerFillLevel ',trailerFillLevel)
			local fillLevel = self:getFillLevel(fillFillType)
			self:printAll('fillLevel ',fillLevel)
			if (fillLevel>0 or self.createFillType) and round(trailerFillLevel,1)<round(trailer.fuelCapacity,1) then
				if not self.createFillType then
					deltaFillLevel=math.min(deltaFillLevel, fillLevel)
				end
				trailer:setFuelFillLevel(round(trailerFillLevel + deltaFillLevel,8))
				deltaFillLevel = trailer.fuelFillLevel - trailerFillLevel
				if deltaFillLevel~=0 then
					if not self.createFillType then
						deltaFillLevel=-self:addFillLevel(-deltaFillLevel, fillFillType)
					end
					local pricePerLiter = self:getPricePerLiter(fillFillType)
					if pricePerLiter~=0 then
						local price = deltaFillLevel * pricePerLiter
						g_currentMission:addSharedMoney(-price, self.statName)
					end
				end
				return deltaFillLevel
			end
		end
	end
	return 0
end

function UPK_FillTrigger:fillMixerWagonPickup(trailer, deltaFillLevel) -- mixing wagon pickups etc
	self:printFn('UPK_FillTrigger:fillMixerWagonPickup(',trailer,', ',deltaFillLevel,')')
	self:printAll('trailer.isTurnedOn ',trailer.isTurnedOn)
	if self.isServer and self.isEnabled and trailer.isTurnedOn==true then
		local fillFillType = self.fillFillType or self:getFillType() -- for single, fifo and filo
		self:printAll('fillFillType ',fillFillType)
		if fillFillType~=UniversalProcessKit.FILLTYPE_UNKNOWN then
			
			if self.fillOnlyWholeNumbers then
				self.amountToFillOfVehicle[trailer] = (self.amountToFillOfVehicle[trailer] or 0) - deltaFillLevel
				deltaFillLevel = -mathfloor(self.amountToFillOfVehicle[trailer])
				self.amountToFillOfVehicle[trailer] = self.amountToFillOfVehicle[trailer] + deltaFillLevel
			end
			
			if deltaFillLevel==0 then
				return 0
			end
			
			local trailerFillLevel = trailer:getFillLevel(fillFillType)
			local fillLevel = self:getFillLevel(fillFillType)
			--self:print('fillLevel '..tostring(fillLevel))
			--self:print('trailer:allowFillType(fillFillType, false) '..tostring(trailer:allowFillType(fillFillType, false)))
			
			if (fillLevel>0 or self.createFillType) and
				trailer:allowFillType(fillFillType, false) and
				trailer.fillLevel<trailer.capacity then
				
				trailer:resetFillLevelIfNeeded(fillFillType)
				trailerFillLevel = trailer:getFillLevel(fillFillType)
				if not self.createFillType then
					deltaFillLevel=math.min(deltaFillLevel, fillLevel)
				end
				trailer:setFillLevel(round(trailerFillLevel + deltaFillLevel,8), fillFillType)
				deltaFillLevel = trailer:getFillLevel(fillFillType) - trailerFillLevel
				if deltaFillLevel~=0 then
					if not self.createFillType then
						deltaFillLevel=-self:addFillLevel(-deltaFillLevel,fillFillType)
					end
					local pricePerLiter = self:getPricePerLiter(fillFillType)
					if pricePerLiter~=0 then
						local price = deltaFillLevel * pricePerLiter
						g_currentMission:addSharedMoney(-price, self.statName)
					end
					trailer.mixerWagonLastPickupTime = trailer.time
					return deltaFillLevel
				end
			end
		end
	end
	return 0
end

function UPK_FillTrigger:fillMixerWagonTrailer(trailer, deltaFillLevel) -- mixer wagon itself etc
	self:printFn('UPK_FillTrigger:fillMixerWagonTrailer(',trailer,', ',deltaFillLevel,')')
	if self.isServer and self.isEnabled then
		local fillFillType = self.fillFillType or self:getFillType() -- for single, fifo and filo
		self:printAll('fillFillType ',fillFillType)
		if fillFillType~=UniversalProcessKit.FILLTYPE_UNKNOWN then
			
			if self.fillOnlyWholeNumbers then
				self.amountToFillOfVehicle[trailer] = (self.amountToFillOfVehicle[trailer] or 0) - deltaFillLevel
				deltaFillLevel = -mathfloor(self.amountToFillOfVehicle[trailer])
				self.amountToFillOfVehicle[trailer] = self.amountToFillOfVehicle[trailer] + deltaFillLevel
			end
			
			if deltaFillLevel==0 then
				return 0
			end
			
			local trailerFillLevel = trailer:getFillLevel(fillFillType)
			local fillLevel = self:getFillLevel(fillFillType)
			--self:print('fillLevel '..tostring(fillLevel))
			--self:print('trailer:allowFillType(fillFillType, false) '..tostring(trailer:allowFillType(fillFillType, false)))
			
			if (fillLevel>0 or self.createFillType) and
				trailer:allowFillType(fillFillType, false) and
				trailer.fillLevel<trailer.capacity then
				
				trailer:resetFillLevelIfNeeded(fillFillType)
				trailerFillLevel = trailer:getFillLevel(fillFillType)
				if not self.createFillType then
					deltaFillLevel=math.min(deltaFillLevel, fillLevel)
				end
				trailer:setFillLevel(round(trailerFillLevel + deltaFillLevel,8), fillFillType)
				deltaFillLevel = trailer:getFillLevel(fillFillType) - trailerFillLevel
				if deltaFillLevel~=0 then
					if not self.createFillType then
						deltaFillLevel=-self:addFillLevel(-deltaFillLevel,fillFillType)
					end
					local pricePerLiter = self:getPricePerLiter(fillFillType)
					if pricePerLiter~=0 then
						local price = deltaFillLevel * pricePerLiter
						g_currentMission:addSharedMoney(-price, self.statName)
					end
					trailer.mixerWagonLastPickupTime = trailer.time
					return deltaFillLevel
				end
			end
		end
	end
	return 0
end

function UPK_FillTrigger:fillPallet(trailer, deltaFillLevel) -- pallets
	self:printFn('UPK_FillTrigger:fillPallet(',trailer,', ',deltaFillLevel,')')
	if self.isServer and self.isEnabled then
		local fillFillType = self.fillFillType or self:getFillType() -- for single, fifo and filo
		self:printAll('fillFillType '..tostring(fillFillType))
		if fillFillType~=UniversalProcessKit.FILLTYPE_UNKNOWN then
			
			if self.fillOnlyWholeNumbers then
				self.amountToFillOfVehicle[trailer] = (self.amountToFillOfVehicle[trailer] or 0) - deltaFillLevel
				deltaFillLevel = -mathfloor(self.amountToFillOfVehicle[trailer])
				self.amountToFillOfVehicle[trailer] = self.amountToFillOfVehicle[trailer] + deltaFillLevel
			end
			
			if deltaFillLevel==0 then
				return 0
			end
			
			local trailerFillType = trailer:getFillType()
			local trailerFillLevel = trailer:getFillLevel()
			local fillLevel = self:getFillLevel(fillFillType)
			--self:print('fillLevel '..tostring(fillLevel))
			--self:print('trailer:allowFillType(fillFillType, false) '..tostring(trailer:allowFillType(fillFillType, false)))
			if (fillLevel>0 or self.createFillType) and
				fillFillType==trailerFillType and
				trailerFillLevel<trailer.capacity then
				
				if not self.createFillType then
					deltaFillLevel=math.min(deltaFillLevel, fillLevel)
				end
				trailer:setFillLevel(round(trailerFillLevel + deltaFillLevel,8), fillFillType)
				deltaFillLevel = trailer:getFillLevel() - trailerFillLevel
				if deltaFillLevel~=0 then
					if not self.createFillType then
						deltaFillLevel=-self:addFillLevel(-deltaFillLevel,fillFillType)
					end
					local pricePerLiter = self:getPricePerLiter(fillFillType)
					if pricePerLiter~=0 then
						local price = deltaFillLevel * pricePerLiter
						g_currentMission:addSharedMoney(-price, self.statName)
					end
					return deltaFillLevel
				end
			end
		end
	end
	return 0
end

function UPK_FillTrigger:getIsActivatable(trailer)
	self:printFn('UPK_FillTrigger:getIsActivatable(',trailer,')')
	local fillFillType = self.fillFillType or self:getFillType()
	if trailer:allowFillType(fillFillType, false) and
		(self:getFillLevel(fillFillType)>0 or self.createFillType) then
		return true
	end
	return false
end
