-- =========================================================
-- Leaning Twin-Tower Builder (ComputerCraft / CC:Tweaked)
-- 外周:  半径19 / ディスク2層 + 柱12層 を1セットとして無限に積む。各セットごとに中心X+1。
-- 内周:  半径15 / 同じ中心オフセットでただの円柱（各Yでリングを打つ）。
-- 追加:  ランダム在庫選択配置 / 自動燃料補給 / turtle位置・向きの厳密トラッキング
-- ※ circlePoints / pillarPoints はあなたの最適化版を使ってください（下のダミーは差し替えが必要）。
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

-- 以下2つは circlePoints の元で使われるので残してあります（あなたの実装と互換）
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

--------------------------------------------------------------
-- ▼▼▼ ここをあなたの最適化版で置き換えてください（関数名は固定） ▼▼▼
--------------------------------------------------------------
-- ダミー：あなたの最適化 circlePoints を貼り付けてください
-- 引数: (cx, cy, cz, r) -> { {x=..., y=..., z=...}, ... }
local function circlePoints(cx, cy, cz, r)
    -- ↓ダミー実装（あなたの最適化版で必ず置換してください）
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
        local symmetries = symmetryPositions(p.x, p.y, p.z)
        for _, s in ipairs(symmetries) do
            table.insert(newPoints, s)
        end
    end

    for _, s in ipairs(newPoints) do
        table.insert(positions, s)
    end

    return positions
end

-- ダミー：あなたの最適化 pillarPoints を貼り付けてください
-- 引数: (cx, cy, cz, r) -> 円周上の柱の“基点（x,z）”群（yはcyで入ってきてもOK）
local function pillarPoints(cx, cy, cz, r)
    -- ↓ダミー実装（あなたの最適化版で必ず置換してください）
    local angleStep = (1 / r)
    local positions = {}
    local count = 0

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
-- ▲▲▲ ここまで差し替え ▲▲▲
--------------------------------------------------------------

--------------------------
-- 方向と姿勢管理
--------------------------
-- lookAt: 0 = +z, 1 = +x, 2 = -z, 3 = -x
local DIR = { POS_Z = 0, POS_X = 1, NEG_Z = 2, NEG_X = 3 }

local turtlePos = makePosTable(0, 0, 0)  -- スタート地点を(0,0,0)として扱う
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
local MIN_FUEL_BUFFER = 1000      -- これ未満になったら補給を試みる
local WAIT_SECONDS_ON_EMPTY = 8   -- 在庫/燃料が無い時は待機して再試行

