-- Loader publik (taruh di LOADER_URL). Script asli tidak ada di sini; diambil dari server bot setelah key dicek.
local GATE_URL = "https://loader.lolhuman.web.id/script"
local DISCORD_LINK = "https://discord.gg/3tyxaCyNH"  -- link invite yang ditampilkan di panel

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local RED = Color3.fromRGB(255, 120, 120)
local WHITE = Color3.fromRGB(225, 225, 230)
local BLURPLE = Color3.fromRGB(88, 101, 242)
local GREY = Color3.fromRGB(60, 60, 70)

-- ---------------------------------------------------------------- helper GUI
local function mount(gui)
    local candidates = {
        function() return type(gethui) == "function" and gethui() or nil end,
        function() return game:GetService("CoreGui") end,
        function()
            local lp = Players.LocalPlayer
            return lp and lp:FindFirstChildOfClass("PlayerGui") or nil
        end,
    }
    for _, get in ipairs(candidates) do
        local okGet, parent = pcall(get)
        if okGet and parent then
            local okSet = pcall(function() gui.Parent = parent end)
            if okSet and gui.Parent == parent then return true end
        end
    end
    return false
end

local function newGui(blockInput)
    local gui = Instance.new("ScreenGui")
    gui.Name = "ALLZXRAA_Notice"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    if blockInput then
        local backdrop = Instance.new("Frame")
        backdrop.Size = UDim2.new(1, 0, 1, 0)
        backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
        backdrop.BackgroundTransparency = 0.35
        backdrop.BorderSizePixel = 0
        backdrop.Active = true -- menelan sentuhan/klik ke UI di bawahnya
        backdrop.ZIndex = 1
        backdrop.Parent = gui
    end
    return gui
end

local function newFrame(gui, height)
    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.Size = UDim2.new(0, 340, 0, height)
    frame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    frame.BorderSizePixel = 0
    frame.ZIndex = 2
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    return frame
end

local function newLabel(parent, text, y, h, size, color, font)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Position = UDim2.new(0, 12, 0, y)
    l.Size = UDim2.new(1, -24, 0, h)
    l.Font = font or Enum.Font.Gotham
    l.TextSize = size
    l.TextWrapped = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Top
    l.TextColor3 = color
    l.Text = text
    l.Parent = parent
    return l
end

local function newButton(parent, text, x, w, y, color)
    local b = Instance.new("TextButton")
    b.Position = UDim2.new(x, x == 0 and 12 or 6, 0, y)
    b.Size = UDim2.new(w, w == 1 and -24 or -18, 0, 38)
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 13
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Text = text
    b.AutoButtonColor = true
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    return b
end

local function newBox(parent, placeholder, y)
    local b = Instance.new("TextBox")
    b.Position = UDim2.new(0, 12, 0, y)
    b.Size = UDim2.new(1, -24, 0, 34)
    b.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
    b.BorderSizePixel = 0
    b.Font = Enum.Font.Gotham
    b.TextSize = 13
    b.TextColor3 = WHITE
    b.PlaceholderText = placeholder
    b.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
    b.Text = ""
    b.ClearTextOnFocus = false
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    Instance.new("UIPadding", b).PaddingLeft = UDim.new(0, 8)
    return b
end

local function wireCopy(btn)
    btn.MouseButton1Click:Connect(function()
        if type(setclipboard) == "function" and pcall(setclipboard, DISCORD_LINK) then
            btn.Text = "Tersalin"
        else
            btn.Text = DISCORD_LINK
            btn.TextScaled = true
        end
    end)
end

-- panel info biasa (bisa ditutup) untuk error teknis
local function showNotice(title, message)
    warn("[ALLZXRAA] " .. message)
    pcall(function()
        local gui = newGui(false)
        local frame = newFrame(gui, 176)
        newLabel(frame, title, 8, 26, 16, RED, Enum.Font.GothamBold)
        newLabel(frame, message, 38, 78, 13, WHITE)
        local close
        if DISCORD_LINK ~= "" then
            wireCopy(newButton(frame, "Salin link Discord", 0, 0.5, 124, BLURPLE))
            close = newButton(frame, "Tutup", 0.5, 0.5, 124, GREY)
        else
            close = newButton(frame, "Tutup", 0, 1, 124, GREY)
        end
        close.MouseButton1Click:Connect(function() gui:Destroy() end)
        if mount(gui) then
            task.delay(30, function() if gui.Parent then gui:Destroy() end end)
        end
    end)
end

-- ---------------------------------------------------------------- data awal
if GATE_URL == "" then warn("[ALLZXRAA] GATE_URL belum diisi di loader.lua"); return end

local env = (type(getgenv) == "function" and getgenv()) or _G
local presetKey = env.script_key or _G.script_key
if type(presetKey) ~= "string" or presetKey == "" then presetKey = nil end
local presetName = env.script_name or _G.script_name  -- nama script (kosong = "default")
if type(presetName) ~= "string" or presetName == "" then presetName = nil end

