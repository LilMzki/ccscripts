-- =========================================================
-- Leaning Twin-Tower Builder (Order-Optimized)
--  - 外周: r=19, ディスク2層 + 柱12層 を1バンドルとして無限積み。バンドル毎に中心X+1。
--  - 内周: r=15, 同じ中心オフセットで円柱（各Yでリングを打つ）。
--  - 置くブロックは在庫からランダム選択。燃料/在庫の自動監視。
--  - 主要修正点: 円周点を角度で並べ替え + 近接点から開始 + 層ごとにCW/CCW交互。
--    柱は角度順に「1本ずつ」積み切る。
--  ※ circlePoints / pillarPoints はあなたの“最適化版”をこのダミーに置き換えてください。
-- =========================================================

--------------------------
-- 乱数Seed
--------------------------
do
    local seed = (os.epoch and os.epoch("utc")) or math.floor((os.clock() or 0) * 1e6) or os.time()
    math.randomseed(seed)
end

--------------------------
-- 基本ユーティリティ
--------------------------
local function makePosTable(x, y, z) return {x = x, y = y, z = z} end

local function symmetryPositions(x, y, z)
    local result = {}
    table.insert(result, makePosTable(-x, y, z))
    table.insert(result, makePosTable(x, y, -z))
    table.insert(result, makePosTable(-x, y, -z))
    table.insert(result, makePosTable(z, y, x))
    table.insert(result, makePosTable(-z, y, x))
    table.insert(result, makePosTable(z, y, -x))
    table.insert(result, makePosTable(-z, y, -x))
    return result
end

-- atan2 互換（Luaのバージョン差吸収）
local function atan2(y, x)
    if math.atan2 then return math.atan2(y, x) end
    return math.atan(y, x)
end

--------------------------------------------------------------
-- ▼▼▼ ここをあなたの最適化版で置き換えてください ▼▼▼
--------------------------------------------------------------
-- ダミー circlePoints（必ず差し替え）
local function circlePoints(cx, cy, cz, r)
    local angleStep = (1 / r)
    local positions = {}
    for i = 0, math.pi / 4, angleStep do
        local x = cx + math.floor(0.5 + r * math.cos(i))
        local y = cy
        local z = cz + math.floor(0.5 + r * math.sin(i))
        table.insert(positions, makePosTable(x, y, z))
    end
    local newPoints = {}
    for _, p in ipairs(positions) do
        local sym = symmetryPositions(p.x, p.y, p.z)
        for _, s in ipairs(sym) do table.insert(newPoints, s) end
    end
    for _, s in ipairs(newPoints) do table.insert(positions, s) end
    return positions
end

-- ダミー pillarPoints（必ず差し替え）
local function pillarPoints(cx, cy, cz, r)
    local angleStep = (1 / r)
    local positions, count = {}, 0
    for i = 0, 2 * math.pi, angleStep do
        if count % 4 ~= 2 and count % 4 ~= 3 then
            local x = cx + math.floor(0.5 + r * math.cos(i))
            local y = cy
            local z = cz + math.floor(0.5 + r * math.sin(i))
            table.insert(positions, makePosTable(x, y, z))
        end
        count = count + 1
    end
    return positions
end
--------------------------------------------------------------
-- ▲▲▲ 差し替えここまで ▲▲▲
--------------------------------------------------------------

--------------------------
-- 方向と姿勢管理
--------------------------
-- lookAt: 0 = +z, 1 = +x, 2 = -z, 3 = -x
local DIR = { POS_Z = 0, POS_X = 1, NEG_Z = 2, NEG_X = 3 }

local turtlePos = makePosTable(0, 0, 0)  -- 原点スタート想定
local turtleLook = DIR.POS_Z

local function turnRightN(n)
    for _ = 1, n do turtle.turnRight(); turtleLook = (turtleLook + 1) % 4 end
end

local function turnLeftN(n)
    for _ = 1, n do turtle.turnLeft(); turtleLook = (turtleLook + 3) % 4 end
end

local function face(direction)
    local delta = (direction - turtleLook) % 4
    if delta == 1 then
        turnRightN(1)
    elseif delta == 2 then
        turnRightN(2)
    elseif delta == 3 then
        turnLeftN(1)
    end
end

--------------------------
-- 燃料＆在庫
--------------------------
local MIN_FUEL_BUFFER = 1000
local WAIT_SECONDS_ON_EMPTY = 8

local function ensureFuel(level)
    local fl = turtle.getFuelLevel()
    if fl == "unlimited" or fl >= level then return true end

    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            if turtle.refuel(0) and turtle.refuel() then
                fl = turtle.getFuelLevel()
                if fl == "unlimited" or fl >= level then return true end
            end
        end
    end
    print("[Fuel] 燃料が不足。補給を待機中…")
    while true do
        sleep(WAIT_SECONDS_ON_EMPTY)
        fl = turtle.getFuelLevel()
        if fl == "unlimited" or fl >= level then return true end
        for slot = 1, 16 do
            if turtle.getItemCount(slot) > 0 then
                turtle.select(slot)
                if turtle.refuel(0) and turtle.refuel() then
                    fl = turtle.getFuelLevel()
                    if fl == "unlimited" or fl >= level then return true end
                end
            end
        end
    end
