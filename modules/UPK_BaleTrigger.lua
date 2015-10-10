-- by mor2000

--------------------
-- BaleTrigger


local UPK_BaleTrigger_mt = ClassUPK(UPK_BaleTrigger,UniversalProcessKit)
InitObjectClass(UPK_BaleTrigger, "UPK_BaleTrigger")
UniversalProcessKit.addModule("baletrigger",UPK_BaleTrigger)

function UPK_BaleTrigger:new(nodeId, parent)
	printFn('UPK_BaleTrigger:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId, parent, UPK_BaleTrigger_mt)
	registerObjectClassName(self, "UPK_BaleTrigger")
	
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
	
	self.revenueMultiplier = getVectorFromUserAttribute(nodeId, "revenueMultiplier", "1 1 1")
	
	self.statName=getStatNameFromUserAttribute(nodeId)
	
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
	
	--actions
	self:getActionUserAttributes('OnEnter')
	self:getActionUserAttributes('OnLeave')
	self:getActionUserAttributes('OnDelete')
	
	self:getActionUserAttributes('IfDissolved')
	self:getActionUserAttributes('IfSold')
	
	self:printFn('UPK_BaleTrigger:new done')
	
	return self
end

function UPK_BaleTrigger:delete()
	self:printFn('UPK_BaleTrigger:delete()')
	UniversalProcessKitListener.removeUpdateable(self)
	UPK_BaleTrigger:superClass().delete(self)
end

function UPK_BaleTrigger:postLoad()
	self:printFn('UPK_BaleTrigger:postLoad()')
	UPK_BaleTrigger:superClass().postLoad(self)
	self:triggerUpdate(false,false)
end

function UPK_BaleTrigger:triggerUpdate(vehicle,isInTrigger)
	self:printFn('UPK_BaleTrigger:triggerUpdate(',vehicle,', ',isInTrigger,')')
	if self.isEnabled then
		self:printAll('vehicle is: '..tostring(vehicle))
		if type(vehicle)=="table" and vehicle:isa(Bale) then
			self:printAll('isInTrigger is: '..tostring(isInTrigger))
			if isInTrigger then
				if self.balesInTrigger[vehicle]==nil then
					local fillType = vehicle:getFillType()
					local isRoundBale = vehicle.isRoundbale
					if isRoundBale==nil then
						isRoundBale = Utils.getNoNil(getUserAttribute(vehicle.nodeId, "isRoundbale"), false)
						vehicle.isRoundbale = isRoundBale
					end
					self:printAll('fillType is: '..tostring(fillType))
					self:printAll('self.acceptedFillTypes[fillType] is: '..tostring(self.acceptedFillTypes[fillType]))
					self:printAll('isRoundBale is: '..tostring(isRoundBale))
					self:printAll('acceptRoundBales is: '..tostring(self.acceptRoundBales))
					self:printAll('acceptSquareBales is: '..tostring(self.acceptSquareBales))
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
						self:printAll('This kind of bale is not accepted')
					end
					self:operateAction('OnEnter')
				end
			else
				if self.balesInTrigger[vehicle]~=nil then
					self.balesInTrigger[vehicle]=nil
					self.nrBalesInTrigger = self.nrBalesInTrigger -1
					self:operateAction('OnLeave')
				end
			end
		end
	end
end

function UPK_BaleTrigger:update(dt)
	self:printAll('UPK_BaleTrigger:update(',dt,')')
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
				local fillLevel = bale:getFillLevel()
				local fillType = bale:getFillType()
				if self.mode=="dissolve" then
					local added = self:addFillLevel(fillLevel, fillType)
					self:operateAction('IfDissolved',added)
					self:deleteBale(bale,baleIndex)
				elseif self.mode=="delete" then
					self:deleteBale(bale,baleIndex)
				elseif self.mode=="save" then
					-- nothing yet
				else
					self:printAll('want to sell bale for '..tostring(bale:getValue()))
					local difficulty = g_currentMission.missionStats.difficulty
					local revenue = 0
					if self.revenuesPerLiter[fillType]~=nil then
						revenue = self.revenuesPerLiter[fillType] * fillLevel * self.revenueMultiplier[difficulty]
					else 
						revenue = bale:getValue() * self.revenueMultiplier[difficulty]
					end
					if revenue~=0 then
						g_currentMission:addSharedMoney(revenue, self.statName)
					end
					self:operateAction('IfSold',fillLevel)
					self:deleteBale(bale,baleIndex)
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

function UPK_BaleTrigger:deleteBale(bale,baleIndex)
	self:printFn('UPK_BaleTrigger:deleteBale(',baleId,',',baleIndex,')')
	self.balesInTrigger[bale]=nil
	table.remove(self.balesInLine,baleIndex)
	self.nrBalesInTrigger = self.nrBalesInTrigger -1
	self:triggerOnLeave(bale)
	bale:delete()
	self:operateAction('OnDelete')
end