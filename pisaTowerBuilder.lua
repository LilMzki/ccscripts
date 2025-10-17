--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__Class(self)
    local c = {prototype = {}}
    c.prototype.__index = c.prototype
    c.prototype.constructor = c
    return c
end

local function __TS__New(target, ...)
    local instance = setmetatable({}, target.prototype)
    instance:____constructor(...)
    return instance
end

local function __TS__ArrayFilter(self, callbackfn, thisArg)
    local result = {}
    local len = 0
    for i = 1, #self do
        if callbackfn(thisArg, self[i], i - 1, self) then
            len = len + 1
            result[len] = self[i]
        end
    end
    return result
end

local function __TS__CountVarargs(...)
    return select("#", ...)
end

local function __TS__SparseArrayNew(...)
    local sparseArray = {...}
    sparseArray.sparseLength = __TS__CountVarargs(...)
    return sparseArray
end

local function __TS__SparseArrayPush(sparseArray, ...)
    local args = {...}
    local argsLen = __TS__CountVarargs(...)
    local listLen = sparseArray.sparseLength
    for i = 1, argsLen do
        sparseArray[listLen + i] = args[i]
    end
    sparseArray.sparseLength = listLen + argsLen
end

local function __TS__SparseArraySpread(sparseArray)
    local _unpack = unpack or table.unpack
    return _unpack(sparseArray, 1, sparseArray.sparseLength)
end

local function __TS__ArrayForEach(self, callbackFn, thisArg)
    for i = 1, #self do
        callbackFn(thisArg, self[i], i - 1, self)
    end
end
-- End of Lua Library inline imports
Vector2 = __TS__Class()
Vector2.name = "Vector2"
function Vector2.prototype.____constructor(self)
    self.x = 0
    self.z = 0
end
function Vector2.prototype.set(self, x, z)
    self.x = x
    self.z = z
    return self
end
Vector3 = __TS__Class()
Vector3.name = "Vector3"
function Vector3.prototype.____constructor(self, x, y, z)
    self.x = 0
    self.y = 0
    self.z = 0
    self.x = x or 0
    self.y = y or 0
    self.z = z or 0
end
function Vector3.prototype.distanceFrom(self, p)
    local dx = self.x - p.x
    local dy = self.y - p.y
    local dz = self.z - p.z
    return math.sqrt(dx ^ 2 + dy ^ 2 + dz ^ 2)
end
CircleMaker = __TS__Class()
CircleMaker.name = "CircleMaker"
function CircleMaker.prototype.____constructor(self)
end
function CircleMaker.prototype.execute(self, radius)
    self.angle = 0
    self.angleStep = 1 / radius
    self.points = {}
    while self.angle < math.pi / 4 do
        self:addCurrentPositions(radius)
        self.angle = self.angle + self.angleStep
    end
    return self.points
