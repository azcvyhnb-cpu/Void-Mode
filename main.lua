-- Void Mode for Project UAI
-- Loads the upstream UAI client, then applies a persistent long-running profile.
-- Provider credentials are entered in UAI -> Providers; this script never embeds keys.

local UAI_URL = "https://raw.githubusercontent.com/Project-Ptolemy/ProjectUAI/main/dist/uai.lua"

local function getEnvironment()
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then return env end
    end
    return _G
end

local env = getEnvironment()
local client = env.UAI

if not (type(client) == "table" and client.alive) then
    local ok, source = pcall(function()
        return game:HttpGet(UAI_URL)
    end)
    if not ok or type(source) ~= "string" or source == "" then
        error("[Void Mode] Could not download Project UAI: " .. tostring(source))
    end

    local compile, compileError = loadstring(source)
    if type(compile) ~= "function" then
        error("[Void Mode] Could not compile Project UAI: " .. tostring(compileError))
    end

    local ran, result = pcall(compile, { reuse = true })
    if not ran then
        -- Some executor environments expect the downloaded chunk to be called
        -- without an options table. Report the original error if both fail.
        local fallback, fallbackError = pcall(compile)
        if not fallback then
            error("[Void Mode] Project UAI failed to start: " .. tostring(fallbackError or result))
        end
        result = fallback
    end
    if type(result) == "table" and result.alive then
        client = result
    else
        client = env.UAI
    end
end

if type(client) ~= "table" or not client.alive or type(client.config) ~= "table" then
    error("[Void Mode] UAI started without the expected public config API. Update Project UAI and retry.")
end

local profile = {
    ["agent.unlimitedTurns"] = true,
    ["agent.requestUnlimited"] = true,
    ["agent.subagentUnlimited"] = true,
}

for path, value in pairs(profile) do
    client.config.set(path, value)
end
if type(client.config.save) == "function" then
    client.config.save()
end

env.VoidMode = {
    alive = true,
    client = client,
    disable = function()
        -- Disabling the profile restores UAI's normal configurable behavior.
        client.config.set("agent.unlimitedTurns", false)
        client.config.set("agent.requestUnlimited", false)
        client.config.set("agent.subagentUnlimited", false)
        if type(client.config.save) == "function" then client.config.save() end
        env.VoidMode = nil
        return true
    end,
    openProviders = function()
        return client.show("providers")
    end,
}

pcall(function() client.show("providers") end)
warn("[Void Mode] Enabled. Configure Base URL, API key, protocol, and model in UAI -> Providers.")
warn("[Void Mode] This removes UAI's turn/request-budget switches; provider, executor, and network limits still apply.")

return env.VoidMode
