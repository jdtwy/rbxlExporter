--------------------------------------------------------------------------------------------
-- rbxlExporter created by Typhoon
-- Requires corresponding python server.py script to receive http data
--------------------------------------------------------------------------------------------

local toolbar = plugin:CreateToolbar("Project Exporter")
local button = toolbar:CreateButton("Export", "", "", "Export Project")

local httpService = game:GetService("HttpService")
local scriptEditorService = game:GetService("ScriptEditorService")

local PORT : string = "3000"
local PATH : string = "/save"

local LOCAL_SERVER = "http://127.0.0.1:" .. PORT .. PATH

local payload

local FILES_TO_ENCODE = {
	workspace,
	game:GetService("Lighting"),
	game:GetService("ReplicatedFirst"),
	game:GetService("ReplicatedStorage"),
	game:GetService("ServerScriptService"),
	game:GetService("ServerStorage"),
	game:GetService("StarterGui"),
	game:GetService("StarterPlayer")
}


local examplefile = { -- Example of json format
	{
		path = {"Workspace", "Part", "TestScript.lua"},
		content = "-- Hello from Roblox!"
	}
}

local function serialiseInstance(root : Instance, path : table, allFiles : table)
	for _, child in ipairs(root:GetChildren()) do
		local currentPath = table.clone(path)
		
		local fileExtension
		local fileContent

		if #child:GetChildren() > 0 then
			table.insert(currentPath, child.Name)
			serialiseInstance(child, currentPath, allFiles)
		end
		
		if child:IsA("StarterCharacterScripts") or child:IsA("StarterPlayerScripts") or child:IsA("Folder") then
			fileExtension = ""
			fileContent = child.ClassName
		elseif child:IsA("Script") or child:IsA("ModuleScript") or child:IsA("LocalScript") then
			fileExtension = ".lua"
			local scriptType = "--" .. child.ClassName .. "\n"
			fileContent = scriptType .. scriptEditorService:GetEditorSource(child)
		else
			fileExtension = ".instance"
			fileContent = child.ClassName
		end
		
		table.insert(currentPath, child.Name .. fileExtension)
		table.insert(allFiles, {
			path = table.clone(currentPath),
			content = fileContent
		})
		
	end
end

local function encode(filesToEncode)
	local files = {}

	for _, folder in ipairs(filesToEncode) do
		serialiseInstance(folder, {folder.Name}, files)
	end

	return files
end

local function post()
	httpService:PostAsync(LOCAL_SERVER, payload, Enum.HttpContentType.ApplicationJson)
	print("Export Success")
end

button.Click:Connect(function()
	payload = httpService:JSONEncode(
	{
		files = encode(FILES_TO_ENCODE)
	})
	
	post()
end)

print("Project Exporter plugin loaded successfully")
