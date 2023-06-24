local scoreboards_file, scoreboards = nil, nil

local function _save()
    playdate.datastore.write(scoreboards, scoreboards_file)
end
local function _callback(callback, result, ok)
    if ok == nil then
        -- Default to true
        callback({ code = "OK", message = "OK" }, result)
    else
        callback({ code = "ERROR", message = "Something went wrong" }, result)
    end
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
        for index = 1, #scoreboards.boards do
            if scoreboards.boards[index].boardID == boardID then
                result.scores = scoreboards.boards[index].scores
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

    playdate.scoreboards.getScoreboards(function(status, _)
        if status.code == "OK" then
            callback(status, nil)
            return
        end

        playdate._scoreboards = playdate.scoreboards  -- Store a backup of the functions
        scoreboards_file = path or "scoreboards"  -- Default to Data/scoreboards.json
        scoreboards = playdate.datastore.read(scoreboards_file)

        if status.message == "Authentication credentials were not provided." then
            -- If we can't authenticate, then use local because device isn't registered
            print("Cannot authenticate with Panic's servers, is your device registered?")
            _init_scoreboards(boards)
        elseif status.message:match("A game with the provided bundle_id .* does not exist") then
            _init_scoreboards(boards)
        elseif status.message == "Wi-Fi not available" then
            -- You must initialize the scoreboards with an internet connection before they can be used
            if scoreboards == nil or scoreboards.not_authorized == nil or scoreboards.not_authorized then
                _init_scoreboards(boards)
            end
        end
        callback(status, nil)
    end)
end
