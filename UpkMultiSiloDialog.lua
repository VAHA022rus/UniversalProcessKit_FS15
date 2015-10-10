
UpkMultiSiloDialog = {}
local UpkMultiSiloDialog_mt = Class(UpkMultiSiloDialog, MultiSiloDialog)

function UpkMultiSiloDialog.new(self, target, custom_mt)
	local self = MultiSiloDialog:new(target, custom_mt or UpkMultiSiloDialog_mt)
	self.upkmodule=nil
	return self
end

function UpkMultiSiloDialog:setModule(upkmodule)
	self.upkmodule=upkmodule
end

function UpkMultiSiloDialog:setFillTypes(fillTypes)
	self.fillTypes = fillTypes
	local fillTypesTable = {}

	local fillTypesLength=length(fillTypes)
	for i=1,fillTypesLength do
		fillType=fillTypes[i]
		local fillTypeName = UniversalProcessKit.fillTypeIntToName[fillType]
		
		local str="["..fillTypeName.."]"
		local fillLevel = 0
		local unit = g_i18n:getText("fluid_unit_short")
		
		if self.upkmodule~=nil then
			str=returnNilIfEmptyString(self.upkmodule.i18n[fillTypeName]) or str
			fillLevel=self.upkmodule:getFillLevel(fillType)
			unit = returnNilIfEmptyString(self.upkmodule.i18n[fillTypeName..'_unit_short']) or self.upkmodule.i18n["fluid_unit_short"]
		end
	
		if not self.upkmodule.createFillType then
			str = str..' '..string.format("%d", fillLevel)..' ['..unit..']'
		end

		table.insert(fillTypesTable, str)
	end

	self.fillTypesElement:setTexts(fillTypesTable)
	self.fillTypesElement:setState(self.selectedState)
	self:fillTypesOnClick(self.selectedState)
end

function UpkMultiSiloDialog:fillTypesOnClick(state)
	self.messageText:setText("")
	self.messageBackground:setVisible(false)
	self.setButtonDisabled(self, false)

	self.selectedFillType = self.fillTypes[state]
	self.selectedState = state
	local fillLevel = 0
	
	local disableIfEmpty=true
	if self.upkmodule~=nil then
		fillLevel=self.upkmodule:getFillLevel(self.selectedFillType)
		if self.upkmodule.createFillType then
			disableIfEmpty=false
		end
	end
	if fillLevel <= 0 and disableIfEmpty then
		self.messageText:setText(g_i18n:getText("siloIsEmpty"))
		self.messageBackground:setVisible(true)
		self.setButtonDisabled(self, true)
	end
end

function UpkMultiSiloDialog:onClickActivate()
	ScreenElement.onClickActivate(self)

	if self.areButtonsDisabled then
		return 
	end

	if self.onSelectCallback ~= nil then
		if self.target ~= nil then
			self.onSelectCallback(self.target, self.selectedFillType)
		else
			self.onSelectCallback(self.selectedFillType)
		end
	end
	ScreenElement.onClickBack(self)
end

function UpkMultiSiloDialog:onClickBack()
	if self.onCancelCallback ~= nil then
		self.onCancelCallback(self.cancelTarget)
	end
	ScreenElement.onClickBack(self)
end

function UpkMultiSiloDialog:setSelectedFillType(fillType)
	if fillType==nil or not isInTable(self.fillTypes,fillType) then
		self.selectedFillType = self.fillTypes[1]
		self.selectedState = 1
	else
		for k,v in pairs(self.fillTypes) do
			if v==fillType then
				self.selectedFillType = v
				self.selectedState = k
				break
			end
		end
	end
end

function UpkMultiSiloDialog:setCancelCallback(onCancelCallback, target)
	self.onCancelCallback = onCancelCallback
	self.cancelTarget = target
end

upkMultiSiloDialog = UpkMultiSiloDialog:new()
g_gui:loadGui("dataS/gui/MultiSiloDialog.xml", "UpkMultiSiloDialog", upkMultiSiloDialog)
