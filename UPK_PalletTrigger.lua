-- by mor2000

--------------------
-- PalletTrigger


local UPK_PalletTrigger_mt = ClassUPK(UPK_PalletTrigger,UniversalProcessKit)
InitObjectClass(UPK_PalletTrigger, "UPK_PalletTrigger")
UniversalProcessKit.addModule("pallettrigger",UPK_PalletTrigger)

function UPK_PalletTrigger:new(nodeId, parent)
	local self = UniversalProcessKit:new(nodeId, parent, UPK_PalletTrigger_mt)
	registerObjectClassName(self, "UPK_PalletTrigger")
	
	-- acceptedFillTypes
	
	self.acceptedFillTypes = {}
	
	local acceptedFillTypesArr = getArrayFromUserAttribute(nodeId, "acceptedFillTypes")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(acceptedFillTypesArr)) do
		self:print('accepting '..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(fillType)..')')
		self.acceptedFillTypes[fillType] = true
		--self.fillTypesConversionMatrix = self.fillTypesConversionMatrix + FillTypesConversionMatrix:new(fillType)
	end
	
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
	
	self.statName=getStringFromUserAttribute(nodeId, "statName")
	local validStatName=false
	if self.statName~=nil then
		for _,v in pairs(FinanceStats.statNames) do
			if self.statName==v then
				validStatName=true
				break
			end
		end
	end
	if not validStatName then
		self.statName="other"
	end
	
	self.palletsInLine = {}
	self.runningUpdate = false

	self:addTrigger()
	
	self:print('loaded PalletTrigger successfully')
	
	return self
end

function UPK_PalletTrigger:delete()
	UniversalProcessKitListener.removeUpdateable(self)
	UPK_PalletTrigger:superClass().delete(self)
end

function UPK_PalletTrigger:postLoad()
	UPK_PalletTrigger:superClass().postLoad(self)
	self:triggerUpdate(false,false)
end

function UPK_PalletTrigger:triggerUpdate(vehicle,isInTrigger)
	self:print('UPK_PalletTrigger:triggerUpdate')
	if self.isEnabled then
		self:print('vehicle is: '..tostring(vehicle))
		if type(vehicle)=="table" and vehicle.isPallet then
			self:print('isInTrigger is: '..tostring(isInTrigger))
			if isInTrigger then
				if not self.palletsInTrigger[vehicle] then
					local fillType = vehicle:getFillType()
				
					self:print('fillType is: '..tostring(fillType))
					self:print('self.acceptedFillTypes[fillType] is: '..tostring(self.acceptedFillTypes[fillType]))
				
					if self.acceptedFillTypes[fillType] then
						self.palletsInTrigger[vehicle]=true
						table.insert(self.palletsInLine,vehicle)
						self.nrPalletsInTrigger = self.nrPalletsInTrigger +1
						self:print('self.nrPalletsInTrigger is: '..tostring(self.nrPalletsInTrigger))
						if self.nrPalletsInTrigger>self.ignorePallets then
							if not self.runningUpdate then
								self.runningUpdate = true
								self.dtsum = 0
								UniversalProcessKitListener.addUpdateable(self)
							end
						end
					else
						self:print('This kind of pallet is not accepted')
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
					self:print('want to sell pallet for '..tostring(pallet:getValue()))
					self.palletsInTrigger[pallet]=nil
					self.nrPalletsInTrigger = self.nrPalletsInTrigger -1
					local fillType = pallet:getFillType()
					local difficulty = g_currentMission.missionStats.difficulty
					local revenue = pallet:getValue() * self.revenueMultiplier[difficulty]
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
