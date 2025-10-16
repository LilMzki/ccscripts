-- =========================================================
-- Leaning Twin-Tower Builder (Resilient + Order-Optimized)
--  - 外周: 半径19, ディスク2層 + 柱12層 を1バンドルとして無限積み。バンドル毎に中心X+1（ピサ風）。
--  - 内周: 半径15, 同じ中心オフセットで円柱（各Yでリングを打つ）。
--  - 置くブロックは在庫からランダム選択。燃料/在庫の自動監視。
--  - 下降は設計上ほぼ不要（常に上へ）。どうしても必要なら smartDescent。
--  - 状態永続化：/tower_state に保存し、クラッシュ/中断から復帰可能。
--  ※ circlePoints / pillarPoints はあなたの“最適化版”に置換してください（関数名・引数は固定）。
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

-- atan2 互換
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
-- 永続化（セーブ / ロード）
--------------------------
local STATE_FILE = "/tower_state"

local function saveState(state)
    -- 走行中の姿勢も保存
    state.turtlePos = {x = turtlePos.x, y = turtlePos.y, z = turtlePos.z}
    state.turtleLook = turtleLook
    local s = textutils.serialize(state)
    local f = fs.open(STATE_FILE, "w")
    f.write(s)
    f.close()
end

local function loadState()
    if not fs.exists(STATE_FILE) then return nil end
    local f = fs.open(STATE_FILE, "r")
    local s = f.readAll()
    f.close()
    local ok, t = pcall(textutils.unserialize, s)
    if ok and type(t) == "table" then return t end
    return nil
end

local function applyPoseFromState(state)
    if not state or not state.turtlePos or not state.turtleLook then return end
    -- 位置・向きは「信頼するが強制移動はしない」: 論理状態のみ復元
    turtlePos = makePosTable(state.turtlePos.x, state.turtlePos.y, state.turtlePos.z)
    turtleLook = state.turtleLook
end

--------------------------
-- 燃料＆在庫
--------------------------
local MIN_FUEL_BUFFER = 1000
local WAIT_SECONDS_ON_EMPTY = 8

local function ensureFuel(level, state)
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
    if state then saveState(state) end
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
-- 最小限の“迂回”ユーティリティ（降下が必要な時のみ使用）
--------------------------
local function tryForward()
    ensureFuel(1)
    local tries = 0
    while not turtle.forward() do
        tries = tries + 1
        if turtle.detect() then
            turtle.dig()
        else
            turtle.attack()
        end
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

local function tryDown()  -- 通常は使わない。必要時のみ。
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

-- 下降が必要なときの簡易経路探索（横に1～N歩ずれて降りる）
local function smartDescent(toY, state)
    -- 原則として使わない設計。どうしても必要なときだけ呼ぶ。
    local MAX_SIDE = 6
    while turtlePos.y > toY do
        -- まず直下降
        if tryDown() then goto continue end

        -- 横へ最大MAX_SIDEまでズレ→下降→戻す の試行
        local triedDirs = {DIR.POS_X, DIR.NEG_X, DIR.POS_Z, DIR.NEG_Z}
        local descended = false
        for _, d in ipairs(triedDirs) do
            face(d)
            local moved = 0
            for s = 1, MAX_SIDE do
                if not tryForward() then break end
                moved = moved + 1
                if tryDown() then
                    descended = true
                    break
                end
            end
            -- 戻す（降りられたなら戻さず次のループで継続）
            if not descended and moved > 0 then
                face((d + 2) % 4)
                for _ = 1, moved do tryForward() end
            end
            if descended then break end
        end
        if not descended then
            print("[Path] 降下経路が見つかりません。周囲障害物の除去/整地が必要かも。")
            if state then saveState(state) end
            sleep(3)
        end
        ::continue::
    end
end

--------------------------
-- 絶対座標へ移動（Z→X→Y）。※Yは基本“上向き”のみ
--------------------------
local function moveTo(dest, state) -- dest = {x=, y=, z=}
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
    -- Y方向（原則上がるだけ）
    local dy = dest.y - turtlePos.y
    if dy > 0 then
        for _ = 1, dy do assert(tryUp(), "上昇不可") end
    elseif dy < 0 then
        -- 設計上ここは呼ばれないが、保険としてスマート降下
        smartDescent(dest.y, state)
    end
end

--------------------------
-- 置く（真上から placeDown）
--------------------------
local function placeDownRandom(state)
    if turtle.detectDown() then return true end
    while true do
        local slot, already = selectRandomPlaceableSlot()
        if already then return true end
        if not slot then
            print("[Inventory] ブロックがありません。補充を待機中…")
            if state then saveState(state) end
            sleep(WAIT_SECONDS_ON_EMPTY)
        else
            turtle.select(slot)
            if turtle.placeDown() then return true end
        end
    end
