local cell = require "cell"
local gameAgent = require "gameAgent"

function cell.main()
    cell.command(gameAgent)
    cell.message(gameAgent)
end