end
function CircleMaker.prototype.addCurrentPositions(self, r)
    local p = __TS__New(Vector2)
    p.x = math.floor(r * math.cos(self.angle) + 0.5)
    p.z = math.floor(r * math.sin(self.angle) + 0.5)
    local ____self_points_0 = self.points
    ____self_points_0[#____self_points_0 + 1] = p
    self:addMirroredPositions(p)
end
function CircleMaker.prototype.addMirroredPositions(self, p)
    local pl = self.points
    pl[#pl + 1] = __TS__New(Vector2):set(-p.x, p.z)
    pl[#pl + 1] = __TS__New(Vector2):set(p.x, -p.z)
    pl[#pl + 1] = __TS__New(Vector2):set(-p.x, -p.z)
    pl[#pl + 1] = __TS__New(Vector2):set(p.z, p.x)
    pl[#pl + 1] = __TS__New(Vector2):set(p.z, -p.x)
    pl[#pl + 1] = __TS__New(Vector2):set(-p.z, p.x)
    pl[#pl + 1] = __TS__New(Vector2):set(-p.z, -p.x)
end
GappedCircleMaker = __TS__Class()
GappedCircleMaker.name = "GappedCircleMaker"
function GappedCircleMaker.prototype.____constructor(self)
end
function GappedCircleMaker.prototype.execute(self, radius)
    self.angle = 0
    self.angleStep = 1 / radius
    self.points = {}
    self.count = 0
    while self.angle < 2 * math.pi do
        if self.count % 4 == 0 or self.count % 4 == 1 then
            self:addCurrentPos(radius)
        end
        self.angle = self.angle + self.angleStep
        self.count = self.count + 1
    end
    return self.points
end
function GappedCircleMaker.prototype.addCurrentPos(self, r)
    local p = __TS__New(Vector2)
    p.x = math.floor(r * math.cos(self.angle) + 0.5)
    p.z = math.floor(r * math.sin(self.angle) + 0.5)
    local ____self_points_1 = self.points
    ____self_points_1[#____self_points_1 + 1] = p
end
InnerTowerMaker = __TS__Class()
InnerTowerMaker.name = "InnerTowerMaker"
function InnerTowerMaker.prototype.____constructor(self)
    self.radius = 15
end
function InnerTowerMaker.prototype.execute(self, y)
    self.circleMaker = __TS__New(CircleMaker)
    self.points = {}
    local circlePoints = self.circleMaker:execute(self.radius)
    local offset = self:getOffsetFrom(y)
    for ____, cp in ipairs(circlePoints) do
        local p = __TS__New(Vector3)
        p.x = cp.x + offset
        p.y = y
        p.z = cp.z
        local ____self_points_2 = self.points
        ____self_points_2[#____self_points_2 + 1] = p
    end
    return self.points
end
function InnerTowerMaker.prototype.getOffsetFrom(self, y)
    return math.floor(y / 14)
end
OuterTowerMaker = __TS__Class()
OuterTowerMaker.name = "OuterTowerMaker"
function OuterTowerMaker.prototype.____constructor(self)
    self.radius = 19
end
function OuterTowerMaker.prototype.execute(self, y)
    self.circleMaker = __TS__New(CircleMaker)
    self.gappedCircleMaker = __TS__New(GappedCircleMaker)
    self.points = {}
    local fixedY = y % 14
    local vec2Points = {}
    if fixedY < 2 then
        vec2Points = self.circleMaker:execute(self.radius)
    else
        vec2Points = self.gappedCircleMaker:execute(self.radius)
    end
    local offset = self:getOffsetFrom(y)
    for ____, point in ipairs(vec2Points) do
        local p = __TS__New(Vector3)
        p.x = point.x + offset
        p.y = y
        p.z = point.z
        local ____self_points_3 = self.points
        ____self_points_3[#____self_points_3 + 1] = p
    end
    return self.points
end
function OuterTowerMaker.prototype.getOffsetFrom(self, y)
    return math.floor(y / 14)
end
LayerMap = __TS__Class()
LayerMap.name = "LayerMap"
function LayerMap.prototype.____constructor(self, points)
    self.points = points
end
function LayerMap.prototype.findNearestPointFrom(self, p)
    local minDistance = 1000
    local candidate = __TS__New(Vector3)
    for ____, point in ipairs(self.points) do
        local d = point:distanceFrom(p)
        if d < minDistance then
            candidate = point
            minDistance = d
        end
    end
    return candidate
end
function LayerMap.prototype.visited(self, point)
    local b = point
    self.points = __TS__ArrayFilter(
        self.points,
        function(____, a) return not (a.x == b.x and a.y == b.y and a.z == b.z) end
    )
end
LayerMapMaker = __TS__Class()
LayerMapMaker.name = "LayerMapMaker"
function LayerMapMaker.prototype.____constructor(self)
    self.height = 0
end
function LayerMapMaker.prototype.init(self)
    self.height = 0
    self.innerMaker = __TS__New(InnerTowerMaker)
    self.outerMaker = __TS__New(OuterTowerMaker)
end
function LayerMapMaker.prototype.setHeight(self, value)
    self.height = value
end
function LayerMapMaker.prototype.incHeight(self)
    self.height = self.height + 1
end
function LayerMapMaker.prototype.get(self)
    local innerPoints = self.innerMaker:execute(self.height)
    local outerPoints = self.outerMaker:execute(self.height)
    local ____array_4 = __TS__SparseArrayNew(table.unpack(innerPoints))
    __TS__SparseArrayPush(
        ____array_4,
        table.unpack(outerPoints)
    )
    local merged = {__TS__SparseArraySpread(____array_4)}
    return __TS__New(LayerMap, merged)
end
Direction = Direction or ({})
Direction.PlusZ = 0
Direction[Direction.PlusZ] = "PlusZ"
Direction.PlusX = 1
Direction[Direction.PlusX] = "PlusX"
Direction.MinusZ = 2
Direction[Direction.MinusZ] = "MinusZ"
Direction.MinusX = 3
Direction[Direction.MinusX] = "MinusX"
TurtleStateTransform = __TS__Class()
TurtleStateTransform.name = "TurtleStateTransform"
function TurtleStateTransform.prototype.____constructor(self)
    self.pos = __TS__New(Vector3)
    self.rot = Direction.PlusZ
end
function TurtleStateTransform.prototype.getPosition(self)
    return __TS__New(Vector3, self.pos.x, self.pos.y, self.pos.z)
end
function TurtleStateTransform.prototype.getRotation(self)
    return self.rot
end
function TurtleStateTransform.prototype.forward(self)
    repeat
        local ____switch44 = self.rot
        local ____cond44 = ____switch44 == Direction.PlusZ
        if ____cond44 then
            local ____self_pos_5, ____z_6 = self.pos, "z"
            ____self_pos_5[____z_6] = ____self_pos_5[____z_6] + 1
            break
        end
        ____cond44 = ____cond44 or ____switch44 == Direction.PlusX
        if ____cond44 then
            local ____self_pos_7, ____x_8 = self.pos, "x"
            ____self_pos_7[____x_8] = ____self_pos_7[____x_8] + 1
            break
        end
        ____cond44 = ____cond44 or ____switch44 == Direction.MinusX
        if ____cond44 then
            local ____self_pos_9, ____x_10 = self.pos, "x"
            ____self_pos_9[____x_10] = ____self_pos_9[____x_10] - 1
            break
        end
        ____cond44 = ____cond44 or ____switch44 == Direction.MinusZ
        if ____cond44 then
            local ____self_pos_11, ____z_12 = self.pos, "z"
            ____self_pos_11[____z_12] = ____self_pos_11[____z_12] - 1
            break
        end
    until true
end
function TurtleStateTransform.prototype.back(self)
    repeat
        local ____switch46 = self.rot
        local ____cond46 = ____switch46 == Direction.PlusZ
        if ____cond46 then
            local ____self_pos_13, ____z_14 = self.pos, "z"
            ____self_pos_13[____z_14] = ____self_pos_13[____z_14] - 1
            break
        end
        ____cond46 = ____cond46 or ____switch46 == Direction.PlusX
        if ____cond46 then
            local ____self_pos_15, ____x_16 = self.pos, "x"
            ____self_pos_15[____x_16] = ____self_pos_15[____x_16] - 1
            break
        end
        ____cond46 = ____cond46 or ____switch46 == Direction.MinusX
        if ____cond46 then
            local ____self_pos_17, ____x_18 = self.pos, "x"
            ____self_pos_17[____x_18] = ____self_pos_17[____x_18] + 1
            break
        end
        ____cond46 = ____cond46 or ____switch46 == Direction.MinusZ
        if ____cond46 then
            local ____self_pos_19, ____z_20 = self.pos, "z"
            ____self_pos_19[____z_20] = ____self_pos_19[____z_20] + 1
            break
        end
    until true
end
function TurtleStateTransform.prototype.turnRight(self)
    self.rot = (self.rot + 1) % 4
end
function TurtleStateTransform.prototype.turnLeft(self)
    self.rot = (self.rot + 3) % 4
end
function TurtleStateTransform.prototype.up(self)
    local ____self_pos_21, ____y_22 = self.pos, "y"
    ____self_pos_21[____y_22] = ____self_pos_21[____y_22] + 1
end
function TurtleStateTransform.prototype.down(self)
    local ____self_pos_23, ____y_24 = self.pos, "y"
    ____self_pos_23[____y_24] = ____self_pos_23[____y_24] - 1
end
Slot = __TS__Class()
Slot.name = "Slot"
function Slot.prototype.____constructor(self, itemId, amount)
    if itemId == nil then
        itemId = "empty"
    end
    if amount == nil then
        amount = 0
    end
    self.itemId = itemId
    self.amount = amount
end
ResourceMap = __TS__Class()
ResourceMap.name = "ResourceMap"
function ResourceMap.prototype.____constructor(self)
    self.content = {
        ["minecraft:end_stone"] = __TS__New(Vector3, -2, -1, 2),
        ["minecraft:iron_block"] = __TS__New(Vector3, 0, -1, 2),
        ["minecraft:quartz_block"] = __TS__New(Vector3, 2, -1, 2),
        ["minecraft:andesite"] = __TS__New(Vector3, -2, -1, 0),
        ["mekanism:tin_block"] = __TS__New(Vector3, 2, -1, 0),
        ["mekanism:fluorite_block"] = __TS__New(Vector3, -2, -1, -2),
        ["minecraft:coal"] = __TS__New(Vector3, 0, -1, -2)
    }
end
TurtleRefuelManager = __TS__Class()
TurtleRefuelManager.name = "TurtleRefuelManager"
function TurtleRefuelManager.prototype.____constructor(self, moveManager, turtle, transform)
    self.moveManager = moveManager
    self.turtle = turtle
    self.transform = transform
    self.threshold = 500
    self.executing = false
    self.resourceMap = __TS__New(ResourceMap)
end
function TurtleRefuelManager.prototype.executeIfNecessary(self)
    if self.executing then
        return
    end
    local remain = self.turtle:getFuelLevel()
    if remain < self.threshold then
        self.executing = true
        local cur = self.transform:getPosition()
        local savedPos = __TS__New(Vector3, cur.x, cur.y, cur.z)
        self.moveManager:goTo(self:getDestination())
        self.turtle:setSlotIndex(15)
        self.turtle:suck()
        self.turtle:refuel()
        self.turtle:up()
        local currentPos = self.transform:getPosition()
        self.moveManager:goTo(__TS__New(Vector3, currentPos.x, currentPos.y + 1, currentPos.z))
        self.moveManager:goTo(savedPos)
        self.executing = false
    end
end
function TurtleRefuelManager.prototype.getDestination(self)
    local coalChestPos = self.resourceMap.content["minecraft:coal"]
    local destination = __TS__New(Vector3, coalChestPos.x, coalChestPos.y, coalChestPos.z - 1)
    return destination
end
TurtleReplenishManager = __TS__Class()
TurtleReplenishManager.name = "TurtleReplenishManager"
function TurtleReplenishManager.prototype.____constructor(self, turtle, moveManager, transform)
    self.turtle = turtle
    self.moveManager = moveManager
    self.transform = transform
    self.resourceMap = __TS__New(ResourceMap)
    self.isExecuting = false
end
function TurtleReplenishManager.prototype.executeIfNecessary(self)
    if self.isExecuting then
        return
    end
    local necessaryIndexes = self:searchNecessaryIndexes()
    if #necessaryIndexes == 0 then
        return
    end
    self.isExecuting = true
    local cur = self.transform:getPosition()
    local savedPos = __TS__New(Vector3, cur.x, cur.y, cur.z)
    for ____, index in ipairs(necessaryIndexes) do
        local id = self:itemIdShouldBeIn(index)
        local destination = self.resourceMap.content[id]
        self.moveManager:goTo(__TS__New(Vector3, destination.x, destination.y, destination.z - 1))
        self.turtle:setSlotIndex(index + 1)
        self.turtle:suck()
        local currentPos = self.transform:getPosition()
        self.moveManager:goTo(__TS__New(Vector3, currentPos.x, currentPos.y + 1, currentPos.z))
    end
    self.moveManager:goTo(savedPos)
    self.isExecuting = false
end
function TurtleReplenishManager.prototype.searchNecessaryIndexes(self)
    local result = {}
    do
        local i = 0
        while i < 12 do
            self.turtle:setSlotIndex(i + 1)
            local slot = self.turtle:getSlot()
            if slot.amount <= 16 then
                result[#result + 1] = i
            end
            i = i + 1
        end
    end
    return result
end
function TurtleReplenishManager.prototype.itemIdShouldBeIn(self, slotIndex)
    if slotIndex == 0 or slotIndex == 1 then
        return "minecraft:end_stone"
    elseif slotIndex == 2 or slotIndex == 3 then
        return "minecraft:iron_block"
    elseif slotIndex == 4 or slotIndex == 5 then
        return "minecraft:quartz_block"
    elseif slotIndex == 6 or slotIndex == 7 then
        return "minecraft:andesite"
    elseif slotIndex == 8 or slotIndex == 9 then
        return "mekanism:tin_block"
    elseif slotIndex == 10 or slotIndex == 11 then
        return "mekanism:fluorite_block"
    end
    return ""
end
TurtleMoveManager = __TS__Class()
TurtleMoveManager.name = "TurtleMoveManager"
function TurtleMoveManager.prototype.____constructor(self, turtle, state, resourceManagers)
    self.turtle = turtle
    self.state = state
    self.resourceManagers = resourceManagers
end
function TurtleMoveManager.prototype.goTo(self, destination)
    __TS__ArrayForEach(
        self.resourceManagers,
        function(____, r) return r:executeIfNecessary() end
    )
    local start = self.state:getPosition()
    local ____end = destination
    local dx = ____end.x - start.x
    local dy = ____end.y - start.y
    local dz = ____end.z - start.z
    self:lookPlusZ()
    if dz < 0 then
        local count = math.abs(dz)
        self:repeatBack(count)
    elseif dz > 0 then
        self:repeatForward(dz)
    end
    self:turnRight()
    if dx < 0 then
        local count = math.abs(dx)
        self:repeatBack(count)
    elseif dx > 0 then
        self:repeatForward(dx)
    end
    if dy < 0 then
        local count = math.abs(dy)
        self:repeatDown(count)
    elseif dy > 0 then
        self:repeatUp(dy)
    end
    self:lookPlusZ()
end
function TurtleMoveManager.prototype.lookPlusZ(self)
    local rot = self.state:getRotation()
    do
        local i = 0
        while i < rot do
            self:turnLeft()
            i = i + 1
        end
    end
end
function TurtleMoveManager.prototype.turnLeft(self)
    self.state:turnLeft()
    self.turtle:turnLeft()
end
function TurtleMoveManager.prototype.turnRight(self)
    self.state:turnRight()
    self.turtle:turnRight()
end
function TurtleMoveManager.prototype.repeatForward(self, count)
    do
        local i = 0
        while i < count do
            self.state:forward()
            self.turtle:forward()
            i = i + 1
        end
    end
end
function TurtleMoveManager.prototype.repeatBack(self, count)
    do
        local i = 0
        while i < count do
            self.state:back()
            self.turtle:back()
            i = i + 1
        end
    end
end
function TurtleMoveManager.prototype.repeatUp(self, count)
    do
        local i = 0
        while i < count do
            self.state:up()
            self.turtle:up()
            i = i + 1
        end
    end
end
function TurtleMoveManager.prototype.repeatDown(self, count)
    do
        local i = 0
        while i < count do
            self.state:down()
            self.turtle:down()
            i = i + 1
        end
    end
end
TurtlePlaceBlockManager = __TS__Class()
TurtlePlaceBlockManager.name = "TurtlePlaceBlockManager"
function TurtlePlaceBlockManager.prototype.____constructor(self, turtle)
    self.turtle = turtle
end
function TurtlePlaceBlockManager.prototype.execute(self)
    local slotIndex = math.floor(12 * math.random()) + 1
    self.turtle:setSlotIndex(slotIndex)
    self.turtle:placeDown()
end
TurtleWrapper = __TS__Class()
TurtleWrapper.name = "TurtleWrapper"
function TurtleWrapper.prototype.____constructor(self, turtle)
    self.turtle = turtle
end
function TurtleWrapper.prototype.forward(self)
    self.turtle.forward()
end
function TurtleWrapper.prototype.back(self)
    self.turtle.back()
end
function TurtleWrapper.prototype.turnLeft(self)
    self.turtle.turnLeft()
end
function TurtleWrapper.prototype.turnRight(self)
    self.turtle.turnRight()
end
function TurtleWrapper.prototype.up(self)
    self.turtle.up()
end
function TurtleWrapper.prototype.down(self)
    self.turtle.down()
end
function TurtleWrapper.prototype.placeDown(self)
    self.turtle.placeDown()
end
function TurtleWrapper.prototype.getFuelLevel(self)
    return self.turtle.getFuelLevel()
end
function TurtleWrapper.prototype.getSlot(self)
    local value = self.turtle.getItemDetail()
    if not value then
        return __TS__New(Slot, "empty", 0)
    end
    return __TS__New(Slot, value.name, value.count)
end
function TurtleWrapper.prototype.setSlotIndex(self, index)
    self.turtle.select(index)
end
function TurtleWrapper.prototype.suck(self)
    self.turtle.suck()
end
function TurtleWrapper.prototype.refuel(self)
    return self.turtle.refuel()
end
layerMapMaker = __TS__New(LayerMapMaker)
layerMapMaker:init()
local turtleAPI = turtle
local tw = __TS__New(TurtleWrapper, turtleAPI)
transform = __TS__New(TurtleStateTransform)
resourceManagers = {}
move = __TS__New(TurtleMoveManager, tw, transform, resourceManagers)
refuel = __TS__New(TurtleRefuelManager, move, tw, transform)
repl = __TS__New(TurtleReplenishManager, tw, move, transform)
place = __TS__New(TurtlePlaceBlockManager, tw)
resourceManagers[#resourceManagers + 1] = refuel
resourceManagers[#resourceManagers + 1] = repl
do
    local i = 0
    while i < 500 do
        local layer = layerMapMaker:get()
        while #layer.points > 0 do
            local target = layer:findNearestPointFrom(transform:getPosition())
            move:goTo(__TS__New(Vector3, target.x, target.y + 1, target.z))
            place:execute()
            layer:visited(target)
        end
        layerMapMaker:incHeight()
        i = i + 1
    end
end
