local Timeline = {}

function Timeline.load()
    Timeline.layers = {{ name = "Layer 1", frames = {{ objects = {} }} }}
    Timeline.currentFrame = 1
    Timeline.currentLayer = 1
    Timeline.isPlaying = false
    Timeline.showOnion = true
    Timeline.fps = 12
    Timeline.timer = 0
    
    Timeline.height = 200
    Timeline.sidebarWidth = 120
    Timeline.rowH = 25
    Timeline.frameW = 25
    Timeline.buttonAreaH = 35 
    Timeline.headerH = 25     

    Timeline.scrollX = 0
    Timeline.scrollY = 0
    
    Timeline.audio = nil 
Timeline.audioPath = nil 
end

function Timeline.addFrame() 
    for _, l in ipairs(Timeline.layers) do table.insert(l.frames, { objects = {} }) end 
end

function Timeline.removeFrame() 
    local totalFrames = #Timeline.layers[1].frames
    
    if totalFrames > 1 then 
        local targetIndex = Timeline.currentFrame
        
        for i = 1, #Timeline.layers do 
            table.remove(Timeline.layers[i].frames, targetIndex) 
        end 
        
        if Timeline.currentFrame > #Timeline.layers[1].frames then
            Timeline.currentFrame = #Timeline.layers[1].frames
        end
        
        Timeline.currentFrame = math.max(1, Timeline.currentFrame)
        print("Deleted Frame: " .. targetIndex) 
    end 
end

function Timeline.addLayer()
    local frames = {}
    for i=1, #Timeline.layers[1].frames do table.insert(frames, {objects={}}) end
    table.insert(Timeline.layers, {name="Layer "..#Timeline.layers+1, frames=frames})
    Timeline.currentLayer = #Timeline.layers 
end

function Timeline.removeLayer()
    if #Timeline.layers > 1 then
        table.remove(Timeline.layers, Timeline.currentLayer)
        Timeline.currentLayer = math.clamp(Timeline.currentLayer, 1, #Timeline.layers)
    end
end

function Timeline.update(dt)
    if not Timeline.isPlaying then 
        if Timeline.audio then Timeline.audio:stop() end
        return 
    end

    if Timeline.audio and not Timeline.audio:isPlaying() then
        local startTime = (Timeline.currentFrame - 1) / _G.TargetFPS
        Timeline.audio:seek(startTime)
        Timeline.audio:play()
    end

    Timeline.timer = (Timeline.timer or 0) + dt
    local frameDuration = 1 / (_G.TargetFPS or 12)

    if Timeline.timer >= frameDuration then
        Timeline.timer = 0
        Timeline.currentFrame = Timeline.currentFrame + 1
        if Timeline.currentFrame > #Timeline.layers[1].frames then
            Timeline.currentFrame = 1
        end
    end
end

function Timeline.draw(sw, sh)
    local tlTop = sh - Timeline.height

    love.graphics.setColor(0.12, 0.08, 0.05)
    love.graphics.rectangle("fill", 0, tlTop, sw, Timeline.height)

    love.graphics.push()
    love.graphics.translate(0, -Timeline.scrollY)
    love.graphics.setScissor(0, tlTop + Timeline.buttonAreaH, Timeline.sidebarWidth, Timeline.height - Timeline.buttonAreaH)
    
    for i, layer in ipairs(Timeline.layers) do
        local y = tlTop + Timeline.buttonAreaH + Timeline.headerH + (i-1) * Timeline.rowH
        
        if i == Timeline.currentLayer then
            love.graphics.setColor(1, 0.6, 0.2)
        else
            love.graphics.setColor(0.2, 0.15, 0.1) 
        end
        
        love.graphics.rectangle("fill", 5, y + 2, Timeline.sidebarWidth - 10, Timeline.rowH - 4, 4)
        
        love.graphics.setColor(i == Timeline.currentLayer and {0,0,0} or {1,1,1})
        love.graphics.print(layer.name, 10, y + 5, 0, 0.7)
    end
    love.graphics.setScissor()
    love.graphics.pop()

    love.graphics.push()
    love.graphics.setScissor(Timeline.sidebarWidth, tlTop + Timeline.buttonAreaH, sw - Timeline.sidebarWidth, Timeline.height - Timeline.buttonAreaH)
    love.graphics.translate(-Timeline.scrollX, -Timeline.scrollY)

    for f = 1, #Timeline.layers[1].frames do
        local x = Timeline.sidebarWidth + (f-1) * Timeline.frameW
        local headerY = tlTop + Timeline.buttonAreaH + Timeline.scrollY

        love.graphics.setColor(0.25, 0.15, 0.05)
        love.graphics.rectangle("fill", x, headerY, Timeline.frameW, Timeline.headerH)
        love.graphics.setColor(1, 0.8, 0.4, 0.6)
        love.graphics.print(f, x + 7, headerY + 5, 0, 0.6)

        love.graphics.setColor(0.3, 0.2, 0.1)
        for i = 1, #Timeline.layers do
            local y = tlTop + Timeline.buttonAreaH + Timeline.headerH + (i-1) * Timeline.rowH
            love.graphics.rectangle("line", x, y, Timeline.frameW, Timeline.rowH)
        end
    end

    local px = Timeline.sidebarWidth + (Timeline.currentFrame - 1) * Timeline.frameW
    love.graphics.setColor(1, 0.5, 0, 0.4) 
    love.graphics.rectangle("fill", px, tlTop + Timeline.buttonAreaH + Timeline.scrollY, Timeline.frameW, Timeline.height)
    love.graphics.setColor(1, 0.8, 0, 1)
    love.graphics.rectangle("fill", px, tlTop + Timeline.buttonAreaH + Timeline.scrollY, 2, Timeline.height)

    love.graphics.setScissor()
    love.graphics.pop()
end

return Timeline