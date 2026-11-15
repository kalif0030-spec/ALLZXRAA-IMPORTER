--[[
  ALLZXRAA LOADER v4 (gate permanen)
  Pemakaian:
    script_key = "KEY_DARI_DISCORD"   -- boleh dikosongkan, key bisa ditempel di panel
    loadstring(game:HttpGet("https://raw.githubusercontent.com/kalif0030-spec/ALLZXRAA-IMPORTER/refs/heads/main/loader.lua"))()
]]

local BASE_URL = "https://tion-aged-players-patients.trycloudflare.com" -- tanpa slash di akhir
local INVITE   = "https://discord.gg/azmNAbHb2"                                                    -- link Discord (boleh kosong)
local RECHECK_SECONDS = 15

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local WARN_COL = Color3.fromRGB(255, 190, 80)
local ERR_COL  = Color3.fromRGB(255, 95, 95)
local ACCENT   = Color3.fromRGB(143, 211, 255)
local PANEL    = Color3.fromRGB(18, 24, 34)
local FIELD    = Color3.fromRGB(28, 36, 48)
local MUTED    = Color3.fromRGB(150, 160, 175)

local MSG = {
    bad_script   = {"Script gagal dimuat", "Script dari server tidak bisa dibaca. Hubungi admin.", ERR_COL},
    no_request   = {"Executor tidak didukung", "Executor kamu tidak punya fungsi request().", ERR_COL},
    offline      = {"Server tidak bisa dihubungi", "Server verifikasi sedang offline atau link berubah. Coba lagi nanti.", ERR_COL},
}

local rq = request or http_request or (syn and syn.request)
local loaded = false
local gate          -- {gui, box, status}
local lastKey = ""

------------------------------------------------------------ helper GUI
local function getParent()
    local p
    local gh = gethui or (getgenv and getgenv().gethui)
    if type(gh) == "function" then pcall(function() p = gh() end) end
    if not p then pcall(function() p = game:GetService("CoreGui") end) end
    if not p and LocalPlayer then
        p = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 10)
    end
    return p
end

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(o, r)
    new("UICorner", {CornerRadius = UDim.new(0, r or 10)}, o)
end

local function button(parent, text, pos, size, color, onClick)
    local b = new("TextButton", {
        Size = size, Position = pos, BackgroundColor3 = color,
        TextColor3 = Color3.fromRGB(15, 20, 28), Font = Enum.Font.GothamBold,
        TextSize = 14, Text = text, AutoButtonColor = true, BorderSizePixel = 0,
    }, parent)
    corner(b, 8)
    b.Activated:Connect(onClick)
    return b
end

-- Logo peringatan: ketupat kuning dengan tanda "!"
local function warningIcon(parent, col)
    local box = new("Frame", {
        Size = UDim2.fromOffset(56, 56), Position = UDim2.fromOffset(20, 20),
        BackgroundTransparency = 1, BorderSizePixel = 0,
    }, parent)
    local diamond = new("Frame", {
        Size = UDim2.fromOffset(40, 40), Position = UDim2.new(0.5, -20, 0.5, -20),
        BackgroundColor3 = col, BorderSizePixel = 0, Rotation = 45,
    }, box)
    corner(diamond, 6)
    new("TextLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Text = "!", Font = Enum.Font.GothamBlack, TextSize = 30,
        TextColor3 = Color3.fromRGB(18, 24, 34), ZIndex = 2,
    }, box)
end

local function setStatus(g, text, col)
    if g and g.status and g.status.Parent then
        g.status.Text = text
        g.status.TextColor3 = col or ACCENT
    end
end

------------------------------------------------------------ gate permanen
local function closeGate()
    if gate and gate.gui then pcall(function() gate.gui:Destroy() end) end
    gate = nil
end

