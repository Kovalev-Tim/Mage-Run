local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = {}

function Remotes.Create()
    local folder = ReplicatedStorage:FindFirstChild("RiftRunRemotes") or Instance.new("Folder")
    folder.Name = "RiftRunRemotes"
    folder.Parent = ReplicatedStorage
    local result = { Folder = folder }
    for _, name in { "Attack", "CastSkill", "Upgrade", "PetAction", "HatchEgg", "Sprint" } do
        local remote = folder:FindFirstChild(name) or Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = folder
        result[name] = remote
    end
    for _, name in { "State", "Enemy", "Reward", "Hit", "Message", "OpenEgg", "HatchResult" } do
        local remote = folder:FindFirstChild(name) or Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = folder
        result[name] = remote
    end
    return result
end

return Remotes
