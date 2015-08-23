-- by mor2000

-- general usage:

-- eval = __eval("2+3*(4-5)<0")
-- if eval() then ..

-- for first time usage check for errors in formula
-- evalval, evaltype, evalerror = eval()
-- if evaltype==EvalFormula.EVALTYPE_ERROR then
--   print(EvalFormula.getErrorMsg(evalerror))
--   ..

-- allowed operations/syntax in formula (keywords are case sensitiv)
-- parentheses ( and )
-- boolean keywords true and false
-- logical operators AND OR XOR and NOT
-- comparisons = <= < >= > != (notice "!=" for not equals instead of "~=")
-- mathmatical transformations + - * /

-- functions may be added

EvalFormula.EVALTYPE_NONE = 0
EvalFormula.EVALTYPE_BOOLEAN = 1
EvalFormula.EVALTYPE_NUMBER = 2
EvalFormula.EVALTYPE_ERROR = 3

EvalFormula.ERRORTYPE_UNKNOWN = 0 -- unknown error
EvalFormula.ERRORTYPE_MISMATCH = 1 -- mismatching eval types (like boolean and number)
EvalFormula.ERRORTYPE_MIXED = 2 -- unallowed mixure of eval types and comparisons (like boolean < boolean)
EvalFormula.ERRORTYPE_FORMAT = 3 -- wrong format (not nil, number or boolean)
EvalFormula.ERRORTYPE_OPERATION = 4 -- wrong operation used

function EvalFormula.getErrorMsg(errortype)
	if errortype==nil then
		return "no error"
	elseif errortype==EvalFormula.ERRORTYPE_UNKNOWN then
		return "unknown error"
	elseif errortype==EvalFormula.ERRORTYPE_MISMATCH then
		return "mismatching eval types (like boolean and number)"
	elseif errortype==EvalFormula.ERRORTYPE_MIXED then
		return "unallowed mixure of eval types and comparisons (like boolean < boolean)"
	elseif errortype==EvalFormula.ERRORTYPE_FORMAT then
		return "wrong format (not nil, number or boolean)"
	elseif errortype==EvalFormula.ERRORTYPE_OPERATION then
		return "wrong operation used"
	end
	return "unknown error type"
end

EvalFormula.OPERATION_NONE = 0

EvalFormula.OPERATION_ADD = 1
EvalFormula.OPERATION_SUB = 2
EvalFormula.OPERATION_MUL = 3
EvalFormula.OPERATION_DIV = 4

EvalFormula.OPERATION_AND = 5
EvalFormula.OPERATION_OR = 6
EvalFormula.OPERATION_XOR = 7
EvalFormula.OPERATION_NOT = 8

EvalFormula.OPERATION_EQ = 9
EvalFormula.OPERATION_NE = 10
EvalFormula.OPERATION_GE = 11
EvalFormula.OPERATION_GT = 12
EvalFormula.OPERATION_LE = 13
EvalFormula.OPERATION_LT = 14

