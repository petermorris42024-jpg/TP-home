-- This is a LocalScript (put in StarterPlayerScripts or similar)
-- This script automatically teleports the local player to the MainMap and then to a specific campsite.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

-- The specific CFrame for the initial spawn location.
local spawn_cframe = CFrame.new(-275.9091491699219, 25.812084197998047, -1548.145751953125, -0.9798217415809631, 0.0000227206928684609, 0.19986890256404877, -0.000003862579433189239, 1, -0.00013261348067317158, -0.19986890256404877, -0.00013070966815575957, -0.9798217415809631)

-- Attempt to require the necessary InteriorsM module.
local InteriorsM = nil
local successInteriorsM, errorMessageInteriorsM = pcall(function()
	InteriorsM = require(ReplicatedStorage.ClientModules.Core.InteriorsM.InteriorsM)
end)

if not successInteriorsM then
	warn("Failed to require InteriorsM:", errorMessageInteriorsM)
	warn("Please ensure the path 'ReplicatedStorage.ClientModules.Core.InteriorsM.InteriorsM' is correct.")
	return
end

print("InteriorsM module loaded successfully. Setting up the two-step teleport.")

-- Define the teleport settings for the first teleport to the MainMap.
local teleportSettings = {
	-- These are likely required properties for the module to function correctly.
	door_id_for_location_module = "MainDoor",
	exiting_door = "MainDoor",
	house_owner = LocalPlayer,
	spawn_cframe = spawn_cframe,

	-- Optional visual settings for the teleport
	fade_in_length = 0.5,
	fade_out_length = 0.4,
	fade_color = Color3.new(0, 0, 0),
}

print("Attempting to initiate first teleport to the MainMap.")

-- Use a small wait before initiating the teleport to ensure everything is ready.
task.wait(1)

-- Initiate the teleport using the InteriorsM module.
InteriorsM.enter_smooth("MainMap", "MainDoor", teleportSettings)

print("Automated teleport script initiated. Waiting for character to move...")

-- --- NEW LOGIC: Wait for the character's position to change. ---
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Wait until the character is close to the expected spawn location.
local maxWaitTime = 30 -- Wait for up to 30 seconds for the teleport to complete.
local startTime = tick()
local teleportCompleted = false

while tick() - startTime < maxWaitTime and not teleportCompleted do
	-- Calculate the distance between the character and the target spawn location.
	local distance = (humanoidRootPart.Position - spawn_cframe.Position).magnitude
	
	print("Distance to spawn point:", distance) -- Added for debugging
	
	if distance < 15 then -- Increased the check to be more reliable
		teleportCompleted = true
		break
	end
	
	task.wait(0.1)
end

if not teleportCompleted then
	warn("Character did not move to MainMap in time. Second teleport cancelled.")
	return
end

print("Character is now at the MainMap spawn location. Beginning the second teleport.")

-- Find the "BeachPartyAilmentTarget" part.
local target_part = Workspace:WaitForChild("StaticMap"):WaitForChild("Beach"):WaitForChild("BeachPartyAilmentTarget")

-- --- NEW LOGIC: CREATE A FLAT PLATFORM AT THE TARGET LOCATION ---
if target_part then
	print("Creating a landing platform at the target location...")
	local platform = Instance.new("Part")
	platform.Name = "TeleportPlatform"
	platform.Size = Vector3.new(200, 1, 200) -- Creates a 200x200 stud platform
	
	-- Create a new, perfectly flat CFrame with the same X, Y, and Z position but no rotation.
	local flat_cframe = CFrame.new(target_part.Position) * CFrame.Angles(0,0,0) * CFrame.new(0,5,0)
	
	platform.CFrame = flat_cframe
	platform.Anchored = false
	platform.CanCollide = false -- The change to make the platform solid
	platform.Color = Color3.new(0.2, 0.8, 0.2) -- A nice green color
	platform.Parent = Workspace
	print("Platform created successfully.")
	
	-- Perform the final teleport to a position above the platform.
	-- This is the key change to ensure you land safely on top.
	print("Teleporting to a safe position on the platform...")
	humanoidRootPart.CFrame = CFrame.new(platform.Position + Vector3.new(0, 3, 0))
	print("Teleport to campsite completed.")
else
	warn("Could not find BeachPartyAilmentTarget part. Cannot create platform or teleport.")
end