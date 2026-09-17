--information:個別オブジェクトをランダム配置する

---$track:個数, min = 1, max = 1000, step = 1
local count = 5

---$track:X軸範囲, min = 0, max = 10000, step = 0.01
local wx = 1000

---$track:Y軸範囲, min = 0, max = 10000, step = 0.01
local wy = 1000

---$track:Z軸範囲, min = 0, max = 10000, step = 0.01
local wz = 0

---$track:X回転角, min = 0, max = 180, step = 0.01
local rx = 0

---$track:Y回転角, min = 0, max = 180, step = 0.01
local ry = 0

---$track:Z回転角, min = 0, max = 180, step = 0.01
local rz = 180

---$track:縮小最小[%], min = 0, max = 100, step = 0.01
local s_min = 100

---$track:乱数, min = 0, max = 1000, step = 1
local ran = 0

obj.effect()
obj.multiobject(count, function()
    local seed = obj.index + 1 + ran
    local x = obj.rand(-wx, wx, seed, 0)
    local y = obj.rand(-wy, wy, seed, 1)
    local z = obj.rand(-wz, wz, seed, 2)
    local s = obj.rand(s_min, 100, seed, 6) / 100
    local rot_x = rx > 0 and obj.rand(-rx, rx, seed, 7) or 0
    local rot_y = ry > 0 and obj.rand(-ry, ry, seed, 8) or 0
    local rot_z = rz > 0 and obj.rand(-rz, rz, seed, 9) or 0
    obj.ox = x
    obj.oy = y
    obj.oz = z
    obj.sx = s
    obj.sy = s
    obj.sz = s
    obj.rx = rot_x
    obj.ry = rot_y
    obj.rz = rot_z
end)
