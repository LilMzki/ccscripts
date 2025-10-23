--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__Class(self)
    local c = {prototype = {}}
    c.prototype.__index = c.prototype
    c.prototype.constructor = c
    return c
end

local __TS__Symbol, Symbol
do
    local symbolMetatable = {__tostring = function(self)
        return ("Symbol(" .. (self.description or "")) .. ")"
    end}
    function __TS__Symbol(description)
        return setmetatable({description = description}, symbolMetatable)
    end
    Symbol = {
        asyncDispose = __TS__Symbol("Symbol.asyncDispose"),
        dispose = __TS__Symbol("Symbol.dispose"),
        iterator = __TS__Symbol("Symbol.iterator"),
        hasInstance = __TS__Symbol("Symbol.hasInstance"),
        species = __TS__Symbol("Symbol.species"),
        toStringTag = __TS__Symbol("Symbol.toStringTag")
    }
end

local __TS__Iterator
do
    local function iteratorGeneratorStep(self)
        local co = self.____coroutine
        local status, value = coroutine.resume(co)
        if not status then
            error(value, 0)
        end
        if coroutine.status(co) == "dead" then
            return
        end
        return true, value
    end
    local function iteratorIteratorStep(self)
        local result = self:next()
        if result.done then
            return
        end
        return true, result.value
    end
    local function iteratorStringStep(self, index)
        index = index + 1
        if index > #self then
            return
        end
        return index, string.sub(self, index, index)
    end
    function __TS__Iterator(iterable)
        if type(iterable) == "string" then
            return iteratorStringStep, iterable, 0
        elseif iterable.____coroutine ~= nil then
            return iteratorGeneratorStep, iterable
        elseif iterable[Symbol.iterator] then
            local iterator = iterable[Symbol.iterator](iterable)
            return iteratorIteratorStep, iterator
        else
            return ipairs(iterable)
        end
    end
end

