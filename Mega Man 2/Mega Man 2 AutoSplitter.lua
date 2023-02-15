local socket = require('socket.core')
local tcp = socket.tcp()
tcp:settimeout(1)
tcp:connect("localhost", 16834)

local previous = {}
local current = {}
local wait_teleport_out = false

local address = {
    screen = 0x440,
    sound = 0x580,
    y = 0x4A0,
    boss_hp = 0x6C1,
    stage = 0x2A
}
local start_screen_sound = 13
local teleport_sound = 58
local victory_sound = 21
local game_start_sound = 255
local refight_stage = 12
local alien_stage = 13


local function reset()
    tcp:send("reset\r\n")
    for k, v in pairs(address) do
        previous[k] = emu.read(v, emu.memType.cpu)
        current[k] = previous[k]
    end
    wait_teleport_out = false
end


local function start_trigger()
    if current.sound == game_start_sound and previous.sound ~= start_screen_sound and emu.isKeyPressed("Start") then
        tcp:send("starttimer\r\n")
        return true
    end
    return false
end


local function split_trigger()
    if current.stage == alien_stage and current.boss_hp == 0 and previous.boss_hp > 0 then
        tcp:send("split\r\n")
        return true
    end
    if current.stage == refight_stage and current.boss_hp == 0 and current.y >= 224 and previous.y < 224 then
        tcp:send("split\r\n")
        return true
    end
    if wait_teleport_out and current.sound == teleport_sound and previous.y >= 8 and current.y < 8 then
        tcp:send("split\r\n")
        wait_teleport_out = false
        return true
    end
    if not wait_teleport_out and current.sound == victory_sound then
        wait_teleport_out = true
    end
    return false
end


local triggers = {start_trigger, split_trigger}


local function run()
    for k, v in pairs(address) do
        current[k] = emu.read(v, emu.memType.cpu)
    end
    for i = 1, #triggers do
        triggers[i]()
    end
    for k, _ in pairs(current) do
        previous[k] = current[k]
    end
end


reset()
emu.addEventCallback(run, emu.eventType.startFrame)
emu.addEventCallback(reset, emu.eventType.reset)
