-- Loader publik (taruh di LOADER_URL). Script asli tidak ada di sini; diambil dari server bot setelah key dicek.
local GATE_URL = "https://loader.lolhuman.web.id/script"
local DISCORD_LINK = "https://discord.gg/3tyxaCyNH"  -- link invite yang ditampilkan di peringatan

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- ---------------------------------------------------------------- peringatan GUI
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

local function showNotice(title, message, permanent)
    warn("[ALLZXRAA] " .. message)
    pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "ALLZXRAA_Notice"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 999999
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        if permanent then
            local backdrop = Instance.new("Frame")
            backdrop.Size = UDim2.new(1, 0, 1, 0)
            backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
            backdrop.BackgroundTransparency = 0.35
            backdrop.BorderSizePixel = 0
            backdrop.Active = true -- menelan sentuhan/klik ke UI di bawahnya
            backdrop.ZIndex = 1
            backdrop.Parent = gui
        end

        local frame = Instance.new("Frame")
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Position = UDim2.new(0.5, 0, 0.5, 0)
        frame.Size = UDim2.new(0, 320, 0, 176)
        frame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
        frame.BorderSizePixel = 0
        frame.ZIndex = 2
        frame.Parent = gui
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

        local t = Instance.new("TextLabel")
        t.BackgroundTransparency = 1
        t.Position = UDim2.new(0, 12, 0, 8)
        t.Size = UDim2.new(1, -24, 0, 26)
        t.Font = Enum.Font.GothamBold
        t.TextSize = 16
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextColor3 = Color3.fromRGB(255, 120, 120)
        t.Text = title
        t.Parent = frame

        local m = Instance.new("TextLabel")
        m.BackgroundTransparency = 1
        m.Position = UDim2.new(0, 12, 0, 38)
        m.Size = UDim2.new(1, -24, 0, 78)
        m.Font = Enum.Font.Gotham
        m.TextSize = 13
        m.TextWrapped = true
        m.TextXAlignment = Enum.TextXAlignment.Left
        m.TextYAlignment = Enum.TextYAlignment.Top
        m.TextColor3 = Color3.fromRGB(225, 225, 230)
        m.Text = message
        m.Parent = frame

        local function makeButton(text, x, w, color)
            local b = Instance.new("TextButton")
            b.Position = UDim2.new(x, x == 0 and 12 or 0, 0, 124)
            b.Size = UDim2.new(w, w == 1 and -24 or -18, 0, 38)
            b.BackgroundColor3 = color
            b.BorderSizePixel = 0
            b.Font = Enum.Font.GothamMedium
            b.TextSize = 13
            b.TextColor3 = Color3.new(1, 1, 1)
            b.Text = text
            b.AutoButtonColor = true
            b.Parent = frame
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
            return b
        end

        local function wireCopy(copy)
            copy.MouseButton1Click:Connect(function()
                if type(setclipboard) == "function" and pcall(setclipboard, DISCORD_LINK) then
                    copy.Text = "Tersalin"
                else
                    copy.Text = DISCORD_LINK
                    copy.TextScaled = true
                end
            end)
        end

        if permanent then
            -- tanpa tombol Tutup dan tanpa auto-hilang: panel tetap sampai script dijalankan ulang dengan key valid
            if DISCORD_LINK ~= "" then
                wireCopy(makeButton("Salin link Discord", 0, 1, Color3.fromRGB(88, 101, 242)))
            end
        else
            local close
            if DISCORD_LINK ~= "" then
                local copy = makeButton("Salin link Discord", 0, 0.5, Color3.fromRGB(88, 101, 242))
                close = makeButton("Tutup", 0.5, 0.5, Color3.fromRGB(60, 60, 70))
                wireCopy(copy)
            else
                close = makeButton("Tutup", 0, 1, Color3.fromRGB(60, 60, 70))
            end
            close.MouseButton1Click:Connect(function() gui:Destroy() end)
        end

        if mount(gui) and not permanent then
            task.delay(30, function() if gui.Parent then gui:Destroy() end end)
        end
    end)
end

-- ---------------------------------------------------------------- pengecekan awal
if GATE_URL == "" then warn("[ALLZXRAA] GATE_URL belum diisi di loader.lua"); return end

local env = (type(getgenv) == "function" and getgenv()) or _G
local key = env.script_key or _G.script_key
if type(key) ~= "string" or key == "" then
    showNotice("Verifikasi diperlukan",
        "Kamu belum verifikasi. Gabung server Discord, jalankan /verify, lalu jalankan ulang script memakai snippet dari tombol \"Ambil key\".",
        true)
    return
end

local uid = Players.LocalPlayer and Players.LocalPlayer.UserId
if type(uid) ~= "number" or uid <= 0 then
    showNotice("Error", "UserId tidak terbaca. Coba jalankan lagi setelah karakter dimuat.")
    return
end

-- ---------------------------------------------------------------- ambil script dari server bot
local httpRequest = (syn and syn.request) or http_request or request

-- return body | nil, kode_status (nil kalau tidak diketahui)
local function fetchScript()
    if httpRequest then
        local ok, res = pcall(httpRequest, {
            Url = GATE_URL, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({uid = tostring(uid), key = key}),
        })
        if not ok or type(res) ~= "table" then return nil, nil end
        if res.StatusCode ~= 200 then return nil, res.StatusCode end
        return res.Body
    end
    local url = GATE_URL .. "?uid=" .. tostring(uid) .. "&key=" .. HttpService:UrlEncode(key)
    local ok, body = pcall(game.HttpGet, game, url)
    if not ok then return nil, nil end
    return body
end

local body, status = fetchScript()
if not body then
    if status == 403 then
        showNotice("Verifikasi diperlukan",
            "Kamu belum terverifikasi, key salah, key sudah dicabut, atau akunmu diblacklist. Gabung Discord, jalankan /verify, lalu jalankan ulang script.",
            true)
    elseif status == 503 then
        showNotice("Script belum tersedia", "Server belum punya script. Hubungi admin.")
    elseif status then
        showNotice("Error server", "Server membalas status " .. tostring(status) .. ". Coba lagi nanti.")
    else
        showNotice("Tidak terhubung",
            "Server tidak bisa dihubungi atau menolak permintaan. Cek koneksi, dan pastikan sudah /verify dengan script_key yang benar.")
    end
    return
end

local fn, perr = loadstring(body)
if not fn then showNotice("Error", "Script tidak bisa dikompilasi: " .. tostring(perr)); return end
local okRun, runErr = pcall(fn)
if not okRun then warn("[ALLZXRAA] script error: " .. tostring(runErr)) end
