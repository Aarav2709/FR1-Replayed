-- loading spinner.

local loadingAnimation = {}

function loadingAnimation.newLoadingAnimation()
  local loader = { displayGroup = display.newGroup() }
  loader.displayGroup.isVisible = false
  loader.loadingAnimation = display.newImageRect("images/gui/loading/loader.png", 40, 40)
  loader.displayGroup:insert(loader.loadingAnimation)
  loader.displayGroup.x = display.contentWidth * 0.5
  loader.displayGroup.y = display.contentHeight * 0.5

  local function spin()
    if loader.loadingAnimation then
      loader.loadingAnimation:rotate(45)
    end
  end

  function loader.startLoader()
    loader.displayGroup.isVisible = true
    if loader.rotateTimer then
      timer.cancel(loader.rotateTimer)
      loader.rotateTimer = nil
    end
    loader.rotateTimer = timer.performWithDelay(100, spin, 0)
  end

  function loader.stopLoader()
    if loader.rotateTimer then
      loader.displayGroup.isVisible = false
      timer.cancel(loader.rotateTimer)
      loader.rotateTimer = nil
    end
  end

  return loader
end

return loadingAnimation
