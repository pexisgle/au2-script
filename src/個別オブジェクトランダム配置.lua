--track@count:個数,1,1000,5,1
--track@wx:X軸範囲,0,10000,1000,0.01
--track@wy:Y軸範囲,0,10000,1000,0.01
--track@wz:Z軸範囲,0,10000,0,0.01
--track@rx:X回転角,0,180,0,0.01
--track@ry:Y回転角,0,180,0,0.01
--track@rz:Z回転角,0,180,180,0.01
--track@s_min:縮小最小[%],0,100,100,0.01
--track@ran:乱数,0,1000,0,1
--information:個別オブジェクトをランダム配置する

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
