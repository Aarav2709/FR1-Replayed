-- game configuration.

local storyboard = require("modules.storyboard")

storyboard.config = {
  version = "2.24",
  fullVersion = "2.24.1",

  serverVersion = 36,

  newItems = { version = 19, items = { 137, 241 } },

  tutorial = false,

  freeCoinPacks = true,

}

return storyboard.config