local __TS__ArrayFrom
do
    local function arrayLikeStep(self, index)
        index = index + 1
        if index > self.length then
            return
        end
        return index, self[index]
    end
    local function arrayLikeIterator(arr)
        if type(arr.length) == "number" then
            return arrayLikeStep, arr, 0
        end
        return __TS__Iterator(arr)
    end
    function __TS__ArrayFrom(arrayLike, mapFn, thisArg)
        local result = {}
        if mapFn == nil then
            for ____, v in arrayLikeIterator(arrayLike) do
                result[#result + 1] = v
            end
        else
            local i = 0
            for ____, v in arrayLikeIterator(arrayLike) do
                local ____mapFn_3 = mapFn
                local ____thisArg_1 = thisArg
                local ____v_2 = v
                local ____i_0 = i
                i = ____i_0 + 1
                result[#result + 1] = ____mapFn_3(____thisArg_1, ____v_2, ____i_0)
            end
        end
        return result
    end
end

local function __TS__New(target, ...)
    local instance = setmetatable({}, target.prototype)
    instance:____constructor(...)
    return instance
end

local function __TS__CloneDescriptor(____bindingPattern0)
    local value
    local writable
    local set
    local get
    local configurable
    local enumerable
    enumerable = ____bindingPattern0.enumerable
    configurable = ____bindingPattern0.configurable
    get = ____bindingPattern0.get
    set = ____bindingPattern0.set
    writable = ____bindingPattern0.writable
    value = ____bindingPattern0.value
    local descriptor = {enumerable = enumerable == true, configurable = configurable == true}
    local hasGetterOrSetter = get ~= nil or set ~= nil
    local hasValueOrWritableAttribute = writable ~= nil or value ~= nil
    if hasGetterOrSetter and hasValueOrWritableAttribute then
        error("Invalid property descriptor. Cannot both specify accessors and a value or writable attribute.", 0)
    end
    if get or set then
        descriptor.get = get
        descriptor.set = set
    else
        descriptor.value = value
        descriptor.writable = writable == true
    end
    return descriptor
end

local __TS__DescriptorGet
do
    local getmetatable = _G.getmetatable
    local ____rawget = _G.rawget
    function __TS__DescriptorGet(self, metatable, key)
        while metatable do
            local rawResult = ____rawget(metatable, key)
            if rawResult ~= nil then
                return rawResult
            end
            local descriptors = ____rawget(metatable, "_descriptors")
            if descriptors then
                local descriptor = descriptors[key]
                if descriptor ~= nil then
                    if descriptor.get then
                        return descriptor.get(self)
                    end
                    return descriptor.value
                end
            end
            metatable = getmetatable(metatable)
        end
    end
end

local __TS__DescriptorSet
do
    local getmetatable = _G.getmetatable
    local ____rawget = _G.rawget
    local rawset = _G.rawset
    function __TS__DescriptorSet(self, metatable, key, value)
        while metatable do
            local descriptors = ____rawget(metatable, "_descriptors")
            if descriptors then
                local descriptor = descriptors[key]
                if descriptor ~= nil then
                    if descriptor.set then
                        descriptor.set(self, value)
                    else
                        if descriptor.writable == false then
                            error(
                                ((("Cannot assign to read only property '" .. key) .. "' of object '") .. tostring(self)) .. "'",
                                0
                            )
                        end
                        descriptor.value = value
                    end
                    return
                end
            end
            metatable = getmetatable(metatable)
        end
        rawset(self, key, value)
    end
end

local __TS__SetDescriptor
do
    local getmetatable = _G.getmetatable
    local function descriptorIndex(self, key)
        return __TS__DescriptorGet(
            self,
            getmetatable(self),
            key
        )
    end
    local function descriptorNewIndex(self, key, value)
        return __TS__DescriptorSet(
            self,
            getmetatable(self),
            key,
            value
        )
    end
    function __TS__SetDescriptor(target, key, desc, isPrototype)
        if isPrototype == nil then
            isPrototype = false
        end
        local ____isPrototype_0
        if isPrototype then
            ____isPrototype_0 = target
        else
            ____isPrototype_0 = getmetatable(target)
        end
        local metatable = ____isPrototype_0
        if not metatable then
            metatable = {}
            setmetatable(target, metatable)
        end
        local value = rawget(target, key)
        if value ~= nil then
            rawset(target, key, nil)
        end
        if not rawget(metatable, "_descriptors") then
            metatable._descriptors = {}
        end
        metatable._descriptors[key] = __TS__CloneDescriptor(desc)
        metatable.__index = descriptorIndex
        metatable.__newindex = descriptorNewIndex
    end
end

local Map
do
    Map = __TS__Class()
    Map.name = "Map"
    function Map.prototype.____constructor(self, entries)
        self[Symbol.toStringTag] = "Map"
        self.items = {}
        self.size = 0
        self.nextKey = {}
        self.previousKey = {}
        if entries == nil then
            return
        end
        local iterable = entries
        if iterable[Symbol.iterator] then
            local iterator = iterable[Symbol.iterator](iterable)
            while true do
                local result = iterator:next()
                if result.done then
                    break
                end
                local value = result.value
                self:set(value[1], value[2])
            end
        else
            local array = entries
            for ____, kvp in ipairs(array) do
                self:set(kvp[1], kvp[2])
            end
        end
    end
    function Map.prototype.clear(self)
        self.items = {}
        self.nextKey = {}
        self.previousKey = {}
        self.firstKey = nil
        self.lastKey = nil
        self.size = 0
    end
    function Map.prototype.delete(self, key)
        local contains = self:has(key)
        if contains then
            self.size = self.size - 1
            local next = self.nextKey[key]
            local previous = self.previousKey[key]
            if next ~= nil and previous ~= nil then
                self.nextKey[previous] = next
                self.previousKey[next] = previous
            elseif next ~= nil then
                self.firstKey = next
                self.previousKey[next] = nil
            elseif previous ~= nil then
                self.lastKey = previous
                self.nextKey[previous] = nil
            else
                self.firstKey = nil
                self.lastKey = nil
            end
            self.nextKey[key] = nil
            self.previousKey[key] = nil
        end
        self.items[key] = nil
        return contains
    end
    function Map.prototype.forEach(self, callback)
        for ____, key in __TS__Iterator(self:keys()) do
            callback(nil, self.items[key], key, self)
        end
    end
    function Map.prototype.get(self, key)
        return self.items[key]
    end
    function Map.prototype.has(self, key)
        return self.nextKey[key] ~= nil or self.lastKey == key
    end
    function Map.prototype.set(self, key, value)
        local isNewValue = not self:has(key)
        if isNewValue then
            self.size = self.size + 1
        end
        self.items[key] = value
        if self.firstKey == nil then
            self.firstKey = key
            self.lastKey = key
        elseif isNewValue then
            self.nextKey[self.lastKey] = key
            self.previousKey[key] = self.lastKey
            self.lastKey = key
        end
        return self
    end
    Map.prototype[Symbol.iterator] = function(self)
        return self:entries()
    end
    function Map.prototype.entries(self)
        local items = self.items
        local nextKey = self.nextKey
        local key = self.firstKey
        return {
            [Symbol.iterator] = function(self)
                return self
            end,
            next = function(self)
                local result = {done = not key, value = {key, items[key]}}
                key = nextKey[key]
                return result
            end
        }
    end
    function Map.prototype.keys(self)
        local nextKey = self.nextKey
        local key = self.firstKey
        return {
            [Symbol.iterator] = function(self)
                return self
            end,
            next = function(self)
                local result = {done = not key, value = key}
                key = nextKey[key]
                return result
            end
        }
    end
    function Map.prototype.values(self)
        local items = self.items
        local nextKey = self.nextKey
        local key = self.firstKey
        return {
            [Symbol.iterator] = function(self)
                return self
            end,
            next = function(self)
                local result = {done = not key, value = items[key]}
                key = nextKey[key]
                return result
            end
        }
    end
    Map[Symbol.species] = Map
end

local function __TS__ArrayForEach(self, callbackFn, thisArg)
    for i = 1, #self do
        callbackFn(thisArg, self[i], i - 1, self)
    end
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
-- End of Lua Library inline imports
Vec3 = __TS__Class()
Vec3.name = "Vec3"
function Vec3.prototype.____constructor(self, x, y, z)
    self.x = x
    self.y = y
    self.z = z
end
Structure = __TS__Class()
Structure.name = "Structure"
function Structure.prototype.____constructor(self, scale)
    self.scale = scale
    self.content = __TS__ArrayFrom(
        {length = scale.x},
        function() return __TS__ArrayFrom(
            {length = scale.y},
            function() return __TS__ArrayFrom(
                {length = scale.z},
                function() return 0 end
            ) end
        ) end
    )
end
ItemStack = __TS__Class()
ItemStack.name = "ItemStack"
function ItemStack.prototype.____constructor(self)
    self.amount = 0
end
function ItemStack.prototype.setId(self, id)
    self.id = id
end
function ItemStack.prototype.setAmount(self, value)
    local extra = 0
    if value <= 64 then
        self.amount = value
    else
        self.amount = 64
        extra = value - 64
    end
    return extra
end
function ItemStack.prototype.clone(self)
    local newStack = __TS__New(ItemStack)
    newStack:setId(self.Id)
    newStack:setAmount(self.Amount)
    return newStack
end
__TS__SetDescriptor(
    ItemStack.prototype,
    "Id",
    {get = function(self)
        return self.id or "minecraft:air"
    end},
    true
)
__TS__SetDescriptor(
    ItemStack.prototype,
    "Amount",
    {get = function(self)
        return self.amount
    end},
    true
)
WorkerInventory = __TS__Class()
WorkerInventory.name = "WorkerInventory"
function WorkerInventory.prototype.____constructor(self)
    self.content = __TS__New(Map)
    do
        local i = 1
        while i <= 16 do
            self.content:set(
                i,
                __TS__New(ItemStack)
            )
            i = i + 1
        end
    end
end
function WorkerInventory.prototype.getStackBy(self, slotId)
    return self.content:get(slotId) or nil
end
function WorkerInventory.prototype.setStackIn(self, slotId, stack)
    if stack.Id == "minecraft:air" then
        return
    end
    self.content:set(slotId, stack)
end
function WorkerInventory.prototype.addStack(self, stack)
    do
        local i = 1
        while i <= 16 do
            local slot = self.content:get(i) or __TS__New(ItemStack)
            if slot.Id == "minecraft:air" then
                self.content:set(i, stack)
                break
            end
            i = i + 1
        end
    end
end
function WorkerInventory.prototype.copy(self)
    local copied = __TS__New(WorkerInventory)
    do
        local i = 1
        while i <= 16 do
            local original = self.content:get(i) or __TS__New(ItemStack)
            local newStack = original:clone()
            copied:setStackIn(i, newStack)
            i = i + 1
        end
    end
    return copied
end
WorkerInventoryState = __TS__Class()
WorkerInventoryState.name = "WorkerInventoryState"
function WorkerInventoryState.prototype.____constructor(self, originalInventory)
    self.content = originalInventory:copy()
    self.consumedEvent = __TS__New(ItemConsumedEvent)
end
function WorkerInventoryState.prototype.canConsume(self, itemId)
    do
        local i = 1
        while i <= 16 do
            local stack = self.content:getStackBy(i)
            if stack and stack.Id == itemId and stack.Amount > 0 then
                return true
            end
            i = i + 1
        end
    end
    return false
end
function WorkerInventoryState.prototype.consume(self, itemId)
    do
        local i = 1
        while i <= 16 do
            local stack = self.content:getStackBy(i)
            if (stack and stack.Id) == itemId then
                stack:setAmount(stack.Amount - 1)
                local eventArgs = __TS__New(ItemConsumedEventArgs, i, itemId)
                self.consumedEvent:notify(eventArgs)
                break
            end
            i = i + 1
        end
    end
end
ItemConsumedEvent = __TS__Class()
ItemConsumedEvent.name = "ItemConsumedEvent"
function ItemConsumedEvent.prototype.____constructor(self)
    self.subscribers = {}
end
function ItemConsumedEvent.prototype.subscribe(self, func)
    local ____self_subscribers_2 = self.subscribers
    ____self_subscribers_2[#____self_subscribers_2 + 1] = func
end
function ItemConsumedEvent.prototype.notify(self, args)
    __TS__ArrayForEach(
        self.subscribers,
        function(____, func)
            func(nil, args)
        end
    )
end
ItemConsumedEventArgs = __TS__Class()
ItemConsumedEventArgs.name = "ItemConsumedEventArgs"
function ItemConsumedEventArgs.prototype.____constructor(self, slotId, itemId)
    self.slotId = slotId
    self.itemId = itemId
end
AbstractCommands = __TS__Class()
AbstractCommands.name = "AbstractCommands"
function AbstractCommands.prototype.____constructor(self)
    self.query = {}
end
function AbstractCommands.prototype.forward(self)
    local ____self_query_3 = self.query
    ____self_query_3[#____self_query_3 + 1] = "f"
    return self
end
function AbstractCommands.prototype.up(self)
    local ____self_query_4 = self.query
    ____self_query_4[#____self_query_4 + 1] = "u"
    return self
end
function AbstractCommands.prototype.turn(self)
    local ____self_query_5 = self.query
    ____self_query_5[#____self_query_5 + 1] = "t"
    return self
end
function AbstractCommands.prototype.setSlot(self, id)
    local ____self_query_6 = self.query
    ____self_query_6[#____self_query_6 + 1] = "s" .. tostring(id)
    return self
end
function AbstractCommands.prototype.place(self)
    local ____self_query_7 = self.query
    ____self_query_7[#____self_query_7 + 1] = "p"
    return self
end
function AbstractCommands.prototype.build(self)
    return table.concat(self.query, "")
end
ResourceCalculator = __TS__Class()
ResourceCalculator.name = "ResourceCalculator"
function ResourceCalculator.prototype.____constructor(self, structure, dict)
    self.structure = structure
    self.dictionary = dict
end
function ResourceCalculator.prototype.neededFuel(self)
    local scale = self.structure.scale
    return scale.y * scale.z
end
function ResourceCalculator.prototype.neededInventoryForWorker(self, workerXPos)
    local strcContent = self.structure.content
    local scale = self.structure.scale
    local xPos = workerXPos
    local blockCount = __TS__New(Map)
    do
        local y = 0
        while y < scale.y do
            do
                local z = 0
                while z < scale.z do
                    do
                        local n = strcContent[xPos + 1][y + 1][z + 1]
                        local id = self.dictionary[n]
                        if id == "minecraft:air" then
                            goto __continue55
                        end
                        if blockCount:has(id) then
                            local current = blockCount:get(id) or 0
                            blockCount:set(id, current + 1)
                        else
                            blockCount:set(id, 1)
                        end
                    end
                    ::__continue55::
                    z = z + 1
                end
            end
            y = y + 1
        end
    end
    local inventory = __TS__New(WorkerInventory)
    for ____, ____value in __TS__Iterator(blockCount) do
        local k = ____value[1]
        local v = ____value[2]
        local extra = v
        while extra > 0 do
            local newStack = __TS__New(ItemStack)
            newStack:setId(k)
            extra = newStack:setAmount(extra)
            inventory:addStack(newStack)
        end
    end
    return inventory
end
ProceduralStructureBuilder = __TS__Class()
ProceduralStructureBuilder.name = "ProceduralStructureBuilder"
function ProceduralStructureBuilder.prototype.____constructor(self)
end
function ProceduralStructureBuilder.prototype.execute(self, scale, logic)
    local structure = __TS__New(Structure, scale)
    do
        local x = 0
        while x < scale.x do
            do
                local y = 0
                while y < scale.y do
                    do
                        local z = 0
                        while z < scale.z do
                            structure.content[x + 1][y + 1][z + 1] = logic(
                                nil,
                                __TS__New(Vec3, x, y, z)
                            )
                            z = z + 1
                        end
                    end
                    y = y + 1
                end
            end
            x = x + 1
        end
    end
    return structure
end
PosToBlock = __TS__Class()
PosToBlock.name = "PosToBlock"
function PosToBlock.prototype.____constructor(self, structure, dict)
    self.dictionary = dict
    self.structure = structure
end
function PosToBlock.prototype.execute(self, p)
    if p.x >= self.structure.scale.x or p.x < 0 then
        return nil
    end
    if p.y >= self.structure.scale.y or p.y < 0 then
        return nil
    end
    if p.z >= self.structure.scale.z or p.z < 0 then
        return nil
    end
    return self.dictionary[self.structure.content[p.x + 1][p.y + 1][p.z + 1]]
end
ResourcesPresenter = __TS__Class()
ResourcesPresenter.name = "ResourcesPresenter"
function ResourcesPresenter.prototype.____constructor(self, resourceCalculator)
    self.resourceCalculator = resourceCalculator
end
function ResourcesPresenter.prototype.execute(self, workerX)
    local fuel = self.resourceCalculator:neededFuel()
    local inventory = self.resourceCalculator:neededInventoryForWorker(workerX)
    local result = ("needed fuel: " .. tostring(fuel)) .. "\n"
    do
        local i = 1
        while i <= 16 do
            local stack = inventory:getStackBy(i)
            if stack and stack.Id ~= "minecraft:air" and stack.Amount > 0 then
                result = result .. ((((("Slot " .. tostring(i)) .. ": ") .. stack.Id) .. " x") .. tostring(stack.Amount)) .. "\n"
            end
            i = i + 1
        end
    end
    return result
end
AbstractCommandsPresenter = __TS__Class()
AbstractCommandsPresenter.name = "AbstractCommandsPresenter"
function AbstractCommandsPresenter.prototype.____constructor(self, structure, resourceCalc, workerInfo, posToBlock)
    self.commands = __TS__New(AbstractCommands)
    self.structure = structure
    self.workerXPos = workerInfo.xPos
    local originalInventory = resourceCalc:neededInventoryForWorker(workerInfo.xPos)
    self.inventoryState = __TS__New(WorkerInventoryState, originalInventory)
    self.posToBlock = posToBlock
    self.inventoryState.consumedEvent:subscribe(function(____, args)
        self.commands:setSlot(args.slotId)
        self.commands:place()
    end)
end
function AbstractCommandsPresenter.prototype.execute(self)
    do
        local y = 0
        while y < self.structure.scale.y do
            if y % 2 == 0 then
            do
                local z = 0
                while z < self.structure.scale.z - 1 do
                    local blockId = self.posToBlock:execute(__TS__New(Vec3, self.workerXPos, y, z))
                    if blockId then
                        if self.inventoryState:canConsume(blockId) then
                            self.inventoryState:consume(blockId)
                        end
                    end
                    self.commands:forward()
                    z = z + 1
                end
            end
            local blockId = self.posToBlock:execute(__TS__New(Vec3, self.workerXPos, y, self.structure.scale.z - 1))
            if blockId then
                if self.inventoryState:canConsume(blockId) then
                    self.inventoryState:consume(blockId)
                end
            end
            self.commands:turn()
            self.commands:up()
            y = y + 1
            else
            do
                local z = self.structure.scale.z - 2
                while z >= 0 do
                    local blockId = self.posToBlock:execute(__TS__New(Vec3, self.workerXPos, y, z))
                    if blockId then
                        if self.inventoryState:canConsume(blockId) then
                            self.inventoryState:consume(blockId)
                        end
                    end
                    self.commands:forward()
                    z = z - 1
                end
            end
            local blockId = self.posToBlock:execute(__TS__New(Vec3, self.workerXPos, y, self.structure.scale.z - 1))
            if blockId then
                if self.inventoryState:canConsume(blockId) then
                    self.inventoryState:consume(blockId)
                end
            end
            self.commands:turn()
            self.commands:up()
            y = y + 1
            end
        end
    end
    return self.commands:build()
end
blockDict = {[0] = "minecraft:air", [1] = "minecraft:glow_stone"}
logic = function(____, p)
    local center_1 = __TS__New(Vec3, 0, 0, 0)
    local center_2 = __TS__New(Vec3, 31, 31, 31)
    local a = 32;
    local r = (math.sqrt(3) / 4) * a;
    local dx_1 = math.abs(p.x - center_1.x)
    local dy_1 = math.abs(p.y - center_1.y)
    local dz_1 = math.abs(p.z - center_1.z)

    local dx_2 = math.abs(p.x - center_2.x)
    local dy_2 = math.abs(p.y - center_2.y)
    local dz_2 = math.abs(p.z - center_2.z)

    if dx_1 * dx_1 + dy_1 * dy_1 + dz_1 * dz_1 <= r*r or dx_2 * dx_2 + dy_2 * dy_2 + dz_2 * dz_2 <= r*r then
        return 1
    end
    return 0
end
builder = __TS__New(ProceduralStructureBuilder)
scale = __TS__New(Vec3, 32, 32, 32)
structure = builder:execute(scale, logic)
resourceCalc = __TS__New(ResourceCalculator, structure, blockDict)
WorkerConnectionProgress = __TS__Class()
WorkerConnectionProgress.name = "WorkerConnectionProgress"
function WorkerConnectionProgress.prototype.____constructor(self, workerId, xPos, readyToBuild)
    if xPos == nil then
        xPos = -1
    end
    if readyToBuild == nil then
        readyToBuild = false
    end
    self.workerId = workerId
    self.xPos = xPos
    self.readyToBuild = readyToBuild
end
workerConnectionStates = {}
rednet.open("right")
rednet.host("Turtle3DPrinter", "Master")
do
  while true do
    local workerId, msg, protocol = rednet.receive()
    local messages = {}
    for tok in tostring(msg):gmatch("%S+") do
      messages[#messages+1] = tok
    end

    if messages[1] == "first" then
      local xPos = tonumber(messages[2]) or -1
      local newState = __TS__New(WorkerConnectionProgress, workerId)
      newState.xPos = xPos
      workerConnectionStates[#workerConnectionStates + 1] = newState

      local resourcesPresenter = __TS__New(ResourcesPresenter, resourceCalc)
      rednet.send(workerId, resourcesPresenter:execute(xPos))

    elseif messages[1] == "second" then  -- ← ここを修正
      for ____, state in ipairs(workerConnectionStates) do
        if state.workerId == workerId then
          state.readyToBuild = true
        end
      end

      if #__TS__ArrayFilter(workerConnectionStates, function(____, s) return s.readyToBuild end)
         == #workerConnectionStates then
        for ____, state in ipairs(workerConnectionStates) do
          local commandPresenter = __TS__New(
            AbstractCommandsPresenter,
            structure,
            resourceCalc,
            state,
            __TS__New(PosToBlock, structure, blockDict)
          )
          rednet.send(state.workerId, commandPresenter:execute())
        end
        break
      end
    end
  end
end
