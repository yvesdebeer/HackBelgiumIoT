-- Executed everytime it restarts or power on
--
tmr.alarm(0, 2000, 0, function()
    dofile('mainIoTF.lua')
end)