local evalFormula_mt = {
	__call = function(t)
		local lhsval, lhstype, lhserror = EvalFormula.getValTypeError(t.lhs)
		local rhsval, rhstype, rhserror = EvalFormula.getValTypeError(t.rhs)
		
		if lhstype==EvalFormula.EVALTYPE_ERROR or rhstype==EvalFormula.EVALTYPE_ERROR then
			return nil, EvalFormula.EVALTYPE_ERROR, lhserror or lhserror
		end
		
		if lhstype==EvalFormula.EVALTYPE_NONE and rhstype==EvalFormula.EVALTYPE_BOOLEAN and t.operation==EvalFormula.OPERATION_NOT then
			return (not rhsval), EvalFormula.EVALTYPE_BOOLEAN, nil
		elseif lhstype==EvalFormula.EVALTYPE_NONE and rhstype==EvalFormula.EVALTYPE_NUMBER and t.operation==EvalFormula.OPERATION_NOT then
			return (-rhsval), EvalFormula.EVALTYPE_NUMBER, nil
		end
		
		if t.operation==EvalFormula.OPERATION_NONE then
			return lhsval, lhstype, nil
		end
		
		if lhstype~=rhstype then
			return nil, EvalFormula.EVALTYPE_ERROR, EvalFormula.ERRORTYPE_MISMATCH
		end
		
		if lhstype==EvalFormula.EVALTYPE_BOOLEAN then
			if t.operation==EvalFormula.OPERATION_AND then
				return (lhsval and rhsval), EvalFormula.EVALTYPE_BOOLEAN, nil
			elseif t.operation==EvalFormula.OPERATION_OR then
				return (lhsval or rhsval), EvalFormula.EVALTYPE_BOOLEAN, nil
			elseif t.operation==EvalFormula.OPERATION_XOR then
				return ((lhsval and not rhsval) or (not lhsval and rhsval)), EvalFormula.EVALTYPE_BOOLEAN, nil
			elseif t.operation==EvalFormula.OPERATION_EQ then
				return (lhsval == rhsval), EvalFormula.EVALTYPE_BOOLEAN, nil
			elseif t.operation==EvalFormula.OPERATION_NE then
				return (lhsval ~= rhsval), EvalFormula.EVALTYPE_BOOLEAN, nil
			end
			return nil, EvalFormula.EVALTYPE_ERROR, EvalFormula.ERRORTYPE_OPERATION
		elseif lhstype==EvalFormula.EVALTYPE_NUMBER then
			if t.operation==EvalFormula.OPERATION_ADD then
				return (lhsval + rhsval), EvalFormula.EVALTYPE_NUMBER, nil
			elseif t.operation==EvalFormula.OPERATION_SUB then
				return (lhsval - rhsval), EvalFormula.EVALTYPE_NUMBER, nil
			elseif t.operation==EvalFormula.OPERATION_MUL then
				return (lhsval * rhsval), EvalFormula.EVALTYPE_NUMBER, nil
			elseif t.operation==EvalFormula.OPERATION_DIV then
				return (lhsval / rhsval), EvalFormula.EVALTYPE_NUMBER, nil
			elseif t.operation==EvalFormula.OPERATION_EQ then
				return (lhsval == rhsval), EvalFormula.EVALTYPE_BOOLEAN, nil
			elseif t.operation==EvalFormula.OPERATION_NE then
				return (lhsval ~= rhsval), EvalFormula.EVALTYPE_BOOLEAN, nil
			elseif t.operation==EvalFormula.OPERATION_GE then
				return (lhsval >= rhsval), EvalFormula.EVALTYPE_BOOLEAN, nil
			elseif t.operation==EvalFormula.OPERATION_GT then
				return (lhsval > rhsval), EvalFormula.EVALTYPE_BOOLEAN, nil
			elseif t.operation==EvalFormula.OPERATION_LE then
				return (lhsval <= rhsval), EvalFormula.EVALTYPE_BOOLEAN, nil
			elseif t.operation==EvalFormula.OPERATION_LT then
				return (lhsval < rhsval), EvalFormula.EVALTYPE_BOOLEAN, nil
			end
			return nil, EvalFormula.EVALTYPE_ERROR, EvalFormula.ERRORTYPE_OPERATION
		end
		return nil, EvalFormula.EVALTYPE_ERROR, EvalFormula.ERRORTYPE_UNKNOWN
	end
}

function EvalFormula.getValTypeError(lhs)
	local lhstypeName = type(lhs)
	if lhstypeName=="nil" then
		return nil, EvalFormula.EVALTYPE_NONE, nil
	elseif lhstypeName=="number" then
		return lhs, EvalFormula.EVALTYPE_NUMBER, nil
	elseif lhstypeName=="boolean" then
		return lhs, EvalFormula.EVALTYPE_BOOLEAN, nil
	elseif lhstypeName=="table" then
		return lhs()
	end
	return nil, EvalFormula.EVALTYPE_ERROR, EvalFormula.ERRORTYPE_UNKNOWN
end
	
function EvalFormula.new(lhs,rhs,operation)
	self={}
	self.lhs=lhs
	self.rhs=rhs
	self.operation=operation
	setmetatable(self,evalFormula_mt)
	return self
end

local evalFormulaFillLevel_mt = {
	__call = function(t)
		return t.fillLevels[t.fillType] or 0, EvalFormula.EVALTYPE_NUMBER, nil
	end
}

function EvalFormula.newFillLevel(fillType,fillLevels)
	self={}
	self.fillType=fillType
	self.fillLevels=fillLevels
	setmetatable(self,evalFormulaFillLevel_mt)
	return self
end

function getIdentifier(identifiers)
	local identifier = ""
	for i = 1,12 do
		identifier = identifier .. string.char(math.random(97, 122))
	end
	if identifiers~=nil and identifiers[identifier]~=nil then
		identifier=getIdentifier(identifiers)
	end
	return identifier
end

function getValFromString(str,identifiers)
	local val=nil
	if str=="true" then
		str="#true#"
	elseif str=="false" then
		str="#false#"
	end
	local number=tonumber(str)
	if number~=nil then
		return number
	end
	local isIdentifier,_ = string.find(str,"^#%l+#$")
	if isIdentifier~=nil then
		identifier=string.gsub(str,"^#(.-)#$", "%1",1)
		return identifiers[identifier]
	end
	return nil
end

function stringToPattern(str)
	str=string.gsub(str,"%*","%%*")
	str=string.gsub(str,"%+","%%+")
	str=string.gsub(str,"%-","%%-")
	str=string.gsub(str,"%/","%%/")
	str=string.gsub(str,"%(","%%(")
	str=string.gsub(str,"%)","%%)")
	str=string.gsub(str,"%.","%%.")
	return str
end