local uid = Players.LocalPlayer and Players.LocalPlayer.UserId
if type(uid) ~= "number" or uid <= 0 then
    showNotice("Error", "UserId tidak terbaca. Coba jalankan lagi setelah karakter dimuat.")
    return
end

-- ---------------------------------------------------------------- minta script ke server bot
local httpRequest = (syn and syn.request) or http_request or request

-- return body | nil, jenis ("banned"|"denied"|"notfound"|"unavailable"|"error"), info (sisa percobaan)
local function requestScript(key, name)
    if not httpRequest then
        local url = GATE_URL .. "?uid=" .. tostring(uid) .. "&key=" .. HttpService:UrlEncode(key)
            .. (name and ("&name=" .. HttpService:UrlEncode(name)) or "")
        local okGet, body = pcall(game.HttpGet, game, url)
        if okGet and type(body) == "string" and #body > 0 then return body end
        return nil, "error"
    end
    local ok, res = pcall(httpRequest, {
        Url = GATE_URL, Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode({uid = tostring(uid), key = key, name = name}),
    })
    if not ok or type(res) ~= "table" then return nil, "unavailable" end
    local code, text = res.StatusCode, tostring(res.Body or "")
    if code == 200 then return res.Body end
    if code == 403 then
        if text:sub(1, 6) == "banned" then return nil, "banned" end
        if text:sub(1, 3) == "vip" then return nil, "vip" end
        return nil, "denied", tonumber(text:match("^denied:(%d+)"))
    end
    if code == 404 then return nil, "notfound" end
    return nil, "unavailable", code
end

local function runScript(body)
    local fn, perr = loadstring(body)
    if not fn then showNotice("Error", "Script tidak bisa dikompilasi: " .. tostring(perr)); return end
    local okRun, runErr = pcall(fn)
    if not okRun then warn("[ALLZXRAA] script error: " .. tostring(runErr)) end
end

local function deniedText(left)
    if left then
        return "Key salah. Sisa percobaan: " .. tostring(left) .. ". Kalau habis, akunmu otomatis dibanned."
    end
    return "Key salah atau akunmu belum terverifikasi."
end

-- ---------------------------------------------------------------- layar banned (permanen, merah, bergetar)
local SHAKE = 50  -- getaran maksimal dalam piksel; kecilkan kalau terlalu keras

