Timeline = require("timeline")
Canvas = require("canvas")
local ContextMenu = require("contextmenu")
local TopBar = require("topbar")
local Save = require("save")
local Undo = require("undo")

library = {} 
local categories = {
    eyes = {"Eye_Normal", "Eye_Closed", "Eye_Cheek", "Eye_Surprised", "Eye_Angry", "Eye_Sad"},
    bodies = {"basic"},
    mouths = {"Closed", "Closed_Neutral", "Closed_Teeth", "Closed_teeth_frown", "Frown", "Frown_open", "Frown_Teeth", "o", "Open", "Open_Frown", "Smile_Open", "smile_teeth", "tall"},
    limbs = {"Asking_Arm", "Curly_Arm", "Finger", "Straight_Arm", "Leg_Straight", "Leg_Bent", "Leg_Bent_Above"}
}

local currentCategory = "eyes"
local selectedAsset = nil
local draggedObj = nil
selectedObj = nil  
local activeHandle = nil 
local FrameClipboard = nil
local isSwapping = false
TargetFPS = 12
local categoryScroll = 0

_G.isTypingSaveName = false
_G.isTypingLoadName = false
_G.isTypingAssetPath = false
_G.isTypingColor = false
_G.isTypingFPS = false
_G.tempPath = "" 
_G.tempHex = ""
_G.tempFPS = ""
_G.StageColor = {1, 1, 1}

function loadAsset(cat, name)
    local path = "assets/" .. cat .. "/" .. name .. ".png"
    if love.filesystem.getInfo(path) then
        local img = love.graphics.newImage(path)
        library[cat] = library[cat] or {}
        library[cat][name] = img
    end
end

function drawButton(x, y, w, h, text, fn, highlight, scroll)
    local scrollOffset = scroll or 0
    local mx, my = love.mouse.getPosition()
    
    local hover = mx > x and mx < x+w and my > (y - scrollOffset) and my < (y + h - scrollOffset)
    
    local color = {0.8, 0.4, 0}
    if highlight then color = {1, 0.9, 0.2}
    elseif hover then color = {1, 0.6, 0.2}
    end
    
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", x, y, w, h, 6)
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(text, x + 5, y + 5, 0, 0.75)
    
    if hover and love.mouse.isDown(1) and not _G.clicked then 
        fn()
        _G.clicked = true 
    end
end

function math.clamp(v, min, max) return math.max(min, math.min(max, v)) end

function hexToRgb(hex)
    hex = hex:gsub("#","")
    local r = tonumber("0x"..hex:sub(1,2)) or 255
    local g = tonumber("0x"..hex:sub(3,4)) or 255
    local b = tonumber("0x"..hex:sub(5,6)) or 255
    return {r/255, g/255, b/255}
end

function love.load()
    love.window.setMode(1024, 768, {resizable=true})
    Timeline.load()
    ContextMenu.load()
    TopBar.load()
    Undo.saveState(Timeline)

    for cat, files in pairs(categories) do
        library[cat] = {}
        for _, name in ipairs(files) do
            loadAsset(cat, name)
        end
    end
end

function love.update(dt)
    Timeline.update(dt)
    
if Timeline.isPlaying and _G.Timeline.audio then

    local targetTime = (Timeline.currentFrame - 1) / (TargetFPS or 12)
    
    if not _G.Timeline.audio:isPlaying() then
        _G.Timeline.audio:seek(targetTime)
        _G.Timeline.audio:play()
    else
        local actualTime = _G.Timeline.audio:tell()
        if math.abs(actualTime - targetTime) > 0.1 then
            _G.Timeline.audio:seek(targetTime)
        end
    end
else
    if _G.Timeline.audio then 
        _G.Timeline.audio:stop() 
    end