function findEval(formula, identifiers, pattern, separator, operation)
	local a,b=string.find(formula,pattern)
	if a~=nil then
		local formulasub=string.sub(formula,a,b)
		local formulasublen=string.len(formulasub)
		local c,d=string.find(formulasub,separator)
		local lhsStr=trim(string.sub(formulasub,1,c-1))
		local rhsStr=trim(string.sub(formulasub,d+1,formulasublen))
		local lhsval=getValFromString(lhsStr,identifiers)
		local rhsval=getValFromString(rhsStr,identifiers)
		local identifier=getIdentifier(identifiers)
		local eval=EvalFormula.new(lhsval,rhsval,operation)
		identifiers[identifier]=eval
		local replacement='#'..identifier..'#'
		if lhsval==nil then
			replacement=lhsStr..replacement
		end
		formula=string.gsub(formula,stringToPattern(formulasub),replacement,1)
		return formula, eval
	end
	return formula, nil
end

function findAllEval(formula, identifiers, pattern, separator, operation)
	local formulacp
	repeat
		formulacp=formula
		formula,_=findEval(formula, identifiers, pattern, separator, operation)
	until formula==formulacp
	return formula,nil
end

function evalFormula(formula,identifiers)
	repeat
		local outerParenthesesbegin,outerParenthesesend=string.find(formula,"%([%s%w#0-9%.%-%*%/%+=<>!]*%)")
		if outerParenthesesbegin~=nil then
			local formulasub=string.sub(formula,outerParenthesesbegin+1,outerParenthesesend-1)
			local identifier=evalFormula(formulasub,identifiers)
			formula=string.gsub(formula,stringToPattern('('..formulasub..')'),' '..identifier..' ',1)
		end
	until outerParenthesesbegin==nil
	
	formula,_=findAllEval(formula,identifiers,"^%s*%-%s*[%l#0-9%.]+","%-",EvalFormula.OPERATION_NOT)
	formula,_=findAllEval(formula,identifiers,"[%+%-%/%*=><!%(]+%s*%-%s*[%l#0-9%.]+","%-",EvalFormula.OPERATION_NOT)
	formula,_=findAllEval(formula,identifiers,"[%l#0-9%.]+%s*%*%s*[%l#0-9%.]+","%*",EvalFormula.OPERATION_MUL)
	formula,_=findAllEval(formula,identifiers,"[%l#0-9%.]+%s*%/%s*[%l#0-9%.]+","%/",EvalFormula.OPERATION_DIV)
	formula,_=findAllEval(formula,identifiers,"[%l#0-9%.]+%s*%-%s*[%l#0-9%.]+","%-",EvalFormula.OPERATION_SUB)
	formula,_=findAllEval(formula,identifiers,"[%l#0-9%.]+%s*%+%s*[%l#0-9%.]+","%+",EvalFormula.OPERATION_ADD)

	formula,_=findAllEval(formula,identifiers,"[%l#0-9%.]+%s*!=%s*[%l#0-9%.]+","!=",EvalFormula.OPERATION_NE)
	formula,_=findAllEval(formula,identifiers,"[%l#0-9%.]+%s*>=%s*[%l#0-9%.]+",">=",EvalFormula.OPERATION_GE)
	formula,_=findAllEval(formula,identifiers,"[%l#0-9%.]+%s*<=%s*[%l#0-9%.]+","<=",EvalFormula.OPERATION_LE)
	formula,_=findAllEval(formula,identifiers,"[%l#0-9%.]+%s*>%s*[%l#0-9%.]+",">",EvalFormula.OPERATION_GT)
	formula,_=findAllEval(formula,identifiers,"[%l#0-9%.]+%s*<%s*[%l#0-9%.]+","<",EvalFormula.OPERATION_LT)
	formula,_=findAllEval(formula,identifiers,"[%l#0-9%.]+%s*=%s*[%l#0-9%.]+","=",EvalFormula.OPERATION_EQ)

	formula,_=findAllEval(formula,identifiers,"NOT%s+[%l#0-9%.]+","NOT%s+",EvalFormula.OPERATION_NOT)
	formula,_=findAllEval(formula,identifiers,"[%l#0-9%.]+%s+XOR%s+[%l#0-9%.]+","%sXOR%s",EvalFormula.OPERATION_XOR)
	formula,_=findAllEval(formula,identifiers,"[%l#0-9%.]+%s+OR%s+[%l#0-9%.]+","%sOR%s",EvalFormula.OPERATION_OR)
	formula,_=findAllEval(formula,identifiers,"[%l#0-9%.]+%s+AND%s+[%l#0-9%.]+","%sAND%s",EvalFormula.OPERATION_AND)

	return trim(formula)
end

function _g.__eval(formula,identifiers)
	if type(formula)~="string" then
		return ""
	end
	if identifiers==nil then
		identifiers={}
		identifiers["true"]=EvalFormula.new(true,nil,EvalFormula.OPERATION_NONE)
		identifiers["false"]=EvalFormula.new(false,nil,EvalFormula.OPERATION_NONE)
	end
	formula=evalFormula(formula,identifiers)
	local eval=getValFromString(formula,identifiers)
	return eval
end
