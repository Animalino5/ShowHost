local Save = {}

function Save.saveProject(timeline, filename)
    if not filename:find("%.SHA$") then
        filename = filename .. ".SHA"
    end

    local data = "return {\n"
    data = data .. string.format("  stageColor = {%f, %f, %f},\n", _G.StageColor[1], _G.StageColor[2], _G.StageColor[3])
    data = data .. "  audioPath = " .. (timeline.audioPath and string.format("%q", timeline.audioPath) or "nil") .. ",\n"
    data = data .. "  layers = {\n"

    for _, layer in ipairs(timeline.layers) do
        data = data .. "    {\n      frames = {\n"
        for _, frame in ipairs(layer.frames) do
            data = data .. "        { objects = {\n"
            for _, obj in ipairs(frame.objects) do
                data = data .. string.format(
                    "          { type = %q, category = %q, x = %d, y = %d, w = %d, h = %d, angle = %f, flipX = %d },\n",
                    obj.type, obj.category, obj.x, obj.y, obj.w, obj.h, obj.angle or 0, obj.flipX or 1
                )
            end
            data = data .. "        }},\n"
        end
        data = data .. "      }\n    },\n"
    end
    data = data .. "  }\n}"

    local success, message = love.filesystem.write(filename, data)
    if success then
        print("Project saved: " .. filename)
    else
        print("Save failed: " .. message)
    end
end

function Save.loadProject(timeline, filename, library)
    if not love.filesystem.getInfo(filename) then 
        print("File not found: " .. filename)
        return 
    end
    
    local chunk, loadErr = love.filesystem.load(filename)
    if not chunk then 
        print("Error loading file: " .. tostring(loadErr))
        return 
    end

    local data = chunk()
    if not data or not data.layers then 
        print("Invalid .SHA file structure")
        return 
    end

if data.stageColor then
        _G.StageColor = data.stageColor
    end
    
    if timeline.audio then
        timeline.audio:stop()
        timeline.audio = nil
        timeline.audioPath = nil
    end

    timeline.layers = {}

    for lIdx, layerData in ipairs(data.layers) do
        local newLayer = {name = "Layer " .. lIdx, frames = {} }
        
        if layerData.frames then
            for fIdx, frameData in ipairs(layerData.frames) do
                local newFrame = { objects = {} }
                
                if frameData.objects then
                    for _, obj in ipairs(frameData.objects) do
                        if library[obj.category] and library[obj.category][obj.type] then
                            obj.data = library[obj.category][obj.type]
                            table.insert(newFrame.objects, obj)
                        
                        elseif obj.category == "imported" then
                            if love.filesystem.getInfo(obj.type) then
                                local success, img = pcall(love.graphics.newImage, obj.type)
                                if success then
                                    library["imported"] = library["imported"] or {}
                                    library["imported"][obj.type] = img
                                    obj.data = img
                                    table.insert(newFrame.objects, obj)
                                    print("Auto-restored: " .. obj.type)
                                end
                            else
                                print("File missing on disk: " .. tostring(obj.type))
                            end
                        else
                            print("Asset not found: " .. tostring(obj.type))
                        end
                    end
                end
                table.insert(newLayer.frames, newFrame)
            end
        end
        table.insert(timeline.layers, newLayer)
    end

    timeline.audioPath = data.audioPath
    if timeline.audioPath then
        local lovePath = timeline.audioPath:gsub("\\", "/")
        local success, source = pcall(love.audio.newSource, lovePath, "stream")
        if success then timeline.audio = source end
    end

    print("Project loaded successfully: " .. filename)
end

return Save