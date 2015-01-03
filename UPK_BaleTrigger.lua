-- by mor2000

--------------------
-- BaleTrigger


local UPK_BaleTrigger_mt = ClassUPK(UPK_BaleTrigger,UniversalProcessKit)
InitObjectClass(UPK_BaleTrigger, "UPK_BaleTrigger")
UniversalProcessKit.addModule("baletrigger",UPK_BaleTrigger)

function UPK_BaleTrigger:new(nodeId, parent)
	local self = UniversalProcessKit:new(nodeId, parent, UPK_BaleTrigger_mt)
	registerObjectClassName(self, "UPK_BaleTrigger")
	
	-- acceptedFillTypes
	
	self.acceptedFillTypes = {}
	
	local acceptedFillTypesArr = getArrayFromUserAttribute(nodeId, "acceptedFillTypes")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(acceptedFillTypesArr)) do
		self:print('accepting '..tostring(UniversalProcessKit.fillTypeIntToName[fillType])..' ('..tostring(fillType)..')')
		self.acceptedFillTypes[fillType] = true
		--self.fillTypesConversionMatrix = self.fillTypesConversionMatrix + FillTypesConversionMatrix:new(fillType)
	end
	
	self.acceptRoundBales = getBoolFromUserAttribute(nodeId, "acceptRoundBales", true)
	self.acceptSquareBales = getBoolFromUserAttribute(nodeId, "acceptSquareBales", true)
	
	self.ignoreBales = getNumberFromUserAttribute(nodeId, "ignoreBales", 0)
	self.useFirstBale = getBoolFromUserAttribute(nodeId, "useFirstBale", true)
	
	self.delay = getNumberFromUserAttribute(nodeId, "delay", 0.1, 0)*1000
	
	self.allowBales = true
	self.allowWalker = false
	self.allowedVehicles={}
	
	self.balesInTrigger = {}
	self.nrBalesInTrigger = 0
	
	self.mode = getStringFromUserAttribute(nodeId, "mode", "sell")
	
	self.revenueMultiplier = getVectorFromUserAttribute(id, "revenueMultiplier", "1 1 1")
	
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
	
	--[[
	baleTypes
	
	roundbaleGrass_w112_d130 -- baleExtension
	roundbaleHay_w112_d130
	roundbaleHayWrapped_w112_d130 -- baleExtension
	roundbaleSilage_w112_d130
	roundbaleStraw_w112_d130
	
	baleHay240
	baleStraw240
	
	
	
	Utils.endsWith(filename, baleTypes..".i3d")
	Utils.getFilenameInfo -- return cleanFilename, extension
	
	local str="/data/xyz/filename.i3d";
	
	function getBaleType(filename)
		local filenamei3d = string.sub(filename, string.find(filename,"%w+%.i3d"))
		local cleanFilename = Utils.getFilenameInfo(filenamei3d)
		return cleanFilename
	end
	
	]]--
	
	self.balesInLine = {}
	self.runningUpdate = false

	self:addTrigger()
	
	self:print('loaded BaleTrigger successfully')
	
	return self
end

function UPK_BaleTrigger:postLoad()
	UPK_BaleTrigger:superClass().postLoad(self)
	self:triggerUpdate(false,false)
end

function UPK_BaleTrigger:triggerUpdate(vehicle,isInTrigger)
	self:print('UPK_BaleTrigger:triggerUpdate')
	if self.isEnabled then
		self:print('vehicle is: '..tostring(vehicle))
		if type(vehicle)=="table" and vehicle:isa(Bale) then
			self:print('isInTrigger is: '..tostring(isInTrigger))
			if isInTrigger then
				local fillType = vehicle:getFillType()
				local isRoundBale = vehicle.isRoundbale
				if isRoundBale==nil then
					isRoundBale = Utils.getNoNil(getUserAttribute(vehicle.nodeId, "isRoundbale"), false)
					vehicle.isRoundbale = isRoundBale
				end
				self:print('fillType is: '..tostring(fillType))
				self:print('self.acceptedFillTypes[fillType] is: '..tostring(self.acceptedFillTypes[fillType]))
				self:print('isRoundBale is: '..tostring(isRoundBale))
				self:print('acceptRoundBales is: '..tostring(self.acceptRoundBales))
				self:print('acceptSquareBales is: '..tostring(self.acceptSquareBales))
				if self.acceptedFillTypes[fillType] and ((isRoundBale and self.acceptRoundBales) or (not isRoundBale and self.acceptSquareBales)) then
					self.balesInTrigger[vehicle]=true
					table.insert(self.balesInLine,vehicle)
					self.nrBalesInTrigger = self.nrBalesInTrigger +1
					self:print('self.nrBalesInTrigger is: '..tostring(self.nrBalesInTrigger))
					if self.nrBalesInTrigger>self.ignoreBales then
						if not self.runningUpdate then
							self.runningUpdate = true
							self.dtsum = 0
							UniversalProcessKitListener.addUpdateable(self)
						end
					end
				else
					self:print('This kind of bale is not accepted')
				end
			else
				self.balesInTrigger[vehicle]=nil
			end
		end
	end
end

function UPK_BaleTrigger:update(dt)
	self.dtsum = self.dtsum + dt
	
	if self.dtsum>self.delay then
		self.dtsum = self.dtsum-self.delay
	
		if #self.balesInLine>self.ignoreBales then
			local baleIndex = 1
			if not self.useFirstBale then
				baleIndex = #self.balesInLine
			end

			local bale = self.balesInLine[baleIndex]
			if type(bale)=="table" and self.balesInTrigger[bale] then
				if self.mode=="dissolve" then
				    local fillLevel = bale:getFillLevel()
				    local fillType = bale:getFillType()
					local added = self:addFillLevel(fillLevel, fillType)
					if added > 0 then
						self.balesInTrigger[bale]=nil
						table.remove(self.balesInLine,baleIndex)
						bale:delete()
					end
				elseif self.mode=="delete" then
					self.balesInTrigger[bale]=nil
					table.remove(self.balesInLine,baleIndex)
					bale:delete()
				elseif self.mode=="save" then
					-- nothing yet
				else
					self:print('want to sell bale for '..tostring(bale:getValue()))
					self.balesInTrigger[bale]=nil
					self.nrBalesInTrigger = self.nrBalesInTrigger -1
					local fillType = bale:getFillType()
					local difficulty = g_currentMission.missionStats.difficulty
					local revenue = bale:getValue() * self.revenueMultiplier[difficulty]
					if revenue~=0 then
						g_currentMission:addSharedMoney(revenue, self.statName)
					end
					self.balesInTrigger[bale]=nil
					table.remove(self.balesInLine,baleIndex)
					bale:delete()
				end
			else
				self.balesInTrigger[bale]=nil
				table.remove(self.balesInLine,baleIndex)
				self:update(0)
			end
		end
	end

	if #self.balesInLine<=self.ignoreBales then
		self.runningUpdate = false
		UniversalProcessKitListener.removeUpdateable(self)
	else
		if self.dtsum>self.delay then
			self:update(0)
		end
	end
end
