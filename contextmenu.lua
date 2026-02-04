local ContextMenu = {}
local FrameClipboard = nil

function ContextMenu.load()
    ContextMenu.visible = false
    ContextMenu.x, ContextMenu.y = 0, 0
    ContextMenu.w, ContextMenu.itemH = 160, 28
    ContextMenu.options = {}
    ContextMenu.title = ""
end

local function deepCopy(obj)
    if type(obj) ~= 'table' then return obj end
    local res = {}
    for k, v in pairs(obj) do res[deepCopy(k)] = deepCopy(v) end
    return res
end

function ContextMenu.openContext(mx, my, Timeline, Canvas, selectedObj)
    local sw, sh = love.graphics.getDimensions()
    local tlT = sh - Timeline.height
    local sideW = 200

    if my > tlT then
        local relX = mx - Timeline.sidebarWidth + Timeline.scrollX
        local relY = my - (tlT + Timeline.buttonAreaH + Timeline.headerH) + Timeline.scrollY
        local fIdx = math.floor(relX / Timeline.frameW) + 1
        local lIdx = math.floor(relY / Timeline.rowH) + 1

        if mx < Timeline.sidebarWidth then
            if Timeline.layers[lIdx] then
                ContextMenu.show(mx, my, {
                    {text = "Duplicate Layer", fn = function()
                        local newLayer = deepCopy(Timeline.layers[lIdx])
                        newLayer.name = newLayer.name .. " (Copy)"
                        table.insert(Timeline.layers, lIdx + 1, newLayer)
                    end},
                    {text = "Delete Layer", fn = function()
                        if #Timeline.layers > 1 then
                            table.remove(Timeline.layers, lIdx)
                        end
                    end},
{text = "Move Layer Down", font = nil, fn = function()
    if lIdx > 1 then
        local layer = table.remove(Timeline.layers, lIdx)
        table.insert(Timeline.layers, lIdx - 1, layer)
        Timeline.currentLayer = lIdx - 1
    end
end},
{text = "Move Layer Up", font = nil, fn = function()
    if lIdx < #Timeline.layers then
        local layer = table.remove(Timeline.layers, lIdx)
        table.insert(Timeline.layers, lIdx + 1, layer)
        Timeline.currentLayer = lIdx + 1
    end
end},
                    {text = "Clear All Frames", fn = function()
                        for _, frame in ipairs(Timeline.layers[lIdx].frames) do
                            frame.objects = {}
                        end
                    end}
                }, "Layer: " .. (Timeline.layers[lIdx].name or lIdx))
                return true
            end
        
        elseif Timeline.layers[lIdx] and Timeline.layers[lIdx].frames[fIdx] then
            local frame = Timeline.layers[lIdx].frames[fIdx]
            ContextMenu.show(mx, my, {
                {text = "Copy Frame", fn = function()
                    _G.FrameClipboard = deepCopy(frame.objects)
                end},
                {text = "Paste Frame", fn = function()
                    if _G.FrameClipboard then
                        frame.objects = deepCopy(_G.FrameClipboard)
                    end
                end},
                {text = "Clear Frame", fn = function()
                    frame.objects = {}
                end}
            }, "Frame " .. fIdx)
            return true
        end
    end

    if mx < sw - sideW then
        local sx, sy = Canvas.getCoords(mx, my, sw, sh, Timeline.height)
        local cf = Timeline.layers[Timeline.currentLayer].frames[Timeline.currentFrame]
        
        for i = #cf.objects, 1, -1 do
            local obj = cf.objects[i]
            if sx > obj.x and sx < obj.x + obj.w and sy > obj.y and sy < obj.y + obj.h then
                
                local mainMenu = {
                    {text = "Swap Asset >", fn = function() 
                        ContextMenu.showSwapSubmenu(mx, my, obj) 
                    end},
                    {text = "Flip Horizontal", fn = function()
                        obj.flipX = (obj.flipX == -1) and 1 or -1
                    end},
                    {text = "Reset All", fn = function()
                        obj.angle = 0
                        obj.flipX = 1
                        obj.w = 150
                        obj.h = 150 * (obj.data:getHeight() / obj.data:getWidth())
                    end},
                    {text = "Duplicate", fn = function()
                       
                        local copy = deepCopy(obj)
                        copy.x, copy.y = copy.x + 20, copy.y + 20
                        table.insert(cf.objects, copy)
                    end},
                    {text = "Delete", fn = function() 
                        table.remove(cf.objects, i) 
                        _G.selectedObj = nil 
                        end}
                }

                ContextMenu.show(mx, my, mainMenu, "Object: " .. (obj.type or "Item"))
                
                return true
            end
        end
    end
    end

