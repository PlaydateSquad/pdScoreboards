
import "CoreLibs/object"
import "CoreLibs/keyboard"
import "libraries/pdScoreboards"

local pd <const> = playdate
local gfx <const> = pd.graphics

local highscore_sprite = gfx.sprite.new(gfx.image.new(200, 240))
highscore_sprite:setCenter(0, 0)
highscore_sprite:moveTo(0, 0)
highscore_sprite:add()
local lowscore_sprite = gfx.sprite.new(gfx.image.new(200, 240))
lowscore_sprite:setCenter(0, 0)
lowscore_sprite:moveTo(200, 0)
lowscore_sprite:add()

local function drawScores(title, scores, sprite)
    local image = sprite:getImage()
    gfx.lockFocus(image)
        gfx.clear()
        gfx.drawText(title, 5, 5)
        for index = 1, #scores do
            local score = scores[index]
            local text = "*#" .. score.rank .. "* " .. score.player .. ": _" .. score.value .. "_"
            gfx.drawText(text, 5, 5 + index * 20)
        end
    gfx.unlockFocus()
    sprite:setImage(image)
end

local function updateScoreboard(board)
    if board == "high" then
        playdate.scoreboards.getScores("highscores", function(status, result)
            printTable(result)
            drawScores("High Scores", result.scores, highscore_sprite)
        end)
    elseif board == "low" then
        playdate.scoreboards.getScores("lowscores", function(status, result)
            drawScores("Low Scores", result.scores, lowscore_sprite)
        end)
    end
end

playdate.scoreboards.initialize({
    { boardID = "highscores", name = "High Scores" },
    { boardID = "lowscores", name = "Low Scores", order="ascending" }
}, function(status, _)
    if status.code ~= "OK" then
        updateScoreboard("high")
        updateScoreboard("low")
    end
end)

playdate.inputHandlers.push({
    leftButtonUp = function()
        playdate.scoreboards.addScore("highscores", math.random(1, 100), function(status, result)
            printTable(result)
            updateScoreboard("high")
        end)
    end,
    rightButtonUp = function()
        playdate.scoreboards.addScore("lowscores", math.random(1, 100), function(status, result)
            printTable(result)
            updateScoreboard("low")
        end)
    end,
    upButtonUp = function()
        pd.keyboard.show()
        function pd.keyboard.keyboardWillHideCallback(ok)
            if ok then
                playdate.scoreboards.setPlayer(pd.keyboard.text)
            end
        end
    end,
})

function pd.update()
    gfx.sprite.update()
end
