local Canvas = {}
Canvas.width = 640
Canvas.height = 480
Canvas.zoom = 1.0

function Canvas.draw(layers, currentFrame, tlHeight, showOnion, selectedObj)
    local sw, sh = love.graphics.getDimensions()
    local sideW, topH = 200, 30
    local cx, cy = (sw - sideW) / 2, (sh - tlHeight - topH) / 2 + topH
    
    local activeLayerIdx = _G.Timeline.currentLayer or 1

    love.graphics.setColor(0.05, 0.05, 0.05)
    love.graphics.rectangle("fill", 0, 0, sw - sideW, sh - tlHeight)

    love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.scale(Canvas.zoom)
        love.graphics.translate(-Canvas.width/2, -Canvas.height/2)

        love.graphics.setColor(_G.StageColor or {1, 1, 1})
        love.graphics.rectangle("fill", 0, 0, Canvas.width, Canvas.height)

        for lIdx, l in ipairs(layers) do
            local f = l.frames[currentFrame]
            if f then
                for _, obj in ipairs(f.objects) do
                    love.graphics.setColor(1, 1, 1, 1)
                    if obj.data then
                        local sx = (obj.w / obj.data:getWidth()) * (obj.flipX or 1)
                        local sy = obj.h / obj.data:getHeight()
                        love.graphics.draw(obj.data, obj.x + obj.w/2, obj.y + obj.h/2, obj.angle or 0, sx, sy, obj.data:getWidth()/2, obj.data:getHeight()/2)
                    end
                end
            end
        end

        if showOnion then
            for offset = -2, 2 do
                if offset ~= 0 then
                    local targetFrame = currentFrame + offset
                    if targetFrame >= 1 and targetFrame <= #layers[1].frames then
                        local alpha = (math.abs(offset) == 1) and 0.35 or 0.15 
                        
                        local l = layers[activeLayerIdx]
                        local f = l.frames[targetFrame]
                        if f then
                            for _, obj in ipairs(f.objects) do
                                if offset < 0 then
                                    love.graphics.setColor(1, 0.2, 0.2, alpha)
                                else
                                    love.graphics.setColor(0.2, 0.5, 1, alpha)
                                end
                                
                                if obj.data then
                                    local sx = (obj.w / obj.data:getWidth()) * (obj.flipX or 1)
                                    local sy = obj.h / obj.data:getHeight()
                                    love.graphics.draw(obj.data, obj.x + obj.w/2, obj.y + obj.h/2, obj.angle or 0, sx, sy, obj.data:getWidth()/2, obj.data:getHeight()/2)
                                end
                            end
                        end
                    end
                end
            end
        end

        if selectedObj then
            love.graphics.setColor(0.39, 0.53, 0.92)
            love.graphics.setLineWidth(2 / Canvas.zoom)
            love.graphics.push()
                love.graphics.translate(selectedObj.x + selectedObj.w/2, selectedObj.y + selectedObj.h/2)
                love.graphics.rotate(selectedObj.angle or 0)
                love.graphics.rectangle("line", -selectedObj.w/2, -selectedObj.h/2, selectedObj.w, selectedObj.h)
                
                local hSize = 8 / Canvas.zoom
                love.graphics.line(0, -selectedObj.h/2, 0, -selectedObj.h/2 - 20)
                love.graphics.circle("fill", 0, -selectedObj.h/2 - 20, hSize/2)
                love.graphics.rectangle("fill", selectedObj.w/2 - hSize/2, selectedObj.h/2 - hSize/2, hSize, hSize)
            love.graphics.pop()
        end

    love.graphics.pop() 
end

function Canvas.getCoords(mx, my, sw, sh, tlH)
    local sideW = 200
    local topH = 30 
    local cx, cy = (sw - sideW) / 2, (sh - tlH - topH) / 2 + topH
    
    return (mx - cx)/Canvas.zoom + Canvas.width/2, (my - cy)/Canvas.zoom + Canvas.height/2
end

return Canvas