-- by mor2000

--------------------
-- DisplayTrigger (shows sth in the top left hud)

local UPK_DisplayTrigger_mt = ClassUPK(UPK_DisplayTrigger,UniversalProcessKit)
InitObjectClass(UPK_DisplayTrigger, "UPK_DisplayTrigger")
UniversalProcessKit.addModule("displaytrigger",UPK_DisplayTrigger)


local countriesUsingCommas={"al", "ad", "ao", "ar", "am", "at", "az", "by", "be", "bo", "ba", "br", "bg", "cm", "cl", "cr", "hr", "cu", "cy", "cz", "dk", "ec", "ee", "fo", "fi", "fr", "de", "ge", "gr", "gl", "hu", "is", "in", "it", "kz", "kg", "lv", "lb", "lt", "lu", "mo", "mk", "md", "mn", "ma", "mz", "nl", "no", "py", "pe", "pl", "pt", "ro", "ru", "cs", "sk", "sm", "za", "es", "ch", "se", "tn", "tr", "ua", "uy", "uz", "ve", "vn"}
local isCountryUsingComma=isInTable(countriesUsingCommas,g_languageShort)

function UPK_DisplayTrigger:new(nodeId, parent)
	local self = UniversalProcessKit:new(nodeId, parent, UPK_DisplayTrigger_mt)
	registerObjectClassName(self, "UPK_DisplayTrigger")
	
	self.onlyFilled = getBoolFromUserAttribute(nodeId, "onlyFilled", true)
	self.showFillLevel = getBoolFromUserAttribute(nodeId, "showFillLevel", true)
	self.showFillLevelDecimals = getNumberFromUserAttribute(nodeId, "showFillLevelDecimals", 0, 0, 6)
	self.showCapacity = getBoolFromUserAttribute(nodeId, "showCapacity", false)
	self.showCapacityDecimals = getNumberFromUserAttribute(nodeId, "showCapacityDecimals", self.showFillLevelDecimals, 0, 6)
	self.showPercentage = getBoolFromUserAttribute(nodeId, "showPercentage", true)
	self.showPercentageDecimals = getNumberFromUserAttribute(nodeId, "showPercentageDecimals", 0, 0, 6)
	
	useLongUnitNames = getBoolFromUserAttribute(nodeId, "useLongUnitNames", false)
	
	self.useUnitNames = "_unit_short"
	if useLongUnitNames then
		self.useUnitNames = "_unit_long"
	end

	self.displayFillTypes={}
	self.displayFillTypesOrder={}
	local displayFillTypesArr = UniversalProcessKit.fillTypeNameToInt(getArrayFromUserAttribute(nodeId, "displayFillTypes"))
	
	for i=1,length(displayFillTypesArr) do
		self.displayFillTypes[displayFillTypesArr[i]] = true
		table.insert(self.displayFillTypesOrder,displayFillTypesArr[i])
	end
	
	self.displayFillTypesOrderLength = length(self.displayFillTypesOrder)

	self:addTrigger()

	self:print('loaded DisplayTrigger successfully')

	return self
end

function UPK_DisplayTrigger:delete()
	UPK_DisplayTrigger:superClass().delete(self)
end

function UPK_DisplayTrigger:triggerUpdate(vehicle,isInTrigger)
	--self:print('UPK_DisplayTrigger:triggerUpdate('..tostring(vehicle)..','..tostring(isInTrigger)..')')
	--self:print('entitiesInTrigger = '..tostring(self.entitiesInTrigger))
	if self.entitiesInTrigger>0 then
		--self:print('UniversalProcessKitListener.addUpdateable()')
		UniversalProcessKitListener.addUpdateable(self)
	else
		--self:print('UniversalProcessKitListener.removeUpdateable()')
		UniversalProcessKitListener.removeUpdateable(self)
	end
end

function UPK_DisplayTrigger:update(dt)
	--self:print('UPK_DisplayTrigger:update('..tostring(dt)..')')
	if self.isEnabled and self:getShowInfo() then
		--self:print('enable printing')
		for i=1,self.displayFillTypesOrderLength do
			fillType = self.displayFillTypesOrder[i]
			display = self.displayFillTypes[fillType]
			--self:print('want to display '..tostring(fillType)..': '..tostring(display))
			if display then
				local fillLevel=self:getFillLevel(fillType) or 0
				--self:print('fillLevel = '..tostring(fillLevel)..', self.onlyFilled = '..tostring(self.onlyFilled))
				if fillLevel>0 or not self.onlyFilled then
					local text=(returnNilIfEmptyString(self.i18n[UniversalProcessKit.fillTypeIntToName[fillType]]) or ("["..UniversalProcessKit.fillTypeIntToName[fillType].."]"))..": "
					local capacity
					if self.showFillLevel then
						local nrStr=string.format('%.'..tostring(self.showFillLevelDecimals)..'f',fillLevel)
						if isCountryUsingComma then
							nrStr=string.gsub(nrStr,"%.",",")
						end
						
						if self.showCapacity then
							capacity = self:getCapacity(fillType)
							if capacity<math.huge then
								local nrStr2=string.format('%.'..tostring(self.showCapacityDecimals)..'f',capacity)
								if isCountryUsingComma then
									nrStr2=string.gsub(nrStr2,"%.",",")
								end
								nrStr=nrStr.." / "..nrStr2
							end
						end
						text=text.. nrStr .. " [" .. (returnNilIfEmptyString(self.i18n[UniversalProcessKit.fillTypeIntToName[fillType]..self.useUnitNames]) or self.i18n["fluid"..self.useUnitNames]) .. "]"
					end
					
					
					if self.showPercentage then
						capacity = capacity or self:getCapacity(fillType)
						if capacity<math.huge then
							local ratio = round(fillLevel/capacity*100, self.showPercentageDecimals)
							if ratio==100 and round(fillLevel,1)<capacity then
								ratio = 99
							end
							local nrStr = string.format('%.'..tostring(self.showPercentageDecimals)..'f',ratio)
							if isCountryUsingComma then
								nrStr=string.gsub(nrStr,"%.",",")
							end
							text=text.." ".. nrStr  .. "%"
						end
					end
	    			g_currentMission:addExtraPrintText(text)
				end
			end
		end
	end
end
