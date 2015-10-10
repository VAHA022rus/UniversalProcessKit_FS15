-- by mor2000

--------------------
-- PalletTrigger


local UPK_PalletTrigger_mt = ClassUPK(UPK_PalletTrigger,UniversalProcessKit)
InitObjectClass(UPK_PalletTrigger, "UPK_PalletTrigger")
UniversalProcessKit.addModule("pallettrigger",UPK_PalletTrigger)

function UPK_PalletTrigger:new(nodeId, parent)
	printFn('UPK_PalletTrigger:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId, parent, UPK_PalletTrigger_mt)
	registerObjectClassName(self, "UPK_PalletTrigger")
	
	-- acceptedFillTypes
	
	self.acceptedFillTypes = {}
	
	local acceptedFillTypesArr = getArrayFromUserAttribute(nodeId, "acceptedFillTypes")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(acceptedFillTypesArr)) do
		self:printInfo('accepting '..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(fillType)..')')
		self.acceptedFillTypes[fillType] = true
		--self.fillTypesConversionMatrix = self.fillTypesConversionMatrix + FillTypesConversionMatrix:new(fillType)
	end
	
	self.revenuePerLiter = getNumberFromUserAttribute(nodeId, "revenuePerLiter", nil)
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
	
	self.ignorePallets = getNumberFromUserAttribute(nodeId, "ignorePallets", 0)
	self.useFirstPallet = getBoolFromUserAttribute(nodeId, "useFirstPallet", true)
	
	self.delay = getNumberFromUserAttribute(nodeId, "delay", 0.1, 0)*1000
	
	self.allowPallets = true
	self.allowWalker = false
	self.allowedVehicles={}
	
	self.palletsInTrigger = {}
	self.nrPalletsInTrigger = 0
	
	self.mode = getStringFromUserAttribute(nodeId, "mode", "sell")
	
	self.revenueMultiplier = getVectorFromUserAttribute(nodeId, "revenueMultiplier", "1 0.5 0.25")
	
	self.statName=getStatNameFromUserAttribute(nodeId)
	
	self.palletsInLine = {}
	self.runningUpdate = false

	self:addTrigger()
	
	self:printFn('UPK_PalletTrigger:new done')
	
	return self
end

function UPK_PalletTrigger:delete()
	self:printFn('UPK_PalletTrigger:delete()')
	UniversalProcessKitListener.removeUpdateable(self)
	UPK_PalletTrigger:superClass().delete(self)
end

function UPK_PalletTrigger:postLoad()
	self:printFn('UPK_PalletTrigger:postLoad()')
	UPK_PalletTrigger:superClass().postLoad(self)
	self:triggerUpdate(false,false)
end

function UPK_PalletTrigger:triggerUpdate(vehicle,isInTrigger)
	self:printFn('UPK_PalletTrigger:triggerUpdate(',vehicle,', ',isInTrigger,')')
	if self.isEnabled then
		self:printAll('vehicle is: ',vehicle)
		if type(vehicle)=="table" and vehicle.isPallet then
			self:printAll('isInTrigger is: ',isInTrigger)
			if isInTrigger then
				if not self.palletsInTrigger[vehicle] then
					local fillType = vehicle:getFillType()
				
					self:printAll('fillType is: ',fillType)
					self:printAll('self.acceptedFillTypes[fillType] is: ',self.acceptedFillTypes[fillType])
				
					if self.acceptedFillTypes[fillType] then
						self.palletsInTrigger[vehicle]=true
						table.insert(self.palletsInLine,vehicle)
						self.nrPalletsInTrigger = self.nrPalletsInTrigger +1
						self:printAll('self.nrPalletsInTrigger is: ',self.nrPalletsInTrigger)
						if self.nrPalletsInTrigger>self.ignorePallets then
							if not self.runningUpdate then
								self.runningUpdate = true
								self.dtsum = 0
								UniversalProcessKitListener.addUpdateable(self)
							end
						end
					else
						self:printInfo('This kind of pallet is not accepted')
					end
				end
			else
				self.palletsInTrigger[vehicle]=nil
				self.nrPalletsInTrigger = self.nrPalletsInTrigger -1
			end
		end
	end
end

function UPK_PalletTrigger:update(dt)
	self:printAll('UPK_PalletTrigger:update(',dt,')')
	self.dtsum = self.dtsum + dt
	
	if self.dtsum>self.delay then
		self.dtsum = self.dtsum-self.delay
	
		if #self.palletsInLine>self.ignorePallets then
			local palletIndex = 1
			if not self.useFirstPallet then
				palletIndex = #self.palletsInLine
			end

			local pallet = self.palletsInLine[palletIndex]
			if type(pallet)=="table" and self.palletsInTrigger[pallet] then
				if self.mode=="dissolve" then
				    local fillLevel = pallet:getFillLevel()
				    local fillType = pallet:getFillType()
					local added = self:addFillLevel(fillLevel, fillType)
					if added > 0 then
						self.palletsInTrigger[pallet]=nil
						table.remove(self.palletsInLine,palletIndex)
						self:triggerUpdate(pallet,false)
						if self.isServer then
							pallet:delete()
						end
					end
				elseif self.mode=="delete" then
					self.palletsInTrigger[pallet]=nil
					table.remove(self.palletsInLine,palletIndex)
					self:triggerUpdate(pallet,false)
					if self.isServer then
						pallet:delete()
					end
				elseif self.mode=="save" then
					-- nothing yet
				else
					self:printAll('want to sell pallet for ',pallet:getValue())
					self.palletsInTrigger[pallet]=nil
					self.nrPalletsInTrigger = self.nrPalletsInTrigger -1
					local fillType = pallet:getFillType()
					local difficulty = g_currentMission.missionStats.difficulty
					local revenue = 0
					if self.revenuesPerLiter[fillType]~=nil then
						revenue = self.revenuesPerLiter[fillType] * pallet.fillLevel * self.revenueMultiplier[difficulty]
					else 
						revenue = pallet:getValue() * self.revenueMultiplier[difficulty]
					end
					if revenue~=0 then
						g_currentMission:addSharedMoney(revenue, self.statName)
					end
					self.palletsInTrigger[pallet]=nil
					table.remove(self.palletsInLine,palletIndex)
					self:triggerUpdate(pallet,false)
					if self.isServer then
						pallet:delete()
					end
				end
			else
				self.palletsInTrigger[pallet]=nil
				table.remove(self.palletsInLine,palletIndex)
				self:update(0)
			end
		end
	end

	if #self.palletsInLine<=self.ignorePallets then
		self.runningUpdate = false
		UniversalProcessKitListener.removeUpdateable(self)
	else
		if self.dtsum>self.delay then
			self:update(0)
		end
	end
end