local function buildGate()
    local parent = getParent()
    if not parent then return nil end

    local gui = new("ScreenGui", {
        Name = "ALLZXRAA_Gate", ResetOnSpawn = false,
        DisplayOrder = 1000, IgnoreGuiInset = true,
    })

    -- lapisan gelap yang menelan klik supaya tidak tembus ke game
    new("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.35, BorderSizePixel = 0, Active = true,
    }, gui)

    local frame = new("Frame", {
        Size = UDim2.fromOffset(440, 330), Position = UDim2.new(0.5, -220, 0.5, -165),
        BackgroundColor3 = PANEL, BorderSizePixel = 0, Active = true,
    }, gui)
    corner(frame, 12)
    new("UIStroke", {Color = WARN_COL, Thickness = 2}, frame)

    warningIcon(frame, WARN_COL)

    new("TextLabel", {
        Size = UDim2.new(1, -100, 0, 30), Position = UDim2.fromOffset(88, 30),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 18,
        TextColor3 = WARN_COL, TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Akses Belum Aktif",
    }, frame)

    new("TextLabel", {
        Size = UDim2.new(1, -40, 0, 84), Position = UDim2.fromOffset(20, 88),
        BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 13,
        TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = ACCENT,
        Text = "Script ini hanya bisa dipakai setelah akun kamu terverifikasi.\n"
            .. "1. Join server Discord" .. ((INVITE ~= "") and (" (" .. INVITE .. ")") or "") .. "\n"
            .. "2. Ketik /verify <username Roblox>\n"
            .. "3. Tempel key yang diberikan di kolom bawah",
    }, frame)

    local box = new("TextBox", {
        Size = UDim2.new(1, -40, 0, 36), Position = UDim2.fromOffset(20, 180),
        BackgroundColor3 = FIELD, BorderSizePixel = 0, ClearTextOnFocus = false,
        Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = ACCENT,
        PlaceholderText = "Tempel key di sini", PlaceholderColor3 = MUTED,
        Text = lastKey, TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)
    corner(box, 8)
    new("UIPadding", {PaddingLeft = UDim.new(0, 10)}, box)

    local status = new("TextLabel", {
        Size = UDim2.new(1, -40, 0, 20), Position = UDim2.fromOffset(20, 224),
        BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, Text = "Belum diverifikasi.",
    }, frame)

    local g = {gui = gui, box = box, status = status}

    button(frame, "Verifikasi", UDim2.fromOffset(20, 256), UDim2.fromOffset(150, 34), ACCENT, function()
        g.tryFn(g)
    end)
    button(frame, "Salin link Discord", UDim2.fromOffset(180, 256), UDim2.fromOffset(240, 34), ACCENT, function()
        if INVITE == "" then
            setStatus(g, "Link Discord belum diatur. Hubungi admin.", WARN_COL)
        elseif type(setclipboard) == "function" then
            pcall(setclipboard, INVITE)
            setStatus(g, "Link Discord disalin. Buka Discord lalu join.", ACCENT)
        else
            setStatus(g, "Salin manual: " .. INVITE, ACCENT)
        end
    end)

    new("TextLabel", {
        Size = UDim2.new(1, -40, 0, 20), Position = UDim2.new(0, 20, 1, -28),
        BackgroundTransparency = 1, Font = Enum.Font.Gotham, TextSize = 11,
        TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Panel ini tetap tampil sampai akun terverifikasi.",
    }, frame)

    box.FocusLost:Connect(function() lastKey = box.Text end)

    gui.Parent = parent
    return g
end

------------------------------------------------------------ jaringan
local function postLoad(key, uid)
    local body = HttpService:JSONEncode({uid = uid, key = key})
    for attempt = 1, 2 do
        local ok, res = pcall(rq, {
            Url = BASE_URL .. "/load",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = body,
        })
        if ok and type(res) == "table" then
            local code = tonumber(res.StatusCode or res.Status) or 0
            if code == 429 and attempt == 1 then
                task.wait(3.5)
            else
                return code, res
            end
        elseif attempt == 1 then
            task.wait(1.5)
        end
    end
    return nil, nil
end

local function decodeCode(res)
    local ok, data = pcall(function() return HttpService:JSONDecode(tostring(res.Body or "")) end)
    if ok and type(data) == "table" and type(data.code) == "string" then return data.code end
    return nil
end

-- kembalikan: "ok", res | "offline" | "not_verified" | "wrong_key" | "cooldown" | "server_error"
local function checkKey(key, uid)
    local code, res = postLoad(key, uid)
    if not code then return "offline" end
    if code == 200 then return "ok", res end
    if code == 403 then
        return decodeCode(res) == "not_verified" and "not_verified" or "wrong_key"
    end
    if code == 429 then return "cooldown" end
    return "server_error"
end

------------------------------------------------------------ muat script utama
local function loadMain(src)
    if src == "" then return false end
    local fn, err = loadstring(src)
    if not fn then
        warn("[ALLZXRAA] loadstring: " .. tostring(err))
        return false
    end
    loaded = true
    closeGate()
    local okRun, runErr = pcall(fn)
    if not okRun then warn("[ALLZXRAA] runtime: " .. tostring(runErr)) end
    return true
end

local STATUS_TEXT = {
    offline      = {"Server tidak bisa dihubungi. Akan dicek ulang otomatis.", ERR_COL},
    not_verified = {"Belum verifikasi. Jalankan /verify di Discord dulu.", WARN_COL},
    wrong_key    = {"Key salah. Pakai key terbaru dari /verify.", ERR_COL},
    cooldown     = {"Terlalu sering, tunggu sebentar.", WARN_COL},
    server_error = {"Server error. Akan dicek ulang otomatis.", ERR_COL},
}

local function tryKey(g, key)
    local uid = LocalPlayer.UserId
    if key == "" then
        setStatus(g, "Isi key dulu.", WARN_COL)
        return
    end
    lastKey = key
    setStatus(g, "Mengecek...", ACCENT)
    local st, res = checkKey(key, uid)
    if st == "ok" then
        if not loadMain(tostring(res.Body or "")) then
            setStatus(g, "Script dari server tidak bisa dibaca. Hubungi admin.", ERR_COL)
        end
        return
    end
    local t = STATUS_TEXT[st] or STATUS_TEXT.server_error
    setStatus(g, t[1], t[2])
end

------------------------------------------------------------ alur utama
local function ensureGate()
    if loaded then return end
    if gate and gate.gui and gate.gui.Parent then return end
    gate = buildGate()
    if gate then gate.tryFn = function(g) tryKey(g, g.box.Text) end end
end

local function gateLoop()
    -- cek diam-diam dulu kalau script_key sudah diisi dan benar
    if lastKey ~= "" then
        local st, res = checkKey(lastKey, LocalPlayer.UserId)
        if st == "ok" and loadMain(tostring(res.Body or "")) then return end
    end

    while not loaded do
        ensureGate()          -- panel dibangun ulang kalau player menutupnya
        if gate and not loaded and gate.box.Text ~= "" then
            tryKey(gate, gate.box.Text)
        end
        for _ = 1, RECHECK_SECONDS * 2 do
            if loaded then break end
            task.wait(0.5)
        end
    end
end

if not rq then
    -- tanpa request() tidak ada yang bisa dilakukan, tampilkan pesan sekali saja
    warn("[ALLZXRAA] Executor tidak punya request().")
    return
end

do
    local key = (getgenv and getgenv().script_key) or script_key
    lastKey = (type(key) == "string") and key or ""
end

task.spawn(gateLoop)
a
