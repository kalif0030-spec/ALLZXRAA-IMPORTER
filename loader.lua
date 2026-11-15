--[[
  ALLZXRAA LOADER
  Simpan file ini di tempat yang URL-nya tetap (mis. GitHub raw). Player menjalankan:

    script_key = "KEY_DARI_DISCORD"
    loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/loader.lua"))()

  Script utama tidak ada di file ini; bot mengirimnya hanya kalau key cocok.
]]

local BASE_URL = "https://operator-thousand-appendix-correct.trycloudflare.com" -- URL tunnel bot, tanpa slash di akhir
local INVITE   = ""                                                        -- link Discord (boleh kosong)

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local function fail(msg)
    local full = "[ALLZXRAA] " .. msg .. (INVITE ~= "" and (" Discord: " .. INVITE) or "")
    warn(full)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = "ALLZXRAA", Text = msg, Duration = 8})
    end)
end

local key = (getgenv and getgenv().script_key) or script_key
if type(key) ~= "string" or key == "" then
    return fail("script_key belum diisi. Ambil key lewat /verify di Discord.")
end

local rq = request or http_request or (syn and syn.request)
if not rq then
    return fail("Executor tidak punya request().")
end

local ok, res = pcall(rq, {
    Url = BASE_URL .. "/load",
    Method = "POST",
    Headers = {["Content-Type"] = "application/json"},
    Body = HttpService:JSONEncode({uid = Players.LocalPlayer.UserId, key = key}),
})
if not ok or type(res) ~= "table" then
    return fail("Tidak bisa menghubungi server.")
end

local code = tonumber(res.StatusCode or res.Status) or 0
if code == 403 then return fail("Key salah atau akun belum di-whitelist.") end
if code == 429 then return fail("Terlalu sering, coba lagi beberapa detik lagi.") end
if code ~= 200 then return fail("Server membalas HTTP " .. code .. ".") end

local fn, err = loadstring(tostring(res.Body or ""))
if not fn then
    return fail("Script gagal dimuat: " .. tostring(err))
end
fn()