local showBanned
function showBanned()
    warn("[ALLZXRAA] akun terbanned")
    pcall(function()
        local gui = newGui(false)

        local root = Instance.new("Frame") -- dasar merah, juga menelan sentuhan ke UI di bawahnya
        root.Size = UDim2.new(1, 0, 1, 0)
        root.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        root.BackgroundTransparency = 0.25
        root.BorderSizePixel = 0
        root.Active = true
        root.ZIndex = 1
        root.Parent = gui

        local shaker = Instance.new("Frame") -- isi yang ikut bergetar
        shaker.Size = UDim2.new(1, 0, 1, 0)
        shaker.BackgroundTransparency = 1
        shaker.ZIndex = 2
        shaker.Parent = root

        local bars = {} -- garis glitch acak
        for i = 1, 7 do
            local bar = Instance.new("Frame")
            bar.Size = UDim2.new(1, 60, 0, 4)
            bar.Position = UDim2.new(0, -30, math.random(), 0)
            bar.BackgroundColor3 = (i % 2 == 0) and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(40, 0, 0)
            bar.BackgroundTransparency = 0.6
            bar.BorderSizePixel = 0
            bar.ZIndex = 2
            bar.Parent = shaker
            bars[#bars + 1] = bar
        end

        local icon = Instance.new("TextLabel")
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.Position = UDim2.new(0.5, 0, 0.38, 0)
        icon.Size = UDim2.new(0, 170, 0, 170)
        icon.BackgroundTransparency = 1
        icon.Font = Enum.Font.GothamBold
        icon.TextSize = 120
        icon.TextColor3 = Color3.fromRGB(255, 225, 60)
        icon.Text = "\u{26A0}\u{FE0F}"
        icon.ZIndex = 3
        icon.Parent = shaker

        local title = Instance.new("TextLabel")
        title.AnchorPoint = Vector2.new(0.5, 0.5)
        title.Position = UDim2.new(0.5, 0, 0.6, 0)
        title.Size = UDim2.new(0.9, 0, 0, 34)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.TextSize = 26
        title.TextColor3 = Color3.new(1, 1, 1)
        title.Text = "HIHUUU!!!"
        title.ZIndex = 3
        title.Parent = shaker

        local msg = Instance.new("TextLabel")
        msg.AnchorPoint = Vector2.new(0.5, 0)
        msg.Position = UDim2.new(0.5, 0, 0.66, 0)
        msg.Size = UDim2.new(0.86, 0, 0, 52)
        msg.BackgroundTransparency = 1
        msg.Font = Enum.Font.GothamMedium
        msg.TextSize = 16
        msg.TextWrapped = true
        msg.TextColor3 = Color3.new(1, 1, 1)
        msg.Text = "Akun anda terbanned. Silahkan lapor ke owner untuk membuka."
        msg.ZIndex = 3
        msg.Parent = shaker

        if DISCORD_LINK ~= "" then -- tombol tidak ikut bergetar supaya mudah ditekan
            local btn = newButton(root, "Salin link Discord (lapor ke owner)", 0, 1, 0, BLURPLE)
            btn.AnchorPoint = Vector2.new(0.5, 0)
            btn.Position = UDim2.new(0.5, 0, 0.84, 0)
            btn.Size = UDim2.new(0, 280, 0, 40)
            btn.ZIndex = 5
            wireCopy(btn)
        end

        if not mount(gui) then warn("[ALLZXRAA] panel tidak bisa ditampilkan di executor ini"); return end

        task.spawn(function()
            while gui.Parent do
                shaker.Position = UDim2.new(0, math.random(-SHAKE, SHAKE), 0, math.random(-SHAKE, SHAKE))
                icon.Rotation = math.random(-10, 10)
                icon.Position = UDim2.new(0.5, math.random(-8, 8), 0.38, math.random(-8, 8))
                root.BackgroundTransparency = 0.2 + math.random() * 0.2 -- kedip merah
                for _, bar in ipairs(bars) do
                    if math.random() < 0.35 then
                        bar.Position = UDim2.new(0, -30, math.random(), 0)
                        bar.Size = UDim2.new(1, 60, 0, math.random(2, 14))
                        bar.BackgroundTransparency = 0.5 + math.random() * 0.4
                    end
                end
                task.wait(0.04)
            end
        end)
    end)
end

-- ---------------------------------------------------------------- panel input key (permanen sampai berhasil / banned)
local function showGate(message, keyText, nameText)
    pcall(function()
        local gui = newGui(true)
        local frame = newFrame(gui, 276)
        newLabel(frame, "Verifikasi diperlukan", 8, 26, 16, RED, Enum.Font.GothamBold)
        newLabel(frame, message, 36, 52, 13, WHITE)
        local keyBox = newBox(frame, "Tempel key dari Discord", 92)
        local nameBox = newBox(frame, "Nama script (kosong = default)", 134)
        if keyText then keyBox.Text = keyText end
        if nameText then nameBox.Text = nameText end
        local status = newLabel(frame, "", 176, 40, 12, Color3.fromRGB(255, 190, 120))
        local submit
        if DISCORD_LINK ~= "" then
            submit = newButton(frame, "Masuk", 0, 0.5, 222, Color3.fromRGB(46, 160, 90))
            wireCopy(newButton(frame, "Salin link Discord", 0.5, 0.5, 222, BLURPLE))
        else
            submit = newButton(frame, "Masuk", 0, 1, 222, Color3.fromRGB(46, 160, 90))
        end

        local busy = false
        submit.MouseButton1Click:Connect(function()
            if busy then return end
            local k = (keyBox.Text or ""):gsub("%s+", "")
            if k == "" then status.Text = "Isi key dulu."; return end
            local nm = (nameBox.Text or ""):gsub("%s+", ""):lower()
            if nm == "" then nm = nil end
            busy = true
            submit.Text = "Memeriksa..."
            local body, kind, info = requestScript(k, nm)
            busy = false
            submit.Text = "Masuk"
            if body then
                gui:Destroy()
                task.spawn(runScript, body)
            elseif kind == "banned" then
                gui:Destroy()
                showBanned()
            elseif kind == "denied" then
                status.Text = deniedText(info)
            elseif kind == "vip" then
                status.Text = "Script ini khusus VIP. Hubungi owner untuk mendapatkan VIP, atau pilih script lain."
            elseif kind == "notfound" then
                status.Text = "Script \"" .. tostring(nm or "default") .. "\" tidak ditemukan. Cek /script_list di Discord."
            else
                status.Text = "Server tidak bisa dihubungi. Coba lagi nanti."
            end
        end)

        if not mount(gui) then warn("[ALLZXRAA] panel tidak bisa ditampilkan di executor ini") end
    end)
end

-- ---------------------------------------------------------------- alur utama
if presetKey then
    local body, kind, info = requestScript(presetKey, presetName)
    if body then runScript(body); return end
    if kind == "banned" then showBanned(); return end
    if kind == "denied" then
        showGate(deniedText(info), presetKey, presetName)
    elseif kind == "vip" then
        showGate("Script \"" .. tostring(presetName or "default") .. "\" khusus VIP. Hubungi owner untuk mendapatkan VIP, atau pilih script lain di bawah.", presetKey, presetName)
    elseif kind == "notfound" then
        showGate("Script \"" .. tostring(presetName or "default") .. "\" tidak ditemukan. Isi nama yang benar di bawah.", presetKey, presetName)
    else
        showNotice("Tidak terhubung",
            "Server tidak bisa dihubungi atau menolak permintaan. Cek koneksi lalu coba lagi.")
    end
else
    showGate("Masukkan key dari /verify di Discord. Belum verifikasi? Gabung Discord lalu jalankan /verify.", nil, presetName)
end
