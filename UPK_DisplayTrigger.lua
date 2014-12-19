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
		for fillType,display in pairs(self.displayFillTypes) do
			--self:print('want to display '..tostring(fillType)..': '..tostring(display))
			if display then
				local fillLevel=self:getFillLevel(fillType) or 0
				--self:print('fillLevel = '..tostring(fillLevel)..', self.onlyFilled = '..tostring(self.onlyFilled))
				if fillLevel>0 or not self.onlyFilled then
					local text=self.i18n[UniversalProcessKit.fillTypeIntToName[fillType]]
					if text~="" then
						text=text..": "
					else
						text="["..UniversalProcessKit.fillTypeIntToName[fillType].."]: "
					end
					if self.showFillLevel then
						text=text..mathceil(fillLevel) .. "[" .. self.i18n["fluid_unit_short"] .. "]"
					end
					if self.showPercentage then
						local capacity = self:getCapacity(fillType)
						local ratio = mathceil(fillLevel/capacity*100)
						if ratio==100 and round(fillLevel,1)<capacity then
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
