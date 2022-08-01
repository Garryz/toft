local cell = require "cell"
local gameAgent = require "gameAgent"

function cell.main()
    gameAgent.init()

    cell.command(gameAgent)
    cell.message(gameAgent)
end
