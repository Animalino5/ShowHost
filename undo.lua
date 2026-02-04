local Undo = {}
Undo.stack = {}
Undo.max_states = 20 

function Undo.saveState(timeline)
    local snapshot = {}
    for lIdx, layer in ipairs(timeline.layers) do
        snapshot[lIdx] = { name = layer.name, frames = {} }
        for fIdx, frame in ipairs(layer.frames) do
            snapshot[lIdx].frames[fIdx] = { objects = {} }
            for _, obj in ipairs(frame.objects) do
                local copy = {}
                for k, v in pairs(obj) do copy[k] = v end
                table.insert(snapshot[lIdx].frames[fIdx].objects, copy)
            end
        end
    end

    table.insert(Undo.stack, snapshot)
    if #Undo.stack > Undo.max_states then
        table.remove(Undo.stack, 1)
    end
end

function Undo.perform(timeline)
    if #Undo.stack > 1 then
        table.remove(Undo.stack) 
        local previous = Undo.stack[#Undo.stack]
        if previous then
            timeline.layers = {}
            for lIdx, layer in ipairs(previous) do
                timeline.layers[lIdx] = layer
            end
        end
    end
end

return Undo