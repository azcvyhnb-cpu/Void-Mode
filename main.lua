-- Void Mode: Dual-AI Collaboration for Roblox
-- Two configurable OpenAI-compatible endpoints collaborate:
-- Model A plans -> Model B critiques/extends -> Model A synthesizes.
-- Credentials remain in memory for this session; never hard-code API keys here.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local env = (type(getgenv) == "function" and getgenv()) or _G

if env.VoidMode and env.VoidMode.gui then
    pcall(function() env.VoidMode.gui:Destroy() end)
end

local function requestHttp(url, headers, body)
    local payload = HttpService:JSONEncode(body)
    local req = request or http_request or (syn and syn.request) or (http and http.request)
    if type(req) == "function" then
        local res = req({
            Url = url,
            Method = "POST",
            Headers = headers,
            Body = payload
        })
        local code = tonumber(res.StatusCode or res.Status or 0) or 0
        local responseBody = res.Body or res.body or ""
        if code < 200 or code >= 300 then
            error("HTTP " .. tostring(code) .. ": " .. tostring(responseBody):sub(1, 1200))
        end
        return HttpService:JSONDecode(responseBody)
    end

    local res = HttpService:RequestAsync({
        Url = url,
        Method = "POST",
        Headers = headers,
        Body = payload
    })
    if not res.Success then
        error("HTTP " .. tostring(res.StatusCode) .. ": " .. tostring(res.Body):sub(1, 1200))
    end
    return HttpService:JSONDecode(res.Body)
end

local function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function chatCompletion(cfg, messages)
    local base = trim(cfg.base):gsub("/+$", "")
    if base == "" then error(cfg.label .. ": Base URL is empty") end
    if trim(cfg.model) == "" then error(cfg.label .. ": Model ID is empty") end
    local url = base
    if not url:match("/chat/completions$") then
        if not url:match("/v%d+$") then url = url .. "/v1" end
        url = url .. "/chat/completions"
    end

    local headers = { ["Content-Type"] = "application/json" }
    if trim(cfg.key) ~= "" then headers.Authorization = "Bearer " .. trim(cfg.key) end
    local result = requestHttp(url, headers, {
        model = trim(cfg.model),
        messages = messages,
        temperature = 0.4
    })
    local content = result and result.choices and result.choices[1]
        and result.choices[1].message and result.choices[1].message.content
    if type(content) ~= "string" or content == "" then
        error(cfg.label .. ": API response has no choices[1].message.content")
    end
    return content
end

local gui = Instance.new("ScreenGui")
gui.Name = "VoidModeDualAI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end

local frame = Instance.new("Frame")
frame.Name = "Window"
frame.Size = UDim2.new(0, 560, 0, 590)
frame.Position = UDim2.new(0.5, -280, 0.5, -295)
frame.BackgroundColor3 = Color3.fromRGB(20, 22, 29)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(82, 91, 120)
stroke.Thickness = 1
stroke.Parent = frame

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local title = make("TextLabel", {
    Size = UDim2.new(1, -60, 0, 38), Position = UDim2.new(0, 14, 0, 7),
    BackgroundTransparency = 1, Text = "VOID MODE  /  DUAL AI",
    TextColor3 = Color3.fromRGB(230, 235, 255), TextSize = 18,
    Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left
}, frame)

local close = make("TextButton", {
    Size = UDim2.new(0, 32, 0, 30), Position = UDim2.new(1, -42, 0, 8),
    Text = "X", TextSize = 16, Font = Enum.Font.GothamBold,
    TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = Color3.fromRGB(145, 55, 65),
    BorderSizePixel = 0
}, frame)
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local function label(text, x, y, w, parent)
    return make("TextLabel", {
        Position = UDim2.new(0, x, 0, y), Size = UDim2.new(0, w, 0, 18),
        BackgroundTransparency = 1, Text = text, TextColor3 = Color3.fromRGB(178, 188, 212),
        TextSize = 12, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left
    }, parent)
end

local function field(placeholder, x, y, w, parent, isSecret)
    local box = make("TextBox", {
        Position = UDim2.new(0, x, 0, y), Size = UDim2.new(0, w, 0, 30),
        BackgroundColor3 = Color3.fromRGB(34, 38, 49), BorderSizePixel = 0,
        Text = "", PlaceholderText = placeholder, PlaceholderColor3 = Color3.fromRGB(125, 135, 157),
        TextColor3 = Color3.fromRGB(240, 242, 250), TextSize = 12, Font = Enum.Font.Code,
        ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left
    }, parent)
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
    make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, box)
    if isSecret then box.TextTransparency = 0 end
    return box
end

label("MODEL A — Planner / Final synthesizer", 14, 50, 530, frame)
local aBase = field("Base URL (e.g. https://api.example.com/v1)", 14, 70, 532, frame)
local aKey = field("API key (optional for local endpoints)", 14, 106, 532, frame, true)
local aModel = field("Model A ID", 14, 142, 532, frame)

label("MODEL B — Reviewer / Specialist", 14, 180, 530, frame)
local bBase = field("Base URL (e.g. https://ai.thirx.com/v1)", 14, 200, 532, frame)
local bKey = field("API key (optional for local endpoints)", 14, 236, 532, frame, true)
local bModel = field("Model B ID", 14, 272, 532, frame)

