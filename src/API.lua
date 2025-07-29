--------------------------------------------------------------------------------------------
-- PropertiesAPI created by Typhoon
-- Used to get and serialise all properties of any instance
--------------------------------------------------------------------------------------------

local PropertiesAPI = {}

local TypeList = require(script.TypeList)

local httpService = game:GetService("HttpService")
local raw = httpService:GetAsync("https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/refs/heads/roblox/API-Dump.json")

local apiDump = httpService:JSONDecode(raw).Classes

local SPECIAL_EDGE_CASES = {
	["Script"] = "Source",
	["LocalScript"] = "Source",
	["ModuleScript"] = "Source",
	["VideoFrame"] = "VideoContent"
}

local EXCEPTIONS = {
	"Terrain",
	"ChatWindowConfiguration",
	"ChatInputBarConfiguration",
	"BubbleChatConfiguration",
	"ChannelTabsConfiguration"
}

local classMutableProperties = {}
local classNames = {}

local function generateClassNames()
	for _, class in apiDump do
		classNames[class.Name] = class
	end
end

local function indexClass(class, baseName)
	for _, member in class.Members do
		if member.MemberType == "Property" 
			and member.Security.Read == "None" 
			and (not member.Tags or not table.find(member.Tags, "NotScriptable"))
		then
			table.insert(classMutableProperties[baseName], member.Name)
		end
	end

	if not (class.Superclass == "<<<ROOT>>>") then
		indexClass(classNames[class.Superclass], baseName)
	end
end

local function dumpClasses()
	for className, class in pairs(classNames) do
		local bypass = false
		if table.find(EXCEPTIONS, className) then
			bypass = true
		end
		
		if (not (class.Tags and table.find(class.Tags, "NotCreatable"))) or bypass then
			local newInstance
			local success = pcall(function()
				newInstance = Instance.new(className) -- eliminate all possible non creatable instances
			end)

			if success or bypass then
				classMutableProperties[class.Name] = {}
				indexClass(class, className)
			end
		end
	end

	for className, property in pairs(SPECIAL_EDGE_CASES) do
		table.remove(classMutableProperties[className], table.find(classMutableProperties[className], property))
	end
end

local function getAllPropertiesTest(_instance : Instance, foundTypes : table)
	local props = classMutableProperties[_instance.ClassName]
	for _, property in pairs(props) do
		local value = _instance[property]
		local typeOfValue = typeof(value)
		if not table.find(foundTypes, typeOfValue) then
			table.insert(foundTypes, typeOfValue)
		end
	end
end

local function testAll()
	local deferrenceTable = {}
	local foundTypes = {}
	local count = 0

	for className, props in pairs(classMutableProperties) do
		local newInstance
		newInstance = Instance.new(className)

		local success, errormsg = pcall(function()
			getAllPropertiesTest(newInstance, foundTypes)
		end)

		if not success then
			deferrenceTable[className] = className .. " did not serialise correctly"
			deferrenceTable[className .. "Warning"] = className .. errormsg
		end
	end
	
	for _, _type in pairs(foundTypes) do
		if not table.find(TypeList, _type) then
			deferrenceTable[_type] = _type .. " unknown type detected"
		end
	end

	for _, warning in pairs(deferrenceTable) do
		warn(warning)
	end
	
	print("testing complete")
end