end

local function selectRandomPlaceableSlot()
    local nonEmpty = {}
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then table.insert(nonEmpty, slot) end
    end
    if #nonEmpty == 0 then return nil end

    local tried = {}
    for _ = 1, #nonEmpty do
        local idx = math.random(1, #nonEmpty)
        while tried[idx] do idx = math.random(1, #nonEmpty) end
        tried[idx] = true

        local slot = nonEmpty[idx]
        turtle.select(slot)
        if turtle.detectDown() then
            return slot, true
        end
        return slot, false
    end
    return nil
end

--------------------------
-- 安全移動
--------------------------
local function tryForward()
    ensureFuel(1)
    local tries = 0
    while not turtle.forward() do
        tries = tries + 1
        if turtle.detect() then turtle.dig() else turtle.attack() end
        if tries > 20 then return false end
        sleep(0.05)
    end
    if turtleLook == DIR.POS_Z then
        turtlePos.z = turtlePos.z + 1
    elseif turtleLook == DIR.NEG_Z then
        turtlePos.z = turtlePos.z - 1
    elseif turtleLook == DIR.POS_X then
        turtlePos.x = turtlePos.x + 1
    else
        turtlePos.x = turtlePos.x - 1
    end
    return true
end

local function tryUp()
    ensureFuel(1)
    local tries = 0
    while not turtle.up() do
        tries = tries + 1
        if turtle.detectUp() then turtle.digUp() else turtle.attackUp() end
        if tries > 20 then return false end
        sleep(0.05)
    end
    turtlePos.y = turtlePos.y + 1
    return true
end

local function tryDown()
    ensureFuel(1)
    local tries = 0
    while not turtle.down() do
        tries = tries + 1
        if turtle.detectDown() then turtle.digDown() else turtle.attackDown() end
        if tries > 20 then return false end
        sleep(0.05)
    end
    turtlePos.y = turtlePos.y - 1
    return true
end

local function moveTo(dest) -- dest = {x=, y=, z=}
    local dz = dest.z - turtlePos.z
    if dz ~= 0 then
        face(dz > 0 and DIR.POS_Z or DIR.NEG_Z)
        for _ = 1, math.abs(dz) do assert(tryForward(), "前進不可") end
    end
    local dx = dest.x - turtlePos.x
    if dx ~= 0 then
        face(dx > 0 and DIR.POS_X or DIR.NEG_X)
        for _ = 1, math.abs(dx) do assert(tryForward(), "前進不可") end
    end
    local dy = dest.y - turtlePos.y
    if dy > 0 then
        for _ = 1, dy do assert(tryUp(), "上昇不可") end
    elseif dy < 0 then
        for _ = 1, -dy do assert(tryDown(), "下降不可") end
    end
end

--------------------------
-- 置く（真上から placeDown）
--------------------------
local function placeDownRandom()
    if turtle.detectDown() then return true end
    while true do
        local slot, already = selectRandomPlaceableSlot()
        if already then return true end
        if not slot then
            print("[Inventory] ブロックがありません。補充を待機中…")
            sleep(WAIT_SECONDS_ON_EMPTY)
        else
            turtle.select(slot)
            if turtle.placeDown() then return true end
        end
    end
end

local function buildAt(pos)
    moveTo(makePosTable(pos.x, pos.y + 1, pos.z))
    ensureFuel(MIN_FUEL_BUFFER)
    assert(placeDownRandom(), "設置失敗")
end

--------------------------
-- 点群ユーティリティ（重複除去 & 角度ソート & 近い点から開始）
--------------------------
local TWO_PI = math.pi * 2

local function keyXYZ(p) return ("%d:%d:%d"):format(p.x, p.y, p.z) end
local function keyXZ(p)  return ("%d:%d"):format(p.x, p.z) end -- 同一Y層での重複用

local function dedupByXYZo(pts)
    local seen, out = {}, {}
    for _, p in ipairs(pts) do
        local k = keyXYZ(p)
        if not seen[k] then seen[k] = true; table.insert(out, p) end
    end
    return out
end

local function dedupByXZ_sameY(pts)
    local seen, out = {}, {}
    for _, p in ipairs(pts) do
        local k = keyXZ(p)
        if not seen[k] then seen[k] = true; table.insert(out, p) end
    end
    return out
end

local function angleOf(p, cx, cz)
    local a = atan2(p.z - cz, p.x - cx)
    if a < 0 then a = a + TWO_PI end
    return a
end

local function sortByAngle(pts, cx, cz, clockwise)
    table.sort(pts, function(a, b)
        local aa, ab = angleOf(a, cx, cz), angleOf(b, cx, cz)
        if clockwise then return aa > ab else return aa < ab end
    end)
    return pts
end

local function rotateToNearestStart(ordered, preferPos) -- preferPos = {x,z}
    if #ordered == 0 then return ordered end
    local min_i, min_d = 1, math.huge
    for i, p in ipairs(ordered) do
        local dx, dz = p.x - preferPos.x, p.z - preferPos.z
        local d = dx * dx + dz * dz
        if d < min_d then min_d, min_i = d, i end
    end
    if min_i == 1 then return ordered end
    local out = {}
    for i = min_i, #ordered do table.insert(out, ordered[i]) end
    for i = 1, min_i - 1 do table.insert(out, ordered[i]) end
    return out
end

--------------------------
-- リング構築（順序最適化付き）
--------------------------
local function buildRingLayer(cx, y, cz, r, clockwise)
    local pts = circlePoints(cx, y, cz, r)

    -- 1) 同一層での重複削除（x,z基準）
    pts = dedupByXZ_sameY(pts)

    -- 2) 角度順に並べ替え
    pts = sortByAngle(pts, cx, cz, clockwise)

    -- 3) 現在位置に近い点から開始（水平面での近傍）
    pts = rotateToNearestStart(pts, {x = turtlePos.x, z = turtlePos.z})

    -- 4) 連続配置
    for _, p in ipairs(pts) do
        buildAt(p)
    end
