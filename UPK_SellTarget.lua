-- by mor2000

--------------------
-- SellTarget

local UPK_SellTarget_mt = ClassUPK(UPK_SellTarget,UniversalProcessKit)
InitObjectClass(UPK_SellTarget, "UPK_SellTarget")
UniversalProcessKit.addModule("selltarget",UPK_SellTarget)

function UPK_SellTarget:new(nodeId, parent)
	printFn('UPK_SellTarget:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId, parent, UPK_SellTarget_mt)
	registerObjectClassName(self, "UPK_SellTarget")
	
	UniversalProcessKitListener.addUpdateable(self)
	
	self:print('UPK_SellTarget:new done')
	
	return self
end

function UPK_SellTarget:delete()
	UPK_SellTarget:superClass().delete(self)
end

function UPK_SellTarget:update(dt)
	self:printAll('UPK_SellTarget:update(',dt,')')
	if self.placeable~=nil and g_gui.currentGuiName=="PlacementScreen" then
		local diffx,diffy,diffz = unpack(self.wpos - {getWorldTranslation(g_placementScreen.camera)})
		if diffx<200 and diffy<200 and diffz<200 then
			local _,wy,_=getRotation(self.base.nodeId)
			local tmpy=Utils.getYRotationFromDirection(diffx, diffz)
			local rx=Utils.getYRotationFromDirection(math.sqrt(diffx*diffx+diffz*diffz), diffy)
			setRotation(self.nodeId,rx,-(wy-tmpy),0)
			self.showPane=true
		end
	elseif self.showPane then
		setRotation(self.nodeId,0,0,0)
		self.showPane=false
	end
end