end
    
    local sw, sh = love.graphics.getDimensions()
    local tlT = sh - Timeline.height
    local mx, my = love.mouse.getPosition()
    local sideW = 200

    Canvas.zoom = math.min((sw - sideW) / 640, tlT / 480) * 0.9

    if Timeline.isPlaying then return end

    if love.mouse.isDown(1) then
        local sx, sy = Canvas.getCoords(mx, my, sw, sh, Timeline.height)
        
        if activeHandle and selectedObj then
            if activeHandle == "corner" then
                selectedObj.w = math.max(10, sx - selectedObj.x)
                selectedObj.h = math.max(10, sy - selectedObj.y)
            elseif activeHandle == "rotate" then
                local ox, oy = selectedObj.x + selectedObj.w/2, selectedObj.y + selectedObj.h/2
                selectedObj.angle = math.atan2(sy - oy, sx - ox) + math.pi/2
            end
        elseif draggedObj then
            draggedObj.x = sx - (draggedObj.w / 2)
            draggedObj.y = sy - (draggedObj.h / 2)
        elseif my > tlT then
            if my > tlT + Timeline.buttonAreaH then
                local relativeX = mx - Timeline.sidebarWidth + Timeline.scrollX
                local clickedFrame = math.floor(relativeX / Timeline.frameW) + 1
                Timeline.currentFrame = math.clamp(clickedFrame, 1, #Timeline.layers[1].frames)
            end
        end
    else
        draggedObj = nil
        activeHandle = nil
    end
end

function love.draw()
    local sw, sh = love.graphics.getDimensions()
    local sideW = 200
    local tlT = sh - Timeline.height

    love.graphics.clear(_G.StageColor)
    Canvas.draw(Timeline.layers, Timeline.currentFrame, Timeline.height, Timeline.showOnion, selectedObj)
    
love.graphics.setColor(0.15, 0.1, 0.05) 
love.graphics.rectangle("fill", sw - sideW, 0, sideW, tlT)

love.graphics.setColor(1, 0.7, 0)
love.graphics.print("CATEGORIES", sw - sideW + 10, 10)
    
    local i = 0
    for catName, _ in pairs(library) do
        local x = sw - sideW + 10 + (i % 2 * 90)
        local y = 30 + (math.floor(i / 2) * 30)
        drawButton(x, y, 85, 25, catName, function() 
            currentCategory = catName; selectedAsset = nil 
        end, currentCategory == catName)
        i = i + 1
    end
    
love.graphics.setColor(1, 0.7, 0)
    love.graphics.line(sw - sideW + 10, 130, sw - 10, 130)
    love.graphics.print("ASSETS: " .. currentCategory:upper(), sw - sideW + 10, 140)

love.graphics.setScissor(sw - sideW, 160, sideW, tlT - 160)
love.graphics.push()
love.graphics.translate(0, -categoryScroll)

local j = 0
if library[currentCategory] then
    for assetName, _ in pairs(library[currentCategory]) do
        local y = 160 + (j * 35)
        
        drawButton(sw - sideW + 10, y, 180, 30, assetName, function() 
            selectedAsset = assetName 
        end, selectedAsset == assetName, categoryScroll) 
        
        j = j + 1
    end
end

love.graphics.pop()
love.graphics.setScissor()

    if _G.isTypingSaveName or _G.isTypingLoadName then
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 0, 0, sw, sh)
        love.graphics.setColor(1, 1, 1)
        local title = _G.isTypingSaveName and "SAVE PROJECT AS (.SHA):" or "LOAD PROJECT (.SHA):"
        love.graphics.printf(title, 0, sh/2 - 40, sw, "center")
        love.graphics.rectangle("line", sw/2 - 300, sh/2 - 15, 600, 30)
        love.graphics.printf(_G.tempPath .. "|", sw/2 - 290, sh/2 - 5, 580, "left")
    end

    if _G.isTypingAssetPath then
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 0, 0, sw, sh)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("TYPE FILENAME TO IMPORT:", 0, sh/2 - 40, sw, "center")
        love.graphics.rectangle("line", sw/2 - 300, sh/2 - 10, 600, 30)
        love.graphics.printf(_G.tempPath .. "|", sw/2 - 290, sh/2, 580, "left")
    end

    if _G.isTypingColor then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, sw, sh)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("TYPE HEX COLOR: #" .. _G.tempHex .. "_", 0, sh/2, sw, "center")
    end

    if _G.isTypingFPS then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, sw, sh)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("SET TARGET FPS (1-24): " .. _G.tempFPS .. "|", 0, sh/2, sw, "center")
    end

    if _G.exportProgress then
        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", 0, 0, sw, sh)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(_G.exportStatus or "EXPORTING...", 0, sh/2 - 40, sw, "center")
        love.graphics.rectangle("fill", sw/2 - 200, sh/2, 400 * _G.exportProgress, 20)
    end

    TopBar.draw()
    Timeline.draw(sw, sh)

    local btY = sh - Timeline.height + 5
    drawButton(5, btY, 55, 25, "+Frm", function() Timeline.addFrame() end)
    drawButton(65, btY, 55, 25, "-Frm", function() Timeline.removeFrame() end)
    drawButton(125, btY, 55, 25, "+Lay", function() Timeline.addLayer() end)
    drawButton(185, btY, 55, 25, "-Lay", function() Timeline.removeLayer() end)
    drawButton(365, btY, 55, 25, "Undo", function() Undo.perform(Timeline) end)
    drawButton(245, btY, 55, 25, "Onion", function() Timeline.showOnion = not Timeline.showOnion end, Timeline.showOnion)
    drawButton(305, btY, 55, 25, (Timeline.isPlaying and "Stop" or "Play"), function() Timeline.isPlaying = not Timeline.isPlaying end, Timeline.isPlaying)

    ContextMenu.draw()