end

--------------------------
-- 柱群構築（角度順 + 1本ずつ積み切る）
--------------------------
local function buildSinglePillarAt(x, baseY, z, height)
    -- 近い層から開始（baseY+1 の高さで水平移動）
    moveTo(makePosTable(x, baseY + 1, z))
    for h = 0, height - 1 do
        buildAt(makePosTable(x, baseY + h, z))
    end
    -- 終了位置を baseY+1 に揃える（次の柱へ水平移動しやすく）
    moveTo(makePosTable(x, baseY + 1, z))
end

local function buildPillars(cx, baseY, cz, r, height, clockwise)
    local bases = pillarPoints(cx, baseY, cz, r)

    -- 1) yはどうでも良いのでx,zで重複削除
    local tmp = {}
    for _, b in ipairs(bases) do table.insert(tmp, makePosTable(b.x, baseY, b.z)) end
    bases = dedupByXZ_sameY(tmp)

    -- 2) 角度順
    bases = sortByAngle(bases, cx, cz, clockwise)

    -- 3) 現在地に近い柱から開始
    bases = rotateToNearestStart(bases, {x = turtlePos.x, z = turtlePos.z})

    -- 4) 柱を1本ずつ積み切る
    for _, b in ipairs(bases) do
        buildSinglePillarAt(b.x, baseY, b.z, height)
    end
end

--------------------------
-- メイン：無限積み
--------------------------
local OUTER_R = 19
local INNER_R = 15
local DISK_H  = 2
local PILLAR_H = 12
local BUNDLE_H = DISK_H + PILLAR_H

local function main()
    print("== Leaning Twin-Tower Builder (Order-Optimized) ==")
    print("在庫と燃料を投入しておいてください。開始します。")
    ensureFuel(MIN_FUEL_BUFFER)

    local bundle = 0
    while true do
        local centerX = bundle -- ピサの傾き: バンドル毎に +1
        local baseY   = bundle * BUNDLE_H
        local centerZ = 0
        print(("--- Bundle %d | center=(%d,%d,%d) ---"):format(bundle, centerX, baseY, centerZ))

        -- 交互にCW/CCWで巡回（上下移動時の横移動を削減）
        local cw0 = (bundle % 2 == 0)

        -- 外周ディスク 2層
        for dy = 0, DISK_H - 1 do
            local y = baseY + dy
            buildRingLayer(centerX, y, centerZ, OUTER_R, (dy % 2 == 0) and cw0 or (not cw0))
        end

        -- 内周ディスク 2層（同じ中心オフセット）
        for dy = 0, DISK_H - 1 do
            local y = baseY + dy
            buildRingLayer(centerX, y, centerZ, INNER_R, (dy % 2 == 0) and (not cw0) or cw0)
        end

        -- 外周の柱 12層（柱は1本ずつ完了）
        buildPillars(centerX, baseY + DISK_H, centerZ, OUTER_R, PILLAR_H, cw0)

        -- 内周は円柱：各Yにリング（CW/CCW交互）
        for h = 0, PILLAR_H - 1 do
            local y = baseY + DISK_H + h
            buildRingLayer(centerX, y, centerZ, INNER_R, ((h % 2) == 0) and cw0 or (not cw0))
        end

        bundle = bundle + 1
    end
end

-- 実行
main()
