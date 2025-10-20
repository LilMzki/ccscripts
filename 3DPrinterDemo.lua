function main()
    print("input depth")
    local depth = read()
    print("input height")
    local height = read()

    local instruction = ""
    for i=1,height do
        for j=1,depth do
            if math.random() < 0.5 then
                instruction = instruction + "0"
            else
                instruction = instruction + "1"
            end
        end
    end

    local z = 1
    for i=1, #instruction do
        if instruction:sub(i, i) == "1" then
            turtle.placeDown()
        end
        z = z + 1
        turtle.forward()
        if z == depth then
            turtle.up()
            turtle.turnRight()
            turtle.turnRight()
            z = 1
        end
    end
end

main()
