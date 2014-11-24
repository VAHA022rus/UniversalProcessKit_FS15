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
				local fillLevel=self:getFillLevel(fillType)
				if fillLevel>0 or not self.onlyFilled then
					local text=self.i18n[UniversalProcessKit.fillTypeIntToName[fillType]]
					if text~="" then
						text=text..": "
					end
					if self.showFillLevel then
						text=text..mathceil(fillLevel) .. "[" .. self.i18n["fluid_unit_short"] .. "]"
					end
					if self.showPercentage then
						local capacity = self:getCapacity(fillType)
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
