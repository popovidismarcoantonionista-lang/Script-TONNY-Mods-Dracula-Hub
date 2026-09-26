--[[
    TONNY MODZ — Script protegido (gate) + entrega via Dracula Hub
    Hospedagem: https://raw.githubusercontent.com/popovidismarcoantonionista-lang/Script-TONNY-Mods-Dracula-Hub/refs/heads/main/script.lua
]]

--// ============================================================
--// AUTO-VALIDAÇÃO TONNY MODZ
--// ============================================================
do
    local HttpService = game:GetService("HttpService")
    local g = getgenv and getgenv() or _G

    local key      = g.TONNY_MODZ_KEY
    local deviceId = g.TONNY_MODZ_DEVICE
    local url      = g.TONNY_MODZ_VALIDATE
        or "https://tonnymodz-sfgx8kjw.manus.space/api/v1/keys/validate"

    if not key or not deviceId then
        warn("[TONNY MODZ] Script executado fora do loader. Abortando.")
        return
    end

    local req = request or (syn and syn.request) or (http and http.request)
        or http_request or (fluxus and fluxus.request) or (krnl and krnl.request)
    if not req then
        warn("[TONNY MODZ] Sem função HTTP request. Abortando.")
        return
    end

    local ok, res = pcall(function()
        return req({
            Url     = url,
            Method  = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["User-Agent"]   = "TonnyModz/Script",
            },
            Body = HttpService:JSONEncode({ key = key, deviceId = deviceId }),
        })
    end)

    if not ok or not res then
        warn("[TONNY MODZ] Revalidação falhou (rede). Abortando.")
        return
    end

    local code = res.StatusCode or res.Status or 0
    local data
    pcall(function() data = HttpService:JSONDecode(res.Body) end)

    if code ~= 200 or not data or data.valid ~= true then
        local err = data and data.error or ("http_" .. tostring(code))
        warn("[TONNY MODZ] Revalidação negada (" .. tostring(err) .. "). Abortando.")
        return
    end

    g.TONNY_MODZ_EXPIRES = data.expiresAt
    g.TONNY_MODZ_DAYS    = data.daysRemaining
end

--// ============================================================
--// DRACULA HUB LOADER — challenge atualizado
--// ============================================================
local H   = game:GetService("HttpService")
local _ct = "pqLCF5SdWn3u1_hHFHsechlJRTSiiYBJOXroGqVgJk8"
local _n  = "636201b583aa7d52c4431cd6f389af60"
local _ts = "1790464159"
local _r
local _req = request
    or (syn and syn.request)
    or (http and http.request)
    or http_request
    or (fluxus and fluxus.request)

if _req then
    for i = 1, 3 do
        local ok, res = pcall(function()
            return _req({
                Url     = "https://draculahub.xyz/get_script",
                Method  = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["X-Challenge"]  = _ct,
                    ["User-Agent"]   = "DraculaHub/Loader",
                },
                Body = H:JSONEncode({ ct = _ct, n = _n, ts = _ts }),
            })
        end)
        _r = res
        if ok and _r and type(_r) == "table"
            and (_r.StatusCode == 200 or _r.StatusCode == 403 or _r.StatusCode == 500) then
            break
        end
        if task and task.wait then task.wait(1 + (i * 1.5)) else wait(1 + (i * 1.5)) end
    end
end

if _r and _r.StatusCode == 200 then
    local _d = H:JSONDecode(_r.Body)
    if _d and _d.p then
        local _k = _d.k
        local _e = _d.p

        local _bx = (bit32 and bit32.bxor) or (bit and bit.bxor) or function(a, b)
            local p, c = 1, 0
            while a > 0 and b > 0 do
                local ra, rb = a % 2, b % 2
                if ra ~= rb then c = c + p end
                a, b, p = math.floor((a - ra) / 2), math.floor((b - rb) / 2), p * 2
            end
            if a > 0 then c = c + a * p end
            if b > 0 then c = c + b * p end
            return c
        end

        local _dec = {}
        for i = 1, #_e, 2 do
            local _b = tonumber(_e:sub(i, i + 1), 16)
            if _b then
                local _kb = string.byte(_k, ((math.floor((i - 1) / 2)) % #_k) + 1)
                table.insert(_dec, string.char(_bx(_b, _kb)))
            end
        end

        local _code = table.concat(_dec)
        _dec = nil; _e = nil; _k = nil

        local fn, err = loadstring(_code)
        _code = nil
        if collectgarbage then pcall(collectgarbage, "collect") end
        if fn then fn() else warn(err) end
    end
else
    local _sc = (_r and _r.StatusCode) or 0
    local _msg = "Failed to connect to Dracula Hub server."
    if _sc == 429 then
        _msg = "Server busy (Rate limited). Please wait a moment and re-execute."
    elseif _sc == 403 then
        _msg = "Connection rejected. Please retry or disable proxy/VPN."
    elseif _sc >= 500 then
        _msg = "Dracula Hub server is undergoing maintenance. Please retry shortly."
    elseif not _req then
        _msg = "Your executor lacks HTTP request functions (request/http_request)."
    end
    warn("[Dracula Hub] " .. _msg .. " (Code: " .. tostring(_sc) .. ")")
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Dracula Hub", Text = _msg, Duration = 8,
        })
    end)
end