local function ensureFuel(level)
    local fl = turtle.getFuelLevel()
    if fl == "unlimited" then return true end
    if fl >= level then return true end

    -- 在庫から燃料化
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            if turtle.refuel(0) then
                -- 一気に使う（必要なら分割も可）
                if turtle.refuel() then
                    fl = turtle.getFuelLevel()
                    if fl == "unlimited" or fl >= level then
                        return true
                    end
                end
            end
        end
    end
    -- 足りなければ待機
    print("[Fuel] 追加燃料が必要です。インベントリに燃料を補充してください。")
    while true do
        sleep(WAIT_SECONDS_ON_EMPTY)
        fl = turtle.getFuelLevel()
        if fl == "unlimited" or fl >= level then return true end
        -- 再スキャン
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
    -- まず空でないスロットの一覧を作る
    local nonEmpty = {}
    for slot = 1, 16 do
        if turtle.getItemCount(slot) > 0 then
            table.insert(nonEmpty, slot)
        end
    end
    if #nonEmpty == 0 then return nil end

    -- ランダム順に試す（最大16回）
    local tried = {}
    for _ = 1, #nonEmpty do
        local idx = math.random(1, #nonEmpty)
        while tried[idx] do idx = math.random(1, #nonEmpty) end
        tried[idx] = true

        local slot = nonEmpty[idx]
        turtle.select(slot)
        -- placeDownの前に“下が既に埋まっている”なら成功扱いで返して良い
        if turtle.detectDown() then
            return slot, true  -- 置かなくてOK（すでに置いてある）
        end
        -- ブロックとして置けるかどうかは置いてみないと分からないので、呼び元で実際にplaceDown
        return slot, false
    end
    return nil
end

--------------------------
-- 安全移動（前進/昇降）
--------------------------
local function tryForward()
    ensureFuel(1)
    local tries = 0
    while not turtle.forward() do
        tries = tries + 1
        if turtle.detect() then turtle.dig() else turtle.attack() end
        if tries > 20 then return false end
        sleep(0.1)
    end
    -- 位置更新
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

local function tryBack()
    ensureFuel(1)
    if turtle.back() then
        if turtleLook == DIR.POS_Z then
            turtlePos.z = turtlePos.z - 1
        elseif turtleLook == DIR.NEG_Z then
            turtlePos.z = turtlePos.z + 1
        elseif turtleLook == DIR.POS_X then
            turtlePos.x = turtlePos.x - 1
        else
            turtlePos.x = turtlePos.x + 1
        end
        return true
    end
    -- 後退できない時は向き変えて前進にフォールバック
    face((turtleLook + 2) % 4)
    local ok = tryForward()
    -- 戻す
    face((turtleLook + 2) % 4)
    return ok
end

local function tryUp()
    ensureFuel(1)
    local tries = 0
    while not turtle.up() do
        tries = tries + 1
        if turtle.detectUp() then turtle.digUp() else turtle.attackUp() end
        if tries > 20 then return false end
        sleep(0.1)
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
        sleep(0.1)
    end
    turtlePos.y = turtlePos.y - 1
    return true
end

--------------------------
-- 絶対座標へ移動
--------------------------
local function moveTo(dest) -- dest = {x=, y=, z=}
    -- Z方向
    local dz = dest.z - turtlePos.z
    if dz ~= 0 then
        face(dz > 0 and DIR.POS_Z or DIR.NEG_Z)
        for _ = 1, math.abs(dz) do assert(tryForward(), "前進不可") end
    end
    -- X方向
    local dx = dest.x - turtlePos.x
    if dx ~= 0 then
        face(dx > 0 and DIR.POS_X or DIR.NEG_X)
        for _ = 1, math.abs(dx) do assert(tryForward(), "前進不可") end
    end
    -- Y方向
    local dy = dest.y - turtlePos.y
    if dy > 0 then
        for _ = 1, dy do assert(tryUp(), "上昇不可") end
    elseif dy < 0 then
        for _ = 1, -dy do assert(tryDown(), "下降不可") end
    end
end

--------------------------
-- ランダム選択で下向き配置
--------------------------
local function placeDownRandom()
    -- 既にブロックがあるなら置かない
    if turtle.detectDown() then return true end

    while true do
        local slot, alreadyPlaced = selectRandomPlaceableSlot()
        if alreadyPlaced then return true end
        if not slot then
            print("[Inventory] 置けるブロックがありません。補充待ち…")
            sleep(WAIT_SECONDS_ON_EMPTY)
        else
            turtle.select(slot)
            if turtle.placeDown() then
                return true
            else
                -- 置けなかった（非設置アイテム等）。他スロットを試す
                -- 全スロット尽きたかは selectRandomPlaceableSlot 側で回しているので、そのまま再試行
            end
        end
    end
end

--------------------------
-- 指定座標にブロックを1つ置く（上から置く）
--------------------------
local function buildAt(pos) -- pos = {x=, y=, z=}
    -- 目的地の“真上”へ移動してから placeDown
    moveTo(makePosTable(pos.x, pos.y + 1, pos.z))
    ensureFuel(MIN_FUEL_BUFFER) -- 余裕を持って燃料確保
    assert(placeDownRandom(), "設置失敗")
end

--------------------------
-- リングを1層作る（circlePoints 利用）
--------------------------
local function buildRingLayer(cx, y, cz, r)
    local pts = circlePoints(cx, y, cz, r)
    for _, p in ipairs(pts) do
        -- p にそのまま置く（buildAt が y+1から置く）
        buildAt(p)
    end
end

--------------------------
-- 柱群を高さ分積む（pillarPoints + 縦に積む）
--------------------------
local function buildPillars(cx, baseY, cz, r, height)
    local bases = pillarPoints(cx, baseY, cz, r) -- x,z（yは無視 or 使ってOK）
    for h = 0, height - 1 do
        local y = baseY + h
        for _, b in ipairs(bases) do
            buildAt(makePosTable(b.x, y, b.z))
        end
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
    print("== Leaning Twin-Tower Builder ==")
    print("外周: r="..OUTER_R.." / ディスク"..DISK_H.." + 柱"..PILLAR_H.."（1段ごとに中心X+1）")
    print("内周: r="..INNER_R.." / ただの円柱（中心オフセットは外周に追従）")
    print("インベントリにブロックと燃料を入れておいてください。開始します。")

    ensureFuel(MIN_FUEL_BUFFER)

    local bundle = 0
    while true do
        local centerX = bundle -- ピサ風の傾き：段ごとに +1
        local baseY   = bundle * BUNDLE_H
        local centerZ = 0

        print(("--- Bundle %d | center=(%d,%d,%d) ---"):format(bundle, centerX, baseY, centerZ))

        -- 1) 外周ディスク 2層
        for dy = 0, DISK_H - 1 do
            local y = baseY + dy
            buildRingLayer(centerX, y, centerZ, OUTER_R)
        end

        -- 2) 内周ディスク 2層（外周に中心オフセットを合わせる）
        for dy = 0, DISK_H - 1 do
            local y = baseY + dy
            buildRingLayer(centerX, y, centerZ, INNER_R)
        end

        -- 3) 外周の柱 12層（ディスクの直上から）
        buildPillars(centerX, baseY + DISK_H, centerZ, OUTER_R, PILLAR_H)

        -- 4) 内周はただの円柱：各Yにリングを打つ
        for h = 0, PILLAR_H - 1 do
            local y = baseY + DISK_H + h
            buildRingLayer(centerX, y, centerZ, INNER_R)
        end

        bundle = bundle + 1
        -- 無限に続く
    end
end

-- 実行
main()
