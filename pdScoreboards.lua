local scoreboards_file, scoreboards = nil, nil

local function _save()
    playdate.datastore.write(scoreboards, scoreboards_file)
end
local function _callback(callback, result)
    callback({ code = "OK", message = "OK" }, result)
end

local function _update_ranks(boardId)
    for board_index = 1, #scoreboards.boards do
        if scoreboards.boards[board_index].boardID == boardId then
            local board = scoreboards.boards[board_index]
            local scores = {}
            for index = 1, #board.scores do
                board.scores[index].rank = index
                table.insert(scores, board.scores[index])
            end
        end
    end
end

local function _init_scoreboards(boards)
    if scoreboards == nil then
        scoreboards = {
            not_authorized = true,  -- On first setup this will let it work offline
            player = "",
            lastUpdated = playdate.getSecondsSinceEpoch(),
            boards = {}
        }
        for index = 1, #boards do
            local b = { scores = {} }
            table.shallowcopy(boards[index], b)
            table.insert(scoreboards.boards, b)
        end
        _save()
    end

    function playdate.scoreboards.setPlayer(username)
        -- Set scoreboard player name, not in official sdk
        scoreboards.player = username
        _save()
    end

    function playdate.scoreboards.getScoreboards(callback)
        -- Get a list of available scoreboards
        local result = {
            lastUpdated = scoreboards.lastUpdated,
            boards = {}
        }
        for id, board in pairs(scoreboards.boards) do
            table.insert(result.boards, {
                boardID = id,
                name = board.name,
            })
        end
        _callback(callback, result)
    end

    function playdate.scoreboards.getScores(boardID, callback)
        local result = {
            lastUpdated = scoreboards.lastUpdated,
            scores = {}
        }
        for board_index = 1, #scoreboards.boards do
            if scoreboards.boards[board_index].boardID == boardID then
                local board = scoreboards.boards[board_index]
                local found = false
                for score_index = 1, #board.scores do
                    local score = board.scores[score_index]
                    -- Always insert to 10
                    if score_index <= 10 then
                        table.insert(result.scores, score)
                        -- If we found the player, we won't have to do any more checks
                        if score.player == scoreboards.player then
                            found = true
                        end
                    -- If we haven't found the player's score, find it
                    elseif not found and score.player == scoreboards.player then
                        table.insert(result.scores, score)
                        found = true
                    -- If both conditions are met, we can stop
                    elseif score_index > 10 and found then
                        break
                    end
                end

                break
            end
        end
        _callback(callback, result)
    end

    function playdate.scoreboards.addScore(boardID, value, callback)
        local result = {
            player = scoreboards.player,
            value = value,
            rank = 1
        }
        for board_index = 1, #scoreboards.boards do
            if scoreboards.boards[board_index].boardID == boardID then
                local board = scoreboards.boards[board_index]
                local order = board.order or "descending"
                for index, score in ipairs(board.scores) do
                    if order == "descending" then
                        result.rank = index
                        if value > score.value then
                            break
                        end
                        -- Check if we should be after the last entry
                        if board.scores[#board.scores].value >= value then
                            result.rank = index + 1
                        end
                    elseif order == "ascending" then
                        result.rank = index
                        if value < score.value then
                            break
                        end
                        -- Check if we should be after the last entry
                        if board.scores[#board.scores].value <= value then
                            result.rank = index + 1
                        end
                    end
                end

                table.insert(board.scores, result.rank, {
                    player = scoreboards.player,
                    value = value,
                    rank = result.rank or 1
                })
                _update_ranks(boardID)
                _save()
                break
            end
        end
        _save()
        _callback(callback, result)
    end

    function playdate.scoreboards.getPersonalBest(boardID, callback)
        local result = nil
        for board_index = 1, #scoreboards.boards do
            if scoreboards.boards[board_index].boardID == boardID then
                local board = scoreboards.boards[board_index]
                for index = 1, #board.scores do
                    if board.scores[index].player == scoreboards.player then
                        result = board.scores[index]
                        break
                    end
                end
            end
            if result ~= nil then
                break
            end
        end
        _callback(callback, result)
    end
end

function playdate.scoreboards.initialize(boards, callback, path)
    -- Check panic's servers for a leaderboard, if none then initialize locally
    -- Defaults save location to Data/scoreboards.json
    -- playdate.scoreboards.initialize({
    --     { boardID = "highscores", name = "High Scores" },
    --     { boardID = "lowscores", name = "Low Scores", order="ascending" }
    -- })
    playdate._scoreboards = playdate.scoreboards  -- Store a backup of the functions
    scoreboards_file = path or "scoreboards"  -- Default to Data/scoreboards.json
    scoreboards = playdate.datastore.read(scoreboards_file)

    -- If we've already detected that we aren't authorized, then don't check again
    if scoreboards ~= nil and scoreboards.not_authorized then
        _init_scoreboards(boards)
        callback({ code = "ERROR", message = "Local scoreboards already initialized" }, nil)
        return
    end

    playdate.scoreboards.getScoreboards(function(status, _)
        if status.code == "OK" then
            callback(status, nil)
            return
        end

        if status.message == "Wi-Fi not available" then
            -- You must initialize the scoreboards with an internet connection before they can be used
            if scoreboards == nil or scoreboards.not_authorized == nil or scoreboards.not_authorized then
                _init_scoreboards(boards)
            end
        else
            -- Generic error, e.g. "A game with the provided bundle_id .* does not exist", "Bad response from server" etc.
            print(status.message)
            _init_scoreboards(boards)
        end
        callback(status, nil)
    end)
end
