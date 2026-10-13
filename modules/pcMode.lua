-- true on the windows build, or in the simulator when started with PCMode.bat.

local M = {}

M.isPC = (system.getInfo("platform") == "win32" and system.getInfo("environment") ~= "simulator")
  or os.getenv("FR1_PC_UI") == "1"

M.isDesktop = system.getInfo("platform") == "win32" or system.getInfo("platform") == "macos"
  or system.getInfo("environment") == "simulator"

return M