local function serialiseValue(value : any)
	local serialisers = {
		EnumItem = function(v) return {__type = "EnumItem", enumType=tostring(v.EnumType), 
									                        value=v.Name} end,
		Color3 = function(v) return {__type = "Color3", r=v.R, g=v.G, b=v.B} end,
		Instance = function(v) return {__type = "Instance", name=v.Name} end,
		Vector3 = function(v) return {__type = "Vector3", x=v.X, y=v.Y, z=v.Z} end,
		CFrame = function(v) return {__type = "CFrame", components = {v:GetComponents()}} end,
		Vector2 = function(v) return {__type = "Vector2", x=v.X, y=v.Y} end,
		Faces = function(v) return {__type = "Faces", back=v.Back, front=v.Front, 
													  left=v.Left, right=v.Right, 
													  top=v.Top, bottom=v.Bottom} end,
		Content = function(v) return {__type = "Content", uri=v.Uri} end,
		Rect = function(v) return {__type = "Rect", minX=v.Min.X, minY=v.Min.Y, 
													maxX=v.Max.X, maxY=v.Max.Y} end,
		UDim2 = function(v) return {__type = "UDim2", xScale=v.X.Scale, xOffset=v.X.Offset, 
													  yScale=v.Y.Scale, yOffset=v.Y.Offset} end,
		PhysicalProperties = function(v) return {__type = "PhysicalProperties", 
												density=v.Density, 
												elasticity=v.Elasticity, 
												elasticityWeight=v.ElasticityWeight, 
												friction=v.Friction, 
												frictionWeight=v.FrictionWeight} end,
		Font = function(v) return {__type = "Font", family=v.Family, 
													weight=v.Weight.Name, 
													style=v.Style.Name} end,
		ColorSequence = function(v) 
			local keypoints = v.Keypoints
			local keypointTable = {}
			for _, keypoint in pairs(keypoints) do
				table.insert(keypointTable, {
					time = keypoint.Time,
					value = serialiseValue(keypoint.Value)
				})
			end
			return {__type = "ColorSequence", keypoints=keypointTable} 
		end,
		NumberSequence = function(v) 
			local keypoints = v.Keypoints
			local keypointTable = {}
			for _, keypoint in pairs(keypoints) do
				table.insert(keypointTable, {
					time = keypoint.Time,
					value = keypoint.Value,
					envelope = keypoint.Envelope
				})
			end
			return {__type = "NumberSequence", keypoints=keypointTable}
		end,
		Axes = function(v) return {__type = "Axes", x=v.X, y=v.Y, z=v.Z, 
													back=v.Back, front=v.Front, 
													left=v.Left, right=v.Right, 
													top=v.Top, bottom=v.Bottom} end,
		Ray = function(v) return {__type = "Ray", origin = serialiseValue(v.Origin),
												  direction = serialiseValue(v.Direction)} end,
		UDim = function(v) return {__type = "UDim", scale=v.Scale, offset=v.Offset} end,
		NumberRange = function(v) return {__type = "NumberRange", min=v.Min, max=v.Max} end,
		TweenInfo = function(v) return {__type = "TweenInfo", time=v.Time, 
															  easingStyle=v.EasingStyle.Name,
															  easingDirection=v.EasingDirection.Name,
															  repeatCount=v.RepeatCount,
															  reverses=v.Reverses,
															  delayTime=v.DelayTime
		} end
	}
	
	local t = typeof(value)
	local serialiser = serialisers[t]
	
	if serialiser then
		return serialiser(value)
	else
		return {__type = t, value = tostring(value)} -- fallback
	end
end

function PropertiesAPI.init()
	generateClassNames()
	dumpClasses()
	--testAll()
	warn("API Loaded Successfully")
end

function PropertiesAPI.getAllProperties(object : Object) -- get all properties of an object
	local compiled = {}
	
	local success, errormsg = pcall(function()
		local className = object.ClassName
		local props = classMutableProperties[className]
		for _, property in pairs(props) do
			local result = object[property]
			compiled[property] = result
		end
	end)
	
	if success then
		return compiled
	else
		warn("Could not get all properties of ", object, " " .. errormsg)
		return nil
	end
end

function PropertiesAPI.serialise(object : Object) -- returns a fully serialisable table with no data loss
	local props = PropertiesAPI.getAllProperties(object)
	if props then
		for property, value in pairs(props) do
			local result
			local success, errormsg = pcall(function()
				props[property] = serialiseValue(value)
			end)

			if success then
				continue
			else
				warn("Could not serialise value, ", value, " ", errormsg)
				return nil
			end
		end
	else
		return nil
	end
	
	return props
end

return PropertiesAPI