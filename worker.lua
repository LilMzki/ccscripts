print("Hello. Enter position x value of this turtle.")

xPos = tonumber(read())

rednet.open("right")
local id = rednet.lookup("Turtle3DPrinter", "Master")

if id then
    rednet.send(id, string.format("first %s", xPos));
    local _, rawMsg = rednet.receive()
    print(rawMsg);
    print("please enter 'yes' if inventory setup done")
    input = read()
    if(input == "yes") then
        rednet.send(id, "second")
        print("wait for every turtle to have done setting up")
        local _, rawCommands = rednet.receive()
        print(rawCommands)
        for i=1,#rawCommands do
            local firstChar = string.sub(rawCommands, i, i)
            if firstChar == "f" then
                turtle.forward()
            elseif firstChar == "t" then
                turtle.turnRight()
                turtle.turnRight()
            elseif firstChar == "u" then
                turtle.up()
            elseif firstChar == "p" then
                turtle.placeDown()
            elseif firstChar == "s" then
                local thirdChar = string.sub(rawCommands, i+2, i+2)
                local slotId = 0
                if tonumber(thirdChar) then
                    slotId = tonumber(string.sub(rawCommands, i+1, i+2))
                else
                    slotId = tonumber(string.sub(rawCommands, i+1, i+1))
                end
                --turtle.sleep(0.1)
                print(string.format("slotId: %s"), slotId)
                turtle.select(slotId)
            end
        end
        print("done")
    end
end
