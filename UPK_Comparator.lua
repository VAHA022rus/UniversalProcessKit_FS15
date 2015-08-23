-- by mor2000

--------------------
-- Comparator

local UPK_Comparator_mt = ClassUPK(UPK_Comparator, UniversalProcessKit)
InitObjectClass(UPK_Comparator, "UPK_Comparator")
UniversalProcessKit.addModule("comparator",UPK_Comparator)

function UPK_Comparator:new(nodeId,parent)
	printFn('UPK_Comparator:new(',nodeId,', ',parent,')')
	local self = UniversalProcessKit:new(nodeId,parent, UPK_Comparator_mt)
	registerObjectClassName(self, "UPK_Comparator")
	
	self.isLoaded = false
	self.fillLevelsCopy = {}
	
	-- formula, eval
	self.formula = getStringFromUserAttribute(nodeId, "formula", "true")
	self.usedFillTypes={}
	self.state = nil
	self.eval = self:evalFormula(self.formula)
	if self.eval==nil then
		printErr('couldnt evaluate formula, check for errors')
		self.eval = EvalFormula.new(false,nil,EvalFormula.OPERATION_NONE)
	end
	local _,evaltype,evalerror=self.eval()
	if evaltype==EvalFormula.EVALTYPE_ERROR then
		printErr(EvalFormula.getErrorMsg(evalerror))
		self.eval = EvalFormula.new(false,nil,EvalFormula.OPERATION_NONE)
	end
	
	-- actions
	self:getActionUserAttributes('OnTrue')
	self:getActionUserAttributes('OnFalse')
	
	self:printFn('UPK_Comparator:new done')
   
   	return self
end

function UPK_Comparator:delete()
	self:printFn('UPK_Comparator:delete()')
	UPK_Comparator:superClass().delete(self)
end

function UPK_Comparator:postLoad()
	self:printFn('UPK_Comparator:postLoad()')
	UPK_Comparator:superClass().postLoad(self)
	
	for fillType,_ in pairs(self.usedFillTypes) do
		local fillLevel = self:getFillLevel(fillType) or 0
		self.fillLevelsCopy[fillType] = fillLevel
	end
	
	local state=self.eval()
	if self.base.timesSaved==0 then
		if state~=self.state then
			if state and not self.state then
				self:printAll('OnTrue')
				self:operateAction('OnTrue')
			elseif not state and self.state then
				self:printAll('OnFalse')
				self:operateAction('OnFalse')
			end
		end
	end
	self.state=state
	
	self.isLoaded=true
end;

function UPK_Comparator:onFillLevelChange(deltaFillLevel, newFillLevel, fillType)
	self:printFn('UPK_Comparator:onFillLevelChange(',deltaFillLevel,', ',newFillLevel,', ',fillType,')')
	
	if self.isEnabled and self.isLoaded then
		if self.usedFillTypes[fillType]==true then		
			self.fillLevelsCopy[fillType] = newFillLevel
			local state=self.eval()
			if state~=self.state then
				if state and not (self.state or false) then
					self:printAll('OnTrue')
					self:operateAction('OnTrue')
				elseif not state and (self.state or true) then
					self:printAll('OnFalse')
					self:operateAction('OnFalse')
				end
				self.state=state
			end
		end
	end
end

function UPK_Comparator:loadExtraNodes(xmlFile, key)
	self:printFn('UPK_Comparator:loadExtraNodes(',xmlFile,', ',key,')')
	self.state=getXMLBool(xmlFile, key .. "#state")
	return true
end;

function UPK_Comparator:getSaveExtraNodes(nodeIdent)
	self:printFn('UPK_Comparator:getSaveExtraNodes(',nodeIdent,')')
	local nodes=""
	nodes=nodes.." state=\""..tostring(self.state).."\""
	return nodes
end;

function UPK_Comparator:evalFormula(formula)
	if formula==nil then
		formula=self.formula
	end
	
	local identifiers={}
	identifiers["true"]=EvalFormula.new(true,nil,EvalFormula.OPERATION_NONE)
	identifiers["false"]=EvalFormula.new(false,nil,EvalFormula.OPERATION_NONE)
	
	local keywords={}
	function registerKeywords(word)
		if word~="AND" and word~="OR" and word~="XOR" and word~="NOT" and word~="true" and word~="false" then
			local keywordRegistered=false
			for _,keyword in pairs(keywords) do
				if word==keyword then
					keywordRegistered=true
				end
			end
			if not keywordRegistered then
				table.insert(keywords, word)
			end
		end
		return word
	end

	string.gsub(formula,"%a[%w_]+",registerKeywords)
	table.sort(keywords, function(a,b) return string.len(a)>string.len(b) end) -- list long names first

	self:printInfo('keywords to check in formula: '..table.concat(keywords))
	for i=1,length(keywords) do
		local keyword = keywords[i]
		local fillType = UniversalProcessKit.fillTypeNameToInt[keyword]
		if fillType~=nil then
			self:printInfo(keyword..' recognized as fill type')
			self.usedFillTypes[fillType]=true
			local flbs = self:getFillLevelBubbleShellFromFillType(fillType)
			if flbs~=nil and flbs~=self then
				flbs:registerOnFillLevelChangeFunc(self,"onFillLevelChange")
			end
			local identifier=getIdentifier(identifiers)
			local evalFillLevel=EvalFormula.newFillLevel(fillType,self.fillLevelsCopy)
			identifiers[identifier]=evalFillLevel
			formula=string.gsub(formula,keyword,'#'..identifier..'#')
		else
			self:printInfo("unknown keyword "..keyword)
		end
	end

	eval=__eval(formula,identifiers)
	
	if eval==nil then
		return nil
	end
	local evalval=eval()
	if evalval~=true and evalval~=false then
		return nil
	end
	return eval
end;
