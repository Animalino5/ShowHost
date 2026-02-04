local Export = {}

function Export.saveSequence(Timeline, Canvas, StageColor)
    local baseDir = love.filesystem.getSourceBaseDirectory()
    local saveDir = love.filesystem.getSaveDirectory()
    
    local exePath = (baseDir .. "/ffmpeg.exe"):gsub("/", "\\")
    
    local folderName = "export_" .. os.time()
    love.filesystem.createDirectory(folderName)
    
    local fullPath = (saveDir .. "/" .. folderName):gsub("/", "\\")
    local outputPath = (fullPath .. "\\output.mp4")

    local buffer = love.graphics.newCanvas(Canvas.width, Canvas.height)
    local totalFrames = #Timeline.layers[1].frames
    local fps = _G.TargetFPS or 12

    _G.exportStatus = "GENERATING PNGS..."
    for f = 1, totalFrames do
        _G.exportProgress = (f / totalFrames) * 0.5
        
        love.graphics.setCanvas(buffer)
        love.graphics.clear(StageColor or {1, 1, 1})
        
        for _, layer in ipairs(Timeline.layers) do
            local frame = layer.frames[f]
            if frame then
                for _, obj in ipairs(frame.objects) do
                    love.graphics.setColor(1, 1, 1, 1)
                    local sx = (obj.w / (obj.data:getWidth())) * (obj.flipX or 1)
                    local sy = obj.h / (obj.data:getHeight())
                    love.graphics.draw(obj.data, obj.x + obj.w/2, obj.y + obj.h/2, 
                        obj.angle or 0, sx, sy, obj.data:getWidth()/2, obj.data:getHeight()/2)
                end
            end
        end
        love.graphics.setCanvas()

        local imageData = buffer:newImageData()
        local filename = folderName .. "/frame_" .. string.format("%04d", f) .. ".png"
        imageData:encode("png", filename)
        love.graphics.present() 
    end

    local audioInput = ""
    if Timeline.audioPath then
        local realAudioPath = ""
        local root = love.filesystem.getRealDirectory(Timeline.audioPath)
        if root then
            realAudioPath = (root .. "/" .. Timeline.audioPath):gsub("/", "\\")
            audioInput = string.format('-i "%s" -map 0:v:0 -map 1:a:0 -shortest', realAudioPath)
        end
    end

    _G.exportStatus = "ENCODING VIDEO..."
    _G.exportProgress = 0.75
    love.graphics.present()

    local ffmpegCmd = string.format(
        'cmd /c ""%s" -y -r %d -i "%s\\frame_%%04d.png" %s -c:v libx264 -pix_fmt yuv420p "%s""',
        exePath, fps, fullPath, audioInput, outputPath
    )

    print("Executing: " .. ffmpegCmd)
    local success = os.execute(ffmpegCmd)
    
    if success == 0 or success == true then
        _G.exportProgress = 1.0
        love.graphics.present()

        local cleanupCmd = string.format('cmd /c "del /q "%s\\frame_*.png""', fullPath)
        os.execute(cleanupCmd)

        print("Export Complete. Temporary PNGs cleared.")
        love.system.openURL("file://" .. fullPath)
    else
        print("FFmpeg Failed. Make sure ffmpeg.exe is in the same folder as the EXE.")
    end
    
    _G.exportProgress = nil
    _G.exportStatus = nil
end


return Export
