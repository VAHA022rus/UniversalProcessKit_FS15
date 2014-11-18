-- by mor2000

-- enables more fillTypes, ie. bales, animals or including dummies
-- works on the fly, just use UniversalProcessKit.fillTypeNameToInt("yourFillType") to initialize fillType

UniversalProcessKit.fillTypeNameToInt={}
UniversalProcessKit.fillTypeIntToName={}
for k,v in pairs(Fillable.fillTypeNameToInt) do
	UniversalProcessKit.fillTypeNameToInt[k]=v
	UniversalProcessKit.fillTypeIntToName[v]=k
end
UniversalProcessKit.NUM_FILLTYPES = 32768 -- may collide with huge pile of FIFO or FILO storage

local fillTypeNameToInt_mt={
	__index=Fillable.fillTypeNameToInt,
	__call=function(func,...)
		local t={}
		local args=...
		if type(args)~="table" then
			args={...}
		end
		for k,v in pairs(args) do
			local type=type(v)
			if type=="string" then
				if rawget(UniversalProcessKit.fillTypeNameToInt,v)==nil and Fillable.fillTypeNameToInt[v]==nil then
					UniversalProcessKit.addFillType(v) -- add fillTypes as used
				end
				table.insert(t,UniversalProcessKit.fillTypeNameToInt[v])
			end
		end
		return t
		end,
	__newindex=function(t,k,v)
		UniversalProcessKit.addFillType(k)
		end
	};

local fillTypeIntToName_mt={
	__index=Fillable.fillTypeIntToName,
	__call=function(func,...)
		local t={}
		local args=...
		if type(args)~="table" then
			args={...}
		end
		for k,v in pairs(args) do
			local type=type(v)
			if type=="number" then
				if UniversalProcessKit.fillTypeIntToName[v]~=nil then
					table.insert(t,UniversalProcessKit.fillTypeIntToName[v])
				end
			end
		end
		return t
		end
	};

setmetatable(UniversalProcessKit.fillTypeNameToInt,fillTypeNameToInt_mt)
setmetatable(UniversalProcessKit.fillTypeIntToName,fillTypeIntToName_mt)

function UniversalProcessKit.addFillType(name,index)
	if type(name)=="table" then
		for k,v in pairs(name) do
			UniversalProcessKit.addFillType(v)
		end
	elseif type(name)=="string" then
		if UniversalProcessKit.fillTypeNameToInt[name]==nil then
			local index=index or UniversalProcessKit.NUM_FILLTYPES
			if UniversalProcessKit.fillTypeIntToName[index]~=nil then
				UniversalProcessKit.addFillType(name,index+1)
			else
				if name~="money" and name~="void" then
					print("Notice: Filltype labeled \""..tostring(name).."\" is not part of the game economy")
				else
					UniversalProcessKit['FILLTYPE_'..string.upper(name)]=index
				end
				print("Notice: adding "..tostring(name).." ("..tostring(index)..") to fillTypes")
				rawset(UniversalProcessKit.fillTypeIntToName,index,name)
				rawset(UniversalProcessKit.fillTypeNameToInt,name,index)
				UniversalProcessKit.NUM_FILLTYPES=UniversalProcessKit.NUM_FILLTYPES+1
				return index
			end
		end
	end
end;

function UniversalProcessKit.registerFillType(name, hudFilename)
	Fillable.registerFillType(name, nil, nil, true, hudFilename)
	UniversalProcessKit.addFillType(name)
end;

-- special fillType "money" and "void"
UniversalProcessKit.addFillType("money")
UniversalProcessKit.addFillType("void")


