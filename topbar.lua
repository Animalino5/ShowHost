local TopBar = {}
local Export = require("export")

function TopBar.load()
    TopBar.height = 30
    TopBar.menus = {
 { name = "File", options = {
    { text = "New Project", fn = function() love.event.quit("restart") end },
    { text = "Open Assets Folder", fn = function() 
        love.system.openURL("file://" .. love.filesystem.getSaveDirectory())
    end },
  { text = "Save Project (.SHA)", fn = function() 
    _G.isTypingSaveName = true
    _G.tempPath = "my_animation.SHA" 
end },
{ text = "Load Project (.SHA)", fn = function() 
    _G.isTypingLoadName = true
    _G.tempPath = "" 
end },
    { text = "Import Asset (Type Name)", fn = function() 
        _G.isTypingAssetPath = true
        _G.tempPath = ""
    end },
    { text = "Export MP4 Video", fn = function() 
        Export.saveSequence(_G.Timeline, _G.Canvas, _G.StageColor) 
    end },
    { text = "Exit", fn = function() love.event.quit() end }
}},
        { name = "Edit", options = {
            { text = "Stage Color (Hex)", fn = function() 
                _G.isTypingColor = true
                _G.tempHex = ""
            end },
        }},
        { name = "View", options = {
            { text = "Toggle Onion Skin", fn = function() 
                _G.Timeline.showOnion = not _G.Timeline.showOnion 
            end },
            { text = "Set Framerate (1-24)", fn = function() 
                _G.isTypingFPS = true
                _G.tempFPS = ""
            end },
        }}
    }
end

function TopBar.importAudio()
    local fp = _G.pickAudioFile() 
    if fp then
        _G.Timeline.audioPath = fp
        _G.Timeline.audio = love.audio.newSource(fp, "static")
        print("🎵 Audio Loaded: " .. fp)
    end
end

function TopBar.draw()
    local sw = love.graphics.getWidth()
    love.graphics.setColor(0.12, 0.08, 0.05)
    love.graphics.rectangle("fill", 0, 0, sw, TopBar.height)

    local currentX = 10
    local mx, my = love.mouse.getPosition()

    for _, menu in ipairs(TopBar.menus) do
        local tw = love.graphics.getFont():getWidth(menu.name) + 20
        local hover = mx > currentX and mx < currentX + tw and my < TopBar.height

        if hover then
            love.graphics.setColor(1, 0.6, 0.2, 0.3)
            love.graphics.rectangle("fill", currentX, 2, tw, TopBar.height - 4, 4)
        end

        love.graphics.setColor(1, 0.9, 0.5)
        love.graphics.print(menu.name, currentX + 10, 7, 0, 0.8)
        
        menu.lastX = currentX
        menu.lastW = tw
        currentX = currentX + tw
    end
end

function TopBar.click(mx, my, ContextMenu)
    if my > TopBar.height then return false end
    for _, menu in ipairs(TopBar.menus) do
        if mx > menu.lastX and mx < menu.lastX + menu.lastW then
            ContextMenu.show(menu.lastX, TopBar.height, menu.options, menu.name)
            return true
        end
    end
    return false
end

return TopBar