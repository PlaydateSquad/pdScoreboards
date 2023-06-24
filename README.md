# pdScoreboards

A wrapper to match the official `playdate.scoreboards` API: https://help.play.date/catalog-developer/scoreboard-api/

![Preview](preview.gif)

## Usage

Import and call `playdate.scoreboards.initialize`. This will check for official scoreboards, and if it cannot find any will create using the boards passed in.

```lua
import "pdScoreboards"

playdate.scoreboards.initialize(
    {
        {
            boardID = "highscores", 
            name = "High Scores" 
        },
        {
            boardID = "lowscores", 
            name = "Low Scores", 
            order="ascending" 
        }
    },
    function(status, _)
        if status.code = "OK" then
            print("You're using official scoreboards!")
        else
            print("You're not using official scoreboards, but that's okay!")
        end
    end
)
```

> NOTE: Scoreboards must be first created with an internet connection.

## API

#### `playdate.scoreboards.initialize(boards, callback, path)`

Checks Panic's servers for any authorized scoreboards. If it fails, it will create local boards using the boards passed in. It will skip the server check if it's already tried, failed, and created local scoreboards.

* `boards` is an array of the format `{ boardID = [id], name = [name], order  ["ascending"/"descending"] }` (order is optional, defaults to descending)
* `callback` is a function with the arguments `status`, the response from panic's servers, and `result`, `nil`
* `path` is the path to the scoreboards file, defaults to `Data/scoreboards.json` (omit `.json` in the path)

#### `playdate.scoreboards.setPlayer(username)`

Sets the username for the scoreboards. Official scoreboards use the registered device's account, but custom scoreboards require a username.

> The rest of the functions can be found in [Panic's official Scoreboard API documentation](https://help.play.date/catalog-developer/scoreboard-api/)
