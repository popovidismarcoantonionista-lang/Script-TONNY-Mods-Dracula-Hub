--[[
    TONNY MODZ — Loader
    Fluxo: valida key → baixa script.lua → executa
]]

local HttpService = game:GetService("HttpService")
local StarterGui  = game:GetService("StarterGui")

local CONFIG = {
    VALIDATE_URL = "https://tonnymodz-sfgx8kjw.manus.space/api/v1/keys/validate",
    SCRIPT_URL   = "https://raw.githubusercontent.com/popovidismarcoantonionista-lang/Script-TONNY-Mods-Dracula-Hub/refs/heads/main/script.lua",
    KEY          = "",  -- ou defina getgenv().TONNY_MODZ_KEY antes de rodar
    RETRIES      = 3,
    RETRY_WAIT   = 1.5,
    USER_AGENT   = "TonnyModz/Loader",
}

local function notify(text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "TONNY MODZ", Text = tostring(text), Duration = dur or 8,
        })
    end)
end

local function sleep(t) if task and task.wait then task.wait(t) else wait(t) end end

local function getRequest()
    return request or (syn and syn.request) or (http and http.request)
        or http_request or (fluxus and fluxus.request) or (krnl and krnl.request)
end

local function http(method, url, body, headers)
    local req = getRequest()
    if not req then return nil, "no_request" end
    local h = headers or {}
    h["Content-Type"] = h["Content-Type"] or "application/json"
    h["User-Agent"]   = h["User-Agent"]   or CONFIG.USER_AGENT
    local ok, res = pcall(function()
        return req({
            Url = url, Method = method, Headers = h,
            Body = body and HttpService:JSONEncode(body) or nil,
        })
    end)
    if not ok then return nil, tostring(res) end
    return res
end

local function decode(res)
    if not res then return nil end
    local b = res.Body or res.body
    if type(b) ~= "string" then return nil end
    local ok, d = pcall(function() return HttpService:JSONDecode(b) end)
    if ok then return d end
end

local function readFileSafe(p)
    local ok, r = pcall(function() return readfile(p) end)
    if ok and type(r) == "string" and #r > 0 then return r end
end
local function writeFileSafe(p, c) pcall(function() writefile(p, c) end) end

local function getDeviceId()
    for _, fn in ipairs({
        function() return gethwid and gethwid() end,
        function() return syn and syn.get_hwid and syn.get_hwid() end,
        function() return getgenv and getgenv().get_hwid and getgenv().get_hwid() end,
    }) do
        local ok, id = pcall(fn)
        if ok and type(id) == "string" and #id >= 8 then return id end
    end
    local ok, cid = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and type(cid) == "string" and #cid >= 8 then return cid end
    local path = "tonnymodz_device.txt"
    local saved = readFileSafe(path)
    if saved then return saved end
    local new = HttpService:GenerateGUID(false)
    writeFileSafe(path, new)
    return new
end

local ERROR_MSG = {
    invalid_key     = "Key inválida ou inexistente.",
    revoked_key     = "Esta key foi revogada.",
    expired_key     = "Esta key expirou.",
    device_mismatch = "Key vinculada a outro dispositivo.",
    invalid_request = "Requisição inválida.",
    network         = "Falha de conexão com o servidor.",
    rate_limited    = "Servidor ocupado. Tente novamente.",
    maintenance     = "Servidor em manutenção. Tente novamente em breve.",
    no_request      = "Executor sem função HTTP request.",
    bad_script      = "Falha ao baixar o script.",
    loadstring      = "Seu executor não possui loadstring.",
}

local function validate(key, deviceId)
    local last = "unknown"
    for attempt = 1, CONFIG.RETRIES do
        local res, err = http("POST", CONFIG.VALIDATE_URL, {
            key = key, deviceId = deviceId,
        })
        if not res then
            last = (err == "no_request") and "no_request" or "network"
        else
            local code = res.StatusCode or res.Status or 0
            local data = decode(res)
            local apiErr = data and data.error or nil
            if code == 200 and data and data.valid == true then
                return true, data
            end
            if code == 404 then return false, apiErr or "invalid_key" end
            if code == 403 then return false, apiErr or "revoked_key" end
            if code == 400 then return false, apiErr or "invalid_request" end
            if code == 429 then last = "rate_limited"
            elseif code >= 500 then last = "maintenance"
            else return false, apiErr or ("http_" .. tostring(code)) end
        end
        if attempt < CONFIG.RETRIES then sleep(CONFIG.RETRY_WAIT * attempt) end
    end
    return false, last
end

local function fetchScript()
    local last = "network"
    for attempt = 1, CONFIG.RETRIES do
        local res, err = http("GET", CONFIG.SCRIPT_URL)
        if res then
            local code = res.StatusCode or res.Status or 0
            if code == 200 then
                local body = res.Body or res.body
                if type(body) == "string" and #body > 0 then
                    return true, body
                end
                return false, "bad_script"
            elseif code == 429 then last = "rate_limited"
            elseif code >= 500 then last = "maintenance"
            else return false, "bad_script" end
        else
            last = (err == "no_request") and "no_request" or "network"
        end
        if attempt < CONFIG.RETRIES then sleep(CONFIG.RETRY_WAIT * attempt) end
    end
    return false, last
end

--// ---------------- main ----------------
if not getRequest() then
    warn("[TONNY MODZ] " .. ERROR_MSG.no_request)
    notify(ERROR_MSG.no_request, 10)
    return
end

local key = CONFIG.KEY
if (key == nil or key == "") and getgenv then
    key = getgenv().TONNY_MODZ_KEY or getgenv().TONNYMODZ_KEY or ""
end
if key == nil or key == "" then
    local m = "Nenhuma key informada. Defina CONFIG.KEY ou getgenv().TONNY_MODZ_KEY."
    warn("[TONNY MODZ] " .. m); notify(m, 10); return
end
key = tostring(key):gsub("%s", "")

local deviceId = getDeviceId()

local ok, result = validate(key, deviceId)
if not ok then
    local m = ERROR_MSG[result] or ("Falha na validação: " .. tostring(result))
    warn("[TONNY MODZ] " .. m); notify(m, 10); return
end

local texto
if result.expiresAt then
    texto = "Key válida! Expira em " .. tostring(result.expiresAt)
    if result.daysRemaining then
        texto = texto .. " (" .. tostring(result.daysRemaining) .. " dias)"
    end
else
    texto = "Key válida! (vitalícia)"
end
print("[TONNY MODZ] " .. texto); notify(texto, 8)

local okFetch, src = fetchScript()
if not okFetch then
    local m = ERROR_MSG[src] or ("Falha ao baixar o script (" .. tostring(src) .. ").")
    warn("[TONNY MODZ] " .. m); notify(m, 10); return
end

if getgenv then
    getgenv().TONNY_MODZ_KEY      = key
    getgenv().TONNY_MODZ_DEVICE   = deviceId
    getgenv().TONNY_MODZ_VALIDATE = CONFIG.VALIDATE_URL
end

local loader = loadstring or load
if not loader then
    warn("[TONNY MODZ] " .. ERROR_MSG.loadstring); notify(ERROR_MSG.loadstring, 10); return
end

local fn, err = loader(src)
if not fn then
    warn("[TONNY MODZ] Erro ao compilar: " .. tostring(err))
    notify("Erro ao compilar o script.", 8); return
end

local okRun, e = pcall(fn)
if not okRun then
    warn("[TONNY MODZ] Runtime: " .. tostring(e))
end
