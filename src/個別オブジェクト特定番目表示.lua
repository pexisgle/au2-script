--information:個別オブジェクトの特定番目のみを表示する

---$track:番目, min = 1, max = 1000, step = 1
local n = 1

if obj.index + 1 ~= n then
    obj.setoption("draw_state", true)
end