end

local function buildAt(pos, state)
    moveTo(makePosTable(pos.x, pos.y + 1, pos.z), state)
    ensureFuel(MIN_FUEL_BUFFER, state)
    assert(placeDownRandom(state), "設置失敗")
end

--------------------------
-- 点群ユーティリティ（重複除去 & 角度ソート & 近い点から開始）
--------------------------
local TWO_PI = math.pi * 2

local function keyXZ(p)  return ("%d:%d"):format(p.x, p.z) end -- 同一Y層での重複用

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

local function rotateToNearestStart(ordered, preferPos)
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
-- リング構築（順序最適化 + 途中再開対応）
--------------------------
local function buildRingLayer(cx, y, cz, r, clockwise, stateKey, state)
    local pts = circlePoints(cx, y, cz, r)
    pts = dedupByXZ_sameY(pts)
    pts = sortByAngle(pts, cx, cz, clockwise)
    pts = rotateToNearestStart(pts, {x = turtlePos.x, z = turtlePos.z})

    state[stateKey] = state[stateKey] or {i = 1}
    local i = state[stateKey].i

    while i <= #pts do
        buildAt(pts[i], state)
        i = i + 1
        state[stateKey].i = i
        saveState(state)
    end
    -- 完了したら進捗をクリア
    state[stateKey] = nil
    saveState(state)
end

--------------------------
-- 柱群を“層ごとに”積む（下降ゼロ運用）
--------------------------
local function buildPillarsLayered(cx, baseY, cz, r, height, clockwise, state)
    -- 柱の基点を角度順に = 一層ごとにその順で置く
    local bases = pillarPoints(cx, baseY, cz, r)
    local tmp = {}
    for _, b in ipairs(bases) do table.insert(tmp, makePosTable(b.x, baseY, b.z)) end
    bases = dedupByXZ_sameY(tmp)
    bases = sortByAngle(bases, cx, cz, clockwise)
    bases = rotateToNearestStart(bases, {x = turtlePos.x, z = turtlePos.z})

    for h = 0, height - 1 do
        local y = baseY + h
        local key = ("pillar_y_%d"):format(y)
        -- 再開用インデックス
        state[key] = state[key] or {i = 1}
        local i = state[key].i

        while i <= #bases do
            buildAt(makePosTable(bases[i].x, y, bases[i].z), state)
            i = i + 1
            state[key].i = i
            saveState(state)
        end
        state[key] = nil
        saveState(state)
        -- 一層終わったら次層へ上昇（下降なし）
        assert(tryUp(), "次層への上昇に失敗")
    end
end



-- ▼ 追加：外周柱を“そのYで1層だけ”進める
local function buildPillarsOneLayer(cx, y, cz, r, clockwise, state)
    local bases = pillarPoints(cx, y, cz, r)
    local tmp = {}
    for _, b in ipairs(bases) do
        table.insert(tmp, makePosTable(b.x, y, b.z))
    end
    bases = dedupByXZ_sameY(tmp)
    bases = sortByAngle(bases, cx, cz, clockwise)
    bases = rotateToNearestStart(bases, {x = turtlePos.x, z = turtlePos.z})

    local key = ("pillar_y_%d"):format(y)
    state[key] = state[key] or { i = 1 }
    local i = state[key].i

    while i <= #bases do
        buildAt(bases[i], state)
        i = i + 1
        state[key].i = i
        saveState(state)
    end

    state[key] = nil
    saveState(state)
end


--------------------------
-- メイン：無限積み（再開対応）
--------------------------
local OUTER_R = 19
local INNER_R = 15
local DISK_H  = 2
local PILLAR_H = 12
local BUNDLE_H = DISK_H + PILLAR_H

-- ▼ 追加：状態移行（v2 → v3）
local function upgradeStateToV3(state)
    if not state.version or state.version < 3 then
        local bundle = state.bundle or 0
        local baseY  = bundle * BUNDLE_H
        local startY = baseY + DISK_H

        -- どの高さ(Y)から再開すべきかを推定
        local h = 0
        for hh = 0, PILLAR_H - 1 do
            local y = startY + hh
            local pk = ("pillar_y_%d"):format(y)
            local rk = ("inner_cyl_y_%d"):format(y)
            if state[pk] or state[rk] then
                h = hh
                break
            end
        end

        if state.phase == "outer_pillars" or state.phase == "inner_cylinder" then
            state.phase = "bundle_raise"
            state.h = h
            state.layer = 0
            state.innerLayer = 0
        end

        state.version = 3
        saveState(state)
    end
    return state
end


