local m = peripheral.wrap("right")
local w, h = m.getSize()
local randHash = {}
m.clear()
m.setTextScale(0.5)
m.setCursorBlink(false)

-- 初期化
for y = 1, h+1 do
    randHash[y] = {}
    for x = 1, w+1 do
        randHash[y][x] = math.random()
    end
end

local function lerp(a,b,t) return a + (b - a) * t end
local function smoothstep(t) return t*t*(3 - 2*t) end

local function get(x, y)
    x = (x - 1) % (w + 1) + 1
    y = (y - 1) % (h + 1) + 1
    return randHash[y][x]
end

local function noise(x, y)
    local ix, iy = math.floor(x), math.floor(y)
    local fx, fy = x - ix, y - iy

    local v00 = get(ix, iy)
    local v10 = get(ix + 1, iy)
    local v01 = get(ix, iy + 1)
    local v11 = get(ix + 1, iy + 1)

    local u = smoothstep(fx)
    local v = smoothstep(fy)

    local nx0 = lerp(v00, v10, u)
    local nx1 = lerp(v01, v11, u)
    return lerp(nx0, nx1, v)
end

-- アニメーションループ
local frame = 0
while true do
    frame = frame + 0.1
    for y = 1, h do
        for x = 1, w do
            local n = noise(x/5 + frame, y/5)
            m.setCursorPos(x,y)
            if n < 0.3 then
                m.write(".")
            elseif n < 0.6 then
                m.write("#")
            else
                m.write("@")
            end
        end
    end
    sleep(0.1)
end
