-- src/features/modules/impl/blatant/HitBoxes.lua

local HitBoxes = {
    Name = "HitBoxes",
    Description = "Expand player hitboxes."
}

function HitBoxes.Callback(enabled)
    if enabled then
        print("HitBoxes Enabled")
    else
        print("HitBoxes Disabled")
    end
end

return HitBoxes