end
    
function love.mousepressed(mx, my, button)
    local sw, sh = love.graphics.getDimensions()
    local tlT = sh - Timeline.height
    local sideW = 200

    local clickingUI = (mx > sw - sideW) or (my > tlT) or (my < 30)

    if button == 1 or button == 2 then
        if not clickingUI then
            Undo.saveState(Timeline)
        end
    end
    
    if button == 1 then
        if TopBar.click(mx, my, ContextMenu) then return end
    end
    if ContextMenu.visible and ContextMenu.click(mx, my) then return end

    if button == 2 then
        if ContextMenu.openContext(mx, my, Timeline, Canvas, selectedObj) then return end
    end

    if button == 1 then
        if mx > sw - sideW then return end
        if my > tlT then
            if mx < Timeline.sidebarWidth then
                local relativeY = my - (tlT + Timeline.buttonAreaH + Timeline.headerH) + Timeline.scrollY
                Timeline.currentLayer = math.clamp(math.floor(relativeY / Timeline.rowH) + 1, 1, #Timeline.layers)
            else
                local relativeX = mx - Timeline.sidebarWidth + Timeline.scrollX
                Timeline.currentFrame = math.clamp(math.floor(relativeX / Timeline.frameW) + 1, 1, #Timeline.layers[1].frames)
            end
            return
        end

        local sx, sy = Canvas.getCoords(mx, my, sw, sh, Timeline.height)
        local cf = Timeline.layers[Timeline.currentLayer].frames[Timeline.currentFrame]

        if selectedObj then
            local hSize = 15 / Canvas.zoom
            local ox, oy = selectedObj.x + selectedObj.w/2, selectedObj.y + selectedObj.h/2
            local s, c = math.sin(-(selectedObj.angle or 0)), math.cos(-(selectedObj.angle or 0))
            local rx = (sx - ox) * c - (sy - oy) * s
            local ry = (sx - ox) * s + (sy - oy) * c
            if math.abs(rx) < hSize and math.abs(ry - (-selectedObj.h/2 - 20)) < hSize then activeHandle = "rotate"; return end
            if math.abs(rx - selectedObj.w/2) < hSize and math.abs(ry - selectedObj.h/2) < hSize then activeHandle = "corner"; return end
        end

        for i = #cf.objects, 1, -1 do
            local obj = cf.objects[i]
            if sx > obj.x and sx < obj.x + obj.w and sy > obj.y and sy < obj.y + obj.h then
                selectedObj, draggedObj = obj, obj; return
            end
        end

        if selectedAsset and not isSwapping then
            local newObj = {
                data = library[currentCategory][selectedAsset],
                type = selectedAsset, category = currentCategory,
                x = sx - 75, y = sy - 75, w = 150, h = 150, angle = 0, flipX = 1
            }
            newObj.h = 150 * (newObj.data:getHeight() / newObj.data:getWidth())
            table.insert(cf.objects, newObj)
            selectedObj = newObj
        else
            selectedObj = nil
        end
    end
end

function love.wheelmoved(x, y)
    local mx, my = love.mouse.getPosition()
    local sw, sh = love.graphics.getDimensions()
    local sideW = 200
    local tlT = sh - Timeline.height

    if mx > sw - sideW and my < tlT then
        categoryScroll = math.max(0, categoryScroll - y * 20)
        
    elseif my > tlT then
        if love.keyboard.isDown("lshift") then
            Timeline.scrollX = math.max(0, Timeline.scrollX - y * 30)
        else
            Timeline.scrollY = math.max(0, Timeline.scrollY - y * 30)
        end
    elseif selectedObj then
        local scale = y > 0 and 1.1 or 0.9
        selectedObj.w, selectedObj.h = selectedObj.w * scale, selectedObj.h * scale
    end
end

function love.textinput(t)
    if _G.isTypingColor then _G.tempHex = _G.tempHex .. t
    elseif _G.isTypingFPS then _G.tempFPS = _G.tempFPS .. t
    elseif _G.isTypingAssetPath or _G.isTypingSaveName or _G.isTypingLoadName then _G.tempPath = _G.tempPath .. t end
end

function love.keypressed(key)
    if _G.isTypingAssetPath or _G.isTypingSaveName or _G.isTypingLoadName then
        if key == "return" then
            local path = _G.tempPath:gsub('"', '')
            if _G.isTypingSaveName then Save.saveProject(Timeline, path)
            elseif _G.isTypingLoadName then 
                if not path:find("%.SHA$") then path = path .. ".SHA" end
                Save.loadProject(Timeline, path, library)

elseif _G.isTypingAssetPath then
    if love.filesystem.getInfo(path) then
        local ext = path:match("^.+(%..+)$")
        if ext == ".png" then
            local success, img = pcall(love.graphics.newImage, path)
            if success then
                library["imported"] = library["imported"] or {}
                library["imported"][path] = img 
                currentCategory = "imported"
                selectedAsset = path 
            end
        elseif ext == ".mp3" or ext == ".wav" then
            local success, source = pcall(love.audio.newSource, path, "stream")
            if success then
              _G.Timeline.audio = source 
              _G.Timeline.audioPath = path
              end
        end
    end
end
            _G.isTypingAssetPath, _G.isTypingSaveName, _G.isTypingLoadName = false, false, false
            _G.tempPath = ""
        elseif key == "backspace" then _G.tempPath = _G.tempPath:sub(1, -2)
        elseif key == "escape" then _G.isTypingAssetPath, _G.isTypingSaveName, _G.isTypingLoadName = false, false, false end
        return
    end

    if _G.isTypingColor then
        if key == "return" then _G.StageColor = hexToRgb(_G.tempHex); _G.isTypingColor = false
        elseif key == "backspace" then _G.tempHex = _G.tempHex:sub(1, -2)
        elseif key == "escape" then _G.isTypingColor = false end
        return
    end

    if _G.isTypingFPS then
        if key == "return" then
            local val = tonumber(_G.tempFPS)
            if val then TargetFPS = math.clamp(val, 1, 60) end
            _G.isTypingFPS = false
        elseif key == "backspace" then _G.tempFPS = _G.tempFPS:sub(1, -2)
        elseif key == "escape" then _G.isTypingFPS = false end
        return
    end

    if key == "space" then Timeline.isPlaying = not Timeline.isPlaying end
    if love.keyboard.isDown("lctrl") and key == "z" then
    Undo.perform(Timeline)
end
end

function love.mousereleased() _G.clicked, draggedObj, activeHandle = false, nil, nil end