local function main()
    print("== Leaning Twin-Tower Builder (Resilient + Order-Optimized) ==")

    -- 既存の状態があればロード
    -- 既存の default state を version=3 に
    local state = loadState() or {
        version = 3,
        bundle = 0,
        phase = "outer_disk",
        layer = 0,
        innerLayer = 0,
        h = 0,            -- ← 追加：bundle_raise 用レイヤオフセット
        pillarStarted = false,
        cw0 = true,
    }
    applyPoseFromState(state)
    state = upgradeStateToV3(state)  -- ← ここでv2→v3移行

    ensureFuel(MIN_FUEL_BUFFER, state)

    while true do
        local bundle = state.bundle
        local centerX = bundle -- ピサの傾き: バンドル毎に +1
        local baseY   = bundle * BUNDLE_H
        local centerZ = 0

        -- バンドル開始時に回転方向を決める（再開でも固定）
        if state.phase == "outer_disk" and state.layer == 0 and state.innerLayer == 0 and not state.pillarStarted then
            state.cw0 = (bundle % 2 == 0)
            saveState(state)
        end

        print(("--- Bundle %d | center=(%d,%d,%d) ---"):format(bundle, centerX, baseY, centerZ))

        -- 1) 外周ディスク 2層
        if state.phase == "outer_disk" then
            for dy = state.layer, DISK_H - 1 do
                local y = baseY + dy
                local clockwise = (dy % 2 == 0) and state.cw0 or (not state.cw0)
                buildRingLayer(centerX, y, centerZ, OUTER_R, clockwise, ("outer_disk_y_%d"):format(y), state)
                state.layer = dy + 1
                saveState(state)
            end
            state.phase = "inner_disk"
            state.layer = 0
            saveState(state)
        end

        -- 2) 内周ディスク 2層（同じ中心オフセット）
        if state.phase == "inner_disk" then
            for dy = state.innerLayer, DISK_H - 1 do
                local y = baseY + dy
                local clockwise = (dy % 2 == 0) and (not state.cw0) or state.cw0
                buildRingLayer(centerX, y, centerZ, INNER_R, clockwise, ("inner_disk_y_%d"):format(y), state)
                state.innerLayer = dy + 1
                saveState(state)
            end
            state.phase = "outer_pillars"
            state.innerLayer = 0
            saveState(state)
        end

        -- 3) 同時進行：内周（リング）＋外周（柱）を“同じY”で1段ずつ上げていく
if state.phase == "bundle_raise" then
    local clockwisePillar = state.cw0
    local startY = baseY + DISK_H

    -- 必要なら開始高度へ（Yは基本上向きのみ）
    if turtlePos.y < startY + 1 then
        moveTo(makePosTable(turtlePos.x, startY + 1, turtlePos.z), state)
    end

    for h = state.h or 0, PILLAR_H - 1 do
        local y  = startY + h
        local cwRing = ((h % 2) == 0) and state.cw0 or (not state.cw0)

        -- 先に内周リング（円柱として上げる）
        buildRingLayer(centerX, y, centerZ, INNER_R, cwRing, ("inner_cyl_y_%d"):format(y), state)

        -- 続けて同じYで外周柱を1層ぶん
        buildPillarsOneLayer(centerX, y, centerZ, OUTER_R, clockwisePillar, state)

        state.h = h + 1
        saveState(state)

        -- 次層へ。最後の層以外は上昇しておく
        if h < PILLAR_H - 1 then
            assert(tryUp(), "層間上昇に失敗")
        end
    end

    -- バンドル完了 → 次のバンドルへ（中心Xも+1に遷移）
    state.bundle = bundle + 1
    state.phase = "outer_disk"
    state.layer = 0
    state.innerLayer = 0
    state.h = 0
    state.pillarStarted = false
    saveState(state)
end


        -- 4) 内周は円柱：各Yにリング（CW/CCW交互）。下降ゼロ。
        if state.phase == "inner_cylinder" then
            for h = state.layer, PILLAR_H - 1 do
                local y = baseY + DISK_H + h
                local clockwise = ((h % 2) == 0) and state.cw0 or (not state.cw0)
                buildRingLayer(centerX, y, centerZ, INNER_R, clockwise, ("inner_cyl_y_%d"):format(y), state)
                state.layer = h + 1
                saveState(state)
                -- 次層へ上昇（buildRingLayer 終了後に上へ）
                if h < PILLAR_H - 1 then assert(tryUp(), "層間上昇に失敗") end
            end
            -- バンドル完了 → 次のバンドルへ（さらに上方向の開始なので下降不要）
            state.bundle = bundle + 1
            state.phase = "outer_disk"
            state.layer = 0
            state.innerLayer = 0
            state.pillarStarted = false
            saveState(state)
        end
    end
end

-- 実行
main()
