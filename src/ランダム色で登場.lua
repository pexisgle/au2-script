--track@frames_per_color:フレーム数/色,1,120,10,1
--check@is_random:ランダム順にする,0
--check@keep_last_color:最後の色を継続,0
--color@color1:色1,0xff0000
--color@color2:色2,0x00ff00
--color@color3:色3,0x0000ff
--color@color4:色4,0xffff00
--color@color5:色5,0xff00ff
--filter
--information:開始数フレームだけ色を切り替える

local colors = { color1, color2, color3, color4, color5 }
local n = #colors
local total_frames = frames_per_color * n

local chunk
if obj.frame >= total_frames then
    if keep_last_color ~= 1 then return end
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
