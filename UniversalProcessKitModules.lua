-- by mor2000

UniversalProcessKit.ModuleTypes={}

function UniversalProcessKit.addModule(name,class)
	if type(name)=="string" then
		if UniversalProcessKit.ModuleTypes[name]~=nil then
			print('Error: module with this name already in use',true)
		else
			UniversalProcessKit.ModuleTypes[name]=class
			print('registered module of type '..tostring(name))
		end
	else
		print('Error: can\'t add module without name',true)
	end
end

UniversalProcessKit.addModule("unspecified",UniversalProcessKit)