label("TASK FOR BOTH MODELS", 14, 310, 530, frame)
local task = make("TextBox", {
    Position = UDim2.new(0, 14, 0, 331), Size = UDim2.new(0, 532, 0, 76),
    BackgroundColor3 = Color3.fromRGB(34, 38, 49), BorderSizePixel = 0,
    Text = "", PlaceholderText = "Describe the task. Model A will plan, Model B will review and extend, then Model A will combine the results.",
    PlaceholderColor3 = Color3.fromRGB(125, 135, 157), TextColor3 = Color3.fromRGB(240, 242, 250),
    TextSize = 13, Font = Enum.Font.Gotham, TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    ClearTextOnFocus = false, MultiLine = true
}, frame)
Instance.new("UICorner", task).CornerRadius = UDim.new(0, 5)
make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 7) }, task)

local run = make("TextButton", {
    Position = UDim2.new(0, 14, 0, 416), Size = UDim2.new(0, 532, 0, 34),
    BackgroundColor3 = Color3.fromRGB(92, 103, 190), BorderSizePixel = 0,
    Text = "RUN COLLABORATION (3 API CALLS)", TextColor3 = Color3.fromRGB(255,255,255),
    TextSize = 13, Font = Enum.Font.GothamBold
}, frame)
Instance.new("UICorner", run).CornerRadius = UDim.new(0, 6)

local status = make("TextLabel", {
    Position = UDim2.new(0, 14, 0, 454), Size = UDim2.new(0, 532, 0, 20),
    BackgroundTransparency = 1, Text = "Ready — configure both models first.",
    TextColor3 = Color3.fromRGB(180, 190, 215), TextSize = 11, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left
}, frame)

local output = make("TextBox", {
    Position = UDim2.new(0, 14, 0, 478), Size = UDim2.new(0, 532, 0, 96),
    BackgroundColor3 = Color3.fromRGB(13, 15, 20), BorderSizePixel = 0,
    Text = "", PlaceholderText = "Collaboration output will appear here.",
    TextColor3 = Color3.fromRGB(220, 228, 245), PlaceholderColor3 = Color3.fromRGB(115, 125, 145),
    TextSize = 12, Font = Enum.Font.Code, TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    ClearTextOnFocus = false, MultiLine = true
}, frame)
Instance.new("UICorner", output).CornerRadius = UDim.new(0, 5)
make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 7) }, output)

local busy = false
run.MouseButton1Click:Connect(function()
    if busy then return end
    local prompt = trim(task.Text)
    if prompt == "" then status.Text = "Enter a task first."; return end
    local A = { label = "Model A", base = aBase.Text, key = aKey.Text, model = aModel.Text }
    local B = { label = "Model B", base = bBase.Text, key = bKey.Text, model = bModel.Text }
    if trim(A.base) == "" or trim(A.model) == "" or trim(B.base) == "" or trim(B.model) == "" then
        status.Text = "Fill in both Base URLs and both Model IDs."; return
    end
    busy = true
    run.Text = "WORKING — PLEASE WAIT"
    output.Text = ""
    task.spawn(function()
        local ok, result = xpcall(function()
            status.Text = "1/3 — Model A is planning..."
            local plan = chatCompletion(A, {
                { role = "system", content = "You are Model A, the lead planner. Analyze the task, identify requirements, assumptions, risks, and propose a concrete solution. Be concise but useful." },
                { role = "user", content = prompt }
            })
            status.Text = "2/3 — Model B is reviewing and extending..."
            local review = chatCompletion(B, {
                { role = "system", content = "You are Model B, a collaborating specialist and critical reviewer. Inspect Model A's plan for errors, missing cases, risks, and improvements. Provide your own solution where useful. Do not merely agree." },
                { role = "user", content = "Original task:\n" .. prompt .. "\n\nModel A's plan:\n" .. plan .. "\n\nReview it independently, correct it, and add improvements." }
            })
            status.Text = "3/3 — Model A is combining both results..."
            local final = chatCompletion(A, {
                { role = "system", content = "You are the lead synthesizer. Combine your plan and Model B's critique into one accurate, actionable answer. Resolve disagreements explicitly. Do not claim unverified facts." },
                { role = "user", content = "Original task:\n" .. prompt .. "\n\nYour initial plan:\n" .. plan .. "\n\nModel B's review:\n" .. review .. "\n\nReturn the final collaborative result." }
            })
            return "=== MODEL A: PLAN ===\n" .. plan .. "\n\n=== MODEL B: REVIEW ===\n" .. review .. "\n\n=== JOINT FINAL ANSWER ===\n" .. final
        end, function(err) return tostring(err) end)
        if ok then
            output.Text = result
            status.Text = "Complete — 3 sequential API calls finished."
        else
            output.Text = "Collaboration failed:\n" .. tostring(result)
            status.Text = "Failed. Check Base URL, model IDs, key, API compatibility, and executor HTTP access."
        end
        busy = false
        run.Text = "RUN COLLABORATION (3 API CALLS)"
    end)
end)

env.VoidMode = {
    alive = true,
    gui = gui,
    close = function() if gui then gui:Destroy() end end,
}
warn("[Void Mode] UI ready. Configure two OpenAI-compatible Chat Completions endpoints.")
