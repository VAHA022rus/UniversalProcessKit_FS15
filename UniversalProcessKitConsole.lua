-- by mor2000

UniversalProcessKit.DEBUG_NONE = 0
UniversalProcessKit.DEBUG_ERROR = 1
UniversalProcessKit.DEBUG_INFO = 2
UniversalProcessKit.DEBUG_FUNCTION = 3
UniversalProcessKit.DEBUG_EVERYTHING = 4 -- default for unspecified prints
UniversalProcessKit.DEBUG_EVERYTHING_PLUS = 5 -- can only be set in DEBUG.lua

-- functions to switch

function sub_UPKprint(self, str) -- should not be called directly
	if type(str)=="string" then
		local msg=str
		if self.nodeId~=nil or self.id~=nil then
			msg='[nid='..tostring(self.nodeId)..' oid='..tostring(self.id)..'] '..msg
		end
		local signature=tostring(self.i18nNameSpace or '(unnamed)')..': '..tostring(self.name)
		_g.print(' ['..tostring(signature)..'] '..msg)
	end
end;

function sub_UPKprintErr(self, ...)
	local str=""
	for _,v in pairs({...}) do
		str=str..tostring(v)
	end
	self:print(str)
end;

function sub_UPKprintInfo(self, ...)
	local str=""
	for _,v in pairs({...}) do
		str=str..tostring(v)
	end
	self:print(str)
end;

function sub_UPKprintFn(self, ...)
	local str=""
	for _,v in pairs({...}) do
		str=str..tostring(v)
	end
	self:print(str)
end;

function sub_UPKprintAll(self, ...)
	local str=""
	for _,v in pairs({...}) do
		str=str..tostring(v)
	end
	self:print(str)
end;

-- function outside UniversalProcessKit modules

function sub_print(str, debug)
	if type(debug)~="number" then
		debug = nil
	end
	if (debug or 4)<=debugMode then
		if type(str)=="string" then
			_g.print(' [UPK] '..str)
		end
	end
end;

function sub_printErr(...)
	local str=""
	for _,v in pairs({...}) do
		str=str..tostring(v)
	end
	print(str, UniversalProcessKit.DEBUG_ERROR)
end;

function sub_printInfo(...)
	local str=""
	for _,v in pairs({...}) do
		str=str..tostring(v)
	end
	print(str, UniversalProcessKit.DEBUG_INFO)
end;

function sub_printFn(...)
	local str=""
	for _,v in pairs({...}) do
		str=str..tostring(v)
	end
	print(str, UniversalProcessKit.DEBUG_FUNCTION)
end;

function sub_printAll(...)
	local str=""
	for _,v in pairs({...}) do
		str=str..tostring(v)
	end
	print(str, UniversalProcessKit.DEBUG_EVERYTHING)
end;

-- add console command

function UniversalProcessKit:upkSetDebugMode(debug)
	if debugMode == UniversalProcessKit.DEBUG_EVERYTHING_PLUS then
		_g.print('upk debug mode '..tostring(UniversalProcessKit.DEBUG_EVERYTHING_PLUS)..' cannot be changed in-game')
		return
	end
	if type(debug) == "table" then
		_g.print('error: argument is a table')
		for k,v in pairs(debug) do
			_g.print(tostring(k)..": "..tostring(v))
		end
		return
	end
	if type(debug) == "string" then
		debug = tonumber(debug)
	end
	if type(debug) ~= "number" or debug<UniversalProcessKit.DEBUG_NONE or debug>UniversalProcessKit.DEBUG_EVERYTHING then
		_g.print('error: the debug mode has to be a number between '..tostring(UniversalProcessKit.DEBUG_NONE)..' and '..tostring(UniversalProcessKit.DEBUG_EVERYTHING))
		return
	end
	debug = round(debug,0)
	debugMode = debug
	
	if debugMode ~= UniversalProcessKit.DEBUG_NONE then
		UniversalProcessKit.print = sub_UPKprint
		_m.print = sub_print
	else
		UniversalProcessKit.print = emptyFunc
		_m.print = emptyFunc
	end
		
	if debugMode >= UniversalProcessKit.DEBUG_ERROR then
		UniversalProcessKit.printErr = sub_UPKprintErr
		_m.printErr = sub_printErr
	else
		UniversalProcessKit.printErr = emptyFunc
		_m.printErr = emptyFunc
	end
	
	if debugMode >= UniversalProcessKit.DEBUG_INFO then
		UniversalProcessKit.printInfo = sub_UPKprintInfo
		_m.printInfo = sub_printInfo
	else
		UniversalProcessKit.printInfo = emptyFunc
		_m.printInfo = emptyFunc
	end
	
	if debugMode >= UniversalProcessKit.DEBUG_FUNCTION then
		UniversalProcessKit.printFn = sub_UPKprintFn
		_m.printFn = sub_printFn
	else
		UniversalProcessKit.printFn = emptyFunc
		_m.printFn = emptyFunc
	end
	
	if debugMode >= UniversalProcessKit.DEBUG_EVERYTHING then
		UniversalProcessKit.printAll = sub_UPKprintAll
		_m.printAll = sub_printAll
	else
		UniversalProcessKit.printAll = emptyFunc
		_m.printAll = emptyFunc
	end
	
	_g.print("upk debug mode set to " .. tostring(debug))
end;

addConsoleCommand("upkSetDebugMode", "set debug mode for upk", "upkSetDebugMode", UniversalProcessKit);

-- set debug mode first time

UniversalProcessKit.upkSetDebugMode(nil, debugMode)