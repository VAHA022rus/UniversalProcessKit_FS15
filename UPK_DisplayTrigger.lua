-- by mor2000

--------------------
-- DisplayTrigger (shows sth in the top left hud)

local UPK_DisplayTrigger_mt = ClassUPK(UPK_DisplayTrigger,UniversalProcessKit)
InitObjectClass(UPK_DisplayTrigger, "UPK_DisplayTrigger")
UniversalProcessKit.addModule("displaytrigger",UPK_DisplayTrigger)

function UPK_DisplayTrigger:new(nodeId, parent)
	local self = UniversalProcessKit:new(nodeId, parent, UPK_DisplayTrigger_mt)
	registerObjectClassName(self, "UPK_DisplayTrigger")
	
	self.onlyFilled = getBoolFromUserAttribute(self.nodeId, "onlyFilled", true)
	self.showFillLevel = getBoolFromUserAttribute(self.nodeId, "showFillLevel", true)
	self.showPercentage = getBoolFromUserAttribute(self.nodeId, "showPercentage", true)

	self.displayFillTypes={}
	
	local displayFillTypesArr = getArrayFromUserAttribute(self.nodeId, "displayFillTypes")
	for _,fillType in pairs(UniversalProcessKit.fillTypeNameToInt(displayFillTypesArr)) do
		self.displayFillTypes[fillType] = true
	end
	
	self.displayTexts={}
	for fillType,_ in pairs(self.displayFillTypes) do
		local i18n_key=UniversalProcessKit.fillTypeIntToName[fillType]
		local text=""
		if self.i18nNameSpace~=nil and (_g or {})[self.i18nNameSpace]~=nil and _g[self.i18nNameSpace].g_i18n~=nil and _g[self.i18nNameSpace].g_i18n:hasText(i18n_key) then
			text=_g[self.i18nNameSpace].g_i18n:getText(i18n_key)
		elseif g_i18n:hasText(i18n_key) then
			text=g_i18n:getText(i18n_key)
		end
		self.displayTexts[fillType]=text
	end
	
	self.fluid_unit_short=g_i18n:getText("fluid_unit_short")
	
	self:addTrigger()

	self:print('loaded DisplayTrigger successfully')

	return self
end

function UPK_DisplayTrigger:delete()
	UPK_DisplayTrigger:superClass().delete(self)
end

function UPK_DisplayTrigger:triggerUpdate(vehicle,isInTrigger)
	if self.isClient then
		if self.entitiesInTrigger>0 and self:getShowInfo() then
			UniversalProcessKitListener.addUpdateable(self)
		else
			UniversalProcessKitListener.removeUpdateable(self)
		end
	end
end

function UPK_DisplayTrigger:update(dt)
	if self.isEnabled then
		for fillType,display in pairs(self.displayFillTypes) do
			if display then
				self:print('want to display '..tostring(fillType))
				local fillLevel=self:getFillLevel(fillType)
				self:print('fillLevel is '..tostring(fillLevel))
				if fillLevel>0 or not self.onlyFilled then
					local text=self.displayTexts[fillType] or ""
					if text~="" then
						text=text..": "
					end
					if self.showFillLevel then
						text=text..mathceil(fillLevel) .. "[" .. self.fluid_unit_short .. "]"
					end
					if self.showPercentage then
						local capacity = self.storageController:getStorageBitCapacity(fillType)
						local ratio = mathceil(fillLevel/capacity*100)
						if ratio==100 and fillLevel<capacity then
							ratio = 99
						end
						text=text.." "..tostring(ratio) .. "%"
					end
	    			g_currentMission:addExtraPrintText(text)
				end
			end
		end
	end
end
