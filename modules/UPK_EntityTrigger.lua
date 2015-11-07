-- by mor2000

--------------------
-- EntityTrigger (enables modules if vehicle or walker is present)

local UPK_EntityTrigger_mt = ClassUPK(UPK_EntityTrigger,UniversalProcessKit)
InitObjectClass(UPK_EntityTrigger, "UPK_EntityTrigger")
UniversalProcessKit.addModule("entitytrigger",UPK_EntityTrigger)

function UPK_EntityTrigger:new(nodeId, parent)
	printFn('UPK_EntityTrigger:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId, parent, UPK_EntityTrigger_mt)
	registerObjectClassName(self, "UPK_EntityTrigger")
	
	self:addTrigger()
	
	-- adjust for old configuration
	local enableOnEmpty = getUserAttribute(nodeId, "enableOnEmpty")
	if enableOnEmpty==true or enableOnEmpty==false then
		self:printInfo('use enableChildrenOnEmpty instead of enableOnEmpty (out-dated)')
		self.actions['OnEmpty']['enableChildren']=enableOnEmpty
		self.actions['OnEmpty']['disableChildren']=not enableOnEmpty
		self.actions['OnPopulated']['enableChildren']=not enableOnEmpty
		self.actions['OnPopulated']['disableChildren']=enableOnEmpty
	end
	
	self:printFn('UPK_EntityTrigger:new done')
	
	return self
end
