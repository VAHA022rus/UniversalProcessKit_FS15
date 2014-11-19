-- by mor2000

--------------------
-- EntityTrigger (enables modules if vehicle or walker is present)


local UPK_EntityTrigger_mt = ClassUPK(UPK_EntityTrigger,UniversalProcessKit)
InitObjectClass(UPK_EntityTrigger, "UPK_EntityTrigger")
UniversalProcessKit.addModule("entitytrigger",UPK_EntityTrigger)

function UPK_EntityTrigger:new(nodeId, parent)
	local self = UniversalProcessKit:new(nodeId, parent, UPK_EntityTrigger_mt)
	registerObjectClassName(self, "UPK_EntityTrigger")
	
	self.enableOnEmpty = getBoolFromUserAttribute(nodeId, "enableOnEmpty", false)
	
	self.isEnabledChildren = not self.enableOnEmpty

	self:addTrigger()
	
	self:print('loaded EntityTrigger successfully')
	
	return self
end

function UPK_EntityTrigger:triggerUpdate(vehicle,isInTrigger)
	self:print('UPK_EntityTrigger:triggerUpdate')
	if self.isEnabled then
		self:print('self.entitiesInTrigger='..tostring(self.entitiesInTrigger))
		if self.entitiesInTrigger>0 then
			if self.isEnabledChildren==self.enableOnEmpty then
				self:print('self:setEnableChildren '..tostring(not self.enableOnEmpty))
				self:setEnableChildren(not self.enableOnEmpty)
				self.isEnabledChildren=not self.enableOnEmpty
			end
		else
			if self.isEnabledChildren~=self.enableOnEmpty then
				self:print('self:setEnableChildren '..tostring(not self.enableOnEmpty))
				self:setEnableChildren(self.enableOnEmpty)
				self.isEnabledChildren=self.enableOnEmpty
			end
		end
	end
end

