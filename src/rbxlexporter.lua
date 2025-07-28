--------------------------------------------------------------------------------------------
-- rbxlExporter created by Typhoon
-- Requires corresponding python server.py script to receive http data
--------------------------------------------------------------------------------------------

local toolbar = plugin:CreateToolbar("Project Exporter")
local button = toolbar:CreateButton("Export", "", "", "Export Project")

local httpService = game:GetService("HttpService")
local scriptEditorService = game:GetService("ScriptEditorService")
local runService = game:GetService("RunService")

local PORT : string = "3000"
local PATH : string = "/save"

local LOCAL_SERVER = "http://127.0.0.1:" .. PORT .. PATH

local CHUNK_SIZE = 800000 -- measured in bytes, can be up to 1.024mb but I set to 0.8mb to be safe
local FOLDER_AVERAGE_SIZE = 75 -- includes content and path
local SCRIPT_AVERAGE_SIZE = 5000
local INSTANCE_AVERAGE_SIZE = 100
local INTERVAL = 4 -- how many size estimations to perform before chunking

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

local function serialiseInstance(root : Instance, path : table, chunks : table, currentChunk : table, sizeEstimationTable : table)
	for _, child in ipairs(root:GetChildren()) do
		local currentPath = table.clone(path)
		
		local fileExtension
		local fileContent

		if #child:GetChildren() > 0 then
			table.insert(currentPath, child.Name)
			currentChunk = serialiseInstance(child, currentPath, chunks, currentChunk, sizeEstimationTable)
		end
		
		if child:IsA("StarterCharacterScripts") or child:IsA("StarterPlayerScripts") or child:IsA("Folder") then
			fileExtension = ".f"
			fileContent = child.ClassName
			sizeEstimationTable["EstimatedChunkSize"] += FOLDER_AVERAGE_SIZE
		elseif child:IsA("Script") or child:IsA("ModuleScript") or child:IsA("LocalScript") then
			fileExtension = ".lua"
			local scriptType = "--" .. child.ClassName .. "\n"
			fileContent = scriptType .. scriptEditorService:GetEditorSource(child)
			sizeEstimationTable["EstimatedChunkSize"] += SCRIPT_AVERAGE_SIZE
		else
			fileExtension = ".instance"
			fileContent = child.ClassName
			sizeEstimationTable["EstimatedChunkSize"] += INSTANCE_AVERAGE_SIZE
		end
		
		table.insert(currentPath, child.Name .. fileExtension)
		table.insert(currentChunk, {
			path = table.clone(currentPath),
			content = fileContent
		})
		
		local estimatedChunkSize = sizeEstimationTable["EstimatedChunkSize"]
		local checkAt = sizeEstimationTable["CheckAt"]
		local sizeIndex = sizeEstimationTable["Index"]
		
		if estimatedChunkSize > checkAt then
			local encodedChunk = httpService:JSONEncode({files = currentChunk})
			local size = #encodedChunk
			
			sizeEstimationTable["EstimatedChunkSize"] = size
			sizeEstimationTable["CheckAt"] += checkAt / sizeIndex -- add itself
			sizeEstimationTable["Index"] += 1
			
			if size > CHUNK_SIZE or checkAt >= CHUNK_SIZE then
				table.insert(chunks, currentChunk)
				currentChunk = {}
				sizeEstimationTable["EstimatedChunkSize"] = 0
				sizeEstimationTable["CheckAt"] = CHUNK_SIZE / INTERVAL
			end
		end
	end
	
	return currentChunk, sizeEstimationTable
end

local function encode(filesToEncode)
	local chunks = {}
	local currentChunk = {}
	local sizeEstimationTable = {
		["EstimatedChunkSize"] = 0,
		["CheckAt"] = CHUNK_SIZE / INTERVAL,
		["Index"] = 1
	}

	for _, folder in ipairs(filesToEncode) do
		currentChunk, sizeEstimationTable = serialiseInstance(folder, {folder.Name}, chunks, currentChunk, sizeEstimationTable)
		if #currentChunk > 0 then
			table.insert(chunks, currentChunk)
			currentChunk = {}
			sizeEstimationTable["EstimatedChunkSize"] = 0
			sizeEstimationTable["CheckAt"] = CHUNK_SIZE / INTERVAL
		end
	end

	return chunks
end

local function post(chunk : string)
	httpService:PostAsync(LOCAL_SERVER, chunk, Enum.HttpContentType.ApplicationJson)
end

local function buildPayload()
	local chunks = encode(FILES_TO_ENCODE)
	local count = 0
	
	for index, chunk in ipairs(chunks) do
		if #chunk > 0 then
			local chunkWithFlags = {
				files = chunk,
				first = (index == 1)
			}

			local payload = httpService:JSONEncode(chunkWithFlags)

			post(payload)
			count += 1
		end
	end
	
	print("Export Success")
	print("Chunk Count: " .. tostring(count))
end

button.Click:Connect(function()
	buildPayload()
end)

if not runService:IsRunning() then
	warn("Project Exporter plugin loaded successfully")
end