-- Wrap monitor on the right side
local mon = peripheral.wrap("right")
mon.setTextScale(0.5)

-- Get monitor dimensions
local w, h = mon.getSize()

-- Server and request setup
local apiUrl = "https://image-to-string-for-cc.onrender.com/getStringData"
local imageUrl = "https://upload.wikimedia.org/wikipedia/commons/3/3f/Fronalpstock_big.jpg"
local requestBody = string.format('{"imageURL":"%s","w":%d,"h":%d}', imageUrl, w, h)
local requestHeaders = { ["Content-Type"] = "application/json" }

-- Split string by spaces into rows
local function splitBySpace(str)
    local t = {}
    for word in string.gmatch(str, "%S+") do table.insert(t, word) end
    return t
end

-- Split string into individual characters
local function splitByChar(str)
    local t = {}
    for c in string.gmatch(str, ".") do table.insert(t, c) end
    return t
end

-- Convert hex digit (as string) to CC color number
local function hexToColor(hexChar)
    local number = tonumber(hexChar, 16)
    return math.pow(2, number)
end

-- Draw one row of pixels on the monitor
local function drawRow(rowString, y)
    local chars = splitByChar(rowString)
    for x = 1, #chars do
        local color = hexToColor(chars[x])
        mon.setCursorPos(x, y)
        mon.setBackgroundColor(color)
        mon.write(" ")
    end
end

-- Draw full image from server response
local function drawImageFromResponse(serverResponse)
    local rows = splitBySpace(serverResponse)
    for y = 1, #rows do
        drawRow(rows[y], y)
    end
end

-- Send request and draw image
local function fetchAndDraw()
    local ok, res = http.post(apiUrl, requestBody, requestHeaders)

    if not ok then
        print("HTTP request failed!", res)
        return
    end

    if type(res) == "table" then
        -- 同期でレスポンスが返った場合
        local response = res.readAll()
        res.close()
        drawImageFromResponse(response)
        print("Response received (sync).")
    else
        -- res はリクエストID → イベントを待つ
        local id = res
        while true do
            local event, p1, p2 = os.pullEvent()
            if event == "http_success" and p1 == id then
                local response = p2.readAll()
                p2.close()
                drawImageFromResponse(response)
                print("Response received (async).")
                break
            elseif event == "http_failure" and p1 == id then
                print("HTTP request failed (async):", p2)
                break
            end
        end
    end
end

-- Main execution
fetchAndDraw()
