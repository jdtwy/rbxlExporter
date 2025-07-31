--------------------------------------------------------------------------------------------
-- rbxlExporter v1.1.1 created by Typhoon
-- Requires corresponding python server.py script to receive http data
--------------------------------------------------------------------------------------------

local toolbar = plugin:CreateToolbar("Project Exporter")
local button = toolbar:CreateButton("Export", "", "", "Export Project")

local httpService = game:GetService("HttpService")
local scriptEditorService = game:GetService("ScriptEditorService")
local runService = game:GetService("RunService")

local API

if not runService:IsRunning() then
	API = require(script.API)
	API.init()
	warn("Project Exporter plugin loaded successfully")
end

local PORT : string = "3000"
local PATH : string = "/save"

local LOCAL_SERVER = "http://127.0.0.1:" .. PORT .. PATH

local VERSION = "1.1.1"

local CHUNK_SIZE = 800000 -- measured in bytes, can be up to 1.024mb but I set to 0.8mb to be safe
local FOLDER_AVERAGE_SIZE = 75 -- includes content and path
local SCRIPT_AVERAGE_SIZE = 5000
local INSTANCE_AVERAGE_SIZE = 5000
local INTERVAL = 4 -- how many size estimations to perform before chunking

local payload
script:SetAttribute("isRunning", false)

local FILES_TO_ENCODE = {
	workspace,
	game:GetService("Lighting"),
	game:GetService("MaterialService"),
	game:GetService("ReplicatedFirst"),
	game:GetService("ReplicatedStorage"),
	game:GetService("ServerScriptService"),
	game:GetService("ServerStorage"),
	game:GetService("StarterGui"),
	game:GetService("StarterPack"),
	game:GetService("StarterPlayer"),
	game:GetService("Teams"),
	game:GetService("SoundService"),
	game:GetService("TextChatService")
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
			fileContent = API.serialise(child) or child.ClassName
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

local function encode(filesToEncode : table)
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

local function post(payload : string)
	local response
	local success, errormsg = pcall(function()
		response = httpService:PostAsync(LOCAL_SERVER, payload, Enum.HttpContentType.ApplicationJson)
	end)
	
	if success then
		local t = httpService:JSONDecode(response)
		if t["status"] == "versionerror" then
			warn("Versions are not synced between Plugin and Server. Plugin Version: " .. VERSION)
			return false
		end
	else
		if errormsg == "HttpError: ConnectFail" then
			warn(errormsg .. ". Make sure the python server is running")
		else
			warn(errormsg .. ". An unknown exception occured")
		end
	end
	
	return success
end

local function buildPayload()
	local chunks = encode(FILES_TO_ENCODE)
	local count = 0
	local success = true
	
	for index, chunk in ipairs(chunks) do
		if #chunk > 0 then
			local chunkWithFlags = {
				files = chunk,
				first = false,
				version = VERSION
			}

			local payload = httpService:JSONEncode(chunkWithFlags)
			success = post(payload)
			
			if not success then
				break
			end
			count += 1
		end
	end
	
	if success then
		print("Export Success")
		print("Chunk Count: " .. tostring(count))
	end
	script:SetAttribute("isRunning", false)
end

local function verifyVersion()
	local chunk = {
		files = {},
		first = true,
		version = VERSION
	}
	
	local payload = httpService:JSONEncode(chunk)
	local success = post(payload)
	
	if success then
		print("Server received POST request, starting serialisation...")
	end
	
	return success
end

button.Click:Connect(function()
	if not runService:IsRunning() then
		if not script:GetAttribute("isRunning") then
			script:SetAttribute("isRunning", true)
			local verified = verifyVersion()
			if verified then
				buildPayload()
			else
				script:SetAttribute("isRunning", false)
			end
		else
			warn("An export is currrently in progress")
		end
	else
		warn("rbxlExporter cannot be run while ingame")
	end
end)