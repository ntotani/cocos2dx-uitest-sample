
cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")

require "config"
require "cocos.init"

local TestApp = class("TestApp", cc.load("mvc").AppBase)

function TestApp:onCreate()
    local counter = 0
    math.random = function(a, b)
        counter = counter + 13
        return a + counter % (b - a)
    end
end

local function main()
    TestApp:create():run()
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
