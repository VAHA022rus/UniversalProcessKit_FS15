-- by mor2000

UniversalProcessKit.ModuleTypes={}

function UniversalProcessKit.addModule(name,class)
	printFn('UniversalProcessKit.addModule('..tostring(name)..', '..tostring(class)..')')
	if type(name)=="string" then
		if UniversalProcessKit.ModuleTypes[name]~=nil then
			printErr('Error: module with this name already in use',true)
		else
			UniversalProcessKit.ModuleTypes[name]=class
			printInfo('registered module of type '..tostring(name))
		end
	else
		printErr('Error: can\'t add module without name',true)
	end
end
