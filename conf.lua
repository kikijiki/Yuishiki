function love.conf(t)
    t.identity = nil
    t.version = "0.9.0"
    t.console = true

    t.window.title = "Testbed"
    t.window.icon = nil
    t.window.width = 1200
    t.window.height = 600
    t.window.borderless = false
    t.window.resizable = true
    t.window.minwidth = 1
    t.window.minheight = 1
    t.window.fullscreen = false
    t.window.fullscreentype = "normal"
    t.window.vsync = true
    t.window.fsaa = 0
    t.window.display = 1

    t.modules.audio = false
    t.modules.event = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = false
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = true
    t.modules.sound = false
    t.modules.system = true
    t.modules.timer = true
    t.modules.window = true
end
