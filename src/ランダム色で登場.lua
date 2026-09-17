--filter
--information:開始数フレームだけ色を切り替える

---$track:フレーム数/色, min = 1, max = 120, step = 1
local frames_per_color = 10

---$check:ランダム順にする
local is_random = 0

---$check:最後の色を継続
local keep_last_color = 0

---$color:色1
local color1 = 0xff0000

---$color:色2
local color2 = 0x00ff00

---$color:色3
local color3 = 0x0000ff

---$color:色4
local color4 = 0xffff00

---$color:色5
local color5 = 0xff00ff

local colors = { color1, color2, color3, color4, color5 }
local n = #colors
local total_frames = frames_per_color * n

local chunk
if obj.frame >= total_frames then
    if keep_last_color ~= 1 then
        return
    end
    chunk = n
else
    chunk = math.floor(obj.frame / frames_per_color) + 1
end

local idx = chunk
if is_random == 1 then
    local order = { 1, 2, 3, 4, 5 }
    local seed = obj.effect_id + obj.index
    for i = n, 2, -1 do
        local j = obj.rand(1, i, seed, i)
        order[i], order[j] = order[j], order[i]
    end
    idx = order[chunk]
end

obj.effect("単色化", "color", colors[idx], "輝度を保持する", 0)