function ContextMenu.showSwapSubmenu(mx, my, obj)
    local cat = obj.category or "eyes"
    local swapOptions = {}

    if _G.library and _G.library[cat] then
        for assetName, imgData in pairs(_G.library[cat]) do
            table.insert(swapOptions, {
                text = assetName,
fn = function()
    local imgData = _G.library[cat][assetName]
    
    local scaleX = obj.w / obj.data:getWidth()
    local scaleY = obj.h / obj.data:getHeight()
    
    obj.data = imgData
    obj.type = assetName
    
    obj.w = imgData:getWidth() * scaleX
    obj.h = imgData:getHeight() * scaleY
                end
            })
        end
    end

    ContextMenu.show(mx, my, swapOptions, "Swap " .. cat:upper())
end

function ContextMenu.show(x, y, options, title)
    ContextMenu.x, ContextMenu.y = x, y
    ContextMenu.options = options
    ContextMenu.title = title or ""
    ContextMenu.visible = true
end

function ContextMenu.draw()
    if not ContextMenu.visible then return end
    local mx, my = love.mouse.getPosition()
    local hasTitle = ContextMenu.title ~= ""
    local titleH = hasTitle and 25 or 0
    local totalH = (#ContextMenu.options * ContextMenu.itemH) + titleH

    love.graphics.setColor(0.1, 0.05, 0, 0.95)
    love.graphics.rectangle("fill", ContextMenu.x, ContextMenu.y, ContextMenu.w, totalH, 6)
    love.graphics.setColor(0.8, 0.4, 0) 
    love.graphics.rectangle("line", ContextMenu.x, ContextMenu.y, ContextMenu.w, totalH, 6)
    
    if hasTitle then
        love.graphics.setColor(0.3, 0.15, 0.05)
        love.graphics.rectangle("fill", ContextMenu.x, ContextMenu.y, ContextMenu.w, titleH, 6)
        love.graphics.setColor(1, 0.9, 0.2) 
        love.graphics.print(ContextMenu.title, ContextMenu.x + 10, ContextMenu.y + 5, 0, 0.7)
    end

    for i, opt in ipairs(ContextMenu.options) do
        local optY = ContextMenu.y + titleH + (i-1) * ContextMenu.itemH
        local hover = mx > ContextMenu.x and mx < ContextMenu.x + ContextMenu.w 
                      and my > optY and my < optY + ContextMenu.itemH
        
        if hover then
            love.graphics.setColor(1, 0.6, 0.1)
            love.graphics.rectangle("fill", ContextMenu.x + 2, optY + 2, ContextMenu.w - 4, ContextMenu.itemH - 4, 4)
            love.graphics.setColor(0, 0, 0) 
        else
            love.graphics.setColor(1, 1, 1) 
        end
        love.graphics.print(opt.text, ContextMenu.x + 10, optY + 5, 0, 0.7)
    end
end

function ContextMenu.click(mx, my)
    if not ContextMenu.visible then return false end
    
    local hasTitle = ContextMenu.title ~= ""
    local titleH = hasTitle and 25 or 0
    local menuH = #ContextMenu.options * ContextMenu.itemH + titleH

    if mx > ContextMenu.x and mx < ContextMenu.x + ContextMenu.w 
       and my > ContextMenu.y and my < ContextMenu.y + menuH then
        
        if hasTitle and my < ContextMenu.y + titleH then return true end

        local idx = math.floor((my - (ContextMenu.y + titleH)) / ContextMenu.itemH) + 1
        local opt = ContextMenu.options[idx]
        
        if opt and opt.fn then
            opt.fn() 
            
            if not opt.text:find(">") then 
                ContextMenu.visible = false 
            end
        end
        return true
    end
    
    
    ContextMenu.visible = false
    return false
end

return ContextMenu